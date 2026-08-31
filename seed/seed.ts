import * as admin from "firebase-admin";
import { runSeedTransaction } from "./operational_control";
import { readFileSync, readdirSync, existsSync } from "fs";
import { resolve, basename } from "path";
import { slugify, compositeSlug } from "./slugify";
import { validateSport, validateCompetition, validateClub, ClubData } from "./validate";
import {
  ExistingChantIdentity,
  findChantIdentityConflicts,
  resolveSeededChantId,
  upsertSeededChantInTransaction,
} from "./chant_identity";
import { executeSeedPlan, parseSeedArguments } from "./seed_plan";
import { buildSeededChantData, CHANT_CONTENT_FIELDS } from "./seed_chant_data";
import { assertServiceAccountProject } from "./seed_credential";
import {
  CHANT_READBACK_FIELDS,
  compareDocumentProjection,
  countReferencesById,
  findReferencedTargetIds,
  findUnexpectedDocumentIds,
  PLAYER_READBACK_FIELDS,
  TEAM_READBACK_FIELDS,
} from "./seed_readback";
import {
  APPROVED_ARSENAL_PLAYER_RETIREMENTS,
  executeApprovedArsenalPlayerRetirements,
  matchesApprovedPlayerRetirementIdentity,
} from "./approved_player_retirement";

const serviceAccountPath = resolve(__dirname, "serviceAccountKey.json");
const EXPECTED_PROJECT_ID = "chants-f95b4";
let db: admin.firestore.Firestore;

function initializeFirestore(): void {
  if (!existsSync(serviceAccountPath)) {
    throw new Error("Missing ignored seed/serviceAccountKey.json.");
  }
  const serviceAccount = JSON.parse(
    readFileSync(serviceAccountPath, "utf8")
  ) as unknown;
  assertServiceAccountProject(serviceAccount, EXPECTED_PROJECT_ID);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath),
    projectId: EXPECTED_PROJECT_ID,
  });
  db = admin.firestore();
}

// --- Helpers ---
const CONTENT_FIELDS_PLAYER = ["name"];
const CONTENT_FIELDS_TEAM = ["name", "crestImageUrl"];

function existingChantIdentity(
  snapshot: admin.firestore.DocumentSnapshot
): ExistingChantIdentity {
  const data = snapshot.data() ?? {};
  return {
    id: snapshot.id,
    title: data.title,
    teamId: data.teamId,
    createdBy: data.createdBy,
  };
}

async function preflightChantIdentities(
  raw: ClubData,
  teamSlug: string
): Promise<void> {
  const seeded = raw.chants.map((chant) => ({
    id: resolveSeededChantId(chant),
    title: chant.title,
  }));
  const targetReferences = seeded.map((chant) =>
    db.collection("chants").doc(chant.id)
  );
  const [teamSnapshot, targetSnapshots] = await Promise.all([
    db.collection("chants").where("teamId", "==", teamSlug).get(),
    db.getAll(...targetReferences),
  ]);

  const existingById = new Map<string, ExistingChantIdentity>();
  for (const snapshot of teamSnapshot.docs) {
    existingById.set(snapshot.id, existingChantIdentity(snapshot));
  }
  for (const snapshot of targetSnapshots) {
    if (snapshot.exists) {
      existingById.set(snapshot.id, existingChantIdentity(snapshot));
    }
  }

  const conflicts = findChantIdentityConflicts(
    teamSlug,
    seeded,
    [...existingById.values()]
  );
  if (conflicts.length > 0) {
    for (const conflict of conflicts) {
      console.error(`    IDENTITY CONFLICT [${conflict.kind}]: ${conflict.message}`);
    }
    throw new Error(
      `Chant identity preflight failed for "${teamSlug}". ` +
        "No club writes were attempted. Correct the seed IDs or prepare an approved migration."
    );
  }

  console.log(`    Chant identity preflight: ${seeded.length} safe target(s).`);
}

function loadClub(filePath: string): { raw: ClubData; teamSlug: string } {
  const raw: ClubData = JSON.parse(readFileSync(filePath, "utf8"));
  const teamSlug = slugify(raw.team.name);
  const errors = validateClub(raw, teamSlug);
  if (errors.length > 0) {
    console.error(`Validation failed for ${basename(filePath)}:`, errors);
    process.exit(1);
  }
  return { raw, teamSlug };
}

async function preflightClub(filePath: string): Promise<void> {
  const { raw, teamSlug } = loadClub(filePath);
  console.log(`\n  Club: ${raw.team.name} (${teamSlug})`);
  await preflightChantIdentities(raw, teamSlug);
}

