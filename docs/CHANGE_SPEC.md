# Change spec: Final freeze independent-review closure

**Status:** Approved, implemented, and locally verified; packaging and replacement CI pending
**Updated:** 2026-08-27
**Risk lane:** Lane 1, evidence integrity and deterministic test hardening
**Base:** `e8103185657c3439116a93079a323124a7e649b8`, draft PR 16 exact green head
**Approval:** Andrew directed Codex to fix the material Claude findings in one coherent batch and use one final combined review rather than repeated incremental reviews.

## Outcome

- **Problem:** The final independent review judged the production range freeze-defensible but found that the native SwiftPM-marker regression failed first on an invalid project flag, so it never proved the marker guard. The adjacent resolution-file scan could fail open, missed a root-level `ios/Package.resolved`, and lacked resolution and pod-removal regressions. Two goldens retained an unmeasured 2.2 percent exception, and closure records still called exact-head CI pending after it passed.
- **Desired behavior:** Every native-contract regression must fail at the intended boundary with the intended message; Git scan failures must fail closed; root and nested SwiftPM resolutions plus both required pods must be proved; unmeasured competition and player goldens must use the shared 1.5 percent ceiling if local and clean-runner evidence stays green; durable truth must name the final review and exact-head CI accurately.
- **Non-goals:** Product behavior, routes, Firebase, Functions, rules, seed, Android, native dependency versions, signing, deployment, stores, physical devices, or production state.

## Acceptance criteria and invariants

1. The SwiftPM-marker fixture uses the valid CocoaPods flag and asserts the marker-specific failure message.
2. `Package.resolved` discovery captures both `ios/Package.resolved` and nested iOS paths through an explicit NUL-delimited Git result file.
3. A Git `ls-files` failure is distinguished from an empty result and stops the native contract.
4. Separate regressions prove root resolution, nested resolution, missing `share_plus`, and missing `url_launcher_ios` are each rejected at their intended boundary.
5. The governance harness still passes its memory, writing, flag, marker, resolution, pod, and Git-error cases.
6. Competition and player use the shared 1.5 percent golden ceiling only if the focused local suite and clean Linux runner pass without calibration.
7. Records retain the independent review's positive freeze judgement, its one medium and related low findings, the exact PR 16 CI evidence, and the device-walk priority for Share and external evidence links.
8. The project profile says Flutter 3.44.8 is the verified native toolchain and does not invent an unverified lower bound.
9. No runtime, server, data, seed, live-service, signing, deployment, store, or owner-worktree change occurs.

## Design

### Prove the intended failure

Negative fixtures assert both a nonzero exit and the exact contract message. A fixture that is invalid for an earlier reason cannot satisfy evidence for a later guard.

### Capture Git output before interpreting it

The resolution scan writes NUL-delimited `git ls-files` output to a temporary file. Command failure is handled separately from a nonempty successful result, so the check cannot treat repository errors as absence.

### Use measured visual exceptions only

Home retains its measured 3 percent cross-renderer allowance. Competition and player had no measured clean-runner drift, so they return to the comparator's shared 1.5 percent ceiling. A new exception requires an observed renderer difference and a narrowly documented bound.

## Verification plan

| Claim | Check |
|---|---|
| Native guard behavior | `./scripts/check-native-project.sh` |
| Every negative fixture reaches its intended boundary | `./scripts/test-project-governance.sh` with exact stderr assertions |
| Visual ceiling is viable | Focused core-journey suite locally, then full clean-runner Flutter suite |
| Shell and prose quality | Bash syntax, staged memory check, staged writing check, `git diff --check` |
| Scope containment | Final diff against `e810318`; protected owner-worktree status audit |

## Rollout and recovery

- No runtime rollout occurs. The change affects only deterministic checks, golden evidence, and durable records.
- If clean Linux rendering exceeds 1.5 percent, use the measured difference to set the smallest image-specific exception; do not raise an unrelated baseline.
- After replacement exact-head CI passes, PR 16 may leave draft for owner merge without another incremental Claude review unless a new material defect appears.

## Remaining release gates

Android SDK provisioning and compilation, distribution signing, combined iPhone/iPad/Android walkthrough, Share and evidence-link launch assertions, airplane-mode Songbook relaunch, RunnerTests on a working simulator, live App Check and operational configuration, policy wording, live stable-ID preflight, remaining club seed, and store release remain outside source freeze closure.
