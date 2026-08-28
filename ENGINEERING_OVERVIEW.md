# Chants engineering overview

This is the current whole-project map for the launch-authentication worktree `codex/v1-auth-onboarding-android`, based on exact reviewed PR 17 correction head `8b457d8`. It includes the inherited creator platform, the accepted takedown correction, and the locally implemented V1 authentication, onboarding, and native-readiness block. It describes source reality, including inherited and unchanged systems. It is not a deployment claim, provider-configuration claim, or approval record.

The active approval contract is `docs/CHANGE_SPEC.md`. Completed reasoning is in the creator-platform, takedown-correction, and launch-authentication records under `docs/changes/`. Durable architectural choices are decisions 017 through 023. `docs/IMPLEMENTATION_RATIONALE.md` is the companion coverage ledger and verification record.

## Review outcome

Chants now has the intended two-part product rather than a catalogue alone:

1. A trusted football Songbook and words-first Chant Lab, where archive evidence remains distinct from community backing (`docs/decisions/004-songbook-and-chant-lab.md`).
2. A creator stage where fans publish manually approved short performances around a chant, compete on performance reach, follow creators, converse, and share public destinations (`lib/presentation/feed/chant_stage_screen.dart :: ChantStageScreen`; `functions/src/performance.ts :: handleSubmitPerformanceDraft`).

The implementation preserves the central trust boundary. A performance has its own status, media, creator, and popularity counters. It cannot mutate the attached chant's `canonical` or `community` state (`functions/src/performance.ts :: handleModeratePerformance`; `docs/decisions/018-performance-stage-and-admission.md`).

The inherited creator correction is exact-head clean-runner green at `8b457d8` in run `33190943182`. The final local launch block passes 454 Flutter tests, 142 Functions tests, 42 seed tests, zero-issue analysis, rules TypeScript compilation, an iOS simulator build, and native, governance, writing, and diff checks. The focused narrow-text test first reproduced and then closed a welcome-screen overflow. The local machine has no usable Java runtime or Android SDK, so the changed rules and first Android APK remain clean-runner gates. Exact-head CI, consolidated review, device walkthrough, provider setup, policy, production configuration, deployment, and release remain open.

## Product and navigation

`lib/presentation/auth/sign_in_screen.dart :: SignInScreen` introduces Watch, Learn, and Create before credentials. Apple, Google, and email are primary when configured. Facebook and phone live under More, and magic link lives inside email. `AuthFeatureConfig` defaults every new provider off so incomplete external configuration does not create a visible dead end.

`lib/app/app.dart :: _SignedInGate` enforces account deletion first, then verified identity, recoverable missing-profile onboarding, current policy, and the product shell. Accepted accounts enter `lib/presentation/shell/app_shell.dart :: AppShell`, which keeps five destinations mounted after first visit: Feed, Clubs, Create, Songbook, and You.

Feed is `lib/presentation/feed/chant_stage_screen.dart :: ChantStageScreen`. Clubs preserves the inherited competition, team, player, Songbook, and Chant Lab routes. Create exposes both words-first chant submission and the performance path through `lib/presentation/create/create_hub_screen.dart :: CreateHubScreen`. Songbook retains the device-local matchday library. You owns creator identity, private draft activity, notifications, policy, feedback, blocking, operator moderation, sign out, and account deletion (`lib/presentation/profile/creator_profile_screen.dart :: CreatorProfileScreen`; `lib/presentation/settings/account_actions_menu.dart :: AccountActionsMenu`).

Routing remains Navigator-based. `MagicLinkGate` wraps the navigator so an initial or resumed HTTPS email link can complete without bypassing the account gate. The native auth path is declared for Apple and Android, but no production domain association is claimed.

## Authentication and initial profile authority

Firebase Auth owns the stable UID, credential, verification, and linked-provider set. `functions/src/safety_submission.ts :: requireVerifiedUid`, `firestore.rules :: hasVerifiedContact`, and `storage.rules :: hasVerifiedContact` accept verified email, verified phone, or current or linked Apple, Google, or Facebook identity. The Flutter gate mirrors this from the current Firebase user only for navigation. An unverified password account can read recovery state but cannot create its profile or perform protected writes.

