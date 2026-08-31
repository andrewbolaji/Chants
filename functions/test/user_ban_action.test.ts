import * as assert from "assert";
import { handleUserBanAction } from "../src/index";

describe("handleUserBanAction", () => {
  it("unbans an existing profile and writes an audit entry", async () => {
    const updates: Array<{ banned: boolean }> = [];
    const creatorUpdates: Array<{ hidden: boolean }> = [];
    let reconciled = 0;
    const audits: Array<Record<string, string>> = [];

    const result = await handleUserBanAction({
      action: "unban",
      actorUid: "operator-1",
      targetId: "user-1",
      profileDocument: {
        get: async () => ({ exists: true }),
        update: async (data) => {
          updates.push(data);
        },
      },
      creatorProfileDocument: {
        get: async () => ({ exists: true, data: () => ({ removed: false }) }),
        update: async (data) => {
          creatorUpdates.push(data);
        },
      },
      reconcilePerformances: async () => {
        reconciled += 1;
      },
      auditWriter: async (entry) => {
        audits.push(entry);
      },
    });

    assert.deepStrictEqual(result, { success: true });
    assert.deepStrictEqual(updates, [{ banned: false }]);
    assert.deepStrictEqual(creatorUpdates, [{ hidden: false }]);
    assert.strictEqual(reconciled, 1);
    assert.deepStrictEqual(audits, [
      {
        actorId: "operator-1",
        action: "unban",
        targetType: "user",
        targetId: "user-1",
        detail: "User unbanned by operator.",
      },
    ]);
  });

  it("rejects a missing profile without writing or auditing", async () => {
    let updated = false;
    let audited = false;

    await assert.rejects(
      handleUserBanAction({
        action: "unban",
        actorUid: "operator-1",
        targetId: "missing-user",
        profileDocument: {
          get: async () => ({ exists: false }),
          update: async () => {
            updated = true;
          },
        },
        creatorProfileDocument: {
          get: async () => ({ exists: false, data: () => undefined }),
          update: async () => undefined,
        },
        reconcilePerformances: async () => undefined,
        auditWriter: async () => {
          audited = true;
        },
      }),
      /User profile not found/,
    );

    assert.strictEqual(updated, false);
    assert.strictEqual(audited, false);
  });

  it("bans public identity and performance eligibility before auditing", async () => {
    const order: string[] = [];
    await handleUserBanAction({
      action: "ban",
      actorUid: "operator-1",
      targetId: "user-1",
      profileDocument: {
        get: async () => ({ exists: true }),
        update: async (data) => {
          assert.deepStrictEqual(data, { banned: true, activePerformanceUpload: null });
          order.push("private-ban");
        },
      },
      creatorProfileDocument: {
        get: async () => ({ exists: true, data: () => ({ removed: false }) }),
        update: async () => {
          order.push("public-hide");
        },
      },
      reconcilePerformances: async () => {
        order.push("performance-hide");
      },
      auditWriter: async () => {
        order.push("audit");
      },
    });
    assert.deepStrictEqual(order, [
      "private-ban",
      "public-hide",
      "performance-hide",
      "audit",
    ]);
  });

  it("does not revive performances when an unbanned user has no public identity", async () => {
    let reconciled = 0;
    await handleUserBanAction({
      action: "unban",
      actorUid: "operator-1",
      targetId: "user-1",
      profileDocument: {
        get: async () => ({ exists: true }),
        update: async () => undefined,
      },
      creatorProfileDocument: {
        get: async () => ({ exists: false, data: () => undefined }),
        update: async () => {
          throw new Error("Missing public identity must not be updated.");
        },
      },
      reconcilePerformances: async () => {
        reconciled += 1;
      },
      auditWriter: async () => undefined,
    });
    assert.strictEqual(reconciled, 1);
  });
});
