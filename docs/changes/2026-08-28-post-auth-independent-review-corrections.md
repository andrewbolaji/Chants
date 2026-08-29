# Post-auth independent review corrections

## Change identity

- **Approval:** Andrew approved `post-auth independent review correction spec` on 2026-08-28.
- **Starting head:** `db40f4257679cd368dc1d4ff5bcd532f324e5a37`, exact PR 18 clean-runner head.
- **Scope:** One bounded correction for four medium and five low findings in Storage operator authority, authentication recovery, truthful status copy, SMS throttling, magic-link persistence, and onboarding accessibility.
- **Excluded authority:** No provider dashboard, live Firebase, SMS, credential, association deployment, signing, Android SDK installation, commit, push, merge, deploy, store, or release action.
- **Durable decision:** `docs/decisions/023-verified-authentication-and-server-onboarding.md`.

## Corrections

Storage operator preview now requires the same verified-contact facts as Firestore operator authority. The owner read branch is unchanged. A new emulator case denies an unverified operator and accepts the active verified operator.

Google initialization still shares one successful or in-flight request, but a rejected request clears its cached future so a later attempt can initialize again. Email verification now returns whether Firebase was actually asked to send. Verification and Sign-in Methods show distinct requested and already-complete results.

Onboarding restores Enter Chants and Sign Out after a successful callable when the profile stream has not advanced, explains that the saved setup is safe to retry, and keeps the destination selector at least 48 logical pixels high. A late completion checks widget lifetime before touching state.

The phone cooldown now guards every send path. Change Number restores editable input but leaves the primary send disabled with the remaining countdown. Cancelling an attempt is monotonic even if a claimed credential is still in flight and later fails.

An ambiguous magic-link send failure retains the pending device binding because Firebase may have accepted the request. Returning to Sign-in Methods after a successful request says the link was sent and still needs completion; it does not claim a provider connection.

## Invariants and failure behavior

- Verified-contact authority is consistent across callable, Firestore, and Storage operator paths.
- A transient provider initialization failure does not poison the process lifetime.
- Completed remote work never leaves onboarding with every useful action disabled.
- One visible SMS cooldown covers initial-send recovery, Change Number, and explicit resend.
- Cancellation cannot be reversed by a later callback after an in-flight failure.
- Ambiguous delivery preserves the local binding needed by a possibly delivered link.
- User copy distinguishes requested, connected, already complete, and failed outcomes.
- No provider becomes visible and no production setup is inferred from source.

## Verification record

Local and clean-runner evidence at the packaged correction and combined merge trees:

- 463 Flutter tests pass. Nine new regressions cover failed Google initialization retry, verification request truth, in-flight phone cancellation, post-callable onboarding recovery, destination target height, Change Number cooldown, ambiguous magic-link delivery, actual email-link return copy, and already-verified email copy.
- Flutter analysis of `lib` and `test` passes with zero issues.
- 142 Functions tests and 42 seed tests pass unchanged.
- Run `33213537910` passed all eight jobs at correction commit `6002724`.
- Run `33215692105` passed all eight jobs at byte-identical combined head `5350b8a`, including 165 Java-backed Firestore and Storage cases and both native compile and identity checks.
- The Storage addition is one cross-account emulator case containing three permission assertions: owner upload, unverified-operator denial, and verified-operator access.
- Project memory, writing style, native project contract, project governance regressions, and `git diff --check` pass locally.

## Deliberately unchanged and remaining gates

- The callable, Firestore, Functions, native projects, provider flags, provider dashboards, and deployed infrastructure are otherwise unchanged.
- Association files wait for exact Android signing and Apple team facts. Facebook Android identifiers wait for reviewed operator values. Android package visibility waits for a reproduced need.
- Real SMS, magic-link cold start, App Links, Universal Links, OAuth providers, release signing, physical devices, production policy, billing, quotas, App Check, deployment, seeding, and store work remain release gates.
- Provider, device, production, seed, deployment, and release evidence remains required as listed above. The post-auth correction itself is packaged and exact-head clean-runner verified.
