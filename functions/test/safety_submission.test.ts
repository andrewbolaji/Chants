import { describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import {
  deleteSafetyRateState,
  handleSubmitFeedback,
  handleSubmitReport,
  planAnchoredWindow,
  requireAuthenticatedUid,
} from "../src/safety_submission";

type Store = Record<string, Record<string, unknown>>;

type FakeDocumentRef = {
  path: string;
  collectionName: string;
  id: string;
  delete: () => Promise<void>;
};

function makeHarness(options: { retryOnce?: boolean } = {}) {
  const stores: Record<string, Store> = {};
  let autoId = 0;
  let retried = false;

  const collectionStore = (name: string): Store => {
    stores[name] ??= {};
    return stores[name];
  };

  const snapshot = (ref: FakeDocumentRef) => {
    const value = collectionStore(ref.collectionName)[ref.id];
    return {
      exists: value !== undefined,
      data: () => value === undefined ? undefined : { ...value },
    };
  };

  const makeRef = (collectionName: string, id: string): FakeDocumentRef => ({
    path: `${collectionName}/${id}`,
    collectionName,
    id,
    delete: async () => {
      delete collectionStore(collectionName)[id];
    },
  });

  const runAttempt = async (
    handler: (transaction: unknown) => Promise<unknown>
  ): Promise<{ result: unknown; writes: Array<{
    ref: FakeDocumentRef;
    data: Record<string, unknown>;
    merge: boolean;
  }> }> => {
    const writes: Array<{
      ref: FakeDocumentRef;
      data: Record<string, unknown>;
      merge: boolean;
    }> = [];
    const result = await handler({
      get: async (ref: FakeDocumentRef) => snapshot(ref),
      set: (
        ref: FakeDocumentRef,
        data: Record<string, unknown>,
        setOptions?: { merge?: boolean }
      ) => writes.push({ ref, data, merge: setOptions?.merge === true }),
    });
    return { result, writes };
  };

  const firestore = {
    collection: (name: string) => ({
      doc: (id?: string) => makeRef(name, id ?? `auto-${++autoId}`),
    }),
    runTransaction: async (
      handler: (transaction: unknown) => Promise<unknown>
    ) => {
      if (options.retryOnce && !retried) {
        retried = true;
        await runAttempt(handler);
      }
      const { result, writes } = await runAttempt(handler);
      for (const write of writes) {
        const target = collectionStore(write.ref.collectionName);
        target[write.ref.id] = write.merge
          ? { ...target[write.ref.id], ...write.data }
          : { ...write.data };
      }
      return result;
    },
  } as unknown as admin.firestore.Firestore;

  return {
    firestore,
    seed: (collection: string, id: string, data: Record<string, unknown>) => {
      collectionStore(collection)[id] = { ...data };
    },
    read: (collection: string, id: string) => collectionStore(collection)[id],
    count: (collection: string) => Object.keys(collectionStore(collection)).length,
  };
}

async function expectCode(
  action: Promise<unknown>,
  code: string
): Promise<void> {
  await assert.rejects(action, (error: unknown) => {
    return error instanceof HttpsError && error.code === code;
  });
}

const NOW = admin.firestore.Timestamp.fromMillis(Date.UTC(2026, 7, 25, 18));
const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

function seedReporter(
  harness: ReturnType<typeof makeHarness>,
  overrides: Record<string, unknown> = {}
): void {
  harness.seed("profiles", "reporter", {
    banned: false,
    createdAt: admin.firestore.Timestamp.fromMillis(NOW.toMillis() - 2 * DAY_MS),
    ...overrides,
  });
}

function reportData(
  targetType: "chant" | "comment" | "user",
  targetId: string
): Record<string, unknown> {
  return { targetType, targetId, reason: "Hate speech or slurs" };
}

describe("handleSubmitReport", () => {
  it("requires callable authentication and returns the server auth UID", async () => {
    assert.strictEqual(requireAuthenticatedUid({ uid: "reporter" }), "reporter");
    await expectCode(Promise.resolve().then(
      () => requireAuthenticatedUid(undefined)
    ), "unauthenticated");
  });

  it("rejects unauthoritative payload fields and malformed values", async () => {
    const harness = makeHarness();
    seedReporter(harness);

    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: { ...reportData("chant", "chant-1"), reportedBy: "attacker" },
      firestore: harness.firestore,
      clock: () => NOW,
    }), "invalid-argument");
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: { targetType: "collection", targetId: "chant-1", reason: "x" },
      firestore: harness.firestore,
      clock: () => NOW,
    }), "invalid-argument");
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: { targetType: "chant", targetId: " ", reason: "x" },
      firestore: harness.firestore,
      clock: () => NOW,
    }), "invalid-argument");
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: { targetType: "chant", targetId: "chant-1", reason: "x".repeat(251) },
      firestore: harness.firestore,
      clock: () => NOW,
    }), "invalid-argument");
    assert.strictEqual(harness.count("safetyRateLimits"), 0);
  });

  it("requires an existing, explicitly unbanned reporter profile", async () => {
    const missing = makeHarness();
    missing.seed("chants", "chant-1", { hidden: false, removed: false });
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "chant-1"),
      firestore: missing.firestore,
      clock: () => NOW,
    }), "failed-precondition");

    const malformed = makeHarness();
    seedReporter(malformed, { banned: "false" });
    malformed.seed("chants", "chant-1", { hidden: false, removed: false });
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "chant-1"),
      firestore: malformed.firestore,
      clock: () => NOW,
    }), "failed-precondition");

    const banned = makeHarness();
    seedReporter(banned, { banned: true });
    banned.seed("chants", "chant-1", { hidden: false, removed: false });
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "chant-1"),
      firestore: banned.firestore,
      clock: () => NOW,
    }), "permission-denied");

    const deleting = makeHarness();
    seedReporter(deleting, { deletionPending: true });
    deleting.seed("chants", "chant-1", { hidden: false, removed: false });
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "chant-1"),
      firestore: deleting.firestore,
      clock: () => NOW,
    }), "failed-precondition");
  });

  it("rejects missing, hidden, and removed content targets without spending budget", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    harness.seed("chants", "hidden", { hidden: true, removed: false });
    harness.seed("comments", "removed", { hidden: false, removed: true });

    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "missing"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "not-found");
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "hidden"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "failed-precondition");
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("comment", "removed"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "failed-precondition");
    assert.strictEqual(harness.count("safetyRateLimits"), 0);
  });

  it("rejects self-reporting and missing user targets", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("user", "reporter"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "invalid-argument");
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("user", "missing"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "not-found");
  });

  it("rejects a user target whose deletion is already pending", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    harness.seed("profiles", "deleting-target", {
      banned: false,
      deletionPending: true,
    });

    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("user", "deleting-target"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "failed-precondition");
    assert.strictEqual(harness.count("userReports"), 0);
    assert.strictEqual(harness.count("safetyRateLimits"), 0);
  });

  it("rejects a target ID whose UTF-8 path would exceed the stored ID budget", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    const targetId = "界".repeat(512);

    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("user", targetId),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "invalid-argument");
    assert.strictEqual(harness.count("userReports"), 0);
  });

  it("writes each legacy report shape with server-owned identity, time, and status", async () => {
    const cases = [
      ["chant", "chants", "reports", "chantId"],
      ["comment", "comments", "commentReports", "commentId"],
      ["user", "profiles", "userReports", "reportedUserId"],
    ] as const;

    for (const [targetType, targetCollection, reportCollection, targetField] of cases) {
      const harness = makeHarness();
      seedReporter(harness);
      harness.seed(targetCollection, "target", targetType === "user"
        ? { banned: false }
        : { hidden: false, removed: false });

      await handleSubmitReport({
        uid: "reporter",
        data: { targetType, targetId: " target ", reason: " reason " },
        firestore: harness.firestore,
        clock: () => NOW,
      });

      assert.deepStrictEqual(harness.read(reportCollection, "reporter_target"), {
        [targetField]: "target",
        reportedBy: "reporter",
        reason: "reason",
        createdAt: NOW,
        status: "pending",
      });
      const rate = harness.read("safetyRateLimits", "reporter");
      assert.strictEqual(rate.reportCount, 1);
      assert.strictEqual(rate.reportWindowStartedAt, NOW);
      assert.strictEqual(rate.updatedAt, NOW);
    }
  });

  it("rejects duplicates without overwriting or consuming budget", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    harness.seed("chants", "chant-1", { hidden: false, removed: false });
    harness.seed("reports", "reporter_chant-1", {
      chantId: "chant-1",
      reportedBy: "reporter",
      reason: "original",
      status: "reviewed",
    });
    harness.seed("safetyRateLimits", "reporter", {
      reportWindowStartedAt: NOW,
      reportCount: 2,
    });

    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "chant-1"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "already-exists");

    assert.strictEqual(harness.read("reports", "reporter_chant-1").reason, "original");
    assert.strictEqual(harness.read("safetyRateLimits", "reporter").reportCount, 2);
  });

  it("enforces the shared five-report budget for accounts under 24 hours", async () => {
    const harness = makeHarness();
    seedReporter(harness, {
      createdAt: admin.firestore.Timestamp.fromMillis(NOW.toMillis() - HOUR_MS),
    });
    for (let index = 1; index <= 6; index++) {
      harness.seed("chants", `chant-${index}`, { hidden: false, removed: false });
    }
    for (let index = 1; index <= 5; index++) {
      await handleSubmitReport({
        uid: "reporter",
        data: reportData("chant", `chant-${index}`),
        firestore: harness.firestore,
        clock: () => NOW,
      });
    }
    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "chant-6"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "resource-exhausted");
    assert.strictEqual(harness.count("reports"), 5);
    assert.strictEqual(harness.read("safetyRateLimits", "reporter").reportCount, 5);
  });

  it("uses the safer five-report limit when profile creation time is malformed", async () => {
    const harness = makeHarness();
    seedReporter(harness, { createdAt: "client-time" });
    harness.seed("comments", "comment-6", { hidden: false, removed: false });
    harness.seed("safetyRateLimits", "reporter", {
      reportWindowStartedAt: NOW,
      reportCount: 5,
    });

    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("comment", "comment-6"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "resource-exhausted");
    assert.strictEqual(harness.count("commentReports"), 0);
  });

  it("enforces the 20-report budget for established accounts", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    harness.seed("profiles", "target-21", { banned: false });
    harness.seed("safetyRateLimits", "reporter", {
      reportWindowStartedAt: NOW,
      reportCount: 20,
    });

    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("user", "target-21"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "resource-exhausted");
    assert.strictEqual(harness.count("userReports"), 0);
    assert.strictEqual(harness.read("safetyRateLimits", "reporter").reportCount, 20);
  });

  it("resets an expired report window on the next accepted report", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    harness.seed("chants", "chant-1", { hidden: false, removed: false });
    harness.seed("safetyRateLimits", "reporter", {
      reportWindowStartedAt: admin.firestore.Timestamp.fromMillis(NOW.toMillis() - HOUR_MS),
      reportCount: 20,
      feedbackCount: 2,
    });

    await handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "chant-1"),
      firestore: harness.firestore,
      clock: () => NOW,
    });
    const rate = harness.read("safetyRateLimits", "reporter");
    assert.strictEqual(rate.reportCount, 1);
    assert.strictEqual(rate.reportWindowStartedAt, NOW);
    assert.strictEqual(rate.feedbackCount, 2);
  });

  it("fails closed for a malformed count in a live rate window", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    harness.seed("chants", "chant-1", { hidden: false, removed: false });
    harness.seed("safetyRateLimits", "reporter", {
      reportWindowStartedAt: NOW,
      reportCount: "not-a-count",
    });

    await expectCode(handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "chant-1"),
      firestore: harness.firestore,
      clock: () => NOW,
    }), "resource-exhausted");
    assert.strictEqual(harness.count("reports"), 0);
  });

  it("commits one budget unit when Firestore retries the transaction callback", async () => {
    const harness = makeHarness({ retryOnce: true });
    seedReporter(harness);
    harness.seed("chants", "chant-1", { hidden: false, removed: false });

    await handleSubmitReport({
      uid: "reporter",
      data: reportData("chant", "chant-1"),
      firestore: harness.firestore,
      clock: () => NOW,
    });
    assert.strictEqual(harness.count("reports"), 1);
    assert.strictEqual(harness.read("safetyRateLimits", "reporter").reportCount, 1);
  });
});

