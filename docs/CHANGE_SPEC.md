# Change spec: V1 launch authentication, onboarding, and Android readiness

**Status:** Implemented and locally verified; clean-runner, provider, device, and release gates remain
**Updated:** 2026-08-28
**Risk lane:** Lane 2, authentication, account identity, age and policy admission, personal data, external identity providers, SMS cost, deep links, and native release configuration
**Base:** `8b457d8b0fd959a7dc54222f8f95856c77b2bed6`, exact PR 17 post-review correction head
**Product direction:** Andrew requested a launch-quality signup and onboarding experience with Apple, Google, email and password, email verification, Facebook, magic email links, phone/SMS, provider account linking, automatic verification return, visible password reset, and Android delivery.
**Approval:** Andrew explicitly approved `V1 launch authentication, onboarding, and Android readiness spec` on 2026-08-28.

## Outcome

- **Problem:** Chants currently has a functional email-and-password entry, but it does not yet introduce the creator and matchday product well, verify email ownership, recover automatically after verification, support social or passwordless access, link providers safely, or prove an Android client build. The current password reset is visible, contrary to the supplied comparison, but it treats a network failure as if the request was sent.
- **Desired behavior:** A supporter can understand Chants before creating an account, choose a suitable sign-in method, verify a contact method, complete the age, identity, and policy steps without becoming stranded, enter the right first product destination, and later connect another provider without losing the same Firebase UID or Chants data. Android becomes a continuously compiled V1 target with production signing and provider configuration kept fail-closed until the operator supplies them.
- **Product position:** The entry experience should feel like Chants, not a generic enterprise login. It should communicate three uses quickly: watch performances on the Stage, learn and save Terrace Proven chants for matchday, and create what gets sung next.
- **Review boundary:** Flutter auth and onboarding presentation, app gate and lifecycle, auth/profile repositories, one server-authoritative onboarding callable, current mutation authority, relevant Firestore rules, native iOS and Android provider/link configuration, Android build and signing configuration, CI build evidence, focused tests, and affected engineering records.

## Current evidence

| Capability | Chants at the base | Required end state |
|---|---|---|
| Apple | Not built | Built for supported native platforms, operator-configured before visibility |
| Google | Not built | Built for iOS and Android, operator-configured before visibility |
| Email and password | Built | Preserved and integrated into the new entry flow |
| Email verification | Not built or enforced | Sent, gated, resendable, and refreshed on app return |
| Facebook | Not built | Built behind verified Meta and Firebase configuration |
| Magic email link | Not built | Built with Firebase Hosting action links and safe local email recovery |
| Phone/SMS | Not built | Built with consent, region and quota gates, retry states, and real-device evidence before enablement |
| Provider account linking | Not built | Explicit signed-in linking without automatic email-only merges |
| Automatic verification return | Not built | App resume and incoming-link completion refresh the Firebase user |
| Visible password reset | Built | Preserved, with real delivery failures distinguished from privacy-safe unknown-account results |
| New-provider profile completion | Not recoverable | A missing profile opens onboarding instead of an indefinite loading screen |
| Android build | Source project exists | Clean-runner debug build required; local build waits for Android SDK installation |
| Android production signing | Uses debug signing | Release fails closed until an operator-owned keystore is supplied |

## Approved experience direction

The implementation will use one calm, supporter-first sequence:

1. **Welcome:** `Learn the songs. Back what comes next. Take the Stage.` Show the product before asking for account details.
2. **Choose access:** Apple, Google, and email are primary. Facebook and phone live under `More ways to sign in` so the screen does not become a wall of provider buttons. Email offers password or `Email me a sign-in link` in one place.
3. **Verify when required:** Password-email users receive a verification message. The waiting screen supports resend, change account, manual refresh, and automatic refresh after the app resumes. Google, Apple, Facebook, magic-link, and phone users use Firebase's verified-provider result rather than repeating email verification.
4. **Complete supporter profile:** Collect display name, date of birth, and content-policy acceptance. The exact birth date remains on the device and only the existing 17-plus result crosses the boundary. Provider names and photos may prefill a field but never become public without confirmation.
5. **Choose the first action:** Enter Feed, find a club, or open Matchday Songbook. This choice changes only the first destination. It does not create unused preference data or claim personalization that does not exist.
6. **Manage sign-in methods later:** `You` exposes a Sign-in methods screen for link, unlink, resend verification, and password reset. A user can never unlink the last usable method.

