# Change spec: Final freeze closure

**Status:** Approved, implemented, and locally verified
**Updated:** 2026-08-26
**Risk lane:** Lane 2, destructive account lifecycle and retained audit privacy
**Stack base:** `fe93e20ed81c3f1aed2a20d49f7b3badf3c89354`, clean-runner PR 14 correction head
**Branch:** `codex/v1-freeze-remediation`
**Review source:** Final independent review of `c893cd00477daf4626b599448ab09b083f5375d9...fe93e20ed81c3f1aed2a20d49f7b3badf3c89354`

## Outcome

- **Problem:** A slow account-deletion response can complete after the profile stream replaces Home with the deletion-pending screen. Both error handlers currently invalidate a Riverpod provider before checking whether Home is still mounted, so the disposed consumer element can throw an unhandled `StateError`. Separately, the disabled merge action's retained audit detail includes authored source content and a raw creator ID, while the current decision rationale describes every retained operator detail as trusted generated text.
- **Desired behavior:** Late deletion errors are ignored by a disposed Home without touching Riverpod or scaffold state. Mounted Home still refreshes deletion state and presents the existing error. The disabled merge path remains stopped, and durable architecture truth makes privacy-safe audit classification an explicit prerequisite for any future re-enable.
- **Non-goals:** Re-enabling or redesigning merge; changing deletion protocol states, Functions, Firestore rules, seed data, dependencies, native code, product copy, Firebase state, deployment, merge, or release.
- **Stop boundary:** Correct the one reproduced disposed-consumer race, its two direct regressions, and the dormant merge audit privacy record. Then package exactly one correction commit, push PR 14, and run replacement clean-runner CI.

## Acceptance criteria and invariants

### Disposed Home deletion response

1. Both the unconfirmed-response and generic-error deletion handlers check `context.mounted` before any `ref` access or scaffold lookup.
2. When Home remains mounted, both handlers still invalidate `savedSongbookDeletionStateProvider` before presenting their existing message.
3. A delayed deletion request may be overtaken by a deletion-pending profile update without producing an uncaught framework or Riverpod exception when that request later fails.
4. In that race, the deletion-pending screen remains visible and Home remains absent.
5. Widget regressions cover both `AccountDeletionRequestUnconfirmedException` and a generic error after Home disposal.
6. The regression is demonstrated against the reviewed ordering and passes after the correction.

### Dormant merge audit privacy

7. `mergeChants` remains disabled before request parsing or mutation. No runtime merge, Functions, or rules behavior changes in this block.
8. Durable records state that the legacy merge audit detail contains source title, lyrics, context, tune, and raw `createdBy`, so it is not wholly trusted generated moderation text.
9. Any future merge re-enable must first define a privacy-safe audit payload and re-review the retained-action allowlist.
10. Unknown future audit actions continue to fail private. The existing disabled merge entry is not precedent for retaining arbitrary action detail.

### Verification and publication

11. The active contract, execution log, architectural decision, roadmap, current overview, implementation rationale, and one completed change rationale describe the corrected boundaries.
12. Focused red and green evidence precedes the complete Flutter, Functions, seed, rules, analysis, formatting, memory, style, ownership, and diff checks.
13. Exactly one correction commit contains this approved block. The owner's existing `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` changes remain unstaged and unedited. The untracked `docs/CODE_REVIEW_FREEZE_2026-08.md` remains outside the block.
14. The commit is pushed to PR 14 and all five replacement clean-runner jobs pass.
15. Native compilation, device walkthrough, Firebase access, seed writes, deployment, PR merge, signing, release, and production observation remain outside this approval.

## Threat, failure, and compatibility analysis

- A Consumer element is invalid once disposed. The mounted guard must dominate every `ref` or context-derived UI access in an async completion handler.
- The deletion protocol remains fail-closed. A pending profile still owns navigation even if an earlier client request later reports an error.
- The legacy merge audit payload is currently unreachable because the callable exits before parsing the request. Its privacy defect is therefore a re-enable gate, not a current runtime exposure.
- The report and unknown-action audit handling from the prior correction remains unchanged and fail-private.
- No deployed compatibility claim is made. This stack remains unreleased and no Firebase access or rollout is authorized.

## Rollout and rollback

1. This client-only runtime correction can roll back without a data migration while deletion-pending routing remains intact.
2. The merge documentation correction has no runtime rollback requirement. A future implementation must satisfy the recorded privacy gate instead of reverting the record.
3. No production rollout, migration, deployment, signing, native build, merge, or release is authorized by this spec.

## Delivery state

Andrew approved the `final freeze closure spec` on 2026-08-26. Implementation and local verification are complete: the focused app-gate regressions failed at both disposed-Consumer invalidations before the fix and pass afterward; 343 Flutter tests, scoped analysis, 78 Functions tests and build, 42 seed tests, seed and rules TypeScript, 136 Java-backed rules assertions, touched-file formatting, the read-only 42-of-142 formatter measurement, memory, style, ownership, and diff checks pass. One correction commit, push to PR 14, and replacement clean-runner CI remain authorized and pending. Merge, deployment, Firebase access, seed writes, native/device actions, signing, release, and production observation are not authorized.
