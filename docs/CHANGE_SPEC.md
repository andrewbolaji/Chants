# Change spec: V1 account deletion recovery

**Status:** Approved, implemented, packaged, and clean-runner verified; external freeze review pending
**Updated:** 2026-08-25
**Risk lane:** Lane 2, destructive lifecycle, background retry, Firebase Auth, persistent server state, and client sign-out behavior
**Stack base:** `dccbad02426022e49ff3ed21b0ae9baf9424985f`, exact green-CI head of stacked draft PR 12
**Branch:** `codex/v1-account-deletion-recovery`, stacked above PR 12

This is the active contract for the final bounded v1 engineering block. The completed report and feedback boundary remains recorded in `docs/changes/2026-08-25-v1-report-feedback-abuse-controls.md` and decision 010. Andrew approved this exact contract before runtime implementation began.

## Outcome

- **Problem:** `deleteAccount` performs eleven sequential cleanup stages inside one callable. A timeout or process failure can leave partial cleanup with no durable phase. Retrying from the beginning cannot rediscover already-deleted documents whose target IDs were needed for counter repair. A failure after Firebase Auth deletion can also strand the profile because the caller can no longer authenticate to retry.
- **Desired behavior:** The authenticated request durably marks the account as deletion-pending and creates one private job. A retry-enabled server worker advances that job through bounded, idempotent pages until interactions are deleted, retained contributions are anonymized, Auth is removed, and the profile and job are atomically finalized. The client treats durable job acceptance as the deletion boundary, removes the device Songbook, and signs out.
- **Non-goals:** Undo or account restoration; deleting retained chants, comments, or replies; changing report, feedback, audit, or contribution retention policy; exposing deletion progress to other users; an operator recovery console; email or push confirmation; scheduled polling; Cloud Tasks; TTL; a new dependency or Firestore index; merge resumability; hosted media; notifications; analytics; deployment; Firebase access; live data; seed work; signing; merge; release; native build; device actions; or repository-wide formatting.
- **Stop boundary:** One deterministic job per UID, one retry-enabled worker, one pending-account gate, and the trigger correction required for deleted user-report counters. No general workflow engine is introduced.

## Acceptance criteria and invariants

### Durable request boundary

1. Keep the callable name `deleteAccount` in `europe-west2` and keep its request payload empty. Authentication is required, and the target UID comes only from `request.auth.uid`.
2. The callable transaction reads `profiles/{uid}` and `accountDeletionJobs/{uid}`. If the job already exists, it returns the same accepted outcome without replacing its phase or timestamps, while reasserting `deletionPending: true` if a profile still exists and the field is missing. This makes a client retry idempotent and repairs the deny marker without resetting progress.
3. If no job exists, the transaction creates `accountDeletionJobs/{uid}` with exactly `schemaVersion`, `phase`, `requestedAt`, and `updatedAt`. Version 1 begins at `disable-auth`. The UID is derived from the document path and is not duplicated in client-supplied data.
4. When the profile exists, the same transaction sets server-owned `deletionPending` to true and updates no other profile field. A missing profile is not a blocker because failed sign-up cleanup can legitimately have Auth without a completed profile.
5. The callable returns `{ accepted: true, success: true }` only after the job transaction commits. It performs no collection scan, user-data deletion, contribution anonymization, audit write, or Auth deletion inline. `success` is retained for one mixed-version release and means durable acceptance, not completed physical cleanup.
6. Firestore rules deny every client read and write to `accountDeletionJobs`. Profile create cannot supply `deletionPending`, and owner profile update is denied once the stored field is true.

### Pending-account authority

7. `UserProfile` parses `deletionPending` as an optional server field defaulting to false. Client profile serialization never emits it.
8. `isOperator` and the existing active-account helper in Firestore rules require both that no `accountDeletionJobs/{uid}` exists and that the profile's pending field is absent or exactly false. The absent-field check must be explicit so every pre-change profile stays compatible. Profile creation also requires no deletion job. A pending account cannot create or update chants, votes, comments, comment likes, or blocks, and cannot use operator authority. Existing owner deletes that only reduce data may remain allowed.
9. `acceptPolicy`, `submitReport`, and `submitFeedback` reject a pending account. Every server callable that grants user or operator authority from a profile must check the pending flag when its touched path is in this block.
10. The signed-in app gate never renders Home or the policy gate for a pending profile. It renders a small account-deletion-in-progress screen with no content or interaction surface and a Sign out action. The normal accepted client path signs out immediately after local cleanup, so this screen is a recovery fallback for delayed sign-out, a reopened old session, or a mixed-version client.

