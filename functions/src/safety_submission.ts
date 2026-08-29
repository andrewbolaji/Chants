import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

const NEW_ACCOUNT_AGE_MS = 24 * 60 * 60 * 1000;
const REPORT_WINDOW_MS = 60 * 60 * 1000;
const FEEDBACK_WINDOW_MS = 24 * 60 * 60 * 1000;
const NEW_ACCOUNT_REPORT_LIMIT = 5;
const ESTABLISHED_ACCOUNT_REPORT_LIMIT = 20;
const FEEDBACK_LIMIT = 3;

const FEEDBACK_CATEGORIES = new Set([
  "suggestion",
  "bug",
  "question",
  "other",
]);

type ReportTargetType =
  | "chant"
  | "comment"
  | "user"
  | "performance"
  | "performanceComment";

type Clock = () => admin.firestore.Timestamp;

type AnchoredWindowPlan = {
  allowed: boolean;
  windowStartedAt: admin.firestore.Timestamp;
  nextCount: number;
};

type ReportTargetConfig = {
  targetCollection:
    | "chants"
    | "comments"
    | "profiles"
    | "performances"
    | "performanceComments";
  reportCollection:
    | "reports"
    | "commentReports"
    | "userReports"
    | "performanceReports"
    | "performanceCommentReports";
  targetField:
    | "chantId"
    | "commentId"
    | "reportedUserId"
    | "performanceId"
    | "performanceCommentId";
};

const REPORT_TARGET_CONFIG: Record<ReportTargetType, ReportTargetConfig> = {
  chant: {
    targetCollection: "chants",
    reportCollection: "reports",
    targetField: "chantId",
  },
  comment: {
    targetCollection: "comments",
    reportCollection: "commentReports",
    targetField: "commentId",
  },
  user: {
    targetCollection: "profiles",
    reportCollection: "userReports",
    targetField: "reportedUserId",
  },
  performance: {
    targetCollection: "performances",
    reportCollection: "performanceReports",
    targetField: "performanceId",
  },
  performanceComment: {
    targetCollection: "performanceComments",
    reportCollection: "performanceCommentReports",
    targetField: "performanceCommentId",
  },
};

export function requireAuthenticatedUid(
  auth: { uid: string } | undefined
): string {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  return auth.uid;
}

