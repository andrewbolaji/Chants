# Chants engineering overview

This is the current whole-project map for Chants. It describes final merged `main` at `9189c71d99c52539cb3d1b02f51701fa4334c144` plus the locally verified `codex/post-interface-review-corrections` branch. Claude independently reviewed the freeze ranges through final closure, then reviewed the merged PR 15 range `2df9fa0...9189c71`. That latest review found one blocking false trust label and three medium evidence or recovery findings. The bounded correction is locally complete, and the same final-review range now includes the next native-readiness block: the iOS simulator target compiles on a project-pinned CocoaPods graph. Packaging and clean-runner CI remain pending. Every material claim names the implementation path and symbol that supports it.

This document is descriptive, not an approval record. `docs/CHANGE_SPEC.md` contains the approved native-readiness contract that follows the completed post-interface correction. `docs/EXECUTION.md` records review and implementation evidence. `docs/IMPLEMENTATION_RATIONALE.md` is the companion coverage ledger and verification record. Completed reasoning lives in `docs/changes/`, and durable decisions live in `docs/decisions/`.

The correction is isolated in a clean worktree from merged PR 15. Andrew's older Gradle, settings, lockfile, and private freeze-note work remains untouched in its original worktree.

## Review outcome

The stacked product work is coherent and unusually well tested for a pre-v1 mobile app. The combined client, Functions, seed, and rules design supports one-level replies, blocking, audited unban, stable seeded chant IDs, explicit provenance and evidence, separate Songbook and Chant Lab browse surfaces, device-local Saved Matchday Songbook, native plain-text share-out, server-authoritative report and feedback budgets, and durable account deletion.

The V1 freeze review found concurrency, acknowledgement, storage-identity, and cache-provenance cases that the earlier automated matrix did not model. The first independent follow-up found that unknown acknowledgement was only transiently explained and that audit rows retained reporter identity and text. Its correction passed clean-runner CI at `c893cd0`. The second narrow follow-up found that actor-wide audit flattening removed useful operator provenance, the copy overstated target-side deletion, and prepared recovery required relaunch. That correction passed clean-runner CI at `fe93e20`. The final review found one disposed-Home error path and one dormant merge audit documentation defect. The merged final closure addresses both:

1. **Destructive acknowledgement.** `SavedSongbookRepository`, `savedSongbookDeletionStateProvider`, and `FileSongbookStorage` preserve prepared, unknown, and accepted local states. Prepared state actively retries artifact recovery in the same process, unknown gates Home behind a persistent deletion retry screen, and a positive pending marker can advance accepted local cleanup.
2. **Audit privacy and provenance.** `auditRedactionForDeletedActor` retains generated detail only for known operator actions under `deleted-operator`, replaces report and unknown detail, and redacts self-target policy acceptance. `writePrivacySafeReportAuditEntry` transactionally redacts delayed report audits for a pending or missing reporter. The non-identifying completion audit is exactly once because its write and phase advancement share one transaction.
3. **Counter serialization.** `functions/src/index.ts` recomputes vote, like, visible-comment, user-report, and explicit chant aggregates in parent-serialized transactions. The controlled overlap test models a parent-version conflict and verifies convergence when the runtime retries the older transaction.
4. **Target and input closure.** `handleSubmitReport` rejects deletion-pending user targets, an existing target deletion job, and oversized UTF-8 document IDs. `firestore.rules :: isActiveProfile` denies a new block against a pending target.
5. **Storage identity.** `songbookStorageKeyForUid` uses lowercase SHA-256 over UTF-8 UID bytes, with active-UID lazy migration from the old base64url names.
6. **Live authority and widget identity.** `ChantRepository.chantStream` carries Firestore cache provenance. Detail and Discover keep cache text readable, and only already-saved local navigation or removal remains available without server confirmation. Vote and comment state reset on chant-ID change and discard callbacks from older generations.
7. **Unsafe merge stop.** `requireMergeChantsEnabled` returns failed-precondition after operator authorization, so the sequential non-resumable merge path cannot mutate data before a separately approved recovery design exists.
8. **Late deletion response.** Both deletion error handlers check that Home remains mounted before accessing Riverpod or scaffold state. A pending profile can therefore replace Home while an older request completes without producing an unhandled disposed-consumer error.
9. **Core interface readiness.** Home, competition, and player have current 390 by 844 baselines and focused state evidence. Competition copies an immutable snapshot before sorting; browse failures no longer promise a nonexistent pull-down gesture; and Home search exposes a stable clear-control label.
10. **Bounded Home hierarchy.** `HomeScreen`, Home-mode `DiscoverySection`, and the optional Home presentation in `ChantCard` surface signed-in matchday utility, Premier League browse, one Terrace Proven chant, and one Chant Lab idea without changing provider, route, current-live authority, persistence, or backend contracts. Search remains one combined result list.
11. **Independent interface correction.** Home-mode `_LiveChantCard` derives Rising from the currently rendered live chant through `isRisingChant` and a deterministic evaluation time. A stale zero-score idea keeps `ORIGINAL IDEA` without `RISING`; a live score change removes the badge. Empty Terrace Proven recovery opens real Premier League browse. Direct semantic assertions protect trust words outside the Home-only 3 percent golden allowance, while competition and player retain 2.2 percent. Governance scripts now preserve spaced paths, fail closed on scan errors, scan tracked index prose, and describe staged memory linkage as a manual pre-handoff gate.

