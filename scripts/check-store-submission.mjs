#!/usr/bin/env node

import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { inflateSync } from 'node:zlib';

const SHA40 = /^[0-9a-f]{40}$/;
const SHA256 = /^[0-9a-f]{64}$/;
const EXPECTED_MARKETS = new Set(['United States', 'United Kingdom', 'Canada']);
const EXPECTED_URLS = {
  marketing: 'https://chantsfc.com/',
  support: 'https://chantsfc.com/support',
  privacy: 'https://chantsfc.com/privacy',
  terms: 'https://chantsfc.com/terms',
  community: 'https://chantsfc.com/community',
  rights: 'https://chantsfc.com/rights',
  accountDeletion: 'https://chantsfc.com/delete-account',
};
const EXPECTED_TRACKED_PATHS = [
  'assets/clubs/crests',
  'lib',
  'functions',
  'firestore.rules',
  'storage.rules',
  'firestore.indexes.json',
  'seed',
  'seed_data',
  'hosting',
  'firebase.json',
  'pubspec.yaml',
  'pubspec.lock',
  'ios',
  'android',
];
const EXPECTED_ALLOWED_DRIFT = [
  'android/app/src/main/AndroidManifest.xml',
  'android/gradle.properties',
  'assets/clubs/crests/arsenal.png',
  'assets/clubs/crests/aston-villa.png',
  'assets/clubs/crests/bournemouth.png',
  'assets/clubs/crests/brentford.png',
  'assets/clubs/crests/brighton-hove-albion.png',
  'assets/clubs/crests/chelsea.png',
  'assets/clubs/crests/coventry-city.png',
  'assets/clubs/crests/crystal-palace.png',
  'assets/clubs/crests/everton.png',
  'assets/clubs/crests/fulham.png',
  'assets/clubs/crests/hull-city.png',
  'assets/clubs/crests/ipswich-town.png',
  'assets/clubs/crests/leeds-united.png',
  'assets/clubs/crests/liverpool.png',
  'assets/clubs/crests/manchester-city.png',
  'assets/clubs/crests/manchester-united.png',
  'assets/clubs/crests/newcastle-united.png',
  'assets/clubs/crests/nottingham-forest.png',
  'assets/clubs/crests/provenance.json',
  'assets/clubs/crests/sunderland.png',
  'assets/clubs/crests/tottenham-hotspur.png',
  'functions/src/performance.ts',
  'functions/test/performance.test.ts',
  'hosting/index.html',
  'hosting/site.css',
  'ios/Runner.xcodeproj/project.pbxproj',
  'ios/Runner/Info.plist',
  'lib/app/app.dart',
  'lib/app/colors.dart',
  'lib/app/providers.dart',
  'lib/data/repositories/first_run_orientation_repository.dart',
  'lib/data/services/performance_media_selection.dart',
  'lib/presentation/auth/email_sign_in_screen.dart',
  'lib/presentation/auth/first_run_orientation_screen.dart',
  'lib/presentation/auth/launch_reveal_screen.dart',
  'lib/presentation/auth/onboarding_screen.dart',
  'lib/presentation/auth/sign_in_screen.dart',
  'lib/presentation/auth/sign_up_screen.dart',
  'lib/presentation/browse/chant_call_up_card.dart',
  'lib/presentation/browse/competition_screen.dart',
  'lib/presentation/browse/team_screen.dart',
  'lib/presentation/create/perform_chant_screen.dart',
  'lib/presentation/feed/chant_stage_screen.dart',
  'lib/presentation/saved/saved_songbook_screen.dart',
  'lib/presentation/shared/club_crest.dart',
  'lib/presentation/shared/club_signal.dart',
  'lib/presentation/shared/gold_foil_badge.dart',
  'lib/presentation/shared/vote_controls.dart',
  'lib/presentation/submit/submit_chant_screen.dart',
  'pubspec.lock',
  'pubspec.yaml',
  'seed/catalogue_content.test.ts',
  'seed/exact_chant_seed.test.ts',
  'seed/exact_chant_seed.ts',
  'seed/exact_chant_seed_cli.ts',
  'seed/package.json',
  'seed_data/clubs/arsenal.json',
];
const EXPECTED_FEATURE_GRAPHIC_INPUTS = [
  'assets/fonts/Anton-Regular.ttf',
  'assets/fonts/SpaceMono-Bold.ttf',
  'store/assets/google-play-icon.png',
];
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
const EXPECTED_SCENES = ['01-stage', '02-clubs', '03-chant', '04-create', '05-songbook'];

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function add(errors, condition, message) {
  if (!condition) errors.push(message);
}

