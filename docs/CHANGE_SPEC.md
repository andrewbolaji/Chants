# Change spec: Final candidate freeze, native rebuild, and consolidated review

**Status:** Approved; pull request 38 is extended on 2026-09-11 with a bounded first-run orientation before merge consideration

**Owner approval:** Andrew replied `ok next phase` after the phase was defined as freezing the exact source, rebuilding Android and iOS, running the consolidated review, resolving accepted findings, and completing exact-head verification.

**Extension approval:** After exact-head pull-request CI passed, Andrew asked for a light, logical, beautiful, skippable V1 onboarding that can jump directly to account creation and approved adding it to pull request 38 before merge.

**Owner:** Andrew, through ThunderRiver Tech LLC

**Lane:** 2, local release packaging, artifact verification, and review closure

**Baseline:** Repository head `b3e65636dd50e72f87685289a75b43585a206522` on `codex/android-v1-release-bundle`, with the accumulated reviewed and owner-observed release-candidate changes present across a mixed Git index and working tree. The full local Flutter suite passes 558 tests, scoped analysis reports no issues, and the launch guide, project memory, governance, writing, and whitespace checks pass. Production is separately contained at generation 35 maintenance with destructive workers false, one matching private pending-review canary draft and staged object, no active grant, and no public performance.

## Outcomes

1. Capture the proposed football-thoughts timeline as a post-V1 product direction without changing V1 behavior, architecture, store positioning, or release scope.
2. Turn the accumulated local candidate into one exact staged handoff without losing, rewriting, or silently omitting existing owner changes.
3. Rebuild Android and iOS from that exact source boundary, then bind each artifact to source, version, identity, signing state, and a SHA-256 receipt.
4. Run one consolidated review of the direct tree difference from Claude-reviewed PR 37 pre-correction tree `5a95c93d0749796af65dc6c9a43707944dc66855` through the frozen candidate.
5. Resolve accepted in-scope findings, rerun the complete local verification matrix, and leave the reviewed candidate ready for an explicitly authorized commit, push, and clean-runner CI gate.
6. Add one device-local first-run orientation that teaches only Songbook, Chant Lab, and Stage, can be skipped from every step, links directly to account creation, and never changes authentication or account authority.

## Included

1. Add the post-V1 supporter-timeline concept to `docs/ROADMAP.md` with a smallest exploratory slice, chant-first differentiation, safety and operational boundaries, success signals, and a revisit trigger.
2. Inventory every staged, unstaged, and untracked nonignored path. Inspect the complete diff, generated assets, executable source, platform declarations, store evidence, tests, and durable records. Scan the intended handoff for secrets and private production artifacts without printing their contents.
3. Preserve the current ignored Firebase client configuration and signing material. Validate project, bundle, and package identity through bounded checks that do not expose keys, passwords, device identifiers, or credentials.
4. Stage only the intended tracked and new repository paths. Keep `.private-report-repair`, Firebase client configuration, signing keys, key properties, build outputs, logs, credentials, and other ignored local state outside the handoff.
5. Run staged project-memory, writing-style, governance, whitespace, source-contract, Flutter, Functions, seed, Firestore and Storage rules, and native-project checks in proportion to the complete review range.
6. Build fresh Android release APK and AAB artifacts from the staged-equivalent tree. Inspect package, version, merged permissions, signatures, certificate continuity, size, and SHA-256.
7. Build a fresh iOS release archive from the same source. Use the existing approved Chants bundle and local distribution setup if it is available and coherent. Inspect bundle, version, team, entitlements, signing state, embedded provisioning, size, and SHA-256. Record an unsigned or environment-blocked result honestly rather than weakening signing or changing native ownership.
8. Snapshot tracked native state before each build and inspect it afterward. Treat tool-driven native changes as outputs requiring review, not as automatically accepted migration.
9. Give the consolidated reviewer the exact base, candidate boundary, included subsystems, known older-installed-build distinction, production exclusions, and verification commands. Record findings by severity with evidence and disposition.
10. Correct only reproduced, accepted findings that remain within this phase. A finding that requires a new product decision, production mutation, dependency migration, or materially broader architecture stops for a new approval.
11. Update `docs/EXECUTION.md`, `docs/INTERFACE.md`, `docs/ROADMAP.md`, the command center, the completed-change rationale, and the repository rationale only where the frozen candidate makes their current-state statements stale.
12. Show the orientation only to a signed-out installation that has not completed or skipped its versioned V1 guide. Keep the existing sign-in welcome as the destination after Skip or Continue, and keep the verified-account profile setup as a separate required gate.
13. Persist completion locally with a versioned, nonidentifying flag. If that local read fails, fail open to sign-in. If the completion write fails, let the current session continue so orientation storage cannot trap a supporter.
14. Keep Skip, Next, Continue to Sign In, and Create Account written and reachable. Give each step a semantic heading, position announcement, concise product truth, and a layout that scrolls safely at narrow widths and enlarged text.

