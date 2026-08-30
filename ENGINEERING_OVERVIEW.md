# Chants engineering overview

This is the current whole-project map through merged PR 24 at `83711bc` plus the approved V1 backend rollout readiness block. It includes inherited and unchanged systems and is not a deployment or release-readiness claim. The 2026-08-30 read-only inventory below explicitly separates current source from the actual July deployment.

The active approval contract is `docs/CHANGE_SPEC.md`. Completed reasoning is in the creator-platform, takedown-correction, launch-authentication, post-auth correction, final minor closure, and V1 launch-services records under `docs/changes/`. Durable architectural choices now run through decision 025. `docs/IMPLEMENTATION_RATIONALE.md` is the companion coverage ledger and verification record.

## Review outcome

Chants now has two core product surfaces plus a maintenance loop rather than a catalogue alone:

1. A trusted football Songbook and words-first Chant Lab, where archive evidence remains distinct from community backing (`docs/decisions/004-songbook-and-chant-lab.md`).
2. A creator stage where fans publish manually approved short performances around a chant, compete on performance reach, follow creators, converse, and share public destinations (`lib/presentation/feed/chant_stage_screen.dart :: ChantStageScreen`; `functions/src/performance.ts :: handleSubmitPerformanceDraft`).
3. A private Living Songbook loop where supporters propose a correction, another real version, or public proof; operators review the exact source version; and accepted evidence can move a user chant to Terrace Proven without confusing popularity with proof (`functions/src/living_songbook.ts`; decision 025).

The implementation preserves the central trust boundary. A performance has its own status, media, creator, and popularity counters. It cannot mutate the attached chant's `canonical` or `community` state (`functions/src/performance.ts :: handleModeratePerformance`; `docs/decisions/018-performance-stage-and-admission.md`).

Post-auth correction commit `6002724` passed all eight jobs in run `33213537910`. PR 18 then merged into PR 17 at byte-identical head `5350b8a`, whose run `33215692105` passed the combined source. The final independent review declared that head clear for source freeze and found only the two minor findings closed by implementation commit `e1474ad`. Exact implementation run `33254213575` and documentation-head run `33255542646` each passed all eight jobs. PR 17 merged as `e8f2591`, and run `33256843751` passed 463 Flutter tests, 142 Functions tests, 42 seed tests, 165 Java-backed Firestore and Storage cases, project governance, analysis, and both native compile and identity checks. Documentation-only PR 19 merged as `9c6286a` after all eight jobs passed. The launch-services range adds source and selected reversible console settings; device walkthrough, remaining provider setup, policy text, deployment, and release remain open.

## Product and navigation

`lib/presentation/auth/sign_in_screen.dart :: SignInScreen` introduces Watch, Learn, and Create before credentials. Apple, Google, and email are primary when configured. Facebook and phone live under More, and magic link lives inside email. `AuthFeatureConfig` defaults every new provider off so incomplete external configuration does not create a visible dead end.

`lib/app/app.dart :: _SignedInGate` enforces account deletion first, then verified identity, recoverable missing-profile onboarding, current policy, and the product shell. Accepted accounts enter `lib/presentation/shell/app_shell.dart :: AppShell`, which keeps five destinations mounted after first visit: Feed, Clubs, Create, Songbook, and You.

Feed is `lib/presentation/feed/chant_stage_screen.dart :: ChantStageScreen`. Clubs preserves the inherited competition, team, player, Songbook, and Chant Lab routes. Create exposes both words-first chant submission and the performance path through `lib/presentation/create/create_hub_screen.dart :: CreateHubScreen`. Songbook retains the device-local matchday library. You owns creator identity, private draft activity, notifications, policy, feedback, blocking, operator moderation, sign out, and account deletion (`lib/presentation/profile/creator_profile_screen.dart :: CreatorProfileScreen`; `lib/presentation/settings/account_actions_menu.dart :: AccountActionsMenu`).

Routing remains Navigator-based. `MagicLinkGate` wraps the navigator so an initial or resumed HTTPS email link can complete without bypassing the account gate. The native auth path is declared for Apple and Android. The launch-services block adds an exact Apple association file and live Firebase Auth authorization for `chantsfc.com` and `auth.chantsfc.com`; Hosting deployment, DNS routing, CDN pickup, Android Asset Links, and device opening remain unverified.

## Authentication and initial profile authority

