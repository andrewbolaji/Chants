import { describe, it } from "mocha";
import * as assert from "assert";
import {
  accountDeletionDispatchDigest,
  parseAccountDeletionDispatchArguments,
  parseAccountDeletionDispatchPlan,
} from "../src/account_deletion_dispatch_cli";

const SOURCE = "a".repeat(40);
const DIGEST = "b".repeat(64);
const CREDENTIAL = "/private/credential.json";
const PLAN = "/private/plan.json";
const VERIFIED_AT = "2026-08-31T20:00:00.000Z";

function plan() {
  return {
    schemaVersion: 1,
    projectId: "chants-f95b4",
    sourceSha: SOURCE,
    actorUid: "operator",
    targetUid: "fan",
    caseReference: "CH-20260831-001",
    verificationMethod: "current-email-challenge",
    verificationCompletedAt: VERIFIED_AT,
  };
}

describe("account deletion dispatch CLI", () => {
  it("accepts one exact private plan and produces a stable digest", () => {
    const parsed = parseAccountDeletionDispatchPlan(plan());
    assert.deepStrictEqual(parsed, plan());
    assert.strictEqual(accountDeletionDispatchDigest(parsed).length, 64);
    assert.strictEqual(
      accountDeletionDispatchDigest({
        targetUid: "fan",
        actorUid: "operator",
        sourceSha: SOURCE,
        schemaVersion: 1,
        projectId: "chants-f95b4",
        verificationCompletedAt: VERIFIED_AT,
        verificationMethod: "current-email-challenge",
        caseReference: "CH-20260831-001",
      }),
      accountDeletionDispatchDigest(parsed)
    );
  });

  it("rejects target substitution, weak case IDs, and noncanonical time", () => {
    assert.throws(
      () => parseAccountDeletionDispatchPlan({ ...plan(), targetUid: "../fan" }),
      /identity/
    );
    assert.throws(
      () => parseAccountDeletionDispatchPlan({ ...plan(), actorUid: "fan" }),
      /in-app route/
    );
    assert.throws(
      () => parseAccountDeletionDispatchPlan({ ...plan(), caseReference: "case" }),
      /identity differs/
    );
    assert.throws(
      () => parseAccountDeletionDispatchPlan({
        ...plan(),
        verificationCompletedAt: "2026-08-31T20:00:00Z",
      }),
      /canonical UTC/
    );
  });

  it("plan requires every identity field and apply derives them from disk", () => {
    const common = [
      "--project", "chants-f95b4",
      "--source-sha", SOURCE,
      "--credential", CREDENTIAL,
      "--plan", PLAN,
    ];
    const planned = parseAccountDeletionDispatchArguments([
      "plan",
      ...common,
      "--operator-uid", "operator",
      "--target-uid", "fan",
      "--case", "CH-20260831-001",
      "--verification-method", "provider-reauth",
      "--verified-at", VERIFIED_AT,
    ]);
    assert.strictEqual(planned.mode, "plan");

    const applied = parseAccountDeletionDispatchArguments([
      "apply",
      ...common,
      "--digest", DIGEST,
    ]);
    assert.strictEqual(applied.mode, "apply");
    assert.throws(
      () => parseAccountDeletionDispatchArguments([
        "apply",
        ...common,
        "--digest", DIGEST,
        "--target-uid", "victim",
      ]),
      /reviewed plan/
    );
  });

  it("rejects an unknown verification method and unexpected plan fields", () => {
    assert.throws(
      () => parseAccountDeletionDispatchPlan({
        ...plan(),
        verificationMethod: "email-from-address",
      }),
      /identity differs/
    );
    assert.throws(
      () => parseAccountDeletionDispatchPlan({
        ...plan(),
        email: "private@example.com",
      }),
      /Unexpected dispatch fields/
    );
  });
});
