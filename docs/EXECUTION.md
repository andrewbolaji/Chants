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

### 2026-08-22T06:47:59Z Implement v1 chant provenance and evidence

- **Status:** implemented and locally verified, PR CI pending
- **Scope:** Prepare a stacked Lane 2 contract for required submission origin, optional allowlisted external evidence, evidence-gated Terrace Proven promotion, honest provenance labels, evidence removal, and the soft duplicate nudge. No application, Functions, Firestore rules, dependency, live-service, or deployment change.
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

- **Files/artifacts:** Flutter model, parser, repositories, submission, labels, evidence action, detail and moderation UI; Cloud Functions trust planner and callable integration; Firestore rules; focused tests and goldens; decision 006; `docs/CHANGE_SPEC.md`; and this execution entry.
- **Skipped or blocked:** Local Firestore emulator execution is blocked by the missing Java runtime. Live Firebase access, deployment, and release remain outside this approval.
- **Current state:** Approved implementation and local verification are complete on the stacked branch. It is not yet committed, pushed, CI-verified, reviewed, merged, deployed, or observed in production.
- **Follow-up:** Commit the scoped implementation, push draft PR 6, inspect clean-runner CI, then close the change record with the independent result.

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
