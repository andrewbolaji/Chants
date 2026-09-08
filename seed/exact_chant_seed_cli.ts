import * as admin from "firebase-admin";
import { createHash } from "crypto";
import { execFileSync } from "child_process";
import {
  existsSync,
  lstatSync,
  readFileSync,
  realpathSync,
  writeFileSync,
} from "fs";
import { basename, dirname, isAbsolute, resolve, sep } from "path";
import {
  applyExactChantSeed,
  buildExactChantSeedPlan,
  ExactChantSeedPlan,
  ExactSeedDocument,
  ExactSeedSnapshot,
  ExactSeedSource,
  exactChantSeedPlanDigest,
  EXACT_CHANT_SEED_PROJECT,
  parseExactChantSeedPlan,
} from "./exact_chant_seed";
import { buildSeededChantData } from "./seed_chant_data";
import { resolveSeededChantId } from "./chant_identity";
import { compositeSlug, slugify } from "./slugify";
import {
  ClubData,
  validateClub,
  validateCompetition,
  validateSport,
} from "./validate";
import { assertServiceAccountProject } from "./seed_credential";
import { parseOperationalControl } from "../functions/src/operational_control";

type Mode = "plan" | "apply";

interface ParsedArguments {
  mode: Mode;
  values: Record<string, string>;
}

const commonOptions = [
  "--project",
  "--source-sha",
  "--credential",
  "--plan",
];
const planOptions = [
  "--club",
  "--chant-id",
  "--expected-generation",
  "--expected-total-chants",
  "--expected-team-chants",
];

function parsePositiveInteger(value: string | undefined, label: string): number {
  if (!value || !/^[1-9][0-9]*$/.test(value)) {
    throw new Error(`${label} must be an explicit positive integer.`);
  }
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed)) {
    throw new Error(`${label} is outside the safe integer range.`);
  }
  return parsed;
}

export function parseExactSeedArguments(args: string[]): ParsedArguments {
  const mode = args[0];
  if (mode !== "plan" && mode !== "apply") {
    throw new Error("Exact seed requires plan or apply.");
  }
  const allowed = new Set([
    ...commonOptions,
    ...(mode === "plan" ? planOptions : ["--digest"]),
  ]);
  const values: Record<string, string> = {};
  const rest = args.slice(1);
  if (rest.length % 2 !== 0) {
    throw new Error("Exact seed options require values.");
  }
  for (let index = 0; index < rest.length; index += 2) {
    const key = rest[index];
    const value = rest[index + 1];
    if (
      !allowed.has(key) ||
      values[key] !== undefined ||
      !value ||
      value.startsWith("--")
    ) {
      throw new Error("Unknown, duplicate, or missing exact-seed option.");
    }
    values[key] = value;
  }
  for (const key of commonOptions) {
    if (!values[key]) {
      throw new Error(`Exact seed requires ${key}.`);
    }
  }
  if (
    values["--project"] !== EXACT_CHANT_SEED_PROJECT ||
    !/^[a-f0-9]{40}$/.test(values["--source-sha"]) ||
    !isAbsolute(values["--credential"]) ||
    !isAbsolute(values["--plan"])
  ) {
    throw new Error("Exact seed project, source, or private path differs.");
  }
  if (mode === "plan") {
    if (!/^[a-z0-9-]+\.json$/.test(values["--club"] ?? "")) {
      throw new Error("Exact seed requires one plain club filename.");
    }
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(values["--chant-id"] ?? "")) {
      throw new Error("Exact seed requires one stable chant ID.");
    }
    parsePositiveInteger(values["--expected-generation"], "generation");
    parsePositiveInteger(
      values["--expected-total-chants"],
      "total chant count"
    );
    parsePositiveInteger(
      values["--expected-team-chants"],
      "team chant count"
    );
  } else if (!/^[a-f0-9]{64}$/.test(values["--digest"] ?? "")) {
    throw new Error("Exact seed apply requires the reviewed digest.");
  }
  return { mode, values };
}

