import { describe, it, beforeEach } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { handleCommentLikeWritten } from "../src/index";

// --- In-memory stub: comment store + like store + batch recorder ---

interface StagedWrite {
  path: string;
  data: Record<string, unknown>;
}

interface BatchCommit {
  writes: StagedWrite[];
}

let batchCommits: BatchCommit[] = [];

// In-memory stores keyed by doc id.
let likeStore: Record<string, Record<string, unknown>> = {};
let commentStore: Record<string, Record<string, unknown>> = {};

function makeFakeFirestore(): admin.firestore.Firestore {
  const fakeDocRefWithPath = (path: string) => {
    const docId = path.split("/")[1];
    const collection = path.split("/")[0];
    return {
      update: (data: Record<string, unknown>) => {
        // Apply the update to the in-memory store
        if (collection === "comments" && commentStore[docId]) {
          Object.assign(commentStore[docId], data);
        }
        return Promise.resolve();
      },
      get: () => {
        if (collection === "comments") {
          const data = commentStore[docId];
          return Promise.resolve({
            exists: !!data,
            data: () => data ? { ...data } : undefined,
          });
        }
        return Promise.resolve({ exists: false, data: () => undefined });
      },
      __path: path,
    };
  };

  const fakeCollectionWithPath = (name: string) => ({
    doc: (id: string) => fakeDocRefWithPath(`${name}/${id}`),
    where: (field: string, _op: string, value: unknown) => ({
      get: () => {
        const store = name === "commentLikes" ? likeStore : commentStore;
        const docs = Object.entries(store)
          .filter(([, data]) => data[field] === value)
          .map(([id, data]) => ({
            id,
            data: () => ({ ...data }),
          }));
        return Promise.resolve({ docs });
      },
    }),
  });

  const fakeBatch = () => {
    const staged: StagedWrite[] = [];
    return {
      update: (ref: Record<string, unknown>, data: Record<string, unknown>) => {
        staged.push({ path: ref.__path as string, data });
      },
      commit: () => {
        batchCommits.push({ writes: [...staged] });
        return Promise.resolve();
      },
    };
  };

  return {
    collection: fakeCollectionWithPath,
    batch: fakeBatch,
  } as unknown as admin.firestore.Firestore;
}

const fakeDb = makeFakeFirestore();

describe("handleCommentLikeWritten", () => {
  beforeEach(() => {
    batchCommits = [];
    likeStore = {};
    commentStore = {};
  });

  it("CREATE: recomputes likeCount from like store and stamps appliedValue atomically", async () => {
    commentStore["comment1"] = { chantId: "chant1", likeCount: 0 };
    likeStore["user1_comment1"] = { value: 1, commentId: "comment1", userId: "user1" };

    await handleCommentLikeWritten(
      undefined,
      { value: 1, commentId: "comment1", userId: "user1" },
      "user1_comment1",
      fakeDb
    );

    assert.strictEqual(batchCommits.length, 1);
    const commit = batchCommits[0];
    assert.strictEqual(commit.writes.length, 2);

    const commentWrite = commit.writes.find((w) => w.path === "comments/comment1");
    assert.ok(commentWrite);
    assert.strictEqual(commentWrite!.data.likeCount, 1);

    const likeWrite = commit.writes.find((w) => w.path === "commentLikes/user1_comment1");
    assert.ok(likeWrite);
    assert.strictEqual(likeWrite!.data.appliedValue, 1);
  });

  it("DELETE (unlike): recomputes likeCount to 0, no appliedValue write", async () => {
    commentStore["comment1"] = { chantId: "chant1", likeCount: 1 };
    // Like doc is gone (deleted)

    await handleCommentLikeWritten(
      { value: 1, commentId: "comment1", userId: "user1" },
      undefined,
      "user1_comment1",
      fakeDb
    );

    assert.strictEqual(batchCommits.length, 1);
    const commit = batchCommits[0];
    assert.strictEqual(commit.writes.length, 1, "Only the comment update, no appliedValue on deleted doc");

    const commentWrite = commit.writes.find((w) => w.path === "comments/comment1");
    assert.ok(commentWrite);
    assert.strictEqual(commentWrite!.data.likeCount, 0);
  });

  it("NO-OP: re-trigger (same value, e.g. appliedValue write-back) produces zero commits", async () => {
    commentStore["comment1"] = { chantId: "chant1", likeCount: 1 };

    await handleCommentLikeWritten(
      { value: 1, commentId: "comment1", userId: "user1" },
      { value: 1, commentId: "comment1", userId: "user1", appliedValue: 1 },
      "user1_comment1",
      fakeDb
    );

    assert.strictEqual(batchCommits.length, 0, "Same value means no-op");
  });

  it("IDEMPOTENCY: duplicate delivery produces the same correct likeCount", async () => {
    commentStore["comment1"] = { chantId: "chant1", likeCount: 0 };
    likeStore["user1_comment1"] = { value: 1, commentId: "comment1", userId: "user1" };

    const afterData = { value: 1, commentId: "comment1", userId: "user1" };

    // First delivery
    await handleCommentLikeWritten(undefined, afterData, "user1_comment1", fakeDb);
    // Second delivery (duplicate)
    await handleCommentLikeWritten(undefined, afterData, "user1_comment1", fakeDb);

    assert.strictEqual(batchCommits.length, 2);
    for (let i = 0; i < 2; i++) {
      const commentWrite = batchCommits[i].writes.find((w) => w.path === "comments/comment1");
      assert.ok(commentWrite);
      assert.strictEqual(commentWrite!.data.likeCount, 1,
        `Delivery ${i + 1}: likeCount must be 1 (not accumulated)`);
    }
  });

  it("BURST: rapid like/unlike/like all converge to correct likeCount", async () => {
    commentStore["comment1"] = { chantId: "chant1", likeCount: 0 };
    // Final state: like exists (user ended on liked)
    likeStore["user1_comment1"] = { value: 1, commentId: "comment1", userId: "user1" };

    const events = [
      { before: undefined, after: { value: 1, commentId: "comment1", userId: "user1" } },
      { before: { value: 1, commentId: "comment1", userId: "user1" }, after: undefined },
      { before: undefined, after: { value: 1, commentId: "comment1", userId: "user1" } },
    ];

    for (const e of events) {
      await handleCommentLikeWritten(
        e.before as admin.firestore.DocumentData | undefined,
        e.after as admin.firestore.DocumentData | undefined,
        "user1_comment1",
        fakeDb
      );
    }

    // All converge to likeCount = 1 because they recompute from the store
    for (let i = 0; i < batchCommits.length; i++) {
      const commentWrite = batchCommits[i].writes.find((w) => w.path === "comments/comment1");
      assert.ok(commentWrite, `Event ${i + 1} must update comment`);
      assert.strictEqual(commentWrite!.data.likeCount, 1,
        `Event ${i + 1}: likeCount must be 1 (recomputed from final store state)`);
    }
  });

  it("GUARD: comment doc missing (deleted) produces zero commits", async () => {
    // Comment does NOT exist in commentStore
    likeStore["user1_comment1"] = { value: 1, commentId: "comment1", userId: "user1" };

    await handleCommentLikeWritten(
      undefined,
      { value: 1, commentId: "comment1", userId: "user1" },
      "user1_comment1",
      fakeDb
    );

    assert.strictEqual(batchCommits.length, 0, "Must no-op when comment doc is gone");
  });
});
