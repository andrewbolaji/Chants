import { readFileSync } from "fs";
import { resolve } from "path";
import {
  compareRosterCurrentness,
  FplBootstrap,
} from "./roster_currentness";

function main(): void {
  const inputPath = process.argv[2];
  if (!inputPath) {
    throw new Error(
      "Usage: npm run roster:check -- /absolute/path/to/bootstrap-static.json"
    );
  }

  const bootstrap = JSON.parse(
    readFileSync(resolve(inputPath), "utf8")
  ) as FplBootstrap;
  const snapshot = JSON.parse(
    readFileSync(
      resolve(__dirname, "../seed_data/rosters/fpl-2026-08-30.json"),
      "utf8"
    )
  ) as { clubs: Record<string, string[]> };
  const arsenal = JSON.parse(
    readFileSync(
      resolve(__dirname, "../seed_data/clubs/arsenal.json"),
      "utf8"
    )
  ) as { squad: Array<{ name: string }> };
  const expectedClubs: Record<string, string[]> = {
    arsenal: arsenal.squad.map((player) => player.name),
    ...snapshot.clubs,
  };
  const result = compareRosterCurrentness(bootstrap, expectedClubs);

  console.log(
    `Roster currentness: ${result.clubCount} scoped clubs, ` +
      `${result.playerCount} scoped players, ${result.totalPlayerCount} total players, ` +
      `${result.aliasesApplied} reviewed display aliases, ` +
      `${result.membershipOverridesApplied} owner membership overrides.`
  );
  for (const error of result.teamErrors) {
    console.error(`TEAM ERROR: ${error}`);
  }
  for (const difference of result.differences) {
    console.error(
      `ROSTER DIFFERENCE ${difference.clubSlug}: ` +
        `+${difference.added.length} -${difference.removed.length}`
    );
    if (difference.added.length > 0) {
      console.error(`  Added: ${difference.added.join(", ")}`);
    }
    if (difference.removed.length > 0) {
      console.error(`  Removed: ${difference.removed.join(", ")}`);
    }
  }

  if (result.teamErrors.length > 0 || result.differences.length > 0) {
    throw new Error("Roster currentness check failed.");
  }
  console.log("Roster currentness check passed with zero membership changes.");
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
