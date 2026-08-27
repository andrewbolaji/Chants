# Change implementation rationale: Final freeze review closure

## Change identity and boundary

- **Change:** Close the final independent review's evidence-integrity findings without changing production behavior.
- **Base:** `e8103185657c3439116a93079a323124a7e649b8`, exact green PR 16 head reviewed by Claude.
- **Branch:** `codex/post-interface-review-corrections`.
- **Risk lane:** Lane 1.
- **Approval:** Andrew's standing instruction is to fix the logical findings as one batch and avoid repeated incremental reviews.
- **Included:** Native-contract scan semantics, targeted governance fixtures, competition/player golden ceiling, final review artifact, current execution and release truth.
- **Excluded:** Runtime behavior, Firebase, Functions, rules, seed, Android, native versions, signing, deployment, stores, devices, and production state.

## Outcome

The native regression suite now proves each boundary it claims. The SwiftPM marker fixture starts from a valid CocoaPods configuration and asserts the marker-specific error. Resolution discovery captures a successful NUL-delimited Git result before interpreting it, covers both root and nested iOS resolution paths, and treats Git failure as an error. Separate fixtures remove each required native plugin pod and assert the relevant message.

Competition and player no longer inherit an unmeasured 2.2 percent exception. Both use the shared 1.5 percent cross-renderer ceiling; Home alone keeps its measured 3 percent allowance.

## Finding disposition

| Finding | Correction | Evidence |
|---|---|---|
| M1 vacuous marker fixture | Valid flag plus marker; exact marker error required | Removing or bypassing the marker guard makes the harness fail |
| L2 fail-open resolution scan | Capture `git ls-files -z` result and branch separately on command status and file size | Fake Git wrapper forces `ls-files` exit 2 and requires the scan-error message |
| L3 root path missed | Explicit root and recursive glob pathspecs | Tracked root and nested fixtures both require the resolution-file message |
| L4 missing guard evidence | Independent root, nested, share-pod, and URL-pod fixtures | Deleting any corresponding check leaves its fixture unexpectedly green or wrong-message red |
| L5 unmeasured 2.2 percent ceiling | Competition and player use 1.5 percent | Focused local core-journey suite passes all 8 tests; clean-runner evidence pending |

## Security, privacy, data, and cost impact

- No application, server, rule, seed, query, schema, credential, or production state changes.
- The check becomes safer because repository-read failure cannot masquerade as absence.
- The additional CI fixtures use only temporary local Git repositories and make no network request.
- Test time increases only by several small shell fixtures.

## Verification performed

- PASS: `scripts/check-native-project.sh` on the real repository.
- PASS: `scripts/test-project-governance.sh` with exact-message assertions for flag, marker, root resolution, nested resolution, both pods, and Git scan failure.
- PASS: Bash syntax for both changed scripts.
- PASS: focused core-journey suite, 8 tests, with competition and player at 1.5 percent.
- PASS: full Flutter suite, 356 tests, with all visual baselines unchanged.
- PASS: touched Dart file formatter check.
- PENDING: full replacement clean-runner CI at the packaged closure head.

## Rollout, observation, and recovery

- No runtime rollout or observation is required.
- A regression appears as a project-governance job failure before merge.
- If Linux golden evidence measures benign drift above 1.5 percent, calibrate only the affected image to the smallest observed bound and record that measurement.
- The final independent review already judged the production range freeze-defensible. This closure requires clean CI, not another incremental review, unless new material behavior enters.

## Documentation impact conclusion

The active spec, final review artifact, execution, learnings, overview, rationale, roadmap, project profile, interface memory, README, and this completed rationale distinguish the evidence correction from later release operations. No ADR is required because architecture and runtime behavior do not change.
