import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "fs";
import { resolve } from "path";
import { Timestamp } from "firebase/firestore";
import firebase from "firebase/compat/app";
import "firebase/compat/storage";

// Cross-product Storage rules calls are evaluated in the emulator process's
// configured Firebase project, so this must match firebase emulators:exec.
const PROJECT_ID = "chants-f95b4";
const BUCKET = `gs://${PROJECT_ID}.appspot.com`;

let testEnv: RulesTestEnvironment;

function verifiedContext(
  uid: string,
  claims: Record<string, unknown> = {},
) {
  return testEnv.authenticatedContext(uid, {
    email: `${uid}@example.com`,
    email_verified: true,
    ...claims,
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(resolve(__dirname, "../firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
    storage: {
      rules: readFileSync(resolve(__dirname, "../storage.rules"), "utf8"),
      host: "127.0.0.1",
      port: 9199,
    },
  });
});

beforeEach(async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().collection("operationalControls").doc("v1").set({
      schemaVersion: 1, generation: 1, mode: "media", destructiveWorkersEnabled: true,
    });
  });
});

afterEach(async () => {
  await Promise.all([testEnv.clearFirestore(), testEnv.clearStorage()]);
});

after(async () => {
  await testEnv.cleanup();
});

async function seedUploadTicket(
  uid: string,
  draftId: string,
  options: { banned?: boolean; deletionPending?: boolean } = {},
) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const issuedAt = Timestamp.now();
    await db.collection("profiles").doc(uid).set({
      activePerformanceUpload: {
        schemaVersion: 1, ownerId: uid, draftId, uploadPath: `performance-staging/${uid}/${draftId}/source`,
        sizeBytes: 3, contentType: "video/mp4", generation: 1, issuedAt,
        expiresAt: Timestamp.fromMillis(issuedAt.toMillis() + 30 * 60 * 1000),
      },
      displayName: "Uploader",
      role: "user",
      banned: options.banned ?? false,
      deletionPending: options.deletionPending ?? false,
      ageConfirmed17Plus: true,
      acceptedPolicyVersion: "v2",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
    await db.collection("performanceDrafts").doc(draftId).set({
      schemaVersion: 1,
      ownerId: uid,
      state: "awaiting_upload",
      uploadPath: `performance-staging/${uid}/${draftId}/source`,
      claimedSizeBytes: 3,
      claimedContentType: "video/mp4",
    });
  });
}

async function seedOperator(uid: string) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().collection("profiles").doc(uid).set({
      displayName: "Operator",
      role: "operator",
      banned: false,
      deletionPending: false,
      ageConfirmed17Plus: true,
      acceptedPolicyVersion: "v2",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  });
}

function uploadMetadata(uid: string, draftId: string) {
  return {
    contentType: "video/mp4",
    customMetadata: { ownerId: uid, draftId, schemaVersion: "1" },
  };
}

function upload(
  reference: firebase.storage.Reference,
  bytes: Uint8Array,
  metadata: firebase.storage.UploadMetadata,
): Promise<firebase.storage.UploadTaskSnapshot> {
  return new Promise((resolveUpload, rejectUpload) => {
    reference.put(bytes, metadata).then(resolveUpload, rejectUpload);
  });
}

