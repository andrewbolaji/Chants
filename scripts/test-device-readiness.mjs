import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync, chmodSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { collectReadiness, parseArgs, parseIosDevices, parseAndroidDevices, exitCode, probeOptions } from './check-device-readiness.mjs';

const ready = { root: '/synthetic checkout with spaces', host: 'darwin', inspectFile: () => 'found', locate: name => `/tools/${name}` };
const ios = [{ platform: 'com.apple.platform.iphoneos', simulator: false, available: true, identifier: 'PRIVATE-ID', name: 'PRIVATE-NAME' }];

test('default is passive and found files/tools never claim runtime readiness', () => {
  let probes = 0;
  const report = collectReadiness({ ...ready, run: () => probes++ });
  assert.equal(probes, 0);
  assert.equal(report.checks.find(row => row.id === 'devices').status, 'not-checked');
  assert.match(report.scope, /NOT launch/);
  assert.equal(exitCode(report), 0);
});

test('missing config, unreadable config and missing tools fail the inventory', () => {
  for (const status of ['missing', 'unknown']) {
    const report = collectReadiness({ ...ready, inspectFile: path => path.endsWith('firebase_options.dart') ? status : 'found' });
    assert.equal(exitCode(report), 1);
  }
  assert.equal(exitCode(collectReadiness({ ...ready, locate: () => null, devices: true })), 1);
});

test('iOS discovery uses exact bounded tool arguments and strips names/identifiers', () => {
  const report = collectReadiness({ ...ready, devices: true, run: (command, args) => {
    assert.equal(command, '/tools/xcrun');
    assert.deepEqual(args, ['xcdevice', 'list', '--timeout', '5']);
    return { status: 0, stdout: JSON.stringify(ios) };
  } });
  assert.equal(exitCode(report), 0);
  assert.doesNotMatch(JSON.stringify(report), /PRIVATE/);
  assert.deepEqual(probeOptions, { encoding: 'utf8', timeout: 15000, maxBuffer: 262144, shell: false, killSignal: 'SIGKILL' });
});

test('simulator-only, unavailable and non-macOS cannot pass a physical iOS check', () => {
  for (const rows of [[], [{ ...ios[0], simulator: true }], [{ ...ios[0], available: false }]]) {
    assert.equal(exitCode(collectReadiness({ ...ready, devices: true, run: () => ({ status: 0, stdout: JSON.stringify(rows) }) })), 1);
  }
  assert.equal(exitCode(collectReadiness({ ...ready, host: 'linux', devices: true, run: () => assert.fail('must not run') })), 1);
});

test('probe errors, malformed data and interrupted success-looking output stay unknown', () => {
  for (const result of [
    { status: 0, stdout: '{}' }, { status: 0, stdout: '[{}]' }, { status: 0, stdout: 'PRIVATE-ERROR' },
    { status: 1, stdout: JSON.stringify(ios) }, { status: 0, stdout: JSON.stringify(ios), signal: 'SIGTERM' },
    { status: null, error: new Error('PRIVATE-ERROR') },
  ]) {
    const report = collectReadiness({ ...ready, devices: true, run: () => result });
    assert.equal(report.checks.at(-1).status, 'unknown');
    assert.equal(exitCode(report), 1);
    assert.doesNotMatch(JSON.stringify(report), /PRIVATE/);
  }
  assert.throws(() => parseIosDevices(JSON.stringify([{ platform: 'com.apple.platform.iphoneos' }])));
});

