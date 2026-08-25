# Repository implementation rationale

> **Document contract:** This is the current milestone snapshot for the entire Chants repository. It covers inherited and newly stacked behavior. Preimplementation intent belongs in `docs/CHANGE_SPEC.md`, completed change reasoning in `docs/changes/`, durable decisions in `docs/decisions/`, and chronological evidence in `docs/EXECUTION.md`.

## Document identity and completeness

- **Product:** Chants, a Flutter and Firebase mobile app for learning trusted football chants and publishing new chant ideas.
- **Reviewed baseline:** `b72f4abddea0cd8a3b201de2d4dda246c62a413c`, the exact head of stacked draft PR 9 on 2026-08-25.
- **Comparison base:** `main` at `f780628`; 136 changed paths, 14,557 insertions, and 1,546 deletions.
- **Review type:** Whole-project stacked engineering review before the combined device walk, not a release sign-off.
- **Coverage:** Flutter client, Cloud Functions, Firestore rules and tests, seed pipeline, native configuration, CI, framework docs, and release boundaries.
- **Excluded:** Vendored `node_modules`, generated Flutter and TypeScript output, live Firebase data and dashboard state, deployed artifacts, store dashboards, and operating-system device behavior.
- **Preserved unrelated work:** `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` were already modified and remain unstaged.
- **Current status:** Existing automated suites are green. Material remediation is proposed in `docs/CHANGE_SPEC.md`; implementation is not approved by this review alone.

## Repository coverage ledger

| Capability | Behavior and key paths | Authority and invariant | Verification | Current gap |
|---|---|---|---|---|
| Auth | Email/password sign-up, sign-in, reset, sign-out in `lib/presentation/auth/` and `lib/data/repositories/auth_repository.dart` | Firebase Auth owns identity; client never chooses privileged role or ban state | Flutter auth and gate tests | Reset-email template behavior remains dashboard-only and unverified |
| Age and consent | Local DOB check, stored 17-plus boolean, versioned policy gate in `lib/data/services/age.dart`, `lib/app/app.dart`, `functions/src/index.ts :: acceptPolicy` | DOB is not stored; policy version and acceptance time are server-written | Flutter, Functions, and rules tests | Actual policy copy is still a placeholder |
| Profiles and roles | Owner profile plus operator moderation identity in `profiles` | Owners can edit only display name and update time; role, ban, age, consent, and report count are pinned by `firestore.rules :: profiles` | Rules suite; ban handler tests | Dashboard-created operator bootstrap and second-account device proof unverified |
| Browse and discovery | Home, competition, Team, Player, Songbook, Chant Lab, Discover, search in `lib/presentation/browse/` | Visible queries must constrain hidden and removed; canonical and community status project to distinct surfaces | Ranking, Team, Player, and golden tests | Discover retains a stale card after a permission-denied document stream |
| Submission | Required origin, title, lyrics, tune, subject, style; optional evidence in `SubmitChantScreen` | User creates community content only; evidence is optional at admission | Flutter and rules tests | Rule-valid malformed typed fields can crash client deserialization; stale prefilled player can assert |
| Provenance and evidence | Honest labels, canonical YouTube/X normalization, evidence-gated promotion in `chant_evidence.dart`, `chant_trust.ts` | Votes never prove terrace use; user content needs valid evidence plus operator review for canonical status | Dart, Functions, rules, and golden tests | No author flow to attach evidence later |
| Duplicate nudge | Advisory token matcher and explicit continue/view/back flow in `SubmitChantScreen :: _reviewLikelyDuplicates` | Failure of an advisory read cannot block posting | Matcher and submit widget tests | `docs/ROADMAP.md` still incorrectly calls the frontend missing |
| Voting | Optimistic up/down/clear with Function recompute in `vote_controls.dart`, `vote_repository.dart`, `handleVoteWritten` | Deterministic vote ID; displayed score equals server score plus intended minus confirmed vote | Large vote widget suite and 6 Functions cases | Vote rules let owner mutate Function-owned `appliedValue`; missing parent guard races merge deletion |
| Comments and replies | Ranked parents, one chronological reply level, likes, report, delete, block in `comment_section.dart` and `comment_card.dart` | Rules validate visible same-chant top-level parent and both block directions | Model, widget, golden, Functions, and rules tests | Failed per-comment like read escapes unhandled; empty state overflows enlarged text; Undo failure is untranslated |
| Reports | One report per reporter/target, chant/comment auto-hide at 3 pending reports, user reports inform operators | Counts recompute from pending ground truth; automatic action hides only | Functions and rules tests | No velocity limit; report schemas and reason lengths are incomplete |
| Moderation | Hide, unhide, remove, promote, demote, evidence removal, ban, unban in callable and operator screen | Callable derives actor from auth and re-reads operator role; audit is Admin-written | Pure trust and ban handlers, rules operator reads | Full callable and `mergeChants` lack end-to-end tests; queue query remains narrow |
| Merge | Operator moves votes, reports, comments/replies and deletes duplicate source in `mergeChants` | Same-Team check; deterministic interaction keys dedupe target rows | TypeScript compilation and source review | Sequential and non-resumable; delayed vote trigger can fail on deleted source; audit payload is partial |
| Account deletion | Remove interactions/reports/blocks, anonymize contributions, delete Auth and profile in `deleteAccount` | Auth is deleted before profile so an Auth failure retains a retryable profile | Account-deletion service tests and source inspection | Eleven sequential steps, no durable progress or end-to-end retry test |
| Saved Matchday Songbook | UID-isolated bounded local JSON snapshots, explicit refresh, offline read-only routes | Maximum 500 unique chants and 2 MiB; local actions require active matching UID | Model, repository, service, widget, lifecycle, and golden tests | Physical force-stop/airplane-mode persistence unverified; no cross-device sync by design |
| Share-out | Plain-text native sheet from live detail in `chant_share.dart` and `chant_detail_screen.dart` | No public URL today; no delivery claim; hidden or removed live data cannot share | Payload, gateway, widget, enlarged-text, and golden tests | Route initial data can enable Share before current live confirmation when reached from stale Discover |
| Seed | Explicit stable chant IDs, read-only preflight, transaction ownership recheck, validation, orphan report | Source content is human supplied; seed may transform but never invent lyrics or context | 42 seed tests plus TypeScript | Only Arsenal JSON exists; no live preflight or remaining club write ran |
| CI | Five GitHub Actions jobs in `.github/workflows/ci.yml` | Tests and rules must fail closed before merge | Exact-head PR 9 CI previously green | Analyze exits 0 when config secret is absent; Flutter version is unpinned; no format gate |
| Native release | Flutter Android/iOS shells and plugin registration | Store signing and native compilation are separate release gates | Source inspection and prior attempted builds | Android uses debug signing; Android SDK unavailable locally; inherited iOS Firestore Swift sources failed compile |

