import { strict as assert } from "assert";
import { execFileSync } from "child_process";
import {
  chmodSync,
  mkdtempSync,
  mkdirSync,
  realpathSync,
  symlinkSync,
  writeFileSync,
} from "fs";
import { tmpdir } from "os";
import { join } from "path";
import {
  applyExactChantSeed,
  assertExactSeedAfterCreate,
  assertExactSeedBeforeCreate,
  buildExactChantSeedPlan,
  ExactSeedDocument,
  ExactSeedSnapshot,
  ExactSeedSource,
  exactCreateProjectionSha256,
  exactChantSeedPlanDigest,
  parseExactChantSeedPlan,
} from "./exact_chant_seed";
import {
  exactSeedCredential,
  exactSeedFailureMessage,
  parseExactSeedArguments,
  requireExactSeedSource,
  requirePrivateExactSeedPlanPath,
} from "./exact_chant_seed_cli";

const sourceSha = "a".repeat(40);
const sourceFileSha256 = "b".repeat(64);

function projection(title: string, teamId = "arsenal") {
  return {
    sportId: "football",
    competitionId: "premier-league",
    teamId,
    createdBy: "system",
    title,
    lyrics: `${title} short refrain`,
    tuneName: "Reviewed tune",
    contextNotes: "Reviewed context",
    subjectTag: "club",
    playerId: null,
    chantType: "sincere",
    mediaType: "none",
    coverImageUrl: null,
    mediaUrl: null,
    status: "canonical",
    variations: [],
    origin: "alreadySung",
    upvotes: 0,
    downvotes: 0,
    score: 0,
    commentCount: 0,
    flagCount: 0,
    hidden: false,
    removed: false,
  };
}

const existingDocument: ExactSeedDocument = {
  id: "arsenal-existing-chant",
  data: projection("Existing Chant"),
};
const targetDocument: ExactSeedDocument = {
  id: "arsenal-north-london-forever",
  data: projection("North London Forever"),
};

function source(): ExactSeedSource {
  return {
    clubFileName: "arsenal.json",
    clubFileSha256: sourceFileSha256,
    teamId: "arsenal",
    chantId: targetDocument.id,
    targetProjection: targetDocument.data,
    existingTeamChants: [existingDocument],
  };
}

function closedSnapshot(): ExactSeedSnapshot {
  return {
    control: {
      schemaVersion: 1,
      generation: 11,
      mode: "maintenance",
      destructiveWorkersEnabled: false,
    },
    totalChants: 192,
    teamChants: [existingDocument],
    target: null,
  };
}

function openSnapshot(): ExactSeedSnapshot {
  return {
    ...closedSnapshot(),
    control: {
      schemaVersion: 1,
      generation: 12,
      mode: "core",
      destructiveWorkersEnabled: false,
    },
  };
}

function completedSnapshot(): ExactSeedSnapshot {
  return {
    ...openSnapshot(),
    totalChants: 193,
    teamChants: [existingDocument, targetDocument],
    target: targetDocument,
  };
}

function plan() {
  return buildExactChantSeedPlan({
    sourceSha,
    source: source(),
    snapshot: closedSnapshot(),
    expectedGeneration: 11,
    expectedTotalChants: 192,
    expectedTeamChants: 1,
  });
}

