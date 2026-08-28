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
    await db.collection("profiles").doc(uid).set({
      displayName: "Uploader",
      role: "user",
      banned: options.banned ?? false,
      deletionPending: options.deletionPending ?? false,
      ageConfirmed17Plus: true,
      acceptedPolicyVersion: "v1",
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
  it("accepts only the owner ticket's exact first upload", async () => {
    await seedUploadTicket("fan", "draft-1");
    const owner = testEnv.authenticatedContext("fan").storage(BUCKET);
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
    const fan = testEnv.authenticatedContext("fan").storage(BUCKET);
    const attacker = testEnv.authenticatedContext("attacker").storage(BUCKET);
    const banned = testEnv.authenticatedContext("banned").storage(BUCKET);

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

  it("keeps staged objects private and canonical objects off the client path", async () => {
    await seedUploadTicket("fan", "draft-private");
    const owner = testEnv.authenticatedContext("fan").storage(BUCKET);
    const other = testEnv.authenticatedContext("other").storage(BUCKET);
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
});