Firebase Auth owns the stable UID, credential, verification, and linked-provider set. `functions/src/safety_submission.ts :: requireVerifiedUid`, `firestore.rules :: hasVerifiedContact`, and `storage.rules :: hasVerifiedContact` accept verified email, verified phone, or current or linked Apple, Google, or Facebook identity. The Flutter gate mirrors this from the current Firebase user only for navigation. An unverified password account can read recovery state but cannot create its profile or perform protected writes.

`functions/src/onboarding.ts :: handleCompleteOnboarding` accepts only display name, confirmed 17-plus, and current-policy consent. It derives UID and verified authority from callable auth and transactionally creates the private profile plus deterministic policy audit. Duplicate completion leaves existing coherent state unchanged. Direct profile create is denied. The birth date is used only by `OnboardingScreen` for the local age calculation and is not persisted or transmitted.

`AuthRepository` supports email and password, Apple, Google, Facebook, magic email link, and phone, plus deliberate same-UID linking. `SignInMethodsScreen` refuses unlinking the final method. Credential collision never starts an app-level merge. A failed Google initialization is discarded so a later attempt can retry. `MagicLinkStore` retains only email, request time, and optional current UID in one versioned device record for up to one hour. An ambiguous send failure retains that binding, while completion, explicit cancellation, terminal invalidity, or expiry clears it. Phone UI discloses Google processing, applies one cooldown to every send path, and uses one monotonic credential claim across manual entry, Android auto-verification, and resends. Leaving or changing the attempt invalidates any later unused automatic credential.

Verification feedback distinguishes a requested email from an already-verified account. Returning from a magic-link request says completion is pending rather than claiming the provider is connected. If `completeOnboarding` succeeds before the profile stream advances, the saved fields freeze while Check Again and Sign Out remain available. Check Again reuses the original confirmed values instead of implying that a later edit was accepted. Storage operator preview now requires the same verified-contact proof as Firestore and callable operator authority.

Provider code is not provider readiness. The iOS Firebase app is now registered with App Attest at the default one-hour TTL and remains unenforced. Android App Check, provider console enablement, Apple and Google identifiers, Meta callback and deletion configuration, SMS regions and quota, APNs or Android fingerprints, deployed association files, branding review, and real-device proof remain external gates. A provider button stays absent until an operator intentionally supplies the matching build flag.

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

## Living Songbook accuracy and provenance

`lib/presentation/browse/chant_detail_screen.dart :: ChantDetailScreen` exposes Suggest an edit separately from Report. `SuggestChantUpdateScreen` captures one of three exact purposes: correction, variation, or evidence. The form retains values after failure and normalizes evidence through the existing YouTube or X parser.

`functions/src/living_songbook.ts :: handleSubmitChantUpdateSuggestion` derives the submitter, current chant version, timestamps, status, and deterministic request ID. It requires an active verified account and current visible chant, rejects a duplicate before budget mutation, and commits independent 5-per-hour and 20-per-day counters in the existing private rate-state document. Direct suggestion mutation is denied; only the submitter and an active operator may read a row (`firestore.rules :: match /chantUpdateSuggestions/{suggestionId}`).

`ChantUpdateModerationTab` compares each valid request to a live non-cache chant and shows both submitted and current versions. Correction and variation requests can be planned, marked updated after the reviewed canonical path changes, or closed with a reason. A source that becomes unavailable leaves only Not changed enabled. Stale resolution requires explicit acknowledgement, while evidence acceptance always rejects staleness. A current Terrace Proven or system-owned community chant can receive reviewed evidence without a trust transition. A current user-created community chant receives evidence and canonical status in one transaction. Replacing different evidence requires explicit confirmation and retains only the prior public proof in operator audit. Promotion notifications exclude system and deleted-user sentinels.

`MyChantUpdatesScreen` shows Received, Planned, Updated, and Not changed without promising a response time or automatic truth. Malformed or future-version rows are dropped independently, and supporter-readable requests retain no operator UID. Account deletion removes the private request rows before profile finalization. Safety reports, flag counts, hiding, report budgets, and report resolution are never involved.

## Durable account deletion

The inherited deletion system remains a durable, bounded, retryable worker (`functions/src/account_deletion.ts :: processAccountDeletionStep`). The phase list now includes creator handles and profiles, performance drafts, private interaction records, both follow directions, notifications, new report collections, chant-update suggestions, and retained public creator attribution.

