import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import {
  currentChantSourceVisible,
  currentCreatorSourceVisible,
} from "./performance_source";

export const PERFORMANCE_SCHEMA_VERSION = 1;
export const MAX_PERFORMANCE_DURATION_MS = 30_000;
export const MAX_PERFORMANCE_BYTES = 50 * 1024 * 1024;
export const PERFORMANCE_CONTENT_TYPES = [
  "video/mp4",
  "video/quicktime",
  "video/x-m4v",
] as const;

type Data = admin.firestore.DocumentData;
type Clock = () => admin.firestore.Timestamp;

export type StagedMediaMetadata = {
  size: number;
  contentType: string;
  generation: string;
  customMetadata: Record<string, string>;
};

export type PerformanceMediaGateway = {
  inspect: (path: string) => Promise<StagedMediaMetadata>;
  copy: (sourcePath: string, destinationPath: string) => Promise<void>;
  remove: (path: string) => Promise<void>;
  signReadUrl: (path: string, expiresAtMs: number) => Promise<string>;
};

type CreatePerformanceDraftInput = {
  chantId: string;
  caption: string;
  contentType: string;
  sizeBytes: number;
  durationMs: number;
};

type DraftIdInput = { draftId: string };
type PerformanceIdInput = { performanceId: string };

type ModeratePerformanceInput = DraftIdInput & {
  action: "approve" | "reject";
  reason: string;
};

type PerformanceLikeInput = PerformanceIdInput & { liked: boolean };
type PerformanceCommentInput = PerformanceIdInput & {
  body: string;
  clientActionId: string;
  parentCommentId: string | null;
};
type PerformanceCommentIdInput = { commentId: string };

const QUALIFIED_VIEW_MS = 3_000;
const PLAYBACK_SESSION_MS = 10 * 60 * 1_000;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasExactKeys(value: Record<string, unknown>, expected: string[]): boolean {
  const keys = Object.keys(value).sort();
  const sortedExpected = [...expected].sort();
  return keys.length === sortedExpected.length &&
    keys.every((key, index) => key === sortedExpected[index]);
}

function cleanId(value: unknown): string {
  return typeof value === "string" && /^[A-Za-z0-9_-]{1,200}$/.test(value)
    ? value
    : "";
}

function cleanText(value: unknown, maximum: number): string | null {
  if (typeof value !== "string") return null;
  const cleaned = value.trim();
  return cleaned.length <= maximum ? cleaned : null;
}

export function parseCreatePerformanceDraft(
  value: unknown
): CreatePerformanceDraftInput {
  if (!isRecord(value) || !hasExactKeys(value, [
    "caption",
    "chantId",
    "contentType",
    "durationMs",
    "sizeBytes",
  ])) {
    throw new HttpsError("invalid-argument", "Invalid performance draft.");
  }
  const chantId = cleanId(value.chantId);
  const caption = cleanText(value.caption, 300);
  const contentType = typeof value.contentType === "string"
    ? value.contentType.toLowerCase()
    : "";
  const sizeBytes = value.sizeBytes;
  const durationMs = value.durationMs;
  if (
    !chantId ||
    caption === null ||
    !PERFORMANCE_CONTENT_TYPES.includes(
      contentType as (typeof PERFORMANCE_CONTENT_TYPES)[number]
    ) ||
    typeof sizeBytes !== "number" ||
    !Number.isInteger(sizeBytes) ||
    sizeBytes < 1 ||
    sizeBytes > MAX_PERFORMANCE_BYTES ||
    typeof durationMs !== "number" ||
    !Number.isInteger(durationMs) ||
    durationMs < 1 ||
    durationMs > MAX_PERFORMANCE_DURATION_MS
  ) {
    throw new HttpsError("invalid-argument", "Invalid performance draft.");
  }
  return { chantId, caption, contentType, sizeBytes, durationMs };
}

export function parseDraftId(value: unknown): DraftIdInput {
  if (!isRecord(value) || !hasExactKeys(value, ["draftId"])) {
    throw new HttpsError("invalid-argument", "Invalid performance request.");
  }
  const draftId = cleanId(value.draftId);
  if (!draftId) {
    throw new HttpsError("invalid-argument", "Invalid performance request.");
  }
  return { draftId };
}

export function parsePerformanceId(value: unknown): PerformanceIdInput {
  if (!isRecord(value) || !hasExactKeys(value, ["performanceId"])) {
    throw new HttpsError("invalid-argument", "Invalid performance request.");
  }
  const performanceId = cleanId(value.performanceId);
  if (!performanceId) {
    throw new HttpsError("invalid-argument", "Invalid performance request.");
  }
  return { performanceId };
}

export function parseModeratePerformance(value: unknown): ModeratePerformanceInput {
  if (!isRecord(value) || !hasExactKeys(value, ["action", "draftId", "reason"])) {
    throw new HttpsError("invalid-argument", "Invalid moderation request.");
  }
  const draftId = cleanId(value.draftId);
  const reason = cleanText(value.reason, 300);
  if (
    !draftId ||
    (value.action !== "approve" && value.action !== "reject") ||
    reason === null ||
    (value.action === "reject" && reason.length === 0)
  ) {
    throw new HttpsError("invalid-argument", "Invalid moderation request.");
  }
  return { draftId, action: value.action, reason };
}

export function parsePerformanceLike(value: unknown): PerformanceLikeInput {
  if (!isRecord(value) || !hasExactKeys(value, ["liked", "performanceId"])) {
    throw new HttpsError("invalid-argument", "Invalid performance like.");
  }
  const performanceId = cleanId(value.performanceId);
  if (!performanceId || typeof value.liked !== "boolean") {
    throw new HttpsError("invalid-argument", "Invalid performance like.");
  }
  return { performanceId, liked: value.liked };
}

export function parsePerformanceComment(value: unknown): PerformanceCommentInput {
  if (!isRecord(value) || !hasExactKeys(value, [
    "body",
    "clientActionId",
    "parentCommentId",
    "performanceId",
  ])) {
    throw new HttpsError("invalid-argument", "Invalid performance comment.");
  }
  const performanceId = cleanId(value.performanceId);
  const clientActionId = cleanId(value.clientActionId);
  const body = cleanText(value.body, 500);
  const parentCommentId = value.parentCommentId === null
    ? null
    : cleanId(value.parentCommentId);
  if (
    !performanceId ||
    !clientActionId ||
    body === null ||
    body.length === 0 ||
    parentCommentId === ""
  ) {
    throw new HttpsError("invalid-argument", "Invalid performance comment.");
  }
  return { performanceId, body, clientActionId, parentCommentId };
}

