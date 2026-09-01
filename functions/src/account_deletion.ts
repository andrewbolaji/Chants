import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

export const ACCOUNT_DELETION_SCHEMA_VERSION = 2;
export const ACCOUNT_DELETION_PAGE_SIZE = 200;

export const ACCOUNT_DELETION_PHASES = [
  "disable-auth",
  "delete-votes",
  "delete-chant-reports",
  "delete-chant-update-suggestions",
  "delete-feedback",
  "delete-safety-rate",
  "anonymize-chants",
  "anonymize-comments",
  "delete-comment-likes",
  "delete-comment-reports",
  "delete-user-reports-by",
  "delete-user-reports-against",
  "delete-blocks-by",
  "delete-blocks-against",
  "delete-follows-by",
  "delete-follows-against",
  "delete-notifications-owned",
  "delete-notifications-acted",
  "delete-performance-likes",
  "delete-performance-views",
  "delete-performance-shares",
  "delete-performance-playback-sessions",
  "delete-performance-reports",
  "delete-performance-comment-reports",
  "anonymize-performance-comments",
  "delete-performance-upload-limits",
  "anonymize-performances",
  "delete-performance-drafts",
  "anonymize-audit-by",
  "write-audit",
  "delete-auth",
  "finalize",
] as const;

export type AccountDeletionPhase = typeof ACCOUNT_DELETION_PHASES[number];

export type AccountDeletionAuth = {
  updateUser: (
    uid: string,
    properties: { disabled: boolean }
  ) => Promise<unknown>;
  deleteUser: (uid: string) => Promise<void>;
};

type AccountDeletionJob = {
  schemaVersion: 1 | 2;
  phase: AccountDeletionPhase;
  requestedAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
};

type RequestAccountDeletionParams = {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
};

export type VerifiedAccountDeletionDispatch = {
  actorUid: string;
  targetUid: string;
  caseReference: string;
  verificationMethod:
    | "current-email-challenge"
    | "current-phone-challenge"
    | "provider-reauth";
  verificationCompletedAt: admin.firestore.Timestamp;
  targetAuthExists: boolean;
};

type ProcessAccountDeletionParams = {
  uid: string;
  firestore: admin.firestore.Firestore;
  auth: AccountDeletionAuth;
  now: () => admin.firestore.Timestamp;
};

export type AccountDeletionStepResult = {
  phase: AccountDeletionPhase;
  processed: number;
  advanced: boolean;
  complete: boolean;
};

type PagePhase = {
  collection: string;
  field: string;
  update?:
    | admin.firestore.UpdateData<admin.firestore.DocumentData>
    | ((
        data: admin.firestore.DocumentData,
        uid: string,
        timestamp: admin.firestore.Timestamp
      ) => admin.firestore.UpdateData<admin.firestore.DocumentData>);
};

const DELETED_COMMENT_BODY = "Comment deleted";

const OPERATOR_AUDIT_ACTIONS = new Set<string>([
  "ban",
  "unban",
  "promote",
  "demote",
  "remove-evidence",
  "hide",
  "unhide",
  "remove",
  "merge_chants",
  "accept-chant-evidence",
  "resolve-chant-update",
  "decline-chant-update",
  "request-account-deletion",
]);

export function auditRedactionForDeletedActor(
  data: admin.firestore.DocumentData,
  uid: string
): admin.firestore.UpdateData<admin.firestore.DocumentData> {
  const action = data.action;
  if (typeof action === "string" && OPERATOR_AUDIT_ACTIONS.has(action)) {
    return { actorId: "deleted-operator" };
  }
  if (action === "report" || action === "report-user") {
    return {
      actorId: "deleted-user",
      detail: "Report details removed during account deletion.",
    };
  }
  if (action === "accept-policy") {
    return {
      actorId: "deleted-user",
      ...(data.targetId === uid ? { targetId: "deleted-user" } : {}),
    };
  }
  return {
    actorId: "deleted-user",
    detail: "Details removed during account deletion.",
  };
}

