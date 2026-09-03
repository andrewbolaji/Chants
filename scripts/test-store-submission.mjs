import assert from 'node:assert/strict';
import { readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import { inspectPng, validateStorePacket } from './check-store-submission.mjs';

const projectRoot = fileURLToPath(new URL('..', import.meta.url));
const baselineSubmission = JSON.parse(
  readFileSync(join(projectRoot, 'store/submission.json'), 'utf8'),
);
const baselineManifest = JSON.parse(
  readFileSync(join(projectRoot, 'store/screenshots/manifest.json'), 'utf8'),
);
const screenshotFrame = readFileSync(
  join(projectRoot, 'store/screenshots/frame.html'),
  'utf8',
);

function clone(value) {
  return structuredClone(value);
}

function validate(submission = baselineSubmission, manifest = baselineManifest) {
  return validateStorePacket({
    projectRoot,
    submission,
    manifest,
  });
}

test('accepts the honest prepared and not-submitted packet', () => {
  assert.deepEqual(validate(), []);
});

test('rejects over-limit Apple and Google listing copy', () => {
  const submission = clone(baselineSubmission);
  submission.apple.keywords = 'x'.repeat(101);
  submission.google.shortDescription = 'x'.repeat(81);
  const errors = validate(submission);
  assert(errors.some((error) => error.includes('Apple keywords exceeds 100 bytes')));
  assert(errors.some((error) => error.includes('Google short description exceeds 80 characters')));
});

test('rejects identity, age-rule, and market drift', () => {
  const submission = clone(baselineSubmission);
  submission.identity.operator = 'Chants';
  submission.identity.accountMinimumAge = '13+';
  submission.identity.releaseMarkets.push('Australia');
  const errors = validate(submission);
  assert(errors.includes('operator identity drifted'));
  assert(errors.includes('account minimum age drifted'));
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

test('rejects ready status while evidence gates remain false', () => {
  const submission = clone(baselineSubmission);
  submission.status = 'ready_for_submission';
  submission.readiness.googleFeatureGraphicFinal = false;
  const errors = validate(submission);
  assert(errors.includes('ready packet requires readiness.releaseCandidateMerged'));
  assert(errors.includes('ready packet requires readiness.reviewAccountVerified'));
  assert(errors.includes('ready packet requires readiness.googleFeatureGraphicFinal'));
});

test('rejects a captured screenshot that is absent', () => {
  const submission = clone(baselineSubmission);
  const manifest = clone(baselineManifest);
  manifest.scenes[0].iosStatus = 'captured';
  submission.readiness.iosScreenshotsCaptured = false;
  const errors = validate(submission, manifest);
  assert(errors.some((error) => error.includes('01-stage ios screenshot is missing')));
});

test('rejects an alpha-bearing, wrong-size image as an iOS screenshot', () => {
  const manifest = clone(baselineManifest);
  manifest.scenes[0].iosStatus = 'captured';
  manifest.scenes[0].iosPath = 'assets/icon/android_foreground.png';
  const errors = validate(baselineSubmission, manifest);
  assert(errors.some((error) => error.includes('01-stage ios screenshot width must be 1320')));
  assert(errors.some((error) => error.includes('01-stage ios screenshot must not contain alpha')));
});

test('current App Store and Google Play icons have exact dimensions and no alpha', () => {
  assert.deepEqual(
    inspectPng(join(projectRoot, 'assets/icon/ios_icon_1024.png')),
    { width: 1024, height: 1024, hasAlpha: false, colorType: 2 },
  );
  assert.deepEqual(
    inspectPng(join(projectRoot, 'store/assets/google-play-icon.png')),
    { width: 512, height: 512, hasAlpha: false, colorType: 2 },
  );
});

test('current Google feature graphic has exact dimensions, no alpha, and valid size', () => {
  const path = join(projectRoot, 'store/assets/google-feature-graphic.png');
  assert.deepEqual(
    inspectPng(path),
    { width: 1024, height: 500, hasAlpha: false, colorType: 2 },
  );
  assert(statSync(path).size <= 15 * 1024 * 1024);
});

test('screenshot frame preserves the five-scene and two-platform source contract', () => {
  for (const scene of ['01-stage', '02-clubs', '03-chant', '04-create', '05-songbook']) {
    assert(screenshotFrame.includes(`'${scene}'`));
  }
  assert(screenshotFrame.includes("params.get('platform')==='android'?'android':'ios'"));
  assert(screenshotFrame.includes("'source/'+platform+'/'+scene+'.png'"));
  assert(screenshotFrame.includes("document.body.dataset.mode='storyboard'"));
  assert(screenshotFrame.includes("capture.addEventListener('load'"));
  assert(screenshotFrame.includes('Final app capture pending.'));
  assert(screenshotFrame.includes('Do not publish this frame'));
});

test('old documentation screenshots are not valid iPhone 6.9-inch store captures', () => {
  const oldCapture = inspectPng(join(projectRoot, 'docs/screenshots/home.png'));
  assert.equal(oldCapture.width, 1320);
  assert.equal(oldCapture.height, 2663);
  assert.notEqual(oldCapture.height, baselineManifest.rules.iosTarget.height);
});
