import { strict as assert } from "assert";
import { assertServiceAccountProject } from "./seed_credential";

describe("seed credential project gate", () => {
  it("accepts only the named Chants project without exposing other fields", () => {
    assert.doesNotThrow(() =>
      assertServiceAccountProject(
        {
          project_id: "chants-f95b4",
          private_key: "must-not-appear",
        },
        "chants-f95b4"
      )
    );
    assert.throws(
      () =>
        assertServiceAccountProject(
          { project_id: "another-project", private_key: "must-not-appear" },
          "chants-f95b4"
        ),
      (error: unknown) =>
        error instanceof Error &&
        error.message ===
          'Service account project does not match required project "chants-f95b4".' &&
        !error.message.includes("must-not-appear")
    );
    assert.throws(
      () => assertServiceAccountProject(null, "chants-f95b4"),
      /missing a project_id/
    );
  });
});
