# V1 club identity, vote clarity, and Arsenal Songbook correction

## Outcome

Club Signal now feels like the calm side of the same Chants product rather than a green second brand. The 20-club directory and club-owned Songbook surfaces use reviewed local crests with a Chants shield fallback. Vote controls explain the user's confirmed state while preserving the existing net-score rule. Local Arsenal seed source adds only the short supporter-sung North London Forever refrain.

Production remains closed at generation 11 maintenance with destructive workers false. The deployed catalogue remains 192 chants with 12 for Arsenal; local source is 193 with 13 for Arsenal. This correction made earlier release screenshots and the prior candidate digest stale.

## Implementation

- Replaced Club Signal's dominant green identity with shared Chants ink, supporter gold, warm paper, restrained coral, and neutral utility tones.
- Rebuilt the club directory as compact full-row targets with crest, club name, and arrow. Removed initial tiles, repeated `OPEN` labels, and repetitive card containers.
- Added the reusable `ClubCrest` component with club-name semantics, aspect-preserving one-axis bounded local decoding, a stable loading shape, and a shield fallback for unavailable artwork.
- Added a diagnostic-only `CHANTS_CREST_FALLBACK_TEAM` build value so one named club can prove fallback behavior on a physical phone. The default release path is empty.
- Retrieved exactly 20 API-Football crest PNGs, confirmed provider identity and team IDs, technically inspected their files and mappings, and stored hashes, dimensions, source hosts, retrieval date, and review status without a credential or private response. Owner visual approval of all 20 rendered crests remains a pre-capture gate.
- Kept crests inside descriptive in-app identification. Exact store captures may show what the app renders, but framing, Chants marketing, the Google feature graphic, and the landing hero cannot add or feature the marks.
- Added visible and semantic no-vote, up, and down states. Added truthful result copy for an added vote, a direct direction change, selected-direction removal, and failure recovery. Existing server math and admission remain unchanged.
- Added `North London Forever` to local Arsenal seed with the reviewed three-line refrain, The Angel by Louis Dunford attribution, official Arsenal context, and deterministic seed assertions.
- Kept `REMOVE FROM DEVICE` and its local-copy explanation unchanged because the owner walk confirmed that wording matches the actual offline-save behavior.

## Credential and rights record

Andrew had already authorized use of the API-Football Pro entitlement held for another app. A bounded path-only inventory located that app's ignored environment file; the fetcher read the selected file without echoing, copying, logging, or committing its value or the private response. This was narrower than a content search but did not meet the approved spec's preference for a Chants-specific private credential path. Any later provider read must use a dedicated Chants path supplied directly.

The provenance record proves source and mapping, not trademark clearance, endorsement, or partnership. The app's independent-product disclosure remains controlling. Any use beyond descriptive club identification needs a new rights review.

## Vote conclusion

The walkthrough result was correct. From a neutral surrounding score, up creates `+1`; switching directly to down removes that `+1` and adds `-1`, so the visible score becomes `-1`; tapping the selected down direction again removes the vote and restores zero. The defect was insufficient state explanation and slow-looking route feedback, not double voting or counter drift.

## Verification

- Focused crest, club directory, vote, team Songbook, Chant Lab, Chant Call-Up, saved Songbook, and golden regressions pass.
- All 20 local PNGs pass signature, size, dimension, host, inventory, mapping, and hash checks. Provider mapping has been technically reviewed; the provenance truthfully keeps owner visual review pending until the final all-club device walk.
- Seed validation passes 87 cases and TypeScript compiles without error.
- Updated 390 by 844 and enlarged-text goldens were visually inspected for representative real crests, shield fallback, long content, explicit vote state, and local saved identity. The macOS chant-detail reference is current and strict.
- All 542 Flutter tests pass and `flutter analyze lib test` reports no issue.
- All nine launch-guide tests, all six crest-integrity tests, seed TypeScript, and whitespace pass.
- Project-memory, writing-style, governance, and staged whitespace checks pass against the exact intended handoff.

## Remaining evidence

The single command-center task remains pending. It separates a short fallback diagnostic build from the exact candidate, then requires owner visual approval of all 20 rendered crests, a long club name, the four non-square marks, Arsenal header, North London Forever, save/remove, vote up to down to neutral, route re-entry, connection failure, offline saved reading, and the surrounding shell. Seeing North London Forever live requires the separately approved guarded seed write and attended production window; neither has occurred yet.

After all approved release building is packaged, run the one final comprehensive Claude review Andrew requested. Do not spend review cycles on a separate review of this correction alone.
