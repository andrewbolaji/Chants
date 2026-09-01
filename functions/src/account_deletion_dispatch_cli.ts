import * as admin from "firebase-admin";
import { createHash } from "crypto";
import { realpathSync, writeFileSync } from "fs";
import { dirname, isAbsolute, resolve, sep } from "path";
import {
  requestVerifiedAccountDeletion,
  VerifiedAccountDeletionDispatch,
} from "./account_deletion";
import { controlCredential } from "./operational_control_cli";
import {
  readPrivateJson,
  requireReviewedSource,
} from "./report_repair_cli";
import { REPAIR_PROJECT } from "./report_repair";

const METHODS = [
  "current-email-challenge",
  "current-phone-challenge",
  "provider-reauth",
] as const;

type VerificationMethod = typeof METHODS[number];

export type AccountDeletionDispatchPlan = {
  schemaVersion: 1;
  projectId: typeof REPAIR_PROJECT;
  sourceSha: string;
  actorUid: string;
  targetUid: string;
  caseReference: string;
  verificationMethod: VerificationMethod;
  verificationCompletedAt: string;
};

function record(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Expected an exact dispatch object.");
  }
  return value as Record<string, unknown>;
}

function exact(value: Record<string, unknown>, keys: string[]): void {
  if (Object.keys(value).sort().join(",") !== keys.sort().join(",")) {
    throw new Error("Unexpected dispatch fields.");
  }
}

function uid(value: unknown): string {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) {
    throw new Error("Invalid dispatch identity.");
  }
  return value;
}

function canonicalInstant(value: unknown): string {
  if (typeof value !== "string") throw new Error("Verification time required.");
  const date = new Date(value);
  if (!Number.isFinite(date.getTime()) || date.toISOString() !== value) {
    throw new Error("Verification time must be canonical UTC.");
  }
  return value;
}

export function parseAccountDeletionDispatchPlan(
  value: unknown
): AccountDeletionDispatchPlan {
  const data = record(value);
  exact(data, [
    "schemaVersion",
    "projectId",
    "sourceSha",
    "actorUid",
    "targetUid",
    "caseReference",
    "verificationMethod",
    "verificationCompletedAt",
  ]);
  if (
    data.schemaVersion !== 1 ||
    data.projectId !== REPAIR_PROJECT ||
    typeof data.sourceSha !== "string" ||
    !/^[a-f0-9]{40}$/.test(data.sourceSha) ||
    typeof data.caseReference !== "string" ||
    !/^[A-Z0-9-]{8,64}$/.test(data.caseReference) ||
    !METHODS.includes(data.verificationMethod as VerificationMethod)
  ) {
    throw new Error("Dispatch plan identity differs.");
  }
  const actorUid = uid(data.actorUid);
  const targetUid = uid(data.targetUid);
  if (actorUid === targetUid) {
    throw new Error("Use the in-app route for an operator's own account.");
  }
  return {
    schemaVersion: 1,
    projectId: REPAIR_PROJECT,
    sourceSha: data.sourceSha,
    actorUid,
    targetUid,
    caseReference: data.caseReference,
    verificationMethod: data.verificationMethod as VerificationMethod,
    verificationCompletedAt: canonicalInstant(data.verificationCompletedAt),
  };
}

export function accountDeletionDispatchDigest(value: unknown): string {
  return createHash("sha256")
    .update(JSON.stringify(parseAccountDeletionDispatchPlan(value)))
    .digest("hex");
}

export function parseAccountDeletionDispatchArguments(args: string[]) {
  const first = args[0];
  const mode = first === "apply" ? "apply" : "plan";
  const rest = first === "plan" || first === "apply" ? args.slice(1) : args;
  const values: Record<string, string> = {};
  const allowed = new Set([
    "--project",
    "--source-sha",
    "--credential",
    "--plan",
    "--operator-uid",
    "--target-uid",
    "--case",
    "--verification-method",
    "--verified-at",
    "--digest",
  ]);
  for (let index = 0; index < rest.length; index += 2) {
    const key = rest[index];
    const value = rest[index + 1];
    if (
      !allowed.has(key) ||
      values[key] !== undefined ||
      !value ||
      value.startsWith("--")
    ) {
      throw new Error("Unknown, duplicate, or missing dispatch option.");
    }
    values[key] = value;
  }
  if (
    values["--project"] !== REPAIR_PROJECT ||
    !/^[a-f0-9]{40}$/.test(values["--source-sha"] ?? "") ||
    !isAbsolute(values["--credential"] ?? "") ||
    !isAbsolute(values["--plan"] ?? "")
  ) {
    throw new Error(
      "Explicit project, reviewed source, credential, and plan paths required."
    );
  }
  if (mode === "apply") {
    if (
      !/^[a-f0-9]{64}$/.test(values["--digest"] ?? "") ||
      [
        "--operator-uid",
        "--target-uid",
        "--case",
        "--verification-method",
        "--verified-at",
      ].some((key) => values[key] !== undefined)
    ) {
      throw new Error("Apply derives exact scope only from the reviewed plan.");
    }
  } else {
    if (values["--digest"] !== undefined) {
      throw new Error("Plan does not accept an apply digest.");
    }
    parseAccountDeletionDispatchPlan({
      schemaVersion: 1,
      projectId: REPAIR_PROJECT,
      sourceSha: values["--source-sha"],
      actorUid: values["--operator-uid"],
      targetUid: values["--target-uid"],
      caseReference: values["--case"],
      verificationMethod: values["--verification-method"],
      verificationCompletedAt: values["--verified-at"],
    });
  }
  return { mode, values };
}

