# Change implementation rationale: Post-review audit and recovery corrections

> **Document contract:** This file explains the bounded correction approved after the independent review of `f5cb748...c893cd0`. It is not a whole-repository architecture handoff.

## Change identity and boundary

- **Change:** Correct audit classification, target-side deletion copy, prepared local recovery, completion-audit reasoning, direct empty-message SHA coverage, and current formatter evidence.
- **Implementation agent:** Codex
- **Base:** `c893cd00477daf4626b599448ab09b083f5375d9`
- **Target:** Current `codex/v1-freeze-remediation` working tree
- **Included paths/services:** Account-deletion audit page, Saved Songbook repository and app gate, deletion copy and recovery screen, focused Functions and Flutter tests, one refreshed golden, durable decisions, and current milestone records.
- **Explicit non-goals:** Raw UID retention for deleted operators; deletion of target-side safety history; report admission, rate limits, counters, rules, job monitoring, dependencies, Firebase state, seed data, native builds, device actions, deployment, merge, or release.
- **Request/acceptance criteria:** Approved `docs/CHANGE_SPEC.md` after the narrow independent follow-up review.
- **Date:** 2026-08-26

The owner's `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` modifications and untracked `docs/CODE_REVIEW_FREEZE_2026-08.md` remain outside the change.

## Outcome

Actor-owned audit cleanup now classifies rows instead of flattening every record. Known generated operator actions use `deleted-operator` and preserve their moderation detail. Reports remove the submitted reason, self-target policy acceptance removes the target UID, and unknown actions fail private with generic detail. Delayed report writers keep their transactional lifecycle check. The non-identifying completion audit remains random-ID, and exactly-once behavior is provided by committing the audit and job-phase advancement together.

Prepared Saved Songbook state can now recover in the same process. The repository clears its initialization memo, serializes another artifact-recovery attempt, and returns the current state. The signed-in gate actively invokes that recovery and remains closed behind a real retry if it fails. A pre-network transition failure restores staged data and never calls the remote deletion boundary. Unknown and accepted semantics are unchanged.

Deletion copy now says precisely what the implementation can prove: reports sent by the deleting account retain neither its actor ID nor submitted text, while safety history about the account may retain its target ID. The SHA implementation has a direct standard empty-message vector, and current formatter evidence records 42 of 142 residual files.

## Impacted capability map

| Capability or boundary | Before | After | Key paths or interfaces | Why affected |
|---|---|---|---|---|
| Actor-owned audit cleanup | Every actor row became `deleted-user` with generic detail | Known operator actions retain generated detail under `deleted-operator`; report and unknown text is replaced | `account_deletion.ts :: auditRedactionForDeletedActor` | Preserve safe accountability without raw identity |
| Completion audit | Documentation implied stable document identity | Random-ID write and phase advancement share one transaction | `processAccountDeletionStep` | Exactly once must match the actual concurrency mechanism |
| Prepared local recovery | A prepared marker could remain until repository reconstruction | Serialized same-process recovery clears initialization memo and reruns storage recovery | `SavedSongbookRepository`, `savedSongbookDeletionStateProvider` | Retry must perform recovery work |
| Deletion copy | Implied no account ID remained anywhere in safety history | Separates authored-report redaction from target-side retention | deletion dialog and pending screen | User promise must match retained data |
| SHA evidence | Empty UID wrapper rejection stood in for empty digest input | Direct empty-message digest plus wrapper rejection | `sha256.dart` test | Lock the primitive boundary independently |

## Implementation choices

| Choice with file or symbol | Why this approach | Alternatives considered | Tradeoff accepted | Evidence or ADR |
|---|---|---|---|---|
| Action allowlist in `auditRedactionForDeletedActor` | Only known operator details are trusted generated text | Preserve all detail or flatten all detail | New operator actions fail private until classified | Decision 016 and action-matrix test |
| `deleted-operator` sentinel | Keeps role-level provenance without raw UID | `deleted-user`, raw UID, or per-user pseudonym | Individual operator attribution is removed | Decision 016 |
| Phase-transaction exactly once | Matches the existing state machine | Stable document ID or post-write phase update | Safety depends on the job transaction remaining atomic | Duplicate-delivery regression |
| Serialized repository recovery | Reuses existing storage recovery and mutation order | Reconstruct repository or reread marker | One additional local filesystem pass on prepared state | Decision 012 and repository tests |
| Fail-closed recovery screen | Home cannot open while prepared recovery is unresolved | Treat prepared as active or deletion-unknown | Local access can remain closed until recovery succeeds | App-gate tests and golden |

## Changed flow and state

1. The signed-in gate reads the active UID's local deletion state.
2. If state is `prepared`, the repository clears the successful initialization memo and reruns artifact recovery inside its mutation queue.
3. Successful recovery returns active state and permits the normal gate. Failure renders `RECOVERY NEEDED`; `TRY RECOVERY` invalidates the provider and performs another recovery attempt.
4. The deletion service prepares local data and must finish the prepared-to-unknown transition before calling the remote boundary. A local transition error restores prepared artifacts and preserves the original error.
5. The server worker queries at most 200 actor-owned audit rows and computes an update from each row's action.
6. Report and unknown text is removed; known operator detail is retained under a role sentinel; self-target policy acceptance loses the raw target UID.
7. The completion audit and phase advancement commit together. Delivery after advancement observes the next phase and writes no second completion row.

