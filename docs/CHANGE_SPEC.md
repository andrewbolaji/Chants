# Change spec: Final candidate freeze, native rebuild, and consolidated review

**Status:** Pull request 38 open; bounded clean-runner golden correction in progress on 2026-09-11

**Owner approval:** Andrew replied `ok next phase` after the phase was defined as freezing the exact source, rebuilding Android and iOS, running the consolidated review, resolving accepted findings, and completing exact-head verification.

**Owner:** Andrew, through ThunderRiver Tech LLC

**Lane:** 2, local release packaging, artifact verification, and review closure

**Baseline:** Repository head `b3e65636dd50e72f87685289a75b43585a206522` on `codex/android-v1-release-bundle`, with the accumulated reviewed and owner-observed release-candidate changes present across a mixed Git index and working tree. The full local Flutter suite passes 558 tests, scoped analysis reports no issues, and the launch guide, project memory, governance, writing, and whitespace checks pass. Production is separately contained at generation 35 maintenance with destructive workers false, one matching private pending-review canary draft and staged object, no active grant, and no public performance.

## Outcomes

1. Capture the proposed football-thoughts timeline as a post-V1 product direction without changing V1 behavior, architecture, store positioning, or release scope.
2. Turn the accumulated local candidate into one exact staged handoff without losing, rewriting, or silently omitting existing owner changes.
3. Rebuild Android and iOS from that exact source boundary, then bind each artifact to source, version, identity, signing state, and a SHA-256 receipt.
4. Run one consolidated review of the direct tree difference from Claude-reviewed PR 37 pre-correction tree `5a95c93d0749796af65dc6c9a43707944dc66855` through the frozen candidate.
5. Resolve accepted in-scope findings, rerun the complete local verification matrix, and leave the reviewed candidate ready for an explicitly authorized commit, push, and clean-runner CI gate.

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

## Excluded

- Commit, push, pull request, merge, tag, GitHub Actions dispatch, or remote branch mutation without a further explicit owner instruction.
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
10. The resulting staged candidate is ready for a separately explicit commit and push instruction. Clean-runner exact-head CI remains pending until such a remote boundary exists.

## Recovery

Before staging, preserve the current mixed index and working-tree inventory. If staging reveals an omitted or unrelated path, stop and repair the index without discarding its working-tree content. Never use a destructive reset or checkout to force cleanliness.

Before each native build, record the tracked platform diff. If Flutter, Xcode, CocoaPods, Gradle, or another tool changes tracked scaffolding or lock state, inspect the exact change. Retain it only when already authorized and necessary; otherwise reverse it with a bounded patch that preserves all unrelated work. Generated build outputs remain ignored.

If signing identity, provisioning, Firebase client identity, package identity, or version is ambiguous, stop that platform build and record the blocker. Do not generate replacement keys, profiles, registrations, identifiers, or versions in this phase.

If the reviewer cannot run or reaches a usage or environment limit, preserve the exact frozen handoff and reviewer brief. Do not substitute self-review for the required independent result. If a finding expands scope, leave it unresolved with its evidence and request a new decision.

## Next gate

After the staged candidate, rebuilt artifacts, consolidated review, accepted-finding closure, and local verification are complete, Andrew may separately authorize the exact commit and push needed for clean-runner CI. Store upload and submission remain later, separately approved gates.

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