`functions/src/onboarding.ts :: handleCompleteOnboarding` accepts only display name, confirmed 17-plus, and current-policy consent. It derives UID and verified authority from callable auth and transactionally creates the private profile plus deterministic policy audit. Duplicate completion leaves existing coherent state unchanged. Direct profile create is denied. The birth date is used only by `OnboardingScreen` for the local age calculation and is not persisted or transmitted.

`AuthRepository` supports email and password, Apple, Google, Facebook, magic email link, and phone, plus deliberate same-UID linking. `SignInMethodsScreen` refuses unlinking the final method. Credential collision never starts an app-level merge. `MagicLinkStore` retains only email, request time, and optional current UID in one versioned device record for up to one hour. Phone UI discloses Google processing, guards resend, and uses one credential claim across manual entry, Android auto-verification, and resends. Leaving the screen invalidates any later unused automatic credential.

Provider code is not provider readiness. Firebase console enablement, Apple and Google identifiers, Meta callback and deletion configuration, SMS regions and quota, APNs or Android fingerprints, hosted association files, App Check, branding review, and real-device proof remain external gates. A provider button stays absent until an operator intentionally supplies the matching build flag.

## Creator identity

Private authority remains in `profiles/{uid}`. Public creator identity lives in `creatorProfiles/{uid}` and contains only handle, public display name, optional bio, visibility, timestamps, and server-owned aggregates (`functions/src/creator_profile.ts :: handleUpdateCreatorProfile`; `firestore.rules :: match /creatorProfiles/{userId}`).

Normalized handle ownership lives in server-only `creatorHandles/{handle}`. `handleUpdateCreatorProfile` reserves, renames, and releases handles in one transaction while preserving server counters. A banned, stale-policy, under-age, missing, or deletion-pending account cannot write identity (`functions/src/creator_profile.ts :: handleUpdateCreatorProfile`).

`lib/presentation/profile/public_creator_profile_screen.dart :: PublicCreatorProfileScreen` shows the public allowlist, aggregate totals, recent approved performances, Follow, Share, Report, and confirmed Block. It does not expose private account fields. Firestore exact-ID gets and public HTTP reads separately check current private account activity so a ban or deletion closes the public surface. Public creator collection listing is denied because V1 has no creator directory and a list query cannot safely prove private account authority for every result.

## Performance admission and media

A performance starts as a private draft. `functions/src/performance.ts :: handleCreatePerformanceDraft` verifies active account, visible creator, and visible chant before issuing the exact staging identity. `storage.rules :: match /performance-staging/{uid}/{draftId}/source` allows only the owner, exact draft path, supported video content type, and bounded object size.

`lib/presentation/create/perform_chant_screen.dart :: PerformChantScreen` uses `lib/data/services/performance_media_selection.dart` to record through the camera or choose from the device library. The selected MP4, MOV, or M4V must be no longer than 30 seconds and no larger than 50 MiB. `lib/data/repositories/performance_draft_repository.dart :: PerformanceDraftRepository` exposes progress, cancellation, retry, submit, and owner draft playback.

`functions/src/performance.ts :: handleSubmitPerformanceDraft` verifies trusted Storage metadata before moving a draft to pending review. `handleModeratePerformance` is active-operator only. Approval produces the parser-safe public `performances/{id}` projection and public media identity. Rejection and cancellation remain private. `cleanupDeletedPerformanceDraft` provides the server cleanup hook for deleted drafts.

Public client reads require an approved, visible performance with exact schema, `sourceCreatorVisible`, `sourceChantVisible`, and matching query predicates (`firestore.rules :: match /performances/{performanceId}`). Firebase client reads of `performance-media` are denied (`storage.rules :: match /performance-media/{performanceId}/source`). In-app playback calls `functions/src/performance.ts :: handleResolvePerformancePlayback`, which rechecks current actor, creator account, creator deletion job, public creator, chant, performance, and block authority before signing a short URL. Active operators have one narrow preview exception for approved, nonremoved hidden media.

