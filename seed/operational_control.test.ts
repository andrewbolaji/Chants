import { strict as assert } from "assert";
import * as admin from "firebase-admin";
import { runSeedTransaction } from "./operational_control";
import { reconcileChant } from "./reconcile";

describe("seed operational interlock", () => {
  it("the real reconciliation writer cannot bypass the same-transaction control", async () => {
    let mode = "maintenance";
    const reads: string[] = [];
    const writes: unknown[] = [];
    const db = {
      collection: (name: string) => ({ doc: () => ({ name }), where: () => ({ name }) }),
      runTransaction: async (handler: (transaction: unknown) => Promise<unknown>) => handler({
        get: async (reference: { name: string }) => {
          reads.push(reference.name);
          if (reference.name === "operationalControls") return { data: () => ({ schemaVersion: 1, generation: 1, mode, destructiveWorkersEnabled: false }) };
          if (reference.name === "votes") return { docs: [{ data: () => ({ value: 1 }) }] };
          return { exists: true, data: () => ({ upvotes: 8, downvotes: 0, score: 8 }) };
        },
        update: (_reference: unknown, value: unknown) => writes.push(value),
      }),
    } as unknown as admin.firestore.Firestore;
    await assert.rejects(reconcileChant("chant", db));
    assert.deepEqual(reads, ["operationalControls"]); assert.equal(writes.length, 0);
    mode = "core"; reads.length = 0;
    await reconcileChant("chant", db);
    assert.deepEqual(reads, ["operationalControls", "votes", "chants"]);
    assert.deepEqual(writes, [{ upvotes: 1, downvotes: 0, score: 1 }]);
  });
  it("never invokes a writer for missing, maintenance, malformed, or unreadable control", async () => {
    let calls = 0;
    for (const value of [undefined, {}, { schemaVersion: 1, generation: 1, mode: "maintenance", destructiveWorkersEnabled: true }, "read-error"]) {
      const db = { collection: () => ({ doc: () => ({}) }),
        runTransaction: async (handler: (transaction: unknown) => Promise<unknown>) => handler({
          get: async () => { if (value === "read-error") throw Error("offline"); return { data: () => value }; },
        }),
      } as unknown as admin.firestore.Firestore; // Isolated SDK test adapter, no credentials or network.
      await assert.rejects(runSeedTransaction(db, async () => { calls++; }));
    }
    assert.equal(calls, 0);
  });
  it("checks admission in the same transaction before an open-mode writer", async () => {
    const order: string[] = [];
    const db = { collection: () => ({ doc: () => ({}) }),
      runTransaction: async (handler: (transaction: unknown) => Promise<unknown>) => handler({
        get: async () => { order.push("control"); return { data: () => ({ schemaVersion: 1, generation: 1, mode: "core", destructiveWorkersEnabled: false }) }; },
      }),
    } as unknown as admin.firestore.Firestore;
    await runSeedTransaction(db, async () => { order.push("writer"); });
    assert.deepEqual(order, ["control", "writer"]);
  });
});
