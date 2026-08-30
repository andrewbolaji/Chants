import { strict as assert } from "assert";
import { readFileSync } from "fs";
import { resolve } from "path";
import { validateClub, validateSport, validateCompetition } from "./validate";

describe("validateSport", () => {
  it("passes for valid sport", () => {
    assert.deepEqual(validateSport({ name: "Football", enabled: true }), []);
  });
  it("fails for missing name", () => {
    const errors = validateSport({ name: "", enabled: true });
    assert.ok(errors.length > 0);
  });
});

describe("validateCompetition", () => {
  it("passes for valid competition", () => {
    assert.deepEqual(
      validateCompetition({ sportId: "football", name: "Premier League", enabled: true }),
      []
    );
  });
  it("fails for missing sportId", () => {
    const errors = validateCompetition({ sportId: "", name: "PL", enabled: true });
    assert.ok(errors.length > 0);
  });
});

describe("validateClub", () => {
  const validClub = {
    team: { name: "Arsenal", crestImageUrl: null },
    squad: [
      { name: "Bukayo Saka" },
      { name: "Martin Odegaard" },
    ],
    chants: [
      {
        id: "arsenal-one-nil-to-the-arsenal",
        title: "One Nil to the Arsenal",
        subjectTag: "club",
        playerName: null,
        lyrics: "One nil to the Arsenal...",
        tuneName: "Go West",
        contextNotes: null,
        chantType: "sincere",
        mediaType: "none",
      },
    ],
  };

  it("passes for valid club", () => {
    assert.deepEqual(validateClub(validClub, "arsenal"), []);
  });

  it("passes for the complete Arsenal source file", () => {
    const arsenal = JSON.parse(
      readFileSync(resolve(__dirname, "../seed_data/clubs/arsenal.json"), "utf8")
    );
    assert.deepEqual(validateClub(arsenal, "arsenal"), []);
  });

  it("fails for missing team name", () => {
    const bad = { ...validClub, team: { name: "", crestImageUrl: null } };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.field === "team.name"));
  });

  it("fails for missing chant title", () => {
    const bad = {
      ...validClub,
      chants: [{ ...validClub.chants[0], title: "" }],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.field.includes("title")));
  });

  it("fails for a missing seeded chant ID", () => {
    const bad = {
      ...validClub,
      chants: [{ ...validClub.chants[0], id: "" }],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.field === "chants[0].id"));
  });

  it("fails for a seeded chant ID without the club prefix", () => {
    const bad = {
      ...validClub,
      chants: [{ ...validClub.chants[0], id: "chelsea-one-nil" }],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("club prefix")));
  });

  it("fails for a seeded chant ID that is not slug-safe", () => {
    const bad = {
      ...validClub,
      chants: [{ ...validClub.chants[0], id: "arsenal-Bad--ID" }],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("lowercase letters")));
  });

  it("fails for a seeded chant ID longer than the bounded maximum", () => {
    const bad = {
      ...validClub,
      chants: [{ ...validClub.chants[0], id: `arsenal-${"a".repeat(114)}` }],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("at most 120")));
  });

  it("fails for duplicate explicit chant IDs", () => {
    const bad = {
      ...validClub,
      chants: [
        validClub.chants[0],
        {
          ...validClub.chants[0],
          title: "A Different Chant",
          id: validClub.chants[0].id,
        },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("Duplicate seeded chant ID")));
  });

  it("fails for player chant with no matching squad member", () => {
    const bad = {
      ...validClub,
      chants: [
        {
          id: "arsenal-ghost-chant",
          title: "Ghost Chant",
          subjectTag: "player",
          playerName: "Nonexistent Player",
          lyrics: "...",
          tuneName: "...",
          contextNotes: null,
          chantType: "sincere",
          mediaType: "none",
        },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("does not match")));
  });

  it("fails for player chant with null playerName", () => {
    const bad = {
      ...validClub,
      chants: [
        {
          id: "arsenal-missing-player",
          title: "Missing Player",
          subjectTag: "player",
          playerName: null,
          lyrics: "...",
          tuneName: "...",
          contextNotes: null,
          chantType: "sincere",
          mediaType: "none",
        },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("must have a playerName")));
  });

  it("fails for club chant with non-null playerName", () => {
    const bad = {
      ...validClub,
      chants: [
        {
          id: "arsenal-club-song",
          title: "Club Song",
          subjectTag: "club",
          playerName: "Bukayo Saka",
          lyrics: "...",
          tuneName: "...",
          contextNotes: null,
          chantType: "sincere",
          mediaType: "none",
        },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("must have null playerName")));
  });

  it("fails for invalid subjectTag", () => {
    const bad = {
      ...validClub,
      chants: [{ ...validClub.chants[0], subjectTag: "invalid" }],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.field.includes("subjectTag")));
  });

  it("fails for invalid mediaType", () => {
    const bad = {
      ...validClub,
      chants: [{ ...validClub.chants[0], mediaType: "video" }],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.field.includes("mediaType")));
  });

  it("fails content that exceeds the runtime chant bounds", () => {
    const bad = {
      ...validClub,
      chants: [
        {
          ...validClub.chants[0],
          title: "t".repeat(201),
          lyrics: "l".repeat(5001),
          tuneName: "u".repeat(201),
          contextNotes: "c".repeat(501),
        },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((error) => error.field === "chants[0].title"));
    assert.ok(errors.some((error) => error.field === "chants[0].lyrics"));
    assert.ok(errors.some((error) => error.field === "chants[0].tuneName"));
    assert.ok(errors.some((error) => error.field === "chants[0].contextNotes"));
  });

  it("fails for duplicate normalized chant titles with different IDs", () => {
    const bad = {
      ...validClub,
      chants: [
        validClub.chants[0],
        {
          ...validClub.chants[0],
          id: "arsenal-one-nil-alternate-id",
          title: "One-Nil to the Arsenal!",
        },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("Duplicate chant title slug")));
  });

  it("fails for duplicate player slugs", () => {
    const bad = {
      ...validClub,
      squad: [
        { name: "Bukayo Saka" },
        { name: "Bukayo Saka" },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("Duplicate player slug")));
  });

  it("passes for chant with no variations key", () => {
    assert.deepEqual(validateClub(validClub, "arsenal"), []);
  });

  it("passes strict offline catalogue metadata", () => {
    const good = {
      ...validClub,
      catalogue: {
        version: 1,
        rosterSource: "https://example.com/roster",
        rosterAsOf: "2026-08-30",
      },
      chants: [
        {
          ...validClub.chants[0],
          era: "evergreen",
          reviewedAsOf: "2026-08-30",
          ownerVerified: true,
          sources: ["https://example.com/source"],
        },
      ],
    };
    assert.deepEqual(validateClub(good, "arsenal"), []);
  });

  it("fails malformed offline catalogue metadata", () => {
    const bad = {
      ...validClub,
      catalogue: {
        version: 2,
        rosterSource: "http://example.com/roster",
        rosterAsOf: "August 30",
      },
      chants: [
        {
          ...validClub.chants[0],
          era: "old",
          reviewedAsOf: "August 30",
          ownerVerified: false,
          sources: [],
        },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((error) => error.field === "catalogue.version"));
    assert.ok(errors.some((error) => error.field === "catalogue.rosterSource"));
    assert.ok(errors.some((error) => error.field === "catalogue.rosterAsOf"));
    assert.ok(errors.some((error) => error.field === "chants[0].era"));
    assert.ok(errors.some((error) => error.field === "chants[0].reviewedAsOf"));
    assert.ok(errors.some((error) => error.field === "chants[0].ownerVerified"));
    assert.ok(errors.some((error) => error.field === "chants[0].sources"));
  });

  it("fails non-object catalogue metadata without throwing", () => {
    const bad = {
      ...validClub,
      catalogue: null,
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((error) => error.field === "catalogue"));
  });

  it("requires safe club linkage for historic catalogue subjects", () => {
    const bad = {
      ...validClub,
      catalogue: {
        version: 1,
        rosterSource: "https://example.com/roster",
        rosterAsOf: "2026-08-30",
      },
      chants: [
        {
          ...validClub.chants[0],
          subjectTag: "player",
          playerName: "Bukayo Saka",
          era: "historic",
          reviewedAsOf: "2026-08-30",
          ownerVerified: true,
          sources: ["https://example.com/source"],
        },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((error) => error.message.includes("club linkage")));
    assert.ok(errors.some((error) => error.field === "chants[0].historicSubject"));
  });

  it("passes for chant with valid variations", () => {
    const good = {
      ...validClub,
      chants: [
        {
          ...validClub.chants[0],
          variations: [
            { label: "Current version", lyric: "Gabi at the back", contextNote: "Updated line" },
            { label: "Original", lyric: "Kieran at the back" },
          ],
        },
      ],
    };
    assert.deepEqual(validateClub(good, "arsenal"), []);
  });

  it("fails for variation missing label", () => {
    const bad = {
      ...validClub,
      chants: [
        {
          ...validClub.chants[0],
          variations: [{ label: "", lyric: "Some lyric" }],
        },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("Variation label is required")));
  });

  it("fails for variation missing lyric", () => {
    const bad = {
      ...validClub,
      chants: [
        {
          ...validClub.chants[0],
          variations: [{ label: "Alt", lyric: "" }],
        },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("Variation lyric is required")));
  });
});
