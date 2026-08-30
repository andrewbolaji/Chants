import { strict as assert } from "assert";
import { CHANT_CONTENT_FIELDS } from "./seed_chant_data";
import {
  CHANT_READBACK_FIELDS,
  compareDocumentProjection,
  countReferencesById,
  findReferencedTargetIds,
  findUnexpectedDocumentIds,
} from "./seed_readback";

describe("seed readback projection", () => {
  it("covers immutable chant identity and every seed-owned content field", () => {
    assert.deepEqual(CHANT_READBACK_FIELDS, [
      "sportId",
      "competitionId",
      "teamId",
      "createdBy",
      ...CHANT_CONTENT_FIELDS,
    ]);
    for (const serverOwnedField of [
      "createdAt",
      "updatedAt",
      "upvotes",
      "downvotes",
      "score",
      "commentCount",
      "flagCount",
      "hidden",
      "removed",
      "status",
    ]) {
      assert.equal(CHANT_READBACK_FIELDS.includes(serverOwnedField), false);
    }
  });

  it("ignores server-owned fields outside the seed projection", () => {
    const result = compareDocumentProjection(
      {
        title: "Marching On Together",
        playerId: null,
        variations: [{ label: "Short", lyric: "Leeds!" }],
        score: 91,
        hidden: true,
      },
      {
        title: "Marching On Together",
        playerId: null,
        variations: [{ label: "Short", lyric: "Leeds!" }],
      },
      ["title", "playerId", "variations"]
    );

    assert.deepEqual(result, { state: "matching", mismatchedFields: [] });
  });

  it("reports only mismatched source-owned field names", () => {
    const result = compareDocumentProjection(
      {
        title: "Wrong title",
        playerId: "wrong-player",
        score: 91,
      },
      {
        title: "Marching On Together",
        playerId: null,
      },
      ["title", "playerId"]
    );

    assert.deepEqual(result, {
      state: "mismatching",
      mismatchedFields: ["title", "playerId"],
    });
  });

  it("distinguishes a missing document from a mismatching document", () => {
    const result = compareDocumentProjection(
      undefined,
      { title: "Marching On Together" },
      ["title"]
    );

    assert.deepEqual(result, { state: "missing", mismatchedFields: [] });
  });

  it("reports extra system chants without treating community work as an orphan", () => {
    const unexpected = findUnexpectedDocumentIds(
      [
        { id: "expected", data: { createdBy: "system" } },
        { id: "old-system-chant", data: { createdBy: "system" } },
        { id: "supporter-chant", data: { createdBy: "supporter-123" } },
      ],
      new Set(["expected"]),
      (data) => data.createdBy === "system"
    );

    assert.deepEqual(unexpected, ["old-system-chant"]);
  });

  it("counts chant references to each unexpected player without another query", () => {
    const counts = countReferencesById(
      [
        { id: "chant-1", data: { playerId: "departed-1" } },
        { id: "chant-2", data: { playerId: "current" } },
        { id: "chant-3", data: { playerId: "departed-1" } },
      ],
      ["departed-1", "departed-2"],
      "playerId"
    );

    assert.deepEqual(counts, { "departed-1": 2, "departed-2": 0 });
  });

  it("keeps retired-player references visible after the player document is gone", () => {
    const referenced = findReferencedTargetIds(
      { "retired-1": 1, "retired-2": 0 }
    );

    assert.deepEqual(referenced, [{ id: "retired-1", count: 1 }]);
  });
});
