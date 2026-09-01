import * as admin from "firebase-admin";
import { createHash } from "node:crypto";
import { HttpsError } from "firebase-functions/v2/https";
import { isValidStoredEvidence } from "./chant_trust";
import { CURRENT_POLICY_VERSION } from "./policy";
import { planAnchoredWindow } from "./safety_submission";

const SCHEMA_VERSION = 1;
const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;
const HOUR_LIMIT = 5;
const DAY_LIMIT = 20;
const VALID_KINDS = new Set(["correction", "variation", "evidence"]);
const VALID_CATEGORIES = new Set([
  "lyrics",
  "title",
  "tune",
  "player",
  "club",
  "era",
  "other",
]);
const VALID_RESOLUTION_KINDS = new Set([
  "primary",
  "variation",
  "era",
  "evidence",
]);
const TERMINAL_STATUSES = new Set(["updated", "notChanged"]);

type Clock = () => admin.firestore.Timestamp;

type Submission = {
  chantId: string;
  kind: "correction" | "variation" | "evidence";
  category:
    | "lyrics"
    | "title"
    | "tune"
    | "player"
    | "club"
    | "era"
    | "other"
    | null;
  message: string;
  evidence: Record<string, unknown> | null;
};

type ModerationAction =
  | "plan"
  | "updated"
  | "notChanged"
  | "acceptEvidence"
  | "acceptAndPromote";

type ModerationRequest = {
  suggestionId: string;
  action: ModerationAction;
  resolutionKind: "primary" | "variation" | "era" | "evidence" | null;
  resolutionNote: string | null;
  acknowledgeStale: boolean;
  acknowledgeEvidenceReplacement: boolean;
};

