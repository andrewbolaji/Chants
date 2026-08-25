# Repository implementation rationale

> **Document contract:** This is the current milestone snapshot for the entire Chants repository. It covers inherited and newly stacked behavior. Preimplementation intent belongs in `docs/CHANGE_SPEC.md`, completed change reasoning in `docs/changes/`, durable decisions in `docs/decisions/`, and chronological evidence in `docs/EXECUTION.md`.

## Document identity and completeness

- **Product:** Chants, a Flutter and Firebase mobile app for learning trusted football chants and publishing new chant ideas.
- **External review baseline:** `c57815c`, the last whole-stack engineering-review commit. The coming freeze review must compare that commit to the eventual account-deletion freeze head.
- **Current stack head:** Account-deletion implementation commit `98f2c9ee98d5feb7a901cb3e8907b056b340b05d` in stacked draft PR 13, plus this CI-evidence refresh.
- **Review type:** Current whole-project milestone snapshot before external freeze review and the combined device walk. It is not a release sign-off.
- **Coverage:** Flutter client, Cloud Functions, Firestore rules and tests, seed pipeline, native configuration, CI, framework docs, and release boundaries.
- **Excluded:** Vendored `node_modules`, generated Flutter and TypeScript output, live Firebase data and dashboard state, deployed artifacts, store dashboards, and operating-system device behavior.
- **Preserved unrelated work:** `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` were already modified and remain unstaged.
- **Current status:** Durable account deletion is packaged in draft PR 13 and all five clean-runner jobs pass. Independent freeze review, native compilation, and the combined device walk remain pending.

## Repository coverage ledger