describe("exact single-chant production seed", () => {
  it("builds one canonical maintenance-to-core plan", () => {
    const value = plan();
    assert.equal(value.chantId, "arsenal-north-london-forever");
    assert.equal(value.expected.control.generation, 11);
    assert.equal(value.requiredControl.generation, 12);
    assert.equal(value.requiredControl.mode, "core");
    assert.equal(value.expected.teamChants.length, 1);
    assert.equal(
      value.targetProjectionSha256,
      exactCreateProjectionSha256(targetDocument.data)
    );
    assert.match(exactChantSeedPlanDigest(value), /^[a-f0-9]{64}$/);
  });

  it("rejects unexpected plan fields, reordered inventory, and control widening", () => {
    const value = plan();
    assert.throws(
      () => parseExactChantSeedPlan({ ...value, widened: true }),
      /Unexpected exact-seed fields/
    );
    assert.throws(
      () =>
        parseExactChantSeedPlan({
          ...value,
          requiredControl: {
            ...value.requiredControl,
            destructiveWorkersEnabled: true,
          },
        }),
      /control transition differs/
    );
    const second = {
      id: "arsenal-second-chant",
      projectionSha256: "c".repeat(64),
    };
    assert.throws(
      () =>
        parseExactChantSeedPlan({
          ...value,
          expected: {
            ...value.expected,
            teamChants: [second, ...value.expected.teamChants],
          },
        }),
      /inventory must be sorted/
    );
  });

  it("stops planning on target, count, projection, or closed-control drift", () => {
    const base = {
      sourceSha,
      source: source(),
      expectedGeneration: 11,
      expectedTotalChants: 192,
      expectedTeamChants: 1,
    };
    assert.throws(
      () =>
        buildExactChantSeedPlan({
          ...base,
          snapshot: { ...closedSnapshot(), target: targetDocument },
        }),
      /target already exists/
    );
    assert.throws(
      () =>
        buildExactChantSeedPlan({
          ...base,
          snapshot: { ...closedSnapshot(), totalChants: 193 },
        }),
      /global chant count differs/
    );
    assert.throws(
      () =>
        buildExactChantSeedPlan({
          ...base,
          snapshot: {
            ...closedSnapshot(),
            teamChants: [
              { ...existingDocument, data: projection("Changed title") },
            ],
          },
        }),
      /team inventory differs/
    );
    assert.throws(
      () =>
        buildExactChantSeedPlan({
          ...base,
          snapshot: { ...closedSnapshot(), control: openSnapshot().control },
        }),
      /closed control baseline differs/
    );
  });

  it("rejects a same-title chant under a different identity", () => {
    const collision = {
      id: "arsenal-different-identity",
      data: projection("  NORTH LONDON   FOREVER "),
    };
    assert.throws(
      () =>
        buildExactChantSeedPlan({
          sourceSha,
          source: {
            ...source(),
            existingTeamChants: [collision],
          },
          snapshot: {
            ...closedSnapshot(),
            teamChants: [collision],
          },
          expectedGeneration: 11,
          expectedTotalChants: 192,
          expectedTeamChants: 1,
        }),
      /same-title collision/
    );
    assert.throws(
      () =>
        assertExactSeedBeforeCreate(plan(), source(), {
          ...openSnapshot(),
          totalChants: 193,
          teamChants: [existingDocument, collision],
        }),
      /same-title collision/
    );
  });

  it("creates only the bound target and verifies exact readback", async () => {
    const value = plan();
    const writes: Array<Record<string, unknown>> = [];
    let readbacks = 0;
    const result = await applyExactChantSeed({
      plan: value,
      approvedDigest: exactChantSeedPlanDigest(value),
      sourceSha,
      source: source(),
      createData: targetDocument.data,
      operations: {
        runTransaction: async (operation) => {
          await operation({
            readSnapshot: async () => openSnapshot(),
            createTarget: (data) => writes.push(data),
          });
        },
        readback: async () => {
          readbacks += 1;
          return completedSnapshot();
        },
      },
    });
    assert.equal(result, "created");
    assert.deepEqual(writes, [targetDocument.data]);
    assert.equal(readbacks, 1);
  });

  it("uses exact readback after an ambiguous acknowledgement", async () => {
    const value = plan();
    let writes = 0;
    const result = await applyExactChantSeed({
      plan: value,
      approvedDigest: exactChantSeedPlanDigest(value),
      sourceSha,
      source: source(),
      createData: targetDocument.data,
      operations: {
        runTransaction: async (operation) => {
          await operation({
            readSnapshot: async () => openSnapshot(),
            createTarget: () => {
              writes += 1;
            },
          });
          throw new Error("lost acknowledgement");
        },
        readback: async () => completedSnapshot(),
      },
    });
    assert.equal(result, "target-observed");
    assert.equal(writes, 1);
  });

  it("does not write on denial, repeated apply, digest drift, or source drift", async () => {
    const value = plan();
    let writes = 0;
    let readbacks = 0;
    const operations = {
      runTransaction: async (
        operation: Parameters<
          Parameters<typeof applyExactChantSeed>[0]["operations"]["runTransaction"]
        >[0]
      ) => {
        await operation({
          readSnapshot: async () => openSnapshot(),
          createTarget: () => {
            writes += 1;
          },
        });
      },
      readback: async () => {
        readbacks += 1;
        return completedSnapshot();
      },
    };
    await assert.rejects(
      applyExactChantSeed({
        plan: value,
        approvedDigest: "0".repeat(64),
        sourceSha,
        source: source(),
        createData: targetDocument.data,
        operations,
      }),
      /reviewed exact-seed plan differs/i
    );
    await assert.rejects(
      applyExactChantSeed({
        plan: value,
        approvedDigest: exactChantSeedPlanDigest(value),
        sourceSha,
        source: { ...source(), clubFileSha256: "f".repeat(64) },
        createData: targetDocument.data,
        operations,
      }),
      /source differs/
    );
    await assert.rejects(
      applyExactChantSeed({
        plan: value,
        approvedDigest: exactChantSeedPlanDigest(value),
        sourceSha,
        source: source(),
        createData: targetDocument.data,
        operations: {
          runTransaction: async () => {
            throw new Error("permission denied");
          },
          readback: operations.readback,
        },
      }),
      /stopped before create/
    );
    await assert.rejects(
      applyExactChantSeed({
        plan: value,
        approvedDigest: exactChantSeedPlanDigest(value),
        sourceSha,
        source: source(),
        createData: targetDocument.data,
        operations: {
          runTransaction: async (operation) => {
            await operation({
              readSnapshot: async () => completedSnapshot(),
              createTarget: () => {
                writes += 1;
              },
            });
          },
          readback: operations.readback,
        },
      }),
      /stopped before create/
    );
    assert.equal(writes, 0);
    assert.equal(readbacks, 0);
  });

  it("rejects post-create target, count, team, and control drift", () => {
    const value = plan();
    assert.throws(
      () =>
        assertExactSeedAfterCreate(value, source(), {
          ...completedSnapshot(),
          target: {
            ...targetDocument,
            data: projection("Wrong target"),
          },
        }),
      /target readback differs/
    );
    assert.throws(
      () =>
        assertExactSeedAfterCreate(value, source(), {
          ...completedSnapshot(),
          totalChants: 194,
        }),
      /global chant count differs/
    );
    assert.throws(
      () =>
        assertExactSeedAfterCreate(value, source(), {
          ...completedSnapshot(),
          teamChants: [
            existingDocument,
            targetDocument,
            { id: "arsenal-unexpected", data: projection("Unexpected") },
          ],
        }),
      /team inventory differs/
    );
    assert.throws(
      () =>
        assertExactSeedAfterCreate(value, source(), {
          ...completedSnapshot(),
          control: {
            schemaVersion: 1,
            generation: 13,
            mode: "maintenance",
            destructiveWorkersEnabled: false,
          },
        }),
      /control changed/
    );
  });
});

