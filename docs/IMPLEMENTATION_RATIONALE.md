# Repository implementation rationale

This document explains the current Chants repository through documentation merge `9c6286a` and the approved V1 launch-services range, including inherited systems and the independently reviewed creator, launch-authentication, Android, post-auth correction, and minor-closure work. It is a reviewer map, not proof of deployment or release readiness.

## Document identity and completeness

- **Current change:** `docs/CHANGE_SPEC.md`
- **Completed change reasoning:** `docs/changes/2026-08-27-creator-platform-foundation.md`, `docs/changes/2026-08-28-pr17-post-review-takedown-integrity.md`, `docs/changes/2026-08-28-v1-launch-auth-onboarding-android.md`, `docs/changes/2026-08-28-post-auth-independent-review-corrections.md`, `docs/changes/2026-08-29-final-source-freeze-minor-closure.md`, and `docs/changes/2026-08-29-v1-launch-services-configuration.md`
- **Durable creator, identity, and launch decisions:** 017 through 024
- **Execution evidence:** `docs/EXECUTION.md`
- **Interface memory:** `docs/INTERFACE.md`
- **Known missing evidence:** combined device walk, remaining provider configuration, association deployment, final policy text, source deployment, observed alert delivery, seed completion, signing, and release

## Repository coverage ledger

| Area | Read and accounted for | Current role |
|---|---|---|
| `lib/app/` | Yes | Theme, providers, routing, deletion, verification, onboarding and policy gates, five-tab shell composition |
| `lib/data/models/` | Yes | Chant, creator, performance, comment, draft, notification, saved and private-account parsing |
| `lib/data/repositories/` | Yes | Auth and provider linking, onboarding, Firestore, Functions, Storage, local file, share, social, and interaction boundaries |
| `lib/data/services/` | Yes | Auth-link coordination, media selection, sharing, evidence, ranking, matching, deletion, hashing, and Songbook logic |
| `lib/presentation/` | Yes | Auth, Stage, clubs, creation, profiles, activity, moderation, comments, saved, reports, and settings |
| `functions/src/` | Yes | Admission, moderation, counters, public pages, follows, notifications, safety, audit, deletion, trust, and disabled merge |
| `firestore.rules` | Yes | Public and private read boundaries, hostile direct-write denial, query requirements |
| `storage.rules` | Yes | Exact draft staging admission and denial of direct published-media reads |
| `firestore.indexes.json` | Yes | Stage, profile, notification, moderation, and deletion query indexes |
| `firebase.json`, `hosting/` | Yes | Functions, Hosting rewrites, public fallback assets, Firestore and Storage emulator config |
| `seed/`, `seed_data/` | Yes | Stable IDs, validation, preflight, Admin writes, and counter reconciliation |
| `.github/`, `scripts/` | Yes | Clean-runner jobs, memory contract, writing, native contract, and governance regressions |
| `test/`, `functions/test/`, `test_rules/` | Yes | Unit, widget, golden, handler, overlap, authority, and lifecycle evidence |
| Android and iOS projects | Yes in source | Auth plugins, permissions, deep links, entitlements, deployment target, CocoaPods lock, fail-closed release signing, compile fixtures, and remaining SDK or provider gates |

Generated build outputs and installed dependency trees are excluded except when a tool result depends on them.

## System overview

Chants has three related content roles:

1. **Terrace Proven Songbook:** canonical chants whose evidence and operator trust action support the archive claim.
2. **Chant Lab:** community chant ideas ranked by backing without implying stadium adoption.
3. **Performances:** manually approved short creator videos attached to either chant type and ranked by performance reach.

The roles share navigation and chant identity but not trust authority. A popular performance cannot make its chant canonical. A creator can still submit words without video. A matchgoer can still use the device-local Songbook without loading social state.

## Critical path: authentication to product shell

`lib/presentation/auth/sign_in_screen.dart :: SignInScreen` introduces Watch, Learn, and Create before credentials. `lib/data/models/auth_feature_config.dart :: AuthFeatureConfig` keeps Apple, Google, Facebook, magic link, and phone invisible by default; an operator compile-time flag is the source-level assertion that the matching external setup is ready. Email and password remain complete, and reset distinguishes unknown-account privacy from known transport or quota failure.