## Chant Stage and popularity

`lib/data/repositories/performance_repository.dart :: PerformanceRepository` pages at ten records through Rising, New, Terrace, and Following. Every query includes both source-eligibility predicates. Rising is a transparent recent popularity order. New is chronological. Terrace requires the underlying chant snapshot to be canonical. Following queries no more than the 30 most recent followed creator IDs and falls back to Rising with written disclosure when the graph is empty or unavailable.

`lib/presentation/feed/chant_stage_screen.dart :: PerformanceCard` uses a 4:5 media area and retains creator, chant title, club or player, trust, lyrics, and popularity. Stage watches the viewer's block set, fails closed while that preference is unavailable, removes blocked creators immediately, and exposes a confirmed Block action. `lib/presentation/feed/performance_video_player.dart :: PerformanceVideoPlayer` never autoplays or prefetches. It records a qualified view only after three seconds of playback.

`functions/src/performance_source.ts` owns source visibility and exact creator performance totals. Creator or chant changes reconcile dependent performance flags; chant changes also reconcile title and trust status. Every dependent update reads current source within its projection transaction, so overlapping or reordered triggers retry to current truth. Because fan-out is asynchronous, server actions and public handlers still read current source truth. Approval retains its idempotent immediate count update, and lifecycle triggers reconstruct `performanceCount` from live rows in a creator-profile transaction so later hide, restore, removal, ban, or chant changes converge.

Likes, qualified views, unique shares, and performance comments are deterministic per-account records (`functions/src/performance.ts :: interactionId`; `handleSetPerformanceLike`; `handleRecordQualifiedPerformanceView`; `handleRecordPerformanceShare`). Their triggers recompute parent totals from source rows (`recomputePerformanceInteractionCounts`; `recomputePerformanceShareCounts`). The weekly label appears only for a real winner with a positive unique-share count; likes and qualified views break ties (`functions/src/performance.ts :: performanceRankingWeek`; `lib/presentation/feed/chant_stage_screen.dart :: ChantStageScreen`).

These are performance popularity signals. `Back it` still ranks the underlying Chant Lab idea. Only evidence plus operator trust action can move a user chant into Terrace Proven (`functions/src/chant_trust.ts`; decision 009).

## Follows, activity, and conversation

Follow edges are private deterministic documents. `functions/src/creator_follow.ts :: handleSetCreatorFollow` rechecks both active accounts, target creator visibility, self-follow, and both block directions. `recomputeCreatorFollowCounts` updates only public aggregate totals. `firestore.rules :: match /creatorFollows/{followId}` lets a follower read their own edges and denies direct writes.

`functions/src/performance.ts :: handleCreatePerformanceComment` accepts a current visible performance, validates same-target parent and root identity, caps stored depth at 50, blocks cycles, resolves up to five normalized handles, and suppresses blocked or deletion-pending fan-out. Reply notification wins over duplicate mention delivery where both target the same recipient.

`lib/presentation/feed/performance_comments_sheet.dart :: PerformanceCommentsSheet` caps visual indentation at three levels and opens deeper branches through `_FocusedPerformanceThread`. `lib/presentation/profile/creator_notifications_screen.dart :: CreatorNotificationsScreen` distinguishes follow, mention, and reply. Follow opens the current public creator. Mention and reply fetch the current visible performance and highlight the referenced comment. The inbox stays recipient-only (`firestore.rules :: match /creatorNotifications/{notificationId}`).

Legacy chant comments remain one direct reply level under decision 002. The deeper model is intentionally scoped to performance conversation.

## Public destinations

`functions/src/public_share.ts :: handleResolvePublicShareDestination` returns only an HTTPS Chants URL for a current visible chant, performance, or creator. Performance and creator destinations recheck current private creator activity as well as public projection state; performances also recheck the current chant. `resolvePublicPage` creates the server-rendered destination. User text is escaped; metadata is bounded; lyrics, private UIDs, report state, and raw Storage paths are omitted. Hidden, removed, source-ineligible, banned, deleting, missing, and malformed targets use the same 404 page.