export function performanceMentionHandles(body: string): string[] {
  const handles: string[] = [];
  const seen = new Set<string>();
  const pattern = /@([a-z0-9_]{3,24})(?![a-z0-9_])/gi;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(body)) !== null && handles.length < 5) {
    const handle = match[1].toLowerCase();
    if (!seen.has(handle)) {
      seen.add(handle);
      handles.push(handle);
    }
  }
  return handles;
}

export function parsePerformanceCommentId(
  value: unknown
): PerformanceCommentIdInput {
  if (!isRecord(value) || !hasExactKeys(value, ["commentId"])) {
    throw new HttpsError("invalid-argument", "Invalid performance comment.");
  }
  const commentId = cleanId(value.commentId);
  if (!commentId) {
    throw new HttpsError("invalid-argument", "Invalid performance comment.");
  }
  return { commentId };
}

function requireActiveAccount(account: Data | undefined, deletionJobExists: boolean): void {
  if (
    !account ||
    account.banned !== false ||
    account.ageConfirmed17Plus !== true ||
    account.acceptedPolicyVersion !== "v1"
  ) {
    throw new HttpsError("permission-denied", "This account cannot use this feature.");
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
    throw new HttpsError(
      "failed-precondition",
      "Create a visible creator profile before performing a chant."
    );
  }
}

function requireVisibleChant(chant: Data | undefined): asserts chant is Data {
  if (
    !chant ||
    chant.hidden !== false ||
    chant.removed !== false ||
    typeof chant.title !== "string" ||
    typeof chant.teamId !== "string" ||
    (chant.status !== "canonical" && chant.status !== "community")
  ) {
    throw new HttpsError("failed-precondition", "This chant is unavailable.");
  }
}

function requireVisiblePerformance(
  performance: Data | undefined
): asserts performance is Data {
  if (
    !performance ||
    performance.schemaVersion !== PERFORMANCE_SCHEMA_VERSION ||
    performance.publicationState !== "approved" ||
    performance.hidden !== false ||
    performance.removed !== false ||
    performance.sourceChantVisible !== true ||
    performance.sourceCreatorVisible !== true ||
    typeof performance.chantId !== "string" ||
    typeof performance.creatorId !== "string"
  ) {
    throw new HttpsError("not-found", "Performance is unavailable.");
  }
}

function safeCount(value: unknown): number {
  return typeof value === "number" && Number.isInteger(value) && value >= 0
    ? value
    : 0;
}

function weeklyCounts(performance: Data, week: string) {
  return performance.rankingWeek === week
    ? {
        weeklyUniqueSharerCount: safeCount(performance.weeklyUniqueSharerCount),
        weeklyLikeCount: safeCount(performance.weeklyLikeCount),
        weeklyQualifiedViewCount: safeCount(performance.weeklyQualifiedViewCount),
      }
    : {
        weeklyUniqueSharerCount: 0,
        weeklyLikeCount: 0,
        weeklyQualifiedViewCount: 0,
      };
}

function interactionId(uid: string, performanceId: string): string {
  return `${uid}_${performanceId}`;
}

function blockRefs(
  firestore: admin.firestore.Firestore,
  uid: string,
  creatorId: string
) {
  return [
    firestore.collection("blocks").doc(`${uid}_${creatorId}`),
    firestore.collection("blocks").doc(`${creatorId}_${uid}`),
  ];
}

function requireNoBlock(
  uid: string,
  creatorId: string,
  blockSnapshots: admin.firestore.DocumentSnapshot[]
): void {
  if (uid !== creatorId && blockSnapshots.some((snapshot) => snapshot.exists)) {
    throw new HttpsError("permission-denied", "This interaction is unavailable.");
  }
}

async function interactionAuthority(params: {
  uid: string;
  performanceId: string;
  firestore: admin.firestore.Firestore;
  transaction: admin.firestore.Transaction;
  actorAuthority?: { account: Data | undefined; deletionJobExists: boolean };
}): Promise<{
  performance: Data;
  performanceRef: admin.firestore.DocumentReference;
}> {
  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const deletionRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.uid);
  const performanceRef = params.firestore
    .collection("performances")
    .doc(params.performanceId);
  let profile: Data | undefined;
  let deletionJobExists: boolean;
  let performanceSnapshot: admin.firestore.DocumentSnapshot;
  if (params.actorAuthority) {
    profile = params.actorAuthority.account;
    deletionJobExists = params.actorAuthority.deletionJobExists;
    performanceSnapshot = await params.transaction.get(performanceRef);
  } else {
    const [profileSnapshot, deletionSnapshot, loadedPerformance] =
      await Promise.all([
        params.transaction.get(profileRef),
        params.transaction.get(deletionRef),
        params.transaction.get(performanceRef),
      ]);
    profile = profileSnapshot.data();
    deletionJobExists = deletionSnapshot.exists;
    performanceSnapshot = loadedPerformance;
  }
  requireActiveAccount(profile, deletionJobExists);
  const performance = performanceSnapshot.data();
  requireVisiblePerformance(performance);
  const creatorId = performance.creatorId as string;
  const chantId = performance.chantId as string;
  const [creatorAccountSnapshot, creatorDeletionSnapshot, creatorSnapshot, chantSnapshot] =
    await Promise.all([
      params.transaction.get(
        params.firestore.collection("profiles").doc(creatorId)
      ),
      params.transaction.get(
        params.firestore.collection("accountDeletionJobs").doc(creatorId)
      ),
      params.transaction.get(
        params.firestore.collection("creatorProfiles").doc(creatorId)
      ),
      params.transaction.get(
        params.firestore.collection("chants").doc(chantId)
      ),
    ]);
  if (
    !currentCreatorSourceVisible({
      account: creatorAccountSnapshot.data(),
      creator: creatorSnapshot.data(),
      deletionJobExists: creatorDeletionSnapshot.exists,
    }) ||
    !currentChantSourceVisible(chantSnapshot.data())
  ) {
    throw new HttpsError("not-found", "Performance is unavailable.");
  }
  if (profile?.role !== "operator") {
    const refs = blockRefs(
      params.firestore,
      params.uid,
      performance.creatorId as string
    );
    const snapshots = await Promise.all(
      refs.map((reference) => params.transaction.get(reference))
    );
    requireNoBlock(params.uid, performance.creatorId as string, snapshots);
  }
  return { performance, performanceRef };
}

