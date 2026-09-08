#!/usr/bin/env node

import { createHash } from 'node:crypto';
import { readFile, mkdir, rename, rm, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptDirectory, '..');
const defaultOutputDirectory = join(
  repositoryRoot,
  'assets',
  'clubs',
  'crests',
);

export const expectedClubs = [
  { slug: 'arsenal', providerTeamId: 42, names: ['Arsenal'] },
  { slug: 'aston-villa', providerTeamId: 66, names: ['Aston Villa'] },
  { slug: 'bournemouth', providerTeamId: 35, names: ['Bournemouth'] },
  { slug: 'brentford', providerTeamId: 55, names: ['Brentford'] },
  { slug: 'brighton-hove-albion', providerTeamId: 51, names: ['Brighton'] },
  { slug: 'chelsea', providerTeamId: 49, names: ['Chelsea'] },
  { slug: 'coventry-city', providerTeamId: 1346, names: ['Coventry'] },
  { slug: 'crystal-palace', providerTeamId: 52, names: ['Crystal Palace'] },
  { slug: 'everton', providerTeamId: 45, names: ['Everton'] },
  { slug: 'fulham', providerTeamId: 36, names: ['Fulham'] },
  { slug: 'hull-city', providerTeamId: 64, names: ['Hull City'] },
  { slug: 'ipswich-town', providerTeamId: 57, names: ['Ipswich'] },
  { slug: 'leeds-united', providerTeamId: 63, names: ['Leeds'] },
  { slug: 'liverpool', providerTeamId: 40, names: ['Liverpool'] },
  { slug: 'manchester-city', providerTeamId: 50, names: ['Manchester City'] },
  { slug: 'manchester-united', providerTeamId: 33, names: ['Manchester United'] },
  { slug: 'newcastle-united', providerTeamId: 34, names: ['Newcastle'] },
  { slug: 'nottingham-forest', providerTeamId: 65, names: ['Nottingham Forest'] },
  { slug: 'sunderland', providerTeamId: 746, names: ['Sunderland'] },
  { slug: 'tottenham-hotspur', providerTeamId: 47, names: ['Tottenham'] },
];

function normalized(value) {
  return value.trim().toLocaleLowerCase('en-GB');
}

export function keyFromPrivateFile(raw) {
  const trimmed = raw.trim();
  if (trimmed.startsWith('{')) {
    const parsed = JSON.parse(trimmed);
    for (const field of ['API_FOOTBALL_KEY', 'apiFootballKey', 'apiKey', 'key']) {
      if (typeof parsed[field] === 'string' && parsed[field].trim()) {
        return parsed[field].trim();
      }
    }
    throw new Error('The JSON key file has no supported API-Football key field.');
  }

  const assignment = trimmed
    .split(/\r?\n/u)
    .map((line) => line.trim())
    .find((line) => /^(API_FOOTBALL_KEY|API_SPORTS_KEY)=/u.test(line));
  if (assignment) {
    return assignment.slice(assignment.indexOf('=') + 1).trim();
  }
  if (trimmed && !/[\r\n]/u.test(trimmed)) return trimmed;
  throw new Error('The private key file format is not recognized.');
}

export function mapExpectedTeams(providerRows) {
  const providerTeams = providerRows.map((row) => row?.team).filter(Boolean);
  return expectedClubs.map((expected) => {
    const accepted = new Set(expected.names.map(normalized));
    const matches = providerTeams.filter(
      (team) => typeof team.name === 'string' && accepted.has(normalized(team.name)),
    );
    if (matches.length !== 1) {
      throw new Error(
        `${expected.slug} matched ${matches.length} provider teams, expected exactly one.`,
      );
    }
    const [team] = matches;
    if (!Number.isInteger(team.id) || team.id <= 0) {
      throw new Error(`${expected.slug} has an invalid provider team ID.`);
    }
    if (team.id !== expected.providerTeamId) {
      throw new Error(
        `${expected.slug} returned provider team ID ${team.id}, expected ${expected.providerTeamId}.`,
      );
    }
    const logo = new URL(team.logo);
    if (logo.protocol !== 'https:' || logo.hostname !== 'media.api-sports.io') {
      throw new Error(`${expected.slug} has an unexpected crest host.`);
    }
    return {
      slug: expected.slug,
      providerTeamId: expected.providerTeamId,
      providerName: team.name,
      logo: logo.toString(),
    };
  });
}

