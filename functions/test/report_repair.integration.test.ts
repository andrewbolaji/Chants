import { strict as assert } from "assert";
import * as admin from "firebase-admin";
import { applyReportRepair, planReportRepair, repairDigest, RepairKind } from "../src/report_repair";
import { handleChantReportWritten, handleCommentReportWritten, onPerformanceDraftDeleted } from "../src/index";
import { handleCreatePerformanceDraft, handleCancelPerformanceDraft } from "../src/performance";
import { handleDeletedDraftCleanup } from "../src/deferred_draft_cleanup";
import { requestAccountDeletion } from "../src/account_deletion";
import { firebaseOperationalStore, ABANDONED_DRAFT_AGE_MS } from "../src/operations";
import { repairEvidence } from "./fixtures/cutover";
import { MAX_PAUSE_EVIDENCE_AGE_MS } from "../src/report_cutover";

const integration = process.env.FIRESTORE_EMULATOR_HOST === "127.0.0.1:8080" ? describe : describe.skip;
const sha = "a".repeat(40);
const now = () => admin.firestore.Timestamp.now();

integration("real-emulator report repair and upload lifecycle", function () {
  this.timeout(60000);
  let app: admin.app.App;
  let db: admin.firestore.Firestore;
  before(() => {
    // Never falls back to a credential or production target, even when the
    // ordinary Functions test suite imports this file without an emulator.
    assert.equal(process.env.FIRESTORE_EMULATOR_HOST, "127.0.0.1:8080");
    app = admin.initializeApp({ projectId: "demo-chants-repair" }, "repair-integration");
    db = app.firestore();
    admin.firestore().settings({ projectId: "demo-chants-repair" });
  });
  beforeEach(async () => {
    for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
    await db.collection("operationalControls").doc("v1").set({ schemaVersion: 1, generation: 4, mode: "maintenance", destructiveWorkersEnabled: false });
  });
  after(async () => {
    for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
    await app.delete();
    await admin.firestore().terminate();
  });
  const target = (extra = {}) => ({ flagCount: 9, hidden: false, removed: false, commentCount: 0, ...extra });
  const plan = (kind: RepairKind = "chants", startAfter?: string, generation = 4) => planReportRepair({
    firestore: db, projectId: "chants-f95b4", sourceSha: sha, kind, startAfter, now, cutover: { ...repairEvidence(), generation },
  });
  const apply = (value: Awaited<ReturnType<typeof plan>>, firestore = db) => applyReportRepair({
    firestore, projectId: "chants-f95b4", sourceSha: sha, plan: value, digest: repairDigest(value), now, cutover: repairEvidence(),
  });
  async function seedRows(collection: string, count: number, data: Record<string, unknown>) {
    for (let offset = 0; offset < count; offset += 400) {
      const batch = db.batch();
      for (let index = offset; index < Math.min(count, offset + 400); index++) batch.set(db.collection(collection).doc(`row-${index.toString().padStart(4, "0")}`), data);
      await batch.commit();
    }
  }

  it("plans without writes, covers zero-report targets, never unhides, and resumes a lost commit acknowledgement", async () => {
    await db.collection("chants").doc("chant").set(target({ hidden: true, lyrics: "Unchanged fixture" }));
    const value = await plan();
    assert.equal((await db.collection("chants").doc("chant").get()).data()!.flagCount, 9);
    assert.equal((await db.collection("auditLog").get()).size, 0);
    let calls = 0;
    const ambiguous = new Proxy(db, { get(object, property) {
      if (property === "runTransaction") return async (operation: (transaction: admin.firestore.Transaction) => Promise<unknown>) => {
        const result = await object.runTransaction(operation);
        if (++calls === 1) throw Error("lost acknowledgement after committed counter, parent, audit and progress");
        return result;
      };
      const result = Reflect.get(object, property); return typeof result === "function" ? result.bind(object) : result;
    } });
    await assert.rejects(apply(value, ambiguous));
    assert.equal((await db.collection("reportRepairProgress").get()).docs[0].data().state, "applied");
    await apply(value); await apply(value);
    const final = (await db.collection("chants").doc("chant").get()).data()!;
    assert.equal(final.flagCount, 0); assert.equal(final.hidden, true); assert.equal(final.lyrics, "Unchanged fixture");
    assert.equal((await db.collection("auditLog").get()).size, 1);
    assert.equal((await db.collection("reportRepairProgress").get()).docs[0].data().state, "complete");
    await Promise.all([handleChantReportWritten(undefined, { chantId: "chant" }, db), handleChantReportWritten({ chantId: "chant" }, undefined, db)]);
    assert.equal((await db.collection("chants").doc("chant").get()).data()!.flagCount, 0);
  });

  it("repairs auto-hide and the visible parent count together, preserving private report content", async () => {
    await db.collection("chants").doc("parent").set(target({ commentCount: 8 }));
    await db.collection("comments").doc("comment").set(target({ chantId: "parent", body: "Keep body" }));
    await seedRows("commentReports", 3, { commentId: "comment", status: "pending", reportedBy: "private-fixture", reason: "DO_NOT_COPY_REASON" });
    const value = await plan("comments");
    await apply(value); await apply(value);
    assert.equal((await db.collection("comments").doc("comment").get()).data()!.hidden, true);
    assert.equal((await db.collection("comments").doc("comment").get()).data()!.flagCount, 3);
    assert.equal((await db.collection("chants").doc("parent").get()).data()!.commentCount, 0);
    const audits = (await db.collection("auditLog").get()).docs.map((doc) => doc.data());
    assert.equal(audits.length, 1);
    assert(!JSON.stringify(audits).includes("private-fixture")); assert(!JSON.stringify(audits).includes("DO_NOT_COPY_REASON"));
    await Promise.all([handleCommentReportWritten(undefined, { commentId: "comment" }, db), handleCommentReportWritten({ commentId: "comment" }, undefined, db)]);
    assert.equal((await db.collection("comments").doc("comment").get()).data()!.flagCount, 3);
  });

  for (const kind of ["chants", "comments"] as const) {
    it(`repairs mixed and terminal-only ${kind} report history without skipping ordered targets`, async () => {
      if (kind === "comments") await db.collection("chants").doc("parent").set(target());
      for (const id of ["a-mixed", "b-terminal", "c-zero"]) {
        await db.collection(kind).doc(id).set(target(kind === "comments" ? { chantId: "parent" } : {}));
      }
      const reports = db.collection(kind === "chants" ? "reports" : "commentReports");
      const field = kind === "chants" ? "chantId" : "commentId";
      for (const id of ["a-mixed", "b-terminal"]) {
        const states = id === "a-mixed" ? ["pending", "reviewed", "dismissed"] : ["reviewed", "dismissed"];
        for (const status of states) await reports.doc(`${id}-${status}`).set({ [field]: id, status, reason: "PRIVATE_FIXTURE" });
      }
      const beforeReports = (await reports.get()).docs.map((doc) => doc.data());
      const covered: string[] = [];
      let cursor: string | undefined;
      for (;;) {
        const page = await plan(kind, cursor);
        covered.push(...page.targets.map((row) => row.id));
        await apply(page); await apply(page);
        if (page.endOfCollection) break;
        cursor = page.nextCursor!;
      }
      assert.deepEqual(covered, ["a-mixed", "b-terminal", "c-zero"]);
      assert.equal((await db.collection(kind).doc("a-mixed").get()).data()!.flagCount, 1);
      for (const id of covered.slice(1)) assert.equal((await db.collection(kind).doc(id).get()).data()!.flagCount, 0);
      for (const id of covered) assert.equal((await db.collection(kind).doc(id).get()).data()!.hidden, false);
      if (kind === "comments") assert.equal((await db.collection("chants").doc("parent").get()).data()!.commentCount, 3);
      assert.deepEqual((await reports.get()).docs.map((doc) => doc.data()), beforeReports);
      assert.equal((await db.collection("reportRepairProgress").get()).docs.filter((doc) => doc.data().state === "complete").length, 3);
    });

    it(`rejects unknown ${kind} report states in planning and after a plan without writes`, async () => {
      if (kind === "comments") await db.collection("chants").doc("parent").set(target());
      await db.collection(kind).doc("target").set(target(kind === "comments" ? { chantId: "parent" } : {}));
      const report = db.collection(kind === "chants" ? "reports" : "commentReports").doc("bad");
      const field = kind === "chants" ? "chantId" : "commentId";
      const page = await plan(kind);
      for (const status of ["resolved", "unexpected", null, 1, undefined]) {
        await report.set({ [field]: "target", ...(status === undefined ? {} : { status }) });
        await assert.rejects(plan(kind), /Malformed report state/);
        await assert.rejects(apply(page), /Malformed report state/);
        assert.equal((await db.collection(kind).doc("target").get()).data()!.flagCount, 9);
        assert.equal((await db.collection("auditLog").get()).size, 0);
        assert.equal((await db.collection("reportRepairProgress").get()).size, 0);
      }
    });
  }

  it("refuses stale control, changed report state, and missing relationships without repair writes", async () => {
    await db.collection("chants").doc("chant").set(target());
    const value = await plan();
    await db.collection("operationalControls").doc("v1").update({ generation: 5 });
    await assert.rejects(apply(value), /maintenance generation/);
    await db.collection("operationalControls").doc("v1").update({ generation: 4 });
    await seedRows("reports", 1, { chantId: "chant", status: "pending" });
    await assert.rejects(apply(value), /source changed/);
    assert.equal((await db.collection("chants").doc("chant").get()).data()!.flagCount, 9);
    assert.equal((await db.collection("auditLog").get()).size, 0);
    await db.collection("comments").doc("missing").set(target({ chantId: "absent" }));
    await assert.rejects(plan("comments"), /parent is missing/);
  });

  it("does not mark completion when the control closes between commit and readback", async () => {
    await db.collection("chants").doc("chant").set(target());
    const value = await plan();
    let calls = 0;
    const interrupted = new Proxy(db, { get(object, property) {
      if (property === "runTransaction") return async (operation: (transaction: admin.firestore.Transaction) => Promise<unknown>) => {
        const result = await object.runTransaction(operation);
        if (++calls === 1) await db.collection("operationalControls").doc("v1").update({ generation: 5 });
        return result;
      };
      const result = Reflect.get(object, property); return typeof result === "function" ? result.bind(object) : result;
    } });
    await assert.rejects(apply(value, interrupted), /maintenance generation/);
    assert.equal((await db.collection("reportRepairProgress").get()).docs[0].data().state, "applied");
    assert.equal((await db.collection("auditLog").get()).size, 1);
    // Explicitly restoring the original fixture generation is a test-only
    // fault recovery, not an approved production generation rollback.
    await db.collection("operationalControls").doc("v1").update({ generation: 4 });
    await apply(value);
    assert.equal((await db.collection("reportRepairProgress").get()).docs[0].data().state, "complete");
  });

  it("persists event-only cleanup through the actual paused exported trigger", async () => {
    await onPerformanceDraftDeleted.run({ params: { draftId: "event-draft" },
      data: { data: () => ({ ownerId: "fan", uploadPath: "performance-staging/fan/event-draft/source" }) },
    } as never);
    const job = (await db.collection("deferredDraftCleanupJobs").doc("event-draft").get()).data()!;
    assert.equal(job.state, "pending");
    assert.equal(job.uploadPath, "performance-staging/fan/event-draft/source");
  });

  it("acknowledges permanent cleanup faults only with durable private quarantine through the exported trigger", async () => {
    const original = { state: "pending", uploadPath: "performance-staging/original/collision/source" };
    await db.collection("deferredDraftCleanupJobs").doc("collision").set(original);
    await db.collection("profiles").doc("fan").set({ activePerformanceUpload: { draftId: "collision" } });
    for (const draftId of ["invalid", "collision"]) {
      const event = { params: { draftId }, data: { data: () => ({
        ownerId: "fan", uploadPath: `performance-staging/${draftId === "invalid" ? "victim" : "fan"}/${draftId}/source`,
        caption: "DO_NOT_RETAIN",
      }) } };
      await onPerformanceDraftDeleted.run(event as never);
      await onPerformanceDraftDeleted.run(event as never);
    }
    const rows = (await db.collection("deferredDraftCleanupJobs").get()).docs.map((doc) => doc.data());
    const blocked = rows.filter((row) => row.state === "blocked");
    assert.equal(rows.length, 3); assert.equal(blocked.length, 2);
    assert.deepEqual(blocked.map((row) => row.reason).sort(), ["invalid-identity", "path-conflict"]);
    for (const row of blocked) assert.deepEqual(Object.keys(row).sort(),
      ["createdAt", "draftId", "reason", "schemaVersion", "sourceDigest", "state", "updatedAt"]);
    assert.deepEqual(blocked.map((row) => row.draftId).sort(), ["collision", "invalid"]);
    assert(!JSON.stringify(blocked).includes("DO_NOT_RETAIN"));
    assert.deepEqual((await db.collection("deferredDraftCleanupJobs").doc("collision").get()).data(), original);
    assert.equal((await db.collection("profiles").doc("fan").get()).data()!.activePerformanceUpload.draftId, "collision");
  });

  it("binds evidence to live control and stops expired evidence before readback or another target", async () => {
    await db.collection("chants").doc("a").set(target());
    await db.collection("chants").doc("b").set(target());
    let clock = Date.now();
    const cutover = repairEvidence(clock);
    const context = { firestore: db, projectId: "chants-f95b4", sourceSha: sha, cutover,
      now: () => admin.firestore.Timestamp.fromMillis(clock) };
    await assert.rejects(planReportRepair({ ...context, kind: "chants", cutover: { ...cutover, generation: 5 } }), /not ready/);
    await assert.rejects(planReportRepair({ ...context, kind: "chants", cutover: { ...cutover, sourceSha: "b".repeat(40) } }), /not ready/);
    const value = await planReportRepair({ ...context, kind: "chants" });
    const invoke = (firestore = db) => applyReportRepair({ ...context, firestore, plan: value, digest: repairDigest(value) });
    await assert.rejects(applyReportRepair({ ...context, plan: value, digest: repairDigest(value),
      cutover: { ...cutover, generation: 5 } }), /not ready/);
    assert.equal((await db.collection("auditLog").get()).size, 0);
    let calls = 0;
    const delayed = new Proxy(db, { get(object, property) {
      if (property === "runTransaction") return async (operation: (transaction: admin.firestore.Transaction) => Promise<unknown>) => {
        const result = await object.runTransaction(operation);
        if (++calls === 1) clock += MAX_PAUSE_EVIDENCE_AGE_MS + 1;
        return result;
      };
      const result = Reflect.get(object, property); return typeof result === "function" ? result.bind(object) : result;
    } });
    await assert.rejects(invoke(delayed), /stale/);
    assert.equal((await db.collection("reportRepairProgress").get()).docs[0].data().state, "applied");
    assert.equal((await db.collection("chants").doc("b").get()).data()!.flagCount, 9);
    await assert.rejects(planReportRepair({ ...context, kind: "chants" }), /stale/);
    // Refresh observations without changing the reviewed plan or control.
    context.cutover = repairEvidence(clock);
    await invoke();
    assert.equal((await db.collection("reportRepairProgress").get()).docs.filter((doc) => doc.data().state === "complete").length, 2);
  });

  it("refuses altered audit evidence at readback and leaves the checkpoint incomplete", async () => {
    await db.collection("chants").doc("chant").set(target());
    const value = await plan();
    let calls = 0;
    const tampered = new Proxy(db, { get(object, property) {
      if (property === "runTransaction") return async (operation: (transaction: admin.firestore.Transaction) => Promise<unknown>) => {
        const result = await object.runTransaction(operation);
        if (++calls === 1) {
          const audit = (await db.collection("auditLog").get()).docs[0];
          await audit.ref.update({ detail: "Unexpected audit mutation" });
        }
        return result;
      };
      const result = Reflect.get(object, property); return typeof result === "function" ? result.bind(object) : result;
    } });
    await assert.rejects(apply(value, tampered), /readback failed/);
    assert.equal((await db.collection("reportRepairProgress").get()).docs[0].data().state, "applied");
    await assert.rejects(apply(value), /checkpoint or readback differs/);
  });

  it("converges when duplicate report events overlap repair, or stops the stale plan", async () => {
    await db.collection("chants").doc("chant").set(target());
    await seedRows("reports", 3, { chantId: "chant", status: "pending" });
    const value = await plan();
    const outcomes = await Promise.allSettled([
      apply(value),
      handleChantReportWritten(undefined, { chantId: "chant" }, db),
      handleChantReportWritten({ chantId: "chant" }, undefined, db),
    ]);
    assert.equal(outcomes[1].status, "fulfilled"); assert.equal(outcomes[2].status, "fulfilled");
    const final = (await db.collection("chants").doc("chant").get()).data()!;
    assert.equal(final.flagCount, 3); assert.equal(final.hidden, true);
    if (outcomes[0].status === "rejected") await apply(await plan());
    assert.equal((await db.collection("auditLog").get()).size, 1);
    assert.equal((await db.collection("reportRepairProgress").get()).docs[0].data().state, "complete");
  });

  it("rejects the wrong reviewed digest before writes and rechecks an empty-page generation", async () => {
    const empty = await plan();
    await db.collection("operationalControls").doc("v1").update({ generation: 5 });
    await assert.rejects(apply(empty), /maintenance generation/);
    await db.collection("chants").doc("chant").set(target());
    const value = await plan("chants", undefined, 5);
    await assert.rejects(applyReportRepair({ firestore: db, projectId: "chants-f95b4", sourceSha: sha,
      plan: value, digest: "b".repeat(64), now, cutover: repairEvidence() }), /digest differs/);
    assert.equal((await db.collection("chants").doc("chant").get()).data()!.flagCount, 9);
    assert.equal((await db.collection("auditLog").get()).size, 0);
  });

  it("enforces report and visible-comment sentinel bounds before mutation", async () => {
    await db.collection("chants").doc("chant").set(target());
    await seedRows("reports", 501, { chantId: "chant", status: "pending" });
    await assert.rejects(plan(), /Report read bound exceeded/);
    assert.equal((await db.collection("chants").doc("chant").get()).data()!.flagCount, 9);
    await seedRows("comments", 1001, target({ chantId: "chant" }));
    await assert.rejects(plan("comments"), /Visible-comment read bound exceeded/);
    assert.equal((await db.collection("auditLog").get()).size, 0);
  });

  it("uses explicit document-ID pages without silently scanning the next page", async () => {
    await seedRows("chants", 26, target());
    const first = await plan();
    assert.equal(first.targets.length, 25); assert.equal(first.endOfCollection, false);
    await apply(first);
    const second = await plan("chants", first.nextCursor!);
    assert.equal(second.targets.length, 1); assert.equal(second.endOfCollection, true);
    assert.equal((await db.collection("chants").doc(second.targets[0].id).get()).data()!.flagCount, 9);
  });

  it("serializes real concurrent grant creation, deletion revocation, and stale draft cleanup", async () => {
    await db.collection("operationalControls").doc("v1").set({ schemaVersion: 1, generation: 4, mode: "media", destructiveWorkersEnabled: true });
    await db.collection("profiles").doc("fan").set({ banned: false, ageConfirmed17Plus: true, acceptedPolicyVersion: "v1", createdAt: now() });
    await db.collection("creatorProfiles").doc("fan").set({ hidden: false, removed: false, handle: "fan", displayName: "Fan" });
    await db.collection("chants").doc("chant").set(target({ teamId: "club", title: "Chant", status: "community" }));
    await db.collection("teams").doc("club").set({ name: "Club" });
    const create = (id: string) => handleCreatePerformanceDraft({ uid: "fan", data: { chantId: "chant", caption: "", contentType: "video/mp4", sizeBytes: 3, durationMs: 1000 }, firestore: db, now, newId: () => id });
    const outcomes = await Promise.allSettled([create("first"), create("second")]);
    assert.equal(outcomes.filter((result) => result.status === "fulfilled").length, 1);
    const grant = (await db.collection("profiles").doc("fan").get()).data()!.activePerformanceUpload;
    const media = { remove: async () => {}, inspect: async () => { throw Error("unused"); }, copy: async () => {}, signReadUrl: async () => "" };
    await handleCancelPerformanceDraft({ uid: "fan", data: { draftId: grant.draftId }, firestore: db, media, now });
    await create("newer");
    await handleDeletedDraftCleanup({ draftId: grant.draftId, data: { ownerId: "fan", uploadPath: grant.uploadPath }, firestore: db, remove: media.remove, now });
    assert.equal((await db.collection("profiles").doc("fan").get()).data()!.activePerformanceUpload.draftId, "newer");
    await requestAccountDeletion({ uid: "fan", data: {}, firestore: db, now });
    const profile = (await db.collection("profiles").doc("fan").get()).data()!;
    assert.equal(profile.activePerformanceUpload, null); assert.equal(profile.deletionPending, true);
  });

  it("revokes only the matching grant when abandoned cleanup claims a draft", async () => {
    const createdAt = admin.firestore.Timestamp.fromMillis(now().toMillis() - ABANDONED_DRAFT_AGE_MS - 1000);
    await db.collection("profiles").doc("fan").set({ activePerformanceUpload: { draftId: "old" } });
    await db.collection("performanceDrafts").doc("old").set({ schemaVersion: 1, ownerId: "fan", state: "awaiting_upload", uploadPath: "performance-staging/fan/old/source", createdAt });
    const store = firebaseOperationalStore(db);
    await store.claimCleanupDraft("old", now().toMillis() - ABANDONED_DRAFT_AGE_MS, now().toMillis());
    assert.equal((await db.collection("profiles").doc("fan").get()).data()!.activePerformanceUpload, null);
    await db.collection("profiles").doc("fan").update({ activePerformanceUpload: { draftId: "newer" } });
    await store.deleteClaimedDraft("old");
    assert.equal((await db.collection("profiles").doc("fan").get()).data()!.activePerformanceUpload.draftId, "newer");
  });
});