`functions/src/index.ts :: publicSharePage` serves `/chants/**`, `/performances/**`, and `/creators/**` through Firebase Hosting rewrites (`firebase.json :: hosting.rewrites`). Performance pages use a controlled, non-autoplay video source at `/media/performances/{id}`. `publicPerformanceMedia` calls `handleResolvePublicPerformanceMedia`, rechecks the exact visible projection and media path, then issues a no-store redirect to a two-minute signed URL.

`lib/data/repositories/public_share_repository.dart :: PublicShareRepository` gives the client the current server destination before native sharing. Native universal links, Android App Links, store fallback, domain association, and production IAM signing remain configuration gates because their identifiers and deployed state are not available in source.

## Reports, blocks, and moderation

`functions/src/safety_submission.ts :: handleSubmitReport` now recognizes performance and performance-comment targets while preserving authenticated callable admission, deterministic reporter-target identity, atomic rate limits, and server-owned report fields. Direct report writes remain denied (`firestore.rules :: match /performanceReports/{reportId}`; `match /performanceCommentReports/{reportId}`).

`lib/presentation/report/report_sheet.dart :: ReportSheet` supports chant, chant comment, user, performance, and performance-comment reporting. Stage, comments, and public creator surfaces expose Report and Block without granting authority through UI visibility.

`functions/src/published_performance_moderation.ts :: handlePublishedPerformanceModeration` reauthorizes active operators, supports dismiss, hide, remove, and restore, resolves relevant reports, and writes audit. Terminal performance removal also creates deterministic `performanceMediaDeletionJobs/{performanceId}` work bound to the exact published object. `functions/src/index.ts :: onPerformanceMediaDeletionJobWritten` deletes that object idempotently and acknowledges the job only after cleanup. `lib/presentation/moderation/moderation_screen.dart :: ModerationScreen` adds Reported media and Hidden queues with Videos and Comments scope. Eligible hidden rows expose Preview, Restore, and Remove. Operators may inspect blocked or source-ineligible approved media for moderation; ordinary social action still respects the authority boundary.

Manual pre-publication review is the V1 safety model. No automated provider-scale media screening exists. Policy wording, queue response target, staffing, and escalation remain launch work.

## Durable account deletion

The inherited deletion system remains a durable, bounded, retryable worker (`functions/src/account_deletion.ts :: processAccountDeletionStep`). The phase list now includes creator handles and profiles, performance drafts, private interaction records, both follow directions, notifications, new report collections, and retained public creator attribution.

New actions check the private pending job as well as profile state before mutation. The client still prepares local Songbook deletion before requesting remote deletion and preserves unknown acknowledgement across relaunch (`lib/data/services/account_deletion_service.dart`; `lib/presentation/auth/account_deletion_recovery_screen.dart`).

Retained public content follows the existing privacy decisions: active public creator linkage is removed, user-authored report material is redacted, and trusted operator provenance is retained only through the reviewed allowlist. No repository-backed data export, backup restoration, or retention schedule exists.

## Inherited Songbook, Chant Lab, and seed system

The creator expansion does not replace the established chant model. Canonical content remains Terrace Proven; community content remains Chant Lab. Submission origin, optional external evidence, promotion requirements, stable seeded IDs, live current-authority checks, cache-readable but non-actionable fallback, one-level chant comments, votes, reports, blocking, Saved Matchday Songbook, and disabled merge behavior remain as recorded in decisions 003 through 016.

The seed pipeline still validates explicit chant identity and content shape before Admin writes (`seed/validate.ts`; `seed/chant_identity.ts`; `seed/seed_plan.ts`). Only Arsenal JSON is packaged in source. Remaining club lyrics and context must be externally sourced and manually verified. No live preflight or seed write was authorized in this change.

## CI, dependencies, and native status

