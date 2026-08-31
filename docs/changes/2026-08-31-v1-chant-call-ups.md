# Change implementation rationale: V1 Chant Call-Ups

## Change identity and boundary

- **Implementation:** Codex, source-only approved Call-Ups block.
- **Base:** `2d362a2709ccdc1dd8b18bedea9d72b432f3556b`, PR 26 correction head.
- **Target:** One feature commit on `codex/v1-chant-call-ups`; the PR receipt identifies the packaged SHA and exact-tree CI after they exist. Claude reviewed the earlier staged tree `91213af707f4c6dc4bd3d3334b7adaea35a1ea0b` before the two corrections below.
- **Date:** 2026-08-31.
- **Population:** Two browse repositories, one pure eligibility function, club card and composition, typed submission result, optional player initial tab, related Dart tests/goldens and current project memory.
- **Excluded:** PR 26's already committed F1-F5 corrections, source backend/rules/seed/native changes, production, credentials, deployment, signing, merges and unrelated worktrees. The final Claude handoff includes PR 26 corrections as a separate earlier range.
- **Approval:** Andrew accepted the bounded creation invitation, then both low review corrections, one commit, push and exact-head CI. The active `docs/CHANGE_SPEC.md` records acceptance and non-goals. Merge and deployment remain separate.

## Outcome and capability map

| Boundary | Before | After |
|---|---|---|
| Club opportunity discovery | First-idea prompt buried in player Chant Lab | One labelled call-up above the club's separate Songbook/Lab headings |
| Catalogue truth | Squad stream discarded metadata | Absence prompt requires both complete server-confirmed active streams with no errors or local pending writes |
| Writing | Existing club/player-prefilled form | Same form, origin remains explicit; acknowledged result returns the actual submitted subject |
| Return journey | Form popped with no result | Call-up caller opens that player's Lab, or club Lab for a changed/unlisted subject; other callers can ignore the result |
| Backend/infrastructure | Existing ordinary community chant admission | Unchanged, no call-up entity or new query/index/service |

## Implementation choices

| Choice and source | Reason | Alternative and accepted tradeoff |
|---|---|---|
| `chantCallUpPlayers` | Complete club-set projection excludes players with a visible chant for that club, other-club and blank player data; stable name/ID order | Prior-club chants do not exclude the player here, and card copy names the checked club. No per-player reads or ranking backend. Alphabetical order is not fair-exposure or popularity proof |
| `PlayerRepository.teamBrowseStream`, `ChantBrowseSnapshot.hasPendingWrites` | Preserve metadata at the real Firestore boundary | Inferring freshness from an ordinary list loses authority; legacy squad list callers retain an adapter |
| `TeamScreen._callUpPlayers` and `_reconcileCallUpPlayer` | Omit stale claims and preserve chosen eligible target across tab/data updates | No reserved player or transactional absence. Another fan may post while a form is open; existing duplicate review still applies |
| `ChantCallUpCard` | Reuse current tokens, one action and local next-player choice with no auto-advance | No feed redesign or carousel. After a long name shrinks, keep the new card visible |
| `MaterialPageRoute<Chant>` and submission result | Match the real navigation result type and submitted subject | A boolean loses subject changes; routing the old prefill could show the wrong player. No new document ID is fabricated |
| `PlayerScreen.openChantLab` | Reuse ordinary player discovery and existing detail/vote/share/perform paths | No duplicate result screen or contest-specific comment/ranking system |

No new durable architecture decision is required: the feature is reversible client composition using existing product and authority contracts. The material interface decision is in `docs/INTERFACE.md`.

## Changed flow, authority and failure

TeamScreen owns one team chant and one squad subscription. Each data event replaces its snapshot and clears that stream's error; errors retain readable data but remove call-up eligibility. Stream completion removes the prompt. Cached or pending writes cannot establish absence. The projection uses all visible chants for the current club, including unknown future trust statuses, before filtering listed players. A selected ID remains stable while eligible; another-player taps cycle within that set.

