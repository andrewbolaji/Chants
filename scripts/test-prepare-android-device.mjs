import { strict as assert } from 'node:assert';
import { createHash } from 'node:crypto';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';
import {
  candidate,
  inspectCandidate,
  installCandidate,
  parseArgs,
} from './prepare-android-device.mjs';

function fixture() {
  const root = mkdtempSync(join(tmpdir(), 'chants android preparation '));
  const apk = join(root, candidate.apkPath);
  mkdirSync(dirname(apk), { recursive: true });
  return { root, apk };
}

function badging({ permission = '' } = {}) {
  return [
    `package: name='${candidate.packageName}' versionCode='${candidate.versionCode}' versionName='${candidate.versionName}'`,
    `sdkVersion:'${candidate.minSdk}'`,
    `targetSdkVersion:'${candidate.targetSdk}'`,
    permission ? `uses-permission: name='${permission}'` : '',
  ].join('\n');
}

function signer({ digest = candidate.certificateSha256, v2 = true } = {}) {
  return [
    `Verified using v2 scheme (APK Signature Scheme v2): ${v2}`,
    `Signer #1 certificate SHA-256 digest: ${digest}`,
  ].join('\n');
}

function prepareFixture() {
  const prepared = fixture();
  const bytes = Buffer.from('candidate bytes');
  writeFileSync(prepared.apk, bytes);
  const sha = createHash('sha256').update(bytes).digest('hex');
  return { ...prepared, sha };
}

function inspectOptions(prepared, outputs = {}, expected = candidate) {
  return {
    root: prepared.root,
    expected,
    environment: { PATH: '/tools' },
    locate: (name) => name === 'adb' ? '/tools/adb' : null,
    locateBuildTool: (name) => `/tools/${name}`,
    locateJavaHome: () => '/java',
    run: (command) => ({
      status: 0,
      stdout: command.endsWith('aapt') ? (outputs.badging ?? badging()) : (outputs.signer ?? signer()),
    }),
  };
}

test('candidate inspection accepts the exact identity, signature and permission boundary', () => {
  const prepared = prepareFixture();
  try {
    const expected = { ...candidate, apkSha256: prepared.sha };
    const result = inspectCandidate(inspectOptions(prepared, {}, expected));
    assert.equal(result.ready, true);
    assert.equal(result.packageName, candidate.packageName);
    assert.equal(result.adbAvailable, true);
    assert.equal(result.rejectedAdvertisingPermissions, 0);
  } finally { rmSync(prepared.root, { recursive: true, force: true }); }
});

test('candidate inspection rejects stale bytes, wrong identity, ad permission, signer or v2 state', () => {
  const prepared = prepareFixture();
  try {
    assert.throws(() => inspectCandidate(inspectOptions(prepared)), /hash/);
    for (const outputs of [
      { badging: badging().replace(candidate.packageName, 'com.example.other') },
      { badging: badging({ permission: 'com.google.android.gms.permission.AD_ID' }) },
      { signer: signer({ digest: '00'.repeat(32) }) },
      { signer: signer({ v2: false }) },
    ]) {
      const expected = { ...candidate, apkSha256: prepared.sha };
      assert.throws(() => inspectCandidate(inspectOptions(prepared, outputs, expected)));
    }
  } finally { rmSync(prepared.root, { recursive: true, force: true }); }
});

test('explicit install uses one physical device, preserves data and never reports its identifier', () => {
  const prepared = prepareFixture();
  const calls = [];
  try {
    const result = installCandidate({
      root: prepared.root,
      environment: { PATH: '/tools' },
      locate: () => '/tools/adb',
      inspection: { ready: true, packageName: candidate.packageName },
      run: (_command, args) => {
        calls.push(args);
        if (args[0] === 'devices') return { status: 0, stdout: 'List of devices attached\nPRIVATE-SERIAL device product:test\n' };
        if (args.includes('getprop')) return { status: 0, stdout: '35\n' };
        if (args.includes('install')) return { status: 0, stdout: 'Success\n' };
        if (args.includes('pm')) return { status: 0, stdout: 'package:/data/app/base.apk\n' };
        return { status: 0, stdout: 'Status: ok\n' };
      },
    });
    assert.equal(result.installed, true);
    assert.equal(result.launched, true);
    assert.equal(result.deviceIdentifiersReported, false);
    assert.doesNotMatch(JSON.stringify(result), /PRIVATE-SERIAL/);
    assert.ok(calls.some((args) => args.includes('install') && args.includes('-r')));
  } finally { rmSync(prepared.root, { recursive: true, force: true }); }
});

test('install rejects emulator, ambiguous, unauthorized and unsupported devices before mutation', () => {
  const prepared = prepareFixture();
  try {
    for (const devices of [
      'List of devices attached\nemulator-5554 device\n',
      'List of devices attached\nONE device\nTWO device\n',
      'List of devices attached\nLOCKED unauthorized\n',
    ]) {
      let installs = 0;
      assert.throws(() => installCandidate({
        root: prepared.root,
        locate: () => '/tools/adb',
        inspection: { ready: true },
        run: (_command, args) => {
          if (args.includes('install')) installs += 1;
          return { status: 0, stdout: devices };
        },
      }));
      assert.equal(installs, 0);
    }
    let installs = 0;
    assert.throws(() => installCandidate({
      root: prepared.root,
      locate: () => '/tools/adb',
      inspection: { ready: true },
      run: (_command, args) => {
        if (args[0] === 'devices') return { status: 0, stdout: 'List of devices attached\nPHONE device\n' };
        if (args.includes('install')) installs += 1;
        return { status: 0, stdout: '23\n' };
      },
    }), /minimum SDK/);
    assert.equal(installs, 0);
  } finally { rmSync(prepared.root, { recursive: true, force: true }); }
});

test('CLI arguments remain bounded and unknown values are not echoed', () => {
  assert.deepEqual(parseArgs(['--install', '--json']), { install: true, json: true, help: false });
  for (const args of [['--install', '--install'], ['--device', 'PRIVATE-ID'], ['--apk', '/tmp/other']]) {
    assert.throws(() => parseArgs(args));
  }
  const script = new URL('./prepare-android-device.mjs', import.meta.url);
  const bad = spawnSync(process.execPath, [script.pathname, '--PRIVATE-ARG'], { encoding: 'utf8' });
  assert.equal(bad.status, 2);
  assert.doesNotMatch(bad.stderr, /PRIVATE-ARG/);
});
