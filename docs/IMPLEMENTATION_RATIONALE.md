# Repository implementation rationale

> **Document contract:** This is the current milestone snapshot for the entire Chants repository. It covers inherited and newly stacked behavior. Preimplementation intent belongs in `docs/CHANGE_SPEC.md`, completed change reasoning in `docs/changes/`, durable decisions in `docs/decisions/`, and chronological evidence in `docs/EXECUTION.md`.

## Document identity and completeness

- **Product:** Chants, a Flutter and Firebase mobile app for learning trusted football chants and publishing new chant ideas.
- **External review boundary:** Claude independently reviewed `c57815c...f5cb748`, `f5cb748...c893cd0`, and `c893cd0...fe93e20`, then approved the final closure range `fe93e20...0b64dcf` with both prior findings closed and no new defect.
- **Current stack head:** Final merged `main` at `2df9fa04a839f88a19fe43c2bcc8ed9a583627c3`, plus the locally verified `codex/framework-ui-readiness` and bounded Home hierarchy changes.
- **Review type:** Current whole-project milestone snapshot after the independent freeze reviews, final stack merge, exact-main clean-runner CI, local interface readiness, and the approved Home hierarchy pass. It is not a native or release sign-off.
- **Coverage:** Flutter client, Cloud Functions, Firestore rules and tests, seed pipeline, native configuration, CI, framework docs, and release boundaries.
- **Excluded:** Vendored `node_modules`, generated Flutter and TypeScript output, live Firebase data and dashboard state, deployed artifacts, store dashboards, and operating-system device behavior.
- **Preserved unrelated work:** Andrew's older `android/app/build.gradle.kts`, `android/settings.gradle.kts`, `pubspec.lock`, and private freeze-note work remains untouched in its original worktree.
- **Current status:** The V1 engineering stack is merged and exact-main clean-runner green. Native compilation, the combined device walk, live stable-identity preflight, remaining verified seed, production configuration, signing, and release remain pending.

## Repository coverage ledger