The writing callback rechecks current eligibility and authentication. Signed-out viewers take the existing sign-in route with no automatic-return promise. Signed-in viewers open the real form. Existing origin validation, duplicate review, stale-player recovery, rate limits and server/rules admission are unchanged. Only a successful create acknowledgement returns the submitted Chant. The caller checks mounting before navigation, follows the actual selected player if still listed and otherwise opens club Lab.

No new personal information, logging, analytics, credentials, collection, retention rule or external service. Titles, names and copy are rendered as Flutter text. Synthetic test names and lyrics are isolated to tests and never enter the catalogue.

## Performance, cost and compatibility

Current catalogue: 20 clubs, 622 players and 192 chants. The existing full team queries are unchanged. Eligibility costs one team-chant pass plus sorting eligible squad rows; one visible card is rendered. Metadata-only events can cause extra local rebuilds, not extra queries. No production latency, cost reduction, conversion or fairness measurement is claimed.

Dependencies, SDK versions, lockfiles, rules, indexes, Functions and media protocols are unchanged. CI now retains synthetic failed-golden PNGs for seven days using the already-used artifact action, with no new permissions or success override. Prior clients ignore the presentation feature and still read newly created ordinary community chants. Reverting this client block removes the prompt without deleting contributions or requiring a migration.

## Verification performed

Tests deliberately exercise the real AppRouter and SubmitChantScreen, not a stand-in submit handler. Repository doubles preserve SDK query shape and metadata; they are not an emulator claim. Verification used local Flutter 3.44.8 with existing locked dependencies and only the ignored example client configuration.

| Check | Result |
|---|---|
| `flutter test --no-pub` eligibility and metadata files | Two projection and two actual repository-adapter cases passed, including all three metadata phases and preserved query filters |
| `flutter test --no-pub` Call-Ups widget file | Twelve cases passed in the final full suite: exact real-route prefill, acknowledgement, changed subject, departure, disposal, cancellation/failure, freshness, cycling and independently runnable viewport renders |
| `flutter test --no-pub --reporter expanded` | Final local run: 509 passed in 69 seconds; retained log `/private/tmp/chants-call-ups-final-flutter-test.log`. The additional case splits the old two-viewport test. This is local evidence, not clean-runner CI |
| `flutter analyze --no-pub lib test` | No issues. Missing example config and test-only annotations/braces were corrected before this final check |
| Golden inspection and contrast | 390 by 844 and 320 by 844 at 1.8x text inspected. Existing default 1.5% tolerance, no increase. Card accent/surface 5.01:1, button text/accent 5.61:1, muted body/surface 6.02:1 |
| Pre-feature reproduction | Temporarily substituted the base TeamScreen and ran the actual live-spotlight test. It compiled and failed at the missing player invitation, exit 1. Automatically restored the complete feature; full suite then passed |
| Staged memory, writing, governance and changed-file formatting | All three governance commands, staged whitespace check and all 15 touched Dart files passed |

Early focused checks caught and corrected an untyped MaterialPageRoute result mismatch and the long-to-short name scroll regression. Existing club tests needed scrolling to reach controls below the new card; their ordering and trust assertions remain. Test-only corrections addressed offscreen taps, fake-clock stream teardown and viewport/semantics lifecycle, without weakening runtime assertions.

## Independent review and bounded corrections

Claude's [combined review](https://claude.ai/code/artifact/2d4276b6-e5d2-4ab3-aa43-4ca7ae3c19e7) independently closed PR 26 F1-F5 and found no source blocker in the reviewed Call-Ups tree. It ran 508 Flutter tests, analysis and governance, verified the prior exact-head CI and caught five deliberate behavior mutations. That evidence belongs to the reviewed tree, not automatically to this follow-up.

| Finding | Correction and evidence |
|---|---|
| Low: global absence wording over a team-only query | Pass the actual club name to the shared card. Exact-copy assertions cover Test United and Arsenal; the first failed against the old copy before implementation. Eligibility and player browse remain unchanged |
| Low: completed golden streams suppress the invitation | Replace both Stream.value fixtures with controllers that remain open until screen disposal. Both main club tabs assert CHANT CALL-UP and Declan Rice before comparing pixels. The old fixture failed the presence assertion. No runtime completion guard was relaxed |
| Informational: legacy picker receives metadata events | Expected compatibility behavior already disclosed; no extra filtering abstraction or new query |
| Preference: secondary gold action | Retain the existing theme action token. Red border, eyebrow and primary action distinguish the invitation; gold is not exclusive to trust badges |

