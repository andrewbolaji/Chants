import { beforeEach, describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import {
  ABANDONED_DRAFT_AGE_MS,
  ABANDONED_DRAFT_LIMIT,
  ACCOUNT_DELETION_STALE_AGE_MS,
  MEDIA_DELETION_STALE_AGE_MS,
  OPERATIONAL_BACKLOG_LIMIT,
  OperationalCleanupMedia,
  OperationalDocument,
  OperationalStore,
  cleanupAbandonedPerformanceDrafts,
  monitorOperationalBacklogs,
  operationalBacklogLog,
} from "../src/operations";

type Data = Record<string, unknown>;

const NOW_MS = Date.UTC(2026, 7, 29, 12);
const NOW = admin.firestore.Timestamp.fromMillis(NOW_MS);

function timestamp(milliseconds: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(milliseconds);
}

function draft(id: string, overrides: Data = {}): OperationalDocument {
  const ownerId = `fan-${id}`;
  return {
    id,
    data: {
      schemaVersion: 1,
      ownerId,
      state: "awaiting_upload",
      uploadPath: `performance-staging/${ownerId}/${id}/source`,
      createdAt: timestamp(NOW_MS - ABANDONED_DRAFT_AGE_MS - 1),
      updatedAt: timestamp(NOW_MS - ABANDONED_DRAFT_AGE_MS - 1),
      ...overrides,
    },
  };
}

class StoreHarness implements OperationalStore {
  readonly drafts = new Map<string, Data>();
  readonly jobs = new Map<string, Map<string, Data>>();
  listedLimit = 0;
  staleLimits: number[] = [];

  addDraft(value: OperationalDocument): void {
    this.drafts.set(value.id, { ...value.data });
  }

  addJob(collection: string, id: string, data: Data): void {
    let bucket = this.jobs.get(collection);
    if (!bucket) {
      bucket = new Map<string, Data>();
      this.jobs.set(collection, bucket);
    }
    bucket.set(id, { ...data });
  }

  async listCleanupDrafts(
    createdAtOrBeforeMs: number,
    limit: number,
  ): Promise<OperationalDocument[]> {
    this.listedLimit = limit;
    return [...this.drafts.entries()]
      .filter(([, data]) => {
        const state = data.state;
        const createdAt = data.createdAt;
        return (state === "awaiting_upload" || state === "cleanup_pending") &&
          createdAt instanceof admin.firestore.Timestamp &&
          createdAt.toMillis() <= createdAtOrBeforeMs;
      })
      .sort((left, right) => {
        const leftTime = (left[1].createdAt as admin.firestore.Timestamp).toMillis();
        const rightTime = (right[1].createdAt as admin.firestore.Timestamp).toMillis();
        return leftTime - rightTime || left[0].localeCompare(right[0]);
      })
      .slice(0, limit)
      .map(([id, data]) => ({ id, data: { ...data } }));
  }

  async claimCleanupDraft(
    id: string,
    createdAtOrBeforeMs: number,
    updatedAtMs: number,
  ): Promise<OperationalDocument | null> {
    const data = this.drafts.get(id);
    if (!data) return null;
    const createdAt = data.createdAt;
    if (
      (data.state !== "awaiting_upload" && data.state !== "cleanup_pending") ||
      !(createdAt instanceof admin.firestore.Timestamp) ||
      createdAt.toMillis() > createdAtOrBeforeMs
    ) return null;
    const claimed = {
      ...data,
      state: "cleanup_pending",
      updatedAt: timestamp(updatedAtMs),
    };
    this.drafts.set(id, claimed);
    return { id, data: { ...claimed } };
  }

  async deleteClaimedDraft(id: string): Promise<boolean> {
    if (this.drafts.get(id)?.state !== "cleanup_pending") return false;
    this.drafts.delete(id);
    return true;
  }

  async countStaleJobs(
    collection: "accountDeletionJobs" | "performanceMediaDeletionJobs",
    updatedAtOrBeforeMs: number,
    limit: number,
  ): Promise<number> {
    this.staleLimits.push(limit);
    return [...(this.jobs.get(collection)?.values() ?? [])]
      .filter((data) => {
        const updatedAt = data.updatedAt;
        return updatedAt instanceof admin.firestore.Timestamp &&
          updatedAt.toMillis() <= updatedAtOrBeforeMs;
      })
      .slice(0, limit)
      .length;
  }
}

class MediaHarness implements OperationalCleanupMedia {
  removed: string[] = [];
  failOnce = false;

  async remove(path: string): Promise<void> {
    if (this.failOnce) {
      this.failOnce = false;
      throw new Error("storage unavailable");
    }
    this.removed.push(path);
  }
}

describe("launch operations", () => {
  let store: StoreHarness;
  let media: MediaHarness;

  beforeEach(() => {
    store = new StoreHarness();
    media = new MediaHarness();
  });

  it("cleans only the bounded page of expired upload drafts", async () => {
    for (let index = 0; index < ABANDONED_DRAFT_LIMIT + 4; index++) {
      store.addDraft(draft(`draft-${String(index).padStart(3, "0")}`));
    }

    const result = await cleanupAbandonedPerformanceDrafts({
      store,
      media,
      now: () => NOW,
    });

    assert.strictEqual(store.listedLimit, ABANDONED_DRAFT_LIMIT);
    assert.deepStrictEqual(result, {
      scanned: ABANDONED_DRAFT_LIMIT,
      claimed: ABANDONED_DRAFT_LIMIT,
      deleted: ABANDONED_DRAFT_LIMIT,
      invalid: 0,
      failures: 0,
    });
    assert.strictEqual(store.drafts.size, 4);
    assert.strictEqual(media.removed.length, ABANDONED_DRAFT_LIMIT);
  });

  it("does not select active, moderated, new, or malformed drafts", async () => {
    store.addDraft(draft("pending", { state: "pending_review" }));
    store.addDraft(draft("approved", { state: "approved" }));
    store.addDraft(draft("new", {
      createdAt: timestamp(NOW_MS - ABANDONED_DRAFT_AGE_MS + 1),
    }));
    store.addDraft(draft("malformed", {
      uploadPath: "performance-staging/victim/other/source",
    }));

    const result = await cleanupAbandonedPerformanceDrafts({
      store,
      media,
      now: () => NOW,
    });

    assert.deepStrictEqual(result, {
      scanned: 1,
      claimed: 0,
      deleted: 0,
      invalid: 1,
      failures: 0,
    });
    assert.strictEqual(store.drafts.size, 4);
    assert.deepStrictEqual(media.removed, []);
  });

  it("retains a cleanup claim after Storage failure and finishes on retry", async () => {
    store.addDraft(draft("retry"));
    media.failOnce = true;

    const first = await cleanupAbandonedPerformanceDrafts({
      store,
      media,
      now: () => NOW,
    });
    assert.deepStrictEqual(first, {
      scanned: 1,
      claimed: 1,
      deleted: 0,
      invalid: 0,
      failures: 1,
    });
    assert.strictEqual(store.drafts.get("retry")?.state, "cleanup_pending");

    const second = await cleanupAbandonedPerformanceDrafts({
      store,
      media,
      now: () => NOW,
    });
    assert.strictEqual(second.deleted, 1);
    assert.strictEqual(second.failures, 0);
    assert.strictEqual(store.drafts.has("retry"), false);

    const duplicate = await cleanupAbandonedPerformanceDrafts({
      store,
      media,
      now: () => NOW,
    });
    assert.strictEqual(duplicate.scanned, 0);
  });

  it("reports capped stale-job counts without document identities", async () => {
    for (let index = 0; index < OPERATIONAL_BACKLOG_LIMIT + 3; index++) {
      store.addJob("accountDeletionJobs", `private-${index}`, {
        updatedAt: timestamp(NOW_MS - ACCOUNT_DELETION_STALE_AGE_MS),
      });
    }
    store.addJob("performanceMediaDeletionJobs", "media-private", {
      updatedAt: timestamp(NOW_MS - MEDIA_DELETION_STALE_AGE_MS),
    });
    store.addJob("performanceMediaDeletionJobs", "fresh", {
      updatedAt: timestamp(NOW_MS - MEDIA_DELETION_STALE_AGE_MS + 1),
    });

    const summary = await monitorOperationalBacklogs({
      store,
      now: () => NOW,
    });
    assert.deepStrictEqual(summary, {
      accountDeletionJobs: {
        staleCount: OPERATIONAL_BACKLOG_LIMIT,
        moreThanLimit: true,
      },
      performanceMediaDeletionJobs: {
        staleCount: 1,
        moreThanLimit: false,
      },
      hasStaleJobs: true,
    });
    assert.deepStrictEqual(store.staleLimits, [
      OPERATIONAL_BACKLOG_LIMIT + 1,
      OPERATIONAL_BACKLOG_LIMIT + 1,
    ]);

    const log = operationalBacklogLog(summary);
    assert.deepStrictEqual(log, {
      operationalSignal: "stale-deletion-jobs",
      accountDeletionStaleCount: OPERATIONAL_BACKLOG_LIMIT,
      accountDeletionMoreThanLimit: true,
      performanceMediaDeletionStaleCount: 1,
      performanceMediaDeletionMoreThanLimit: false,
    });
    assert.strictEqual(JSON.stringify(log).includes("private"), false);
  });
});
