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

### 2026-08-26T13:34:53Z Correct the post-review audit and recovery findings

- **Status:** Implemented and locally verified; packaging and replacement clean-runner CI pending
- **Scope:** Correct the verified `f5cb748...c893cd0` follow-up findings: preserve known operator audit detail under a non-identifying operator sentinel, keep report and unknown detail private, make retained target-side history copy accurate, recover prepared local state without relaunch, replace the stable-ID claim with transactional exactly-once evidence, test empty SHA input directly, and refresh the current formatter count. No Firebase, seed, native, device, deployment, merge, or release action.
- **Reference:** `docs/CHANGE_SPEC.md`, independent review of commit `c893cd0`
- **Approval:** Andrew explicitly approved `post-review audit and recovery correction spec` on 2026-08-26.
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 13:34:53 | Independently verified the review against the clean PR 14 head and owner-owned worktree boundary | Local repository at `c893cd0` | Confirmed D-1, D-2, D-3, D-5, and D-6. Classified D-4 as an inaccurate invariant rather than a duplicate-write defect because the audit write and phase advance are transactional. Confirmed clean-runner run `32970254587` had already passed all five jobs. |
| 13:34:53 | Replaced the completed correction spec with the exact approved follow-up contract | Local repository | Recorded allowlisted operator-detail preservation, report and unknown fail-private behavior, target-side disclosure, prepared recovery, transactional exactly-once evidence, direct empty-message SHA coverage, formatter truth, non-goals, and rollout limits before implementation. |
| 13:45:00 | Implemented classified audit cleanup and transactional completion evidence | Local Functions source and tests | Known generated operator actions now use `deleted-operator` and retain detail. Reports and unknown actions remove text, self-target policy acceptance removes the target UID, and delayed writers retain their lifecycle transaction. A duplicate post-advance worker delivery writes no second completion row. |
| 13:45:00 | Implemented same-process prepared recovery and truthful deletion copy | Local Flutter repository, provider, screens, service behavior, tests, and golden | Prepared state actively reruns serialized artifact recovery before Home. Recovery failure stays closed behind a real retry. Pre-network transition failure restores staged data and never calls the remote boundary. Copy distinguishes authored-report redaction from retained target-side history. |
| 13:50:59 | Ran the complete local verification matrix and reconciled durable records | Local macOS, Flutter 3.44.8, Node 20, OpenJDK 26, Firestore emulator, Dart 3.12.2 | PASS: 341 Flutter tests, scoped analysis, 78 Functions tests and build, 42 seed tests, seed and rules TypeScript, and 136 Java-backed rules assertions. Focused Flutter and Functions groups passed first. The read-only formatter check confirmed 42 of 142 residual files, touched Dart files are formatted, the refreshed 390 by 844 golden was inspected, and memory, style, caller, ownership, and diff checks passed. |

- **Files/artifacts:** Runtime, tests, and golden named in `docs/changes/2026-08-26-post-review-audit-recovery-corrections.md`; decisions 011, 012, and 016; current overview, rationale, interface and learning memory, roadmap, README, handbook, active contract, and this execution entry.
- **Skipped or blocked:** Commit, push, replacement clean-runner CI, Firebase, seed writes, native build, device walk, deployment, merge, release, and production observation remain outside this approval.
- **Current state:** Approved Lane 2 follow-up is locally complete and green on `codex/v1-freeze-remediation`. No external state changed. The owner-owned Gradle and lockfile changes plus untracked freeze report remain outside the correction.

### 2026-08-26T12:06:39Z Correct the post-freeze independent review findings

