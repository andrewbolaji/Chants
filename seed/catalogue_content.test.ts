import { strict as assert } from "assert";
import { readFileSync, readdirSync } from "fs";
import { basename, resolve } from "path";
import { slugify } from "./slugify";
import { ClubData, validateClub } from "./validate";
import { buildSeededChantData } from "./seed_chant_data";

type CatalogueChant = ClubData["chants"][number] & {
  era?: unknown;
  historicSubject?: unknown;
  reviewedAsOf?: unknown;
  ownerVerified?: unknown;
  sources?: unknown;
};

type CatalogueClub = ClubData & {
  catalogue?: {
    version?: unknown;
    rosterSource?: unknown;
    rosterAsOf?: unknown;
  };
  chants: CatalogueChant[];
};

const clubsDir = resolve(__dirname, "../seed_data/clubs");
const rosterSnapshot = JSON.parse(
  readFileSync(
    resolve(__dirname, "../seed_data/rosters/fpl-2026-08-30.json"),
    "utf8"
  )
) as {
  source: string;
  asOf: string;
  clubs: Record<string, string[]>;
};
const expectedClubSlugs = [
  "arsenal",
  "aston-villa",
  "bournemouth",
  "brentford",
  "brighton-hove-albion",
  "chelsea",
  "coventry-city",
  "crystal-palace",
  "everton",
  "fulham",
  "hull-city",
  "ipswich-town",
  "leeds-united",
  "liverpool",
  "manchester-city",
  "manchester-united",
  "newcastle-united",
  "nottingham-forest",
  "sunderland",
  "tottenham-hotspur",
];

function loadClubs(): Array<{ fileName: string; slug: string; club: CatalogueClub }> {
  return readdirSync(clubsDir)
    .filter((fileName) => fileName.endsWith(".json"))
    .sort()
    .map((fileName) => {
      const club = JSON.parse(
        readFileSync(resolve(clubsDir, fileName), "utf8")
      ) as CatalogueClub;
      return { fileName, slug: slugify(club.team.name), club };
    });
}

function findClub(clubs: ReturnType<typeof loadClubs>, slug: string): CatalogueClub {
  const match = clubs.find((entry) => entry.slug === slug);
  assert.ok(match, `Missing club ${slug}.`);
  return match.club;
}

function findChant(club: CatalogueClub, titlePart: string): CatalogueChant {
  const needle = titlePart.toLowerCase();
  const match = club.chants.find((chant) =>
    chant.title.toLowerCase().includes(needle)
  );
  assert.ok(match, `Missing ${club.team.name} chant containing "${titlePart}".`);
  return match;
}

