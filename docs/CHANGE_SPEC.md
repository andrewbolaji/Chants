# Change spec: Final source-freeze minor closure

**Status:** Implemented, locally verified, and staged; commit, exact-head CI, and merge pending
**Updated:** 2026-08-29
**Risk lane:** Lane 2 because the bounded interface correction sits inside authentication onboarding
**Base:** `5350b8ae0d41665db7a41e00117b50e73c062b4e`, combined PR 17 and PR 18 head
**Review source:** Final independent read-only review of `86603c22fbd7647f89c9276af9a60a0b3d63113b...5350b8ae0d41665db7a41e00117b50e73c062b4e`
**Approval:** Andrew explicitly requested the two minor fixes, replacement CI, and merge on 2026-08-29.

## Outcome

- **Problem:** A successful onboarding request restores the whole form even though a duplicate server request preserves the existing profile. A user can therefore edit the display name, retry, and receive success copy even though the edit is intentionally ignored. Current engineering records also describe the already packaged and green post-auth correction as local or pending.
- **Desired behavior:** After setup succeeds while profile projection is delayed, retry and Sign Out remain available, saved fields are visibly immutable, and copy describes a projection check rather than another editable submission. Durable records state the exact reviewed and clean-runner evidence while preserving real device, provider, deployment, policy, seed, and release gates.
- **Review boundary:** Onboarding presentation, its production widget regression, current engineering truth, interface memory, roadmap, project profile, execution evidence, and one scoped completion record.
- **Non-goal:** No callable, profile schema, Firebase rule, provider, native project, CI workflow, deployment, seed, or release behavior changes.

## Approved corrections

### N1: Truthful post-success onboarding

1. A successful `completeOnboarding` response records that the form values are already saved.
2. Display name, birth date, policy acceptance, and first-destination controls become read-only after that response.
3. Retry remains available under a truthful `CHECK AGAIN` label and reuses the unchanged saved payload.
4. Sign Out remains available.
5. Failed first attempts remain fully editable and retryable.
6. A late completion still checks widget lifetime before reading or mutating presentation state.

### N2: Exact engineering evidence

1. Replace claims that the nine-finding correction is local, unpackaged, or awaiting replacement CI.
2. Record correction commit `600272413a3350db54528b2ad6b757d07d646a96`, PR 18 merge commit `5350b8ae0d41665db7a41e00117b50e73c062b4e`, run `33213537910` at the correction head, and run `33215692105` at the byte-identical combined head.
3. Record 463 Flutter tests, 142 Functions tests, 42 seed tests, and 165 Java-backed Firestore and Storage assertions without inflating a test case into multiple new cases.
4. Keep the combined device walk and every provider, association, policy, signing, deployment, cost, seed, and release gate explicitly open.

## Acceptance criteria and invariants

1. The production onboarding widget regression inspects the display name after server success and proves the field retains the submitted value and is disabled.
2. The same regression proves `CHECK AGAIN` and Sign Out remain enabled.
3. A second retry sends the original saved display name and remains idempotent.
4. Existing validation, under-age handling, first-submit destination selection, and failure recovery remain unchanged.
5. Repository-authored current milestone documents contain no stale claim that the post-auth correction still needs packaging or replacement CI.
6. Documentation distinguishes source freeze from device, provider, deployment, and release readiness.
7. Focused onboarding tests, the full Flutter suite, scoped analysis, unchanged backend suites, governance, writing, native contract, and diff checks pass locally where the toolchain exists.
8. All eight exact-head CI jobs pass after the implementation closure commit is pushed to PR 17.
9. One documentation-only evidence commit records that run and the merge-ready state, then all eight jobs pass again at the final head.
10. PR 17 merges into `main` only after its reviewed head and final CI head are identical and every required job is green.

## Failure and recovery analysis

| Condition | Required behavior | Evidence |
|---|---|---|
| Profile stream stalls after successful setup | Saved values are frozen; Check Again and Sign Out remain available | Production widget regression |
| User tries to edit the saved name | The disabled field retains the server-submitted value | Production widget regression |
| User checks again | The original saved payload is reused and no edit is implied | Repository call capture in the widget regression |
| First request fails | Form controls restore and retained values remain editable | Existing onboarding recovery coverage |
| Documentation is read after CI | Exact commit, run, counts, and remaining gates agree across current records | Bounded search plus changed-line review |
| Replacement CI fails | Do not merge; diagnose and correct or report the exact blocker | GitHub Actions job evidence |

## Verification plan

- Extend the existing production onboarding widget test around the known post-success state.
- Run the focused onboarding test file, then the complete Flutter suite and scoped analysis.
- Run Functions and seed tests because the final merge range includes those systems even though this closure does not change them.
- Run rules TypeScript plus Java-backed rules in CI, project memory, writing style, native contract, governance regressions, formatting, and diff checks.
- Inspect the staged diff and generated native artifacts through the existing eight-job workflow.
- Verify the PR head and CI head before merge, then verify the resulting `main` merge commit and clean PR state.

## Rollout and recovery

1. Package one cohesive implementation closure commit on PR 17.
2. Push only that branch and require replacement exact-head CI.
3. If the run is green, record its identity and merge-ready state in one documentation-only evidence commit.
4. Require all eight jobs again at that final documentation head, then merge PR 17 into `main` only when every job succeeds.
5. If the onboarding copy or frozen-state behavior regresses, revert the implementation closure commit without changing stored data or server authority.
6. No production deployment follows from this merge.

## Excluded authority

This approval includes the bounded source and documentation edits, local checks, one commit, push to PR 17, replacement CI, and merge into `main` when green. It does not authorize provider-console changes, Firebase or Storage writes, SMS sends, credentials, association deployment, signing, store actions, seed writes, application deployment, or public release.
