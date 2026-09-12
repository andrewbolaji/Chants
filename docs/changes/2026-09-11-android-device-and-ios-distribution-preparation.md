# Android device and iOS distribution preparation

## Outcome

The Android workstation and fixed release candidate are prepared so the physical-device session needs only phone setup, one guarded install command, and the six-step walk. A current App Store archive and IPA are also built, distribution-verified, and preserved locally. No artifact was uploaded, no store or provider console changed, and production was neither read nor changed.

## Source boundary

- Pull request 38 passed all eight exact-head jobs at `3066474474803881f07f92e0ac1be46c50a2d521` in run `34667543812`.
- The native runtime source is anchored at `7c86ca9713a2beea208110d705fd86fbd6dce1b5`. The later exact-head commit changes only documentation, tests, and inspected Linux visual references.
- The package and bundle remain `com.chants.chants`, version 1.0.0, with Android code and iOS build 1.

## Android preparation

- Android platform-tools 37.0.1 are installed locally. Android build-tools 36 and OpenJDK 21 are available.
- `scripts/prepare-android-device.mjs` passively verifies the exact APK hash, package, version, code, minimum and target SDK, rejected advertising-permission boundary, APK v2 signature, and expected upload certificate.
- Only explicit `--install` mode may touch a device. It requires exactly one authorized physical Android phone, rejects emulators and ambiguous, offline, unauthorized, or unsupported targets before installation, preserves app data, confirms the installed package, launches Chants, and never emits a device identifier or raw tool output.
- Tests cover the exact pass, every receipt mismatch, rejected permissions, missing v2, wrong certificate, emulator and multi-device rejection, authorization and OS failures, the app-data-preserving install, launch, and bounded arguments.

## Signed artifact receipts

- Android AAB: 65,372,439 bytes, SHA-256 `bf937418a468cafe4ecc0b20f6fa8be2e20069a63bb1cd4d9479eff57f705502`.
- Android APK: 64,095,075 bytes, SHA-256 `f30c55a408bc0fadc5c2cbb90975005e2ea3fd470b408e6e71393031a88a3cc9`.
- Android reports package `com.chants.chants`, version 1.0.0, code 1, minimum SDK 24, target SDK 36, and upload-certificate SHA-256 `8277987e342dc5a2de3f2a96c36ce11efe5c33a66582cfd2f00953a0daf2fc55`. AAB JAR and APK v2 verification pass, with no Advertising ID or Privacy Sandbox ad-services permission.
- iOS archive: 537,714,688 allocated bytes, deterministic content-tree SHA-256 `84cdf14451e8695f6a27ae97598b0d7ceaf67821237e12365074ba9f92b20741`.
- iOS App Store IPA: 51,694,766 bytes, SHA-256 `3976481a00273d1e45d905aec4be30864f317162ea7e06b559f7f0edabca1fb4`.
- The IPA passes ZIP integrity and strict deep-signature verification. Its arm64 iPhone app reports `com.chants.chants`, version 1.0.0, build 1, minimum iOS 15, Apple Distribution team `J7V95LBCWR`, App Store profile expiry 2027-09-10, no provisioned-device list, `get-task-allow` false, TestFlight reporting, Sign in with Apple, and only the two approved Chants associated domains.
- Strict trust construction used Apple's already retained public WWDR G3 certificate only inside a temporary verification keychain. That keychain and the extracted IPA were deleted. No normal keychain or signing identity changed.

## Durable handoff

The APK, AAB, and IPA are copied to the sibling local folder `../Chants-v1-release-handoff` with `README.md` and `SHA256SUMS`. `shasum -a 256 -c SHA256SUMS` passes for all three files. This folder is outside the Git checkout so a later Flutter cleanup does not erase the candidates.

## Verification

- All 44 Android-preparation, device-readiness, command-center, launch-policy, and public-site cases pass.
- The honest prepared and not-submitted store packet passes, and all 20 store regressions pass.
- Native-project, staged project-memory, writing-style, governance, staged whitespace, and diff checks pass.
- The native builds introduced no tracked Android, iOS, pubspec, or lockfile drift.

## Remaining gates

- Android phone day: enable Developer options and USB debugging, connect and unlock one phone, approve this Mac, run `node scripts/prepare-android-device.mjs --install --json`, then complete the six-step walk.
- The existing app source already contains Apple, Google, Facebook, passwordless email, and email-password paths behind fail-closed configuration. Provider dashboard credentials, callbacks, domains, and configured-device proof remain open.
- Public routes, final store captures, questionnaires and metadata, TestFlight and Play upload, store-installed beta walks, submission, merge, production changes, and public release remain separately gated.
