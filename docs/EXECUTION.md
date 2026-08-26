# Execution log

This is the chronological evidence trail for substantial engineering work. It records what happened, not private reasoning.

## Rules

- Start an entry for every Lane 1-3 change and other multi-step task that changes repository or external state.
- Timestamp material actions in UTC and distinguish planned, attempted, completed, failed, skipped, and blocked work.
- Record commands, targets, meaningful results, artifacts, approvals, blockers, and final state.
- Never record prompts, chain-of-thought, secrets, credentials, personal data, or raw production payloads.
- Preserve prior entries. Correct an error with a dated correction instead of silently rewriting history.
- Archive closed entries intact under `docs/execution/YYYY-MM.md` when this file becomes hard to scan.

## Entries

### 2026-08-25T10:25:44Z Implement stacked v1 authority and integration remediation

- **Status:** Implemented and locally verified; independent review and clean-runner CI pending
- **Scope:** Implement the exact approved Lane 2 schema, moderation, live-action, comments, stale Player, vote-trigger, CI, test, and framework-record boundary. No Firebase deployment or data access, live seed action, native build, device action, merge, signing, or release.
- **Reference:** `docs/CHANGE_SPEC.md`, decision 009
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 09:05:00 | Received Andrew's exact approval and preserved the existing worktree boundary | Local repository | Approved with `approved stacked v1 authority and integration remediation spec`. Preserved the user's existing Gradle and lockfile changes unstaged. |
| 09:15:00 | Implemented exact direct-write schemas and client write parity | Firestore rules and Dart repositories | Added parser-safe chant, vote, comment-like, comment, report, and feedback shapes; Team and Player relationships; server-owned reconciliation stamps; and transactional vote and like intent writes. |
| 09:32:00 | Implemented moderation and current-live action authority | Discover and chant detail | Permission denial, current absence, hidden, and removed states now fail closed. Ordinary transient Discover failure retains safe content. Live Save, Share, Report, Vote, and Comment actions wait for current visible authority. |
| 09:47:00 | Implemented comments, submission, trigger, and CI resilience | Flutter, Functions, GitHub Actions | Contained retryable like hydration and Undo failure, fixed enlarged empty layout, added stale Player recovery, guarded missing vote parent before query and batch, corrected merge comments, and made analysis use a deterministic checked-in fixture when no secret exists. |
| 10:08:00 | Ran focused and subsystem verification | Local macOS and Node 20 | Focused authority, share, comments, submission, golden, and regression groups passed. Functions passed 36 and seed passed 42. Rules TypeScript compiled. |
| 10:21:00 | Started the real local Firestore emulator with the available Homebrew Java runtime | Local OpenJDK 26 and Firestore emulator 1.21.0 | First run exposed one author-update rule path over the 1,000-expression limit and one legacy-shaped positive fixture. Removed redundant exact-key work and made the positive fixture current-schema. |
| 10:23:00 | Reran the complete Java-backed rules suite | Local Firestore emulator | PASS, 131 assertions. Hostile shapes, types, timestamps, hierarchy, media, variations, reports, feedback, and reconciliation stamps fail closed; current client shapes pass. |
| 10:25:44 | Ran final Flutter, analysis, rules compilation, and diff checks; refreshed durable records | Local macOS, Flutter 3.44.8 | `flutter test` passed 282; `flutter analyze lib test`, rules `tsc --noEmit`, and `git diff --check` passed. A separate repository-wide analysis attempt traversed ignored `build/ios/SourcePackages` from the earlier failed native build and reported third-party example errors; no first-party analyzer issue was reported. Added decision 009, completed-change rationale, interface and learning memory, and milestone corrections. |

- **Files/artifacts:** Runtime and test paths named in the approved spec, two submission goldens, decision 009, `docs/changes/2026-08-25-stacked-v1-authority-integration-remediation.md`, refreshed milestone docs, and this execution entry.
- **Skipped or blocked:** Native Android and iOS compilation, live Firebase inspection, stable-ID preflight, seed writes, deployment, merge, signing, release, and device walkthrough were not authorized or remain separate gates.
- **Final state:** Approved implementation is locally green with 282 Flutter, 131 rules, 36 Functions, and 42 seed tests. No commit, push, or PR update has been made for this block.
- **Follow-up:** Obtain independent review and clean-runner CI, whose clean checkout will prove the workflow's repository-wide `flutter analyze`, then perform the combined native and device walkthrough before release.

### 2026-08-25T08:50:37Z Review the combined v1 feature stack