Firebase Auth owns the UID, credential, verification, and linked-provider state. `functions/src/safety_submission.ts :: requireVerifiedUid`, `firestore.rules :: hasVerifiedContact`, and `storage.rules :: hasVerifiedContact` accept a verified email, verified phone, current trusted federated provider, or nonempty linked Apple, Google, or Facebook identity. An ordinary unverified password account stays read-recoverable but cannot perform protected mutations.

`lib/app/app.dart :: _SignedInGate` evaluates durable deletion recovery first. It then sends an unverified password account to `EmailVerificationScreen`, a verified missing-profile account to `OnboardingScreen`, a policy-stale profile to the inherited policy gate, and only a coherent account to `AppShell`. Verification reloads on app resume or explicit action, with no polling.

`functions/src/onboarding.ts :: handleCompleteOnboarding` is the only initial profile writer. It accepts an exact three-field confirmation, derives UID and verified authority from callable auth, rejects deletion or incoherent existing profiles, and transactionally writes the pinned private profile plus deterministic policy audit. Duplicate completion does not overwrite existing authority. Date of birth is evaluated in the current device form and never enters the payload.

`lib/presentation/settings/sign_in_methods_screen.dart :: SignInMethodsScreen` deliberately links providers to the current UID and refuses removal of the final usable method. Collision copy does not claim an email-based merge. Magic-link pending email and linking UID remain device-local for one hour. Phone entry includes explicit Google processing disclosure, resend controls, manual code entry, and late Android auto-verification recovery.

## Critical path: public creator identity

`lib/presentation/profile/edit_creator_profile_screen.dart` submits handle, public name, and optional bio through `lib/data/repositories/creator_profile_repository.dart`. `functions/src/creator_profile.ts :: handleUpdateCreatorProfile` normalizes and validates the input, rechecks private account authority, reserves `creatorHandles/{handle}` transactionally, writes the public allowlist, and preserves server counters.

Public profile content uses exact-ID `creatorProfiles` gets; private authority is never copied into that schema. Firestore rules and public HTTP handlers separately recheck current private account activity, so a ban or deletion closes public access without exposing role, ban, policy, age, deletion, report, or email fields. Public creator collection listing is operator-only because V1 has no creator-directory query and a list rule cannot safely prove private account authority for every possible result.

## Critical path: record or choose, upload, and approve

`lib/presentation/browse/chant_detail_screen.dart` opens `PerformChantScreen` for a current visible chant. A creator profile is required. The media service invokes camera recording or the device library. The client rejects unsupported extension, duration over 30 seconds, and size over 50 MiB before upload.

`handleCreatePerformanceDraft` allocates one owner draft and exact staging path. Storage rules allow only that UID and draft path. `PerformanceDraftRepository` transfers bytes and exposes progress, retry, cancellation, and submission. `handleSubmitPerformanceDraft` trusts Storage metadata rather than client claims and moves the draft to pending only after account, creator, chant, object, type, bytes, and duration checks.

An active operator uses `handleModeratePerformance`. Approval creates the public performance projection, approved media identity, and both server-owned source-eligibility flags. Rejection stays private. Upload completion alone never grants visibility.

## Critical path: browse and play Stage

`PerformanceRepository` issues bounded ten-record queries for Rising, New, Terrace, or Following and carries a cursor. Every public query includes approval, moderation visibility, current creator-source eligibility, and current chant-source eligibility. Following first reads up to the 30 most recent private follow edges, then performs the bounded creator query. Empty or signed-out Following falls back visibly to Rising. The Stage additionally watches the viewer's private block set, fails closed while that authority is unavailable, and removes blocked creators immediately.

`PerformanceVideoPlayer` starts from a poster and explicit play. It calls the playback resolver only on demand. The server checks current actor authority, private creator account, creator deletion job, public creator, current chant, performance visibility, source flags, and both block directions before returning a short signed URL. Three seconds of actual playback triggers the qualified-view callable once for that account.

Playback errors preserve the card and expose Retry. The feed does not autoplay, background play, prefetch, or loop through failed network requests.

## Critical path: popularity and weekly competition

Like, view, and share callables use deterministic UID plus performance identity. The performance creator's own view or share does not improve competition rank. Trigger handlers recompute totals from child records and serialize the parent update so duplicate or reordered delivery converges.

The weekly winner uses current UTC week unique shares, then likes, then qualified views, then stable identity. The UI renders `#1 MOST SHARED` only if the derived winner has a positive unique-share count. The label describes an operating-system share handoff, not confirmed recipient opens.