export function requireVerifiedUid(
  auth: {
    uid: string;
    token?: Record<string, unknown>;
  } | undefined
): string {
  const uid = requireAuthenticatedUid(auth);
  const token = auth?.token;
  const hasVerifiedEmail = token?.email_verified === true;
  const phoneNumber = token?.phone_number;
  const hasVerifiedPhone = typeof phoneNumber === "string" &&
    phoneNumber.trim().length > 0;
  const firebaseClaim = token?.firebase;
  const signInProvider = isRecord(firebaseClaim)
    ? firebaseClaim.sign_in_provider
    : undefined;
  const identities = isRecord(firebaseClaim)
    ? firebaseClaim.identities
    : undefined;
  const trustedProviders = ["apple.com", "google.com", "facebook.com"];
  const hasTrustedFederatedProvider =
    (typeof signInProvider === "string" &&
      trustedProviders.includes(signInProvider)) ||
    (isRecord(identities) && trustedProviders.some((provider) => {
      const identityValues = identities[provider];
      return Array.isArray(identityValues) && identityValues.length > 0;
    }));
  if (!hasVerifiedEmail && !hasVerifiedPhone && !hasTrustedFederatedProvider) {
    throw new HttpsError(
      "permission-denied",
      "Verify an email address or phone number to continue."
    );
  }
  return uid;
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

function timestampMillis(value: unknown): number | undefined {
  if (!isRecord(value) && typeof value !== "object") return undefined;
  const candidate = value as { toMillis?: () => number } | null;
  if (!candidate || typeof candidate.toMillis !== "function") return undefined;
  const millis = candidate.toMillis();
  return Number.isFinite(millis) ? millis : undefined;
}

function reportLimit(profileCreatedAt: unknown, nowMs: number): number {
  const createdAtMs = timestampMillis(profileCreatedAt);
  if (createdAtMs === undefined) return NEW_ACCOUNT_REPORT_LIMIT;

  const accountAgeMs = nowMs - createdAtMs;
  if (accountAgeMs < NEW_ACCOUNT_AGE_MS) return NEW_ACCOUNT_REPORT_LIMIT;
  return ESTABLISHED_ACCOUNT_REPORT_LIMIT;
}

export function planAnchoredWindow(params: {
  storedWindowStartedAt: unknown;
  storedCount: unknown;
  now: admin.firestore.Timestamp;
  windowMs: number;
  limit: number;
}): AnchoredWindowPlan {
  const nowMs = params.now.toMillis();
  const storedStartMs = timestampMillis(params.storedWindowStartedAt);
  const hasUsableStart = storedStartMs !== undefined &&
    storedStartMs <= nowMs &&
    nowMs - storedStartMs < params.windowMs;

  if (!hasUsableStart) {
    return {
      allowed: true,
      windowStartedAt: params.now,
      nextCount: 1,
    };
  }

  const storedCount = params.storedCount;
  const safeCount = typeof storedCount === "number" &&
    Number.isInteger(storedCount) && storedCount >= 0
    ? storedCount
    : params.limit;

  if (safeCount >= params.limit) {
    return {
      allowed: false,
      windowStartedAt: params.storedWindowStartedAt as admin.firestore.Timestamp,
      nextCount: safeCount,
    };
  }

  return {
    allowed: true,
    windowStartedAt: params.storedWindowStartedAt as admin.firestore.Timestamp,
    nextCount: safeCount + 1,
  };
}

function parseReportPayload(data: unknown): {
  targetType: ReportTargetType;
  targetId: string;
  reason: string;
} {
  if (!isRecord(data) || !hasExactKeys(data, ["targetType", "targetId", "reason"])) {
    throw new HttpsError("invalid-argument", "Invalid report request.");
  }

  const targetType = data.targetType;
  const rawTargetId = data.targetId;
  const rawReason = data.reason;
  if (
    (targetType !== "chant" &&
      targetType !== "comment" &&
      targetType !== "user" &&
      targetType !== "performance" &&
      targetType !== "performanceComment") ||
    typeof rawTargetId !== "string" ||
    typeof rawReason !== "string"
  ) {
    throw new HttpsError("invalid-argument", "Invalid report request.");
  }

  const targetId = rawTargetId.trim();
  const reason = rawReason.trim();
  if (
    targetId.length < 1 ||
    targetId.length > 512 ||
    targetId.includes("/") ||
    reason.length < 1 ||
    reason.length > 250
  ) {
    throw new HttpsError("invalid-argument", "Invalid report request.");
  }

  return { targetType, targetId, reason };
}

function parseFeedbackPayload(data: unknown): {
  category: string;
  message: string;
  followUpOk: boolean;
} {
  if (!isRecord(data) || !hasExactKeys(data, ["category", "message", "followUpOk"])) {
    throw new HttpsError("invalid-argument", "Invalid feedback request.");
  }

  const rawCategory = data.category;
  const rawMessage = data.message;
  const followUpOk = data.followUpOk;
  if (
    typeof rawCategory !== "string" ||
    !FEEDBACK_CATEGORIES.has(rawCategory) ||
    typeof rawMessage !== "string" ||
    typeof followUpOk !== "boolean"
  ) {
    throw new HttpsError("invalid-argument", "Invalid feedback request.");
  }

  const message = rawMessage.trim();
  if (message.length < 1 || message.length > 1000) {
    throw new HttpsError("invalid-argument", "Invalid feedback request.");
  }

  return { category: rawCategory, message, followUpOk };
}

function validateReporterProfile(
  snapshot: admin.firestore.DocumentSnapshot
): admin.firestore.DocumentData {
  if (!snapshot.exists) {
    throw new HttpsError("failed-precondition", "Reporter profile is unavailable.");
  }
  const profile = snapshot.data()!;
  if (profile.banned === true) {
    throw new HttpsError("permission-denied", "This account cannot submit reports or feedback.");
  }
  if (profile.banned !== false) {
    throw new HttpsError("failed-precondition", "Reporter profile is unavailable.");
  }
  if (profile.deletionPending === true) {
    throw new HttpsError("failed-precondition", "Account deletion is in progress.");
  }
  return profile;
}

export async function handleSubmitReport(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  clock: Clock;
}): Promise<{ success: true }> {
  const payload = parseReportPayload(params.data);
  if (payload.targetType === "user" && payload.targetId === params.uid) {
    throw new HttpsError("invalid-argument", "You cannot report your own account.");
  }
  if (Buffer.byteLength(`${params.uid}_${payload.targetId}`, "utf8") > 1500) {
    throw new HttpsError("invalid-argument", "Invalid report request.");
  }

  const targetConfig = REPORT_TARGET_CONFIG[payload.targetType];
  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const targetRef = params.firestore
    .collection(targetConfig.targetCollection)
    .doc(payload.targetId);
  const reportRef = params.firestore
    .collection(targetConfig.reportCollection)
    .doc(`${params.uid}_${payload.targetId}`);
  const rateRef = params.firestore.collection("safetyRateLimits").doc(params.uid);
  const targetDeletionJobRef = payload.targetType === "user"
    ? params.firestore.collection("accountDeletionJobs").doc(payload.targetId)
    : null;
  const now = params.clock();

  await params.firestore.runTransaction(async (transaction) => {
    const [
      profileSnapshot,
      targetSnapshot,
      reportSnapshot,
      rateSnapshot,
      targetDeletionJobSnapshot,
    ] =
      await Promise.all([
        transaction.get(profileRef),
        transaction.get(targetRef),
        transaction.get(reportRef),
        transaction.get(rateRef),
        targetDeletionJobRef === null
          ? Promise.resolve(null)
          : transaction.get(targetDeletionJobRef),
      ]);

    const profile = validateReporterProfile(profileSnapshot);
    if (!targetSnapshot.exists) {
      throw new HttpsError("not-found", "Report target not found.");
    }
    if (payload.targetType === "user") {
      if (
        targetSnapshot.data()?.deletionPending === true ||
        targetDeletionJobSnapshot?.exists === true
      ) {
        throw new HttpsError(
          "failed-precondition",
          "Report target is unavailable."
        );
      }
    } else {
      const target = targetSnapshot.data()!;
      if (target.hidden !== false || target.removed !== false) {
        throw new HttpsError("failed-precondition", "Report target is unavailable.");
      }
      if (
        (payload.targetType === "performance" &&
          target.creatorId === params.uid) ||
        (payload.targetType === "performanceComment" &&
          target.userId === params.uid)
      ) {
        throw new HttpsError("invalid-argument", "You cannot report your own content.");
      }
    }
    if (reportSnapshot.exists) {
      throw new HttpsError("already-exists", "This target was already reported.");
    }

    const rateData = rateSnapshot.data() ?? {};
    const limit = reportLimit(profile.createdAt, now.toMillis());
    const ratePlan = planAnchoredWindow({
      storedWindowStartedAt: rateData.reportWindowStartedAt,
      storedCount: rateData.reportCount,
      now,
      windowMs: REPORT_WINDOW_MS,
      limit,
    });
    if (!ratePlan.allowed) {
      throw new HttpsError("resource-exhausted", "Report submission limit reached.");
    }

    transaction.set(reportRef, {
      [targetConfig.targetField]: payload.targetId,
      reportedBy: params.uid,
      reason: payload.reason,
      createdAt: now,
      status: "pending",
    });
    transaction.set(rateRef, {
      reportWindowStartedAt: ratePlan.windowStartedAt,
      reportCount: ratePlan.nextCount,
      updatedAt: now,
    }, { merge: true });
  });

  return { success: true };
}