The disabled merge's legacy audit detail is not wholly generated moderation text. It includes source title, lyrics, context, tune, and raw `createdBy`. Any future re-enable must pair resumable mutation design with a privacy-safe audit payload and a fresh retained-action allowlist review.

Release gates also remain outside those defects:

- `android/app/build.gradle.kts :: android.buildTypes.release` signs with the debug keystore, which blocks a store release.
- `lib/presentation/content_policy/content_policy_screen.dart :: ContentPolicyBody` still tells users the full policy is coming later.
- Android compilation and the combined iPhone, Android, iPad share, keyboard, moderation, account deletion, and airplane-mode walk remain incomplete. The iOS simulator app itself now compiles on CocoaPods.

The prior fail-open analysis path is also closed. `.github/workflows/ci.yml :: flutter-analyze` now uses the secret when present or copies `lib/firebase_options.dart.example`, then always runs analysis.

Two later stacked blocks closed risks that the earlier review identified. `functions/src/safety_submission.ts` and decision 010 move report and feedback admission behind atomic private budgets. `functions/src/account_deletion.ts` and decision 011 replace synchronous deletion with a private bounded retry job, pending-account authority, and recoverable Auth finalization. Decisions 012 through 016 record the additional freeze corrections and audit-retention boundary.

The engineering stack through PR 15 is merged and exact-main clean-runner green. The independent-review correction and iOS native-readiness block are locally green at their verified boundaries and still need packaging, clean-runner CI, and one combined independent closure. The product is not release-ready: Android compilation, signing credentials, final policy wording, live deployment, operational configuration, seed completion, and the combined device walk require separate owner input or authorization.

## What the product is now

Chants is both a trusted terrace archive and a creator workshop. `docs/decisions/004-songbook-and-chant-lab.md` assigns `canonical` chants to the Terrace Proven Songbook and `community` chants to Chant Lab. New submissions declare either `alreadySung` or `originalIdea`; an external YouTube or X evidence link is optional at admission and required, with operator review, before a user submission can become canonical.

The current user journey is:

