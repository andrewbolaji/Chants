import * as admin from "firebase-admin";

type Data = admin.firestore.DocumentData;

export type PerformanceSourceState = {
  sourceChantVisible: boolean;
  sourceCreatorVisible: boolean;
};

function visibleFlag(data: Data | undefined): boolean {
  return !!data && data.hidden === false && data.removed === false;
}

export function currentCreatorSourceVisible(params: {
  account: Data | undefined;
  creator: Data | undefined;
  deletionJobExists: boolean;
}): boolean {
  return params.account?.banned === false &&
    params.account.deletionPending !== true &&
    !params.deletionJobExists &&
    visibleFlag(params.creator);
}

export function currentChantSourceVisible(chant: Data | undefined): boolean {
  return visibleFlag(chant) &&
    (chant?.status === "canonical" || chant?.status === "community");
}

export function performanceIsLive(data: Data | undefined): boolean {
  return !!data &&
    data.schemaVersion === 1 &&
    data.publicationState === "approved" &&
    data.hidden === false &&
    data.removed === false &&
    data.sourceChantVisible === true &&
    data.sourceCreatorVisible === true;
}

function visibilityChanged(before: Data | undefined, after: Data | undefined): boolean {
  return before?.creatorId !== after?.creatorId ||
    before?.publicationState !== after?.publicationState ||
    before?.hidden !== after?.hidden ||
    before?.removed !== after?.removed ||
    (!before && !!after) ||
    (!!before && !after);
}

export async function recomputeCreatorPerformanceCount(params: {
  creatorId: string;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
}): Promise<number> {
  if (!params.creatorId) return 0;
  const creatorRef = params.firestore
    .collection("creatorProfiles")
    .doc(params.creatorId);
  const creatorPerformancesQuery = params.firestore
    .collection("performances")
    .where("creatorId", "==", params.creatorId);

  return params.firestore.runTransaction(async (transaction) => {
    const [creatorSnapshot, performancesSnapshot] = await Promise.all([
      transaction.get(creatorRef),
      transaction.get(creatorPerformancesQuery),
    ]);
    if (!creatorSnapshot.exists) return 0;
    const performanceCount = performancesSnapshot.docs
      .filter((document) => performanceIsLive(document.data()))
      .length;
    transaction.update(creatorRef, {
      performanceCount,
      updatedAt: params.now(),
    });
    return performanceCount;
  });
}

export async function handlePerformanceVisibilityWritten(params: {
  before: Data | undefined;
  after: Data | undefined;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
}): Promise<boolean> {
  if (!visibilityChanged(params.before, params.after)) return false;
  const creatorIds = new Set<string>();
  for (const value of [params.before?.creatorId, params.after?.creatorId]) {
    if (typeof value === "string" && value) creatorIds.add(value);
  }
  for (const creatorId of creatorIds) {
    await recomputeCreatorPerformanceCount({
      creatorId,
      firestore: params.firestore,
      now: params.now,
    });
  }
  return creatorIds.size > 0;
}

export async function reconcileCreatorPerformanceSource(params: {
  creatorId: string;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
}): Promise<number> {
  const snapshots = await params.firestore
    .collection("performances")
    .where("creatorId", "==", params.creatorId)
    .get();
  const accountRef = params.firestore.collection("profiles").doc(params.creatorId);
  const creatorRef = params.firestore
    .collection("creatorProfiles")
    .doc(params.creatorId);
  const deletionRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.creatorId);
  for (const document of snapshots.docs) {
    await params.firestore.runTransaction(async (transaction) => {
      const [account, creator, deletion, performance] = await Promise.all([
        transaction.get(accountRef),
        transaction.get(creatorRef),
        transaction.get(deletionRef),
        transaction.get(document.ref),
      ]);
      if (!performance.exists) return;
      transaction.update(document.ref, {
        sourceCreatorVisible: currentCreatorSourceVisible({
          account: account.data(),
          creator: creator.data(),
          deletionJobExists: deletion.exists,
        }),
        updatedAt: params.now(),
      });
    });
  }
  await recomputeCreatorPerformanceCount({
    creatorId: params.creatorId,
    firestore: params.firestore,
    now: params.now,
  });
  return snapshots.size;
}

export async function reconcileChantPerformanceSource(params: {
  chantId: string;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
}): Promise<number> {
  const snapshots = await params.firestore
    .collection("performances")
    .where("chantId", "==", params.chantId)
    .get();
  const chantRef = params.firestore.collection("chants").doc(params.chantId);
  const creatorIds = new Set<string>();
  for (const document of snapshots.docs) {
    const creatorId = document.data().creatorId;
    if (typeof creatorId === "string" && creatorId) creatorIds.add(creatorId);
    await params.firestore.runTransaction(async (transaction) => {
      const [chant, performance] = await Promise.all([
        transaction.get(chantRef),
        transaction.get(document.ref),
      ]);
      if (!performance.exists) return;
      const chantData = chant.data();
      const update: admin.firestore.UpdateData<Data> = {
        sourceChantVisible: currentChantSourceVisible(chantData),
        updatedAt: params.now(),
      };
      if (typeof chantData?.title === "string") {
        update.chantTitle = chantData.title;
      }
      if (
        chantData?.status === "canonical" ||
        chantData?.status === "community"
      ) {
        update.chantStatus = chantData.status;
      }
      transaction.update(document.ref, update);
    });
  }
  for (const creatorId of creatorIds) {
    await recomputeCreatorPerformanceCount({
      creatorId,
      firestore: params.firestore,
      now: params.now,
    });
  }
  return snapshots.size;
}

export function chantSourceChanged(
  before: Data | undefined,
  after: Data | undefined,
): boolean {
  return before?.title !== after?.title ||
    before?.status !== after?.status ||
    before?.hidden !== after?.hidden ||
    before?.removed !== after?.removed;
}
