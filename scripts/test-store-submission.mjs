import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { deflateSync } from 'node:zlib';

import {
  analyzePngContent,
  hasPlausibleScreenshotContent,
  inspectPng,
  inspectPngPixel,
  validatePngFile,
  validateStorePacket,
} from './check-store-submission.mjs';

const projectRoot = fileURLToPath(new URL('..', import.meta.url));
const baselineSubmission = JSON.parse(readFileSync(join(projectRoot, 'store/submission.json'), 'utf8'));
const baselineManifest = JSON.parse(readFileSync(join(projectRoot, 'store/screenshots/manifest.json'), 'utf8'));
const screenshotFrame = readFileSync(join(projectRoot, 'store/screenshots/frame.html'), 'utf8');
const featureGraphicPreview = readFileSync(join(projectRoot, 'store/assets/google-feature-graphic.html'), 'utf8');

function clone(value) {
  return structuredClone(value);
}

function validate(submission = baselineSubmission, manifest = baselineManifest) {
  return validateStorePacket({ projectRoot, submission, manifest });
}

const crcTable = Array.from({ length: 256 }, (_, tableIndex) => {
  let crc = tableIndex;
  for (let bit = 0; bit < 8; bit += 1) crc = (crc & 1) ? 0xedb88320 ^ (crc >>> 1) : crc >>> 1;
  return crc >>> 0;
});

function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) crc = crcTable[(crc ^ byte) & 255] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data) {
  const typeBytes = Buffer.from(type, 'ascii');
  const chunk = Buffer.alloc(12 + data.length);
  chunk.writeUInt32BE(data.length, 0);
  typeBytes.copy(chunk, 4);
  data.copy(chunk, 8);
  chunk.writeUInt32BE(crc32(Buffer.concat([typeBytes, data])), 8 + data.length);
  return chunk;
}

function writeSolidRgbPng(path, width, height, rgb) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 2;
  const row = Buffer.alloc(1 + width * 3);
  for (let x = 0; x < width; x += 1) {
    row[1 + x * 3] = rgb[0];
    row[2 + x * 3] = rgb[1];
    row[3 + x * 3] = rgb[2];
  }
  const raw = Buffer.concat(Array.from({ length: height }, () => row));
  writeFileSync(path, Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    pngChunk('IHDR', ihdr),
    pngChunk('IDAT', deflateSync(raw)),
    pngChunk('IEND', Buffer.alloc(0)),
  ]));
}

test('accepts the honest prepared and not-submitted packet', () => {
  assert.deepEqual(validate(), []);
});

test('rejects schema, locale, version, and iPad support drift', () => {
  const submission = clone(baselineSubmission);
  submission.schemaVersion = 1;
  submission.apple.locale = 'en-GB';
  submission.google.locale = 'en-GB';
  submission.identity.versionCode = 2;
  submission.identity.appleSupportedDevices.push('iPad');
  const errors = validate(submission);
  assert(errors.includes('submission schemaVersion must be 3'));
  assert(errors.includes('Apple locale must be en-US'));
  assert(errors.includes('Google locale must be en-US'));
  assert(errors.includes('versionCode must be 1'));
  assert(errors.includes('Apple V1 supported devices must be iPhone only'));
});

test('rejects over-limit Apple and Google listing copy', () => {
  const submission = clone(baselineSubmission);
  submission.apple.keywords = 'x'.repeat(101);
  submission.google.shortDescription = 'x'.repeat(81);
  const errors = validate(submission);
  assert(errors.some((error) => error.includes('Apple keywords exceeds 100 bytes')));
  assert(errors.some((error) => error.includes('Google short description exceeds 80 characters')));
});

test('rejects identity, age-rule, rating, and market drift', () => {
  const submission = clone(baselineSubmission);
  submission.identity.operator = 'Chants';
  submission.identity.accountMinimumAge = '13+';
  submission.identity.storeRatingStatus = '17+';
  submission.identity.releaseMarkets.push('Australia');
  const errors = validate(submission);
  assert(errors.includes('operator identity drifted'));
  assert(errors.includes('account minimum age drifted'));
  assert(errors.includes('store rating evidence boundary drifted'));
  assert(errors.some((error) => error.startsWith('release markets must be exactly')));
});

test('rejects an off-domain or insecure trust URL', () => {
  const submission = clone(baselineSubmission);
  submission.urls.privacy = 'http://example.com/privacy';
  const errors = validate(submission);
  assert(errors.some((error) => error.includes('privacy URL must be https://chantsfc.com/privacy')));
  assert(errors.includes('privacy URL must use HTTPS'));
  assert(errors.includes('privacy URL must use chantsfc.com'));
});

