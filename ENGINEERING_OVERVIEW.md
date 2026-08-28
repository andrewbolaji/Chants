# Chants engineering overview

This is the current whole-project map for the packaged creator-platform implementation on `codex/v1-creator-platform-foundation`, based on merged `main` at `86603c22fbd7647f89c9276af9a60a0b3d63113b`. The reviewed implementation boundary is `86603c22...641281e` in draft PR 17. It describes source reality, including inherited and unchanged systems. It is not a deployment claim or an approval record.

The active approval contract is `docs/CHANGE_SPEC.md`. Completed change reasoning is in `docs/changes/2026-08-27-creator-platform-foundation.md`. Durable architectural choices are decisions 017 through 021. `docs/IMPLEMENTATION_RATIONALE.md` is the companion coverage ledger and verification record.

## Review outcome

Chants now has the intended two-part product rather than a catalogue alone:

1. A trusted football Songbook and words-first Chant Lab, where archive evidence remains distinct from community backing (`docs/decisions/004-songbook-and-chant-lab.md`).
2. A creator stage where fans publish manually approved short performances around a chant, compete on performance reach, follow creators, converse, and share public destinations (`lib/presentation/feed/chant_stage_screen.dart :: ChantStageScreen`; `functions/src/performance.ts :: handleSubmitPerformanceDraft`).

The implementation preserves the central trust boundary. A performance has its own status, media, creator, and popularity counters. It cannot mutate the attached chant's `canonical` or `community` state (`functions/src/performance.ts :: handleModeratePerformance`; `docs/decisions/018-performance-stage-and-admission.md`).

The local automated matrix is green: 415 Flutter tests, 122 Cloud Functions tests, 157 Firestore and Storage emulator assertions, 42 seed tests, full Flutter analysis exit 0, and project-governance regressions. Replacement clean-runner run `33181165940` passed all six jobs at implementation head `641281e`, including zero-issue analysis on Flutter 3.47.2 and the complete 415-test Flutter suite. The iOS CocoaPods graph resolves on Firebase iOS 12.18, but the full Xcode compile did not complete within the bounded local attempt. Android compilation is blocked by the absent SDK. One independent Claude review, both native builds, the combined device walkthrough, policy, production configuration, deployment, and release remain open (`docs/EXECUTION.md :: 2026-08-28 creator platform entry`).

## Product and navigation

`lib/app/app.dart :: _SignedInGate` still enforces account-deletion and content-policy state before the signed-in product. Accepted accounts enter `lib/presentation/shell/app_shell.dart :: AppShell`, which keeps five destinations mounted after first visit: Feed, Clubs, Create, Songbook, and You.

Feed is `lib/presentation/feed/chant_stage_screen.dart :: ChantStageScreen`. Clubs preserves the inherited competition, team, player, Songbook, and Chant Lab routes. Create exposes both words-first chant submission and the performance path through `lib/presentation/create/create_hub_screen.dart :: CreateHubScreen`. Songbook retains the device-local matchday library. You owns creator identity, private draft activity, notifications, policy, feedback, blocking, operator moderation, sign out, and account deletion (`lib/presentation/profile/creator_profile_screen.dart :: CreatorProfileScreen`; `lib/presentation/settings/account_actions_menu.dart :: AccountActionsMenu`).

Routing remains Navigator-based and preserves the existing policy and lifecycle gates (`lib/app/router.dart`; `lib/app/app.dart`). No production deep-link association is claimed.

## Creator identity

Private authority remains in `profiles/{uid}`. Public creator identity lives in `creatorProfiles/{uid}` and contains only handle, public display name, optional bio, visibility, timestamps, and server-owned aggregates (`functions/src/creator_profile.ts :: handleUpdateCreatorProfile`; `firestore.rules :: match /creatorProfiles/{userId}`).

Normalized handle ownership lives in server-only `creatorHandles/{handle}`. `handleUpdateCreatorProfile` reserves, renames, and releases handles in one transaction while preserving server counters. A banned, stale-policy, under-age, missing, or deletion-pending account cannot write identity (`functions/src/creator_profile.ts :: handleUpdateCreatorProfile`).

