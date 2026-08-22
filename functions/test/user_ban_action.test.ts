import * as assert from "assert";
import { handleUserBanAction } from "../src/index";

describe("handleUserBanAction", () => {
  it("unbans an existing profile and writes an audit entry", async () => {
    const updates: Array<{ banned: boolean }> = [];
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
      auditWriter: async (entry) => {
        audits.push(entry);
      },
    });

    assert.deepStrictEqual(result, { success: true });
    assert.deepStrictEqual(updates, [{ banned: false }]);
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
        auditWriter: async () => {
          audited = true;
        },
      }),
      /User profile not found/,
    );

    assert.strictEqual(updated, false);
    assert.strictEqual(audited, false);
  });
});