function dailyUploadLimit(account: Data, now: admin.firestore.Timestamp): number {
  const createdAt = account.createdAt;
  if (createdAt instanceof admin.firestore.Timestamp) {
    const establishedAt = now.toMillis() - 30 * 24 * 60 * 60 * 1000;
    if (createdAt.toMillis() <= establishedAt) return 5;
  }
  return 2;
}

function utcDay(timestamp: admin.firestore.Timestamp): string {
  return timestamp.toDate().toISOString().slice(0, 10);
}

export function performanceRankingWeek(
  timestamp: admin.firestore.Timestamp
): string {
  const date = timestamp.toDate();
  const day = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() - day + 1);
  return date.toISOString().slice(0, 10);
}

export async function handleCreatePerformanceDraft(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: Clock;
  newId: () => string;
}): Promise<{ draftId: string; uploadPath: string }> {
  const input = parseCreatePerformanceDraft(params.data);
  const timestamp = params.now();
  const draftId = cleanId(params.newId());
  if (!draftId) throw new Error("Generated an invalid performance draft ID.");
  const uploadPath = `performance-staging/${params.uid}/${draftId}/source`;
  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const deletionRef = params.firestore.collection("accountDeletionJobs").doc(params.uid);
  const creatorRef = params.firestore.collection("creatorProfiles").doc(params.uid);
  const chantRef = params.firestore.collection("chants").doc(input.chantId);
  const draftRef = params.firestore.collection("performanceDrafts").doc(draftId);
  const limitRef = params.firestore
    .collection("performanceUploadLimits")
    .doc(`${params.uid}_${utcDay(timestamp)}`);

  await params.firestore.runTransaction(async (transaction) => {
    const [profileSnapshot, deletionSnapshot, creatorSnapshot, chantSnapshot, limitSnapshot] =
      await Promise.all([
        transaction.get(profileRef),
        transaction.get(deletionRef),
        transaction.get(creatorRef),
        transaction.get(chantRef),
        transaction.get(limitRef),
      ]);
    const account = profileSnapshot.data();
    const creator = creatorSnapshot.data();
    const chant = chantSnapshot.data();
    requireActiveAccount(account, deletionSnapshot.exists);
    requireVisibleCreator(creator);
    requireVisibleChant(chant);

    const limit = dailyUploadLimit(account!, timestamp);
    const count = limitSnapshot.exists && Number.isInteger(limitSnapshot.data()?.count)
      ? limitSnapshot.data()!.count as number
      : 0;
    if (count >= limit) {
      throw new HttpsError(
        "resource-exhausted",
        "You have reached today's performance upload limit."
      );
    }

    const teamSnapshot = await transaction.get(
      params.firestore.collection("teams").doc(chant.teamId as string)
    );
    const teamName = teamSnapshot.data()?.name;
    if (typeof teamName !== "string" || teamName.length === 0) {
      throw new HttpsError("failed-precondition", "This club is unavailable.");
    }
    let playerName: string | null = null;
    if (typeof chant.playerId === "string" && chant.playerId.length > 0) {
      const playerSnapshot = await transaction.get(
        params.firestore.collection("players").doc(chant.playerId)
      );
      if (
        playerSnapshot.data()?.teamId === chant.teamId &&
        typeof playerSnapshot.data()?.name === "string"
      ) {
        playerName = playerSnapshot.data()!.name as string;
      }
    }

    transaction.create(draftRef, {
      schemaVersion: PERFORMANCE_SCHEMA_VERSION,
      ownerId: params.uid,
      chantId: input.chantId,
      chantTitle: chant.title,
      teamId: chant.teamId,
      teamName,
      playerName,
      chantStatus: chant.status,
      creatorHandle: creator.handle,
      creatorDisplayName: creator.displayName,
      caption: input.caption,
      uploadPath,
      claimedContentType: input.contentType,
      claimedSizeBytes: input.sizeBytes,
      claimedDurationMs: input.durationMs,
      state: "awaiting_upload",
      moderationReason: null,
      sourceGeneration: null,
      verifiedContentType: null,
      verifiedSizeBytes: null,
      createdAt: timestamp,
      updatedAt: timestamp,
      submittedAt: null,
      reviewedAt: null,
    });
    transaction.set(limitRef, {
      ownerId: params.uid,
      utcDay: utcDay(timestamp),
      count: count + 1,
      limit,
      updatedAt: timestamp,
    });
  });

  return { draftId, uploadPath };
}

function verifyStagedObject(
  draftId: string,
  uid: string,
  draft: Data,
  metadata: StagedMediaMetadata
): void {
  if (
    metadata.size < 1 ||
    metadata.size > MAX_PERFORMANCE_BYTES ||
    metadata.size !== draft.claimedSizeBytes ||
    !PERFORMANCE_CONTENT_TYPES.includes(
      metadata.contentType as (typeof PERFORMANCE_CONTENT_TYPES)[number]
    ) ||
    metadata.contentType !== draft.claimedContentType ||
    metadata.customMetadata.ownerId !== uid ||
    metadata.customMetadata.draftId !== draftId ||
    metadata.customMetadata.schemaVersion !== `${PERFORMANCE_SCHEMA_VERSION}` ||
    !metadata.generation
  ) {
    throw new HttpsError("failed-precondition", "Uploaded media did not pass validation.");
  }
}