## Critical path: follow, mention, reply, and activity

Follow is a server transaction. It rejects self-follow, absent or restricted creator, inactive account, pending deletion, and either block direction. Public profile counts are recomputed from private edges.

Performance comment creation checks current performance, creator and actor authority, block directions, body bounds, parent and root consistency, stored depth, and mention count. Mention handles resolve through the private reservation index. The server writes deterministic recipient notifications after rechecking block and deletion state. Reply and mention duplication resolves to one notification.

The comments sheet visually indents only three levels. Deeper branches open a focused thread. Activity navigation fetches current performance authority before opening a mentioned or replied-to comment. A stale notification remains historical text and cannot revive removed content.

## Critical path: public share

The mobile repository asks `resolvePublicShareDestination` for a current HTTPS URL. The system share sheet receives bounded text plus that destination. Server-rendered pages independently recheck visibility and emit escaped, allowlisted metadata.

Public performance video uses a same-origin media route. It does not reveal the raw Storage path. The handler verifies the exact performance media identity plus current creator and chant authority, then returns a no-store redirect to a two-minute signed URL. A ban, deletion, source takedown, hide, or removal stops new resolution. Immediate revocation of an already issued URL is not claimed. In-app playback URLs have a ten-minute residual.

## Critical path: report and moderate

The existing report callable now parses performance and performance-comment targets. It rechecks current target authority, both deletion states where applicable, duplicate identity, and the atomic report budget before writing server-owned rows.

Draft approval is separate from published-media response. `handlePublishedPerformanceModeration` supports dismiss, hide, remove, and restore after current operator authorization. It updates target state, resolves relevant reports, and writes bounded audit. Terminal performance removal also commits deterministic exact-path media-deletion work. A retry-enabled trigger deletes the object idempotently and acknowledges the job only after cleanup. The operator UI separates reported video, reported comments, and hidden content; eligible hidden rows expose Preview, Restore, and Remove.

Directional blocks suppress Stage cards, public creator access in the app, ordinary viewing interaction, follow, comment, mention fan-out, and notification delivery. Stage cards and public creator profiles expose a confirmed Block action. Operator preview is a narrow inspection exception for approved, nonremoved hidden media, not a social-action bypass.

## Critical path: keep the Songbook current

`submitChantUpdateSuggestion` parses one exact correction, variation, or evidence shape, derives the verified caller, and rereads the private profile, deletion job, and current visible chant. A server-read timestamp becomes the source version. A deterministic hash of user, chant, version, purpose, and correction category prevents duplicate work before any rate write.

The same transaction commits the private request and independent 5-per-hour plus 20-per-day anchored counters. These fields share the private rate-state document for deletion and storage economy, but never share report or feedback counts. A suggestion never increments flags, hides content, or writes safety state.

`moderateChantUpdateSuggestion` reauthorizes the operator and compares the stored source version to the current chant. Evidence acceptance rejects every stale version. Correction and variation resolution requires explicit stale acknowledgement, but it never writes canonical content. Operators apply those accepted changes through the reviewed content path before marking the request Updated.

Reviewed evidence can be attached to a current Terrace Proven or system-owned community chant without a trust transition. A user-created community chant receives evidence and canonical status atomically. Only that real promotion creates the deterministic private Your chant made the terrace activity item, and sentinel owners never receive it. Replacing different existing evidence requires a separate acknowledgement. Ordinary audit detail records IDs and outcome class. A replacement audit also retains the prior public evidence map, but no audit retains proposed lyrics, request text, proposed evidence, or submitter identity.

## Critical path: source reconciliation and creator totals

`functions/src/performance_source.ts` derives creator and chant eligibility from current documents. Profile and chant triggers fan out server-owned source flags to dependent performances. Each dependent write rereads its current source in the same transaction, so a concurrent source change causes an older handler to retry. Chant reconciliation also updates the attached title and trust status. Live server actions and public HTTP handlers still read current source documents because trigger delivery is asynchronous.

Approval retains an idempotent immediate `performanceCount` update. Lifecycle repair reconstructs that total from approved, unhidden, unremoved performances with both source flags true. The query and creator write share one transaction, so overlapping writers serialize on the creator profile. Visibility-affecting writes invoke reconstruction; likes, views, shares, and comment counter updates do not.

## Critical path: account deletion