`.github/workflows/ci.yml` runs governance, full Flutter tests, full analysis with a deterministic non-secret Firebase fixture, Functions, seed, and Firestore plus Storage emulators. It now also builds an Android debug APK and iOS simulator app from obvious non-secret compile fixtures. Android CI inspects `com.chants.chants`, records the APK digest, and retains the artifact. iOS CI inspects the same bundle ID. The governance job fetches complete history and runs `scripts/check-project-memory.sh --range <base>`, so implementation changes must carry `docs/EXECUTION.md` in the same PR or push range.

The auth client adds Google Sign-In, Facebook Auth, app links, and shared preferences. FlutterFire resolves as one current graph in `pubspec.lock`; iOS resolves 18 direct dependencies and 56 total pods against Firebase iOS 12.18. Google Sign-In 9.2 moves `GTMSessionFetcher` from 5.3.1 to compatible 3.5.0. CocoaPods warns that its Firebase distribution will stop receiving new versions after October 2026, but the repository intentionally remains CocoaPods-owned under the existing native decision. A future dependency-manager migration requires its own compatibility block.

Android declares Internet access, uses the Chants label, owns the approved auth and public HTTPS paths, and refuses debug signing for release, including when an aggregate Gradle task reaches a release task indirectly. The local machine has no Android SDK, so the new clean runner owns first compile proof. iOS Runner carries Sign in with Apple plus auth and public-domain entitlements. The final local source builds a simulator `Runner.app` with bundle ID `com.chants.chants`; this does not prove provider or distribution readiness.

## Deployment, cost, and recovery

CI verifies and does not deploy. The source names one Firebase project and no staging environment. No public Function, Hosting route, rule, index, Storage rule, or client has been deployed by this work.

Performance read and upload surfaces have explicit limits: ten-record feed pages, 30-second and 50-MiB uploads, no autoplay or prefetch, one deterministic ranking contribution per account, short playback URLs, and manual approval. Creator and chant source fan-out plus exact aggregate reconstruction are not globally bounded and have no measured production budget. Production read, write, signing, storage, moderation, cleanup, and egress measurements do not exist.

The compatible rollout order is Firestore and Storage rules, Functions, Hosting, then client. Before rollout, verify URL-signing IAM, domain and app associations, store destinations, App Check, billing and Function alerts, staged-media cleanup, moderation staffing, privacy and content policy, and deployed parity. Recovery can pause admission while keeping Songbook and words-only Chant Lab available.

## Where I most want your eyes

1. `functions/src/onboarding.ts`, `requireVerifiedUid`, and both rules implementations for inconsistent email, phone, current-provider, or linked-provider authority.
2. `lib/app/app.dart`, `MagicLinkGate`, and `SignInMethodsScreen` for deletion precedence, stale Firebase user state, cross-account links, collision, or last-method holes.
3. `AuthRepository` phone callbacks and magic-link local binding for duplicate credential use, stale screens, replay, expiry, or unrelated-account replacement.
4. Android Gradle signing, both native link declarations, non-secret fixtures, and the two new native CI jobs for false readiness claims.
5. `functions/src/performance_source.ts` and performance media-deletion work for inherited stale projection, aggregate, or retry holes.
6. Firestore and Storage rules for parser-safe public projections and path substitution.
7. `.github/workflows/ci.yml` and the project-memory and native governance scripts for range and source-contract correctness.

## Unverified

- Full launch-block clean-runner CI and the consolidated independent review.
- The first Android clean-runner APK and exact application-ID evidence.
- Apple, Google, Facebook, magic-link, and phone dashboard, credential, callback, domain, privacy, quota, anti-abuse, and real-device behavior. Every provider remains disabled until its own gates pass.
- Camera and library permissions, upload progress, backgrounding, retry, cancellation, playback, share destinations, Following, notifications, deep comments, moderation, blocking, deletion, accessibility, and offline behavior on real devices.
- `chantsfc.com` Hosting deployment, DNS, domain association, social crawler output, app/store routing, and URL-signing IAM.
- Production App Check, alerts, billing controls, staged-object cleanup, moderation response time, backup or restore, data export, and deployed parity.
- Final content policy, privacy policy, terms, media rules, signing, store metadata, seed completion, and release.
