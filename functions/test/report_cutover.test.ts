import { strict as assert } from "assert";
import { assertRepairCutover, CutoverEvidence, PAUSE_SURFACES, REPORT_CUTOVER_TARGETS, reportCutoverNextStep } from "../src/report_cutover";
import { parseRepairArguments } from "../src/report_repair_cli";
import { repairAudit, repairDigest, validateRepairPlan, REPAIR_BOUNDS } from "../src/report_repair";
import { auditRedactionForDeletedActor } from "../src/account_deletion";

const sha = "a".repeat(40);
function evidence(): CutoverEvidence {
  return {
    schemaVersion: 1, projectId: "chants-f95b4", sourceSha: sha, generation: 4, mode: "maintenance",
    surfaces: PAUSE_SURFACES.map((surface) => ({ surface, evidenceRef: `synthetic/${surface}`,
      observedAt: "2026-08-31T00:00:00Z", maximumRuntimeSeconds: 60, revisionsContained: true,
      alternatePathsContained: true, inFlightDrained: true, queuedDeliveryAccounted: true })),
    legacyTargetsIsolated: false, replacements: [], repairCoverage: { chants: false, comments: false },
    readbackVerified: false, dependenciesVerified: false,
  };
}

describe("exact report cutover rehearsal", () => {
  it("stays closed through either missing replacement, then requires repair, readback and dependencies", () => {
    const state = evidence();
    assert.equal(reportCutoverNextStep(state), "isolate-old-targets");
    assert.throws(() => assertRepairCutover(state, sha, 4));
    state.legacyTargetsIsolated = true;
    for (const name of REPORT_CUTOVER_TARGETS) {
      assert.equal(reportCutoverNextStep(state), `replace-${name}`);
      assert.throws(() => assertRepairCutover(state, sha, 4));
      state.replacements.push({ name, sourceSha: sha, computeRegion: "europe-west2", eventLocation: "nam5",
        document: name === "onReportCreated" ? "reports/{reportId}" : "commentReports/{reportId}",
        eventType: "google.cloud.firestore.document.v1.written", active: true });
    }
    assert.equal(reportCutoverNextStep(state), "repair");
    assertRepairCutover(state, sha, 4);
    const saved = JSON.parse(JSON.stringify(state)) as CutoverEvidence;
    saved.replacements[0].eventType = "google.cloud.firestore.document.v1.created" as never;
    assert.equal(reportCutoverNextStep(saved), "replace-onReportCreated");
    state.repairCoverage = { chants: true, comments: true };
    assert.equal(reportCutoverNextStep(state), "readback");
    state.readbackVerified = true;
    assert.equal(reportCutoverNextStep(state), "verify-dependencies");
    state.dependenciesVerified = true;
    assert.equal(reportCutoverNextStep(state), "eligible-for-explicit-release");
    assert.equal(state.mode, "maintenance");
    assert.throws(() => assertRepairCutover(state, "b".repeat(40), 4));
    assert.throws(() => assertRepairCutover(state, sha, 5));
  });

  it("rejects incomplete containment rather than substituting a quiet-log timeout", () => {
    for (const surface of PAUSE_SURFACES) {
      const state = evidence();
      state.surfaces.find((row) => row.surface === surface)!.inFlightDrained = false;
      assert.throws(() => reportCutoverNextStep(state), /Pause evidence incomplete/);
    }
    const state = evidence(); state.mode = "core" as never;
    assert.throws(() => reportCutoverNextStep(state));
    state.mode = "maintenance"; state.surfaces.pop();
    assert.throws(() => reportCutoverNextStep(state));
  });
});

describe("private repair command boundary", () => {
  const args = ["--project", "chants-f95b4", "--source-sha", sha, "--credential", "/private/credential.json",
    "--plan", "/private/page.json", "--cutover", "/private/cutover.json"];
  it("defaults to planning and requires a separate exact apply digest", () => {
    assert.equal(parseRepairArguments([...args, "--kind", "chants"]).mode, "plan");
    assert.equal(parseRepairArguments(["apply", ...args, "--digest", "a".repeat(64)]).mode, "apply");
    for (const bad of [[], ["apply", ...args], [...args, "--kind", "chants", "--force", "yes"],
      [...args, "--project", "other", "--kind", "chants"], [...args, "--kind", "comments", "--after", "../other"],
      [...args, "--kind", "chants", "--digest", "a".repeat(64)]]) assert.throws(() => parseRepairArguments(bad));
  });
  it("validates exact plan shape and keeps repair audit content out of retained personal detail", () => {
    const plan = { schemaVersion: 1 as const, projectId: "chants-f95b4" as const, sourceSha: sha, generation: 4,
      kind: "chants" as const, bounds: REPAIR_BOUNDS, startAfter: null, nextCursor: null, endOfCollection: true, targets: [] };
    validateRepairPlan(plan);
    assert.throws(() => validateRepairPlan({ ...plan, projectId: "other" }));
    assert.throws(() => validateRepairPlan({ ...plan, extra: true }));
    assert.throws(() => validateRepairPlan({ ...plan, bounds: { ...REPAIR_BOUNDS, parents: 26 } }));
    assert.equal(repairDigest(plan), repairDigest(JSON.parse(JSON.stringify(plan))));
    const audit = repairAudit(plan, "chant-1");
    assert.deepEqual(Object.keys(audit).sort(), ["action", "actorId", "detail", "targetId", "targetType"]);
    assert.equal(audit.actorId, "system");
    assert.equal(auditRedactionForDeletedActor(audit, "system").detail, "Details removed during account deletion.");
    assert(!/reporter|lyrics|reason|email/.test(JSON.stringify(audit)));
  });
});