The client still durably marks local Songbook state before requesting deletion. The server accepts deletion into a private job, sets pending authority, and advances bounded phases under retry.

The phase set now removes creator handle and profile, drafts and staging references, interactions, follows in both directions, notifications, private chant-update suggestions, user-authored report material, and other inherited private rows. Retained approved content loses active creator linkage. Delayed audit writes still pass through privacy-safe classification. Auth deletion and finalization remain idempotent.

## Persistent state and ownership

| State | Visibility | Writer |
|---|---|---|
| Firebase Auth identity and provider links | Current authenticated user through Firebase SDK | Firebase Auth provider and explicit signed-in link operations |
| `profiles` initial state | Owner and operator only | `completeOnboarding` server transaction only |
| `profiles` later display-name state | Owner and operator only | Narrow verified-owner allowlist plus server authority |
| Pending magic-link email, time, and optional UID | Current device only, one-hour maximum | Local `MagicLinkStore` |
| `creatorProfiles` | Visible public profiles; owner/operator restricted inspection | Creator-profile callable and server counters |
| `creatorHandles` | No client read | Server transaction |
| `performanceDrafts` | Owner and operator | Server callables |
| `performances` | Approved visible public projection; operator restricted inspection | Server admission and moderation |
| Staged media | Exact owner draft only | UID-scoped Storage rule |
| Published media | No direct client read | Server copy and signed delivery |
| `performanceMediaDeletionJobs` | No client read or write | Terminal moderation transaction and retry-enabled cleanup trigger |
| Performance interactions | Actor or recipient where needed; aggregates public only | Server callables and triggers |
| `creatorFollows` | Follower only | Server callable |
| `creatorNotifications` | Recipient only | Server fan-out and read callable |
| Performance reports | Operator only | Server safety callable |
| `chantUpdateSuggestions` | Submitter and active operator only | Server submission and moderation callables |
| Audit and deletion jobs | Operator or server only according to path | Server |
| Saved Matchday Songbook | Device-local, UID-scoped | Local repository |

## Invariants and evidence

| Invariant | Enforcement | Current local evidence |
|---|---|---|
| Unverified password identity cannot create a profile or mutate protected data | Server-only initial profile create plus callable, Firestore, and Storage verified-contact checks | Functions tests, app-gate tests, and 165 Java-backed Firestore and Storage cases at merged `main` `e8f2591` |
| Linked trusted identity remains authoritative after later password sign-in | Firebase linked identity claims accepted at server and provider data mirrored by app gate | Functions and rules regressions |
| Initial onboarding cannot choose protected fields or split age and policy state | Exact callable payload and one Firestore transaction | Onboarding handler and repository tests |
| Birth date does not leave the current onboarding form | Client computes only the 17-plus result and callable schema has no birth-date field | Widget, payload, and handler tests |
| Provider availability fails closed | Compile-time flags default false and native or dashboard state is not inferred | Provider hierarchy and native contract tests |
| Linking preserves UID and never removes the last method | Firebase link operations and repository unlink guard | Focused repository and interface review; real-provider device proof pending |
| Provider failures preserve a retry or truthful pending state | Failed Google initialization is not cached; ambiguous magic-link delivery retains its binding; verification returns requested versus complete | Repository and production widget regressions |
| Phone cancellation and cooldown are monotonic | One attempt token blocks after cancellation and every screen send path shares one cooldown | In-flight failure and Change Number regressions |
| Onboarding cannot strand all controls after server success | Mounted success restores retry and Sign Out while idempotent profile projection catches up | Production onboarding widget regression |
| Private account authority never enters public creator identity | Separate schemas, exact public allowlist, callable-only writes | Functions and rules tests |
| Pending or rejected media is not public | Draft collection, Storage path, public visibility predicate | Functions plus Firestore and Storage emulator tests |
| A performance does not alter chant trust | Separate model and moderation write set | Handler and model tests |
| Client cannot forge counters, rank, moderation, or media path | Direct writes denied, exact projection parser, server recompute | Hostile rules and handler tests |
| One account contributes once to competition signals | Deterministic interaction IDs | Duplicate and overlap tests |
| New actions require current target authority | Callable reads and current-visible repository fetch | Handler and widget tests |
| Accuracy intake cannot become automatic truth, a safety action, or unclosable work | Separate collection, copy, counters, oldest-first queue, version check, unavailable-source closure, and canonical content path | Living Songbook Functions, Flutter production widgets, deletion, and rules tests |
| Follow graph and inbox remain private | Recipient or follower rules, aggregate public profile only | Rules and repository tests |
| Replies stay same-target and acyclic | Parent/root/depth validation | Functions and widget tests |
| Block suppresses social fan-out in both directions | Server block reads and callable denial | Functions tests |
| Current creator or chant takedown closes dependent performances | Server source reads, query flags, fan-out, strict rules | Functions, Flutter, and rules tests |
| Hidden public media stops new resolution while remaining operator-reviewable | Page and media current checks plus narrow operator preview | Public-share, playback, and moderation tests |
| Terminal performance removal schedules exact retryable Storage cleanup | Deterministic server-only job and path-validating worker | Functions cleanup and moderation tests |
| Creator performance totals converge from live rows | Parent-serialized exact reconstruction | Source overlap and repair tests |
| New persistent data joins deletion | Added bounded phases and finalization | Failure-injection and app-gate tests |
| CI enforces project memory for the review range | `--range` workflow and regression harness | Governance tests |