## System overview and architecture

The client is a repository-backed Flutter app with Riverpod dependency injection. There is no generated Riverpod code. `lib/app/providers.dart` declares repositories and derived providers by hand, which makes widget tests replace external boundaries cheaply.

Firestore uses flat top-level collections. Chants denormalize sport, competition, Team, and optional Player IDs so Team queries and cross-club discovery read one document type. Interactions also use top-level collections and deterministic IDs. This avoids subcollection traversal and makes global moderation queries possible, at the cost of repeated referential fields that rules must validate.

Cloud Functions own counter recomputation, moderation callables, rate-limit auto-hide, consent stamps, account deletion, and duplicate merge. Every exported Function is configured for `europe-west2` in `functions/src/index.ts`. Live deployment parity was not inspected.

### Critical path: create and browse a chant

1. `SubmitChantScreen` validates retained form fields, parses optional evidence, and performs the advisory duplicate lookup.
2. `ChantRepository.createChant` writes the Dart model to `chants`.
3. `firestore.rules :: chants` checks authentication, ban and policy state, community status, content values, zero counters, origin, evidence, and timestamps.
4. `onChantCreated` classifies account age and may auto-hide an over-limit submission.
5. Team and Player queries project status through `lib/data/services/chant_browse.dart :: projectChants`; Discover performs a separate full visible fetch and shuffle.

The direct-write schema check at step 3 is incomplete relative to the direct casts at step 5. That mismatch is the most important P1 review finding.

### Critical path: vote and reconcile

1. `VoteControls` records intent and displays an optimistic delta.
2. `VoteRepository` creates, updates, or deletes `votes/{uid}_{chantId}`.
3. `handleVoteWritten` queries all votes for that chant, computes absolute up, down, and score values, and batches the chant update with `appliedValue` on the vote.
4. The live chant stream and private vote read reconcile the local state.

The absolute recompute is idempotent under duplicate trigger delivery. The parent-existence assumption is not safe under merge deletion and needs the same guard already used by comment likes.

### Critical path: report and moderate

