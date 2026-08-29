import { describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import {
  handlePublishedPerformanceModeration,
  parsePublishedPerformanceModeration,
} from "../src/published_performance_moderation";

type Data = Record<string, unknown>;
type Ref = { collectionName: string; id: string };
type QueryRef = {
  collectionName: string;
  filters: Array<{ field: string; value: unknown }>;
  where: (field: string, operator: string, value: unknown) => QueryRef;
};

class Harness {
  private readonly store = new Map<string, Map<string, Data>>();
  readonly firestore = {
    collection: (name: string) => this.collection(name),
    runTransaction: <T>(handler: (transaction: unknown) => Promise<T>) =>
      this.transaction(handler),
  } as unknown as admin.firestore.Firestore;

  set(collection: string, id: string, data: Data): void {
    this.bucket(collection).set(id, { ...data });
  }

  get(collection: string, id: string): Data | undefined {
    const data = this.bucket(collection).get(id);
    return data ? { ...data } : undefined;
  }

  private bucket(name: string): Map<string, Data> {
    let bucket = this.store.get(name);
    if (!bucket) {
      bucket = new Map();
      this.store.set(name, bucket);
    }
    return bucket;
  }

  private snapshot(ref: Ref) {
    const data = this.bucket(ref.collectionName).get(ref.id);
    return {
      exists: data !== undefined,
      id: ref.id,
      ref,
      data: () => data ? { ...data } : undefined,
    };
  }

  private query(name: string, filters: QueryRef["filters"] = []): QueryRef {
    return {
      collectionName: name,
      filters,
      where: (field, operator, value) => {
        if (operator !== "==") throw new Error("unsupported query");
        return this.query(name, [...filters, { field, value }]);
      },
    };
  }

  private querySnapshot(query: QueryRef) {
    const docs = [...this.bucket(query.collectionName).entries()]
      .filter(([, data]) => query.filters.every(
        ({ field, value }) => data[field] === value
      ))
      .map(([id]) => this.snapshot({ collectionName: query.collectionName, id }));
    return { docs, size: docs.length, empty: docs.length === 0 };
  }

  private collection(name: string) {
    return {
      doc: (id: string) => ({ collectionName: name, id }),
      where: (field: string, operator: string, value: unknown) =>
        this.query(name).where(field, operator, value),
    };
  }

  private async transaction<T>(handler: (transaction: {
    get: (target: Ref | QueryRef) => Promise<unknown>;
    create: (ref: Ref, data: Data) => void;
    set: (ref: Ref, data: Data) => void;
    update: (ref: Ref, data: Data) => void;
  }) => Promise<T>): Promise<T> {
    const operations: Array<() => void> = [];
    const result = await handler({
      get: async (target) => "filters" in target
        ? this.querySnapshot(target)
        : this.snapshot(target),
      create: (ref, data) => operations.push(() => {
        if (this.bucket(ref.collectionName).has(ref.id)) {
          throw new Error("document exists");
        }
        this.bucket(ref.collectionName).set(ref.id, { ...data });
      }),
      set: (ref, data) => operations.push(() => {
        this.bucket(ref.collectionName).set(ref.id, { ...data });
      }),
      update: (ref, data) => operations.push(() => {
        const before = this.bucket(ref.collectionName).get(ref.id);
        if (!before) throw new Error("document missing");
        this.bucket(ref.collectionName).set(ref.id, { ...before, ...data });
      }),
    });
    operations.forEach((operation) => operation());
    return result;
  }
}

const NOW = admin.firestore.Timestamp.fromMillis(Date.UTC(2026, 7, 28, 12));

function seedOperator(db: Harness, role = "operator"): void {
  db.set("profiles", "operator", {
    role,
    banned: false,
    deletionPending: false,
  });
}

describe("published performance moderation", () => {
  it("parses only an exact target and bounded action", () => {
    assert.deepStrictEqual(parsePublishedPerformanceModeration({
      targetType: "performance",
      targetId: "performance-1",
      action: "hide",
    }), {
      targetType: "performance",
      targetId: "performance-1",
      action: "hide",
    });
    assert.throws(() => parsePublishedPerformanceModeration({
      targetType: "performance",
      targetId: "performance-1",
      action: "publish",
    }));
  });

  it("hides reported media, resolves every pending report, and audits once", async () => {
    const db = new Harness();
    seedOperator(db);
    db.set("performances", "performance-1", {
      hidden: false,
      removed: false,
    });
    db.set("performanceReports", "one", {
      performanceId: "performance-1",
      status: "pending",
    });
    db.set("performanceReports", "two", {
      performanceId: "performance-1",
      status: "pending",
    });

    const result = await handlePublishedPerformanceModeration({
      actorUid: "operator",
      data: {
        targetType: "performance",
        targetId: "performance-1",
        action: "hide",
      },
      firestore: db.firestore,
      now: () => NOW,
      newAuditId: () => "audit-1",
    });
    assert.deepStrictEqual(result, { success: true, reportsResolved: 2 });
    assert.strictEqual(db.get("performances", "performance-1")?.hidden, true);
    assert.strictEqual(db.get("performanceReports", "one")?.status, "reviewed");
    assert.strictEqual(db.get("performanceReports", "two")?.status, "reviewed");
    assert.deepStrictEqual(db.get("auditLog", "audit-1"), {
      actorId: "operator",
      action: "hide",
      targetType: "performance",
      targetId: "performance-1",
      detail: "Published content hide action applied by operator.",
      createdAt: NOW,
    });
  });

  it("dismisses a comment report without changing visible content", async () => {
    const db = new Harness();
    seedOperator(db);
    db.set("performanceComments", "comment-1", {
      hidden: false,
      removed: false,
      body: "Keep this",
    });
    db.set("performanceCommentReports", "report-1", {
      performanceCommentId: "comment-1",
      status: "pending",
    });
    await handlePublishedPerformanceModeration({
      actorUid: "operator",
      data: {
        targetType: "performanceComment",
        targetId: "comment-1",
        action: "dismiss",
      },
      firestore: db.firestore,
      now: () => NOW,
      newAuditId: () => "audit-1",
    });
    assert.strictEqual(
      db.get("performanceCommentReports", "report-1")?.status,
      "dismissed"
    );
    assert.strictEqual(db.get("performanceComments", "comment-1")?.body, "Keep this");
  });

  it("makes terminal performance removal schedule durable media deletion", async () => {
    const db = new Harness();
    seedOperator(db);
    db.set("performances", "performance-1", {
      hidden: true,
      removed: false,
      mediaPath: "performance-media/performance-1/source",
    });

    await handlePublishedPerformanceModeration({
      actorUid: "operator",
      data: {
        targetType: "performance",
        targetId: "performance-1",
        action: "remove",
      },
      firestore: db.firestore,
      now: () => NOW,
      newAuditId: () => "audit-1",
    });

    assert.strictEqual(db.get("performances", "performance-1")?.removed, true);
    assert.deepStrictEqual(
      db.get("performanceMediaDeletionJobs", "performance-1"),
      {
        performanceId: "performance-1",
        mediaPath: "performance-media/performance-1/source",
        requestedAt: NOW,
        updatedAt: NOW,
      },
    );
  });

  it("rejects non-operators and missing targets without resolving reports", async () => {
    const db = new Harness();
    seedOperator(db, "user");
    await assert.rejects(
      handlePublishedPerformanceModeration({
        actorUid: "operator",
        data: {
          targetType: "performance",
          targetId: "missing",
          action: "hide",
        },
        firestore: db.firestore,
        now: () => NOW,
        newAuditId: () => "audit-1",
      }),
      (error: unknown) => error instanceof HttpsError &&
        error.code === "permission-denied"
    );
  });
});
