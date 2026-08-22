import { strict as assert } from "assert";
import { executeSeedPlan, parseSeedArguments } from "./seed_plan";

describe("seed execution plan", () => {
  it("parses preflight-only without treating it as a club filename", () => {
    assert.deepEqual(
      parseSeedArguments(["--preflight-only", "arsenal.json"]),
      {
        preflightOnly: true,
        clubFileNames: ["arsenal.json"],
      }
    );
    assert.throws(
      () => parseSeedArguments(["--write-anyway"]),
      /Unknown seed option/
    );
  });

  it("preflight-only performs no sport, competition, or club write", async () => {
    const actions: string[] = [];
    const result = await executeSeedPlan(
      ["arsenal.json"],
      true,
      {
        preflightClub: async (filePath) => {
          actions.push(`preflight:${filePath}`);
        },
        seedSport: async () => {
          actions.push("write:sport");
          return "football";
        },
        seedCompetition: async () => {
          actions.push("write:competition");
          return "premier-league";
        },
        seedClub: async () => {
          actions.push("write:club");
        },
      }
    );

    assert.equal(result, "preflighted");
    assert.deepEqual(actions, ["preflight:arsenal.json"]);
  });

  it("preflight-only propagates a read failure before any writer", async () => {
    const actions: string[] = [];
    await assert.rejects(
      executeSeedPlan(
        ["arsenal.json"],
        true,
        {
          preflightClub: async () => {
            actions.push("preflight");
            throw new Error("credential or network failure");
          },
          seedSport: async () => {
            actions.push("write:sport");
            return "football";
          },
          seedCompetition: async () => {
            actions.push("write:competition");
            return "premier-league";
          },
          seedClub: async () => {
            actions.push("write:club");
          },
        }
      ),
      /credential or network failure/
    );
    assert.deepEqual(actions, ["preflight"]);
  });

  it("normal mode preserves sport, competition, then club write order", async () => {
    const actions: string[] = [];
    const result = await executeSeedPlan(
      ["arsenal.json"],
      false,
      {
        preflightClub: async () => {
          actions.push("preflight-only");
        },
        seedSport: async () => {
          actions.push("sport");
          return "football";
        },
        seedCompetition: async (sportSlug) => {
          actions.push(`competition:${sportSlug}`);
          return "premier-league";
        },
        seedClub: async (filePath, sportSlug, competitionSlug) => {
          actions.push(
            `club:${filePath}:${sportSlug}:${competitionSlug}`
          );
        },
      }
    );

    assert.equal(result, "seeded");
    assert.deepEqual(actions, [
      "sport",
      "competition:football",
      "club:arsenal.json:football:premier-league",
    ]);
  });
});
