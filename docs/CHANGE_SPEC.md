# Change spec: Post-review audit and recovery corrections

**Status:** Approved, implemented, and locally verified
**Updated:** 2026-08-26
**Risk lane:** Lane 2, destructive account lifecycle, audit retention, local recovery, and user-facing deletion copy
**Stack base:** `c893cd00477daf4626b599448ab09b083f5375d9`, clean-runner PR 14 correction head
**Branch:** `codex/v1-freeze-remediation`
**Review source:** Independent review of `f5cb748...c893cd0`

## Outcome

- **Problem:** The reviewed head flattened operator moderation detail along with report text. Its deletion dialog overstated removal of target-side identifiers, a prepared local Songbook could remain behind a no-op recovery action until relaunch, and the completion-audit contract claimed stable document identity even though safety came from transactional phase advancement. Empty-message SHA coverage and formatter evidence were incomplete.
- **Desired behavior:** Account deletion removes the deleting account's actor identity and user-authored report text without discarding known operator action detail or its operator provenance. Copy accurately distinguishes actor-side redaction from retained target-side safety history. Prepared local data restores after a pre-network failure without relaunch. Completion audit delivery is exactly once through the durable phase transaction. SHA and documentation evidence match the implementation.
- **Non-goals:** Retaining a deleted operator's raw UID; deleting target-side safety history; changing report admission, rate limits, counters, rules, job monitoring, dependencies, native code, seed data, Firebase state, deployment, merge, or release.
- **Stop boundary:** Correct only the independently verified D-1 through D-6 findings and their direct tests and durable records.

## Acceptance criteria and invariants

### Audit classification

1. The bounded `anonymize-audit-by` phase still queries at most 200 rows where `actorId` equals the deleting UID and remains retryable and idempotent.
2. Known operator actions `ban`, `unban`, `promote`, `demote`, `remove-evidence`, `hide`, `unhide`, `remove`, and `merge_chants` become `actorId: deleted-operator` and retain their generated moderation detail, action, target type, target ID, and timestamp.
3. `report` and `report-user` rows become `actorId: deleted-user` and replace the reason with deletion-safe generic detail.
4. `accept-policy` becomes `actorId: deleted-user`; a self target becomes `targetId: deleted-user`; its generated policy-version detail may remain.
5. Unknown actor actions fail private: actor becomes `deleted-user` and detail becomes generic rather than risking retained user-authored text.
6. Delayed report writers retain the existing transaction that writes no reporter UID or reason for pending or missing profiles.
7. Tests cover a mixed 201-row population, known operator detail preservation, report and unknown-action redaction, accept-policy self-target redaction, multi-page advancement, and retry safety.

### Completion audit

8. The completion audit contains no deleted UID in document ID or stored fields.
9. Exactly one completion row is committed because the audit write and phase advancement share one transaction. A duplicate worker delivery after advancement writes no second row.
10. Documentation no longer claims a deterministic or stable audit document ID.

### Prepared local recovery

11. `prepared` continues to mean the remote deletion request was not called. Recovery may therefore restore it to the active Songbook.
12. The repository exposes a serialized retry that clears the successful initialization memo, reruns artifact recovery, and returns the resulting local deletion state.
13. The app gate invokes that recovery for prepared state and never presents a `CHECK AGAIN` action that only rereads the same marker.
14. A recovery failure remains fail-closed with a meaningful retry and Sign out. Unknown and accepted behavior does not change.
15. Repository and app-gate tests prove prepared recovery without process relaunch and prove Home remains closed when recovery fails.

### Copy, SHA, and documentation

16. The deletion dialog states that safety records about the account may retain its ID while reports authored by the deleting account retain neither its actor ID nor submitted report text.
17. `sha256Hex(const [])` is tested directly against the standard empty-message digest. The UID wrapper continues to reject an empty UID.
18. Current formatter residual evidence is 42 of 142 Dart files. The earlier 46-of-142 observation remains attributed only as historical evidence.
19. Decision 016, decision 012, overview, implementation rationale, interface memory, learning memory, roadmap, scoped change rationale, and execution log describe the corrected behavior and residual target-side retention accurately.
20. Focused tests run before the complete Flutter, Functions, seed, rules, scoped analysis, formatting, memory, writing-style, and diff checks.
21. The owner's existing `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` changes remain unstaged and unedited. The untracked `docs/CODE_REVIEW_FREEZE_2026-08.md` remains outside this block.

## Threat, failure, and compatibility analysis

- Preserving detail is allowlisted only for known generated operator actions. Unknown actions redact detail.
- `deleted-operator` preserves role-level accountability without retaining the deleted account's raw UID.
- Target-side identifiers may remain when another actor reported or moderated the deleting account. The user copy must disclose this instead of promising full audit erasure.
- Prepared recovery is safe because the repository marks `unknown` before awaiting the remote request. If that transition fails, the remote callable is never invoked.
- Completion audit deduplication depends on the job phase transaction, not on a predictable document ID.
- No deployed compatibility claim is made. This stack remains unreleased and no Firebase access or rollout is authorized.

## Rollout and rollback

1. If later authorized, deploy Functions before the corrected client. Rules and seed are unchanged.
2. Audit redaction is forward-only. A faulty deployed classification requires a forward correction.
3. Prepared recovery and copy can roll back independently only while unknown and accepted artifacts remain fail-closed.
4. No production rollout, migration, deployment, signing, native build, merge, or release is authorized by this spec.

## Delivery state

Local implementation and verification are complete: 341 Flutter tests, 78 Functions tests, 42 seed tests, 136 Java-backed rules assertions, scoped analysis, rules and seed TypeScript, touched-file formatting, the read-only 42-of-142 formatter measurement, memory and style checks, and diff checks. Packaging, commit, push, replacement clean-runner CI, merge, deployment, and observation remain separate later states.