## Excluded

- Merge, tag, GitHub Actions dispatch, a new pull request, or remote mutation beyond the focused orientation extension to the existing pull request 38 branch without a further explicit owner instruction. Andrew's extension request authorizes the focused commit and push needed to put this work into pull request 38, but it does not authorize merge.
- Store upload, TestFlight upload, Play upload, store submission, store review request, managed publishing change, or public release.
- Production mode, worker, IAM, rule, Function, Hosting, DNS, App Check, provider, data, canary, moderation, publication, playback, deletion, or object change.
- Another performance upload or reuse, review, preview, download, moderation, publication, or deletion of the private canary.
- Dependency upgrades, CocoaPods-to-SwiftPM migration, Gradle migration, identifier change, version or build-number change, new permission, signing-material change, or new native capability unless a reproduced release blocker receives separate approval.
- Implementation of the supporter timeline, text posts, reposts, ranking, new feed schemas, new social graph behavior, or related moderation systems.
- Rewriting unrelated user work, deleting ignored local state, bulk formatting, or normalizing goldens without a reproduced visual reason.

## Acceptance criteria

1. One inventory accounts for every nonignored changed path. No private credential, Firebase client file, signing file, operational plan, raw production payload, or build output enters the staged handoff.
2. The intended handoff is staged and `git diff --cached --check`, staged project memory, writing style, and governance checks pass. There is no unintended unstaged source or documentation drift at the freeze boundary.
3. The complete Flutter suite and scoped analysis pass from the frozen tree. Every touched source-contract suite passes, and representative changed goldens are inspected.
4. Functions build and unit tests, seed tests and typecheck, Firestore and Storage rules tests, the real Firestore transaction suite, native-project checks, launch-service checks, store-packet checks, public-site checks, and guide checks pass or carry a precise environment blocker.
5. Fresh Android APK and AAB receipts name the exact source boundary, package, version, signing certificate, signature state, size, and SHA-256. The merged release manifest contains no rejected advertising or ad-services permissions.
6. A fresh iOS archive receipt names the exact source boundary, bundle, version, team, entitlements, signing state, size, and SHA-256. It uses the project-owned CocoaPods graph and introduces no unreviewed SwiftPM state.
7. The consolidated review covers the entire direct range from `5a95c93d0749796af65dc6c9a43707944dc66855`, distinguishes older installed-device evidence from rebuilt artifacts, and reports no unresolved high or medium finding before handoff.
8. Every accepted finding has a reproduced boundary, focused regression where behavior changed, recorded correction, and replacement verification.
9. Production remains generation 35 maintenance with destructive workers false by prior receipt. This phase performs no production read or write merely to refresh elapsed-time evidence.
10. The resulting staged candidate is committed and pushed only as the focused orientation extension Andrew requested for pull request 38. Clean-runner exact-head CI passes before merge consideration. Merge remains a separate explicit gate.
11. A fresh signed-out installation reaches the three-step orientation after the launch reveal. Skip works from every step, Create Account reaches the existing signup route, Continue reaches the existing sign-in welcome, and all three exits mark the V1 guide complete for later launches.
12. Signed-in users, verified-account profile onboarding, policy admission, deletion recovery, provider configuration, and server authority remain unchanged. Local preference read or write failure cannot block sign-in.
13. Focused tests cover first install, repeat launch, every exit, storage failure, reduced motion, semantics, 390 by 844 presentation, 320-pixel width, and enlarged text. The full Flutter suite and exact-head CI pass after the extension.

## Recovery

Before staging, preserve the current mixed index and working-tree inventory. If staging reveals an omitted or unrelated path, stop and repair the index without discarding its working-tree content. Never use a destructive reset or checkout to force cleanliness.

Before each native build, record the tracked platform diff. If Flutter, Xcode, CocoaPods, Gradle, or another tool changes tracked scaffolding or lock state, inspect the exact change. Retain it only when already authorized and necessary; otherwise reverse it with a bounded patch that preserves all unrelated work. Generated build outputs remain ignored.

If signing identity, provisioning, Firebase client identity, package identity, or version is ambiguous, stop that platform build and record the blocker. Do not generate replacement keys, profiles, registrations, identifiers, or versions in this phase.

If the reviewer cannot run or reaches a usage or environment limit, preserve the exact frozen handoff and reviewer brief. Do not substitute self-review for the required independent result. If a finding expands scope, leave it unresolved with its evidence and request a new decision.

## Next gate

After the staged orientation extension, rebuilt artifacts, and local verification are complete, use Andrew's pull request 38 extension authority for one focused commit and push, then require exact-head clean-runner CI. A rebuilt-phone presentation check and a separate explicit merge instruction remain before merge. Store upload and submission remain later, separately approved gates.

## Completion receipt