| Capability | Behavior and key paths | Authority and invariant | Verification | Current gap |
|---|---|---|---|---|
| Auth | Email/password sign-up, sign-in, reset, sign-out in `lib/presentation/auth/` and `lib/data/repositories/auth_repository.dart` | Firebase Auth owns identity; client never chooses privileged role or ban state | Flutter auth and gate tests | Reset-email template behavior remains dashboard-only and unverified |
| Age and consent | Local DOB check, stored 17-plus boolean, versioned policy gate in `lib/data/services/age.dart`, `lib/app/app.dart`, `functions/src/index.ts :: acceptPolicy` | DOB is not stored; policy version and acceptance time are server-written | Flutter, Functions, and rules tests | Actual policy copy is still a placeholder |
| Profiles and roles | Owner profile plus operator moderation identity in `profiles` | Owners can edit only display name and update time; role, ban, age, consent, and report count are pinned by `firestore.rules :: profiles` | Rules suite; ban handler tests | Dashboard-created operator bootstrap and second-account device proof unverified |
| Browse and discovery | Home matchday utility, Premier League entry, one Terrace Proven and one Chant Lab preview, competition, Team, Player, Songbook, Discover, and broad search in `lib/presentation/home/` and `lib/presentation/browse/` | Existing providers and routes remain authoritative; visible queries constrain hidden and removed; permission denial removes Discover cards; cache stays readable but cannot authorize live actions; presentation never mutates repository-owned lists | Core Home exact-route, search, signed-state, 1.8x, and golden tests plus competition, player, ranking, cache-authority, and identity tests | Full Discover fetch remains a scale boundary; native visual sign-off remains pending |
| Submission | Required origin, title, lyrics, tune, subject, style; optional evidence in `SubmitChantScreen` | Exact parser-safe user schema; Team and optional Player relationship; community, no direct media, empty variations | Flutter and 136-case rules suite | No author flow to attach evidence later; invalid legacy rows require normalization before direct edit |
| Provenance and evidence | Honest labels, canonical YouTube/X normalization, evidence-gated promotion in `chant_evidence.dart`, `chant_trust.ts` | Votes never prove terrace use; user content needs valid evidence plus operator review for canonical status | Dart, Functions, rules, and golden tests | No author flow to attach evidence later |
| Duplicate nudge | Advisory token matcher and explicit continue/view/back flow in `SubmitChantScreen :: _reviewLikelyDuplicates` | Failure of an advisory read cannot block posting | Matcher and submit widget tests | No open implementation gap in v1 boundary |
| Voting | Optimistic up/down/clear with transactional Function recompute in `vote_controls.dart`, `vote_repository.dart`, `handleVoteWritten` | Deterministic vote ID; client changes only intent; Function owns `appliedValue`; parent serializes overlapping aggregates; widget work stays with captured chant ID | Vote widget identity, repository, concurrency, duplicate, burst, and hostile rules cases | Transactional aggregate query cost grows with popularity |
| Comments and replies | Ranked parents, one chronological reply level, likes, report, delete, block in `comment_section.dart` and `comment_card.dart` | Visible same-chant top-level parent; both block directions; background hydration and Undo failures contained; stream generation cannot cross chant IDs | Model, identity, enlarged-text, golden, Functions, and rules tests | No open v1 correctness gap in this reviewed boundary |
| Reports and feedback | Callable-only admission, one report per reporter/target, shared anchored report budget, independent feedback budget, content auto-hide at 3 pending reports | Server owns identity, time, state, bounded ID, and atomic admission; pending profiles or deletion jobs reject new against-user rows; deleting or missing reporters receive redacted audit rows | Functions, Flutter failure-state, and hostile rules tests | Limits need closed-beta tuning; App Check enforcement remains live configuration |
| Moderation | Hide, unhide, remove, promote, demote, evidence removal, ban, unban in callable and operator screen | Callable derives actor from auth and re-reads operator role; audit is Admin-written | Pure trust and ban handlers, rules operator reads | Full callable and `mergeChants` lack end-to-end tests; queue query remains narrow |
| Merge | `mergeChants` retains the old sequential implementation behind a failed-precondition stop after operator authorization | No merge mutation is permitted until resumable recovery and a privacy-safe audit payload have a separate approved design | Freeze-guard test, TypeScript compilation, and source review | Existing implementation is sequential and non-resumable; legacy audit detail embeds authored source fields and raw `createdBy` |
| Account deletion | Durable request plus 17-phase bounded worker in `functions/src/account_deletion.ts`; prepared recovery plus pending and unknown app gates; three-state local acknowledgement; classified audit cleanup | Prepared local state actively recovers; unknown response locks local data and persistently gates Home; only callable success or positive pending state advances cleanup; reachable operator writers retain reviewed generated detail under `deleted-operator`; report and unknown text is removed; disposed Home is never touched by a late deletion error | Functions failure injection and mixed audit-page tests, 136-case rules suite, Flutter same-process lifecycle, disposed-Home, and reconstruction tests, and two inspected goldens | Target-side safety history may retain the account ID; disabled legacy merge detail is a re-enable privacy gate; no operator recovery console or retained-job alert; no undo by design; no time-based audit retention policy |
| Saved Matchday Songbook | UID-isolated bounded local JSON snapshots, explicit refresh, offline read-only routes | Maximum 500 unique chants and 2 MiB; active matching UID; case-safe SHA-256 path; unknown deletion state unreadable; accepted marker removed after every other artifact | Model, repository, migration, service, widget, lifecycle, SHA-boundary, and golden tests | Physical force-stop/airplane-mode persistence unverified; no cross-device sync by design |
| Share-out | Plain-text native sheet from live detail in `chant_share.dart` and `chant_detail_screen.dart` | No public URL or delivery claim; every live-target action requires server-confirmed non-cache visible authority | Payload, gateway, cache authority, enlarged-text, and golden tests | Native device destination behavior unverified |
| Seed | Explicit stable chant IDs, read-only preflight, transaction ownership recheck, validation, orphan report | Source content is human supplied; seed may transform but never invent lyrics or context | 42 seed tests plus TypeScript | Only Arsenal JSON exists; no live preflight or remaining club write ran |
| CI | Six GitHub Actions jobs in the readiness branch's `.github/workflows/ci.yml` | Tests, rules, analysis, project memory, and prose style must fail closed before merge | Final-main run `32993748570` at `2df9fa0` passed the original five jobs; PR 15 run `33011415224` proved governance, analysis, Functions, seed, and rules | Replacement Flutter evidence is pending after measured golden calibration; Flutter version is unpinned; no Dart format gate |
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