const PAGE_PHASES: Partial<Record<AccountDeletionPhase, PagePhase>> = {
  "delete-votes": { collection: "votes", field: "userId" },
  "delete-chant-reports": { collection: "reports", field: "reportedBy" },
  "delete-chant-update-suggestions": {
    collection: "chantUpdateSuggestions",
    field: "submittedBy",
  },
  "delete-feedback": { collection: "feedback", field: "userId" },
  "anonymize-chants": {
    collection: "chants",
    field: "createdBy",
    update: (_data, _uid, timestamp) => ({
      createdBy: "deleted-user",
      title: "",
      lyrics: "",
      tuneName: "",
      contextNotes: null,
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: "none",
      evidence: null,
      variations: [],
      hidden: true,
      removed: true,
      updatedAt: timestamp,
    }),
  },
  "anonymize-comments": {
    collection: "comments",
    field: "userId",
    update: {
      userId: "deleted-user",
      displayName: "Deleted user",
      body: DELETED_COMMENT_BODY,
    },
  },
  "delete-comment-likes": { collection: "commentLikes", field: "userId" },
  "delete-comment-reports": {
    collection: "commentReports",
    field: "reportedBy",
  },
  "delete-user-reports-by": {
    collection: "userReports",
    field: "reportedBy",
  },
  "delete-user-reports-against": {
    collection: "userReports",
    field: "reportedUserId",
  },
  "delete-blocks-by": { collection: "blocks", field: "blockerId" },
  "delete-blocks-against": {
    collection: "blocks",
    field: "blockedUserId",
  },
  "delete-follows-by": {
    collection: "creatorFollows",
    field: "followerId",
  },
  "delete-follows-against": {
    collection: "creatorFollows",
    field: "followedId",
  },
  "delete-notifications-owned": {
    collection: "creatorNotifications",
    field: "ownerId",
  },
  "delete-notifications-acted": {
    collection: "creatorNotifications",
    field: "actorId",
  },
  "delete-performance-likes": {
    collection: "performanceLikes",
    field: "userId",
  },
  "delete-performance-views": {
    collection: "performanceViews",
    field: "userId",
  },
  "delete-performance-shares": {
    collection: "performanceShares",
    field: "userId",
  },
  "delete-performance-playback-sessions": {
    collection: "performancePlaybackSessions",
    field: "userId",
  },
  "delete-performance-reports": {
    collection: "performanceReports",
    field: "reportedBy",
  },
  "delete-performance-comment-reports": {
    collection: "performanceCommentReports",
    field: "reportedBy",
  },
  "anonymize-performance-comments": {
    collection: "performanceComments",
    field: "userId",
    update: (_data, _uid, timestamp) => ({
      userId: "deleted-user",
      creatorHandle: "deleted",
      creatorDisplayName: "Deleted creator",
      body: DELETED_COMMENT_BODY,
      mentionedHandles: [],
      updatedAt: timestamp,
    }),
  },
  "delete-performance-upload-limits": {
    collection: "performanceUploadLimits",
    field: "ownerId",
  },
  "anonymize-audit-by": {
    collection: "auditLog",
    field: "actorId",
    update: auditRedactionForDeletedActor,
  },
};

function requireEmptyPayload(data: unknown): void {
  if (
    data === null ||
    typeof data !== "object" ||
    Array.isArray(data) ||
    Object.keys(data as Record<string, unknown>).length !== 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Account deletion does not accept request fields."
    );
  }
}

function isTimestamp(value: unknown): value is admin.firestore.Timestamp {
  return typeof (value as { toMillis?: unknown } | undefined)?.toMillis === "function";
}