- Email and password authentication, 17-plus confirmation, and versioned content-policy acceptance through `lib/presentation/auth/`, `lib/app/app.dart :: _SignedInGate`, and `functions/src/index.ts :: acceptPolicy`.
- Premier League browse, Discover, search, Team and Player Songbook, Team and Player Chant Lab, live detail, voting, comments, direct replies, reporting, blocking, and submission through `lib/presentation/`.
- Explicit local offline copies through `lib/data/repositories/saved_songbook_repository.dart`, `lib/data/services/saved_songbook_service.dart`, and `lib/presentation/saved/`. Saved content is a bounded read-only device snapshot, not a Firestore sync feature.
- Plain-text native sharing from live chant detail through `lib/data/services/chant_share.dart` and `lib/presentation/browse/chant_detail_screen.dart`. Current builds intentionally emit no public URL because no chant web resolver exists.
- Durable account deletion through `lib/data/services/account_deletion_service.dart`, `functions/src/account_deletion.ts`, `lib/presentation/auth/account_deletion_recovery_screen.dart`, and `account_deletion_pending_screen.dart`. Prepared local state actively recovers, unknown state persistently gates Home, and accepted deletion removes active authority and finishes without keeping the client open.

The data model can represent more sports and competitions, but the current product route is not fully data-only. `lib/presentation/home/home_screen.dart` hardcodes the Premier League tile and `lib/presentation/browse/discovery_section.dart :: allTeamsProvider` hardcodes the Premier League ID.

## How to read the repository

Start with `AGENTS.md`, the active `docs/CHANGE_SPEC.md`, and accepted records in `docs/decisions/`. Read `firestore.rules` before assuming any client UI restriction is authoritative. Then read `functions/src/index.ts`, followed by the client repositories and these load-bearing state boundaries:

- `lib/presentation/shared/vote_controls.dart :: OptimisticVoteState`
- `lib/presentation/comments/comment_card.dart :: CommentLikeState`
- `lib/presentation/comments/comment_section.dart :: _CommentSectionState`
- `lib/data/repositories/chant_repository.dart :: _visibleChants`
- `lib/data/repositories/saved_songbook_repository.dart :: SavedSongbookRepository`
- `lib/data/services/chant_browse.dart :: projectChants`

Historical `docs/DECISIONS.md` and `docs/BLOCK_RECAPS.md` explain earlier work but are not current implementation authority. Their statement that `mergeChants` records a complete undo snapshot is superseded by the current source and this review.

## Runtime stack

| Layer | Current repository state | Authority |
|---|---|---|
| Client | Flutter, Dart, Material 3, Riverpod, dark theme | `pubspec.yaml`, `lib/app/` |
| Authentication | Firebase Auth, email and password | `lib/data/repositories/auth_repository.dart` |
| Database | Cloud Firestore, flat top-level collections | `firestore.rules`, `firestore.indexes.json` |
| Server | Fifteen Cloud Functions v2 exports, Node 20, TypeScript, `europe-west2` | `functions/src/index.ts`, `functions/package.json` |
| Integrity | App Check with Apple App Attest/DeviceCheck fallback and Android Play Integrity in release | `lib/main.dart` |
| Crash reporting | Firebase Crashlytics for Flutter and platform-dispatched errors | `lib/main.dart` |
| Local persistence | One schema-versioned JSON Saved Songbook per lowercase SHA-256 UID key | `lib/data/repositories/songbook_storage.dart`, `saved_songbook_repository.dart` |
| Seeding | Admin SDK CLI with explicit chant IDs and read-only preflight mode | `seed/seed.ts`, `seed/chant_identity.ts`, `seed/seed_plan.ts` |
| CI | Project governance, Flutter test, Flutter analysis, Functions, seed, and Java-backed rules jobs on the readiness branch | `.github/workflows/ci.yml` |

The repository declares Flutter SDK `^3.10.8` and Node 20. This review ran on Flutter 3.44.8 and Dart 3.12.2. CI follows unpinned Flutter `stable`, which makes the runner version movable without a repository change.

## Data and authority

All Firestore collections are top-level. Reference collections are `sports`, `competitions`, `teams`, and `players`. Content and interaction collections are `chants`, `votes`, `comments`, `commentLikes`, `reports`, `commentReports`, `userReports`, `profiles`, `feedback`, `auditLog`, and `blocks`. Private server lifecycle state lives in `safetyRateLimits` and `accountDeletionJobs`.

`firestore.rules` is the direct-client authority. Admin SDK code in Functions and the seed pipeline bypasses those rules, so callable role checks and seed validation are separate load-bearing controls.

