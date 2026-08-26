import { strict as assert } from "assert";
import { readFileSync } from "fs";
import { resolve } from "path";
import {
  ChantIdentityConflictError,
  ExistingChantIdentity,
  RunSeedChantTransaction,
  SeedChantSnapshot,
  findChantIdentityConflicts,
  resolveSeededChantId,
  upsertSeededChantInTransaction,
} from "./chant_identity";
import { compositeSlug } from "./slugify";

const teamSlug = "arsenal";
const seedChant = {
  id: "arsenal-one-nil-to-the-arsenal",
  title: "One Nil to the Arsenal",
};

function existing(
  overrides: Partial<ExistingChantIdentity> = {}
): ExistingChantIdentity {
  return {
    id: seedChant.id,
    title: seedChant.title,
    teamId: teamSlug,
    createdBy: "system",
    ...overrides,
  };
}

describe("stable seeded chant identity", () => {
  it("keeps the document ID when only the title changes", () => {
    assert.equal(resolveSeededChantId(seedChant), seedChant.id);
    assert.equal(
      resolveSeededChantId({ ...seedChant, title: "One-Nil Arsenal" }),
      seedChant.id
    );
  });

  it("freezes every Arsenal ID to the legacy algorithm result", () => {
    const club = JSON.parse(
      readFileSync(resolve(__dirname, "../seed_data/clubs/arsenal.json"), "utf8")
    ) as { chants: Array<{ id: string; title: string }> };

    for (const chant of club.chants) {
      assert.equal(chant.id, compositeSlug(teamSlug, chant.title));
    }
  });
});

describe("chant identity preflight", () => {
  it("accepts a same-team system document whose stored title changed", () => {
    const conflicts = findChantIdentityConflicts(teamSlug, [seedChant], [
      existing({ title: "Older display title" }),
    ]);
    assert.deepEqual(conflicts, []);
  });

  it("rejects a community document at the explicit ID", () => {
    const conflicts = findChantIdentityConflicts(teamSlug, [seedChant], [
      existing({ createdBy: "user-123" }),
    ]);
    assert.equal(conflicts[0]?.kind, "target_not_system_owned");
  });

  it("rejects an explicit ID belonging to another team", () => {
    const conflicts = findChantIdentityConflicts(teamSlug, [seedChant], [
      existing({ teamId: "chelsea" }),
    ]);
    assert.equal(conflicts[0]?.kind, "target_wrong_team");
  });

  it("rejects a same-title system chant at another ID", () => {
    const conflicts = findChantIdentityConflicts(teamSlug, [seedChant], [
      existing({ id: "arsenal-legacy-one-nil" }),
    ]);
    assert.equal(conflicts[0]?.kind, "system_title_at_different_id");
  });
});

describe("transactional seeded chant write", () => {
  it("creates the explicit target when the transaction still sees it missing", async () => {
    let created: Record<string, unknown> | undefined;
    const runTransaction: RunSeedChantTransaction<string> = async (operation) =>
      operation({
        get: async () => ({ exists: false, data: () => undefined }),
        create: (_reference, data) => {
          created = data;
        },
        update: () => assert.fail("missing target must not be updated"),
      });
    const fullData = { title: seedChant.title, teamId: teamSlug };

    const result = await upsertSeededChantInTransaction({
      runTransaction,
      reference: seedChant.id,
      referenceId: seedChant.id,
      teamSlug,
      fullData,
      contentFields: ["title"],
      updatedAtValue: "server-time",
    });

    assert.equal(result, "created");
    assert.deepEqual(created, fullData);
  });

  it("rechecks ownership and refuses a concurrent community claim", async () => {
    let wrote = false;
    const snapshot: SeedChantSnapshot = {
      exists: true,
      data: () => ({ teamId: teamSlug, createdBy: "user-123" }),
    };
    const runTransaction: RunSeedChantTransaction<string> = async (operation) =>
      operation({
        get: async () => snapshot,
        create: () => {
          wrote = true;
        },
        update: () => {
          wrote = true;
        },
      });

    await assert.rejects(
      upsertSeededChantInTransaction({
        runTransaction,
        reference: seedChant.id,
        referenceId: seedChant.id,
        teamSlug,
        fullData: { title: seedChant.title, teamId: teamSlug },
        contentFields: ["title"],
        updatedAtValue: "server-time",
      }),
      ChantIdentityConflictError
    );
    assert.equal(wrote, false);
  });

  it("updates only allowlisted content for a safe existing target", async () => {
    let update: Record<string, unknown> | undefined;
    const runTransaction: RunSeedChantTransaction<string> = async (operation) =>
      operation({
        get: async () => ({
          exists: true,
          data: () => ({ teamId: teamSlug, createdBy: "system" }),
        }),
        create: () => assert.fail("existing target must not be created"),
        update: (_reference, data) => {
          update = data;
        },
      });

    const result = await upsertSeededChantInTransaction({
      runTransaction,
      reference: seedChant.id,
      referenceId: seedChant.id,
      teamSlug,
      fullData: { title: "Renamed", score: 99 },
      contentFields: ["title"],
      updatedAtValue: "server-time",
    });

    assert.equal(result, "updated");
    assert.deepEqual(update, { title: "Renamed", updatedAt: "server-time" });
  });
});
