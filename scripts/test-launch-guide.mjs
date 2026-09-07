import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import vm from 'node:vm';
const require = createRequire(import.meta.url);
const guide = require('../docs/launch-command-center.js');
const html = readFileSync(new URL('../docs/CHANTS_LAUNCH_COMMAND_CENTER.html', import.meta.url), 'utf8');
const context = { source: 'fixture-source', backend: 'fixture-backend', ios: 'fixture-ios', android: 'fixture-android' };

test('HTML has unique IDs, valid local anchors/copy targets and labeled static fields', () => {
  const ids = [...html.matchAll(/\sid="([^"]+)"/g)].map(match => match[1]);
  assert.equal(new Set(ids).size, ids.length);
  for (const match of html.matchAll(/(?:href="#|data-copy-target="|for=")([^"]+)"/g)) assert.ok(ids.includes(match[1]), `Missing target ${match[1]}`);
  for (const id of ['session-source', 'session-backend', 'session-ios', 'session-android', 'walk-report']) assert.ok(html.includes(`for="${id}"`));
  assert.match(html, /<script src="launch-command-center.js"><\/script>/);
});

test('guide excludes stale seed, broad deployment and config-overwrite recipes', () => {
  assert.match(html, /20 clubs, 622 players and 192 chants/);
  assert.doesNotMatch(html, /Arsenal is the only club|Keep verifying the remaining|firebase deploy.*--only functions|ef7195cf5159c45/);
  assert.doesNotMatch(html, /cp\s+lib\/firebase_options\.dart\.example\s+lib\/firebase_options\.dart/);
  assert.match(html, /PR 32 merged/);
  assert.match(html, /88ce483/);
  assert.match(html, /33562025155/);
  assert.match(html, /Production closed, client check passed/);
  assert.match(html, /Updated 2 September 2026/);
  assert.match(html, /Corrected iPhone client proven/);
  assert.doesNotMatch(html, />approved V1 Lane 3 Gate 3 owner walkthrough retry</);
  assert.doesNotMatch(html, />approved V1 Lane 3 Gate 3 immediate owner walkthrough retry</);
  assert.doesNotMatch(html, />approved V1 Lane 3 Gate 3 30-second countdown owner walkthrough retry</);
  assert.match(html, /does not reopen production/);
  assert.match(html, /maintenance generation 9/);
  assert.match(html, /All four core windows had zero backend requests/);
  assert.match(html, /null-task-runner failure/);
  assert.match(html, /Repeated cold launch, force quit, background, and resume checks/);
  assert.match(html, /owner-observed device check/);
  assert.match(html, /visible saving feedback, truthful maintenance result, and no crash/);
  assert.match(html, /functional smoke is incomplete/);
  assert.match(html, /Gate 4 is not next/);
  assert.match(html, /all eight jobs successfully/);
  assert.match(html, /Android Play Integrity configurations exist/);
  assert.match(html, /dedicated runtime account remains keyless/);
  assert.match(html, /all 16 composite indexes are ready/);
  assert.match(html, /46 non-scheduled/);
  assert.match(html, /196 complete repair checkpoints/);
  assert.match(html, /no scheduled Function or Scheduler job exists/);
  assert.match(html, /missed events/);
  assert.match(html, /ROADMAP.md#automated-media-cleanup-monitoring/);
  assert.doesNotMatch(html, /combined Claude review still needs|Source merged; review pending/);
  assert.match(html, /explicit destructive-test approval/);
  for (const id of ['walk-core', 'walk-songbook', 'walk-creator', 'walk-social-safety', 'walk-deletion', 'walk-polish', 'walk-updates']) assert.match(html, new RegExp(`id="${id}"`));
});

test('unavailable or malformed storage returns truthful defaults and never deletes data', () => {
  const blocked = { getItem: () => { throw new Error('blocked'); }, setItem: () => { throw new Error('blocked'); } };
  const result = guide.loadState(blocked);
  assert.equal(result.readable, false); assert.equal(guide.saveState(blocked, result.state), false);
  assert.equal(guide.loadState({ getItem: () => '{bad' }).readable, false);
  assert.deepEqual(guide.loadState({ getItem: () => 'null' }).state.checks, {});
});

test('v4 state roundtrips without touching legacy state', () => {
  const keys = [];
  let stored;
  const storage = { setItem: (key, value) => { keys.push(key); stored = value; }, getItem: key => { keys.push(key); return stored; } };
  const state = guide.loadState({ getItem: () => null }).state;
  state.context = context; state.checks['prep-local'] = true;
  assert.equal(guide.saveState(storage, state), true);
  assert.deepEqual(guide.loadState(storage).state, state);
  assert.deepEqual(keys, ['chants-launch-command-center-v4', 'chants-launch-command-center-v4']);
  const legacy = JSON.stringify({ checks: { 'walk-core': true }, context });
  const isolated = guide.loadState({ getItem: key => key.endsWith('-v3') ? legacy : null });
  assert.deepEqual(isolated.state.checks, {});
});

test('a pass needs source, backend and its platform build; blocked can be recorded now', () => {
  for (const key of ['source', 'backend', 'ios']) assert.throws(() => guide.recordObservation('Passed', '', { ...context, [key]: '' }, 'ios'));
  assert.equal(guide.recordObservation('Blocked', 'No approved backend', {}, 'ios').result, 'Blocked');
  assert.throws(() => guide.recordObservation('Looks good', '', context, 'ios'));
});

test('changed source/backend/platform makes prior results stale, but not the other platform alone', () => {
  const observation = guide.recordObservation('Passed', 'Observed in fixture', context, 'ios');
  assert.equal(guide.observedStatus(observation, context, 'ios'), 'Passed');
  for (const key of ['source', 'backend', 'ios']) assert.match(guide.observedStatus(observation, { ...context, [key]: 'changed' }, 'ios'), /Stale/);
  assert.equal(guide.observedStatus(observation, { ...context, android: 'changed' }, 'ios'), 'Passed');
  assert.match(guide.observedStatus({ ...observation, note: 'Edited notes' }, { ...context, source: 'new' }, 'ios'), /Stale/);
});

test('report preserves notes as text, marks missing/stale results, and excludes unrelated saved fields', () => {
  const state = guide.loadState({ getItem: () => null }).state;
  state.context = context;
  state.notes['unrelated-private-field'] = 'DO-NOT-EXPORT';
  state.observations['walk-core:ios'] = guide.recordObservation('Failed', '<script>fixture</script>', context, 'ios');
  let report = guide.buildReport(state, [{ id: 'walk-core', title: 'Core' }]);
  assert.match(report, /ios: Failed/); assert.match(report, /android: Not run/); assert.match(report, /<script>fixture/);
  assert.doesNotMatch(report, /DO-NOT-EXPORT/);
  state.context = { ...context, source: 'new' };
  report = guide.buildReport(state, [{ id: 'walk-core', title: 'Core' }]); assert.match(report, /Stale/);
});

test('copy success and failure are truthful across both clipboard paths', async () => {
  assert.equal(await guide.copyText('fixture', { secure: true, clipboard: { writeText: async value => assert.equal(value, 'fixture') }, fallback: () => assert.fail() }), true);
  assert.equal(await guide.copyText('fixture', { secure: true, clipboard: { writeText: async () => { throw Error(); } }, fallback: () => true }), true);
  assert.equal(await guide.copyText('fixture', { secure: false, fallback: () => false }), false);
  assert.equal(await guide.copyText('fixture', { secure: false, fallback: () => { throw Error(); } }), false);
});

// Minimal DOM fixture exercises the shipped script wiring, not a second implementation.
test('real guide script wires record, stale context, copy failure and storage refusal', async () => {
  class Element {
    constructor(id = '') { this.id = id; this.value = ''; this.textContent = ''; this.checked = false; this.children = []; this.events = {}; this.attrs = {}; this.classList = { toggle() {}, contains: () => false }; }
    appendChild(child) { this.children.push(child); return child; }
    append(...children) { this.children.push(...children); }
    addEventListener(name, callback) { this.events[name] = callback; }
    setAttribute(name, value) { this.attrs[name] = value; }
    getAttribute(name) { return this.attrs[name]; }
    removeAttribute(name) { delete this.attrs[name]; }
    closest() { return this.filteredAncestor || null; }
  }
  const ids = Object.fromEntries(['persistenceStatus', 'filterIncomplete', 'walk-report', 'progressText', 'progressBar', 'expandAll', 'collapseAll', 'resetChecks'].map(id => [id, new Element(id)]));
  ids.progressBar.style = {};
  const box = new Element('walk-core');
  const body = new Element(); const title = new Element(); title.textContent = 'Core';
  const card = new Element(); card.querySelector = selector => ({ '[data-check]': box, '.task-title': title, '.task-body': body })[selector];
  const fields = ['source', 'backend', 'ios', 'android'].map(key => new Element(`session-${key}`));
  const copy = new Element(); copy.attrs['data-copy-target'] = 'walk-report';
  const nestedDetail = new Element();
  const filteredDetail = new Element(); filteredDetail.filteredAncestor = card;
  const document = {
    querySelectorAll: selector => ({ '[data-check]': [box], '[data-note]': [], '[data-task]': [card], details: [nestedDetail, filteredDetail, ...body.children], '[data-context]': fields, '#walk [data-task]': [card], '[data-copy-target]': [copy], 'a[href^="#"]': [] })[selector] || [],
    getElementById: id => ids[id], createElement: () => new Element(),
  };
  const window = { localStorage: { getItem: () => { throw Error(); }, setItem: () => { throw Error(); } }, isSecureContext: true, setTimeout() {}, confirm: () => true };
  vm.runInNewContext(readFileSync(new URL('../docs/launch-command-center.js', import.meta.url), 'utf8'), { document, window, navigator: { clipboard: { writeText: async () => { throw Error(); } } } });
  assert.match(ids.persistenceStatus.textContent, /unavailable/);
  fields.forEach(field => { field.value = context[field.id.replace('session-', '')]; field.events.input(); });
  const disclosure = body.children[0];
  assert.equal(disclosure.className, 'observations');
  assert.equal(disclosure.children[0].textContent, 'Record iPhone / Android result');
  ids.expandAll.events.click();
  assert.equal(disclosure.open, true);
  assert.equal(nestedDetail.open, true);
  assert.notEqual(filteredDetail.open, true);
  ids.collapseAll.events.click();
  assert.equal(disclosure.open, false);
  assert.equal(nestedDetail.open, false);
  const group = disclosure.children[1];
  const iosSelect = group.children.find(child => child.id === 'walk-core-ios-result');
  const record = group.children.find(child => child.attrs['aria-label'] === 'Record ios result for Core');
  iosSelect.value = 'Passed'; record.events.click(); assert.match(ids['walk-report'].value, /ios: Passed/);
  fields[0].value = 'new-source'; fields[0].events.input(); assert.match(ids['walk-report'].value, /Stale/);
  record.events.click(); assert.match(ids['walk-report'].value, /ios: Passed/);
  await copy.events.click(); assert.equal(copy.textContent, 'Select text to copy');
  ids.resetChecks.events.click();
  assert.match(ids['walk-report'].value, /ios: Not run/);
  assert.match(ids.persistenceStatus.textContent, /unavailable/);
});
