import { createHash } from "crypto";
import { isDeepStrictEqual } from "util";
import {
  OperationalControl,
  parseOperationalControl,
} from "../functions/src/operational_control";
import { CHANT_READBACK_FIELDS } from "./seed_readback";

export const EXACT_CHANT_SEED_PROJECT = "chants-f95b4";

export interface ExactSeedDocument {
  id: string;
  data: Record<string, unknown>;
}

export interface ExactSeedSnapshot {
  control: OperationalControl | null;
  totalChants: number;
  teamChants: ExactSeedDocument[];
  target: ExactSeedDocument | null;
}

export interface ExactSeedSource {
  clubFileName: string;
  clubFileSha256: string;
  teamId: string;
  chantId: string;
  targetProjection: Record<string, unknown>;
  existingTeamChants: ExactSeedDocument[];
}

interface InventoryEntry {
  id: string;
  projectionSha256: string;
}

export interface ExactChantSeedPlan {
  schemaVersion: 1;
  projectId: typeof EXACT_CHANT_SEED_PROJECT;
  sourceSha: string;
  clubFileName: string;
  clubFileSha256: string;
  teamId: string;
  chantId: string;
  targetProjectionSha256: string;
  expected: {
    control: OperationalControl;
    totalChants: number;
    teamChants: InventoryEntry[];
    targetExists: false;
  };
  requiredControl: OperationalControl;
}

function record(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Expected an exact object.");
  }
  return value as Record<string, unknown>;
}

function exact(value: Record<string, unknown>, keys: string[]): void {
  if (Object.keys(value).sort().join(",") !== [...keys].sort().join(",")) {
    throw new Error("Unexpected exact-seed fields.");
  }
}

