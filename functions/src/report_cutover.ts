// Evidence validator only. This module never deploys, deletes, changes traffic,
// or treats a source test as proof of live containment.
export const REPORT_CUTOVER_TARGETS = ["onReportCreated", "onCommentReportCreated"] as const;
export const PAUSE_SURFACES = [
  "client-rules", "onModerationAction", "deleteAccount", "mergeChants",
  "report-intake", "destructive-workers", "repository-admin", "external-admin", "legacy-report-events",
] as const;
export type PauseSurface = typeof PAUSE_SURFACES[number];
// A source-side re-observation ceiling, not a live containment guarantee.
export const MAX_PAUSE_EVIDENCE_AGE_MS = 15 * 60 * 1000;
export type PauseEvidence = {
  surface: PauseSurface;
  evidenceRef: string;
  containmentStartedAt: string;
  observedAt: string;
  maximumRuntimeSeconds: number;
  revisionsContained: boolean;
  alternatePathsContained: boolean;
  inFlightDrained: boolean;
  queuedDeliveryAccounted: boolean;
};
export type ReportInventory = {
  name: typeof REPORT_CUTOVER_TARGETS[number];
  computeRegion: "europe-west2";
  eventLocation: "nam5";
  document: "reports/{reportId}" | "commentReports/{reportId}";
  eventType: "google.cloud.firestore.document.v1.written";
  sourceSha: string;
  active: boolean;
};
export type CutoverEvidence = {
  schemaVersion: 2;
  projectId: "chants-f95b4";
  sourceSha: string;
  generation: number;
  mode: "maintenance";
  surfaces: PauseEvidence[];
  legacyTargetsIsolated: boolean;
  replacements: ReportInventory[];
  repairCoverage: { chants: boolean; comments: boolean };
  readbackVerified: boolean;
  dependenciesVerified: boolean;
};

function utcMillis(value: unknown): number {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$/.test(value)) return NaN;
  const time = Date.parse(value);
  const normalized = value.includes(".") ? value : value.replace("Z", ".000Z");
  return Number.isFinite(time) && new Date(time).toISOString() === normalized ? time : NaN;
}

export function assertPauseEvidence(value: CutoverEvidence, nowMs = Date.now()): void {
  if (!Number.isSafeInteger(nowMs) || !value || value.schemaVersion !== 2 || value.projectId !== "chants-f95b4" ||
      !/^[a-f0-9]{40}$/.test(value.sourceSha) || !Number.isSafeInteger(value.generation) || value.generation < 1 ||
      value.mode !== "maintenance" || !Array.isArray(value.surfaces) || value.surfaces.length !== PAUSE_SURFACES.length ||
      new Set(value.surfaces.map((surface) => surface?.surface)).size !== PAUSE_SURFACES.length) throw new Error("Incomplete cutover identity or pause evidence.");
  for (const name of PAUSE_SURFACES) {
    const evidence = value.surfaces.find((surface) => surface?.surface === name);
    if (!evidence || typeof evidence.evidenceRef !== "string" || evidence.evidenceRef.trim().length < 1 ||
        !Number.isFinite(utcMillis(evidence.observedAt)) || !Number.isFinite(utcMillis(evidence.containmentStartedAt)) ||
        !Number.isSafeInteger(evidence.maximumRuntimeSeconds) || evidence.maximumRuntimeSeconds < 1 ||
        evidence.revisionsContained !== true || evidence.alternatePathsContained !== true ||
        evidence.inFlightDrained !== true || evidence.queuedDeliveryAccounted !== true) throw new Error(`Pause evidence incomplete: ${name}.`);
    const observed = utcMillis(evidence.observedAt);
    const started = utcMillis(evidence.containmentStartedAt);
    if (observed > nowMs || nowMs - observed > MAX_PAUSE_EVIDENCE_AGE_MS ||
        (observed - started) / 1000 < evidence.maximumRuntimeSeconds) {
      throw new Error(`Pause evidence stale, future-dated or insufficiently drained: ${name}.`);
    }
  }
}

function verifiedReplacement(value: CutoverEvidence, name: typeof REPORT_CUTOVER_TARGETS[number]): boolean {
  if (!Array.isArray(value.replacements) || value.replacements.length > 2 ||
      value.replacements.some((row) => !REPORT_CUTOVER_TARGETS.includes(row.name)) ||
      new Set(value.replacements.map((row) => row.name)).size !== value.replacements.length) throw new Error("Unexpected replacement target.");
  const row = value.replacements.find((target) => target.name === name);
  return !!row && row.active === true && row.sourceSha === value.sourceSha &&
    row.computeRegion === "europe-west2" && row.eventLocation === "nam5" &&
    row.eventType === "google.cloud.firestore.document.v1.written" &&
    row.document === (name === "onReportCreated" ? "reports/{reportId}" : "commentReports/{reportId}");
}

export function reportCutoverNextStep(value: CutoverEvidence, nowMs = Date.now()): string {
  assertPauseEvidence(value, nowMs);
  if (value.legacyTargetsIsolated !== true) return "isolate-old-targets";
  for (const name of REPORT_CUTOVER_TARGETS) {
    if (!verifiedReplacement(value, name)) return `replace-${name}`;
  }
  if (value.repairCoverage?.chants !== true || value.repairCoverage?.comments !== true) return "repair";
  if (value.readbackVerified !== true) return "readback";
  if (value.dependenciesVerified !== true) return "verify-dependencies";
  return "eligible-for-explicit-release";
}

export function assertRepairCutover(value: CutoverEvidence, sourceSha: string, generation: number, nowMs = Date.now()): void {
  const next = reportCutoverNextStep(value, nowMs);
  if (value.sourceSha !== sourceSha || value.generation !== generation ||
      next === "isolate-old-targets" || next.startsWith("replace-")) throw new Error("Report cutover is not ready for repair.");
}
