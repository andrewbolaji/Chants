import { describe, it, beforeEach } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { handleVoteWritten } from "../src/index";

// --- In-memory Firestore stub with batch recorder and vote store ---

interface StagedWrite {
  path: string;
  data: Record<string, unknown>;
}

interface BatchCommit {
  writes: StagedWrite[];
}

let batchCommits: BatchCommit[] = [];
let standaloneWrites: StagedWrite[] = [];
let chantExists = true;
let voteQueryReads = 0;

// In-memory vote store for where().get() queries.
// Keyed by doc id. Each entry has { value, chantId, userId }.
let voteStore: Record<string, Record<string, unknown>> = {};

function makeFakeFirestore(): admin.firestore.Firestore {
  const fakeDocRefWithPath = (path: string) => {
    const ref = {
      __path: path,
    };
    return ref;
  };

  const fakeCollectionWithPath = (name: string) => ({
    doc: (id: string) => fakeDocRefWithPath(`${name}/${id}`),
    where: (field: string, _op: string, value: unknown) => ({
      __query: { name, field, value },
    }),
  });

  const runTransaction = async (
    handler: (transaction: {
      get: (target: Record<string, unknown>) => Promise<unknown>;
      update: (ref: Record<string, unknown>, data: Record<string, unknown>) => void;
    }) => Promise<unknown>
  ) => {
    const staged: StagedWrite[] = [];
    const result = await handler({
      get: async (target: Record<string, unknown>) => {
        const query = target.__query as {
          name: string;
          field: string;
          value: unknown;
        } | undefined;
        if (query) {
          voteQueryReads++;
          const docs = Object.entries(voteStore)
            .filter(([, data]) => data[query.field] === query.value)
            .map(([id, data]) => ({ id, data: () => ({ ...data }) }));
          return { docs };
        }
        const path = target.__path as string;
        const [collection, id] = path.split("/");
        if (collection === "chants") {
          return { exists: chantExists, data: () => undefined };
        }
        const data = collection === "votes" ? voteStore[id] : undefined;
        return {
          exists: data !== undefined,
          data: () => data === undefined ? undefined : { ...data },
        };
      },
      update: (ref: Record<string, unknown>, data: Record<string, unknown>) => {
        staged.push({ path: ref.__path as string, data });
      },
    });
    if (staged.length > 0) batchCommits.push({ writes: [...staged] });
    for (const write of staged) {
      const [collection, id] = write.path.split("/");
      if (collection === "votes" && voteStore[id]) {
        Object.assign(voteStore[id], write.data);
      }
    }
    return result;
  };

  return {
    collection: fakeCollectionWithPath,
    runTransaction,
  } as unknown as admin.firestore.Firestore;
}

const fakeDb = makeFakeFirestore();