Deterministic interaction document IDs enforce one row per relationship:

- `votes/{userId}_{chantId}`, mirrored by `lib/data/models/vote.dart :: Vote.documentId`
- `commentLikes/{userId}_{commentId}`, mirrored by `lib/data/models/comment_like.dart :: CommentLike.documentId`
- report IDs built from reporter and target in the three report repositories
- `blocks/{blockerId}_{blockedUserId}`, mirrored by `lib/data/models/blocked_user.dart :: BlockedUser.documentId`

Profiles are owner-private and operator-readable. Votes and comment likes are owner-private and operator-readable. Visible chants and comments are publicly readable. Reports and the audit log are operator-readable. Blocks are private to the blocker. Safety-rate and account-deletion job documents are unreadable and unwritable by every client. Those policies are implemented in the matching blocks in `firestore.rules`.

Direct-client authority now includes exact shapes for profiles, blocks, chants, votes, comment likes, and comments. Report and feedback creation is callable-only; the server owns identity, time, admission budget, and stored shape. New direct user chants must match stored Team and optional Player relationships and fit the shipped parser. User media and variations remain deliberately unavailable in v1 direct writes. Admin SDK seed and Function writes remain separate authority paths. Existing legacy visible chants remain readable, while a legacy document that does not fit the current schema cannot use the strict direct-author edit path until normalized.

## Counters and asynchronous reconciliation

Chant vote totals, comment like totals, visible comment counts, and report-derived counts are denormalized for live reads. Their ground truth remains the child collections.

`functions/src/index.ts :: handleVoteWritten`, `handleCommentLikeWritten`, `recomputeCommentCount`, `handleChantReportWritten`, `handleCommentReportWritten`, `handleUserReportCreated`, and `handleUserReportDeleted` recompute absolute totals instead of blindly incrementing. Each path reads and writes its parent inside the same Firestore transaction as the child query. Duplicate delivery is idempotent, and overlapping delivery conflicts on the shared parent so a stale transaction retries against current stored truth.

Votes and comment likes also write `appliedValue` in the parent transaction when the surviving interaction still has the event's identity and value. `OptimisticVoteState` and `CommentLikeState` use that stamp to distinguish a local write that the server count has already absorbed from one still waiting for its trigger. The no-op guards in both Functions prevent the stamp write-back from looping.

Both vote and comment-like handlers check parent existence inside their transaction before aggregate work. A delayed trigger after deletion makes no child query, parent write, or reconciliation stamp.

## Browse, moderation, and live state

`lib/data/repositories/chant_repository.dart :: _visibleChants` applies `hidden == false` and `removed == false` to list queries. `TeamScreen` and `PlayerScreen` subscribe to query snapshots, preserve their last usable result through ordinary connection errors, and remove a chant when the query authoritatively removes it.

Discover performs a one-shot visible fetch and shuffles it, then each keyed card listens to its document. `_LiveChantCard` classifies Firebase permission denial separately from ordinary connection failure: transient failure retains the last safe card, while denial, server-confirmed absence, hidden, or removed state removes it. A cache-only card remains readable and navigable but cannot vote.

`ChantDetailScreen` receives a route snapshot for readable fallback. `ChantRepository.chantStream` includes metadata changes and preserves `isFromCache`. The screen derives current server authority only from an active, error-free, non-cache visible document. Share, Report, Vote, Comment, and a new save are unavailable until that state exists. Opening an already-saved club or removing an individual device copy remains available because those branches do not act on Firestore or an external destination.

Discover currently reads all visible chants with no page size in `ChantRepository.discoveryChants()`. Saved club refresh also reads the complete visible Team set from the server. Both are acceptable at the current 12-chant seed, but Discover must paginate or adopt a server-supported random-selection strategy when content volume grows.

## Submission, provenance, and evidence

`lib/presentation/submit/submit_chant_screen.dart` requires origin, title, lyrics, tune, subject, and style. Evidence remains optional and is normalized by `lib/data/services/chant_evidence.dart :: ChantEvidenceParser` to canonical YouTube watch or X status URLs.

