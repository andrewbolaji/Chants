# Change implementation rationale: V1 native build readiness

## Change identity and boundary

- **Change:** Close the repository-owned iOS compilation blocker after the post-interface corrections.
- **Base:** `9189c71d99c52539cb3d1b02f51701fa4334c144`, exact merged PR 15 head, plus the locally verified correction batch.
- **Branch:** `codex/post-interface-review-corrections`.
- **Risk lane:** Lane 1.
- **Approval:** Andrew directed Codex to fix the complete review batch, continue the next sensible engineering work, and wait for one combined final Claude review.
- **Included:** iOS simulator compilation, dependency-manager ownership, native lock representation for merged plugins, current Flutter UIScene migration, scoped RunnerTests build and launch evidence, generated-state cleanup, Android environment check, and durable records.
- **Excluded:** Real Firebase access, production credentials, signing for distribution, Android SDK installation, physical devices, live seed work, deployment, stores, and production observation.

## Outcome

The combined app now compiles for an iOS simulator. The first native run reproduced the inherited Cloud Firestore failure rather than merely carrying it forward: Flutter 3.44.8 automatically introduced a mixed Swift Package Manager graph, resolved a newer Firebase iOS SDK beside the CocoaPods graph, and compiled `cloud_firestore 6.4.1` against Objective-C bridge initializers that did not exist in that resolution.

The smallest supported correction is project ownership of the dependency manager. `pubspec.yaml` sets `flutter.config.enable-swift-package-manager: false`, so global Flutter defaults cannot silently convert this V1 project. CocoaPods then compiles the existing pinned Firebase graph. `ios/Podfile.lock` adds only the missing native representations of the already-merged `share_plus` and `url_launcher_ios` plugins and the local CocoaPods metadata version.

The Flutter tool also applied its current UIScene migration. The migration is retained because it is independent of SwiftPM, current Flutter regenerated it after cleanup, and the successfully compiled target verifies the resulting AppDelegate and plist boundary.

## Failure and correction evidence

| Boundary | Before | After |
|---|---|---|
| Dependency manager | Automatic mixed SwiftPM/CocoaPods graph | Project-pinned CocoaPods graph |
| Cloud Firestore bridge | Missing `initWithRef:firestore:` and `initWithCollectionId:` while compiling SwiftPM plugin sources | Full simulator app compiles |
| Native share dependencies | Dart packages existed, but Podfile lock omitted their iOS pods | `share_plus` and `url_launcher_ios` present and linked |
| Generated project state | SwiftPM package references and resolution files appeared during the failed build | No SwiftPM project marker or `Package.resolved`; Xcode project restored |
| RunnerTests | Test host had not been compiled in the current native graph | App and RunnerTests bundle compile and validate; simulator launcher fails before XCTest starts |
| Android | No SDK configured | Still explicitly environment-blocked; no toolchain mutation |

## Implementation choices

### Own the dependency manager per project

Changing Firebase or FlutterFire versions would turn a reproduced integration-mode defect into a broad dependency upgrade. The Flutter project configuration is the narrower supported control and preserves the repository's pinned CocoaPods dependency family.

### Keep the current UIScene migration

Reverting UIScene would cause the current Flutter tool to migrate the project again and would retain an obsolete launch lifecycle. Keeping the generated template change makes the native entry point explicit and was verified by the successful simulator compile.

### Distinguish compile evidence from launch evidence

`flutter build ios --simulator --debug --no-pub` completed successfully. Xcode also compiled, signed for local simulator execution, embedded, and validated Runner plus RunnerTests. CoreSimulator then failed before either Runner or XCTest spawned, first with a dead simulator service and then with a launch request denied by `SBMainWorkspace`. The placeholder `testExample` is therefore recorded as launch-blocked, not passed or failed.

## Security, privacy, data, and cost impact

- Placeholder Firebase files used non-production values, were ignored, and were removed.
- No Firebase request, seed read or write, deployment, signing credential, or production secret was used.
- No application data model, authorization rule, Function, or query changed.
- The change prevents an ambient Flutter setting from changing the repository's iOS dependency graph.
- The native compile was a cold local build of Firebase and gRPC and took roughly 34 minutes. Keeping derived artifacts makes later walkthrough builds materially faster.

## Verification performed

- PASS: `flutter build ios --simulator --debug --no-pub`; produced `Runner.app` after the CocoaPods correction.
- PASS: Xcode compiled, embedded, locally signed, and validated the Runner and RunnerTests bundles on the CocoaPods graph.
- BLOCKED: RunnerTests execution. Two fresh single-simulator launch attempts stopped before XCTest at CoreSimulator service or workspace-launch denial. No assertion ran.
- BLOCKED: Android compilation because no Android SDK is configured.
- PASS: `pubspec.lock` and `ios/Runner.xcodeproj/project.pbxproj` match the base.
- PASS: placeholder Firebase files and SwiftPM resolution files are absent.
- PASS: existing Firebase pod pins were preserved; only merged native share and URL-launcher plugin pods were added.
- PASS: the native-project check and its clean, missing-flag, and tracked-SwiftPM regression fixtures enforce the dependency-manager boundary in CI.
- PASS: PR 16 run `33025135738` passed all six jobs at implementation head `41d23b5`, including the new native contract.
- PASS: PR 16 run `33025564912` passed all six jobs at exact reviewed head `e810318` after moving GitHub checkout, Node setup, and Java setup to their official v5 Node 24 majors. The run emitted no Node 20 action-runtime warning.
- PENDING: replacement CI for the later evidence-only final-review closure.

## Rollout, recovery, and remaining gates

- No runtime rollout occurs from this local block.
- Reverting the project-level Flutter config would allow ambient SwiftPM migration to reproduce the Firestore bridge failure.
- Production Firebase configuration, distribution signing, Android compilation, the combined physical-device walkthrough, seed completion, deployment, and store work remain explicit later gates.
- This block stays in the same final review range as the post-interface corrections. No intermediate Claude review is requested.

## Documentation impact conclusion

The active spec, execution log, learnings, overview, rationale, roadmap, profile, and README are refreshed because native compilation truth changed. No ADR is required while CocoaPods remains the existing architecture; migrating to SwiftPM later would be a new reviewed dependency-manager decision.
