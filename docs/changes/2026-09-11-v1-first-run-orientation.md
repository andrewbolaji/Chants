# V1 first-run orientation

## Outcome

Chants now gives a first-time signed-out installation one short, skippable introduction to Songbook, Chant Lab, and Stage. The guide preserves fast exits, keeps Create Account visible on every step, and hands Skip or Continue to the existing sign-in welcome. It is ready to enter pull request 38 after complete local and signed-native verification.

## Authority and boundary

- Andrew requested a light, logical, beautiful, skippable V1 onboarding built for retention and supporter happiness, with a direct account-creation route where it makes sense.
- Andrew approved adding the completed orientation to pull request 38. That authorizes one focused commit and push to the existing branch, not merge, store upload, submission, production mutation, or release.
- The guide does not add guest browsing, change authentication authority, alter policy admission, or replace the required verified-account profile setup.

## Product behavior

- Three concise pages explain Songbook learning and device saves, Chant Lab ideas and evidence, and Stage creation plus private video review.
- `SKIP` and `CREATE ACCOUNT` remain available on every page. `NEXT` advances locally, and the final `CONTINUE TO SIGN IN` opens the existing sign-in welcome.
- Completion is a single versioned, nonidentifying device-local boolean. Repeat signed-out launches do not replay V1 orientation.
- A local read failure fails open to sign-in. A failed or two-second-stalled completion write cannot trap the supporter.
- Signed-in users and every existing account, onboarding, deletion, and policy gate bypass this guide unchanged.

## Interface and accessibility

- The three 390 by 844 references were inspected. Each keeps one short headline, calm explanation, written trust distinction, visible progress, and a consistent action area.
- Semantic headings and a written step position support assistive technology. Reduced-motion mode removes the page transition.
- A 320 by 568 layout at 1.8x text remains scrollable with reachable actions and no overflow.

## Verification

- Focused repository, app-gate, interaction, failure, timeout, reduced-motion, semantics, responsive, and golden set: 45 tests passed.
- Complete Flutter suite: 588 tests passed.
- `flutter analyze --no-pub lib test`: no issues.
- Store packet live validator and all 20 regressions: passed.
- Native builds changed no tracked Android, iOS, or lockfile source.

## Signed native receipts

- Android AAB: 65,358,385 bytes, SHA-256 `97d28f20e1862ea27e71fb5bdcd6bf63861b6d2c8e2e055401e71dca0bc07fc3`.
- Android APK: 64,078,519 bytes, SHA-256 `83f49ef7c6f8eb5f7062791cd0e222512263884b07fc56022dfe69bdb1f2c700`.
- Android reports package `com.chants.chants`, version `1.0.0`, code `1`, minimum SDK 24, target SDK 36, arm64-v8a, armeabi-v7a, and x86_64. AAB JAR and APK v2 signature verification pass with the existing upload-certificate SHA-256 `8277987e342dc5a2de3f2a96c36ce11efe5c33a66582cfd2f00953a0daf2fc55`. No Advertising ID or Privacy Sandbox ad-services permission is present.
- iOS archive: 537,710,592 allocated bytes, content-tree SHA-256 `9181dc16e379716053e3d7fb695e111d59e44e9ab29845471231846c037ab7d7`.
- iOS IPA: 51,686,765 bytes, SHA-256 `7c2e1dc8311f7c1061956d21992bbeac18784c3a5f4dd53ddc38f1c1b144b483`; ZIP integrity and strict deep-signature verification pass.
- iOS reports `com.chants.chants`, version `1.0.0`, build `1`, arm64, iPhone family, minimum iOS 15, Apple Distribution team `J7V95LBCWR`, profile expiry 2027-09-10, `get-task-allow` false, TestFlight reporting, Sign in with Apple, and only the two approved Chants associated domains.
- Apple's public WWDR G3 certificate was imported only into a temporary verification keychain. That keychain and the extracted IPA were deleted after verification; no signing identity or normal keychain changed.

## Residual gates

- Stage the exact extension, pass repository governance, and push one focused commit to pull request 38.
- Require exact-head clean-runner CI for that commit.
- Inspect the rebuilt orientation on the physical iPhone before merge consideration. Physical Android, TestFlight, Play, store submission, merge, production changes, and public release remain separate gates.
