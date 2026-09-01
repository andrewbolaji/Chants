import { describe, it, beforeEach } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { handleAcceptPolicy } from "../src/index";

// --- In-memory Firestore stub: a single profiles store, get + update ---

interface UpdateCall {
  path: string;
  data: Record<string, unknown>;
}

let profileStore: Record<string, Record<string, unknown>> = {};
let updateCalls: UpdateCall[] = [];

function makeFakeFirestore(): admin.firestore.Firestore {
  const fakeDocRefWithPath = (path: string, id: string) => ({
    __path: path,
    get: () => {
      const data = profileStore[id];
      return Promise.resolve({
        exists: data !== undefined,
        data: () => (data ? { ...data } : undefined),
      });
    },
    update: (data: Record<string, unknown>) => {
      updateCalls.push({ path, data });
      profileStore[id] = { ...(profileStore[id] || {}), ...data };
      return Promise.resolve();
    },
  });

  const fakeCollectionWithPath = (name: string) => ({
    doc: (id: string) => fakeDocRefWithPath(`${name}/${id}`, id),
  });

  return {
    collection: fakeCollectionWithPath,
  } as unknown as admin.firestore.Firestore;
}

const fakeDb = makeFakeFirestore();

describe("handleAcceptPolicy", () => {
  beforeEach(() => {
    profileStore = {};
    updateCalls = [];
  });

  it("existing profile: writes acceptedPolicyVersion and acceptedPolicyAt, reports accepted", async () => {
    profileStore["user1"] = { role: "user", banned: false };

    const result = await handleAcceptPolicy("user1", fakeDb);

    assert.strictEqual(result.accepted, true);
    assert.strictEqual(updateCalls.length, 1);
    const write = updateCalls[0];
    assert.strictEqual(write.path, "profiles/user1");
    assert.strictEqual(write.data.acceptedPolicyVersion, "v2");
    assert.ok(write.data.acceptedPolicyAt, "acceptedPolicyAt must be set");
  });

  it("missing profile: makes no write, reports not accepted", async () => {
    // profileStore has no entry for this uid.
    const result = await handleAcceptPolicy("ghost-user", fakeDb);

    assert.strictEqual(result.accepted, false);
    assert.strictEqual(updateCalls.length, 0,
      "Must not write anything when the profile does not exist");
  });

  it("does not disturb other profile fields (role, banned, displayName)", async () => {
    profileStore["user1"] = {
      role: "user",
      banned: false,
      displayName: "GoalKing",
    };

    await handleAcceptPolicy("user1", fakeDb);

    assert.strictEqual(profileStore["user1"].role, "user");
    assert.strictEqual(profileStore["user1"].banned, false);
    assert.strictEqual(profileStore["user1"].displayName, "GoalKing");
  });

  it("repeat acceptance is safe: second call still succeeds and re-stamps", async () => {
    profileStore["user1"] = { role: "user", banned: false };

    const first = await handleAcceptPolicy("user1", fakeDb);
    const second = await handleAcceptPolicy("user1", fakeDb);

    assert.strictEqual(first.accepted, true);
    assert.strictEqual(second.accepted, true);
    assert.strictEqual(updateCalls.length, 2);
  });

  it("pending deletion rejects acceptance without a write", async () => {
    profileStore["user1"] = {
      role: "user",
      banned: false,
      deletionPending: true,
    };

    await assert.rejects(
      handleAcceptPolicy("user1", fakeDb),
      (error: { code?: string }) => error.code === "failed-precondition"
    );
    assert.strictEqual(updateCalls.length, 0);
  });
});
