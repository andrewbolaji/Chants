import { beforeEach, describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import {
  handleCompleteOnboarding,
  parseOnboardingInput,
} from "../src/onboarding";

type Data = Record<string, unknown>;
type Ref = { collection: string; id: string };
type Operation = { ref: Ref; data: Data };

class FirestoreHarness {
  private readonly store = new Map<string, Map<string, Data>>();
  private transactionTail: Promise<void> = Promise.resolve();
  private beforeRetry: (() => void) | undefined;

  readonly firestore = {
    collection: (name: string) => ({
      doc: (id: string) => ({ collection: name, id }),
    }),
    runTransaction: <T>(handler: (transaction: unknown) => Promise<T>) =>
      this.runTransaction(handler),
  } as unknown as admin.firestore.Firestore;

  set(collection: string, id: string, data: Data): void {
    this.bucket(collection).set(id, { ...data });
  }

  get(collection: string, id: string): Data | undefined {
    const data = this.bucket(collection).get(id);
    return data ? { ...data } : undefined;
  }

  size(collection: string): number {
    return this.bucket(collection).size;
  }

  retryNextTransactionAfter(concurrentWrite: () => void): void {
    this.beforeRetry = concurrentWrite;
  }

  private bucket(collection: string): Map<string, Data> {
    let bucket = this.store.get(collection);
    if (!bucket) {
      bucket = new Map<string, Data>();
      this.store.set(collection, bucket);
    }
    return bucket;
  }

  private snapshot(ref: Ref) {
    const data = this.bucket(ref.collection).get(ref.id);
    return {
      exists: data !== undefined,
      data: () => data ? { ...data } : undefined,
    };
  }

  private async runTransaction<T>(
    handler: (transaction: {
      get: (ref: Ref) => Promise<ReturnType<FirestoreHarness["snapshot"]>>;
      set: (ref: Ref, data: Data) => void;
    }) => Promise<T>
  ): Promise<T> {
    let release!: () => void;
    const previous = this.transactionTail;
    this.transactionTail = new Promise<void>((resolve) => {
      release = resolve;
    });
    await previous;
    try {
      const runAttempt = async () => {
        const operations: Operation[] = [];
        const result = await handler({
          get: async (ref) => this.snapshot(ref),
          set: (ref, data) => operations.push({ ref, data }),
        });
        return { operations, result };
      };
      let { operations, result } = await runAttempt();
      const beforeRetry = this.beforeRetry;
      if (beforeRetry) {
        this.beforeRetry = undefined;
        beforeRetry();
        ({ operations, result } = await runAttempt());
      }
      for (const operation of operations) {
        this.set(operation.ref.collection, operation.ref.id, operation.data);
      }
      return result;
    } finally {
      release();
    }
  }
}

const NOW = admin.firestore.Timestamp.fromMillis(Date.UTC(2026, 7, 28));

describe("complete onboarding", () => {
  let db: FirestoreHarness;

  beforeEach(() => {
    db = new FirestoreHarness();
  });

  it("accepts only the narrow confirmed payload", () => {
    assert.deepStrictEqual(
      parseOnboardingInput({
        displayName: " North Bank Leo ",
        ageConfirmed17Plus: true,
        policyAccepted: true,
      }),
      {
        displayName: "North Bank Leo",
        ageConfirmed17Plus: true,
        policyAccepted: true,
      }
    );
    for (const payload of [
      null,
      { displayName: "", ageConfirmed17Plus: true, policyAccepted: true },
      { displayName: "Fan", ageConfirmed17Plus: false, policyAccepted: true },
      { displayName: "Fan", ageConfirmed17Plus: true, policyAccepted: false },
      {
        displayName: "Fan",
        ageConfirmed17Plus: true,
        policyAccepted: true,
        role: "operator",
      },
    ]) {
      assert.throws(
        () => parseOnboardingInput(payload),
        (error: { code?: string }) => error.code === "invalid-argument"
      );
    }
  });

  it("creates one coherent profile and deterministic consent audit", async () => {
    const result = await handleCompleteOnboarding({
      uid: "fan",
      data: {
        displayName: "North Bank Leo",
        ageConfirmed17Plus: true,
        policyAccepted: true,
      },
      firestore: db.firestore,
      now: () => NOW,
      policyVersion: "v1",
    });

    assert.deepStrictEqual(result, { created: true, completed: true });
    assert.deepStrictEqual(db.get("profiles", "fan"), {
      displayName: "North Bank Leo",
      role: "user",
      banned: false,
      deletionPending: false,
      ageConfirmed17Plus: true,
      acceptedPolicyVersion: "v1",
      acceptedPolicyAt: NOW,
      userReportCount: 0,
      createdAt: NOW,
      updatedAt: NOW,
    });
    assert.deepStrictEqual(
      db.get("auditLog", "onboarding-policy-fan-v1"),
      {
        actorId: "fan",
        action: "accept-policy",
        targetType: "user",
        targetId: "fan",
        detail: "Accepted Terms and Community Rules version v1.",
        createdAt: NOW,
      }
    );
  });

  it("converges overlapping completion without a second profile or audit", async () => {
    const request = {
      uid: "fan",
      data: {
        displayName: "North Bank Leo",
        ageConfirmed17Plus: true,
        policyAccepted: true,
      },
      firestore: db.firestore,
      now: () => NOW,
      policyVersion: "v1",
    };
    const results = await Promise.all([
      handleCompleteOnboarding(request),
      handleCompleteOnboarding(request),
    ]);
    assert.deepStrictEqual(
      results.map((result) => result.created),
      [true, false]
    );
    assert.strictEqual(db.size("profiles"), 1);
    assert.strictEqual(db.size("auditLog"), 1);
  });

  it("reports the winning result after a transaction retry", async () => {
    db.retryNextTransactionAfter(() => {
      db.set("profiles", "fan", {
        displayName: "Concurrent winner",
        role: "user",
        banned: false,
        ageConfirmed17Plus: true,
        acceptedPolicyVersion: "v1",
      });
      db.set("auditLog", "onboarding-policy-fan-v1", {
        actorId: "fan",
        action: "accept-policy",
      });
    });

    const result = await handleCompleteOnboarding({
      uid: "fan",
      data: {
        displayName: "Losing attempt",
        ageConfirmed17Plus: true,
        policyAccepted: true,
      },
      firestore: db.firestore,
      now: () => NOW,
      policyVersion: "v1",
    });

    assert.deepStrictEqual(result, { created: false, completed: true });
    assert.strictEqual(
      db.get("profiles", "fan")?.displayName,
      "Concurrent winner"
    );
    assert.strictEqual(db.size("profiles"), 1);
    assert.strictEqual(db.size("auditLog"), 1);
  });

  it("does not overwrite an existing complete account", async () => {
    db.set("profiles", "fan", {
      displayName: "Existing name",
      role: "operator",
      banned: false,
      ageConfirmed17Plus: true,
      acceptedPolicyVersion: "v1",
      userReportCount: 9,
    });
    const result = await handleCompleteOnboarding({
      uid: "fan",
      data: {
        displayName: "Replacement",
        ageConfirmed17Plus: true,
        policyAccepted: true,
      },
      firestore: db.firestore,
      now: () => NOW,
      policyVersion: "v1",
    });
    assert.strictEqual(result.created, false);
    assert.strictEqual(db.get("profiles", "fan")?.displayName, "Existing name");
    assert.strictEqual(db.get("profiles", "fan")?.role, "operator");
    assert.strictEqual(db.get("profiles", "fan")?.userReportCount, 9);
  });

  it("rejects deletion, bans, and incoherent existing profiles", async () => {
    const cases: Array<[string, Data, boolean]> = [
      ["job", {}, true],
      ["banned", {
        banned: true,
        ageConfirmed17Plus: true,
        acceptedPolicyVersion: "v1",
      }, false],
      ["pending", {
        banned: false,
        deletionPending: true,
        ageConfirmed17Plus: true,
        acceptedPolicyVersion: "v1",
      }, false],
      ["unaccepted", {
        banned: false,
        ageConfirmed17Plus: true,
      }, false],
    ];
    for (const [uid, profile, deletionJob] of cases) {
      if (Object.keys(profile).length > 0) db.set("profiles", uid, profile);
      if (deletionJob) db.set("accountDeletionJobs", uid, { phase: "queued" });
      await assert.rejects(
        handleCompleteOnboarding({
          uid,
          data: {
            displayName: "Fan",
            ageConfirmed17Plus: true,
            policyAccepted: true,
          },
          firestore: db.firestore,
          now: () => NOW,
          policyVersion: "v1",
        })
      );
      assert.strictEqual(
        db.get("auditLog", `onboarding-policy-${uid}-v1`),
        undefined
      );
    }
  });
});