| Changed invariant or failure condition | Enforcement point | Verification |
|---|---|---|
| Known operator audit detail survives without raw operator identity | `auditRedactionForDeletedActor` | Nine-action matrix and mixed page |
| User-authored or unknown audit text does not survive | Audit classification and delayed writer | Report, unknown, pending-profile, and missing-profile tests |
| Completion audit occurs once per job | Write-audit transaction | Duplicate worker delivery test |
| Prepared state retries without relaunch | Repository recovery and signed-in provider | Same-process repository and app-gate tests |
| Local transition failure cannot call remote deletion | `markAccountDeletionRequestStarted` failure handling | Service boundary test |
| Recovery failure cannot expose Home | `_SignedInGate` recovery state | Widget test and inspected golden |

## Security, privacy, and abuse impact

- **Identity and authorization:** No authority rule changes. Raw actor identity is still removed. `deleted-operator` exposes only a role category.
- **Sensitive data and retention:** Authored report reasons and unknown detail are removed. Known generated operator detail may remain. Target-side safety history may retain the account ID and is disclosed in user copy.
- **Input and output boundary:** The action allowlist is fail-private. A new or misspelled action receives generic detail until explicitly reviewed.
- **Secrets and external services:** None. No credential, Firebase, live data, registry, device, or deployment action occurred.
- **Abuse controls:** Report admission and budgets are unchanged.

## Dependency and infrastructure impact

None. No manifest, lockfile, rule, index, service, CI workflow, runtime, or deployment configuration changed. The owner-modified lockfile remains excluded.

## Performance, scale, and cost impact

- **Affected workload:** Account-deletion audit pages perform the same bounded query and writes, with a small per-row action classification. Prepared launch recovery performs one additional local artifact-recovery pass only while a prepared marker exists.
- **Expected resource change:** No additional Firestore read or write beyond the existing page. No normal app launch work changes after prepared state resolves.
- **Budget:** Audit pages remain capped at 200 rows. Local recovery remains serialized behind the repository mutation queue.
- **Measured evidence:** Tests cover a mixed 201-row population and same-process recovery. No production workload was accessed.

## Verification performed

The complete local matrix passed 341 Flutter tests, 78 Functions tests and build, 42 seed tests, seed and rules TypeScript, 136 Java-backed Firestore rules assertions, and scoped Flutter analysis. Before that matrix, the focused Flutter lifecycle, service, repository, recovery-screen, and golden tests passed 45 cases; the focused Functions account-deletion and audit-writer group passed 15 cases. The refreshed 390 by 844 pending-state golden was visually inspected with no clipping. Touched Dart files are formatted, the read-only repository formatter measurement reports 42 of 142 residual files, and memory, style, caller, ownership, and diff checks pass.

The regression guards sit at the smallest affected boundaries: pure audit classification, mixed bounded page, duplicate completion delivery, repository recovery, remote-not-called service behavior, app-gate retry, exact copy, and direct SHA input.

## Rollout, observation, and recovery

- **Deploy order:** If later authorized, deploy Functions before the corrected client. Rules and seed are unchanged.
- **Compatibility:** This stack is unreleased. Older clients do not depend on audit detail classification. Prepared recovery only changes a local fail-closed state.
- **Healthy signals:** Replacement clean-runner CI, then the combined device walk. No deployed observation was authorized.
- **Rollback or forward recovery:** Audit redaction is forward-only and requires a forward correction if wrong. Client recovery and copy can be reverted only while unknown and accepted states remain fail-closed.
- **Operator and user documentation:** Decisions 012 and 016, interface memory, current overview and rationale, learning memory, roadmap, and this record are updated.

## Known compromises and uncertainty

| Item | Consequence | Why accepted | Owner | Revisit trigger |
|---|---|---|---|---|
| Target-side safety rows may retain account ID | Deletion is not a claim that every moderation reference disappears | Other actors' records serve a separate safety purpose and copy now discloses it | Andrew | Approved retention policy changes |
| Operator sentinel removes individual attribution | Historical action retains role but not the specific operator | Data minimization is preferred after deletion | Andrew | Approved pseudonymous operator ledger |
| Action allowlist needs maintenance | New trusted actions default to generic detail | Fail-private default is safer than accidental text retention | Andrew | Any new audit action |
| No retained-job alert or recovery console | A permanent worker failure can remain invisible | Separate operational block | Andrew | Before public beta or first retained job |
| No repository-wide format gate | 42 of 142 files remain non-normalized | Avoid unrelated mechanical churn in a privacy correction | Andrew | Separate format-only change |

## Material files and artifacts

- `functions/src/account_deletion.ts` and `functions/test/account_deletion.test.ts`.
- `lib/app/providers.dart`, `lib/data/repositories/saved_songbook_repository.dart`, deletion service behavior, and deletion screens.
- Focused Flutter tests, Functions tests, SHA vector, and refreshed pending-state golden.
- Decisions 012 and 016, current overview and rationale, interface and learning memory, active spec, execution log, roadmap, and this completed record.

## Documentation impact conclusion

- **Does `ENGINEERING_OVERVIEW.md` need refresh?** Yes. Audit provenance, exactly-once behavior, prepared recovery, user copy, CI baseline, formatter residual, and verification evidence changed.
- **Does `docs/IMPLEMENTATION_RATIONALE.md` need refresh?** Yes. The repository-wide capability ledger, deletion flow, invariants, privacy boundary, test evidence, and known compromises changed.