export async function handleSubmitPerformanceDraft(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  media: PerformanceMediaGateway;
  now: Clock;
}): Promise<{ accepted: true; state: "pending_review" }> {
  const { draftId } = parseDraftId(params.data);
  const draftRef = params.firestore.collection("performanceDrafts").doc(draftId);
  const firstSnapshot = await draftRef.get();
  const firstDraft = firstSnapshot.data();
  if (!firstDraft || firstDraft.ownerId !== params.uid) {
    throw new HttpsError("not-found", "Performance draft not found.");
  }
  if (firstDraft.state === "pending_review") {
    return { accepted: true, state: "pending_review" };
  }
  if (firstDraft.state !== "awaiting_upload") {
    throw new HttpsError("failed-precondition", "This draft cannot be submitted.");
  }
  const metadata = await params.media.inspect(firstDraft.uploadPath as string);
  verifyStagedObject(draftId, params.uid, firstDraft, metadata);
  const timestamp = params.now();

  await params.firestore.runTransaction(async (transaction) => {
    const [draftSnapshot, profileSnapshot, deletionSnapshot, creatorSnapshot, chantSnapshot] =
      await Promise.all([
        transaction.get(draftRef),
        transaction.get(params.firestore.collection("profiles").doc(params.uid)),
        transaction.get(params.firestore.collection("accountDeletionJobs").doc(params.uid)),
        transaction.get(params.firestore.collection("creatorProfiles").doc(params.uid)),
        transaction.get(params.firestore.collection("chants").doc(firstDraft.chantId as string)),
      ]);
    const draft = draftSnapshot.data();
    if (!draft || draft.ownerId !== params.uid) {
      throw new HttpsError("not-found", "Performance draft not found.");
    }
    if (draft.state === "pending_review") return;
    if (
      draft.state !== "awaiting_upload" ||
      draft.uploadPath !== firstDraft.uploadPath ||
      draft.claimedSizeBytes !== metadata.size ||
      draft.claimedContentType !== metadata.contentType
    ) {
      throw new HttpsError("failed-precondition", "This draft changed during upload.");
    }
    requireActiveAccount(profileSnapshot.data(), deletionSnapshot.exists);
    requireVisibleCreator(creatorSnapshot.data());
    requireVisibleChant(chantSnapshot.data());
    transaction.update(draftRef, {
      state: "pending_review",
      sourceGeneration: metadata.generation,
      verifiedContentType: metadata.contentType,
      verifiedSizeBytes: metadata.size,
      submittedAt: timestamp,
      updatedAt: timestamp,
    });
  });
  return { accepted: true, state: "pending_review" };
}

export async function handleCancelPerformanceDraft(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  media: PerformanceMediaGateway;
  now: Clock;
}): Promise<{ cancelled: true }> {
  const { draftId } = parseDraftId(params.data);
  const draftRef = params.firestore.collection("performanceDrafts").doc(draftId);
  const timestamp = params.now();
  let uploadPath: string | undefined;
  await params.firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(draftRef);
    const draft = snapshot.data();
    if (!draft || draft.ownerId !== params.uid) {
      throw new HttpsError("not-found", "Performance draft not found.");
    }
    if (draft.state === "approved" || draft.state === "cancelled") {
      if (draft.state === "approved") {
        throw new HttpsError("failed-precondition", "A live performance cannot be cancelled.");
      }
      return;
    }
    uploadPath = typeof draft.uploadPath === "string" ? draft.uploadPath : undefined;
    transaction.update(draftRef, {
      state: "cancelled",
      updatedAt: timestamp,
      reviewedAt: timestamp,
    });
  });
  if (uploadPath) await params.media.remove(uploadPath).catch(() => undefined);
  return { cancelled: true };
}

function requireOperator(profile: Data | undefined): void {
  if (
    !profile ||
    profile.role !== "operator" ||
    profile.banned !== false ||
    profile.deletionPending === true
  ) {
    throw new HttpsError("permission-denied", "Operator access required.");
  }
}

export async function handleModeratePerformance(params: {
  actorUid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  media: PerformanceMediaGateway;
  now: Clock;
}): Promise<{ state: "approved" | "rejected"; performanceId?: string }> {
  const input = parseModeratePerformance(params.data);
  const draftRef = params.firestore.collection("performanceDrafts").doc(input.draftId);
  const actorSnapshot = await params.firestore.collection("profiles").doc(params.actorUid).get();
  requireOperator(actorSnapshot.data());
  const initialSnapshot = await draftRef.get();
  const initialDraft = initialSnapshot.data();
  if (!initialDraft) throw new HttpsError("not-found", "Performance draft not found.");
  if (initialDraft.state === "approved") {
    return { state: "approved", performanceId: input.draftId };
  }
  if (initialDraft.state === "rejected") return { state: "rejected" };
  if (initialDraft.state !== "pending_review") {
    throw new HttpsError("failed-precondition", "This draft is not ready for review.");
  }

  const timestamp = params.now();
  if (input.action === "reject") {
    await params.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(draftRef);
      const draft = snapshot.data();
      if (!draft || draft.state !== "pending_review") {
        throw new HttpsError("failed-precondition", "This draft changed during review.");
      }
      transaction.update(draftRef, {
        state: "rejected",
        moderationReason: input.reason,
        reviewedBy: params.actorUid,
        reviewedAt: timestamp,
        updatedAt: timestamp,
      });
    });
    await params.media.remove(initialDraft.uploadPath as string).catch(() => undefined);
    return { state: "rejected" };
  }

  const mediaPath = `performance-media/${input.draftId}/source`;
  await params.media.copy(initialDraft.uploadPath as string, mediaPath);
  await params.firestore.runTransaction(async (transaction) => {
    const [draftSnapshot, accountSnapshot, deletionSnapshot, creatorSnapshot, chantSnapshot] =
      await Promise.all([
        transaction.get(draftRef),
        transaction.get(params.firestore.collection("profiles").doc(initialDraft.ownerId as string)),
        transaction.get(params.firestore.collection("accountDeletionJobs").doc(initialDraft.ownerId as string)),
        transaction.get(params.firestore.collection("creatorProfiles").doc(initialDraft.ownerId as string)),
        transaction.get(params.firestore.collection("chants").doc(initialDraft.chantId as string)),
      ]);
    const draft = draftSnapshot.data();
    if (!draft) throw new HttpsError("not-found", "Performance draft not found.");
    if (draft.state === "approved") return;
    if (draft.state !== "pending_review") {
      throw new HttpsError("failed-precondition", "This draft changed during review.");
    }
    requireActiveAccount(accountSnapshot.data(), deletionSnapshot.exists);
    const creator = creatorSnapshot.data();
    const chant = chantSnapshot.data();
    requireVisibleCreator(creator);
    requireVisibleChant(chant);
    if (chant.teamId !== draft.teamId) {
      throw new HttpsError("failed-precondition", "The chant changed during review.");
    }

    transaction.create(params.firestore.collection("performances").doc(input.draftId), {
      schemaVersion: PERFORMANCE_SCHEMA_VERSION,
      chantId: draft.chantId,
      chantTitle: chant.title,
      teamId: draft.teamId,
      teamName: draft.teamName,
      playerName: draft.playerName,
      chantStatus: chant.status,
      creatorId: draft.ownerId,
      creatorHandle: creator.handle,
      creatorDisplayName: creator.displayName,
      caption: draft.caption,
      mediaPath,
      durationMs: draft.claimedDurationMs,
      publicationState: "approved",
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      uniqueSharerCount: 0,
      weeklyUniqueSharerCount: 0,
      weeklyLikeCount: 0,
      weeklyQualifiedViewCount: 0,
      rankingWeek: performanceRankingWeek(timestamp),
      hidden: false,
      removed: false,
      sourceChantVisible: true,
      sourceCreatorVisible: true,
      createdAt: draft.createdAt,
      approvedAt: timestamp,
      updatedAt: timestamp,
    });
    transaction.update(draftRef, {
      state: "approved",
      moderationReason: null,
      mediaPath,
      reviewedBy: params.actorUid,
      reviewedAt: timestamp,
      updatedAt: timestamp,
    });
    transaction.update(creatorSnapshot.ref, {
      performanceCount: admin.firestore.FieldValue.increment(1),
      updatedAt: timestamp,
    });
  });
  await params.media.remove(initialDraft.uploadPath as string).catch(() => undefined);
  return { state: "approved", performanceId: input.draftId };
}

