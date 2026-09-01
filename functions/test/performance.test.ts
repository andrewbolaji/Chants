import { beforeEach, describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { createHash } from "crypto";
import { handleDeletedDraftCleanup } from "../src/deferred_draft_cleanup";
import { UPLOAD_GRANT_LIFETIME_MS } from "../src/upload_grant";
import {
  MAX_PERFORMANCE_BYTES,
  PerformanceMediaGateway,
  StagedMediaMetadata,
  handleCreatePerformanceDraft,
  handleCancelPerformanceDraft,
  handleModeratePerformance,
  handleResolvePerformanceDraftPlayback,
  handleResolvePerformancePlayback,
  handleSetPerformanceLike,
  handleRecordQualifiedPerformanceView,
  handleRecordPerformanceShare,
  handleCreatePerformanceComment,
  handleDeletePerformanceComment,
  handleSubmitPerformanceDraft,
  recomputePerformanceLikeCounts,
  recomputePerformanceViewCounts,
  recomputePerformanceCommentCount,
  recomputePerformanceShareCounts,
  parseCreatePerformanceDraft,
  parsePerformanceComment,
  performanceMentionHandles,
  parseModeratePerformance,
  cleanupRemovedPerformanceMedia,
} from "../src/performance";

type Data = Record<string, unknown>;
type Ref = { collectionName: string; id: string; path: string };
type QueryRef = {
  collectionName: string;
  filters: Array<{ field: string; value: unknown }>;
  where: (field: string, operator: string, value: unknown) => QueryRef;
};
type Operation =
  | { kind: "create" | "set" | "update"; ref: Ref; data: Data }
  | { kind: "delete"; ref: Ref };

class FirestoreHarness {
  private readonly store = new Map<string, Map<string, Data>>();

  readonly firestore = {
    collection: (name: string) => this.collection(name),
    runTransaction: <T>(handler: (transaction: unknown) => Promise<T>) =>
      this.runTransaction(handler),
  } as unknown as admin.firestore.Firestore;

  set(collection: string, id: string, data: Data): void {
    this.bucket(collection).set(id, { ...data });
  }

  get(collection: string, id: string): Data | undefined {
    const data = this.bucket(collection).get(id);
    return data ? { ...data } : undefined;
  }

  private bucket(collection: string): Map<string, Data> {
    let bucket = this.store.get(collection);
    if (!bucket) {
      bucket = new Map<string, Data>();
      this.store.set(collection, bucket);
    }
    return bucket;
  }

  private reference(collectionName: string, id: string): Ref {
    return { collectionName, id, path: `${collectionName}/${id}` };
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

  private query(collectionName: string, filters: QueryRef["filters"] = []): QueryRef {
    return {
      collectionName,
      filters,
      where: (field: string, operator: string, value: unknown) => {
        if (operator !== "==") throw new Error(`Unsupported operator: ${operator}`);
        return this.query(collectionName, [...filters, { field, value }]);
      },
    };
  }

  private querySnapshot(query: QueryRef) {
    const docs = [...this.bucket(query.collectionName).entries()]
      .filter(([, data]) => query.filters.every(
        (filter) => data[filter.field] === filter.value
      ))
      .map(([id]) => this.snapshot(this.reference(query.collectionName, id)));
    return { docs, size: docs.length, empty: docs.length === 0 };
  }

  private collection(name: string) {
    return {
      doc: (id: string) => {
        const ref = this.reference(name, id);
        return { ...ref, get: async () => this.snapshot(ref),
          update: async (data: Data) => this.apply({ kind: "update", ref, data }),
        };
      },
      where: (field: string, operator: string, value: unknown) =>
        this.query(name).where(field, operator, value),
    };
  }

  private apply(operation: Operation): void {
    const bucket = this.bucket(operation.ref.collectionName);
    if (operation.kind === "delete") {
      bucket.delete(operation.ref.id);
      return;
    }
    const existing = bucket.get(operation.ref.id);
    if (operation.kind === "create" && existing) {
      throw new Error(`Document exists: ${operation.ref.path}`);
    }
    if (operation.kind === "update" && !existing) {
      throw new Error(`Document is missing: ${operation.ref.path}`);
    }
    bucket.set(
      operation.ref.id,
      operation.kind === "update"
        ? { ...existing, ...operation.data }
        : { ...operation.data }
    );
  }

  private async runTransaction<T>(
    handler: (transaction: {
      get: (
        target: Ref | QueryRef
      ) => Promise<ReturnType<FirestoreHarness["snapshot"]> |
        ReturnType<FirestoreHarness["querySnapshot"]>>;
      create: (ref: Ref, data: Data) => void;
      set: (ref: Ref, data: Data) => void;
      update: (ref: Ref, data: Data) => void;
      delete: (ref: Ref) => void;
    }) => Promise<T>
  ): Promise<T> {
    const operations: Operation[] = [];
    const result = await handler({
      get: async (target) => "filters" in target
        ? this.querySnapshot(target)
        : this.snapshot(target),
      create: (ref, data) => operations.push({ kind: "create", ref, data }),
      set: (ref, data) => operations.push({ kind: "set", ref, data }),
      update: (ref, data) => operations.push({ kind: "update", ref, data }),
      delete: (ref) => operations.push({ kind: "delete", ref }),
    });
    operations.forEach((operation) => this.apply(operation));
    return result;
  }
}

class MediaHarness implements PerformanceMediaGateway {
  metadata: StagedMediaMetadata = {
    size: 3,
    contentType: "video/mp4",
    generation: "generation-1",
    customMetadata: { ownerId: "fan", draftId: "draft-1", schemaVersion: "1" },
  };
  inspectCalls = 0;
  copied: Array<[string, string]> = [];
  removed: string[] = [];
  signed: Array<[string, number]> = [];

  async inspect(_path: string): Promise<StagedMediaMetadata> {
    this.inspectCalls++;
    return this.metadata;
  }

  async copy(sourcePath: string, destinationPath: string): Promise<void> {
    this.copied.push([sourcePath, destinationPath]);
  }

  async remove(path: string): Promise<void> {
    this.removed.push(path);
  }

  async signReadUrl(path: string, expiresAtMs: number): Promise<string> {
    this.signed.push([path, expiresAtMs]);
    return "https://signed.example.test/media";
  }
}

const NOW = admin.firestore.Timestamp.fromMillis(Date.UTC(2026, 7, 28, 12));
const OLD = admin.firestore.Timestamp.fromMillis(Date.UTC(2026, 0, 1));

function activeAccount(overrides: Data = {}): Data {
  return {
    displayName: "Fan",
    role: "user",
    banned: false,
    ageConfirmed17Plus: true,
    acceptedPolicyVersion: "v2",
    deletionPending: false,
    createdAt: NOW,
    ...overrides,
  };
}

function visibleCreator(overrides: Data = {}): Data {
  return {
    handle: "northbankleo",
    displayName: "North Bank Leo",
    hidden: false,
    removed: false,
    performanceCount: 0,
    ...overrides,
  };
}

function visibleChant(overrides: Data = {}): Data {
  return {
    title: "Super Saka",
    teamId: "arsenal",
    playerId: "saka",
    status: "community",
    hidden: false,
    removed: false,
    ...overrides,
  };
}

function approvedPerformance(overrides: Data = {}): Data {
  return {
    schemaVersion: 1,
    publicationState: "approved",
    hidden: false,
    removed: false,
    sourceChantVisible: true,
    sourceCreatorVisible: true,
    chantId: "chant-1",
    creatorId: "fan",
    mediaPath: "performance-media/performance-1/source",
    ...overrides,
  };
}

function seedAuthority(db: FirestoreHarness): void {
  db.set("operationalControls", "v1", { schemaVersion: 1, generation: 1, mode: "media", destructiveWorkersEnabled: true });
  db.set("profiles", "fan", activeAccount());
  db.set("creatorProfiles", "fan", visibleCreator());
  db.set("profiles", "other", activeAccount());
  db.set("creatorProfiles", "other", visibleCreator({
    handle: "otherfan",
    displayName: "Other Fan",
  }));
  db.set("chants", "chant-1", visibleChant());
  db.set("teams", "arsenal", { name: "Arsenal" });
  db.set("players", "saka", { teamId: "arsenal", name: "Bukayo Saka" });
}

function awaitingDraft(overrides: Data = {}): Data {
  return {
    schemaVersion: 1,
    ownerId: "fan",
    chantId: "chant-1",
    chantTitle: "Super Saka",
    teamId: "arsenal",
    teamName: "Arsenal",
    playerName: "Bukayo Saka",
    chantStatus: "community",
    creatorHandle: "northbankleo",
    creatorDisplayName: "North Bank Leo",
    caption: "First take.",
    uploadPath: "performance-staging/fan/draft-1/source",
    claimedContentType: "video/mp4",
    claimedSizeBytes: 3,
    claimedDurationMs: 18_000,
    state: "awaiting_upload",
    moderationReason: null,
    sourceGeneration: null,
    verifiedContentType: null,
    verifiedSizeBytes: null,
    createdAt: NOW,
    updatedAt: NOW,
    submittedAt: null,
    reviewedAt: null,
    ...overrides,
  };
}

describe("performance admission", () => {
  let db: FirestoreHarness;
  let media: MediaHarness;

  beforeEach(() => {
    db = new FirestoreHarness();
    media = new MediaHarness();
    seedAuthority(db);
  });

  it("accepts only the exact bounded draft payload", () => {
    assert.deepStrictEqual(parseCreatePerformanceDraft({
      chantId: "chant-1",
      caption: " First take. ",
      contentType: "video/mp4",
      sizeBytes: 3,
      durationMs: 18_000,
    }), {
      chantId: "chant-1",
      caption: "First take.",
      contentType: "video/mp4",
      sizeBytes: 3,
      durationMs: 18_000,
    });

    for (const payload of [
      { chantId: "chant-1", caption: "", contentType: "text/plain", sizeBytes: 3, durationMs: 1 },
      { chantId: "chant-1", caption: "", contentType: "video/mp4", sizeBytes: MAX_PERFORMANCE_BYTES + 1, durationMs: 1 },
      { chantId: "chant-1", caption: "", contentType: "video/mp4", sizeBytes: 3, durationMs: 30_001 },
      { chantId: "chant-1", caption: "", contentType: "video/mp4", sizeBytes: 3, durationMs: 1, ownerId: "victim" },
    ]) {
      assert.throws(
        () => parseCreatePerformanceDraft(payload),
        (error: { code?: string }) => error.code === "invalid-argument"
      );
    }
  });

  it("owns one slot, frees it on cancel, and never clears a newer grant", async () => {
    const create = (id: string) => handleCreatePerformanceDraft({
      uid: "fan", data: { chantId: "chant-1", caption: "", contentType: "video/mp4", sizeBytes: 3, durationMs: 1 },
      firestore: db.firestore, now: () => NOW, newId: () => id,
    });
    const cancel = (id: string) => handleCancelPerformanceDraft({ uid: "fan", data: { draftId: id }, firestore: db.firestore, media, now: () => NOW });
    await create("draft-1");
    await assert.rejects(create("draft-2"), (error: { details?: { reason: string } }) => error.details?.reason === "upload-in-progress");
    assert.strictEqual(db.get("performanceDrafts", "draft-2"), undefined);
    await cancel("draft-1");
    assert.strictEqual(db.get("profiles", "fan")?.activePerformanceUpload, null);
    await create("draft-2"); await cancel("draft-1");
    assert.strictEqual((db.get("profiles", "fan")?.activePerformanceUpload as Data).draftId, "draft-2");
  });

  it("refuses late or old-generation submission, and can replace an expired grant", async () => {
    const create = (id: string, now = NOW) => handleCreatePerformanceDraft({
      uid: "fan", data: { chantId: "chant-1", caption: "", contentType: "video/mp4", sizeBytes: 3, durationMs: 1 },
      firestore: db.firestore, now: () => now, newId: () => id,
    });
    await create("draft-1");
    const later = admin.firestore.Timestamp.fromMillis(NOW.toMillis() + UPLOAD_GRANT_LIFETIME_MS);
    const submit = (now = NOW) => handleSubmitPerformanceDraft({ uid: "fan", data: { draftId: "draft-1" }, firestore: db.firestore, media, now: () => now });
    await assert.rejects(submit(later), (error: { details?: { reason: string } }) => error.details?.reason === "upload-expired");
    db.set("operationalControls", "v1", { schemaVersion: 1, generation: 2, mode: "media", destructiveWorkersEnabled: true });
    await assert.rejects(submit(), (error: { details?: { reason: string } }) => error.details?.reason === "upload-expired");
    await create("draft-2", later);
    assert.strictEqual((db.get("profiles", "fan")?.activePerformanceUpload as Data).draftId, "draft-2");
    assert.strictEqual(db.get("performanceDrafts", "draft-1")?.state, "awaiting_upload");
    assert.strictEqual(db.get("performances", "draft-1"), undefined);
  });

  it("refuses grant issuance while paused without spending budget or creating a draft", async () => {
    db.set("operationalControls", "v1", { schemaVersion: 1, generation: 2, mode: "maintenance", destructiveWorkersEnabled: true });
    await assert.rejects(handleCreatePerformanceDraft({
      uid: "fan", data: { chantId: "chant-1", caption: "", contentType: "video/mp4", sizeBytes: 3, durationMs: 1 },
      firestore: db.firestore, now: () => NOW, newId: () => "draft-1",
    }), (error: { code: string }) => error.code === "unavailable");
    assert.strictEqual(db.get("performanceDrafts", "draft-1"), undefined);
    assert.strictEqual(db.get("performanceUploadLimits", "fan_2026-08-28"), undefined);
  });

  it("retains event-only cleanup while paused, after failure, and after a late upload", async () => {
    db.set("operationalControls", "v1", { schemaVersion: 1, generation: 1, mode: "maintenance", destructiveWorkersEnabled: true });
    let attempts = 0; let fail = true; let objectExists = true;
    const invoke = () => handleDeletedDraftCleanup({
      draftId: "draft-1", data: awaitingDraft(), firestore: db.firestore, now: () => NOW,
      remove: async (path) => {
        assert.strictEqual(path, "performance-staging/fan/draft-1/source");
        attempts++; if (fail) throw Error("storage unavailable");
        objectExists = false;
      },
    });
    await invoke();
    assert.strictEqual(attempts, 0);
    assert.strictEqual(objectExists, true);
    assert.strictEqual(db.get("deferredDraftCleanupJobs", "draft-1")?.state, "pending");
    db.set("operationalControls", "v1", { schemaVersion: 1, generation: 2, mode: "core", destructiveWorkersEnabled: true });
    // A control update alone does not replay the retained instruction.
    assert.strictEqual(attempts, 0);
    await assert.rejects(invoke());
    assert.strictEqual(db.get("deferredDraftCleanupJobs", "draft-1")?.state, "pending");
    fail = false; await invoke();
    assert.strictEqual(objectExists, false);
    assert.strictEqual(db.get("deferredDraftCleanupJobs", "draft-1")?.state, "attempted");
    // Retained exact-path evidence permits another explicit cleanup if an
    // already admitted transfer finishes after the first deletion attempt.
    objectExists = true;
    await invoke(); assert.strictEqual(attempts, 3);
    assert.strictEqual(objectExists, false);
    assert.deepStrictEqual(Object.keys(db.get("deferredDraftCleanupJobs", "draft-1")!).sort(),
      ["createdAt", "draftId", "schemaVersion", "state", "updatedAt", "uploadPath"]);
  });

  it("links retained staging cleanup to an account deletion in progress", async () => {
    db.set("accountDeletionJobs", "fan", {
      schemaVersion: 2,
      phase: "delete-performance-drafts",
      requestedAt: NOW,
      updatedAt: NOW,
    });
    db.set("operationalControls", "v1", {
      schemaVersion: 1,
      generation: 1,
      mode: "maintenance",
      destructiveWorkersEnabled: true,
    });

    const result = await handleDeletedDraftCleanup({
      draftId: "draft-1",
      data: awaitingDraft(),
      firestore: db.firestore,
      now: () => NOW,
      remove: media.remove.bind(media),
    });

    assert.strictEqual(result, "deferred");
    assert.strictEqual(
      db.get("deferredDraftCleanupJobs", "draft-1")
        ?.accountDeletionOwnerId,
      "fan"
    );
    assert.deepStrictEqual(media.removed, []);
  });

  it("durably blocks invalid cleanup identities on the live handler without media or grant changes", async () => {
    const grant = { draftId: "draft-1" };
    db.set("profiles", "fan", { activePerformanceUpload: grant });
    const cases = [
      { draftId: "draft-1", data: { ...awaitingDraft(), ownerId: "victim" } },
      { draftId: "invalid/identity", data: awaitingDraft() },
      { draftId: "wrong-path", data: { ...awaitingDraft(), uploadPath: "performance-staging/fan/different/source" } },
      { draftId: "bad-owner", data: { ...awaitingDraft(), ownerId: null } },
    ];
    for (const input of cases) {
      let timestamp = NOW;
      const invoke = () => handleDeletedDraftCleanup({ ...input, firestore: db.firestore, now: () => timestamp, remove: media.remove.bind(media) });
      assert.strictEqual(await invoke(), "blocked");
      const sourceDigest = createHash("sha256").update(input.draftId).digest("hex");
      const key = `blocked:${sourceDigest}`;
      const record = db.get("deferredDraftCleanupJobs", key)!;
      assert.deepStrictEqual(record, { schemaVersion: 1, sourceDigest,
        draftId: input.draftId === "invalid/identity" ? null : input.draftId, state: "blocked",
        reason: "invalid-identity", createdAt: NOW, updatedAt: NOW });
      timestamp = admin.firestore.Timestamp.fromMillis(NOW.toMillis() + 1000);
      assert.strictEqual(await invoke(), "blocked");
      assert.deepStrictEqual(db.get("deferredDraftCleanupJobs", key), record);
      assert.strictEqual(db.get("deferredDraftCleanupJobs", input.draftId), undefined);
    }
    // A later well-shaped delivery cannot silently clear a prior block.
    assert.strictEqual(await handleDeletedDraftCleanup({ draftId: "draft-1", data: awaitingDraft(),
      firestore: db.firestore, now: () => NOW, remove: media.remove.bind(media) }), "blocked");
    assert.deepStrictEqual(media.removed, []);
    assert.deepStrictEqual(db.get("profiles", "fan")!.activePerformanceUpload, grant);
  });

  it("preserves conflicting cleanup work, quarantines once, and retries database failures", async () => {
    const original = { schemaVersion: 1, uploadPath: "performance-staging/other/draft-1/source", state: "pending" };
    db.set("deferredDraftCleanupJobs", "draft-1", original);
    db.set("profiles", "fan", { activePerformanceUpload: { draftId: "draft-1" } });
    const invoke = (firestore = db.firestore) => handleDeletedDraftCleanup({ draftId: "draft-1",
      data: awaitingDraft(), firestore, now: () => NOW, remove: media.remove.bind(media) });
    const unavailable = new Proxy(db.firestore, { get(object, property) {
      if (property === "runTransaction") return async () => { throw Error("database unavailable"); };
      return Reflect.get(object, property);
    } });
    await assert.rejects(invoke(unavailable), /database unavailable/);
    assert.strictEqual(await invoke(), "blocked");
    assert.strictEqual(await invoke(), "blocked");
    assert.deepStrictEqual(db.get("deferredDraftCleanupJobs", "draft-1"), original);
    const key = "blocked:" + createHash("sha256").update("draft-1").digest("hex");
    assert.strictEqual(db.get("deferredDraftCleanupJobs", key)!.reason, "path-conflict");
    assert.deepStrictEqual(db.get("profiles", "fan")!.activePerformanceUpload, { draftId: "draft-1" });
    assert.deepStrictEqual(media.removed, []);
  });

  it("creates a private allowlisted upload ticket and snapshots chant identity", async () => {
    const result = await handleCreatePerformanceDraft({
      uid: "fan",
      data: {
        chantId: "chant-1",
        caption: "First take.",
        contentType: "video/mp4",
        sizeBytes: 3,
        durationMs: 18_000,
      },
      firestore: db.firestore,
      now: () => NOW,
      newId: () => "draft-1",
    });

    assert.deepStrictEqual(result, {
      draftId: "draft-1",
      uploadPath: "performance-staging/fan/draft-1/source",
    });
    assert.strictEqual(db.get("performanceDrafts", "draft-1")?.ownerId, "fan");
    assert.strictEqual(db.get("performanceDrafts", "draft-1")?.playerName, "Bukayo Saka");
    assert.strictEqual(db.get("performanceDrafts", "draft-1")?.state, "awaiting_upload");
    assert.strictEqual(db.get("performances", "draft-1"), undefined);
    assert.strictEqual(db.get("performanceUploadLimits", "fan_2026-08-28")?.count, 1);
  });

  it("enforces a smaller daily limit for new accounts", async () => {
    const request = (id: string) => handleCreatePerformanceDraft({
      uid: "fan",
      data: {
        chantId: "chant-1", caption: "", contentType: "video/mp4",
        sizeBytes: 3, durationMs: 1,
      },
      firestore: db.firestore,
      now: () => NOW,
      newId: () => id,
    });
    await request("draft-1");
    await handleCancelPerformanceDraft({ uid: "fan", data: { draftId: "draft-1" }, firestore: db.firestore, media, now: () => NOW });
    await request("draft-2");
    await handleCancelPerformanceDraft({ uid: "fan", data: { draftId: "draft-2" }, firestore: db.firestore, media, now: () => NOW });
    await assert.rejects(request("draft-3"),
      (error: { code?: string }) => error.code === "resource-exhausted");

    db.set("profiles", "fan", activeAccount({ createdAt: OLD }));
    await request("draft-4");
    assert.strictEqual(db.get("performanceUploadLimits", "fan_2026-08-28")?.count, 3);
  });

  it("inspects storage, submits once, and reconciles a repeated response", async () => {
    await handleCreatePerformanceDraft({
      uid: "fan", data: { chantId: "chant-1", caption: "", contentType: "video/mp4", sizeBytes: 3, durationMs: 1 },
      firestore: db.firestore, now: () => NOW, newId: () => "draft-1",
    });
    const request = {
      uid: "fan",
      data: { draftId: "draft-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    };
    assert.deepStrictEqual(await handleSubmitPerformanceDraft(request), {
      accepted: true,
      state: "pending_review",
    });
    assert.strictEqual(db.get("performanceDrafts", "draft-1")?.state, "pending_review");
    assert.strictEqual(db.get("performanceDrafts", "draft-1")?.sourceGeneration, "generation-1");
    assert.strictEqual(media.inspectCalls, 1);

    await handleSubmitPerformanceDraft(request);
    assert.strictEqual(media.inspectCalls, 1);
  });

  it("fails closed when staged object metadata is forged", async () => {
    db.set("performanceDrafts", "draft-1", awaitingDraft());
    media.metadata = {
      ...media.metadata,
      customMetadata: { ...media.metadata.customMetadata, ownerId: "victim" },
    };
    await assert.rejects(handleSubmitPerformanceDraft({
      uid: "fan",
      data: { draftId: "draft-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    }), (error: { code?: string }) => error.code === "failed-precondition");
    assert.strictEqual(db.get("performanceDrafts", "draft-1")?.state, "awaiting_upload");
  });

  it("publishes an exact projection only through an active operator review", async () => {
    db.set("profiles", "operator", activeAccount({ role: "operator" }));
    db.set("performanceDrafts", "draft-1", awaitingDraft({ state: "pending_review" }));
    const result = await handleModeratePerformance({
      actorUid: "operator",
      data: { draftId: "draft-1", action: "approve", reason: "" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    });
    assert.deepStrictEqual(result, { state: "approved", performanceId: "draft-1" });
    assert.deepStrictEqual(media.copied, [[
      "performance-staging/fan/draft-1/source",
      "performance-media/draft-1/source",
    ]]);
    const projection = db.get("performances", "draft-1")!;
    assert.deepStrictEqual(Object.keys(projection).sort(), [
      "approvedAt", "caption", "chantId", "chantStatus", "chantTitle",
      "commentCount", "createdAt", "creatorDisplayName", "creatorHandle",
      "creatorId", "durationMs", "hidden", "likeCount", "mediaPath",
      "playerName", "publicationState", "removed", "schemaVersion",
      "sourceChantVisible", "sourceCreatorVisible",
      "shareCount", "teamId", "teamName", "uniqueSharerCount", "updatedAt",
      "viewCount", "weeklyLikeCount", "weeklyQualifiedViewCount",
      "weeklyUniqueSharerCount", "rankingWeek",
    ].sort());
    assert.strictEqual(projection.publicationState, "approved");
    assert.strictEqual(projection.chantStatus, "community");
    assert.strictEqual(db.get("performanceDrafts", "draft-1")?.state, "approved");
  });

  it("requires a rejection reason and never publishes a rejected draft", async () => {
    assert.throws(
      () => parseModeratePerformance({ draftId: "draft-1", action: "reject", reason: "" }),
      (error: { code?: string }) => error.code === "invalid-argument"
    );
    db.set("profiles", "operator", activeAccount({ role: "operator" }));
    db.set("performanceDrafts", "draft-1", awaitingDraft({ state: "pending_review" }));
    await handleModeratePerformance({
      actorUid: "operator",
      data: { draftId: "draft-1", action: "reject", reason: "Over 30 seconds." },
      firestore: db.firestore,
      media,
      now: () => NOW,
    });
    assert.strictEqual(db.get("performanceDrafts", "draft-1")?.state, "rejected");
    assert.strictEqual(db.get("performances", "draft-1"), undefined);
    assert.deepStrictEqual(media.removed, ["performance-staging/fan/draft-1/source"]);
  });

  it("mints a short URL only after current public visibility is rechecked", async () => {
    db.set("performances", "performance-1", approvedPerformance());
    const result = await handleResolvePerformancePlayback({
      actorUid: "fan",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    });
    assert.strictEqual(result.url, "https://signed.example.test/media");
    assert.strictEqual(result.expiresAtMs, NOW.toMillis() + 600_000);

    db.set("performances", "performance-1", {
      ...db.get("performances", "performance-1"),
      hidden: true,
    });
    await assert.rejects(handleResolvePerformancePlayback({
      actorUid: "fan",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    }), (error: { code?: string }) => error.code === "not-found");
    assert.strictEqual(media.signed.length, 1);
  });

  it("lets an active operator preview blocked published media for moderation", async () => {
    db.set("profiles", "operator", activeAccount({ role: "operator" }));
    db.set("performances", "performance-1", approvedPerformance());
    db.set("blocks", "fan_operator", {
      blockerId: "fan",
      blockedUserId: "operator",
    });

    const result = await handleResolvePerformancePlayback({
      actorUid: "operator",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    });

    assert.strictEqual(result.url, "https://signed.example.test/media");
    assert.strictEqual(media.signed.length, 1);
  });

  it("lets an active operator preview hidden media without reopening it to fans", async () => {
    db.set("profiles", "operator", activeAccount({ role: "operator" }));
    db.set("performances", "performance-1", approvedPerformance({ hidden: true }));

    const result = await handleResolvePerformancePlayback({
      actorUid: "operator",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    });
    assert.strictEqual(result.url, "https://signed.example.test/media");

    await assert.rejects(handleResolvePerformancePlayback({
      actorUid: "fan",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    }), (error: { code?: string }) => error.code === "not-found");
  });

  it("rejects a stale projection when the creator is banned or chant is hidden", async () => {
    db.set("profiles", "viewer", activeAccount());
    db.set("performances", "performance-1", approvedPerformance());
    db.set("profiles", "fan", activeAccount({ banned: true }));

    await assert.rejects(handleResolvePerformancePlayback({
      actorUid: "viewer",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    }), (error: { code?: string }) => error.code === "not-found");

    db.set("profiles", "fan", activeAccount());
    db.set("chants", "chant-1", visibleChant({ hidden: true }));
    await assert.rejects(handleSetPerformanceLike({
      uid: "viewer",
      data: { performanceId: "performance-1", liked: true },
      firestore: db.firestore,
      now: () => NOW,
    }), (error: { code?: string }) => error.code === "not-found");
  });

  it("deletes only the exact removed performance media path idempotently", async () => {
    const media = new MediaHarness();
    assert.strictEqual(await cleanupRemovedPerformanceMedia({
      performanceId: "performance-1",
      mediaPath: "performance-media/performance-1/source",
    }, media), true);
    assert.deepStrictEqual(media.removed, [
      "performance-media/performance-1/source",
    ]);
    assert.strictEqual(await cleanupRemovedPerformanceMedia({
      performanceId: "performance-1",
      mediaPath: "performance-media/another/source",
    }, media), false);
    assert.strictEqual(await cleanupRemovedPerformanceMedia({
      performanceId: "../unsafe",
      mediaPath: "performance-media/../unsafe/source",
    }, media), false);
    assert.deepStrictEqual(media.removed, [
      "performance-media/performance-1/source",
    ]);
  });

  it("stores one like source and removes it idempotently", async () => {
    db.set("performances", "performance-1", approvedPerformance({
      creatorId: "other",
    }));
    const request = (liked: boolean) => handleSetPerformanceLike({
      uid: "fan",
      data: { performanceId: "performance-1", liked },
      firestore: db.firestore,
      now: () => NOW,
    });

    assert.deepStrictEqual(await request(true), { liked: true });
    assert.strictEqual(
      db.get("performanceLikes", "fan_performance-1")?.rankingEligible,
      true
    );
    await request(true);
    assert.deepStrictEqual(await request(false), { liked: false });
    assert.strictEqual(db.get("performanceLikes", "fan_performance-1"), undefined);
    await request(false);
  });

  it("stores one unique share source after current authority succeeds", async () => {
    db.set("performances", "performance-1", approvedPerformance({
      creatorId: "other",
    }));
    const request = () => handleRecordPerformanceShare({
      uid: "fan",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      now: () => NOW,
    });

    assert.deepStrictEqual(await request(), { counted: true });
    assert.deepStrictEqual(await request(), { counted: false });
    assert.strictEqual(
      db.get("performanceShares", "fan_performance-1")?.rankingEligible,
      true
    );
  });

  it("counts a view only after a current three-second playback ticket", async () => {
    db.set("performances", "performance-1", approvedPerformance({
      creatorId: "other",
    }));
    await handleResolvePerformancePlayback({
      actorUid: "fan",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    });
    await assert.rejects(handleRecordQualifiedPerformanceView({
      uid: "fan",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      now: () => NOW,
    }), (error: { code?: string }) => error.code === "failed-precondition");

    const later = admin.firestore.Timestamp.fromMillis(NOW.toMillis() + 3_001);
    assert.deepStrictEqual(await handleRecordQualifiedPerformanceView({
      uid: "fan",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      now: () => later,
    }), { counted: true });
    assert.strictEqual(
      db.get("performanceViews", "fan_performance-1")?.rankingEligible,
      true
    );
    assert.strictEqual(
      db.get("performancePlaybackSessions", "fan_performance-1"),
      undefined
    );
    assert.deepStrictEqual(await handleRecordQualifiedPerformanceView({
      uid: "fan",
      data: { performanceId: "performance-1" },
      firestore: db.firestore,
      now: () => later,
    }), { counted: false });
  });

  it("creates idempotent public comments and lets only the author remove them", async () => {
    db.set("performances", "performance-1", approvedPerformance({
      creatorId: "other",
    }));
    assert.deepStrictEqual(parsePerformanceComment({
      performanceId: "performance-1",
      body: "  This will catch on.  ",
      clientActionId: "action-1",
      parentCommentId: null,
    }), {
      performanceId: "performance-1",
      body: "This will catch on.",
      clientActionId: "action-1",
      parentCommentId: null,
    });
    const request = {
      uid: "fan",
      data: {
        performanceId: "performance-1",
        body: "This will catch on.",
        clientActionId: "action-1",
        parentCommentId: null,
      },
      firestore: db.firestore,
      now: () => NOW,
    };
    const result = await handleCreatePerformanceComment(request);
    assert.deepStrictEqual(result, { commentId: "fan_action-1" });
    await handleCreatePerformanceComment(request);
    assert.strictEqual(
      db.get("performanceComments", "fan_action-1")?.creatorHandle,
      "northbankleo"
    );

    db.set("profiles", "other", activeAccount());
    await assert.rejects(handleDeletePerformanceComment({
      uid: "other",
      data: { commentId: "fan_action-1" },
      firestore: db.firestore,
      now: () => NOW,
    }), (error: { code?: string }) => error.code === "not-found");
    await handleDeletePerformanceComment({
      uid: "fan",
      data: { commentId: "fan_action-1" },
      firestore: db.firestore,
      now: () => NOW,
    });
    assert.strictEqual(db.get("performanceComments", "fan_action-1")?.removed, true);
    assert.strictEqual(db.get("performanceComments", "fan_action-1")?.body, "");
  });

  it("stores continued threads and fans out only validated unblocked mentions", async () => {
    db.set("performances", "performance-1", approvedPerformance({
      creatorId: "other",
    }));
    db.set("creatorHandles", "target_handle", { uid: "target" });
    db.set("creatorProfiles", "target", visibleCreator({
      handle: "target_handle",
      displayName: "Target Fan",
    }));
    db.set("performanceComments", "parent-1", {
      schemaVersion: 2,
      performanceId: "performance-1",
      userId: "target",
      hidden: false,
      removed: false,
      rootCommentId: "root-1",
      depth: 3,
    });

    assert.deepStrictEqual(
      performanceMentionHandles("@TARGET_HANDLE @target_handle @bad!"),
      ["target_handle", "bad"]
    );
    const result = await handleCreatePerformanceComment({
      uid: "fan",
      data: {
        performanceId: "performance-1",
        body: "@target_handle this reply can keep going.",
        clientActionId: "thread-action",
        parentCommentId: "parent-1",
      },
      firestore: db.firestore,
      now: () => NOW,
    });

    assert.deepStrictEqual(result, { commentId: "fan_thread-action" });
    assert.deepStrictEqual(
      db.get("performanceComments", "fan_thread-action")?.mentionedHandles,
      ["target_handle"]
    );
    assert.strictEqual(
      db.get("performanceComments", "fan_thread-action")?.rootCommentId,
      "root-1"
    );
    assert.strictEqual(
      db.get("performanceComments", "fan_thread-action")?.depth,
      4
    );
    assert.strictEqual(
      db.get("creatorNotifications", "comment_fan_thread-action_target")?.type,
      "performance_reply"
    );
  });

  it("keeps a blocked mention as plain text without an inbox side effect", async () => {
    db.set("performances", "performance-1", approvedPerformance({
      creatorId: "other",
    }));
    db.set("creatorHandles", "target_handle", { uid: "target" });
    db.set("creatorProfiles", "target", visibleCreator({ handle: "target_handle" }));
    db.set("blocks", "target_fan", {
      blockerId: "target",
      blockedUserId: "fan",
    });
    await handleCreatePerformanceComment({
      uid: "fan",
      data: {
        performanceId: "performance-1",
        body: "@target_handle take a listen.",
        clientActionId: "blocked-mention",
        parentCommentId: null,
      },
      firestore: db.firestore,
      now: () => NOW,
    });
    assert.deepStrictEqual(
      db.get("performanceComments", "fan_blocked-mention")?.mentionedHandles,
      []
    );
    assert.strictEqual(
      db.get("creatorNotifications", "comment_fan_blocked-mention_target"),
      undefined
    );
  });

  it("recomputes interaction counters from source records and current week", async () => {
    db.set("performances", "performance-1", {
      rankingWeek: "2026-08-17",
      weeklyUniqueSharerCount: 9,
      weeklyLikeCount: 9,
      weeklyQualifiedViewCount: 9,
    });
    db.set("performanceLikes", "fan_performance-1", {
      performanceId: "performance-1",
      rankingEligible: true,
      rankingWeek: "2026-08-24",
    });
    db.set("performanceLikes", "owner_performance-1", {
      performanceId: "performance-1",
      rankingEligible: false,
      rankingWeek: "2026-08-24",
    });
    assert.strictEqual(await recomputePerformanceLikeCounts({
      before: undefined,
      after: { performanceId: "performance-1" },
      firestore: db.firestore,
      now: () => NOW,
    }), true);
    assert.strictEqual(db.get("performances", "performance-1")?.likeCount, 2);
    assert.strictEqual(db.get("performances", "performance-1")?.weeklyLikeCount, 1);
    assert.strictEqual(
      db.get("performances", "performance-1")?.weeklyQualifiedViewCount,
      0
    );

    db.set("performanceViews", "fan_performance-1", {
      performanceId: "performance-1",
      rankingEligible: true,
      rankingWeek: "2026-08-24",
    });
    await recomputePerformanceViewCounts({
      before: undefined,
      after: { performanceId: "performance-1" },
      firestore: db.firestore,
      now: () => NOW,
    });
    assert.strictEqual(db.get("performances", "performance-1")?.viewCount, 1);
    assert.strictEqual(
      db.get("performances", "performance-1")?.weeklyQualifiedViewCount,
      1
    );

    db.set("performanceShares", "fan_performance-1", {
      performanceId: "performance-1",
      rankingEligible: true,
      rankingWeek: "2026-08-24",
    });
    await recomputePerformanceShareCounts({
      before: undefined,
      after: { performanceId: "performance-1" },
      firestore: db.firestore,
      now: () => NOW,
    });
    assert.strictEqual(db.get("performances", "performance-1")?.shareCount, 1);
    assert.strictEqual(
      db.get("performances", "performance-1")?.weeklyUniqueSharerCount,
      1
    );

    db.set("performanceComments", "comment-1", {
      performanceId: "performance-1",
      hidden: false,
      removed: false,
    });
    db.set("performanceComments", "comment-2", {
      performanceId: "performance-1",
      hidden: true,
      removed: false,
    });
    await recomputePerformanceCommentCount({
      before: undefined,
      after: { performanceId: "performance-1" },
      firestore: db.firestore,
      now: () => NOW,
    });
    assert.strictEqual(db.get("performances", "performance-1")?.commentCount, 1);
  });

  it("keeps draft previews owner-or-operator only and cleans deleted staging", async () => {
    db.set("performanceDrafts", "draft-1", awaitingDraft({ state: "pending_review" }));
    const ownerResult = await handleResolvePerformanceDraftPlayback({
      actorUid: "fan",
      data: { draftId: "draft-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    });
    assert.strictEqual(ownerResult.url, "https://signed.example.test/media");

    db.set("profiles", "operator", activeAccount({ role: "operator" }));
    await handleResolvePerformanceDraftPlayback({
      actorUid: "operator",
      data: { draftId: "draft-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    });
    db.set("profiles", "other", activeAccount());
    await assert.rejects(handleResolvePerformanceDraftPlayback({
      actorUid: "other",
      data: { draftId: "draft-1" },
      firestore: db.firestore,
      media,
      now: () => NOW,
    }), (error: { code?: string }) => error.code === "permission-denied");

  });
});