The soft duplicate nudge is implemented, despite stale wording in `docs/ROADMAP.md`. `SubmitChantScreen :: _reviewLikelyDuplicates` fetches the Team's visible chants, runs `ChantMatcher`, and requires an explicit View, Post mine anyway, or Go back choice. Failure of the advisory lookup does not become an authorization boundary.

Promotion is not vote-driven. `functions/src/chant_trust.ts :: planChantTrustAction` requires valid stored evidence for user-created canonical promotion. System-owned seed content is the documented sourcing-ledger exception. Evidence removal demotes user-owned canonical content in the same transaction.

Player-prefilled submission now validates the loaded Player set before giving the dropdown an initial value. A removed or moved Player clears the selection, explains the recovery, and lets the fan choose again or switch subject. Player-stream failure also leaves the subject control usable instead of spinning indefinitely.

## Comments, replies, blocks, and reports

Comments are flat Firestore documents. A nullable or absent `parentCommentId` means top-level; a non-null parent means one direct reply. `firestore.rules :: validReplyParent` rejects missing, hidden, cross-chant, reply-to-reply, and block-conflicting parents. `CommentSection` ranks parents by likes then recency and sorts replies oldest first.

Blocking is directional for storage and private visibility, but reply and like rules check both directions. The client filters blocked authors from the rendered thread. Block snackbar Undo now contains repository failure and shows `Could not unblock this user. Try again.`

Report counters are computed from pending report rows inside a Firestore transaction. Chant and comment content auto-hide at three pending reports and never auto-remove. User reports only increase an operator-review count. `submitReport` and `submitFeedback` validate typed payloads, current targets, profile and deletion-job state, bounded UTF-8 path identity, and private anchored-window budgets before storing server-owned rows. Report audits transactionally read the reporter profile so pending or already-deleted identities and report text are redacted even when trigger delivery is late. User reports and direct blocks reject deletion-pending targets. Direct report and feedback creates are denied. App Check enforcement remains a separate live configuration question.

## Saved Matchday Songbook

Saved Matchday Songbook is local-only by design. `SavedSongbookRepository` stores at most 500 unique chants and 2 MiB of encoded JSON, isolates files by a lowercase SHA-256 digest of the UTF-8 Firebase UID, serializes mutations, and writes through a temporary file plus atomic replacement. It refuses future schema versions and malformed shapes. The active UID lazily migrates its matching legacy base64url files.

Fresh save and refresh paths use explicit server reads in `SavedSongbookService`. Saved detail is read-only and excludes votes, comments, reports, evidence, media, and share. Account deletion moves the local file from prepared to unknown before the remote await. A pre-network failure never calls the remote boundary and serialized recovery can restore prepared data without relaunch. An unknown response remains locked and persistently gates Home; explicit callable success or a positive server pending marker permits accepted cleanup. A negative profile observation never restores unknown data. Confirmed cleanup deletes every other artifact before its accepted marker, so partial I/O failure remains locked and retryable.

This design has strong unit and widget coverage. Its remaining evidence boundary is physical-device force-stop and relaunch in airplane mode. No test renderer can prove operating-system filesystem survival or real background lifecycle behavior.

## Durable account deletion

`functions/src/account_deletion.ts :: requestAccountDeletion` creates one `accountDeletionJobs/{uid}` cursor and sets `profiles/{uid}.deletionPending` in the same transaction. Duplicate requests preserve the stored phase. `functions/src/index.ts :: onAccountDeletionJobWritten` uses Eventarc retry and advances one Auth operation, audit operation, finalization, or page of at most 200 rows per event.

The 17 ordered phases disable Auth, delete private interactions and rate state, anonymize retained chants and comments, classify audit rows written by the user, write one non-identifying completion audit, delete Auth, and atomically delete profile plus job. Reachable generated operator actions retain detail under `deleted-operator`; reports and unknown actions lose their text. The disabled legacy merge detail is documented as a privacy re-enable gate rather than treated as safe generated text. The completion audit and phase advancement share one transaction, so duplicate delivery after advancement writes no second row. Page writes include the heartbeat; empty-page transitions compare the current phase transactionally. Duplicate delivery, missing Auth, and partial failure therefore retain forward-only recovery state.