function failedPrecondition(reason: string, message: string): HttpsError {
  return new HttpsError("failed-precondition", message, { reason });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasExactKeys(
  value: Record<string, unknown>,
  expected: readonly string[]
): boolean {
  const actual = Object.keys(value).sort();
  const sortedExpected = [...expected].sort();
  return actual.length === sortedExpected.length &&
    actual.every((key, index) => key === sortedExpected[index]);
}

function isTimestamp(value: unknown): value is admin.firestore.Timestamp {
  return typeof (value as { toMillis?: unknown } | undefined)?.toMillis ===
    "function";
}

function cleanId(value: unknown): string {
  return typeof value === "string" &&
    /^[A-Za-z0-9_-]{1,500}$/.test(value)
    ? value
    : "";
}

export function parseChantUpdateSubmission(value: unknown): Submission {
  if (
    !isRecord(value) ||
    !hasExactKeys(value, [
      "chantId",
      "kind",
      "category",
      "message",
      "evidence",
    ])
  ) {
    throw new HttpsError("invalid-argument", "Invalid chant update request.");
  }

  const chantId = cleanId(value.chantId);
  const kind = value.kind;
  const category = value.category;
  const rawMessage = value.message;
  const evidence = value.evidence;
  if (
    !chantId ||
    typeof kind !== "string" ||
    !VALID_KINDS.has(kind) ||
    typeof rawMessage !== "string"
  ) {
    throw new HttpsError("invalid-argument", "Invalid chant update request.");
  }
  const message = rawMessage.trim();
  if (message.length < 10 || message.length > 1000) {
    throw new HttpsError("invalid-argument", "Invalid chant update request.");
  }

  if (kind === "correction") {
    if (
      typeof category !== "string" ||
      !VALID_CATEGORIES.has(category) ||
      evidence !== null
    ) {
      throw new HttpsError("invalid-argument", "Invalid chant update request.");
    }
  } else if (category !== null) {
    throw new HttpsError("invalid-argument", "Invalid chant update request.");
  }

  if (kind === "evidence") {
    if (!isValidStoredEvidence(evidence)) {
      throw new HttpsError("invalid-argument", "Invalid chant evidence.");
    }
  } else if (evidence !== null) {
    throw new HttpsError("invalid-argument", "Invalid chant update request.");
  }

  return {
    chantId,
    kind: kind as Submission["kind"],
    category: category as Submission["category"],
    message,
    evidence: evidence as Record<string, unknown> | null,
  };
}

export function parseChantUpdateModeration(
  value: unknown
): ModerationRequest {
  if (
    !isRecord(value) ||
    !hasExactKeys(value, [
      "suggestionId",
      "action",
      "resolutionKind",
      "resolutionNote",
      "acknowledgeStale",
      "acknowledgeEvidenceReplacement",
    ])
  ) {
    throw new HttpsError("invalid-argument", "Invalid update review request.");
  }
  const suggestionId = cleanId(value.suggestionId);
  const action = value.action;
  const resolutionKind = value.resolutionKind;
  const rawNote = value.resolutionNote;
  if (
    !suggestionId ||
    typeof action !== "string" ||
    ![
      "plan",
      "updated",
      "notChanged",
      "acceptEvidence",
      "acceptAndPromote",
    ].includes(action) ||
    typeof value.acknowledgeStale !== "boolean" ||
    typeof value.acknowledgeEvidenceReplacement !== "boolean" ||
    (rawNote !== null && typeof rawNote !== "string")
  ) {
    throw new HttpsError("invalid-argument", "Invalid update review request.");
  }
  const resolutionNote = typeof rawNote === "string" ? rawNote.trim() : null;
  if (
    resolutionNote !== null &&
    (resolutionNote.length < 1 || resolutionNote.length > 500)
  ) {
    throw new HttpsError("invalid-argument", "Invalid update review request.");
  }

  if (action === "notChanged") {
    if (resolutionKind !== null || resolutionNote === null) {
      throw new HttpsError("invalid-argument", "A closure reason is required.");
    }
  } else {
    if (
      typeof resolutionKind !== "string" ||
      !VALID_RESOLUTION_KINDS.has(resolutionKind)
    ) {
      throw new HttpsError("invalid-argument", "A resolution target is required.");
    }
    if (
      (action === "acceptEvidence" || action === "acceptAndPromote") &&
      resolutionKind !== "evidence"
    ) {
      throw new HttpsError("invalid-argument", "Invalid evidence review request.");
    }
  }

  return {
    suggestionId,
    action: action as ModerationAction,
    resolutionKind: resolutionKind as ModerationRequest["resolutionKind"],
    resolutionNote,
    acknowledgeStale: value.acknowledgeStale,
    acknowledgeEvidenceReplacement: value.acknowledgeEvidenceReplacement,
  };
}

function requireActiveSubmitter(
  profile: admin.firestore.DocumentData | undefined,
  deletionJobExists: boolean
): void {
  if (
    !profile ||
    profile.banned !== false ||
    profile.ageConfirmed17Plus !== true ||
    profile.acceptedPolicyVersion !== CURRENT_POLICY_VERSION
  ) {
    throw new HttpsError(
      "permission-denied",
      "This account cannot suggest chant updates."
    );
  }
  if (profile.deletionPending === true || deletionJobExists) {
    throw failedPrecondition(
      "account-deletion-in-progress",
      "Account deletion is in progress."
    );
  }
}

function requireOperator(
  profile: admin.firestore.DocumentData | undefined,
  deletionJobExists: boolean
): void {
  if (profile?.deletionPending === true || deletionJobExists) {
    throw failedPrecondition(
      "account-deletion-in-progress",
      "Account deletion is in progress."
    );
  }
  if (
    !profile ||
    profile.role !== "operator" ||
    profile.banned !== false
  ) {
    throw new HttpsError("permission-denied", "Operator access required.");
  }
}

function isVisibleChant(
  chant: admin.firestore.DocumentData | undefined
): chant is admin.firestore.DocumentData {
  return !!chant &&
    chant.hidden === false &&
    chant.removed === false &&
    (chant.status === "community" || chant.status === "canonical") &&
    typeof chant.title === "string" &&
    chant.title.length >= 1 &&
    chant.title.length <= 200 &&
    isTimestamp(chant.updatedAt);
}

function requireVisibleChant(
  chant: admin.firestore.DocumentData | undefined
): asserts chant is admin.firestore.DocumentData {
  if (!isVisibleChant(chant)) {
    throw failedPrecondition("chant-unavailable", "This chant is unavailable.");
  }
}

function evidenceEquals(left: unknown, right: unknown): boolean {
  if (!isValidStoredEvidence(left) || !isValidStoredEvidence(right)) {
    return false;
  }
  const leftEvidence = left as Record<string, unknown>;
  const rightEvidence = right as Record<string, unknown>;
  return leftEvidence.provider === rightEvidence.provider &&
    leftEvidence.url === rightEvidence.url;
}

export function chantUpdateSuggestionId(params: {
  uid: string;
  chantId: string;
  chantUpdatedAt: admin.firestore.Timestamp;
  kind: string;
  category: string | null;
}): string {
  return createHash("sha256")
    .update([
      params.uid,
      params.chantId,
      String(params.chantUpdatedAt.toMillis()),
      params.kind,
      params.category ?? "",
    ].join("\u0000"))
    .digest("hex");
}

export async function handleSubmitChantUpdateSuggestion(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  clock: Clock;
}): Promise<{ success: true; suggestionId: string }> {
  const input = parseChantUpdateSubmission(params.data);
  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const deletionRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.uid);
  const chantRef = params.firestore.collection("chants").doc(input.chantId);
  const rateRef = params.firestore.collection("safetyRateLimits").doc(params.uid);
  const now = params.clock();
  let suggestionId = "";

  await params.firestore.runTransaction(async (transaction) => {
    const [profileSnapshot, deletionSnapshot, chantSnapshot, rateSnapshot] =
      await Promise.all([
        transaction.get(profileRef),
        transaction.get(deletionRef),
        transaction.get(chantRef),
        transaction.get(rateRef),
      ]);
    requireActiveSubmitter(profileSnapshot.data(), deletionSnapshot.exists);
    const chant = chantSnapshot.data();
    requireVisibleChant(chant);

    suggestionId = chantUpdateSuggestionId({
      uid: params.uid,
      chantId: input.chantId,
      chantUpdatedAt: chant.updatedAt,
      kind: input.kind,
      category: input.category,
    });
    const suggestionRef = params.firestore
      .collection("chantUpdateSuggestions")
      .doc(suggestionId);
    const suggestionSnapshot = await transaction.get(suggestionRef);
    if (suggestionSnapshot.exists) {
      throw new HttpsError(
        "already-exists",
        "You already sent this update for the current chant version."
      );
    }

    const rate = rateSnapshot.data() ?? {};
    const hourPlan = planAnchoredWindow({
      storedWindowStartedAt: rate.chantUpdateHourStartedAt,
      storedCount: rate.chantUpdateHourCount,
      now,
      windowMs: HOUR_MS,
      limit: HOUR_LIMIT,
    });
    const dayPlan = planAnchoredWindow({
      storedWindowStartedAt: rate.chantUpdateDayStartedAt,
      storedCount: rate.chantUpdateDayCount,
      now,
      windowMs: DAY_MS,
      limit: DAY_LIMIT,
    });
    if (!hourPlan.allowed || !dayPlan.allowed) {
      throw new HttpsError(
        "resource-exhausted",
        "Chant update submission limit reached."
      );
    }

    transaction.create(suggestionRef, {
      schemaVersion: SCHEMA_VERSION,
      chantId: input.chantId,
      chantTitleSnapshot: chant.title,
      submittedBy: params.uid,
      kind: input.kind,
      category: input.category,
      message: input.message,
      evidence: input.evidence,
      chantUpdatedAt: chant.updatedAt,
      status: "received",
      resolutionKind: null,
      resolutionNote: null,
      createdAt: now,
      updatedAt: now,
      resolvedAt: null,
    });
    transaction.set(rateRef, {
      chantUpdateHourStartedAt: hourPlan.windowStartedAt,
      chantUpdateHourCount: hourPlan.nextCount,
      chantUpdateDayStartedAt: dayPlan.windowStartedAt,
      chantUpdateDayCount: dayPlan.nextCount,
      updatedAt: now,
    }, { merge: true });
  });

  return { success: true, suggestionId };
}

