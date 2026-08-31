import * as admin from "firebase-admin";
import { execFileSync } from "child_process";
import { readFileSync, writeFileSync, lstatSync, realpathSync } from "fs";
import { dirname, isAbsolute, resolve, sep } from "path";
import { applyReportRepair, planReportRepair, REPAIR_PROJECT, repairDigest, RepairKind, validateRepairPlan } from "./report_repair";
import { reportCutoverNextStep, CutoverEvidence } from "./report_cutover";

export function parseRepairArguments(args: string[]) {
  const values: Record<string, string> = {};
  const allowed = new Set(["--project", "--source-sha", "--credential", "--plan", "--kind", "--after", "--digest", "--cutover"]);
  const mode = args[0] === "apply" ? "apply" : "plan";
  const rest = args[0] === "plan" || args[0] === "apply" ? args.slice(1) : args;
  for (let index = 0; index < rest.length; index += 2) {
    const key = rest[index], value = rest[index + 1];
    if (!allowed.has(key) || values[key] !== undefined || !value || value.startsWith("--")) throw new Error("Unknown, duplicate, or missing repair option.");
    values[key] = value;
  }
  if (values["--project"] !== REPAIR_PROJECT || !/^[a-f0-9]{40}$/.test(values["--source-sha"] ?? "")) throw new Error("Explicit project and reviewed source SHA required.");
  for (const key of ["--credential", "--plan", "--cutover"]) if (!isAbsolute(values[key] ?? "")) throw new Error("Absolute private-file paths required.");
  if (mode === "apply") {
    if (!/^[a-f0-9]{64}$/.test(values["--digest"] ?? "") || values["--kind"] || values["--after"]) throw new Error("Apply requires an exact digest and derives scope only from the plan.");
  } else if (!["chants", "comments"].includes(values["--kind"]) || values["--digest"] ||
      (values["--after"] !== undefined && !/^[A-Za-z0-9_-]{1,200}$/.test(values["--after"]))) throw new Error("Plan requires an explicit scope and no apply digest.");
  return { mode, values };
}

export function readPrivateJson(path: string): unknown {
  const stat = lstatSync(path);
  if (!stat.isFile() || stat.isSymbolicLink() || (stat.mode & 0o077) !== 0 || stat.size > 1024 * 1024) throw new Error("Expected an owner-only regular JSON file, at most 1 MiB.");
  return JSON.parse(readFileSync(path, "utf8"));
}

export function requireReviewedSource(root: string, sourceSha: string,
  paths = ["functions/src", "firestore.rules", "storage.rules"]): void {
  if (execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim() !== sourceSha ||
      execFileSync("git", ["status", "--porcelain", "--", ...paths], { cwd: root, encoding: "utf8" }).trim()) throw new Error("Operation needs the clean reviewed source checkout.");
}

async function main(args: string[]): Promise<void> {
  const { mode, values } = parseRepairArguments(args);
  const root = resolve(__dirname, "../..");
  const sourceSha = values["--source-sha"];
  requireReviewedSource(root, sourceSha);
  const privateRoot = resolve(root, ".private-report-repair");
  const planPath = values["--plan"];
  if (dirname(planPath) !== privateRoot || realpathSync(dirname(planPath)) !== privateRoot ||
      !planPath.startsWith(privateRoot + sep)) throw new Error("Plans belong directly in the ignored .private-report-repair directory.");
  const credential = readPrivateJson(values["--credential"]);
  if (!credential || typeof credential !== "object" || Array.isArray(credential) ||
      (credential as { project_id?: unknown }).project_id !== REPAIR_PROJECT ||
      (credential as { type?: unknown }).type !== "service_account" ||
      typeof (credential as { client_email?: unknown }).client_email !== "string" ||
      typeof (credential as { private_key?: unknown }).private_key !== "string") throw new Error("Credential project or identity differs.");
  const account = credential as { client_email: string; private_key: string };
  // These are operator-reviewed attestations, not a claim that this CLI can
  // independently prove live revision, traffic, IAM, or in-flight containment.
  const evidence = readPrivateJson(values["--cutover"]) as CutoverEvidence;
  const next = reportCutoverNextStep(evidence);
  if (evidence.sourceSha !== sourceSha || next === "isolate-old-targets" || next.startsWith("replace-")) {
    throw new Error("Report cutover is not ready for repair.");
  }
  let plan: unknown;
  if (mode === "apply") {
    plan = readPrivateJson(planPath); validateRepairPlan(plan);
    if (plan.sourceSha !== sourceSha || plan.generation !== evidence.generation || repairDigest(plan) !== values["--digest"]) throw new Error("Reviewed plan or containment evidence differs.");
  }
  const app = admin.initializeApp({ projectId: REPAIR_PROJECT, credential: admin.credential.cert({
    projectId: REPAIR_PROJECT, clientEmail: account.client_email, privateKey: account.private_key,
  }) }, "report-repair");
  try {
    const firestore = app.firestore();
    const now = () => admin.firestore.Timestamp.now();
    if (mode === "plan") {
      const result = await planReportRepair({ firestore, projectId: REPAIR_PROJECT, sourceSha,
        kind: values["--kind"] as RepairKind, startAfter: values["--after"], cutover: evidence, now });
      writeFileSync(planPath, JSON.stringify(result, null, 2) + "\n", { flag: "wx", mode: 0o600 });
      console.log(JSON.stringify({ mode, targets: result.targets.length, digest: repairDigest(result), endOfCollection: result.endOfCollection }));
    } else {
      const result = await applyReportRepair({ firestore, projectId: REPAIR_PROJECT, sourceSha, plan,
        digest: values["--digest"], cutover: evidence, now });
      console.log(JSON.stringify({ mode, completed: result.completed, endOfCollection: result.endOfCollection }));
    }
  } finally { await app.delete(); }
}

if (require.main === module) {
  main(process.argv.slice(2)).catch(() => {
    // No credentials, reporter text, target IDs, or raw SDK payloads in logs.
    console.error("Report repair stopped. No further targets will be processed; inspect the private plan and current control before retrying.");
    process.exitCode = 1;
  });
}
