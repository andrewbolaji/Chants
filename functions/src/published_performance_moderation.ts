import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

type ModerationTarget = "performance" | "performanceComment";
type ModerationAction = "hide" | "remove" | "unhide" | "dismiss";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function parsePublishedPerformanceModeration(value: unknown): {
  targetType: ModerationTarget;
  targetId: string;
  action: ModerationAction;
} {
  if (!isRecord(value)) {
    throw new HttpsError("invalid-argument", "Invalid moderation request.");
  }
  const keys = Object.keys(value).sort();
  if (
    keys.length !== 3 ||
    keys[0] !== "action" ||
    keys[1] !== "targetId" ||
    keys[2] !== "targetType" ||
    (value.targetType !== "performance" &&
      value.targetType !== "performanceComment") ||
    (value.action !== "hide" &&
      value.action !== "remove" &&
      value.action !== "unhide" &&
      value.action !== "dismiss") ||
    typeof value.targetId !== "string" ||
    !/^[A-Za-z0-9_-]{1,500}$/.test(value.targetId)
  ) {
    throw new HttpsError("invalid-argument", "Invalid moderation request.");
  }
  return {
    targetType: value.targetType,
    targetId: value.targetId,
    action: value.action,
  };
}

export async function handlePublishedPerformanceModeration(params: {
  actorUid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
  newAuditId: () => string;
}): Promise<{ success: true; reportsResolved: number }> {
  const input = parsePublishedPerformanceModeration(params.data);
  const targetCollection = input.targetType === "performance"
    ? "performances"
    : "performanceComments";
  const reportCollection = input.targetType === "performance"
    ? "performanceReports"
    : "performanceCommentReports";
  const reportField = input.targetType === "performance"
    ? "performanceId"
    : "performanceCommentId";
  const actorRef = params.firestore.collection("profiles").doc(params.actorUid);
  const deletionRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.actorUid);
  const targetRef = params.firestore.collection(targetCollection).doc(input.targetId);
  const reportQuery = params.firestore
    .collection(reportCollection)
    .where(reportField, "==", input.targetId)
    .where("status", "==", "pending");
  const auditId = params.newAuditId();
  if (!/^[A-Za-z0-9_-]{1,500}$/.test(auditId)) {
    throw new Error("Generated invalid audit ID.");
  }
  const auditRef = params.firestore.collection("auditLog").doc(auditId);
  let reportsResolved = 0;

  await params.firestore.runTransaction(async (transaction) => {
    const [actorSnapshot, deletionSnapshot, targetSnapshot, reportsSnapshot] =
      await Promise.all([
        transaction.get(actorRef),
        transaction.get(deletionRef),
        transaction.get(targetRef),
        transaction.get(reportQuery),
      ]);
    const actor = actorSnapshot.data();
    if (
      !actor ||
      actor.role !== "operator" ||
      actor.banned !== false ||
      actor.deletionPending === true ||
      deletionSnapshot.exists
    ) {
      throw new HttpsError("permission-denied", "Operator access required.");
    }
    if (!targetSnapshot.exists) {
      throw new HttpsError("not-found", "Moderation target not found.");
    }
    const target = targetSnapshot.data()!;
    if (input.action === "unhide" && target.removed === true) {
      throw new HttpsError(
        "failed-precondition",
        "Removed content cannot be unhidden."
      );
    }
    const timestamp = params.now();
    if (input.action === "hide") {
      transaction.update(targetRef, { hidden: true, updatedAt: timestamp });
    } else if (input.action === "remove") {
      transaction.update(targetRef, { removed: true, updatedAt: timestamp });
    } else if (input.action === "unhide") {
      transaction.update(targetRef, { hidden: false, updatedAt: timestamp });
    }
    const reportStatus = input.action === "dismiss" || input.action === "unhide"
      ? "dismissed"
      : "reviewed";
    reportsResolved = reportsSnapshot.size;
    for (const report of reportsSnapshot.docs) {
      transaction.update(report.ref, { status: reportStatus });
    }
    transaction.create(auditRef, {
      actorId: params.actorUid,
      action: input.action === "dismiss" ? "dismiss-report" : input.action,
      targetType: input.targetType === "performance"
        ? "performance"
        : "performance-comment",
      targetId: input.targetId,
      detail: input.action === "dismiss"
        ? "Published-content reports dismissed by operator."
        : `Published content ${input.action} action applied by operator.`,
      createdAt: timestamp,
    });
  });
  return { success: true, reportsResolved };
}
