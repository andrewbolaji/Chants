# Final source-freeze minor closure

## Change identity

- **Approval:** Andrew requested the two minor fixes, replacement CI, and merge on 2026-08-29.
- **Starting head:** `5350b8ae0d41665db7a41e00117b50e73c062b4e`, independently reviewed combined PR 17 and PR 18 head.
- **Implementation head:** `e1474ad7ae362dcaaf6a19c45907024c31a60f7b`.
- **Documentation head:** `c1c4ea4f2278a36337f0de56836368315a30632b`.
- **Merged main:** `e8f2591740963f87623aacb82a806328cb1a98fe` through PR 17.
- **Scope:** Freeze saved onboarding values during delayed profile projection and reconcile current engineering evidence with the packaged, reviewed, and green source state.
- **Excluded authority:** No callable, schema, rule, provider, native, Firebase, Storage, SMS, credential, association, signing, store, seed, deployment, or release change.
- **Durable decision:** Decision 023 remains unchanged. This closure makes its existing idempotent onboarding consequence truthful in the interface.

## Correction

`OnboardingScreen` records when the server has confirmed setup. It then disables display name, birth date, policy acceptance, and first destination while retaining two explicit recovery actions. `CHECK AGAIN` reuses the original saved values so it cannot imply that a later edit was accepted. Sign Out remains available. First-submit validation and failure recovery remain editable.

The current overview, implementation rationale, interface memory, project profile, roadmap, and prior post-auth record now identify correction commit `6002724`, PR 18 merge commit `5350b8a`, runs `33213537910` and `33215692105`, 463 Flutter tests, 142 Functions tests, 42 seed tests, 165 Java-backed rule cases, and both native builds. They no longer describe the nine-finding correction as local or awaiting packaging. Device, provider, association, policy, signing, deployment, cost, seed, and release gates remain open.

## Invariants and failure behavior

- A confirmed profile-creation payload cannot diverge from editable values still shown on screen.
- Delayed profile projection keeps Check Again and Sign Out available.
- A repeated check submits the original saved display name and relies on the unchanged idempotent server path.
- A failed first request restores editable controls and retained values.
- Documentation separates clean source evidence from real-device and production readiness.

## Verification record

- The focused production widget file passes 10 tests, including the changed post-success regression.
- The regression requires frozen saved fields, Check Again, enabled Sign Out, and two calls carrying the same original display name. Those assertions reject the reviewed pre-correction interface, which exposed Enter Chants and editable fields after success.
- Exact current-truth searches confirm the stale local and pending claims were limited to the records updated by this closure. Historical execution entries remain unchanged because they accurately describe their time.
- The full Flutter suite passes 463 tests, and `flutter analyze lib test` reports zero issues.
- Functions pass 142 tests, seed passes 42 tests plus TypeScript, and rules TypeScript passes. Java-backed execution remains clean-runner evidence because Java is unavailable locally.
- Project memory, staged-memory, index-scoped writing, governance regressions, native contract, formatter, authored-prose search, and diff checks pass against the intended commit boundary.
- GitHub Actions run `33254213575` passes all eight jobs at exact implementation head `e1474ad`, including both native compile and identity checks and 165 Java-backed Firestore and Storage cases.
- GitHub Actions run `33255542646` passes all eight jobs at exact documentation head `c1c4ea4`.
- GitHub Actions run `33256843751` passes all eight jobs at exact merged `main` `e8f2591`: 463 Flutter tests, analysis, 142 Functions tests, 42 seed tests, 165 Java-backed Firestore and Storage cases, governance, and both native compile and identity checks.

## Remaining gates

- Combined iOS and Android device walkthrough.
- Provider dashboards, credentials, associations, production signing, policy, cost controls, App Check, monitoring, deployment, remaining seed, store work, and release.