`firestore.rules :: isNotBanned` and `isOperator` require both no job and an absent-or-false pending marker. The app gate checks both `UserProfile.deletionPending` and device-local deletion state before policy or Home. Unknown acknowledgement shows a persistent retry and Sign out surface; positive pending state advances local cleanup and shows the queued screen. Home's async deletion handlers verify that their widget is still mounted before any provider invalidation, so a late request failure cannot reach a disposed Consumer after the pending gate takes over. This protects already-issued credentials while Auth disable blocks new sign-in. There is no undo, progress dashboard, retained-job alert, or operator recovery console in v1.

## Seed pipeline and content integrity

Only `seed_data/clubs/arsenal.json` exists: 27 squad entries, 12 chants, and one chant with variations. The remaining clubs are still Andrew's content task.

Seeded chants use explicit club-prefixed IDs from source. `seed/chant_identity.ts :: findChantIdentityConflicts` refuses community ownership, wrong-Team collisions, and same normalized seeded titles at another ID. `upsertSeededChantInTransaction` repeats the ownership check at write time. `seed/seed_plan.ts` guarantees `--preflight-only` performs no sport, competition, or club write.

The seed updates only content allowlists and preserves engagement counters and ownership. It reports orphans but never deletes them. No service account file was read and no live preflight or write occurred in this review.

## CI and verification

Local verification on 2026-08-26:

| Check | Result |
|---|---|
| `flutter test --no-pub` | PASS, 356 tests on the post-interface correction branch |
| `flutter analyze --no-pub lib test` | PASS, no issues |
| `cd functions && npm test` | PASS, 78 tests |
| `cd seed && npm test` | PASS, 42 tests |
| `cd seed && npx tsc --noEmit` | PASS |
| `git diff --check` | PASS after the local correction |
| `cd test_rules && npx tsc --noEmit` | PASS |
| Java-backed Firestore emulator | PASS, 136 rules assertions |
| focused final closure regressions | RED before fix at both disposed-Consumer invalidations; PASS after fix, 19 app-gate tests including both late error classes |
| focused core-journey and inherited authority suites | RED before fix on immutable competition input; PASS, 24 tests after correction |
| focused Home hierarchy, route, enlarged-text, Songbook-entry, card, and inherited authority suites | PASS, including the inspected updated 390 by 844 Home golden |
| post-interface trust and empty-action regressions | RED before correction on false `RISING` and impossible `SHUFFLE`; PASS, 8 core-journey tests after correction |
| governance regression harness | RED before correction on a documentation path containing spaces; PASS after path, index, and error handling corrections |
| `flutter build ios --simulator --debug --no-pub` | RED on automatic mixed SwiftPM Firestore bridge sources; PASS on the project-pinned CocoaPods graph, producing `Runner.app` |
| scoped RunnerTests boundary | Runner and RunnerTests compile, embed, sign locally, and validate; CoreSimulator blocks before XCTest launch, so no assertion is claimed |
| final `main` GitHub Actions run `33012771517` at `9189c71` | Exact merged-head PASS: project governance, 353 Flutter tests, analysis, 78 Functions tests, 42 seed tests, and 136 rules assertions |

The earlier remediation first proved its affected boundaries red. The final closure also captures direct red evidence for both late deletion error classes after Home disposal, then passes those guards with the pending screen still authoritative. The interface block reproduced the immutable-list crash before correction. PR 15 run `33011415224` measured a 2.40 percent Linux Home render difference against a 2.20 percent golden ceiling while its other five jobs passed. After a 3.00 percent calibration, replacement run `33011936510` and exact-main run `33012771517` passed all six jobs. Independent review then proved that the broad comparator could absorb a missing trust word and that Home hardcoded Rising. The correction keeps 3.00 percent only for Home, restores 2.20 percent for competition and player, adds semantic trust assertions, and passes 356 local Flutter tests. Clean-runner evidence for the correction is pending.

