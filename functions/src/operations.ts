import * as admin from "firebase-admin";

type Data = Record<string, unknown>;

export const ABANDONED_DRAFT_AGE_MS = 24 * 60 * 60 * 1000;
export const ABANDONED_DRAFT_LIMIT = 100;
export const ACCOUNT_DELETION_STALE_AGE_MS = 30 * 60 * 1000;
export const MEDIA_DELETION_STALE_AGE_MS = 15 * 60 * 1000;
export const OPERATIONAL_BACKLOG_LIMIT = 100;

export type OperationalDocument = {
  id: string;
  data: Data;
};

export type OperationalJobCollection =
  | "accountDeletionJobs"
  | "performanceMediaDeletionJobs";

export interface OperationalStore {
  listCleanupDrafts(
    createdAtOrBeforeMs: number,
    limit: number,
  ): Promise<OperationalDocument[]>;
  claimCleanupDraft(
    id: string,
    createdAtOrBeforeMs: number,
    updatedAtMs: number,
  ): Promise<OperationalDocument | null>;
  deleteClaimedDraft(id: string): Promise<boolean>;
  countStaleJobs(
    collection: OperationalJobCollection,
    updatedAtOrBeforeMs: number,
    limit: number,
  ): Promise<number>;
}

export interface OperationalCleanupMedia {
  remove(path: string): Promise<void>;
}

export type AbandonedDraftCleanupResult = {
  scanned: number;
  claimed: number;
  deleted: number;
  invalid: number;
  failures: number;
};

export function abandonedDraftCleanupDisposition(
  result: AbandonedDraftCleanupResult,
): { shouldRetry: boolean; shouldWarn: boolean } {
  return {
    shouldRetry: result.failures > 0,
    shouldWarn: result.invalid > 0,
  };
}

type BacklogCount = {
  staleCount: number;
  moreThanLimit: boolean;
};

export type OperationalBacklogSummary = {
  accountDeletionJobs: BacklogCount;
  performanceMediaDeletionJobs: BacklogCount;
  hasStaleJobs: boolean;
};

function isTimestamp(value: unknown): value is admin.firestore.Timestamp {
  return value instanceof admin.firestore.Timestamp;
}

function isCleanId(value: unknown): value is string {
  return typeof value === "string" && /^[A-Za-z0-9_-]{1,128}$/.test(value);
}

function exactDraftPath(ownerId: string, draftId: string): string {
  return `performance-staging/${ownerId}/${draftId}/source`;
}

function validCleanupDraft(document: OperationalDocument): boolean {
  const data = document.data;
  if (
    !isCleanId(document.id) ||
    data.schemaVersion !== 1 ||
    !isCleanId(data.ownerId) ||
    (data.state !== "awaiting_upload" && data.state !== "cleanup_pending") ||
    !isTimestamp(data.createdAt)
  ) return false;
  return data.uploadPath === exactDraftPath(data.ownerId, document.id);
}

export async function cleanupAbandonedPerformanceDrafts(params: {
  store: OperationalStore;
  media: OperationalCleanupMedia;
  now: () => admin.firestore.Timestamp;
}): Promise<AbandonedDraftCleanupResult> {
  const nowMs = params.now().toMillis();
  const cutoffMs = nowMs - ABANDONED_DRAFT_AGE_MS;
  const candidates = await params.store.listCleanupDrafts(
    cutoffMs,
    ABANDONED_DRAFT_LIMIT,
  );
  const result: AbandonedDraftCleanupResult = {
    scanned: candidates.length,
    claimed: 0,
    deleted: 0,
    invalid: 0,
    failures: 0,
  };

  for (const candidate of candidates) {
    if (!validCleanupDraft(candidate)) {
      result.invalid++;
      continue;
    }
    const claimed = await params.store.claimCleanupDraft(
      candidate.id,
      cutoffMs,
      nowMs,
    );
    if (!claimed) continue;
    if (!validCleanupDraft(claimed)) {
      result.invalid++;
      continue;
    }
    result.claimed++;
    try {
      await params.media.remove(claimed.data.uploadPath as string);
      if (await params.store.deleteClaimedDraft(claimed.id)) result.deleted++;
      else result.failures++;
    } catch (_) {
      result.failures++;
    }
  }
  return result;
}