function exactArray(actual, expected) {
  return Array.isArray(actual)
    && actual.length === expected.length
    && actual.every((value, index) => value === expected[index]);
}

function textLength(errors, value, limit, label, { bytes = false, min = 1 } = {}) {
  add(errors, typeof value === 'string', `${label} must be text`);
  if (typeof value !== 'string') return;
  const length = bytes ? Buffer.byteLength(value, 'utf8') : [...value].length;
  add(errors, length >= min, `${label} must be at least ${min} characters`);
  add(errors, length <= limit, `${label} exceeds ${limit}${bytes ? ' bytes' : ' characters'}`);
}

function git(root, args) {
  return execFileSync('git', args, {
    cwd: root,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  }).trimEnd();
}

function gitSucceeds(root, args) {
  try {
    git(root, args);
    return true;
  } catch {
    return false;
  }
}

function fileSha256(path) {
  return createHash('sha256').update(readFileSync(path)).digest('hex');
}

function parsePng(path) {
  const bytes = readFileSync(path);
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (bytes.length < 33 || !bytes.subarray(0, 8).equals(signature)) {
    throw new Error(`${path} is not a valid PNG`);
  }

  const chunks = [];
  let offset = 8;
  while (offset + 12 <= bytes.length) {
    const length = bytes.readUInt32BE(offset);
    const dataStart = offset + 8;
    const dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) throw new Error(`${path} has a truncated PNG chunk`);
    const type = bytes.toString('ascii', offset + 4, offset + 8);
    chunks.push({ type, data: bytes.subarray(dataStart, dataEnd) });
    offset = dataEnd + 4;
    if (type === 'IEND') break;
  }

  const ihdr = chunks.find((chunk) => chunk.type === 'IHDR')?.data;
  if (!ihdr || ihdr.length !== 13) throw new Error(`${path} is missing a valid IHDR chunk`);
  const width = ihdr.readUInt32BE(0);
  const height = ihdr.readUInt32BE(4);
  const bitDepth = ihdr[8];
  const colorType = ihdr[9];
  const interlace = ihdr[12];
  const hasTransparencyChunk = chunks.some((chunk) => chunk.type === 'tRNS');
  return {
    bytes,
    chunks,
    width,
    height,
    bitDepth,
    colorType,
    interlace,
    hasAlpha: colorType === 4 || colorType === 6 || hasTransparencyChunk,
  };
}

export function inspectPng(path) {
  const png = parsePng(path);
  return {
    width: png.width,
    height: png.height,
    hasAlpha: png.hasAlpha,
    colorType: png.colorType,
  };
}

function paeth(a, b, c) {
  const p = a + b - c;
  const pa = Math.abs(p - a);
  const pb = Math.abs(p - b);
  const pc = Math.abs(p - c);
  if (pa <= pb && pa <= pc) return a;
  if (pb <= pc) return b;
  return c;
}

function samplesPerPixel(colorType) {
  if (colorType === 0) return 1;
  if (colorType === 2) return 3;
  if (colorType === 4) return 2;
  if (colorType === 6) return 4;
  return 0;
}