export function privateAccountDeletionPlanPath(root: string, path: string): void {
  const privateRoot = resolve(root, ".private-report-repair");
  if (
    !isAbsolute(path) ||
    dirname(path) !== privateRoot ||
    realpathSync(dirname(path)) !== privateRoot ||
    !path.startsWith(privateRoot + sep)
  ) {
    throw new Error(
      "Deletion plans belong directly in the ignored private directory."
    );
  }
}

async function requireDispatchAuthority(params: {
  plan: AccountDeletionDispatchPlan;
  firestore: admin.firestore.Firestore;
  auth: admin.auth.Auth;
}): Promise<boolean> {
  const [actor, actorDeletion, targetDeletion, targetAuth] = await Promise.all([
    params.firestore.collection("profiles").doc(params.plan.actorUid).get(),
    params.firestore
      .collection("accountDeletionJobs")
      .doc(params.plan.actorUid)
      .get(),
    params.firestore
      .collection("accountDeletionJobs")
      .doc(params.plan.targetUid)
      .get(),
    params.auth.getUser(params.plan.targetUid).catch((error: unknown) => {
      if (
        (error as { code?: unknown } | undefined)?.code ===
        "auth/user-not-found"
      ) {
        return null;
      }
      throw error;
    }),
  ]);
  const actorData = actor.data();
  if (
    !actorData ||
    actorData.role !== "operator" ||
    actorData.banned !== false ||
    actorData.deletionPending === true ||
    actorDeletion.exists
  ) {
    throw new Error("Active operator access required.");
  }
  if (targetAuth === null && !targetDeletion.exists) {
    throw new Error("Deletion target has no Auth user or resumable job.");
  }
  return targetAuth !== null;
}

async function main(args: string[]): Promise<void> {
  const { mode, values } = parseAccountDeletionDispatchArguments(args);
  if (process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error("Production deletion dispatch refuses emulator redirection.");
  }
  const root = resolve(__dirname, "../..");
  const sourceSha = values["--source-sha"];
  requireReviewedSource(root, sourceSha, [
    "functions/src",
    "firestore.rules",
    "storage.rules",
  ]);
  privateAccountDeletionPlanPath(root, values["--plan"]);
  const credential = controlCredential(readPrivateJson(values["--credential"]));
  const app = admin.initializeApp(
    {
      projectId: REPAIR_PROJECT,
      credential: admin.credential.cert(credential),
    },
    "account-deletion-dispatch"
  );
  try {
    const firestore = app.firestore();
    const auth = app.auth();
    if (mode === "plan") {
      const plan = parseAccountDeletionDispatchPlan({
        schemaVersion: 1,
        projectId: REPAIR_PROJECT,
        sourceSha,
        actorUid: values["--operator-uid"],
        targetUid: values["--target-uid"],
        caseReference: values["--case"],
        verificationMethod: values["--verification-method"],
        verificationCompletedAt: values["--verified-at"],
      });
      await requireDispatchAuthority({ plan, firestore, auth });
      writeFileSync(values["--plan"], JSON.stringify(plan, null, 2) + "\n", {
        flag: "wx",
        mode: 0o600,
      });
      console.log(JSON.stringify({
        mode,
        caseReference: plan.caseReference,
        digest: accountDeletionDispatchDigest(plan),
      }));
      return;
    }

    const plan = parseAccountDeletionDispatchPlan(
      readPrivateJson(values["--plan"])
    );
    if (
      plan.sourceSha !== sourceSha ||
      accountDeletionDispatchDigest(plan) !== values["--digest"]
    ) {
      throw new Error("Reviewed deletion dispatch plan differs.");
    }
    const targetAuthExists = await requireDispatchAuthority({
      plan,
      firestore,
      auth,
    });
    const dispatch: VerifiedAccountDeletionDispatch = {
      actorUid: plan.actorUid,
      targetUid: plan.targetUid,
      caseReference: plan.caseReference,
      verificationMethod: plan.verificationMethod,
      verificationCompletedAt: admin.firestore.Timestamp.fromDate(
        new Date(plan.verificationCompletedAt)
      ),
      targetAuthExists,
    };
    await requestVerifiedAccountDeletion({
      dispatch,
      firestore,
      now: () => admin.firestore.Timestamp.now(),
    });
    console.log(JSON.stringify({
      mode,
      caseReference: plan.caseReference,
      deletionAccepted: true,
    }));
  } finally {
    await app.delete();
  }
}

if (require.main === module) {
  main(process.argv.slice(2)).catch(() => {
    console.error(
      "Deletion dispatch stopped. Do not infer acceptance or delete Auth manually; inspect the private plan and durable job before retrying."
    );
    process.exitCode = 1;
  });
}
