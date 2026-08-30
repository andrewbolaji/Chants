import { describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import {
  chantUpdateSuggestionId,
  handleModerateChantUpdateSuggestion,
  handleSubmitChantUpdateSuggestion,
  parseChantUpdateModeration,
  parseChantUpdateSubmission,
} from "../src/living_songbook";

type Data = Record<string, unknown>;
type Store = Record<string, Record<string, Data>>;
type Ref = { collectionName: string; id: string; path: string };
type Write = {
  kind: "create" | "set" | "update" | "delete";
  ref: Ref;
  data?: Data;
  merge?: boolean;
};

function makeHarness(options: { retryOnce?: boolean } = {}) {
  const store: Store = {};
  let retried = false;
  const bucket = (collection: string) => store[collection] ??= {};
  const ref = (collectionName: string, id: string): Ref => ({
    collectionName,
    id,
    path: `${collectionName}/${id}`,
  });
  const snapshot = (reference: Ref) => {
    const data = bucket(reference.collectionName)[reference.id];
    return {
      exists: data !== undefined,
      data: () => data === undefined ? undefined : { ...data },
    };
  };
  const attempt = async (
    handler: (transaction: unknown) => Promise<unknown>
  ) => {
    const writes: Write[] = [];
    const result = await handler({
      get: async (reference: Ref) => snapshot(reference),
      create: (reference: Ref, data: Data) =>
        writes.push({ kind: "create", ref: reference, data }),
      set: (reference: Ref, data: Data, options?: { merge?: boolean }) =>
        writes.push({
          kind: "set",
          ref: reference,
          data,
          merge: options?.merge === true,
        }),
      update: (reference: Ref, data: Data) =>
        writes.push({ kind: "update", ref: reference, data }),
      delete: (reference: Ref) =>
        writes.push({ kind: "delete", ref: reference }),
    });
    return { result, writes };
  };
  const apply = (writes: Write[]) => {
    for (const write of writes) {
      const target = bucket(write.ref.collectionName);
      if (write.kind === "delete") {
        delete target[write.ref.id];
      } else if (write.kind === "create") {
        if (target[write.ref.id] !== undefined) {
          throw new Error("already exists");
        }
        target[write.ref.id] = { ...write.data! };
      } else if (write.kind === "update" || write.merge) {
        target[write.ref.id] = { ...target[write.ref.id], ...write.data! };
      } else {
        target[write.ref.id] = { ...write.data! };
      }
    }
  };
  const firestore = {
    collection: (collectionName: string) => ({
      doc: (id: string) => ref(collectionName, id),
    }),
    runTransaction: async (
      handler: (transaction: unknown) => Promise<unknown>
    ) => {
      if (options.retryOnce && !retried) {
        retried = true;
        await attempt(handler);
      }
      const result = await attempt(handler);
      apply(result.writes);
      return result.result;
    },
  } as unknown as admin.firestore.Firestore;
  return {
    firestore,
    seed: (collection: string, id: string, data: Data) => {
      bucket(collection)[id] = { ...data };
    },
    read: (collection: string, id: string) => bucket(collection)[id],
    count: (collection: string) => Object.keys(bucket(collection)).length,
  };
}

const NOW = admin.firestore.Timestamp.fromMillis(Date.UTC(2026, 7, 29, 18));
const EVIDENCE = {
  provider: "youtube",
  url: "https://www.youtube.com/watch?v=abcdefghijk",
};

function seedActiveUser(
  harness: ReturnType<typeof makeHarness>,
  uid = "supporter"
) {
  harness.seed("profiles", uid, {
    role: "user",
    banned: false,
    deletionPending: false,
    ageConfirmed17Plus: true,
    acceptedPolicyVersion: "v1",
  });
}

function seedOperator(harness: ReturnType<typeof makeHarness>) {
  harness.seed("profiles", "operator", {
    role: "operator",
    banned: false,
    deletionPending: false,
  });
}

function seedChant(
  harness: ReturnType<typeof makeHarness>,
  overrides: Data = {}
) {
  harness.seed("chants", "chant-1", {
    title: "North Bank Song",
    status: "community",
    createdBy: "creator-1",
    hidden: false,
    removed: false,
    updatedAt: NOW,
    ...overrides,
  });
}

function submission(overrides: Data = {}): Data {
  return {
    chantId: "chant-1",
    kind: "correction",
    category: "lyrics",
    message: "The second line should use the away wording.",
    evidence: null,
    ...overrides,
  };
}

async function expectCode(action: Promise<unknown>, code: string) {
  await assert.rejects(action, (error: unknown) =>
    error instanceof HttpsError && error.code === code
  );
}

async function expectReason(
  action: Promise<unknown>,
  code: string,
  reason: string
) {
  await assert.rejects(action, (error: unknown) =>
    error instanceof HttpsError &&
    error.code === code &&
    (error.details as { reason?: string } | undefined)?.reason === reason
  );
}

describe("Living Songbook submission", () => {
  it("parses exact cross-field shapes and rejects disguised evidence", () => {
    assert.strictEqual(
      parseChantUpdateSubmission(submission()).category,
      "lyrics"
    );
    assert.strictEqual(
      parseChantUpdateSubmission(submission({
        kind: "evidence",
        category: null,
        evidence: EVIDENCE,
      })).kind,
      "evidence"
    );
    for (const invalid of [
      { ...submission(), submittedBy: "attacker" },
      submission({ kind: "variation", category: "lyrics" }),
      submission({ kind: "evidence", category: null, evidence: null }),
      submission({
        kind: "evidence",
        category: null,
        evidence: {
          provider: "youtube",
          url: "https://evil.example/watch?v=abcdefghijk",
        },
      }),
    ]) {
      assert.throws(
        () => parseChantUpdateSubmission(invalid),
        (error: { code?: string }) => error.code === "invalid-argument"
      );
    }
  });

  it("derives identity and source version and keeps its own rate budget", async () => {
    const harness = makeHarness({ retryOnce: true });
    seedActiveUser(harness);
    seedChant(harness);

    const result = await handleSubmitChantUpdateSuggestion({
      uid: "supporter",
      data: submission(),
      firestore: harness.firestore,
      clock: () => NOW,
    });

    const expectedId = chantUpdateSuggestionId({
      uid: "supporter",
      chantId: "chant-1",
      chantUpdatedAt: NOW,
      kind: "correction",
      category: "lyrics",
    });
    assert.strictEqual(result.suggestionId, expectedId);
    assert.deepStrictEqual(harness.read("chantUpdateSuggestions", expectedId), {
      schemaVersion: 1,
      chantId: "chant-1",
      chantTitleSnapshot: "North Bank Song",
      submittedBy: "supporter",
      kind: "correction",
      category: "lyrics",
      message: "The second line should use the away wording.",
      evidence: null,
      chantUpdatedAt: NOW,
      status: "received",
      resolutionKind: null,
      resolutionNote: null,
      createdAt: NOW,
      updatedAt: NOW,
      resolvedAt: null,
    });
    const rate = harness.read("safetyRateLimits", "supporter");
    assert.strictEqual(rate.chantUpdateHourCount, 1);
    assert.strictEqual(rate.chantUpdateDayCount, 1);
    assert.strictEqual(rate.reportCount, undefined);
  });

  it("rejects duplicate and unavailable chants without spending budget", async () => {
    const harness = makeHarness();
    seedActiveUser(harness);
    seedChant(harness);
    const input = submission();
    await handleSubmitChantUpdateSuggestion({
      uid: "supporter",
      data: input,
      firestore: harness.firestore,
      clock: () => NOW,
    });
    await expectCode(handleSubmitChantUpdateSuggestion({
      uid: "supporter",
      data: input,
      firestore: harness.firestore,
      clock: () => NOW,
    }), "already-exists");
    assert.strictEqual(
      harness.read("safetyRateLimits", "supporter").chantUpdateHourCount,
      1
    );

    const hidden = makeHarness();
    seedActiveUser(hidden);
    seedChant(hidden, { hidden: true });
    await expectCode(handleSubmitChantUpdateSuggestion({
      uid: "supporter",
      data: input,
      firestore: hidden.firestore,
      clock: () => NOW,
    }), "failed-precondition");
    assert.strictEqual(hidden.count("safetyRateLimits"), 0);
  });

  it("enforces independent hourly and daily anchored limits", async () => {
    for (const [field, value] of [
      ["chantUpdateHourCount", 5],
      ["chantUpdateDayCount", 20],
    ] as const) {
      const harness = makeHarness();
      seedActiveUser(harness);
      seedChant(harness);
      harness.seed("safetyRateLimits", "supporter", {
        chantUpdateHourStartedAt: NOW,
        chantUpdateHourCount: field === "chantUpdateHourCount" ? value : 0,
        chantUpdateDayStartedAt: NOW,
        chantUpdateDayCount: field === "chantUpdateDayCount" ? value : 0,
        reportCount: 7,
      });
      await expectCode(handleSubmitChantUpdateSuggestion({
        uid: "supporter",
        data: submission(),
        firestore: harness.firestore,
        clock: () => NOW,
      }), "resource-exhausted");
      assert.strictEqual(harness.count("chantUpdateSuggestions"), 0);
      assert.strictEqual(
        harness.read("safetyRateLimits", "supporter").reportCount,
        7
      );
    }
  });

  it("denies inactive submitter states before writing or spending budget", async () => {
    const deniedProfiles = [
      { banned: true },
      { ageConfirmed17Plus: false },
      { acceptedPolicyVersion: "old" },
      { deletionPending: true },
    ];
    for (const profileOverride of deniedProfiles) {
      const harness = makeHarness();
      seedActiveUser(harness);
      harness.seed("profiles", "supporter", {
        role: "user",
        banned: false,
        deletionPending: false,
        ageConfirmed17Plus: true,
        acceptedPolicyVersion: "v1",
        ...profileOverride,
      });
      seedChant(harness);
      await expectCode(handleSubmitChantUpdateSuggestion({
        uid: "supporter",
        data: submission(),
        firestore: harness.firestore,
        clock: () => NOW,
      }), profileOverride.deletionPending ? "failed-precondition" : "permission-denied");
      assert.strictEqual(harness.count("chantUpdateSuggestions"), 0);
      assert.strictEqual(harness.count("safetyRateLimits"), 0);
    }

    const deletionJob = makeHarness();
    seedActiveUser(deletionJob);
    seedChant(deletionJob);
    deletionJob.seed("accountDeletionJobs", "supporter", { phase: "start" });
    await expectReason(handleSubmitChantUpdateSuggestion({
      uid: "supporter",
      data: submission(),
      firestore: deletionJob.firestore,
      clock: () => NOW,
    }), "failed-precondition", "account-deletion-in-progress");
    assert.strictEqual(deletionJob.count("chantUpdateSuggestions"), 0);
    assert.strictEqual(deletionJob.count("safetyRateLimits"), 0);
  });
});

describe("Living Songbook moderation", () => {
  function seedSuggestion(
    harness: ReturnType<typeof makeHarness>,
    overrides: Data = {}
  ) {
    harness.seed("chantUpdateSuggestions", "suggestion-1", {
      schemaVersion: 1,
      chantId: "chant-1",
      chantTitleSnapshot: "North Bank Song",
      submittedBy: "supporter",
      kind: "evidence",
      category: null,
      message: "This clip shows the whole end singing it.",
      evidence: EVIDENCE,
      chantUpdatedAt: NOW,
      status: "received",
      resolutionKind: null,
      resolutionNote: null,
      createdAt: NOW,
      updatedAt: NOW,
      resolvedAt: null,
      ...overrides,
    });
  }

  function review(overrides: Data = {}): Data {
    return {
      suggestionId: "suggestion-1",
      action: "acceptAndPromote",
      resolutionKind: "evidence",
      resolutionNote: "Evidence reviewed.",
      acknowledgeStale: false,
      acknowledgeEvidenceReplacement: false,
      ...overrides,
    };
  }

  it("requires exact moderation fields and a closure reason", () => {
    assert.strictEqual(parseChantUpdateModeration(review()).action,
      "acceptAndPromote");
    assert.throws(
      () => parseChantUpdateModeration(review({ actorUid: "attacker" })),
      (error: { code?: string }) => error.code === "invalid-argument"
    );
    assert.throws(
      () => parseChantUpdateModeration(review({
        action: "notChanged",
        resolutionKind: null,
        resolutionNote: null,
      })),
      (error: { code?: string }) => error.code === "invalid-argument"
    );
  });

  it("rejects review actions that do not match the request type", async () => {
    const evidenceHarness = makeHarness();
    seedOperator(evidenceHarness);
    seedChant(evidenceHarness);
    seedSuggestion(evidenceHarness);
    await expectCode(handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({ action: "updated", resolutionKind: "primary" }),
      firestore: evidenceHarness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-1",
    }), "failed-precondition");

    const correctionHarness = makeHarness();
    seedOperator(correctionHarness);
    seedChant(correctionHarness);
    seedSuggestion(correctionHarness, {
      kind: "correction",
      category: "lyrics",
      evidence: null,
    });
    await expectCode(handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({ action: "updated", resolutionKind: "evidence" }),
      firestore: correctionHarness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-1",
    }), "failed-precondition");
  });

  it("denies a nonoperator without writing resolution or audit state", async () => {
    const harness = makeHarness();
    seedActiveUser(harness, "operator");
    seedChant(harness);
    seedSuggestion(harness);
    await expectCode(handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review(),
      firestore: harness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-1",
    }), "permission-denied");
    assert.strictEqual(
      harness.read("chantUpdateSuggestions", "suggestion-1").status,
      "received"
    );
    assert.strictEqual(harness.count("auditLog"), 0);
  });

  it("atomically accepts evidence, promotes, audits, and notifies once", async () => {
    const harness = makeHarness({ retryOnce: true });
    seedOperator(harness);
    seedChant(harness);
    seedSuggestion(harness);

    const result = await handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review(),
      firestore: harness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-1",
    });

    assert.strictEqual(result.status, "updated");
    assert.deepStrictEqual(
      {
        status: harness.read("chants", "chant-1").status,
        evidence: harness.read("chants", "chant-1").evidence,
      },
      { status: "canonical", evidence: EVIDENCE }
    );
    assert.strictEqual(
      harness.read("chantUpdateSuggestions", "suggestion-1").status,
      "updated"
    );
    assert.strictEqual(harness.count("auditLog"), 1);
    assert.strictEqual(harness.count("creatorNotifications"), 1);
    assert.deepStrictEqual(harness.read("auditLog", "audit-1"), {
      actorId: "operator",
      action: "accept-chant-evidence",
      targetType: "chant",
      targetId: "chant-1",
      detail: "Accepted suggestion suggestion-1; promoted to Terrace Proven.",
      previousEvidence: null,
      createdAt: NOW,
    });

    await expectCode(handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review(),
      firestore: harness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-2",
    }), "failed-precondition");
    assert.strictEqual(harness.count("auditLog"), 1);
    assert.strictEqual(harness.count("creatorNotifications"), 1);
  });

  it("rejects stale evidence but allows an acknowledged planning action", async () => {
    const harness = makeHarness();
    seedOperator(harness);
    seedChant(harness, {
      updatedAt: admin.firestore.Timestamp.fromMillis(NOW.toMillis() + 1000),
    });
    seedSuggestion(harness);

    await expectCode(handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({ acknowledgeStale: true }),
      firestore: harness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-1",
    }), "failed-precondition");
    assert.strictEqual(harness.read("chants", "chant-1").status, "community");

    seedSuggestion(harness, {
      kind: "correction",
      category: "lyrics",
      evidence: null,
    });
    const planned = await handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({
        action: "plan",
        resolutionKind: "primary",
        acknowledgeStale: true,
      }),
      firestore: harness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-2",
    });
    assert.strictEqual(planned.status, "planned");
  });

  it("closes an unavailable request only through Not changed", async () => {
    const harness = makeHarness();
    seedOperator(harness);
    seedSuggestion(harness, {
      kind: "correction",
      category: "lyrics",
      evidence: null,
    });

    const result = await handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({
        action: "notChanged",
        resolutionKind: null,
        resolutionNote: "The source chant is no longer available.",
      }),
      firestore: harness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-1",
    });
    assert.strictEqual(result.status, "notChanged");
    assert.strictEqual(
      harness.read("chantUpdateSuggestions", "suggestion-1").status,
      "notChanged"
    );
    assert.strictEqual(harness.count("chants"), 0);

    const mutation = makeHarness();
    seedOperator(mutation);
    seedSuggestion(mutation, {
      kind: "correction",
      category: "lyrics",
      evidence: null,
    });
    await expectReason(handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({ action: "updated", resolutionKind: "primary" }),
      firestore: mutation.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-2",
    }), "failed-precondition", "chant-unavailable");
    assert.strictEqual(
      mutation.read("chantUpdateSuggestions", "suggestion-1").status,
      "received"
    );
  });

  it("requires explicit replacement and audits only prior public evidence", async () => {
    const previousEvidence = {
      provider: "x",
      url: "https://x.com/terrace/status/1234567890",
    };
    const harness = makeHarness();
    seedOperator(harness);
    seedChant(harness, {
      status: "canonical",
      createdBy: "system",
      evidence: previousEvidence,
    });
    seedSuggestion(harness);

    await expectReason(handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({ action: "acceptEvidence" }),
      firestore: harness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-1",
    }), "failed-precondition", "evidence-replacement-unconfirmed");
    assert.deepStrictEqual(harness.read("chants", "chant-1").evidence,
      previousEvidence);
    assert.strictEqual(harness.count("auditLog"), 0);

    await handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({
        action: "acceptEvidence",
        acknowledgeEvidenceReplacement: true,
      }),
      firestore: harness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-2",
    });
    assert.deepStrictEqual(harness.read("auditLog", "audit-2"), {
      actorId: "operator",
      action: "accept-chant-evidence",
      targetType: "chant",
      targetId: "chant-1",
      detail: "Accepted evidence suggestion suggestion-1 and replaced prior evidence.",
      previousEvidence,
      createdAt: NOW,
    });
    const auditText = JSON.stringify(harness.read("auditLog", "audit-2"));
    assert.strictEqual(auditText.includes("supporter"), false);
    assert.strictEqual(auditText.includes("whole end"), false);
    assert.strictEqual(auditText.includes(EVIDENCE.url), false);
  });

  it("attaches reviewed evidence to a current canonical chant without a promotion alert", async () => {
    const harness = makeHarness();
    seedOperator(harness);
    seedChant(harness, { status: "canonical", createdBy: "system" });
    seedSuggestion(harness);

    const result = await handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({
        action: "acceptEvidence",
        resolutionKind: "evidence",
      }),
      firestore: harness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-1",
    });

    assert.strictEqual(result.status, "updated");
    assert.deepStrictEqual(
      harness.read("chants", "chant-1").evidence,
      EVIDENCE
    );
    assert.strictEqual(
      harness.read("chants", "chant-1").status,
      "canonical"
    );
    assert.strictEqual(harness.count("creatorNotifications"), 0);
  });

  it("attaches evidence to a system-owned community chant without promotion", async () => {
    const harness = makeHarness();
    seedOperator(harness);
    seedChant(harness, { status: "community", createdBy: "system" });
    seedSuggestion(harness);

    await handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({ action: "acceptEvidence" }),
      firestore: harness.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-1",
    });

    assert.deepStrictEqual(harness.read("chants", "chant-1").evidence,
      EVIDENCE);
    assert.strictEqual(harness.read("chants", "chant-1").status, "community");
    assert.strictEqual(harness.count("creatorNotifications"), 0);

    const userCommunity = makeHarness();
    seedOperator(userCommunity);
    seedChant(userCommunity);
    seedSuggestion(userCommunity);
    await expectReason(handleModerateChantUpdateSuggestion({
      actorUid: "operator",
      data: review({ action: "acceptEvidence" }),
      firestore: userCommunity.firestore,
      clock: () => NOW,
      newAuditId: () => "audit-2",
    }), "failed-precondition", "review-action-mismatch");
  });

  it("never creates a promotion milestone for retained identity sentinels", async () => {
    for (const createdBy of ["system", "deleted-user"]) {
      const harness = makeHarness();
      seedOperator(harness);
      seedChant(harness, { createdBy });
      seedSuggestion(harness);
      if (createdBy === "system") {
        await handleModerateChantUpdateSuggestion({
          actorUid: "operator",
          data: review({ action: "acceptEvidence" }),
          firestore: harness.firestore,
          clock: () => NOW,
          newAuditId: () => "audit-1",
        });
      } else {
        await handleModerateChantUpdateSuggestion({
          actorUid: "operator",
          data: review(),
          firestore: harness.firestore,
          clock: () => NOW,
          newAuditId: () => "audit-1",
        });
      }
      assert.strictEqual(harness.count("creatorNotifications"), 0);
    }
  });
});