- **Status:** Whole-project review completed; Lane 2 remediation proposed and pending approval
- **Scope:** Review the exact combined state of stacked draft PRs 4 through 9 across Flutter, Functions, Firestore rules, seed, native configuration, CI, tests, and current framework records. Refresh the two canonical milestone documents and replace the completed share spec with the resulting remediation proposal. No runtime fix, Firebase access, deployment, seed write, merge, release, or device action.
- **Reference:** `ENGINEERING_OVERVIEW.md`, `docs/IMPLEMENTATION_RATIONALE.md`, `docs/CHANGE_SPEC.md`
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 07:10:00 | Created `codex/v1-stacked-engineering-review` from exact PR 9 head `b72f4ab` and established the comparison boundary | Local repository | Combined stack contains 136 changed paths, 14,557 insertions, and 1,546 deletions relative to `main`. Preserved the user's pre-existing `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` modifications unstaged. |
| 07:18:00 | Inspected application, repository, model, rules, Functions, seed, CI, native, test, and framework boundaries | Local repository | Confirmed the implemented provenance, duplicate nudge, browse split, saved snapshots, share gateway, stable identity, replies, blocks, and moderation paths. Identified raw-write/model schema mismatch, Discover moderation retention, vote parent-deletion race, comments failure/overflow, stale Player prefill, fail-open analysis, debug release signing, and placeholder policy. |
| 07:45:00 | Probed live-detail share revocation with a temporary focused widget test | Local Flutter renderer | Probe passed: after a current stream value followed by an error, the snapshot no longer supplies current data and Share disables. Removed the temporary test. This rejected the initial broader hypothesis and narrowed the defect to stale route data before current confirmation and Discover retention. |
| 07:55:00 | Probed per-comment like hydration failure | Local Flutter renderer | Deliberately throwing from `getUserLike` failed with an unhandled `StateError` from `CommentSection._loadUserLike`. Removed the temporary test after recording the red result. |
| 08:02:00 | Probed the empty-comments state at 390 by 844 and 1.8x text | Local Flutter renderer | Failed with a 430-pixel right `RenderFlex` overflow. Removed the temporary test after recording the red result. |
| 08:15:00 | Probed moderation revocation in the real Discover widget | Local Flutter renderer | A permission-style stream error left `MODERATED CHANT` rendered because `_LiveChantCard` restored `initialChant`. Removed the temporary test after the expected red result. |
| 08:25:00 | Ran the available full local correctness matrix | Local macOS, Flutter 3.44.8, Dart 3.12.2, Node 20.20.2 | `flutter test` passed 271; `flutter analyze lib test` passed; Functions passed 35; seed passed 42; seed `tsc --noEmit` passed; `git diff --check main...HEAD` passed. Local rules emulator remained blocked by missing Java; exact-head PR 9 CI had previously passed 117 Java-backed assertions. |
| 08:32:00 | Checked formatter conformance without writing files | Local Dart tool | `dart format --output=none --set-exit-if-changed lib test` reported 56 committed files would change. Output mode preserved the worktree. Recorded formatter normalization as separate debt because mixing 56 mechanical rewrites into authority remediation would obscure review. |
| 08:36:00 | Attempted a current production npm advisory check | npm advisory endpoint | Sandboxed Functions and seed checks failed DNS. The elevated request was rejected because it would disclose dependency metadata to a public service without separate explicit authorization. Did not retry or work around the denial; advisory status remains unverified. |
| 08:50:37 | Refreshed the whole-project truth and drafted the remediation boundary | Local repository | Replaced stale amendment-style milestone docs with current exact-head overview and rationale. Replaced the completed share spec with a proposed Lane 2 exact-schema, moderation, trigger, comments, submission, CI, and documentation contract. No runtime, rules, Functions, CI, or release implementation was made. |

- **Files/artifacts:** `ENGINEERING_OVERVIEW.md`, `docs/IMPLEMENTATION_RATIONALE.md`, proposed `docs/CHANGE_SPEC.md`, and this execution entry.
- **Skipped or blocked:** Local rules emulator, Android and iOS native compilation, dependency advisory audit, live Firebase inspection, stable-ID preflight, seed writes, deployment, merge, signing, release, and device walk.
- **Final state:** Review complete and evidenced. Existing suites are green, but the stack is not release-ready. Runtime remediation waits for Andrew's explicit approval of `docs/CHANGE_SPEC.md`.
- **Follow-up:** Approve or revise the stacked v1 authority and integration remediation spec. Then implement that bounded block, require Java-backed clean-runner rules evidence, and perform the combined native/device walk only after the code stack is review-clean.

### 2026-08-25T00:08:50Z Implement V1 basic share-out

