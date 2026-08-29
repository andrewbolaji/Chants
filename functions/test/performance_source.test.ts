import * as assert from "assert";
import * as admin from "firebase-admin";
import {
  chantSourceChanged,
  currentChantSourceVisible,
  currentCreatorSourceVisible,
  handlePerformanceVisibilityWritten,
  performanceIsLive,
  reconcileChantPerformanceSource,
  reconcileCreatorPerformanceSource,
} from "../src/performance_source";

type Data = Record<string, unknown>;
type Ref = { collectionName: string; id: string; path: string };
type QueryRef = {
  collectionName: string;
  filters: Array<{ field: string; value: unknown }>;
  where: (field: string, operator: string, value: unknown) => QueryRef;
  get: () => Promise<QuerySnapshot>;
};
type Snapshot = {
  exists: boolean;
  id: string;
  ref: Ref;
  data: () => Data | undefined;
};
type QuerySnapshot = { docs: Snapshot[]; size: number; empty: boolean };

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

  private snapshot(ref: Ref): Snapshot {
    const data = this.bucket(ref.collectionName).get(ref.id);
    return {
      exists: data !== undefined,
      id: ref.id,
      ref,
      data: () => data ? { ...data } : undefined,
    };
  }

  private query(
    collectionName: string,
    filters: QueryRef["filters"] = [],
  ): QueryRef {
    const query: QueryRef = {
      collectionName,
      filters,
      where: (field, operator, value) => {
        if (operator !== "==") throw new Error(`Unsupported: ${operator}`);
        return this.query(collectionName, [...filters, { field, value }]);
      },
      get: async () => this.querySnapshot(query),
    };
    return query;
  }

  private querySnapshot(query: QueryRef): QuerySnapshot {
    const docs = [...this.bucket(query.collectionName).entries()]
      .filter(([, data]) => query.filters.every(
        (filter) => data[filter.field] === filter.value,
      ))
      .map(([id]) => this.snapshot(this.reference(query.collectionName, id)));
    return { docs, size: docs.length, empty: docs.length === 0 };
  }

  private collection(name: string) {
    return {
      doc: (id: string) => this.reference(name, id),
      where: (field: string, operator: string, value: unknown) =>
        this.query(name).where(field, operator, value),
    };
  }

  private update(ref: Ref, data: Data): void {
    const existing = this.bucket(ref.collectionName).get(ref.id);
    if (!existing) throw new Error(`Missing document: ${ref.path}`);
    this.bucket(ref.collectionName).set(ref.id, { ...existing, ...data });
  }

  private async runTransaction<T>(handler: (transaction: {
    get: (target: Ref | QueryRef) => Promise<Snapshot | QuerySnapshot>;
    update: (ref: Ref, data: Data) => void;
  }) => Promise<T>): Promise<T> {
    const updates: Array<{ ref: Ref; data: Data }> = [];
    const result = await handler({
      get: async (target) => "filters" in target
        ? this.querySnapshot(target)
        : this.snapshot(target),
      update: (ref, data) => updates.push({ ref, data }),
    });
    updates.forEach((update) => this.update(update.ref, update.data));
    return result;
  }
}

const NOW = admin.firestore.Timestamp.fromMillis(Date.UTC(2026, 7, 28, 16));

function livePerformance(overrides: Data = {}): Data {
  return {
    schemaVersion: 1,
    creatorId: "creator-1",
    chantId: "chant-1",
    publicationState: "approved",
    hidden: false,
    removed: false,
    sourceChantVisible: true,
    sourceCreatorVisible: true,
    ...overrides,
  };
}