| Capability | Behavior and key paths | Authority and invariant | Verification | Current gap |
|---|---|---|---|---|
| Auth | Email/password sign-up, sign-in, reset, sign-out in `lib/presentation/auth/` and `lib/data/repositories/auth_repository.dart` | Firebase Auth owns identity; client never chooses privileged role or ban state | Flutter auth and gate tests | Reset-email template behavior remains dashboard-only and unverified |
| Age and consent | Local DOB check, stored 17-plus boolean, versioned policy gate in `lib/data/services/age.dart`, `lib/app/app.dart`, `functions/src/index.ts :: acceptPolicy` | DOB is not stored; policy version and acceptance time are server-written | Flutter, Functions, and rules tests | Actual policy copy is still a placeholder |
| Profiles and roles | Owner profile plus operator moderation identity in `profiles` | Owners can edit only display name and update time; role, ban, age, consent, and report count are pinned by `firestore.rules :: profiles` | Rules suite; ban handler tests | Dashboard-created operator bootstrap and second-account device proof unverified |
| Browse and discovery | Home, competition, Team, Player, Songbook, Chant Lab, Discover, search in `lib/presentation/browse/` | Visible queries constrain hidden and removed; permission denial removes Discover cards; ordinary transient failure may retain safe content | Ranking, Team, Player, authority, and golden tests | Full Discover fetch remains a scale boundary |
| Submission | Required origin, title, lyrics, tune, subject, style; optional evidence in `SubmitChantScreen` | Exact parser-safe user schema; Team and optional Player relationship; community, no direct media, empty variations | Flutter and 135-case rules suite | No author flow to attach evidence later; invalid legacy rows require normalization before direct edit |
| Provenance and evidence | Honest labels, canonical YouTube/X normalization, evidence-gated promotion in `chant_evidence.dart`, `chant_trust.ts` | Votes never prove terrace use; user content needs valid evidence plus operator review for canonical status | Dart, Functions, rules, and golden tests | No author flow to attach evidence later |
| Duplicate nudge | Advisory token matcher and explicit continue/view/back flow in `SubmitChantScreen :: _reviewLikelyDuplicates` | Failure of an advisory read cannot block posting | Matcher and submit widget tests | No open implementation gap in v1 boundary |
| Voting | Optimistic up/down/clear with Function recompute in `vote_controls.dart`, `vote_repository.dart`, `handleVoteWritten` | Deterministic vote ID; client changes only intent; Function owns `appliedValue`; missing parent no-ops | Vote widget, repository, 7 Functions, and hostile rules cases | Aggregate query cost grows with popularity |
| Comments and replies | Ranked parents, one chronological reply level, likes, report, delete, block in `comment_section.dart` and `comment_card.dart` | Visible same-chant top-level parent; both block directions; background hydration and Undo failures contained | Model, widget, enlarged-text, golden, Functions, and rules tests | No open v1 correctness gap in this reviewed boundary |
| Reports and feedback | Callable-only admission, one report per reporter/target, shared anchored report budget, independent feedback budget, content auto-hide at 3 pending reports | Server owns identity, time, state, ID, and atomic admission; counters recompute from pending ground truth; automatic action hides only | Functions, Flutter failure-state, and hostile rules tests | Limits need closed-beta tuning; App Check enforcement remains live configuration |
| Moderation | Hide, unhide, remove, promote, demote, evidence removal, ban, unban in callable and operator screen | Callable derives actor from auth and re-reads operator role; audit is Admin-written | Pure trust and ban handlers, rules operator reads | Full callable and `mergeChants` lack end-to-end tests; queue query remains narrow |
| Merge | Operator moves votes, reports, comments/replies and deletes duplicate source in `mergeChants` | Same-Team check; deterministic interaction keys dedupe target rows; delayed vote triggers tolerate a deleted parent | Functions tests, TypeScript compilation, and source review | Sequential and non-resumable; audit payload is partial |
| Account deletion | Durable request plus 16-phase bounded worker in `functions/src/account_deletion.ts`; pending app gate and local Songbook compensation | Acceptance precedes sign-out; pending account loses write authority; retry survives Auth deletion; retained contributions are anonymized | Functions failure injection, 135-case rules suite, Flutter lifecycle tests, and inspected golden | No operator recovery console or retained-job alert; no undo by design |
| Saved Matchday Songbook | UID-isolated bounded local JSON snapshots, explicit refresh, offline read-only routes | Maximum 500 unique chants and 2 MiB; local actions require active matching UID | Model, repository, service, widget, lifecycle, and golden tests | Physical force-stop/airplane-mode persistence unverified; no cross-device sync by design |
| Share-out | Plain-text native sheet from live detail in `chant_share.dart` and `chant_detail_screen.dart` | No public URL or delivery claim; every live-target action requires current visible authority | Payload, gateway, authority, enlarged-text, and golden tests | Native device destination behavior unverified |
| Seed | Explicit stable chant IDs, read-only preflight, transaction ownership recheck, validation, orphan report | Source content is human supplied; seed may transform but never invent lyrics or context | 42 seed tests plus TypeScript | Only Arsenal JSON exists; no live preflight or remaining club write ran |
| CI | Five GitHub Actions jobs in `.github/workflows/ci.yml` | Tests, rules, and analysis must fail closed before merge | Draft PR 13 run `32907722272` passed all jobs; deterministic analysis fixture active | Flutter version is unpinned; no format gate |
| Native release | Flutter Android/iOS shells and plugin registration | Store signing and native compilation are separate release gates | Source inspection and prior attempted builds | Android uses debug signing; Android SDK unavailable locally; inherited iOS Firestore Swift sources failed compile |

## System overview and architecture

The client is a repository-backed Flutter app with Riverpod dependency injection. There is no generated Riverpod code. `lib/app/providers.dart` declares repositories and derived providers by hand, which makes widget tests replace external boundaries cheaply.

Firestore uses flat top-level collections. Chants denormalize sport, competition, Team, and optional Player IDs so Team queries and cross-club discovery read one document type. Interactions also use top-level collections and deterministic IDs. This avoids subcollection traversal and makes global moderation queries possible, at the cost of repeated referential fields that rules must validate.

Cloud Functions own counter recomputation, report and feedback admission, moderation callables, rate-limit auto-hide, consent stamps, durable account deletion, and duplicate merge. All fifteen exported Functions are configured for `europe-west2` in `functions/src/index.ts`. Live deployment parity was not inspected.

### Critical path: create and browse a chant

