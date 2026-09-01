import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';

const root = new URL('../', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const routeNames = [
  'privacy',
  'terms',
  'community',
  'rights',
  'delete-account',
  'support',
];
const routes = Object.fromEntries(
  routeNames.map(name => [name, read(`hosting/${name}/index.html`)]),
);
const correspondenceAddress =
  '5667 Treaschwig Rd #1014, Spring, TX 77373, United States';

test('all six public policy routes are complete and mutually reachable', () => {
  for (const [name, html] of Object.entries(routes)) {
    assert.match(html, /support@chantsfc\.com/);
    assert.match(html, /Thunderriver Tech LLC/);
    assert.match(html, new RegExp(correspondenceAddress));
    assert.match(html, /Effective 31 August 2026/);
    for (const destination of routeNames) {
      assert.match(html, new RegExp(`href="/${destination}(?:["#?])`), `${name} lacks ${destination}`);
    }
    assert.doesNotMatch(html, /\[PLACEHOLDER\]|coming soon|24\/7 (?:support|monitoring is provided)/i);
  }
});

test('published copy matches the approved service commitments', () => {
  assert.match(routes.support, /acknowledge ordinary support and video-review requests within two business days/);
  assert.match(routes.support, /Moderation is reviewed daily and urgent safety concerns are prioritized/);
  assert.match(routes.support, /does not promise 24\/7 monitoring/);
  assert.match(routes['delete-account'], /complete a verified deletion within 30 calendar days/);
  assert.match(routes['delete-account'], /Never send a password, sign-in code, or recovery code/);
});

test('public correspondence uses the approved business mailbox', () => {
  const dartPolicy = read('lib/app/policy.dart');
  assert.match(dartPolicy, /kBusinessCorrespondenceAddress/);
  assert.match(dartPolicy, /5667 Treaschwig Rd #1014, Spring, TX 77373/);
  assert.match(dartPolicy, /United States/);
  assert.match(routes.privacy, /Business correspondence can be sent to Thunderriver Tech LLC/);
  assert.match(routes.rights, /Email remains the fastest way to start a request/);
  assert.match(routes.support, /Business correspondence can be sent to Thunderriver Tech LLC/);
});

test('the policy pack closes only the correspondence-address hold', () => {
  const pack = read('docs/LAUNCH_POLICY_PACK.md');
  assert.match(pack, new RegExp(correspondenceAddress));
  assert.match(pack, /support@chantsfc\.com.*mailbox receipt and branded outbound reply are not yet evidence/);
  assert.doesNotMatch(pack, /No non-residential address has been selected/);
});

test('acceptance contract is v2 Terms and Community Rules, with Privacy separate', () => {
  const authority = read('functions/src/policy.ts');
  const version = authority.match(/CURRENT_POLICY_VERSION = "([^"]+)"/)?.[1];
  assert.equal(version, 'v2');
  assert.match(read('lib/app/policy.dart'), new RegExp(`kCurrentPolicyVersion = '${version}'`));
  assert.match(read('firestore.rules'), new RegExp(`acceptedPolicyVersion == '${version}'`));
  assert.match(read('storage.rules'), new RegExp(`acceptedPolicyVersion == '${version}'`));
  for (const path of [
    'functions/src/creator_follow.ts',
    'functions/src/creator_notification.ts',
    'functions/src/creator_profile.ts',
    'functions/src/index.ts',
    'functions/src/living_songbook.ts',
    'functions/src/performance.ts',
  ]) {
    const source = read(path);
    assert.match(source, /import \{ CURRENT_POLICY_VERSION \} from "\.\/policy";/);
    assert.doesNotMatch(source, /acceptedPolicyVersion\s*[!=]==?\s*["'][^"']+["']/);
  }
  const gate = read('lib/presentation/auth/policy_acceptance_gate_screen.dart');
  assert.match(gate, /Terms and Community Rules/);
  assert.match(gate, /Privacy Notice explains how/);
  assert.match(gate, /not part of this agreement/);
  assert.match(gate, /AppRouter\.support/);
  assert.match(gate, /showDeleteAccountDialog/);
  assert.match(gate, /authRepositoryProvider\)\.signOut\(\)/);
  assert.match(read('lib/presentation/auth/sign_in_screen.dart'), /AppRouter\.policyHub/);
  assert.match(read('lib/presentation/content_policy/content_policy_screen.dart'), /Accepted contract version/);
  assert.match(read('lib/presentation/content_policy/content_policy_screen.dart'), /Urgent child safety/);
  assert.match(
    read('functions/src/account_deletion_dispatch_cli.ts'),
    /"functions\/src",\s*"firestore\.rules",\s*"storage\.rules"/s,
  );
});

test('launch policy does not alter the app age boundary', () => {
  assert.match(read('lib/data/services/age.dart'), /kMinimumAge = 17/);
  assert.match(read('functions/src/onboarding.ts'), /ageConfirmed17Plus: true/);
  assert.match(routes.terms, /at least 17 to create an account/);
});

test('deletion instructions distinguish public removal from retained recovery evidence', () => {
  assert.match(routes['delete-account'], /structural tombstones/);
  assert.match(routes['delete-account'], /retain your account ID as their target/);
  assert.match(routes['delete-account'], /unresolved cleanup evidence/);
  assert.match(routes.privacy, /Unresolved cleanup evidence stays until cleanup is verified/);
  assert.match(routes.privacy, /closed support correspondence is targeted for deletion after 90 days/);
});
