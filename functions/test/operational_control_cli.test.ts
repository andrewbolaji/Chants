import { strict as assert } from "assert";
import { execFileSync, spawnSync } from "child_process";
import { chmodSync, mkdtempSync, mkdirSync, readFileSync, realpathSync, rmSync, symlinkSync, writeFileSync } from "fs";
import { tmpdir } from "os";
import { resolve } from "path";
import { ControlPlan, controlCredential, controlPlanDigest, parseControlArguments, parseControlPlan, privateControlPlanPath } from "../src/operational_control_cli";
import { readPrivateJson, requireReviewedSource } from "../src/report_repair_cli";

const sha = "a".repeat(40);
const closed = { schemaVersion: 1 as const, generation: 7, mode: "maintenance" as const, destructiveWorkersEnabled: false };
const plan: ControlPlan = { schemaVersion: 1, projectId: "chants-f95b4", sourceSha: sha,
  expected: { control: closed, updateTime: { seconds: 100, nanoseconds: 1 } },
  target: { ...closed, generation: 8, mode: "core" } };

describe("private operational control plan and command", () => {
  it("accepts closed creation, legal transitions and key-order-independent exact digests", () => {
    assert.deepEqual(parseControlPlan(plan), plan);
    const initial = { ...plan, expected: { control: null, updateTime: null }, target: { ...closed, generation: 1 } };
    assert.deepEqual(parseControlPlan(initial), initial);
    const shuffled = JSON.parse(JSON.stringify(plan, Object.keys(plan).concat(
      ["updateTime", "control", "mode", "generation", "destructiveWorkersEnabled", "seconds", "nanoseconds"])));
    assert.equal(controlPlanDigest(shuffled), controlPlanDigest(plan));
    assert.notEqual(controlPlanDigest({ ...plan, target: { ...plan.target, destructiveWorkersEnabled: true } }), controlPlanDigest(plan));
  });

  it("rejects changed identity, unknown fields, malformed versions, unsafe creation and skipped/overflowed generations", () => {
    const invalid: unknown[] = [null, [], {}, { ...plan, extra: true }, { ...plan, schemaVersion: 2 },
      { ...plan, projectId: "other" }, { ...plan, sourceSha: "main" },
      { ...plan, expected: { control: null, updateTime: plan.expected.updateTime } },
      { ...plan, expected: { control: closed, updateTime: null } },
      { ...plan, expected: { ...plan.expected, extra: true } },
      { ...plan, expected: { ...plan.expected, control: { ...closed, unexpected: "do-not-erase" } } },
      { ...plan, expected: { control: null, updateTime: null }, target: { ...plan.target, generation: 1 } },
      { ...plan, expected: { control: null, updateTime: null }, target: { ...closed, generation: 1, destructiveWorkersEnabled: true } },
      { ...plan, target: { ...plan.target, generation: 9 } }, { ...plan, target: { ...plan.target, generation: 7 } },
      { ...plan, target: { ...plan.target, extra: true } }, { ...plan, target: { ...plan.target, mode: "media" } },
      { ...plan, target: { ...closed, generation: 8 } },
      { ...plan, expected: { ...plan.expected, control: { ...closed, generation: Number.MAX_SAFE_INTEGER } },
        target: { ...plan.target, generation: Number.MAX_SAFE_INTEGER + 1 } }];
    for (const version of [{ seconds: -1, nanoseconds: 0 }, { seconds: 1, nanoseconds: 1e9 },
      { seconds: 1, nanoseconds: -1 }, { seconds: 1.5, nanoseconds: 0 }, { seconds: 1, nanoseconds: 0, extra: true }]) {
      invalid.push({ ...plan, expected: { ...plan.expected, updateTime: version } });
    }
    for (const value of invalid) assert.throws(() => parseControlPlan(value));
  });

  it("rejects a credential for a different project or identity shape before SDK initialization", () => {
    const fixture = { type: "service_account", project_id: "chants-f95b4", client_email: "synthetic@chants.invalid", private_key: "not-a-real-key" };
    assert.deepEqual(controlCredential(fixture), { projectId: "chants-f95b4", clientEmail: fixture.client_email, privateKey: fixture.private_key });
    for (const value of [null, [], {}, { ...fixture, type: "authorized_user" }, { ...fixture, project_id: "other" },
      { ...fixture, client_email: null }, { ...fixture, client_email: "" }, { ...fixture, private_key: null }, { ...fixture, private_key: "" }]) {
      assert.throws(() => controlCredential(value), /identity|object/);
    }
  });

  const args = ["--project", "chants-f95b4", "--source-sha", sha, "--credential", "/private/key.json"];
  it("defaults to read, never infers apply, and requires explicit transition/digest arguments", () => {
    assert.equal(parseControlArguments(args).mode, "read");
    assert.equal(parseControlArguments(["read", ...args]).mode, "read");
    const planning = ["plan", ...args, "--plan", "/private/control.json", "--mode", "core", "--workers", "false"];
    assert.equal(parseControlArguments(planning).mode, "plan");
    assert.equal(parseControlArguments(["apply", ...args, "--plan", "/private/control.json", "--digest", controlPlanDigest(plan)]).mode, "apply");
    for (const invalid of [[], ["write", ...args], ["apply", ...args], [...args, "--workers", "true"],
      [...args, "--credential", "/another"], [...args, "--force", "true"],
      args.map(v => v === "chants-f95b4" ? "other" : v), args.map(v => v === sha ? "main" : v),
      args.map(v => v === "/private/key.json" ? "key.json" : v),
      [...planning, "--digest", controlPlanDigest(plan)], planning.map(v => v === "false" ? "yes" : v),
      planning.map(v => v === "core" ? "media" : v), planning.slice(0, -1),
      ["apply", ...args, "--plan", "/private/control.json", "--digest", controlPlanDigest(plan), "--mode", "core"]]) {
      assert.throws(() => parseControlArguments(invalid));
    }
  });

  let temp: string;
  beforeEach(() => { temp = realpathSync(mkdtempSync(resolve(tmpdir(), "chants-control-cli-test-"))); });
  afterEach(() => { rmSync(temp, { recursive: true, force: true }); });

  it("reuses private-file protections and rejects escaping or symlinked plan directories", () => {
    const key = resolve(temp, "private.json");
    writeFileSync(key, "{}", { mode: 0o600 });
    assert.deepEqual(readPrivateJson(key), {});
    chmodSync(key, 0o644); assert.throws(() => readPrivateJson(key)); chmodSync(key, 0o600);
    symlinkSync(key, resolve(temp, "link.json")); assert.throws(() => readPrivateJson(resolve(temp, "link.json")));
    writeFileSync(key, "x".repeat(1024 * 1024 + 1)); assert.throws(() => readPrivateJson(key));
    writeFileSync(key, "not JSON"); assert.throws(() => readPrivateJson(key));
    assert.throws(() => readPrivateJson(temp));
    const privateDir = resolve(temp, ".private-report-repair");
    mkdirSync(privateDir);
    privateControlPlanPath(temp, resolve(privateDir, "control.json"));
    assert.throws(() => privateControlPlanPath(temp, key));
    mkdirSync(resolve(privateDir, "child"));
    assert.throws(() => privateControlPlanPath(temp, resolve(privateDir, "child/control.json")));
    const other = resolve(temp, "other"); mkdirSync(other);
    symlinkSync(privateDir, resolve(other, ".private-report-repair"));
    assert.throws(() => privateControlPlanPath(other, resolve(other, ".private-report-repair/control.json")));
  });

  it("pins exact HEAD and rejects staged, unstaged and untracked input without reading credentials", () => {
    const git = (...command: string[]) => execFileSync("git", command, { cwd: temp, encoding: "utf8", stdio: "pipe" }).trim();
    git("init", "-q"); git("config", "user.name", "Synthetic control test"); git("config", "user.email", "test@chants.invalid");
    const file = resolve(temp, "source.txt"); writeFileSync(file, "original"); git("add", "."); git("commit", "-qm", "fixture");
    const head = git("rev-parse", "HEAD"); requireReviewedSource(temp, head, []);
    assert.throws(() => requireReviewedSource(temp, sha, []));
    writeFileSync(file, "changed"); assert.throws(() => requireReviewedSource(temp, head, []));
    git("add", "."); assert.throws(() => requireReviewedSource(temp, head, []));
    git("commit", "-qm", "fixture update"); writeFileSync(resolve(temp, "untracked.txt"), "untracked");
    assert.throws(() => requireReviewedSource(temp, git("rev-parse", "HEAD"), []));
  });

  it("runs the real CLI entrypoint fail-closed without logging private arguments or using a cloud credential", () => {
    const entry = resolve(__dirname, "../src/operational_control_cli.js");
    const result = spawnSync(process.execPath, [entry, "apply", ...args, "--unrecognized", "DO_NOT_PRINT_PRIVATE_INPUT"],
      { encoding: "utf8", timeout: 10000 });
    assert.equal(result.status, 1); assert.equal(result.stdout, "");
    assert.match(result.stderr, /Operational control stopped/);
    assert(!result.stderr.includes("DO_NOT_PRINT_PRIVATE_INPUT")); assert(!result.stderr.includes("key.json"));
    const redirected = spawnSync(process.execPath, [entry, ...args],
      { encoding: "utf8", timeout: 10000, env: { ...process.env, FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" } });
    assert.equal(redirected.status, 1); assert.equal(redirected.stdout, "");
    assert.equal(readFileSync(resolve(__dirname, "../../package.json"), "utf8").includes('"node": "22"'), true);
  });
});