Provider buttons are controlled by an injected availability contract. A release build shows a method only when its native and dashboard setup has been verified. Local tests can exercise every method without depending on production provider state.

## Delivery blocks

### Block A: Entry, verification, and recoverable onboarding

1. Replace the current single-form entry with the approved welcome and method hierarchy while preserving email and password.
2. Use Firebase user-change state plus an app-lifecycle refresh so external verification returns automatically.
3. Add a verification waiting screen with resend cooldown, manual refresh, change-account, offline, expired-session, and ordinary failure states.
4. Replace direct client profile creation during signup with one authenticated `completeOnboarding` callable. It validates the narrow input, derives UID from auth, requires a verified email, verified phone, or trusted current or linked federated identity, creates the private profile with server timestamps, and records current policy acceptance in one Firestore transaction.
5. Route an authenticated account with no profile to onboarding. Existing valid profiles remain compatible and do not repeat onboarding.
6. Preserve age 17-plus behavior without storing the birth date. An underage or declined new account is signed out and offered a best-effort recent-user deletion path without entering the product.
7. Correct password reset so unknown-account privacy remains intact while network, quota, invalid-email, and disabled-provider failures remain truthful and retryable.

### Block B: Provider breadth and account linking

1. Add Google with the official native Google sign-in plugin and Firebase credential exchange.
2. Add Apple through Firebase's Apple provider. Keep Apple consent explicit before linking and add the iOS capability only to the intended app target.
3. Add Facebook through the provider-supported native plugin and Firebase credential exchange. Do not expose the button until the Meta app, callback, policy, and data-deletion configuration are verified.
4. Add Firebase Hosting email-link authentication. Store the pending email only on the device, never in the URL, remove it after completion or cancellation, and ask for it again when a link arrives on another device.
5. Add phone/SMS with clear disclosure that the number is sent to and stored by Google for abuse prevention. Cover code sent, auto-verification, invalid code, expiry, resend, quota, cancellation, and timeout. Do not enable production SMS until region policy, test numbers, quotas, billing alerts, and real-device proof exist.
6. Add an explicit Sign-in methods screen. Linking preserves the current Firebase UID. `account-exists-with-different-credential` never triggers an automatic email-only merge. The user signs in by the existing method and then links deliberately.
7. Prevent unlinking the final usable method. Refresh the Firebase user after link or unlink and preserve the current Chants profile, creator identity, follows, Songbook ownership, and moderation state.

### Block C: Android source and clean build readiness

1. Keep the stable application ID and namespace `com.chants.chants` unless Andrew separately approves a store-identity change.
2. Add production Internet access, correct the visible app label, and inspect the merged manifest for camera, microphone, media selection, auth callback, and App Link behavior.
3. Add Android App Links for the approved public and auth paths without claiming domain association until `assetlinks.json` is deployed and verified.
4. Replace release debug signing with a fail-closed operator-owned signing contract. No keystore, password, certificate, or service credential enters Git.
5. Add a clean-runner Android debug-build job using a checked-in non-secret Firebase compile fixture or an approved secret when available. Inspect the APK identity and source SHA rather than treating Gradle exit zero as complete proof.
6. Install or point Flutter to an Android SDK only with separate machine-level authorization. Then compile locally and walk at least one Google Play emulator or physical Android device.
7. Record Google and phone SHA fingerprints, Play Integrity/App Check, store signing, app-link association, permissions, data safety, and Play listing as release configuration gates rather than source-complete claims.

## Acceptance criteria and invariants