1. `SubmitChantScreen` validates retained form fields, parses optional evidence, and performs the advisory duplicate lookup.
2. `ChantRepository.createChant` writes the Dart model to `chants`.
3. `firestore.rules :: chants` checks authentication, ban and policy state, community status, content values, zero counters, origin, evidence, and timestamps.
4. `onChantCreated` classifies account age and may auto-hide an over-limit submission.
5. Team and Player queries project status through `lib/data/services/chant_browse.dart :: projectChants`; Discover performs a separate full visible fetch and shuffle.

Step 3 now enforces exact keys, types, bounds, Team and Player relationships, no direct media, and empty v1 variations. The 135-case rules suite includes hostile raw SDK payloads so the public parser boundary is tested independently of the form.

### Critical path: vote and reconcile

1. `VoteControls` records intent and displays an optimistic delta.
2. `VoteRepository` creates, updates, or deletes `votes/{uid}_{chantId}`.
3. `handleVoteWritten` queries all votes for that chant, computes absolute up, down, and score values, and batches the chant update with `appliedValue` on the vote.
4. The live chant stream and private vote read reconcile the local state.

The absolute recompute is idempotent under duplicate trigger delivery. Both vote and like handlers now no-op before aggregate work when the parent is absent, so delayed deletion-trigger delivery does not recreate or retry a missing target.

### Critical path: report and moderate

1. The client sends domain-only report or feedback fields to `submitReport` or `submitFeedback`.
2. `functions/src/safety_submission.ts` validates the current profile and target, applies a private anchored-window budget transactionally, and stores server-owned identity, time, and state.
3. `recomputeReportCount` counts pending rows in a transaction and updates the target absolute `flagCount`.
4. Crossing three pending reports auto-hides, never auto-removes.
5. Operators call `onModerationAction`; the Function rechecks Firestore role and deletion state, applies the action, resolves reports where required, and writes `auditLog`.
6. Visible query streams remove the content. Discover distinguishes permission denial from transient failure, and detail actions require a current visible live value even when route text remains readable.

### Critical path: save for matchday

1. A Team or detail screen requests a fresh server-visible set.
2. `SavedSongbookService` projects only required public reading fields into a bounded snapshot.
3. `SavedSongbookRepository` serializes the mutation and asks `FileSongbookStorage` for atomic replacement.
4. Saved routes load only local data and expose refresh date and device-copy semantics.

No Firestore document, Function, rule, index, background task, or cloud sync is involved.

### Critical path: delete an account

1. `AccountDeletionService` stages the active UID's local Songbook behind a tombstone.
2. `deleteAccount` transactionally creates `accountDeletionJobs/{uid}` and marks an existing profile pending, then returns durable acceptance.
3. The client finalizes the unreadable local tombstone and signs out. Failure before acceptance restores the exact staged bytes.
4. `onAccountDeletionJobWritten` advances one bounded phase or 200-row page per retry-enabled event.
5. Auth is disabled first. Private interactions are deleted, retained contributions are anonymized, and existing triggers converge counters from ground truth.
6. One deterministic audit is written, Auth is deleted, and the profile plus job are deleted atomically. Missing Auth or duplicate delivery is a successful no-op.

## Feature and subsystem implementation choices