function decodePngRows(path) {
  const png = parsePng(path);
  if (png.bitDepth !== 8 || png.interlace !== 0) {
    throw new Error(`${path} must be an 8-bit, non-interlaced PNG for content inspection`);
  }
  const bytesPerPixel = samplesPerPixel(png.colorType);
  if (bytesPerPixel === 0) {
    throw new Error(`${path} uses unsupported PNG color type ${png.colorType}`);
  }
  const compressed = Buffer.concat(
    png.chunks.filter((chunk) => chunk.type === 'IDAT').map((chunk) => chunk.data),
  );
  const raw = inflateSync(compressed);
  const rowBytes = png.width * bytesPerPixel;
  const expectedBytes = png.height * (rowBytes + 1);
  if (raw.length !== expectedBytes) throw new Error(`${path} has unexpected decoded PNG length`);

  let previous = Buffer.alloc(rowBytes);
  const rows = [];
  for (let y = 0; y < png.height; y += 1) {
    const sourceOffset = y * (rowBytes + 1);
    const filter = raw[sourceOffset];
    const source = raw.subarray(sourceOffset + 1, sourceOffset + 1 + rowBytes);
    const row = Buffer.allocUnsafe(rowBytes);
    for (let index = 0; index < rowBytes; index += 1) {
      const left = index >= bytesPerPixel ? row[index - bytesPerPixel] : 0;
      const up = previous[index] ?? 0;
      const upperLeft = index >= bytesPerPixel ? previous[index - bytesPerPixel] : 0;
      if (filter === 0) row[index] = source[index];
      else if (filter === 1) row[index] = (source[index] + left) & 255;
      else if (filter === 2) row[index] = (source[index] + up) & 255;
      else if (filter === 3) row[index] = (source[index] + Math.floor((left + up) / 2)) & 255;
      else if (filter === 4) row[index] = (source[index] + paeth(left, up, upperLeft)) & 255;
      else throw new Error(`${path} uses unsupported PNG filter ${filter}`);
    }
    rows.push(row);
    previous = row;
  }
  return { png, bytesPerPixel, rows };
}

export function inspectPngPixel(path, x, y) {
  const { png, bytesPerPixel, rows } = decodePngRows(path);
  if (!Number.isInteger(x) || !Number.isInteger(y) || x < 0 || x >= png.width || y < 0 || y >= png.height) {
    throw new Error(`${path} pixel coordinate ${x},${y} is outside ${png.width} by ${png.height}`);
  }
  const row = rows[y];
  const index = x * bytesPerPixel;
  const gray = row[index];
  const red = png.colorType === 0 || png.colorType === 4 ? gray : row[index];
  const green = png.colorType === 0 || png.colorType === 4 ? gray : row[index + 1];
  const blue = png.colorType === 0 || png.colorType === 4 ? gray : row[index + 2];
  const alpha = png.colorType === 4 ? row[index + 1] : png.colorType === 6 ? row[index + 3] : 255;
  return [red, green, blue, alpha];
}

export function analyzePngContent(path) {
  const { png, bytesPerPixel, rows } = decodePngRows(path);
  const colors = new Set();
  let minChannel = 255;
  let maxChannel = 0;
  let opaquePixels = 0;
  let maxOpaqueRadius = 0;
  const sampleEvery = Math.max(1, Math.floor((png.width * png.height) / 200000));

  for (let y = 0; y < png.height; y += 1) {
    const row = rows[y];

    for (let x = 0; x < png.width; x += 1) {
      const index = x * bytesPerPixel;
      const gray = row[index];
      const red = png.colorType === 0 || png.colorType === 4 ? gray : row[index];
      const green = png.colorType === 0 || png.colorType === 4 ? gray : row[index + 1];
      const blue = png.colorType === 0 || png.colorType === 4 ? gray : row[index + 2];
      const alpha = png.colorType === 4 ? row[index + 1] : png.colorType === 6 ? row[index + 3] : 255;
      if ((y * png.width + x) % sampleEvery === 0) {
        colors.add((red << 16) | (green << 8) | blue);
        minChannel = Math.min(minChannel, red, green, blue);
        maxChannel = Math.max(maxChannel, red, green, blue);
      }
      if (alpha > 0) {
        opaquePixels += 1;
        maxOpaqueRadius = Math.max(
          maxOpaqueRadius,
          Math.hypot(x + 0.5 - png.width / 2, y + 0.5 - png.height / 2),
        );
      }
    }
  }

  return {
    distinctSampledColors: colors.size,
    channelRange: maxChannel - minChannel,
    opaquePixels,
    maxOpaqueRadius,
  };
}

export function hasPlausibleScreenshotContent(analysis) {
  return analysis.distinctSampledColors >= 32 && analysis.channelRange >= 24;
}