async function retireApprovedArsenalPlayers(): Promise<void> {
  const result = await executeApprovedArsenalPlayerRetirements(
    async (operation) =>
      runSeedTransaction(db, async (transaction) =>
        operation({
          readPlayer: async (id) => {
            const snapshot = await transaction.get(
              db.collection("players").doc(id)
            );
            return {
              exists: snapshot.exists,
              data: snapshot.data(),
            };
          },
          countChantReferences: async (id) => {
            const snapshot = await transaction.get(
              db
                .collection("chants")
                .where("playerId", "==", id)
                .count()
            );
            return snapshot.data().count;
          },
          deletePlayer: (id) => {
            transaction.delete(db.collection("players").doc(id));
          },
        })
      )
  );
  console.log(
    `Approved Arsenal retirement: ${result.deletedIds.length} deleted, ` +
      `${result.alreadyAbsentIds.length} already absent.`
  );
}

interface ReadbackAudit {
  matching: number;
  missing: string[];
  mismatching: Array<{ id: string; fields: string[] }>;
  orphans: string[];
  orphanReferenceCounts: Record<string, number>;
  blockedReferences: Array<{ id: string; count: number }>;
}

function emptyReadbackAudit(): ReadbackAudit {
  return {
    matching: 0,
    missing: [],
    mismatching: [],
    orphans: [],
    orphanReferenceCounts: {},
    blockedReferences: [],
  };
}

function auditProjection(
  audit: ReadbackAudit,
  id: string,
  actual: Record<string, unknown> | undefined,
  expected: Record<string, unknown>,
  fields: string[]
): void {
  const comparison = compareDocumentProjection(actual, expected, fields);
  if (comparison.state === "matching") {
    audit.matching += 1;
  } else if (comparison.state === "missing") {
    audit.missing.push(id);
  } else {
    audit.mismatching.push({ id, fields: comparison.mismatchedFields });
  }
}

function reportReadback(label: string, audit: ReadbackAudit): boolean {
  console.log(
    `    ${label}: ${audit.matching} matching, ${audit.missing.length} missing, ` +
      `${audit.mismatching.length} mismatching, ${audit.orphans.length} orphan(s).`
  );
  for (const id of audit.missing.slice(0, 5)) {
    console.error(`      MISSING: ${id}`);
  }
  for (const mismatch of audit.mismatching.slice(0, 5)) {
    console.error(
      `      MISMATCH: ${mismatch.id} [${mismatch.fields.join(", ")}]`
    );
  }
  for (const id of audit.orphans.slice(0, 5)) {
    const referenceCount = audit.orphanReferenceCounts[id];
    const suffix = Number.isInteger(referenceCount)
      ? ` [${referenceCount} chant reference(s)]`
      : "";
    console.error(`      ORPHAN: ${id}${suffix}`);
  }
  for (const reference of audit.blockedReferences.slice(0, 5)) {
    console.error(
      `      RETIRED PLAYER REFERENCE: ${reference.id} [${reference.count} chant reference(s)]`
    );
  }
  return (
    audit.missing.length === 0 &&
    audit.mismatching.length === 0 &&
    audit.orphans.length === 0 &&
    audit.blockedReferences.length === 0
  );
}

async function readbackFoundation(): Promise<boolean> {
  const sport = JSON.parse(
    readFileSync(resolve(__dirname, "../seed_data/sport.json"), "utf8")
  ) as Record<string, unknown>;
  const competition = JSON.parse(
    readFileSync(resolve(__dirname, "../seed_data/competition.json"), "utf8")
  ) as Record<string, unknown>;
  const sportErrors = validateSport(sport);
  const competitionErrors = validateCompetition(competition);
  if (sportErrors.length > 0 || competitionErrors.length > 0) {
    throw new Error("Foundation source validation failed before readback.");
  }
  const sportSlug = slugify(sport.name as string);
  const competitionSlug = slugify(competition.name as string);
  const [sportSnapshot, competitionSnapshot] = await db.getAll(
    db.collection("sports").doc(sportSlug),
    db.collection("competitions").doc(competitionSlug)
  );
  const audit = emptyReadbackAudit();
  auditProjection(
    audit,
    `sports/${sportSlug}`,
    sportSnapshot.data(),
    { name: sport.name, enabled: sport.enabled },
    ["name", "enabled"]
  );
  auditProjection(
    audit,
    `competitions/${competitionSlug}`,
    competitionSnapshot.data(),
    {
      sportId: sportSlug,
      name: competition.name,
      enabled: competition.enabled,
    },
    ["sportId", "name", "enabled"]
  );
  return reportReadback("Foundation readback", audit);
}

