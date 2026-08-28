import { describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import {
  handleSetCreatorFollow,
  parseCreatorFollow,
  recomputeCreatorFollowCounts,
} from "../src/creator_follow";
import {
  handleMarkCreatorNotificationRead,
  parseNotificationId,
} from "../src/creator_notification";

type Data = Record<string, unknown>;
type Ref = { collectionName: string; id: string };
type QueryRef = {
  collectionName: string;
  filters: Array<{ field: string; value: unknown }>;
  where: (field: string, operator: string, value: unknown) => QueryRef;
};

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
    const value = this.bucket(collection).get(id);
    return value ? { ...value } : undefined;
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
    const value = this.bucket(ref.collectionName).get(ref.id);
    return {
      exists: value !== undefined,
      id: ref.id,
      data: () => value ? { ...value } : undefined,
    };
  }

  private query(collectionName: string, filters: QueryRef["filters"] = []): QueryRef {
    return {
      collectionName,
      filters,
      where: (field, operator, value) => {
        if (operator !== "==") throw new Error("unsupported query");
        return this.query(collectionName, [...filters, { field, value }]);
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

  private async runTransaction<T>(handler: (transaction: {
    get: (target: Ref | QueryRef) => Promise<unknown>;
    create: (ref: Ref, data: Data) => void;
    update: (ref: Ref, data: Data) => void;
    delete: (ref: Ref) => void;
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
      update: (ref, data) => operations.push(() => {
        const before = this.bucket(ref.collectionName).get(ref.id);
        if (!before) throw new Error("document missing");
        this.bucket(ref.collectionName).set(ref.id, { ...before, ...data });
      }),
      delete: (ref) => operations.push(() => {
        this.bucket(ref.collectionName).delete(ref.id);
      }),
    });
    operations.forEach((operation) => operation());
    return result;
  }
}

const NOW = admin.firestore.Timestamp.fromMillis(Date.UTC(2026, 7, 28, 12));

function activeAccount(): Data {
  return {
    banned: false,
    ageConfirmed17Plus: true,
    acceptedPolicyVersion: "v1",
    deletionPending: false,
  };
}

function creator(handle: string): Data {
  return {
    handle,
    displayName: handle,
    followerCount: 0,
    followingCount: 0,
    hidden: false,
    removed: false,
  };
}

function seed(db: FirestoreHarness): void {
  db.set("profiles", "fan", activeAccount());
  db.set("creatorProfiles", "fan", creator("fan_handle"));
  db.set("creatorProfiles", "target", creator("target_handle"));
}

describe("creator follows", () => {
  it("accepts only an exact target and boolean intent", () => {
    assert.deepStrictEqual(
      parseCreatorFollow({ targetCreatorId: "target", following: true }),
      { targetCreatorId: "target", following: true }
    );
    assert.throws(
      () => parseCreatorFollow({ targetCreatorId: "target", following: true, uid: "fan" }),
      (error: unknown) => error instanceof HttpsError && error.code === "invalid-argument"
    );
  });

  it("creates one private edge and one recipient notification idempotently", async () => {
    const db = new FirestoreHarness();
    seed(db);
    const call = () => handleSetCreatorFollow({
      uid: "fan",
      data: { targetCreatorId: "target", following: true },
      firestore: db.firestore,
      now: () => NOW,
    });

    assert.deepStrictEqual(await call(), { following: true, changed: true });
    assert.deepStrictEqual(await call(), { following: true, changed: false });
    assert.deepStrictEqual(db.get("creatorFollows", "fan_target"), {
      schemaVersion: 1,
      followerId: "fan",
      followedId: "target",
      createdAt: NOW,
    });
    assert.deepStrictEqual(db.get("creatorNotifications", "follow_fan_target"), {
      schemaVersion: 1,
      ownerId: "target",
      actorId: "fan",
      actorHandle: "fan_handle",
      actorDisplayName: "fan_handle",
      type: "creator_follow",
      performanceId: null,
      commentId: null,
      read: false,
      createdAt: NOW,
      readAt: null,
    });
  });

  it("removes the edge idempotently without erasing the historical inbox event", async () => {
    const db = new FirestoreHarness();
    seed(db);
    db.set("creatorFollows", "fan_target", {
      schemaVersion: 1,
      followerId: "fan",
      followedId: "target",
      createdAt: NOW,
    });
    db.set("creatorNotifications", "follow_fan_target", { ownerId: "target" });
    const result = await handleSetCreatorFollow({
      uid: "fan",
      data: { targetCreatorId: "target", following: false },
      firestore: db.firestore,
      now: () => NOW,
    });
    assert.deepStrictEqual(result, { following: false, changed: true });
    assert.strictEqual(db.get("creatorFollows", "fan_target"), undefined);
    assert.ok(db.get("creatorNotifications", "follow_fan_target"));
  });

  it("rejects self-follow, blocks, hidden creators, and deleting actors", async () => {
    const selfDb = new FirestoreHarness();
    seed(selfDb);
    await assert.rejects(
      handleSetCreatorFollow({
        uid: "fan",
        data: { targetCreatorId: "fan", following: true },
        firestore: selfDb.firestore,
        now: () => NOW,
      }),
      (error: unknown) => error instanceof HttpsError && error.code === "invalid-argument"
    );

    const blockedDb = new FirestoreHarness();
    seed(blockedDb);
    blockedDb.set("blocks", "target_fan", { blockerId: "target", blockedUserId: "fan" });
    await assert.rejects(
      handleSetCreatorFollow({
        uid: "fan",
        data: { targetCreatorId: "target", following: true },
        firestore: blockedDb.firestore,
        now: () => NOW,
      }),
      (error: unknown) => error instanceof HttpsError && error.code === "permission-denied"
    );

    const hiddenDb = new FirestoreHarness();
    seed(hiddenDb);
    hiddenDb.set("creatorProfiles", "target", {
      ...creator("target_handle"), hidden: true,
    });
    await assert.rejects(handleSetCreatorFollow({
      uid: "fan",
      data: { targetCreatorId: "target", following: true },
      firestore: hiddenDb.firestore,
      now: () => NOW,
    }));

    const deletingDb = new FirestoreHarness();
    seed(deletingDb);
    deletingDb.set("accountDeletionJobs", "fan", { phase: "disable-auth" });
    await assert.rejects(handleSetCreatorFollow({
      uid: "fan",
      data: { targetCreatorId: "target", following: true },
      firestore: deletingDb.firestore,
      now: () => NOW,
    }));
  });

  it("recomputes both public totals from stored edges", async () => {
    const db = new FirestoreHarness();
    seed(db);
    db.set("creatorFollows", "fan_target", {
      followerId: "fan", followedId: "target",
    });
    db.set("creatorFollows", "fan_other", {
      followerId: "fan", followedId: "other",
    });
    db.set("creatorFollows", "other_target", {
      followerId: "other", followedId: "target",
    });
    assert.strictEqual(await recomputeCreatorFollowCounts({
      before: undefined,
      after: { followerId: "fan", followedId: "target" },
      firestore: db.firestore,
      now: () => NOW,
    }), true);
    assert.strictEqual(db.get("creatorProfiles", "fan")?.followingCount, 2);
    assert.strictEqual(db.get("creatorProfiles", "target")?.followerCount, 2);
  });
});

describe("creator notifications", () => {
  it("accepts an exact ID and marks only the owner's row idempotently", async () => {
    assert.deepStrictEqual(parseNotificationId({ notificationId: "notice-1" }), {
      notificationId: "notice-1",
    });
    assert.throws(() => parseNotificationId({
      notificationId: "notice-1",
      ownerId: "fan",
    }));

    const db = new FirestoreHarness();
    db.set("profiles", "fan", activeAccount());
    db.set("creatorNotifications", "notice-1", {
      ownerId: "fan",
      read: false,
      readAt: null,
    });
    const call = () => handleMarkCreatorNotificationRead({
      uid: "fan",
      data: { notificationId: "notice-1" },
      firestore: db.firestore,
      now: () => NOW,
    });
    assert.deepStrictEqual(await call(), { read: true, changed: true });
    assert.deepStrictEqual(await call(), { read: true, changed: false });
    assert.strictEqual(db.get("creatorNotifications", "notice-1")?.read, true);
    assert.strictEqual(db.get("creatorNotifications", "notice-1")?.readAt, NOW);
  });

  it("does not disclose another creator's notification", async () => {
    const db = new FirestoreHarness();
    db.set("profiles", "fan", activeAccount());
    db.set("creatorNotifications", "notice-1", {
      ownerId: "target",
      read: false,
    });
    await assert.rejects(
      handleMarkCreatorNotificationRead({
        uid: "fan",
        data: { notificationId: "notice-1" },
        firestore: db.firestore,
        now: () => NOW,
      }),
      (error: unknown) => error instanceof HttpsError && error.code === "not-found"
    );
  });
});