describe("handleVoteWritten", () => {
  beforeEach(() => {
    batchCommits = [];
    standaloneWrites = [];
    voteStore = {};
    chantExists = true;
    voteQueryReads = 0;
  });

  it("CREATE: recomputes counters from vote store and stamps appliedValue atomically", async () => {
    // The vote doc now exists in the store (the write that triggered this event)
    voteStore["user1_chant1"] = { value: -1, chantId: "chant1", userId: "user1" };

    await handleVoteWritten(
      undefined, // no before (create)
      { value: -1, chantId: "chant1", userId: "user1" },
      "user1_chant1",
      fakeDb
    );

    assert.strictEqual(standaloneWrites.length, 0,
      "Must not have standalone writes; all writes must be batched");
    assert.strictEqual(batchCommits.length, 1,
      "Expected exactly one batch commit");

    const commit = batchCommits[0];
    assert.strictEqual(commit.writes.length, 2,
      "Batch must contain exactly 2 writes (chant + vote)");

    const chantWrite = commit.writes.find((w) => w.path === "chants/chant1");
    assert.ok(chantWrite, "Batch must contain chant counter update");
    assert.strictEqual(chantWrite!.data.upvotes, 0);
    assert.strictEqual(chantWrite!.data.downvotes, 1);
    assert.strictEqual(chantWrite!.data.score, -1);

    const voteWrite = commit.writes.find((w) => w.path === "votes/user1_chant1");
    assert.ok(voteWrite, "Batch must contain appliedValue write");
    assert.strictEqual(voteWrite!.data.appliedValue, -1);
  });

  it("UPDATE (flip): recomputes and stamps appliedValue with new value", async () => {
    // After the flip, the vote doc has value 1
    voteStore["user1_chant1"] = { value: 1, chantId: "chant1", userId: "user1" };

    await handleVoteWritten(
      { value: -1, chantId: "chant1", userId: "user1" },
      { value: 1, chantId: "chant1", userId: "user1" },
      "user1_chant1",
      fakeDb
    );

    assert.strictEqual(standaloneWrites.length, 0);
    assert.strictEqual(batchCommits.length, 1);

    const commit = batchCommits[0];
    assert.strictEqual(commit.writes.length, 2);

    const chantWrite = commit.writes.find((w) => w.path === "chants/chant1");
    assert.ok(chantWrite);
    assert.strictEqual(chantWrite!.data.upvotes, 1);
    assert.strictEqual(chantWrite!.data.downvotes, 0);
    assert.strictEqual(chantWrite!.data.score, 1);

    const voteWrite = commit.writes.find((w) => w.path === "votes/user1_chant1");
    assert.ok(voteWrite, "Expected appliedValue write in batch");
    assert.strictEqual(voteWrite!.data.appliedValue, 1,
      "appliedValue must be the NEW value after a flip");
  });

  it("DELETE: recomputes counters (excluding deleted vote), no appliedValue", async () => {
    // The vote doc is gone (deleted before this trigger fires).
    // voteStore is empty for this chant.

    await handleVoteWritten(
      { value: -1, chantId: "chant1", userId: "user1" },
      undefined, // no after (delete)
      "user1_chant1",
      fakeDb
    );

    assert.strictEqual(standaloneWrites.length, 0);
    assert.strictEqual(batchCommits.length, 1);

    const commit = batchCommits[0];
    assert.strictEqual(commit.writes.length, 1,
      "Delete batch must contain only the chant counter update");

    const chantWrite = commit.writes.find((w) => w.path === "chants/chant1");
    assert.ok(chantWrite, "Expected chant counter update in batch");
    assert.strictEqual(chantWrite!.data.upvotes, 0);
    assert.strictEqual(chantWrite!.data.downvotes, 0);
    assert.strictEqual(chantWrite!.data.score, 0);

    const voteWrite = commit.writes.find((w) => w.path === "votes/user1_chant1");
    assert.strictEqual(voteWrite, undefined,
      "Must not write appliedValue on a deleted vote doc");
  });

  it("NO-OP: re-trigger (same value) stages NOTHING and commits nothing", async () => {
    await handleVoteWritten(
      { value: -1, chantId: "chant1", userId: "user1" },
      { value: -1, chantId: "chant1", userId: "user1", appliedValue: -1 },
      "user1_chant1",
      fakeDb
    );

    assert.strictEqual(batchCommits.length, 0,
      "Re-trigger with unchanged value must not create any batch");
    assert.strictEqual(standaloneWrites.length, 0,
      "Re-trigger with unchanged value must produce zero writes");
    assert.strictEqual(voteQueryReads, 0,
      "Re-trigger with unchanged value must not query vote ground truth");
  });

  it("MISSING PARENT: returns before querying votes or staging writes", async () => {
    chantExists = false;
    voteStore["user1_chant1"] = {
      value: 1,
      chantId: "chant1",
      userId: "user1",
    };

    await handleVoteWritten(
      undefined,
      { value: 1, chantId: "chant1", userId: "user1" },
      "user1_chant1",
      fakeDb
    );

    assert.strictEqual(voteQueryReads, 0,
      "A deleted parent must stop before the vote query");
    assert.strictEqual(batchCommits.length, 0,
      "A deleted parent must not create or commit a batch");
    assert.strictEqual(standaloneWrites.length, 0,
      "A deleted parent must not receive any standalone write");
  });

  it("IDEMPOTENCY: duplicate delivery of the same create produces correct counters both times", async () => {
    voteStore["user1_chant1"] = { value: 1, chantId: "chant1", userId: "user1" };

    const payload = {
      before: undefined,
      after: { value: 1, chantId: "chant1", userId: "user1" },
    };

    // First delivery
    await handleVoteWritten(payload.before, payload.after, "user1_chant1", fakeDb);
    // Second delivery (duplicate)
    await handleVoteWritten(payload.before, payload.after, "user1_chant1", fakeDb);

    assert.strictEqual(batchCommits.length, 2,
      "Both deliveries run (no dedup needed, recompute is safe)");

    // Both must write the same absolute values
    for (let i = 0; i < 2; i++) {
      const chantWrite = batchCommits[i].writes.find((w) => w.path === "chants/chant1");
      assert.ok(chantWrite, `Delivery ${i + 1} must update chant`);
      assert.strictEqual(chantWrite!.data.upvotes, 1,
        `Delivery ${i + 1}: upvotes must be 1 (not accumulated)`);
      assert.strictEqual(chantWrite!.data.downvotes, 0,
        `Delivery ${i + 1}: downvotes must be 0`);
      assert.strictEqual(chantWrite!.data.score, 1,
        `Delivery ${i + 1}: score must be 1 (not 2)`);
    }
  });

  it("BURST: rapid flips all converge to the same correct counters", async () => {
    // Final state after a burst of flips: user ended on value -1
    voteStore["user1_chant1"] = { value: -1, chantId: "chant1", userId: "user1" };

    // Simulate 4 rapid events: create(1), flip(1->-1), flip(-1->1), flip(1->-1)
    const events = [
      { before: undefined, after: { value: 1, chantId: "chant1", userId: "user1" } },
      { before: { value: 1, chantId: "chant1", userId: "user1" }, after: { value: -1, chantId: "chant1", userId: "user1" } },
      { before: { value: -1, chantId: "chant1", userId: "user1" }, after: { value: 1, chantId: "chant1", userId: "user1" } },
      { before: { value: 1, chantId: "chant1", userId: "user1" }, after: { value: -1, chantId: "chant1", userId: "user1" } },
    ];

    for (const e of events) {
      await handleVoteWritten(e.before, e.after, "user1_chant1", fakeDb);
    }

    assert.strictEqual(batchCommits.length, 4,
      "Each event fires (recompute is safe for all)");

    // Every single invocation must write the same correct absolute values,
    // because they all recompute from the same vote store (final state: -1).
    for (let i = 0; i < 4; i++) {
      const chantWrite = batchCommits[i].writes.find((w) => w.path === "chants/chant1");
      assert.ok(chantWrite, `Event ${i + 1} must update chant`);
      assert.strictEqual(chantWrite!.data.upvotes, 0,
        `Event ${i + 1}: upvotes must be 0`);
      assert.strictEqual(chantWrite!.data.downvotes, 1,
        `Event ${i + 1}: downvotes must be 1`);
      assert.strictEqual(chantWrite!.data.score, -1,
        `Event ${i + 1}: score must be -1`);
    }
  });

  it("CONCURRENCY: an older transaction retries after a newer aggregate commits", async () => {
    const votes: Record<string, Record<string, unknown>> = {
      user1_chant1: { value: 1, chantId: "chant1", userId: "user1" },
    };
    let parentVersion = 0;
    let storedScore = 0;
    let firstAttempt = true;
    let releaseOlder: () => void = () => undefined;
    const olderCanCommit = new Promise<void>((resolve) => {
      releaseOlder = resolve;
    });
    let olderReadComplete: () => void = () => undefined;
    const olderHasRead = new Promise<void>((resolve) => {
      olderReadComplete = resolve;
    });
    let invocation = 0;
    let olderAttempts = 0;

    const collection = (name: string) => ({
      doc: (id: string) => ({ __path: `${name}/${id}` }),
      where: (field: string, _op: string, value: unknown) => ({
        __query: { name, field, value },
      }),
    });
    const firestore = {
      collection,
      runTransaction: async (handler: (transaction: {
        get: (target: Record<string, unknown>) => Promise<unknown>;
        update: (ref: Record<string, unknown>, data: Record<string, unknown>) => void;
      }) => Promise<unknown>) => {
        const currentInvocation = ++invocation;
        while (true) {
          if (currentInvocation === 1) olderAttempts++;
          const readVersion = parentVersion;
          const writes: StagedWrite[] = [];
          const result = await handler({
            get: async (target: Record<string, unknown>) => {
              const query = target.__query as {
                field: string;
                value: unknown;
              } | undefined;
              if (query) {
                const docs = Object.entries(votes)
                  .filter(([, data]) => data[query.field] === query.value)
                  .map(([id, data]) => ({ id, data: () => ({ ...data }) }));
                if (currentInvocation === 1 && firstAttempt) {
                  firstAttempt = false;
                  olderReadComplete();
                  await olderCanCommit;
                }
                return { docs };
              }
              const path = target.__path as string;
              if (path.startsWith("chants/")) {
                return { exists: true, data: () => ({ score: storedScore }) };
              }
              const [, id] = path.split("/");
              const data = votes[id];
              return {
                exists: data !== undefined,
                data: () => data === undefined ? undefined : { ...data },
              };
            },
            update: (ref, data) => writes.push({
              path: ref.__path as string,
              data,
            }),
          });
          if (parentVersion !== readVersion) continue;
          const parentWrite = writes.find((write) => write.path === "chants/chant1");
          if (parentWrite) {
            storedScore = parentWrite.data.score as number;
            parentVersion++;
          }
          return result;
        }
      },
    } as unknown as admin.firestore.Firestore;

    const older = handleVoteWritten(
      undefined,
      { value: 1, chantId: "chant1", userId: "user1" },
      "user1_chant1",
      firestore
    );
    await olderHasRead;
    votes.user2_chant1 = { value: 1, chantId: "chant1", userId: "user2" };
    await handleVoteWritten(
      undefined,
      { value: 1, chantId: "chant1", userId: "user2" },
      "user2_chant1",
      firestore
    );
    releaseOlder();
    await older;

    assert.strictEqual(storedScore, 2);
    assert.strictEqual(olderAttempts, 2,
      "the transaction that read one vote must retry after the parent changed");
  });
});