1. A deterministic report row is created by the appropriate repository.
2. `recomputeReportCount` counts pending rows in a transaction and updates the target absolute `flagCount`.
3. Crossing three pending reports auto-hides, never auto-removes.
4. Operators call `onModerationAction`; the Function rechecks Firestore role, applies the action, resolves reports where required, and writes `auditLog`.
5. Visible query streams should remove the content. The current Discover single-document fallback violates this final disappearance step.

### Critical path: save for matchday

1. A Team or detail screen requests a fresh server-visible set.
2. `SavedSongbookService` projects only required public reading fields into a bounded snapshot.
3. `SavedSongbookRepository` serializes the mutation and asks `FileSongbookStorage` for atomic replacement.
4. Saved routes load only local data and expose refresh date and device-copy semantics.

No Firestore document, Function, rule, index, background task, or cloud sync is involved.

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
| Fail-soft cached browse | Ordinary network errors should not erase readable chants | Clear all data on any error | Team and Player retained-data tests | Permission-denied moderation must be handled separately from ordinary failure |

No new durable architectural decision is needed for the remediation proposal. It restores existing rules-authority, moderation-disappearance, server-bookkeeping, and accessibility invariants.

## Data, state, and external effects

### Persistent state

- **Firebase Auth:** account identity.
- **Firestore reference data:** sports, competitions, Teams, Players.
- **Firestore content:** chants, comments, replies through `parentCommentId`.
- **Firestore interactions:** votes, likes, reports, blocks, feedback.
- **Firestore authority and audit:** profiles and audit log.
- **Device filesystem:** Saved Matchday Songbook JSON and deletion tombstones.

No media bytes are hosted. `storage.rules` denies all access. External evidence opens in YouTube or X; native share hands plain text to a user-selected operating-system destination.

### Lifecycle and deletion

Remote account deletion intentionally retains anonymized chants and comments as community content. It deletes votes, likes, reports, feedback, blocks, Auth, and profile. Local deletion stages and removes the matching UID's Saved Songbook. The user-facing dialog in `lib/presentation/home/home_screen.dart :: _showDeleteAccountDialog` states that retained and removed boundary.

Merge is a separate destructive content lifecycle. It rekeys child interactions sequentially, then deletes the source. Saved device snapshots and any future public links do not migrate. Its audit data cannot recreate every source field or reverse target dedup decisions.

### Retention and export

No repository retention job exists for audit or feedback. No user-data export exists. No backup or restore configuration is checked in. Those are operational and regulatory gaps, not hidden implementation features.

## Invariants and failure behavior

| Invariant | Current enforcement | Review result |
|---|---|---|
| A direct client cannot set role, ban, consent, age, or report-count authority | Exact profile schema and update allowlist in rules | PASS |
| A rule-valid public document must deserialize in the shipped Dart client | Partial chant validation versus direct casts in `Chant.fromJson` | **FAIL, P1** |
| Function-owned reconciliation fields cannot be client-authored | Client omits `appliedValue`, but vote and like rules allow it | **FAIL, P1 hardening** |
| Hidden or removed content disappears from actionable live browse | Team and Player query removal; Discover falls back on permission error | **FAIL, P1** |
| External sharing uses a current visible chant | Share disables on active stream error, but route initial data is actionable before first confirmation | **FAIL, P1 race** |
| Duplicate trigger delivery converges | Absolute counter recomputes and transactional report counts | PASS |
| A child trigger tolerates a missing parent | Comment-like guard exists; vote guard does not | **FAIL, P1 during merge** |
| One reply level only | `validReplyParent` checks parent visibility, Team relation, and parent depth | PASS |
| Failed network reads do not escape as unhandled UI errors | Main comments stream handles errors; per-comment like read does not | **FAIL, P2** |
| Launch viewport and enlarged text do not overflow | Most focused screens pass; empty comment Row fails at 1.8x | **FAIL, P2** |
| Saved content is UID-isolated and bounded | Access callback, encoded file name, schema, count, and byte bounds | PASS in repository tests |
| Stable seed identity survives title edits | Explicit source ID plus preflight and transaction recheck | PASS locally; live preflight unverified |
| A green analysis job means analysis ran | CI exits 0 when Firebase secret is absent | **FAIL, release gate** |
| Store release uses production signing | Android release explicitly selects debug signing | **FAIL, release gate** |

## Security and privacy

Firestore rules deny unmatched paths. Privileged client writes are constrained, public content visibility is rule-enforced, private interaction reads are owner/operator only, and callable operators are reauthorized server-side.

