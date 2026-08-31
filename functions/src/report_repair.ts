import * as admin from "firebase-admin";
import { createHash } from "crypto";
import { parseOperationalControl } from "./operational_control";
import { pendingReportCount, reportAutoHide } from "./report_projection";

export const REPAIR_PROJECT = "chants-f95b4";
export const REPAIR_BOUNDS = Object.freeze({ parents: 25, reports: 500, visibleComments: 1000 } as const);
export type RepairKind = "chants" | "comments";
// Two comment repairs can share one parent counter. Keep a comment page to one
// target so its exact reviewed parent state cannot be invalidated by the same
// page's earlier write. Chants are independent and retain the 25-target ceiling.
function pageSize(kind: RepairKind): number { return kind === "comments" ? 1 : REPAIR_BOUNDS.parents; }
type Target = { id: string; before: string; after: string; reportFingerprint: string; parentFingerprint: string };
export type RepairPlan = {
  schemaVersion: 1;
  projectId: typeof REPAIR_PROJECT;
  sourceSha: string;
  generation: number;
  kind: RepairKind;
  bounds: typeof REPAIR_BOUNDS;
  startAfter: string | null;
  nextCursor: string | null;
  endOfCollection: boolean;
  targets: Target[];
};

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(",")}]`;
  if (value && typeof value === "object") {
    return `{${Object.entries(value).sort(([a], [b]) => a.localeCompare(b))
      .map(([key, item]) => `${JSON.stringify(key)}:${canonical(item)}`).join(",")}}`;
  }
  return JSON.stringify(value);
}
export function repairDigest(value: unknown): string {
  return createHash("sha256").update(canonical(value)).digest("hex");
}
function cleanId(value: unknown): value is string {
  return typeof value === "string" && /^[A-Za-z0-9_-]{1,200}$/.test(value);
}
function exactKeys(value: object, names: string[]): boolean {
  return Object.keys(value).sort().join(",") === names.sort().join(",");
}
function validateIdentity(projectId: string, sourceSha: string, kind: unknown): void {
  if (projectId !== REPAIR_PROJECT || !/^[a-f0-9]{40}$/.test(sourceSha) ||
      (kind !== "chants" && kind !== "comments")) throw new Error("Invalid repair identity or scope.");
}
export function validateRepairPlan(value: unknown): asserts value is RepairPlan {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("Invalid repair plan.");
  const plan = value as RepairPlan;
  if (!exactKeys(plan, ["schemaVersion", "projectId", "sourceSha", "generation", "kind", "bounds", "startAfter", "nextCursor", "endOfCollection", "targets"])) throw new Error("Unexpected repair plan fields.");
  validateIdentity(plan.projectId, plan.sourceSha, plan.kind);
  if (plan.schemaVersion !== 1 || !Number.isSafeInteger(plan.generation) || plan.generation < 1 ||
      repairDigest(plan.bounds) !== repairDigest(REPAIR_BOUNDS) ||
      (plan.startAfter !== null && !cleanId(plan.startAfter)) ||
      (plan.nextCursor !== null && !cleanId(plan.nextCursor)) ||
      typeof plan.endOfCollection !== "boolean" || !Array.isArray(plan.targets) || plan.targets.length > pageSize(plan.kind)) throw new Error("Invalid repair plan bounds.");
  let previous = plan.startAfter ?? "";
  for (const target of plan.targets) {
    if (!target || !exactKeys(target, ["id", "before", "after", "reportFingerprint", "parentFingerprint"]) ||
        !cleanId(target.id) || target.id <= previous ||
        ![target.before, target.after, target.reportFingerprint, target.parentFingerprint].every((hash) => /^[a-f0-9]{64}$/.test(hash))) throw new Error("Invalid repair target.");
    previous = target.id;
  }
  if (plan.nextCursor !== (plan.targets[plan.targets.length - 1]?.id ?? plan.startAfter) || plan.endOfCollection !== (plan.targets.length < pageSize(plan.kind))) throw new Error("Invalid repair cursor.");
}

async function requireMaintenance(
  db: admin.firestore.Firestore, transaction: admin.firestore.Transaction, generation?: number,
): Promise<number> {
  const control = parseOperationalControl((await transaction.get(db.collection("operationalControls").doc("v1"))).data());
  if (!control || control.mode !== "maintenance" || (generation !== undefined && control.generation !== generation)) throw new Error("Repair requires the exact maintenance generation.");
  return control.generation;
}

type Projection = {
  fingerprint: string;
  reportFingerprint: string;
  parentFingerprint: string;
  ref: admin.firestore.DocumentReference;
  parent: admin.firestore.DocumentReference | null;
  flagCount: number;
  autoHide: boolean;
  hidden: boolean;
  visibleCount: number | null;
  after: string;
};

async function readProjection(db: admin.firestore.Firestore, transaction: admin.firestore.Transaction, kind: RepairKind, id: string): Promise<Projection> {
  const ref = db.collection(kind).doc(id);
  const snapshot = await transaction.get(ref);
  const data = snapshot.data();
  if (!data || typeof data.hidden !== "boolean" || typeof data.removed !== "boolean" ||
      !Number.isSafeInteger(data.flagCount) || data.flagCount < 0 ||
      (kind === "comments" && !cleanId(data.chantId))) throw new Error("Missing or malformed repair target; no repair applied.");
  const field = kind === "chants" ? "chantId" : "commentId";
  const reports = await transaction.get(db.collection(kind === "chants" ? "reports" : "commentReports")
    .where(field, "==", id).limit(REPAIR_BOUNDS.reports + 1));
  if (reports.size > REPAIR_BOUNDS.reports) throw new Error("Report read bound exceeded; no partial count applied.");
  const reportRows = reports.docs.map((doc) => ({ id: doc.id, status: doc.data().status }));
  if (reportRows.some((row) => row.status !== "pending" && row.status !== "resolved")) throw new Error("Malformed report state; manual review required.");
  const flagCount = pendingReportCount(reportRows);
  const autoHide = reportAutoHide(flagCount, data.hidden);
  const parent = kind === "comments" ? db.collection("chants").doc(data.chantId) : null;
  let visibleCount: number | null = null;
  let parentFingerprint = repairDigest(null);
  let parentBeforeCount: number | null = null;
  if (parent) {
    const parentSnapshot = await transaction.get(parent);
    if (!parentSnapshot.exists) throw new Error("Comment parent is missing; manual review required.");
    parentBeforeCount = parentSnapshot.data()!.commentCount;
    if (!Number.isSafeInteger(parentBeforeCount) || parentBeforeCount! < 0) throw new Error("Malformed parent count.");
    const visible = await transaction.get(db.collection("comments").where("chantId", "==", parent.id)
      .where("hidden", "==", false).where("removed", "==", false).limit(REPAIR_BOUNDS.visibleComments + 1));
    if (visible.size > REPAIR_BOUNDS.visibleComments) throw new Error("Visible-comment read bound exceeded; no repair applied.");
    const ids = visible.docs.map((doc) => doc.id).sort();
    visibleCount = ids.length - (autoHide && ids.includes(id) ? 1 : 0);
    // Exclude the target: its own hide is already bound by before/after hashes.
    parentFingerprint = repairDigest({ id: parent.id, siblings: ids.filter((value) => value !== id) });
  }
  const state = { flagCount: data.flagCount, hidden: data.hidden, removed: data.removed, chantId: parent?.id ?? null, parentCount: parentBeforeCount };
  return {
    ref, parent, flagCount, autoHide, hidden: data.hidden, visibleCount,
    fingerprint: repairDigest(state),
    after: repairDigest({ ...state, flagCount, hidden: data.hidden || autoHide, parentCount: visibleCount }),
    reportFingerprint: repairDigest(reportRows.sort((a, b) => a.id.localeCompare(b.id))), parentFingerprint,
  };
}

export async function planReportRepair(params: {
  firestore: admin.firestore.Firestore; projectId: string; sourceSha: string; kind: RepairKind; startAfter?: string;
}): Promise<RepairPlan> {
  validateIdentity(params.projectId, params.sourceSha, params.kind);
  if (params.startAfter !== undefined && !cleanId(params.startAfter)) throw new Error("Invalid repair cursor.");
  const generation = await params.firestore.runTransaction((transaction) => requireMaintenance(params.firestore, transaction));
  let query = params.firestore.collection(params.kind).orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize(params.kind));
  if (params.startAfter) query = query.startAfter(params.startAfter);
  const page = await query.get();
  const targets: Target[] = [];
  for (const document of page.docs) {
    if (!cleanId(document.id)) throw new Error("Unsupported parent identity; manual review required.");
    const target = await params.firestore.runTransaction(async (transaction) => {
      await requireMaintenance(params.firestore, transaction, generation);
      const projection = await readProjection(params.firestore, transaction, params.kind, document.id);
      return { id: document.id, before: projection.fingerprint, after: projection.after,
        reportFingerprint: projection.reportFingerprint, parentFingerprint: projection.parentFingerprint };
    });
    targets.push(target);
  }
  return { schemaVersion: 1, projectId: REPAIR_PROJECT, sourceSha: params.sourceSha, generation,
    kind: params.kind, bounds: REPAIR_BOUNDS, startAfter: params.startAfter ?? null,
    nextCursor: targets[targets.length - 1]?.id ?? params.startAfter ?? null, endOfCollection: targets.length < pageSize(params.kind), targets };
}

export function repairAudit(plan: RepairPlan, targetId: string) {
  return { actorId: "system", action: "repair-report-count", targetType: plan.kind === "chants" ? "chant" : "comment",
    targetId, detail: "Pending report count reconstructed from stored report state." };
}

export async function applyReportRepair(params: {
  firestore: admin.firestore.Firestore; projectId: string; sourceSha: string; plan: unknown; digest: string;
  now: () => admin.firestore.Timestamp;
}): Promise<{ completed: number; nextCursor: string | null; endOfCollection: boolean }> {
  validateRepairPlan(params.plan);
  const plan = params.plan;
  validateIdentity(params.projectId, params.sourceSha, plan.kind);
  if (params.sourceSha !== plan.sourceSha || params.projectId !== plan.projectId || params.digest !== repairDigest(plan)) throw new Error("Repair plan identity or reviewed digest differs.");
  if (plan.targets.length === 0) {
    await params.firestore.runTransaction((transaction) => requireMaintenance(params.firestore, transaction, plan.generation));
  }
  let completed = 0;
  for (const target of plan.targets) {
    const key = `${params.digest}-${target.id}`;
    const progressRef = params.firestore.collection("reportRepairProgress").doc(key);
    const auditRef = params.firestore.collection("auditLog").doc(`report-repair-${key}`);
    await params.firestore.runTransaction(async (transaction) => {
      await requireMaintenance(params.firestore, transaction, plan.generation);
      const progress = await transaction.get(progressRef);
      const audit = await transaction.get(auditRef);
      const projection = await readProjection(params.firestore, transaction, plan.kind, target.id);
      if (projection.reportFingerprint !== target.reportFingerprint || projection.parentFingerprint !== target.parentFingerprint) throw new Error("Repair source changed; re-plan the remaining page.");
      if (progress.exists) {
        if (progress.data()?.digest !== params.digest || progress.data()?.after !== target.after ||
            !["applied", "complete"].includes(progress.data()?.state) ||
            !audit.exists || repairDigest({ ...audit.data(), createdAt: null }) !== repairDigest({ ...repairAudit(plan, target.id), createdAt: null }) ||
            projection.fingerprint !== target.after) throw new Error("Repair checkpoint or readback differs; stop and investigate.");
        return;
      }
      if (audit.exists || projection.fingerprint !== target.before || projection.after !== target.after) throw new Error("Stale repair target or unexpected audit.");
      transaction.update(projection.ref, { flagCount: projection.flagCount, ...(projection.autoHide ? { hidden: true } : {}) });
      if (projection.parent) transaction.update(projection.parent, { commentCount: projection.visibleCount });
      transaction.create(auditRef, { ...repairAudit(plan, target.id), createdAt: params.now() });
      transaction.create(progressRef, { digest: params.digest, after: target.after, state: "applied", updatedAt: params.now() });
    });
    // A separate transaction provides actual readback. Lost acknowledgement at
    // either commit resumes this same identity; audit creation never duplicates.
    await params.firestore.runTransaction(async (transaction) => {
      await requireMaintenance(params.firestore, transaction, plan.generation);
      const progress = await transaction.get(progressRef);
      const audit = await transaction.get(auditRef);
      const projection = await readProjection(params.firestore, transaction, plan.kind, target.id);
      if (!progress.exists || progress.data()?.digest !== params.digest || progress.data()?.after !== target.after ||
          !["applied", "complete"].includes(progress.data()?.state) ||
          !audit.exists || repairDigest({ ...audit.data(), createdAt: null }) !== repairDigest({ ...repairAudit(plan, target.id), createdAt: null }) ||
          projection.fingerprint !== target.after || projection.reportFingerprint !== target.reportFingerprint ||
          projection.parentFingerprint !== target.parentFingerprint) throw new Error("Repair readback failed; completion not acknowledged.");
      transaction.update(progressRef, { state: "complete", updatedAt: params.now() });
    });
    completed++;
  }
  return { completed, nextCursor: plan.nextCursor, endOfCollection: plan.endOfCollection };
}