function backlogCount(observed: number): BacklogCount {
  return {
    staleCount: Math.min(observed, OPERATIONAL_BACKLOG_LIMIT),
    moreThanLimit: observed > OPERATIONAL_BACKLOG_LIMIT,
  };
}

export async function monitorOperationalBacklogs(params: {
  store: OperationalStore;
  now: () => admin.firestore.Timestamp;
}): Promise<OperationalBacklogSummary> {
  const nowMs = params.now().toMillis();
  const queryLimit = OPERATIONAL_BACKLOG_LIMIT + 1;
  const [accountCount, mediaCount] = await Promise.all([
    params.store.countStaleJobs(
      "accountDeletionJobs",
      nowMs - ACCOUNT_DELETION_STALE_AGE_MS,
      queryLimit,
    ),
    params.store.countStaleJobs(
      "performanceMediaDeletionJobs",
      nowMs - MEDIA_DELETION_STALE_AGE_MS,
      queryLimit,
    ),
  ]);
  const accountDeletionJobs = backlogCount(accountCount);
  const performanceMediaDeletionJobs = backlogCount(mediaCount);
  return {
    accountDeletionJobs,
    performanceMediaDeletionJobs,
    hasStaleJobs: accountCount > 0 || mediaCount > 0,
  };
}

export function operationalBacklogLog(summary: OperationalBacklogSummary): {
  operationalSignal: "stale-deletion-jobs";
  accountDeletionStaleCount: number;
  accountDeletionMoreThanLimit: boolean;
  performanceMediaDeletionStaleCount: number;
  performanceMediaDeletionMoreThanLimit: boolean;
} {
  return {
    operationalSignal: "stale-deletion-jobs",
    accountDeletionStaleCount: summary.accountDeletionJobs.staleCount,
    accountDeletionMoreThanLimit: summary.accountDeletionJobs.moreThanLimit,
    performanceMediaDeletionStaleCount:
      summary.performanceMediaDeletionJobs.staleCount,
    performanceMediaDeletionMoreThanLimit:
      summary.performanceMediaDeletionJobs.moreThanLimit,
  };
}

export function firebaseOperationalStore(
  firestore: admin.firestore.Firestore,
): OperationalStore {
  return {
    listCleanupDrafts: async (createdAtOrBeforeMs, limit) => {
      const snapshot = await firestore
        .collection("performanceDrafts")
        .where("state", "in", ["awaiting_upload", "cleanup_pending"])
        .where(
          "createdAt",
          "<=",
          admin.firestore.Timestamp.fromMillis(createdAtOrBeforeMs),
        )
        .orderBy("createdAt", "asc")
        .limit(limit)
        .get();
      return snapshot.docs.map((document) => ({
        id: document.id,
        data: document.data(),
      }));
    },
    claimCleanupDraft: async (id, createdAtOrBeforeMs, updatedAtMs) => {
      const reference = firestore.collection("performanceDrafts").doc(id);
      return firestore.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(reference);
        if (!snapshot.exists) return null;
        const document = { id: snapshot.id, data: snapshot.data()! };
        if (!validCleanupDraft(document)) return null;
        const createdAt = document.data.createdAt as admin.firestore.Timestamp;
        if (createdAt.toMillis() > createdAtOrBeforeMs) return null;
        transaction.update(reference, {
          state: "cleanup_pending",
          updatedAt: admin.firestore.Timestamp.fromMillis(updatedAtMs),
        });
        return {
          id: document.id,
          data: {
            ...document.data,
            state: "cleanup_pending",
            updatedAt: admin.firestore.Timestamp.fromMillis(updatedAtMs),
          },
        };
      });
    },
    deleteClaimedDraft: async (id) => {
      const reference = firestore.collection("performanceDrafts").doc(id);
      return firestore.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(reference);
        if (!snapshot.exists) return true;
        const document = { id: snapshot.id, data: snapshot.data()! };
        if (!validCleanupDraft(document) || document.data.state !== "cleanup_pending") {
          return false;
        }
        transaction.delete(reference);
        return true;
      });
    },
    countStaleJobs: async (collection, updatedAtOrBeforeMs, limit) => {
      const snapshot = await firestore
        .collection(collection)
        .where(
          "updatedAt",
          "<=",
          admin.firestore.Timestamp.fromMillis(updatedAtOrBeforeMs),
        )
        .limit(limit)
        .get();
      return snapshot.size;
    },
  };
}
