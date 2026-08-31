import * as admin from "firebase-admin";
import { createHash } from "crypto";
import { realpathSync, writeFileSync } from "fs";
import { dirname, isAbsolute, resolve } from "path";
import { OperationalControl, parseOperationalControl } from "./operational_control";
import { readPrivateJson, requireReviewedSource } from "./report_repair_cli";
import { REPAIR_PROJECT } from "./report_repair";

type Version = { seconds: number; nanoseconds: number };
export type ControlObservation = { control: OperationalControl | null; updateTime: Version | null };
export type ControlPlan = {
  schemaVersion: 1;
  projectId: typeof REPAIR_PROJECT;
  sourceSha: string;
  expected: ControlObservation;
  target: OperationalControl;
};
type DesiredControl = Pick<OperationalControl, "mode" | "destructiveWorkersEnabled">;

function record(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw Error("Expected an exact object.");
  return value as Record<string, unknown>;
}

function exact(value: Record<string, unknown>, keys: string[]): void {
  if (Object.keys(value).sort().join(",") !== keys.sort().join(",")) throw Error("Unexpected control fields.");
}

function control(value: unknown): OperationalControl {
  const parsed = parseOperationalControl(value);
  if (!parsed) throw Error("Invalid operational control; manual investigation required.");
  // Canonical order makes a reviewed digest independent of JSON key order.
  return { schemaVersion: 1, generation: parsed.generation, mode: parsed.mode,
    destructiveWorkersEnabled: parsed.destructiveWorkersEnabled };
}

function observation(value: unknown): ControlObservation {
  const data = record(value);
  exact(data, ["control", "updateTime"]);
  if (data.control === null && data.updateTime === null) return { control: null, updateTime: null };
  const version = record(data.updateTime);
  exact(version, ["seconds", "nanoseconds"]);
  const { seconds, nanoseconds } = version;
  if (typeof seconds !== "number" || !Number.isSafeInteger(seconds) || seconds < 0 ||
      typeof nanoseconds !== "number" || !Number.isInteger(nanoseconds) || nanoseconds < 0 || nanoseconds >= 1e9) {
    throw Error("Invalid document version.");
  }
  return { control: control(data.control), updateTime: { seconds, nanoseconds } };
}

function fromSnapshot(snapshot: admin.firestore.DocumentSnapshot): ControlObservation {
  if (!snapshot.exists) return { control: null, updateTime: null };
  const time = snapshot.updateTime;
  if (!time) throw Error("Existing control has no version.");
  return observation({ control: snapshot.data(), updateTime: { seconds: time.seconds, nanoseconds: time.nanoseconds } });
}

export function parseControlPlan(value: unknown): ControlPlan {
  const data = record(value);
  exact(data, ["schemaVersion", "projectId", "sourceSha", "expected", "target"]);
  if (data.schemaVersion !== 1 || data.projectId !== REPAIR_PROJECT ||
      typeof data.sourceSha !== "string" || !/^[a-f0-9]{40}$/.test(data.sourceSha)) throw Error("Control plan identity differs.");
  const expected = observation(data.expected);
  const target = control(data.target);
  if (target.generation !== (expected.control?.generation ?? 0) + 1) throw Error("Generation must advance exactly once.");
  if (expected.control === null) {
    if (target.mode !== "maintenance" || target.destructiveWorkersEnabled) throw Error("Initial control must be closed.");
  } else if (target.mode === expected.control.mode &&
      target.destructiveWorkersEnabled === expected.control.destructiveWorkersEnabled) throw Error("No control transition requested.");
  return { schemaVersion: 1, projectId: REPAIR_PROJECT, sourceSha: data.sourceSha, expected, target };
}

export function controlPlanDigest(value: unknown): string {
  return createHash("sha256").update(JSON.stringify(parseControlPlan(value))).digest("hex");
}

export async function readControl(firestore: admin.firestore.Firestore): Promise<ControlObservation> {
  return fromSnapshot(await firestore.doc("operationalControls/v1").get());
}

export async function planControl(firestore: admin.firestore.Firestore, sourceSha: string,
  desired: DesiredControl): Promise<ControlPlan> {
  // Reject bad arguments before any database access.
  if (!/^[a-f0-9]{40}$/.test(sourceSha)) throw Error("Reviewed source SHA required.");
  control({ schemaVersion: 1, generation: 1, ...desired });
  const expected = await readControl(firestore);
  return parseControlPlan({ schemaVersion: 1, projectId: REPAIR_PROJECT, sourceSha, expected,
    target: { schemaVersion: 1, generation: (expected.control?.generation ?? 0) + 1, ...desired } });
}

class StaleControlPlan extends Error {}
const same = (left: unknown, right: unknown) => JSON.stringify(left) === JSON.stringify(right);

export async function applyControl(firestore: admin.firestore.Firestore, sourceSha: string,
  value: unknown, approvedDigest: string): Promise<{ result: "target-observed"; control: OperationalControl }> {
  const plan = parseControlPlan(value);
  if (plan.sourceSha !== sourceSha || !/^[a-f0-9]{64}$/.test(approvedDigest) ||
      controlPlanDigest(plan) !== approvedDigest) throw Error("Reviewed control plan differs.");
  const ref = firestore.doc("operationalControls/v1");
  try {
    await firestore.runTransaction(async (transaction) => {
      const current = fromSnapshot(await transaction.get(ref));
      // Observing an existing target proves neither authorship nor write access.
      // A read-capable duplicate needs no mutation. Never advance again.
      if (same(current.control, plan.target)) return;
      if (!same(current, plan.expected)) throw new StaleControlPlan("Control changed; stop and review a fresh plan.");
      if (current.control === null) transaction.create(ref, plan.target);
      else transaction.set(ref, plan.target);
    }, { maxAttempts: 3 });
  } catch (error) {
    if (error instanceof StaleControlPlan) throw error;
    // A transport error may follow a commit. Readback alone establishes state,
    // not write capability; its validation/read error can replace this cause.
    // Keep raw SDK errors private. No compensating write or automatic retry.
  }
  const observed = await readControl(firestore);
  if (!same(observed.control, plan.target)) throw Error("Control write unconfirmed; inspect state before retrying.");
  return { result: "target-observed", control: plan.target };
}

