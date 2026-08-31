import * as admin from "firebase-admin";
import { admissionAllowed, parseOperationalControl } from "../functions/src/operational_control";

export async function requireSeedWritesEnabled(
  db: admin.firestore.Firestore, transaction: admin.firestore.Transaction,
): Promise<void> {
  const snapshot = await transaction.get(db.collection("operationalControls").doc("v1"));
  if (!admissionAllowed("core", parseOperationalControl(snapshot.data()))) {
    throw new Error("Seed writes are paused. Read-only preflight remains available.");
  }
}

export function runSeedTransaction<T>(
  db: admin.firestore.Firestore,
  operation: (transaction: admin.firestore.Transaction) => Promise<T>,
): Promise<T> {
  return db.runTransaction(async (transaction) => {
    await requireSeedWritesEnabled(db, transaction);
    return operation(transaction);
  });
}
