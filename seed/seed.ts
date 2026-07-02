import * as admin from "firebase-admin";
import { readFileSync, readdirSync, existsSync } from "fs";
import { resolve, basename } from "path";
import { slugify, compositeSlug } from "./slugify";
import { validateSport, validateCompetition, validateClub, ClubData } from "./validate";

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
const CONTENT_FIELDS_CHANT = [
  "title", "lyrics", "tuneName", "contextNotes", "subjectTag",
  "playerId", "chantType", "mediaType", "coverImageUrl", "mediaUrl",
  "variations",
];

const CONTENT_FIELDS_PLAYER = ["name"];
const CONTENT_FIELDS_TEAM = ["name", "crestImageUrl"];

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
  const raw: ClubData = JSON.parse(readFileSync(filePath, "utf8"));
  const teamSlug = slugify(raw.team.name);

  // Validate
  const errors = validateClub(raw, teamSlug);
  if (errors.length > 0) {
    console.error(`Validation failed for ${basename(filePath)}:`, errors);
    process.exit(1);
  }

  console.log(`\n  Club: ${raw.team.name} (${teamSlug})`);

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
  const seededChantSlugs = new Set<string>();
  for (const chant of raw.chants) {
    const chantSlug = compositeSlug(teamSlug, chant.title);
    seededChantSlugs.add(chantSlug);
    const playerId = chant.playerName
      ? compositeSlug(teamSlug, chant.playerName)
      : null;

    const fullData: Record<string, unknown> = {
      title: chant.title,
      sportId: sportSlug,
      competitionId: compSlug,
      teamId: teamSlug,
      playerId,
      subjectTag: chant.subjectTag,
      lyrics: chant.lyrics,
      tuneName: chant.tuneName,
      contextNotes: chant.contextNotes ?? null,
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: chant.mediaType,
      status: "canonical",
      chantType: chant.chantType,
      variations: chant.variations ?? [],
      upvotes: 0,
      downvotes: 0,
      score: 0,
      commentCount: 0,
      createdBy: "system",
      createdAt: now,
      updatedAt: now,
      flagCount: 0,
      hidden: false,
      removed: false,
    };

    const chantRef = db.collection("chants").doc(chantSlug);
    const chantResult = await upsert(chantRef, fullData, CONTENT_FIELDS_CHANT);
    console.log(`    Chant "${chant.title}" (${chantSlug}): ${chantResult}`);
  }

  // Fix C: orphan report
  await reportOrphans("players", "teamId", teamSlug, seededPlayerSlugs);
  await reportOrphans("chants", "teamId", teamSlug, seededChantSlugs);
}

async function reportOrphans(
  collection: string,
  filterField: string,
  filterValue: string,
  seededSlugs: Set<string>
): Promise<void> {
  const existing = await db
    .collection(collection)
    .where(filterField, "==", filterValue)
    .get();
  let orphanCount = 0;
  for (const doc of existing.docs) {
    if (!seededSlugs.has(doc.id)) {
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
  const args = process.argv.slice(2);
  const clubsDir = resolve(__dirname, "../seed_data/clubs");

  console.log("Seeding Chants...\n");

  const sportSlug = await seedSport();
  const compSlug = await seedCompetition(sportSlug);

  // Determine which club files to process
  let clubFiles: string[];
  if (args.length > 0) {
    // Seed specific clubs
    clubFiles = args.map((f) => resolve(clubsDir, f));
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

  for (const file of clubFiles) {
    await seedClub(file, sportSlug, compSlug);
  }

  console.log(`\nDone. Seeded ${clubFiles.length} club(s).`);
}

main().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
