import * as admin from "firebase-admin";
import { operationEnabled } from "./operational_gate";
import { clearMatchingUploadGrant } from "./upload_grant";

// A deletion event has no remaining source row to replay. Retain its exact path
// even after an attempt, including when an already admitted upload finishes late.
// Replaying retained rows is an explicit operator action, never a mode-toggle side effect.
export async function handleDeletedDraftCleanup(params: {
  draftId: string;
  data: admin.firestore.DocumentData | undefined;
  firestore: admin.firestore.Firestore;
  remove: (path: string) => Promise<void>;
  now: () => admin.firestore.Timestamp;
}): Promise<void> {
  if (!params.data) return;
  const ownerId = params.data.ownerId;
  if (typeof ownerId !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(ownerId) ||
      !/^[A-Za-z0-9_-]{1,200}$/.test(params.draftId) ||
      params.data.uploadPath !== `performance-staging/${ownerId}/${params.draftId}/source`) {
    throw new Error("Invalid deleted draft cleanup identity.");
  }
  const path = params.data.uploadPath as string;
  const job = params.firestore.collection("deferredDraftCleanupJobs").doc(params.draftId);
  await params.firestore.runTransaction(async (transaction) => {
    const existing = await transaction.get(job);
    const profile = await transaction.get(params.firestore.collection("profiles").doc(ownerId));
    if (existing.exists && existing.data()?.uploadPath !== path) {
      throw new Error("Deleted draft cleanup identity changed.");
    }
    clearMatchingUploadGrant(transaction, profile, params.draftId);
    if (!existing.exists) {
      transaction.create(job, {
        schemaVersion: 1, draftId: params.draftId, uploadPath: path,
        state: "pending", createdAt: params.now(), updatedAt: params.now(),
      });
    }
  });
  if (!await operationEnabled("onPerformanceDraftDeleted", params.firestore)) return;
  await params.remove(path);
  // A later admitted transfer may recreate bytes. This is attempt evidence,
  // never permanent completion or permission to discard the retained path.
  await job.update({ state: "attempted", updatedAt: params.now() });
}