`lib/presentation/profile/public_creator_profile_screen.dart :: PublicCreatorProfileScreen` shows the public allowlist, aggregate totals, recent approved performances, Follow, Share, and Report. It does not read private account fields.

## Performance admission and media

A performance starts as a private draft. `functions/src/performance.ts :: handleCreatePerformanceDraft` verifies active account, visible creator, and visible chant before issuing the exact staging identity. `storage.rules :: match /performance-staging/{uid}/{draftId}/source` allows only the owner, exact draft path, supported video content type, and bounded object size.

`lib/presentation/create/perform_chant_screen.dart :: PerformChantScreen` uses `lib/data/services/performance_media_selection.dart` to record through the camera or choose from the device library. The selected MP4, MOV, or M4V must be no longer than 30 seconds and no larger than 50 MiB. `lib/data/repositories/performance_draft_repository.dart :: PerformanceDraftRepository` exposes progress, cancellation, retry, submit, and owner draft playback.

`functions/src/performance.ts :: handleSubmitPerformanceDraft` verifies trusted Storage metadata before moving a draft to pending review. `handleModeratePerformance` is active-operator only. Approval produces the parser-safe public `performances/{id}` projection and public media identity. Rejection and cancellation remain private. `cleanupDeletedPerformanceDraft` provides the server cleanup hook for deleted drafts.

Public client reads require an approved, visible performance with exact schema and query predicates (`firestore.rules :: match /performances/{performanceId}`). Firebase client reads of `performance-media` are denied (`storage.rules :: match /performance-media/{performanceId}/source`). In-app playback calls `functions/src/performance.ts :: handleResolvePerformancePlayback`, which rechecks current performance and block authority before signing a short URL.

## Chant Stage and popularity

`lib/data/repositories/performance_repository.dart :: PerformanceRepository` pages at ten records through Rising, New, Terrace, and Following. Rising is a transparent recent popularity order. New is chronological. Terrace requires the underlying chant snapshot to be canonical. Following queries no more than the 30 most recent followed creator IDs and falls back to Rising with written disclosure when the graph is empty or unavailable.

`lib/presentation/feed/chant_stage_screen.dart :: PerformanceCard` uses a 4:5 media area and retains creator, chant title, club or player, trust, lyrics, and popularity. `lib/presentation/feed/performance_video_player.dart :: PerformanceVideoPlayer` never autoplays or prefetches. It records a qualified view only after three seconds of playback.

Likes, qualified views, unique shares, and performance comments are deterministic per-account records (`functions/src/performance.ts :: interactionId`; `handleSetPerformanceLike`; `handleRecordQualifiedPerformanceView`; `handleRecordPerformanceShare`). Their triggers recompute parent totals from source rows (`recomputePerformanceInteractionCounts`; `recomputePerformanceShareCounts`). The weekly label appears only for a real winner with a positive unique-share count; likes and qualified views break ties (`functions/src/performance.ts :: performanceRankingWeek`; `lib/presentation/feed/chant_stage_screen.dart :: ChantStageScreen`).

These are performance popularity signals. `Back it` still ranks the underlying Chant Lab idea. Only evidence plus operator trust action can move a user chant into Terrace Proven (`functions/src/chant_trust.ts`; decision 009).

## Follows, activity, and conversation

Follow edges are private deterministic documents. `functions/src/creator_follow.ts :: handleSetCreatorFollow` rechecks both active accounts, target creator visibility, self-follow, and both block directions. `recomputeCreatorFollowCounts` updates only public aggregate totals. `firestore.rules :: match /creatorFollows/{followId}` lets a follower read their own edges and denies direct writes.

`functions/src/performance.ts :: handleCreatePerformanceComment` accepts a current visible performance, validates same-target parent and root identity, caps stored depth at 50, blocks cycles, resolves up to five normalized handles, and suppresses blocked or deletion-pending fan-out. Reply notification wins over duplicate mention delivery where both target the same recipient.