describe("exact seed CLI boundaries", () => {
  const common = [
    "--project",
    "chants-f95b4",
    "--source-sha",
    sourceSha,
    "--credential",
    "/private/credential.json",
    "--plan",
    "/private/plan.json",
  ];

  it("requires explicit plan scope and derives apply scope only from the plan", () => {
    assert.equal(
      parseExactSeedArguments([
        "plan",
        ...common,
        "--club",
        "arsenal.json",
        "--chant-id",
        "arsenal-north-london-forever",
        "--expected-generation",
        "11",
        "--expected-total-chants",
        "192",
        "--expected-team-chants",
        "12",
      ]).mode,
      "plan"
    );
    assert.equal(
      parseExactSeedArguments([
        "apply",
        ...common,
        "--digest",
        "d".repeat(64),
      ]).mode,
      "apply"
    );
    assert.throws(
      () =>
        parseExactSeedArguments([
          "apply",
          ...common,
          "--digest",
          "d".repeat(64),
          "--club",
          "arsenal.json",
        ]),
      /Unknown, duplicate, or missing/
    );
    assert.throws(
      () =>
        parseExactSeedArguments([
          "plan",
          ...common,
          "--club",
          "../arsenal.json",
          "--chant-id",
          "arsenal-north-london-forever",
          "--expected-generation",
          "11",
          "--expected-total-chants",
          "192",
          "--expected-team-chants",
          "12",
        ]),
      /plain club filename/
    );
  });

  it("preserves an actionable failure cause without a stack trace", () => {
    const message = exactSeedFailureMessage(
      new Error("Exact-seed team inventory differs.")
    );
    assert.match(message, /team inventory differs/);
    assert.match(message, /Do not infer success or retry/);
    assert.doesNotMatch(message, /exact_chant_seed_cli\.ts:/);
    assert.doesNotMatch(
      exactSeedFailureMessage(new Error("Denied.\nRetry detail.")),
      /\n/
    );
  });

  it("requires an exact clean committed source", () => {
    const root = mkdtempSync(join(tmpdir(), "chants-exact-seed-source-"));
    execFileSync("git", ["init", "-q"], { cwd: root });
    execFileSync("git", ["config", "user.email", "test@example.com"], {
      cwd: root,
    });
    execFileSync("git", ["config", "user.name", "Test"], { cwd: root });
    writeFileSync(join(root, "source.txt"), "reviewed\n");
    execFileSync("git", ["add", "source.txt"], { cwd: root });
    execFileSync("git", ["commit", "-qm", "reviewed"], { cwd: root });
    const head = execFileSync("git", ["rev-parse", "HEAD"], {
      cwd: root,
      encoding: "utf8",
    }).trim();
    assert.doesNotThrow(() => requireExactSeedSource(root, head));
    writeFileSync(join(root, "source.txt"), "dirty\n");
    assert.throws(
      () => requireExactSeedSource(root, head),
      /clean reviewed source/
    );
    assert.throws(
      () => requireExactSeedSource(root, "f".repeat(40)),
      /clean reviewed source/
    );
  });

  it("accepts only the exact Chants service-account shape", () => {
    const credential = {
      type: "service_account",
      project_id: "chants-f95b4",
      client_email: "seed@example.invalid",
      private_key: "private-key-placeholder",
    };
    assert.deepEqual(exactSeedCredential(credential), {
      projectId: "chants-f95b4",
      clientEmail: "seed@example.invalid",
      privateKey: "private-key-placeholder",
    });
    assert.throws(
      () => exactSeedCredential({ ...credential, project_id: "other" }),
      /project does not match/
    );
    assert.throws(
      () => exactSeedCredential({ ...credential, private_key: "" }),
      /credential identity differs/
    );
  });

  it("accepts only the real ignored private directory, not a symlink", () => {
    const root = realpathSync(
      mkdtempSync(join(tmpdir(), "chants-exact-seed-plan-"))
    );
    const privateDirectory = join(root, ".private-report-repair");
    mkdirSync(privateDirectory, { mode: 0o700 });
    chmodSync(privateDirectory, 0o700);
    assert.doesNotThrow(() =>
      requirePrivateExactSeedPlanPath(
        root,
        join(privateDirectory, "north-london-forever.json")
      )
    );
    chmodSync(privateDirectory, 0o755);
    assert.throws(
      () =>
        requirePrivateExactSeedPlanPath(
          root,
          join(privateDirectory, "north-london-forever.json")
        ),
      /ignored private directory/
    );
    chmodSync(privateDirectory, 0o700);
    const linkedRoot = realpathSync(
      mkdtempSync(join(tmpdir(), "chants-exact-seed-plan-link-"))
    );
    symlinkSync(privateDirectory, join(linkedRoot, ".private-report-repair"));
    assert.throws(
      () =>
        requirePrivateExactSeedPlanPath(
          linkedRoot,
          join(
            linkedRoot,
            ".private-report-repair",
            "north-london-forever.json"
          )
        ),
      /ignored private directory/
    );
  });
});
