# V1 account deletion recovery

**Completed in repository:** 2026-08-25
**Type:** Lane 2 destructive lifecycle, background retry, persistent server state, authority, and local sign-out
**Application behavior changed:** In-app account deletion and pending-account recovery

## Change identity and boundary

- **Change:** Replace synchronous best-effort deletion with a private resumable account-deletion job and bounded retry worker.
- **Target:** `codex/v1-account-deletion-recovery`, based on exact green PR 12 head `dccbad02426022e49ff3ed21b0ae9baf9424985f`.
- **Included:** Durable request transaction, 16-phase worker, 200-row pages, pending-account authority, retained-contribution anonymization, interaction deletion, deterministic audit, Auth disable and deletion, user-report counter convergence, Saved Songbook compensation, client sign-out, pending screen, tests, golden, and durable records.
- **Excluded:** Undo, restoration, user-data export, merge recovery, operator job console, notifications, analytics, scheduled polling, Cloud Tasks, indexes, dependencies, live Firebase access, deployment, seed work, signing, merge, release, native build, and device actions.
- **Approval:** Andrew explicitly approved `approved v1 account deletion recovery spec` on 2026-08-25 before runtime edits began.

## Outcome

- `deleteAccount` now accepts only an authenticated empty request. Its transaction creates the exact private job shape and marks an existing profile pending before returning `{ accepted: true, success: true }`. A duplicate request preserves progress.
- `onAccountDeletionJobWritten` is retry-enabled and performs one Auth action, audit action, finalization, or page of at most 200 matching rows per event. Page mutations and the job heartbeat share one batch; empty-page transitions compare the current phase transactionally.
- The worker disables Auth first, deletes private interactions and safety rate state, anonymizes retained chants and comments, writes one deterministic audit row, deletes Auth, then atomically deletes the profile and job. Missing Auth users and duplicate events are idempotent.
- A pending profile and the existence of its private job both deny new active client writes and operator authority. Touched callables reject pending users. Cleanup-reducing owner deletes remain available where explicitly safe.
- User-report deletes recompute the surviving target's `userReportCount` from ground truth without writing a new create audit.
- The Flutter client accepts only an explicit durable-acceptance response, stages the local Songbook before the request, restores exact bytes on rejection, finalizes the tombstone after acceptance, and signs out. Failed sign-up cleanup also signs out after durable acceptance.
- A reopened pending session sees one narrow recovery screen and cannot reach Home or policy acceptance.

## Invariants preserved

- The target UID always comes from authenticated server context.
- Durable acceptance happens before irreversible local cleanup or sign-out.
- Retained chants and comments keep their content and relationships but lose account identity.
- Duplicate or racing delivery never rewinds the phase, duplicates the audit, or recreates deleted interactions.
- The worker never claims completion while the profile or job remains.
- The three pre-existing Android and lockfile modifications remained unstaged and were not overwritten.
- No production, staging, Firebase, seed, deployment, signing, merge, release, native build, or device state changed.

## Verification

- `flutter test`: 310 passed, including profile parsing, app-gate precedence, unknown-profile fail-closed behavior, retained verified gate state, callable response validation, local compensation, tombstone cleanup, sign-out failure containment, dialog copy, pending-screen recovery, responsive layout, and the new golden.
- `flutter analyze lib test`: no issues.
- `cd functions && npm test`: 69 passed. Coverage includes exact request and job shape, missing profile, duplicate requests, all phase transitions, 200-row bounds, multi-page progress, stale-phase races, write failures, Auth absence, deterministic audit, finalization recovery, malformed jobs, pending callable denial, and user-report deletion convergence.
- `cd functions && npm run build`: passed.
- `cd seed && npm test`: 42 passed.
- `cd test_rules && npx tsc --noEmit`: passed.
- Java-backed Firestore emulator: 135 passed. Jobs are private, pending identity is denied across active writes and operator paths, absent fields remain compatible, and cleanup-reducing deletes remain explicit.
- `git diff --check`: passed after the final documentation refresh.
- Deliberate red checks changed the 200-row worker page to 201, reopened pending block creation, and inverted the pending app gate. Each focused test failed for the intended reason before production behavior was restored.
- The 390 by 844 pending-state golden was generated with repository fonts and visually inspected. The hierarchy, copy, action, and viewport are unclipped and consistent with the Chants design system.
- Clean-runner GitHub Actions run `32907722272` passed all five jobs on implementation commit `98f2c9ee98d5feb7a901cb3e8907b056b340b05d`: 310 Flutter tests, repository-wide Flutter analysis, 69 Functions tests, 42 seed tests, and 135 Java-backed Firestore rules assertions.

The block is packaged in stacked draft PR 13 against `codex/v1-abuse-controls`. Independent review, native compilation, and the combined device walk remain pending.

## Security, privacy, performance, and infrastructure impact

The job is server-only and stores only schema version, phase, and two server timestamps. Each data invocation reads and mutates at most 200 matching rows plus one heartbeat. Existing per-document counter triggers absorb interaction deletion and converge from stored truth. The deterministic audit contains a UID-scoped lifecycle event but no email, device data, or content body.

Disabling Auth prevents new sign-in. The profile pending marker and job existence block already-issued credentials. A permanently failing phase remains visible as a retained private job but currently depends on future Function alerting or manual inspection.

The safe rollout order is backward-compatible rules, Functions, then the client. The worker must remain deployed until all jobs drain. Rollback of client or rules does not authorize removing a worker that still owns pending cleanup.

## Review boundary and follow-up

The last whole-stack external-review baseline remains commit `c57815c`. The final external freeze review should use the exact range `c57815c...<final-pr-13-head>` after the CI-evidence record is committed and its replacement checks pass.

At that point, remaining work is not another planned v1 feature block. It is external review and remediation if needed, native compilation, the combined device walk, verified content seeding, real policy and legal copy, signing, deployment preparation, and release operations. Resumable chant merge, operator recovery tooling, notifications, deeper replies, and hosted media remain later work.
