import { CutoverEvidence, PAUSE_SURFACES, REPORT_CUTOVER_TARGETS } from "../../src/report_cutover";

// Synthetic evidence only. Never a production containment receipt.
export function repairEvidence(nowMs = Date.now()): CutoverEvidence {
  const sourceSha = "a".repeat(40);
  return {
    schemaVersion: 2, projectId: "chants-f95b4", sourceSha, generation: 4, mode: "maintenance",
    surfaces: PAUSE_SURFACES.map((surface) => ({ surface, evidenceRef: `synthetic/${surface}`,
      containmentStartedAt: new Date(nowMs - 61000).toISOString(),
      observedAt: new Date(nowMs - 1000).toISOString(), maximumRuntimeSeconds: 60,
      revisionsContained: true, alternatePathsContained: true, inFlightDrained: true, queuedDeliveryAccounted: true })),
    legacyTargetsIsolated: true,
    replacements: REPORT_CUTOVER_TARGETS.map((name) => ({ name, sourceSha, computeRegion: "europe-west2",
      eventLocation: "nam5", document: name === "onReportCreated" ? "reports/{reportId}" : "commentReports/{reportId}",
      eventType: "google.cloud.firestore.document.v1.written", active: true })),
    repairCoverage: { chants: false, comments: false }, readbackVerified: false, dependenciesVerified: false,
  };
}
