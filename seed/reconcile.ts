/**
 * Reconciliation script: recomputes a chant's upvotes, downvotes, and score
 * directly from the votes collection. Fixes any counter drift caused by
 * at-least-once function delivery or other anomalies.
 *
 * Usage:
 *   npx ts-node reconcile.ts                  # reconcile all chants
 *   npx ts-node reconcile.ts <chantId>        # reconcile one chant
 */
import * as admin from "firebase-admin";
import { resolve } from "path";
import { readFileSync } from "fs";
import { assertServiceAccountProject } from "./seed_credential";
import { runSeedTransaction } from "./operational_control";

const serviceAccountPath = resolve(__dirname, "serviceAccountKey.json");
let db: admin.firestore.Firestore;
function initializeFirestore(): void {
  assertServiceAccountProject(JSON.parse(readFileSync(serviceAccountPath, "utf8")), "chants-f95b4");
  admin.initializeApp({ credential: admin.credential.cert(serviceAccountPath), projectId: "chants-f95b4" });
  db = admin.firestore();
}

export async function reconcileChant(chantId: string, firestore: admin.firestore.Firestore = db): Promise<{
  before: { upvotes: number; downvotes: number; score: number };
  after: { upvotes: number; downvotes: number; score: number };
  changed: boolean;
}> {
  return runSeedTransaction(firestore, async (transaction) => {
    const votesSnap = await transaction.get(firestore.collection("votes").where("chantId", "==", chantId));

    let upvotes = 0;
    let downvotes = 0;
    for (const doc of votesSnap.docs) {
      const val = doc.data().value;
      if (val === 1) upvotes++;
      else if (val === -1) downvotes++;
    }
    const score = upvotes - downvotes;

    const chantRef = firestore.collection("chants").doc(chantId);
    const chantSnap = await transaction.get(chantRef);
    if (!chantSnap.exists) {
      throw new Error(`Chant ${chantId} not found.`);
    }

    const data = chantSnap.data()!;
    const before = {
      upvotes: data.upvotes || 0,
      downvotes: data.downvotes || 0,
      score: data.score || 0,
    };
    const after = { upvotes, downvotes, score };
    const changed =
      before.upvotes !== after.upvotes ||
      before.downvotes !== after.downvotes ||
      before.score !== after.score;

    if (changed) {
      transaction.update(chantRef, { upvotes, downvotes, score });
    }

    return { before, after, changed };
  });
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  if (args.length > 1 || args.some((arg) => !/^[A-Za-z0-9_-]{1,200}$/.test(arg))) throw new Error("Expected zero or one chant ID.");
  initializeFirestore();

  if (args.length > 0) {
    // Reconcile one chant
    const chantId = args[0];
    console.log(`Reconciling chant: ${chantId}`);
    const result = await reconcileChant(chantId);
    console.log(`  Before: ${JSON.stringify(result.before)}`);
    console.log(`  After:  ${JSON.stringify(result.after)}`);
    console.log(`  Changed: ${result.changed}`);
  } else {
    // Reconcile all chants
    console.log("Reconciling all chants...");
    const chants = await db.collection("chants").get();
    let changed = 0;
    let total = 0;
    for (const doc of chants.docs) {
      total++;
      const result = await reconcileChant(doc.id);
      if (result.changed) {
        changed++;
        console.log(
          `  ${doc.id}: ${JSON.stringify(result.before)} -> ${JSON.stringify(result.after)}`
        );
      }
    }
    console.log(`Done. ${total} chants checked, ${changed} corrected.`);
  }
}

// Only run main if executed directly (not imported)
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error("Reconciliation failed:", err);
      process.exit(1);
    });
}