| Choice | Reason | Rejected alternative | Consequence and evidence |
|---|---|---|---|
| Songbook and Chant Lab split by stored status | Archive truth and creative popularity are different meanings | One blended feed | `docs/decisions/004-songbook-and-chant-lab.md`; browse projection tests |
| Optional evidence at post, mandatory for user promotion | Fans may know a chant without having a clip; canonical status must remain factual | Require every submitter to find a link, or let votes verify | `docs/decisions/006-chant-provenance-and-evidence.md`; trust tests |
| Explicit stable IDs for seeded chants | Title edits must not orphan interactions, saves, or future links | Title-derived IDs | `docs/decisions/005-explicit-seeded-chant-identity.md`; seed rename red guard |
| Ground-truth counter recompute | At-least-once delivery made increments drift | Blind `FieldValue.increment` | Functions burst, duplicate, and no-op tests |
| One direct reply level | Retention benefit without a deep moderation graph | Unlimited nesting or flat comments only | `docs/decisions/002-comment-reply-depth-and-retention.md`; reply rules and goldens |
| Device-local saved snapshots | Stadium connectivity is unreliable; v1 does not need cloud sync complexity | Generic favorites or Firestore sync | `docs/decisions/003-saved-matchday-songbook.md`; persistence tests |
| Native text share with no current URL | A useful chant can be sent now without a dead web destination | Guessed URL, direct social SDK, generated image | `docs/changes/2026-08-24-basic-share-out.md`; payload and gateway tests |
| Fail-soft cached browse | Ordinary network errors should not erase readable chants | Clear all data on any error | Team, Player, and Discover transient-error tests | Permission denial separately removes Discover and live action authority |
| Callable-only safety intake | Abuse must be rejected before storage and trigger cost | Post-write rate repair | Decision 010; atomic budget and rejected-non-consumption tests |
| Durable bounded deletion job | Auth cannot remain the retry token after Auth is deleted | One long callable or restart-from-zero retry | Decision 011; page, race, failure, and Auth-finalization tests |

Decision 009 records the durable cross-service contract introduced by the remediation: exact parser-safe direct writes, server-owned reconciliation stamps, and separation of readable fallback from live action authority.

## Data, state, and external effects

### Persistent state

- **Firebase Auth:** account identity.
- **Firestore reference data:** sports, competitions, Teams, Players.
- **Firestore content:** chants, comments, replies through `parentCommentId`.
- **Firestore interactions:** votes, likes, reports, blocks, feedback.
- **Firestore authority and audit:** profiles, audit log, private safety-rate rows, and private account-deletion jobs.
- **Device filesystem:** Saved Matchday Songbook JSON and deletion tombstones.

No media bytes are hosted. `storage.rules` denies all access. External evidence opens in YouTube or X; native share hands plain text to a user-selected operating-system destination.

### Lifecycle and deletion

Remote account deletion intentionally retains anonymized chants and comments as community content. A durable private job disables Auth, deletes votes, likes, reports, feedback, blocks, private safety state, Auth, and profile, then removes itself. Local deletion stages and removes the matching UID's Saved Songbook only after durable acceptance. The user-facing dialog in `lib/presentation/home/home_screen.dart :: _showDeleteAccountDialog` states that retained and removed boundary, and `AccountDeletionPendingScreen` is the fail-closed fallback for a retained session.

Merge is a separate destructive content lifecycle. It rekeys child interactions sequentially, then deletes the source. Saved device snapshots and any future public links do not migrate. Its audit data cannot recreate every source field or reverse target dedup decisions.

### Retention and export

No repository retention job exists for audit or feedback. No user-data export exists. No backup or restore configuration is checked in. Those are operational and regulatory gaps, not hidden implementation features.

## Invariants and failure behavior

| Invariant | Current enforcement | Review result |
|---|---|---|
| A direct client cannot set role, ban, consent, age, or report-count authority | Exact profile schema and update allowlist in rules | PASS |
| A rule-valid public document must deserialize in the shipped Dart client | Exact user chant keys, types, bounds, hierarchy, media, and variations checks | PASS, 135-case hostile rules suite |
| Function-owned reconciliation fields cannot be client-authored | Vote and like create omit `appliedValue`; update may change only `value` | PASS |
| Hidden or removed content disappears from actionable live browse | Query removal plus permission-denied, absence, hidden, and removed Discover handling | PASS |
| External sharing uses a current visible chant | All live-target actions require active, error-free, current visible data | PASS |
| Duplicate trigger delivery converges | Absolute counter recomputes and transactional report counts | PASS |
| A child trigger tolerates a missing parent | Vote and comment-like parent guards run before aggregate work | PASS |
| One reply level only | `validReplyParent` checks parent visibility, Team relation, and parent depth | PASS |
| Failed network reads do not escape as unhandled UI errors | Like hydration retries after contained failure; failed Undo shows recovery copy | PASS in focused widget tests |
| Launch viewport and enlarged text do not overflow | Empty comments pass at 390 by 844 and 1.8x; stale Player golden inspected | PASS for remediated states |
| Saved content is UID-isolated and bounded | Access callback, encoded file name, schema, count, and byte bounds | PASS in repository tests |
| Accepted deletion no longer depends on client auth or uptime | Durable job, pending marker, retry-enabled worker, Auth-missing tolerance, atomic finalization | PASS in Functions failure-injection and Flutter lifecycle tests |
| Pending deletion cannot create new active data | Rules require no job and absent-or-false pending state; touched callables check pending; app gate precedes Home | PASS in rules, Functions, and app-gate tests |
| Stable seed identity survives title edits | Explicit source ID plus preflight and transaction recheck | PASS locally; live preflight unverified |
| A green analysis job means analysis ran | CI writes secret or deterministic example, then always invokes analysis | PASS by workflow inspection and PR 13 clean-runner result |
| Store release uses production signing | Android release explicitly selects debug signing | **FAIL, release gate** |