All twelve focused tests passed after correction and regeneration. Four images were inspected: both main club tabs at 390 by 844, plus the Call-Up at 390 by 844 and 320 by 844 with 1.8x text. Labels wrap, actions remain reachable, and the invitation stays separate from the trust headings. Existing 2.2% main-club and 1.5% Call-Up tolerances are unchanged. Full replacement local checks and packaging checkpoints are in `docs/EXECUTION.md`; the new CI receipt belongs on the PR.

Replacement full Flutter run: 508 passed in 120 seconds. Analysis found no issues; all 15 staged Dart files are formatter-clean. Memory, writing, governance, native/launch-services contracts and all 19 preparation/guide regressions passed. Backend, rules, seed and native builds are unchanged and are checked on the clean runner rather than repeated locally for this client-only correction.

First CI run `33361604474` at `ee51faa` found Linux Flutter 3.47.2 pixel differences: normal Call-Up 2.25%, main Songbook 2.83%, main Lab 2.74%. Its 506 other cases passed; this is not a green receipt. Failure-image retention and independently runnable viewport cases were added for diagnosis, since the original workflow lost the PNGs and the first failure skipped the enlarged render. All 13 focused cases still pass locally; tolerances remain unchanged while actual runner images are collected.

Diagnostic run `33362066687` at `3ef81c9` retained all four Linux test images and differences in artifact `9747065673`; the enlarged Call-Up differed by 2.93%. Inspection found matching layout/content with differences along glyph and curve edges. The final correction selects four separate Linux references, preserving the macOS images and all thresholds. `test/presentation/browse/goldens/linux/README.md` records byte-exact provenance, hashes and update procedure. Only the two affected test files choose a platform folder; no shared-comparator policy or app rendering changed. The failure-only upload uses the existing action and cannot hide a failed test.

Final local verification after that correction: 509 Flutter cases pass, analysis is clean, touched test files are formatter-clean and staged governance checks pass. Both obsolete failed runs were canceled after their useful evidence was retained; their native completion is not credited to the final head. PR 27 owns the final replacement eight-job CI receipt.

## Rollout, recovery and uncertainty

- Source implementation and reviewed-tree closure are complete. This precommit record does not claim the two low corrections were re-reviewed by Claude, or that packaging, new CI, merge, deployment or device proof has completed.
- PR 26 correction CI `33354752226` proves only its committed base tree, not this new feature.
- Andrew authorized packaging and new exact-head clean-runner CI after the two corrections. Preserve PR 26 as the stacked base while it remains unmerged.
- Walk club to invitation to form to the correct Lab on configured devices, including lost connectivity and cancellation, before release. No production access was needed here.
- Listed membership can still be outdated in the underlying reviewed catalogue. Copy never claims confirmed active contracts or no stadium songs.
- No call-up telemetry, fair-exposure algorithm, prizes, recurring contest, automatic winner, new following/notification or Matchday Mode is included.
- Unchanged backend/rules/seed suites and native packaging were not rerun locally for this client-only block. Their base CI evidence must not be attributed to the feature. No real-device, production or browser claim is made.
- Andrew owns release, catalogue maintenance and any later expansion.

## Material files and repository reconciliation

The two browse repositories own metadata; `chant_call_ups.dart` owns catalogue eligibility; `chant_call_up_card.dart` owns presentation; TeamScreen owns selection and route continuation. AppRouter, SubmitChantScreen and PlayerScreen retain their existing roles with the narrow result/tab extension.

Updated `docs/ROADMAP.md` promotes only this small slice from V1.1, keeping wider competition ideas deferred. `docs/INTERFACE.md`, `docs/PROJECT_PROFILE.md` and the affected Songbook section of `docs/IMPLEMENTATION_RATIONALE.md` record the new capability. `docs/EXECUTION.md` owns chronological verification. Existing unrelated milestone history is unchanged.
