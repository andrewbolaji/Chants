# Change spec: V1 freeze correctness remediation

**Status:** Implemented and locally verified; packaging, clean-runner CI, and independent review pending
**Updated:** 2026-08-26
**Risk lane:** Lane 2, persistent local state, destructive lifecycle, Firestore triggers, authorization, and live-action authority
**Stack base:** `267afa216ccf05ba88a928e93d4ee30a2334ea4c`, exact reviewed PR 13 head
**Branch:** `codex/v1-freeze-remediation`, stacked above PR 13
**Review source:** `docs/CODE_REVIEW_FREEZE_2026-08.md`

## Outcome

- **Problem:** The external freeze review found that several documented guarantees fail under ambiguous network completion, process death, concurrent trigger delivery, late writes against a deleting account, case-insensitive local paths, cached Firestore snapshots, or widget identity reuse.
- **Desired behavior:** Deletion uncertainty never restores or discards local data without proof; counter writers serialize against the parent; deletion-pending targets reject new relationship rows; UID file paths remain distinct on case-insensitive filesystems; cached chant data stays readable but never authorizes a live action; and stateful interaction widgets cannot carry work across chant IDs.
- **Non-goals:** Final legal or policy copy; production signing secrets; native compilation; device actions; dependency advisory requests; Firebase deployment or live access; alert-policy creation in Google Cloud; seed reads or writes; merge, release, or repository-wide formatting.
- **Stop boundary:** Correct the locally reproducible freeze findings H1 through H4, M1 through M3, M5, M6, and L1. Keep release-only gates visible. Do not build a generic workflow, storage, or authority framework.

## Acceptance criteria and invariants

### Account-deletion acknowledgement and local recovery

1. A thrown remote deletion request is an unknown outcome unless the server explicitly proves rejection. The client must not say deletion did not start, restore the active Songbook, or sign out on an unknown outcome.
2. Local staging has durable `prepared`, `unknown`, and `accepted` meanings. A process death at any point leaves enough state for a new repository instance to preserve the correct boundary.
3. Starting the remote call moves a prepared tombstone to unknown before any network await. A retry reuses the same tombstone and the idempotent empty `deleteAccount` callable.
4. Explicit durable acceptance moves the tombstone to accepted before best-effort deletion and sign-out. Startup cleanup may delete accepted tombstones, but never unknown ones.
5. An unknown tombstone remains unreadable as an active Songbook and retryable. The UI says the request could not be confirmed and asks the user to retry; it makes no claim that the account or local Songbook is still available.
6. Tests instantiate fresh storage and repository objects across interruption points, including crash before request, crash during an unknown request, accepted cleanup failure, and retry acceptance.

### UID-safe local paths

7. New Songbook filenames use a lowercase SHA-256 digest of the UTF-8 Firebase UID. Path identity cannot depend on filesystem case sensitivity and stays below platform filename limits.
8. Existing base64url files migrate only for the active UID. Active, temporary, prepared, unknown, and accepted legacy variants are mapped without reading another UID's data.
9. The digest implementation is deterministic and covered by known vectors plus the previously colliding mixed-case UID pair. No new package or lockfile change is introduced.

### Transactional counter convergence

10. Vote, comment-like, visible-comment, user-report, and explicit chant reconciliation read the parent and child query and write the resulting absolute count in one Firestore transaction.
11. A surviving vote or comment-like document receives `appliedValue` in the same transaction only when it still exists and still carries the triggering value. Deletion remains a parent-only reconciliation.
12. Missing parents are successful no-ops inside the transaction and are not recreated. A parent deleted after an earlier read cannot make a stale batch retry forever.
13. Tests deliberately overlap two logical reconciliations, allow the newer snapshot to commit first, and prove the older transaction retries against current ground truth instead of committing stale state.
14. Report counters that already use a transaction keep their existing behavior.

### Deletion-pending target closure