## Security and privacy

Firestore denies unmatched paths. New public projections have explicit schemas, visibility states, and list-query requirements. New private paths deny direct mutation. Storage accepts only the exact staged source object for a current owner draft and denies direct public-media reads.

Every callable reauthorizes from private actor state and relevant current target sources. UI visibility and denormalized eligibility are never treated as sufficient live authority. App Check remains client-wired but production enforcement is unverified.

Authentication adds no credential logging or provider discovery. Raw provider exceptions are converted to bounded user copy. Magic-link email stays local and is removed on completion, explicit cancellation, terminal invalidity, malformed state, or expiry. It is retained after an ambiguous send failure so a possibly delivered link can still complete. Phone and federated methods remain invisible until their external privacy and abuse controls are verified.

Public pages omit lyrics, private UIDs, raw Storage paths, report state, and unrestricted user HTML. Creator bios are escaped. Hidden and missing public targets are indistinguishable. Signed media creates a bounded two-minute residual after moderation.

The product stores user-created video. Policy, privacy, takedown, retention, moderation staffing, and billing controls are not optional documentation polish; they are release gates.

## Dependencies and native platforms

| Dependency | Purpose | Current boundary |
|---|---|---|
| `firebase_storage` | Staged upload and media transfer | FlutterFire graph, Storage rules, server signed delivery |
| `image_picker` | Camera recording and device-library selection | Native permission copy in iOS Info.plist; device behavior unverified |
| `video_player` | In-app approved and operator-preview playback | Explicit play, no autoplay, retry state |
| Existing Firebase plugins | Auth, Firestore, Functions, App Check, Crashlytics | Resolved together in Flutter and Firebase iOS 12.18 lock graphs |
| `share_plus` | Operating-system share handoff | Destination resolver precedes public URL sharing |
| `google_sign_in` | Native Google account selection and Firebase credential exchange | Hidden until client IDs, Firebase provider, fingerprints, and device proof are verified |
| `flutter_facebook_auth` | Native Meta login and Firebase credential exchange | Hidden until Meta app, callback, policy, and deletion configuration are verified |
| `app_links` | Initial and resumed HTTPS magic-link delivery | Source paths exist; hosted Apple and Android association is not deployed or claimed |
| `shared_preferences` | Short-lived device-local pending magic-link identity | One-hour maximum with terminal and malformed-state clearing |

iOS remains on the project-owned CocoaPods path. The auth graph resolves 18 direct dependencies and 56 total pods. Google Sign-In 9.2 uses `GTMSessionFetcher` 3.5.0, which remains inside Firebase Storage's accepted range. Exact PR 18 clean CI built both the iOS simulator bundle and Android debug APK. Android SDK and Java remain unavailable locally, so replacement current-head native and rules evidence belongs to clean CI. CocoaPods reports Firebase Apple SDK pod publication will stop after October 2026; a Swift Package Manager migration needs a separate compatibility decision because the project previously rejected automatic mixed ownership.

## Performance, scale, and cost