Step 3 now enforces exact keys, types, bounds, Team and Player relationships, no direct media, and empty v1 variations. The 136-case rules suite includes hostile raw SDK payloads so the public parser boundary is tested independently of the form.

### Critical path: vote and reconcile

1. `VoteControls` records intent and displays an optimistic delta.
2. `VoteRepository` creates, updates, or deletes `votes/{uid}_{chantId}`.
3. `handleVoteWritten` transactionally reads the parent and all votes for that chant, computes absolute up, down, and score values, then writes the parent and a still-matching `appliedValue` stamp.
4. The live chant stream and private vote read reconcile the local state.

The absolute recompute is idempotent under duplicate trigger delivery. The parent transaction also serializes overlapping handlers, so an older query cannot overwrite a newer aggregate without retrying. Both vote and like handlers no-op inside the transaction when the parent is absent.

### Critical path: report and moderate

1. The client sends domain-only report or feedback fields to `submitReport` or `submitFeedback`.
2. `functions/src/safety_submission.ts` validates the current profile and target, rejects a pending user profile or existing deletion job plus path-sized IDs, applies a private anchored-window budget transactionally, and stores server-owned identity, time, and state.
3. `recomputeReportCount` counts pending rows in a transaction and updates the target absolute `flagCount`.
4. Crossing three pending reports auto-hides, never auto-removes.
5. Report triggers transactionally classify the reporter as active or deleting before writing `auditLog`; pending or missing reporters receive no UID or report text.
6. Operators call `onModerationAction`; the Function rechecks Firestore role and deletion state, applies the action, resolves reports where required, and writes `auditLog`.
7. Visible query streams remove the content. Discover distinguishes permission denial from transient failure, and detail actions require a server-confirmed non-cache current visible value even when route or cache text remains readable.

### Critical path: save for matchday

1. A Team or detail screen requests a fresh server-visible set.
2. `SavedSongbookService` projects only required public reading fields into a bounded snapshot.
3. `SavedSongbookRepository` serializes the mutation and asks `FileSongbookStorage` for atomic replacement under a lowercase SHA-256 UID key.
4. Saved routes load only local data and expose refresh date and device-copy semantics.

No Firestore document, Function, rule, index, background task, or cloud sync is involved.

### Critical path: delete an account

1. `AccountDeletionService` prepares the active UID's local Songbook, then marks it unknown before awaiting the request.
2. `deleteAccount` transactionally creates `accountDeletionJobs/{uid}` and marks an existing profile pending, then returns durable acceptance.
3. Explicit callable success moves local state to accepted, permits cleanup, and signs out. A thrown response remains unknown, locked, signed in, and retryable because it does not prove rejection. If a positive pending profile replaces Home before that response arrives, both error paths stop at the mounted guard before touching Riverpod or scaffold state.
4. `onAccountDeletionJobWritten` advances one bounded phase or 200-row page per retry-enabled event.
5. Auth is disabled first. Private interactions are deleted, retained contributions are anonymized, and existing triggers converge counters from ground truth.
6. Audit rows authored by the user are classified in bounded pages. Reachable generated operator actions keep their detail under `deleted-operator`; report and unknown text is replaced; self-target policy acceptance loses its target UID. Delayed report triggers also redact against pending or missing profile state. The disabled legacy merge detail is documented separately because it contains authored source fields and raw creator identity.
7. One non-identifying completion audit is written in the same transaction that advances the job phase, Auth is deleted, and the profile plus job are deleted atomically. Missing Auth or duplicate delivery is a successful no-op.
8. Prepared local state actively recovers before Home without relaunch. Local recovery failure remains behind a real retry action. Unknown state gates Home behind deletion retry; a positive pending profile can advance local accepted cleanup, while a negative observation never restores uncertain data.

## Feature and subsystem implementation choices

