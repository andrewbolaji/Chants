# Change spec: Post-merge documentation closure

**Status:** Implemented locally; documentation-only packaging and branch CI remain pending
**Updated:** 2026-08-29
**Risk lane:** Lane 0 documentation and mechanical reconciliation
**Base:** `e8f2591740963f87623aacb82a806328cb1a98fe`, exact merged `origin/main` through PR 17
**Approval:** Andrew requested documentation closure on 2026-08-29.

## Outcome

- **Problem:** The creator, authentication, Android, and final correction stack is merged and exact-main green, but several canonical documents still describe draft PRs, pending final-head CI, an older `main`, or the pre-creator product surface.
- **Desired state:** Current milestone documents identify merged `main` `e8f2591`, exact-main run `33256843751`, the implemented creator product, and the remaining device, provider, policy, seed, deployment, signing, store, and release gates without rewriting accurate historical entries.
- **Review boundary:** `README.md`, the engineering overview, implementation rationale, interface memory, project profile, roadmap, execution ledger, the completed final-closure record, and one new documentation-closure record.
- **Non-goal:** No application, Functions, rules, Storage, seed, dependency, native project, workflow, Firebase, provider, deployment, or release behavior change.

## Required corrections

1. Replace current-state claims that PR 17, its final documentation head, Android compilation, or replacement CI remain pending.
2. Record documentation head `c1c4ea4`, PR 17 merge commit `e8f2591`, and exact-main run `33256843751` with the verified counts: 463 Flutter tests, 142 Functions tests, 42 seed tests, and 165 Java-backed Firestore and Storage cases.
3. Describe the merged Chant Stage, creator profiles, social activity, public destinations, launch authentication, and source-ready Android client in the repository entry points.
4. Preserve timestamped execution claims and prior decision context that were accurate when written.
5. Keep real-device, provider, domain association, policy, production configuration, cost controls, App Check enforcement, remaining seed, deployment, signing, store, and release work explicitly open.

## Acceptance criteria

1. Every modified path is documentation.
2. Current milestone documents agree on the exact merged-main identity and clean-runner evidence.
3. The README no longer presents the pre-creator product or obsolete test matrix as current.
4. The roadmap distinguishes source completion from launch readiness and names the real remaining gates.
5. Historical execution entries remain intact unless a current-state summary explicitly supersedes them.
6. Repository memory, writing-style, governance, native-contract, and diff checks pass for the staged documentation boundary.
7. Authored prose contains no literal or encoded em dash.

## Verification plan

- Inspect the diff by canonical document group and search current-state prose for obsolete branch, CI, native-build, and resolver claims.
- Confirm `origin/main`, PR 17, and GitHub Actions identities independently.
- Confirm the source still exports 44 Cloud Functions before updating the README count.
- Stage only the approved documentation paths.
- Run Lane 0 project-memory, writing-style, governance-regression, native-contract, authored-prose, and staged diff checks.
- Do not rerun Flutter, Functions, rules, seed, or native builds because this closure changes no executable input and exact-main run `33256843751` already supplies that evidence.

## Rollout and recovery

1. Keep the work isolated from Andrew's dirty owner checkout.
2. Package one documentation-only commit only after explicit packaging authorization.
3. Push a narrow review branch and require its configured checks before merge when authorized.
4. If a claim is disputed, retain the prior text until commit, run, source, or historical evidence resolves it.
5. Reverting this documentation-only change restores the prior records and changes no runtime state.

## Excluded authority

This approval covers the bounded documentation edits and local verification only. It does not authorize commit, push, pull-request creation, production configuration, provider or domain changes, Firebase or Storage writes, SMS sends, seed writes, deployment, signing, store actions, or release.
