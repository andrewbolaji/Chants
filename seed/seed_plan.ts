export type SeedPlanMode = "seed" | "preflight" | "readback";

export interface SeedArguments {
  mode: SeedPlanMode | "retireApprovedArsenalPlayers";
  clubFileNames: string[];
}

export function parseSeedArguments(args: string[]): SeedArguments {
  const modeFlags = [
    "--preflight-only",
    "--readback-only",
    "--retire-approved-arsenal-players",
  ].filter((flag) => args.includes(flag));
  if (modeFlags.length > 1) {
    throw new Error("Seed operation mode flags are mutually exclusive.");
  }
  const unknownFlags = args.filter(
    (arg) =>
      arg.startsWith("--") &&
      arg !== "--preflight-only" &&
      arg !== "--readback-only" &&
      arg !== "--retire-approved-arsenal-players"
  );
  if (unknownFlags.length > 0) {
    throw new Error(`Unknown seed option: ${unknownFlags.join(", ")}`);
  }

  const clubFileNames = args.filter((arg) => !arg.startsWith("--"));
  if (
    args.includes("--retire-approved-arsenal-players") &&
    clubFileNames.length > 0
  ) {
    throw new Error(
      "Approved Arsenal retirement does not accept club file arguments."
    );
  }

  return {
    mode: args.includes("--preflight-only")
      ? "preflight"
      : args.includes("--readback-only")
        ? "readback"
        : args.includes("--retire-approved-arsenal-players")
          ? "retireApprovedArsenalPlayers"
          : "seed",
    clubFileNames,
  };
}

interface SeedPlanOperations {
  preflightClub(filePath: string): Promise<void>;
  readbackFoundation(): Promise<boolean>;
  readbackClub(filePath: string): Promise<boolean>;
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
  mode: SeedPlanMode,
  operations: SeedPlanOperations
): Promise<"preflighted" | "readback" | "seeded"> {
  if (mode === "preflight") {
    for (const filePath of clubFiles) {
      await operations.preflightClub(filePath);
    }
    return "preflighted";
  }

  if (mode === "readback") {
    let exact = await operations.readbackFoundation();
    for (const filePath of clubFiles) {
      exact = (await operations.readbackClub(filePath)) && exact;
    }
    if (!exact) {
      throw new Error("Seed readback found missing or mismatching documents.");
    }
    return "readback";
  }

  const sportSlug = await operations.seedSport();
  const competitionSlug = await operations.seedCompetition(sportSlug);
  for (const filePath of clubFiles) {
    await operations.seedClub(filePath, sportSlug, competitionSlug);
  }
  return "seeded";
}