- **Status:** Implemented and locally verified; packaging, clean-runner CI, and narrow re-review pending
- **Scope:** Correct the verified review findings at PR 14 head `f5cb748`: persistent unknown-deletion recovery, audit actor and free-text privacy, confirmed local cleanup, local saved-action availability, initialization retry, typed permission classification, deleting-target report closure, dead report lookup code, SHA boundary coverage, and exact freeze documentation. No job monitor, aggregate redesign, dependency, Firebase, seed, native, device, deployment, merge, or release action.
- **Reference:** `docs/CHANGE_SPEC.md`, independent review range `c57815c...f5cb748`
- **Approval:** Andrew explicitly approved `post-freeze independent review correction spec` on 2026-08-26.
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 12:06:39 | Verified branch, user-owned worktree boundary, framework requirements, and independent-review evidence | Local repository at `f5cb748` | Confirmed PR 14 head is unchanged and pushed. Preserved the owner's two Gradle files, `pubspec.lock`, and untracked freeze report. Reproduced the formatter observation as 46 of 142 files with read-only output. Confirmed the review's suggested restore-on-false-profile approach is unsafe because negative state can be stale or race a late commit. |
| 12:06:39 | Replaced the completed freeze spec with the approved bounded correction contract | Local repository | Recorded positive-only reconciliation, persistent recovery UI, accepted-marker-last cleanup, audit redaction, local-action authority split, bounded hardening, evidence corrections, rollout limits, and explicit non-goals before implementation. |
| 12:36:47 | Implemented persistent positive-only deletion recovery and accepted-last local cleanup | Flutter app gate, Saved Songbook repository and storage, deletion UI | Unknown state now presents Retry and Sign out before Home even when the first profile read is unavailable. Only callable success or a positive pending profile advances cleanup. Initialization retries after transient failure, and accepted cleanup removes every conflicting artifact before its marker. |
| 12:36:47 | Closed audit privacy and deleting-target admission | Cloud Functions | Added a 200-row audit redaction phase, non-identifying completion audit, transactional delayed-report audit guard, and same-transaction user-report denial when the target deletion job exists. No Functions deployment or live data access occurred. |
| 12:36:47 | Completed bounded authority, dead-code, SHA, copy, and regression corrections | Flutter, Functions, tests, goldens, and durable records | Existing device-local Songbook navigation and removal work from cached detail while new saves and live actions stay gated. Permission denial is typed, unused report lookup paths are removed, SHA padding vectors are fixed, deletion retention copy is accurate, and decisions 011, 012, 015, and 016 preserve the architecture. |
| 12:36:47 | Ran the complete local verification matrix and inspected both deletion goldens | Local macOS, Flutter 3.44.8, Node 20, OpenJDK 26, Firestore emulator | PASS: 336 Flutter tests, scoped analysis, 77 Functions tests and build, 42 seed tests and TypeScript, rules TypeScript, 136 Java-backed assertions, 16-file Dart format check, project-memory and writing checks, caller searches, and final diff checks. The 390 by 844 pending and recovery goldens are unclipped and truthful. |

- **Files/artifacts:** Runtime, tests, and goldens named in `docs/changes/2026-08-26-post-freeze-independent-review-corrections.md`; decision 016; refinements to decisions 011, 012, and 015; current overview, rationale, interface, learning, roadmap, README, setup, active contract, and this execution record.
- **Skipped or blocked:** Firebase, seed writes, native build, device walk, deployment, commit, push, clean-runner CI, merge, release, deletion-job monitoring, and aggregate redesign remain outside this approved local block.
- **Current state:** Approved Lane 2 correction is locally complete and green on `codex/v1-freeze-remediation`. No external state changed. The owner-owned Gradle and lockfile changes plus untracked freeze report remain outside the correction.

### 2026-08-26T04:06:54Z Start V1 freeze correctness remediation