export function inspectPng(bytes, slug) {
  const pngSignature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (bytes.length < 24 || !bytes.subarray(0, 8).equals(pngSignature)) {
    throw new Error(`${slug} did not return a valid PNG.`);
  }
  if (bytes.length > 1024 * 1024) {
    throw new Error(`${slug} crest exceeds the 1 MiB V1 asset limit.`);
  }
  const width = bytes.readUInt32BE(16);
  const height = bytes.readUInt32BE(20);
  if (width < 16 || height < 16 || width > 1024 || height > 1024) {
    throw new Error(`${slug} has unsafe PNG dimensions ${width}x${height}.`);
  }
  return { width, height };
}

function argumentValue(name) {
  const prefix = `--${name}=`;
  const match = process.argv.find((argument) => argument.startsWith(prefix));
  return match?.slice(prefix.length);
}

async function fetchCrests() {
  const keyFile = argumentValue('key-file');
  if (!keyFile) {
    throw new Error(
      'Usage: node scripts/fetch-api-football-crests.mjs --key-file=/private/path [--season=2026]',
    );
  }
  const season = argumentValue('season') ?? '2026';
  if (!/^20\d{2}$/u.test(season)) throw new Error('Season must be YYYY.');

  const apiKey = keyFromPrivateFile(await readFile(resolve(keyFile), 'utf8'));
  const endpoint = new URL('https://v3.football.api-sports.io/teams');
  endpoint.searchParams.set('league', '39');
  endpoint.searchParams.set('season', season);

  const response = await fetch(endpoint, {
    headers: { 'x-apisports-key': apiKey },
    signal: AbortSignal.timeout(20_000),
  });
  if (!response.ok) {
    throw new Error(`API-Football team request failed with HTTP ${response.status}.`);
  }
  const payload = await response.json();
  if (!Array.isArray(payload.response)) {
    throw new Error('API-Football returned no team list.');
  }
  const mappedTeams = mapExpectedTeams(payload.response);

  const retrievedAt = new Date().toISOString();
  const assets = [];
  for (const team of mappedTeams) {
    const logoResponse = await fetch(team.logo, {
      signal: AbortSignal.timeout(20_000),
    });
    if (!logoResponse.ok) {
      throw new Error(`${team.slug} crest failed with HTTP ${logoResponse.status}.`);
    }
    const bytes = Buffer.from(await logoResponse.arrayBuffer());
    const dimensions = inspectPng(bytes, team.slug);
    assets.push({
      ...team,
      ...dimensions,
      bytes,
      sha256: createHash('sha256').update(bytes).digest('hex'),
    });
  }

  const outputDirectory = defaultOutputDirectory;
  const stagingDirectory = join(outputDirectory, `.incoming-${process.pid}`);
  await mkdir(stagingDirectory, { recursive: true });
  try {
    for (const asset of assets) {
      await writeFile(join(stagingDirectory, `${asset.slug}.png`), asset.bytes, {
        mode: 0o644,
      });
    }
    const provenance = {
      schemaVersion: 1,
      provider: 'API-Football',
      providerTerms: 'https://www.api-football.com/terms',
      competition: { providerLeagueId: 39, season },
      usage: 'In-app club identification only',
      rightsNote:
        'Provider delivery is not trademark clearance and does not imply club affiliation.',
      retrievedAt,
      assets: assets.map(({ bytes, logo, ...asset }) => ({
        ...asset,
        sourceUrl: logo,
        localFile: `assets/clubs/crests/${asset.slug}.png`,
        reviewStatus: 'provider_identity_matched_pending_owner_visual_review',
      })),
    };
    await writeFile(
      join(stagingDirectory, 'provenance.json'),
      `${JSON.stringify(provenance, null, 2)}\n`,
      { mode: 0o644 },
    );

    for (const asset of assets) {
      await rename(
        join(stagingDirectory, `${asset.slug}.png`),
        join(outputDirectory, `${asset.slug}.png`),
      );
    }
    await rename(
      join(stagingDirectory, 'provenance.json'),
      join(outputDirectory, 'provenance.json'),
    );
  } finally {
    await rm(stagingDirectory, { recursive: true, force: true });
  }

  for (const asset of assets) {
    console.log(
      `${asset.slug}: provider team ${asset.providerTeamId}, ${asset.width}x${asset.height}, sha256 ${asset.sha256}`,
    );
  }
  console.log(`Wrote ${assets.length} reviewed candidates for owner visual review.`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  fetchCrests().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
