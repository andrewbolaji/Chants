import * as admin from "firebase-admin";
import { onDocumentCreated, onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { writeAuditEntry } from "./audit";

admin.initializeApp();
const db = admin.firestore();

const AUTO_HIDE_THRESHOLD = 3;

// --- onReportCreated ---
// Increments flagCount on the reported chant.
// Auto-hides the chant if flagCount reaches the threshold.
export const onReportCreated = onDocumentCreated(
  { document: "reports/{reportId}", region: "europe-west2" },
  async (event) => {
    const reportData = event.data?.data();
    if (!reportData) return;

    const chantId = reportData.chantId as string;
    const chantRef = db.collection("chants").doc(chantId);

    await db.runTransaction(async (txn) => {
      const chantSnap = await txn.get(chantRef);
      if (!chantSnap.exists) return;

      const chantData = chantSnap.data()!;
      const newFlagCount = (chantData.flagCount || 0) + 1;

      const update: Record<string, unknown> = {
        flagCount: admin.firestore.FieldValue.increment(1),
      };

      if (newFlagCount >= AUTO_HIDE_THRESHOLD && chantData.hidden === false) {
        update.hidden = true;
        await writeAuditEntry({
          actorId: "system",
          action: "auto-hide",
          targetType: "chant",
          targetId: chantId,
          detail: `Auto-hidden: flagCount reached ${newFlagCount} (threshold ${AUTO_HIDE_THRESHOLD}).`,
        });
      }

      txn.update(chantRef, update);
    });

    await writeAuditEntry({
      actorId: reportData.reportedBy as string,
      action: "report",
      targetType: "chant",
      targetId: chantId,
      detail: `Reason: ${reportData.reason}`,
    });
  }
);

// --- onModerationAction (callable) ---
// Operator-only. Actions: hide, unhide, remove, ban.
// Actor UID derived from auth context, never from client parameter.
// Fix 4: resolves associated reports and resets flagCount on unhide.
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

      case "ban": {
        // targetId is the user's profile UID
        const targetProfile = await db.collection("profiles").doc(targetId).get();
        if (!targetProfile.exists) {
          throw new HttpsError("not-found", "User profile not found.");
        }
        await db.collection("profiles").doc(targetId).update({ banned: true });
        await writeAuditEntry({
          actorId: actorUid,
          action: "ban",
          targetType: "user",
          targetId,
          detail: "User banned by operator.",
        });
        return { success: true };
      }

      case "promote": {
        const chantSnap = await db.collection("chants").doc(targetId).get();
        if (!chantSnap.exists) {
          throw new HttpsError("not-found", "Chant not found.");
        }
        await db.collection("chants").doc(targetId).update({ status: "canonical" });
        await writeAuditEntry({
          actorId: actorUid,
          action: "promote",
          targetType: "chant",
          targetId,
          detail: "Community chant promoted to canonical by operator.",
        });
        return { success: true };
      }

      case "demote": {
        const chantSnap2 = await db.collection("chants").doc(targetId).get();
        if (!chantSnap2.exists) {
          throw new HttpsError("not-found", "Chant not found.");
        }
        await db.collection("chants").doc(targetId).update({ status: "community" });
        await writeAuditEntry({
          actorId: actorUid,
          action: "demote",
          targetType: "chant",
          targetId,
          detail: "Canonical chant demoted to community by operator.",
        });
        return { success: true };
      }

      default:
        throw new HttpsError(
          "invalid-argument",
          `Unknown action "${action}". Valid: hide, unhide, remove, ban, promote, demote.`
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
const NEW_ACCOUNT_MIN_SUBMISSIONS = 3;

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
    const isNew =
      accountAge < NEW_ACCOUNT_AGE_MS || totalSubmissions <= NEW_ACCOUNT_MIN_SUBMISSIONS;
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
// Maintains upvotes, downvotes, and score on the chant via atomic increments.
// Handles create, flip (update), and delete in one function using before/after diff.
// NOTE: Firestore triggers are at-least-once. This function is NOT idempotent.
// A duplicate delivery would double-apply the delta. The reconciliation script
// (reconcile.ts) recomputes counters from ground truth as the remedy.
// Trigger to add event.id dedup: observed drift or volume growth.
export const onVoteWritten = onDocumentWritten(
  { document: "votes/{voteId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    const chantId = (afterData?.chantId || beforeData?.chantId) as string;
    if (!chantId) return;

    let upDelta = 0;
    let downDelta = 0;

    // Remove old vote effect
    if (beforeData) {
      if (beforeData.value === 1) upDelta -= 1;
      else if (beforeData.value === -1) downDelta -= 1;
    }

    // Add new vote effect
    if (afterData) {
      if (afterData.value === 1) upDelta += 1;
      else if (afterData.value === -1) downDelta += 1;
    }

    if (upDelta === 0 && downDelta === 0) return;

    const scoreDelta = upDelta - downDelta;

    await db.collection("chants").doc(chantId).update({
      upvotes: admin.firestore.FieldValue.increment(upDelta),
      downvotes: admin.firestore.FieldValue.increment(downDelta),
      score: admin.firestore.FieldValue.increment(scoreDelta),
    });
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

    // 2. Delete all reports by this user
    const reports = await db.collection("reports").where("reportedBy", "==", uid).get();
    for (const reportDoc of reports.docs) {
      await reportDoc.ref.delete();
    }

    // 3. Delete all feedback by this user
    const feedback = await db.collection("feedback").where("userId", "==", uid).get();
    for (const fbDoc of feedback.docs) {
      await fbDoc.ref.delete();
    }

    // 4. Anonymize createdBy on all chants by this user
    const chants = await db.collection("chants").where("createdBy", "==", uid).get();
    for (const chantDoc of chants.docs) {
      await chantDoc.ref.update({ createdBy: "deleted-user" });
    }

    // 5. Delete profile
    await db.collection("profiles").doc(uid).delete();

    // 6. Audit log
    await writeAuditEntry({
      actorId: uid,
      action: "delete-account",
      targetType: "user",
      targetId: uid,
      detail: `User deleted their own account. ${votes.size} votes removed, ${chants.size} chants anonymized.`,
    });

    // 7. Delete Firebase Auth account
    await admin.auth().deleteUser(uid);

    return { success: true };
  }
);

// --- Helper: reconcile chant counters from votes collection ---
async function reconcileChantCounters(chantId: string): Promise<void> {
  const votesSnap = await db.collection("votes").where("chantId", "==", chantId).get();
  let upvotes = 0;
  let downvotes = 0;
  for (const doc of votesSnap.docs) {
    if (doc.data().value === 1) upvotes++;
    else if (doc.data().value === -1) downvotes++;
  }
  await db.collection("chants").doc(chantId).update({
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
