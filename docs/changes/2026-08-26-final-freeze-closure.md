# Change implementation rationale: Final freeze closure

> **Document contract:** This file explains the bounded correction approved after the final independent review of `c893cd0...fe93e20`. It is not a whole-repository architecture handoff.

## Change identity and boundary

- **Change:** Prevent late account-deletion failures from touching a disposed Home and record the disabled merge audit privacy re-enable gate.
- **Implementation agent:** Codex
- **Base:** `fe93e20ed81c3f1aed2a20d49f7b3badf3c89354`
- **Target:** Current `codex/v1-freeze-remediation` working tree
- **Included paths/services:** Home deletion response handling, app-gate widget regressions, decision 016, roadmap, current overview and rationale, active contract, and execution evidence.
- **Explicit non-goals:** Runtime merge or audit writer changes, deletion protocol redesign, Functions, rules, seed, dependencies, Firebase, native builds, device actions, deployment, PR merge, signing, or release.
- **Request/acceptance criteria:** Andrew approved the final closure in `docs/CHANGE_SPEC.md` on 2026-08-26.
- **Date:** 2026-08-26

The owner's `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` modifications and untracked `docs/CODE_REVIEW_FREEZE_2026-08.md` remain outside the change.

## Outcome

Both account-deletion error paths now verify that Home is still mounted before invalidating `savedSongbookDeletionStateProvider` or looking up scaffold state. A slow request may therefore be overtaken by the positive pending-profile gate, dispose Home, and fail later without producing Riverpod's disposed-consumer `StateError`. When Home remains mounted, the same invalidation and user message still run.

The merge runtime remains unchanged and disabled before request parsing or mutation. Durable records now distinguish reachable generated moderation detail from the legacy `merge_chants` payload, which embeds source title, lyrics, context, tune, and raw `createdBy`. Any future re-enable must pair resumable execution with a privacy-safe audit payload and re-review the retained-action allowlist.

## Impacted capability map

| Capability or boundary | Before | After | Key paths or interfaces | Why affected |
|---|---|---|---|---|
| Deletion response race | Both catch paths invalidated a provider before checking mounted state | Mounted guard dominates every provider and scaffold access | `home_screen.dart :: _showDeleteAccountDialog` | A pending profile can dispose Home while the request is in flight |
| App-gate regression | No delayed-response test crossed active Home into pending deletion | Unconfirmed and generic failures both complete after pending gate takeover | `test/app/app_gate_test.dart` | Lock the exact lifecycle ordering at the widget boundary |
| Merge audit truth | Retained operator detail was described as wholly generated | Legacy merge payload is an explicit disabled exception and re-enable gate | Decision 016 and current engineering records | Authored content and raw creator identity need separate privacy review |

## Implementation choices

| Choice with file or symbol | Why this approach | Alternatives considered | Tradeoff accepted | Evidence or ADR |
|---|---|---|---|---|
| Move `context.mounted` before `ref.invalidate` in both catches | Consumer state and its `ref` become invalid together on disposal | Catch framework errors or keep provider access first | A disposed screen does not refresh a provider it no longer owns | Two red-then-green widget regressions |
| Preserve mounted-path invalidation and messages | Existing recovery behavior remains correct while Home is active | Remove invalidation entirely | No behavior change outside the race | Existing unknown-result test plus focused suite |
| Documentation-only merge correction | The callable is already unreachable before input parsing and no current mutation defect exists | Redesign dormant merge during freeze closure | Merge remains unavailable until a separately approved safe design | Decision 016 and `requireMergeChantsEnabled` guard |

## Changed flow and state

1. Home starts the deletion request after explicit confirmation.
2. A positive pending-profile update may replace Home while the request remains unresolved.
3. If the old request then throws, its catch path first tests `context.mounted`.
4. A disposed Home returns without provider or scaffold access. The pending screen remains authoritative.
5. A still-mounted Home invalidates local deletion state and presents the existing error message.

