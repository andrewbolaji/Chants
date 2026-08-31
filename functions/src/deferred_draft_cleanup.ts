import * as admin from "firebase-admin";
import { createHash } from "crypto";
import { operationEnabled } from "./operational_gate";
import { clearMatchingUploadGrant } from "./upload_grant";

// These private rows are retained evidence, not an automatic replay queue.
// A blocked row contains no executable path and requires explicit operator recovery.
export async function handleDeletedDraftCleanup(params: {
  draftId: string;
  data: admin.firestore.DocumentData | undefined;
  firestore: admin.firestore.Firestore;
  remove: (path: string) => Promise<void>;
  now: () => admin.firestore.Timestamp;
}): Promise<"ignored" | "blocked" | "deferred" | "attempted"> {
  if (!params.data) return "ignored";
  const ownerId = params.data.ownerId;
  const path = params.data.uploadPath;
  const safeDraftId = /^[A-Za-z0-9_-]{1,200}$/.test(params.draftId) ? params.draftId : null;
  const validIdentity = typeof ownerId === "string" && /^[A-Za-z0-9_-]{1,128}$/.test(ownerId) &&
    safeDraftId !== null &&
    path === `performance-staging/${ownerId}/${params.draftId}/source`;
  const sourceDigest = createHash("sha256").update(params.draftId).digest("hex");
  const jobs = params.firestore.collection("deferredDraftCleanupJobs");
  // Colon is outside the accepted draft-ID alphabet, so failure evidence cannot
  // overwrite a legitimate job. The digest avoids copying hostile source data.
  const blockedRef = jobs.doc(`blocked:${sourceDigest}`);
  const timestamp = params.now();
  const disposition = await params.firestore.runTransaction(async (transaction) => {
    const blocked = await transaction.get(blockedRef);
    if (blocked.exists) return "blocked";
    const block = (reason: "invalid-identity" | "path-conflict") => {
      transaction.create(blockedRef, { schemaVersion: 1, sourceDigest, draftId: safeDraftId, state: "blocked",
        reason, createdAt: timestamp, updatedAt: timestamp });
      return "blocked" as const;
    };
    if (!validIdentity) return block("invalid-identity");
    const job = jobs.doc(params.draftId);
    const existing = await transaction.get(job);
    if (existing.exists && existing.data()?.uploadPath !== path) return block("path-conflict");
    const profile = await transaction.get(params.firestore.collection("profiles").doc(ownerId));
    clearMatchingUploadGrant(transaction, profile, params.draftId);
    if (!existing.exists) transaction.create(job, {
      schemaVersion: 1, draftId: params.draftId, uploadPath: path,
      state: "pending", createdAt: timestamp, updatedAt: timestamp,
    });
    return "ready";
  });
  // Permanent faults acknowledge only after durable quarantine. Infrastructure
  // failures still reject so event retries can recover.
  if (disposition === "blocked") return "blocked";
  if (!await operationEnabled("onPerformanceDraftDeleted", params.firestore)) return "deferred";
  await params.remove(path);
  // A later admitted transfer may recreate bytes. This is attempt evidence,
  // never permanent completion or permission to discard the retained path.
  await jobs.doc(params.draftId).update({ state: "attempted", updatedAt: params.now() });
  return "attempted";
}