- Feed pages are limited to ten records.
- Following V1 is limited to 30 followed creator IDs.
- Upload is limited to one 30-second, 50-MiB object per draft.
- Abandoned staging cleanup reads and attempts at most 100 exact-path drafts per daily run.
- Retained deletion monitoring reads at most 101 rows per collection every 15 minutes and logs aggregate counts only.
- Video does not autoplay, prefetch, or retry indefinitely.
- Public signed playback URLs last two minutes; in-app signed playback URLs last ten minutes.
- Interaction totals recompute from all source rows for a performance, which favors correctness over large-scale write cost.
- Creator and chant changes scan dependent performances and execute one current-source transaction per row. Creator performance totals scan that creator's performance rows. These paths favor convergence over globally bounded work and have no measured production budget.
- Manual review limits admission throughput.
- Phone production cost is controlled by provider quotas, permitted regions, test numbers, billing alerts, and first-cohort observation, not the source cooldown alone. Phone remains disabled until those gates exist.
- Production reads, writes, signing, storage, egress, moderation time, and cost are unmeasured.

The launch-services block provides bounded staged-object cleanup and the privacy-safe stale-job signal in source. The two operational policies and USD 25 alert-only budget are saved, enabled, and re-read. Launch still requires deployment, observed signal and notification delivery, moderation response expectations, and an admission pause procedure.

## Verification performed

| Command or probe | Result |
|---|---|
| Focused Flutter auth, onboarding, app-gate, reset, magic-link, provider cancellation, phone-race, stale-session, provider hierarchy, and narrow 1.8x tests | PASS during the launch implementation and retained by the full exact-main suite |
| Full `flutter test` | PASS, 463 tests locally and in exact-main run `33256843751` at `e8f2591` |
| `flutter analyze lib test` with the deterministic non-secret fixture | PASS with zero issues locally and in exact-main run `33256843751` |
| `functions/npm test` | PASS, 142 including overlapping onboarding and explicit transaction-retry state |
| Launch-services Functions suite | PASS, 146 including bounded cleanup, exact retry, stale boundaries, count caps, and privacy-safe logging |
| Launch-services Flutter suite and analysis | PASS, 465 tests and zero analyzer issues after the private cleanup-state parser regression |
| Complete Functions and focused deletion suite after Living Songbook corrections | PASS, 163 tests covering exact parsing, derived identity, inactive admission, dedupe, independent limits, retry classification, action-to-request matching, unavailable closure, stale review, evidence replacement, exact audit content, attachment, atomic promotion, sentinel-safe notification, and deletion |
| Complete Flutter suite after Living Songbook corrections | PASS, 488 tests including the reviewed Chant Detail golden, current-authority promotion activity, typed failures, malformed-row isolation, operator review, and private history |
| Living Songbook Flutter tests and fixture-backed scoped analysis | PASS for repository authority, correction and evidence forms, retained failure values, invalid link refusal, chant-detail separation, promotion navigation, unavailable closure, replacement confirmation, attach versus promote, stale acknowledgement, private status, responsive dialog behavior, intentional golden review, and zero-issue `flutter analyze lib test` |
| Living Songbook Firestore rules TypeScript | PASS; Java is absent locally, so owner, cross-user, operator, and direct-write emulator cases require clean-runner execution |
| Firestore plus Storage emulator | PASS, 165 Java-backed cases in exact-main run `33256843751`, including one cross-account Storage case with three permission assertions |
| `seed/npm test` | PASS, 42 |
| Memory, writing-style, native-contract, and governance-regression scripts | PASS in exact-main run `33256843751`; rerun against the documentation-only staged boundary |
| `git diff --check` | PASS for the reviewed implementation heads; rerun against the documentation-only staged boundary |
| GitHub Actions runs `33254213575`, `33255542646`, and `33256843751` | PASS, all eight jobs at runtime implementation `e1474ad`, documentation head `c1c4ea4`, and merged `main` `e8f2591` |
| Three targeted goldens | Updated, passing, and visually inspected |
| CocoaPods resolution | PASS, 18 direct dependencies and 56 total pods on Firebase iOS 12.18 |
| iOS simulator compile | PASS with bundle and exact-source inspection at merged `main` `e8f2591` in run `33256843751` |
| Launch-services iOS simulator compile | PASS locally; `Runner.app` reports `com.chants.chants` and the Crashlytics pod symbol tool is present |
| Android debug compile | PASS with package and source identity inspection at merged `main` `e8f2591` in run `33256843751` |
| Launch-services Android debug compile | BLOCKED locally because this machine has no Android SDK; replacement clean-runner CI remains the source gate |

## Deployment and recovery

