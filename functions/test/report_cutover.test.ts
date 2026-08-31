import { strict as assert } from "assert";
import { assertRepairCutover, CutoverEvidence, PAUSE_SURFACES, REPORT_CUTOVER_TARGETS, reportCutoverNextStep, MAX_PAUSE_EVIDENCE_AGE_MS } from "../src/report_cutover";
import { repairEvidence } from "./fixtures/cutover";
import { parseRepairArguments } from "../src/report_repair_cli";
import { repairAudit, repairDigest, validateRepairPlan, REPAIR_BOUNDS } from "../src/report_repair";
import { auditRedactionForDeletedActor } from "../src/account_deletion";

const sha = "a".repeat(40);
const NOW_MS = Date.parse("2026-08-31T00:01:01Z");
function evidence(): CutoverEvidence {
  return { ...repairEvidence(NOW_MS), legacyTargetsIsolated: false, replacements: [] };
}
const nextStep = (value: CutoverEvidence) => reportCutoverNextStep(value, NOW_MS);
const assertReady = (value: CutoverEvidence, sourceSha: string, generation: number) =>
  assertRepairCutover(value, sourceSha, generation, NOW_MS);

describe("exact report cutover rehearsal", () => {
  it("stays closed through either missing replacement, then requires repair, readback and dependencies", () => {
    const state = evidence();
    assert.equal(nextStep(state), "isolate-old-targets");
    assert.throws(() => assertReady(state, sha, 4));
    state.legacyTargetsIsolated = true;
    for (const name of REPORT_CUTOVER_TARGETS) {
      assert.equal(nextStep(state), `replace-${name}`);
      assert.throws(() => assertReady(state, sha, 4));
      state.replacements.push({ name, sourceSha: sha, computeRegion: "europe-west2", eventLocation: "nam5",
        document: name === "onReportCreated" ? "reports/{reportId}" : "commentReports/{reportId}",
        eventType: "google.cloud.firestore.document.v1.written", active: true });
    }
    assert.equal(nextStep(state), "repair");
    assertReady(state, sha, 4);
    const saved = JSON.parse(JSON.stringify(state)) as CutoverEvidence;
    saved.replacements[0].eventType = "google.cloud.firestore.document.v1.created" as never;
    assert.equal(nextStep(saved), "replace-onReportCreated");
    state.repairCoverage = { chants: true, comments: true };
    assert.equal(nextStep(state), "readback");
    state.readbackVerified = true;
    assert.equal(nextStep(state), "verify-dependencies");
    state.dependenciesVerified = true;
    assert.equal(nextStep(state), "eligible-for-explicit-release");
    assert.equal(state.mode, "maintenance");
    assert.throws(() => assertReady(state, "b".repeat(40), 4));
    assert.throws(() => assertReady(state, sha, 5));
  });

  it("rejects incomplete containment rather than substituting a quiet-log timeout", () => {
    for (const surface of PAUSE_SURFACES) {
      const state = evidence();
      state.surfaces.find((row) => row.surface === surface)!.inFlightDrained = false;
      assert.throws(() => nextStep(state), /Pause evidence incomplete/);
    }
    const state = evidence(); state.mode = "core" as never;
    assert.throws(() => nextStep(state));
    state.mode = "maintenance"; state.surfaces.pop();
    assert.throws(() => nextStep(state));
  });

  it("rejects stale, future, undrained and invalid UTC evidence at an injected clock", () => {
    const fresh = repairEvidence(NOW_MS);
    assert.equal(reportCutoverNextStep(fresh, NOW_MS), "repair");
    const observed = Date.parse(fresh.surfaces[0].observedAt);
    assert.equal(reportCutoverNextStep(fresh, observed + MAX_PAUSE_EVIDENCE_AGE_MS), "repair");
    assert.throws(() => reportCutoverNextStep(fresh, observed + MAX_PAUSE_EVIDENCE_AGE_MS + 1), /stale/);
    for (const name of PAUSE_SURFACES) {
      for (const change of [
        { observedAt: "2000-01-01T00:00:00Z" }, { observedAt: "2099-01-01T00:00:00Z" },
        { observedAt: new Date(NOW_MS + 1).toISOString() },
        { containmentStartedAt: new Date(observed - 59999).toISOString() },
        { maximumRuntimeSeconds: 61 }, { observedAt: "2026-02-30T00:00:00Z" },
        { observedAt: "2026-08-31T00:01:00" }, { containmentStartedAt: "invalid" },
      ]) {
        const invalid = repairEvidence(NOW_MS);
        Object.assign(invalid.surfaces.find((row) => row.surface === name)!, change);
        assert.throws(() => reportCutoverNextStep(invalid, NOW_MS));
      }
    }
    assert.throws(() => reportCutoverNextStep({ ...fresh, schemaVersion: 1 } as never, NOW_MS));
    assert.throws(() => reportCutoverNextStep(fresh, NaN));
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