export async function handleResolvePerformancePlayback(params: {
  actorUid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  media: PerformanceMediaGateway;
  now: Clock;
}): Promise<{ url: string; expiresAtMs: number }> {
  const { performanceId } = parsePerformanceId(params.data);
  const timestamp = params.now();
  const sessionRef = params.firestore
    .collection("performancePlaybackSessions")
    .doc(interactionId(params.actorUid, performanceId));
  let mediaPath = "";
  await params.firestore.runTransaction(async (transaction) => {
    const [actorSnapshot, deletionSnapshot] = await Promise.all([
      transaction.get(params.firestore.collection("profiles").doc(params.actorUid)),
      transaction.get(
        params.firestore.collection("accountDeletionJobs").doc(params.actorUid)
      ),
    ]);
    const actor = actorSnapshot.data();
    requireActiveAccount(actor, deletionSnapshot.exists);
    let performance: Data;
    if (actor?.role === "operator") {
      const performanceSnapshot = await transaction.get(
        params.firestore.collection("performances").doc(performanceId)
      );
      const candidate = performanceSnapshot.data();
      if (
        !candidate ||
        candidate.schemaVersion !== PERFORMANCE_SCHEMA_VERSION ||
        candidate.publicationState !== "approved" ||
        candidate.removed !== false ||
        typeof candidate.mediaPath !== "string"
      ) {
        throw new HttpsError("not-found", "Performance is unavailable.");
      }
      performance = candidate;
    } else {
      performance = (await interactionAuthority({
        uid: params.actorUid,
        performanceId,
        firestore: params.firestore,
        transaction,
        actorAuthority: {
          account: actor,
          deletionJobExists: deletionSnapshot.exists,
        },
      })).performance;
    }
    if (typeof performance.mediaPath !== "string") {
      throw new HttpsError("not-found", "Performance is unavailable.");
    }
    mediaPath = performance.mediaPath;
    transaction.set(sessionRef, {
      schemaVersion: PERFORMANCE_SCHEMA_VERSION,
      userId: params.actorUid,
      performanceId,
      creatorId: performance.creatorId,
      issuedAt: timestamp,
      expiresAt: admin.firestore.Timestamp.fromMillis(
        timestamp.toMillis() + PLAYBACK_SESSION_MS
      ),
    });
  });
  const expiresAtMs = timestamp.toMillis() + PLAYBACK_SESSION_MS;
  const url = await params.media.signReadUrl(mediaPath, expiresAtMs);
  if (!url.startsWith("https://")) throw new Error("Media signer returned an invalid URL.");
  return { url, expiresAtMs };
}

export async function handleSetPerformanceLike(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: Clock;
}): Promise<{ liked: boolean }> {
  const input = parsePerformanceLike(params.data);
  const likeRef = params.firestore
    .collection("performanceLikes")
    .doc(interactionId(params.uid, input.performanceId));
  const timestamp = params.now();
  await params.firestore.runTransaction(async (transaction) => {
    const { performance } = await interactionAuthority({
      uid: params.uid,
      performanceId: input.performanceId,
      firestore: params.firestore,
      transaction,
    });
    const likeSnapshot = await transaction.get(likeRef);
    if (input.liked) {
      if (likeSnapshot.exists) return;
      transaction.create(likeRef, {
        schemaVersion: PERFORMANCE_SCHEMA_VERSION,
        performanceId: input.performanceId,
        userId: params.uid,
        creatorId: performance.creatorId,
        rankingEligible: performance.creatorId !== params.uid,
        rankingWeek: performanceRankingWeek(timestamp),
        createdAt: timestamp,
      });
    } else if (likeSnapshot.exists) {
      transaction.delete(likeRef);
    }
  });
  return { liked: input.liked };
}

export async function handleRecordPerformanceShare(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: Clock;
}): Promise<{ counted: boolean }> {
  const { performanceId } = parsePerformanceId(params.data);
  const shareRef = params.firestore
    .collection("performanceShares")
    .doc(interactionId(params.uid, performanceId));
  const timestamp = params.now();
  let counted = false;
  await params.firestore.runTransaction(async (transaction) => {
    const { performance } = await interactionAuthority({
      uid: params.uid,
      performanceId,
      firestore: params.firestore,
      transaction,
    });
    const shareSnapshot = await transaction.get(shareRef);
    if (shareSnapshot.exists) return;
    transaction.create(shareRef, {
      schemaVersion: PERFORMANCE_SCHEMA_VERSION,
      performanceId,
      userId: params.uid,
      creatorId: performance.creatorId,
      rankingEligible: performance.creatorId !== params.uid,
      rankingWeek: performanceRankingWeek(timestamp),
      createdAt: timestamp,
    });
    counted = true;
  });
  return { counted };
}