function checkPng(errors, root, relativePath, expected, label) {
  const path = resolve(root, relativePath);
  add(errors, existsSync(path), `${label} is missing at ${relativePath}`);
  if (!existsSync(path)) return;
  try {
    const png = inspectPng(path);
    add(errors, png.width === expected.width, `${label} width must be ${expected.width}, got ${png.width}`);
    add(errors, png.height === expected.height, `${label} height must be ${expected.height}, got ${png.height}`);
    if (expected.alphaAllowed === false) add(errors, !png.hasAlpha, `${label} must not contain alpha`);
    if (expected.alphaRequired === true) add(errors, png.hasAlpha, `${label} must contain alpha`);
    if (expected.maxBytes) add(errors, statSync(path).size <= expected.maxBytes, `${label} exceeds ${expected.maxBytes} bytes`);
    if (expected.contentRequired === true) {
      const analysis = analyzePngContent(path);
      add(errors, hasPlausibleScreenshotContent(analysis), `${label} appears blank or placeholder-like`);
    }
    if (expected.maxOpaqueRadius) {
      const analysis = analyzePngContent(path);
      add(
        errors,
        analysis.maxOpaqueRadius <= expected.maxOpaqueRadius,
        `${label} artwork exceeds the ${expected.maxOpaqueRadius}px safe-zone radius`,
      );
    }
  } catch (error) {
    errors.push(`${label}: ${error.message}`);
  }
}

export function validatePngFile({ projectRoot, relativePath, expected, label }) {
  const errors = [];
  checkPng(errors, resolve(projectRoot), relativePath, expected, label);
  return errors;
}

function checkBoundFile(errors, root, evidence, expectedPath, label) {
  add(errors, isPlainObject(evidence), `${label} evidence must be an object`);
  if (!isPlainObject(evidence)) return;
  add(errors, evidence.path === expectedPath, `${label} evidence path must be ${expectedPath}`);
  add(errors, SHA256.test(evidence.sha256 ?? ''), `${label} SHA-256 must be a full lowercase digest`);
  const path = resolve(root, expectedPath);
  if (existsSync(path) && SHA256.test(evidence.sha256 ?? '')) {
    add(errors, fileSha256(path) === evidence.sha256, `${label} SHA-256 does not match ${expectedPath}`);
  }
}

function checkSourceBoundary(errors, root, metadata) {
  const source = metadata.sourceBaseline;
  add(errors, isPlainObject(source), 'sourceBaseline must be an evidence object');
  if (!isPlainObject(source)) return;
  add(errors, SHA40.test(source.commit ?? ''), 'sourceBaseline.commit must be a full Git SHA');
  add(errors, exactArray(source.trackedPaths, EXPECTED_TRACKED_PATHS), 'sourceBaseline.trackedPaths drifted');
  add(errors, exactArray(source.allowedDrift, EXPECTED_ALLOWED_DRIFT), 'sourceBaseline.allowedDrift drifted');
  if (!SHA40.test(source.commit ?? '')) return;
  add(errors, gitSucceeds(root, ['cat-file', '-e', `${source.commit}^{commit}`]), 'sourceBaseline.commit does not exist locally');
  add(errors, gitSucceeds(root, ['merge-base', '--is-ancestor', source.commit, 'HEAD']), 'sourceBaseline.commit is not an ancestor of HEAD');

  if (exactArray(source.trackedPaths, EXPECTED_TRACKED_PATHS)) {
    try {
      const changed = git(root, ['diff', '--name-only', source.commit, '--', ...EXPECTED_TRACKED_PATHS])
        .split('\n').filter(Boolean);
      const unexpected = changed.filter((path) => !EXPECTED_ALLOWED_DRIFT.includes(path));
      add(errors, unexpected.length === 0, `source baseline has unapproved product drift: ${unexpected.join(', ')}`);
      const status = git(root, ['status', '--porcelain', '--untracked-files=all', '--', ...EXPECTED_TRACKED_PATHS])
        .split('\n').filter(Boolean).map((line) => line.slice(3));
      const unexpectedWorktree = status.filter((path) => !EXPECTED_ALLOWED_DRIFT.includes(path));
      add(errors, unexpectedWorktree.length === 0, `source worktree has unapproved product changes: ${unexpectedWorktree.join(', ')}`);
    } catch (error) {
      errors.push(`source baseline comparison failed: ${error.message}`);
    }
  }

  const bindings = Array.isArray(source.boundFiles) ? source.boundFiles : [];
  add(errors, bindings.length === EXPECTED_ALLOWED_DRIFT.length, 'sourceBaseline.boundFiles must bind every allowed drift file');
  for (const expectedPath of EXPECTED_ALLOWED_DRIFT) {
    checkBoundFile(
      errors,
      root,
      bindings.find((binding) => binding?.path === expectedPath),
      expectedPath,
      `allowed source drift ${expectedPath}`,
    );
  }
}

