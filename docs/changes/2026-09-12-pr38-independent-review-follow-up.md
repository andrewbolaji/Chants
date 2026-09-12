# Pull request 38 independent-review follow-up

## Outcome

The accepted final review findings are corrected inside the approved release-candidate boundary. The app keeps current loading authority during a profile retry, dismisses an email form when authentication arrives after its written timeout, preserves the real upload-admission failure during early cancellation, and compensates an approved-media copy when publication fails. Native privacy defaults and the Android device handoff are stricter and more accurately documented.

No provider was enabled. No production, store, signing, deployment, merge, or release state changed.

## Corrections

- The signed-in gate no longer converts a refreshing error into immediate recovery or starts a second retry behind a manual retry.
- Email sign-in keeps one auth-state listener after its 15-second written timeout and dismisses the stale route when an authenticated user arrives.
- Early upload cancellation does not claim cancellation failed when draft admission itself failed.
- A failed performance publication transaction removes the exact copied canonical object and preserves the original moderation error even if cleanup also fails.
- iOS explicitly disables Facebook automatic event logging and advertiser identifier collection while the provider remains hidden and unconfigured.
- The Android helper accepts one explicit hash-bound APK, verifies the complete permission set and 16 KB ZIP alignment, rejects emulator runtime properties, and maps common installation failures to sanitized recovery guidance.
- Current documentation states that local release packaging uses Flutter 3.44.8 while CI pins Flutter 3.47.3.

## Verification before packaging

- 80 focused Flutter tests pass.
- The complete Flutter suite passes 599 tests and scoped analysis reports no issue.
- Functions compile and report 232 passing unit tests with 24 emulator-only cases pending in that process.
- All 24 dedicated real-Firestore transaction cases pass.
- All 174 Firestore and Storage rules assertions pass on local Java 21 emulators.
- All 87 seed tests and seed TypeScript pass.
- All 50 helper, guide, policy, launch-service, and public-site regressions pass.
- The store packet passes in honest prepared and not-submitted state, and all 20 store regressions pass.
- Native-project and launch-services checks pass. The iOS plist is syntactically valid.

## Replacement release artifacts

- Runtime source commit `fedfe2cc2ea0d5cf2da26b3525fd15961a2ac248` produced a 65,374,710-byte signed Android AAB with SHA-256 `b19015b6572629177d22f46ca4074474ddd2c2b18a19dbfc82de084eb5765b1f` and a 64,095,075-byte signed APK with SHA-256 `b5eb1cca78069f25574aec4b9f6d1b659a68698775451bc07ca7adef58f14151`. Package, version, SDK, complete permissions, upload certificate, AAB JAR signature, APK v2 signature, and 16 KB ZIP alignment checks pass.
- The same source produced a 537,714,688-allocated-byte iOS archive with content-tree SHA-256 `131450bdeff907730948815c8803a69cf1d3ec56e527f18e1917b16a9b4c565c` and a 51,695,398-byte App Store IPA with SHA-256 `9a2ebb076df62d7abded2002f20d31eddeb35096ee54a2559bb7e0545aa47d9a`. ZIP integrity, strict deep signature, arm64, identity, version, minimum OS, distribution profile, privacy flags, and exact entitlement checks pass.
- Hash-verified copies of the APK, AAB, and IPA replace the older files in the sibling `Chants-v1-release-handoff` directory. Nothing was uploaded or submitted.

## Remaining gates

The final staged packet passes governance checks. The focused commits may now be pushed to pull request 38, where exact-head CI must pass. A new physical iPhone or Android walkthrough is not part of this source-only correction and remains required for the rebuilt candidate where applicable.
