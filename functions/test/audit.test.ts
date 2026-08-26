import { describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { writePrivacySafeReportAuditEntry } from "../src/audit";

type Data = Record<string, unknown>;
type Ref = { collectionName: string; id: string };

function makeHarness(profile?: Data) {
  const store = new Map<string, Map<string, Data>>();
  let nextId = 0;
  const bucket = (name: string) => {
    let value = store.get(name);
    if (!value) {
      value = new Map<string, Data>();
      store.set(name, value);
    }
    return value;
  };
  if (profile) bucket("profiles").set("reporter", { ...profile });

  const firestore = {
    collection: (collectionName: string) => ({
      doc: (id?: string) => ({
        collectionName,
        id: id ?? `auto-${++nextId}`,
      }),
    }),
    runTransaction: async (
      handler: (transaction: {
        get: (ref: Ref) => Promise<{
          exists: boolean;
          data: () => Data | undefined;
        }>;
        set: (ref: Ref, data: Data) => void;
      }) => Promise<void>
    ) => {
      const writes: Array<{ ref: Ref; data: Data }> = [];
      await handler({
        get: async (ref) => {
          const value = bucket(ref.collectionName).get(ref.id);
          return {
            exists: value !== undefined,
            data: () => value === undefined ? undefined : { ...value },
          };
        },
        set: (ref, data) => writes.push({ ref, data }),
      });
      for (const write of writes) {
        bucket(write.ref.collectionName).set(write.ref.id, { ...write.data });
      }
    },
  } as unknown as admin.firestore.Firestore;

  return {
    firestore,
    audit: () => bucket("auditLog").get("auto-1"),
  };
}

describe("writePrivacySafeReportAuditEntry", () => {
  it("retains an active reporter identity and reason", async () => {
    const harness = makeHarness({ deletionPending: false });

    await writePrivacySafeReportAuditEntry({
      reporterId: "reporter",
      action: "report",
      targetType: "chant",
      targetId: "chant-1",
      reason: "Spam with context",
      firestore: harness.firestore,
    });

    assert.strictEqual(harness.audit()?.actorId, "reporter");
    assert.strictEqual(harness.audit()?.detail, "Reason: Spam with context");
  });

  for (const [name, profile] of [
    ["pending", { deletionPending: true }],
    ["missing", undefined],
  ] as const) {
    it(`redacts a ${name} reporter before writing a delayed audit`, async () => {
      const harness = makeHarness(profile);

      await writePrivacySafeReportAuditEntry({
        reporterId: "reporter",
        action: "report-user",
        targetType: "user",
        targetId: "target",
        reason: "Private report text",
        firestore: harness.firestore,
      });

      assert.strictEqual(harness.audit()?.actorId, "deleted-user");
      assert.strictEqual(
        harness.audit()?.detail,
        "Report details removed during account deletion."
      );
      assert.strictEqual(JSON.stringify(harness.audit()).includes("Private report text"), false);
    });
  }
});
