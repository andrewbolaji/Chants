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
