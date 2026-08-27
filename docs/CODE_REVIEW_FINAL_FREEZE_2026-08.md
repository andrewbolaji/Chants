# Independent final freeze review: PR 16

## Review identity

- **Reviewer:** Claude Code, independently directed by Andrew
- **Mode:** Read-only; scratch probes ran outside the repository
- **Range:** `9189c71d99c52539cb3d1b02f51701fa4334c144...e8103185657c3439116a93079a323124a7e649b8`
- **Date:** 2026-08-26
- **Repository state reported by reviewer:** Clean at `e810318`
- **Disposition:** Defensible for the engineering freeze with one medium evidence fix; no high finding and no production behavior defect

## Independently verified closures

The reviewer verified that every H1, M1, M2, M3, L1, L2, and L3 finding from the PR 15 interface-readiness review is closed and that each prior regression can fail on the earlier implementation. It also independently confirmed:

- Home derives Rising from the currently rendered live community chant and recalculates after a live score change.
- Semantic trust assertions execute independently of Home's measured golden tolerance.
- The empty Terrace Proven action opens the real Premier League browse route.
- Project-memory and writing checks preserve spaced paths, use tracked index prose, and fail closed on their tested Git errors.
- The CocoaPods project pin is the smallest supported correction for the reproduced mixed SwiftPM Firestore bridge failure.
- No native package upgrade, `pubspec.lock`, generated SwiftPM state, backend, rules, seed, Android, live-service, or owner-worktree change entered the range.
- Flutter's UIScene migration matches the Flutter 3.44.8 vendor template and migrator output while the iOS 15 deployment target remains unchanged.
- Exact-head run `33025564912` passed all six jobs with zero Node 20 action-runtime warnings.
- Durable records distinguish iOS compilation, RunnerTests compile-only evidence, environment-blocked execution, and later release gates.

## Finding to close before merge

### M1: SwiftPM-marker regression was vacuous

`scripts/test-project-governance.sh` initialized the marker fixture with both `enable-swift-package-manager: true` and a tracked `FlutterGeneratedPluginSwiftPackage` marker. The native check therefore failed on the flag before reaching the marker guard. Removing the marker guard left the harness green, contradicting the claimed evidence.

Required correction: initialize the marker fixture with the valid CocoaPods flag and the marker present, and assert the marker-specific error.

## Related low findings accepted into the same batch

- The `Package.resolved` pipeline treated `git ls-files` failure like an empty result.
- The pathspec missed a root-level `ios/Package.resolved` while claiming all iOS locations.
- No regression proved the resolution-file guard or either required-pod assertion.
- Competition and player retained a 2.2 percent ceiling without a recorded measured need; the shared default is 1.5 percent.

## Watch items retained as release work

- Share and external evidence opening must be the first two native plugin assertions in the device walkthrough because runtime plugin registration remains unverified.
- Flutter 3.44.8 is the verified toolchain for the current `FlutterImplicitEngineDelegate` entry point; no lower bound has been proved or pinned.
- CocoaPods 1.17.0 is the lockfile regeneration version.
- Android compilation, signing, physical-device journeys, RunnerTests execution, live service configuration, policy, seed completion, observability controls, backups, and stores remain release operations.

## Freeze judgement

The reviewer judged the range freeze-defensible. The production diff is small and derived rather than asserted, the native blocker was reproduced before correction, scope discipline held, and no further product behavior defect was found. M1 is required before merge because claimed evidence must exercise the guard it names. The related low evidence defects are safe to close in the same bounded correction.