function parseJob(data: admin.firestore.DocumentData): AccountDeletionJob {
  const keys = Object.keys(data).sort();
  const expectedKeys = ["phase", "requestedAt", "schemaVersion", "updatedAt"];
  if (
    keys.length !== expectedKeys.length ||
    keys.some((key, index) => key !== expectedKeys[index]) ||
    (data.schemaVersion !== 1 &&
      data.schemaVersion !== ACCOUNT_DELETION_SCHEMA_VERSION) ||
    !ACCOUNT_DELETION_PHASES.includes(data.phase as AccountDeletionPhase) ||
    !isTimestamp(data.requestedAt) ||
    !isTimestamp(data.updatedAt)
  ) {
    throw new Error("Malformed account deletion job.");
  }
  return data as AccountDeletionJob;
}

function nextPhase(phase: AccountDeletionPhase): AccountDeletionPhase | null {
  const index = ACCOUNT_DELETION_PHASES.indexOf(phase);
  return ACCOUNT_DELETION_PHASES[index + 1] ?? null;
}

function isAuthUserMissing(error: unknown): boolean {
  return (error as { code?: unknown } | undefined)?.code === "auth/user-not-found";
}

function validUid(value: string): boolean {
  return /^[A-Za-z0-9_-]{1,128}$/.test(value);
}

function validateVerifiedDispatch(
  dispatch: VerifiedAccountDeletionDispatch,
  timestamp: admin.firestore.Timestamp
): void {
  if (
    !validUid(dispatch.actorUid) ||
    !validUid(dispatch.targetUid) ||
    dispatch.actorUid === dispatch.targetUid ||
    !/^[A-Z0-9-]{8,64}$/.test(dispatch.caseReference) ||
    ![
      "current-email-challenge",
      "current-phone-challenge",
      "provider-reauth",
    ].includes(dispatch.verificationMethod) ||
    !isTimestamp(dispatch.verificationCompletedAt) ||
    typeof dispatch.targetAuthExists !== "boolean"
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid verified account-deletion dispatch."
    );
  }
  const ageMs = timestamp.toMillis() - dispatch.verificationCompletedAt.toMillis();
  if (ageMs < 0 || ageMs > 24 * 60 * 60 * 1000) {
    throw new HttpsError(
      "failed-precondition",
      "Account-control verification is no longer current."
    );
  }
}

async function requestAccountDeletionForUid(params: {
  uid: string;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
  dispatch?: VerifiedAccountDeletionDispatch;
}): Promise<{ accepted: true; success: true }> {
  const timestamp = params.now();
  if (params.dispatch) validateVerifiedDispatch(params.dispatch, timestamp);
  const jobRef = params.firestore.collection("accountDeletionJobs").doc(params.uid);
  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const actorRef = params.dispatch
    ? params.firestore.collection("profiles").doc(params.dispatch.actorUid)
    : undefined;
  const actorDeletionRef = params.dispatch
    ? params.firestore
      .collection("accountDeletionJobs")
      .doc(params.dispatch.actorUid)
    : undefined;
  const auditRef = params.dispatch
    ? params.firestore
      .collection("auditLog")
      .doc(`external-delete-${params.dispatch.caseReference}`)
    : undefined;

  await params.firestore.runTransaction(async (transaction) => {
    const [jobSnap, profileSnap, actorSnap, actorDeletionSnap, auditSnap] =
      await Promise.all([
        transaction.get(jobRef),
        transaction.get(profileRef),
        actorRef ? transaction.get(actorRef) : Promise.resolve(undefined),
        actorDeletionRef
          ? transaction.get(actorDeletionRef)
          : Promise.resolve(undefined),
        auditRef ? transaction.get(auditRef) : Promise.resolve(undefined),
      ]);

    if (params.dispatch) {
      if (!params.dispatch.targetAuthExists && !jobSnap.exists) {
        throw new HttpsError(
          "not-found",
          "Deletion target has no Auth user or resumable job."
        );
      }
      const actor = actorSnap?.data();
      if (
        !actor ||
        actor.role !== "operator" ||
        actor.banned !== false ||
        actor.deletionPending === true ||
        actorDeletionSnap?.exists
      ) {
        throw new HttpsError(
          "permission-denied",
          "Active operator access required."
        );
      }
      const detail =
        `Verified external deletion request dispatched. Case ${params.dispatch.caseReference}; ` +
        `method ${params.dispatch.verificationMethod}.`;
      if (auditSnap?.exists) {
        const audit = auditSnap.data();
        if (
          audit?.actorId !== params.dispatch.actorUid ||
          audit.action !== "request-account-deletion" ||
          audit.targetType !== "user" ||
          audit.targetId !== params.uid ||
          audit.detail !== detail
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Deletion case reference is already in use."
          );
        }
      } else {
        transaction.create(auditRef!, {
          actorId: params.dispatch.actorUid,
          action: "request-account-deletion",
          targetType: "user",
          targetId: params.uid,
          detail,
          createdAt: timestamp,
        });
      }
    }

    if (
      profileSnap.exists &&
      (profileSnap.data()?.deletionPending !== true ||
        profileSnap.data()?.activePerformanceUpload != null)
    ) {
      transaction.update(profileRef, {
        deletionPending: true,
        activePerformanceUpload: null,
      });
    }

    if (jobSnap.exists) return;
    transaction.create(jobRef, {
      schemaVersion: ACCOUNT_DELETION_SCHEMA_VERSION,
      phase: ACCOUNT_DELETION_PHASES[0],
      requestedAt: timestamp,
      updatedAt: timestamp,
    });
  });

  return { accepted: true, success: true };
}

