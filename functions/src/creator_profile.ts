import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { CURRENT_POLICY_VERSION } from "./policy";

const HANDLE_PATTERN = /^[a-z0-9_]{3,24}$/;

type CreatorIdentity = {
  displayName: string;
  handle: string;
  bio: string;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function parseCreatorIdentity(data: unknown): CreatorIdentity {
  if (!isRecord(data)) {
    throw new HttpsError("invalid-argument", "Invalid creator profile.");
  }
  const keys = Object.keys(data).sort();
  const expected = ["bio", "displayName", "handle"];
  if (
    keys.length !== expected.length ||
    keys.some((key, index) => key !== expected[index]) ||
    typeof data.displayName !== "string" ||
    typeof data.handle !== "string" ||
    typeof data.bio !== "string"
  ) {
    throw new HttpsError("invalid-argument", "Invalid creator profile.");
  }

  const displayName = data.displayName.trim();
  const handle = data.handle.trim().toLowerCase();
  const bio = data.bio.trim();
  if (
    displayName.length < 1 ||
    displayName.length > 50 ||
    !HANDLE_PATTERN.test(handle) ||
    bio.length > 160
  ) {
    throw new HttpsError("invalid-argument", "Invalid creator profile.");
  }
  return { displayName, handle, bio };
}

function safeCounter(value: unknown): number {
  return typeof value === "number" && Number.isInteger(value) && value >= 0
    ? value
    : 0;
}

export async function handleUpdateCreatorProfile(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
}): Promise<CreatorIdentity> {
  const identity = parseCreatorIdentity(params.data);
  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const deletionJobRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.uid);
  const creatorRef = params.firestore
    .collection("creatorProfiles")
    .doc(params.uid);
  const newHandleRef = params.firestore
    .collection("creatorHandles")
    .doc(identity.handle);

  await params.firestore.runTransaction(async (transaction) => {
    const [profileSnapshot, deletionJobSnapshot, creatorSnapshot] =
      await Promise.all([
        transaction.get(profileRef),
        transaction.get(deletionJobRef),
        transaction.get(creatorRef),
      ]);

    if (!profileSnapshot.exists) {
      throw new HttpsError("failed-precondition", "Account profile is unavailable.");
    }
    const account = profileSnapshot.data()!;
    if (
      account.banned !== false ||
      account.ageConfirmed17Plus !== true ||
      account.acceptedPolicyVersion !== CURRENT_POLICY_VERSION
    ) {
      throw new HttpsError(
        "permission-denied",
        "This account cannot publish a creator profile."
      );
    }
    if (account.deletionPending === true || deletionJobSnapshot.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Account deletion is in progress."
      );
    }

    const existing = creatorSnapshot.exists ? creatorSnapshot.data()! : undefined;
    if (existing?.removed === true) {
      throw new HttpsError("failed-precondition", "Creator profile is unavailable.");
    }
    const oldHandle = typeof existing?.handle === "string"
      ? existing.handle.toLowerCase()
      : undefined;
    const oldHandleRef = oldHandle && oldHandle !== identity.handle
      ? params.firestore.collection("creatorHandles").doc(oldHandle)
      : undefined;

    const newHandleSnapshot = await transaction.get(newHandleRef);
    const oldHandleSnapshot = oldHandleRef
      ? await transaction.get(oldHandleRef)
      : undefined;
    if (
      newHandleSnapshot.exists &&
      newHandleSnapshot.data()?.uid !== params.uid
    ) {
      throw new HttpsError("already-exists", "That handle is unavailable.");
    }

    const timestamp = params.now();
    transaction.set(newHandleRef, {
      uid: params.uid,
      handle: identity.handle,
      createdAt: newHandleSnapshot.exists
        ? newHandleSnapshot.data()?.createdAt ?? timestamp
        : timestamp,
      updatedAt: timestamp,
    });
    if (oldHandleRef && oldHandleSnapshot?.data()?.uid === params.uid) {
      transaction.delete(oldHandleRef);
    }

    transaction.update(profileRef, {
      displayName: identity.displayName,
      updatedAt: timestamp,
    });
    transaction.set(creatorRef, {
      handle: identity.handle,
      displayName: identity.displayName,
      bio: identity.bio,
      followerCount: safeCounter(existing?.followerCount),
      followingCount: safeCounter(existing?.followingCount),
      performanceCount: safeCounter(existing?.performanceCount),
      likeCount: safeCounter(existing?.likeCount),
      shareCount: safeCounter(existing?.shareCount),
      hidden: existing?.hidden === true,
      removed: false,
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
    });
  });

  return identity;
}
