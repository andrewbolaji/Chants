# Change spec: Post-freeze independent review corrections

**Status:** Implemented and locally verified; packaging, clean-runner CI, and narrow re-review pending
**Updated:** 2026-08-26
**Risk lane:** Lane 2, destructive account lifecycle, privacy retention, persistent local state, Firestore authorization, and user-facing recovery
**Stack base:** `f5cb748a8e5fbc0bc36eec5f686729e9b1c0f4bc`, PR 14 head before this correction
**Branch:** `codex/v1-freeze-remediation`
**Review source:** Independent review of `c57815c...f5cb748`

## Outcome

- **Problem:** An ambiguous account-deletion response leaves the local Songbook safely locked but does not present a durable recovery route after process death. Confirmed cleanup can also leave conflicting local artifacts. Account deletion retains reporter identity and free-text reasons in audit rows. A small set of related authority, offline-action, retry, dead-code, test, and documentation defects remain at the freeze boundary.
- **Desired behavior:** A signed-in user with an unknown local deletion request always sees a persistent, truthful retry surface. The client never restores uncertain data from a negative or cached observation. Positive server evidence can advance cleanup. Confirmed deletion removes every local artifact safely. Deleted users are no longer identifiable through audit actor fields or report text. Existing local Songbook actions remain useful offline without weakening live server authority.
- **Non-goals:** Cancellation or undo for account deletion; a new server receipt protocol; a deletion-job sweeper, alert, or operator console; aggregate-counter redesign; dependency changes; production policy approval; native compilation; device actions; Firebase access or deployment; seed actions; merge or release.
- **Stop boundary:** Correct the independently verified deletion-recovery, audit-privacy, local-action, initialization, permission classification, target-guard, dead-code, SHA-vector, and documentation findings. Do not broaden into release operations or speculative scale work.

## Acceptance criteria and invariants

### Unknown deletion acknowledgement

1. A local `unknown` marker remains unreadable and write-locked. A profile observation with `deletionPending == false` never restores it because the observation may be cached, stale, or race a request that later commits.
2. The app gate checks local deletion state for the authenticated UID before exposing Home. An unknown request renders a persistent recovery screen with truthful explanatory copy, a retry action, and Sign out.
3. Retry uses the existing idempotent `deleteAccount` callable and preserves unknown state on another ambiguous failure. Explicit callable success advances the local marker to accepted, removes local artifacts, and signs out through the existing service boundary.
4. A verified profile with `deletionPending == true` is positive acceptance evidence. When it coexists with a local unknown marker, the client advances local state to accepted and retries cleanup before showing the existing deletion-pending screen.
5. The interface never claims that an unknown request failed, succeeded, or can be cancelled. Transient recovery failures remain retryable and do not expose Home.

### Local artifact cleanup and initialization

6. Confirmed deletion removes active, temporary, prepared, and unknown artifacts before removing the accepted marker. If cleanup fails, the accepted marker remains last so any surviving data stays unreadable and cleanup can retry.
7. A transient initialization failure is not memoized forever. Concurrent callers still share one in-flight initialization, while a later call can retry after failure.
8. Resetting an ordinary local copy cannot clear deletion markers or bypass the deletion boundary.
9. Tests reconstruct storage and repository instances across unknown, accepted, conflicting-artifact, retry, positive-reconciliation, and transient-I/O cases.

### Audit privacy

10. The durable deletion job includes a resumable, idempotent phase that finds audit rows where the deleted UID is `actorId`, replaces the actor with a non-identifying sentinel, and replaces user-authored detail with generic deletion-safe text.
11. The final deletion audit row contains no deleted UID in its document ID, actor, target, or detail. Its identity remains stable across retries of the same durable job.
12. Audit rows about the deleted account may remain for moderation and security history, but the deletion copy and engineering documents state the retention boundary accurately. No reporter UID or report free text remains linked to the deleted user as actor.
13. Functions tests prove multi-batch progress, retry safety, redaction content, final-audit identity, and compatibility with existing phase parsing.

### Local Songbook actions and live authority

14. When a chant is already saved, opening its saved club or removing its individual local copy remains available from cached or route detail because both actions are device-local.
15. Creating a new save still requires an active, error-free, non-cache, current visible chant. Share, Report, Vote, and Comment retain the existing live-authority gate.
16. Widget tests distinguish existing local actions from a new save and preserve the visible disabled state for server-authorized actions.

### Bounded hardening

17. Permission denial is recognized only from typed Firebase error codes. Unrelated error text containing `permission-denied` does not hide a Discover card.
18. User-report admission rejects either a pending target profile or an existing deletion job in the same transaction.
19. Unused client report lookup repositories and the unused comment-report lookup method are removed after a complete `lib/` and `test/` caller search.
20. The in-tree SHA-256 implementation retains its existing known-vector tests and adds empty-input, multi-block NIST, and block-boundary coverage without adding a package or changing `pubspec.lock`.

### Documentation and verification

21. `ENGINEERING_OVERVIEW.md`, `docs/IMPLEMENTATION_RATIONALE.md`, `docs/INTERFACE.md`, the affected decisions, and the scoped change rationale describe persistent unknown recovery, audit retention/redaction, local-only saved actions, and residual operations and scale risks accurately.
22. Formatter evidence reports the current observed scope, 46 of 142 Dart files would change before repository-wide formatting, without claiming those unrelated files are part of this block.
23. The controlled transaction test is described as modeling a parent-version conflict and verifying handler convergence under retry, not as proving Firestore's runtime implementation.
24. PR 14 clean-runner evidence is attributed to run `32932769393` at `f5cb748`; later local or CI evidence is recorded separately.
25. Focused regression tests run before the complete Flutter, Functions, seed, rules, scoped analysis, formatting, memory, writing-style, and diff checks that apply.
26. The owner's existing `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` changes remain unstaged and unedited. The untracked `docs/CODE_REVIEW_FREEZE_2026-08.md` remains outside this block.

## Threat, failure, and compatibility analysis

- A negative profile observation cannot safely prove rejection, so it cannot unlock local data. Only callable success or a positive pending marker can advance deletion state.
- Process death is handled by durable local markers and an app-gate recovery surface rather than transient snackbar state.
- Audit redaction is monotonic and idempotent. A retry may redact the same rows again without restoring identity or text.
- The new deletion phase is compatible with jobs created by this unreleased stack because phase parsing accepts the updated exact phase set. No production migration or deployment is authorized here. If an older worker were ever deployed with in-flight jobs, rollout would first require proving those jobs drained or a separate backfill plan because a job already beyond the inserted phase cannot be assumed redacted.
- Accepted-marker-last cleanup preserves privacy after partial local I/O failure.
- Removing dead repositories changes no supported caller because the complete source and test population has zero references.

## Rollout and rollback

1. If later authorized, deploy Functions before releasing a client that depends on positive pending reconciliation. Existing clients remain compatible with the durable deletion job.
2. The audit phase is forward-only privacy work. Rollback must not reintroduce deleted actor identity or report text. A faulty deployed phase requires a forward correction.
3. The client recovery screen and local-action split can be rolled back independently only if unknown markers remain locked and retryable.
4. No production rollout, deployment, migration, signing, native build, merge, or release is authorized by this spec.

## Delivery state

Approved for local implementation and verification. Packaging, commit, push, clean-runner CI, merge, deployment, and observation remain distinct later states and require the authority applicable to each action.