test('rejects an invalid or unbound source baseline', () => {
  const submission = clone(baselineSubmission);
  submission.sourceBaseline.commit = '0'.repeat(40);
  submission.sourceBaseline.allowedDrift = [];
  submission.sourceBaseline.boundFiles[0].sha256 = 'f'.repeat(64);
  const errors = validate(submission);
  assert(errors.includes('sourceBaseline.allowedDrift drifted'));
  assert(errors.includes('sourceBaseline.commit does not exist locally'));
  assert(errors.some((error) => error.includes('SHA-256 does not match')));
});

test('binds the shipped crest directory and every reviewed crest file', () => {
  const provenance = JSON.parse(
    readFileSync(join(projectRoot, 'assets/clubs/crests/provenance.json'), 'utf8'),
  );
  const expected = [
    ...provenance.assets.map((asset) => asset.localFile),
    'assets/clubs/crests/provenance.json',
  ].sort();
  const allowed = baselineSubmission.sourceBaseline.allowedDrift
    .filter((path) => path.startsWith('assets/clubs/crests/'))
    .sort();
  const bound = baselineSubmission.sourceBaseline.boundFiles
    .map((entry) => entry.path)
    .filter((path) => path.startsWith('assets/clubs/crests/'))
    .sort();

  assert(
    baselineSubmission.sourceBaseline.trackedPaths.includes(
      'assets/clubs/crests',
    ),
  );
  assert.deepEqual(allowed, expected);
  assert.deepEqual(bound, expected);
});

test('rejects asset bytes that do not match their evidence digest', () => {
  const submission = clone(baselineSubmission);
  submission.assetEvidence.googlePlayIcon.sha256 = '0'.repeat(64);
  submission.assetEvidence.googleFeatureGraphic.sha256 = '1'.repeat(64);
  submission.assetEvidence.googleFeatureGraphic.sourceSha256 = '2'.repeat(64);
  const errors = validate(submission);
  assert(errors.includes('Google Play icon SHA-256 does not match store/assets/google-play-icon.png'));
  assert(errors.includes('Google feature graphic SHA-256 does not match store/assets/google-feature-graphic.png'));
  assert(errors.includes('Google feature graphic source SHA-256 does not match scripts/render-google-feature-graphic.swift'));
});

test('rejects stale feature graphic approval claims', () => {
  const submission = clone(baselineSubmission);
  submission.readiness.googleFeatureGraphicFinal = true;
  submission.assetEvidence.googleFeatureGraphic.ownerApproved = true;
  submission.assetEvidence.googleFeatureGraphic.approvedOn = '2026-09-07';
  submission.assetEvidence.googleFeatureGraphic.approvedSha256 = '0'.repeat(64);
  submission.assetEvidence.googleFeatureGraphic.approvedSourceSha256 = '1'.repeat(64);
  const errors = validate(submission);
  assert(errors.includes('approved feature graphic SHA-256 must match the current asset SHA-256'));
  assert(errors.includes('approved feature graphic source SHA-256 must match the current source SHA-256'));
});

test('rejects retained feature graphic approval fields after the final gate is cleared', () => {
  const submission = clone(baselineSubmission);
  submission.readiness.googleFeatureGraphicFinal = false;
  submission.assetEvidence.googleFeatureGraphic.ownerApproved = false;
  const errors = validate(submission);
  assert(errors.includes('unapproved feature graphic must not retain an approval date'));
  assert(errors.includes('unapproved feature graphic must not retain an approved SHA-256'));
  assert(errors.includes('unapproved feature graphic must not retain an approved source SHA-256'));
});

test('rejects ready status while evidence gates remain false', () => {
  const submission = clone(baselineSubmission);
  submission.status = 'ready_for_submission';
  submission.readiness.googleFeatureGraphicFinal = false;
  submission.assetEvidence.googleFeatureGraphic.ownerApproved = false;
  submission.assetEvidence.googleFeatureGraphic.approvedOn = null;
  submission.assetEvidence.googleFeatureGraphic.approvedSha256 = null;
  submission.assetEvidence.googleFeatureGraphic.approvedSourceSha256 = null;
  const errors = validate(submission);
  assert(errors.includes('ready packet requires readiness.releaseCandidateMerged'));
  assert(errors.includes('ready packet requires readiness.reviewAccountVerified'));
  assert(errors.includes('ready packet requires readiness.googleFeatureGraphicFinal'));
});

test('rejects a captured screenshot without exact source, output, and release evidence', () => {
  const manifest = clone(baselineManifest);
  manifest.scenes[0].iosStatus = 'captured';
  const errors = validate(baselineSubmission, manifest);
  assert(errors.includes('01-stage ios output requires a SHA-256'));
  assert(errors.includes('01-stage ios source requires a SHA-256'));
  assert(errors.some((error) => error.includes('01-stage ios screenshot is missing')));
  assert(errors.some((error) => error.includes('01-stage ios source capture is missing')));
  assert(errors.includes('01-stage ios requires release commit evidence'));
  assert(errors.includes('01-stage ios requires verified release artifact evidence'));
});