- **Status:** Implemented and locally verified; packaging and independent review pending
- **Scope:** Implement the locally reproducible correctness fixes from `docs/CODE_REVIEW_FREEZE_2026-08.md`: deletion acknowledgement and tombstone states, transaction-safe counters, deletion-pending target closure, UID-safe local paths, cache-aware live authority, chant-identity lifecycle, report path validation, and a safe stop on non-resumable merge. Production policy copy, signing, native builds, device actions, dependency disclosure, Firebase, seed, deployment, merge, and release remain outside scope.
- **Reference:** `docs/CHANGE_SPEC.md`, reviewed range `c57815c...267afa2`
- **Approval:** Andrew directed Codex to "make the fixes you think make logical sense" on 2026-08-25, explicitly delegating the bounded technical choices recorded in the active spec.
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 04:06:54 | Created a stacked remediation branch from the exact reviewed head | Local Git | Created `codex/v1-freeze-remediation` at `267afa2`. Preserved the untracked freeze review and the owner's three existing Gradle and lockfile modifications. |
| 04:06:54 | Replaced the completed prior active contract with the bounded remediation contract | Local repository | Marked the exact technical scope approved under Andrew's delegated instruction. Runtime implementation begins only after this record. |
| 04:14:00 | Captured red evidence at the affected boundaries | Focused Flutter, Functions, and rules tests | Reproduced ambiguous deletion restoration, cache-only action enablement, chant-ID state reuse, pending-target acceptance, oversized report identity, and non-transactional counter writers before implementing fixes. |
| 04:24:00 | Implemented deletion acknowledgement and UID-safe storage | Local Flutter repositories and UI | Added prepared, unknown, and accepted artifacts; retryable unconfirmed response; lowercase SHA-256 UID keys; active legacy migration; truthful uncertainty copy; and reconstruction coverage without a dependency or lockfile change. |
| 04:29:00 | Implemented transactional aggregation and safety target closure | Local Functions and Firestore rules | Parent-serialized vote, like, visible-comment, user-report, content-report, and explicit chant reconciliation now converge under overlap. Pending report and block targets and path-sized report IDs fail closed. |
| 04:33:00 | Implemented cache provenance, chant identity isolation, and merge stop | Local Flutter and Functions source | Cache text stays readable while live actions wait for server authority. Vote and comment async work cannot cross chant IDs. Operator merge stops before target parsing or mutation. |
| 04:36:00 | Ran backend and authorization verification | Local Node 20, OpenJDK 26, Firestore emulator | PASS: 73 Functions tests and build, 42 seed tests, rules TypeScript compilation, and 136 Java-backed rules assertions. The first rules cold start exceeded the inherited 10-second setup timeout; the same suite passed with a 30-second hook allowance. |
| 04:40:55 | Ran full client verification and refreshed durable records | Local Flutter and repository | PASS: 322 Flutter tests, scoped analysis with no issues, 21 touched Dart files formatted, and focused lifecycle, cache, migration, and identity regressions. Added decisions 012 through 015, completed record, interface and learning updates, overview, rationale, roadmap, README, and handbook truth. |
| 04:53:09 | Hardened conflicting local artifact recovery and completed the ownership and diff audit | Local Flutter, Git, and repository | Unknown and accepted deletion markers now outrank conflicting active files. The added regression passes, the complete Flutter suite remains 322 of 322, scoped analysis is clean, `git diff --check` passes, new files have no trailing whitespace, and the Git index is empty. |

- **Files/artifacts:** Runtime and regression paths named in `docs/changes/2026-08-26-v1-freeze-correctness-remediation.md`; decisions 012 through 015; active contract; current overview and rationale; this execution entry; and the preserved untracked external freeze report.
- **Skipped or blocked:** Final policy text, production signing, native builds, physical-device review, advisory lookup, cloud alert creation, Firebase access, seed reads or writes, deployment, commit, push, PR, merge, and release. Clean-runner CI awaits packaging authorization.
- **Current state:** Approved remediation is locally complete and green on `codex/v1-freeze-remediation`. No external or repository-publication state changed. The owner's three pre-existing modifications remain unstaged and untouched.

### 2026-08-25T20:25:22Z Package abuse controls and implement account deletion recovery