| Choice | Reason | Rejected alternative | Consequence and evidence |
|---|---|---|---|
| Songbook and Chant Lab split by stored status | Archive truth and creative popularity are different meanings | One blended feed | `docs/decisions/004-songbook-and-chant-lab.md`; browse projection tests |
| Optional evidence at post, mandatory for user promotion | Fans may know a chant without having a clip; canonical status must remain factual | Require every submitter to find a link, or let votes verify | `docs/decisions/006-chant-provenance-and-evidence.md`; trust tests |
| Explicit stable IDs for seeded chants | Title edits must not orphan interactions, saves, or future links | Title-derived IDs | `docs/decisions/005-explicit-seeded-chant-identity.md`; seed rename red guard |
| Parent-serialized ground-truth counter recompute | At-least-once delivery made increments drift, and absolute batches still allowed stale concurrent overwrite | Blind increment or query-plus-batch | Decision 013; duplicate, burst, missing-parent, and controlled overlap tests |
| One direct reply level | Retention benefit without a deep moderation graph | Unlimited nesting or flat comments only | `docs/decisions/002-comment-reply-depth-and-retention.md`; reply rules and goldens |
| Device-local saved snapshots | Stadium connectivity is unreliable; v1 does not need cloud sync complexity | Generic favorites or Firestore sync | `docs/decisions/003-saved-matchday-songbook-offline-v1.md`; persistence tests |
| Native text share with no current URL | A useful chant can be sent now without a dead web destination | Guessed URL, direct social SDK, generated image | `docs/changes/2026-08-24-basic-share-out.md`; payload and gateway tests |
| Fail-soft cached browse without cache authority | Ordinary network errors should not erase readable chants, but cache cannot prove moderation state | Clear all data or trust every active stream | Decision 015; metadata, transient-error, action-gate, and existing-local-save tests |
| Callable-only safety intake | Abuse must be rejected before storage and trigger cost | Post-write rate repair | Decision 010; atomic budget and rejected-non-consumption tests |
| Durable bounded deletion job plus three-state client acknowledgement | Auth cannot remain the retry token, and a lost response cannot prove request rejection | One long callable, restart-from-zero retry, restore-on-throw, or restore-on-false-profile | Decisions 011 and 012; page, race, failure, persistent unknown, positive reconciliation, and retry tests |
| Classified audit cleanup during deletion | Report rows were deleted but audit retained reporter identity and text; uniform cleanup later erased operator provenance | Delete all audit history, preserve raw operator UID, or flatten every actor row | Decision 016; mixed bounded-page, delayed-trigger, and completion retry tests; future merge detail remains fail-closed behind a privacy re-review gate |
| Lowercase SHA-256 UID storage key | Base64 case distinctions can collapse on case-insensitive filesystems | Raw or lowercased reversible UID encoding | Decision 014; vector, collision-pair, and migration tests |

Decision 009 records exact parser-safe direct writes and server-owned reconciliation stamps. Decisions 012 through 015 refine destructive acknowledgement, transactional aggregates, local UID identity, and cache-provenance authority.

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

Remote account deletion intentionally retains anonymized chants and comments as community content. A durable private job disables Auth, deletes votes, likes, reports, feedback, blocks, and private safety state, classifies audit rows authored by the user, deletes Auth and profile, then removes itself. Known operator actions retain generated detail under a non-identifying operator sentinel. Authored reports and unknown action text are replaced. Audit rows about the deleted account may remain when another actor created them, including its target ID. Local deletion can restore prepared state after a pre-network failure, removes the matching UID's Saved Songbook only after positive acceptance, and preserves unreadable unknown state for persistent retry after an unconfirmed response. The dialog, `AccountDeletionRecoveryScreen`, and `AccountDeletionPendingScreen` state the retained, removed, and uncertain boundaries.

Merge is a separate destructive content lifecycle. The retained implementation rekeys child interactions sequentially, then deletes the source; its audit data cannot reverse target dedup decisions. The callable now stops with failed-precondition before target parsing or mutation, after operator authorization, until a resumable design is approved.

### Retention and export

No time-based repository retention job exists for audit or feedback. Raw deleted actor identity and user-authored report text are redacted. Known operator actions retain trusted generated detail under `deleted-operator`, and target-side safety history may retain the account ID. No user-data export exists. No backup or restore configuration is checked in. Those are operational and regulatory gaps, not hidden implementation features.

## Invariants and failure behavior

