export interface SeedArguments {
  preflightOnly: boolean;
  clubFileNames: string[];
}

export function parseSeedArguments(args: string[]): SeedArguments {
  const unknownFlags = args.filter(
    (arg) => arg.startsWith("--") && arg !== "--preflight-only"
  );
  if (unknownFlags.length > 0) {
    throw new Error(`Unknown seed option: ${unknownFlags.join(", ")}`);
  }

  return {
    preflightOnly: args.includes("--preflight-only"),
    clubFileNames: args.filter((arg) => !arg.startsWith("--")),
  };
}

interface SeedPlanOperations {
  preflightClub(filePath: string): Promise<void>;
  seedSport(): Promise<string>;
  seedCompetition(sportSlug: string): Promise<string>;
  seedClub(
    filePath: string,
    sportSlug: string,
    competitionSlug: string
  ): Promise<void>;
}

export async function executeSeedPlan(
  clubFiles: string[],
  preflightOnly: boolean,
  operations: SeedPlanOperations
): Promise<"preflighted" | "seeded"> {
  if (preflightOnly) {
    for (const filePath of clubFiles) {
      await operations.preflightClub(filePath);
    }
    return "preflighted";
  }

  const sportSlug = await operations.seedSport();
  const competitionSlug = await operations.seedCompetition(sportSlug);
  for (const filePath of clubFiles) {
    await operations.seedClub(filePath, sportSlug, competitionSlug);
  }
  return "seeded";
}