New actions check the private pending job as well as profile state before mutation. The client still prepares local Songbook deletion before requesting remote deletion and preserves unknown acknowledgement across relaunch (`lib/data/services/account_deletion_service.dart`; `lib/presentation/auth/account_deletion_recovery_screen.dart`).

Retained public content follows the existing privacy decisions: active public creator linkage is removed, user-authored report material is redacted, and trusted operator provenance is retained only through the reviewed allowlist. No repository-backed data export, backup restoration, or retention schedule exists.

## Inherited Songbook, Chant Lab, and seed system

The creator expansion does not replace the established chant model. Canonical content remains Terrace Proven; community content remains Chant Lab. Submission origin, optional external evidence, promotion requirements, stable seeded IDs, live current-authority checks, cache-readable but non-actionable fallback, one-level chant comments, votes, reports, blocking, Saved Matchday Songbook, and disabled merge behavior remain as recorded in decisions 003 through 016.

The seed pipeline validates explicit chant identity, content shape, review provenance, current-player linkage, and historic-subject fallback before Admin writes (`seed/validate.ts`; `seed/chant_identity.ts`; `seed/seed_chant_data.ts`; `seed/seed_plan.ts`). Source packages all 20 approved clubs with 192 chants and 622 reviewed squad rows (`seed_data/clubs/`; `seed_data/rosters/fpl-2026-08-30.json`). The refreshed currentness gate compares every club against 623 raw official-feed rows, preserves 17 reviewed display aliases, and exposes three named owner membership overrides instead of silently accepting feed lag (`seed/roster_currentness.ts`). Runtime projection adds `origin: alreadySung` and excludes offline era, review, historic-subject, and source metadata. The CLI rejects an unexpected project credential before Firestore access and provides a writer-free exact source-owned-field readback with system-orphan and departed-player reference reporting (`seed/seed_credential.ts`; `seed/seed_readback.ts`; `seed/seed.ts`). Read-only named-project preflight found all 192 chant targets collision-free. The bounded Arsenal production sequence created the four approved additions, reconciled all 12 chant projections, and used the exact no-argument transaction to remove only the three approved zero-reference departures after rechecking identity and reference counts (`seed/approved_player_retirement.ts`). Leeds then passed its one-club canary, and the remaining 18 clubs completed in six groups with exact same-group readback. Final production readback reports 20 matching teams, 622 matching players, 192 matching chants, and zero missing, mismatching, or orphan rows.

## CI, dependencies, and native status

`functions/package.json`, its root lock metadata, and `.github/workflows/ci.yml :: functions` now target Node 22. The existing CI job runs the production TypeScript build before the separate test build. Local Node 22.23.2 passed both builds and all 163 Functions tests with unchanged dependency versions and unchanged handlers. Seed and rules-test CI remain Node 20. This block has no new committed head or replacement clean-runner result yet.

`.github/workflows/ci.yml` runs governance, full Flutter tests, full analysis with a deterministic non-secret Firebase fixture, Functions, seed, and Firestore plus Storage emulators. It now also builds an Android debug APK and iOS simulator app from obvious non-secret compile fixtures. Android CI inspects `com.chants.chants`, records the APK digest, and retains the artifact. iOS CI inspects the same bundle ID. The governance job fetches complete history and runs `scripts/check-project-memory.sh --range <base>`, so implementation changes must carry `docs/EXECUTION.md` in the same PR or push range.

The auth client adds Google Sign-In, Facebook Auth, app links, and shared preferences. FlutterFire resolves as one current graph in `pubspec.lock`; iOS resolves 18 direct dependencies and 56 total pods against Firebase iOS 12.18. Google Sign-In 9.2 moves `GTMSessionFetcher` from 5.3.1 to compatible 3.5.0. CocoaPods warns that its Firebase distribution will stop receiving new versions after October 2026, but the repository intentionally remains CocoaPods-owned under the existing native decision. A future dependency-manager migration requires its own compatibility block.

Android declares Internet access, uses the Chants label, owns the approved auth and public HTTPS paths, applies the Google Services and Crashlytics plugins, and refuses debug signing for release, including when an aggregate Gradle task reaches a release task indirectly. Exact PR 18 clean CI built and inspected the debug APK; the local machine still has no Android SDK. iOS Runner carries Sign in with Apple plus auth and public-domain entitlements and now has a release-only FlutterFire symbol-upload phase. The launch-services branch also built and inspected `com.chants.chants` as a local iOS simulator app. Neither compile proves provider, signing, deployed association, device, Crashlytics delivery, or distribution readiness.