export function requireExactSeedSource(
  root: string,
  sourceSha: string
): void {
  const head = execFileSync("git", ["rev-parse", "HEAD"], {
    cwd: root,
    encoding: "utf8",
  }).trim();
  const status = execFileSync("git", ["status", "--porcelain"], {
    cwd: root,
    encoding: "utf8",
  }).trim();
  if (head !== sourceSha || status) {
    throw new Error("Exact seed needs the clean reviewed source checkout.");
  }
}

function readOwnerOnlyJson(path: string): unknown {
  const stat = lstatSync(path);
  if (
    !stat.isFile() ||
    stat.isSymbolicLink() ||
    (stat.mode & 0o077) !== 0 ||
    stat.size > 1024 * 1024
  ) {
    throw new Error(
      "Expected an owner-only regular JSON file, at most 1 MiB."
    );
  }
  return JSON.parse(readFileSync(path, "utf8"));
}

export function requirePrivateExactSeedPlanPath(
  root: string,
  path: string
): void {
  const privateRoot = resolve(root, ".private-report-repair");
  const privateRootStat = existsSync(privateRoot)
    ? lstatSync(privateRoot)
    : null;
  if (
    !isAbsolute(path) ||
    dirname(path) !== privateRoot ||
    !existsSync(privateRoot) ||
    !privateRootStat?.isDirectory() ||
    privateRootStat.isSymbolicLink() ||
    (privateRootStat.mode & 0o077) !== 0 ||
    realpathSync(privateRoot) !== privateRoot ||
    !path.startsWith(`${privateRoot}${sep}`)
  ) {
    throw new Error(
      "Exact-seed plans belong directly in the ignored private directory."
    );
  }
}

function fileSha256(path: string): string {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

function loadSource(
  root: string,
  clubFileName: string,
  chantId: string
): { source: ExactSeedSource; createData: Record<string, unknown> } {
  const clubPath = resolve(root, "seed_data/clubs", clubFileName);
  if (
    basename(clubPath) !== clubFileName ||
    dirname(clubPath) !== resolve(root, "seed_data/clubs") ||
    !existsSync(clubPath)
  ) {
    throw new Error("Exact-seed club source is unavailable.");
  }
  const raw = JSON.parse(readFileSync(clubPath, "utf8")) as ClubData;
  const teamId = slugify(raw.team.name);
  const clubErrors = validateClub(raw, teamId);
  const sport = JSON.parse(
    readFileSync(resolve(root, "seed_data/sport.json"), "utf8")
  ) as Record<string, unknown>;
  const competition = JSON.parse(
    readFileSync(resolve(root, "seed_data/competition.json"), "utf8")
  ) as Record<string, unknown>;
  if (
    clubErrors.length > 0 ||
    validateSport(sport).length > 0 ||
    validateCompetition(competition).length > 0
  ) {
    throw new Error("Exact-seed source validation failed.");
  }
  const target = raw.chants.find(
    (chant) => resolveSeededChantId(chant) === chantId
  );
  if (!target) {
    throw new Error("Exact-seed target is absent from reviewed source.");
  }
  const sportId = slugify(sport.name as string);
  const competitionId = slugify(competition.name as string);
  const projectionFor = (chant: (typeof raw.chants)[number]) =>
    buildSeededChantData({
      chant,
      sportSlug: sportId,
      competitionSlug: competitionId,
      teamSlug: teamId,
      playerId: chant.playerName
        ? compositeSlug(teamId, chant.playerName)
        : null,
      timestamp: null,
    });
  const targetProjection = projectionFor(target);
  const source: ExactSeedSource = {
    clubFileName,
    clubFileSha256: fileSha256(clubPath),
    teamId,
    chantId,
    targetProjection,
    existingTeamChants: raw.chants
      .filter((chant) => resolveSeededChantId(chant) !== chantId)
      .map((chant) => ({
        id: resolveSeededChantId(chant),
        data: projectionFor(chant),
      })),
  };
  const timestamp = admin.firestore.FieldValue.serverTimestamp();
  return {
    source,
    createData: buildSeededChantData({
      chant: target,
      sportSlug: sportId,
      competitionSlug: competitionId,
      teamSlug: teamId,
      playerId: target.playerName
        ? compositeSlug(teamId, target.playerName)
        : null,
      timestamp,
    }),
  };
}

function document(
  snapshot: admin.firestore.DocumentSnapshot
): ExactSeedDocument {
  return { id: snapshot.id, data: snapshot.data() ?? {} };
}

async function readSnapshot(
  firestore: admin.firestore.Firestore,
  teamId: string,
  chantId: string
): Promise<ExactSeedSnapshot> {
  const controlReference = firestore.doc("operationalControls/v1");
  const targetReference = firestore.collection("chants").doc(chantId);
  const teamQuery = firestore
    .collection("chants")
    .where("teamId", "==", teamId);
  const [controlSnapshot, totalSnapshot, teamSnapshot, targetSnapshot] =
    await Promise.all([
      controlReference.get(),
      firestore.collection("chants").count().get(),
      teamQuery.get(),
      targetReference.get(),
    ]);
  return {
    control: parseOperationalControl(controlSnapshot.data()),
    totalChants: totalSnapshot.data().count,
    teamChants: teamSnapshot.docs.map(document),
    target: targetSnapshot.exists ? document(targetSnapshot) : null,
  };
}

export function exactSeedCredential(value: unknown): admin.ServiceAccount {
  assertServiceAccountProject(value, EXACT_CHANT_SEED_PROJECT);
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Exact-seed credential identity differs.");
  }
  const credential = value as Record<string, unknown>;
  if (
    credential.type !== "service_account" ||
    typeof credential.client_email !== "string" ||
    !credential.client_email ||
    typeof credential.private_key !== "string" ||
    !credential.private_key
  ) {
    throw new Error("Exact-seed credential identity differs.");
  }
  return {
    projectId: EXACT_CHANT_SEED_PROJECT,
    clientEmail: credential.client_email,
    privateKey: credential.private_key,
  };
}

