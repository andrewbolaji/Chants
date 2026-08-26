import { describe, it, beforeEach } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import {
  handleChantReportWritten,
  handleCommentReportWritten,
  isNewAccount,
} from "../src/index";

type Store = Record<string, Record<string, unknown>>;

let reports: Store = {};
let commentReports: Store = {};
let chants: Store = {};
let comments: Store = {};

function makeFakeFirestore(): admin.firestore.Firestore {
  const stores: Record<string, Store> = {
    reports,
    commentReports,
    chants,
    comments,
  };

  const firestore = {
    collection: (name: string) => ({
      where: (field: string, _op: string, value: unknown) => ({
        get: async () => ({
          docs: Object.entries(stores[name])
            .filter(([, data]) => data[field] === value)
            .map(([id, data]) => ({ id, data: () => ({ ...data }) })),
        }),
      }),
      doc: (id: string) => ({
        get: async () => ({
          exists: stores[name][id] !== undefined,
          data: () => stores[name][id],
        }),
        update: async (data: Record<string, unknown>) => {
          stores[name][id] = { ...stores[name][id], ...data };
        },
      }),
    }),
    runTransaction: async (handler: (transaction: {
      get: (ref: { get: () => Promise<unknown> }) => Promise<unknown>;
      update: (
        ref: { update: (data: Record<string, unknown>) => Promise<void> },
        data: Record<string, unknown>,
      ) => void;
    }) => Promise<unknown>) => handler({
      get: (ref) => ref.get(),
      update: (ref, data) => {
        void ref.update(data);
      },
    }),
  };

  return firestore as unknown as admin.firestore.Firestore;
}

describe("ground-truth report counters", () => {
  beforeEach(() => {
    reports = {};
    commentReports = {};
    chants = {};
    comments = {};
  });

  it("duplicate chant-report delivery cannot increment twice", async () => {
    chants["chant-1"] = { hidden: false, flagCount: 0 };
    reports["u1_chant-1"] = { chantId: "chant-1", status: "pending" };
    reports["u2_chant-1"] = { chantId: "chant-1", status: "pending" };
    reports["u3_chant-1"] = { chantId: "chant-1", status: "pending" };
    const db = makeFakeFirestore();

    const first = await handleChantReportWritten(
      undefined,
      { chantId: "chant-1" },
      db
    );
    const duplicate = await handleChantReportWritten(
      undefined,
      { chantId: "chant-1" },
      db
    );

    assert.strictEqual(first.flagCount, 3);
    assert.strictEqual(first.autoHidden, true);
    assert.strictEqual(duplicate.flagCount, 3);
    assert.strictEqual(duplicate.autoHidden, false);
    assert.strictEqual(chants["chant-1"].flagCount, 3);
  });

  it("report status changes and deletes reduce the absolute count without auto-unhiding", async () => {
    comments["comment-1"] = { hidden: true, flagCount: 3 };
    commentReports["u1_comment-1"] = {
      commentId: "comment-1",
      status: "reviewed",
    };
    commentReports["u2_comment-1"] = {
      commentId: "comment-1",
      status: "pending",
    };
    const db = makeFakeFirestore();

    const result = await handleCommentReportWritten(
      { commentId: "comment-1", status: "pending" },
      { commentId: "comment-1", status: "reviewed" },
      db
    );

    assert.strictEqual(result.flagCount, 1);
    assert.strictEqual(result.autoHidden, false);
    assert.strictEqual(comments["comment-1"].flagCount, 1);
    assert.strictEqual(comments["comment-1"].hidden, true);
  });
});

describe("rate-limit account classification", () => {
  it("depends only on account age, so submission count cannot flip the limit", () => {
    assert.strictEqual(isNewAccount(23 * 60 * 60 * 1000), true);
    assert.strictEqual(isNewAccount(25 * 60 * 60 * 1000), false);
    assert.strictEqual(isNewAccount(30 * 24 * 60 * 60 * 1000), false);
  });
});
