import { isDeepStrictEqual } from "util";
import { CHANT_CONTENT_FIELDS } from "./seed_chant_data";

export type ProjectionState = "matching" | "mismatching" | "missing";

export interface ProjectionComparison {
  state: ProjectionState;
  mismatchedFields: string[];
}

export interface ReadbackDocument {
  id: string;
  data: Record<string, unknown>;
}

export const TEAM_READBACK_FIELDS = [
  "sportId",
  "competitionId",
  "name",
  "crestImageUrl",
];

export const PLAYER_READBACK_FIELDS = ["teamId", "name"];

export const CHANT_READBACK_FIELDS = [
  "sportId",
  "competitionId",
  "teamId",
  "createdBy",
  ...CHANT_CONTENT_FIELDS,
];

export function compareDocumentProjection(
  actual: Record<string, unknown> | undefined,
  expected: Record<string, unknown>,
  fields: string[]
): ProjectionComparison {
  if (!actual) {
    return { state: "missing", mismatchedFields: [] };
  }
  const mismatchedFields = fields.filter(
    (field) => !isDeepStrictEqual(actual[field], expected[field])
  );
  return {
    state: mismatchedFields.length === 0 ? "matching" : "mismatching",
    mismatchedFields,
  };
}

export function findUnexpectedDocumentIds(
  documents: ReadbackDocument[],
  expectedIds: Set<string>,
  include: (data: Record<string, unknown>) => boolean = () => true
): string[] {
  return documents
    .filter(
      (document) =>
        include(document.data) && !expectedIds.has(document.id)
    )
    .map((document) => document.id);
}

export function countReferencesById(
  documents: ReadbackDocument[],
  targetIds: string[],
  field: string
): Record<string, number> {
  const counts = Object.fromEntries(targetIds.map((id) => [id, 0]));
  for (const document of documents) {
    const targetId = document.data[field];
    if (typeof targetId === "string" && targetId in counts) {
      counts[targetId] += 1;
    }
  }
  return counts;
}

export function findReferencedTargetIds(
  referenceCounts: Record<string, number>
): Array<{ id: string; count: number }> {
  return Object.entries(referenceCounts)
    .filter(([, count]) => count > 0)
    .map(([id, count]) => ({ id, count }));
}