describe("performance source authority", () => {
  it("derives current creator, chant, and live projection truth strictly", () => {
    assert.strictEqual(currentCreatorSourceVisible({
      account: { banned: false, deletionPending: false },
      creator: { hidden: false, removed: false },
      deletionJobExists: false,
    }), true);
    assert.strictEqual(currentCreatorSourceVisible({
      account: { banned: true },
      creator: { hidden: false, removed: false },
      deletionJobExists: false,
    }), false);
    assert.strictEqual(currentChantSourceVisible({
      status: "canonical",
      hidden: false,
      removed: false,
    }), true);
    assert.strictEqual(currentChantSourceVisible({
      status: "candidate",
      hidden: false,
      removed: false,
    }), false);
    assert.strictEqual(performanceIsLive(livePerformance()), true);
    assert.strictEqual(performanceIsLive(livePerformance({
      sourceCreatorVisible: false,
    })), false);
  });

  it("reconciles chant trust and availability into every dependent row", async () => {
    const db = new FirestoreHarness();
    db.set("creatorProfiles", "creator-1", { performanceCount: 999 });
    db.set("chants", "chant-1", {
      title: "Updated chant",
      status: "canonical",
      hidden: false,
      removed: false,
    });
    db.set("performances", "live", livePerformance());
    db.set("performances", "hidden", livePerformance({ hidden: true }));

    assert.strictEqual(await reconcileChantPerformanceSource({
      chantId: "chant-1",
      firestore: db.firestore,
      now: () => NOW,
    }), 2);
    assert.deepStrictEqual(
      {
        title: db.get("performances", "live")?.chantTitle,
        status: db.get("performances", "live")?.chantStatus,
        visible: db.get("performances", "live")?.sourceChantVisible,
        count: db.get("creatorProfiles", "creator-1")?.performanceCount,
      },
      { title: "Updated chant", status: "canonical", visible: true, count: 1 },
    );

    db.set("chants", "chant-1", {
      title: "Updated chant",
      status: "canonical",
      hidden: true,
      removed: false,
    });
    await reconcileChantPerformanceSource({
      chantId: "chant-1",
      firestore: db.firestore,
      now: () => NOW,
    });
    assert.strictEqual(
      db.get("creatorProfiles", "creator-1")?.performanceCount,
      0,
    );
  });

  it("reconciles creator takedown idempotently and repairs its live count", async () => {
    const db = new FirestoreHarness();
    db.set("profiles", "creator-1", { banned: true, deletionPending: false });
    db.set("creatorProfiles", "creator-1", {
      performanceCount: 2,
      hidden: true,
      removed: false,
    });
    db.set("performances", "one", livePerformance());
    db.set("performances", "two", livePerformance());

    for (let attempt = 0; attempt < 2; attempt++) {
      assert.strictEqual(await reconcileCreatorPerformanceSource({
        creatorId: "creator-1",
        firestore: db.firestore,
        now: () => NOW,
      }), 2);
    }
    assert.strictEqual(
      db.get("performances", "one")?.sourceCreatorVisible,
      false,
    );
    assert.strictEqual(
      db.get("creatorProfiles", "creator-1")?.performanceCount,
      0,
    );
  });

  it("derives every reconciliation from the latest stored source", async () => {
    const db = new FirestoreHarness();
    db.set("profiles", "creator-1", { banned: false, deletionPending: false });
    db.set("creatorProfiles", "creator-1", {
      performanceCount: 0,
      hidden: false,
      removed: false,
    });
    db.set("performances", "one", livePerformance({
      sourceCreatorVisible: false,
    }));

    await reconcileCreatorPerformanceSource({
      creatorId: "creator-1",
      firestore: db.firestore,
      now: () => NOW,
    });
    assert.strictEqual(
      db.get("performances", "one")?.sourceCreatorVisible,
      true,
    );

    db.set("profiles", "creator-1", { banned: true, deletionPending: false });
    await reconcileCreatorPerformanceSource({
      creatorId: "creator-1",
      firestore: db.firestore,
      now: () => NOW,
    });
    assert.strictEqual(
      db.get("performances", "one")?.sourceCreatorVisible,
      false,
    );
  });

  it("repairs counts only for lifecycle visibility changes, not counters", async () => {
    const db = new FirestoreHarness();
    db.set("creatorProfiles", "creator-1", { performanceCount: 0 });
    db.set("performances", "one", livePerformance());

    assert.strictEqual(await handlePerformanceVisibilityWritten({
      before: undefined,
      after: livePerformance(),
      firestore: db.firestore,
      now: () => NOW,
    }), true);
    assert.strictEqual(
      db.get("creatorProfiles", "creator-1")?.performanceCount,
      1,
    );
    assert.strictEqual(await handlePerformanceVisibilityWritten({
      before: livePerformance({ likeCount: 1 }),
      after: livePerformance({ likeCount: 2 }),
      firestore: db.firestore,
      now: () => NOW,
    }), false);
    assert.strictEqual(chantSourceChanged(
      { title: "Before", hidden: false },
      { title: "After", hidden: false },
    ), true);
  });
});