| Invariant | Current enforcement | Review result |
|---|---|---|
| A direct client cannot set role, ban, consent, age, or report-count authority | Exact profile schema and update allowlist in rules | PASS |
| A rule-valid public document must deserialize in the shipped Dart client | Exact user chant keys, types, bounds, hierarchy, media, and variations checks | PASS, 136-case hostile rules suite |
| Function-owned reconciliation fields cannot be client-authored | Vote and like create omit `appliedValue`; update may change only `value` | PASS |
| Hidden or removed content disappears from actionable live browse | Query removal plus permission-denied, absence, hidden, and removed Discover handling | PASS |
| External sharing uses a server-confirmed current visible chant | All live-target actions require active, error-free, non-cache visible data | PASS |
| Duplicate and overlapping trigger delivery converge | Parent-serialized absolute counter transactions | PASS, including controlled older-after-newer overlap |
| A child trigger tolerates a missing parent | Vote and comment-like parent guards run inside the aggregate transaction | PASS |
| One reply level only | `validReplyParent` checks parent visibility, Team relation, and parent depth | PASS |
| Failed network reads do not escape as unhandled UI errors | Like hydration retries after contained failure; failed Undo shows recovery copy | PASS in focused widget tests |
| Launch viewport and enlarged text do not overflow | Empty comments pass at 390 by 844 and 1.8x; stale Player golden inspected | PASS for remediated states |
| Saved content is UID-isolated and bounded | Access callback, SHA-256 filename, schema, count, and byte bounds | PASS in repository and migration tests |
| Prepared state recovers and ambiguous acknowledgement cannot restore or discard local data | Serialized prepared recovery, unknown and accepted storage states, and local-state app gate | PASS across same-process recovery, repository reconstruction, relaunch, positive reconciliation, and retry |
| Completion audit writes exactly once without embedding the deleted UID | Completion audit and phase advancement share one transaction | PASS after duplicate worker delivery |
| Accepted deletion no longer depends on client auth or uptime | Durable job, pending marker, retry-enabled worker, Auth-missing tolerance, atomic finalization | PASS in Functions failure-injection and Flutter lifecycle tests |
| Pending deletion cannot create new active or against-user data | Rules require no job and absent-or-false pending state; user-report admission checks both target sources; app gate precedes Home | PASS in rules, Functions, and app-gate tests |
| Deleted reporters do not remain linked to audit reason text | Bounded audit phase plus transactional pending or missing reporter classification | PASS in page and delayed-audit tests |
| Stable seed identity survives title edits | Explicit source ID plus preflight and transaction recheck | PASS locally; live preflight unverified |
| A green analysis job means analysis ran | CI writes secret or deterministic example, then always invokes analysis | PASS by workflow inspection and PR 14 clean-runner result |
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
| Functions Node 20 | `firebase-admin ^13`, `firebase-functions ^6.3` | Server authority | 78 local tests pass |
| Seed Node | `firebase-admin ^13` | Manual Admin writes | 42 tests and `tsc --noEmit` pass |
| Rules test | Firebase emulator, Java in CI and local Homebrew runtime | Authorization assertions | 136 passed locally and on final merged `main` at `2df9fa0` |
| Android Gradle | AGP 8.11.1, Kotlin 2.2.20 | Android build | User has unstaged Crashlytics plugin changes; release signs debug |
| iOS | deployment target 15.0, CocoaPods scaffold | iOS build | Prior simulator compilation failed in inherited Cloud Firestore Swift package sources |

Removal and update ownership is Andrew's. Dependency freshness and advisories need a separately authorized maintenance pass before release.

## Performance, scale, and cost

No production metrics or cost exports were inspected. All scale statements below are code-derived.

- `ChantRepository.discoveryChants()` reads every visible chant, then shuffles client-side. Cost and latency grow linearly with the full archive.
- Vote and like Functions query every interaction row for the parent on each write. Correctness is strong; write amplification grows with popularity.
- Report transactions query every report row for the target. The deterministic reporter-target key bounds one account's contribution, not the number of accounts.
- The retained `mergeChants` implementation remains sequential and could exceed callable limits, so the callable is disabled. Account deletion is total-work linear but each retry invocation is capped at 200 matching rows plus one job heartbeat.
- Saved Songbook codec work is bounded at 500 unique chants and 2 MiB. The current full suite measured a 500-chant encode/decode workload around 122 ms on this workstation, but timing is not a CI correctness gate.

Before public volume, establish query/read budgets for Discover and counters, Function error alerts including retained deletion jobs, and a resumable merge model.

