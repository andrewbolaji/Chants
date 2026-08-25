# Decision 011: Account deletion uses a durable bounded job

- **Status:** Accepted
- **Date:** 2026-08-25
- **Owner:** Andrew
- **Related:** Decisions 003, 009, and 010; v1 account deletion recovery

## Context

The original `deleteAccount` callable performed eleven sequential cleanup stages before deleting Firebase Auth and the profile. A timeout or process failure could leave partial cleanup with no durable phase. After Auth deletion, the user could no longer authenticate to retry. Restarting the whole callable also could not reliably recover target IDs from interaction rows that had already been deleted.

Account deletion crosses Firebase Auth, public retained contributions, private interactions, counters, audit state, the profile authority record, and the device-local Saved Matchday Songbook. It therefore needs a durable handoff that does not depend on the client remaining connected.

## Decision

An authenticated empty `deleteAccount` request creates one private deterministic `accountDeletionJobs/{uid}` document and marks the existing profile `deletionPending: true` in the same transaction. The callable returns only after this request is durable. Repeating the request never resets the stored phase or timestamps.

A retry-enabled `onAccountDeletionJobWritten` Function advances one bounded unit per event. Collection work is paged at 200 documents. Interactions are deleted, retained chants and comments are anonymized, a deterministic audit entry is written, Firebase Auth is deleted, and the profile plus job are finalized atomically. Missing Auth users and already-processed rows are successful no-ops. Unknown job schemas or phases fail closed and preserve the job for investigation.

Pending authority is a deny state. Firestore rules require both no deletion job and an absent-or-false profile pending marker before active writes or operator actions. Touched callables perform the corresponding server check. The signed-in app gate shows only a deletion-in-progress recovery screen with Sign out.

The client stages the UID-scoped Saved Songbook before the request. A request failure restores the exact local bytes. Durable acceptance finalizes the unreadable tombstone and signs out, while deferred tombstone removal is retried by normal storage initialization.

User-report deletion receives its own ground-truth convergence trigger so deletion of reports filed by one account repairs a surviving target profile's count.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Keep one synchronous callable | Small source footprint | Timeout can strand partial cleanup and Auth deletion removes the caller's retry authority | It cannot meet recoverability requirements |
| Retry the whole callable from the beginning | No job collection | Deleted rows can erase reconciliation context, and work remains unbounded | Idempotency alone does not provide a durable cursor |
| Store every affected target ID in the job | Direct counter repair list | Job size grows with account history and becomes another sensitive archive | Existing deletion triggers can converge from ground truth |
| Cloud Tasks or a general workflow engine | Explicit scheduling and richer operations | New service, dependency, deployment, cost, and operational surface | One Firestore event cursor is enough for v1 |
| Delete submitted chants and comments | Simpler ownership cleanup | Breaks the current community-content retention promise | Retained contributions remain useful when anonymized |

## Consequences

- Positive: accepted deletion completes without the app remaining open or the user authenticating again.
- Positive: each invocation has a bounded Firestore mutation footprint and duplicate delivery does not regress progress.
- Positive: current and mixed-version sessions lose write authority immediately after the request transaction.
- Positive: local Songbook cleanup preserves compensation before acceptance and privacy after acceptance.
- Negative: deletion is eventually complete rather than physically complete when the callable returns.
- Negative: one private job and multiple trigger invocations are created per deletion.
- Negative: a permanently failing phase needs operational alerting and manual investigation. V1 adds no operator job console.
- Operational: deploy backward-compatible rules first, then Functions, then the client. Do not remove the worker while any job remains.

## Validation and revisit trigger

- **Evidence:** 69 Functions tests, 135 Java-backed rules assertions, 310 Flutter tests including an inspected 390 by 844 golden, 42 seed tests, three deliberate red checks, and the completed record in `docs/changes/2026-08-25-v1-account-deletion-recovery.md`.
- **Revisit when:** deletion volume or duration produces retained jobs, Eventarc retry needs a dead-letter or alerting path, legal retention policy changes, exports or restoration are added, or a reusable destructive-work orchestration service becomes justified.
