import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import {
  admissionAllowed, AdmissionClass, ENDPOINT_ADMISSION, EndpointName,
  OperationalControl, parseOperationalControl,
} from "./operational_control";

export function maintenanceError(): HttpsError {
  return new HttpsError("unavailable", "Chants is temporarily paused. Please try again later.", {
    reason: "maintenance",
  });
}

export async function readOperationalControl(
  firestore: admin.firestore.Firestore,
): Promise<OperationalControl | null> {
  try {
    return parseOperationalControl((await firestore.collection("operationalControls").doc("v1").get()).data());
  } catch (_) {
    // An unreadable control must never reuse an earlier open result.
    return null;
  }
}

export async function operationEnabled(
  name: EndpointName, firestore: admin.firestore.Firestore, performanceTarget = false,
): Promise<boolean> {
  const allowed = admissionAllowed(ENDPOINT_ADMISSION[name], await readOperationalControl(firestore), performanceTarget);
  if (!allowed && ENDPOINT_ADMISSION[name] === "workers") {
    logger.info("Operational worker paused; retained work requires an explicit replay decision.", {
      operationalWorkerPaused: true, operation: name,
    });
  }
  return allowed;
}

export async function requireOperationEnabled(
  name: EndpointName, firestore: admin.firestore.Firestore, performanceTarget = false,
): Promise<void> {
  if (!await operationEnabled(name, firestore, performanceTarget)) throw maintenanceError();
}

export async function transactionControl(
  firestore: admin.firestore.Firestore, transaction: admin.firestore.Transaction,
  classification: AdmissionClass,
): Promise<OperationalControl> {
  let control: OperationalControl | null;
  try {
    control = parseOperationalControl((await transaction.get(
      firestore.collection("operationalControls").doc("v1"),
    )).data());
  } catch (_) { throw maintenanceError(); }
  if (!control || !admissionAllowed(classification, control)) throw maintenanceError();
  return control;
}