export async function handleRecordQualifiedPerformanceView(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: Clock;
}): Promise<{ counted: boolean }> {
  const { performanceId } = parsePerformanceId(params.data);
  const viewRef = params.firestore
    .collection("performanceViews")
    .doc(interactionId(params.uid, performanceId));
  const sessionRef = params.firestore
    .collection("performancePlaybackSessions")
    .doc(interactionId(params.uid, performanceId));
  const timestamp = params.now();
  let counted = false;
  await params.firestore.runTransaction(async (transaction) => {
    const { performance } = await interactionAuthority({
      uid: params.uid,
      performanceId,
      firestore: params.firestore,
      transaction,
    });
    const [viewSnapshot, sessionSnapshot] = await Promise.all([
      transaction.get(viewRef),
      transaction.get(sessionRef),
    ]);
    if (viewSnapshot.exists) {
      if (sessionSnapshot.exists) transaction.delete(sessionRef);
      return;
    }
    const session = sessionSnapshot.data();
    if (
      !session ||
      session.userId !== params.uid ||
      session.performanceId !== performanceId ||
      !(session.issuedAt instanceof admin.firestore.Timestamp) ||
      !(session.expiresAt instanceof admin.firestore.Timestamp) ||
      session.issuedAt.toMillis() > timestamp.toMillis() - QUALIFIED_VIEW_MS ||
      session.expiresAt.toMillis() < timestamp.toMillis()
    ) {
      throw new HttpsError(
        "failed-precondition",
        "This playback has not reached a qualified view."
      );
    }
    transaction.create(viewRef, {
      schemaVersion: PERFORMANCE_SCHEMA_VERSION,
      performanceId,
      userId: params.uid,
      creatorId: performance.creatorId,
      rankingEligible: performance.creatorId !== params.uid,
      rankingWeek: performanceRankingWeek(timestamp),
      createdAt: timestamp,
    });
    transaction.delete(sessionRef);
    counted = true;
  });
  return { counted };
}

export async function handleCreatePerformanceComment(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: Clock;
}): Promise<{ commentId: string }> {
  const input = parsePerformanceComment(params.data);
  const commentId = interactionId(params.uid, input.clientActionId);
  if (input.parentCommentId === commentId) {
    throw new HttpsError("invalid-argument", "A comment cannot reply to itself.");
  }
  const mentionHandles = performanceMentionHandles(input.body);
  const commentRef = params.firestore
    .collection("performanceComments")
    .doc(commentId);
  const creatorRef = params.firestore.collection("creatorProfiles").doc(params.uid);
  const parentRef = input.parentCommentId
    ? params.firestore.collection("performanceComments").doc(input.parentCommentId)
    : undefined;
  const handleRefs = mentionHandles.map((handle) =>
    params.firestore.collection("creatorHandles").doc(handle)
  );
  const timestamp = params.now();
  await params.firestore.runTransaction(async (transaction) => {
    const { performance } = await interactionAuthority({
      uid: params.uid,
      performanceId: input.performanceId,
      firestore: params.firestore,
      transaction,
    });
    const [creatorSnapshot, commentSnapshot, parentSnapshot, ...handleSnapshots] =
      await Promise.all([
      transaction.get(creatorRef),
      transaction.get(commentRef),
        parentRef ? transaction.get(parentRef) : Promise.resolve(undefined),
        ...handleRefs.map((reference) => transaction.get(reference)),
      ]);
    const creator = creatorSnapshot.data();
    requireVisibleCreator(creator);
    if (commentSnapshot.exists) {
      const comment = commentSnapshot.data();
      if (
        comment?.userId === params.uid &&
        comment.performanceId === input.performanceId &&
        comment.body === input.body &&
        (comment.parentCommentId ?? null) === input.parentCommentId
      ) {
        return;
      }
      throw new HttpsError("already-exists", "Comment request already used.");
    }

    const parent = parentSnapshot?.data();
    if (input.parentCommentId) {
      if (
        !parent ||
        parent.performanceId !== input.performanceId ||
        parent.hidden !== false ||
        parent.removed !== false ||
        typeof parent.userId !== "string"
      ) {
        throw new HttpsError("failed-precondition", "Reply target is unavailable.");
      }
    }
    const parentDepth = parent
      ? parent.schemaVersion === 2
        ? parent.depth
        : 0
      : -1;
    if (!Number.isInteger(parentDepth) || parentDepth < -1 || parentDepth >= 50) {
      throw new HttpsError("failed-precondition", "This thread cannot continue.");
    }
    const depth = parentDepth + 1;
    const rootCommentId = parent
      ? parent.schemaVersion === 2 && cleanId(parent.rootCommentId)
        ? parent.rootCommentId as string
        : input.parentCommentId!
      : commentId;

    const recipients = new Map<string, {
      type: "performance_reply" | "performance_mention";
      handle?: string;
    }>();
    if (parent && parent.userId !== params.uid) {
      const parentUserId = cleanId(parent.userId);
      if (parentUserId) recipients.set(parentUserId, { type: "performance_reply" });
    }
    handleSnapshots.forEach((snapshot, index) => {
      const mentionedUid = cleanId(snapshot?.data()?.uid);
      if (mentionedUid && mentionedUid !== params.uid) {
        const existing = recipients.get(mentionedUid);
        if (existing) {
          existing.handle = mentionHandles[index];
        } else {
          recipients.set(mentionedUid, {
            type: "performance_mention",
            handle: mentionHandles[index],
          });
        }
      }
    });

    const recipientIds = [...recipients.keys()];
    const recipientCreatorRefs = recipientIds.map((uid) =>
      params.firestore.collection("creatorProfiles").doc(uid)
    );
    const recipientDeletionRefs = recipientIds.map((uid) =>
      params.firestore.collection("accountDeletionJobs").doc(uid)
    );
    const recipientBlockRefs = recipientIds.flatMap((uid) =>
      blockRefs(params.firestore, params.uid, uid)
    );
    const notificationRefs = recipientIds.map((uid) =>
      params.firestore
        .collection("creatorNotifications")
        .doc(`comment_${commentId}_${uid}`)
    );
    const [
      recipientCreatorSnapshots,
      recipientDeletionSnapshots,
      recipientBlockSnapshots,
      notificationSnapshots,
    ] = await Promise.all([
      Promise.all(recipientCreatorRefs.map((reference) => transaction.get(reference))),
      Promise.all(recipientDeletionRefs.map((reference) => transaction.get(reference))),
      Promise.all(recipientBlockRefs.map((reference) => transaction.get(reference))),
      Promise.all(notificationRefs.map((reference) => transaction.get(reference))),
    ]);

    const resolvedMentionHandles: string[] = [];
    recipientIds.forEach((recipientId, index) => {
      const recipient = recipients.get(recipientId)!;
      const recipientCreator = recipientCreatorSnapshots[index].data();
      const forwardBlock = recipientBlockSnapshots[index * 2];
      const reverseBlock = recipientBlockSnapshots[index * 2 + 1];
      if (
        recipientDeletionSnapshots[index].exists ||
        !recipientCreator ||
        recipientCreator.hidden !== false ||
        recipientCreator.removed !== false ||
        forwardBlock.exists ||
        reverseBlock.exists
      ) {
        return;
      }
      const validMention = recipient.handle !== undefined &&
        recipientCreator.handle === recipient.handle;
      if (recipient.type === "performance_mention" && !validMention) {
        return;
      }
      if (validMention) {
        resolvedMentionHandles.push(recipient.handle!);
      }
      if (!notificationSnapshots[index].exists) {
        transaction.create(notificationRefs[index], {
          schemaVersion: 1,
          ownerId: recipientId,
          actorId: params.uid,
          actorHandle: creator.handle,
          actorDisplayName: creator.displayName,
          type: recipient.type,
          performanceId: input.performanceId,
          commentId,
          read: false,
          createdAt: timestamp,
          readAt: null,
        });
      }
    });
    transaction.create(commentRef, {
      schemaVersion: 2,
      performanceId: input.performanceId,
      performanceCreatorId: performance.creatorId,
      userId: params.uid,
      creatorHandle: creator.handle,
      creatorDisplayName: creator.displayName,
      body: input.body,
      parentCommentId: input.parentCommentId,
      rootCommentId,
      depth,
      mentionedHandles: resolvedMentionHandles,
      hidden: false,
      removed: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    });
  });
  return { commentId };
}

