import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

type OnboardingInput = {
  displayName: string;
  ageConfirmed17Plus: true;
  policyAccepted: true;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function parseOnboardingInput(data: unknown): OnboardingInput {
  if (!isRecord(data)) {
    throw new HttpsError("invalid-argument", "Invalid onboarding request.");
  }
  const keys = Object.keys(data).sort();
  const expected = ["ageConfirmed17Plus", "displayName", "policyAccepted"];
  if (
    keys.length !== expected.length ||
    keys.some((key, index) => key !== expected[index]) ||
    typeof data.displayName !== "string" ||
    data.ageConfirmed17Plus !== true ||
    data.policyAccepted !== true
  ) {
    throw new HttpsError("invalid-argument", "Invalid onboarding request.");
  }
  const displayName = data.displayName.trim();
  if (displayName.length < 1 || displayName.length > 50) {
    throw new HttpsError("invalid-argument", "Invalid onboarding request.");
  }
  return {
    displayName,
    ageConfirmed17Plus: true,
    policyAccepted: true,
  };
}

export async function handleCompleteOnboarding(params: {
  uid: string;
  data: unknown;
  firestore: admin.firestore.Firestore;
  now: () => admin.firestore.Timestamp;
  policyVersion: string;
}): Promise<{ created: boolean; completed: true }> {
  const input = parseOnboardingInput(params.data);
  const profileRef = params.firestore.collection("profiles").doc(params.uid);
  const deletionJobRef = params.firestore
    .collection("accountDeletionJobs")
    .doc(params.uid);
  const auditRef = params.firestore
    .collection("auditLog")
    .doc(`onboarding-policy-${params.uid}-${params.policyVersion}`);

  let created = false;
  await params.firestore.runTransaction(async (transaction) => {
    created = false;
    const [profileSnapshot, deletionJobSnapshot] = await Promise.all([
      transaction.get(profileRef),
      transaction.get(deletionJobRef),
    ]);
    if (deletionJobSnapshot.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Account deletion is in progress."
      );
    }

    if (profileSnapshot.exists) {
      const profile = profileSnapshot.data()!;
      if (profile.banned === true || profile.deletionPending === true) {
        throw new HttpsError(
          "permission-denied",
          "This account cannot complete onboarding."
        );
      }
      if (
        profile.ageConfirmed17Plus !== true ||
        profile.acceptedPolicyVersion !== params.policyVersion
      ) {
        throw new HttpsError(
          "failed-precondition",
          "The existing account profile needs operator recovery."
        );
      }
      return;
    }

    const timestamp = params.now();
    transaction.set(profileRef, {
      displayName: input.displayName,
      role: "user",
      banned: false,
      deletionPending: false,
      ageConfirmed17Plus: true,
      acceptedPolicyVersion: params.policyVersion,
      acceptedPolicyAt: timestamp,
      userReportCount: 0,
      createdAt: timestamp,
      updatedAt: timestamp,
    });
    transaction.set(auditRef, {
      actorId: params.uid,
      action: "accept-policy",
      targetType: "user",
      targetId: params.uid,
      detail: `Accepted Terms and Community Rules version ${params.policyVersion}.`,
      createdAt: timestamp,
    });
    created = true;
  });

  return { created, completed: true };
}
