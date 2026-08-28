# Change spec: Post-auth independent review corrections

**Status:** Implemented and locally verified; packaging and exact-head CI pending
**Updated:** 2026-08-28
**Risk lane:** Lane 2, authentication recovery, verified-contact authorization, SMS abuse controls, magic-link persistence, and launch onboarding
**Base:** `db40f4257679cd368dc1d4ff5bcd532f324e5a37`, exact PR 18 clean-runner head
**Review source:** Independent read-only review of `86603c22fbd7647f89c9276af9a60a0b3d63113b..db40f4257679cd368dc1d4ff5bcd532f324e5a37`
**Approval:** Andrew explicitly approved `post-auth independent review correction spec` on 2026-08-28.

## Outcome

- **Problem:** The combined creator and launch-authentication stack has no source-freeze blocker, but the independent review found four medium and five low defects in recovery, rule consistency, SMS throttling, magic-link state, truthful feedback, and touch-target behavior.
- **Desired behavior:** Enabled authentication methods remain retryable, onboarding always preserves an escape or retry action, phone attempts cannot bypass the visible cooldown or revive after cancellation, client and server verified-contact authority remain consistent, and every confirmation states only what actually happened.
- **Review boundary:** `storage.rules`, authentication repository primitives, phone, magic-link, verification, onboarding and sign-in-methods presentation, focused tests, interface memory, execution evidence, decision 023, current milestone truth, and the completed change record.
- **Freeze position:** This correction may close source defects. It does not convert provider configuration or device evidence into source-complete claims.

## Approved corrections

### M1: Storage verified-contact parity

1. Storage operator authority must require the same verified-contact facts as Firestore operator authority.
2. An unverified operator may not read another account's staged performance media.
3. An active verified operator retains the intended narrow staging-preview access.
4. A user may retain only the existing owner read behavior allowed by the approved policy. This correction does not expand any Storage path.

### M2: Retryable Google initialization

1. One successful Google initialization may be shared by later Google sign-in or linking calls.
2. A rejected initialization must not remain cached.
3. A later call may initialize again without restarting the app.
4. Concurrent callers may share one in-flight initialization rather than starting duplicate initialization work.

### M3: Recoverable post-callable onboarding

1. The onboarding submit operation disables mutation controls only while the callable is in flight.
2. If the callable succeeds but the profile stream does not advance, the screen restores Enter Chants and Sign Out.
3. A repeated Enter Chants action remains safe because `completeOnboarding` is idempotent.
4. The screen states that setup was saved and a retry is safe when it remains visible after success.
5. A late completion may not access disposed widget or Riverpod state.

### M4: Cooldown across every phone send

1. The 60-second cooldown applies to every new SMS request from the screen, not only the explicit resend button.
2. Change Number may restore editable input but cannot enable another send until the current cooldown ends.
3. Cancelling or changing the attempt prevents a late unused credential from being accepted.
4. Firebase quota, region, billing, and platform anti-abuse controls remain the real production boundary.

### L1 through L5: Narrow recovery and interface truth

1. An ambiguous magic-link send failure preserves the newly written pending binding because Firebase may have accepted the request before the transport error surfaced.
2. Phone attempt cancellation remains terminal even when cancellation occurs while one credential is in flight and that credential later fails.
3. Returning from a successful magic-link send in Sign-in methods reports that a link was sent and still needs completion. It does not claim the provider is connected.
4. Email-verification send returns whether a message was actually requested. Callers do not claim a send when the current user was already verified.
5. The onboarding destination selector has a minimum 48 logical-pixel target without forcing unrelated segmented controls through a global visual change.

## Acceptance criteria and invariants