export async function requestAccountDeletion({
  uid,
  data,
  firestore,
  now,
}: RequestAccountDeletionParams): Promise<{ accepted: true; success: true }> {
  requireEmptyPayload(data);
  return requestAccountDeletionForUid({ uid, firestore, now });
}

export async function requestVerifiedAccountDeletion(params: {
  dispatch: VerifiedAccountDeletionDispatch;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
}): Promise<{ accepted: true; success: true }> {
  if (params.dispatch.targetUid.length === 0) {
    throw new HttpsError("invalid-argument", "Deletion target is required.");
  }
  return requestAccountDeletionForUid({
    uid: params.dispatch.targetUid,
    firestore: params.firestore,
    now: params.now,
    dispatch: params.dispatch,
  });
}

async function advancePhase(
  firestore: admin.firestore.Firestore,
  uid: string,
  expected: AccountDeletionPhase,
  now: () => admin.firestore.Timestamp
): Promise<boolean> {
  const following = nextPhase(expected);
  if (!following) return false;
  const jobRef = firestore.collection("accountDeletionJobs").doc(uid);
  return firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(jobRef);
    if (!snapshot.exists) return false;
    const current = parseJob(snapshot.data()!);
    if (current.phase !== expected) return false;
    transaction.update(jobRef, { phase: following, updatedAt: now() });
    return true;
  });
}

async function migrateLegacyJob(
  params: ProcessAccountDeletionParams
): Promise<boolean> {
  const jobRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.uid);
  return params.firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(jobRef);
    if (!snapshot.exists) return false;
    const current = parseJob(snapshot.data()!);
    if (current.schemaVersion !== 1) return false;
    const replayStart: AccountDeletionPhase = "anonymize-chants";
    const currentIndex = ACCOUNT_DELETION_PHASES.indexOf(current.phase);
    const replayIndex = ACCOUNT_DELETION_PHASES.indexOf(replayStart);
    transaction.update(jobRef, {
      schemaVersion: ACCOUNT_DELETION_SCHEMA_VERSION,
      phase: currentIndex >= replayIndex ? replayStart : current.phase,
      updatedAt: params.now(),
    });
    return true;
  });
}