1. Every enabled method has success, user cancellation, network failure, provider-disabled, and account-collision behavior with no permanent loading state.
2. A signed-in user without a private profile sees recoverable onboarding, never the product shell and never an indefinite neutral spinner.
3. A password-email user without a verified address cannot complete onboarding or perform a protected mutation through the app, raw SDK, rules, or callable boundary.
4. A Firebase-verified email, verified phone, or trusted current or linked Apple, Google, or Facebook identity can complete onboarding without a redundant email challenge.
5. `completeOnboarding` derives UID and verified-contact authority from Firebase Auth, accepts only display name, 17-plus confirmation, and current policy consent, and writes one coherent profile state transactionally.
6. Duplicate or concurrent onboarding completion converges on one private profile without changing role, ban, report, deletion, or creator counters.
7. Existing profiles remain readable and do not require schema backfill. Existing users may be asked for contact verification when their Firebase identity lacks it, but they keep the same UID and all existing data.
8. The birth date never enters Firebase, logs, Crashlytics, provider metadata, URLs, or project memory.
9. Provider email, name, phone, token, access token, authorization code, nonce, and raw Firebase exception text do not enter logs.
10. Magic-link completion verifies the Firebase link, binds it to the intended email, uses HTTPS in production, rejects replay or malformed input through Firebase, and removes local pending state after a terminal result.
11. Phone entry uses international format, does not log the number, states the Google processing disclosure, and cannot hammer resend from the UI. Dashboard quotas and region controls remain the real cost boundary.
12. Linking is explicit and preserves the current UID. Collision never deletes or silently merges either account.
13. The last usable sign-in method cannot be unlinked. Recent-login failures explain the safe next action.
14. Email verification reloads once on app resume or deliberate refresh, with no polling loop or background battery cost.
15. Password reset keeps account existence private but does not report `sent` after a known transport or provider failure.
16. Auth cancellation or a declined/underage onboarding path cannot enter the app. Best-effort deletion failure leaves a signed-out, recoverable account rather than granting authority.
17. Banned, deletion-pending, or policy-stale users remain behind the existing gates after any sign-in or link method.
18. Provider buttons meet platform naming and branding rules, have semantic labels, 48 by 48 logical-pixel targets, keyboard order, screen-reader meaning, and no color-only state.
19. Welcome, method choice, email/password, magic-link wait, phone number, SMS code, verification wait, onboarding, and collision recovery render without clipping at 390 by 844, a narrow Android width, and 1.8x text.
20. Android clean CI produces a debug APK from the exact source head. Production release signing refuses to use the debug key.
21. Existing app-gate deletion recovery, policy updates, public creator identity, performance creation, Stage, Songbook, and safety authority remain unchanged after onboarding completes.

## Source of truth and compatibility

- Firebase Auth owns authentication identity, verification state, linked providers, and the stable UID.
- `profiles/{uid}` remains the private Chants authority record. The new callable owns initial creation; existing profile reads and allowed display-name updates remain compatible.
- `creatorProfiles/{uid}` remains optional public identity and is not silently created from provider data during authentication.
- Current Firebase UID remains the ownership key for creator identity, follows, interactions, notifications, reports, deletion work, and local Songbook state.
- Existing email-password accounts and profiles require no backfill. New clients handle a missing profile; old clients are not released against newly enabled providers until the onboarding callable and compatible rules are deployed.
- Email-link pending state is device-local and short-lived. No server-side pending-email collection is introduced.
- Provider availability is injected configuration, not inferred from UI or trusted as authorization.

## Failure and abuse analysis