- **Status:** implemented and clean-runner verified; native compilation, review, and device walk pending
- **Scope:** Specify and implement a stacked Lane 2 native text share from live chant detail with honest provenance, a no-dead-link fallback, bounded failure behavior, and no backend or analytics. No public route, Firebase, deployment, merge, or release change.
- **Reference:** `docs/CHANGE_SPEC.md`, decision 004
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 00:08:50 | Created `codex/v1-basic-share-out` from Saved Matchday Songbook closure commit `c3bb8a0`; inspected the roadmap, product spec, accepted decisions, current detail and route composition, model limits, dependencies, platform versions, tests, interface memory, learnings, and user-owned worktree changes | Local repository | Completed. Confirmed basic share-out is the last independent V1 interaction block, live detail has Save and Report but no Share, the app and workspace have no public chant resolver, `chantsfc.com` is documented as coming soon, and Android Gradle plus unrelated lockfile changes remain unstaged. |
| 00:08:50 | Read the current Codex engineering, delivery, CI, change-spec, execution, and interface framework contracts | Local framework source and project memory | Completed. Classified the block as Lane 2 because the native share sheet is an external platform side effect and public chant URLs become a durable cross-product contract once enabled. |
| 00:08:50 | Compared maintained native-share package versions and platform requirements | Official `share_plus` package documentation and repository | Completed. Version 11.1.0 supports Flutter 3.22+, Dart 3.4+, iOS 12+, Java 17, Android Gradle Plugin 8.3+, and Gradle 8.4+. Current latest majors require Android Gradle Plugin 8.12.1, above the repository's tracked 8.11.1 and inside a user-modified file. Selected compatible major 11 and required a non-zero `sharePositionOrigin` for iPad safety. |
| 00:08:50 | Replaced the branch-local active specification with the exact basic share-out technical contract | Local repository | Completed as proposed. Runtime implementation remains intentionally absent until Andrew approves the payload, trust wording, compatible dependency, no-dead-link behavior, native failure boundary, interface placement, and verification contract. |
| 00:21:21 | Received Andrew's explicit approval of the exact basic share-out specification | Codex task and local repository | Approved for repository implementation and local or clean-runner verification. Firebase access, a public website route, deep-link configuration, analytics, deployment, merge, release, and production observation remain unauthorized. |
| 00:41:42 | Implemented the approved payload, native gateway, provider, and live-detail action | Local repository | Added a pure text payload with exact trust wording and optional HTTPS validation, a replaceable `share_plus 11.1.0` gateway, a non-zero source-rectangle guard, and one disabled-while-pending Share action between Save and Report. Current wiring supplies no public URL and no backend or analytics changed. |
| 00:41:42 | Added and corrected focused verification | Local Flutter test environment | The final focused share suite passed 16 tests. Initial runs correctly exposed a missing explicit semantics label and a stream-test timing error. An enlarged-text attempt also surfaced an inherited empty-comment row overflow outside this action; the focused 1.8x test now includes one short comment so it isolates the three app-bar controls without hiding that separate issue. |
| 00:41:42 | Proved a real regression guard | Local Flutter test environment | Temporarily removing main lyrics from the production payload made the exact builder test fail for the missing lyrics. Restoring the approved payload made the same focused test pass. |
| 00:41:42 | Ran the available repository verification matrix and inspected the visual | Local repository | `flutter test` passed 271 tests; `flutter analyze lib test` reported no issues; Functions passed 35; seed passed 42; rules TypeScript compiled with exit 0. The 390 by 844 chant-detail golden was generated and visually inspected with no visible clipping or crowding. The Java-backed Firestore emulator was not run locally because Java is unavailable; rules and backend are untouched and clean-runner CI remains the independent gate. |
| 00:41:42 | Attempted both native compilation gates | Local macOS environment | Android debug compilation was blocked before build because no Android SDK is configured. The iOS simulator build reached Xcode but failed inside Cloud Firestore 6.4.1 Swift Package sources with missing Objective-C initializers, not inside the share package. Flutter had automatically begun converting the inherited CocoaPods project to Swift Package Manager before that failure. |
| 00:41:42 | Removed native-project mutations created by the failed iOS attempt | Local repository | Restored every tracked iOS project file exactly to branch HEAD and deleted the generated SwiftPM resolution files. No unrelated Flutter migration or lockfile collapse remains in the share diff. Native compilation stays a release blocker, not a claimed pass. |
| 00:48:21 | Opened stacked draft PR 9 and inspected the first clean-runner result | GitHub Actions run `32794917851` | Functions, seed, 117 Firestore rules assertions, and Flutter analysis passed. Of 271 Flutter tests, 270 passed and only the new golden failed at a measured 1.85% macOS-to-Ubuntu renderer difference against the shared 1.5% threshold. All new functional share tests passed. |
| 00:48:21 | Applied the existing measured golden-drift control | Local repository | Set only the share-detail golden to 1.9%, 0.05 percentage points above its observed benign difference. The shared 1.5% default and known-bad comparator guard remain unchanged. Replacement clean-runner evidence is pending. |
| 00:52:03 | Verified the bounded visual control in replacement clean-runner CI | GitHub Actions run `32795153302` | All five jobs passed: 271 Flutter tests, Flutter analysis, 35 Functions tests, 42 seed tests, and 117 Java-backed Firestore rules assertions. Draft PR 9 remains unreviewed and unmerged; native compilation and the device destination walk remain pending. |

- **Files/artifacts:** Proposed `docs/CHANGE_SPEC.md` and this execution entry only.
- **Skipped or blocked:** No public chant URL exists, so the approved current build remains text-only. Firebase access, website work, deployment, merge, release, and external-destination testing remain outside this implementation pass.
- **Final state:** Exact contract approved. Repository implementation and verification are in progress.
- **Follow-up:** Implement and verify the approved boundary, prepare the scoped change rationale and interface record, then prepare a stacked draft PR.