### Retry-enabled bounded worker

11. Add one `onDocumentWritten` worker for `accountDeletionJobs/{uid}` in `europe-west2` with event retry enabled. A delete event or missing current job is a successful no-op.
12. Each invocation reads the current server-owned phase and performs at most one bounded unit: one Auth operation, one audit operation, one finalization batch, or one query page of at most 200 documents. It never scans every matching document into one invocation.
13. Collection pages use existing UID query fields and mutate at most 200 matching rows plus the job heartbeat in one Firestore batch. Deleted rows disappear from the next query. Anonymized rows change their queried ownership field to `deleted-user`, so the next page also makes forward progress without an offset.
14. A nonempty page leaves the phase unchanged and updates `updatedAt`, causing the next worker event. An empty page advances to the next phase. Phase advancement re-reads the job transactionally and advances only if the stored phase still matches, so duplicate or racing delivery cannot move the job backward or skip a phase.
15. The ordered phases are: disable Auth; delete votes; delete chant reports; delete feedback; delete the private safety-rate row; anonymize chants; anonymize comments and replies; delete comment likes; delete comment reports; delete user reports filed by the account; delete user reports against the account; delete blocks created by the account; delete blocks against the account; write the deterministic audit entry; delete Auth; finalize profile and job.
16. `disable-auth` calls the Admin Auth API with `disabled: true`. A missing Auth user is a successful no-op. This prevents a new sign-in while cleanup continues; the profile pending flag remains the direct-write authority because an already-issued token can outlive disablement.
17. Delete and anonymize operations are idempotent under duplicate delivery. The worker does not use blind counter increments, client timestamps, random recovery IDs, or an in-memory-only progress list.
18. The audit phase writes one deterministic `delete-account-{uid}` audit document with bounded lifecycle detail and a server timestamp. Retry overwrites the same semantic entry instead of producing duplicate deletion audits. It does not store email, device data, raw deleted payloads, or full contribution content.
19. The Auth phase treats `auth/user-not-found` as already complete. Finalization deletes `profiles/{uid}` and `accountDeletionJobs/{uid}` in one Firestore batch. If Auth deletion succeeds and finalization fails, the retained job event retries, sees Auth already absent, and retries finalization without requiring the user.
20. No failed worker phase deletes or rewinds the job. Retry delivery remains the recovery mechanism. A permanent retry failure is an operational alert condition, not a client-visible claim that deletion completed.

### Counter and retained-content convergence

21. Submitted chants remain community content and change only `createdBy` to `deleted-user`. Comments and replies remain community content and change only `userId` to `deleted-user` plus `displayName` to `Deleted user`. The current user-facing retention promise remains true.
22. Vote, chant-report, comment-like, and comment-report deletes continue through their existing ground-truth write triggers. Delayed or duplicate delivery converges without the worker retaining affected target IDs.
23. Add deletion handling for `userReports`, whose current trigger handles only creates. A deleted report recomputes `userReportCount` for the surviving reported profile from ground truth. Create audit behavior remains create-only, and a missing target profile is a successful no-op.
24. Comment anonymization keeps visibility and parent relationships unchanged. Existing comment-count recomputation may run from the write trigger, but account deletion does not remove retained comments from the count.
25. Profile and job deletion happen only after every interaction and retained-content phase has reached an empty query. New user-authored writes are blocked from the moment the request transaction commits.

### Client and device-local behavior

26. `ModerationRepository.deleteAccount` remains the replaceable callable boundary and accepts only an explicit `accepted == true` response. Missing or malformed success data is a failure.
27. `AccountDeletionService` stages the active UID's Saved Matchday Songbook before requesting deletion. A request failure restores the exact staged bytes. A staging failure prevents the remote request.
28. After durable acceptance, the service finalizes the local tombstone and signs out. A failure to remove the already-unreadable tombstone does not reverse or misreport the accepted remote deletion; normal storage initialization retries tombstone cleanup. Sign-out is attempted even when tombstone cleanup is deferred.
29. The confirmation copy states that deletion starts after confirmation, retained chants and comments stay anonymized, the local Songbook is removed, and completion may continue briefly in the background. It does not promise undo, instantaneous physical erasure, or recovery of submitted content.
30. The normal success path returns to Sign in. A request failure leaves the account and Songbook usable and shows retry copy. The pending fallback screen remains readable at 390 by 844 logical pixels and 1.8 text scale without overflow.