| Condition | Expected behavior | Evidence |
|---|---|---|
| Provider flow is cancelled | Return to the same method screen with entered non-secret form state preserved | Widget and repository cancellation tests |
| Auth succeeds but profile creation times out | Missing-profile gate remains recoverable; retry reads current profile before attempting the idempotent transaction | Callable duplicate and timeout reconciliation tests |
| Two onboarding requests overlap | One transaction creates the profile; the other returns the same completed state without field drift | Functions overlap test |
| Existing provider owns the email | Do not reveal provider inventory or auto-merge. Explain that the user should sign in by the existing method, then link | Repository and widget collision tests |
| Link credential belongs to another UID | Preserve both accounts and current session; show a non-destructive recovery message | Linking boundary tests |
| Verification link opens after app restart | Restore the pending email locally or ask for it again, complete once, then clear it | Link lifecycle tests and device walk |
| Verification link is malformed, expired, or replayed | Firebase rejects it; remain signed out or gated with a new-link action | Focused link tests |
| App resumes while still unverified | One reload returns to the waiting state without repeated sends or polling | Lifecycle widget test |
| Password reset request is offline | Keep entered email, restore control, and say the message could not be requested | Repository and widget error test |
| SMS is requested repeatedly | UI cooldown and in-flight guards apply; Firebase quota, region, and anti-abuse controls remain enabled | Callback-state tests and dashboard launch checklist |
| Automatic Android SMS verification races manual entry | First accepted credential wins and later callbacks cannot sign in twice or replace another account | Controller concurrency test |
| User unlinks a provider during stale UI | Reload current provider data and refuse removal when it would leave no usable method | Repository state test |
| User becomes banned or deletion-pending after provider auth | Existing live private-profile and deletion gates fail closed before the shell | App-gate and callable authority regressions |
| Release config omits signing or provider setup | Release build or provider availability fails closed; the app never ships a broken visible method | Gradle/config contract tests |

## Security and privacy

- Do not log Firebase credentials, provider tokens, nonces, emails, phone numbers, dates of birth, or raw provider exceptions.
- Keep generic sign-in and reset copy resistant to account enumeration. Do not call provider-discovery APIs to reveal how an email is registered.
- Verify contact authority on trusted Firebase token state at both rules and callable mutation boundaries. UI gating alone is not evidence.
- Require explicit Apple account-linking consent. Never link accounts only because provider emails match.
- Keep OAuth state, nonce, callback scheme, package fingerprint, associated-domain, and redirect configuration platform-specific and reviewed.
- Delete or expire device-local magic-link email state after completion, cancellation, sign-out, or a bounded age.
- Phone/SMS remains disabled until user disclosure, permitted regions, quota/billing controls, test numbers, and App Check or platform anti-abuse configuration are verified.
- Existing account deletion continues to act on the Firebase UID and therefore covers linked sign-in methods without a second Chants data-deletion path.

## Performance and cost

- No background verification polling. Refresh only on screen entry, app resume, incoming link, or explicit user action.
- One provider flow or SMS send may be in flight per screen. Buttons remain disabled only for that bounded operation.
- Email verification and reset resend controls use a visible cooldown. Cooldown is UX protection, not the security boundary.
- Phone/SMS production enablement requires an explicit regional allowlist, Firebase quota review, billing alert, and observed first-cohort volume. Source implementation does not claim cost safety.
- Onboarding performs at most one Auth refresh, one idempotent callable, and the existing profile stream reconciliation on completion.
- Adding provider SDKs requires dependency, binary-size, native-build, license, and update-path review. Remove a provider dependency if the method is not enabled for launch.

## Verification plan

| Claim | Check | Expected evidence |
|---|---|---|
| Auth domain behavior | Focused Dart repository/controller tests with fake Firebase boundaries | Success, cancellation, collision, verification, link, unlink, resend, timeout, and error mapping pass |
| Server onboarding authority | Functions tests and TypeScript build | Verified token required, narrow input, duplicate and overlap convergence, private fields pinned |
| Direct-write and verified-contact authority | Java-backed Firestore and Storage emulator suites | Unverified and hostile identities fail; existing verified identities retain intended access |
| App gate and automatic return | Focused widget tests with lifecycle and user-stream changes | Missing profile, unverified, verified-on-resume, banned, deletion, and policy states select the correct screen |
| Interface quality | Widget semantics plus targeted goldens | Required screens pass representative iOS, Android, narrow, and 1.8x states with direct semantic assertions outside tolerance |
| Existing behavior | Full Flutter, Functions, rules, seed, analysis, and governance suites | No regression in established authority or product journeys |
| iOS native graph | Simulator build with non-secret local Firebase config | App target compiles with intended capabilities; real providers still require configured-device walk |
| Android source graph | Clean CI `flutter build apk --debug` with non-secret compile fixture | APK exists, package ID is `com.chants.chants`, and exact source SHA is recorded |
| Android local behavior | `flutter doctor`, local debug build, Play emulator or physical-device walk | Requires Android SDK installation and configured test project |
| External provider readiness | Operator checklist against Firebase, Apple, Google, Meta, Hosting, APNs, Play, and domain dashboards | Each visible method is enabled, callback and fingerprint match, and test account succeeds without production mutation claims |

