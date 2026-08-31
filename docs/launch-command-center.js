(function () {
  'use strict';
  const storageKey = 'chants-launch-command-center-v3';
  const results = ['Not run', 'Passed', 'Failed', 'Blocked'];
  const contextKeys = ['source', 'backend', 'ios', 'android'];
  const text = value => typeof value === 'string' ? value.slice(0, 4000) : '';
  const object = value => value && typeof value === 'object' && !Array.isArray(value) ? value : {};
  const fresh = () => ({ checks: {}, notes: {}, context: {}, observations: {}, hideComplete: false });

  function loadState(storage) {
    try {
      const parsed = object(JSON.parse(storage.getItem(storageKey) || '{}'));
      return { state: { checks: object(parsed.checks), notes: object(parsed.notes), context: object(parsed.context), observations: object(parsed.observations), hideComplete: parsed.hideComplete === true }, readable: true };
    } catch { return { state: fresh(), readable: false }; }
  }
  function saveState(storage, state) {
    try { storage.setItem(storageKey, JSON.stringify(state)); return true; }
    catch { return false; }
  }
  function stamp(context, platform) {
    return JSON.stringify([text(context.source), text(context.backend), text(context[platform])]);
  }
  function recordObservation(result, note, context, platform) {
    if (!results.includes(result)) throw new Error('Unsupported result');
    if (['Passed', 'Failed'].includes(result) && ['source', 'backend', platform].some(key => !text(context[key]).trim())) {
      throw new Error('Fill source, backend record and this platform build above before recording a pass or failure. Use Blocked while a gate is closed.');
    }
    return { result, note: text(note), context: stamp(context, platform) };
  }
  function observedStatus(observation, context, platform) {
    if (!observation || !results.includes(observation.result) || observation.result === 'Not run') return 'Not run';
    return observation.context === stamp(context, platform) ? observation.result : 'Stale: candidate changed';
  }
  function buildReport(state, journeys) {
    const lines = ['Chants walkthrough observations (self-recorded, not release approval)',
      ...contextKeys.map(key => `${key}: ${text(state.context[key]) || 'Not recorded'}`),
      'Use roles only. No credentials, emails, device IDs or raw logs.', ''];
    for (const journey of journeys) {
      lines.push(`${journey.id}: ${journey.title}`);
      for (const platform of ['ios', 'android']) {
        const observation = state.observations[`${journey.id}:${platform}`];
        lines.push(`  ${platform}: ${observedStatus(observation, state.context, platform)}`);
        if (observation && text(observation.note)) lines.push(`  Notes: ${text(observation.note)}`);
      }
      lines.push('');
    }
    return lines.join('\n');
  }
  async function copyText(value, { clipboard, secure, fallback }) {
    if (secure && clipboard) {
      try { await clipboard.writeText(value); return true; } catch { /* Try local selection. */ }
    }
    try { return fallback(value) === true; } catch { return false; }
  }
  if (typeof module !== 'undefined' && module.exports) module.exports = { storageKey, loadState, saveState, stamp, recordObservation, observedStatus, buildReport, copyText };
  if (typeof document === 'undefined') return;

  const storage = { getItem: key => window.localStorage.getItem(key), setItem: (key, value) => window.localStorage.setItem(key, value) };
  const loaded = loadState(storage);
  const state = loaded.state;
  const checks = [...document.querySelectorAll('[data-check]')];
  const notes = [...document.querySelectorAll('[data-note]')];
  const cards = [...document.querySelectorAll('[data-task]')];
  const stages = [...document.querySelectorAll('details.stage')];
  const contexts = [...document.querySelectorAll('[data-context]')];
  const persistence = document.getElementById('persistenceStatus');
  const filter = document.getElementById('filterIncomplete');
  const report = document.getElementById('walk-report');
  const journeys = [...document.querySelectorAll('#walk [data-task]')].map(card => ({
    id: card.querySelector('[data-check]').id,
    title: card.querySelector('.task-title').textContent,
    card,
  }));
  const badges = [];
  function showPersistence(saved) {
    persistence.textContent = saved ? 'Progress is saved in this browser only. Keep a copied report before moving the file or changing browsers. Older v2 checks are not imported.' : 'Local storage is unavailable or unreadable. This page still works, but progress may disappear on reload. Copy your report before closing. Older progress was not deleted.';
  }
  function refresh() {
    const complete = checks.filter(box => box.checked).length;
    document.getElementById('progressText').textContent = `${complete} of ${checks.length}`;
    document.getElementById('progressBar').style.width = `${checks.length ? complete / checks.length * 100 : 0}%`;
    for (const card of cards) {
      const done = card.querySelector('[data-check]').checked;
      card.classList.toggle('done', done);
      card.classList.toggle('filtered', state.hideComplete && done);
    }
    filter.setAttribute('aria-pressed', String(state.hideComplete));
    filter.textContent = state.hideComplete ? 'Show complete' : 'Hide complete';
    for (const { badge, key, platform } of badges) badge.textContent = observedStatus(state.observations[key], state.context, platform);
    report.value = buildReport(state, journeys);
  }
  function persist() { showPersistence(saveState(storage, state)); refresh(); }
  for (const box of checks) {
    box.checked = state.checks[box.id] === true;
    box.addEventListener('change', () => { state.checks[box.id] = box.checked; persist(); });
  }
  for (const field of notes) {
    field.maxLength = 4000;
    field.value = text(state.notes[field.id]);
    field.addEventListener('input', () => { state.notes[field.id] = field.value; persist(); });
  }
  for (const field of contexts) {
    const key = field.id.replace('session-', '');
    field.value = text(state.context[key]);
    field.addEventListener('input', () => { state.context[key] = field.value; persist(); });
  }
  for (const journey of journeys) {
    const group = document.createElement('fieldset');
    const legend = document.createElement('legend'); legend.textContent = 'Record this journey'; group.appendChild(legend);
    for (const platform of ['ios', 'android']) {
      const key = `${journey.id}:${platform}`;
      const observation = object(state.observations[key]);
      const label = document.createElement('label'); label.className = 'notes-label';
      label.htmlFor = `${journey.id}-${platform}-result`; label.textContent = `${platform === 'ios' ? 'iPhone' : 'Android'} result: ${journey.title}`;
      const select = document.createElement('select'); select.id = label.htmlFor;
      for (const result of results) { const option = document.createElement('option'); option.value = result; option.textContent = result; select.appendChild(option); }
      select.value = results.includes(observation.result) ? observation.result : 'Not run';
      const badge = document.createElement('p'); badge.setAttribute('role', 'status');
      badges.push({ badge, key, platform });
      const noteLabel = document.createElement('label'); noteLabel.className = 'notes-label'; noteLabel.htmlFor = `${journey.id}-${platform}-note`; noteLabel.textContent = `${platform === 'ios' ? 'iPhone' : 'Android'} notes: ${journey.title}`;
      const field = document.createElement('textarea'); field.id = noteLabel.htmlFor; field.maxLength = 4000;
      field.value = text(observation.note); field.placeholder = 'Role; starting state; exact actions; expected; actual; sanitized screenshot reference. No secrets or identifiers.';
      const record = document.createElement('button'); record.type = 'button'; record.className = 'button';
      record.textContent = 'Record result'; record.setAttribute('aria-label', `Record ${platform} result for ${journey.title}`);
      const capture = () => {
        try { state.observations[key] = recordObservation(select.value, field.value, state.context, platform); persist(); }
        catch (error) { select.value = object(state.observations[key]).result || 'Not run'; badge.textContent = error.message; }
      };
      // Notes do not renew a stale pass. Only the record button records a retest.
      record.addEventListener('click', capture);
      field.addEventListener('input', () => {
        state.observations[key] = { ...object(state.observations[key]), note: text(field.value) };
        persist();
      });
      group.append(label, select, badge, noteLabel, field, record);
    }
    journey.card.querySelector('.task-body').appendChild(group);
  }
  filter.addEventListener('click', () => { state.hideComplete = !state.hideComplete; persist(); });
  document.getElementById('expandAll').addEventListener('click', () => {
    stages.forEach(stage => { stage.open = true; });
    document.querySelectorAll('details.task-card').forEach(card => { if (!card.classList.contains('filtered')) card.open = true; });
  });
  document.getElementById('collapseAll').addEventListener('click', () => {
    document.querySelectorAll('details').forEach(detail => { detail.open = false; });
  });
  document.getElementById('resetChecks').addEventListener('click', () => {
    if (!window.confirm('Clear checks, notes and observations in this v3 guide? Copy your report first. Older guide data is not changed.')) return;
    Object.assign(state, fresh());
    checks.forEach(box => { box.checked = false; });
    notes.concat(contexts).forEach(field => { field.value = ''; });
    document.querySelectorAll('#walk fieldset textarea').forEach(field => { field.value = ''; });
    document.querySelectorAll('#walk fieldset select').forEach(field => { field.value = 'Not run'; });
    persist();
  });
  function fallback(value) {
    const field = document.createElement('textarea'); field.value = value; field.setAttribute('readonly', '');
    field.style.position = 'fixed'; field.style.opacity = '0'; document.body.appendChild(field);
    try { field.select(); return document.execCommand('copy'); } finally { field.remove(); }
  }
  document.querySelectorAll('[data-copy-target]').forEach(button => {
    button.addEventListener('click', async () => {
      const target = document.getElementById(button.getAttribute('data-copy-target'));
      if (!target) return;
      const value = 'value' in target ? target.value : target.textContent;
      const copied = await copyText(value, { clipboard: navigator.clipboard, secure: window.isSecureContext, fallback });
      button.textContent = copied ? 'Copied' : 'Select text to copy';
      button.setAttribute('aria-label', copied ? 'Copied to clipboard' : 'Copy failed. Select the adjacent text and copy manually.');
      window.setTimeout(() => { button.textContent = 'Copy'; button.removeAttribute('aria-label'); }, 2400);
    });
  });
  document.querySelectorAll('a[href^="#"]').forEach(link => link.addEventListener('click', () => {
    const target = document.getElementById(link.getAttribute('href').slice(1));
    if (!target) return;
    if (target.matches('details')) target.open = true;
    let parent = target.parentElement;
    while (parent) { if (parent.matches('details')) parent.open = true; parent = parent.parentElement; }
  }));
  showPersistence(loaded.readable && saveState(storage, state));
  refresh();
}());