| Changed invariant or failure condition | Enforcement point | Verification |
|---|---|---|
| No Consumer `ref` access after Home disposal | Both deletion catches | Unconfirmed-response and generic-error widget cases |
| Pending gate remains authoritative after the old request fails | Signed-in profile gate plus mounted guard | Pending screen remains present and Home absent |
| Merge cannot be re-enabled on the old audit contract | Runtime stop plus decision revisit trigger | Source review and durable documentation |

## Security, privacy, and abuse impact

- **Identity and authorization:** No authority or identity rule changes.
- **Sensitive data and retention:** No stored data changes. Documentation now accurately identifies authored fields and raw creator identity in the disabled legacy merge payload.
- **Input and output boundary:** Merge remains stopped before input parsing. Unknown future audit actions remain fail-private.
- **Secrets and external services:** None. No Firebase, live data, registry, device, deployment, or release action is part of this change.
- **Abuse controls:** Unchanged.

## Dependency and infrastructure impact

None. No manifest, lockfile, rule, index, Function, CI workflow, runtime dependency, or deployment configuration changed. The owner-modified lockfile remains excluded.

## Performance, scale, and cost impact

The mounted check is a constant-time client lifecycle guard in two exceptional paths. No steady-state query, storage, network, Function, or Firestore cost changes.

## Verification performed

Before the runtime correction, both new widget cases failed with `Bad state: Cannot use "ref" after the widget was disposed` at the respective provider invalidation. After moving the guard, the focused app-gate file passed all 19 tests. The complete local matrix passed 343 Flutter tests, scoped analysis, 78 Functions tests and build, 42 seed tests, seed and rules TypeScript, and 136 Java-backed Firestore rules assertions. Both touched Dart files are formatted, the read-only repository measurement remains 42 of 142 residual files, and memory, style, ownership, and diff checks pass. Replacement clean-runner CI remains the publication gate.

## Rollout, observation, and recovery

- **Deploy order:** No deployment is authorized. If later released, this is a client-only lifecycle correction.
- **Compatibility:** No schema or protocol change. Existing pending and unknown deletion states are unchanged.
- **Healthy signals:** Complete local verification, replacement PR 14 CI, then the combined device walkthrough.
- **Rollback or forward recovery:** The client ordering can roll back without migration, but doing so reopens the reproduced disposed-consumer error. Merge remains disabled.
- **Operator and user documentation:** Decision 016, roadmap, current overview and rationale, active spec, execution log, and this record are updated. No user-facing copy changes.

## Known compromises and uncertainty

| Item | Consequence | Why accepted | Owner | Revisit trigger |
|---|---|---|---|---|
| Merge remains disabled | Duplicate consolidation is unavailable | Safe resumability and privacy design are separate work | Andrew | Separately approved merge redesign |
| Legacy merge audit payload remains in dormant source | Re-enable without redesign would retain authored fields and raw creator identity | Current guard exits before parsing or mutation | Andrew | Any merge re-enable proposal |
| Native lifecycle not yet walked | Automated widget scheduling cannot prove every device timing | Combined device walkthrough is the next gate | Andrew | Before release |

## Material files and artifacts

- `lib/presentation/home/home_screen.dart`
- `test/app/app_gate_test.dart`
- `docs/decisions/016-account-deletion-audit-privacy.md`
- `ENGINEERING_OVERVIEW.md`, `docs/IMPLEMENTATION_RATIONALE.md`, `docs/ROADMAP.md`, `docs/INTERFACE.md`, and `docs/LEARNINGS.md`
- `docs/CHANGE_SPEC.md`, `docs/EXECUTION.md`, and this completed record

## Documentation impact conclusion

- **Does `ENGINEERING_OVERVIEW.md` need refresh?** Yes. The final runtime lifecycle boundary, merge privacy exception, and verification state changed.
- **Does `docs/IMPLEMENTATION_RATIONALE.md` need refresh?** Yes. The capability ledger, deletion flow, merge gate, evidence, and known compromises changed.
