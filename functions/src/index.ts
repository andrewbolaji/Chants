import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions/v2/options";
import { CURRENT_POLICY_VERSION } from "./policy";
import { V1_RUNTIME, SERIAL_WORKER_RUNTIME, MEDIA_VALIDATION_RUNTIME, MONITOR_RUNTIME } from "./runtime_options";
import { pendingReportCount, reportAutoHide } from "./report_projection";
import { operationEnabled, requireOperationEnabled } from "./operational_gate";
import { handleDeletedDraftCleanup } from "./deferred_draft_cleanup";
import {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import { writeAuditEntry, writePrivacySafeReportAuditEntry } from "./audit";
import {
  ChantTrustAction,
  ChantTrustPlan,
  planChantTrustAction,
} from "./chant_trust";
import {
  handleSubmitFeedback,
  handleSubmitReport,
  requireVerifiedUid,
} from "./safety_submission";
import { handleCompleteOnboarding } from "./onboarding";
import {
  processAccountDeletionStep,
  requestAccountDeletion,
} from "./account_deletion";
import { handleUpdateCreatorProfile } from "./creator_profile";
import {
  handleSetCreatorFollow,
  recomputeCreatorFollowCounts,
} from "./creator_follow";
import { handleMarkCreatorNotificationRead } from "./creator_notification";
import {
  handleModerateChantUpdateSuggestion,
  handleSubmitChantUpdateSuggestion,
} from "./living_songbook";
import { handlePublishedPerformanceModeration } from "./published_performance_moderation";
import {
  firebasePerformanceMediaGateway,
  handleCancelPerformanceDraft,
  handleCreatePerformanceDraft,
  handleModeratePerformance,
  handleResolvePerformancePlayback,
  handleResolvePerformanceDraftPlayback,
  handleSetPerformanceLike,
  handleRecordPerformanceShare,
  handleRecordQualifiedPerformanceView,
  handleCreatePerformanceComment,
  handleDeletePerformanceComment,
  handleSubmitPerformanceDraft,
  cleanupRemovedPerformanceMedia,
  recomputePerformanceLikeCounts,
  recomputePerformanceViewCounts,
  recomputePerformanceCommentCount,
  recomputePerformanceShareCounts,
} from "./performance";
import {
  chantSourceChanged,
  handlePerformanceVisibilityWritten,
  reconcileChantPerformanceSource,
  reconcileCreatorPerformanceSource,
} from "./performance_source";
import {
  handleResolvePublicShareDestination,
  handleResolvePublicPerformanceMedia,
  performanceIdFromPublicMediaPath,
  renderPublicPage,
  resolvePublicPage,
} from "./public_share";
import {
  cleanupAbandonedPerformanceDrafts as cleanupAbandonedPerformanceDraftsBatch,
  abandonedDraftCleanupDisposition,
  firebaseOperationalStore,
  monitorOperationalBacklogs,
  operationalBacklogLog,
} from "./operations";

setGlobalOptions(V1_RUNTIME);
admin.initializeApp();
const db = admin.firestore();

function performanceMediaGateway() {
  // Resolve the configured bucket only when a media callable runs. The test
  // harness imports this module without production Firebase options.
  return firebasePerformanceMediaGateway(admin.storage().bucket());
}

const AUTO_HIDE_THRESHOLD = 3;

export const cleanupAbandonedPerformanceDraftsJob = onSchedule(
  {
    ...SERIAL_WORKER_RUNTIME,
    schedule: "every day 03:00",
    timeZone: "UTC",
    region: "europe-west2",
    retryCount: 3,
  },
  async () => {
    if (!await operationEnabled("cleanupAbandonedPerformanceDraftsJob", db)) return;
    const result = await cleanupAbandonedPerformanceDraftsBatch({
      store: firebaseOperationalStore(db),
      media: performanceMediaGateway(),
      now: () => admin.firestore.Timestamp.now(),
    });
    const disposition = abandonedDraftCleanupDisposition(result);
    if (disposition.shouldWarn) {
      logger.warn("Abandoned performance cleanup found invalid rows.", {
        operationalSignal: "abandoned-performance-cleanup-invalid",
        scanned: result.scanned,
        claimed: result.claimed,
        deleted: result.deleted,
        invalid: result.invalid,
      });
    }
    if (disposition.shouldRetry) {
      logger.error("Abandoned performance cleanup did not finish.", {
        operationalSignal: "abandoned-performance-cleanup-failed",
        scanned: result.scanned,
        claimed: result.claimed,
        deleted: result.deleted,
        failures: result.failures,
      });
      throw new Error("Abandoned performance cleanup did not finish.");
    }
    if (result.deleted > 0) {
      logger.info("Abandoned performance cleanup completed.", {
        operationalSignal: "abandoned-performance-cleanup",
        scanned: result.scanned,
        claimed: result.claimed,
        deleted: result.deleted,
        invalid: result.invalid,
      });
    }
  },
);

export const monitorOperationalBacklogsJob = onSchedule(
  {
    ...MONITOR_RUNTIME,
    schedule: "every 15 minutes",
    timeZone: "UTC",
    region: "europe-west2",
  },
  async () => {
    const summary = await monitorOperationalBacklogs({
      store: firebaseOperationalStore(db),
      now: () => admin.firestore.Timestamp.now(),
    });
    if (summary.hasStaleJobs) {
      logger.error(
        "Stale deletion jobs detected.",
        operationalBacklogLog(summary),
      );
    }
  },
);

// Must match kCurrentPolicyVersion in lib/app/policy.dart and the version
// check in firestore.rules. Bump all three together, only for a substantive
// policy text change (a bump re-gates every existing user on next open).

export const submitReport = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("submitReport", db,
      request.data?.targetType === "performance" || request.data?.targetType === "performanceComment");
    return handleSubmitReport({
      uid,
      data: request.data,
      firestore: db,
      clock: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const submitFeedback = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("submitFeedback", db);
    return handleSubmitFeedback({
      uid,
      data: request.data,
      firestore: db,
      clock: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const submitChantUpdateSuggestion = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("submitChantUpdateSuggestion", db);
    return handleSubmitChantUpdateSuggestion({
      uid,
      data: request.data,
      firestore: db,
      clock: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const moderateChantUpdateSuggestion = onCall(
  { region: "europe-west2" },
  async (request) => {
    const actorUid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("moderateChantUpdateSuggestion", db);
    return handleModerateChantUpdateSuggestion({
      actorUid,
      data: request.data,
      firestore: db,
      clock: () => admin.firestore.Timestamp.now(),
      newAuditId: () => db.collection("auditLog").doc().id,
    });
  }
);

export const updateCreatorProfile = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("updateCreatorProfile", db);
    return handleUpdateCreatorProfile({
      uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const setCreatorFollow = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("setCreatorFollow", db);
    return handleSetCreatorFollow({
      uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const markCreatorNotificationRead = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("markCreatorNotificationRead", db);
    return handleMarkCreatorNotificationRead({
      uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const moderatePublishedPerformance = onCall(
  { region: "europe-west2" },
  async (request) => {
    const actorUid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("moderatePublishedPerformance", db);
    return handlePublishedPerformanceModeration({
      actorUid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
      newAuditId: () => db.collection("auditLog").doc().id,
    });
  }
);

export const resolvePublicShareDestination = onCall(
  { region: "europe-west2" },
  async (request) => {
    await requireOperationEnabled("resolvePublicShareDestination", db, request.data?.targetType === "performance");
    return handleResolvePublicShareDestination({
      data: request.data,
      firestore: db,
    });
  }
);

export const publicSharePage = onRequest(
  { region: "europe-west2" },
  async (request, response) => {
    if (!await operationEnabled("publicSharePage", db, request.path.split("/").filter(Boolean)[0] === "performances")) {
      response.status(503).set("Cache-Control", "no-store").type("text").send("Chants is temporarily paused.");
      return;
    }
    const page = await resolvePublicPage({ path: request.path, firestore: db });
    response
      .status(page.status)
      .set("Cache-Control", "no-store")
      .set(
        "Content-Security-Policy",
        "default-src 'none'; style-src 'unsafe-inline'; img-src https:; " +
          "media-src https:; " +
          "base-uri 'none'; frame-ancestors 'none'; form-action 'none'"
      )
      .set("Referrer-Policy", "no-referrer")
      .set("X-Content-Type-Options", "nosniff")
      .type("html")
      .send(renderPublicPage(page));
  }
);

export const publicPerformanceMedia = onRequest(
  { region: "europe-west2" },
  async (request, response) => {
    if (!await operationEnabled("publicPerformanceMedia", db)) {
      response.status(503).set("Cache-Control", "no-store").type("text").send("Chants is temporarily paused.");
      return;
    }
    const performanceId = performanceIdFromPublicMediaPath(request.path);
    try {
      const destination = await handleResolvePublicPerformanceMedia({
        performanceId,
        firestore: db,
        media: performanceMediaGateway(),
        nowMs: Date.now,
      });
      response
        .status(302)
        .set("Cache-Control", "private,no-store,max-age=0")
        .set("Referrer-Policy", "no-referrer")
        .set("X-Content-Type-Options", "nosniff")
        .redirect(destination.url);
    } catch (_) {
      response
        .status(404)
        .set("Cache-Control", "private,no-store,max-age=0")
        .set("Referrer-Policy", "no-referrer")
        .set("X-Content-Type-Options", "nosniff")
        .type("text")
        .send("This performance is unavailable.");
    }
  }
);

export const createPerformanceDraft = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("createPerformanceDraft", db);
    return handleCreatePerformanceDraft({
      uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
      newId: () => db.collection("performanceDrafts").doc().id,
    });
  }
);

export const submitPerformanceDraft = onCall(
  { region: "europe-west2", ...MEDIA_VALIDATION_RUNTIME },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("submitPerformanceDraft", db);
    return handleSubmitPerformanceDraft({
      uid,
      data: request.data,
      firestore: db,
      media: performanceMediaGateway(),
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const cancelPerformanceDraft = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("cancelPerformanceDraft", db);
    return handleCancelPerformanceDraft({
      uid,
      data: request.data,
      firestore: db,
      media: performanceMediaGateway(),
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const moderatePerformance = onCall(
  { region: "europe-west2", ...MEDIA_VALIDATION_RUNTIME },
  async (request) => {
    const actorUid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("moderatePerformance", db);
    return handleModeratePerformance({
      actorUid,
      data: request.data,
      firestore: db,
      media: performanceMediaGateway(),
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const resolvePerformancePlayback = onCall(
  { region: "europe-west2" },
  async (request) => {
    const actorUid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("resolvePerformancePlayback", db);
    return handleResolvePerformancePlayback({
      actorUid,
      data: request.data,
      firestore: db,
      media: performanceMediaGateway(),
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const setPerformanceLike = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("setPerformanceLike", db);
    return handleSetPerformanceLike({
      uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const recordPerformanceShare = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("recordPerformanceShare", db);
    return handleRecordPerformanceShare({
      uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const recordQualifiedPerformanceView = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("recordQualifiedPerformanceView", db);
    return handleRecordQualifiedPerformanceView({
      uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const createPerformanceComment = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("createPerformanceComment", db);
    return handleCreatePerformanceComment({
      uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const deletePerformanceComment = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("deletePerformanceComment", db);
    return handleDeletePerformanceComment({
      uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const resolvePerformanceDraftPlayback = onCall(
  { region: "europe-west2" },
  async (request) => {
    const actorUid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("resolvePerformanceDraftPlayback", db);
    return handleResolvePerformanceDraftPlayback({
      actorUid,
      data: request.data,
      firestore: db,
      media: performanceMediaGateway(),
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const onPerformanceDraftDeleted = onDocumentDeleted(
  { document: "performanceDrafts/{draftId}", region: "europe-west2", retry: true, ...SERIAL_WORKER_RUNTIME },
  async (event) => {
    const disposition = await handleDeletedDraftCleanup({
      draftId: event.params.draftId, data: event.data?.data(), firestore: db,
      remove: (path) => performanceMediaGateway().remove(path),
      now: () => admin.firestore.Timestamp.now(),
    });
    if (disposition === "blocked") logger.warn("draft-cleanup-blocked", { action: "operator-review-required" });
  }
);

export const onPerformanceLikeWritten = onDocumentWritten(
  { document: "performanceLikes/{likeId}", region: "europe-west2" },
  async (event) => {
    await recomputePerformanceLikeCounts({
      before: event.data?.before.data(),
      after: event.data?.after.data(),
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const onPerformanceViewWritten = onDocumentWritten(
  { document: "performanceViews/{viewId}", region: "europe-west2" },
  async (event) => {
    await recomputePerformanceViewCounts({
      before: event.data?.before.data(),
      after: event.data?.after.data(),
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const onPerformanceShareWritten = onDocumentWritten(
  { document: "performanceShares/{shareId}", region: "europe-west2" },
  async (event) => {
    await recomputePerformanceShareCounts({
      before: event.data?.before.data(),
      after: event.data?.after.data(),
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const onPerformanceCommentWritten = onDocumentWritten(
  { document: "performanceComments/{commentId}", region: "europe-west2" },
  async (event) => {
    await recomputePerformanceCommentCount({
      before: event.data?.before.data(),
      after: event.data?.after.data(),
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const onPerformanceWritten = onDocumentWritten(
  { document: "performances/{performanceId}", region: "europe-west2" },
  async (event) => {
    await handlePerformanceVisibilityWritten({
      before: event.data?.before.data(),
      after: event.data?.after.data(),
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const onChantWrittenForPerformances = onDocumentWritten(
  { document: "chants/{chantId}", region: "europe-west2" },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!chantSourceChanged(before, after)) return;
    await reconcileChantPerformanceSource({
      chantId: event.params.chantId,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const onProfileAuthorityWrittenForPerformances = onDocumentWritten(
  { document: "profiles/{userId}", region: "europe-west2" },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (
      before?.banned === after?.banned &&
      before?.deletionPending === after?.deletionPending &&
      !!before === !!after
    ) return;
    await reconcileCreatorPerformanceSource({
      creatorId: event.params.userId,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const onPerformanceMediaDeletionJobWritten = onDocumentWritten(
  {
    ...SERIAL_WORKER_RUNTIME,
    document: "performanceMediaDeletionJobs/{performanceId}",
    region: "europe-west2",
    retry: true,
  },
  async (event) => {
    const snapshot = event.data?.after;
    if (!snapshot?.exists) return;
    if (!await operationEnabled("onPerformanceMediaDeletionJobWritten", db)) return;
    const cleaned = await cleanupRemovedPerformanceMedia(
      snapshot.data(),
      performanceMediaGateway(),
    );
    if (!cleaned) throw new Error("Invalid performance media deletion job.");
    await snapshot.ref.delete();
  }
);

export const onCreatorFollowWritten = onDocumentWritten(
  { document: "creatorFollows/{followId}", region: "europe-west2" },
  async (event) => {
    await recomputeCreatorFollowCounts({
      before: event.data?.before.data(),
      after: event.data?.after.data(),
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

type ReportWriteResult = {
  flagCount: number;
  autoHidden: boolean;
  targetExists: boolean;
};

async function recomputeReportCount(
  beforeData: admin.firestore.DocumentData | undefined,
  afterData: admin.firestore.DocumentData | undefined,
  targetIdField: "chantId" | "commentId",
  reportsCollection: "reports" | "commentReports",
  targetCollection: "chants" | "comments",
  firestore: admin.firestore.Firestore
): Promise<ReportWriteResult> {
  const targetId = (afterData?.[targetIdField] || beforeData?.[targetIdField]) as string;
  if (!targetId) {
    return { flagCount: 0, autoHidden: false, targetExists: false };
  }

  const reportsQuery = firestore
    .collection(reportsCollection)
    .where(targetIdField, "==", targetId);
  const targetRef = firestore.collection(targetCollection).doc(targetId);
  return firestore.runTransaction(async (transaction) => {
    // Every invocation writes the same target document. If deliveries race,
    // that shared write forces a retry and a fresh query before commit.
    const reportsSnap = await transaction.get(reportsQuery);
    const targetSnap = await transaction.get(targetRef);
    const flagCount = pendingReportCount(reportsSnap.docs.map((report) => report.data()));

    if (!targetSnap.exists) {
      return { flagCount, autoHidden: false, targetExists: false };
    }

    const autoHidden = reportAutoHide(flagCount, targetSnap.data()?.hidden);
    transaction.update(targetRef, {
      flagCount,
      ...(autoHidden ? { hidden: true } : {}),
    });

    return { flagCount, autoHidden, targetExists: true };
  });
}

export async function handleChantReportWritten(
  beforeData: admin.firestore.DocumentData | undefined,
  afterData: admin.firestore.DocumentData | undefined,
  firestore: admin.firestore.Firestore
): Promise<ReportWriteResult> {
  return recomputeReportCount(
    beforeData,
    afterData,
    "chantId",
    "reports",
    "chants",
    firestore
  );
}

export async function handleCommentReportWritten(
  beforeData: admin.firestore.DocumentData | undefined,
  afterData: admin.firestore.DocumentData | undefined,
  firestore: admin.firestore.Firestore
): Promise<ReportWriteResult> {
  return recomputeReportCount(
    beforeData,
    afterData,
    "commentId",
    "commentReports",
    "comments",
    firestore
  );
}

// Recomputes flagCount from pending report documents. An absolute count makes
// duplicate, out-of-order, status-change, and delete deliveries converge.
export const onReportCreated = onDocumentWritten(
  { document: "reports/{reportId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const result = await handleChantReportWritten(beforeData, afterData, db);
    const chantId = (afterData?.chantId || beforeData?.chantId) as string;

    if (result.autoHidden) {
      await writeAuditEntry({
        actorId: "system",
        action: "auto-hide",
        targetType: "chant",
        targetId: chantId,
        detail: `Auto-hidden: flagCount reached ${result.flagCount} (threshold ${AUTO_HIDE_THRESHOLD}).`,
      });
    }

    if (!beforeData && afterData) {
      await writePrivacySafeReportAuditEntry({
        reporterId: afterData.reportedBy as string,
        action: "report",
        targetType: "chant",
        targetId: chantId,
        reason: afterData.reason as string,
        firestore: db,
      });
    }
  }
);

// --- onModerationAction (callable) ---
// Operator-only. Actions include hide, unhide, remove, ban, and unban.
// Actor UID derived from auth context, never from client parameter.
// Fix 4: resolves associated reports and resets flagCount on unhide.
type UserBanAction = "ban" | "unban";

type UserProfileDocument = {
  get: () => Promise<{ exists: boolean }>;
  update: (data: { banned: boolean; activePerformanceUpload?: null }) => Promise<unknown>;
};

type CreatorProfileDocument = {
  get: () => Promise<{
    exists: boolean;
    data: () => admin.firestore.DocumentData | undefined;
  }>;
  update: (data: { hidden: boolean }) => Promise<unknown>;
};

type AuditWriter = (params: {
  actorId: string;
  action: string;
  targetType: string;
  targetId: string;
  detail: string;
}) => Promise<void>;

export async function handleUserBanAction(params: {
  action: UserBanAction;
  actorUid: string;
  targetId: string;
  profileDocument: UserProfileDocument;
  creatorProfileDocument: CreatorProfileDocument;
  reconcilePerformances: () => Promise<unknown>;
  auditWriter: AuditWriter;
}): Promise<{ success: true }> {
  const targetProfile = await params.profileDocument.get();
  if (!targetProfile.exists) {
    throw new HttpsError("not-found", "User profile not found.");
  }

  const banned = params.action === "ban";
  await params.profileDocument.update({ banned, ...(banned ? { activePerformanceUpload: null } : {}) });
  const creatorProfile = await params.creatorProfileDocument.get();
  const creatorCanReturn = creatorProfile.exists &&
    creatorProfile.data()?.removed !== true;
  if (creatorProfile.exists && (banned || creatorCanReturn)) {
    await params.creatorProfileDocument.update({ hidden: banned });
  }
  await params.reconcilePerformances();
  await params.auditWriter({
    actorId: params.actorUid,
    action: params.action,
    targetType: "user",
    targetId: params.targetId,
    detail: banned
      ? "User banned by operator."
      : "User unbanned by operator.",
  });
  return { success: true };
}

async function applyChantTrustAction(params: {
  action: ChantTrustAction;
  actorUid: string;
  targetId: string;
}): Promise<{ success: true; changed: boolean }> {
  const chantRef = db.collection("chants").doc(params.targetId);
  const auditRef = db.collection("auditLog").doc();
  let plan: ChantTrustPlan | undefined;

  await db.runTransaction(async (transaction) => {
    const chantSnap = await transaction.get(chantRef);
    if (!chantSnap.exists) {
      throw new HttpsError("not-found", "Chant not found.");
    }

    plan = planChantTrustAction(params.action, chantSnap.data()!);
    if (!plan.changed) return;

    const update: admin.firestore.UpdateData<admin.firestore.DocumentData> = {};
    if (plan.nextStatus) update.status = plan.nextStatus;
    if (plan.deleteEvidence) {
      update.evidence = admin.firestore.FieldValue.delete();
    }
    transaction.update(chantRef, update);
    transaction.set(auditRef, {
      actorId: params.actorUid,
      action: plan.auditAction,
      targetType: "chant",
      targetId: params.targetId,
      detail: plan.auditDetail,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  if (!plan) {
    throw new HttpsError("internal", "Moderation action was not planned.");
  }
  return { success: true, changed: plan.changed };
}

export const onModerationAction = onCall(
  { region: "europe-west2" },
  async (request) => {
    // Derive actor from auth context (hardening: never trust client-supplied UID)
    const actorUid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("onModerationAction", db);

    // Verify operator role via Admin SDK
    const actorProfile = await db.collection("profiles").doc(actorUid).get();
    if (
      !actorProfile.exists ||
      actorProfile.data()?.role !== "operator" ||
      actorProfile.data()?.deletionPending === true
    ) {
      throw new HttpsError("permission-denied", "Operator access required.");
    }

    const { action, targetId } = request.data as {
      action: string;
      targetId: string;
    };

    if (!action || !targetId) {
      throw new HttpsError("invalid-argument", "action and targetId are required.");
    }

    switch (action) {
      case "hide": {
        await db.collection("chants").doc(targetId).update({ hidden: true });
        // Fix 4: resolve associated reports
        await resolveReportsForChant(targetId, "reviewed");
        await writeAuditEntry({
          actorId: actorUid,
          action: "hide",
          targetType: "chant",
          targetId,
          detail: "Chant hidden by operator.",
        });
        return { success: true };
      }

      case "unhide": {
        // Fix 4: reset flagCount so cleared false positives do not re-trigger auto-hide
        await db.collection("chants").doc(targetId).update({
          hidden: false,
          flagCount: 0,
        });
        // Fix 4: dismiss associated reports (operator reviewed and cleared)
        await resolveReportsForChant(targetId, "dismissed");
        await writeAuditEntry({
          actorId: actorUid,
          action: "unhide",
          targetType: "chant",
          targetId,
          detail: "Chant unhidden by operator. flagCount reset to 0, reports dismissed.",
        });
        return { success: true };
      }

      case "remove": {
        await db.collection("chants").doc(targetId).update({ removed: true });
        await resolveReportsForChant(targetId, "reviewed");
        await writeAuditEntry({
          actorId: actorUid,
          action: "remove",
          targetType: "chant",
          targetId,
          detail: "Chant removed by operator.",
        });
        return { success: true };
      }

      case "ban":
      case "unban": {
        // targetId is the user's profile UID. The Admin SDK write remains
        // behind the operator role check above; clients cannot edit banned.
        return handleUserBanAction({
          action,
          actorUid,
          targetId,
          profileDocument: db.collection("profiles").doc(targetId),
          creatorProfileDocument: db.collection("creatorProfiles").doc(targetId),
          reconcilePerformances: () =>
            reconcileCreatorPerformanceSource({
              creatorId: targetId,
              firestore: db,
              now: () => admin.firestore.Timestamp.now(),
            }),
          auditWriter: writeAuditEntry,
        });
      }

      case "promote":
      case "demote":
      case "remove-evidence":
        return applyChantTrustAction({ action, actorUid, targetId });

      case "hide-comment": {
        const cSnap = await db.collection("comments").doc(targetId).get();
        if (!cSnap.exists) {
          throw new HttpsError("not-found", "Comment not found.");
        }
        await db.collection("comments").doc(targetId).update({ hidden: true });
        await resolveCommentReports(targetId, "reviewed");
        await recomputeCommentCount(cSnap.data()!.chantId as string);
        await writeAuditEntry({
          actorId: actorUid,
          action: "hide",
          targetType: "comment",
          targetId,
          detail: "Comment hidden by operator.",
        });
        return { success: true };
      }

      case "unhide-comment": {
        const cSnap2 = await db.collection("comments").doc(targetId).get();
        if (!cSnap2.exists) {
          throw new HttpsError("not-found", "Comment not found.");
        }
        await db.collection("comments").doc(targetId).update({
          hidden: false,
          flagCount: 0,
        });
        await resolveCommentReports(targetId, "dismissed");
        await recomputeCommentCount(cSnap2.data()!.chantId as string);
        await writeAuditEntry({
          actorId: actorUid,
          action: "unhide",
          targetType: "comment",
          targetId,
          detail: "Comment unhidden by operator. flagCount reset to 0, reports dismissed.",
        });
        return { success: true };
      }

      case "remove-comment": {
        const cSnap3 = await db.collection("comments").doc(targetId).get();
        if (!cSnap3.exists) {
          throw new HttpsError("not-found", "Comment not found.");
        }
        await db.collection("comments").doc(targetId).update({ removed: true });
        await resolveCommentReports(targetId, "reviewed");
        await recomputeCommentCount(cSnap3.data()!.chantId as string);
        await writeAuditEntry({
          actorId: actorUid,
          action: "remove",
          targetType: "comment",
          targetId,
          detail: "Comment removed by operator.",
        });
        return { success: true };
      }

      default:
        throw new HttpsError(
          "invalid-argument",
          `Unknown action "${action}". Valid: hide, unhide, remove, ban, unban, promote, demote, remove-evidence, hide-comment, unhide-comment, remove-comment.`
        );
    }
  }
);

// --- onChantCreated ---
// Soft rate limit (Fix 2, option b): checks submission velocity.
// Auto-hides (never auto-removes) abnormally high-velocity bursts.
const NEW_ACCOUNT_LIMIT = 2;
const PROVEN_ACCOUNT_LIMIT = 5;
const NEW_ACCOUNT_AGE_MS = 24 * 60 * 60 * 1000; // 24 hours

export function isNewAccount(accountAgeMs: number): boolean {
  return accountAgeMs < NEW_ACCOUNT_AGE_MS;
}

export const onChantCreated = onDocumentCreated(
  { document: "chants/{chantId}", region: "europe-west2" },
  async (event) => {
    const chantData = event.data?.data();
    if (!chantData) return;

    const userId = chantData.createdBy as string;
    if (userId === "system") return; // Seed writes bypass rate limit

    const profileSnap = await db.collection("profiles").doc(userId).get();
    if (!profileSnap.exists) return;

    const profileData = profileSnap.data()!;
    const createdAt = profileData.createdAt?.toDate?.() || new Date();
    const accountAge = Date.now() - createdAt.getTime();

    // Count submissions in the last hour
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentChants = await db
      .collection("chants")
      .where("createdBy", "==", userId)
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(oneHourAgo))
      .get();

    const totalSubmissions = recentChants.size;
    const isNew = isNewAccount(accountAge);
    const limit = isNew ? NEW_ACCOUNT_LIMIT : PROVEN_ACCOUNT_LIMIT;

    if (totalSubmissions > limit) {
      // Auto-hide (pending review), never auto-remove
      await event.data?.ref.update({ hidden: true });
      await writeAuditEntry({
        actorId: "system",
        action: "rate-limit-hide",
        targetType: "chant",
        targetId: event.data?.id || "unknown",
        detail: `Auto-hidden: user submitted ${totalSubmissions} chants in the last hour (limit ${limit}).`,
      });
    }
  }
);

// --- onVoteWritten ---
// Maintains upvotes, downvotes, and score on the chant by recomputing from
// the actual vote docs (ground truth). The parent read, child query, counter
// write, and surviving vote stamp share one transaction. Concurrent handlers
// therefore conflict on the parent and retry with current ground truth.
/// Core handler logic, extracted so it can be unit-tested with a fake db.
export async function handleVoteWritten(
  beforeData: admin.firestore.DocumentData | undefined,
  afterData: admin.firestore.DocumentData | undefined,
  voteId: string,
  firestore: admin.firestore.Firestore
): Promise<void> {
  const chantId = (afterData?.chantId || beforeData?.chantId) as string;
  if (!chantId) return;

  // No-op early return: if the value field did not change (e.g. appliedValue
  // write-back re-trigger), skip the recompute entirely.
  let upDelta = 0;
  let downDelta = 0;

  if (beforeData) {
    if (beforeData.value === 1) upDelta -= 1;
    else if (beforeData.value === -1) downDelta -= 1;
  }

  if (afterData) {
    if (afterData.value === 1) upDelta += 1;
    else if (afterData.value === -1) downDelta += 1;
  }

  if (upDelta === 0 && downDelta === 0) return;

  const chantRef = firestore.collection("chants").doc(chantId);
  const votesQuery = firestore
    .collection("votes")
    .where("chantId", "==", chantId);
  const voteRef = firestore.collection("votes").doc(voteId);

  await firestore.runTransaction(async (transaction) => {
    const chantSnap = await transaction.get(chantRef);
    if (!chantSnap.exists) return;

    const votesSnap = await transaction.get(votesQuery);
    const currentVoteSnap = afterData
      ? await transaction.get(voteRef)
      : null;
    let upvotes = 0;
    let downvotes = 0;
    for (const doc of votesSnap.docs) {
      if (doc.data().value === 1) upvotes++;
      else if (doc.data().value === -1) downvotes++;
    }

    transaction.update(chantRef, {
      upvotes,
      downvotes,
      score: upvotes - downvotes,
    });

    // An older delivery may run after the same vote changed again. Stamp only
    // when the surviving document still represents this event's value.
    if (
      afterData &&
      currentVoteSnap?.exists &&
      currentVoteSnap.data()?.chantId === chantId &&
      currentVoteSnap.data()?.value === afterData.value
    ) {
      transaction.update(voteRef, { appliedValue: afterData.value });
    }
  });
}

export const onVoteWritten = onDocumentWritten(
  { document: "votes/{voteId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    await handleVoteWritten(beforeData, afterData, event.params.voteId, db);
  }
);

// --- deleteAccount (callable plus retry worker) ---
// Durably requests deletion for the calling UID. The retry-enabled job worker
// advances one bounded phase or page per event, so completion does not depend
// on the client remaining connected or authenticating again.
export const deleteAccount = onCall(
  { region: "europe-west2" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    await requireOperationEnabled("deleteAccount", db);
    return requestAccountDeletion({
      uid: request.auth.uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

export const onAccountDeletionJobWritten = onDocumentWritten(
  {
    ...SERIAL_WORKER_RUNTIME,
    document: "accountDeletionJobs/{uid}",
    region: "europe-west2",
    retry: true,
  },
  async (event) => {
    if (!event.data?.after.exists) return;
    if (!await operationEnabled("onAccountDeletionJobWritten", db)) return;
    await processAccountDeletionStep({
      uid: event.params.uid,
      firestore: db,
      auth: admin.auth(),
      now: () => admin.firestore.Timestamp.now(),
    });
  }
);

// --- acceptPolicy (callable) ---
// Records that the calling user accepted the current Terms and Community Rules
// version. Actor derived from auth context, never from a client parameter.
// The version and timestamp are decided server-side, never trusted from the
// client, so this write is the only source of truth for consent.
/// Core handler logic, extracted so it can be unit-tested with a fake db,
/// same pattern as handleVoteWritten/handleCommentLikeWritten. Does not
/// write the audit entry itself, so the tested core has no dependency on
/// the global admin.firestore() that writeAuditEntry uses.
export async function handleAcceptPolicy(
  uid: string,
  firestore: admin.firestore.Firestore
): Promise<{ accepted: boolean }> {
  const profileRef = firestore.collection("profiles").doc(uid);
  const profileSnap = await profileRef.get();
  if (!profileSnap.exists) {
    return { accepted: false };
  }
  if (profileSnap.data()?.deletionPending === true) {
    throw new HttpsError("failed-precondition", "Account deletion is in progress.");
  }

  await profileRef.update({
    acceptedPolicyVersion: CURRENT_POLICY_VERSION,
    acceptedPolicyAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { accepted: true };
}

export const acceptPolicy = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("acceptPolicy", db);

    const result = await handleAcceptPolicy(uid, db);
    if (!result.accepted) {
      throw new HttpsError("not-found", "Profile not found.");
    }

    await writeAuditEntry({
      actorId: uid,
      action: "accept-policy",
      targetType: "user",
      targetId: uid,
      detail: `Accepted Terms and Community Rules version ${CURRENT_POLICY_VERSION}.`,
    });

    return { success: true, version: CURRENT_POLICY_VERSION };
  }
);

export const completeOnboarding = onCall(
  { region: "europe-west2" },
  async (request) => {
    const uid = requireVerifiedUid(request.auth);
    await requireOperationEnabled("completeOnboarding", db);
    return handleCompleteOnboarding({
      uid,
      data: request.data,
      firestore: db,
      now: () => admin.firestore.Timestamp.now(),
      policyVersion: CURRENT_POLICY_VERSION,
    });
  }
);

// --- mergeChants (callable) ---
// Operator-only. Merges a duplicate chant (source) into a keeper (target).
// Moves votes and reports, deletes the source, reconciles target counters,
// and logs a bounded source summary for investigation. The operation is not
// atomic, resumable, or automatically reversible.
export function requireMergeChantsEnabled(): void {
  throw new HttpsError(
    "failed-precondition",
    "Chant merging is unavailable until resumable recovery is implemented."
  );
}

export const mergeChants = onCall(
  { region: "europe-west2" },
  async (request) => {
    const actorUid = requireVerifiedUid(request.auth);

    // Operator check: read role from Firestore profile, same pattern as onModerationAction
    const actorProfile = await db.collection("profiles").doc(actorUid).get();
    if (
      !actorProfile.exists ||
      actorProfile.data()?.role !== "operator" ||
      actorProfile.data()?.deletionPending === true
    ) {
      throw new HttpsError("permission-denied", "Operator access required.");
    }

    requireMergeChantsEnabled();

    const { sourceId, targetId } = request.data as {
      sourceId: string;
      targetId: string;
    };

    if (!sourceId || !targetId) {
      throw new HttpsError("invalid-argument", "sourceId and targetId are required.");
    }
    if (sourceId === targetId) {
      throw new HttpsError("invalid-argument", "sourceId and targetId must be different.");
    }

    // Validate both chants exist and belong to the same team
    const sourceSnap = await db.collection("chants").doc(sourceId).get();
    const targetSnap = await db.collection("chants").doc(targetId).get();

    if (!sourceSnap.exists) {
      throw new HttpsError("not-found", `Source chant ${sourceId} not found.`);
    }
    if (!targetSnap.exists) {
      throw new HttpsError("not-found", `Target chant ${targetId} not found.`);
    }

    const sourceData = sourceSnap.data()!;
    const targetData = targetSnap.data()!;

    if (sourceData.teamId !== targetData.teamId) {
      throw new HttpsError(
        "invalid-argument",
        "Source and target must belong to the same team."
      );
    }

    // Capture a bounded source summary for audit and incident investigation.
    const sourcePayload = {
      title: sourceData.title,
      lyrics: sourceData.lyrics,
      tuneName: sourceData.tuneName,
      subjectTag: sourceData.subjectTag,
      teamId: sourceData.teamId,
      playerId: sourceData.playerId || null,
      sportId: sourceData.sportId,
      competitionId: sourceData.competitionId,
      status: sourceData.status,
      contextNotes: sourceData.contextNotes || null,
      chantType: sourceData.chantType,
      mediaType: sourceData.mediaType,
      createdBy: sourceData.createdBy,
    };

    // Step 1: Move votes from source to target.
    // NOTE: onVoteWritten fires automatically as votes move, handling counter
    // deltas on both source and target. The reconcile-target step at the end
    // is the safety net for any drift or duplicate delivery from at-least-once
    // trigger delivery.
    const sourceVotes = await db.collection("votes")
      .where("chantId", "==", sourceId).get();
    let votesMoved = 0;
    let votesSkipped = 0;

    for (const voteDoc of sourceVotes.docs) {
      const voteData = voteDoc.data();
      const userId = voteData.userId as string;
      const targetVoteId = `${userId}_${targetId}`;

      // Check if user already voted on target
      const existingTargetVote = await db.collection("votes").doc(targetVoteId).get();

      if (existingTargetVote.exists) {
        // User voted on both: keep target vote, delete source vote
        await voteDoc.ref.delete();
        votesSkipped++;
      } else {
        // Move: delete old doc, create new doc with target chantId
        await db.collection("votes").doc(targetVoteId).set({
          ...voteData,
          chantId: targetId,
        });
        await voteDoc.ref.delete();
        votesMoved++;
      }
    }

    // Step 2: Move reports from source to target
    const sourceReports = await db.collection("reports")
      .where("chantId", "==", sourceId).get();
    let reportsMoved = 0;

    for (const reportDoc of sourceReports.docs) {
      const reportData = reportDoc.data();
      const reportedBy = reportData.reportedBy as string;
      const targetReportId = `${reportedBy}_${targetId}`;

      // Check if user already reported target
      const existingTargetReport = await db.collection("reports").doc(targetReportId).get();

      if (existingTargetReport.exists) {
        // Already reported target: just delete the source report
        await reportDoc.ref.delete();
      } else {
        // Move: delete old, create new
        await db.collection("reports").doc(targetReportId).set({
          ...reportData,
          chantId: targetId,
        });
        await reportDoc.ref.delete();
        reportsMoved++;
      }
    }

    // Step 3: Move all comments, including replies, to the target. Parent IDs
    // remain stable because every comment in the source thread moves together.
    const sourceComments = await db.collection("comments")
      .where("chantId", "==", sourceId).get();
    let commentsMoved = 0;
    for (const commentDoc of sourceComments.docs) {
      await commentDoc.ref.update({ chantId: targetId });
      commentsMoved++;
    }

    // Step 4: Delete the source chant
    await db.collection("chants").doc(sourceId).delete();

    // Step 5: Reconcile target counters from ground truth (safety net)
    await reconcileChantCounters(targetId);
    await recomputeCommentCount(targetId);

    // Step 6: Audit log with the bounded source summary and move counts.
    await writeAuditEntry({
      actorId: actorUid,
      action: "merge_chants",
      targetType: "chant",
      targetId,
      detail: JSON.stringify({
        sourceId,
        targetId,
        votesMoved,
        votesSkipped,
        reportsMoved,
        commentsMoved,
        sourcePayload,
      }),
    });

    return {
      success: true,
      votesMoved,
      votesSkipped,
      reportsMoved,
      commentsMoved,
    };
  }
);

// --- onCommentLikeWritten ---
// Maintains likeCount on the comment by recomputing from the actual like docs.
// Parent, query, count, and surviving like stamp share one transaction so a
// stale concurrent invocation cannot overwrite a newer aggregate.
export async function handleCommentLikeWritten(
  beforeData: admin.firestore.DocumentData | undefined,
  afterData: admin.firestore.DocumentData | undefined,
  likeId: string,
  firestore: admin.firestore.Firestore
): Promise<void> {
  const commentId = (afterData?.commentId || beforeData?.commentId) as string;
  if (!commentId) return;

  // No-op early return: if the value field did not change (e.g. appliedValue
  // write-back re-trigger), skip the recompute.
  const beforeVal = beforeData?.value as number | undefined;
  const afterVal = afterData?.value as number | undefined;
  if (beforeVal === afterVal) return;

  const commentRef = firestore.collection("comments").doc(commentId);
  const likesQuery = firestore
    .collection("commentLikes")
    .where("commentId", "==", commentId);
  const likeRef = firestore.collection("commentLikes").doc(likeId);

  await firestore.runTransaction(async (transaction) => {
    const commentSnap = await transaction.get(commentRef);
    if (!commentSnap.exists) return;

    const likesSnap = await transaction.get(likesQuery);
    const currentLikeSnap = afterData
      ? await transaction.get(likeRef)
      : null;
    let likeCount = 0;
    for (const doc of likesSnap.docs) {
      if (doc.data().value === 1) likeCount++;
    }

    transaction.update(commentRef, { likeCount });
    if (
      afterData &&
      currentLikeSnap?.exists &&
      currentLikeSnap.data()?.commentId === commentId &&
      currentLikeSnap.data()?.value === afterData.value
    ) {
      transaction.update(likeRef, { appliedValue: afterData.value });
    }
  });
}

export const onCommentLikeWritten = onDocumentWritten(
  { document: "commentLikes/{likeId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    await handleCommentLikeWritten(
      beforeData, afterData, event.params.likeId, db
    );
  }
);

// --- onCommentWritten ---
// Fires on every comment write (create, update, delete). Recomputes
// commentCount on the parent chant from ground truth on every invocation.
// This covers author soft-delete, operator hide/remove, rate-limit auto-hide,
// and regular creates in a single trigger, so there is never a path that
// changes visibility without updating the count.
//
// Loop guard: this function writes to the CHANT document (commentCount), not
// back to the comment document that triggered it, so it cannot retrigger itself.
//
// Rate-limiting runs only on creates (no beforeData), same as the previous
// onCommentCreated.
const COMMENT_NEW_ACCOUNT_LIMIT = 5;
const COMMENT_PROVEN_ACCOUNT_LIMIT = 20;

export const onCommentWritten = onDocumentWritten(
  { document: "comments/{commentId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    const chantId = (afterData?.chantId || beforeData?.chantId) as string;
    if (!chantId) return;

    // Always recompute commentCount from ground truth.
    await recomputeCommentCount(chantId);

    // Rate-limit check only on create (no beforeData).
    if (beforeData) return; // update or delete, skip rate-limiting
    if (!afterData) return;

    const userId = afterData.userId as string;
    if (userId === "system") return;

    const profileSnap = await db.collection("profiles").doc(userId).get();
    if (!profileSnap.exists) return;

    const profileData = profileSnap.data()!;
    const createdAt = profileData.createdAt?.toDate?.() || new Date();
    const accountAge = Date.now() - createdAt.getTime();

    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentComments = await db
      .collection("comments")
      .where("userId", "==", userId)
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(oneHourAgo))
      .get();

    const totalComments = recentComments.size;
    const isNew = isNewAccount(accountAge);
    const limit = isNew ? COMMENT_NEW_ACCOUNT_LIMIT : COMMENT_PROVEN_ACCOUNT_LIMIT;

    if (totalComments > limit) {
      // Auto-hide (pending review), never auto-remove.
      // This update retriggers onCommentWritten, but the second invocation
      // just recomputes commentCount again (idempotent, same result).
      const commentRef = event.data?.after?.ref;
      if (commentRef) {
        await commentRef.update({ hidden: true });
      }
      await writeAuditEntry({
        actorId: "system",
        action: "rate-limit-hide",
        targetType: "comment",
        targetId: event.params.commentId,
        detail: `Auto-hidden: user posted ${totalComments} comments in the last hour (limit ${limit}).`,
      });
    }
  }
);

// Mirrors the chant report handler with ground-truth recomputation.
export const onCommentReportCreated = onDocumentWritten(
  { document: "commentReports/{reportId}", region: "europe-west2" },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const result = await handleCommentReportWritten(beforeData, afterData, db);
    const commentId = (afterData?.commentId || beforeData?.commentId) as string;

    if (result.autoHidden) {
      const commentSnap = await db.collection("comments").doc(commentId).get();
      if (commentSnap.exists) {
        await recomputeCommentCount(commentSnap.data()!.chantId as string);
      }
      await writeAuditEntry({
        actorId: "system",
        action: "auto-hide",
        targetType: "comment",
        targetId: commentId,
        detail: `Auto-hidden: flagCount reached ${result.flagCount} (threshold ${AUTO_HIDE_THRESHOLD}).`,
      });
    }

    if (!beforeData && afterData) {
      await writePrivacySafeReportAuditEntry({
        reporterId: afterData.reportedBy as string,
        action: "report",
        targetType: "comment",
        targetId: commentId,
        reason: afterData.reason as string,
        firestore: db,
      });
    }
  }
);

// --- onUserReportCreated ---
// Recomputes userReportCount on the reported user's profile from a
// ground-truth query over userReports (never FieldValue.increment), so
// duplicate or out-of-order trigger delivery always converges to the
// correct count, same pattern as onVoteWritten/onCommentLikeWritten.
// No auto-action: a high count only surfaces the profile in moderation for
// a human to review. banUser stays operator-only and manual.
/// Core handler logic, extracted so it can be unit-tested with a fake db,
/// same pattern as handleVoteWritten/handleCommentLikeWritten. Does not
/// write the audit entry itself (writeAuditEntry uses the global
/// admin.firestore(), see the same note on handleAcceptPolicy above).
export async function handleUserReportCreated(
  reportedUserId: string,
  firestore: admin.firestore.Firestore
): Promise<{ userReportCount: number }> {
  const reportsQuery = firestore
    .collection("userReports")
    .where("reportedUserId", "==", reportedUserId);
  const profileRef = firestore.collection("profiles").doc(reportedUserId);
  return firestore.runTransaction(async (transaction) => {
    const profileSnap = await transaction.get(profileRef);
    if (!profileSnap.exists) return { userReportCount: 0 };

    const reportsSnap = await transaction.get(reportsQuery);
    const userReportCount = reportsSnap.size;
    transaction.update(profileRef, { userReportCount });
    return { userReportCount };
  });
}

export const onUserReportCreated = onDocumentCreated(
  { document: "userReports/{reportId}", region: "europe-west2" },
  async (event) => {
    const reportData = event.data?.data();
    if (!reportData) return;

    const reportedUserId = reportData.reportedUserId as string;
    await handleUserReportCreated(reportedUserId, db);

    await writePrivacySafeReportAuditEntry({
      reporterId: reportData.reportedBy as string,
      action: "report-user",
      targetType: "user",
      targetId: reportedUserId,
      reason: reportData.reason as string,
      firestore: db,
    });
  }
);

// Account deletion removes user reports in bounded background pages. Deletes
// need their own convergence trigger because the legacy create-only trigger
// cannot repair a surviving target's count after the report disappears.
export async function handleUserReportDeleted(
  reportData: admin.firestore.DocumentData | undefined,
  firestore: admin.firestore.Firestore
): Promise<void> {
  const reportedUserId = reportData?.reportedUserId as string | undefined;
  if (!reportedUserId) return;
  await handleUserReportCreated(reportedUserId, firestore);
}

export const onUserReportDeleted = onDocumentDeleted(
  { document: "userReports/{reportId}", region: "europe-west2" },
  async (event) => {
    await handleUserReportDeleted(event.data?.data(), db);
  }
);

// --- Helper: recompute commentCount on a chant from ground truth ---
async function recomputeCommentCount(
  chantId: string,
  firestore: admin.firestore.Firestore = db
): Promise<void> {
  const chantRef = firestore.collection("chants").doc(chantId);
  const commentsQuery = firestore
    .collection("comments")
    .where("chantId", "==", chantId)
    .where("hidden", "==", false)
    .where("removed", "==", false);
  await firestore.runTransaction(async (transaction) => {
    const chantSnap = await transaction.get(chantRef);
    if (!chantSnap.exists) return;
    const commentsSnap = await transaction.get(commentsQuery);
    transaction.update(chantRef, { commentCount: commentsSnap.size });
  });
}

// --- Helper: resolve comment reports ---
async function resolveCommentReports(
  commentId: string,
  newStatus: "reviewed" | "dismissed"
): Promise<void> {
  const reports = await db
    .collection("commentReports")
    .where("commentId", "==", commentId)
    .where("status", "==", "pending")
    .get();

  if (reports.empty) return;
  const batch = db.batch();
  for (const doc of reports.docs) {
    batch.update(doc.ref, { status: newStatus });
  }
  await batch.commit();
}

// --- Helper: reconcile chant counters from votes collection ---
async function reconcileChantCounters(
  chantId: string,
  firestore: admin.firestore.Firestore = db
): Promise<void> {
  const chantRef = firestore.collection("chants").doc(chantId);
  const votesQuery = firestore.collection("votes").where("chantId", "==", chantId);
  await firestore.runTransaction(async (transaction) => {
    const chantSnap = await transaction.get(chantRef);
    if (!chantSnap.exists) return;
    const votesSnap = await transaction.get(votesQuery);
    let upvotes = 0;
    let downvotes = 0;
    for (const doc of votesSnap.docs) {
      if (doc.data().value === 1) upvotes++;
      else if (doc.data().value === -1) downvotes++;
    }
    transaction.update(chantRef, {
      upvotes,
      downvotes,
      score: upvotes - downvotes,
    });
  });
}

// --- Helper: resolve reports for a chant ---
async function resolveReportsForChant(
  chantId: string,
  newStatus: "reviewed" | "dismissed"
): Promise<void> {
  const reports = await db
    .collection("reports")
    .where("chantId", "==", chantId)
    .where("status", "==", "pending")
    .get();

  const batch = db.batch();
  for (const doc of reports.docs) {
    batch.update(doc.ref, { status: newStatus });
  }
  await batch.commit();
}