async function processPage(
  params: ProcessAccountDeletionParams,
  phase: AccountDeletionPhase,
  page: PagePhase
): Promise<AccountDeletionStepResult> {
  const snapshot = await params.firestore
    .collection(page.collection)
    .where(page.field, "==", params.uid)
    .limit(ACCOUNT_DELETION_PAGE_SIZE)
    .get();

  if (snapshot.empty) {
    const advanced = await advancePhase(
      params.firestore,
      params.uid,
      phase,
      params.now
    );
    return { phase, processed: 0, advanced, complete: false };
  }

  const batch = params.firestore.batch();
  const timestamp = params.now();
  for (const document of snapshot.docs) {
    if (page.update) {
      const update = typeof page.update === "function"
        ? page.update(document.data(), params.uid, timestamp)
        : page.update;
      batch.update(document.ref, update);
    } else batch.delete(document.ref);
  }
  batch.update(params.firestore.collection("accountDeletionJobs").doc(params.uid), {
    updatedAt: timestamp,
  });
  await batch.commit();
  return {
    phase,
    processed: snapshot.size,
    advanced: false,
    complete: false,
  };
}

async function processPerformancePage(
  params: ProcessAccountDeletionParams
): Promise<AccountDeletionStepResult> {
  const phase: AccountDeletionPhase = "anonymize-performances";
  const snapshot = await params.firestore
    .collection("performances")
    .where("creatorId", "==", params.uid)
    .limit(ACCOUNT_DELETION_PAGE_SIZE)
    .get();

  if (snapshot.empty) {
    const advanced = await advancePhase(
      params.firestore,
      params.uid,
      phase,
      params.now
    );
    return { phase, processed: 0, advanced, complete: false };
  }

  const cleanupRows = snapshot.docs.map((document) => {
    if (!/^[A-Za-z0-9_-]{1,500}$/.test(document.id)) {
      throw new Error("Invalid owned performance identity.");
    }
    const expectedPath = `performance-media/${document.id}/source`;
    const ref = params.firestore
      .collection("performanceMediaDeletionJobs")
      .doc(document.id);
    return { document, expectedPath, ref };
  });

  const jobRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.uid);
  const processed = await params.firestore.runTransaction(async (transaction) => {
    const [jobSnapshot, ...rows] = await Promise.all([
      transaction.get(jobRef),
      ...cleanupRows.map(async (row) => ({
        ...row,
        current: await transaction.get(row.document.ref),
        existing: await transaction.get(row.ref),
      })),
    ]);
    if (
      !jobSnapshot.exists ||
      parseJob(jobSnapshot.data()!).phase !== phase
    ) {
      return 0;
    }
    for (const row of rows) {
      if (!row.current.exists || row.current.data()?.creatorId !== params.uid) {
        throw new Error("Owned performance changed during deletion.");
      }
      if (row.current.data()?.mediaPath !== row.expectedPath) {
        throw new Error("Invalid owned performance media path.");
      }
      if (
        row.existing.exists &&
        (row.existing.data()?.performanceId !== row.document.id ||
          row.existing.data()?.mediaPath !== row.expectedPath)
      ) {
        throw new Error("Conflicting performance media cleanup identity.");
      }
    }
    const timestamp = params.now();
    for (const row of rows) {
      if (row.existing.exists) {
        transaction.update(row.ref, {
          ownerId: params.uid,
          updatedAt: timestamp,
        });
      } else {
        transaction.set(row.ref, {
          performanceId: row.document.id,
          mediaPath: row.expectedPath,
          ownerId: params.uid,
          requestedAt: timestamp,
          updatedAt: timestamp,
        });
      }
      transaction.update(row.document.ref, {
        creatorId: "deleted-user",
        creatorHandle: "deleted",
        creatorDisplayName: "Deleted creator",
        caption: "",
        hidden: true,
        removed: true,
        sourceCreatorVisible: false,
        updatedAt: timestamp,
      });
    }
    transaction.update(jobRef, { updatedAt: timestamp });
    return rows.length;
  });
  return {
    phase,
    processed,
    advanced: false,
    complete: false,
  };
}

