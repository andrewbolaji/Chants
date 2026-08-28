import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

const SOCIAL_SCHEMA_VERSION = 1;

type Data = admin.firestore.DocumentData;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasExactKeys(value: Record<string, unknown>, expected: string[]): boolean {
  const keys = Object.keys(value).sort();
  const sorted = [...expected].sort();
  return keys.length === sorted.length &&
    keys.every((key, index) => key === sorted[index]);
}

function cleanId(value: unknown): string {
  return typeof value === "string" && /^[A-Za-z0-9_-]{1,200}$/.test(value)
    ? value
    : "";
}

export function parseCreatorFollow(value: unknown): {
  targetCreatorId: string;
  following: boolean;
} {
  if (!isRecord(value) || !hasExactKeys(value, ["following", "targetCreatorId"])) {
    throw new HttpsError("invalid-argument", "Invalid creator follow request.");
  }
  const targetCreatorId = cleanId(value.targetCreatorId);
  if (!targetCreatorId || typeof value.following !== "boolean") {
    throw new HttpsError("invalid-argument", "Invalid creator follow request.");
  }
  return { targetCreatorId, following: value.following };
}

function requireActiveAccount(
  account: Data | undefined,
  deletionJobExists: boolean
): void {
  if (
    !account ||
    account.banned !== false ||
    account.ageConfirmed17Plus !== true ||
    account.acceptedPolicyVersion !== "v1"
  ) {
    throw new HttpsError("permission-denied", "This account cannot follow creators.");
  }
  if (account.deletionPending === true || deletionJobExists) {
    throw new HttpsError("failed-precondition", "Account deletion is in progress.");
  }
}

function requireVisibleCreator(creator: Data | undefined): asserts creator is Data {
  if (
    !creator ||
    creator.hidden !== false ||
    creator.removed !== false ||
    typeof creator.handle !== "string" ||
    typeof creator.displayName !== "string"
  ) {
    throw new HttpsError("not-found", "This creator is unavailable.");
  }
}

function edgeId(followerId: string, followedId: string): string {
  return `${followerId}_${followedId}`;
}

export async function handleSetCreatorFollow(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
}): Promise<{ following: boolean; changed: boolean }> {
  const input = parseCreatorFollow(params.data);
  if (input.targetCreatorId === params.uid) {
    throw new HttpsError("invalid-argument", "A creator cannot follow themselves.");
  }

  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const deletionRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.uid);
  const targetDeletionRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(input.targetCreatorId);
  const actorCreatorRef = params.firestore
    .collection("creatorProfiles")
    .doc(params.uid);
  const targetCreatorRef = params.firestore
    .collection("creatorProfiles")
    .doc(input.targetCreatorId);
  const forwardBlockRef = params.firestore
    .collection("blocks")
    .doc(`${params.uid}_${input.targetCreatorId}`);
  const reverseBlockRef = params.firestore
    .collection("blocks")
    .doc(`${input.targetCreatorId}_${params.uid}`);
  const followId = edgeId(params.uid, input.targetCreatorId);
  const followRef = params.firestore.collection("creatorFollows").doc(followId);
  const notificationRef = params.firestore
    .collection("creatorNotifications")
    .doc(`follow_${followId}`);
  let changed = false;

  await params.firestore.runTransaction(async (transaction) => {
    const [
      profileSnapshot,
      deletionSnapshot,
      targetDeletionSnapshot,
      actorCreatorSnapshot,
      targetCreatorSnapshot,
      forwardBlockSnapshot,
      reverseBlockSnapshot,
      followSnapshot,
      notificationSnapshot,
    ] = await Promise.all([
      transaction.get(profileRef),
      transaction.get(deletionRef),
      transaction.get(targetDeletionRef),
      transaction.get(actorCreatorRef),
      transaction.get(targetCreatorRef),
      transaction.get(forwardBlockRef),
      transaction.get(reverseBlockRef),
      transaction.get(followRef),
      transaction.get(notificationRef),
    ]);
    requireActiveAccount(profileSnapshot.data(), deletionSnapshot.exists);
    requireVisibleCreator(actorCreatorSnapshot.data());
    requireVisibleCreator(targetCreatorSnapshot.data());
    if (targetDeletionSnapshot.exists) {
      throw new HttpsError("not-found", "This creator is unavailable.");
    }
    if (forwardBlockSnapshot.exists || reverseBlockSnapshot.exists) {
      throw new HttpsError("permission-denied", "This follow is unavailable.");
    }

    if (input.following) {
      if (followSnapshot.exists) return;
      const timestamp = params.now();
      const actor = actorCreatorSnapshot.data()!;
      transaction.create(followRef, {
        schemaVersion: SOCIAL_SCHEMA_VERSION,
        followerId: params.uid,
        followedId: input.targetCreatorId,
        createdAt: timestamp,
      });
      if (!notificationSnapshot.exists) {
        transaction.create(notificationRef, {
          schemaVersion: SOCIAL_SCHEMA_VERSION,
          ownerId: input.targetCreatorId,
          actorId: params.uid,
          actorHandle: actor.handle,
          actorDisplayName: actor.displayName,
          type: "creator_follow",
          performanceId: null,
          commentId: null,
          read: false,
          createdAt: timestamp,
          readAt: null,
        });
      }
      changed = true;
      return;
    }

    if (!followSnapshot.exists) return;
    transaction.delete(followRef);
    changed = true;
  });
  return { following: input.following, changed };
}

function safeId(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

export async function recomputeCreatorFollowCounts(params: {
  before: Data | undefined;
  after: Data | undefined;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
}): Promise<boolean> {
  const followerId = safeId(params.after?.followerId ?? params.before?.followerId);
  const followedId = safeId(params.after?.followedId ?? params.before?.followedId);
  if (!followerId || !followedId) return false;

  const followingQuery = params.firestore
    .collection("creatorFollows")
    .where("followerId", "==", followerId);
  const followerQuery = params.firestore
    .collection("creatorFollows")
    .where("followedId", "==", followedId);
  const followerCreatorRef = params.firestore
    .collection("creatorProfiles")
    .doc(followerId);
  const followedCreatorRef = params.firestore
    .collection("creatorProfiles")
    .doc(followedId);

  return params.firestore.runTransaction(async (transaction) => {
    const [
      followingSnapshot,
      followerSnapshot,
      followerCreatorSnapshot,
      followedCreatorSnapshot,
    ] = await Promise.all([
      transaction.get(followingQuery),
      transaction.get(followerQuery),
      transaction.get(followerCreatorRef),
      transaction.get(followedCreatorRef),
    ]);
    const timestamp = params.now();
    if (followerCreatorSnapshot.exists) {
      transaction.update(followerCreatorRef, {
        followingCount: followingSnapshot.size,
        updatedAt: timestamp,
      });
    }
    if (followedCreatorSnapshot.exists) {
      transaction.update(followedCreatorRef, {
        followerCount: followerSnapshot.size,
        updatedAt: timestamp,
      });
    }
    return followerCreatorSnapshot.exists || followedCreatorSnapshot.exists;
  });
}
