import { strict as assert } from "assert";
import { readFileSync } from "fs";
import { resolve } from "path";
import {
  FPL_TEAM_NAMES_BY_SLUG,
  compareRosterCurrentness,
  FplBootstrap,
} from "./roster_currentness";

const snapshot = JSON.parse(
  readFileSync(
    resolve(__dirname, "../seed_data/rosters/fpl-2026-08-30.json"),
    "utf8"
  )
) as {
  clubs: Record<string, string[]>;
};
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

function currentBootstrap(): FplBootstrap {
  const teamEntries = Object.entries(FPL_TEAM_NAMES_BY_SLUG);
  const teams = teamEntries.map(([, name], index) => ({
    id: index + 1,
    name,
  }));
  const elements = teamEntries.flatMap(([slug], index) =>
    expectedClubs[slug].flatMap((canonicalName) => {
      const arsenalAliases: Record<string, [string, string]> = {
        "Ben White": ["Benjamin", "White"],
        "Bruno Guimarães": ["Bruno", "Guimarães Rodriguez Moura"],
        "David Raya": ["David", "Raya Martín"],
        "Ezri Konsa": ["Ezri", "Konsa Ngoyo"],
        "Gabriel Jesus": ["Gabriel Fernando", "de Jesus"],
        "Gabriel Magalhaes": ["Gabriel dos Santos", "Magalhães"],
        "Gabriel Martinelli": ["Gabriel", "Martinelli Silva"],
        "Jurrien Timber": ["Jurriën", "Timber"],
        "Kepa Arrizabalaga": ["Kepa", "Arrizabalaga Revuelta"],
        "Martin Odegaard": ["Martin", "Ødegaard"],
        "Martin Zubimendi": ["Martín", "Zubimendi Ibáñez"],
        "Mikel Merino": ["Mikel", "Merino Zazón"],
        "Piero Hincapie": ["Piero", "Hincapié"],
        "Victor Gyokeres": ["Viktor", "Gyökeres"],
      };
      if (slug === "arsenal" && canonicalName === "Marli Salmon") {
        return [];
      }
      if (slug === "arsenal" && arsenalAliases[canonicalName]) {
        const [first_name, second_name] = arsenalAliases[canonicalName];
        return [{ first_name, second_name, team: index + 1 }];
      }
      if (canonicalName === "Igor Thiago") {
        return [{
          first_name: "Igor Thiago",
          second_name: "Nascimento Rodrigues",
          team: index + 1,
        }];
      }
      if (canonicalName === "Kaoru Mitoma") {
        return [{
          first_name: "Mitoma",
          second_name: "Kaoru",
          team: index + 1,
        }];
      }
      return [{
        first_name: canonicalName,
        second_name: "",
        team: index + 1,
      }];
    })
  );
  const arsenalTeam = teams.find((team) => team.name === "Arsenal");
  assert.ok(arsenalTeam);
  elements.push(
    {
      first_name: "Fábio",
      second_name: "Ferreira Vieira",
      team: arsenalTeam.id,
    },
    {
      first_name: "Reiss",
      second_name: "Nelson",
      team: arsenalTeam.id,
    }
  );
  return { teams, elements };
}

describe("roster currentness", () => {
  it("preserves canonical IDs across reviewed display and membership overrides", () => {
    const result = compareRosterCurrentness(currentBootstrap(), expectedClubs);

    assert.equal(result.clubCount, 20);
    assert.equal(result.playerCount, 622);
    assert.equal(result.totalPlayerCount, 623);
    assert.equal(result.aliasesApplied, 17);
    assert.equal(result.membershipOverridesApplied, 3);
    assert.deepEqual(result.differences, []);
  });

  it("reports added, removed, and moved membership instead of normalizing it away", () => {
    const bootstrap = currentBootstrap();
    const leeds = bootstrap.teams.find((team) => team.name === "Leeds");
    const sunderland = bootstrap.teams.find((team) => team.name === "Sunderland");
    assert.ok(leeds);
    assert.ok(sunderland);

    bootstrap.elements = bootstrap.elements.filter(
      (player) =>
        !(
          player.team === leeds.id &&
          player.first_name === "Alfie Cresswell"
        )
    );
    const moved = bootstrap.elements.find(
      (player) =>
        player.team === leeds.id && player.first_name === "Anton Stach"
    );
    assert.ok(moved);
    moved.team = sunderland.id;
    bootstrap.elements.push({
      first_name: "Unexpected Signing",
      second_name: "",
      team: leeds.id,
    });

    const result = compareRosterCurrentness(bootstrap, expectedClubs);
    const leedsDifference = result.differences.find(
      (difference) => difference.clubSlug === "leeds-united"
    );
    const sunderlandDifference = result.differences.find(
      (difference) => difference.clubSlug === "sunderland"
    );

    assert.deepEqual(leedsDifference, {
      clubSlug: "leeds-united",
      added: ["Unexpected Signing"],
      removed: ["Alfie Cresswell", "Anton Stach"],
    });
    assert.deepEqual(sunderlandDifference, {
      clubSlug: "sunderland",
      added: ["Anton Stach"],
      removed: [],
    });
  });
});
