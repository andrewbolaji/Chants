# Android device and iOS distribution preparation

## Outcome

The Android workstation and fixed release candidate are prepared so the physical-device session needs only phone setup, one guarded install command, and the six-step walk. A current App Store archive and IPA are also built, distribution-verified, and preserved locally. No artifact was uploaded, no store or provider console changed, and production was neither read nor changed.

## Source boundary

- The replacement runtime source is anchored at `fedfe2cc2ea0d5cf2da26b3525fd15961a2ac248`. Pull request 38 previously passed all eight exact-head jobs at `bb15ca62e4a169b52a4413e68a5d52bc48f3faab`; replacement exact-head CI is required for the follow-up.
- The later receipt commit changes only the hash-bound helper, handoff records, and current artifact documentation.
- The package and bundle remain `com.chants.chants`, version 1.0.0, with Android code and iOS build 1.

## Android preparation

- Android platform-tools 37.0.1 are installed locally. Android build-tools 36 and OpenJDK 21 are available.
- `scripts/prepare-android-device.mjs` passively verifies the exact APK hash, package, version, code, minimum and target SDK, complete merged permission inventory, rejected advertising-permission boundary, 16 KB ZIP alignment, APK v2 signature, and expected upload certificate. It accepts the checkout build output or one explicit durable APK path, but never relaxes the receipt.
- Only explicit `--install` mode may touch a device. It requires exactly one authorized physical Android phone, rejects emulator serials and runtime properties plus ambiguous, offline, unauthorized, or unsupported targets before installation, confirms the installed package, launches Chants, and never emits a device identifier or raw tool output. Replacement installation preserves data only when signatures match. Incompatible-signature recovery requires a separately chosen uninstall that deletes local app data.
- Tests cover the exact pass, durable-path pass, every receipt mismatch, rejected permissions, missing v2, wrong certificate, serial and runtime emulator rejection, multi-device rejection, authorization and OS failures, classified restricted and incompatible installation failures, the app-data-preserving compatible install, launch, and bounded arguments.

## Signed artifact receipts

- Android AAB: 65,374,710 bytes, SHA-256 `b19015b6572629177d22f46ca4074474ddd2c2b18a19dbfc82de084eb5765b1f`.
- Android APK: 64,095,075 bytes, SHA-256 `b5eb1cca78069f25574aec4b9f6d1b659a68698775451bc07ca7adef58f14151`.
- Android reports package `com.chants.chants`, version 1.0.0, code 1, minimum SDK 24, target SDK 36, and upload-certificate SHA-256 `8277987e342dc5a2de3f2a96c36ce11efe5c33a66582cfd2f00953a0daf2fc55`. AAB JAR and APK v2 verification pass. The exact APK passes 16 KB ZIP alignment and declares only `android.permission.INTERNET`, `android.permission.ACCESS_NETWORK_STATE`, `android.permission.WAKE_LOCK`, `android.permission.USE_BIOMETRIC`, `android.permission.USE_FINGERPRINT`, `com.google.android.c2dm.permission.RECEIVE`, `com.google.android.providers.gsf.permission.READ_GSERVICES`, `com.chants.chants.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, and `com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE`. No Advertising ID or Privacy Sandbox ad-services permission is present.
- iOS archive: 537,714,688 allocated bytes, deterministic content-tree SHA-256 `131450bdeff907730948815c8803a69cf1d3ec56e527f18e1917b16a9b4c565c`.
- iOS App Store IPA: 51,695,398 bytes, SHA-256 `9a2ebb076df62d7abded2002f20d31eddeb35096ee54a2559bb7e0545aa47d9a`.
- The IPA passes ZIP integrity and strict deep-signature verification. Its arm64 iPhone app reports `com.chants.chants`, version 1.0.0, build 1, minimum iOS 15, Apple Distribution team `J7V95LBCWR`, App Store profile expiry 2027-09-10, no provisioned-device list, `get-task-allow` false, TestFlight reporting, Sign in with Apple, and only the two approved Chants associated domains. Both native Facebook automatic-collection flags are false in the exported app.
- Strict trust construction used Apple's already retained public WWDR G3 certificate only inside a temporary verification keychain. That keychain and the extracted IPA were deleted. No normal keychain or signing identity changed.

## Durable handoff

The APK, AAB, and IPA are copied to the sibling local folder `../Chants-v1-release-handoff` with `README.md` and `SHA256SUMS`. `shasum -a 256 -c SHA256SUMS` passes for all three files. This folder is outside the Git checkout so a later Flutter cleanup does not erase the candidates.

## Verification

- All 50 Android-preparation, device-readiness, command-center, launch-policy, launch-service, and public-site cases pass.
- The honest prepared and not-submitted store packet passes, and all 20 store regressions pass.
- Native-project, staged project-memory, writing-style, governance, staged whitespace, and diff checks pass.
- The native builds introduced no tracked Android, iOS, pubspec, or lockfile drift.

## Remaining gates

- Android phone day: enable Developer options and USB debugging, connect and unlock one phone, approve this Mac, run `node scripts/prepare-android-device.mjs --apk ../Chants-v1-release-handoff/Chants-1.0.0-1-release.apk --install --json`, then complete the six-step walk.
- The existing app source already contains Apple, Google, Facebook, passwordless email, and email-password paths behind fail-closed configuration. Provider dashboard credentials, callbacks, domains, and configured-device proof remain open.
- The prior physical iPhone walk predates the independent-review runtime fixes. Public routes, final store captures, questionnaires and metadata, TestFlight and Play upload, store-installed beta walks, submission, merge, production changes, and public release remain separately gated.
