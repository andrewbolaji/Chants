import { HttpsError } from "firebase-functions/v2/https";

export type ChantTrustAction = "promote" | "demote" | "remove-evidence";

export type ChantTrustPlan = {
  changed: boolean;
  nextStatus?: "canonical" | "community";
  deleteEvidence: boolean;
  auditAction: ChantTrustAction;
  auditDetail: string;
};

type ChantData = {
  status?: unknown;
  createdBy?: unknown;
  evidence?: unknown;
};

const canonicalYoutube =
  /^https:\/\/www[.]youtube[.]com\/watch[?]v=[A-Za-z0-9_-]{11}$/;
const canonicalX =
  /^https:\/\/x[.]com\/[A-Za-z0-9_]{1,15}\/status\/[0-9]{1,25}$/;

export function isValidStoredEvidence(value: unknown): boolean {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    return false;
  }

  const evidence = value as Record<string, unknown>;
  const keys = Object.keys(evidence).sort();
  if (keys.length !== 2 || keys[0] !== "provider" || keys[1] !== "url") {
    return false;
  }
  if (typeof evidence.url !== "string") return false;

  if (evidence.provider === "youtube") {
    return canonicalYoutube.test(evidence.url);
  }
  if (evidence.provider === "x") return canonicalX.test(evidence.url);
  return false;
}

export function planChantTrustAction(
  action: ChantTrustAction,
  chant: ChantData
): ChantTrustPlan {
  const status = chant.status;
  if (status !== "canonical" && status !== "community") {
    throw new HttpsError("failed-precondition", "Chant status is invalid.");
  }

  const systemOwned = chant.createdBy === "system";
  const validEvidence = isValidStoredEvidence(chant.evidence);

  switch (action) {
    case "promote": {
      if (!systemOwned && !validEvidence) {
        throw new HttpsError(
          "failed-precondition",
          "Valid YouTube or X evidence is required before Terrace Proven."
        );
      }
      return {
        changed: status !== "canonical",
        nextStatus: "canonical",
        deleteEvidence: false,
        auditAction: "promote",
        auditDetail: "Community chant promoted to Terrace Proven by operator.",
      };
    }

    case "demote":
      return {
        changed: status !== "community",
        nextStatus: "community",
        deleteEvidence: false,
        auditAction: "demote",
        auditDetail: "Terrace Proven chant returned to community by operator.",
      };

    case "remove-evidence": {
      if (!("evidence" in chant) || chant.evidence == null) {
        return {
          changed: false,
          deleteEvidence: false,
          auditAction: "remove-evidence",
          auditDetail: "No chant evidence was present.",
        };
      }
      const demotes = status === "canonical" && !systemOwned;
      return {
        changed: true,
        nextStatus: demotes ? "community" : undefined,
        deleteEvidence: true,
        auditAction: "remove-evidence",
        auditDetail: demotes
          ? "Evidence removed and user chant returned to community by operator."
          : "Evidence removed by operator.",
      };
    }
  }
}
