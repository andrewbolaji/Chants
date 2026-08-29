# Decision 019: Resolve public destinations through current server authority

- **Status:** Accepted
- **Date:** 2026-08-27
- **Owner:** Andrew
- **Related:** Decisions 009, 015, 017, and 018; creator platform expansion

## Context

Native plain-text sharing could not carry a chant or performance beyond the installed app. Stable public links are necessary for fan distribution and social previews, but a copied link must not keep exposing content after moderation. Public metadata also cannot leak private profile IDs, raw Storage paths, lyrics, report state, or unsafe user markup.

## Decision

The canonical public origin is `https://chantsfc.com`. Visible chants, performances, and creators resolve to stable `/chants/{id}`, `/performances/{id}`, and `/creators/{handle}` destinations through server-owned handlers.

The callable resolver checks current visibility before the mobile app adds a URL to the operating-system share payload. The Hosting page resolver performs the same current check, escapes user content, uses an allowlisted metadata shape, and returns the same generic unavailable page for hidden, removed, missing, and malformed targets.

Public performance pages include a controlled, non-autoplay video element. Its source is a same-origin media route, not a Firebase Storage path. Each media request checks the exact visible performance projection and expected `performance-media/{performanceId}/source` path before issuing a two-minute signed URL and a no-store redirect. A hide or removal stops new page and media resolution. An already issued signed URL may remain usable for at most its remaining two-minute lifetime.

The initial page has an honest Chants call to action. Native universal links, Android App Links, verified domain association, and store fallback remain deployment and store-identity gates because the repository cannot invent team IDs, signing fingerprints, or store listing identifiers.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Share direct Storage URLs | Minimal server code | Leaks storage topology and bypasses current visibility | Media delivery must recheck authority |
| Put full lyrics in social metadata | Rich preview | Copyright, privacy, and moderation exposure | Preview uses bounded identity and trust copy only |
| Return different errors for hidden and missing | Easier debugging | Enables moderation-state probing | Public callers receive one unavailable result |
| Autoplay public video | Higher immediate play count | Surprise playback and uncontrolled egress | The viewer initiates playback |
| Claim app deep-link fallback now | More complete launch story | Requires unverified domain, signing, and store configuration | Source records only what it can prove |

## Consequences

- Positive: every share has a stable destination that can travel beyond the app.
- Positive: moderation remains effective at page and new media-request boundaries.
- Positive: previews cannot expose lyrics, private IDs, or raw Storage paths.
- Negative: video delivery adds a Function redirect and signed-URL operation.
- Negative: immediate revocation is bounded by the two-minute signed URL lifetime.
- Operational: the production Functions identity needs URL-signing permission, and Hosting plus domain configuration must be verified before links are emitted from a released client.

## Validation and revisit trigger

- **Evidence:** `functions/src/public_share.ts`, `functions/src/index.ts :: publicSharePage`, `publicPerformanceMedia`, `firebase.json`, `hosting/`, `lib/data/repositories/public_share_repository.dart`, native share services, and `functions/test/public_share.test.ts`.
- **Revisit when:** production IAM cannot sign URLs, measured media egress is unacceptable, domain association is ready, anonymous view measurement is approved, or a CDN token and revocation design can replace Function redirects without weakening current authority.