async function processPerformanceDraftPage(
  params: ProcessAccountDeletionParams
): Promise<AccountDeletionStepResult> {
  const phase: AccountDeletionPhase = "delete-performance-drafts";
  const snapshot = await params.firestore
    .collection("performanceDrafts")
    .where("ownerId", "==", params.uid)
    .limit(ACCOUNT_DELETION_PAGE_SIZE)
    .get();

  if (snapshot.empty) {
    const advanced = await advancePhase(
      params.firestore,
      params.uid,
      phase,
      params.now
    );
    return { phase, processed: 0, advanced, complete: false };
  }

  const cleanupRows = snapshot.docs.map((document) => {
    if (!/^[A-Za-z0-9_-]{1,200}$/.test(document.id)) {
      throw new Error("Invalid owned performance draft identity.");
    }
    const expectedPath =
      `performance-staging/${params.uid}/${document.id}/source`;
    const ref = params.firestore
      .collection("deferredDraftCleanupJobs")
      .doc(document.id);
    return { document, expectedPath, ref };
  });

  const jobRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.uid);
  const processed = await params.firestore.runTransaction(async (transaction) => {
    const [jobSnapshot, ...rows] = await Promise.all([
      transaction.get(jobRef),
      ...cleanupRows.map(async (row) => ({
        ...row,
        current: await transaction.get(row.document.ref),
        existing: await transaction.get(row.ref),
      })),
    ]);
    if (
      !jobSnapshot.exists ||
      parseJob(jobSnapshot.data()!).phase !== phase
    ) {
      return 0;
    }
    for (const row of rows) {
      if (!row.current.exists || row.current.data()?.ownerId !== params.uid) {
        throw new Error("Owned performance draft changed during deletion.");
      }
      if (row.current.data()?.uploadPath !== row.expectedPath) {
        throw new Error("Invalid owned performance draft media path.");
      }
      if (
        row.existing.exists &&
        (row.existing.data()?.draftId !== row.document.id ||
          row.existing.data()?.uploadPath !== row.expectedPath)
      ) {
        throw new Error("Conflicting performance draft cleanup identity.");
      }
    }
    const timestamp = params.now();
    for (const row of rows) {
      if (row.existing.exists) {
        transaction.update(row.ref, {
          accountDeletionOwnerId: params.uid,
          updatedAt: timestamp,
        });
      } else {
        transaction.set(row.ref, {
          schemaVersion: 1,
          draftId: row.document.id,
          uploadPath: row.expectedPath,
          accountDeletionOwnerId: params.uid,
          state: "pending",
          createdAt: timestamp,
          updatedAt: timestamp,
        });
      }
      transaction.delete(row.document.ref);
    }
    transaction.update(jobRef, { updatedAt: timestamp });
    return rows.length;
  });
  return {
    phase,
    processed,
    advanced: false,
    complete: false,
  };
}

async function processDirectDelete(
  params: ProcessAccountDeletionParams,
  phase: AccountDeletionPhase,
  collection: string
): Promise<AccountDeletionStepResult> {
  const following = nextPhase(phase);
  if (!following) throw new Error(`No phase follows ${phase}.`);
  const jobRef = params.firestore.collection("accountDeletionJobs").doc(params.uid);
  const targetRef = params.firestore.collection(collection).doc(params.uid);

  const advanced = await params.firestore.runTransaction(async (transaction) => {
    const jobSnap = await transaction.get(jobRef);
    if (!jobSnap.exists) return false;
    const current = parseJob(jobSnap.data()!);
    if (current.phase !== phase) return false;
    transaction.delete(targetRef);
    transaction.update(jobRef, { phase: following, updatedAt: params.now() });
    return true;
  });
  return { phase, processed: advanced ? 1 : 0, advanced, complete: false };
}

async function processAuthOperation(
  params: ProcessAccountDeletionParams,
  phase: "disable-auth" | "delete-auth"
): Promise<AccountDeletionStepResult> {
  try {
    if (phase === "disable-auth") {
      await params.auth.updateUser(params.uid, { disabled: true });
    } else {
      await params.auth.deleteUser(params.uid);
    }
  } catch (error) {
    if (!isAuthUserMissing(error)) throw error;
  }

  const advanced = await advancePhase(
    params.firestore,
    params.uid,
    phase,
    params.now
  );
  return { phase, processed: 1, advanced, complete: false };
}