## Security and privacy

Firestore rules deny unmatched paths. Privileged client writes are constrained, public content visibility is rule-enforced, private interaction reads are owner/operator only, and callable operators are reauthorized server-side.

Direct-write structural validation now matches the shipped client capability. Chants, comments, votes, and likes reject unknown or wrongly typed fields; chant references and v1 media and variations are constrained; and server reconciliation stamps are not client-owned. Reports and feedback are callable-only and atomically budgeted. Private safety-rate and account-deletion job paths deny all client access.

App Check is activated non-blockingly in `lib/main.dart`, with debug providers in debug and platform attestation in release. Whether enforcement is enabled in Firebase is unverified. Client Firebase identifiers are gitignored configuration, not Admin credentials. Seed Admin credentials are also gitignored; no credential file was read.

The app stores display names on comments and block rows. DOB is not stored. Saved Songbook files contain public reading snapshots scoped by UID but are not encrypted by application code. Protection at rest relies on the mobile operating system's application container.

No current dependency advisory conclusion is claimed. The audit request was blocked before completion because separate disclosure authorization was absent.

## Dependency, platform, and infrastructure inventory

| Surface | Declared dependency or config | Role | Current evidence and risk |
|---|---|---|---|
| Flutter/Dart | `pubspec.yaml`, SDK `^3.10.8` | Client runtime | Verified on Flutter 3.44.8 and Dart 3.12.2; CI uses movable stable |
| Riverpod | `flutter_riverpod ^2.6.1` | DI and async state | Hand-written providers; codegen packages are unused |
| Firebase client | core, auth, Firestore, Functions, App Check, Crashlytics | Auth, data, callable, integrity, errors | Native compilation incomplete; live enforcement unverified |
| `url_launcher ^6.3.2` | External evidence | Opens normalized provider URL | Failure translated in UI tests |
| `path_provider ^2.1.6` | Local Songbook | Application-support directory | Physical lifecycle unverified |
| `share_plus ^11.1.0` | Native share sheet | Plain-text operating-system handoff | Gateway and widgets pass; native compile/device gate pending |
| Functions Node 20 | `firebase-admin ^13`, `firebase-functions ^6.3` | Server authority | 69 local tests pass |
| Seed Node | `firebase-admin ^13` | Manual Admin writes | 42 tests and `tsc --noEmit` pass |
| Rules test | Firebase emulator, Java in CI and local Homebrew runtime | Authorization assertions | 135 passed locally and in PR 13 clean-runner CI |
| Android Gradle | AGP 8.11.1, Kotlin 2.2.20 | Android build | User has unstaged Crashlytics plugin changes; release signs debug |
| iOS | deployment target 15.0, CocoaPods scaffold | iOS build | Prior simulator compilation failed in inherited Cloud Firestore Swift package sources |

Removal and update ownership is Andrew's. Dependency freshness and advisories need a separately authorized maintenance pass before release.

## Performance, scale, and cost

No production metrics or cost exports were inspected. All scale statements below are code-derived.