function initializeFirestore(
  credentialPath: string
): { app: admin.app.App; firestore: admin.firestore.Firestore } {
  const credential = exactSeedCredential(readOwnerOnlyJson(credentialPath));
  const app = admin.initializeApp(
    {
      projectId: EXACT_CHANT_SEED_PROJECT,
      credential: admin.credential.cert(credential),
    },
    "exact-chant-seed-cli"
  );
  return { app, firestore: app.firestore() };
}

async function runPlan(
  root: string,
  values: Record<string, string>,
  firestore: admin.firestore.Firestore
): Promise<void> {
  const { source } = loadSource(
    root,
    values["--club"],
    values["--chant-id"]
  );
  const snapshot = await readSnapshot(firestore, source.teamId, source.chantId);
  const plan = buildExactChantSeedPlan({
    sourceSha: values["--source-sha"],
    source,
    snapshot,
    expectedGeneration: parsePositiveInteger(
      values["--expected-generation"],
      "generation"
    ),
    expectedTotalChants: parsePositiveInteger(
      values["--expected-total-chants"],
      "total chant count"
    ),
    expectedTeamChants: parsePositiveInteger(
      values["--expected-team-chants"],
      "team chant count"
    ),
  });
  writeFileSync(values["--plan"], `${JSON.stringify(plan, null, 2)}\n`, {
    flag: "wx",
    mode: 0o600,
  });
  console.log(
    JSON.stringify({
      mode: "plan",
      projectId: plan.projectId,
      sourceSha: plan.sourceSha,
      target: plan.chantId,
      expectedGeneration: plan.expected.control.generation,
      requiredGeneration: plan.requiredControl.generation,
      expectedTotalChants: plan.expected.totalChants,
      expectedTeamChants: plan.expected.teamChants.length,
      digest: exactChantSeedPlanDigest(plan),
    })
  );
}

