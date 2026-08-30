import * as admin from "firebase-admin";
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

// --- Init ---
const serviceAccountPath = resolve(__dirname, "serviceAccountKey.json");
if (!existsSync(serviceAccountPath)) {
  console.error("Missing serviceAccountKey.json in seed/. See README for setup.");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccountPath),
});
const db = admin.firestore();

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

async function upsert(
  ref: admin.firestore.DocumentReference,
  fullData: Record<string, unknown>,
  contentFields: string[]
): Promise<"created" | "updated"> {
  const snap = await ref.get();
  if (!snap.exists) {
    await ref.set(fullData);
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
  await ref.update(update);
  return "updated";
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
        db.runTransaction(async (transaction) =>
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
  const { preflightOnly, clubFileNames } = parseSeedArguments(
    process.argv.slice(2)
  );
  const clubsDir = resolve(__dirname, "../seed_data/clubs");

  console.log(preflightOnly ? "Preflighting Chants...\n" : "Seeding Chants...\n");

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

  const result = await executeSeedPlan(clubFiles, preflightOnly, {
    preflightClub,
    seedSport,
    seedCompetition,
    seedClub,
  });
  if (result === "preflighted") {
    console.log(`\nDone. Preflighted ${clubFiles.length} club(s); no writes performed.`);
  } else {
    console.log(`\nDone. Seeded ${clubFiles.length} club(s).`);
  }
}

main().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
