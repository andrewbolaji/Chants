# Change spec: V1 native build readiness

**Status:** Implemented and locally compiled; packaging, clean-runner CI, combined device walk, and final independent review pending
**Updated:** 2026-08-26
**Risk lane:** Lane 1, bounded native compilation and release-readiness evidence
**Base:** `9189c71d99c52539cb3d1b02f51701fa4334c144`, merged PR 15 on `main`, plus the locally verified post-interface correction batch
**Approval:** Andrew asked Codex to fix the complete PR 15 review batch, continue with the next sensible build work, and defer independent review until one combined pre-release engineering head.

## Outcome

- **Problem:** Flutter, Functions, rules, seed, and interface tests are green, but the current merged application has not yet been compiled across its native V1 boundary. The repository also lacks checked-in production Firebase configuration by design, and this Mac has no Android SDK.
- **Desired behavior:** Prove that the iOS simulator target compiles from the current combined source with temporary non-secret local fixtures, diagnose and correct only repository-owned native blockers, preserve an honest Android environment gate, and leave a reproducible final-review record.
- **Non-goals:** Production signing, physical-device installation, live Firebase access, seed writes, Functions or rules deployment, App Store or Play Console work, Android SDK installation, package upgrades, new product features, or visual redesign.
- **Review boundary:** Native project source and configuration needed to compile, scoped native tests, temporary ignored fixtures, generated-file cleanup, current engineering records, and the already approved correction batch. The independent review happens once at the final pre-release engineering head rather than after this block.

## Acceptance criteria and invariants

1. `flutter build ios --simulator --debug --no-pub` succeeds from the current feature head, or the exact external/repository blocker is captured with command evidence.
2. Temporary Firebase files contain placeholder values only, remain ignored, and are removed after verification.
3. A repository-owned native defect is changed only when the build reproduces it and the smallest supported correction can be verified.
4. Generated build products and dependency artifacts do not enter the tracked diff. Any incidental tracked rewrite is manually restored and audited.
5. Native Runner tests run when the available simulator/toolchain can execute them without signing or live-service access.
6. Android compilation is not claimed on this machine while the Android SDK is absent. Source-level inspection may identify risks, but installing a toolchain remains a separate user-authorized action.
7. No production key, signing credential, live Firebase operation, deployment, seed mutation, store action, or physical-device action occurs.
8. The protected owner worktree and its uncommitted platform/configuration files remain untouched.
9. The post-interface corrections remain in the same eventual final-review range and are not sent for another intermediate review.
10. The final records distinguish verified compilation, environment-blocked checks, and deferred release gates without converting any of them into inferred evidence.

## Implementation outcome

- `flutter build ios --simulator --debug --no-pub` now succeeds and produces `build/ios/iphonesimulator/Runner.app` from the combined correction head.
- The first build reproduced Flutter's automatic mixed SwiftPM migration compiling `cloud_firestore 6.4.1` against incompatible Firebase bridge APIs. The project now pins Flutter's supported project-level SwiftPM setting off and keeps the V1 graph on CocoaPods.
- `ios/Podfile.lock` now includes the native `share_plus` and `url_launcher_ios` pods already declared by the merged V1 Dart dependencies. Existing Firebase pod versions remain pinned.
- CI now fails if the project loses its CocoaPods ownership flag, loses either merged native plugin pod, or tracks generated Flutter SwiftPM state.
- The current Flutter UIScene migration is retained: `AppDelegate` registers plugins through `FlutterImplicitEngineDelegate`, `Info.plist` declares the Flutter scene, and the obsolete framework minimum-version override is removed.
- The Runner app and RunnerTests bundle both compile and validate. Two signed, single-destination RunnerTests launches were blocked before XCTest began because CoreSimulator denied or lost the app-launch service. The inherited `testExample` assertion is therefore not claimed as executed.
- Android remains environment-blocked because this Mac has no Android SDK. No SDK was installed.
- Both placeholder Firebase fixtures were ignored, contained no production secret, and were deleted after verification. `pubspec.lock` and the Xcode project file match the base; generated SwiftPM resolution files are absent.

## Design

### Local-only Firebase fixtures

The compile uses ignored placeholder `firebase_options.dart` and `GoogleService-Info.plist` files with the repository's production identifiers replaced by non-routable test values. They exist only long enough to satisfy generated imports and the Xcode resource reference. The build must not contact or mutate Firebase.

### Native evidence before native edits

The inherited iOS project uses CocoaPods. The first proof is the existing project as-is. If compilation fails, the build log determines whether the defect belongs to source, generated state, dependency resolution, or the local toolchain before any tracked file changes.

### Honest platform boundary

iOS is the executable native gate on this Mac because Xcode, CocoaPods, and iOS simulators are available. Android remains a named environment prerequisite because no Android SDK is installed; this block does not silently expand into a large toolchain installation.

## Failure analysis

| Condition | Expected behavior | Evidence |
|---|---|---|
| Ignored Firebase files are absent | Add placeholder-only fixtures for the build and remove them afterward | Ignore checks, fixture inspection, final status audit |
| CocoaPods or Swift compilation fails | Capture the exact failing target and diagnose ownership before editing | Full native build log |
| Tracked generated files change during build | Restore only the incidental generated delta and verify the intended diff remains | Before/after path and diff audit |
| Native tests require signing or live services | Stop at the authorized boundary and record the deferred gate | Exact command result |
| Android tooling is unavailable | Record the missing SDK; do not claim a build or install it implicitly | `flutter doctor` and SDK-path checks |

## Verification plan

| Claim | Check |
|---|---|
| iOS source compiles | `flutter build ios --simulator --debug --no-pub` |
| Runner native target is executable under test | Scoped `xcodebuild test` against an available iOS simulator, when supported |
| Fixtures are safe and ephemeral | Inspect placeholder content, ignore rules, and final absence |
| No unintended platform diff exists | Compare tracked native paths and lockfiles against the pre-build state |
| Existing app corrections remain sound | Re-run only the proportionate governance/diff checks after native work; full clean-runner CI belongs to packaging |
| Records are truthful | Update execution, rationale, overview, and roadmap with verified versus blocked gates |

## Rollout and recovery

- No runtime rollout occurs in this block.
- Temporary ignored files are deleted after the native evidence run.
- A bounded tracked native correction, if required, stays on this branch and is included in the eventual combined clean CI and one final Claude review.
- If the blocker is the local environment rather than the repository, record it as a release prerequisite instead of changing application code to work around it.

## Open decisions

- Installing an Android SDK is deferred unless Andrew separately authorizes that machine-level change.
- Production signing, real Firebase configuration, combined device walkthrough, seed writes, deployment, and store release remain later release gates.
