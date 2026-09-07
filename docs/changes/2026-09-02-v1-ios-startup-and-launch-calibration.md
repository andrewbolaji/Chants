# Change rationale: V1 iOS startup and launch calibration

## Identity and authority

- **Date:** 2026-09-02. **Owner:** Andrew. **Author:** Codex.
- **Baseline:** Exact `main` at `88ce483f1ea18df6a7a2b4e790803773164ac9a5` inside the approved Lane 3 rollout checkout.
- **Authority:** Andrew approved `V1 iOS 26 ProMotion explicit-engine startup correction spec`, then directly requested bounded presentation calibration after observing the corrected client. No production, backend, data, deployment, store, or release authority is included.

## Problem and correction

Three paired-iPhone reports proved the same pre-Dart null-task-runner crash in Flutter's iOS 26 ProMotion implicit-engine startup path. The correction creates and runs one explicit Flutter engine before the scene constructs its engine-backed view controller, registers plugins once, and preserves application and scene lifecycle forwarding.

The corrected client launched reliably on the paired phone. The owner then observed that the one-shot brand reveal disappeared too quickly and that the policy gate placed too many secondary choices and repeated explanations beside the consent task. The final calibration holds the cold-launch reveal for 2.8 seconds, still resolves immediately for reduced motion, and never delays resume. The policy gate now contains one restrained introduction, two accepted-document rows, a compact separate Privacy route, and one Other options disclosure for Help, Support, Delete account, and Sign out. The long Community Rules stay on their document route instead of being repeated below the consent action.

## Why the secondary actions remain

Privacy is not part of the accepted contract, so its separate route remains explicit without occupying a full card. Help, Support, Delete account, and Sign out remain available before consent so a person is not trapped into agreeing to leave, get assistance, or close the account. One labeled disclosure keeps that authority while reducing visual competition.

## Evidence and remaining gates

- Source contracts reject a return to the implicit storyboard/controller path.
- Debug, Profile, and Release iOS builds compiled during the correction work.
- The paired ProMotion iPhone completed repeated no-debug cold launches, force quit and relaunch, background and resume, and policy interaction without the prior crash.
- While production remained at maintenance generation 9, acceptance showed visible saving progress and then the truthful result `Chants is temporarily paused. Try again later. Nothing was changed.`
- Focused app-gate, policy, and golden verification passes after the final hierarchy change. The first independent review confirmed the engine, lifecycle, deep-link, route, and containment boundaries, then found one bounded policy-recovery defect plus documentation and source-contract corrections. The approved correction ends both successful and stalled acceptance waits, preserves Help and Support during saving, distinguishes failure classes, proves app-level reduced motion, strengthens the iOS source contract, and excludes the obsolete Main storyboard from packaged resources.
- The independent closure review found no blocking or correction-required defect. Its four low findings are closed: verified-contact failure copy is accurate, every mapped error class has a direct test, an already-open Other options sheet reacts when acceptance finishes, and the superseded source-contract count has a dated correction in `docs/EXECUTION.md`.
- The corrected complete local matrix passes 537 Flutter, 230 Functions, and 74 seed tests; scoped Flutter analysis; 37 launch-source contracts; 11 iOS startup contracts; launch-services contracts; project governance; native-project, memory, and writing-style checks; and whitespace validation. A replacement signed iOS Profile build produced a 75.0 MB device app from the final corrected project. The final 2.8-second owner presentation check and both independent reviews are complete. Closure commit `ac8c65a` was pushed in PR 33. Initial exact-head run `33709206783` measured 2.05 percent cross-platform font-edge drift with identical policy-screen geometry. The golden now carries a test-local 2.2 percent allowance, backed by separate semantic widget assertions. Replacement exact-head clean-runner CI remains open.
- Production stays schema version 1, generation 9, mode `maintenance`, with destructive workers false. Gate 4 is not next.