### Verification and delivery

31. Functions tests prove authenticated empty requests, missing-profile cleanup, deterministic duplicate requests, exact job shape, same-transaction pending state, every phase transition, 200-row page bounds, multi-page progress, duplicate delivery, stale phase protection, Auth disable, Auth already missing, deterministic audit, failure retention, and final profile-plus-job cleanup.
32. A focused trigger test proves user-report deletion repairs a surviving target's `userReportCount` and writes no create audit. Existing vote, report, comment-like, comment, and user-report create tests remain green.
33. Rules tests prove jobs are completely private, clients cannot set or clear `deletionPending`, an account with a job cannot create a late profile, pending users cannot create or update active content or exercise operator access, ordinary profiles without the new field retain current behavior, and cleanup-reducing owner deletes remain as explicitly allowed.
34. Flutter tests prove profile parsing, pending gate precedence, request result validation, local success and request-failure compensation, deferred tombstone cleanup, sign-out, and confirmation or failure copy. The pending screen receives a screenshot review.
35. Existing Flutter, Functions, seed, rules, and analysis suites remain green. New load-bearing tests receive deliberate red checks before restoration. `git diff --check` passes and the three pre-existing Android and lockfile edits remain unstaged.
36. Planning, implementation, local verification, clean-runner verification, external review, deployment, observation, merge, and release remain separate states. This specification authorizes none of deployment, Firebase access, live reads or writes, seed operations, merge, signing, release, native build, or device actions.

Invariants:

- A client can request deletion only for its authenticated UID.
- Durable server acceptance happens before the client destroys its recoverable local copy or signs out.
- Once accepted, deletion no longer depends on the user keeping the app open or authenticating again.
- Pending accounts cannot create new retained data while cleanup is progressing.
- Retry and duplicate delivery never undo anonymization, recreate interactions, duplicate the deletion audit, or move the job backward.
- Chants and comments remain as anonymized community content; private interactions and profile data are removed.
- The worker never claims completion while a phase, profile, or job remains.

## Design

### Job state machine

Place the request transaction and worker in a focused `functions/src/account_deletion.ts` module. The exported callable wrapper and Firestore trigger stay in `functions/src/index.ts`. The module receives Firestore, Auth, clock, and audit boundaries explicitly so failure and redelivery can be tested without live Firebase.

The job is a cursor, not an archive. Its phase is the only durable progress needed because every data phase queries the rows that still carry the deleting UID. A batch that mutates a page also updates the job heartbeat, so either both the page and next event exist or neither does. An empty-page transition uses a transaction to avoid stale duplicate events regressing state.

Use a fixed phase allowlist and schema version. Unknown versions or phases fail closed and retain the job for investigation. Do not guess a next phase from malformed state.

### Authority during cleanup

The profile remains until the final batch because current rules and callables use it as the account authority record. `deletionPending` turns that record into a deny state while still letting the worker find and finalize it. Disabling Auth blocks future sign-ins, while the profile flag handles already-issued credentials.

The pending app screen is a recovery surface, not a progress dashboard. It exposes no phase, counts, timestamps, or retry controls because server retry owns progress and the job is intentionally private.

### Trigger convergence

Bulk deletion already emits one document event per removed vote, chant report, comment like, and comment report. Those handlers recompute from ground truth and tolerate missing parents. User-report deletion is the only missing convergence path, so this block adds that exact trigger behavior rather than storing potentially large affected-ID arrays in the job.

### Local deletion boundary

The callable now means "the durable deletion job exists," not "every remote row is already gone." That is the correct handoff point for local cleanup and sign-out because the server worker no longer needs the client. The existing tombstone provides crash safety before acceptance and unreadability after acceptance.

## Failure and abuse analysis

