import { beforeEach, describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import {
  handleUpdateCreatorProfile,
  parseCreatorIdentity,
} from "../src/creator_profile";

type Data = Record<string, unknown>;
type Ref = { collection: string; id: string };
type Operation =
  | { kind: "set" | "update"; ref: Ref; data: Data }
  | { kind: "delete"; ref: Ref };

class FirestoreHarness {
  private readonly store = new Map<string, Map<string, Data>>();

  readonly firestore = {
    collection: (name: string) => ({
      doc: (id: string) => ({ collection: name, id }),
    }),
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

  private snapshot(ref: Ref) {
    const data = this.bucket(ref.collection).get(ref.id);
    return {
      exists: data !== undefined,
      data: () => data ? { ...data } : undefined,
    };
  }

  private apply(operation: Operation): void {
    const bucket = this.bucket(operation.ref.collection);
    if (operation.kind === "delete") {
      bucket.delete(operation.ref.id);
      return;
    }
    const previous = bucket.get(operation.ref.id);
    if (operation.kind === "update" && !previous) {
      throw new Error("Missing update target.");
    }
    bucket.set(
      operation.ref.id,
      operation.kind === "update"
        ? { ...previous, ...operation.data }
        : { ...operation.data }
    );
  }

  private async runTransaction<T>(
    handler: (transaction: {
      get: (ref: Ref) => Promise<ReturnType<FirestoreHarness["snapshot"]>>;
      set: (ref: Ref, data: Data) => void;
      update: (ref: Ref, data: Data) => void;
      delete: (ref: Ref) => void;
    }) => Promise<T>
  ): Promise<T> {
    const operations: Operation[] = [];
    const result = await handler({
      get: async (ref) => this.snapshot(ref),
      set: (ref, data) => operations.push({ kind: "set", ref, data }),
      update: (ref, data) => operations.push({ kind: "update", ref, data }),
      delete: (ref) => operations.push({ kind: "delete", ref }),
    });
    operations.forEach((operation) => this.apply(operation));
    return result;
  }
}

const NOW = admin.firestore.Timestamp.fromMillis(Date.UTC(2026, 7, 28));

function activeAccount(overrides: Data = {}): Data {
  return {
    displayName: "Old name",
    role: "user",
    banned: false,
    ageConfirmed17Plus: true,
    acceptedPolicyVersion: "v1",
    deletionPending: false,
    ...overrides,
  };
}

describe("creator profile identity", () => {
  let db: FirestoreHarness;

  beforeEach(() => {
    db = new FirestoreHarness();
    db.set("profiles", "fan", activeAccount());
  });

  it("normalizes the handle and rejects malformed or expanded payloads", () => {
    assert.deepStrictEqual(
      parseCreatorIdentity({
        displayName: " North Bank Leo ",
        handle: " NorthBankLeo ",
        bio: " Arsenal and away ends. ",
      }),
      {
        displayName: "North Bank Leo",
        handle: "northbankleo",
        bio: "Arsenal and away ends.",
      }
    );

    for (const payload of [
      { displayName: "Fan", handle: "ab", bio: "" },
      { displayName: "Fan", handle: "spaces fail", bio: "" },
      { displayName: "", handle: "valid_name", bio: "" },
      { displayName: "Fan", handle: "valid_name", bio: "x".repeat(161) },
      { displayName: "Fan", handle: "valid_name", bio: "", role: "operator" },
    ]) {
      assert.throws(
        () => parseCreatorIdentity(payload),
        (error: { code?: string }) => error.code === "invalid-argument"
      );
    }
  });

  it("creates one public allowlisted profile and one private reservation", async () => {
    const result = await handleUpdateCreatorProfile({
      uid: "fan",
      data: {
        displayName: "North Bank Leo",
        handle: "NorthBankLeo",
        bio: "Arsenal, away ends and bad ideas.",
      },
      firestore: db.firestore,
      now: () => NOW,
    });

    assert.deepStrictEqual(result, {
      displayName: "North Bank Leo",
      handle: "northbankleo",
      bio: "Arsenal, away ends and bad ideas.",
    });
    assert.deepStrictEqual(db.get("creatorHandles", "northbankleo"), {
      uid: "fan",
      handle: "northbankleo",
      createdAt: NOW,
      updatedAt: NOW,
    });
    assert.deepStrictEqual(db.get("creatorProfiles", "fan"), {
      handle: "northbankleo",
      displayName: "North Bank Leo",
      bio: "Arsenal, away ends and bad ideas.",
      followerCount: 0,
      followingCount: 0,
      performanceCount: 0,
      likeCount: 0,
      shareCount: 0,
      hidden: false,
      removed: false,
      createdAt: NOW,
      updatedAt: NOW,
    });
    assert.strictEqual(db.get("profiles", "fan")?.displayName, "North Bank Leo");
  });

  it("keeps case-insensitive handles unique without a partial profile write", async () => {
    db.set("creatorHandles", "clockend", {
      uid: "another-fan",
      handle: "clockend",
      createdAt: NOW,
      updatedAt: NOW,
    });

    await assert.rejects(
      handleUpdateCreatorProfile({
        uid: "fan",
        data: { displayName: "Fan", handle: "ClockEnd", bio: "" },
        firestore: db.firestore,
        now: () => NOW,
      }),
      (error: { code?: string }) => error.code === "already-exists"
    );
    assert.strictEqual(db.get("creatorProfiles", "fan"), undefined);
    assert.strictEqual(db.get("profiles", "fan")?.displayName, "Old name");
  });

  it("renames safely, releases only its old reservation, and preserves counters", async () => {
    db.set("creatorHandles", "oldhandle", { uid: "fan", createdAt: NOW });
    db.set("creatorProfiles", "fan", {
      handle: "oldhandle",
      displayName: "Old",
      bio: "Old bio",
      followerCount: 12,
      followingCount: 4,
      performanceCount: 3,
      likeCount: 99,
      shareCount: 18,
      hidden: true,
      removed: false,
      createdAt: NOW,
      updatedAt: NOW,
    });

    await handleUpdateCreatorProfile({
      uid: "fan",
      data: { displayName: "New", handle: "newhandle", bio: "New bio" },
      firestore: db.firestore,
      now: () => NOW,
    });

    assert.strictEqual(db.get("creatorHandles", "oldhandle"), undefined);
    assert.strictEqual(db.get("creatorHandles", "newhandle")?.uid, "fan");
    assert.strictEqual(db.get("creatorProfiles", "fan")?.followerCount, 12);
    assert.strictEqual(db.get("creatorProfiles", "fan")?.hidden, true);
  });

  it("makes a repeated same-handle save idempotent", async () => {
    const request = {
      uid: "fan",
      data: { displayName: "Fan", handle: "same_handle", bio: "Bio" },
      firestore: db.firestore,
      now: () => NOW,
    };
    await handleUpdateCreatorProfile(request);
    await handleUpdateCreatorProfile(request);

    assert.strictEqual(db.get("creatorHandles", "same_handle")?.uid, "fan");
    assert.strictEqual(db.get("creatorProfiles", "fan")?.handle, "same_handle");
  });

  it("rejects missing, banned, unconfirmed, unaccepted, and deleting accounts", async () => {
    const cases: Array<[string, Data | undefined, boolean]> = [
      ["missing", undefined, false],
      ["banned", activeAccount({ banned: true }), false],
      ["unconfirmed", activeAccount({ ageConfirmed17Plus: false }), false],
      ["unaccepted", activeAccount({ acceptedPolicyVersion: null }), false],
      ["pending", activeAccount({ deletionPending: true }), false],
      ["job", activeAccount(), true],
    ];

    for (const [uid, account, hasJob] of cases) {
      if (account) db.set("profiles", uid, account);
      if (hasJob) db.set("accountDeletionJobs", uid, { phase: "disable-auth" });
      await assert.rejects(
        handleUpdateCreatorProfile({
          uid,
          data: { displayName: "Fan", handle: `handle_${uid}`, bio: "" },
          firestore: db.firestore,
          now: () => NOW,
        })
      );
      assert.strictEqual(db.get("creatorProfiles", uid), undefined);
    }
  });
});