No repository artifact in this range is deployed. The approved Auth domains, unenforced iOS App Attest registration, operational policies, private notification channel, and alert-only budget are saved and re-read in their owning consoles. No live Firestore or Storage mutation, seed write, signing, or store action occurred.

Compatible deployment order is rules, Functions, Hosting, then client. Public URLs should not ship until Hosting, domain, IAM signing, and store routing are verified. Media admission should not open until policy, moderation, cleanup, billing, and alert gates are operational.

Recovery options are additive. Pause performance admission without removing Songbook or words-only creation. Hide or remove approved media to stop new public resolution; terminal removal leaves retryable physical cleanup. Reconcile source flags and exact creator totals from current documents. Revert the client shell without deleting creator data. Account deletion continues through its durable worker.

## Documentation consistency

| Record | Current meaning |
|---|---|
| `docs/CHANGE_SPEC.md` | Approved V1 launch-services source and reversible configuration contract |
| Six current change records dated 2026-08-27 through 2026-08-29 | Creator implementation, takedown correction, launch authentication extension, post-auth correction, final minor closure, and V1 launch services |
| Decisions 017 through 024 | Shell, creator, performance, public, social, safety, source eligibility, verified identity, and staged launch integrity architecture |
| `docs/INTERFACE.md` | Current launch, Stage, creator, conversation, moderation, and inherited interaction contract |
| `docs/ROADMAP.md` | Feature source merged; launch services are packaged separately; device evidence, remaining provider configuration, policy, seed, deployment, and release remain |
| `ENGINEERING_OVERVIEW.md` | Reviewer-oriented current code map |

## Known compromises and uncertainty

| Item | Consequence | Revisit trigger |
|---|---|---|
| Manual media review | Queue can stall | Before public beta and when response time crosses the chosen target |
| Following query cap | More than 30 followed creators are not represented in one V1 page query | When real accounts cross the cap |
| Signed URL residual | Hide is not instantaneous for an already issued public two-minute or in-app ten-minute URL | When risk requires stronger revocation |
| Source fan-out and ground-truth aggregate scans | Trigger time and write cost grow with dependent performance volume and popularity | Before public volume or when telemetry crosses budget |
| Durable media-deletion monitoring is source-only until deployment, and saved policy delivery is unobserved | Failed physical cleanup may remain queued without prompt operator attention | Before media admission opens |
| No automated media screening | Harm detection depends on humans | When queue or incident volume justifies a reviewed provider contract |
| Apple association is source-ready but not hosted; Android and store association remain absent | Public pages cannot yet guarantee app opening | Before release emits links |
| Requested providers are source-complete but disabled | Launch breadth depends on external console, credential, callback, privacy, cost, and device proof | Before enabling each provider flag |
| No cross-UID account merge | A user with two existing accounts must choose one and link only credentials not already owned | When measured support demand justifies a separately reviewed recovery system |
| Policy copy is placeholder and the saved alert-only cost control has no observed delivery | Public UGC release remains blocked on policy and operational proof | Before public submission |
| No staging, restore proof, or export | Operational recovery remains manual | Before public beta or meaningful user data |

## Material files

- `lib/presentation/shell/`, `feed/`, `create/`, `profile/`, `moderation/`, `report/`
- `lib/presentation/auth/`, `lib/presentation/settings/sign_in_methods_screen.dart`, `lib/app/app.dart`
- `lib/data/repositories/auth_repository.dart`, `magic_link_store.dart`, `onboarding_repository.dart`
- `lib/data/models/creator_*`, `performance*`
- `lib/data/repositories/creator_*`, `performance_*`, `public_share_repository.dart`
- `functions/src/creator_profile.ts`, `creator_follow.ts`, `creator_notification.ts`, `performance.ts`, `performance_source.ts`, `public_share.ts`, `published_performance_moderation.ts`
- `functions/src/onboarding.ts`, `safety_submission.ts`, `account_deletion.ts`, and `index.ts`
- `firestore.rules`, `storage.rules`, `firestore.indexes.json`, `firebase.json`, `hosting/`
- `.github/workflows/ci.yml`, Android and iOS native source, `scripts/check-native-project.sh`, `scripts/check-project-memory.sh`, `scripts/test-project-governance.sh`
- `pubspec.yaml`, `pubspec.lock`, `ios/Podfile.lock`, `ios/Runner/Info.plist`

The most valuable review targets are listed in `ENGINEERING_OVERVIEW.md :: Where I most want your eyes`.