function checkReleaseEvidence(errors, root, metadata) {
  const evidence = metadata.releaseEvidence;
  add(errors, isPlainObject(evidence), 'releaseEvidence must be an object');
  if (!isPlainObject(evidence)) return;
  const readiness = metadata.readiness ?? {};
  if (readiness.releaseCandidateMerged === true) {
    add(errors, SHA40.test(evidence.commit ?? ''), 'release candidate evidence requires a full Git SHA');
    if (SHA40.test(evidence.commit ?? '')) {
      add(errors, gitSucceeds(root, ['cat-file', '-e', `${evidence.commit}^{commit}`]), 'release candidate commit does not exist locally');
      add(errors, gitSucceeds(root, ['merge-base', '--is-ancestor', evidence.commit, 'HEAD']), 'release candidate commit is not an ancestor of HEAD');
    }
  } else {
    add(errors, evidence.commit === null, 'unmerged release candidate must not retain a commit claim');
  }
  for (const [gate, key, label] of [
    ['iosDistributionArchiveVerified', 'iosDistributionArchiveSha256', 'iOS distribution archive'],
    ['androidReleaseBundleVerified', 'androidReleaseBundleSha256', 'Android release bundle'],
  ]) {
    if (readiness[gate] === true) add(errors, SHA256.test(evidence[key] ?? ''), `${label} evidence requires a SHA-256`);
    else add(errors, evidence[key] === null, `${label} evidence must be null until verified`);
  }
}