The main security weakness is structural validation. A permitted authenticated writer can currently shape some fields outside the client model contract. For chants, that can convert one malicious document into a query-wide client error. For reports and feedback, absent exact keys and size/type constraints increase storage abuse and operator-parser risk. `docs/CHANGE_SPEC.md` defines exact schema parity and hostile raw-write tests as the first remediation slice.

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
| Functions Node 20 | `firebase-admin ^13`, `firebase-functions ^6.3` | Server authority | 35 local tests pass |
| Seed Node | `firebase-admin ^13` | Manual Admin writes | 42 tests and `tsc --noEmit` pass |
| Rules test | Firebase emulator, Java 21 in CI | Authorization assertions | 117 passed on exact-head clean CI; local Java unavailable |
| Android Gradle | AGP 8.11.1, Kotlin 2.2.20 | Android build | User has unstaged Crashlytics plugin changes; release signs debug |
| iOS | deployment target 15.0, CocoaPods scaffold | iOS build | Prior simulator compilation failed in inherited Cloud Firestore Swift package sources |

Removal and update ownership is Andrew's. Dependency freshness and advisories need a separately authorized maintenance pass before release.

## Performance, scale, and cost

No production metrics or cost exports were inspected. All scale statements below are code-derived.

- `ChantRepository.discoveryChants()` reads every visible chant, then shuffles client-side. Cost and latency grow linearly with the full archive.
- Vote and like Functions query every interaction row for the parent on each write. Correctness is strong; write amplification grows with popularity.
- Report transactions query every report row for the target. The deterministic reporter-target key bounds one account's contribution, not the number of accounts.
- `mergeChants` and `deleteAccount` perform sequential per-document operations and can exceed callable limits at volume.
- Saved Songbook codec work is bounded at 500 unique chants and 2 MiB. The full suite measured a 500-chant encode/decode workload around 98 ms on this workstation, but timing is not a CI correctness gate.

Before public volume, establish query/read budgets for Discover and counters, Function error alerts, and a resumable destructive-work model.

## Verification performed

| Command or probe | Environment | Result | Claim supported |
|---|---|---|---|
| `flutter test` | Local macOS, Flutter 3.44.8 | PASS, 271 | Current committed Flutter suite |
| `flutter analyze lib test` | Same | PASS | Project Dart source has no analyzer issue |
| `cd functions && npm test` | Node 20.20.2 | PASS, 35 | Extracted handlers compile and pass |
| `cd seed && npm test` | Node 20.20.2 | PASS, 42 | Seed identity, plan, validation, reconciliation |
| `cd seed && npx tsc --noEmit` | Node 20.20.2 | PASS | Full seed TypeScript type check |
| `git diff --check main...HEAD` | Git | PASS | Combined committed diff has no whitespace error |
| temporary Discover permission-error widget test | Local Flutter renderer | RED as expected | `_LiveChantCard` retains moderated initial data |
| temporary detail stream-revocation share test | Local Flutter renderer | PASS | Active stream error clears current data and disables Share |
| temporary comment like-read failure test | Local Flutter renderer | RED as expected | `_loadUserLike` leaks the read error |
| temporary empty-comments 1.8x test | 390 by 844 logical viewport | RED as expected, 430 px overflow | Empty Row is not responsive |
| `dart format --output=none --set-exit-if-changed lib test` | Dart 3.12.2 | FAIL, 56 files would change | Formatting is not normalized or gated; output mode preserved files |
| exact-head draft PR 9 CI | GitHub Actions | Previously PASS: Flutter, analyze, Functions, seed, 117 rules | Clean Linux and Java-backed existing-suite evidence |

Temporary probes were removed. `git status` returned to only the three pre-existing user modifications.

Skipped or blocked:

- Local rules emulator: no Java runtime.
- Android build: no Android SDK.
- iOS build: prior inherited Cloud Firestore Swift package compile failure.
- Live Firebase, deploy, seed, merge, release, and device actions: not authorized.
- npm production advisory audit: network failed in sandbox and elevated disclosure was rejected.

## Deployment, operations, and recovery

CI does not deploy. The repository identifies one Firebase project and no staging environment. The safe application rollout order is indexes, rules, Functions, then clients. Stable seed identity preflight must precede any remaining club write.

Healthy-state evidence is weak outside tests. Crashlytics records application errors, but no Function error alert, usage dashboard, release smoke test, or incident runbook is stored here. App Check, backup/PITR, API restrictions, billing, authentication templates, and deployed parity are dashboard-only and unverified.