test('Android discovery distinguishes connected, unauthorized, offline and emulators', () => {
  const output = 'List of devices attached\nPRIVATE-ID device product:test\nemulator-5554 device\nLOCKED unauthorized\nLOST offline\n';
  assert.deepEqual(parseAndroidDevices(output), { physical: 1, emulators: 1, unauthorized: 1, offline: 1 });
  const report = collectReadiness({ ...ready, platform: 'android', devices: true, run: (command, args) => {
    assert.equal(command, '/tools/adb'); assert.deepEqual(args, ['devices', '-l']);
    return { status: 0, stdout: output };
  } });
  assert.equal(exitCode(report), 1);
  assert.doesNotMatch(JSON.stringify(report), /PRIVATE|LOCKED|LOST/);
  for (const output of ['oops', 'List of devices attached\nSERIAL recovery', 'List of devices attached\ngarbage']) assert.throws(() => parseAndroidDevices(output));
  assert.equal(exitCode(collectReadiness({ ...ready, platform: 'android', devices: true, run: () => ({ status: 0, stdout: 'List of devices attached\nSERIAL device\n' }) })), 0);
});

test('arguments reject unknown, repeated and incomplete options', () => {
  assert.deepEqual(parseArgs(['--platform', 'android', '--devices', '--json']), { platform: 'android', devices: true, json: true, help: false });
  for (const args of [['--platform'], ['--platform', 'web'], ['--devices', '--devices'], ['--write'], ['--root', '/other']]) assert.throws(() => parseArgs(args));
});

test('real filesystem inspection works with spaces and never reads or rewrites config bytes', () => {
  const root = mkdtempSync(join(tmpdir(), 'chants readiness '));
  try {
    for (const dir of ['lib', 'ios/Runner', '.dart_tool', 'bin']) mkdirSync(join(root, dir), { recursive: true });
    for (const file of ['pubspec.yaml', 'firebase.json', 'lib/firebase_options.dart', 'ios/Runner/GoogleService-Info.plist', '.dart_tool/package_config.json']) writeFileSync(join(root, file), 'SYNTHETIC-SECRET');
    for (const tool of ['flutter', 'xcodebuild', 'xcrun', 'pod']) { writeFileSync(join(root, 'bin', tool), '#!/bin/sh\nexit 99\n'); chmodSync(join(root, 'bin', tool), 0o755); }
    const report = collectReadiness({ root, host: 'darwin', environment: { PATH: join(root, 'bin') }, run: () => assert.fail('passive check invoked a command') });
    assert.equal(exitCode(report), 0);
    assert.doesNotMatch(JSON.stringify(report), /SYNTHETIC-SECRET/);
    assert.equal(readFileSync(join(root, 'lib/firebase_options.dart'), 'utf8'), 'SYNTHETIC-SECRET');
    rmSync(join(root, 'lib/firebase_options.dart'));
    symlinkSync(join(root, 'does-not-exist'), join(root, 'lib/firebase_options.dart'));
    assert.equal(exitCode(collectReadiness({ root, host: 'darwin', environment: { PATH: join(root, 'bin') } })), 1);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('actual CLI help and usage do not invoke platform tools or echo unknown arguments', () => {
  const script = new URL('./check-device-readiness.mjs', import.meta.url);
  const help = spawnSync(process.execPath, [script.pathname, '--help'], { encoding: 'utf8', env: { PATH: '' } });
  assert.equal(help.status, 0); assert.match(help.stdout, /No config reads/);
  const bad = spawnSync(process.execPath, [script.pathname, '--PRIVATE-ARG'], { encoding: 'utf8', env: { PATH: '' } });
  assert.equal(bad.status, 2); assert.doesNotMatch(bad.stderr, /PRIVATE-ARG/);
});

test('actual CLI inventories its own checkout even when launched from another directory', () => {
  const result = spawnSync(process.execPath, [new URL('./check-device-readiness.mjs', import.meta.url).pathname, '--json'], { cwd: tmpdir(), encoding: 'utf8', env: { PATH: '' } });
  assert.equal(result.status, 1); // No tools on this synthetic PATH, not a false ready result.
  const report = JSON.parse(result.stdout);
  assert.equal(report.checks.find(row => row.id === 'pubspec.yaml').status, 'found');
  assert.equal(report.checks.find(row => row.id === 'devices').status, 'not-checked');
});
