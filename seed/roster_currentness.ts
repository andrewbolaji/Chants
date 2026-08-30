export interface FplTeam {
  id: number;
  name: string;
}

export interface FplPlayer {
  first_name: string;
  second_name: string;
  team: number;
}

export interface FplBootstrap {
  teams: FplTeam[];
  elements: FplPlayer[];
}

export interface RosterDifference {
  clubSlug: string;
  added: string[];
  removed: string[];
}

export interface RosterCurrentnessResult {
  clubCount: number;
  playerCount: number;
  totalPlayerCount: number;
  aliasesApplied: number;
  membershipOverridesApplied: number;
  teamErrors: string[];
  differences: RosterDifference[];
}

export const FPL_TEAM_NAMES_BY_SLUG: Record<string, string> = {
  arsenal: "Arsenal",
  "aston-villa": "Aston Villa",
  bournemouth: "Bournemouth",
  brentford: "Brentford",
  "brighton-hove-albion": "Brighton",
  chelsea: "Chelsea",
  "coventry-city": "Coventry City",
  "crystal-palace": "Crystal Palace",
  everton: "Everton",
  fulham: "Fulham",
  "hull-city": "Hull City",
  "ipswich-town": "Ipswich Town",
  "leeds-united": "Leeds",
  liverpool: "Liverpool",
  "manchester-city": "Man City",
  "manchester-united": "Man Utd",
  "newcastle-united": "Newcastle",
  "nottingham-forest": "Nott'm Forest",
  "tottenham-hotspur": "Spurs",
  sunderland: "Sunderland",
};

const EXPECTED_FPL_TEAM_NAMES = Object.values(FPL_TEAM_NAMES_BY_SLUG).sort();

const REVIEWED_DISPLAY_ALIASES: Record<string, string> = {
  "arsenal|Benjamin White": "Ben White",
  "arsenal|Bruno Guimarães Rodriguez Moura": "Bruno Guimarães",
  "arsenal|David Raya Martín": "David Raya",
  "arsenal|Ezri Konsa Ngoyo": "Ezri Konsa",
  "arsenal|Fábio Ferreira Vieira": "Fábio Vieira",
  "arsenal|Gabriel dos Santos Magalhães": "Gabriel Magalhaes",
  "arsenal|Gabriel Fernando de Jesus": "Gabriel Jesus",
  "arsenal|Gabriel Martinelli Silva": "Gabriel Martinelli",
  "arsenal|Jurriën Timber": "Jurrien Timber",
  "arsenal|Kepa Arrizabalaga Revuelta": "Kepa Arrizabalaga",
  "arsenal|Martin Ødegaard": "Martin Odegaard",
  "arsenal|Martín Zubimendi Ibáñez": "Martin Zubimendi",
  "arsenal|Mikel Merino Zazón": "Mikel Merino",
  "arsenal|Piero Hincapié": "Piero Hincapie",
  "arsenal|Viktor Gyökeres": "Victor Gyokeres",
  "brentford|Igor Thiago Nascimento Rodrigues": "Igor Thiago",
  "brighton-hove-albion|Mitoma Kaoru": "Kaoru Mitoma",
};

const OWNER_EXCLUDED_CURRENT_PLAYERS = new Set([
  "arsenal|Fábio Vieira",
  "arsenal|Reiss Nelson",
]);

const OWNER_RETAINED_PLAYERS: Record<string, string[]> = {
  arsenal: ["Marli Salmon"],
};

function sorted(values: Iterable<string>): string[] {
  return [...values].sort((a, b) => a.localeCompare(b, "en"));
}

export function compareRosterCurrentness(
  bootstrap: FplBootstrap,
  expectedClubs: Record<string, string[]>
): RosterCurrentnessResult {
  const teamErrors: string[] = [];
  const actualTeamNames = bootstrap.teams.map((team) => team.name).sort();
  if (
    actualTeamNames.length !== EXPECTED_FPL_TEAM_NAMES.length ||
    actualTeamNames.some(
      (teamName, index) => teamName !== EXPECTED_FPL_TEAM_NAMES[index]
    )
  ) {
    teamErrors.push("The FPL club set does not match the approved 20 clubs.");
  }

  const slugByFplName = new Map(
    Object.entries(FPL_TEAM_NAMES_BY_SLUG).map(([slug, name]) => [name, slug])
  );
  const slugByTeamId = new Map<number, string>();
  for (const team of bootstrap.teams) {
    const slug = slugByFplName.get(team.name);
    if (slug) slugByTeamId.set(team.id, slug);
  }

  const actualClubs = new Map<string, string[]>();
  let aliasesApplied = 0;
  let membershipOverridesApplied = 0;
  for (const player of bootstrap.elements) {
    const clubSlug = slugByTeamId.get(player.team);
    if (!clubSlug) continue;
    const rawName = `${player.first_name} ${player.second_name}`.trim();
    const alias = REVIEWED_DISPLAY_ALIASES[`${clubSlug}|${rawName}`];
    if (alias) aliasesApplied += 1;
    const canonicalName = alias ?? rawName;
    if (
      OWNER_EXCLUDED_CURRENT_PLAYERS.has(`${clubSlug}|${canonicalName}`)
    ) {
      membershipOverridesApplied += 1;
      continue;
    }
    const names = actualClubs.get(clubSlug) ?? [];
    names.push(canonicalName);
    actualClubs.set(clubSlug, names);
  }
  for (const [clubSlug, retainedNames] of Object.entries(
    OWNER_RETAINED_PLAYERS
  )) {
    const names = actualClubs.get(clubSlug) ?? [];
    for (const retainedName of retainedNames) {
      if (!names.includes(retainedName)) {
        names.push(retainedName);
        membershipOverridesApplied += 1;
      }
    }
    actualClubs.set(clubSlug, names);
  }

  const expectedSlugs = Object.keys(expectedClubs).sort();
  const configuredSlugs = Object.keys(FPL_TEAM_NAMES_BY_SLUG).sort();
  if (
    expectedSlugs.length !== configuredSlugs.length ||
    expectedSlugs.some((slug, index) => slug !== configuredSlugs[index])
  ) {
    teamErrors.push(
      "The reviewed roster source does not match the configured 20-club scope."
    );
  }

  const differences: RosterDifference[] = [];
  for (const clubSlug of expectedSlugs) {
    const expected = new Set(expectedClubs[clubSlug]);
    const actualNames = actualClubs.get(clubSlug) ?? [];
    const actual = new Set(actualNames);
    if (actual.size !== actualNames.length) {
      teamErrors.push(`${clubSlug} contains a duplicate canonical player name.`);
    }
    const added = sorted([...actual].filter((name) => !expected.has(name)));
    const removed = sorted([...expected].filter((name) => !actual.has(name)));
    if (added.length > 0 || removed.length > 0) {
      differences.push({ clubSlug, added, removed });
    }
  }

  return {
    clubCount: expectedSlugs.length,
    playerCount: [...actualClubs.values()].reduce(
      (count, names) => count + names.length,
      0
    ),
    totalPlayerCount: bootstrap.elements.length,
    aliasesApplied,
    membershipOverridesApplied,
    teamErrors,
    differences,
  };
}