The first independent review recorded that 46 of 142 Dart files would change. The current read-only `dart format --output=none --set-exit-if-changed lib test` check identifies 41 of 143 after intervening touched-file formatting and the two new Dart test files. It made no files writable because output was disabled. Formatting is not a CI gate today; this correction formats only its touched files and keeps the larger mechanical rewrite separate.

An attempted current npm production advisory audit was not completed. The sandboxed attempt could not reach the registry, and the elevated request was rejected because it would disclose the dependency manifest to the public npm advisory service without separate explicit authorization. Current advisory status is therefore unverified.

## Deployment, operations, and recovery

Repository configuration names one Firebase project, `chants-f95b4`, and no staging project. CI validates but does not deploy. Functions, rules, indexes, seed writes, store submission, and production observation remain manual owner actions.

Safe deployment order for the final deletion-aware stack is backward-compatible rules, Functions, then clients. Seed writes remain separate and must start with the read-only stable-identity preflight. No live environment was inspected, so the deployed order and current parity are unknown.

Recovery is uneven:

- A bad app release requires another store release.
- Rules and Functions can be redeployed from a reviewed compatible commit. `docs/RUNBOOK.md` now records the source-backed response and recovery boundary, while deployed parity still requires operator verification.
- Seeded canonical content is reproducible from reviewed JSON.
- User submissions and interaction data depend on unverified Firestore backup and point-in-time-recovery settings.
- `mergeChants` is not safely undoable from its partial audit payload and is now disabled after operator authorization. Its legacy payload also needs privacy redesign before re-enable.
- Account deletion has durable repository recovery, but no operational alert, dead-letter path, or operator console for a permanently retained job.

Crashlytics is wired, and `docs/RUNBOOK.md` now records first response and known recovery paths. There is still no repository-defined alerting, function-error dashboard, or deployment smoke test. App Check enforcement, billing alerts, backup settings, authentication templates, and live indexes are dashboard state that this review did not inspect.

## Where I most want your eyes

1. **The strict author-update boundary.** Review exact current-schema enforcement against any real legacy documents before rollout; legacy reads remain compatible, but invalid legacy documents cannot use direct author editing until normalized.
2. **Moderation and offline semantics.** Confirm on device that readable route fallback, Discover disappearance, Saved Songbook copies, and disabled live actions communicate their different authority clearly.
3. **Release configuration.** The real policy, Android build and release signing, App Check dashboard state, and device walk are release blockers even though the iOS simulator compile and automated suites are green.
4. **Remaining destructive workflow.** `mergeChants` is disabled because its implementation is sequential, partially audited, non-resumable, and retains authored source fields plus raw creator identity in its legacy audit detail. Account deletion is bounded and resumable, but retained-job operations still need production alerting.
5. **Scale boundaries.** Discover's full fetch and ground-truth counter scans need measured budgets before community volume makes linear reads material.

## Unverified

- Deployed rules, indexes, Functions, Firebase Auth settings, App Check enforcement, Crashlytics symbol upload, billing alerts, backup/PITR, and live data were not inspected.
- No live stable-ID preflight or seed write ran.
- No Android build succeeded locally because the Android SDK is unavailable. The iOS simulator app now compiles after pinning the project to CocoaPods; RunnerTests execution remains unverified because CoreSimulator rejected the app before XCTest spawned.
- No iPhone, Android, or iPad walkthrough ran in this review.
- Exact merged `main` at `9189c71` passed all six jobs in run `33012771517`, including project governance, 353 Flutter tests, analysis, Functions, seed, and 136 rules assertions. The local correction has no clean-runner result yet.
- Android release signing remains debug-only in the tracked configuration.
- The content policy remains placeholder copy.
- Dependency freshness and current security-advisory state are unverified.
- Formatter conformance is unverified as a passing repository gate; the current read-only check identified 41 of 143 files needing normalization.