describe("handleSubmitFeedback", () => {
  it("validates the exact payload and accepted categories", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    await expectCode(handleSubmitFeedback({
      uid: "reporter",
      data: { category: "praise", message: "hello", followUpOk: true },
      firestore: harness.firestore,
      clock: () => NOW,
    }), "invalid-argument");
    await expectCode(handleSubmitFeedback({
      uid: "reporter",
      data: { category: "bug", message: "hello", followUpOk: true, userId: "other" },
      firestore: harness.firestore,
      clock: () => NOW,
    }), "invalid-argument");
    await expectCode(handleSubmitFeedback({
      uid: "reporter",
      data: { category: "bug", message: " ", followUpOk: true },
      firestore: harness.firestore,
      clock: () => NOW,
    }), "invalid-argument");
    await expectCode(handleSubmitFeedback({
      uid: "reporter",
      data: { category: "bug", message: "x".repeat(1001), followUpOk: true },
      firestore: harness.firestore,
      clock: () => NOW,
    }), "invalid-argument");
    assert.strictEqual(harness.count("safetyRateLimits"), 0);
  });

  it("requires an existing, explicitly unbanned profile", async () => {
    const missing = makeHarness();
    await expectCode(handleSubmitFeedback({
      uid: "reporter",
      data: { category: "bug", message: "hello", followUpOk: true },
      firestore: missing.firestore,
      clock: () => NOW,
    }), "failed-precondition");

    const banned = makeHarness();
    seedReporter(banned, { banned: true });
    await expectCode(handleSubmitFeedback({
      uid: "reporter",
      data: { category: "bug", message: "hello", followUpOk: true },
      firestore: banned.firestore,
      clock: () => NOW,
    }), "permission-denied");
    assert.strictEqual(banned.count("feedback"), 0);
  });

  it("writes a random-id feedback row with server-owned fields", async () => {
    const harness = makeHarness();
    seedReporter(harness);

    await handleSubmitFeedback({
      uid: "reporter",
      data: { category: "bug", message: "  playback broke  ", followUpOk: true },
      firestore: harness.firestore,
      clock: () => NOW,
    });

    assert.deepStrictEqual(harness.read("feedback", "auto-1"), {
      userId: "reporter",
      category: "bug",
      message: "playback broke",
      followUpOk: true,
      createdAt: NOW,
      resolved: false,
    });
    assert.strictEqual(harness.read("safetyRateLimits", "reporter").feedbackCount, 1);
  });

  it("enforces three submissions per anchored 24-hour window", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    for (let index = 1; index <= 3; index++) {
      await handleSubmitFeedback({
        uid: "reporter",
        data: { category: "suggestion", message: `message ${index}`, followUpOk: false },
        firestore: harness.firestore,
        clock: () => NOW,
      });
    }
    await expectCode(handleSubmitFeedback({
      uid: "reporter",
      data: { category: "other", message: "message 4", followUpOk: false },
      firestore: harness.firestore,
      clock: () => NOW,
    }), "resource-exhausted");
    assert.strictEqual(harness.count("feedback"), 3);
    assert.strictEqual(harness.read("safetyRateLimits", "reporter").feedbackCount, 3);
  });

  it("resets an expired feedback window and preserves report state", async () => {
    const harness = makeHarness();
    seedReporter(harness);
    harness.seed("safetyRateLimits", "reporter", {
      feedbackWindowStartedAt: admin.firestore.Timestamp.fromMillis(NOW.toMillis() - DAY_MS),
      feedbackCount: 3,
      reportCount: 7,
    });

    await handleSubmitFeedback({
      uid: "reporter",
      data: { category: "question", message: "hello", followUpOk: false },
      firestore: harness.firestore,
      clock: () => NOW,
    });
    const rate = harness.read("safetyRateLimits", "reporter");
    assert.strictEqual(rate.feedbackCount, 1);
    assert.strictEqual(rate.feedbackWindowStartedAt, NOW);
    assert.strictEqual(rate.reportCount, 7);
  });
});

describe("safety rate-state support", () => {
  it("treats a future window as malformed and starts one bounded window", () => {
    const result = planAnchoredWindow({
      storedWindowStartedAt: admin.firestore.Timestamp.fromMillis(NOW.toMillis() + HOUR_MS),
      storedCount: 1000,
      now: NOW,
      windowMs: HOUR_MS,
      limit: 5,
    });
    assert.strictEqual(result.allowed, true);
    assert.strictEqual(result.nextCount, 1);
    assert.strictEqual(result.windowStartedAt, NOW);
  });

  it("deletes account-owned rate state and treats a missing document as a no-op", async () => {
    const harness = makeHarness();
    harness.seed("safetyRateLimits", "reporter", { reportCount: 1 });
    await deleteSafetyRateState("reporter", harness.firestore);
    await deleteSafetyRateState("reporter", harness.firestore);
    assert.strictEqual(harness.count("safetyRateLimits"), 0);
  });
});