- **Status:** Abuse-control PR and account-deletion PR packaged and clean-runner green; external freeze review pending
- **Scope:** Commit and publish the approved report and feedback block, run clean CI, then inspect and specify one bounded deletion-recovery block on a branch stacked from that exact green head. No runtime deletion redesign before spec approval. No Firebase, deployment, seed, merge, release, signing, native build, or device action.
- **Reference:** Draft PR 12, commit `dccbad02426022e49ff3ed21b0ae9baf9424985f`, and `docs/CHANGE_SPEC.md`
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 20:18:00 | Staged and committed only the approved abuse-control paths | Local Git | Created `dccbad0 Harden report and feedback intake`, 27 files. Preserved `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` unstaged. |
| 20:19:00 | Pushed the branch and opened its stacked draft review | Private GitHub repository | Published `codex/v1-abuse-controls` and opened draft PR 12 against `codex/v1-stacked-engineering-review`. GitHub had already assigned number 11 to the owner-created stack, so the next actual pull request number was 12. |
| 20:22:00 | Watched clean-runner CI to completion | GitHub Actions run `32894622653` | PASS: Flutter tests, Flutter analysis, Functions, Java-backed Firestore rules, and seed. No job failed or was skipped. |
| 20:23:00 | Created the next stacked branch from the exact green head | Local Git | Created `codex/v1-account-deletion-recovery` at `dccbad0`; the three user-owned worktree edits remained unstaged. |
| 20:25:22 | Inspected the destructive lifecycle, local compensation, profile and rules authority, Auth APIs, counter triggers, framework records, and mixed-version rollout | Local repository and installed Firebase Functions types | Confirmed the synchronous eleven-stage callable can lose progress and target-reconciliation context, and the Auth-before-profile gap cannot be recovered by an unauthenticated client. Confirmed Eventarc retry is available locally and every affected query already exists without a new index. |
| 20:25:22 | Replaced the completed active contract with the exact recovery proposal | Local repository | Proposed one private deterministic job, one retry-enabled bounded state-machine worker, pending-account authority, 200-row pages, user-report deletion convergence, deterministic audit, Auth-finalization recovery, local cleanup and sign-out behavior, tests, rollout, and rollback. Runtime remains absent pending Andrew's exact approval. |
| 20:31:00 | Received Andrew's exact implementation approval | Codex task | Approved with `approved v1 account deletion recovery spec`. Repository implementation and proportionate verification are authorized; Firebase, deployment, live data, seed, merge, signing, release, native build, and device actions remain outside scope. |
| 20:46:00 | Implemented the durable request transaction and retry-enabled bounded worker | Local Functions source | Added an exact four-field deterministic job, pending profile marker, 16 forward-only phases, 200-row pages, heartbeat batches, compare-before-advance transactions, Auth disable and missing-user tolerance, deterministic audit, Auth deletion, and atomic profile-plus-job finalization. Unknown jobs fail closed. |
| 20:57:00 | Closed pending-account authority and counter convergence across rules and callables | Local Functions and Firestore rules | Denied active client writes and operator authority when a profile is pending or a job exists. Added touched-callable pending checks and a user-report deletion trigger that repairs surviving target counts without a new create audit. Jobs are private to every client. |
| 21:07:00 | Implemented client acceptance, compensation, sign-out, and recovery UI | Local Flutter source | Required explicit `accepted == true`, retained exact local Songbook restoration before acceptance, allowed deferred unreadable tombstone cleanup after acceptance, signed out normal and failed-sign-up paths, and gated pending sessions before policy or Home. Added one scrollable pending screen. |
| 21:13:00 | Added focused coverage and proved three load-bearing guards red | Local Flutter, Node, and Firestore emulator tests | Functions tests cover every phase, paging, duplicate and stale events, failure retention, Auth and finalization recovery, audit, malformed jobs, and user-report deletion. Rules and Flutter cover pending authority and app gating. Temporarily changing 200 to 201, allowing pending block creation, and inverting the pending app gate each failed the intended focused test before restoration. |
| 21:22:57 | Ran the backend and authorization matrix and inspected the interface | Local macOS, Node 20, OpenJDK 26, Firestore emulator, Flutter renderer | PASS: 69 Functions tests and build, 42 seed tests, rules TypeScript compilation, 135 Java-backed rules assertions, scoped Flutter analysis, and diff checks. Generated and inspected the 390 by 844 pending-state golden; hierarchy, copy, and action were unclipped and consistent. |
| 21:31:43 | Refreshed the canonical current-state records and reran the post-documentation matrix | Local repository and Flutter renderer | Added decision 011, the completed change record, interface and handbook memory, the reusable deletion lesson, roadmap freeze state, and current whole-project engineering snapshots. Preserved external-review baseline `c57815c`. The then-current Flutter suite passed 308 tests, analysis passed, Functions passed 69 again, seed passed 42 again, and the post-documentation diff check passed. |
| 21:35:00 | Self-reviewed unknown profile state and post-acceptance sign-out failure | Local Flutter source and focused tests | Corrected two authority claims before handoff. An initial profile error now stays neutral instead of opening Home; a later error retains only the same UID's last verified active or pending gate. A sign-out failure after durable acceptance no longer produces false `deletion did not start` copy or restores local data. Focused gate and lifecycle tests passed 16. |
| 21:37:25 | Reran the final complete Flutter suite | Local Flutter renderer | PASS: 310 tests. The two added stream-error guards pass alongside every inherited test and golden. Scoped analysis remained clean. |
| 22:45:00 | Packaged and published the approved deletion-recovery block | Local Git and private GitHub repository | Created implementation commit `98f2c9e` with 37 approved paths, pushed `codex/v1-account-deletion-recovery`, and opened stacked draft PR 13 against `codex/v1-abuse-controls`. The two Android Gradle files and `pubspec.lock` remained unstaged. |
| 22:48:37 | Watched the implementation head through clean-runner CI | GitHub Actions run `32907722272` on `98f2c9e` | PASS: 310 Flutter tests, repository-wide Flutter analysis, 69 Functions tests, 42 seed tests, and 135 Java-backed Firestore rules assertions. No job failed or was skipped. |
| 22:49:17 | Prepared the clean-CI evidence refresh for the final review head | Local repository | Updated the active contract, roadmap, overview, rationale, decision, and completed record with the exact PR, commit, and run. This documentation-only head receives a replacement five-job run before handoff to Claude. |

