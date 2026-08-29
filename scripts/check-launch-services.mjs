import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const defaultRoot = resolve(scriptDirectory, "..");
const expectedPaths = [
  "/finish-sign-in",
  "/chants/*",
  "/performances/*",
  "/creators/*",
];
const fingerprintPattern = /^(?:[0-9A-F]{2}:){31}[0-9A-F]{2}$/;

function read(root, path, errors) {
  try {
    return readFileSync(join(root, path), "utf8");
  } catch (_) {
    errors.push(`${path} is missing or unreadable`);
    return "";
  }
}

function parse(root, path, errors) {
  const source = read(root, path, errors);
  if (!source) return null;
  try {
    return JSON.parse(source);
  } catch (_) {
    errors.push(`${path} is not valid JSON`);
    return null;
  }
}

function expectIncludes(source, expected, message, errors) {
  if (!source.includes(expected)) errors.push(message);
}

export function collectLaunchServiceErrors(root = defaultRoot) {
  const errors = [];
  const firebase = parse(root, "firebase.json", errors);
  const association = parse(
    root,
    "hosting/.well-known/apple-app-site-association",
    errors,
  );
  const settings = read(root, "android/settings.gradle.kts", errors);
  const appGradle = read(root, "android/app/build.gradle.kts", errors);
  const xcodeProject = read(root, "ios/Runner.xcodeproj/project.pbxproj", errors);
  const entitlements = read(root, "ios/Runner/Runner.entitlements", errors);
  const manifest = read(root, "android/app/src/main/AndroidManifest.xml", errors);
  const main = read(root, "lib/main.dart", errors);
  const functionsIndex = read(root, "functions/src/index.ts", errors);
  read(root, "functions/src/operations.ts", errors);

  if (firebase) {
    const ignore = firebase.hosting?.ignore;
    if (!Array.isArray(ignore) || ignore.includes("**/.*")) {
      errors.push("Firebase Hosting still excludes every dotfile directory");
    }
    const headers = Array.isArray(firebase.hosting?.headers)
      ? firebase.hosting.headers
      : [];
    for (const path of [
      "/.well-known/apple-app-site-association",
      "/.well-known/assetlinks.json",
    ]) {
      const entry = headers.find((value) => value?.source === path);
      const values = Array.isArray(entry?.headers) ? entry.headers : [];
      if (!values.some((value) =>
        value?.key === "Content-Type" && value?.value === "application/json"
      )) errors.push(`${path} is missing its JSON content type`);
      if (!values.some((value) =>
        value?.key === "Cache-Control" && value?.value === "public,max-age=300"
      )) errors.push(`${path} is missing its reviewed cache policy`);
    }
    if (firebase.flutter?.platforms?.ios?.default?.uploadDebugSymbols !== true) {
      errors.push("FlutterFire iOS symbol upload is not enabled");
    }
  }

  const details = association?.applinks?.details;
  if (!Array.isArray(details) || details.length !== 1) {
    errors.push("Apple association must have one details entry");
  } else {
    const detail = details[0];
    if (
      !Array.isArray(detail.appIDs) ||
      detail.appIDs.length !== 1 ||
      detail.appIDs[0] !== "J7V95LBCWR.com.chants.chants"
    ) errors.push("Apple association has the wrong signed app identity");
    const paths = Array.isArray(detail.components)
      ? detail.components.map((component) => component?.["/"])
      : [];
    if (JSON.stringify(paths) !== JSON.stringify(expectedPaths)) {
      errors.push("Apple association paths do not match the approved routes");
    }
  }

  for (const entitlement of [
    "applinks:auth.chantsfc.com",
    "applinks:chantsfc.com",
  ]) expectIncludes(entitlements, entitlement, `Missing entitlement ${entitlement}`, errors);
  for (const manifestPart of [
    'android:host="auth.chantsfc.com"',
    'android:pathPrefix="/finish-sign-in"',
    'android:host="chantsfc.com"',
    'android:pathPrefix="/chants/"',
    'android:pathPrefix="/performances/"',
    'android:pathPrefix="/creators/"',
  ]) expectIncludes(manifest, manifestPart, `Missing Android route ${manifestPart}`, errors);

  expectIncludes(
    settings,
    'id("com.google.firebase.crashlytics") version("3.0.8") apply false',
    "Android Crashlytics plugin is missing or unpinned",
    errors,
  );
  expectIncludes(
    settings,
    'id("com.google.gms.google-services") version("4.5.0") apply false',
    "Android Google Services plugin is outside the reviewed version",
    errors,
  );
  expectIncludes(
    appGradle,
    'id("com.google.firebase.crashlytics")',
    "Android app does not apply Crashlytics",
    errors,
  );
  expectIncludes(
    xcodeProject,
    'FlutterFire: \\"flutterfire upload-crashlytics-symbols\\"',
    "iOS does not contain the FlutterFire Crashlytics phase",
    errors,
  );
  expectIncludes(
    xcodeProject,
    'if [ \\"${CONFIGURATION}\\" != \\"Release\\" ]; then',
    "iOS Crashlytics upload is not limited to release builds",
    errors,
  );
  expectIncludes(
    main,
    "FirebaseCrashlytics.instance.recordFlutterFatalError",
    "Flutter framework crashes are not routed to Crashlytics",
    errors,
  );
  expectIncludes(
    main,
    "FirebaseCrashlytics.instance.recordError(error, stack, fatal: true)",
    "Flutter asynchronous crashes are not routed to Crashlytics",
    errors,
  );
  for (const functionName of [
    "cleanupAbandonedPerformanceDraftsJob",
    "monitorOperationalBacklogsJob",
  ]) expectIncludes(functionsIndex, functionName, `Missing Function ${functionName}`, errors);
  if (functionsIndex.includes("enforceAppCheck: true")) {
    errors.push("App Check enforcement was enabled before the telemetry gate");
  }

  const assetLinksPath = join(root, "hosting/.well-known/assetlinks.json");
  if (existsSync(assetLinksPath)) {
    const assetLinks = parse(root, "hosting/.well-known/assetlinks.json", errors);
    const target = Array.isArray(assetLinks) && assetLinks.length === 1
      ? assetLinks[0]?.target
      : null;
    if (
      target?.namespace !== "android_app" ||
      target?.package_name !== "com.chants.chants" ||
      !Array.isArray(target?.sha256_cert_fingerprints) ||
      target.sha256_cert_fingerprints.length === 0 ||
      !target.sha256_cert_fingerprints.every((value) =>
        typeof value === "string" && fingerprintPattern.test(value)
      )
    ) errors.push("Android Asset Links contains an invalid app identity or fingerprint");
  }
  return errors;
}

const invokedPath = process.argv[1] ? pathToFileURL(resolve(process.argv[1])).href : "";
if (invokedPath === import.meta.url) {
  const errors = collectLaunchServiceErrors();
  if (errors.length > 0) {
    for (const error of errors) process.stderr.write(`Launch services check failed: ${error}\n`);
    process.exitCode = 1;
  } else {
    process.stdout.write("Launch services contract passes.\n");
  }
}