export async function handleDeletePerformanceComment(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: Clock;
}): Promise<{ removed: true }> {
  const { commentId } = parsePerformanceCommentId(params.data);
  const commentRef = params.firestore
    .collection("performanceComments")
    .doc(commentId);
  const timestamp = params.now();
  await params.firestore.runTransaction(async (transaction) => {
    const [profileSnapshot, deletionSnapshot, commentSnapshot] =
      await Promise.all([
        transaction.get(params.firestore.collection("profiles").doc(params.uid)),
        transaction.get(
          params.firestore.collection("accountDeletionJobs").doc(params.uid)
        ),
        transaction.get(commentRef),
      ]);
    requireActiveAccount(profileSnapshot.data(), deletionSnapshot.exists);
    const comment = commentSnapshot.data();
    if (!comment || comment.userId !== params.uid) {
      throw new HttpsError("not-found", "Performance comment not found.");
    }
    if (comment.removed === true) return;
    transaction.update(commentRef, {
      body: "",
      hidden: true,
      removed: true,
      updatedAt: timestamp,
    });
  });
  return { removed: true };
}

async function recomputePerformanceInteractionCounts(params: {
  before: Data | undefined;
  after: Data | undefined;
  firestore: admin.firestore.Firestore;
  now: Clock;
  collection: "performanceLikes" | "performanceViews";
  lifetimeField: "likeCount" | "viewCount";
  weeklyField: "weeklyLikeCount" | "weeklyQualifiedViewCount";
}): Promise<boolean> {
  const performanceId = params.after?.performanceId ?? params.before?.performanceId;
  if (typeof performanceId !== "string") return false;
  const sourceQuery = params.firestore
    .collection(params.collection)
    .where("performanceId", "==", performanceId);
  const performanceRef = params.firestore
    .collection("performances")
    .doc(performanceId);
  return params.firestore.runTransaction(async (transaction) => {
    const [sourceSnapshot, performanceSnapshot] = await Promise.all([
      transaction.get(sourceQuery),
      transaction.get(performanceRef),
    ]);
    const performance = performanceSnapshot.data();
    if (!performance) return false;
    const timestamp = params.now();
    const week = performanceRankingWeek(timestamp);
    const carried = weeklyCounts(performance, week);
    let weeklyCount = 0;
    for (const document of sourceSnapshot.docs) {
      const source = document.data();
      if (source.rankingEligible === true && source.rankingWeek === week) {
        weeklyCount++;
      }
    }
    transaction.update(performanceRef, {
      [params.lifetimeField]: sourceSnapshot.size,
      ...carried,
      [params.weeklyField]: weeklyCount,
      rankingWeek: week,
      updatedAt: timestamp,
    });
    return true;
  });
}

export async function recomputePerformanceShareCounts(params: {
  before: Data | undefined;
  after: Data | undefined;
  firestore: admin.firestore.Firestore;
  now: Clock;
}): Promise<boolean> {
  const performanceId = params.after?.performanceId ?? params.before?.performanceId;
  if (typeof performanceId !== "string") return false;
  const sourceQuery = params.firestore
    .collection("performanceShares")
    .where("performanceId", "==", performanceId);
  const performanceRef = params.firestore
    .collection("performances")
    .doc(performanceId);
  return params.firestore.runTransaction(async (transaction) => {
    const [sourceSnapshot, performanceSnapshot] = await Promise.all([
      transaction.get(sourceQuery),
      transaction.get(performanceRef),
    ]);
    const performance = performanceSnapshot.data();
    if (!performance) return false;
    const timestamp = params.now();
    const week = performanceRankingWeek(timestamp);
    const carried = weeklyCounts(performance, week);
    let weeklyCount = 0;
    for (const document of sourceSnapshot.docs) {
      const source = document.data();
      if (source.rankingEligible === true && source.rankingWeek === week) {
        weeklyCount++;
      }
    }
    transaction.update(performanceRef, {
      shareCount: sourceSnapshot.size,
      uniqueSharerCount: sourceSnapshot.size,
      ...carried,
      weeklyUniqueSharerCount: weeklyCount,
      rankingWeek: week,
      updatedAt: timestamp,
    });
    return true;
  });
}

