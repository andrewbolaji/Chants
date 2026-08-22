import * as assert from "assert";
import {
  isValidStoredEvidence,
  planChantTrustAction,
} from "../src/chant_trust";

const youtubeEvidence = {
  provider: "youtube",
  url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
};

const xEvidence = {
  provider: "x",
  url: "https://x.com/arsenal/status/1234567890",
};

describe("chant trust evidence", () => {
  it("accepts only canonical provider and URL pairs", () => {
    assert.strictEqual(isValidStoredEvidence(youtubeEvidence), true);
    assert.strictEqual(isValidStoredEvidence(xEvidence), true);
    assert.strictEqual(
      isValidStoredEvidence({
        provider: "youtube",
        url: "https://youtube.com.example.test/watch?v=dQw4w9WgXcQ",
      }),
      false
    );
    assert.strictEqual(
      isValidStoredEvidence({
        provider: "youtube",
        url: "https://youtu.be/dQw4w9WgXcQ",
      }),
      false
    );
    assert.strictEqual(
      isValidStoredEvidence({ ...youtubeEvidence, extra: "forged" }),
      false
    );
    assert.strictEqual(
      isValidStoredEvidence({ provider: "x", url: youtubeEvidence.url }),
      false
    );
    assert.strictEqual(
      isValidStoredEvidence({
        provider: "x",
        url: "https://x.com/arsenal/status/12345678901234567890123456",
      }),
      false
    );
  });

  it("rejects promotion of a user chant without valid evidence", () => {
    assert.throws(
      () =>
        planChantTrustAction("promote", {
          status: "community",
          createdBy: "user-1",
          evidence: null,
        }),
      /Valid YouTube or X evidence is required/
    );
    assert.throws(
      () =>
        planChantTrustAction("promote", {
          status: "community",
          createdBy: "user-1",
          evidence: {
            provider: "x",
            url: "https://x.com/arsenal",
          },
        }),
      /Valid YouTube or X evidence is required/
    );
  });

  it("plans promotion with valid retained evidence", () => {
    const plan = planChantTrustAction("promote", {
      status: "community",
      createdBy: "user-1",
      evidence: youtubeEvidence,
    });

    assert.strictEqual(plan.changed, true);
    assert.strictEqual(plan.nextStatus, "canonical");
    assert.strictEqual(plan.deleteEvidence, false);
  });

  it("allows a system-owned seed chant through the sourcing-ledger exception", () => {
    const plan = planChantTrustAction("promote", {
      status: "community",
      createdBy: "system",
    });
    assert.strictEqual(plan.nextStatus, "canonical");
  });

  it("rejects an invalid already-canonical user state", () => {
    assert.throws(
      () =>
        planChantTrustAction("promote", {
          status: "canonical",
          createdBy: "user-1",
        }),
      /Valid YouTube or X evidence is required/
    );
  });

  it("makes a valid repeated promotion idempotent", () => {
    const plan = planChantTrustAction("promote", {
      status: "canonical",
      createdBy: "user-1",
      evidence: xEvidence,
    });
    assert.strictEqual(plan.changed, false);
  });

  it("removes evidence and demotes a user-owned canonical chant", () => {
    const plan = planChantTrustAction("remove-evidence", {
      status: "canonical",
      createdBy: "user-1",
      evidence: xEvidence,
    });

    assert.strictEqual(plan.changed, true);
    assert.strictEqual(plan.deleteEvidence, true);
    assert.strictEqual(plan.nextStatus, "community");
  });

  it("removes system evidence without demoting the seed chant", () => {
    const plan = planChantTrustAction("remove-evidence", {
      status: "canonical",
      createdBy: "system",
      evidence: youtubeEvidence,
    });

    assert.strictEqual(plan.changed, true);
    assert.strictEqual(plan.deleteEvidence, true);
    assert.strictEqual(plan.nextStatus, undefined);
  });

  it("does not audit or write a missing evidence removal", () => {
    const plan = planChantTrustAction("remove-evidence", {
      status: "community",
      createdBy: "user-1",
    });
    assert.strictEqual(plan.changed, false);
    assert.strictEqual(plan.deleteEvidence, false);
  });
});