export async function handleSubmitFeedback(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  clock: Clock;
}): Promise<{ success: true }> {
  const payload = parseFeedbackPayload(params.data);
  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const feedbackRef = params.firestore.collection("feedback").doc();
  const rateRef = params.firestore.collection("safetyRateLimits").doc(params.uid);
  const now = params.clock();

  await params.firestore.runTransaction(async (transaction) => {
    const [profileSnapshot, rateSnapshot] = await Promise.all([
      transaction.get(profileRef),
      transaction.get(rateRef),
    ]);

    validateReporterProfile(profileSnapshot);
    const rateData = rateSnapshot.data() ?? {};
    const ratePlan = planAnchoredWindow({
      storedWindowStartedAt: rateData.feedbackWindowStartedAt,
      storedCount: rateData.feedbackCount,
      now,
      windowMs: FEEDBACK_WINDOW_MS,
      limit: FEEDBACK_LIMIT,
    });
    if (!ratePlan.allowed) {
      throw new HttpsError("resource-exhausted", "Feedback submission limit reached.");
    }

    transaction.set(feedbackRef, {
      userId: params.uid,
      category: payload.category,
      message: payload.message,
      followUpOk: payload.followUpOk,
      createdAt: now,
      resolved: false,
    });
    transaction.set(rateRef, {
      feedbackWindowStartedAt: ratePlan.windowStartedAt,
      feedbackCount: ratePlan.nextCount,
      updatedAt: now,
    }, { merge: true });
  });

  return { success: true };
}

export async function deleteSafetyRateState(
  uid: string,
  firestore: admin.firestore.Firestore
): Promise<void> {
  await firestore.collection("safetyRateLimits").doc(uid).delete();
}