describe("V1 Premier League catalogue", () => {
  it("contains exactly the approved twenty clubs", () => {
    const clubs = loadClubs();
    assert.deepEqual(
      clubs.map((entry) => entry.slug).sort(),
      [...expectedClubSlugs].sort()
    );
    assert.equal(clubs.length, 20);
  });

  it("validates every club and keeps a three-chant floor", () => {
    for (const { fileName, slug, club } of loadClubs()) {
      assert.deepEqual(
        validateClub(club, slug),
        [],
        `${basename(fileName)} failed validation.`
      );
      assert.ok(
        club.chants.length >= 3,
        `${club.team.name} has fewer than three reviewed chants.`
      );
    }
  });

  it("retains review provenance on every new club and chant", () => {
    for (const { slug, club } of loadClubs()) {
      if (slug === "arsenal") continue;
      assert.deepEqual(club.catalogue, {
        version: 1,
        rosterSource: "https://fantasy.premierleague.com/api/bootstrap-static/",
        rosterAsOf: "2026-08-30",
      });
      for (const chant of club.chants) {
        assert.ok(
          chant.era === "current" ||
            chant.era === "historic" ||
            chant.era === "evergreen",
          `${chant.id} has an invalid catalogue era.`
        );
        assert.equal(chant.ownerVerified, true, `${chant.id} is not owner verified.`);
        assert.equal(chant.reviewedAsOf, "2026-08-30");
        assert.ok(Array.isArray(chant.sources) && chant.sources.length > 0);
        assert.ok(
          (chant.sources as unknown[]).every(
            (source) => typeof source === "string" && /^https:\/\//.test(source)
          ),
          `${chant.id} has an invalid source URL.`
        );
        if (chant.era === "historic") {
          assert.equal(chant.subjectTag, "club");
          assert.equal(chant.playerName, null);
          assert.equal(typeof chant.historicSubject, "string");
          assert.ok((chant.historicSubject as string).length > 0);
        }
      }
    }
  });

  it("matches every new squad to the checked-in dated roster snapshot", () => {
    assert.equal(
      rosterSnapshot.source,
      "https://fantasy.premierleague.com/api/bootstrap-static/"
    );
    assert.equal(rosterSnapshot.asOf, "2026-08-30");
    assert.deepEqual(
      Object.keys(rosterSnapshot.clubs).sort(),
      expectedClubSlugs.filter((slug) => slug !== "arsenal").sort()
    );

    for (const { slug, club } of loadClubs()) {
      if (slug === "arsenal") continue;
      assert.deepEqual(
        club.squad.map((member) => member.name),
        rosterSnapshot.clubs[slug],
        `${club.team.name} does not match the dated roster snapshot.`
      );
    }
  });

  it("preserves the settled inclusions and exclusions", () => {
    const clubs = loadClubs();
    const liverpool = findClub(clubs, "liverpool");
    const salah = findChant(liverpool, "Salah");
    assert.equal(salah.era, "historic");
    assert.equal(salah.historicSubject, "Mohamed Salah");

    const manUtd = findClub(clubs, "manchester-united");
    const bruno = findChant(manUtd, "Bruno Fernandes");
    assert.equal(bruno.era, "current");
    assert.equal(bruno.playerName, "Bruno Borges Fernandes");

    const chelsea = findClub(clubs, "chelsea");
    findChant(chelsea, "Carefree");
    assert.ok(chelsea.chants.length > 5, "Chelsea was incorrectly capped at five.");

    const allTitlesAndLyrics = clubs
      .flatMap(({ club }) => club.chants)
      .map((chant) => `${chant.title}\n${chant.lyrics}`.toLowerCase())
      .join("\n");
    assert.doesNotMatch(allTitlesAndLyrics, /banks of the royal blue mersey/);
    assert.doesNotMatch(allTitlesAndLyrics, /yid army/);
    assert.doesNotMatch(allTitlesAndLyrics, /bruno guimar/);
    assert.doesNotMatch(allTitlesAndLyrics, /wagner/);
  });

  it("retains real workbook entries displaced by the former five-chant cap", () => {
    const clubs = loadClubs();
    for (const [slug, titles] of Object.entries({
      bournemouth: ["Triumphal March", "We're on Our Way", "We Hate Brighton"],
      "hull-city": ["I Love City Till I Die", "We Are Hull City", "Super Hull City"],
      fulham: ["You Are My Fulham"],
      "ipswich-town": ["Blue and White Army", "Come On You Blues"],
      liverpool: [
        "You'll Never Walk Alone",
        "Allez Allez Allez",
        "Virgil van Dijk",
        "We Hate Man United",
        "Alisson Becker",
      ],
      "manchester-city": ["Clap Your Hands", "Vincent Kompany"],
      "newcastle-united": ["Who Put the Ball"],
      sunderland: ["You Laughed at Us"],
      "tottenham-hotspur": ["A Grand Old Team"],
    })) {
      const club = findClub(clubs, slug);
      for (const title of titles) findChant(club, title);
    }
  });

  it("publishes already-sung origin without leaking offline review metadata", () => {
    const club = findClub(loadClubs(), "liverpool");
    const chant = findChant(club, "Salah");
    const runtime = buildSeededChantData({
      chant,
      sportSlug: "football",
      competitionSlug: "premier-league",
      teamSlug: "liverpool",
      playerId: null,
      timestamp: "server-time",
    });

    assert.equal(runtime.origin, "alreadySung");
    assert.ok(!("era" in runtime));
    assert.ok(!("historicSubject" in runtime));
    assert.ok(!("ownerVerified" in runtime));
    assert.ok(!("reviewedAsOf" in runtime));
    assert.ok(!("sources" in runtime));
  });
});
