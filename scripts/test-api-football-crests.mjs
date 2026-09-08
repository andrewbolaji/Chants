import { strict as assert } from 'node:assert';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import {
  expectedClubs,
  inspectPng,
  keyFromPrivateFile,
  mapExpectedTeams,
} from './fetch-api-football-crests.mjs';

const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function pngHeader(width = 128, height = 128) {
  const bytes = Buffer.alloc(24);
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]).copy(bytes);
  bytes.writeUInt32BE(width, 16);
  bytes.writeUInt32BE(height, 20);
  return bytes;
}

test('crest inventory contains twenty unique stable club slugs', () => {
  assert.equal(expectedClubs.length, 20);
  assert.equal(new Set(expectedClubs.map((club) => club.slug)).size, 20);
});

test('private key parser supports plain, environment, and JSON files', () => {
  assert.equal(keyFromPrivateFile('secret-value\n'), 'secret-value');
  assert.equal(
    keyFromPrivateFile('API_FOOTBALL_KEY=secret-value\n'),
    'secret-value',
  );
  assert.equal(
    keyFromPrivateFile('{"apiFootballKey":"secret-value"}'),
    'secret-value',
  );
});

test('team mapping fails closed for a missing or ambiguous club', () => {
  const rows = expectedClubs.map((club, index) => ({
    team: {
      id: club.providerTeamId,
      name: club.names[0],
      logo: `https://media.api-sports.io/football/teams/${index + 1}.png`,
    },
  }));
  assert.equal(mapExpectedTeams(rows).length, 20);
  assert.throws(() => mapExpectedTeams(rows.slice(1)), /arsenal matched 0/u);
  assert.throws(
    () => mapExpectedTeams([...rows, rows[0]]),
    /arsenal matched 2/u,
  );
  assert.throws(
    () =>
      mapExpectedTeams([
        { ...rows[0], team: { ...rows[0].team, id: 999999 } },
        ...rows.slice(1),
      ]),
    /arsenal returned provider team ID 999999/u,
  );
});

test('team mapping rejects an unexpected crest host', () => {
  const rows = expectedClubs.map((club, index) => ({
    team: {
      id: club.providerTeamId,
      name: club.names[0],
      logo:
        index === 0
          ? 'https://example.com/arsenal.png'
          : `https://media.api-sports.io/football/teams/${index + 1}.png`,
    },
  }));
  assert.throws(() => mapExpectedTeams(rows), /unexpected crest host/u);
});

test('PNG inspection rejects malformed and unsafe artwork', () => {
  assert.deepEqual(inspectPng(pngHeader(), 'arsenal'), {
    width: 128,
    height: 128,
  });
  assert.throws(() => inspectPng(Buffer.from('not-png'), 'arsenal'), /valid PNG/u);
  assert.throws(() => inspectPng(pngHeader(2048, 128), 'arsenal'), /unsafe PNG/u);
});

test('cached crest inventory matches its credential-free provenance', async () => {
  const provenancePath = resolve(
    repositoryRoot,
    'assets/clubs/crests/provenance.json',
  );
  const provenance = JSON.parse(await readFile(provenancePath, 'utf8'));
  assert.equal(provenance.provider, 'API-Football');
  assert.equal(provenance.assets.length, 20);
  assert.deepEqual(
    provenance.assets.map((asset) => asset.slug),
    expectedClubs.map((club) => club.slug),
  );
  assert.deepEqual(
    provenance.assets.map((asset) => asset.providerTeamId),
    expectedClubs.map((club) => club.providerTeamId),
  );

  for (const asset of provenance.assets) {
    const bytes = await readFile(resolve(repositoryRoot, asset.localFile));
    const dimensions = inspectPng(bytes, asset.slug);
    assert.deepEqual(dimensions, {
      width: asset.width,
      height: asset.height,
    });
    assert.equal(
      createHash('sha256').update(bytes).digest('hex'),
      asset.sha256,
    );
    assert.equal(
      new URL(asset.sourceUrl).hostname,
      'media.api-sports.io',
    );
  }
});