test('rejects a pending screenshot with stale evidence', () => {
  const manifest = clone(baselineManifest);
  manifest.scenes[0].iosSha256 = '0'.repeat(64);
  manifest.scenes[0].iosSourceSha256 = '1'.repeat(64);
  const errors = validate(baselineSubmission, manifest);
  assert(errors.includes('01-stage ios pending output SHA-256 must be null'));
  assert(errors.includes('01-stage ios pending source SHA-256 must be null'));
});

test('rejects placeholder-like PNG content', () => {
  const directory = mkdtempSync(join(tmpdir(), 'chants-store-test-'));
  const path = join(directory, 'solid.png');
  try {
    writeSolidRgbPng(path, 40, 70, [17, 17, 17]);
    const analysis = analyzePngContent(path);
    assert.equal(analysis.distinctSampledColors, 1);
    assert.equal(analysis.channelRange, 0);
    assert.equal(hasPlausibleScreenshotContent(analysis), false);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test('store PNG validation invokes placeholder-content rejection', () => {
  const directory = mkdtempSync(join(tmpdir(), 'chants-store-validator-test-'));
  const path = join(directory, 'solid.png');
  try {
    writeSolidRgbPng(path, 40, 70, [17, 17, 17]);
    const errors = validatePngFile({
      projectRoot: directory,
      relativePath: 'solid.png',
      expected: { width: 40, height: 70, alphaAllowed: false, contentRequired: true },
      label: 'captured scene',
    });
    assert(errors.includes('captured scene appears blank or placeholder-like'));
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test('current store icons have exact format and dimensions', () => {
  assert.deepEqual(inspectPng(join(projectRoot, 'assets/icon/ios_icon_1024.png')), {
    width: 1024,
    height: 1024,
    hasAlpha: false,
    colorType: 2,
  });
  assert.deepEqual(inspectPng(join(projectRoot, 'store/assets/google-play-icon.png')), {
    width: 512,
    height: 512,
    hasAlpha: true,
    colorType: 6,
  });
  assert(analyzePngContent(join(projectRoot, 'store/assets/google-play-icon.png')).maxOpaqueRadius <= 192);
});

test('current Google feature graphic has exact dimensions, no alpha, and valid size', () => {
  const path = join(projectRoot, 'store/assets/google-feature-graphic.png');
  assert.deepEqual(inspectPng(path), { width: 1024, height: 500, hasAlpha: false, colorType: 2 });
  assert(statSync(path).size <= 15 * 1024 * 1024);
  assert.deepEqual(inspectPngPixel(path, 0, 0), [8, 8, 6, 255]);
  assert.deepEqual(inspectPngPixel(path, 60, 97), [238, 103, 79, 255]);
  assert.deepEqual(inspectPngPixel(path, 60, 65), [255, 193, 38, 255]);
});

test('feature graphic preview displays only the canonical PNG', () => {
  assert.equal((featureGraphicPreview.match(/<img\b/g) ?? []).length, 1);
  assert.match(
    featureGraphicPreview,
    /<img\s+src="google-feature-graphic\.png"\s+width="1024"\s+height="500"\s+alt="[^"]+">/,
  );
  assert.doesNotMatch(featureGraphicPreview, /<(?:h1|h2|section|p)\b|@font-face|--(?:gold|paper|coral)\b/);
});

test('screenshot frame preserves the five-scene, two-platform, and hold-state contract', () => {
  for (const scene of ['01-stage', '02-clubs', '03-chant', '04-create', '05-songbook']) {
    assert(screenshotFrame.includes(`'${scene}'`));
  }
  assert(screenshotFrame.includes("params.get('platform')==='android'?'android':'ios'"));
  assert(screenshotFrame.includes("'source/'+platform+'/'+scene+'.png'"));
  assert(screenshotFrame.includes("document.body.dataset.mode='storyboard'"));
  assert(screenshotFrame.includes("capture.addEventListener('load'"));
  assert.match(screenshotFrame, /<div class="capture-shell missing" id="shell">/);
  assert(screenshotFrame.includes('Final app capture pending.'));
  assert(screenshotFrame.includes('Do not publish this frame'));
});

test('old documentation screenshots are not valid iPhone 6.9-inch store captures', () => {
  const oldCapture = inspectPng(join(projectRoot, 'docs/screenshots/home.png'));
  assert.equal(oldCapture.width, 1320);
  assert.equal(oldCapture.height, 2663);
  assert.notEqual(oldCapture.height, baselineManifest.rules.iosTarget.height);
});