export function recomputePerformanceLikeCounts(params: {
  before: Data | undefined;
  after: Data | undefined;
  firestore: admin.firestore.Firestore;
  now: Clock;
}): Promise<boolean> {
  return recomputePerformanceInteractionCounts({
    ...params,
    collection: "performanceLikes",
    lifetimeField: "likeCount",
    weeklyField: "weeklyLikeCount",
  });
}

export function recomputePerformanceViewCounts(params: {
  before: Data | undefined;
  after: Data | undefined;
  firestore: admin.firestore.Firestore;
  now: Clock;
}): Promise<boolean> {
  return recomputePerformanceInteractionCounts({
    ...params,
    collection: "performanceViews",
    lifetimeField: "viewCount",
    weeklyField: "weeklyQualifiedViewCount",
  });
}

export async function recomputePerformanceCommentCount(params: {
  before: Data | undefined;
  after: Data | undefined;
  firestore: admin.firestore.Firestore;
  now: Clock;
}): Promise<boolean> {
  const performanceId = params.after?.performanceId ?? params.before?.performanceId;
  if (typeof performanceId !== "string") return false;
  const sourceQuery = params.firestore
    .collection("performanceComments")
    .where("performanceId", "==", performanceId)
    .where("hidden", "==", false)
    .where("removed", "==", false);
  const performanceRef = params.firestore
    .collection("performances")
    .doc(performanceId);
  return params.firestore.runTransaction(async (transaction) => {
    const [sourceSnapshot, performanceSnapshot] = await Promise.all([
      transaction.get(sourceQuery),
      transaction.get(performanceRef),
    ]);
    if (!performanceSnapshot.exists) return false;
    transaction.update(performanceRef, {
      commentCount: sourceSnapshot.size,
      updatedAt: params.now(),
    });
    return true;
  });
}

export async function handleResolvePerformanceDraftPlayback(params: {
  actorUid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  media: PerformanceMediaGateway;
  now: Clock;
}): Promise<{ url: string; expiresAtMs: number }> {
  const { draftId } = parseDraftId(params.data);
  const [draftSnapshot, actorSnapshot, deletionSnapshot] = await Promise.all([
    params.firestore.collection("performanceDrafts").doc(draftId).get(),
    params.firestore.collection("profiles").doc(params.actorUid).get(),
    params.firestore.collection("accountDeletionJobs").doc(params.actorUid).get(),
  ]);
  const draft = draftSnapshot.data();
  const actor = actorSnapshot.data();
  if (!draft) throw new HttpsError("not-found", "Performance draft not found.");
  requireActiveAccount(actor, deletionSnapshot.exists);
  const ownsDraft = draft.ownerId === params.actorUid;
  const operator = actor?.role === "operator";
  if (!ownsDraft && !operator) {
    throw new HttpsError("permission-denied", "Performance draft is private.");
  }
  if (
    draft.state !== "awaiting_upload" &&
    draft.state !== "pending_review" &&
    draft.state !== "approved"
  ) {
    throw new HttpsError("not-found", "Performance media is unavailable.");
  }
  const path = draft.state === "approved" ? draft.mediaPath : draft.uploadPath;
  if (typeof path !== "string") {
    throw new HttpsError("not-found", "Performance media is unavailable.");
  }
  const expiresAtMs = params.now().toMillis() + 10 * 60 * 1000;
  const url = await params.media.signReadUrl(path, expiresAtMs);
  if (!url.startsWith("https://")) throw new Error("Media signer returned an invalid URL.");
  return { url, expiresAtMs };
}

export async function cleanupDeletedPerformanceDraft(
  data: Data | undefined,
  media: PerformanceMediaGateway
): Promise<boolean> {
  if (!data || typeof data.uploadPath !== "string") return false;
  const ownerId = typeof data.ownerId === "string" ? data.ownerId : "";
  const match = data.uploadPath.match(
    /^performance-staging\/([A-Za-z0-9_-]+)\/([A-Za-z0-9_-]+)\/source$/
  );
  if (!match || match[1] !== ownerId) return false;
  await media.remove(data.uploadPath);
  return true;
}

export async function cleanupRemovedPerformanceMedia(
  data: Data | undefined,
  media: PerformanceMediaGateway,
): Promise<boolean> {
  if (!data || typeof data.performanceId !== "string") return false;
  const performanceId = cleanId(data.performanceId);
  if (!performanceId || performanceId !== data.performanceId) return false;
  const expectedPath = `performance-media/${performanceId}/source`;
  if (data.mediaPath !== expectedPath) return false;
  await media.remove(expectedPath);
  return true;
}

export function firebasePerformanceMediaGateway(
  bucket: ReturnType<admin.storage.Storage["bucket"]>
): PerformanceMediaGateway {
  return {
    inspect: async (path) => {
      try {
        const [metadata] = await bucket.file(path).getMetadata();
        const size = Number(metadata.size);
        if (!Number.isInteger(size)) throw new Error("Invalid object size.");
        const customMetadata: Record<string, string> = {};
        for (const [key, value] of Object.entries(metadata.metadata ?? {})) {
          if (typeof value === "string") customMetadata[key] = value;
        }
        return {
          size,
          contentType: metadata.contentType ?? "",
          generation: metadata.generation == null ? "" : String(metadata.generation),
          customMetadata,
        };
      } catch (error) {
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("failed-precondition", "Uploaded media is unavailable.");
      }
    },
    copy: async (sourcePath, destinationPath) => {
      await bucket.file(sourcePath).copy(bucket.file(destinationPath));
    },
    remove: async (path) => {
      await bucket.file(path).delete({ ignoreNotFound: true });
    },
    signReadUrl: async (path, expiresAtMs) => {
      const [url] = await bucket.file(path).getSignedUrl({
        action: "read",
        expires: expiresAtMs,
        version: "v4",
      });
      return url;
    },
  };
}
