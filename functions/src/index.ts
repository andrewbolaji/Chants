import * as admin from "firebase-admin";
import { onDocumentCreated, onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { writeAuditEntry } from "./audit";
import {
  ChantTrustAction,
  ChantTrustPlan,
  planChantTrustAction,
} from "./chant_trust";
import {
  deleteSafetyRateState,
  handleSubmitFeedback,
  handleSubmitReport,
  requireAuthenticatedUid,
} from "./safety_submission";

admin.initializeApp();
const db = admin.firestore();

const AUTO_HIDE_THRESHOLD = 3;

// Must match kCurrentPolicyVersion in lib/app/policy.dart and the version
// check in firestore.rules. Bump all three together, only for a substantive
// policy text change (a bump re-gates every existing user on next open).
const CURRENT_POLICY_VERSION = "v1";

export const submitReport = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireAuthenticatedUid(request.auth);
    return handleSubmitReport({
      uid,
      data: request.data,
      firestore: db,
      clock: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const submitFeedback = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireAuthenticatedUid(request.auth);
    return handleSubmitFeedback({
      uid,
      data: request.data,
      firestore: db,
      clock: () => admin.firestore.Timestamp.now(),
    });
  }
);

type ReportWriteResult = {
  flagCount: number;
  autoHidden: boolean;
  targetExists: boolean;
};

async function recomputeReportCount(
  beforeData: admin.firestore.DocumentData | undefined,
  afterData: admin.firestore.DocumentData | undefined,
  targetIdField: "chantId" | "commentId",
  reportsCollection: "reports" | "commentReports",
  targetCollection: "chants" | "comments",
  firestore: admin.firestore.Firestore
): Promise<ReportWriteResult> {
  const targetId = (afterData?.[targetIdField] || beforeData?.[targetIdField]) as string;
  if (!targetId) {
    return { flagCount: 0, autoHidden: false, targetExists: false };
  }

  const reportsQuery = firestore
    .collection(reportsCollection)
    .where(targetIdField, "==", targetId);
  const targetRef = firestore.collection(targetCollection).doc(targetId);
  return firestore.runTransaction(async (transaction) => {
    // Every invocation writes the same target document. If deliveries race,
    // that shared write forces a retry and a fresh query before commit.
    const reportsSnap = await transaction.get(reportsQuery);
    const targetSnap = await transaction.get(targetRef);
    let flagCount = 0;
    for (const report of reportsSnap.docs) {
      if (report.data().status === "pending") flagCount++;
    }

    if (!targetSnap.exists) {
      return { flagCount, autoHidden: false, targetExists: false };
    }

    const autoHidden =
      flagCount >= AUTO_HIDE_THRESHOLD && targetSnap.data()?.hidden === false;
    transaction.update(targetRef, {
      flagCount,
      ...(autoHidden ? { hidden: true } : {}),
    });

    return { flagCount, autoHidden, targetExists: true };
  });
}

export async function handleChantReportWritten(
  beforeData: admin.firestore.DocumentData | undefined,
  afterData: admin.firestore.DocumentData | undefined,
  firestore: admin.firestore.Firestore
): Promise<ReportWriteResult> {
  return recomputeReportCount(
    beforeData,
    afterData,
    "chantId",
    "reports",
    "chants",
    firestore
  );
}

export async function handleCommentReportWritten(
  beforeData: admin.firestore.DocumentData | undefined,
  afterData: admin.firestore.DocumentData | undefined,
  firestore: admin.firestore.Firestore
): Promise<ReportWriteResult> {
  return recomputeReportCount(
    beforeData,
    afterData,
    "commentId",
    "commentReports",
    "comments",
    firestore
  );
}

// Recomputes flagCount from pending report documents. An absolute count makes
// duplicate, out-of-order, status-change, and delete deliveries converge.
export const onReportCreated = onDocumentWritten(
  { document: "reports/{reportId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const result = await handleChantReportWritten(beforeData, afterData, db);
    const chantId = (afterData?.chantId || beforeData?.chantId) as string;

    if (result.autoHidden) {
      await writeAuditEntry({
        actorId: "system",
        action: "auto-hide",
        targetType: "chant",
        targetId: chantId,
        detail: `Auto-hidden: flagCount reached ${result.flagCount} (threshold ${AUTO_HIDE_THRESHOLD}).`,
      });
    }

    if (!beforeData && afterData) {
      await writeAuditEntry({
        actorId: afterData.reportedBy as string,
        action: "report",
        targetType: "chant",
        targetId: chantId,
        detail: `Reason: ${afterData.reason}`,
      });
    }
  }
);

// --- onModerationAction (callable) ---
// Operator-only. Actions include hide, unhide, remove, ban, and unban.
// Actor UID derived from auth context, never from client parameter.
// Fix 4: resolves associated reports and resets flagCount on unhide.
type UserBanAction = "ban" | "unban";

type UserProfileDocument = {
  get: () => Promise<{ exists: boolean }>;
  update: (data: { banned: boolean }) => Promise<unknown>;
};

type AuditWriter = (params: {
  actorId: string;
  action: string;
  targetType: string;
  targetId: string;
  detail: string;
}) => Promise<void>;

export async function handleUserBanAction(params: {
  action: UserBanAction;
  actorUid: string;
  targetId: string;
  profileDocument: UserProfileDocument;
  auditWriter: AuditWriter;
}): Promise<{ success: true }> {
  const targetProfile = await params.profileDocument.get();
  if (!targetProfile.exists) {
    throw new HttpsError("not-found", "User profile not found.");
  }

  const banned = params.action === "ban";
  await params.profileDocument.update({ banned });
  await params.auditWriter({
    actorId: params.actorUid,
    action: params.action,
    targetType: "user",
    targetId: params.targetId,
    detail: banned
      ? "User banned by operator."
      : "User unbanned by operator.",
  });
  return { success: true };
}

async function applyChantTrustAction(params: {
  action: ChantTrustAction;
  actorUid: string;
  targetId: string;
}): Promise<{ success: true; changed: boolean }> {
  const chantRef = db.collection("chants").doc(params.targetId);
  const auditRef = db.collection("auditLog").doc();
  let plan: ChantTrustPlan | undefined;

  await db.runTransaction(async (transaction) => {
    const chantSnap = await transaction.get(chantRef);
    if (!chantSnap.exists) {
      throw new HttpsError("not-found", "Chant not found.");
    }

    plan = planChantTrustAction(params.action, chantSnap.data()!);
    if (!plan.changed) return;

    const update: admin.firestore.UpdateData<admin.firestore.DocumentData> = {};
    if (plan.nextStatus) update.status = plan.nextStatus;
    if (plan.deleteEvidence) {
      update.evidence = admin.firestore.FieldValue.delete();
    }
    transaction.update(chantRef, update);
    transaction.set(auditRef, {
      actorId: params.actorUid,
      action: plan.auditAction,
      targetType: "chant",
      targetId: params.targetId,
      detail: plan.auditDetail,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  if (!plan) {
    throw new HttpsError("internal", "Moderation action was not planned.");
  }
  return { success: true, changed: plan.changed };
}

export const onModerationAction = onCall(
  { region: "europe-west2" },
  async (request) => {
    // Derive actor from auth context (hardening: never trust client-supplied UID)
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const actorUid = request.auth.uid;

    // Verify operator role via Admin SDK
    const actorProfile = await db.collection("profiles").doc(actorUid).get();
    if (!actorProfile.exists || actorProfile.data()?.role !== "operator") {
      throw new HttpsError("permission-denied", "Operator access required.");
    }

    const { action, targetId } = request.data as {
      action: string;
      targetId: string;
    };

    if (!action || !targetId) {
      throw new HttpsError("invalid-argument", "action and targetId are required.");
    }

    switch (action) {
      case "hide": {
        await db.collection("chants").doc(targetId).update({ hidden: true });
        // Fix 4: resolve associated reports
        await resolveReportsForChant(targetId, "reviewed");
        await writeAuditEntry({
          actorId: actorUid,
          action: "hide",
          targetType: "chant",
          targetId,
          detail: "Chant hidden by operator.",
        });
        return { success: true };
      }

      case "unhide": {
        // Fix 4: reset flagCount so cleared false positives do not re-trigger auto-hide
        await db.collection("chants").doc(targetId).update({
          hidden: false,
          flagCount: 0,
        });
        // Fix 4: dismiss associated reports (operator reviewed and cleared)
        await resolveReportsForChant(targetId, "dismissed");
        await writeAuditEntry({
          actorId: actorUid,
          action: "unhide",
          targetType: "chant",
          targetId,
          detail: "Chant unhidden by operator. flagCount reset to 0, reports dismissed.",
        });
        return { success: true };
      }

      case "remove": {
        await db.collection("chants").doc(targetId).update({ removed: true });
        await resolveReportsForChant(targetId, "reviewed");
        await writeAuditEntry({
          actorId: actorUid,
          action: "remove",
          targetType: "chant",
          targetId,
          detail: "Chant removed by operator.",
        });
        return { success: true };
      }

      case "ban":
      case "unban": {
        // targetId is the user's profile UID. The Admin SDK write remains
        // behind the operator role check above; clients cannot edit banned.
        return handleUserBanAction({
          action,
          actorUid,
          targetId,
          profileDocument: db.collection("profiles").doc(targetId),
          auditWriter: writeAuditEntry,
        });
      }

      case "promote":
      case "demote":
      case "remove-evidence":
        return applyChantTrustAction({ action, actorUid, targetId });

      case "hide-comment": {
        const cSnap = await db.collection("comments").doc(targetId).get();
        if (!cSnap.exists) {
          throw new HttpsError("not-found", "Comment not found.");
        }
        await db.collection("comments").doc(targetId).update({ hidden: true });
        await resolveCommentReports(targetId, "reviewed");
        await recomputeCommentCount(cSnap.data()!.chantId as string);
        await writeAuditEntry({
          actorId: actorUid,
          action: "hide",
          targetType: "comment",
          targetId,
          detail: "Comment hidden by operator.",
        });
        return { success: true };
      }

      case "unhide-comment": {
        const cSnap2 = await db.collection("comments").doc(targetId).get();
        if (!cSnap2.exists) {
          throw new HttpsError("not-found", "Comment not found.");
        }
        await db.collection("comments").doc(targetId).update({
          hidden: false,
          flagCount: 0,
        });
        await resolveCommentReports(targetId, "dismissed");
        await recomputeCommentCount(cSnap2.data()!.chantId as string);
        await writeAuditEntry({
          actorId: actorUid,
          action: "unhide",
          targetType: "comment",
          targetId,
          detail: "Comment unhidden by operator. flagCount reset to 0, reports dismissed.",
        });
        return { success: true };
      }

      case "remove-comment": {
        const cSnap3 = await db.collection("comments").doc(targetId).get();
        if (!cSnap3.exists) {
          throw new HttpsError("not-found", "Comment not found.");
        }
        await db.collection("comments").doc(targetId).update({ removed: true });
        await resolveCommentReports(targetId, "reviewed");
        await recomputeCommentCount(cSnap3.data()!.chantId as string);
        await writeAuditEntry({
          actorId: actorUid,
          action: "remove",
          targetType: "comment",
          targetId,
          detail: "Comment removed by operator.",
        });
        return { success: true };
      }

      default:
        throw new HttpsError(
          "invalid-argument",
          `Unknown action "${action}". Valid: hide, unhide, remove, ban, unban, promote, demote, remove-evidence, hide-comment, unhide-comment, remove-comment.`
        );
    }
  }
);

// --- onChantCreated ---
// Soft rate limit (Fix 2, option b): checks submission velocity.
// Auto-hides (never auto-removes) abnormally high-velocity bursts.
const NEW_ACCOUNT_LIMIT = 2;
const PROVEN_ACCOUNT_LIMIT = 5;
const NEW_ACCOUNT_AGE_MS = 24 * 60 * 60 * 1000; // 24 hours

export function isNewAccount(accountAgeMs: number): boolean {
  return accountAgeMs < NEW_ACCOUNT_AGE_MS;
}

export const onChantCreated = onDocumentCreated(
  { document: "chants/{chantId}", region: "europe-west2" },
  async (event) => {
    const chantData = event.data?.data();
    if (!chantData) return;

    const userId = chantData.createdBy as string;
    if (userId === "system") return; // Seed writes bypass rate limit

    const profileSnap = await db.collection("profiles").doc(userId).get();
    if (!profileSnap.exists) return;

    const profileData = profileSnap.data()!;
    const createdAt = profileData.createdAt?.toDate?.() || new Date();
    const accountAge = Date.now() - createdAt.getTime();

    // Count submissions in the last hour
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentChants = await db
      .collection("chants")
      .where("createdBy", "==", userId)
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(oneHourAgo))
      .get();

    const totalSubmissions = recentChants.size;
    const isNew = isNewAccount(accountAge);
    const limit = isNew ? NEW_ACCOUNT_LIMIT : PROVEN_ACCOUNT_LIMIT;

    if (totalSubmissions > limit) {
      // Auto-hide (pending review), never auto-remove
      await event.data?.ref.update({ hidden: true });
      await writeAuditEntry({
        actorId: "system",
        action: "rate-limit-hide",
        targetType: "chant",
        targetId: event.data?.id || "unknown",
        detail: `Auto-hidden: user submitted ${totalSubmissions} chants in the last hour (limit ${limit}).`,
      });
    }
  }
);

// --- onVoteWritten ---
// Maintains upvotes, downvotes, and score on the chant by recomputing from
// the actual vote docs (ground truth). This makes the function fully
// idempotent: duplicate deliveries, bursts of rapid writes, and out-of-order
// events all converge to the correct count.
// The chant counter set and the appliedValue stamp are committed in one
// WriteBatch so they land atomically (preserving the -2 flash fix).
/// Core handler logic, extracted so it can be unit-tested with a fake db.
export async function handleVoteWritten(
  beforeData: admin.firestore.DocumentData | undefined,
  afterData: admin.firestore.DocumentData | undefined,
  voteId: string,
  firestore: admin.firestore.Firestore
): Promise<void> {
  const chantId = (afterData?.chantId || beforeData?.chantId) as string;
  if (!chantId) return;

  // No-op early return: if the value field did not change (e.g. appliedValue
  // write-back re-trigger), skip the recompute entirely.
  let upDelta = 0;
  let downDelta = 0;

  if (beforeData) {
    if (beforeData.value === 1) upDelta -= 1;
    else if (beforeData.value === -1) downDelta -= 1;
  }

  if (afterData) {
    if (afterData.value === 1) upDelta += 1;
    else if (afterData.value === -1) downDelta += 1;
  }

  if (upDelta === 0 && downDelta === 0) return;

  // The parent may already be gone when a delayed vote event arrives after
  // an account cleanup or duplicate merge. Do not recreate it or retry a
  // batch that can never succeed.
  const chantRef = firestore.collection("chants").doc(chantId);
  const chantSnap = await chantRef.get();
  if (!chantSnap.exists) return;

  // Recompute counters from the actual vote docs (ground truth).
  const votesSnap = await firestore
    .collection("votes")
    .where("chantId", "==", chantId)
    .get();
  let upvotes = 0;
  let downvotes = 0;
  for (const doc of votesSnap.docs) {
    if (doc.data().value === 1) upvotes++;
    else if (doc.data().value === -1) downvotes++;
  }

  // Batch the chant counter set and the appliedValue stamp so they become
  // visible atomically. Without this, a reader can see the updated score
  // before appliedValue is written and double-count the delta (-2 flash).
  const batch = firestore.batch();

  batch.update(chantRef, {
    upvotes,
    downvotes,
    score: upvotes - downvotes,
  });

  // Write appliedValue back to the vote doc so the client can tell whether
  // the chant score already includes this vote on a cold load.
  // Skip on delete (afterData is undefined, doc is gone).
  // The write triggers onVoteWritten again, but that re-trigger is a no-op:
  // value is unchanged, so upDelta and downDelta are both 0, hitting the
  // early return above.
  if (afterData) {
    batch.update(firestore.collection("votes").doc(voteId), {
      appliedValue: afterData.value,
    });
  }

  await batch.commit();
}

export const onVoteWritten = onDocumentWritten(
  { document: "votes/{voteId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    await handleVoteWritten(beforeData, afterData, event.params.voteId, db);
  }
);

// --- deleteAccount (callable) ---
// Deletes the calling user's account and all associated data.
// Apple 5.1.1(v) and Google Play require in-app account deletion.
// Actor derived from auth context. A user can only delete their own account.
export const deleteAccount = onCall(
  { region: "europe-west2" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;

    // 1. Delete all votes by this user and reconcile affected chants
    const votes = await db.collection("votes").where("userId", "==", uid).get();
    const affectedChantIds = new Set<string>();
    for (const voteDoc of votes.docs) {
      affectedChantIds.add(voteDoc.data().chantId);
      await voteDoc.ref.delete();
    }

    // Reconcile counters on each affected chant
    for (const chantId of affectedChantIds) {
      await reconcileChantCounters(chantId);
    }

    // 2. Delete all chant reports by this user and reconcile flag counters
    const reports = await db.collection("reports").where("reportedBy", "==", uid).get();
    const reportedChantIds = new Set<string>();
    for (const reportDoc of reports.docs) {
      reportedChantIds.add(reportDoc.data().chantId as string);
      await reportDoc.ref.delete();
    }
    for (const chantId of reportedChantIds) {
      await handleChantReportWritten({ chantId }, undefined, db);
    }

    // 3. Delete all feedback by this user
    const feedback = await db.collection("feedback").where("userId", "==", uid).get();
    for (const fbDoc of feedback.docs) {
      await fbDoc.ref.delete();
    }
    await deleteSafetyRateState(uid, db);

    // 4. Anonymize createdBy on all chants by this user
    const chants = await db.collection("chants").where("createdBy", "==", uid).get();
    for (const chantDoc of chants.docs) {
      await chantDoc.ref.update({ createdBy: "deleted-user" });
    }

    // 5. Anonymize comments by this user and recompute commentCounts
    const comments = await db.collection("comments").where("userId", "==", uid).get();
    const commentChantIds = new Set<string>();
    for (const commentDoc of comments.docs) {
      commentChantIds.add(commentDoc.data().chantId);
      await commentDoc.ref.update({
        userId: "deleted-user",
        displayName: "Deleted user",
      });
    }

    // 6. Delete comment likes by this user and recompute affected likeCounts
    const commentLikes = await db.collection("commentLikes").where("userId", "==", uid).get();
    const affectedCommentIds = new Set<string>();
    for (const likeDoc of commentLikes.docs) {
      affectedCommentIds.add(likeDoc.data().commentId);
      await likeDoc.ref.delete();
    }
    for (const commentId of affectedCommentIds) {
      await recomputeCommentLikeCount(commentId);
    }

    // 7. Delete comment reports by this user and reconcile flag counters
    const commentReports = await db.collection("commentReports").where("reportedBy", "==", uid).get();
    const reportedCommentIds = new Set<string>();
    for (const crDoc of commentReports.docs) {
      reportedCommentIds.add(crDoc.data().commentId as string);
      await crDoc.ref.delete();
    }
    for (const commentId of reportedCommentIds) {
      await handleCommentReportWritten({ commentId }, undefined, db);
    }

    // 8. Delete user reports filed by or against this user. Recompute the
    // surviving targets' counters from ground truth.
    const userReportsBy = await db.collection("userReports")
      .where("reportedBy", "==", uid).get();
    const userReportsAgainst = await db.collection("userReports")
      .where("reportedUserId", "==", uid).get();
    const userReportDocs = new Map<string, admin.firestore.QueryDocumentSnapshot>();
    const affectedReportedUsers = new Set<string>();
    for (const reportDoc of userReportsBy.docs) {
      userReportDocs.set(reportDoc.ref.path, reportDoc);
      affectedReportedUsers.add(reportDoc.data().reportedUserId as string);
    }
    for (const reportDoc of userReportsAgainst.docs) {
      userReportDocs.set(reportDoc.ref.path, reportDoc);
    }
    for (const reportDoc of userReportDocs.values()) {
      await reportDoc.ref.delete();
    }
    affectedReportedUsers.delete(uid);
    for (const reportedUserId of affectedReportedUsers) {
      await handleUserReportCreated(reportedUserId, db);
    }

    // 9. Delete both directions of block relationships involving this user.
    const blocksBy = await db.collection("blocks").where("blockerId", "==", uid).get();
    const blocksAgainst = await db.collection("blocks").where("blockedUserId", "==", uid).get();
    const blockRefs = new Map<string, admin.firestore.DocumentReference>();
    for (const blockDoc of [...blocksBy.docs, ...blocksAgainst.docs]) {
      blockRefs.set(blockDoc.ref.path, blockDoc.ref);
    }
    for (const blockRef of blockRefs.values()) {
      await blockRef.delete();
    }

    // 10. Audit before deleting Auth so the actor remains attributable.
    await writeAuditEntry({
      actorId: uid,
      action: "delete-account",
      targetType: "user",
      targetId: uid,
      detail: `User deleted their own account. ${votes.size} votes removed, ${chants.size} chants anonymized, ${comments.size} comments anonymized, ${commentLikes.size} comment likes removed, ${userReportDocs.size} user reports removed, ${blockRefs.size} blocks removed.`,
    });

    // 11. Delete Auth before the profile. If Auth deletion fails, the user
    // can still sign in and retry instead of being stranded without a profile.
    await admin.auth().deleteUser(uid);
    await db.collection("profiles").doc(uid).delete();

    return { success: true };
  }
);

// --- acceptPolicy (callable) ---
// Records that the calling user accepted the current content policy
// version. Actor derived from auth context, never from a client parameter.
// The version and timestamp are decided server-side, never trusted from the
// client, so this write is the only source of truth for consent.
/// Core handler logic, extracted so it can be unit-tested with a fake db,
/// same pattern as handleVoteWritten/handleCommentLikeWritten. Does not
/// write the audit entry itself, so the tested core has no dependency on
/// the global admin.firestore() that writeAuditEntry uses.
export async function handleAcceptPolicy(
  uid: string,
  firestore: admin.firestore.Firestore
): Promise<{ accepted: boolean }> {
  const profileRef = firestore.collection("profiles").doc(uid);
  const profileSnap = await profileRef.get();
  if (!profileSnap.exists) {
    return { accepted: false };
  }

  await profileRef.update({
    acceptedPolicyVersion: CURRENT_POLICY_VERSION,
    acceptedPolicyAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { accepted: true };
}

export const acceptPolicy = onCall(
  { region: "europe-west2" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;

    const result = await handleAcceptPolicy(uid, db);
    if (!result.accepted) {
      throw new HttpsError("not-found", "Profile not found.");
    }

    await writeAuditEntry({
      actorId: uid,
      action: "accept-policy",
      targetType: "user",
      targetId: uid,
      detail: `Accepted content policy version ${CURRENT_POLICY_VERSION}.`,
    });

    return { success: true, version: CURRENT_POLICY_VERSION };
  }
);

// --- mergeChants (callable) ---
// Operator-only. Merges a duplicate chant (source) into a keeper (target).
// Moves votes and reports, deletes the source, reconciles target counters,
// and logs a bounded source summary for investigation. The operation is not
// atomic, resumable, or automatically reversible.
export const mergeChants = onCall(
  { region: "europe-west2" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const actorUid = request.auth.uid;

    // Operator check: read role from Firestore profile, same pattern as onModerationAction
    const actorProfile = await db.collection("profiles").doc(actorUid).get();
    if (!actorProfile.exists || actorProfile.data()?.role !== "operator") {
      throw new HttpsError("permission-denied", "Operator access required.");
    }

    const { sourceId, targetId } = request.data as {
      sourceId: string;
      targetId: string;
    };

    if (!sourceId || !targetId) {
      throw new HttpsError("invalid-argument", "sourceId and targetId are required.");
    }
    if (sourceId === targetId) {
      throw new HttpsError("invalid-argument", "sourceId and targetId must be different.");
    }

    // Validate both chants exist and belong to the same team
    const sourceSnap = await db.collection("chants").doc(sourceId).get();
    const targetSnap = await db.collection("chants").doc(targetId).get();

    if (!sourceSnap.exists) {
      throw new HttpsError("not-found", `Source chant ${sourceId} not found.`);
    }
    if (!targetSnap.exists) {
      throw new HttpsError("not-found", `Target chant ${targetId} not found.`);
    }

    const sourceData = sourceSnap.data()!;
    const targetData = targetSnap.data()!;

    if (sourceData.teamId !== targetData.teamId) {
      throw new HttpsError(
        "invalid-argument",
        "Source and target must belong to the same team."
      );
    }

    // Capture a bounded source summary for audit and incident investigation.
    const sourcePayload = {
      title: sourceData.title,
      lyrics: sourceData.lyrics,
      tuneName: sourceData.tuneName,
      subjectTag: sourceData.subjectTag,
      teamId: sourceData.teamId,
      playerId: sourceData.playerId || null,
      sportId: sourceData.sportId,
      competitionId: sourceData.competitionId,
      status: sourceData.status,
      contextNotes: sourceData.contextNotes || null,
      chantType: sourceData.chantType,
      mediaType: sourceData.mediaType,
      createdBy: sourceData.createdBy,
    };

    // Step 1: Move votes from source to target.
    // NOTE: onVoteWritten fires automatically as votes move, handling counter
    // deltas on both source and target. The reconcile-target step at the end
    // is the safety net for any drift or duplicate delivery from at-least-once
    // trigger delivery.
    const sourceVotes = await db.collection("votes")
      .where("chantId", "==", sourceId).get();
    let votesMoved = 0;
    let votesSkipped = 0;

    for (const voteDoc of sourceVotes.docs) {
      const voteData = voteDoc.data();
      const userId = voteData.userId as string;
      const targetVoteId = `${userId}_${targetId}`;

      // Check if user already voted on target
      const existingTargetVote = await db.collection("votes").doc(targetVoteId).get();

      if (existingTargetVote.exists) {
        // User voted on both: keep target vote, delete source vote
        await voteDoc.ref.delete();
        votesSkipped++;
      } else {
        // Move: delete old doc, create new doc with target chantId
        await db.collection("votes").doc(targetVoteId).set({
          ...voteData,
          chantId: targetId,
        });
        await voteDoc.ref.delete();
        votesMoved++;
      }
    }

    // Step 2: Move reports from source to target
    const sourceReports = await db.collection("reports")
      .where("chantId", "==", sourceId).get();
    let reportsMoved = 0;

    for (const reportDoc of sourceReports.docs) {
      const reportData = reportDoc.data();
      const reportedBy = reportData.reportedBy as string;
      const targetReportId = `${reportedBy}_${targetId}`;

      // Check if user already reported target
      const existingTargetReport = await db.collection("reports").doc(targetReportId).get();

      if (existingTargetReport.exists) {
        // Already reported target: just delete the source report
        await reportDoc.ref.delete();
      } else {
        // Move: delete old, create new
        await db.collection("reports").doc(targetReportId).set({
          ...reportData,
          chantId: targetId,
        });
        await reportDoc.ref.delete();
        reportsMoved++;
      }
    }

    // Step 3: Move all comments, including replies, to the target. Parent IDs
    // remain stable because every comment in the source thread moves together.
    const sourceComments = await db.collection("comments")
      .where("chantId", "==", sourceId).get();
    let commentsMoved = 0;
    for (const commentDoc of sourceComments.docs) {
      await commentDoc.ref.update({ chantId: targetId });
      commentsMoved++;
    }

    // Step 4: Delete the source chant
    await db.collection("chants").doc(sourceId).delete();

    // Step 5: Reconcile target counters from ground truth (safety net)
    await reconcileChantCounters(targetId);
    await recomputeCommentCount(targetId);

    // Step 6: Audit log with the bounded source summary and move counts.
    await writeAuditEntry({
      actorId: actorUid,
      action: "merge_chants",
      targetType: "chant",
      targetId,
      detail: JSON.stringify({
        sourceId,
        targetId,
        votesMoved,
        votesSkipped,
        reportsMoved,
        commentsMoved,
        sourcePayload,
      }),
    });

    return {
      success: true,
      votesMoved,
      votesSkipped,
      reportsMoved,
      commentsMoved,
    };
  }
);

// --- onCommentLikeWritten ---
// Maintains likeCount on the comment by recomputing from the actual like docs
// (ground truth). Fully idempotent: duplicate deliveries, bursts, and
// out-of-order events all converge. The likeCount set and appliedValue stamp
// are committed in one WriteBatch so they land atomically.
export async function handleCommentLikeWritten(
  beforeData: admin.firestore.DocumentData | undefined,
  afterData: admin.firestore.DocumentData | undefined,
  likeId: string,
  firestore: admin.firestore.Firestore
): Promise<void> {
  const commentId = (afterData?.commentId || beforeData?.commentId) as string;
  if (!commentId) return;

  // No-op early return: if the value field did not change (e.g. appliedValue
  // write-back re-trigger), skip the recompute.
  const beforeVal = beforeData?.value as number | undefined;
  const afterVal = afterData?.value as number | undefined;
  if (beforeVal === afterVal) return;

  // Guard: if the comment doc no longer exists (racing with a delete), no-op.
  const commentRef = firestore.collection("comments").doc(commentId);
  const commentSnap = await commentRef.get();
  if (!commentSnap.exists) return;

  // Recompute likeCount from all like docs (ground truth).
  const likesSnap = await firestore
    .collection("commentLikes")
    .where("commentId", "==", commentId)
    .get();
  let likeCount = 0;
  for (const doc of likesSnap.docs) {
    if (doc.data().value === 1) likeCount++;
  }

  const batch = firestore.batch();
  batch.update(commentRef, { likeCount });

  // Stamp appliedValue on the like doc so the client can reconcile on cold load.
  // Skip on delete (afterData is undefined, doc is gone).
  if (afterData) {
    batch.update(firestore.collection("commentLikes").doc(likeId), {
      appliedValue: afterData.value,
    });
  }

  await batch.commit();
}

export const onCommentLikeWritten = onDocumentWritten(
  { document: "commentLikes/{likeId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    await handleCommentLikeWritten(
      beforeData, afterData, event.params.likeId, db
    );
  }
);

// --- onCommentWritten ---
// Fires on every comment write (create, update, delete). Recomputes
// commentCount on the parent chant from ground truth on every invocation.
// This covers author soft-delete, operator hide/remove, rate-limit auto-hide,
// and regular creates in a single trigger, so there is never a path that
// changes visibility without updating the count.
//
// Loop guard: this function writes to the CHANT document (commentCount), not
// back to the comment document that triggered it, so it cannot retrigger itself.
//
// Rate-limiting runs only on creates (no beforeData), same as the previous
// onCommentCreated.
const COMMENT_NEW_ACCOUNT_LIMIT = 5;
const COMMENT_PROVEN_ACCOUNT_LIMIT = 20;

export const onCommentWritten = onDocumentWritten(
  { document: "comments/{commentId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    const chantId = (afterData?.chantId || beforeData?.chantId) as string;
    if (!chantId) return;

    // Always recompute commentCount from ground truth.
    await recomputeCommentCount(chantId);

    // Rate-limit check only on create (no beforeData).
    if (beforeData) return; // update or delete, skip rate-limiting
    if (!afterData) return;

    const userId = afterData.userId as string;
    if (userId === "system") return;

    const profileSnap = await db.collection("profiles").doc(userId).get();
    if (!profileSnap.exists) return;

    const profileData = profileSnap.data()!;
    const createdAt = profileData.createdAt?.toDate?.() || new Date();
    const accountAge = Date.now() - createdAt.getTime();

    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentComments = await db
      .collection("comments")
      .where("userId", "==", userId)
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(oneHourAgo))
      .get();

    const totalComments = recentComments.size;
    const isNew = isNewAccount(accountAge);
    const limit = isNew ? COMMENT_NEW_ACCOUNT_LIMIT : COMMENT_PROVEN_ACCOUNT_LIMIT;

    if (totalComments > limit) {
      // Auto-hide (pending review), never auto-remove.
      // This update retriggers onCommentWritten, but the second invocation
      // just recomputes commentCount again (idempotent, same result).
      const commentRef = event.data?.after?.ref;
      if (commentRef) {
        await commentRef.update({ hidden: true });
      }
      await writeAuditEntry({
        actorId: "system",
        action: "rate-limit-hide",
        targetType: "comment",
        targetId: event.params.commentId,
        detail: `Auto-hidden: user posted ${totalComments} comments in the last hour (limit ${limit}).`,
      });
    }
  }
);

// Mirrors the chant report handler with ground-truth recomputation.
export const onCommentReportCreated = onDocumentWritten(
  { document: "commentReports/{reportId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const result = await handleCommentReportWritten(beforeData, afterData, db);
    const commentId = (afterData?.commentId || beforeData?.commentId) as string;

    if (result.autoHidden) {
      const commentSnap = await db.collection("comments").doc(commentId).get();
      if (commentSnap.exists) {
        await recomputeCommentCount(commentSnap.data()!.chantId as string);
      }
      await writeAuditEntry({
        actorId: "system",
        action: "auto-hide",
        targetType: "comment",
        targetId: commentId,
        detail: `Auto-hidden: flagCount reached ${result.flagCount} (threshold ${AUTO_HIDE_THRESHOLD}).`,
      });
    }

    if (!beforeData && afterData) {
      await writeAuditEntry({
        actorId: afterData.reportedBy as string,
        action: "report",
        targetType: "comment",
        targetId: commentId,
        detail: `Reason: ${afterData.reason}`,
      });
    }
  }
);

// --- onUserReportCreated ---
// Recomputes userReportCount on the reported user's profile from a
// ground-truth query over userReports (never FieldValue.increment), so
// duplicate or out-of-order trigger delivery always converges to the
// correct count, same pattern as onVoteWritten/onCommentLikeWritten.
// No auto-action: a high count only surfaces the profile in moderation for
// a human to review. banUser stays operator-only and manual.
/// Core handler logic, extracted so it can be unit-tested with a fake db,
/// same pattern as handleVoteWritten/handleCommentLikeWritten. Does not
/// write the audit entry itself (writeAuditEntry uses the global
/// admin.firestore(), see the same note on handleAcceptPolicy above).
export async function handleUserReportCreated(
  reportedUserId: string,
  firestore: admin.firestore.Firestore
): Promise<{ userReportCount: number }> {
  const reportsSnap = await firestore
    .collection("userReports")
    .where("reportedUserId", "==", reportedUserId)
    .get();
  const userReportCount = reportsSnap.size;

  // Guard: if the reported user's profile no longer exists (e.g. they
  // deleted their account), skip the write rather than erroring.
  const profileRef = firestore.collection("profiles").doc(reportedUserId);
  const profileSnap = await profileRef.get();
  if (!profileSnap.exists) return { userReportCount };

  await profileRef.update({ userReportCount });

  return { userReportCount };
}

export const onUserReportCreated = onDocumentCreated(
  { document: "userReports/{reportId}", region: "europe-west2" },
  async (event) => {
    const reportData = event.data?.data();
    if (!reportData) return;

    const reportedUserId = reportData.reportedUserId as string;
    await handleUserReportCreated(reportedUserId, db);

    await writeAuditEntry({
      actorId: reportData.reportedBy as string,
      action: "report-user",
      targetType: "user",
      targetId: reportedUserId,
      detail: `Reason: ${reportData.reason}`,
    });
  }
);

// --- Helper: recompute commentCount on a chant from ground truth ---
async function recomputeCommentCount(chantId: string): Promise<void> {
  const commentsSnap = await db
    .collection("comments")
    .where("chantId", "==", chantId)
    .where("hidden", "==", false)
    .where("removed", "==", false)
    .get();
  await db.collection("chants").doc(chantId).update({
    commentCount: commentsSnap.size,
  });
}

// --- Helper: recompute likeCount on a comment from ground truth ---
async function recomputeCommentLikeCount(commentId: string): Promise<void> {
  const commentSnap = await db.collection("comments").doc(commentId).get();
  if (!commentSnap.exists) return;
  const likesSnap = await db
    .collection("commentLikes")
    .where("commentId", "==", commentId)
    .get();
  let likeCount = 0;
  for (const doc of likesSnap.docs) {
    if (doc.data().value === 1) likeCount++;
  }
  await db.collection("comments").doc(commentId).update({ likeCount });
}

// --- Helper: resolve comment reports ---
async function resolveCommentReports(
  commentId: string,
  newStatus: "reviewed" | "dismissed"
): Promise<void> {
  const reports = await db
    .collection("commentReports")
    .where("commentId", "==", commentId)
    .where("status", "==", "pending")
    .get();

  if (reports.empty) return;
  const batch = db.batch();
  for (const doc of reports.docs) {
    batch.update(doc.ref, { status: newStatus });
  }
  await batch.commit();
}

// --- Helper: reconcile chant counters from votes collection ---
async function reconcileChantCounters(
  chantId: string,
  firestore: admin.firestore.Firestore = db
): Promise<void> {
  const votesSnap = await firestore.collection("votes").where("chantId", "==", chantId).get();
  let upvotes = 0;
  let downvotes = 0;
  for (const doc of votesSnap.docs) {
    if (doc.data().value === 1) upvotes++;
    else if (doc.data().value === -1) downvotes++;
  }
  await firestore.collection("chants").doc(chantId).update({
    upvotes,
    downvotes,
    score: upvotes - downvotes,
  });
}

// --- Helper: resolve reports for a chant ---
async function resolveReportsForChant(
  chantId: string,
  newStatus: "reviewed" | "dismissed"
): Promise<void> {
  const reports = await db
    .collection("reports")
    .where("chantId", "==", chantId)
    .where("status", "==", "pending")
    .get();

  const batch = db.batch();
  for (const doc of reports.docs) {
    batch.update(doc.ref, { status: newStatus });
  }
  await batch.commit();
}
