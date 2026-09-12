#!/usr/bin/env node
// Exact-candidate Android preflight and opt-in physical-device installer.
import { createHash } from 'node:crypto';
import { accessSync, constants, existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { delimiter, dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
export const candidate = Object.freeze({
  sourceAnchor: 'fedfe2cc2ea0d5cf2da26b3525fd15961a2ac248',
  apkPath: 'build/app/outputs/flutter-apk/app-release.apk',
  apkSha256: 'b5eb1cca78069f25574aec4b9f6d1b659a68698775451bc07ca7adef58f14151',
  packageName: 'com.chants.chants',
  versionName: '1.0.0',
  versionCode: '1',
  minSdk: 24,
  targetSdk: 36,
  certificateSha256: '8277987e342dc5a2de3f2a96c36ce11efe5c33a66582cfd2f00953a0daf2fc55',
});

const rejectedPermissions = new Set([
  'com.google.android.gms.permission.AD_ID',
  'android.permission.ACCESS_ADSERVICES_ATTRIBUTION',
  'android.permission.ACCESS_ADSERVICES_AD_ID',
  'android.permission.ACCESS_ADSERVICES_CUSTOM_AUDIENCE',
  'android.permission.ACCESS_ADSERVICES_TOPICS',
]);

const commandOptions = Object.freeze({
  encoding: 'utf8',
  timeout: 120000,
  maxBuffer: 1024 * 1024,
  shell: false,
  killSignal: 'SIGKILL',
});

function findOnPath(name, environment) {
  for (const directory of (environment.PATH || '').split(delimiter).filter(Boolean)) {
    const executable = join(directory, name);
    try {
      if (statSync(executable).isFile()) {
        accessSync(executable, constants.X_OK);
        return executable;
      }
    } catch { /* Continue through the bounded PATH. */ }
  }
  return null;
}

function latestBuildTool(name, environment) {
  const roots = [
    environment.ANDROID_HOME,
    environment.ANDROID_SDK_ROOT,
    '/usr/local/share/android-commandlinetools',
    '/opt/homebrew/share/android-commandlinetools',
  ].filter(Boolean);
  const matches = [];
  for (const root of roots) {
    const buildTools = join(root, 'build-tools');
    try {
      for (const version of readdirSync(buildTools)) {
        const executable = join(buildTools, version, name);
        if (existsSync(executable)) matches.push({ version, executable });
      }
    } catch { /* Try the next known SDK root. */ }
  }
  return matches.sort((left, right) => left.version.localeCompare(
    right.version,
    undefined,
    { numeric: true },
  )).at(-1)?.executable ?? null;
}

function javaHome(environment) {
  const homes = [
    environment.JAVA_HOME,
    '/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home',
    '/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home',
    '/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home',
    '/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home',
  ].filter(Boolean);
  return homes.find((home) => existsSync(join(home, 'bin', 'java'))) ?? null;
}

function invoke(run, command, args, environment) {
  const result = run(command, args, { ...commandOptions, env: environment });
  if (result.error || result.signal || result.status !== 0) {
    const boundedOutput = `${result.stdout || ''}\n${result.stderr || ''}`;
    if (boundedOutput.includes('INSTALL_FAILED_UPDATE_INCOMPATIBLE')) {
      throw new Error(
        'Existing Chants installation has a different signature; uninstall '
        + 'com.chants.chants first, which removes its local app data, then retry',
      );
    }
    if (boundedOutput.includes('INSTALL_FAILED_USER_RESTRICTED')) {
      throw new Error(
        'Android blocked USB installation; allow installs via USB in Developer '
        + 'options, unlock the phone, then retry',
      );
    }
    throw new Error('Command failed');
  }
  return result.stdout || '';
}

function parseBadging(output) {
  const packageMatch = /^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'/m.exec(output);
  const minimumMatch = /^sdkVersion:'(\d+)'/m.exec(output);
  const targetMatch = /^targetSdkVersion:'(\d+)'/m.exec(output);
  if (!packageMatch || !minimumMatch || !targetMatch) throw new Error('Incomplete APK metadata');
  const permissions = [...output.matchAll(/^uses-permission: name='([^']+)'/gm)].map((match) => match[1]);
  return {
    packageName: packageMatch[1],
    versionCode: packageMatch[2],
    versionName: packageMatch[3],
    minSdk: Number(minimumMatch[1]),
    targetSdk: Number(targetMatch[1]),
    permissions,
  };
}

function parseCertificate(output) {
  const digest = /Signer #1 certificate SHA-256 digest: ([0-9a-f:]+)/i.exec(output)?.[1];
  const v2 = /Verified using v2 scheme \(APK Signature Scheme v2\): true/i.test(output);
  if (!digest || !v2) throw new Error('Required APK signature is absent');
  return digest.replaceAll(':', '').toLowerCase();
}

export function inspectCandidate({
  root = repoRoot,
  expected = candidate,
  apkPath = expected.apkPath,
  environment = process.env,
  run = spawnSync,
  locate = (name) => findOnPath(name, environment),
  locateBuildTool = (name) => latestBuildTool(name, environment),
  locateJavaHome = () => javaHome(environment),
} = {}) {
  const apk = resolve(root, apkPath);
  if (!existsSync(apk) || !statSync(apk).isFile()) throw new Error('Candidate APK is missing');
  const digest = createHash('sha256').update(readFileSync(apk)).digest('hex');
  if (digest !== expected.apkSha256) throw new Error('Candidate APK hash does not match');

  const aapt = locateBuildTool('aapt');
  const apksigner = locateBuildTool('apksigner');
  const zipalign = locateBuildTool('zipalign');
  const selectedJavaHome = locateJavaHome();
  if (!aapt || !apksigner || !zipalign || !selectedJavaHome) {
    throw new Error('Android verification tools are unavailable');
  }
  const toolEnvironment = { ...environment, JAVA_HOME: selectedJavaHome };
  const metadata = parseBadging(invoke(run, aapt, ['dump', 'badging', apk], toolEnvironment));
  if (metadata.packageName !== expected.packageName
      || metadata.versionName !== expected.versionName
      || metadata.versionCode !== expected.versionCode
      || metadata.minSdk !== expected.minSdk
      || metadata.targetSdk !== expected.targetSdk) {
    throw new Error('Candidate APK identity does not match');
  }
  if (metadata.permissions.some((permission) => rejectedPermissions.has(permission))) {
    throw new Error('Candidate APK contains a rejected advertising permission');
  }
  const signerOutput = invoke(
    run,
    apksigner,
    ['verify', '--verbose', '--print-certs', apk],
    toolEnvironment,
  );
  if (parseCertificate(signerOutput) !== expected.certificateSha256) {
    throw new Error('Candidate APK certificate does not match');
  }
  invoke(run, zipalign, ['-c', '-P', '16', '-v', '4', apk], toolEnvironment);
  return {
    ready: true,
    sourceAnchor: expected.sourceAnchor,
    artifact: apkPath === expected.apkPath
      ? expected.apkPath
      : 'explicit hash-bound APK',
    sha256: digest,
    packageName: metadata.packageName,
    versionName: metadata.versionName,
    versionCode: metadata.versionCode,
    minSdk: metadata.minSdk,
    targetSdk: metadata.targetSdk,
    certificateSha256: expected.certificateSha256,
    mergedPermissions: [...metadata.permissions].sort(),
    rejectedAdvertisingPermissions: 0,
    pageAlignment16KiB: true,
    adbAvailable: Boolean(locate('adb')),
  };
}

function selectPhysicalDevice(output) {
  const lines = output.trim().split(/\r?\n/);
  if (lines.shift() !== 'List of devices attached') throw new Error('Unexpected ADB response');
  const rows = lines.filter((line) => line.trim()).map((line) => {
    const match = /^(\S+)\s+(device|unauthorized|offline)(?:\s+.*)?$/.exec(line);
    if (!match) throw new Error('Unexpected ADB device state');
    return { serial: match[1], state: match[2] };
  });
  if (rows.some((row) => row.state !== 'device')) throw new Error('A device needs authorization or recovery');
  const physical = rows.filter((row) => !row.serial.startsWith('emulator-'));
  const emulators = rows.length - physical.length;
  if (physical.length !== 1 || emulators !== 0) throw new Error('Connect exactly one physical Android device');
  return physical[0].serial;
}

export function installCandidate({
  root = repoRoot,
  apkPath = candidate.apkPath,
  environment = process.env,
  run = spawnSync,
  locate = (name) => findOnPath(name, environment),
  inspection,
} = {}) {
  const verified = inspection ?? inspectCandidate({
    root,
    apkPath,
    environment,
    run,
    locate,
  });
  const apk = resolve(root, apkPath);
  if (verified.sha256) {
    if (!existsSync(apk) || !statSync(apk).isFile()) {
      throw new Error('Candidate APK is missing');
    }
    const installDigest = createHash('sha256').update(readFileSync(apk)).digest('hex');
    if (installDigest !== verified.sha256) {
      throw new Error('Candidate APK changed after verification');
    }
  }
  const adb = locate('adb');
  if (!adb) throw new Error('ADB is unavailable');
  const serial = selectPhysicalDevice(invoke(run, adb, ['devices', '-l'], environment));
  const qemu = invoke(
    run,
    adb,
    ['-s', serial, 'shell', 'getprop', 'ro.kernel.qemu'],
    environment,
  ).trim();
  const hardware = invoke(
    run,
    adb,
    ['-s', serial, 'shell', 'getprop', 'ro.hardware'],
    environment,
  ).trim();
  if (qemu === '1' || /(?:goldfish|ranchu|vbox|nox|qemu)/i.test(hardware)) {
    throw new Error('Connected Android target is an emulator');
  }
  const deviceSdkText = invoke(
    run,
    adb,
    ['-s', serial, 'shell', 'getprop', 'ro.build.version.sdk'],
    environment,
  ).trim();
  const deviceSdk = Number(deviceSdkText);
  if (!Number.isInteger(deviceSdk) || deviceSdk < candidate.minSdk) {
    throw new Error('Android device does not meet the minimum SDK');
  }
  const installOutput = invoke(run, adb, ['-s', serial, 'install', '-r', apk], environment);
  if (!/^Success\s*$/m.test(installOutput)) throw new Error('ADB did not confirm installation');
  const packageOutput = invoke(
    run,
    adb,
    ['-s', serial, 'shell', 'pm', 'path', candidate.packageName],
    environment,
  );
  if (!/^package:/m.test(packageOutput)) throw new Error('Installed package was not found');
  const launchOutput = invoke(
    run,
    adb,
    ['-s', serial, 'shell', 'am', 'start', '-W', '-n', `${candidate.packageName}/.MainActivity`],
    environment,
  );
  if (!/^Status: ok$/m.test(launchOutput)) throw new Error('Android launch was not confirmed');
  return {
    ...verified,
    installed: true,
    launched: true,
    deviceSdk,
    installMode: 'replace while preserving app data',
    deviceIdentifiersReported: false,
  };
}

export function parseArgs(args) {
  const options = { install: false, json: false, help: false, apkPath: candidate.apkPath };
  const seen = new Set();
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (seen.has(arg)) throw new Error('Duplicate option');
    seen.add(arg);
    if (arg === '--install') options.install = true;
    else if (arg === '--json') options.json = true;
    else if (arg === '--help') options.help = true;
    else if (arg === '--apk') {
      const value = args[index + 1];
      if (!value || value.startsWith('--')) throw new Error('Missing APK path');
      options.apkPath = resolve(value);
      index += 1;
    }
    else throw new Error('Unknown option');
  }
  return options;
}

export function main(args = process.argv.slice(2)) {
  let options;
  try { options = parseArgs(args); }
  catch {
    console.error('Usage: node scripts/prepare-android-device.mjs [--apk PATH] [--install] [--json]');
    return 2;
  }
  if (options.help) {
    console.log('Validates the fixed signed release APK from the build output or --apk PATH. A relative --apk PATH is resolved from the current working directory. --install requires exactly one authorized physical Android device, preserves app data when signatures match, installs the verified APK, and launches Chants. No device identifier or raw SDK output is printed.');
    return 0;
  }
  try {
    const inspection = inspectCandidate({ apkPath: options.apkPath });
    const report = options.install
      ? installCandidate({ inspection, apkPath: options.apkPath })
      : inspection;
    console.log(options.json ? JSON.stringify(report, null, 2) : [
      'Chants Android candidate is verified.',
      `Package: ${report.packageName}`,
      `Version: ${report.versionName} (${report.versionCode})`,
      `APK SHA-256: ${report.sha256}`,
      options.install
        ? `Installed and launched on one physical Android SDK ${report.deviceSdk} target. Device identifier omitted.`
        : 'No device action was requested. Connect one phone and rerun with --install.',
    ].join('\n'));
    return 0;
  } catch (error) {
    const reason = error instanceof Error ? error.message : 'Unknown local preparation error';
    console.error(`Android candidate preparation stopped safely: ${reason}. No raw tool or device output was printed.`);
    return 1;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) process.exitCode = main();