async function readbackClub(filePath: string): Promise<boolean> {
  const { raw, teamSlug } = loadClub(filePath);
  const sportSlug = slugify(
    (JSON.parse(
      readFileSync(resolve(__dirname, "../seed_data/sport.json"), "utf8")
    ) as { name: string }).name
  );
  const competitionSlug = slugify(
    (JSON.parse(
      readFileSync(
        resolve(__dirname, "../seed_data/competition.json"),
        "utf8"
      )
    ) as { name: string }).name
  );
  console.log(`\n  Club: ${raw.team.name} (${teamSlug})`);

  const playerIds = raw.squad.map((member) =>
    compositeSlug(teamSlug, member.name)
  );
  const chantIds = raw.chants.map(resolveSeededChantId);
  const teamSnapshot = await db.collection("teams").doc(teamSlug).get();
  const playerSnapshots = await db.getAll(
    ...playerIds.map((id) => db.collection("players").doc(id))
  );
  const chantSnapshots = await db.getAll(
    ...chantIds.map((id) => db.collection("chants").doc(id))
  );
  const [existingPlayers, existingChants] = await Promise.all([
    db.collection("players").where("teamId", "==", teamSlug).get(),
    db.collection("chants").where("teamId", "==", teamSlug).get(),
  ]);
  let retirementPlayerSnapshots: admin.firestore.DocumentSnapshot[] = [];
  let retirementReferenceCounts: Record<string, number> = {};
  if (teamSlug === "arsenal") {
    const retirementTargets = APPROVED_ARSENAL_PLAYER_RETIREMENTS;
    [retirementPlayerSnapshots, retirementReferenceCounts] = await Promise.all([
      db.getAll(
        ...retirementTargets.map((target) =>
          db.collection("players").doc(target.id)
        )
      ),
      Promise.all(
        retirementTargets.map(async (target) => {
          const snapshot = await db
            .collection("chants")
            .where("playerId", "==", target.id)
            .count()
            .get();
          return [target.id, snapshot.data().count] as const;
        })
      ).then((entries) => Object.fromEntries(entries)),
    ]);
  }

  const teamAudit = emptyReadbackAudit();
  auditProjection(
    teamAudit,
    `teams/${teamSlug}`,
    teamSnapshot.data(),
    {
      sportId: sportSlug,
      competitionId: competitionSlug,
      name: raw.team.name,
      crestImageUrl: raw.team.crestImageUrl ?? null,
    },
    TEAM_READBACK_FIELDS
  );

  const playerAudit = emptyReadbackAudit();
  for (let index = 0; index < raw.squad.length; index += 1) {
    auditProjection(
      playerAudit,
      `players/${playerIds[index]}`,
      playerSnapshots[index].data(),
      { teamId: teamSlug, name: raw.squad[index].name },
      PLAYER_READBACK_FIELDS
    );
  }
  const expectedPlayerIds = new Set(playerIds);
  const existingPlayerDocuments = existingPlayers.docs.map((snapshot) => ({
    id: snapshot.id,
    data: snapshot.data(),
  }));
  const unexpectedPlayerIds = findUnexpectedDocumentIds(
    existingPlayerDocuments,
    expectedPlayerIds
  );
  playerAudit.orphans = unexpectedPlayerIds.map((id) => `players/${id}`);
  const existingChantDocuments = existingChants.docs.map((snapshot) => ({
    id: snapshot.id,
    data: snapshot.data(),
  }));
  const playerReferenceCounts = countReferencesById(
    existingChantDocuments,
    unexpectedPlayerIds,
    "playerId"
  );
  for (const [id, count] of Object.entries(retirementReferenceCounts)) {
    if (id in playerReferenceCounts) {
      playerReferenceCounts[id] = count;
    }
  }
  playerAudit.orphanReferenceCounts = Object.fromEntries(
    unexpectedPlayerIds.map((id) => [
      `players/${id}`,
      playerReferenceCounts[id],
    ])
  );
  if (teamSlug === "arsenal") {
    for (
      let index = 0;
      index < APPROVED_ARSENAL_PLAYER_RETIREMENTS.length;
      index += 1
    ) {
      const target = APPROVED_ARSENAL_PLAYER_RETIREMENTS[index];
      const snapshot = retirementPlayerSnapshots[index];
      if (
        snapshot.exists &&
        !matchesApprovedPlayerRetirementIdentity(target, snapshot.data())
      ) {
        playerAudit.mismatching.push({
          id: `players/${target.id}`,
          fields: ["retirementIdentity"],
        });
      }
    }
    playerAudit.blockedReferences = findReferencedTargetIds(
      retirementReferenceCounts
    ).map((reference) => ({
      id: `players/${reference.id}`,
      count: reference.count,
    }));
  }

  const chantAudit = emptyReadbackAudit();
  for (let index = 0; index < raw.chants.length; index += 1) {
    const chant = raw.chants[index];
    const playerId = chant.playerName
      ? compositeSlug(teamSlug, chant.playerName)
      : null;
    const expected = buildSeededChantData({
      chant,
      sportSlug,
      competitionSlug,
      teamSlug,
      playerId,
      timestamp: null,
    });
    auditProjection(
      chantAudit,
      `chants/${chantIds[index]}`,
      chantSnapshots[index].data(),
      expected,
      CHANT_READBACK_FIELDS
    );
  }
  const expectedChantIds = new Set(chantIds);
  chantAudit.orphans = findUnexpectedDocumentIds(
    existingChantDocuments,
    expectedChantIds,
    (data) => data.createdBy === "system"
  ).map((id) => `chants/${id}`);

  const teamExact = reportReadback("Team readback", teamAudit);
  const playersExact = reportReadback("Player readback", playerAudit);
  const chantsExact = reportReadback("Chant readback", chantAudit);
  return teamExact && playersExact && chantsExact;
}