The owner completed development-certificate setup on 2026-08-30. A read-only `security find-identity -v -p codesigning` check reports one valid identity after certificate creation and Apple's WWDR G3 import. Device provisioning, signed device execution, and distribution credentials are separate unverified gates (`docs/EXECUTION.md :: Package backend readiness and record owner certificate closure`).

## Deployment, cost, and recovery

CI verifies and does not deploy. The source names one Firebase project and no staging environment. No public Function, Hosting route, rule, index, Storage rule, or client has been deployed by this work.

Read-only inventory recovered the actual generation-pinned source for all nine live Functions, each from the same July bundle. Both live report handlers blindly increment and use created events; reviewed source reconstructs counts on written events. The old live `mergeChants` lacks the reviewed stop. Production has old Firestore rules, two of sixteen required indexes, no configured media bucket or Storage rules release, and disabled Storage and Scheduler services. Firestore/Eventarc location is `nam5`, independently of `europe-west2` Functions compute. Exact identities, hashes, source lines, and proposed groups are in `docs/changes/2026-08-30-v1-backend-rollout-readiness.md :: Read-only production baseline, 2026-08-30`.

Performance read and upload surfaces have explicit limits: ten-record feed pages, 30-second and 50-MiB uploads, no autoplay or prefetch, one deterministic ranking contribution per account, short playback URLs, and manual approval. The launch-services branch adds one daily 100-row abandoned-draft cleanup page and two 101-row capped stale-job probes every 15 minutes. Creator and chant source fan-out plus exact aggregate reconstruction are not globally bounded and have no measured production budget. Production read, write, signing, storage, moderation, cleanup, and egress measurements do not exist.

The proposed order is reviewed source/CI, verified maintenance and recovery controls, additive ready indexes and compatible rules/bucket, named Function groups, separately approved workers/schedules, Hosting, then client. The report cutover cannot overlap the old incrementers. A general admission-pause mechanism and bounded repair caller do not exist in current source; they must be specified, built or configured, and tested under the next amendment. Source archives are not user-data backups, and the weaker predecessor is not an acceptable blanket rollback. Before admission, verify URL-signing IAM, domain and app associations, store destinations, App Check, alert delivery, cleanup, staffing, and final policy.

## Where I most want your eyes

The next combined Claude review starts at its last reviewed source `cb50d3c` and ends at the eventual packaged readiness head, covering seed PRs 22-24 and this block. Prior optional Living Songbook findings remain listed in the readiness record. Review the live/source distinction, report cutover pause, recovery limits, and destructive-worker holds before authorizing production writes.

1. `functions/src/onboarding.ts`, `requireVerifiedUid`, and both rules implementations for inconsistent email, phone, current-provider, linked-provider, or operator authority.
2. `lib/app/app.dart`, `MagicLinkGate`, onboarding, and `SignInMethodsScreen` for deletion precedence, stale Firebase user state, ambiguous delivery, cross-account links, collision, or last-method holes.
3. `AuthRepository` Google initialization, phone callbacks, cancellation, and magic-link local binding for poisoned retry, duplicate credential use, replay, expiry, or unrelated-account replacement.
4. Android Gradle signing, both native link declarations, non-secret fixtures, and the two new native CI jobs for false readiness claims.
5. `functions/src/performance_source.ts` and performance media-deletion work for inherited stale projection, aggregate, or retry holes.
6. Firestore and Storage rules for parser-safe public projections and path substitution.
7. `.github/workflows/ci.yml` and the project-memory and native governance scripts for range and source-contract correctness.

## Unverified

- Apple, Google, Facebook, magic-link, and phone dashboard, credential, callback, domain, privacy, quota, anti-abuse, and real-device behavior. Every provider remains disabled until its own gates pass.
- Camera and library permissions, upload progress, backgrounding, retry, cancellation, playback, share destinations, Following, notifications, deep comments, moderation, blocking, deletion, accessibility, and offline behavior on real devices.
- `chantsfc.com` Hosting deployment, DNS, domain association, social crawler output, app/store routing, and URL-signing IAM.
- Android App Check, App Check enforcement and observation, alert delivery, deployed signal production, billing-threshold delivery, deployed staged-object cleanup, moderation response time, backup or restore, data export, and deployed parity.
- Final content policy, privacy policy, terms, media rules, signing, store metadata, configured-device catalogue inspection, and release.