15. A user-target report transaction rejects a target profile whose `deletionPending` field is true.
16. A direct block create requires the target profile to be absent from account deletion and to have an absent-or-false pending marker.
17. Because the deletion request transaction establishes the pending marker before cleanup begins, no ordinary client or touched callable can create a new against-user row after the cleanup phases start.
18. Functions and Java-backed rules tests prove the target-side denial while preserving ordinary active targets and cleanup-reducing deletes.

### Current live authority

19. The chant repository preserves `SnapshotMetadata.isFromCache` in its single-document stream contract.
20. Route and cached snapshots may remain readable. Save, Share, Report, Vote, Comment, and Discover authority require an active, error-free, non-cache, visible live document.
21. Permission denial, absence, hidden, and removed values continue to fail closed. An ordinary transient error may retain the last readable card but never creates new authority.
22. Widget tests prove a cached visible event renders fallback with actions disabled, followed by a server-confirmed visible event that enables actions.

### Stateful chant identity

23. Discovery cards and stateful interaction controls receive stable chant-ID keys.
24. `VoteControls` resets its optimistic state when chant ID changes, captures the operation chant ID, and ignores async reads or writes completed for an old identity.
25. `CommentSection` clears old rows on chant change, cancels the prior subscription, and ignores callbacks from older subscription generations.
26. Controlled tests swap chant IDs with hydration or stream work in flight and prove no old state or write crosses the identity boundary.

### Input and destructive-operation boundaries

27. Report target IDs are validated by UTF-8 byte length before being embedded in a Firestore document ID. Invalid path-sized input returns `invalid-argument`, not an internal storage error.
28. `mergeChants` remains documented as non-resumable and is disabled by a server-side failed-precondition guard until a separately approved cursor design exists. Existing operator authorization remains before detailed target disclosure.

### Documentation and verification

29. Decision 011 is superseded where it claimed restoration on every request failure. Decision 009 is refined so cached snapshots are readable fallback, not live authority. Durable counter and UID-path choices receive current decision records.
30. `ENGINEERING_OVERVIEW.md`, `docs/IMPLEMENTATION_RATIONALE.md`, `docs/INTERFACE.md`, `docs/LEARNINGS.md`, and `docs/ROADMAP.md` describe the implemented state and retain policy, signing, native, device, advisory, deployment, and observability gates as unverified.
31. A completed record under `docs/changes/` and a timestamped `docs/EXECUTION.md` entry distinguish implementation, local verification, external review, clean-runner CI, deployment, and observation.
32. Focused tests first prove the affected behavior can fail. Then the complete Flutter, Functions, seed, rules, TypeScript, analysis, formatting-scope, and diff checks run as applicable.
33. The owner's existing `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` changes remain unstaged and are not edited. The freeze review remains untracked unless Andrew separately asks to package it.

## Rollout and rollback

1. Deploy compatible Firestore rules before Functions, then clients. The rules and report callable target guard may ship before the client.
2. Client storage migration is active-UID-only and lazy. Old files are retained until their mapped new state is committed.
3. Counter Functions are rollback-compatible with existing child and parent schemas because they add no stored fields.
4. Unknown and accepted local deletion states must not be rolled back to the old unconditional tombstone cleanup.
5. `mergeChants` can be re-enabled only through a separately approved resumable change, not an emergency client toggle.

## Delivery state

The approved local implementation is complete. Local evidence is 322 Flutter tests, clean scoped analysis, 73 Functions tests and build, 42 seed tests, 136 Java-backed rules assertions, rules TypeScript compilation, scoped formatting, and diff checks. The completed record is `docs/changes/2026-08-26-v1-freeze-correctness-remediation.md`.

This spec authorizes local repository implementation and verification only. It does not authorize commit, push, PR creation, Firebase access, deployment, live reads or writes, seed actions, native build, device actions, signing, merge, or release. Those actions remain pending separate owner direction.