Recovery paths:

- Code rollback: redeploy earlier rules/Functions; ship a new client build.
- Seed content: reproduce canonical source from reviewed JSON.
- Counter drift: `seed/reconcile.ts` repairs chant vote counters.
- Wrong hide/ban: operator unhide/unban paths exist and audit.
- Merge: no complete undo snapshot or resumable marker.
- Account deletion: no resumable marker or compensating end-to-end recovery.
- User data: no repository-backed backup restoration or export procedure.

## Documentation consistency

| Document or claim | Current source reality | Action |
|---|---|---|
| `README.md` says 182 Flutter, 106 rules, 26 Functions, 23 seed tests | Exact reviewed counts are 271, 117, 35, and 42 | Correct in a documentation cleanup after remediation scope approval |
| `README.md` says remaining v1 work still needs explicit Songbook/Lab | Songbook/Lab, saved copies, and share are implemented in the stack | Correct status copy |
| `docs/ROADMAP.md` says duplicate matcher frontend is missing | `SubmitChantScreen :: _reviewLikelyDuplicates` is wired and tested | Correct roadmap state |
| `docs/ROADMAP.md` says CI is in progress | Five-job CI exists; fail-open analysis remains | State CI as shipped with an open gate defect |
| `functions/src/index.ts` and historical docs call merge payload full | Payload omits evidence, origin, variations, media URLs, counters, flags, dates, visibility, and interactions | Remove full/undo claim; retain historical archive with supersession note |
| `docs/KNOWN_ISSUES.md` | Clearly labels itself a legacy snapshot | No longer an authority defect |
| `docs/CHANGE_SPEC.md` | Share spec was complete and has a completed change record | Replaced by proposed stacked remediation contract |

## Known compromises, gaps, and uncertainty

| Item | Consequence | Owner | Revisit trigger |
|---|---|---|---|
| Raw-write schema gaps | Malformed visible content can fail typed query mapping; arbitrary payload increases abuse surface | Andrew | Immediate, active remediation |
| Discover moderation retention | Hidden content remains rendered and can route to stale detail | Andrew | Immediate, active remediation |
| Vote missing-parent trigger guard | Merge-related delete trigger can retry/fail on deleted source | Andrew | Before any live merge, active remediation |
| Comment like read error and empty-state overflow | Unhandled error telemetry and inaccessible enlarged-text state | Andrew | Active remediation |
| No report/feedback velocity limit | Automated accounts can create storage and moderation load | Andrew | Before public launch or any abuse signal |
| Sequential merge and deletion | Partial destructive workflow can require manual repair | Andrew | Before volume or delegating moderation |
| Android debug signing | Store release blocked | Andrew | Before production build |
| Placeholder policy | User consent and store compliance incomplete | Andrew | Before any public submission release |
| Fail-open analysis job | Green CI may not mean analysis ran | Andrew | Active remediation |
| 56 files not formatter-normalized | Mechanical churn and inconsistent style | Andrew | Separate normalization commit before adding format gate |
| No staging, runbook, backup proof, or data export | Incident and regulatory recovery depend on manual console work | Andrew | Before public beta or real irreproducible content |
| Discover full fetch and ground-truth counter scans | Linear reads and write amplification | Andrew | When closed-beta metrics show meaningful volume |
| Dependency advisories unverified | Current supply-chain risk is unknown | Andrew | Separately authorize registry audit before release |

## Material files and generated artifacts

**Current authority and server logic**

- `firestore.rules`
- `functions/src/index.ts`
- `functions/src/chant_trust.ts`
- `functions/src/audit.ts`
- `firestore.indexes.json`
- `storage.rules`

**Load-bearing client boundaries**

- `lib/app/app.dart`, `providers.dart`, `policy.dart`
- `lib/data/models/chant.dart`, `saved_songbook.dart`
- `lib/data/repositories/chant_repository.dart`, `saved_songbook_repository.dart`, `songbook_storage.dart`
- `lib/data/services/chant_browse.dart`, `chant_evidence.dart`, `chant_matcher.dart`, `chant_share.dart`, `saved_songbook_service.dart`
- `lib/presentation/browse/discovery_section.dart`, `team_screen.dart`, `player_screen.dart`, `chant_detail_screen.dart`
- `lib/presentation/comments/comment_section.dart`, `comment_card.dart`
- `lib/presentation/submit/submit_chant_screen.dart`
- `lib/presentation/moderation/moderation_screen.dart`

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
