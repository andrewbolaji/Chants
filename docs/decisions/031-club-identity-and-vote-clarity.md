# Decision 031: Use crest-led Club Signal identity and explicit vote state

**Status:** Accepted

**Date:** 2026-09-08

## Context

The first exact-candidate iPhone walkthrough proved the core app but exposed three release-facing gaps. Stage used Chants ink, gold, and coral while Club Signal used a dominant green utility theme and repeated initial tiles. A direct vote switch from up to down correctly changed the surrounding net score from `+1` to `-1`, but the interface did not explain the selected vote or distinguish a change from another vote. Arsenal's local seed also omitted the short North London Forever refrain supporters sing before home matches.

API-Football can supply stable club identification media, but provider delivery is not trademark clearance or evidence of affiliation. Song lyrics also remain protected even when supporters sing them in a stadium.

## Decision

- Keep Stage expressive and Club Signal calm, but use the same Chants ink, supporter gold, warm paper, restrained coral, and neutral utility family across both.
- Replace the club directory's initials and repeated card treatment with compact crest-led rows. Use one crest in the club header and saved-club overview where identity materially helps; do not repeat crests on chant cards.
- Cache the exact 20 technically verified API-Football crest PNGs as local app assets with hashes, provider team IDs, source URLs, retrieval dates, dimensions, and review status. Preserve intrinsic aspect ratio during bounded decode. Flutter has no runtime provider dependency or credential.
- Use club marks only for descriptive in-app identification. Do not use them as Chants branding, feature-graphic art, landing-page hero art, paid marketing, or evidence of a club relationship.
- Fall back to a Chants shield with club-name semantics for missing, corrupt, unsupported, or withdrawn crest assets. Never fall back to a lone initial or blank area.
- Preserve one vote per user with values `+1`, `0`, and `-1`. A direct up-to-down switch is a two-point net change and ends selected down. A second tap on down removes the vote and returns that user's contribution to zero.
- Name the confirmed vote as `YOUR VOTE  UP`, `YOUR VOTE  DOWN`, or `NO VOTE`, announce the score and state semantically, and distinguish added, changed, removed, and failed transitions. Do not change vote aggregation, permissions, ranking, schema, or backend logic.
- Add one local Arsenal entry titled `North London Forever` containing only the reviewed three-line supporter refrain, attributed to The Angel by Louis Dunford and backed by official Arsenal and tune evidence. Keep production at its existing 192 chants until a separate seed-write approval.
- Retain `REMOVE FROM DEVICE` because the saved Songbook is a local offline copy. Confirmation must continue to state that the live chant and account are unaffected.

## Reasons

Recognition matters in a 20-club scan, but visual identity must still feel like Chants and must not imply endorsement. Local bounded assets make that experience deterministic and offline-safe. Explicit vote state resolves the walkthrough's confusion without weakening server truth. The short established refrain adds genuine matchday value while respecting a narrow content boundary.

## Consequences

- Existing release screenshots and exact-candidate interface evidence become stale and must be recaptured from the next candidate.
- The source catalogue contains 193 chants and Arsenal contains 13; production remains at 192 and Arsenal at 12 until separately authorized.
- A crest may be removed later without breaking layout or club identification.
- Provider identity and file integrity are technically verified; owner visual approval of all 20 rendered crests remains mandatory before store capture, and provenance stays pending until that device check is complete.
- Provider terms and trademark use need renewed review before club marks are used outside the descriptive in-app context.
- A physical iPhone walkthrough must prove loaded and fallback crest states, long names, vote transitions and recovery, North London Forever, route re-entry, and device-local save removal.

## Revisit triggers

Revisit if a club identity changes, a crest must be withdrawn, provider redistribution terms change, a club partnership is proposed, real-device decoding or scrolling is unstable, vote state no longer converges between routes, or a production seed write is approved. Do not replace deterministic local assets with a runtime provider request as an isolated change.