async function transactionSnapshot(
  transaction: admin.firestore.Transaction,
  firestore: admin.firestore.Firestore,
  plan: ExactChantSeedPlan
): Promise<ExactSeedSnapshot> {
  const controlReference = firestore.doc("operationalControls/v1");
  const targetReference = firestore.collection("chants").doc(plan.chantId);
  const teamQuery = firestore
    .collection("chants")
    .where("teamId", "==", plan.teamId);
  const [controlSnapshot, totalSnapshot, teamSnapshot, targetSnapshot] =
    await Promise.all([
    transaction.get(controlReference),
    transaction.get(firestore.collection("chants").count()),
    transaction.get(teamQuery),
    transaction.get(targetReference),
  ]);
  return {
    control: parseOperationalControl(controlSnapshot.data()),
    totalChants: totalSnapshot.data().count,
    teamChants: teamSnapshot.docs.map(document),
    target: targetSnapshot.exists ? document(targetSnapshot) : null,
  };
}

async function runApply(
  root: string,
  values: Record<string, string>,
  firestore: admin.firestore.Firestore
): Promise<void> {
  const planValue = readOwnerOnlyJson(values["--plan"]);
  const plan = parseExactChantSeedPlan(planValue);
  const { source, createData } = loadSource(
    root,
    plan.clubFileName,
    plan.chantId
  );
  const targetReference = firestore.collection("chants").doc(plan.chantId);
  const result = await applyExactChantSeed({
    plan,
    approvedDigest: values["--digest"],
    sourceSha: values["--source-sha"],
    source,
    createData,
    operations: {
      runTransaction: (operation) =>
        firestore.runTransaction(
          async (transaction) => {
            await operation({
              readSnapshot: () =>
                transactionSnapshot(transaction, firestore, plan),
              createTarget: (data) => {
                transaction.create(targetReference, data);
              },
            });
          },
          { maxAttempts: 3 }
        ),
      readback: () => readSnapshot(firestore, plan.teamId, plan.chantId),
    },
  });
  console.log(
    JSON.stringify({
      mode: "apply",
      result,
      projectId: plan.projectId,
      sourceSha: plan.sourceSha,
      target: plan.chantId,
      totalChants: plan.expected.totalChants + 1,
      teamChants: plan.expected.teamChants.length + 1,
    })
  );
}

async function main(args: string[]): Promise<void> {
  const { mode, values } = parseExactSeedArguments(args);
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("Exact production seed refuses emulator redirection.");
  }
  const root = resolve(__dirname, "..");
  requireExactSeedSource(root, values["--source-sha"]);
  requirePrivateExactSeedPlanPath(root, values["--plan"]);
  let plan: ExactChantSeedPlan | undefined;
  if (mode === "apply") {
    plan = parseExactChantSeedPlan(readOwnerOnlyJson(values["--plan"]));
    if (
      plan.sourceSha !== values["--source-sha"] ||
      exactChantSeedPlanDigest(plan) !== values["--digest"]
    ) {
      throw new Error("Reviewed exact-seed plan differs.");
    }
  }
  const { app, firestore } = initializeFirestore(values["--credential"]);
  try {
    if (mode === "plan") {
      await runPlan(root, values, firestore);
    } else {
      await runApply(root, values, firestore);
    }
  } finally {
    await app.delete();
  }
}

export function exactSeedFailureMessage(error: unknown): string {
  const rawReason =
    error instanceof Error && error.message.trim() !== ""
      ? error.message.trim()
      : "Unknown failure.";
  const reason = rawReason.replace(/\s+/g, " ").slice(0, 300);
  return `Exact seed stopped: ${reason} Do not infer success or retry; inspect the reviewed plan, target, and control.`;
}

if (require.main === module) {
  main(process.argv.slice(2)).catch((error: unknown) => {
    console.error(exactSeedFailureMessage(error));
    process.exitCode = 1;
  });
}