async function upsert(
  ref: admin.firestore.DocumentReference,
  fullData: Record<string, unknown>,
  contentFields: string[]
): Promise<"created" | "updated"> {
  return runSeedTransaction(db, async (transaction) => {
    const snap = await transaction.get(ref);
    if (!snap.exists) {
      transaction.set(ref, fullData);
      return "created";
    }
    // Fix A: only update content fields, never touch counters, flags, timestamps
    const update: Record<string, unknown> = {};
    for (const field of contentFields) {
      if (field in fullData) {
        update[field] = fullData[field];
      }
    }
    update["updatedAt"] = admin.firestore.FieldValue.serverTimestamp();
    transaction.update(ref, update);
    return "updated";
  });
}

// --- Seed Sport ---
async function seedSport(): Promise<string> {
  const raw = JSON.parse(readFileSync(resolve(__dirname, "../seed_data/sport.json"), "utf8"));
  const errors = validateSport(raw);
  if (errors.length > 0) {
    console.error("sport.json validation failed:", errors);
    process.exit(1);
  }
  const sportSlug = slugify(raw.name);
  const ref = db.collection("sports").doc(sportSlug);
  const result = await upsert(ref, { name: raw.name, enabled: raw.enabled }, ["name", "enabled"]);
  console.log(`  Sport "${raw.name}" (${sportSlug}): ${result}`);
  return sportSlug;
}

// --- Seed Competition ---
async function seedCompetition(sportSlug: string): Promise<string> {
  const raw = JSON.parse(
    readFileSync(resolve(__dirname, "../seed_data/competition.json"), "utf8")
  );
  const errors = validateCompetition(raw);
  if (errors.length > 0) {
    console.error("competition.json validation failed:", errors);
    process.exit(1);
  }
  const compSlug = slugify(raw.name);
  const ref = db.collection("competitions").doc(compSlug);
  const result = await upsert(
    ref,
    { sportId: sportSlug, name: raw.name, enabled: raw.enabled },
    ["name", "enabled", "sportId"]
  );
  console.log(`  Competition "${raw.name}" (${compSlug}): ${result}`);
  return compSlug;
}