function checkAssetEvidence(errors, root, metadata) {
  const evidence = metadata.assetEvidence;
  add(errors, isPlainObject(evidence), 'assetEvidence must be an object');
  if (!isPlainObject(evidence)) return;
  checkBoundFile(errors, root, evidence.appStoreIcon, 'assets/icon/ios_icon_1024.png', 'App Store icon');
  checkBoundFile(errors, root, evidence.googlePlayIcon, 'store/assets/google-play-icon.png', 'Google Play icon');
  checkBoundFile(errors, root, evidence.googleFeatureGraphic, 'store/assets/google-feature-graphic.png', 'Google feature graphic');
  checkBoundFile(
    errors,
    root,
    evidence.googlePlayIcon && {
      path: evidence.googlePlayIcon.sourcePath,
      sha256: evidence.googlePlayIcon.sourceSha256,
    },
    'assets/icon/ios_icon_1024.png',
    'Google Play icon source',
  );
  checkBoundFile(
    errors,
    root,
    evidence.googlePlayIcon && {
      path: evidence.googlePlayIcon.rendererPath,
      sha256: evidence.googlePlayIcon.rendererSha256,
    },
    'scripts/render-google-play-icon.swift',
    'Google Play icon renderer',
  );
  checkBoundFile(
    errors,
    root,
    evidence.googleFeatureGraphic && {
      path: evidence.googleFeatureGraphic.sourcePath,
      sha256: evidence.googleFeatureGraphic.sourceSha256,
    },
    'scripts/render-google-feature-graphic.swift',
    'Google feature graphic source',
  );
  const graphic = evidence.googleFeatureGraphic ?? {};
  checkBoundFile(
    errors,
    root,
    graphic && {
      path: graphic.previewPath,
      sha256: graphic.previewSha256,
    },
    'store/assets/google-feature-graphic.html',
    'Google feature graphic preview',
  );
  const inputs = Array.isArray(graphic.inputs) ? graphic.inputs : [];
  add(
    errors,
    inputs.length === EXPECTED_FEATURE_GRAPHIC_INPUTS.length,
    'Google feature graphic must bind every renderer input',
  );
  for (const expectedPath of EXPECTED_FEATURE_GRAPHIC_INPUTS) {
    checkBoundFile(
      errors,
      root,
      inputs.find((input) => input?.path === expectedPath),
      expectedPath,
      `Google feature graphic input ${expectedPath}`,
    );
  }

  const previewPath = resolve(root, 'store/assets/google-feature-graphic.html');
  if (existsSync(previewPath)) {
    const preview = readFileSync(previewPath, 'utf8');
    const images = preview.match(/<img\b/g) ?? [];
    add(errors, images.length === 1, 'Google feature graphic preview must contain exactly one image');
    add(
      errors,
      /<img\s+src="google-feature-graphic\.png"\s+width="1024"\s+height="500"\s+alt="[^"]+">/.test(preview),
      'Google feature graphic preview must display the canonical PNG at 1024 by 500',
    );
    add(
      errors,
      !/<(?:h1|h2|section|p)\b|@font-face|--(?:gold|paper|coral)\b/.test(preview),
      'Google feature graphic preview must not rebuild the composition',
    );
  }
  add(
    errors,
    graphic.ownerApproved === metadata.readiness?.googleFeatureGraphicFinal,
    'feature graphic approval evidence must match readiness.googleFeatureGraphicFinal',
  );
  if (graphic.ownerApproved === true) {
    add(errors, /^\d{4}-\d{2}-\d{2}$/.test(graphic.approvedOn ?? ''), 'approved feature graphic requires an approval date');
    add(errors, SHA256.test(graphic.approvedSha256 ?? ''), 'approved feature graphic requires an approved SHA-256');
    add(errors, SHA256.test(graphic.approvedSourceSha256 ?? ''), 'approved feature graphic requires an approved source SHA-256');
    add(errors, graphic.approvedSha256 === graphic.sha256, 'approved feature graphic SHA-256 must match the current asset SHA-256');
    add(errors, graphic.approvedSourceSha256 === graphic.sourceSha256, 'approved feature graphic source SHA-256 must match the current source SHA-256');
  } else {
    add(errors, graphic.approvedOn === null, 'unapproved feature graphic must not retain an approval date');
    add(errors, graphic.approvedSha256 === null, 'unapproved feature graphic must not retain an approved SHA-256');
    add(errors, graphic.approvedSourceSha256 === null, 'unapproved feature graphic must not retain an approved source SHA-256');
  }
}

