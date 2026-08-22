import { slugify } from "./slugify";

export const MAX_SEEDED_CHANT_ID_LENGTH = 120;

const SEEDED_CHANT_ID_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export interface SeededChantIdentity {
  id: string;
  title: string;
}

export interface ExistingChantIdentity {
  id: string;
  title: unknown;
  teamId: unknown;
  createdBy: unknown;
}

export type ChantIdentityConflictKind =
  | "target_not_system_owned"
  | "target_wrong_team"
  | "system_title_at_different_id";

export interface ChantIdentityConflict {
  kind: ChantIdentityConflictKind;
  seedId: string;
  existingId: string;
  message: string;
}

export class ChantIdentityConflictError extends Error {
  constructor(readonly conflict: ChantIdentityConflict) {
    super(conflict.message);
    this.name = "ChantIdentityConflictError";
  }
}

export function resolveSeededChantId(chant: SeededChantIdentity): string {
  return chant.id;
}

export function seededChantIdValidationError(
  id: unknown,
  teamSlug: string
): string | null {
  if (typeof id !== "string" || id.length === 0) {
    return "Seeded chant ID is required.";
  }
  if (id.length > MAX_SEEDED_CHANT_ID_LENGTH) {
    return `Seeded chant ID must be at most ${MAX_SEEDED_CHANT_ID_LENGTH} characters.`;
  }
  if (!SEEDED_CHANT_ID_PATTERN.test(id)) {
    return "Seeded chant ID must contain only lowercase letters, numbers, and single hyphens.";
  }
  if (!id.startsWith(`${teamSlug}-`)) {
    return `Seeded chant ID must start with the club prefix "${teamSlug}-".`;
  }
  return null;
}

function targetConflict(
  seedId: string,
  teamSlug: string,
  existing: ExistingChantIdentity
): ChantIdentityConflict | null {
  if (existing.createdBy !== "system") {
    return {
      kind: "target_not_system_owned",
      seedId,
      existingId: existing.id,
      message:
        `Seed chant ID "${seedId}" is occupied by a chant that is not system-owned. ` +
        "Choose another explicit ID or prepare an approved migration.",
    };
  }
  if (existing.teamId !== teamSlug) {
    return {
      kind: "target_wrong_team",
      seedId,
      existingId: existing.id,
      message:
        `Seed chant ID "${seedId}" belongs to another team. ` +
        "Correct the source ID or prepare an approved migration.",
    };
  }
  return null;
}

export function findChantIdentityConflicts(
  teamSlug: string,
  seeded: SeededChantIdentity[],
  existing: ExistingChantIdentity[]
): ChantIdentityConflict[] {
  const existingById = new Map(existing.map((chant) => [chant.id, chant]));
  const conflicts: ChantIdentityConflict[] = [];

  for (const seedChant of seeded) {
    const existingTarget = existingById.get(seedChant.id);
    if (existingTarget) {
      const conflict = targetConflict(seedChant.id, teamSlug, existingTarget);
      if (conflict) {
        conflicts.push(conflict);
        continue;
      }
    }

    const normalizedSeedTitle = slugify(seedChant.title);
    const titleCollision = existing.find(
      (chant) =>
        chant.id !== seedChant.id &&
        chant.createdBy === "system" &&
        chant.teamId === teamSlug &&
        typeof chant.title === "string" &&
        slugify(chant.title) === normalizedSeedTitle
    );
    if (titleCollision) {
      conflicts.push({
        kind: "system_title_at_different_id",
        seedId: seedChant.id,
        existingId: titleCollision.id,
        message:
          `Seed chant "${seedChant.id}" matches system chant "${titleCollision.id}" at another ID. ` +
          "Reconcile the IDs before seeding.",
      });
    }
  }

  return conflicts;
}

export interface SeedChantSnapshot {
  exists: boolean;
  data(): Record<string, unknown> | undefined;
}

export interface SeedChantTransaction<TReference> {
  get(reference: TReference): Promise<SeedChantSnapshot>;
  create(reference: TReference, data: Record<string, unknown>): void;
  update(reference: TReference, data: Record<string, unknown>): void;
}

export type SeededChantWriteResult = "created" | "updated";

export type RunSeedChantTransaction<TReference> = (
  operation: (
    transaction: SeedChantTransaction<TReference>
  ) => Promise<SeededChantWriteResult>
) => Promise<SeededChantWriteResult>;

interface UpsertSeededChantOptions<TReference> {
  runTransaction: RunSeedChantTransaction<TReference>;
  reference: TReference;
  referenceId: string;
  teamSlug: string;
  fullData: Record<string, unknown>;
  contentFields: string[];
  updatedAtValue: unknown;
}

export async function upsertSeededChantInTransaction<TReference>({
  runTransaction,
  reference,
  referenceId,
  teamSlug,
  fullData,
  contentFields,
  updatedAtValue,
}: UpsertSeededChantOptions<TReference>): Promise<SeededChantWriteResult> {
  return runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (!snapshot.exists) {
      transaction.create(reference, fullData);
      return "created";
    }

    const data = snapshot.data() ?? {};
    const conflict = targetConflict(referenceId, teamSlug, {
      id: referenceId,
      title: data.title,
      teamId: data.teamId,
      createdBy: data.createdBy,
    });
    if (conflict) {
      throw new ChantIdentityConflictError(conflict);
    }

    const update: Record<string, unknown> = {};
    for (const field of contentFields) {
      if (field in fullData) {
        update[field] = fullData[field];
      }
    }
    update.updatedAt = updatedAtValue;
    transaction.update(reference, update);
    return "updated";
  });
}