- **Files/artifacts:** Draft PR 12 and run `32894622653`; `functions/src/account_deletion.ts`; Functions, rules, Flutter lifecycle and UI changes; focused tests; one pending-state golden; decision 011; completed change record; current engineering snapshots; active spec; and this execution entry.
- **Skipped or blocked:** External review, native compilation, combined device walk, live Firebase, deployment, seed work, merge, signing, and release remain pending separate authorization or later gates. No external Firebase or data action occurred.
- **Final state:** Draft PR 13 contains the final v1 feature layer and its implementation head is clean-runner green. The three user-owned Android and lockfile edits remain unstaged and untouched.
- **Follow-up:** After exact approval, implement and verify the bounded deletion job, package its final stacked PR, then stop feature engineering for the combined device walk and external freeze review over `c57815c...<freeze-head>`.

### 2026-08-25T18:46:20Z Specify and implement v1 report and feedback abuse controls

- **Status:** Approved implementation locally complete and verified; packaging, clean-runner CI, and independent review pending
- **Scope:** Inspect and replace the remaining direct report and feedback admission paths with a server-authoritative, atomically budgeted boundary on a branch stacked above PR 10. No Firebase, deployment, seed, merge, release, signing, or device action.
- **Reference:** `docs/CHANGE_SPEC.md`
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 18:32:00 | Inspected report, comment-report, user-report, feedback, profile, rate-limit, account-deletion, rule, provider, UI, and test boundaries | Local repository at `6252179` | Confirmed exact schemas and deterministic per-target report IDs are present, but all four collections still accept direct client creates and have no cross-target velocity budget. Post-write triggers cannot prevent already-incurred storage, queue, audit, counter, and Function load. |
| 18:40:00 | Chose the smallest enforceable admission boundary | Local design review | Selected authenticated callables plus one private per-UID rate document. Report creation and budget increment share a transaction; all target types share one report window; feedback has an independent window. Rejected client timestamps, query-count rate checks, profile parser expansion, and post-write deletion as forgeable or race-prone. |
| 18:43:00 | Created `codex/v1-abuse-controls` from exact PR 10 head | Local Git | Branch created at `6252179`. Preserved the user's existing `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` modifications unstaged. |
| 18:46:20 | Replaced the completed active contract with the exact PR 11 proposal | Local repository | Proposed two callables, atomic limits, client migration, direct-create denial, deletion cleanup, error behavior, rollout order, abuse cases, and verification. Runtime implementation remains absent pending Andrew's exact approval. |
| 18:52:00 | Received Andrew's exact implementation approval and fixed the later whole-stack review anchor | Codex task and local Git history | Approved with `approved v1 report and feedback abuse controls spec`. The future freeze review will compare immutable review commit `c57815c` with the final freeze head; the milestone files at that commit remain retrievable even though their current paths are living snapshots. |
| 19:03:00 | Implemented authenticated callable admission and atomic budgets | Functions and Flutter source | Added testable report and feedback handlers, one private per-UID rate document with independent anchored windows, exact profile and target validation, deterministic duplicate protection, server-owned stored fields, and one typed Flutter callable repository. Removed all shipped direct-create methods and client identity fields. |
| 19:08:00 | Closed direct-write paths and extended lifecycle cleanup | Firestore rules and account deletion | Denied all direct creates for the three report collections and feedback, denied every client access to private rate rows, preserved existing read boundaries and post-write triggers, and deleted the caller's rate row during account deletion. |
| 19:13:00 | Ran focused client, Functions, rules compilation, and emulator checks | Local macOS, Node 20, OpenJDK 26 | Focused Flutter tests passed. Functions reached 54 passing at the first boundary. Rules TypeScript compiled. The first two full emulator attempts each passed 131 assertions and timed out on a different inherited assertion at Mocha's 10-second limit, indicating local emulator stalls rather than a stable failed boundary. |
| 19:23:00 | Proved the new guards can fail and restored production behavior | Local focused red checks | Raising the new-account report limit to 6 failed the five-report guard; mapping comment reports as chants failed the target-mapping guard; temporarily allowing direct report creates failed the exact report-schema denial guards. Restored all three production values afterward. |
| 19:27:00 | Ran the complete local verification matrix | Local macOS, Node 20, OpenJDK 26 | PASS: 294 Flutter tests, scoped Flutter analysis, 56 Functions tests, 42 seed tests, rules TypeScript, and 132 Java-backed rules assertions. The rules suite passed in 15 seconds with a 30-second local test timeout. |
| 19:29:54 | Inspected temporary error-state renders and refreshed durable records | Local Flutter renderer and repository docs | Report and feedback rate-limit captures showed stable forms, controls, and error presentation without clipping. Capture-only code and files remain outside the repository. Added decision 010, the completed-change record, interface memory, roadmap state, and the immutable freeze-review range. |

