# Signup recovery and first-run polish

## Outcome

The verified password-signup journey no longer remains on an indefinite submit spinner. The pushed signup route exits after account creation and the verification request complete, allowing the existing account gate to show the next confirmed state.

The first-run presentation now follows the Chants framework rule `LOUD FRAME, CALM WORDS`. Anton remains on short football signage and primary labels. Nunito owns inputs, instructions, consent, utilities, and policy routes. Gold is concentrated in the primary action instead of appearing on every available choice.

## Interface changes

- Reduced the display scale and density on launch, signup, onboarding, and empty Stage surfaces without removing the football identity.
- Made email, password, display-name, and birth-date values use the calm UI type role rather than the lyric role.
- Gave display name and date of birth the same external-label and equal-height field pattern, removing the border-cutting birth-date label.
- Replaced the detached onboarding agreement treatment with one restrained surface containing the aligned checkbox, sentence, and compact policy-link group.
- Made policy links and Sign Out neutral utilities.
- Changed the first-destination selection from a full gold segment to a quiet raised surface with three fixed centered labels and no layout-shifting check icon.
- Kept the full-width gold treatment for the final Enter Chants action.
- Returned supporter gold to the documented `#F2AE2E` token and kept `#FFC94D` only as the brighter foil endpoint, reducing glare without removing the accent.
- Simplified the empty Stage illustration, copy, and secondary action while preserving the route to create or browse.
- Retained all existing authority, validation, recovery, navigation, and accessibility behavior.

## Evidence

- Added a successful-signup route regression.
- Added policy-group alignment, neutral-style, minimum-target, selected-state, and 320-pixel enlarged-text checks.
- Added and inspected 390 by 844 and 440 by 956 onboarding goldens plus a 440 by 956 account-creation golden.
- Corrected the physical-device alignment exposed after the first install: the app bar and form now share one 24-pixel edge, the checkbox no longer reserves a detached column, and the policy links retain a compact but explicit gap.
- Focused auth, onboarding, and app-gate suites: 61 tests passed.
- Final alignment-focused auth, onboarding, and app-gate set: 38 tests passed.
- Final full Flutter suite: 548 tests passed.
- Scoped Flutter analysis: no issues.
- Fresh final-source signed iOS release build: 67.2 MB, bundle `com.chants.chants`, version `1.0.0` build `1`, arm64, team `J7V95LBCWR`. It was not installed during the unattended pass because the physical phone was unavailable.
- After the owner returned and confirmed the paired iPhone was ready, the exact final-source build installed and launched successfully as `com.chants.chants` on the iPhone 17 Pro Max.
- Earlier alignment builds installed successfully on the paired iPhone and supplied the owner captures that drove the structural correction. They are not the final exact-source package.
- Fresh final-source Android release AAB: 65,209,160 bytes, SHA-256 `27c6cf4814de6d0ee36efcdf1a1f5ee81931cf8e72f765e68846110d75f79435`.
- Fresh final-source Android release APK: 63,963,195 bytes, SHA-256 `d592dd690efd311840d5e8a4db6958b451f10a65963ba76ab36ccfae43e0341b`.
- The APK is package `com.chants.chants`, version `1.0.0` code `1`, targets SDK 36, verifies with signature scheme v2 and the existing 4096-bit upload certificate, and contains no Advertising ID or Privacy Sandbox ad-services permission.
- Installed the final-source release APK on an Android 16 emulator and inspected the aligned welcome screen at 1080 by 2400 after a true cold start. The app remained running without a crash. The emulator disconnected while opening a second capture, so account creation is covered by the inspected 440 by 956 final-source golden and the earlier packaged Android proof.
- Updated the prepared, not-submitted store packet to hash-bind the approved UI source. Live packet validation and all 20 packet regressions pass.

## Operational boundary

Production remains generation 17 maintenance with destructive workers false. The existing verified reviewer Authentication account still has no supporter profile. No production data, deployment, store record, binary upload, review request, submission, or release changed in this block. Reviewer onboarding and the later upload canary require their own controlled windows.
