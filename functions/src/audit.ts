import * as admin from "firebase-admin";

export async function writeAuditEntry(params: {
  actorId: string;
  action: string;
  targetType: string;
  targetId: string;
  detail: string;
}): Promise<void> {
  await admin.firestore().collection("auditLog").add({
    actorId: params.actorId,
    action: params.action,
    targetType: params.targetType,
    targetId: params.targetId,
    detail: params.detail,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export async function writePrivacySafeReportAuditEntry(params: {
  reporterId: string;
  action: "report" | "report-user";
  targetType: "chant" | "comment" | "user";
  targetId: string;
  reason: string;
  firestore: admin.firestore.Firestore;
}): Promise<void> {
  const profileRef = params.firestore.collection("profiles").doc(params.reporterId);
  const auditRef = params.firestore.collection("auditLog").doc();
  await params.firestore.runTransaction(async (transaction) => {
    const profile = await transaction.get(profileRef);
    const identityMustBeRemoved =
      !profile.exists || profile.data()?.deletionPending === true;
    transaction.set(auditRef, {
      actorId: identityMustBeRemoved ? "deleted-user" : params.reporterId,
      action: params.action,
      targetType: params.targetType,
      targetId: params.targetId,
      detail: identityMustBeRemoved
        ? "Report details removed during account deletion."
        : `Reason: ${params.reason}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}