- Claude Code independently reviewed the complete direct range from `5a95c93d0749796af65dc6c9a43707944dc66855` through the frozen staged candidate at head `b3e65636dd50e72f87685289a75b43585a206522` and reported two P1, two P2, and four P3 findings.
- All eight findings were accepted, reproduced, corrected within this Lane 2 boundary, and covered by replacement regressions. The correction record is `docs/changes/2026-09-11-final-candidate-independent-review-corrections.md`.
- The corrected focused Flutter set passes 43 tests, the complete Flutter suite passes 563 tests, scoped analysis reports no issue, Functions and seed checks pass, and the Java-backed rules and transaction suites pass 174 and 24 cases respectively.
- Fresh corrected Android AAB and APK artifacts and an App Store-signed iOS archive and IPA were rebuilt and inspected. Their final hashes and signing receipts are recorded in `docs/EXECUTION.md` and the command center.
- Project memory, writing, governance, native-project, store-packet, launch-service, public-site, guide, source-contract, staged whitespace, and bounded staged credential-value checks pass at final staging.
- No production, canary, provider, Hosting, DNS, store, release, commit, push, merge, or signing-material mutation occurred in this correction and packaging phase.
- Andrew later authorized the exact staged commit and push, then separately authorized opening the release-candidate pull request into `main`. Commit `f2e405f92f5ac0592e5c5c959f3b1a9d68e4aea7` is the initial head of pull request 38.
- The first pull-request clean runner passed every completed non-Flutter job and all 559 nonfailing Flutter cases. It found five Linux screenshot differences between 1.54 and 1.89 percent, all confined to glyph, icon, and border-edge antialiasing after retained artifact inspection. The bounded correction adds Linux-only references from that exact runner and does not raise the shared 1.5 percent tolerance. The focused 20-test set, complete 564-test Flutter suite, and scoped analysis pass locally. Replacement exact-head CI is required.
- The first replacement run proved that Flutter widget-test target selection does not identify the Linux host. It repeated the same five parent-reference differences with identical percentages and pixel counts while every other completed job passed. The helper now uses the actual host operating system with an injectable regression seam. Another replacement exact-head run is required.
- Commit `3f26e66239c1c12237b26127e7decafe6baa85ee` passed all eight jobs in exact-head GitHub Actions run `34598537127`, including 564 Flutter tests, scoped analysis, project governance, Functions, seed, Firestore and Storage rules, Android debug build, and iOS simulator build under pinned Flutter 3.47.3.
- Andrew supplied a final exact-head Claude Code review. Its one P2, two P3, and two P4 findings were reproduced and accepted: duplicate Storage progress-stream errors, a disposed player-field callback, unpinned CI Flutter, dead modal semantics, and UTF-16 lyric counting.
- The corrections deliberately consume observational progress-stream errors while the upload completion future remains authoritative, remove the stale field callback, count user-perceived lyric characters, pin all CI jobs to Flutter 3.47.3, and remove the dead semantics label. Focused coverage passes 32 tests, the complete Flutter suite passes 567 tests, and scoped analysis reports no issue.
- The previous signed Android and iOS receipts remain valid only for their recorded source boundary. Fresh corrected candidates replace them: Android AAB SHA-256 `ac60bb412d2c668e61410d03f3dd69a4bffff7126ce44df6ffe83fdb6717b4c6`, Android APK SHA-256 `291a062dbe11ef070d0e220947a3d404bd648811572e7079cdaf72bc34b641b7`, iOS archive content-tree SHA-256 `ccb5b26b69fac3c9a36a372210a1a0b03c450ae959b3bdb06110917671adf074`, and iOS IPA SHA-256 `8e645f704685754e8dc547d447efd9082f0d7a54e60a8101ce01978751a9408e`. Replacement exact-head CI remains required before merge consideration.
- The first-run orientation extension passes 45 focused repository, interaction, gate, failure, timeout, reduced-motion, semantics, responsive, and golden tests. All three 390 by 844 references were inspected. The complete Flutter suite passes 588 tests and scoped analysis reports no issue.
- Fresh orientation-source Android artifacts replace the prior Android receipts: AAB 65,358,385 bytes, SHA-256 `97d28f20e1862ea27e71fb5bdcd6bf63861b6d2c8e2e055401e71dca0bc07fc3`; APK 64,078,519 bytes, SHA-256 `83f49ef7c6f8eb5f7062791cd0e222512263884b07fc56022dfe69bdb1f2c700`. Identity, version, SDK, architecture, merged permissions, AAB JAR signature, APK v2 signature, and upload-certificate continuity pass.
- Fresh orientation-source iOS artifacts replace the prior iOS receipts: archive 537,710,592 allocated bytes with content-tree SHA-256 `9181dc16e379716053e3d7fb695e111d59e44e9ab29845471231846c037ab7d7`; IPA 51,686,765 bytes with SHA-256 `7c2e1dc8311f7c1061956d21992bbeac18784c3a5f4dd53ddc38f1c1b144b483`. ZIP integrity and strict deep-signature verification pass with the approved Apple Distribution identity, team, profile, and entitlements. Temporary verification files and keychain were removed.