- **Files/artifacts:** Functions handler and tests, Flutter safety repository and surface tests, Firestore rules and tests, decision 010, completed-change reasoning, interface and roadmap updates.
- **Skipped or blocked:** No dependency, index, Firebase, deployment, live data, seed, merge, release, signing, native build, or device action. Repository-wide local analysis still traverses ignored iOS package sources from the earlier native attempt; `flutter analyze lib test` is clean.
- **Final state:** Approved source block is locally complete and remains uncommitted and unpushed. The three preserved user changes remain outside scope.
- **Follow-up:** After Andrew separately authorizes packaging, commit and push stacked PR 11 and run clean-runner CI. Then assess account-deletion recovery before the v1 freeze review from `c57815c...<freeze-head>`.

### 2026-08-25T14:51:28Z Publish and clean-runner verify stacked PR 10

- **Status:** Remediation packaged, pushed, and clean-runner verified; independent review and later device walk remain
- **Scope:** Package the approved authority remediation as one commit, push its stacked review branch, open the draft pull request, and run the existing five-job clean CI matrix. No merge, deployment, seed, release, or device action.
- **Reference:** PR 10, commit `625217940e9817d9801b90f28aa4025e48dfbd48`
- **Operator:** Codex

| UTC time | Action | Target/environment | Result and evidence |
|---|---|---|---|
| 14:48:54 | Committed the approved remediation while excluding user-owned work | Local Git | Created one remediation commit, `6252179 Harden v1 authority and integration boundaries`. Gradle and lockfile modifications remained unstaged. |
| 14:49:00 | Pushed the stacked review branch and opened draft PR 10 against Basic Share-Out | GitHub | Published `codex/v1-stacked-engineering-review` and opened `Review and harden combined v1 feature stack`. |
| 14:51:28 | Watched clean-runner CI to completion | GitHub Actions run `32861926202` | PASS: 282 Flutter tests, repository-wide Flutter analysis, 36 Functions tests, 42 seed tests, and 131 Java-backed Firestore rules assertions. This also proved the deterministic non-secret analysis fixture on a clean checkout. |

- **Final state:** PR 10 is clean-runner green and is the seventh layer of the owner-created GitHub stack. No merge or release action occurred.
- **Follow-up:** Independent review remains in a separate task. The combined device walk is deliberately deferred until the build reaches its v1 freeze point.

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