function validSuggestion(
  value: admin.firestore.DocumentData | undefined
): value is admin.firestore.DocumentData {
  return !!value &&
    value.schemaVersion === SCHEMA_VERSION &&
    cleanId(value.chantId).length > 0 &&
    cleanId(value.submittedBy).length > 0 &&
    VALID_KINDS.has(value.kind) &&
    ["received", "planned", "updated", "notChanged"].includes(value.status) &&
    isTimestamp(value.chantUpdatedAt);
}

export async function handleModerateChantUpdateSuggestion(params: {
  actorUid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  clock: Clock;
  newAuditId: () => string;
}): Promise<{ success: true; status: string }> {
  const input = parseChantUpdateModeration(params.data);
  const suggestionRef = params.firestore
    .collection("chantUpdateSuggestions")
    .doc(input.suggestionId);
  const actorProfileRef = params.firestore
    .collection("profiles")
    .doc(params.actorUid);
  const actorDeletionRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.actorUid);
  const now = params.clock();
  let status = "";

  await params.firestore.runTransaction(async (transaction) => {
    const [
      suggestionSnapshot,
      actorProfileSnapshot,
      actorDeletionSnapshot,
    ] = await Promise.all([
      transaction.get(suggestionRef),
      transaction.get(actorProfileRef),
      transaction.get(actorDeletionRef),
    ]);
    requireOperator(actorProfileSnapshot.data(), actorDeletionSnapshot.exists);
    const suggestion = suggestionSnapshot.data();
    if (!validSuggestion(suggestion)) {
      throw new HttpsError("not-found", "Chant update request not found.");
    }
    if (TERMINAL_STATUSES.has(suggestion.status)) {
      throw failedPrecondition(
        "request-already-closed",
        "This request is already closed."
      );
    }

    const chantRef = params.firestore
      .collection("chants")
      .doc(suggestion.chantId);
    const chantSnapshot = await transaction.get(chantRef);
    const chant = chantSnapshot.data();
    const visibleChant = isVisibleChant(chant);
    if (!visibleChant && input.action !== "notChanged") {
      throw failedPrecondition("chant-unavailable", "This chant is unavailable.");
    }
    const stale = visibleChant &&
      chant.updatedAt.toMillis() !== suggestion.chantUpdatedAt.toMillis();
    if (
      (stale && !input.acknowledgeStale) ||
      (stale &&
        (input.action === "acceptEvidence" ||
          input.action === "acceptAndPromote"))
    ) {
      throw failedPrecondition(
        "stale-chant-version",
        "The chant changed after this request was submitted."
      );
    }

    const evidenceAction =
      input.action === "acceptEvidence" ||
      input.action === "acceptAndPromote";
    if (
      (suggestion.kind === "evidence" &&
        (input.action === "plan" || input.action === "updated")) ||
      (suggestion.kind !== "evidence" &&
        (evidenceAction || input.resolutionKind === "evidence"))
    ) {
      throw failedPrecondition(
        "review-action-mismatch",
        "This review action does not match the request type."
      );
    }

    if (evidenceAction) {
      requireVisibleChant(chant);
      if (
        suggestion.kind !== "evidence" ||
        !isValidStoredEvidence(suggestion.evidence)
      ) {
        throw failedPrecondition(
          "review-action-mismatch",
          "This evidence cannot update the current chant."
        );
      }
      const promotes = input.action === "acceptAndPromote";
      if (
        promotes &&
        (chant.status !== "community" || chant.createdBy === "system")
      ) {
        throw failedPrecondition(
          "review-action-mismatch",
          "This evidence cannot promote the current chant."
        );
      }
      if (
        !promotes &&
        chant.status !== "canonical" &&
        !(chant.status === "community" && chant.createdBy === "system")
      ) {
        throw failedPrecondition(
          "review-action-mismatch",
          "This evidence action does not match the current chant."
        );
      }
      const previousEvidence = isValidStoredEvidence(chant.evidence)
        ? chant.evidence
        : null;
      const replacesEvidence = previousEvidence !== null &&
        !evidenceEquals(previousEvidence, suggestion.evidence);
      if (replacesEvidence && !input.acknowledgeEvidenceReplacement) {
        throw failedPrecondition(
          "evidence-replacement-unconfirmed",
          "Confirm replacement of the chant's existing evidence."
        );
      }
      const auditRef = params.firestore
        .collection("auditLog")
        .doc(params.newAuditId());
      const notificationId = createHash("sha256")
        .update(`chant-promoted\u0000${suggestion.chantId}`)
        .digest("hex");
      const notificationRef = params.firestore
        .collection("creatorNotifications")
        .doc(notificationId);
      const notificationSnapshot = await transaction.get(notificationRef);
      transaction.update(chantRef, {
        evidence: suggestion.evidence,
        ...(promotes ? { status: "canonical" } : {}),
        updatedAt: now,
      });
      transaction.update(suggestionRef, {
        status: "updated",
        resolutionKind: "evidence",
        resolutionNote: input.resolutionNote,
        updatedAt: now,
        resolvedAt: now,
      });
      transaction.create(auditRef, {
        actorId: params.actorUid,
        action: "accept-chant-evidence",
        targetType: "chant",
        targetId: suggestion.chantId,
        detail: promotes
          ? `Accepted suggestion ${input.suggestionId}; promoted to Terrace Proven.`
          : replacesEvidence
          ? `Accepted evidence suggestion ${input.suggestionId} and replaced prior evidence.`
          : `Accepted evidence suggestion ${input.suggestionId}.`,
        previousEvidence: replacesEvidence ? previousEvidence : null,
        createdAt: now,
      });
      if (
        promotes &&
        !notificationSnapshot.exists &&
        cleanId(chant.createdBy) &&
        chant.createdBy !== "system" &&
        chant.createdBy !== "deleted-user"
      ) {
        transaction.create(notificationRef, {
          schemaVersion: 1,
          ownerId: chant.createdBy,
          actorId: "chants",
          actorHandle: "chants",
          actorDisplayName: "Chants",
          type: "chant_promoted",
          performanceId: null,
          commentId: null,
          chantId: suggestion.chantId,
          read: false,
          createdAt: now,
          readAt: null,
        });
      }
      status = "updated";
      return;
    }

    if (input.action === "plan") {
      requireVisibleChant(chant);
      transaction.update(suggestionRef, {
        status: "planned",
        resolutionKind: input.resolutionKind,
        resolutionNote: input.resolutionNote,
        updatedAt: now,
        resolvedAt: null,
      });
      status = "planned";
      return;
    }

    status = input.action;
    transaction.update(suggestionRef, {
      status,
      resolutionKind: input.resolutionKind,
      resolutionNote: input.resolutionNote,
      updatedAt: now,
      resolvedAt: now,
    });
    const auditRef = params.firestore
      .collection("auditLog")
      .doc(params.newAuditId());
    transaction.create(auditRef, {
      actorId: params.actorUid,
      action: status === "updated"
        ? "resolve-chant-update"
        : "decline-chant-update",
      targetType: "chant",
      targetId: suggestion.chantId,
      detail: `Resolved suggestion ${input.suggestionId} as ${status}.`,
      createdAt: now,
    });
  });

  return { success: true, status };
}
