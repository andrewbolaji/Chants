import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

export const UPLOAD_GRANT_LIFETIME_MS = 30 * 60 * 1000;
export type UploadGrant = {
  schemaVersion: 1;
  draftId: string;
  ownerId: string;
  uploadPath: string;
  sizeBytes: number;
  contentType: string;
  generation: number;
  issuedAt: admin.firestore.Timestamp;
  expiresAt: admin.firestore.Timestamp;
};

export function parseUploadGrant(value: unknown): UploadGrant | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  const grant = value as Record<string, unknown>;
  if (Object.keys(grant).sort().join(",") !==
      "contentType,draftId,expiresAt,generation,issuedAt,ownerId,schemaVersion,sizeBytes,uploadPath" ||
      grant.schemaVersion !== 1 ||
      typeof grant.draftId !== "string" || !/^[A-Za-z0-9_-]{1,200}$/.test(grant.draftId) ||
      typeof grant.ownerId !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(grant.ownerId) ||
      grant.uploadPath !== `performance-staging/${grant.ownerId}/${grant.draftId}/source` ||
      !Number.isSafeInteger(grant.sizeBytes) || (grant.sizeBytes as number) < 1 ||
      (grant.sizeBytes as number) > 50 * 1024 * 1024 ||
      !["video/mp4", "video/quicktime", "video/x-m4v"].includes(grant.contentType as string) ||
      !Number.isSafeInteger(grant.generation) || (grant.generation as number) < 1 ||
      !(grant.issuedAt instanceof admin.firestore.Timestamp) ||
      !(grant.expiresAt instanceof admin.firestore.Timestamp) ||
      grant.expiresAt.toMillis() - grant.issuedAt.toMillis() !== UPLOAD_GRANT_LIFETIME_MS) return null;
  return grant as UploadGrant;
}

export function requireFreeUploadSlot(profile: admin.firestore.DocumentData, nowMs: number): void {
  const value = profile.activePerformanceUpload;
  if (value === undefined || value === null) return;
  const grant = parseUploadGrant(value);
  if (!grant) throw new HttpsError("failed-precondition", "Your upload permission needs attention. Please contact support.", {
    reason: "upload-needs-recovery",
  });
  if (grant.expiresAt.toMillis() > nowMs) {
    throw new HttpsError("failed-precondition", "Finish or cancel your current upload before starting another, or retry after 30 minutes.", {
      reason: "upload-in-progress", draftId: grant.draftId,
    });
  }
}

// All reads precede this synchronous write helper. Only the matching slot clears.
export function clearMatchingUploadGrant(
  transaction: admin.firestore.Transaction,
  profile: admin.firestore.DocumentSnapshot,
  draftId: string,
): void {
  if (profile.exists && profile.data()?.activePerformanceUpload?.draftId === draftId) {
    transaction.update(profile.ref, { activePerformanceUpload: null });
  }
}