### 2026-08-22T18:05:48Z Implement V1 Saved Matchday Songbook

- **Status:** completed in repository and CI, PR review pending
- **Scope:** Prepare a stacked Lane 2 contract for UID-scoped, device-local Saved Matchday Songbook persistence, server refresh, account-deletion cleanup, and offline interface behavior. No runtime, dependency, Firebase, backend, rules, seed, deployment, merge, or release change.
- **Reference:** `docs/CHANGE_SPEC.md`, decision 003
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 18:05:48 | Created `codex/v1-saved-matchday-songbook` from browse closure commit `b18c52a`; inspected accepted decision 003, current repositories, models, auth and deletion lifecycle, Home, Team, Player, chant detail, routing, tests, interface memory, learnings, roadmap, dependencies, and current user-owned worktree changes | Local repository | Completed. Confirmed there is no explicit local persistence package or saved route; Firestore cache is browse-only; offline saved detail must avoid current live vote and comment composition; account deletion currently has no local cleanup seam; and Android Gradle plus `pubspec.lock` changes remain unrelated and unstaged. |
| 18:05:48 | Read the current Codex engineering, delivery, CI, change-spec, execution, and interface framework contracts | Local framework source | Completed. Classified the block as Lane 2 because it introduces persistent state, identity isolation, deletion lifecycle behavior, a runtime dependency, and a material offline interface. |
| 18:05:48 | Compared maintained Flutter persistence options against the relaunch promise | Official Flutter and Dart documentation | Completed. Rejected `shared_preferences` because its documentation disclaims restart persistence and larger payload use. Selected `path_provider` plus a bounded, versioned JSON file, flushed temporary write, and same-directory replacement as the smallest supported mobile footprint. |
| 18:05:48 | Replaced the branch-local active specification with the exact Saved Matchday Songbook technical contract | Local repository | Completed as proposed. Runtime implementation remains intentionally absent until Andrew approves the exact storage, refresh, UID, deletion, interface, and verification contract. |
| 18:16:05 | Reviewed the complete planning diff and ran structural and writing checks | Local repository | Completed. `git diff --check`, placeholder searches, and forbidden-dash searches returned zero findings. The framework's optional `scripts/check-project-memory.sh` and `scripts/check-writing-style.sh` are not installed in this repository, so their direct checks were run instead. Only the two intended documentation files are part of the planning boundary; unrelated Android Gradle and lockfile changes remain unstaged. |
| 18:17:02 | Committed and published the planning boundary | Local repository and GitHub | Completed in commit `c42ea20`. Opened stacked draft PR [#8](https://github.com/andrewbolaji/Chants/pull/8) with base `codex/v1-songbook-chant-lab` and head `codex/v1-saved-matchday-songbook`; verified it is open and draft. The five existing CI jobs started. Runtime implementation remains intentionally absent. |
| 18:19:52 | Watched clean-runner planning CI and inspected the final checks | GitHub Actions run `32590297068` | Completed. Flutter tests, Flutter analysis, Functions, seed, and Firestore rules all passed. This confirms the stacked planning commit preserves the existing repository gates; it is not runtime evidence for the proposed offline feature. |
| 19:02:01 | Received Andrew's explicit approval of the exact Saved Matchday Songbook specification | Codex task and local repository | Approved for repository implementation and verification inside draft PR 8. Firebase access, moderation fixture changes, deployment, merge, and release remain unauthorized. |
| 19:38:09 | Implemented the approved persistence, refresh, identity, lifecycle, and interface boundary | Local repository | Added schema-versioned UID files, atomic replacement, bounded validation, serialized mutations, active-account guards, complete server refresh, deduplicated club and individual ownership, account-deletion compensation, Home, Team, live detail, and read-only saved routes. Added `path_provider` through a clean-worktree dependency resolution while preserving unrelated lockfile upgrades. No backend, rules, index, seed, Firebase, deployment, or release change occurred. |
| 19:38:09 | Generated and inspected representative interface evidence | Local Flutter test renderer, 390 by 844 | Overview and saved-detail goldens passed the bounded comparator. Visual inspection confirmed clear device-copy and refresh-age wording, readable club and individual hierarchy, no live social actions on saved detail, and no visible overflow. The overview also passed at 1.6x text. |
| 19:38:09 | Proved the offline-relaunch guard red, restored it, and ran the local verification matrix | Local repository | Returning an empty model instead of reading the file made the reconstruction test fail; restoring the file read made it pass. After restoration, 255 Flutter tests, 35 Functions tests, 42 seed tests, rules TypeScript compilation, and `flutter analyze lib test` passed. The 500-chant codec diagnostic measured 89.342 ms during the full suite. |
| 19:45:19 | Inspected the first implementation CI run | GitHub Actions run `32594555589` | Functions, seed, Java-backed rules, Flutter analysis, and 254 Flutter tests passed. The one failure was the saved-detail golden at 2.25% renderer difference between macOS Flutter 3.44.8 and Ubuntu Flutter 3.47.1, just above the test-local 2.2% allowance. Raised only this new test to a measured 2.3%; the shared 1.5% default and known-bad comparator guard remain unchanged. Replacement CI is pending. |
| 19:49:15 | Watched replacement clean-runner CI and inspected the final checks | GitHub Actions run `32594730151` | Completed. Flutter tests, Flutter analysis, Functions, seed, and rules all passed. The Java-backed Firestore emulator reported 117 passing assertions, and the Linux runner accepted the measured Saved Songbook golden boundary. |

- **Files/artifacts:** Versioned model, file storage, repository, refresh and deletion services, provider and route wiring, saved screens, shared reading layout, live entry controls, focused tests, two goldens, `path_provider`, decision 003, `docs/changes/2026-08-22-saved-matchday-songbook.md`, interface and learning memory, `docs/CHANGE_SPEC.md`, and this execution entry.
- **Skipped or blocked:** The local Firestore emulator remains unavailable because no Java runtime is installed; clean-runner CI supplied the 117-assertion independent result. Native Android and iOS compilation plus the actual airplane-mode force-stop and relaunch walk remain release gates. Firebase access, moderation fixture changes, deployment, merge, and release remain outside approval.
- **Final state:** Exact contract approved, implemented, visually inspected, red-checked, committed, pushed, and green-CI verified in draft PR 8. It is not reviewed, merged, deployed, released, or observed in production.
- **Follow-up:** Review stacked PRs 4 through 8 in order. Run native client compilation and the combined device walk before release, including the actual airplane-mode process relaunch promised by decision 003.

### 2026-08-22T13:14:57Z Specify V1 Songbook and Chant Lab browse split

- **Status:** completed in repository and CI, PR review pending
- **Scope:** Prepare the stacked Lane 2 contract for separate Songbook and Chant Lab tabs, deterministic Top and New ranking, a non-verification Rising signal, cached and partial browse states, and the player Start a chant path. No runtime, backend, rules, index, dependency, Firebase, or deployment change.
- **Reference:** `docs/CHANGE_SPEC.md`
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 13:14:57 | Created `codex/v1-songbook-chant-lab` from provenance closure commit `1549574` and inspected Team, Player, chant repository, ranking, routing, shared cards and states, tests, interface memory, roadmap, and accepted decisions 004 and 006 | Local repository | Completed. Confirmed both browse routes still consume mixed visible-status streams, Team has route-local frozen ranking while Player can reorder on score emissions, no browse widgets are directly tested, and the existing query boundary can support a client-only split without a new index or backend. |
| 13:14:57 | Replaced the branch-local active specification with the exact Songbook and Chant Lab technical contract | Local repository | Completed as proposed. The contract selects status-only surface projection, Songbook-first tabs, deterministic Top and New orders, an inclusive seven-day and score-3 Rising signal, stable in-visit Top and Songbook order, cache metadata, fail-soft player metadata, player-prefilled creation, and representative tests and goldens. |
| 13:31:00 | Committed and published the planning boundary | Local repository and GitHub | Completed in commit `3414a0f`. Opened stacked draft PR [#7](https://github.com/andrewbolaji/Chants/pull/7) against `codex/v1-provenance-evidence`. Runtime implementation remains intentionally absent. |
| 13:41:12 | Received Andrew's explicit approval of the exact Songbook and Chant Lab specification | Codex task and local repository | Approved for repository implementation. Firebase access, deployment, merge, and release remain unauthorized. |
| 16:57:38 | Implemented the approved client browse boundary | Local repository | Added fail-closed status projection, deterministic Top and New order, inclusive seven-day and score-3 Rising, route-local stable ordering, cache-aware repository snapshots, explicit retained-data subscriptions, Songbook-first Team and Player tabs, fail-soft player metadata, player-prefilled creation, and surface-specific empty and error states. No backend, rules, index, dependency, seed, or Firebase change. |
| 16:57:38 | Generated and inspected representative interface evidence | Local Flutter test renderer, 390 by 844 | Songbook and Chant Lab goldens passed the bounded comparator. Visual inspection confirmed distinct trust hierarchy, readable Top and New controls, non-gold Rising presentation, known player enrichment, stable club identity, and no visible overflow. A 1.8x text test passed on the same logical viewport. |
| 16:57:38 | Proved both critical guards red, restored them, and ran the local verification matrix | Local repository | Routing canonical status into Chant Lab made the projection test fail. Clearing the retained Player snapshot on a later stream error made the chant-disappearance test fail. After restoration, 224 Flutter tests, 35 Functions tests, 42 seed tests, rules TypeScript compilation, and `flutter analyze lib test` passed. |
| 16:57:38 | Checked availability of the Firestore rules emulator | Local workstation | Blocked locally because no Java runtime is installed. Rules and fixtures are untouched and TypeScript compiles; the emulator suite must run on the clean GitHub Actions runner before CI verification is complete. |
| 17:20:31 | Inspected the first implementation CI run | GitHub Actions run `32587305522` | Functions, seed, rules, and Flutter analysis passed. The Flutter job had 223 non-golden tests pass, then failed only because the two new text-heavy full-screen goldens differed by 2.09% and 1.94% across macOS Flutter 3.44.8 and Ubuntu Flutter 3.47.1, above the 1.5% default. Applied a measured 2.2% threshold only in the new browse golden test; the shared default remains unchanged. |
| 17:26:39 | Verified the corrected implementation on a clean runner and inspected the rules evidence | GitHub Actions run `32587485488` | Completed. Flutter tests, Flutter analysis, Functions, seed, and rules all passed. The Java-backed Firestore emulator reported 117 passing assertions. |

- **Files/artifacts:** Pure browse service; cache-aware chant repository snapshot; shared Chant Lab and support-notice widgets; Team, Player, and ChantCard updates; focused unit, widget, enlarged-text, and golden tests; decision 007; `docs/changes/2026-08-22-songbook-chant-lab-browse.md`; interface, roadmap, learning, spec, and this execution entry.
- **Skipped or blocked:** Local Firestore emulator execution remains unavailable because the workstation has no Java runtime. Live Firebase access, deployment, merge, release, and device inspection remain outside this implementation pass.
- **Final state:** Exact contract approved, implemented, visually inspected, committed, pushed, and green-CI verified in draft PR 7. It is not reviewed, merged, deployed, released, or observed in production. The combined device walk remains pending by Andrew's request.
- **Follow-up:** Review stacked PRs 4, 5, 6, then 7. Complete the combined device walk before release. Saved Matchday Songbook is the next independent v1 product block that does not depend on remaining seed work.

### 2026-08-22T06:47:59Z Implement v1 chant provenance and evidence

- **Status:** completed in repository and CI, PR review pending
- **Scope:** Specify and implement required submission origin, optional allowlisted external evidence, evidence-gated Terrace Proven promotion, honest provenance labels, evidence removal, and the soft duplicate nudge on stacked draft PR 6. No live-service access or deployment.
- **Reference:** `docs/CHANGE_SPEC.md`
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 06:47:59 | Created `codex/v1-provenance-evidence` from stable-identity commit `6aea174` and inspected the chant model, submit flow, repository queries, matcher, detail and card labels, moderation UI and callable, Firestore rules, tests, accepted product decision, interface contract, and roadmap | Local repository | Completed. Confirmed origin and evidence are absent, `VERIFIED` remains in the UI, promotion accepts evidence-free user chants, authors can still edit promoted chants, the matcher is pure but unwired, and `url_launcher` is not installed. |
| 06:47:59 | Replaced the branch-local active spec with the provenance and evidence technical contract | Local repository | Completed as proposed. The contract selects explicit backward-compatible fields, canonical external URL forms, client and server validation parity, a raw-write promotion guard, evidence removal with demotion, an author-edit freeze after promotion, and a fail-open advisory duplicate check. |
| 06:53:20 | Committed and pushed the planning boundary and opened stacked draft PR 6 | Local Git and GitHub | Completed. Commit `037428d` is published at `https://github.com/andrewbolaji/Chants/pull/6`, with base `codex/stable-chant-identity` and head `codex/v1-provenance-evidence`. CI started. |
| 07:54:42 | Recorded Andrew's explicit approval of the provenance technical specification | Local repository | Approved. Repository implementation and verification may begin on draft PR 6. Live Firebase access, deployment, and release remain unauthorized. |
| 12:45:35 | Implemented the approved application and trust boundary | Local repository | Added typed origin and evidence data, strict YouTube and X normalization, external link-out, honest labels, origin-aware submission, soft duplicate review, evidence-gated promotion, transactional evidence removal, raw-write rules parity, and focused tests. Self-review also retained operator moderation for untouched malformed legacy evidence while keeping its mutation and promotion blocked. |
| 12:45:35 | Generated and inspected representative interface evidence | Local Flutter test renderer, 390 by 844 | Both origin and evidence submission goldens passed. Visual inspection found no overflow and confirmed full helper copy, clear required origin choices, and the external-link warning. Live-device inspection remains pending. |
| 12:45:35 | Proved the promotion guard red, restored it, and ran the local verification matrix | Local repository | Disabling the Functions evidence guard made the focused promotion test fail on the missing exception. After restoration, 206 Flutter tests, 35 Functions tests, 42 seed tests, rules TypeScript compilation, and `flutter analyze lib test` passed. `git diff --check` was clean before documentation completion. |
| 12:45:35 | Checked availability of the Firestore rules emulator | Local workstation | Blocked locally because no Java runtime is installed. The rules source and test file compile, but the 117-assertion emulator suite must run on the clean GitHub Actions runner before the PR is called CI-verified. |
| 12:53:47 | Committed and pushed the approved implementation | Local Git and GitHub | Commit `9cedea2` added the scoped source, tests, goldens, decision, and current framework records to draft PR 6. The unrelated Android files and pre-existing lockfile version and SDK bumps remained unstaged. |
| 12:56:13 | Watched clean-runner CI and inspected the rules job evidence | GitHub Actions run `32574241342` | Completed. Flutter tests, Flutter analysis, Functions, seed, and Firestore rules jobs all passed. The Java 21 emulator job reported 117 passing rules assertions, including every new trust-boundary and legacy-compatibility case. |

- **Files/artifacts:** Flutter model, parser, repositories, submission, labels, evidence action, detail and moderation UI; Cloud Functions trust planner and callable integration; Firestore rules; focused tests and goldens; decision 006; `docs/changes/2026-08-22-chant-provenance-evidence.md`; `docs/CHANGE_SPEC.md`; and this execution entry.
- **Skipped or blocked:** Local Firestore emulator execution remains unavailable because the workstation has no Java runtime; clean-runner CI supplied the independent result. Live Firebase access, deployment, and release remain outside this approval.
- **Final state:** Approved, implemented, committed, pushed, and green-CI verified in draft PR 6. It is not reviewed, merged, deployed, released, or observed in production. The live-device walk remains pending by Andrew's request.
- **Follow-up:** Review stacked PRs 4, 5, then 6. Complete the combined device walk before release. The Songbook and Chant Lab browse split can proceed as a separate stacked block without waiting for seed completion.

### 2026-08-22T00:45:56Z Implement stable seeded chant identity

- **Status:** completed
- **Scope:** Create a branch stacked on draft PR 4, approve the Lane 2 contract, replace title-derived seeded chant IDs with explicit source IDs, add collision and transaction controls, and verify the repository boundary. No live Firebase access or seed write.
- **Reference:** `docs/CHANGE_SPEC.md`
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 00:45:56 | Created `codex/stable-chant-identity` from `f7079b2`; inspected seed ID derivation, validation, tests, Firestore references, and merge/reconciliation paths | Local repository | Completed. Confirmed seeded chant IDs are currently `compositeSlug(teamSlug, title)`, community chants already use stable auto IDs, only Arsenal exists in club seed data, and dependent collections reference the chant document ID. |
| 00:45:56 | Replaced the branch-local active spec with the stable-identity Lane 2 contract | Local repository | Completed as proposed. The design freezes current IDs as explicit source data, adds a preflight collision boundary, and refuses automatic migration when live state differs. |
| 01:26:03 | Recorded Andrew's explicit approval and implemented the approved source boundary | Local repository | Added explicit club-prefixed IDs, pre-write collision evaluation, transactional target recheck, validation, focused tests, decision 005, and rollout documentation. No service-account file was read and no Firebase request was made. |
| 01:26:03 | Ran the seed suite, TypeScript compiler, and Arsenal source-integrity comparison | Local repository | `npm test` passed 42 tests; `npx tsc --noEmit` exited 0; deleting only the 12 new `chants[].id` fields made the Arsenal JSON structurally equal to the stack base. Every explicit ID also equals its legacy algorithm result. |
| 01:27:35 | Proved the rename guard red, restored the implementation, and reran green | Local repository | A temporary title-derived resolver made `keeps the document ID when only the title changes` fail with the expected changed ID. The approved explicit resolver was restored; all 42 tests and TypeScript compilation passed again. |
| 01:34:43 | Added and tested the read-only CLI execution boundary found missing during self-review | Local repository | `--preflight-only` now calls only club preflight operations. Focused tests fail if any sport, competition, or club writer is invoked, prove a read failure stops before writers, and make unknown flags fail closed. |
| 02:38:05 | Committed and pushed the implementation, updated draft PR 5, and checked CI | Local Git and GitHub | Implementation commit `7c1eea3` is on `codex/stable-chant-identity`. GitHub Actions run `32543937728` passed Flutter tests, Flutter analysis, Functions, seed, and Firestore rules. Draft PR 5 remains stacked on draft PR 4. |

- **Files/artifacts:** `docs/CHANGE_SPEC.md`, `seed/chant_identity.ts`, focused seed tests, `seed_data/clubs/arsenal.json`, decision 005, the completed change record, and stacked draft PR 5.
- **Skipped or blocked:** The live read-only preflight, production seed, migration, and dependent-record rewrite were deliberately skipped. They require separate operator authorization after review.
- **Final state:** Approved, implemented, committed, pushed, and clean-CI verified in draft PR 5; not reviewed, merged, deployed, or observed against live data.
- **Follow-up:** Review the stack in order. After merge, obtain separate authorization before running the read-only live preflight.

### 2026-08-22T00:42:03Z Stage the interaction and safety block for review

- **Status:** completed
- **Scope:** Create a feature branch from local `main`, commit the current interaction, safety, and documentation work, push it, and open a draft pull request. Preserve unrelated Android Gradle and `pubspec.lock` changes unstaged.
- **Reference:** `docs/CHANGE_SPEC.md`
- **Operator:** Codex with Andrew's authorization to stage and stack review branches

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 00:42:03 | Inspected branch, remotes, working-tree paths, recent history, and open-PR availability | Local repository and GitHub CLI | Local inspection completed on `main` at `f780628`. GitHub PR listing could not reach `api.github.com` in the sandbox and will be retried with authorized network access. |
| 00:42:33 | Created `codex/v1-interaction-safety-replies` and staged 55 confirmed paths | Local Git index | Completed. Android Gradle files and `pubspec.lock` remain unstaged; no `seed/` or `seed_data/` path is staged. Initial diff check identified Markdown trailing spaces for correction before commit. |
| 00:43:28 | Committed the application, Functions, rules, and focused-test boundary | Local branch | Completed as `66be441` (`Add one-level replies and interaction safety`), 28 paths. Documentation was deliberately left for a separate review commit. |
| 00:44:24 | Committed documentation as `04b9ff6`, pushed the branch, created draft PR 4, and verified its base/head and initial checks | GitHub | Completed. PR is open and draft at `https://github.com/andrewbolaji/Chants/pull/4`, base `main`, head `codex/v1-interaction-safety-replies`. CI started; Functions and seed had already passed in the first run while the remaining checks were in progress. |
| 00:48:00 | Inspected failed Flutter CI logs | GitHub Actions, Ubuntu with Flutter stable 3.47.1 | Functional tests passed, but the reply and operator-control goldens differed from the macOS-generated baselines by 1.02% and 0.49%. The push and pull-request triggers also started duplicate workflow runs for the same commit. |
| 01:01:47 | Added a bounded golden comparator, its known-good and known-bad guard, and one-run-per-PR workflow triggers; ran the focused tests | Local macOS with Flutter stable 3.44.8 | Completed. All three focused tests passed. The guard accepts a 1% synthetic pixel difference under the 1.5% boundary and rejects a completely different image. Full-suite and remote Linux verification remain pending. |
| 01:03:18 | Ran the full Flutter suite and static analysis | Local macOS with Flutter stable 3.44.8 | `flutter test` passed 183 tests. Root analysis was polluted by generated `build/ios/SourcePackages` examples and failed outside changed source; `flutter analyze test` then completed with no issues. Clean-checkout CI remains the authoritative root analysis. |
| 01:06:13 | Watched replacement CI to completion | GitHub Actions run `32542321292` on draft PR 4 | Completed. Flutter tests, Flutter analysis, Functions, seed, and all 106 Firestore rules assertions passed on the clean Linux runner. |

- **Files/artifacts:** Branch `codex/v1-interaction-safety-replies`, commits `66be441` and `04b9ff6`, draft PR 4, and its linked CI runs.
- **Skipped or blocked:** Live-device walk remains pending by user request. Android Gradle and lockfile changes are excluded from this block.
- **Final state:** Implemented and verified locally and in clean CI; draft PR open and green; live-device walk pending; not review-complete, merged, deployed, or observed in production.
- **Follow-up:** Prepare the stable-identity stacked spec. Complete the live-device walk before PR 4 leaves draft status.

### 2026-08-21T23:59:53Z Adopt project memory and define the v1 creator loop

- **Status:** completed
- **Scope:** Documentation and product contracts only. No application, backend, rules, seed, deployment, or version-control write.
- **Reference:** `docs/decisions/004-songbook-and-chant-lab.md`
- **Operator:** Codex with Andrew's product approval

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 23:59:53 | Read the updated execution, interface, learnings, delivery, change-spec, ADR, and maintenance contracts | Local Codex framework | Completed. Classified this documentation block as Lane 1 and the later provenance/media implementation as Lane 2. |
| 00:00:35 | Inspected the active change spec, product spec, roadmap, wishlist, current chant model, submit flow, queries, rules, and moderation promotion action | Local working tree | Completed. Confirmed the replies/security change spec is still active and the working tree contains a large uncommitted implementation block. |
| 00:08:09 | Added separate execution, learning, and interface memory plus the accepted Songbook and Chant Lab decision; reconciled v1 and future scope across product guidance | Local working tree | Completed. Promoted stable chant identity after confirming the known title-derived-ID failure and public-link dependency. No runtime or seed file changed. |
| 00:11:40 | Ran the project-memory structure check, changed-guidance em-dash and placeholder searches, `git diff --check`, cited-path existence checks, and seed-path diff check | Local working tree | Completed. Memory contract passed; searches and diff check returned zero findings; `seed/` and `seed_data/` have no diff. |

- **Files/artifacts:** `docs/EXECUTION.md`, `docs/LEARNINGS.md`, `docs/INTERFACE.md`, `docs/decisions/004-songbook-and-chant-lab.md`, `docs/changes/2026-08-21-v1-creator-product-contract.md`, and reconciled product guidance.
- **Skipped or blocked:** Flutter, Functions, rules, and seed tests were skipped because this block changed documentation only. Chant Lab implementation was intentionally not started inside the active replies/security block, which still needs its live-device release walk and closure.
- **Final state:** Product and workflow documentation implemented, structurally verified, and self-reviewed locally. Not committed, pushed, merged, deployed, or observed in production. No application behavior changed.
- **Follow-up:** Andrew continues chant sourcing. After the current device walk and change closure, create and approve the stable-identity Lane 2 spec before remaining live seed writes.
