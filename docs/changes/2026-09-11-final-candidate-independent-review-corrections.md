# Final candidate independent-review corrections

## Outcome

The complete staged release-candidate range received the planned independent Claude Code review. All eight findings were accepted, reproduced, corrected within the approved Lane 2 boundary, and covered by replacement local evidence. Fresh corrected native artifacts are verified. The candidate is ready for the separately authorized commit, push, and clean-runner CI gate.

## Authority and boundary

- Andrew supplied the completed review report and said to continue after Codex had defined the correction and final-handoff phase.
- The reviewer covered the direct range from Claude-reviewed PR 37 pre-correction tree `5a95c93d0749796af65dc6c9a43707944dc66855` through the 91-path staged candidate at repository head `b3e65636dd50e72f87685289a75b43585a206522`.
- The review was read only. This correction phase did not open or read production, change workers or generation, touch the private pending-review canary, deploy, publish, upload to a store, request review, release, commit, push, or merge.
- Production remains generation 35 maintenance with destructive workers false by the prior recorded receipt. One pending-review canary draft and matching staged object remain private, with no active grant or public performance.

## Accepted findings and corrections

1. **P1, cancellation during admission:** Persist cancellation intent while draft admission is unresolved. When the exact ticket arrives, cancel its draft and do not start transfer. A failed admission clears the pending cancellation state and supplies a truthful next action.
2. **P1, stale strict Linux golden:** Regenerate only the strict Linux chant-detail reference using the documented Flutter 3.47.2 Linux renderer and retain exact comparison. The replacement SHA-256 is `3de74f47f98bdef1b0bbff260ed43de20006f78f99b895d026d96199173120ee`.
3. **P2, final-handoff race:** Remove Cancel after transfer completion and before the review submission callable, so a pending-review success cannot race a valid server cancellation.
4. **P2, hidden cancel semantics:** Limit the live-region exclusion to changing status content and keep the actual Cancel button focusable and activatable for VoiceOver and TalkBack.
5. **P3, player sheet keyboard:** Pad the searchable player selector by the current bottom view inset, keeping the final row reachable with the keyboard open.
6. **P3, onboarding selection:** Add a gold selected border and stronger selected type weight, so the first destination is not distinguished only by surface and text color.
7. **P3, inert app-bar back:** Remove the visible leading back action throughout upload, cancellation, and final handoff while route popping is blocked.
8. **P3, permission recovery:** Recognize camera and media-library denial codes and provide written Settings guidance plus the alternate picker.

## Replacement verification

- Corrected focused Flutter set: 43 tests passed.
- Complete Flutter suite: 563 tests passed.
- `flutter analyze --no-pub lib test`: no issues.
- Strict Linux Flutter 3.47.2 chant-detail golden: one exact comparison passed after visual inspection.
- Functions production compilation: passed.
- Functions unit suite: 230 passed, with 24 emulator-only cases correctly excluded from that process.
- Real Firestore Functions integration: 24 passed.
- Combined Java-backed Firestore and Storage rules: 174 passed.
- Seed suite: 87 passed; seed TypeScript check reports no error.
- Store-packet, launch-services, launch-guide, public-site, device-readiness, crest, project-memory, writing, governance, native-project, staged whitespace, and bounded staged credential-value gates pass at final staging.

## Corrected native receipts

- Android AAB: 65,259,947 bytes, SHA-256 `2c847a1bf33ce5b3b3c7dca7eeb4740624e8e9c8fdc17b0049ebd0c9b9950102`.
- Android APK: 64,045,551 bytes, SHA-256 `f5bdc859fc0087cc5b4a136d92e324db25e4ec5fbe349f03670a8eef9707d836`.
- Android package `com.chants.chants`, version 1.0.0, code 1, existing upload-certificate SHA-256 `8277987e342dc5a2de3f2a96c36ce11efe5c33a66582cfd2f00953a0daf2fc55`; AAB JAR and APK v2 verification and archive integrity pass. No rejected advertising or ad-services permission is present.
- iOS archive: 537,640,960 allocated bytes, content-tree SHA-256 `e1c4bc40e09f5de32e69d8ba45ac6315dd947e5ae0e0dbb9977502de4c261d11`.
- iOS IPA: 51,670,635 bytes, SHA-256 `7d2a586fb49c72e288f077a1dd153a7ec327f47623db6e154f36b0270f95b4d5`; ZIP integrity and strict deep-signature verification pass.
- iOS reports `com.chants.chants`, version 1.0.0, build 1, iPhone family, minimum iOS 15, Apple Distribution team `J7V95LBCWR`, profile expiry 2027-09-10, `get-task-allow` false, TestFlight reporting, Sign in with Apple, and only the two approved associated domains.
- Both native builds left tracked Android, iOS, and pubspec state unchanged beyond the already reviewed staged manifest correction. Build outputs and signing material remain ignored and untracked.

## Residual gates

- Fresh replacement Android and iOS receipts are recorded in `docs/EXECUTION.md`; neither artifact has been uploaded or installed through a store.
- The exact corrected handoff remains uncommitted and unpushed until Andrew separately authorizes that mutation.
- Clean-runner exact-head CI, physical Android installation, TestFlight upload and iPhone walk, provider and public-site evidence, store submission, and release remain separate gates.