// --- Seed Club ---
async function seedClub(
  filePath: string,
  sportSlug: string,
  compSlug: string
): Promise<void> {
  const { raw, teamSlug } = loadClub(filePath);

  console.log(`\n  Club: ${raw.team.name} (${teamSlug})`);

  // Read every target before the first club write. Unsafe identity state aborts
  // the club rather than guessing at a migration.
  await preflightChantIdentities(raw, teamSlug);

  // Team
  const teamRef = db.collection("teams").doc(teamSlug);
  const teamResult = await upsert(
    teamRef,
    {
      sportId: sportSlug,
      competitionId: compSlug,
      name: raw.team.name,
      crestImageUrl: raw.team.crestImageUrl ?? null,
    },
    CONTENT_FIELDS_TEAM
  );
  console.log(`    Team: ${teamResult}`);

  // Squad
  const seededPlayerSlugs = new Set<string>();
  for (const member of raw.squad) {
    const playerSlug = compositeSlug(teamSlug, member.name);
    seededPlayerSlugs.add(playerSlug);
    const playerRef = db.collection("players").doc(playerSlug);
    const playerResult = await upsert(
      playerRef,
      {
        teamId: teamSlug,
        name: member.name,
      },
      CONTENT_FIELDS_PLAYER
    );
    console.log(`    Player "${member.name}" (${playerSlug}): ${playerResult}`);
  }

  // Chants
  const now = admin.firestore.FieldValue.serverTimestamp();
  const seededChantIds = new Set<string>();
  for (const chant of raw.chants) {
    const chantId = resolveSeededChantId(chant);
    seededChantIds.add(chantId);
    const playerId = chant.playerName
      ? compositeSlug(teamSlug, chant.playerName)
      : null;

    const fullData = buildSeededChantData({
      chant,
      sportSlug,
      competitionSlug: compSlug,
      teamSlug,
      playerId,
      timestamp: now,
    });

    const chantRef = db.collection("chants").doc(chantId);
    const chantResult = await upsertSeededChantInTransaction({
      runTransaction: (operation) =>
        runSeedTransaction(db, async (transaction) =>
          operation({
            get: (reference) => transaction.get(reference),
            create: (reference, data) => {
              transaction.create(reference, data);
            },
            update: (reference, data) => {
              transaction.update(reference, data);
            },
          })
        ),
      reference: chantRef,
      referenceId: chantId,
      teamSlug,
      fullData,
      contentFields: CHANT_CONTENT_FIELDS,
      updatedAtValue: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`    Chant "${chant.title}" (${chantId}): ${chantResult}`);
  }

  // Fix C: orphan report
  await reportOrphans("players", "teamId", teamSlug, seededPlayerSlugs);
  await reportOrphans("chants", "teamId", teamSlug, seededChantIds);
}

async function reportOrphans(
  collection: string,
  filterField: string,
  filterValue: string,
  seededIds: Set<string>
): Promise<void> {
  const existing = await db
    .collection(collection)
    .where(filterField, "==", filterValue)
    .get();
  let orphanCount = 0;
  for (const doc of existing.docs) {
    if (!seededIds.has(doc.id)) {
      orphanCount++;
      console.log(
        `    ORPHAN ${collection}: "${doc.id}" exists in Firestore but not in seed file. Review manually.`
      );
    }
  }
  if (orphanCount === 0) {
    console.log(`    No orphan ${collection} for ${filterValue}.`);
  }
}

// --- Main ---
async function main(): Promise<void> {
  const { mode, clubFileNames } = parseSeedArguments(process.argv.slice(2));
  if (mode === "retireApprovedArsenalPlayers") {
    initializeFirestore();
    console.log("Retiring approved Arsenal players...\n");
    await retireApprovedArsenalPlayers();
    console.log("\nDone. Exact approved Arsenal retirement completed.");
    return;
  }
  const clubsDir = resolve(__dirname, "../seed_data/clubs");

  // Determine which club files to process
  let clubFiles: string[];
  if (clubFileNames.length > 0) {
    // Seed specific clubs
    clubFiles = clubFileNames.map((f) => resolve(clubsDir, f));
    for (const f of clubFiles) {
      if (!existsSync(f)) {
        console.error(`Club file not found: ${f}`);
        process.exit(1);
      }
    }
  } else {
    // Seed all clubs
    if (!existsSync(clubsDir)) {
      console.log("No clubs directory found. Skipping club seed.");
      return;
    }
    clubFiles = readdirSync(clubsDir)
      .filter((f) => f.endsWith(".json"))
      .sort()
      .map((f) => resolve(clubsDir, f));
  }

  if (clubFiles.length === 0) {
    console.log("No club files to seed.");
    return;
  }

  initializeFirestore();
  console.log(
    mode === "preflight"
      ? "Preflighting Chants...\n"
      : mode === "readback"
        ? "Reading back Chants...\n"
        : "Seeding Chants...\n"
  );

  const result = await executeSeedPlan(clubFiles, mode, {
    preflightClub,
    readbackFoundation,
    readbackClub,
    seedSport,
    seedCompetition,
    seedClub,
  });
  if (result === "preflighted") {
    console.log(`\nDone. Preflighted ${clubFiles.length} club(s); no writes performed.`);
  } else if (result === "readback") {
    console.log(
      `\nDone. Read back ${clubFiles.length} club(s); no writes performed.`
    );
  } else {
    console.log(`\nDone. Seeded ${clubFiles.length} club(s).`);
  }
}

main().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