function checkScreenshotEvidence(errors, root, metadata, screenshots) {
  add(errors, screenshots.schemaVersion === 2, 'screenshot schemaVersion must be 2');
  add(errors, screenshots.captureSource === 'exact submitted release candidate', 'screenshot source contract drifted');
  add(
    errors,
    screenshots.releaseEvidenceSource === 'store/submission.json#releaseEvidence',
    'screenshot release-evidence link drifted',
  );
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
      const expectedPath = `store/screenshots/${platform}/${scene.id}.png`;
      const expectedSourcePath = `store/screenshots/source/${platform}/${scene.id}.png`;
      const status = scene[`${platform}Status`];
      const outputHash = scene[`${platform}Sha256`];
      const sourceHash = scene[`${platform}SourceSha256`];
      add(errors, scene[`${platform}Path`] === expectedPath, `${scene.id} ${platform} path must be ${expectedPath}`);
      add(errors, scene[`${platform}SourcePath`] === expectedSourcePath, `${scene.id} ${platform} source path must be ${expectedSourcePath}`);
      add(errors, ['pending_capture', 'captured'].includes(status), `${scene.id} ${platform} status is invalid`);
      allPaths.push(scene[`${platform}Path`], scene[`${platform}SourcePath`]);
      if (status === 'captured') {
        const target = platform === 'ios' ? iosTarget : androidTarget;
        add(errors, SHA256.test(outputHash ?? ''), `${scene.id} ${platform} output requires a SHA-256`);
        add(errors, SHA256.test(sourceHash ?? ''), `${scene.id} ${platform} source requires a SHA-256`);
        checkPng(errors, root, expectedPath, { ...target, contentRequired: true }, `${scene.id} ${platform} screenshot`);
        checkPng(errors, root, expectedSourcePath, { ...target, contentRequired: true }, `${scene.id} ${platform} source capture`);
        if (existsSync(resolve(root, expectedPath)) && SHA256.test(outputHash ?? '')) {
          add(errors, fileSha256(resolve(root, expectedPath)) === outputHash, `${scene.id} ${platform} output SHA-256 does not match`);
        }
        if (existsSync(resolve(root, expectedSourcePath)) && SHA256.test(sourceHash ?? '')) {
          add(errors, fileSha256(resolve(root, expectedSourcePath)) === sourceHash, `${scene.id} ${platform} source SHA-256 does not match`);
        }
        add(errors, outputHash !== sourceHash, `${scene.id} ${platform} framed output must differ from its source capture`);
        add(errors, SHA40.test(metadata.releaseEvidence?.commit ?? ''), `${scene.id} ${platform} requires release commit evidence`);
        const archiveGate = platform === 'ios' ? 'iosDistributionArchiveVerified' : 'androidReleaseBundleVerified';
        add(errors, metadata.readiness?.[archiveGate] === true, `${scene.id} ${platform} requires verified release artifact evidence`);
      } else {
        add(errors, outputHash === null, `${scene.id} ${platform} pending output SHA-256 must be null`);
        add(errors, sourceHash === null, `${scene.id} ${platform} pending source SHA-256 must be null`);
        add(errors, !existsSync(resolve(root, expectedPath)), `${scene.id} ${platform} pending output file must be absent`);
        add(errors, !existsSync(resolve(root, expectedSourcePath)), `${scene.id} ${platform} pending source file must be absent`);
        if (platform === 'ios') allIosCaptured = false;
        else allAndroidCaptured = false;
      }
    }
  }
  add(errors, new Set(allPaths).size === allPaths.length, 'screenshot source and output paths must be unique');
  add(errors, metadata.readiness?.iosScreenshotsCaptured === allIosCaptured, 'iOS screenshot readiness must match all five manifest statuses');
  add(errors, metadata.readiness?.androidScreenshotsCaptured === allAndroidCaptured, 'Android screenshot readiness must match all five manifest statuses');
}