- `ChantRepository.discoveryChants()` reads every visible chant, then shuffles client-side. Cost and latency grow linearly with the full archive.
- Vote and like Functions query every interaction row for the parent on each write. Correctness is strong; write amplification grows with popularity.
- Report transactions query every report row for the target. The deterministic reporter-target key bounds one account's contribution, not the number of accounts.
- `mergeChants` remains sequential and can exceed callable limits at volume. Account deletion is total-work linear but each retry invocation is capped at 200 matching rows plus one job heartbeat.
- Saved Songbook codec work is bounded at 500 unique chants and 2 MiB. The full suite measured a 500-chant encode/decode workload around 98 ms on this workstation, but timing is not a CI correctness gate.

Before public volume, establish query/read budgets for Discover and counters, Function error alerts including retained deletion jobs, and a resumable merge model.

## Verification performed

| Command or probe | Environment | Result | Claim supported |
|---|---|---|---|
| `flutter test` | Local macOS, Flutter 3.44.8 | PASS, 310 | Current combined Flutter suite, including pending-state golden |
| `flutter analyze lib test` | Same | PASS | Project Dart source has no analyzer issue |
| `flutter analyze` | Same, with ignored prior native-build outputs present | FAIL outside first-party source | Analyzer traversed `build/ios/SourcePackages` and reported third-party package example errors; clean-runner gate pending |
| `cd functions && npm test` | Node 20.20.2 | PASS, 69 | Extracted handlers compile and pass, including deletion state machine and failure recovery |
| `cd seed && npm test` | Node 20.20.2 | PASS, 42 | Seed identity, plan, validation, reconciliation |
| `cd seed && npx tsc --noEmit` | Node 20.20.2 | PASS | Full seed TypeScript type check |
| `git diff --check main...HEAD` | Git | PASS | Combined committed diff has no whitespace error |
| `firebase emulators:exec --only firestore ...` | Local OpenJDK 26, emulator 1.21.0 | PASS, 135 | Current shapes accepted; pending identities and private jobs denied |
| Discover and detail authority tests | Local Flutter renderer | PASS | Denial removes stale card; all live-target actions wait for current authority |
| comments resilience tests | Local Flutter renderer | PASS, 8 focused | Like-read retry, Undo failure, and 1.8x empty state are contained |
| submit tests and two goldens | Local Flutter renderer | PASS, 10 focused plus 2 goldens | Stale and failed Player data recover without assertion or clipping |
| `dart format --output=none --set-exit-if-changed lib test` | Dart 3.12.2 | FAIL, 56 files would change | Formatting is not normalized or gated; output mode preserved files |
| draft PR 13 implementation CI | GitHub Actions run `32907722272` on `98f2c9e` | PASS: 310 Flutter, analysis, 69 Functions, 42 seed, 135 rules | Clean Linux and Java evidence for the final runtime layer |

The earlier review probes supplied red evidence for stale Discover retention, escaping like hydration, and the 430-pixel overflow. The deletion block deliberately broke its 200-row bound, pending block denial, and pending app gate; each new guard failed for the intended reason before restoration. Permanent regression coverage passes. The final worktree contains the approved stack changes plus the same three pre-existing user modifications.

Skipped or blocked:

- Android build: no Android SDK.
- iOS build: prior inherited Cloud Firestore Swift package compile failure.
- External freeze review: pending against `c57815c...<final-pr-13-head>`.
- Live Firebase, deploy, seed, merge, release, and device actions: not authorized.
- npm production advisory audit: network failed in sandbox and elevated disclosure was rejected.

## Deployment, operations, and recovery

CI does not deploy. The repository identifies one Firebase project and no staging environment. The deletion-aware application rollout order is backward-compatible rules, Functions, then clients. Stable seed identity preflight must precede any remaining club write.

Healthy-state evidence is weak outside tests. Crashlytics records application errors, but no Function error alert, usage dashboard, release smoke test, or incident runbook is stored here. App Check, backup/PITR, API restrictions, billing, authentication templates, and deployed parity are dashboard-only and unverified.

Recovery paths:

- Code rollback: redeploy earlier rules/Functions; ship a new client build.
- Seed content: reproduce canonical source from reviewed JSON.
- Counter drift: `seed/reconcile.ts` repairs chant vote counters.
- Wrong hide/ban: operator unhide/unban paths exist and audit.
- Merge: no complete undo snapshot or resumable marker.
- Account deletion: durable bounded retry exists; permanently retained jobs still need alerting and an operator runbook.
- User data: no repository-backed backup restoration or export procedure.

## Documentation consistency

| Document or claim | Current source reality | Action |
|---|---|---|
| README test counts and feature status | Current counts are 310 Flutter, 135 rules, 69 Functions, and 42 seed; durable deletion is built | Corrected in this block |
| Roadmap freeze state | Final deletion feature block is packaged and clean-runner green; review and release gates remain | Corrected in this block |
| CI analysis state | Five jobs exist and analysis runs with secret or deterministic fixture | PR 13 run `32907722272` green |
| Function merge comments | Audit payload is bounded and cannot reverse the operation | Corrected source comments; historical archive retained |
| `docs/KNOWN_ISSUES.md` | Clearly labels itself a legacy snapshot | No longer an authority defect |
| `docs/CHANGE_SPEC.md` | Account-deletion recovery contract is approved, implemented, and clean-runner verified | Retain through independent review |

## Known compromises, gaps, and uncertainty

| Item | Consequence | Owner | Revisit trigger |
|---|---|---|---|
| Sequential merge | Partial merge can require manual repair | Andrew | Before volume or delegating moderation |
| No retained-deletion-job alert or console | A permanent worker failure depends on manual investigation | Andrew | Before public beta or first observed retained job |
| Android debug signing | Store release blocked | Andrew | Before production build |
| Placeholder policy | User consent and store compliance incomplete | Andrew | Before any public submission release |
| 56 files not formatter-normalized | Mechanical churn and inconsistent style | Andrew | Separate normalization commit before adding format gate |
| No staging, runbook, backup proof, or data export | Incident and regulatory recovery depend on manual console work | Andrew | Before public beta or real irreproducible content |
| Discover full fetch and ground-truth counter scans | Linear reads and write amplification | Andrew | When closed-beta metrics show meaningful volume |
| Dependency advisories unverified | Current supply-chain risk is unknown | Andrew | Separately authorize registry audit before release |

## Material files and generated artifacts

**Current authority and server logic**

- `firestore.rules`
- `functions/src/index.ts`
- `functions/src/account_deletion.ts`
- `functions/src/safety_submission.ts`
- `functions/src/chant_trust.ts`
- `functions/src/audit.ts`
- `firestore.indexes.json`
- `storage.rules`

**Load-bearing client boundaries**

- `lib/app/app.dart`, `providers.dart`, `policy.dart`
- `lib/data/models/chant.dart`, `saved_songbook.dart`, `user_profile.dart`
- `lib/data/repositories/chant_repository.dart`, `saved_songbook_repository.dart`, `songbook_storage.dart`
- `lib/data/services/account_deletion_service.dart`, `chant_browse.dart`, `chant_evidence.dart`, `chant_matcher.dart`, `chant_share.dart`, `saved_songbook_service.dart`
- `lib/presentation/browse/discovery_section.dart`, `team_screen.dart`, `player_screen.dart`, `chant_detail_screen.dart`
- `lib/presentation/comments/comment_section.dart`, `comment_card.dart`
- `lib/presentation/submit/submit_chant_screen.dart`
- `lib/presentation/moderation/moderation_screen.dart`
- `lib/presentation/auth/account_deletion_pending_screen.dart`

**Seed and tests**

- `seed/seed.ts`, `chant_identity.ts`, `seed_plan.ts`, `validate.ts`, `reconcile.ts`
- `seed_data/clubs/arsenal.json`
- `test/`, `functions/test/`, `test_rules/firestore_rules.test.ts`

**Process and review records**

- `.github/workflows/ci.yml`
- `AGENTS.md`
- `docs/CHANGE_SPEC.md`
- `docs/EXECUTION.md`
- `ENGINEERING_OVERVIEW.md`
- `docs/IMPLEMENTATION_RATIONALE.md`

Generated `build/`, `.dart_tool/`, `functions/lib-test/`, and dependency trees were excluded except where their existence affected a tool result.
