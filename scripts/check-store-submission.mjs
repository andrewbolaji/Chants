#!/usr/bin/env node

import { existsSync, readFileSync, statSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const EXPECTED_MARKETS = new Set([
  'United States',
  'United Kingdom',
  'Canada',
]);
const EXPECTED_URLS = {
  marketing: 'https://chantsfc.com/',
  support: 'https://chantsfc.com/support',
  privacy: 'https://chantsfc.com/privacy',
  terms: 'https://chantsfc.com/terms',
  community: 'https://chantsfc.com/community',
  rights: 'https://chantsfc.com/rights',
  accountDeletion: 'https://chantsfc.com/delete-account',
};
const REQUIRED_READINESS = [
  'releaseCandidateMerged',
  'productionOpenAndWalked',
  'publicUrlsVerified',
  'supportDeliveryVerified',
  'reviewAccountVerified',
  'iosDistributionArchiveVerified',
  'androidReleaseBundleVerified',
  'iosScreenshotsCaptured',
  'androidScreenshotsCaptured',
  'googleFeatureGraphicFinal',
  'applePrivacyEntered',
  'googleDataSafetyEntered',
  'storeRatingQuestionnairesCompleted',
  'consoleMetadataEntered',
];
const EXPECTED_SCENES = [
  '01-stage',
  '02-clubs',
  '03-chant',
  '04-create',
  '05-songbook',
];

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function add(errors, condition, message) {
  if (!condition) errors.push(message);
}

function textLength(errors, value, limit, label, { bytes = false, min = 1 } = {}) {
  add(errors, typeof value === 'string', `${label} must be text`);
  if (typeof value !== 'string') return;
  const length = bytes ? Buffer.byteLength(value, 'utf8') : [...value].length;
  add(errors, length >= min, `${label} must be at least ${min} characters`);
  add(errors, length <= limit, `${label} exceeds ${limit}${bytes ? ' bytes' : ' characters'}`);
}

export function inspectPng(path) {
  const bytes = readFileSync(path);
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (bytes.length < 33 || !bytes.subarray(0, 8).equals(signature)) {
    throw new Error(`${path} is not a valid PNG`);
  }
  const width = bytes.readUInt32BE(16);
  const height = bytes.readUInt32BE(20);
  const colorType = bytes[25];
  let hasTransparencyChunk = false;
  let offset = 8;
  while (offset + 12 <= bytes.length) {
    const length = bytes.readUInt32BE(offset);
    const type = bytes.toString('ascii', offset + 4, offset + 8);
    if (type === 'tRNS') hasTransparencyChunk = true;
    offset += 12 + length;
    if (type === 'IEND') break;
  }
  return {
    width,
    height,
    hasAlpha: colorType === 4 || colorType === 6 || hasTransparencyChunk,
    colorType,
  };
}

function checkPng(errors, root, relativePath, expected, label) {
  const path = resolve(root, relativePath);
  add(errors, existsSync(path), `${label} is missing at ${relativePath}`);
  if (!existsSync(path)) return;
  try {
    const png = inspectPng(path);
    add(errors, png.width === expected.width, `${label} width must be ${expected.width}, got ${png.width}`);
    add(errors, png.height === expected.height, `${label} height must be ${expected.height}, got ${png.height}`);
    if (expected.alphaAllowed === false) {
      add(errors, !png.hasAlpha, `${label} must not contain alpha`);
    }
    if (expected.maxBytes) {
      add(errors, statSync(path).size <= expected.maxBytes, `${label} exceeds ${expected.maxBytes} bytes`);
    }
  } catch (error) {
    errors.push(`${label}: ${error.message}`);
  }
}

export function validateStorePacket({ projectRoot, submission, manifest } = {}) {
  const root = resolve(projectRoot ?? fileURLToPath(new URL('..', import.meta.url)));
  const metadata = submission ?? JSON.parse(
    readFileSync(resolve(root, 'store/submission.json'), 'utf8'),
  );
  const screenshots = manifest ?? JSON.parse(
    readFileSync(resolve(root, 'store/screenshots/manifest.json'), 'utf8'),
  );
  const errors = [];

  add(errors, metadata.schemaVersion === 1, 'submission schemaVersion must be 1');
  add(
    errors,
    ['prepared_not_submitted', 'ready_for_submission', 'submitted'].includes(metadata.status),
    'submission status is invalid',
  );
  add(errors, /^[0-9a-f]{40}$/.test(metadata.sourceBaseline ?? ''), 'sourceBaseline must be a full Git SHA');

  const identity = metadata.identity ?? {};
  add(errors, identity.productName === 'Chants FC', 'productName must remain Chants FC');
  add(errors, identity.installedDisplayName === 'Chants', 'installedDisplayName must remain Chants');
  add(errors, identity.operator === 'ThunderRiver Tech LLC', 'operator identity drifted');
  add(errors, identity.supportEmail === 'support@chantsfc.com', 'support email drifted');
  add(errors, identity.iosBundleId === 'com.chants.chants', 'iOS bundle ID drifted');
  add(errors, identity.androidPackageName === 'com.chants.chants', 'Android package name drifted');
  add(errors, identity.accountMinimumAge === '17+', 'account minimum age drifted');
  const markets = new Set(identity.releaseMarkets ?? []);
  add(
    errors,
    markets.size === EXPECTED_MARKETS.size && [...EXPECTED_MARKETS].every((market) => markets.has(market)),
    'release markets must be exactly United States, United Kingdom, and Canada',
  );

  add(errors, isPlainObject(metadata.urls), 'urls must be an object');
  for (const [key, expected] of Object.entries(EXPECTED_URLS)) {
    const value = metadata.urls?.[key];
    add(errors, value === expected, `${key} URL must be ${expected}`);
    if (typeof value === 'string') {
      try {
        const url = new URL(value);
        add(errors, url.protocol === 'https:', `${key} URL must use HTTPS`);
        add(errors, url.hostname === 'chantsfc.com', `${key} URL must use chantsfc.com`);
      } catch {
        errors.push(`${key} URL is invalid`);
      }
    }
  }

  const apple = metadata.apple ?? {};
  textLength(errors, apple.name, 30, 'Apple name', { min: 2 });
  textLength(errors, apple.subtitle, 30, 'Apple subtitle');
  textLength(errors, apple.promotionalText, 170, 'Apple promotional text');
  textLength(errors, apple.keywords, 100, 'Apple keywords', { bytes: true });
  textLength(errors, apple.description, 4000, 'Apple description');
  textLength(errors, apple.reviewNotes, 4000, 'Apple review notes', { bytes: true });
  add(errors, apple.primaryCategory === 'Sports', 'Apple primary category must be Sports');
  add(errors, apple.secondaryCategory === 'Social Networking', 'Apple secondary category must be Social Networking');
  add(errors, apple.screenshotSet === 'iphone_6_9_portrait', 'Apple screenshot set must be iPhone 6.9-inch portrait');

  const google = metadata.google ?? {};
  textLength(errors, google.title, 30, 'Google title');
  textLength(errors, google.shortDescription, 80, 'Google short description');
  textLength(errors, google.fullDescription, 4000, 'Google full description');
  textLength(errors, google.appAccessInstructions, 4000, 'Google app access instructions');
  add(errors, google.category === 'Sports', 'Google category must be Sports');
  const expectedFeatureGraphicPath = 'store/assets/google-feature-graphic.png';
  add(
    errors,
    google.featureGraphicPath === expectedFeatureGraphicPath,
    'Google feature graphic path drifted',
  );
  const featureGraphicPath = resolve(root, expectedFeatureGraphicPath);
  if (
    metadata.readiness?.googleFeatureGraphicFinal === true
    || existsSync(featureGraphicPath)
  ) {
    checkPng(
      errors,
      root,
      expectedFeatureGraphicPath,
      { width: 1024, height: 500, alphaAllowed: false, maxBytes: 15 * 1024 * 1024 },
      'Google feature graphic',
    );
  }

  add(errors, isPlainObject(metadata.readiness), 'readiness must be an object');
  for (const key of [...REQUIRED_READINESS, 'submitted']) {
    add(errors, typeof metadata.readiness?.[key] === 'boolean', `readiness.${key} must be boolean`);
  }
  if (metadata.status === 'prepared_not_submitted') {
    add(errors, metadata.readiness?.submitted === false, 'prepared packet cannot claim submitted');
  }
  if (metadata.status === 'ready_for_submission') {
    for (const key of REQUIRED_READINESS) {
      add(errors, metadata.readiness?.[key] === true, `ready packet requires readiness.${key}`);
    }
    add(errors, metadata.readiness?.submitted === false, 'ready packet cannot already claim submitted');
  }
  if (metadata.status === 'submitted') {
    for (const key of REQUIRED_READINESS) {
      add(errors, metadata.readiness?.[key] === true, `submitted packet requires readiness.${key}`);
    }
    add(errors, metadata.readiness?.submitted === true, 'submitted status requires submitted evidence');
  }

  add(errors, screenshots.schemaVersion === 1, 'screenshot schemaVersion must be 1');
  add(errors, screenshots.captureSource === 'exact submitted release candidate', 'screenshot source contract drifted');
  const iosTarget = screenshots.rules?.iosTarget ?? {};
  const androidTarget = screenshots.rules?.androidTarget ?? {};
  add(errors, iosTarget.width === 1320 && iosTarget.height === 2868, 'iOS screenshot target must be 1320 by 2868');
  add(errors, iosTarget.format === 'png' && iosTarget.alphaAllowed === false, 'iOS screenshots must be no-alpha PNG');
  add(errors, androidTarget.width === 1080 && androidTarget.height === 1920, 'Android screenshot target must be 1080 by 1920');
  add(errors, androidTarget.format === 'png' && androidTarget.alphaAllowed === false, 'Android screenshots must be no-alpha PNG');

  const scenes = Array.isArray(screenshots.scenes) ? screenshots.scenes : [];
  add(errors, scenes.length === EXPECTED_SCENES.length, 'screenshot manifest must contain exactly five scenes');
  const ids = new Set(scenes.map((scene) => scene.id));
  add(errors, ids.size === scenes.length, 'screenshot scene IDs must be unique');
  for (const id of EXPECTED_SCENES) add(errors, ids.has(id), `missing screenshot scene ${id}`);

  const allPaths = [];
  let allIosCaptured = scenes.length === EXPECTED_SCENES.length;
  let allAndroidCaptured = scenes.length === EXPECTED_SCENES.length;
  for (const scene of scenes) {
    textLength(errors, scene.headline, 80, `${scene.id ?? 'unknown'} headline`);
    add(errors, Array.isArray(scene.mustShow) && scene.mustShow.length > 0, `${scene.id} must list visible truth requirements`);
    for (const platform of ['ios', 'android']) {
      const pathKey = `${platform}Path`;
      const statusKey = `${platform}Status`;
      const expectedPath = `store/screenshots/${platform}/${scene.id}.png`;
      const status = scene[statusKey];
      add(errors, scene[pathKey] === expectedPath, `${scene.id} ${platform} path must be ${expectedPath}`);
      add(errors, ['pending_capture', 'captured'].includes(status), `${scene.id} ${platform} status is invalid`);
      allPaths.push(scene[pathKey]);
      if (status === 'captured') {
        checkPng(errors, root, scene[pathKey], platform === 'ios' ? iosTarget : androidTarget, `${scene.id} ${platform} screenshot`);
      } else if (platform === 'ios') {
        allIosCaptured = false;
      } else {
        allAndroidCaptured = false;
      }
    }
  }
  add(errors, new Set(allPaths).size === allPaths.length, 'screenshot output paths must be unique');
  add(
    errors,
    metadata.readiness?.iosScreenshotsCaptured === allIosCaptured,
    'iOS screenshot readiness must match all five manifest statuses',
  );
  add(
    errors,
    metadata.readiness?.androidScreenshotsCaptured === allAndroidCaptured,
    'Android screenshot readiness must match all five manifest statuses',
  );

  checkPng(
    errors,
    root,
    'assets/icon/ios_icon_1024.png',
    { width: 1024, height: 1024, alphaAllowed: false },
    'App Store icon source',
  );
  checkPng(
    errors,
    root,
    'store/assets/google-play-icon.png',
    { width: 512, height: 512, alphaAllowed: false, maxBytes: 1024 * 1024 },
    'Google Play icon',
  );

  return errors;
}

const scriptPath = fileURLToPath(import.meta.url);
if (process.argv[1] && resolve(process.argv[1]) === scriptPath) {
  const projectRoot = process.argv[2]
    ? resolve(process.argv[2])
    : resolve(dirname(scriptPath), '..');
  const errors = validateStorePacket({ projectRoot });
  if (errors.length > 0) {
    console.error('Store submission packet failed validation:');
    for (const error of errors) console.error(`- ${error}`);
    process.exitCode = 1;
  } else {
    console.log('Store submission packet passes in prepared, not-submitted state.');
  }
}
