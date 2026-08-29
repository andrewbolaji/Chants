import * as assert from "node:assert";
import {
  cpSync,
  mkdtempSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { collectLaunchServiceErrors } from "./check-launch-services.mjs";
import { buildAssetLinks } from "./generate-android-assetlinks.mjs";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDirectory, "..");
const tempRoot = mkdtempSync(join(tmpdir(), "chants-launch-services-"));
const paths = [
  "firebase.json",
  "hosting/.well-known/apple-app-site-association",
  "android/settings.gradle.kts",
  "android/app/build.gradle.kts",
  "android/app/src/main/AndroidManifest.xml",
  "ios/Runner.xcodeproj/project.pbxproj",
  "ios/Runner/Runner.entitlements",
  "lib/main.dart",
  "functions/src/index.ts",
  "functions/src/operations.ts",
];

try {
  for (const path of paths) {
    mkdirSync(dirname(join(tempRoot, path)), { recursive: true });
    cpSync(join(root, path), join(tempRoot, path));
  }
  assert.deepStrictEqual(collectLaunchServiceErrors(tempRoot), []);

  const associationPath = join(
    tempRoot,
    "hosting/.well-known/apple-app-site-association",
  );
  const association = JSON.parse(readFileSync(associationPath, "utf8"));
  association.applinks.details[0].appIDs = ["WRONG.com.chants.chants"];
  writeFileSync(associationPath, `${JSON.stringify(association)}\n`);
  assert.ok(collectLaunchServiceErrors(tempRoot).some((error) =>
    error.includes("wrong signed app identity")
  ));
  cpSync(
    join(root, "hosting/.well-known/apple-app-site-association"),
    associationPath,
  );

  const settingsPath = join(tempRoot, "android/settings.gradle.kts");
  writeFileSync(
    settingsPath,
    readFileSync(settingsPath, "utf8").replace(
      'id("com.google.firebase.crashlytics") version("3.0.8") apply false',
      "",
    ),
  );
  assert.ok(collectLaunchServiceErrors(tempRoot).some((error) =>
    error.includes("Crashlytics plugin")
  ));
  cpSync(join(root, "android/settings.gradle.kts"), settingsPath);

  const invalidAssetLinks = join(
    tempRoot,
    "hosting/.well-known/assetlinks.json",
  );
  writeFileSync(invalidAssetLinks, '[{"target":{"package_name":"wrong"}}]\n');
  assert.ok(collectLaunchServiceErrors(tempRoot).some((error) =>
    error.includes("invalid app identity")
  ));

  const validFingerprint = Array.from({ length: 32 }, () => "AB").join(":");
  assert.strictEqual(
    buildAssetLinks([validFingerprint])[0].target.package_name,
    "com.chants.chants",
  );
  assert.throws(() => buildAssetLinks([]));
  assert.throws(() => buildAssetLinks([validFingerprint.toLowerCase()]));
  process.stdout.write("Launch services check regressions pass.\n");
} finally {
  rmSync(tempRoot, { recursive: true, force: true });
}
