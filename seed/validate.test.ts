import { strict as assert } from "assert";
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

  it("fails for player chant with no matching squad member", () => {
    const bad = {
      ...validClub,
      chants: [
        {
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

  it("fails for duplicate chant slugs", () => {
    const bad = {
      ...validClub,
      chants: [
        validClub.chants[0],
        { ...validClub.chants[0], title: "One Nil to the Arsenal" },
      ],
    };
    const errors = validateClub(bad, "arsenal");
    assert.ok(errors.some((e) => e.message.includes("Duplicate chant slug")));
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
