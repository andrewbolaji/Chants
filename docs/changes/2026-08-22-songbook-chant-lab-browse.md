# Songbook and Chant Lab browse split

**Completed:** 2026-08-22
**Type:** Lane 2 trust presentation, ranking behavior, navigation, and cached-state handling
**Application behavior changed:** Team and Player browse hierarchy, ordering, empty states, cache/error presentation, and player creation entry

## Change identity and boundary

- **Change:** Replace the mixed Team and Player chant feed with Songbook-first trust surfaces and a separate competitive Chant Lab.
- **Target:** Stacked branch `codex/v1-songbook-chant-lab` and draft PR 7, based on provenance draft PR 6.
- **Included:** Pure projection and ranking, route-local stable order, Rising presentation, cache metadata, retained-data error handling, fail-soft player metadata, Team and Player tabs and empty states, player-prefilled creation, tests, goldens, and durable framework records.
- **Excluded:** Firestore schema, rules, indexes, Functions, seed content, packages, Firebase access, deployment, migration, Saved Matchday Songbook, share-out, hosted media, notifications, and release.
- **Approval:** Andrew explicitly approved the exact `docs/CHANGE_SPEC.md` contract before runtime implementation began on 2026-08-22.

## Outcome

- Team and Player routes open on Songbook and place only canonical Terrace Proven chants there. Community chants appear only in Chant Lab. Unknown future statuses fail closed from both surfaces.
- Songbook and Chant Lab Top use score descending, creation time ascending, then ID ascending. Survivor positions remain stable through score updates during one route visit, removed or status-changed chants leave immediately, and newcomers append.
- Chant Lab New uses creation time descending then ID ascending. Negative-score community chants remain visible.
- Rising is explicit secondary card text for community work with score at least 3 from the inclusive previous seven days. Supporting copy says it is early community support and not Terrace Proven.
- Team Songbook retains club and player sections plus Full squad. Chants with missing or loading player metadata remain visible. Team Chant Lab is one team-wide list enriched with known player names.
- Player routes retain exact player-prefilled Start a chant arguments. Signed-out empty Lab states explain the sign-in requirement without presenting an enabled write action.
- Repository snapshots expose Firestore cache provenance without another query. Team and Player each own one chant subscription, keep the last usable data through a later error, and show neutral DEVICE CACHE or LAST LOADED CHANTS support copy.

## Invariants preserved

- `canonical` remains the only Terrace Proven membership state and `community` remains the only Chant Lab membership state.
- Votes rank community taste and momentum but never promote, verify, or change surface membership.
- Existing hidden and removed query filters remain the visibility enforcement boundary.
- Existing chant IDs, counters, comments, votes, provenance, evidence, and seed records are unchanged.
- No live Firebase request, deployment, migration, merge, or release occurred.

## Verification

- `flutter test`: 224 passed locally.
- `flutter analyze lib test`: no issues.
- `cd functions && npm test`: 35 passed.
- `cd seed && npm test`: 42 passed.
- `cd test_rules && npm exec tsc -- --noEmit`: exit 0.
- The local Firestore emulator suite was not run because this machine has no Java runtime. Its rules and fixtures are untouched; the clean GitHub Actions rules job remains the authoritative execution for this block.
- Red-check 1: temporarily routing canonical status into Chant Lab made the focused projection test fail on the missing Songbook ID. Restoring the partition made the focused and full suites pass.
- Red-check 2: temporarily clearing the last successful Player snapshot on a later stream error made the retained-data widget test fail because the chant disappeared. Restoring independent data and error state made it pass.
- Visual evidence: `team_songbook.png` and `team_chant_lab.png` were generated at 390 by 844, passed the bounded cross-platform comparator, and were visually inspected. The enlarged-text Team test passes at 1.8x without overflow or clipped Top/New controls.
- Scope evidence: `git diff --check` and the changed-prose dash scan pass. Unrelated Android Gradle and lockfile changes remain outside the implementation boundary.

## Security, privacy, abuse, and infrastructure impact

This block changes no write path or authorization rule. Surface membership is projected from the existing status field after the existing hidden and removed query filters. Unknown statuses fail closed. Rising uses client time and score only for decoration, so clock manipulation cannot grant trust, moderation, or write authority. Cache metadata is presented accurately and does not claim durable offline availability.

The block adds no Firestore read per route, index, collection, field, Cloud Function, package, analytics event, remote configuration, or hosted service. Metadata changes may produce local snapshot events without changing document-read cost.

## Rollout, rollback, and follow-up

Draft PR 7 remains unreviewed and unmerged. Complete its clean CI and stacked review after PR 6, then include mixed, canonical-only, community-only, empty, cached, promoted, demoted, hidden, player-prefilled creation, and enlarged-text states in the combined device walk. Rollback is a client-only restoration of the mixed feed; no data or backend rollback is required. The next independent v1 product block is Saved Matchday Songbook.
