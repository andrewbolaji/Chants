# Decision 004: Chants is both a trusted songbook and a creator workshop

- **Status:** Accepted
- **Date:** 2026-08-21
- **Owner:** Andrew
- **Supersedes:** Refines the archive-only emphasis and the 2026-06-02 link-out decision in `docs/DECISIONS.md`

## Context

Chants began as a useful archive of words already sung on football terraces, but the original product vision also invited fans to invent funny or sincere chants, compete to make the best chant for a player, and help a new idea spread until it reaches a stadium. The current `canonical` and `community` data states support part of that distinction, but the interface and product language mostly present one archive. That can suppress creation, while mixing every item into one unlabeled feed can weaken trust in the real-songbook promise.

External videos can provide useful evidence that a chant is being sung. Requiring a link for every submission would reject honest matchgoers who heard something live but cannot immediately find a clip. Treating votes as proof would let popularity or coordinated voting manufacture a false historical claim.

## Decision

Chants will present two connected product surfaces in v1:

- **Songbook** is the trusted archive. User-facing verified content is labeled **Terrace Proven**. The existing `canonical` status remains its current internal source of truth until an approved implementation spec changes that contract.
- **Chant Lab** is the creator and community surface. It contains original ideas and claims about chants already being sung that have not yet been verified. It supports **Top** and **New** ordering.
- **Rising** is a ranking or editorial signal for promising Chant Lab entries. It never means verified and does not automatically change a chant to Terrace Proven.

Every new submission must declare one origin:

- **Already sung:** The fan is reporting a chant they believe has been sung before.
- **I made this:** The fan is publishing an original chant idea.

The evidence rule is:

- A link is optional when either origin is posted.
- An Already sung submission without evidence remains in Chant Lab with an honest unverified label.
- A user-submitted chant cannot become Terrace Proven until a valid evidence record is attached and an operator reviews it.
- Evidence may be added after the original submission by an authorized future flow. It does not have to be found by the original submitter at creation time.
- Votes may affect Top and Rising placement, but votes alone never prove that a chant has been sung.
- Existing and future operator-seeded canonical content may use the retained human sourcing ledger during v1. It does not need a public video attached to every seed record, but it still requires the established external verification process.

V1 media remains link-out only:

- Evidence links are limited to approved external platforms, initially YouTube and X, validated before storage, opened in the platform app or browser, and removable through moderation.
- Chants does not download, extract, host, transcode, autoplay, or provide background playback for linked media.
- Hosted fan video, an in-app video editor, media feeds, and offline media are not v1 work.

The v1 creator loop also includes a player-scoped Start a chant action, the existing score voting, a soft duplicate nudge, and basic share-out from chant detail. Scheduled creation challenges, creator profiles, follows, notifications, collaborative lyric proposals, richer media, and deeper reply trees remain later work.

## Alternatives considered

| Alternative | Benefits | Costs and risks | Why not chosen |
|---|---|---|---|
| Verified archive only | Clearest trust story and simplest moderation | Weak creation loop, fewer reasons to return, and misses how chants actually emerge | It preserves only half of the product vision |
| One mixed feed with no provenance split | Smallest navigation change | Fans cannot tell terrace history from a new joke; score has to mean truth and popularity at once | It damages both trust and creative freedom |
| Require an evidence link for every Already sung post | Stronger evidence at intake | Honest live observations are discarded when no clip is immediately available | Verification belongs at promotion, not admission |
| Let votes automatically verify a chant | Cheap and community-led | Popularity, brigading, or rival voting can manufacture a factual status | Votes are a quality signal, not evidence |
| Host video in v1 | Richest consumption and creation loop | Adds storage, transcoding, moderation, takedown, licensing, privacy, and cost before demand is proven | Link-out tests demand without making media infrastructure the product |

## Consequences

- Positive: The archive keeps a legible trust boundary while new, funny, and experimental chants have an explicit home and competitive loop.
- Positive: Fans can contribute immediately, and evidence can arrive later without weakening the Terrace Proven standard.
- Negative: Submission, ranking, detail, moderation, and club/player navigation all need coordinated changes and backward compatibility for existing chant documents.
- Negative: External links create validation, dead-link, reporting, privacy, and platform-policy work even without hosting media.
- Follow-up: After the current replies/security change closes, write a Lane 2 change spec for the smallest end-to-end provenance slice. Implement Songbook and Chant Lab in bounded vertical blocks rather than a single rebuild.

## Validation and revisit trigger

- **Evidence:** Andrew approved the two-surface product direction and the optional-at-submit, required-at-verification evidence rule on 2026-08-21. Current code inspection confirms `canonical` and `community` already provide a partial compatibility base, while origin and evidence are not yet represented.
- **Revisit when:** Closed-beta behavior shows fans do not understand the split, valid evidence is consistently unavailable, external links create unacceptable moderation load, or hosted media has proven demand plus approved legal, safety, cost, and operational controls.