describe("performance media storage", () => {
  it("closes old grants on maintenance, malformed control, and a later generation", async () => {
    await seedUploadTicket("fan", "draft-gate");
    const reference = verifiedContext("fan").storage(BUCKET).ref("performance-staging/fan/draft-gate/source");
    const attempt = () => upload(reference, new Uint8Array([1, 2, 3]), uploadMetadata("fan", "draft-gate"));
    for (const control of [null,
      { schemaVersion: 1, generation: 1, mode: "maintenance", destructiveWorkersEnabled: true },
      { schemaVersion: 1, generation: 1, mode: "core", destructiveWorkersEnabled: true },
      { schemaVersion: 1, generation: 1, mode: "media", destructiveWorkersEnabled: false },
      { schemaVersion: 2, generation: 1, mode: "media", destructiveWorkersEnabled: true },
      { schemaVersion: 1, generation: 2, mode: "media", destructiveWorkersEnabled: true },
    ]) {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const doc = context.firestore().collection("operationalControls").doc("v1");
        if (control === null) await doc.delete(); else await doc.set(control);
      });
      await assertFails(attempt());
    }
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("operationalControls").doc("v1").set({
        schemaVersion: 1, generation: 1, mode: "media", destructiveWorkersEnabled: true,
      });
    });
    await assertSucceeds(attempt());
  });

  it("uses current account authority and rejects missing, expired, future, or revoked grants", async () => {
    await seedUploadTicket("fan", "draft-grant");
    const reference = verifiedContext("fan").storage(BUCKET).ref("performance-staging/fan/draft-grant/source");
    const attempt = () => upload(reference, new Uint8Array([1, 2, 3]), uploadMetadata("fan", "draft-grant"));
    for (const change of [
      { banned: true }, { deletionPending: true }, { ageConfirmed17Plus: false },
      { acceptedPolicyVersion: "v1" }, { activePerformanceUpload: null },
      { "activePerformanceUpload.ownerId": "other" }, { "activePerformanceUpload.draftId": "other" },
      { "activePerformanceUpload.extra": true }, { "activePerformanceUpload.sizeBytes": 2 },
      { "activePerformanceUpload.issuedAt": Timestamp.fromMillis(0), "activePerformanceUpload.expiresAt": Timestamp.fromMillis(1800000) },
      { "activePerformanceUpload.issuedAt": Timestamp.fromMillis(Date.now() + 3600000), "activePerformanceUpload.expiresAt": Timestamp.fromMillis(Date.now() + 5400000) },
    ]) {
      await seedUploadTicket("fan", "draft-grant");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("profiles").doc("fan").update(change);
      });
      await assertFails(attempt());
    }
    await seedUploadTicket("fan", "draft-grant");
    await assertSucceeds(attempt());
  });

  it("accepts only the owner ticket's exact first upload", async () => {
    await seedUploadTicket("fan", "draft-1");
    const owner = verifiedContext("fan").storage(BUCKET);
    const path = "performance-staging/fan/draft-1/source";
    const reference = owner.ref(path);

    await assertSucceeds(
      upload(reference, new Uint8Array([1, 2, 3]), uploadMetadata("fan", "draft-1")),
    );
    await assertFails(
      upload(reference, new Uint8Array([1, 2, 3]), uploadMetadata("fan", "draft-1")),
    );
    await assertSucceeds(reference.getDownloadURL());
    await assertFails(reference.delete());
  });

  it("rejects forged ownership, metadata, type, size, and inactive accounts", async () => {
    await seedUploadTicket("fan", "draft-1");
    await seedUploadTicket("banned", "draft-2", { banned: true });
    const fan = verifiedContext("fan").storage(BUCKET);
    const attacker = verifiedContext("attacker").storage(BUCKET);
    const banned = verifiedContext("banned").storage(BUCKET);

    await assertFails(
      upload(
        attacker.ref("performance-staging/fan/draft-1/source"),
        new Uint8Array([1, 2, 3]),
        uploadMetadata("fan", "draft-1"),
      ),
    );
    await assertFails(
      upload(
        fan.ref("performance-staging/fan/draft-1/source"),
        new Uint8Array([1, 2, 3]),
        {
          ...uploadMetadata("fan", "draft-1"),
          customMetadata: {
            ...uploadMetadata("fan", "draft-1").customMetadata,
            role: "operator",
          },
        },
      ),
    );
    await assertFails(
      upload(
        fan.ref("performance-staging/fan/draft-1/source"),
        new Uint8Array([1, 2, 3]),
        {
          ...uploadMetadata("fan", "draft-1"),
          contentType: "text/plain",
        },
      ),
    );
    await assertFails(
      upload(
        fan.ref("performance-staging/fan/draft-1/source"),
        new Uint8Array([1, 2]),
        uploadMetadata("fan", "draft-1"),
      ),
    );
    await assertFails(
      upload(
        banned.ref("performance-staging/banned/draft-2/source"),
        new Uint8Array([1, 2, 3]),
        uploadMetadata("banned", "draft-2"),
      ),
    );
  });

  it("denies an upload until the owner has a verified contact", async () => {
    await seedUploadTicket("unverified", "draft-unverified");
    const storage = testEnv.authenticatedContext("unverified", {
      email: "unverified@example.com",
      email_verified: false,
    }).storage(BUCKET);

    await assertFails(
      upload(
        storage.ref("performance-staging/unverified/draft-unverified/source"),
        new Uint8Array([1, 2, 3]),
        uploadMetadata("unverified", "draft-unverified"),
      ),
    );

    await seedUploadTicket("linked-facebook", "draft-linked");
    const linkedStorage = testEnv.authenticatedContext("linked-facebook", {
      email: "linked@example.com",
      email_verified: false,
      firebase: {
        sign_in_provider: "password",
        identities: { "facebook.com": ["facebook-id"] },
      },
    }).storage(BUCKET);
    await assertSucceeds(
      upload(
        linkedStorage.ref(
          "performance-staging/linked-facebook/draft-linked/source",
        ),
        new Uint8Array([1, 2, 3]),
        uploadMetadata("linked-facebook", "draft-linked"),
      ),
    );
  });

  it("keeps staged objects private and canonical objects off the client path", async () => {
    await seedUploadTicket("fan", "draft-private");
    const owner = verifiedContext("fan").storage(BUCKET);
    const other = verifiedContext("other").storage(BUCKET);
    const staged = owner.ref("performance-staging/fan/draft-private/source");
    await assertSucceeds(
      upload(
        staged,
        new Uint8Array([1, 2, 3]),
        uploadMetadata("fan", "draft-private"),
      ),
    );
    await assertFails(
      other.ref("performance-staging/fan/draft-private/source").getDownloadURL(),
    );

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await upload(
        context.storage(BUCKET).ref("performance-media/performance-1/source"),
        new Uint8Array([1, 2, 3]),
        { contentType: "video/mp4" },
      );
    });
    await assertFails(
      owner.ref("performance-media/performance-1/source").getDownloadURL(),
    );
  });

  it("requires verified contact for operator staging previews", async () => {
    await seedUploadTicket("fan", "draft-review");
    await seedOperator("operator");
    const path = "performance-staging/fan/draft-review/source";
    const owner = verifiedContext("fan").storage(BUCKET);
    await assertSucceeds(
      upload(
        owner.ref(path),
        new Uint8Array([1, 2, 3]),
        uploadMetadata("fan", "draft-review"),
      ),
    );

    const unverifiedOperator = testEnv.authenticatedContext("operator", {
      email: "operator@example.com",
      email_verified: false,
    }).storage(BUCKET);
    await assertFails(unverifiedOperator.ref(path).getDownloadURL());

    const verifiedOperator = verifiedContext("operator").storage(BUCKET);
    await assertSucceeds(verifiedOperator.ref(path).getDownloadURL());
  });
});
