import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
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

      default:
        throw new HttpsError(
          "invalid-argument",
          `Unknown action "${action}". Valid: hide, unhide, remove, ban.`
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
