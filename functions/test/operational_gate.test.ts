import * as assert from "assert";
import * as admin from "firebase-admin";
import * as endpoints from "../src/index";
import * as gate from "../src/operational_gate";
import { admissionAllowed, ENDPOINT_ADMISSION, parseOperationalControl } from "../src/operational_control";
import { readFileSync } from "fs";
import { resolve } from "path";

const media = { schemaVersion: 1, generation: 7, mode: "media", destructiveWorkersEnabled: true };
const core = { ...media, mode: "core", destructiveWorkersEnabled: false };
const closed = { ...media, mode: "maintenance" };
const auth = { uid: "fan", token: { email_verified: true } };
const db = admin.firestore();
const original = db.collection;
let control: unknown;
let failedRead = false;
let handlerReads = 0;
const handlerReached = new Error("handler reached");

beforeEach(() => {
  control = undefined; failedRead = false; handlerReads = 0;
  // Test-only SDK boundary: every non-control read fails before network access.
  Object.defineProperty(db, "collection", { configurable: true, value: (name: string) => {
    if (name !== "operationalControls") { handlerReads++; throw handlerReached; }
    return { doc: (id: string) => {
      assert.strictEqual(id, "v1");
      return { get: async () => { if (failedRead) throw Error("offline"); return { data: () => control }; } };
    } };
  } });
});
afterEach(() => Object.defineProperty(db, "collection", { configurable: true, value: original }));

describe("operational admission at exported wrappers", () => {
  it("classifies exactly every compiled endpoint and no helper", () => {
    const names = Object.entries(endpoints).filter(([, value]) =>
      typeof value === "function" && "__endpoint" in value).map(([name]) => name).sort();
    assert.strictEqual(names.length, 48);
    assert.deepStrictEqual(names, Object.keys(ENDPOINT_ADMISSION).sort());
  });

  it("rejects malformed controls and media without workers", () => {
    for (const value of [null, [], {}, { ...media, extra: true }, { ...media, schemaVersion: 2 },
      { ...media, generation: 0 }, { ...media, generation: 1.5 }, { ...media, generation: Number.MAX_SAFE_INTEGER + 1 },
      { ...media, mode: "open" }, { ...media, destructiveWorkersEnabled: false }]) {
      assert.strictEqual(parseOperationalControl(value), null);
    }
    assert.ok(admissionAllowed("core", parseOperationalControl(core)));
    assert.ok(!admissionAllowed("workers", parseOperationalControl(core)));
    assert.ok(!admissionAllowed("workers", parseOperationalControl(closed)));
    assert.ok(!admissionAllowed("media", parseOperationalControl(core)));
    assert.ok(!admissionAllowed("disabled", parseOperationalControl(media)));
    assert.ok(admissionAllowed("reconciler", null));
    assert.ok(admissionAllowed("monitor", null));
  });

  for (const [name, classification] of Object.entries(ENDPOINT_ADMISSION)) {
    const endpoint = endpoints[name as keyof typeof ENDPOINT_ADMISSION];
    if (!("run" in endpoint) || !("__endpoint" in endpoint) || !("callableTrigger" in endpoint.__endpoint) || classification === "disabled") continue;
    it(`${name}: rejects closed/missing/unreadable control before the real handler`, async () => {
      for (const state of [undefined, closed, { ...media, mode: "invalid" }]) {
        control = state;
        await assert.rejects(endpoint.run({ auth, data: { targetType: "performance" } } as never),
          (error: { code?: string; details?: { reason?: string } }) => error.code === "unavailable" && error.details?.reason === "maintenance");
      }
      control = media; failedRead = true;
      await assert.rejects(endpoint.run({ auth, data: {} } as never), (error: { code?: string }) => error.code === "unavailable");
      assert.strictEqual(handlerReads, 0);
      failedRead = false;
      control = media;
      await assert.rejects(endpoint.run({ auth, data: {} } as never),
        (error: { code?: string }) => error.code !== "unavailable");
      if (classification === "media") {
        control = core;
        await assert.rejects(endpoint.run({ auth, data: {} } as never),
          (error: { code?: string }) => error.code === "unavailable");
      }
      if (name !== "resolvePublicShareDestination") {
        await assert.rejects(endpoint.run({ data: {} } as never), (error: { code?: string }) => error.code === "unauthenticated");
      }
    });
  }

  it("does not cache an open control across invocations", async () => {
    control = media;
    await assert.rejects(endpoints.updateCreatorProfile.run({ auth, data: {} } as never));
    control = closed;
    await assert.rejects(endpoints.updateCreatorProfile.run({ auth, data: {} } as never),
      (error: { code?: string }) => error.code === "unavailable");
  });

  it("the actual callable regression detects a deliberately bypassed admission gate", async () => {
    control = closed;
    const expectClosed = () => assert.rejects(endpoints.updateCreatorProfile.run({ auth, data: {} } as never),
      (error: { code?: string }) => error.code === "unavailable");
    await expectClosed();
    const descriptor = Object.getOwnPropertyDescriptor(gate, "requireOperationEnabled")!;
    try {
      Object.defineProperty(gate, "requireOperationEnabled", { ...descriptor, value: async () => {} });
      await assert.rejects(expectClosed(), assert.AssertionError);
    } finally { Object.defineProperty(gate, "requireOperationEnabled", descriptor); }
    await expectClosed();
  });

  it("keeps existing job documents when workers are paused", async () => {
    control = closed;
    let deletes = 0;
    const snapshot = { exists: true, data: () => ({}), ref: { delete: async () => { deletes++; } } };
    await endpoints.onAccountDeletionJobWritten.run({ data: { after: snapshot }, params: { uid: "fan" } } as never);
    await endpoints.onPerformanceMediaDeletionJobWritten.run({ data: { after: snapshot } } as never);
    await endpoints.cleanupAbandonedPerformanceDraftsJob.run({} as never);
    assert.strictEqual(deletes, 0);
    assert.strictEqual(handlerReads, 0);
  });

  it("returns no-store unavailable from the actual anonymous HTTP wrappers", async () => {
    for (const endpoint of [endpoints.publicSharePage, endpoints.publicPerformanceMedia]) {
      let status = 0; let cache = ""; let sent = false;
      const response = {
        status: (value: number) => { status = value; return response; },
        set: (key: string, value: string) => { if (key === "Cache-Control") cache = value; return response; },
        type: () => response, send: () => { sent = true; },
      };
      await endpoint({ path: "/performances/p1", headers: {} } as never, response as never);
      assert.strictEqual(status, 503); assert.strictEqual(cache, "no-store"); assert.ok(sent);
    }
    assert.strictEqual(handlerReads, 0);
  });

  it("gates every allowed direct-write rule expression", () => {
    const source = readFileSync(resolve(__dirname, "../../../firestore.rules"), "utf8");
    const expressions = [...source.matchAll(/allow ([a-z, ]+): if ([\s\S]*?);/g)]
      .filter((match) => /create|update|delete|write/.test(match[1]) && match[2].trim() !== "false");
    assert.strictEqual(expressions.length, 19);
    for (const match of expressions) assert.ok(match[2].startsWith("coreWritesEnabled() &&"), match[0]);
  });
});