function sha256(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function canonical(value: unknown): string {
  if (Array.isArray(value)) {
    return `[${value.map(canonical).join(",")}]`;
  }
  if (value && typeof value === "object") {
    const data = value as Record<string, unknown>;
    return `{${Object.keys(data)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${canonical(data[key])}`)
      .join(",")}}`;
  }
  const encoded = JSON.stringify(value);
  if (encoded === undefined) {
    throw new Error("Exact-seed projection contains an unsupported value.");
  }
  return encoded;
}

export function chantProjection(
  data: Record<string, unknown>
): Record<string, unknown> {
  return Object.fromEntries(
    CHANT_READBACK_FIELDS.map((field) => [field, data[field]])
  );
}

export function chantProjectionSha256(
  data: Record<string, unknown>
): string {
  return sha256(canonical(chantProjection(data)));
}

const EXACT_CREATE_FIELDS = [
  "title",
  "sportId",
  "competitionId",
  "teamId",
  "playerId",
  "subjectTag",
  "lyrics",
  "tuneName",
  "contextNotes",
  "coverImageUrl",
  "mediaUrl",
  "mediaType",
  "status",
  "chantType",
  "variations",
  "origin",
  "upvotes",
  "downvotes",
  "score",
  "commentCount",
  "createdBy",
  "flagCount",
  "hidden",
  "removed",
];

export function exactCreateProjectionSha256(
  data: Record<string, unknown>
): string {
  const projection = Object.fromEntries(
    EXACT_CREATE_FIELDS.map((field) => [field, data[field]])
  );
  return sha256(canonical(projection));
}

function inventory(documents: ExactSeedDocument[]): InventoryEntry[] {
  const ids = new Set<string>();
  const result = documents
    .map((document) => {
      if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(document.id)) {
        throw new Error("Invalid chant identity in exact-seed inventory.");
      }
      if (ids.has(document.id)) {
        throw new Error("Duplicate chant identity in exact-seed inventory.");
      }
      ids.add(document.id);
      return {
        id: document.id,
        projectionSha256: chantProjectionSha256(document.data),
      };
    })
    .sort((left, right) => left.id.localeCompare(right.id));
  return result;
}

function parseControl(value: unknown): OperationalControl {
  const parsed = parseOperationalControl(value);
  if (!parsed) {
    throw new Error("Invalid exact-seed operational control.");
  }
  return {
    schemaVersion: 1,
    generation: parsed.generation,
    mode: parsed.mode,
    destructiveWorkersEnabled: parsed.destructiveWorkersEnabled,
  };
}

function parseInventory(value: unknown): InventoryEntry[] {
  if (!Array.isArray(value)) {
    throw new Error("Invalid exact-seed team inventory.");
  }
  const parsed = value.map((entry) => {
    const data = record(entry);
    exact(data, ["id", "projectionSha256"]);
    if (
      typeof data.id !== "string" ||
      !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(data.id) ||
      typeof data.projectionSha256 !== "string" ||
      !/^[a-f0-9]{64}$/.test(data.projectionSha256)
    ) {
      throw new Error("Invalid exact-seed inventory entry.");
    }
    return {
      id: data.id,
      projectionSha256: data.projectionSha256,
    };
  });
  const sorted = [...parsed].sort((left, right) =>
    left.id.localeCompare(right.id)
  );
  if (!isDeepStrictEqual(parsed, sorted)) {
    throw new Error("Exact-seed inventory must be sorted.");
  }
  if (new Set(parsed.map((entry) => entry.id)).size !== parsed.length) {
    throw new Error("Exact-seed inventory identities must be unique.");
  }
  return parsed;
}

export function parseExactChantSeedPlan(
  value: unknown
): ExactChantSeedPlan {
  const data = record(value);
  exact(data, [
    "schemaVersion",
    "projectId",
    "sourceSha",
    "clubFileName",
    "clubFileSha256",
    "teamId",
    "chantId",
    "targetProjectionSha256",
    "expected",
    "requiredControl",
  ]);
  if (
    data.schemaVersion !== 1 ||
    data.projectId !== EXACT_CHANT_SEED_PROJECT ||
    typeof data.sourceSha !== "string" ||
    !/^[a-f0-9]{40}$/.test(data.sourceSha) ||
    typeof data.clubFileName !== "string" ||
    !/^[a-z0-9-]+\.json$/.test(data.clubFileName) ||
    typeof data.clubFileSha256 !== "string" ||
    !/^[a-f0-9]{64}$/.test(data.clubFileSha256) ||
    typeof data.teamId !== "string" ||
    !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(data.teamId) ||
    typeof data.chantId !== "string" ||
    !data.chantId.startsWith(`${data.teamId}-`) ||
    typeof data.targetProjectionSha256 !== "string" ||
    !/^[a-f0-9]{64}$/.test(data.targetProjectionSha256)
  ) {
    throw new Error("Exact-seed plan identity differs.");
  }

  const expectedData = record(data.expected);
  exact(expectedData, [
    "control",
    "totalChants",
    "teamChants",
    "targetExists",
  ]);
  if (
    !Number.isSafeInteger(expectedData.totalChants) ||
    (expectedData.totalChants as number) < 0 ||
    expectedData.targetExists !== false
  ) {
    throw new Error("Invalid exact-seed expected state.");
  }
  const expectedControl = parseControl(expectedData.control);
  const requiredControl = parseControl(data.requiredControl);
  const expectedTeamChants = parseInventory(expectedData.teamChants);
  if (
    expectedControl.mode !== "maintenance" ||
    expectedControl.destructiveWorkersEnabled ||
    requiredControl.generation !== expectedControl.generation + 1 ||
    requiredControl.mode !== "core" ||
    requiredControl.destructiveWorkersEnabled
  ) {
    throw new Error("Exact-seed control transition differs.");
  }
  if (expectedTeamChants.some((entry) => entry.id === data.chantId)) {
    throw new Error("Exact-seed target cannot exist in the baseline inventory.");
  }

  return {
    schemaVersion: 1,
    projectId: EXACT_CHANT_SEED_PROJECT,
    sourceSha: data.sourceSha,
    clubFileName: data.clubFileName,
    clubFileSha256: data.clubFileSha256,
    teamId: data.teamId,
    chantId: data.chantId,
    targetProjectionSha256: data.targetProjectionSha256,
    expected: {
      control: expectedControl,
      totalChants: expectedData.totalChants as number,
      teamChants: expectedTeamChants,
      targetExists: false,
    },
    requiredControl,
  };
}

export function exactChantSeedPlanDigest(value: unknown): string {
  return sha256(JSON.stringify(parseExactChantSeedPlan(value)));
}

function assertSourceMatchesPlan(
  plan: ExactChantSeedPlan,
  source: ExactSeedSource
): void {
  if (
    source.clubFileName !== plan.clubFileName ||
    source.clubFileSha256 !== plan.clubFileSha256 ||
    source.teamId !== plan.teamId ||
    source.chantId !== plan.chantId ||
    exactCreateProjectionSha256(source.targetProjection) !==
      plan.targetProjectionSha256 ||
    !isDeepStrictEqual(inventory(source.existingTeamChants), plan.expected.teamChants)
  ) {
    throw new Error("Exact-seed source differs from reviewed plan.");
  }
}

function sameControl(
  left: OperationalControl | null,
  right: OperationalControl
): boolean {
  return left !== null && isDeepStrictEqual(left, right);
}

function assertTargetAbsent(snapshot: ExactSeedSnapshot): void {
  if (snapshot.target !== null) {
    throw new Error("Exact-seed target already exists; plan is stale.");
  }
}

function assertTeamInventory(
  documents: ExactSeedDocument[],
  expected: InventoryEntry[]
): void {
  if (!isDeepStrictEqual(inventory(documents), expected)) {
    throw new Error("Exact-seed team inventory differs.");
  }
}

function normalizedTitle(data: Record<string, unknown>): string {
  if (typeof data.title !== "string" || data.title.trim() === "") {
    throw new Error("Invalid chant title in exact-seed inventory.");
  }
  return data.title.normalize("NFKC").trim().replace(/\s+/g, " ").toLowerCase();
}

function assertNoSameTitleCollision(
  source: ExactSeedSource,
  documents: ExactSeedDocument[]
): void {
  const targetTitle = normalizedTitle(source.targetProjection);
  if (
    documents.some(
      (document) =>
        document.id !== source.chantId &&
        normalizedTitle(document.data) === targetTitle
    )
  ) {
    throw new Error("Exact-seed same-title collision exists.");
  }
}

export function buildExactChantSeedPlan(options: {
  sourceSha: string;
  source: ExactSeedSource;
  snapshot: ExactSeedSnapshot;
  expectedGeneration: number;
  expectedTotalChants: number;
  expectedTeamChants: number;
}): ExactChantSeedPlan {
  const {
    sourceSha,
    source,
    snapshot,
    expectedGeneration,
    expectedTotalChants,
    expectedTeamChants,
  } = options;
  if (!/^[a-f0-9]{40}$/.test(sourceSha)) {
    throw new Error("Reviewed source SHA required.");
  }
  if (
    !snapshot.control ||
    snapshot.control.generation !== expectedGeneration ||
    snapshot.control.mode !== "maintenance" ||
    snapshot.control.destructiveWorkersEnabled
  ) {
    throw new Error("Exact-seed closed control baseline differs.");
  }
  assertNoSameTitleCollision(source, snapshot.teamChants);
  if (snapshot.totalChants !== expectedTotalChants) {
    throw new Error("Exact-seed global chant count differs.");
  }
  assertTargetAbsent(snapshot);
  const expectedInventory = inventory(source.existingTeamChants);
  if (
    expectedInventory.length !== expectedTeamChants ||
    snapshot.teamChants.length !== expectedTeamChants
  ) {
    throw new Error("Exact-seed team chant count differs.");
  }
  assertTeamInventory(snapshot.teamChants, expectedInventory);

  return parseExactChantSeedPlan({
    schemaVersion: 1,
    projectId: EXACT_CHANT_SEED_PROJECT,
    sourceSha,
    clubFileName: source.clubFileName,
    clubFileSha256: source.clubFileSha256,
    teamId: source.teamId,
    chantId: source.chantId,
    targetProjectionSha256: exactCreateProjectionSha256(
      source.targetProjection
    ),
    expected: {
      control: snapshot.control,
      totalChants: snapshot.totalChants,
      teamChants: expectedInventory,
      targetExists: false,
    },
    requiredControl: {
      schemaVersion: 1,
      generation: snapshot.control.generation + 1,
      mode: "core",
      destructiveWorkersEnabled: false,
    },
  });
}

export function assertExactSeedBeforeCreate(
  planValue: unknown,
  source: ExactSeedSource,
  snapshot: ExactSeedSnapshot
): ExactChantSeedPlan {
  const plan = parseExactChantSeedPlan(planValue);
  assertSourceMatchesPlan(plan, source);
  if (!sameControl(snapshot.control, plan.requiredControl)) {
    throw new Error("Exact-seed open control differs.");
  }
  assertNoSameTitleCollision(source, snapshot.teamChants);
  if (snapshot.totalChants !== plan.expected.totalChants) {
    throw new Error("Exact-seed global chant count changed before create.");
  }
  assertTargetAbsent(snapshot);
  assertTeamInventory(snapshot.teamChants, plan.expected.teamChants);
  return plan;
}

export function assertExactSeedAfterCreate(
  planValue: unknown,
  source: ExactSeedSource,
  snapshot: ExactSeedSnapshot
): void {
  const plan = parseExactChantSeedPlan(planValue);
  assertSourceMatchesPlan(plan, source);
  if (!sameControl(snapshot.control, plan.requiredControl)) {
    throw new Error("Exact-seed control changed before readback.");
  }
  if (snapshot.totalChants !== plan.expected.totalChants + 1) {
    throw new Error("Exact-seed global chant count differs after create.");
  }
  if (
    snapshot.target === null ||
    snapshot.target.id !== plan.chantId ||
    exactCreateProjectionSha256(snapshot.target.data) !==
      plan.targetProjectionSha256
  ) {
    throw new Error("Exact-seed target readback differs.");
  }
  const expectedInventory = [
    ...plan.expected.teamChants,
    {
      id: plan.chantId,
      projectionSha256: chantProjectionSha256(source.targetProjection),
    },
  ].sort((left, right) => left.id.localeCompare(right.id));
  assertTeamInventory(snapshot.teamChants, expectedInventory);
}

export interface ExactSeedTransaction {
  readSnapshot(): Promise<ExactSeedSnapshot>;
  createTarget(data: Record<string, unknown>): void;
}

export interface ExactSeedApplyOperations {
  runTransaction(
    operation: (transaction: ExactSeedTransaction) => Promise<void>
  ): Promise<void>;
  readback(): Promise<ExactSeedSnapshot>;
}

export async function applyExactChantSeed(options: {
  plan: unknown;
  approvedDigest: string;
  sourceSha: string;
  source: ExactSeedSource;
  createData: Record<string, unknown>;
  operations: ExactSeedApplyOperations;
}): Promise<"created" | "target-observed"> {
  const {
    plan: planValue,
    approvedDigest,
    sourceSha,
    source,
    createData,
    operations,
  } = options;
  const plan = parseExactChantSeedPlan(planValue);
  if (
    sourceSha !== plan.sourceSha ||
    !/^[a-f0-9]{64}$/.test(approvedDigest) ||
    exactChantSeedPlanDigest(plan) !== approvedDigest ||
    exactCreateProjectionSha256(createData) !== plan.targetProjectionSha256
  ) {
    throw new Error("Reviewed exact-seed plan differs.");
  }
  assertSourceMatchesPlan(plan, source);

  let reachedCreate = false;
  try {
    await operations.runTransaction(async (transaction) => {
      const before = await transaction.readSnapshot();
      assertExactSeedBeforeCreate(plan, source, before);
      reachedCreate = true;
      transaction.createTarget(createData);
    });
  } catch (_error) {
    if (!reachedCreate) {
      throw new Error(
        "Exact-seed transaction stopped before create; inspect current state."
      );
    }
    const observed = await operations.readback();
    assertExactSeedAfterCreate(plan, source, observed);
    return "target-observed";
  }

  const observed = await operations.readback();
  assertExactSeedAfterCreate(plan, source, observed);
  return "created";
}