`lib/presentation/feed/performance_comments_sheet.dart :: PerformanceCommentsSheet` caps visual indentation at three levels and opens deeper branches through `_FocusedPerformanceThread`. `lib/presentation/profile/creator_notifications_screen.dart :: CreatorNotificationsScreen` distinguishes follow, mention, and reply. Follow opens the current public creator. Mention and reply fetch the current visible performance and highlight the referenced comment. The inbox stays recipient-only (`firestore.rules :: match /creatorNotifications/{notificationId}`).

Legacy chant comments remain one direct reply level under decision 002. The deeper model is intentionally scoped to performance conversation.

## Public destinations

`functions/src/public_share.ts :: handleResolvePublicShareDestination` returns only an HTTPS Chants URL for a current visible chant, performance, or creator. `resolvePublicPage` creates the server-rendered destination. User text is escaped; metadata is bounded; lyrics, private UIDs, report state, and raw Storage paths are omitted. Hidden, removed, missing, and malformed targets use the same 404 page.

`functions/src/index.ts :: publicSharePage` serves `/chants/**`, `/performances/**`, and `/creators/**` through Firebase Hosting rewrites (`firebase.json :: hosting.rewrites`). Performance pages use a controlled, non-autoplay video source at `/media/performances/{id}`. `publicPerformanceMedia` calls `handleResolvePublicPerformanceMedia`, rechecks the exact visible projection and media path, then issues a no-store redirect to a two-minute signed URL.

`lib/data/repositories/public_share_repository.dart :: PublicShareRepository` gives the client the current server destination before native sharing. Native universal links, Android App Links, store fallback, domain association, and production IAM signing remain configuration gates because their identifiers and deployed state are not available in source.

## Reports, blocks, and moderation

`functions/src/safety_submission.ts :: handleSubmitReport` now recognizes performance and performance-comment targets while preserving authenticated callable admission, deterministic reporter-target identity, atomic rate limits, and server-owned report fields. Direct report writes remain denied (`firestore.rules :: match /performanceReports/{reportId}`; `match /performanceCommentReports/{reportId}`).

`lib/presentation/report/report_sheet.dart :: ReportSheet` supports chant, chant comment, user, performance, and performance-comment reporting. Stage, comments, and public creator surfaces expose Report and Block without granting authority through UI visibility.

`functions/src/published_performance_moderation.ts :: handlePublishedPerformanceModeration` reauthorizes active operators, supports dismiss, hide, remove, and restore, resolves relevant reports, and writes audit. `lib/presentation/moderation/moderation_screen.dart :: ModerationScreen` adds Reported media and Hidden queues with Videos and Comments scope. Operators may inspect blocked creator media for moderation; ordinary social action still respects the block boundary.

Manual pre-publication review is the V1 safety model. No automated provider-scale media screening exists. Policy wording, queue response target, staffing, and escalation remain launch work.

## Durable account deletion

The inherited deletion system remains a durable, bounded, retryable worker (`functions/src/account_deletion.ts :: processAccountDeletionStep`). The phase list now includes creator handles and profiles, performance drafts, private interaction records, both follow directions, notifications, new report collections, and retained public creator attribution.

New actions check the private pending job as well as profile state before mutation. The client still prepares local Songbook deletion before requesting remote deletion and preserves unknown acknowledgement across relaunch (`lib/data/services/account_deletion_service.dart`; `lib/presentation/auth/account_deletion_recovery_screen.dart`).

Retained public content follows the existing privacy decisions: active public creator linkage is removed, user-authored report material is redacted, and trusted operator provenance is retained only through the reviewed allowlist. No repository-backed data export, backup restoration, or retention schedule exists.

## Inherited Songbook, Chant Lab, and seed system

The creator expansion does not replace the established chant model. Canonical content remains Terrace Proven; community content remains Chant Lab. Submission origin, optional external evidence, promotion requirements, stable seeded IDs, live current-authority checks, cache-readable but non-actionable fallback, one-level chant comments, votes, reports, blocking, Saved Matchday Songbook, and disabled merge behavior remain as recorded in decisions 003 through 016.

