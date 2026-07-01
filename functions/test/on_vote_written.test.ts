import { describe, it, beforeEach } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { handleVoteWritten } from "../src/index";

// --- In-memory Firestore stub ---

interface WriteRecord {
  path: string;
  data: Record<string, unknown>;
}

let writes: WriteRecord[] = [];

function makeFakeFirestore(): admin.firestore.Firestore {
  const fakeDoc = (path: string) => ({
    update: (data: Record<string, unknown>) => {
      writes.push({ path, data });
      return Promise.resolve();
    },
  });

  const fakeCollection = (name: string) => ({
    doc: (id: string) => fakeDoc(`${name}/${id}`),
  });

  return { collection: fakeCollection } as unknown as admin.firestore.Firestore;
}

const fakeDb = makeFakeFirestore();

describe("handleVoteWritten", () => {
  beforeEach(() => {
    writes = [];
  });

  it("CREATE: updates chant counters and writes appliedValue = -1", async () => {
    await handleVoteWritten(
      undefined, // no before (create)
      { value: -1, chantId: "chant1", userId: "user1" },
      "user1_chant1",
      fakeDb
    );

    // Chant counter update.
    const chantWrite = writes.find((w) => w.path === "chants/chant1");
    assert.ok(chantWrite, "Expected a write to chants/chant1");

    // appliedValue written to vote doc.
    const voteWrite = writes.find((w) => w.path === "votes/user1_chant1");
    assert.ok(voteWrite, "Expected appliedValue write to votes/user1_chant1");
    assert.strictEqual(voteWrite!.data.appliedValue, -1);
  });

  it("UPDATE (flip): writes appliedValue = 1 after flip from down to up", async () => {
    await handleVoteWritten(
      { value: -1, chantId: "chant1", userId: "user1" },
      { value: 1, chantId: "chant1", userId: "user1" },
      "user1_chant1",
      fakeDb
    );

    const voteWrite = writes.find((w) => w.path === "votes/user1_chant1");
    assert.ok(voteWrite, "Expected appliedValue write");
    assert.strictEqual(voteWrite!.data.appliedValue, 1,
      "appliedValue must be the NEW value after a flip");
  });

  it("DELETE: updates chant counters but does NOT write appliedValue", async () => {
    await handleVoteWritten(
      { value: -1, chantId: "chant1", userId: "user1" },
      undefined, // no after (delete)
      "user1_chant1",
      fakeDb
    );

    // Chant counter update should happen.
    const chantWrite = writes.find((w) => w.path === "chants/chant1");
    assert.ok(chantWrite, "Expected chant counter update on delete");

    // No appliedValue write (doc is deleted, cannot write back).
    const voteWrite = writes.find((w) => w.path === "votes/user1_chant1");
    assert.strictEqual(voteWrite, undefined,
      "Must not write appliedValue on a deleted vote doc");
  });

  it("NO-OP: re-trigger (same value) exits early with zero writes", async () => {
    // Simulates the re-trigger after the CF wrote appliedValue back.
    // value is unchanged (-1 -> -1), only appliedValue was added.
    await handleVoteWritten(
      { value: -1, chantId: "chant1", userId: "user1" },
      { value: -1, chantId: "chant1", userId: "user1", appliedValue: -1 },
      "user1_chant1",
      fakeDb
    );

    assert.strictEqual(writes.length, 0,
      "Re-trigger with unchanged value must produce zero writes");
  });
});