1. Storage and Firestore use the same verified-contact requirement for operator authority.
2. Disabling or failing one provider flow cannot poison every later attempt in the same process.
3. No onboarding path leaves every actionable control disabled after remote work has completed.
4. No screen path can request more than one phone verification message during the active cooldown.
5. Cancellation is monotonic for one phone verification attempt.
6. Ambiguous remote delivery never destroys the only local state required to complete a possibly delivered magic link.
7. The app distinguishes `requested`, `already complete`, and `failed` verification outcomes in user-facing copy.
8. No new provider becomes visible and no production configuration is inferred from source.
9. Existing deletion-first routing, server onboarding, UID preservation, last-method protection, creator-platform authority, and protected mutation boundaries remain unchanged.
10. Focused tests reproduce every finding at the production boundary and fail if its correction is removed.
11. Full Flutter, Functions, seed, analysis, rules compilation, governance, writing-style, native-contract, and diff checks pass locally where the toolchain exists.
12. Java-backed rules and both native clean builds remain exact-head clean-runner gates after packaging is separately authorized.

## Failure and recovery analysis

| Condition | Required behavior | Evidence |
|---|---|---|
| Unverified operator reads staged media | Storage denies the read | Storage emulator assertion |
| Google initialization fails once | First call fails; second initialization may succeed | Auth repository regression |
| Onboarding callable succeeds but profile stream stalls | Controls restore, setup-saved copy appears, retry and Sign Out remain available | Production widget regression |
| User changes number during cooldown | Number becomes editable; send remains disabled with countdown | Phone screen widget regression |
| Phone credential is cancelled while in flight and then fails | Later automatic credential is rejected | Attempt state-machine regression |
| Magic-link request returns an ambiguous failure | Pending binding remains and retry is possible | Magic-link widget and store assertion |
| Magic-link request is sent from Sign-in methods | Copy says completion is still required | Sign-in-methods widget regression |
| Verification resend is requested after the user is already verified | No false sent confirmation is shown | Repository and widget regression |
| Onboarding destination is rendered at narrow width and enlarged text | Every destination remains present with at least a 48-pixel target | Widget accessibility assertion |

## Verification plan

- Add focused Storage emulator coverage for unverified and verified operator reads.
- Add repository tests for failed-then-successful Google initialization and cancellation during an in-flight phone claim.
- Add production widget tests for post-callable onboarding recovery, change-number cooldown, magic-link pending-state retention, accurate method-link copy, accurate verification copy, and the 48-pixel destination target.
- Run focused tests during implementation and prove critical guards can fail against the reviewed behavior where practical.
- Run the complete Flutter, Functions, seed, analysis, rules TypeScript, governance, native-contract, writing-style, memory, and diff matrix.
- After separate packaging and push authorization, require all eight exact-head CI jobs on PR 18.

## Deliberately deferred launch gates

- Firebase, Apple, Google, Meta, APNs, Play, Hosting, App Check, quota, billing, and provider-console changes.
- `assetlinks.json`, `apple-app-site-association`, the hosted magic-link completion route, and deployed domain verification until exact signing and Apple-team facts exist.
- Facebook Android identifiers and callback entries until the operator supplies reviewed non-secret identifiers and the provider is ready for device verification.
- Android merged-manifest inspection on an Android 11 or later device.
- Android release signing with and without an operator `key.properties` file.
- Real SMS auto-retrieval, magic-link cold start, App Links, Universal Links, provider login, physical-device, store, deploy, seed, and production observation work.

## Rollout and recovery

1. Keep every new provider flag disabled through this correction.
2. Package the correction only after local evidence and durable records agree.
3. Run replacement exact-head clean CI before treating the correction as source-verified.
4. Use one narrow independent closure of only the correction range if Andrew requests it. Do not repeat the full combined-stack review.
5. Configure and enable one provider at a time only after its external and device gates pass.

## Excluded authority

Approval authorizes local source, focused tests, and durable-record changes inside this correction boundary. It does not authorize provider-console changes, Firebase writes, SMS sends, credentials, association deployment, signing keys, Android SDK installation, deployment, seed writes, commit, push, merge, store actions, or release.