## Verification performed

| Command or probe | Environment | Result | Claim supported |
|---|---|---|---|
| `flutter test` | Local macOS, Flutter 3.44.8 | PASS, 353 | Current combined Flutter suite, including Home hierarchy and routes, core journey, both disposed-Home error classes, same-process prepared recovery, persistent unknown state, cache-local actions, identity, and goldens |
| scoped `flutter analyze` over the Home change boundary | Same | PASS | Home runtime and focused tests have no analyzer issue |
| `cd functions && npm test` | Node 20.20.2 | PASS, 78 | Extracted handlers compile and pass, including classified audit cleanup, duplicate completion delivery, delayed audit privacy, target job denial, counter overlap, merge stop, deletion, and safety boundaries |
| `cd seed && npm test` | Node 20.20.2 | PASS, 42 | Seed identity, plan, validation, reconciliation |
| `cd seed && npx tsc --noEmit` | Node 20.20.2 | PASS | Full seed TypeScript type check |
| `git diff --check` | Git | PASS after final documentation refresh | Current worktree diff has no whitespace error |
| `firebase emulators:exec --only firestore ...` | Local OpenJDK 26, emulator 1.21.0 | PASS, 136 | Current shapes accepted; pending target block is denied |
| final closure Flutter regressions | Local Flutter renderer | RED at both disposed-Consumer invalidations, then PASS, 19 app-gate tests | Both late error classes leave the pending screen authoritative and never touch disposed Home state |
| post-review Functions regressions | Local Node | PASS, 15 focused | Classified audit pages, duplicate completion delivery, and delayed audit privacy hold |
| core-journey and inherited authority suites | Local Flutter | PASS, 24 focused after a pre-fix immutable-list failure | Home, competition, player, cached authority, and Songbook entry states hold |
| Home hierarchy and inherited authority suites | Local Flutter | PASS | Exact utility, competition, chant, and account routes hold; normal and 1.8x Home layouts remain scrollable; signed-state, search, authority, and card behavior remain intact |
| scoped formatting over touched Dart files | Dart 3.12.2 | PASS, no changes required | Readiness Dart files are formatted without normalizing inherited files |
| project memory and writing checks | Local POSIX shell | PASS after each rejected its temporary known-bad fixture | Framework governance is executable and fail-closed locally |
| repository formatter measurement | Dart 3.12.2, read-only output | Expected nonzero, 41 of 143 | Current residual measured without writing files; earlier 46-of-142 result remains historical |
| Final-main clean-runner CI | GitHub Actions run `32993748570` on `2df9fa04a839f88a19fe43c2bcc8ed9a583627c3` | PASS: Flutter, analysis, Functions, seed, and 136 rules | Clean Linux and Java evidence for the exact merged V1 engineering stack |

The earlier freeze blocks captured red evidence before their implementations. The final closure also proved both disposed-Home error paths red before moving the mounted guard, then passed the focused and complete matrix. The readiness baseline then reproduced mutation of an immutable competition snapshot before the list-copy correction. The merged stack and its exact-main clean-runner result remain the remote baseline for the locally verified interface branch.

Skipped or blocked:

- Android build: no Android SDK.
- iOS build: prior inherited Cloud Firestore Swift package compile failure.
- Independent freeze reviews: completed against `c57815c...f5cb748`, `f5cb748...c893cd0`, `c893cd0...fe93e20`, and final closure `fe93e20...0b64dcf`.
- Live Firebase, deploy, seed, merge, release, and device actions: not authorized.
- npm production advisory audit: network failed in sandbox and elevated disclosure was rejected.

## Deployment, operations, and recovery

CI does not deploy. The repository identifies one Firebase project and no staging environment. The deletion-aware application rollout order is backward-compatible rules, Functions, then clients. Stable seed identity preflight must precede any remaining club write.

Healthy-state evidence is weak outside tests. Crashlytics records application errors, and `docs/RUNBOOK.md` now records source-backed first response and recovery. No Function error alert, usage dashboard, or release smoke test is stored here. App Check, backup/PITR, API restrictions, billing, authentication templates, and deployed parity are dashboard-only and unverified.

Recovery paths:

