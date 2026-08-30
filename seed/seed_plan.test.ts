import { strict as assert } from "assert";
import { executeSeedPlan, parseSeedArguments } from "./seed_plan";

describe("seed execution plan", () => {
  it("parses preflight-only without treating it as a club filename", () => {
    assert.deepEqual(
      parseSeedArguments(["--preflight-only", "arsenal.json"]),
      {
        mode: "preflight",
        clubFileNames: ["arsenal.json"],
      }
    );
    assert.throws(
      () => parseSeedArguments(["--write-anyway"]),
      /Unknown seed option/
    );
    assert.throws(
      () =>
        parseSeedArguments(["--preflight-only", "--readback-only"]),
      /mutually exclusive/
    );
    assert.deepEqual(
      parseSeedArguments(["--readback-only", "leeds-united.json"]),
      {
        mode: "readback",
        clubFileNames: ["leeds-united.json"],
      }
    );
    assert.deepEqual(
      parseSeedArguments(["--retire-approved-arsenal-players"]),
      {
        mode: "retireApprovedArsenalPlayers",
        clubFileNames: [],
      }
    );
    assert.throws(
      () =>
        parseSeedArguments([
          "--readback-only",
          "--retire-approved-arsenal-players",
        ]),
      /mutually exclusive/
    );
    assert.throws(
      () =>
        parseSeedArguments([
          "--retire-approved-arsenal-players",
          "arsenal.json",
        ]),
      /does not accept club file arguments/
    );
  });

  it("preflight-only performs no sport, competition, or club write", async () => {
    const actions: string[] = [];
    const result = await executeSeedPlan(
      ["arsenal.json"],
      "preflight",
      {
        preflightClub: async (filePath) => {
          actions.push(`preflight:${filePath}`);
        },
        readbackFoundation: async () => {
          actions.push("readback:foundation");
          return true;
        },
        readbackClub: async () => {
          actions.push("readback:club");
          return true;
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
        "preflight",
        {
          preflightClub: async () => {
            actions.push("preflight");
            throw new Error("credential or network failure");
          },
          readbackFoundation: async () => {
            actions.push("readback:foundation");
            return true;
          },
          readbackClub: async () => {
            actions.push("readback:club");
            return true;
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

  it("readback-only aggregates every club and performs no writer", async () => {
    const actions: string[] = [];
    await assert.rejects(
      executeSeedPlan(
        ["arsenal.json", "leeds-united.json"],
        "readback",
        {
          preflightClub: async () => {
            actions.push("preflight");
          },
          readbackFoundation: async () => {
            actions.push("readback:foundation");
            return true;
          },
          readbackClub: async (filePath) => {
            actions.push(`readback:${filePath}`);
            return filePath === "arsenal.json";
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
      /missing or mismatching/
    );
    assert.deepEqual(actions, [
      "readback:foundation",
      "readback:arsenal.json",
      "readback:leeds-united.json",
    ]);
  });

  it("normal mode preserves sport, competition, then club write order", async () => {
    const actions: string[] = [];
    const result = await executeSeedPlan(
      ["arsenal.json"],
      "seed",
      {
        preflightClub: async () => {
          actions.push("preflight-only");
        },
        readbackFoundation: async () => {
          actions.push("readback:foundation");
          return true;
        },
        readbackClub: async () => {
          actions.push("readback:club");
          return true;
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