The seed pipeline still validates explicit chant identity and content shape before Admin writes (`seed/validate.ts`; `seed/chant_identity.ts`; `seed/seed_plan.ts`). Only Arsenal JSON is packaged in source. Remaining club lyrics and context must be externally sourced and manually verified. No live preflight or seed write was authorized in this change.

## CI, dependencies, and native status

`.github/workflows/ci.yml` runs governance, full Flutter tests, full analysis with a deterministic non-secret Firebase fixture, Functions, seed, and Firestore plus Storage emulators. The governance job fetches complete history and runs `scripts/check-project-memory.sh --range <base>`, so implementation changes must carry `docs/EXECUTION.md` in the same PR or push range. `scripts/test-project-governance.sh` proves both staged and range modes.

The client adds Firebase Storage, image picker, and video player dependencies (`pubspec.yaml`). FlutterFire resolves as one current graph in `pubspec.lock`; iOS resolves all FlutterFire pods against Firebase iOS 12.18 in `ios/Podfile.lock`. CocoaPods warns that its Firebase distribution will stop receiving new versions after October 2026, but the repository intentionally remains CocoaPods-owned under the existing native decision. A future dependency-manager migration requires its own compatibility block.

The local Xcode build entered compilation after successful pod resolution but was terminated after an extended silent wait. Android compilation cannot start because no Android SDK is installed. Neither result is presented as application-source failure or native success.

## Deployment, cost, and recovery

CI verifies and does not deploy. The source names one Firebase project and no staging environment. No public Function, Hosting route, rule, index, Storage rule, or client has been deployed by this work.

Performance cost is bounded in source by ten-record feed pages, 30-second and 50-MiB upload limits, no autoplay, no prefetch, one deterministic ranking contribution per account, short playback URLs, and manual approval. Production read, write, signing, storage, moderation, and egress measurements do not exist.

The compatible rollout order is Firestore and Storage rules, Functions, Hosting, then client. Before rollout, verify URL-signing IAM, domain and app associations, store destinations, App Check, billing and Function alerts, staged-media cleanup, moderation staffing, privacy and content policy, and deployed parity. Recovery can pause admission while keeping Songbook and words-only Chant Lab available.

## Where I most want your eyes

1. `functions/src/performance.ts :: handleSubmitPerformanceDraft`, `handleModeratePerformance`, and interaction recomputation for overlap, idempotence, and media lifecycle holes.
2. `firestore.rules :: validPerformance`, `validPerformanceComment`, and the query predicates for parser-safe public projections.
3. `storage.rules :: performance-staging` plus `functions/src/public_share.ts :: handleResolvePublicPerformanceMedia` for path substitution or stale-authority leakage.
4. `functions/src/creator_follow.ts` and performance mention fan-out for block, deletion, duplicate, and graph-privacy failures.
5. `functions/src/published_performance_moderation.ts` and the new deletion phases for partial failure, restoration, audit, or retention mistakes.
6. `lib/presentation/feed/chant_stage_screen.dart` and `performance_comments_sheet.dart` for popularity wording, deep-thread context, large text, and stale navigation.
7. `.github/workflows/ci.yml` and `scripts/check-project-memory.sh` for PR-range correctness on push and pull-request events.

## Unverified

- The requested independent Claude review of `86603c22...641281e`.
- Completed iOS and Android native builds for the creator-platform graph.
- Camera and library permissions, upload progress, backgrounding, retry, cancellation, playback, share destinations, Following, notifications, deep comments, moderation, blocking, deletion, accessibility, and offline behavior on real devices.
- `chantsfc.com` Hosting deployment, DNS, domain association, social crawler output, app/store routing, and URL-signing IAM.
- Production App Check, alerts, billing controls, staged-object cleanup, moderation response time, backup or restore, data export, and deployed parity.
- Final content policy, privacy policy, terms, media rules, signing, store metadata, seed completion, and release.