## Local implementation evidence

- All three source blocks are implemented in the isolated worktree without provider-console, live Firebase, SMS, signing-key, deployment, commit, push, merge, or store actions.
- The final local matrix passes 454 Flutter tests, 142 Cloud Functions tests, 42 seed tests, zero-issue Flutter analysis, rules TypeScript compilation, and project-memory, writing-style, native-contract, governance-regression, and diff checks.
- The Java-backed Firestore and Storage suites remain clean-runner only because this machine has no usable Java runtime.
- The final iOS source state builds `Runner.app` for the simulator without code signing and reports bundle ID `com.chants.chants`. This is compile evidence, not provider, device, or distribution evidence.
- This machine has no Android SDK or `adb`. The new Android clean-runner job owns the first APK compile and application-ID proof after commit and push are separately authorized.

## Rollout and recovery

1. Merge compatible rules and `completeOnboarding` Function before enabling a client that can create provider-only Auth accounts.
2. Keep every new provider hidden through injected availability until its dashboard, native, policy, callback, and device checks pass.
3. Enable Google and Apple first, then magic link and Facebook, then phone/SMS after the additional consent and cost gates.
4. Roll back a provider by hiding its entry point while preserving already linked Firebase identities. Do not unlink users in bulk.
5. If onboarding admission fails, keep existing signed-in profiles working, leave incomplete new accounts behind the missing-profile gate, and forward-fix or disable new provider entry.
6. If Android build or signing fails, keep Android unreleased. iOS and backend behavior remain separately versioned; no source gate claims store readiness.
7. Deployment, dashboard changes, domain association, credentials, signing, live SMS, store submission, and production observation require separate explicit authorization.

## Alternatives rejected

- **One giant form with every method visible:** too much cognitive load and does not explain why Chants is worth joining.
- **FirebaseUI replacement:** the Flutter product already has a custom design system and FirebaseUI does not remove the project-specific profile, age, policy, deletion, and provider-availability contracts.
- **Client-only profile creation for every provider:** repeats the existing partial-signup failure and cannot authoritatively bind verified-contact state to profile admission.
- **Automatic account merging by email:** risks joining the wrong identities and conflicts with explicit Apple linking consent.
- **Store the date of birth:** unnecessary personal data for the existing 17-plus gate.
- **Enable phone at the same time as source implementation:** obscures SMS cost, regional availability, consent, and real-device abuse checks.
- **Keep Android release on the debug key:** makes an apparently successful release build unfit for Play delivery.
- **Persist a favourite club during onboarding before it changes product behavior:** creates dead personal data. The first-destination choice provides immediate relevance without pretending personalization exists.

## External gates and open decisions

The source block does not authorize or complete these actions:

- Firebase console provider enablement and email-enumeration protection review.
- Apple Developer Sign in with Apple setup, key, service ID, consent wording, and associated domains.
- Google OAuth consent, Android SHA-1/SHA-256 registration, and iOS URL configuration.
- Meta developer app, Facebook Login settings, privacy policy, data deletion URL, and app review if required.
- Firebase Hosting auth link domain, authorized domains, iOS Universal Links, Android `assetlinks.json`, and deployed callback verification.
- Phone regions, test numbers, APNs, Play Integrity/reCAPTCHA, quota, billing alert, and live SMS.
- Android SDK installation on this Mac, physical device or emulator setup, upload key generation, Play App Signing, Play Console, and store release.

## Requested approval

Approve with:

`approved V1 launch authentication, onboarding, and Android readiness spec`

Approval authorizes local source, tests, native project configuration without secrets, durable records, and clean-runner CI preparation on `codex/v1-auth-onboarding-android`. It does not authorize provider-console changes, live Firebase changes, SMS sends, credentials, signing-key creation, deployment, commit, push, merge, or store release.
