import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('../', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const html = read('hosting/index.html');
const css = read('hosting/site.css');
const rosterCurrentness = read('seed/roster_currentness.ts');
const firebase = JSON.parse(read('firebase.json'));
const trustRoutes = [
  'privacy',
  'terms',
  'community',
  'rights',
  'delete-account',
  'support',
];
const fabricatedMetricPattern =
  /\b\d[\d,.]*(?:k|m|b)?(?:\+)?\s+(?:supporters|fans|clubs|creators|members|downloads|installs|views|followers|shares|users)\b/i;
const stadiumProofPattern =
  /(?:votes?|views?|shares?|popularity)[^<.]{0,100}(?:(?:prove|show|mean)s?|(?:has|have|is|are)(?:\s+already)?\s+(?:been\s+)?sung)[^<.]{0,100}(?:stadium|terrace|ground)/i;
const storeCtaPattern =
  /download (?:now|today)|(?:download|available|now)\s+(?:(?:the|it)\s+)?(?:on|from)\s+(?:the\s+)?(?:app store|google play)|get it on|get (?:the )?app (?:on|from)|join (?:the )?waitlist/i;
const remoteEmbedPattern =
  /<(?:script|img|iframe|video|audio|source|embed)[^>]+src="https?:\/\//i;

const showcaseRow = className => {
  const match = html.match(
    new RegExp(`<article class="showcase-row ${className}"[^>]*>([\\s\\S]*?)<\\/article>`),
  );
  assert.ok(match, `missing showcase row: ${className}`);
  return match[1];
};

const teamMap = rosterCurrentness.match(
  /FPL_TEAM_NAMES_BY_SLUG:[^{]+\{([\s\S]*?)\n\};/,
);
assert.ok(teamMap, 'missing current seeded-team authority');
const seededTeamNames = [...teamMap[1].matchAll(/:\s*"([^"]+)"/g)].map(
  match => match[1],
);
const escapeRegex = value => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const seededTeamPattern = new RegExp(
  `\\b(?:${seededTeamNames.map(escapeRegex).join('|')})\\b`,
  'i',
);

test('root metadata identifies the real Chants product and canonical origin', () => {
  assert.match(html, /<title>Chants FC \| Football chants, made by supporters<\/title>/);
  assert.match(html, /name="description"[\s\S]*coming soon to iOS and Android/i);
  assert.match(html, /rel="canonical" href="https:\/\/chantsfc\.com\/"/);
  assert.match(html, /property="og:title" content="Chants FC \| Find your voice in the crowd"/);
  assert.match(html, /property="og:description"[\s\S]*songbook of the terraces/i);
  assert.match(html, /property="og:image" content="https:\/\/chantsfc\.com\/share\/og-default\.png"/);
  assert.match(html, /property="og:image:width" content="1204"/);
  assert.match(html, /property="og:image:height" content="1204"/);
  assert.match(html, /name="twitter:card" content="summary_large_image"/);
  assert.match(html, /name="twitter:image" content="https:\/\/chantsfc\.com\/share\/og-default\.png"/);
  assert.match(html, /name="twitter:image:alt" content="Chants FC supporter holding a scarf"/);
  assert.match(html, /Operated by ThunderRiver Tech LLC/);
  assert.doesNotMatch(html, /Thunderriver Tech LLC/);
});

test('root explains Songbook, Chant Lab, Stage, Club Signal, and trust without collapsing their meaning', () => {
  for (const phrase of [
    'Find your voice in the crowd.',
    'songbook of the terraces',
    'SONGBOOK',
    'CHANT LAB',
    'CHANT STAGE',
    'CLUB SIGNAL',
    'TERRACE PROVEN',
    'RISING',
    'STAGE POPULARITY',
    'Views and shares measure reach, never proof that a stadium sings it.',
    'Saved on this device',
    'AVAILABLE OFFLINE',
  ]) {
    assert.match(html, new RegExp(phrase, 'i'), `missing product meaning: ${phrase}`);
  }

  assert.match(showcaseRow('songbook-showcase'), /01 \/ SONGBOOK/i);
  assert.match(showcaseRow('lab-showcase'), /02 \/ CHANT LAB/i);
  assert.match(showcaseRow('stage-showcase'), /03 \/ CHANT STAGE/i);
  assert.doesNotMatch(html, /ARSENAL|NORTH BANK IDEA|From the North Bank/i);
});

test('root carries the approved product-led launch frame without fake social proof', () => {
  for (const marker of [
    'product-stage',
    'primary-phone',
    'secondary-phone',
    'performance-card',
    'product-showcase',
    'Every chant starts with',
    'LEARN IT',
    'MAKE IT',
    'SING IT',
    'one voice',
  ]) {
    assert.match(html, new RegExp(marker, 'i'), `missing design marker: ${marker}`);
  }
  assert.match(html, /class="phone primary-phone"/);
  assert.match(html, /class="phone secondary-phone"/);
  assert.doesNotMatch(html, fabricatedMetricPattern);
  assert.doesNotMatch(html, stadiumProofPattern);
});

test('illustrative product copy is club-neutral and explicitly allowlisted', () => {
  assert.doesNotMatch(html, seededTeamPattern);
  assert.match(html, /CLUB SIGNAL[\s\S]*MATCHDAY SONGBOOK[\s\S]*READY FOR THE GROUND/);
  assert.match(html, /Saved chants remain available when the signal drops\./);
  assert.match(html, /CHANT LAB[\s\S]*NEW IDEA[\s\S]*WHO IS THIS CHANT FOR\?/);
  assert.match(html, /Your club, your player, or the whole stand\./);
});

test('launch status is honest and the root collects no data', () => {
  assert.match(html, /Coming soon on iOS and Android/);
  assert.doesNotMatch(html, storeCtaPattern);
  assert.doesNotMatch(html, /<form\b|<input\b|<script\b|autoplay|gtag\(|google-analytics|facebook\.com\/tr/i);
  assert.doesNotMatch(html, remoteEmbedPattern);
  assert.doesNotMatch(html, /<object[^>]+data="https?:\/\//i);
  assert.doesNotMatch(html, /<link[^>]+rel="stylesheet"[^>]+href="https?:\/\//i);
  assert.doesNotMatch(html, /<a[^>]+href="https?:\/\//i);
  assert.doesNotMatch(css, /@import\s+(?:url\()?['"]?https?:\/\//i);
  assert.match(html, /href="mailto:support@chantsfc\.com"/);
});

test('negative guards reject representative social-proof, store, and embed regressions', () => {
  assert.match('Joined by 12,000 supporters and 40 clubs', fabricatedMetricPattern);
  assert.match('Trusted by 5k fans across the league', fabricatedMetricPattern);
  assert.match(
    'Enough votes and views prove the chant is sung in the stadium',
    stadiumProofPattern,
  );
  assert.match(
    'A chant with enough votes has already been sung in the ground',
    stadiumProofPattern,
  );
  assert.match('Get the app on the App Store', storeCtaPattern);
  assert.match('Download on the App Store', storeCtaPattern);
  assert.match('Now on Google Play', storeCtaPattern);
  assert.match(
    '<iframe src="https://platform.twitter.com/embed"></iframe>',
    remoteEmbedPattern,
  );
});

test('all six public trust destinations stay reachable from the root', () => {
  for (const route of trustRoutes) {
    assert.match(html, new RegExp(`href="/${route}"`));
    assert.equal(
      existsSync(new URL(`hosting/${route}/index.html`, root)),
      true,
      `missing /${route}`,
    );
  }
});

test('the page keeps accessible and responsive source controls', () => {
  assert.match(html, /class="skip-link" href="#main-content"/);
  assert.match(html, /<main id="main-content">/);
  assert.match(html, /aria-labelledby="hero-title"/);
  assert.match(html, /aria-labelledby="experience-title"/);
  assert.match(html, /aria-labelledby="trust-title"/);
  assert.match(html, /aria-labelledby="matchday-title"/);
  assert.match(css, /:focus-visible/);
  assert.match(css, /outline: 3px solid #ffffff;/);
  assert.match(css, /box-shadow: 0 0 0 7px #000000;/);
  assert.match(css, /@media \(prefers-reduced-motion: reduce\)/);
  assert.match(css, /@media \(max-width: 900px\)/);
  assert.match(css, /@media \(max-width: 580px\)/);
  assert.match(css, /\.hero\s*\{[\s\S]*?overflow: hidden;/);
  const sharedLinkTargetRule = css.match(
    /\.header-nav a,\s*\.header-link,\s*\.primary-action,\s*\.site-footer a\s*\{([\s\S]*?)\}/,
  );
  assert.ok(sharedLinkTargetRule, 'missing shared interactive link target rule');
  assert.match(sharedLinkTargetRule[1], /min-height: 44px;/);
  assert.match(css, /url\("\/assets\/fonts\/Oswald-Bold\.ttf"\)/);
  assert.match(css, /url\("\/assets\/fonts\/Nunito-Variable\.ttf"\)/);
  assert.doesNotMatch(css, /Anton-Regular\.ttf/);
  assert.doesNotMatch(css, /url\(["']?https?:\/\//i);
  for (const font of [
    'Nunito-Variable.ttf',
    'Oswald-Bold.ttf',
  ]) {
    assert.equal(
      existsSync(new URL(`hosting/assets/fonts/${font}`, root)),
      true,
      `missing local font: ${font}`,
    );
  }
});

test('illustrations expose one useful label without leaking fake app structure', () => {
  assert.match(
    html,
    /class="product-stage" role="img" aria-label="Illustration of the Chants Stage and Club Signal screens"/,
  );
  assert.match(html, /class="phone primary-phone" aria-hidden="true"/);
  assert.match(html, /class="product-panel songbook-panel" role="img"/);
  assert.match(html, /class="product-panel lab-panel" role="img"/);
  assert.match(html, /class="product-panel stage-panel" role="img"/);
  assert.doesNotMatch(html, />For you</i);
  assert.match(
    html,
    /class="app-tabs">\s*<span class="active">Stage<\/span><span>Clubs<\/span><span>Create<\/span><span>Songbook<\/span><span>You<\/span>/,
  );
  assert.match(css, /\.dark-eyebrow \{ color: #8a5f00; \}/);
  assert.match(css, /\.lab-prompt \{[^}]*color: #6f6a5e;/);
  assert.match(css, /\.lab-footer \{[^}]*color: #6f6a5e;/);
  assert.match(css, /\.play-button \{[^}]*top: 28px;[^}]*right: 24px;/);
});

test('existing public route and media authority rewrites are unchanged', () => {
  assert.deepEqual(firebase.hosting.rewrites, [
    {
      source: '/media/performances/**',
      function: {
        functionId: 'publicPerformanceMedia',
        region: 'europe-west2',
      },
    },
    {
      source: '/chants/**',
      function: {
        functionId: 'publicSharePage',
        region: 'europe-west2',
      },
    },
    {
      source: '/performances/**',
      function: {
        functionId: 'publicSharePage',
        region: 'europe-west2',
      },
    },
    {
      source: '/creators/**',
      function: {
        functionId: 'publicSharePage',
        region: 'europe-west2',
      },
    },
  ]);
  assert.equal(
    existsSync(new URL('hosting/.well-known/apple-app-site-association', root)),
    true,
  );
  assert.equal(existsSync(new URL('hosting/share/og-default.png', root)), true);
});