async function processAudit(
  params: ProcessAccountDeletionParams
): Promise<AccountDeletionStepResult> {
  const phase: AccountDeletionPhase = "write-audit";
  const following = nextPhase(phase)!;
  const jobRef = params.firestore.collection("accountDeletionJobs").doc(params.uid);
  const auditRef = params.firestore.collection("auditLog").doc();

  const advanced = await params.firestore.runTransaction(async (transaction) => {
    const jobSnap = await transaction.get(jobRef);
    if (!jobSnap.exists) return false;
    const current = parseJob(jobSnap.data()!);
    if (current.phase !== phase) return false;
    const timestamp = params.now();
    transaction.set(auditRef, {
      actorId: "system",
      action: "delete-account",
      targetType: "user",
      targetId: "deleted-user",
      detail: "Anonymous account cleanup completed; Auth and profile finalization queued.",
      createdAt: timestamp,
    });
    transaction.update(jobRef, { phase: following, updatedAt: timestamp });
    return true;
  });
  return { phase, processed: advanced ? 1 : 0, advanced, complete: false };
}

async function finalizeAccountDeletion(
  params: ProcessAccountDeletionParams
): Promise<AccountDeletionStepResult> {
  const phase: AccountDeletionPhase = "finalize";
  const jobRef = params.firestore.collection("accountDeletionJobs").doc(params.uid);
  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const creatorRef = params.firestore.collection("creatorProfiles").doc(params.uid);

  const complete = await params.firestore.runTransaction(async (transaction) => {
    const [jobSnap, creatorSnap] = await Promise.all([
      transaction.get(jobRef),
      transaction.get(creatorRef),
    ]);
    if (!jobSnap.exists) return true;
    const current = parseJob(jobSnap.data()!);
    if (current.phase !== phase) return false;
    const handle = creatorSnap.exists && typeof creatorSnap.data()?.handle === "string"
      ? (creatorSnap.data()!.handle as string).toLowerCase()
      : undefined;
    const handleRef = handle
      ? params.firestore.collection("creatorHandles").doc(handle)
      : undefined;
    const handleSnap = handleRef ? await transaction.get(handleRef) : undefined;
    if (handleRef && handleSnap?.data()?.uid === params.uid) {
      transaction.delete(handleRef);
    }
    if (creatorSnap.exists) transaction.delete(creatorRef);
    transaction.delete(profileRef);
    transaction.delete(jobRef);
    return true;
  });
  return { phase, processed: complete ? 4 : 0, advanced: false, complete };
}

export async function processAccountDeletionStep(
  params: ProcessAccountDeletionParams
): Promise<AccountDeletionStepResult | null> {
  const jobSnapshot = await params.firestore
    .collection("accountDeletionJobs")
    .doc(params.uid)
    .get();
  if (!jobSnapshot.exists) return null;
  const job = parseJob(jobSnapshot.data()!);
  if (job.schemaVersion === 1) {
    await migrateLegacyJob(params);
    return processAccountDeletionStep(params);
  }
  const page = PAGE_PHASES[job.phase];
  if (page) return processPage(params, job.phase, page);

  switch (job.phase) {
    case "disable-auth":
    case "delete-auth":
      return processAuthOperation(params, job.phase);
    case "delete-safety-rate":
      return processDirectDelete(params, job.phase, "safetyRateLimits");
    case "anonymize-performances":
      return processPerformancePage(params);
    case "delete-performance-drafts":
      return processPerformanceDraftPage(params);
    case "write-audit":
      return processAudit(params);
    case "finalize":
      return finalizeAccountDeletion(params);
    default:
      throw new Error(`Unsupported account deletion phase: ${job.phase}`);
  }
}
