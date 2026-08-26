import { describe, it } from "mocha";
import * as assert from "assert";
import { HttpsError } from "firebase-functions/v2/https";
import { requireMergeChantsEnabled } from "../src/index";

describe("mergeChants freeze guard", () => {
  it("fails closed until a resumable merge design replaces the sequential path", () => {
    assert.throws(requireMergeChantsEnabled, (error: unknown) => {
      return error instanceof HttpsError && error.code === "failed-precondition";
    });
  });
});
