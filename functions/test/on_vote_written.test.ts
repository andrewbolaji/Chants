import { describe, it, beforeEach } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { handleVoteWritten } from "../src/index";

// --- In-memory Firestore stub with batch recorder ---

interface StagedWrite {
  path: string;
  data: Record<string, unknown>;
}

interface BatchCommit {
  writes: StagedWrite[];
}

let batchCommits: BatchCommit[] = [];
let standaloneWrites: StagedWrite[] = [];

function makeFakeFirestore(): admin.firestore.Firestore {
  const fakeDocRef = (path: string) => ({
    update: (data: Record<string, unknown>) => {
      standaloneWrites.push({ path, data });
      return Promise.resolve();
    },
  });

  const fakeCollection = (name: string) => ({
    doc: (id: string) => fakeDocRef(`${name}/${id}`),
  });

  const fakeBatch = () => {
    const staged: StagedWrite[] = [];
    return {
      update: (ref: { update: Function } & Record<string, unknown>, data: Record<string, unknown>) => {
        // ref is a fakeDocRef; we need to get the path from it.
        // We capture the path via a closure trick: wrap fakeDocRef to expose path.
        const path = (ref as any).__path as string;
        staged.push({ path, data });
      },
      commit: () => {
        batchCommits.push({ writes: [...staged] });
        return Promise.resolve();
      },
    };
  };

  // Wrap fakeDocRef to attach __path for batch usage
  const fakeDocRefWithPath = (path: string) => {
    const ref = fakeDocRef(path);
    (ref as any).__path = path;
    return ref;
  };

  const fakeCollectionWithPath = (name: string) => ({
    doc: (id: string) => fakeDocRefWithPath(`${name}/${id}`),
  });

  return {
    collection: fakeCollectionWithPath,
    batch: fakeBatch,
  } as unknown as admin.firestore.Firestore;
}

const fakeDb = makeFakeFirestore();

describe("handleVoteWritten", () => {
  beforeEach(() => {
    batchCommits = [];
    standaloneWrites = [];
  });

  it("CREATE: a single batch commit contains BOTH chant counter update AND appliedValue = -1", async () => {
    await handleVoteWritten(
      undefined, // no before (create)
      { value: -1, chantId: "chant1", userId: "user1" },
      "user1_chant1",
      fakeDb
    );

    // No standalone writes (everything goes through batch)
    assert.strictEqual(standaloneWrites.length, 0,
      "Must not have standalone writes; all writes must be batched");

    // Exactly one batch commit
    assert.strictEqual(batchCommits.length, 1,
      "Expected exactly one batch commit");

    const commit = batchCommits[0];
    assert.strictEqual(commit.writes.length, 2,
      "Batch must contain exactly 2 writes (chant + vote)");

    const chantWrite = commit.writes.find((w) => w.path === "chants/chant1");
    assert.ok(chantWrite, "Batch must contain chant counter update");

    const voteWrite = commit.writes.find((w) => w.path === "votes/user1_chant1");
    assert.ok(voteWrite, "Batch must contain appliedValue write");
    assert.strictEqual(voteWrite!.data.appliedValue, -1);
  });

  it("UPDATE (flip): single batch with chant update and appliedValue = 1", async () => {
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

    const voteWrite = commit.writes.find((w) => w.path === "votes/user1_chant1");
    assert.ok(voteWrite, "Expected appliedValue write in batch");
    assert.strictEqual(voteWrite!.data.appliedValue, 1,
      "appliedValue must be the NEW value after a flip");
  });

  it("DELETE: single batch contains ONLY chant counter update, no appliedValue", async () => {
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
  });
});
