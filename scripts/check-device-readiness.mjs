#!/usr/bin/env node
// Local inventory only. No Firebase clients, config reads, installs or builds.
import { accessSync, constants, statSync } from 'node:fs';
import { delimiter, dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
export const probeOptions = Object.freeze({
  encoding: 'utf8', timeout: 15000, maxBuffer: 256 * 1024, shell: false, killSignal: 'SIGKILL',
});

function regularFile(path) {
  try {
    if (!statSync(path).isFile()) return 'missing';
    accessSync(path, constants.R_OK);
    return 'found';
  } catch (error) {
    return ['ENOENT', 'ENOTDIR'].includes(error.code) ? 'missing' : 'unknown';
  }
}

function findTool(name, environment) {
  for (const dir of (environment.PATH || '').split(delimiter).filter(Boolean)) {
    const path = join(dir, name);
    try {
      if (statSync(path).isFile()) {
        accessSync(path, constants.X_OK);
        return path;
      }
    } catch { /* Another PATH entry may contain this executable. */ }
  }
  return null;
}

export function parseIosDevices(output) {
  const rows = JSON.parse(output);
  if (!Array.isArray(rows)) throw new Error('Expected device list');
  const counts = { physical: 0, simulators: 0, unavailable: 0 };
  for (const row of rows) {
    if (!row || typeof row.platform !== 'string') throw new Error('Invalid device row');
    if (!['com.apple.platform.iphoneos', 'com.apple.platform.iphonesimulator'].includes(row.platform)) continue;
    if (typeof row.available !== 'boolean' || typeof row.simulator !== 'boolean') throw new Error('Missing device state');
    if (!row.available) counts.unavailable++;
    else if (row.simulator) counts.simulators++;
    else counts.physical++;
  }
  return counts;
}

export function parseAndroidDevices(output) {
  const lines = output.trim().split(/\r?\n/);
  if (lines.shift() !== 'List of devices attached') throw new Error('Expected adb header');
  const counts = { physical: 0, emulators: 0, unauthorized: 0, offline: 0 };
  for (const line of lines.filter(line => line.trim())) {
    const match = /^(\S+)\s+(device|unauthorized|offline)(?:\s+.*)?$/.exec(line);
    if (!match) throw new Error('Unknown device state');
    if (match[2] !== 'device') counts[match[2]]++;
    else if (match[1].startsWith('emulator-')) counts.emulators++;
    else counts.physical++;
  }
  return counts;
}

export function collectReadiness({
  root = repoRoot, platform = 'ios', devices = false,
  environment = process.env, host = process.platform,
  run = (command, args) => spawnSync(command, args, probeOptions),
  inspectFile = regularFile, locate = findTool,
} = {}) {
  if (!['ios', 'android'].includes(platform)) throw new Error('Unsupported platform');
  const checks = [];
  const add = (id, status, detail, next) => checks.push({ id, status, detail, next });
  for (const file of ['pubspec.yaml', 'firebase.json', '.dart_tool/package_config.json', 'lib/firebase_options.dart',
    platform === 'ios' ? 'ios/Runner/GoogleService-Info.plist' : 'android/app/google-services.json']) {
    const status = inspectFile(join(root, file));
    add(file, status, status === 'found' ? 'Readable file exists. Contents and project identity NOT validated.' : 'Required local file is missing or inaccessible.',
      file.includes('package_config') ? 'Use the prepared checkout, or arrange dependency setup separately.' : 'Use the configured checkout. Do not overwrite an existing file with an example or paste its contents.');
  }
  const tools = new Map();
  for (const name of platform === 'ios' ? ['flutter', 'xcodebuild', 'xcrun', 'pod'] : ['flutter', 'java', 'adb']) {
    const path = locate(name, environment);
    tools.set(name, path);
    add(`tool:${name}`, path ? 'found' : 'missing', path ? 'Executable located. Version and compatibility NOT validated.' : 'Executable not found on PATH.',
      'Resolve the named tool locally; this check does not install tools or alter PATH.');
  }
  if (platform === 'ios' && host !== 'darwin') {
    add('host', 'missing', 'iOS tooling requires macOS.', 'Run the iOS check on the Mac, or select --platform android.');
  }
  if (!devices) {
    add('devices', 'not-checked', 'Device discovery was not requested.', 'Connect/unlock a test device, then rerun with --devices. Discovery may start local OS/ADB services.');
  } else if ((platform === 'ios' && host !== 'darwin') || !tools.get(platform === 'ios' ? 'xcrun' : 'adb')) {
    add('devices', 'unknown', 'Device discovery cannot run without the selected platform tool.', 'Resolve the missing tool and rerun.');
  } else {
    try {
      const command = tools.get(platform === 'ios' ? 'xcrun' : 'adb');
      const args = platform === 'ios' ? ['xcdevice', 'list', '--timeout', '5'] : ['devices', '-l'];
      const result = run(command, args);
      if (result.error || result.status !== 0 || result.signal) throw new Error('Probe did not complete');
      const counts = platform === 'ios' ? parseIosDevices(result.stdout) : parseAndroidDevices(result.stdout);
      const physical = counts.physical;
      const virtual = counts.simulators ?? counts.emulators;
      const blocked = (counts.unauthorized || 0) + (counts.offline || 0);
      add('devices', physical > 0 && !blocked ? 'found' : 'attention',
        `${physical} physical target(s), ${virtual} simulator/emulator target(s), ${counts.unavailable || 0} unavailable, ${counts.unauthorized || 0} unauthorized, ${counts.offline || 0} offline. Identifiers omitted.`,
        'Choose the intended physical device manually. Trust, provisioning, signing and app installation are NOT proved by discovery.');
    } catch {
      // Never echo SDK output/errors: they can include names, IDs and environment data.
      add('devices', 'unknown', 'Discovery failed, timed out, exceeded its output limit, or returned an unsupported shape.',
        'Check the local device tool yourself, then retry. No raw device output was retained by this script.');
    }
  }
  return {
    schemaVersion: 1, checkedAt: new Date().toISOString(), platform, scope: 'Local preparation inventory, NOT launch or deployment approval',
    checks,
    remainingGates: ['Independent review', 'Approved and observed backend rollout', 'Config project identity', 'Signed physical-device walkthrough', 'Media/cleanup and destructive-test approvals'],
  };
}

export function parseArgs(args) {
  const options = { platform: 'ios', devices: false, json: false, help: false };
  const seen = new Set();
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (seen.has(arg)) throw new Error('Duplicate option');
    seen.add(arg);
    if (arg === '--platform' && ['ios', 'android'].includes(args[i + 1])) options.platform = args[++i];
    else if (arg === '--devices') options.devices = true;
    else if (arg === '--json') options.json = true;
    else if (arg === '--help') options.help = true;
    else throw new Error('Unknown option');
  }
  return options;
}

export function exitCode(report) {
  return report.checks.some(row => ['missing', 'unknown', 'attention'].includes(row.status)) ? 1 : 0;
}

export function main(args = process.argv.slice(2)) {
  let options;
  try { options = parseArgs(args); }
  catch {
    console.error('Usage: node scripts/check-device-readiness.mjs [--platform ios|android] [--devices] [--json]');
    return 2;
  }
  if (options.help) {
    console.log('Local inventory. Default: file presence and executable locations only. No config reads, keychain access, builds, installs or Firebase calls.\n--devices opts into local SDK discovery (15-second limit); OS/ADB services may start.\n--json emits only sanitized results. Exit 0: no local inventory issue; 1: missing/unknown/attention; 2: usage.\nExit 0 is NOT authorization to launch, deploy or test against production.');
    return 0;
  }
  const report = collectReadiness(options);
  console.log(options.json ? JSON.stringify(report, null, 2) : [report.scope, `Platform: ${report.platform}`,
    ...report.checks.map(row => `[${row.status.toUpperCase()}] ${row.id}\n  ${row.detail}\n  Next: ${row.next}`),
    `Still required: ${report.remainingGates.join('; ')}.`].join('\n'));
  return exitCode(report);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) process.exitCode = main();
