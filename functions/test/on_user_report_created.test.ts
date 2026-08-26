import { describe, it, beforeEach } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { handleUserReportCreated, handleUserReportDeleted } from "../src/index";

// --- In-memory Firestore stub: userReports store (queryable) + profiles
// store (get/update), same shape as the fakes in on_vote_written.test.ts
// and accept_policy.test.ts.

let userReportsStore: Record<string, Record<string, unknown>> = {};
let profilesStore: Record<string, Record<string, unknown>> = {};
let profileUpdateCalls: Array<{ id: string; data: Record<string, unknown> }> = [];

function makeFakeFirestore(): admin.firestore.Firestore {
  const fakeCollection = (name: string) => ({
    doc: (id: string) => ({ __path: `${name}/${id}` }),
    where: (field: string, _op: string, value: unknown) => ({
      __query: { name, field, value },
    }),
  });

  return {
    collection: fakeCollection,
    runTransaction: async (handler: (transaction: {
      get: (target: Record<string, unknown>) => Promise<unknown>;
      update: (ref: Record<string, unknown>, data: Record<string, unknown>) => void;
    }) => Promise<unknown>) => {
      const writes: Array<{
        ref: Record<string, unknown>;
        data: Record<string, unknown>;
      }> = [];
      const result = await handler({
        get: async (target: Record<string, unknown>) => {
          const query = target.__query as {
            name: string;
            field: string;
            value: unknown;
          } | undefined;
          if (query) {
            const docs = Object.entries(userReportsStore)
              .filter(([, data]) => data[query.field] === query.value)
              .map(([id, data]) => ({ id, data: () => ({ ...data }) }));
            return { docs, size: docs.length };
          }
          const path = target.__path as string;
          const [collection, id] = path.split("/");
          const data = collection === "profiles" ? profilesStore[id] : undefined;
          return {
            exists: data !== undefined,
            data: () => data === undefined ? undefined : { ...data },
          };
        },
        update: (ref, data) => writes.push({ ref, data }),
      });
      for (const write of writes) {
        const path = write.ref.__path as string;
        const [, id] = path.split("/");
        profileUpdateCalls.push({ id, data: write.data });
        profilesStore[id] = { ...(profilesStore[id] || {}), ...write.data };
      }
      return result;
    },
  } as unknown as admin.firestore.Firestore;
}

const fakeDb = makeFakeFirestore();

describe("handleUserReportCreated", () => {
  beforeEach(() => {
    userReportsStore = {};
    profilesStore = {};
    profileUpdateCalls = [];
  });

  it("CREATE: recomputes userReportCount from the userReports store, not an increment", async () => {
    profilesStore["baduser"] = { role: "user", banned: false, userReportCount: 0 };
    userReportsStore["reporter1_baduser"] = {
      reportedUserId: "baduser",
      reportedBy: "reporter1",
      reason: "Hate speech or slurs",
      status: "pending",
    };

    const result = await handleUserReportCreated("baduser", fakeDb);

    assert.strictEqual(result.userReportCount, 1);
    assert.strictEqual(profileUpdateCalls.length, 1);
    assert.strictEqual(profileUpdateCalls[0].id, "baduser");
    assert.strictEqual(profileUpdateCalls[0].data.userReportCount, 1);
  });

  it("GUARD: reported user's profile no longer exists, no write attempted", async () => {
    // No entry in profilesStore for "ghost-user".
    userReportsStore["reporter1_ghost-user"] = {
      reportedUserId: "ghost-user",
      reportedBy: "reporter1",
      reason: "test",
      status: "pending",
    };

    const result = await handleUserReportCreated("ghost-user", fakeDb);

    assert.strictEqual(result.userReportCount, 0,
      "missing parent stops before reading report ground truth");
    assert.strictEqual(profileUpdateCalls.length, 0,
      "must not attempt to update a profile that no longer exists");
  });

  it("IDEMPOTENCY: duplicate delivery of the same report produces the same count both times", async () => {
    profilesStore["baduser"] = { role: "user", banned: false, userReportCount: 0 };
    userReportsStore["reporter1_baduser"] = {
      reportedUserId: "baduser",
      reportedBy: "reporter1",
      reason: "test",
      status: "pending",
    };

    const first = await handleUserReportCreated("baduser", fakeDb);
    const second = await handleUserReportCreated("baduser", fakeDb);

    assert.strictEqual(first.userReportCount, 1);
    assert.strictEqual(second.userReportCount, 1,
      "recompute from ground truth, not an increment: duplicate delivery must not double-count");
    assert.strictEqual(profileUpdateCalls.length, 2);
    assert.strictEqual(profileUpdateCalls[0].data.userReportCount, 1);
    assert.strictEqual(profileUpdateCalls[1].data.userReportCount, 1);
  });

  it("BURST: three distinct reporters, each trigger converges to the correct total", async () => {
    profilesStore["baduser"] = { role: "user", banned: false, userReportCount: 0 };

    // Simulate three reports landing one at a time, each firing the trigger
    // with whatever is in the store at that moment (mirrors real delivery:
    // the store already contains the report that triggered this event).
    userReportsStore["reporter1_baduser"] = {
      reportedUserId: "baduser", reportedBy: "reporter1", reason: "a", status: "pending",
    };
    const afterFirst = await handleUserReportCreated("baduser", fakeDb);

    userReportsStore["reporter2_baduser"] = {
      reportedUserId: "baduser", reportedBy: "reporter2", reason: "b", status: "pending",
    };
    const afterSecond = await handleUserReportCreated("baduser", fakeDb);

    userReportsStore["reporter3_baduser"] = {
      reportedUserId: "baduser", reportedBy: "reporter3", reason: "c", status: "pending",
    };
    const afterThird = await handleUserReportCreated("baduser", fakeDb);

    assert.strictEqual(afterFirst.userReportCount, 1);
    assert.strictEqual(afterSecond.userReportCount, 2);
    assert.strictEqual(afterThird.userReportCount, 3);
    assert.strictEqual(profileUpdateCalls.length, 3);
  });

  it("only counts reports targeting this user, not other users' reports", async () => {
    profilesStore["baduser"] = { role: "user", banned: false, userReportCount: 0 };
    profilesStore["otheruser"] = { role: "user", banned: false, userReportCount: 0 };
    userReportsStore["reporter1_baduser"] = {
      reportedUserId: "baduser", reportedBy: "reporter1", reason: "a", status: "pending",
    };
    userReportsStore["reporter1_otheruser"] = {
      reportedUserId: "otheruser", reportedBy: "reporter1", reason: "b", status: "pending",
    };

    const result = await handleUserReportCreated("baduser", fakeDb);

    assert.strictEqual(result.userReportCount, 1);
  });

  it("DELETE: recomputes the surviving target count without an audit path", async () => {
    profilesStore["baduser"] = { role: "user", banned: false, userReportCount: 2 };
    userReportsStore["reporter1_baduser"] = {
      reportedUserId: "baduser", reportedBy: "reporter1", reason: "a", status: "pending",
    };
    userReportsStore["reporter2_baduser"] = {
      reportedUserId: "baduser", reportedBy: "reporter2", reason: "b", status: "pending",
    };
    delete userReportsStore["reporter1_baduser"];

    await handleUserReportDeleted({ reportedUserId: "baduser" }, fakeDb);

    assert.strictEqual(profileUpdateCalls.length, 1);
    assert.strictEqual(profileUpdateCalls[0].data.userReportCount, 1);
  });
});
