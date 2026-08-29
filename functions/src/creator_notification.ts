import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function parseNotificationId(value: unknown): { notificationId: string } {
  if (!isRecord(value) || Object.keys(value).length !== 1) {
    throw new HttpsError("invalid-argument", "Invalid notification request.");
  }
  const notificationId = value.notificationId;
  if (
    typeof notificationId !== "string" ||
    !/^[A-Za-z0-9_-]{1,500}$/.test(notificationId)
  ) {
    throw new HttpsError("invalid-argument", "Invalid notification request.");
  }
  return { notificationId };
}

export async function handleMarkCreatorNotificationRead(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
}): Promise<{ read: true; changed: boolean }> {
  const { notificationId } = parseNotificationId(params.data);
  const notificationRef = params.firestore
    .collection("creatorNotifications")
    .doc(notificationId);
  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const deletionRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.uid);
  let changed = false;
  await params.firestore.runTransaction(async (transaction) => {
    const [notificationSnapshot, profileSnapshot, deletionSnapshot] =
      await Promise.all([
        transaction.get(notificationRef),
        transaction.get(profileRef),
        transaction.get(deletionRef),
      ]);
    const profile = profileSnapshot.data();
    if (
      !profile ||
      profile.banned !== false ||
      profile.ageConfirmed17Plus !== true ||
      profile.acceptedPolicyVersion !== "v1" ||
      profile.deletionPending === true ||
      deletionSnapshot.exists
    ) {
      throw new HttpsError("permission-denied", "Notifications are unavailable.");
    }
    const notification = notificationSnapshot.data();
    if (!notification || notification.ownerId !== params.uid) {
      throw new HttpsError("not-found", "Notification not found.");
    }
    if (notification.read === true) return;
    transaction.update(notificationRef, {
      read: true,
      readAt: params.now(),
    });
    changed = true;
  });
  return { read: true, changed };
}