export function validateStorePacket({ projectRoot, submission, manifest } = {}) {
  const root = resolve(projectRoot ?? fileURLToPath(new URL('..', import.meta.url)));
  const metadata = submission ?? JSON.parse(readFileSync(resolve(root, 'store/submission.json'), 'utf8'));
  const screenshots = manifest ?? JSON.parse(readFileSync(resolve(root, 'store/screenshots/manifest.json'), 'utf8'));
  const errors = [];

  add(errors, metadata.schemaVersion === 3, 'submission schemaVersion must be 3');
  add(errors, ['prepared_not_submitted', 'ready_for_submission', 'submitted'].includes(metadata.status), 'submission status is invalid');
  checkSourceBoundary(errors, root, metadata);

  const identity = metadata.identity ?? {};
  add(errors, identity.productName === 'Chants FC', 'productName must remain Chants FC');
  add(errors, identity.installedDisplayName === 'Chants', 'installedDisplayName must remain Chants');
  add(errors, identity.operator === 'ThunderRiver Tech LLC', 'operator identity drifted');
  add(errors, identity.googleDeveloperName === 'ThunderRiverTech', 'Google developer name drifted');
  add(errors, identity.supportEmail === 'support@chantsfc.com', 'support email drifted');
  add(errors, identity.iosBundleId === 'com.chants.chants', 'iOS bundle ID drifted');
  add(errors, identity.androidPackageName === 'com.chants.chants', 'Android package name drifted');
  add(errors, exactArray(identity.appleSupportedDevices, ['iPhone']), 'Apple V1 supported devices must be iPhone only');
  add(errors, identity.versionName === '1.0.0', 'versionName must be 1.0.0');
  add(errors, identity.versionCode === 1, 'versionCode must be 1');
  add(errors, identity.accountMinimumAge === '17+', 'account minimum age drifted');
  add(
    errors,
    identity.storeRatingStatus === 'Answer each store questionnaire from the exact release behavior. This packet does not change or pre-decide a store rating.',
    'store rating evidence boundary drifted',
  );
  const markets = new Set(identity.releaseMarkets ?? []);
  add(errors, markets.size === EXPECTED_MARKETS.size && [...EXPECTED_MARKETS].every((market) => markets.has(market)), 'release markets must be exactly United States, United Kingdom, and Canada');

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
  add(errors, apple.locale === 'en-US', 'Apple locale must be en-US');
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
  add(errors, google.locale === 'en-US', 'Google locale must be en-US');
  textLength(errors, google.title, 30, 'Google title');
  textLength(errors, google.shortDescription, 80, 'Google short description');
  textLength(errors, google.fullDescription, 4000, 'Google full description');
  textLength(errors, google.appAccessInstructions, 4000, 'Google app access instructions');
  add(errors, google.category === 'Sports', 'Google category must be Sports');
  add(
    errors,
    JSON.stringify(google.tags) === JSON.stringify(['Lyrics', 'Social', 'Sports']),
    'Google discovery tags must remain Lyrics, Social, and Sports',
  );
  add(
    errors,
    google.contactEmail === 'play@thunderrivertech.com',
    'Google public contact email drifted',
  );
  add(errors, google.website === 'https://chantsfc.com', 'Google website drifted');
  add(errors, google.featureGraphicPath === 'store/assets/google-feature-graphic.png', 'Google feature graphic path drifted');

  add(errors, isPlainObject(metadata.readiness), 'readiness must be an object');
  for (const key of [...REQUIRED_READINESS, 'submitted']) {
    add(errors, typeof metadata.readiness?.[key] === 'boolean', `readiness.${key} must be boolean`);
  }
  if (metadata.status === 'prepared_not_submitted') {
    add(errors, metadata.readiness?.submitted === false, 'prepared packet cannot claim submitted');
  }
  if (metadata.status === 'ready_for_submission' || metadata.status === 'submitted') {
    for (const key of REQUIRED_READINESS) {
      add(errors, metadata.readiness?.[key] === true, `${metadata.status === 'submitted' ? 'submitted' : 'ready'} packet requires readiness.${key}`);
    }
  }
  if (metadata.status === 'ready_for_submission') add(errors, metadata.readiness?.submitted === false, 'ready packet cannot already claim submitted');
  if (metadata.status === 'submitted') add(errors, metadata.readiness?.submitted === true, 'submitted status requires submitted evidence');

  checkReleaseEvidence(errors, root, metadata);
  checkAssetEvidence(errors, root, metadata);
  checkScreenshotEvidence(errors, root, metadata, screenshots);

  checkPng(errors, root, 'assets/icon/ios_icon_1024.png', { width: 1024, height: 1024, alphaAllowed: false }, 'App Store icon source');
  checkPng(
    errors,
    root,
    'store/assets/google-play-icon.png',
    { width: 512, height: 512, alphaRequired: true, maxBytes: 1024 * 1024, maxOpaqueRadius: 192 },
    'Google Play icon',
  );
  checkPng(
    errors,
    root,
    'store/assets/google-feature-graphic.png',
    { width: 1024, height: 500, alphaAllowed: false, maxBytes: 15 * 1024 * 1024 },
    'Google feature graphic',
  );

  const project = readFileSync(resolve(root, 'ios/Runner.xcodeproj/project.pbxproj'), 'utf8');
  const plist = readFileSync(resolve(root, 'ios/Runner/Info.plist'), 'utf8');
  add(errors, (project.match(/TARGETED_DEVICE_FAMILY = 1;/g) ?? []).length === 3, 'all V1 iOS build configurations must target iPhone only');
  add(errors, !project.includes('TARGETED_DEVICE_FAMILY = "1,2";'), 'V1 native project still includes iPad');
  add(errors, !plist.includes('UISupportedInterfaceOrientations~ipad'), 'V1 Info.plist still includes iPad orientation metadata');

  return errors;
}

const scriptPath = fileURLToPath(import.meta.url);
if (process.argv[1] && resolve(process.argv[1]) === scriptPath) {
  const projectRoot = process.argv[2] ? resolve(process.argv[2]) : resolve(dirname(scriptPath), '..');
  const errors = validateStorePacket({ projectRoot });
  if (errors.length > 0) {
    console.error('Store submission packet failed validation:');
    for (const error of errors) console.error(`- ${error}`);
    process.exitCode = 1;
  } else {
    console.log('Store submission packet passes in prepared, not-submitted state.');
  }
}