- Code rollback: redeploy earlier rules/Functions; ship a new client build.
- Seed content: reproduce canonical source from reviewed JSON.
- Counter drift: `seed/reconcile.ts` repairs chant vote counters.
- Wrong hide/ban: operator unhide/unban paths exist and audit.
- Merge: callable is disabled; no complete undo snapshot or resumable marker exists, and its legacy audit payload must be redesigned before re-enable.
- Account deletion: durable bounded retry and a source-backed runbook exist; permanently retained jobs still need alerting and verified operator recovery in the deployed environment.
- User data: no repository-backed backup restoration or export procedure.

## Documentation consistency

| Document or claim | Current source reality | Action |
|---|---|---|
| README test counts and feature status | Interface and Home-hierarchy branch passes 353 Flutter; final freeze baseline passes 136 rules, 78 Functions, and 42 seed; exact merged `main` passed CI | Distinguishes local branch evidence from run `32993748570` at `2df9fa0` |
| Roadmap freeze state | Stack PRs 4 through 10 and 12 through 14 are merged; exact-main CI is green | Corrected in the framework-alignment preparation |
| CI analysis and governance state | Final main has five green jobs; readiness branch defines a sixth governance job | PR 15 run `33011415224` passed governance, analysis, Functions, seed, and rules; replacement Flutter evidence is pending |
| Function merge comments | Audit payload is bounded and cannot reverse the operation | Corrected source comments; historical archive retained |
| `docs/KNOWN_ISSUES.md` | Clearly labels itself a legacy snapshot | No longer an authority defect |
| `docs/CHANGE_SPEC.md` | Approved V1 Home hierarchy contract | Packaged in draft PR 15; replacement clean-runner CI pending |

## Known compromises, gaps, and uncertainty

| Item | Consequence | Owner | Revisit trigger |
|---|---|---|---|
| Disabled sequential merge and unsafe legacy audit detail | Duplicate merge is unavailable until recovery and privacy-safe audit retention are designed | Andrew | Separately approve a resumable merge and re-review its audit allowlist before enabling |
| No retained-deletion-job alert or console | A permanent worker failure depends on manual investigation | Andrew | Before public beta or first observed retained job |
| Android debug signing | Store release blocked | Andrew | Before production build |
| Placeholder policy | User consent and store compliance incomplete | Andrew | Before any public submission release |
| 41 of 143 Dart files not formatter-normalized | Mechanical churn and inconsistent style | Andrew | Separate normalization commit before adding format gate |
| No staging, tested operational alerts, backup proof, or data export | Incident and regulatory recovery depend on manual console work | Andrew | Before public beta or real irreproducible content |
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
- `lib/data/services/account_deletion_service.dart`, `sha256.dart`, `chant_browse.dart`, `chant_evidence.dart`, `chant_matcher.dart`, `chant_share.dart`, `saved_songbook_service.dart`
- `lib/presentation/browse/discovery_section.dart`, `team_screen.dart`, `player_screen.dart`, `chant_detail_screen.dart`
- `lib/presentation/comments/comment_section.dart`, `comment_card.dart`
- `lib/presentation/submit/submit_chant_screen.dart`
- `lib/presentation/moderation/moderation_screen.dart`
- `lib/presentation/auth/account_deletion_recovery_screen.dart`, `account_deletion_pending_screen.dart`

**Seed and tests**

- `seed/seed.ts`, `chant_identity.ts`, `seed_plan.ts`, `validate.ts`, `reconcile.ts`
- `seed_data/clubs/arsenal.json`
- `test/`, `functions/test/`, `test_rules/firestore_rules.test.ts`

**Process and review records**

- `.github/workflows/ci.yml`
- `AGENTS.md`
- `docs/PROJECT_PROFILE.md`
- `docs/RUNBOOK.md`
- `docs/CHANGE_SPEC.md`
- `docs/EXECUTION.md`
- `docs/INTERFACE.md`
- `docs/mockups/`
- `docs/changes/2026-08-26-v1-core-journey-interface-readiness.md`
- `docs/changes/2026-08-26-v1-home-hierarchy-refresh.md`
- `ENGINEERING_OVERVIEW.md`
- `docs/IMPLEMENTATION_RATIONALE.md`

Generated `build/`, `.dart_tool/`, `functions/lib-test/`, and dependency trees were excluded except where their existence affected a tool result.