export function parseControlArguments(args: string[]) {
  const commands = ["read", "plan", "apply"] as const;
  const first = args[0];
  const mode = first === "plan" || first === "apply" ? first : "read";
  const rest = commands.some((item) => item === first) ? args.slice(1) : args;
  const values: Record<string, string> = {};
  const allowed = new Set(["--project", "--source-sha", "--credential", "--plan", "--mode", "--workers", "--digest"]);
  for (let index = 0; index < rest.length; index += 2) {
    const key = rest[index], value = rest[index + 1];
    if (!allowed.has(key) || values[key] !== undefined || !value || value.startsWith("--")) throw Error("Unknown, duplicate or missing control option.");
    values[key] = value;
  }
  if (values["--project"] !== REPAIR_PROJECT || !/^[a-f0-9]{40}$/.test(values["--source-sha"] ?? "") ||
      !isAbsolute(values["--credential"] ?? "")) throw Error("Explicit project, reviewed SHA and absolute credential path required.");
  if (mode === "read") {
    if (["--plan", "--mode", "--workers", "--digest"].some((key) => values[key] !== undefined)) throw Error("Read accepts no transition options.");
  } else {
    if (!isAbsolute(values["--plan"] ?? "")) throw Error("Absolute private plan path required.");
    if (mode === "apply") {
      if (!/^[a-f0-9]{64}$/.test(values["--digest"] ?? "") || values["--mode"] !== undefined || values["--workers"] !== undefined) throw Error("Apply takes only the reviewed plan and digest.");
    } else {
      if (!["true", "false"].includes(values["--workers"]) || values["--digest"] !== undefined) throw Error("Plan requires an explicit worker flag and no apply digest.");
      control({ schemaVersion: 1, generation: 1, mode: values["--mode"], destructiveWorkersEnabled: values["--workers"] === "true" });
    }
  }
  return { mode, values };
}

export function privateControlPlanPath(root: string, path: string): void {
  const privateRoot = resolve(root, ".private-report-repair");
  if (!isAbsolute(path) || dirname(path) !== privateRoot || realpathSync(dirname(path)) !== privateRoot) {
    throw Error("Control plans belong directly in the ignored .private-report-repair directory.");
  }
}

export function controlCredential(value: unknown): admin.ServiceAccount {
  const credential = record(value);
  if (credential.type !== "service_account" || credential.project_id !== REPAIR_PROJECT ||
      typeof credential.client_email !== "string" || !credential.client_email ||
      typeof credential.private_key !== "string" || !credential.private_key) throw Error("Credential identity differs.");
  return { projectId: REPAIR_PROJECT, clientEmail: credential.client_email, privateKey: credential.private_key };
}

async function main(args: string[]): Promise<void> {
  const { mode, values } = parseControlArguments(args);
  // Production CLI never silently follows emulator environment overrides.
  if (process.env.FIRESTORE_EMULATOR_HOST) throw Error("Production control CLI refuses emulator redirection.");
  const root = resolve(__dirname, "../..");
  const sourceSha = values["--source-sha"];
  requireReviewedSource(root, sourceSha, []);
  if (mode !== "read") privateControlPlanPath(root, values["--plan"]);
  let plan: ControlPlan | undefined;
  if (mode === "apply") {
    plan = parseControlPlan(readPrivateJson(values["--plan"]));
    if (plan.sourceSha !== sourceSha || controlPlanDigest(plan) !== values["--digest"]) throw Error("Reviewed plan differs.");
  }
  const credential = controlCredential(readPrivateJson(values["--credential"]));
  const app = admin.initializeApp({ projectId: REPAIR_PROJECT, credential: admin.credential.cert(credential) }, "operational-control-cli");
  try {
    const firestore = app.firestore();
    if (mode === "read") console.log(JSON.stringify({ mode, state: await readControl(firestore) }));
    else if (mode === "plan") {
      const desired = control({ schemaVersion: 1, generation: 1, mode: values["--mode"],
        destructiveWorkersEnabled: values["--workers"] === "true" });
      const result = await planControl(firestore, sourceSha, { mode: desired.mode, destructiveWorkersEnabled: desired.destructiveWorkersEnabled });
      writeFileSync(values["--plan"], JSON.stringify(result, null, 2) + "\n", { flag: "wx", mode: 0o600 });
      console.log(JSON.stringify({ mode, target: result.target, digest: controlPlanDigest(result) }));
    } else {
      console.log(JSON.stringify({ mode, ...await applyControl(firestore, sourceSha, plan, values["--digest"]) }));
    }
  } finally { await app.delete(); }
}

if (require.main === module) main(process.argv.slice(2)).catch(() => {
  console.error("Operational control stopped. Do not infer success or advance generation; inspect the private plan and current control before retrying.");
  process.exitCode = 1;
});