| Condition | Required behavior | Evidence |
|---|---|---|
| Caller supplies a target UID or job phase | Empty-payload validation rejects it; server derives UID and phase | Functions request tests |
| Same request is sent twice | Existing job is returned as accepted without phase reset | Functions idempotency test |
| Function dies after deleting one page | Page mutation and heartbeat are durable; retry processes remaining rows | Multi-page failure test |
| Two worker events process the same phase | Mutations are idempotent and transactional advancement cannot regress or skip | Duplicate-delivery test |
| User signs in again during cleanup | Auth disable blocks new sign-in; pending profile blocks current-token writes | Auth fake and rules tests |
| Worker fails after Auth deletion | Job remains; retry treats missing Auth as complete and retries final batch | Finalization failure test |
| User-report delete trigger arrives after target profile deletion | Ground-truth count is computed and missing profile is a successful no-op | Trigger test |
| Local staging fails | No remote request occurs; active file remains | Flutter service test |
| Remote request fails before acceptance | Exact local bytes are restored and account stays usable | Flutter service test |
| Local tombstone removal fails after acceptance | Remote job remains accepted, sign-out proceeds, later initialization retries cleanup | Flutter service and storage tests |
| Malformed server-owned job appears | Worker fails closed and preserves evidence; it does not delete Auth | Functions malformed-job test |
| Old client calls the new Function | Empty request remains compatible; cleanup completes in background | Contract review |
| New client calls the old Function during rollout | The new client requires `accepted == true`, so deploy the new Function before the new client | Rollout review |

## Performance, cost, and privacy

- A worker invocation mutates at most 201 Firestore documents, including its heartbeat. No invocation loads an unbounded user history.
- The state machine adds one server-only document and a bounded number of trigger invocations per deletion. It adds no polling, scheduler, task queue, index, dependency, IP address, device identifier, or raw-payload archive.
- Existing per-document counter triggers still run for deleted interactions. This can be noisy for a very active account, but the work converges from ground truth and remains acceptable before v1 volume. Revisit when measured deletion volume or trigger cost requires bulk reconciliation.
- The job stores only lifecycle phase and server timestamps. The audit stores one UID-scoped bounded event and no content body or email.

## Rollout and recovery

1. Implement and prove the Function state machine, deletion trigger, rules, client lifecycle, pending screen, and focused red checks locally.
2. Run the complete local matrix and clean-runner CI before external review.
3. After separate deployment authorization, deploy backward-compatible rules first, then Functions, then the client. Rules treat absent `deletionPending` as active, the new callable keeps the old name and empty payload, and the new client begins only after the new `{ accepted: true }` response is deployed.
4. Keep returning `success: true` beside `accepted: true` for one release so old clients continue treating durable acceptance as success. The worker owns completion after either client version receives that response.
5. Do not roll back or remove the worker while any deletion job exists. A rollback keeps the worker deployed until jobs drain, restores client and rules behavior only after that check, then removes the job path in a separately verified deploy.
6. No live job inspection, deployment, seed action, merge, or release occurs under this specification.

Healthy signals are jobs advancing without manual retries, no pending account writes, no duplicate deletion audits, no permanently retained jobs, ground-truth counters converging after interaction deletion, and profile plus job disappearing after Auth deletion.

## Approval

**Approved.** Andrew approved this exact contract with `approved v1 account deletion recovery spec` on 2026-08-25.

Approval authorizes repository implementation, tests, screenshots, and proportionate local or clean-runner verification on `codex/v1-account-deletion-recovery`. It does not authorize Firebase access, deployment, live observation, seed operations, merge, signing, release, native build, or device actions.

## Implementation result

The approved boundary is implemented in the local worktree. The full local matrix passes 310 Flutter tests, 69 Functions tests, 42 seed tests, 135 Java-backed Firestore rules assertions, scoped Flutter analysis, Functions and rules TypeScript compilation, and diff checks. Three deliberate red checks proved the page bound, pending-account rule denial, and pending app-gate precedence before restoration. The pending-state golden was visually inspected at 390 by 844.

The completed record is `docs/changes/2026-08-25-v1-account-deletion-recovery.md`, and durable decision 011 preserves the architecture. Implementation commit `98f2c9ee98d5feb7a901cb3e8907b056b340b05d` is published in draft PR 13, and all five jobs passed in clean-runner GitHub Actions run `32907722272`. External freeze review, native compilation, device walk, deployment, and release remain separate later states.
