import { beforeEach, describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import {
  ACCOUNT_DELETION_PAGE_SIZE,
  ACCOUNT_DELETION_PHASES,
  AccountDeletionAuth,
  AccountDeletionPhase,
  auditRedactionForDeletedActor,
  processAccountDeletionStep,
  requestAccountDeletion,
} from "../src/account_deletion";

type Data = Record<string, unknown>;
type Ref = { __collection: string; id: string; path: string };
type Operation =
  | { kind: "create" | "set" | "update"; ref: Ref; data: Data }
  | { kind: "delete"; ref: Ref };

class FirestoreHarness {
  private readonly store = new Map<string, Map<string, Data>>();
  private nextDocumentId = 0;
  failNextBatch = false;
  failNextTransaction = false;
  afterNextQuery: (() => void) | null = null;

  readonly firestore: admin.firestore.Firestore;

  constructor() {
    this.firestore = {
      collection: (name: string) => this.collection(name),
      batch: () => this.batch(),
      runTransaction: <T>(handler: (transaction: unknown) => Promise<T>) =>
        this.runTransaction(handler),
    } as unknown as admin.firestore.Firestore;
  }

  set(collection: string, id: string, data: Data): void {
    this.bucket(collection).set(id, { ...data });
  }

  get(collection: string, id: string): Data | undefined {
    const value = this.bucket(collection).get(id);
    return value ? { ...value } : undefined;
  }

  remove(collection: string, id: string): void {
    this.bucket(collection).delete(id);
  }

  size(collection: string): number {
    return this.bucket(collection).size;
  }

  private bucket(collection: string): Map<string, Data> {
    let bucket = this.store.get(collection);
    if (!bucket) {
      bucket = new Map<string, Data>();
      this.store.set(collection, bucket);
    }
    return bucket;
  }

  private ref(collection: string, id: string): Ref {
    return { __collection: collection, id, path: `${collection}/${id}` };
  }

  private snapshot(ref: Ref) {
    const value = this.bucket(ref.__collection).get(ref.id);
    return {
      exists: value !== undefined,
      id: ref.id,
      ref,
      data: () => value ? { ...value } : undefined,
    };
  }

  private collection(name: string) {
    return {
      doc: (id?: string) => {
        const ref = this.ref(name, id ?? `auto-${++this.nextDocumentId}`);
        return {
          ...ref,
          get: async () => this.snapshot(ref),
        };
      },
      where: (field: string, _operator: string, value: unknown) => ({
        limit: (limit: number) => ({
          get: async () => {
            const entries = [...this.bucket(name).entries()]
              .filter(([, data]) => data[field] === value)
              .slice(0, limit);
            const docs = entries.map(([id]) => this.snapshot(this.ref(name, id)));
            const hook = this.afterNextQuery;
            this.afterNextQuery = null;
            hook?.();
            return { docs, size: docs.length, empty: docs.length === 0 };
          },
        }),
      }),
    };
  }

  private apply(operation: Operation): void {
    const bucket = this.bucket(operation.ref.__collection);
    if (operation.kind === "delete") {
      bucket.delete(operation.ref.id);
      return;
    }
    const current = bucket.get(operation.ref.id);
    if (operation.kind === "create" && current) {
      throw new Error(`Document already exists: ${operation.ref.path}`);
    }
    if (operation.kind === "update" && !current) {
      throw new Error(`Document does not exist: ${operation.ref.path}`);
    }
    bucket.set(
      operation.ref.id,
      operation.kind === "update"
        ? { ...current, ...operation.data }
        : { ...operation.data }
    );
  }

  private batch() {
    const operations: Operation[] = [];
    return {
      delete: (ref: Ref) => operations.push({ kind: "delete", ref }),
      update: (ref: Ref, data: Data) =>
        operations.push({ kind: "update", ref, data }),
      set: (ref: Ref, data: Data) =>
        operations.push({ kind: "set", ref, data }),
      commit: async () => {
        if (this.failNextBatch) {
          this.failNextBatch = false;
          throw new Error("batch failed");
        }
        operations.forEach((operation) => this.apply(operation));
      },
    };
  }

  private async runTransaction<T>(
    handler: (transaction: {
      get: (ref: Ref) => Promise<ReturnType<FirestoreHarness["snapshot"]>>;
      create: (ref: Ref, data: Data) => void;
      set: (ref: Ref, data: Data) => void;
      update: (ref: Ref, data: Data) => void;
      delete: (ref: Ref) => void;
    }) => Promise<T>
  ): Promise<T> {
    if (this.failNextTransaction) {
      this.failNextTransaction = false;
      throw new Error("transaction failed");
    }
    const operations: Operation[] = [];
    const result = await handler({
      get: async (ref) => this.snapshot(ref),
      create: (ref, data) => operations.push({ kind: "create", ref, data }),
      set: (ref, data) => operations.push({ kind: "set", ref, data }),
      update: (ref, data) => operations.push({ kind: "update", ref, data }),
      delete: (ref) => operations.push({ kind: "delete", ref }),
    });
    operations.forEach((operation) => this.apply(operation));
    return result;
  }
}

class AuthHarness implements AccountDeletionAuth {
  exists = true;
  disabled = false;
  updateCalls = 0;
  deleteCalls = 0;

  async updateUser(uid: string, properties: { disabled: boolean }) {
    assert.ok(uid);
    this.updateCalls++;
    if (!this.exists) throw Object.assign(new Error("missing"), { code: "auth/user-not-found" });
    this.disabled = properties.disabled;
    return { uid };
  }

  async deleteUser(uid: string): Promise<void> {
    assert.ok(uid);
    this.deleteCalls++;
    if (!this.exists) throw Object.assign(new Error("missing"), { code: "auth/user-not-found" });
    this.exists = false;
  }
}

const BASE_TIME = admin.firestore.Timestamp.fromMillis(Date.UTC(2026, 7, 25, 20));

function makeClock() {
  let tick = 0;
  return () => admin.firestore.Timestamp.fromMillis(BASE_TIME.toMillis() + tick++);
}

function job(phase: AccountDeletionPhase, timestamp = BASE_TIME): Data {
  return {
    schemaVersion: 1,
    phase,
    requestedAt: timestamp,
    updatedAt: timestamp,
  };
}

describe("account deletion recovery", () => {
  let db: FirestoreHarness;
  let auth: AuthHarness;
  let now: () => admin.firestore.Timestamp;

  beforeEach(() => {
    db = new FirestoreHarness();
    auth = new AuthHarness();
    now = makeClock();
  });

  it("preserves generated detail for every known operator audit action", () => {
    for (const action of [
      "ban",
      "unban",
      "promote",
      "demote",
      "remove-evidence",
      "hide",
      "unhide",
      "remove",
      "merge_chants",
    ]) {
      assert.deepStrictEqual(
        auditRedactionForDeletedActor({
          actorId: "fan",
          action,
          targetId: "target",
          detail: "Generated operator detail.",
        }, "fan"),
        { actorId: "deleted-operator" },
        action
      );
    }
  });

  it("creates the exact durable job and pending marker in one request", async () => {
    db.set("profiles", "fan", { displayName: "Fan", banned: false });

    const result = await requestAccountDeletion({
      uid: "fan",
      data: {},
      firestore: db.firestore,
      now,
    });

    assert.deepStrictEqual(result, { accepted: true, success: true });
    assert.deepStrictEqual(Object.keys(db.get("accountDeletionJobs", "fan")!).sort(), [
      "phase", "requestedAt", "schemaVersion", "updatedAt",
    ]);
    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "disable-auth");
    assert.strictEqual(db.get("profiles", "fan")!.deletionPending, true);
  });

  it("accepts missing-profile cleanup and rejects every nonempty payload", async () => {
    await requestAccountDeletion({
      uid: "partial-signup",
      data: {},
      firestore: db.firestore,
      now,
    });
    assert.ok(db.get("accountDeletionJobs", "partial-signup"));

    await assert.rejects(
      requestAccountDeletion({
        uid: "fan",
        data: { uid: "victim" },
        firestore: db.firestore,
        now,
      }),
      (error: { code?: string }) => error.code === "invalid-argument"
    );
  });

  it("duplicate request preserves progress and repairs the pending marker", async () => {
    const requestedAt = admin.firestore.Timestamp.fromMillis(1234);
    db.set("accountDeletionJobs", "fan", job("delete-feedback", requestedAt));
    db.set("profiles", "fan", { deletionPending: false });

    await requestAccountDeletion({
      uid: "fan",
      data: {},
      firestore: db.firestore,
      now,
    });

    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "delete-feedback");
    assert.strictEqual(
      (db.get("accountDeletionJobs", "fan")!.requestedAt as admin.firestore.Timestamp).toMillis(),
      1234
    );
    assert.strictEqual(db.get("profiles", "fan")!.deletionPending, true);
  });

  it("processes deletion pages at 200 rows and resumes until empty", async () => {
    db.set("accountDeletionJobs", "fan", job("delete-votes"));
    for (let index = 0; index < ACCOUNT_DELETION_PAGE_SIZE + 5; index++) {
      db.set("votes", `vote-${index}`, { userId: "fan", chantId: `chant-${index}` });
    }

    const first = await processAccountDeletionStep({
      uid: "fan", firestore: db.firestore, auth, now,
    });
    assert.strictEqual(first?.processed, ACCOUNT_DELETION_PAGE_SIZE);
    assert.strictEqual(db.size("votes"), 5);
    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "delete-votes");

    const second = await processAccountDeletionStep({
      uid: "fan", firestore: db.firestore, auth, now,
    });
    assert.strictEqual(second?.processed, 5);
    assert.strictEqual(db.size("votes"), 0);

    const third = await processAccountDeletionStep({
      uid: "fan", firestore: db.firestore, auth, now,
    });
    assert.strictEqual(third?.advanced, true);
    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "delete-chant-reports");
  });

  it("anonymizes retained comments without changing relationships", async () => {
    db.set("accountDeletionJobs", "fan", job("anonymize-comments"));
    db.set("comments", "reply", {
      userId: "fan",
      displayName: "Fan",
      chantId: "chant",
      parentCommentId: "parent",
      body: "Keep me",
    });

    await processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now });

    assert.deepStrictEqual(db.get("comments", "reply"), {
      userId: "deleted-user",
      displayName: "Deleted user",
      chantId: "chant",
      parentCommentId: "parent",
      body: "Keep me",
    });
  });

  it("advances every empty page phase in order", async () => {
    const pagePhases = [
      "delete-votes",
      "delete-chant-reports",
      "delete-feedback",
      "anonymize-chants",
      "anonymize-comments",
      "delete-comment-likes",
      "delete-comment-reports",
      "delete-user-reports-by",
      "delete-user-reports-against",
      "delete-blocks-by",
      "delete-blocks-against",
      "anonymize-audit-by",
    ] as const;

    for (const phase of pagePhases) {
      db.set("accountDeletionJobs", "fan", job(phase));
      const result = await processAccountDeletionStep({
        uid: "fan", firestore: db.firestore, auth, now,
      });
      const expected = ACCOUNT_DELETION_PHASES[ACCOUNT_DELETION_PHASES.indexOf(phase) + 1];
      assert.strictEqual(result?.advanced, true, phase);
      assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, expected, phase);
    }
  });

  it("does not regress a phase when a stale empty-page event races", async () => {
    db.set("accountDeletionJobs", "fan", job("delete-feedback"));
    db.afterNextQuery = () => {
      db.set("accountDeletionJobs", "fan", job("anonymize-chants"));
    };

    const result = await processAccountDeletionStep({
      uid: "fan", firestore: db.firestore, auth, now,
    });

    assert.strictEqual(result?.advanced, false);
    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "anonymize-chants");
  });

  it("retains the job and data when a page batch fails", async () => {
    db.set("accountDeletionJobs", "fan", job("delete-votes"));
    db.set("votes", "vote", { userId: "fan" });
    db.failNextBatch = true;

    await assert.rejects(
      processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now }),
      /batch failed/
    );
    assert.ok(db.get("votes", "vote"));
    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "delete-votes");
  });

  it("classifies audit pages and writes exactly one non-identifying completion audit", async () => {
    db.set("accountDeletionJobs", "fan", job("disable-auth"));
    await processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now });
    assert.strictEqual(auth.disabled, true);
    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "delete-votes");

    db.set("accountDeletionJobs", "fan", job("delete-safety-rate"));
    db.set("safetyRateLimits", "fan", { reportCount: 10 });
    await processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now });
    assert.strictEqual(db.get("safetyRateLimits", "fan"), undefined);

    db.set("accountDeletionJobs", "fan", job("anonymize-audit-by"));
    for (let index = 0; index < ACCOUNT_DELETION_PAGE_SIZE - 3; index++) {
      db.set("auditLog", `report-${index}`, {
        actorId: "fan",
        action: "report",
        targetId: `chant-${index}`,
        detail: `Reason: private text ${index}`,
      });
    }
    db.set("auditLog", "operator-action", {
      actorId: "fan",
      action: "hide",
      targetType: "chant",
      targetId: "chant-moderated",
      detail: "Chant hidden by operator.",
    });
    db.set("auditLog", "policy-acceptance", {
      actorId: "fan",
      action: "accept-policy",
      targetType: "user",
      targetId: "fan",
      detail: "Accepted content policy version v1.",
    });
    db.set("auditLog", "unknown-action", {
      actorId: "fan",
      action: "legacy-free-text",
      targetType: "user",
      targetId: "another-user",
      detail: "Potentially user-authored text.",
    });
    db.set("auditLog", "report-final-page", {
      actorId: "fan",
      action: "report-user",
      targetId: "reported-user",
      detail: "Reason: final private text",
    });

    await processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now });
    assert.strictEqual(db.get("auditLog", "report-0")!.actorId, "deleted-user");
    assert.strictEqual(
      db.get("auditLog", "report-0")!.detail,
      "Report details removed during account deletion."
    );
    assert.strictEqual(
      [...Array(ACCOUNT_DELETION_PAGE_SIZE - 3).keys()].some((index) =>
        String(db.get("auditLog", `report-${index}`)!.detail).includes("private text")
      ),
      false
    );
    assert.deepStrictEqual(db.get("auditLog", "operator-action"), {
      actorId: "deleted-operator",
      action: "hide",
      targetType: "chant",
      targetId: "chant-moderated",
      detail: "Chant hidden by operator.",
    });
    assert.deepStrictEqual(db.get("auditLog", "policy-acceptance"), {
      actorId: "deleted-user",
      action: "accept-policy",
      targetType: "user",
      targetId: "deleted-user",
      detail: "Accepted content policy version v1.",
    });
    assert.deepStrictEqual(db.get("auditLog", "unknown-action"), {
      actorId: "deleted-user",
      action: "legacy-free-text",
      targetType: "user",
      targetId: "another-user",
      detail: "Details removed during account deletion.",
    });
    assert.strictEqual(db.get("auditLog", "report-final-page")!.actorId, "fan");

    await processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now });
    assert.strictEqual(
      db.get("auditLog", "report-final-page")!.detail,
      "Report details removed during account deletion."
    );
    await processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now });
    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "write-audit");

    await processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now });
    assert.strictEqual(db.size("auditLog"), ACCOUNT_DELETION_PAGE_SIZE + 2);
    const completion = db.get("auditLog", "auto-1")!;
    assert.strictEqual(completion.actorId, "system");
    assert.strictEqual(completion.targetId, "deleted-user");
    assert.strictEqual(JSON.stringify(completion).includes("fan"), false);
    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "delete-auth");

    await processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now });
    assert.strictEqual(db.size("auditLog"), ACCOUNT_DELETION_PAGE_SIZE + 2);
  });

  it("recovers after Auth deletion and finalization failures", async () => {
    db.set("accountDeletionJobs", "fan", job("delete-auth"));
    db.set("profiles", "fan", { deletionPending: true });
    db.failNextTransaction = true;

    await assert.rejects(
      processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now }),
      /transaction failed/
    );
    assert.strictEqual(auth.exists, false);
    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "delete-auth");

    await processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now });
    assert.strictEqual(db.get("accountDeletionJobs", "fan")!.phase, "finalize");

    db.failNextTransaction = true;
    await assert.rejects(
      processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now }),
      /transaction failed/
    );
    assert.ok(db.get("profiles", "fan"));
    assert.ok(db.get("accountDeletionJobs", "fan"));

    const result = await processAccountDeletionStep({
      uid: "fan", firestore: db.firestore, auth, now,
    });
    assert.strictEqual(result?.complete, true);
    assert.strictEqual(db.get("profiles", "fan"), undefined);
    assert.strictEqual(db.get("accountDeletionJobs", "fan"), undefined);
  });

  it("fails closed on a malformed server-owned job", async () => {
    db.set("accountDeletionJobs", "fan", {
      schemaVersion: 99,
      phase: "delete-auth",
      requestedAt: BASE_TIME,
      updatedAt: BASE_TIME,
    });

    await assert.rejects(
      processAccountDeletionStep({ uid: "fan", firestore: db.firestore, auth, now }),
      /Malformed account deletion job/
    );
    assert.strictEqual(auth.deleteCalls, 0);
    assert.ok(db.get("accountDeletionJobs", "fan"));
  });
});
