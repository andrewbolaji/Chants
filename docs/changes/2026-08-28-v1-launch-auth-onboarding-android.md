# V1 launch authentication, onboarding, and Android readiness

## Change identity

- **Approval:** Andrew approved `V1 launch authentication, onboarding, and Android readiness spec` on 2026-08-28.
- **Starting head:** `8b457d8b0fd959a7dc54222f8f95856c77b2bed6`, exact PR 17 post-review correction head.
- **Scope:** One source block for supporter-first entry, verified identity, recoverable onboarding, requested provider integrations, explicit linking, Android source readiness, native compile fixtures, and clean-runner build jobs.
- **Excluded authority:** No provider dashboard change, live Firebase mutation, SMS send, domain deployment, credential, signing-key creation, store action, commit, push, merge, deployment, or release.
- **Durable decision:** `docs/decisions/023-verified-authentication-and-server-onboarding.md`.

## Product outcome

The launch surface now introduces the actual product before presenting credentials. It names Watch, Learn, and Create; keeps Apple, Google, and email primary; places Facebook and phone under More; offers a magic link inside email; and keeps every unconfigured provider absent. Email and password remain supported and password reset remains visible.

An authenticated account now passes through deletion recovery, contact verification, missing-profile onboarding, current policy, and then the product shell in that order. New users choose a display name, confirm the 17-plus boundary and current policy, and choose Stage, Clubs, or Songbook as their first destination. The date of birth is evaluated in memory and never sent to Firebase.

## Authority and persistence

`completeOnboarding` is the only initial profile writer. It derives UID and verified identity from callable auth, parses an exact three-field payload, rejects deletion and incoherent existing authority, and writes the private profile plus deterministic consent audit in one transaction. Duplicate completion is idempotent and cannot reset role, ban, report, deletion, or creator fields.

Protected callables, Firestore rules, and the performance-staging Storage rule now require a verified email, verified phone, or trusted Apple, Google, or Facebook identity. A linked federated identity remains authoritative when the same account later signs in by password. Direct profile create is denied.

Firebase Auth remains the credential and linked-provider source. Sign-in methods supports deliberate link and unlink, refuses removal of the last method, refreshes live provider state, and reports collisions without merging or deleting either UID. Existing Chants data remains keyed by the unchanged Firebase UID.

Magic-link pending state stores only email, request time, and optional current UID in one versioned device record. The binding is persisted before the email request, expires after one hour, rejects future, partial, expanded, or malformed state, protects a signed-in account from an unrelated sign-in link, and clears on completion, cancellation, or terminal invalidity. Phone entry uses international format, explicit Google processing disclosure, resend cooldown, manual code entry, Android auto-verification, and one shared credential claim across resends. An abandoned attempt ignores a later unused automatic credential.

## Native and delivery boundary

Android keeps `com.chants.chants`, declares Internet access, presents the Chants label, and handles the approved HTTPS auth, chant, performance, and creator paths. Release no longer uses debug signing. A release task fails unless an ignored operator `key.properties` supplies all four signing values. The checked-in example contains placeholders only.

iOS carries Sign in with Apple plus `auth.chantsfc.com` and `chantsfc.com` associated-domain entitlements on the Runner target. The CocoaPods graph adds app links, Firebase Auth, Facebook Auth, Google Sign-In, and device preferences. Google Sign-In 9.2 requires `GTMSessionFetcher` 3.5.0, which also satisfies the existing Firebase Storage range.

Android and iOS clean-build jobs copy obvious non-secret Firebase compile fixtures. The Android job builds and inspects the APK application ID, records its digest, and retains the artifact for seven days. The iOS job resolves the lockfile, builds the simulator app without signing, and inspects its bundle ID. These fixtures prove source integration only and cannot authenticate against production.

Provider buttons stay disabled in release source until the corresponding operator flag is set. Actual Firebase provider enablement, Apple and Google credentials, Meta callback and deletion configuration, phone regions and quotas, APNs and Android fingerprints, hosted association files, App Check, signing, and device evidence remain launch gates.

## Failure and recovery behavior

- Verification refreshes on app resume or explicit action, never through a polling loop.
- A missing profile opens onboarding and retries the idempotent callable instead of spinning indefinitely.
- Password reset swallows only Firebase's unknown-account result. Network and quota failures retain the email and do not claim a message was sent.
- Provider cancellation returns to the same screen. Safe mapped text replaces raw provider exceptions.
- A collision retains both accounts and instructs the user to authenticate through the owning method before linking.
- An underage new account cannot enter the product and receives best-effort recent-account deletion plus sign-out recovery.
- Deletion recovery remains ahead of every new gate and keeps its inherited durable authority.
- Missing native or dashboard setup keeps a provider invisible. Missing Android release signing fails the build.

## Verification record

Local evidence at the uncommitted implementation state:

- 142 Cloud Functions tests pass, including exact onboarding, overlapping completion, explicit Firestore transaction retry, verified contact, current federated provider, linked federated identity, and rejection cases.
- 454 Flutter tests pass, including focused auth, onboarding, app-gate, atomic magic-link persistence, reset, Apple cancellation, cross-resend phone races, stale linking sessions, provider hierarchy, and 1.8x narrow layouts.
- Flutter static analysis passes with the non-secret local Firebase options fixture.
- Firestore and Storage rule tests type-check. Java-backed emulator execution remains clean-runner work because Java is absent locally.
- Native contract, governance regression, writing-style, and diff checks pass.
- CocoaPods resolves 18 direct dependencies and 56 total pods. The final local iOS source builds `Runner.app` for the simulator with bundle ID `com.chants.chants`.
- Android local compilation remains unavailable because this machine has no Android SDK. No SDK installation was authorized.

## Deliberately unchanged or deferred

- No account data merge, passkey, MFA enrollment, username login, cross-device magic-link pending store, or provider-discovery API is added.
- No production provider is enabled, no phone message is sent, and no association or Firebase change is deployed.
- Creator platform, Stage, chant submission, Songbook, report, moderation, deletion, public URL, and seed behavior are changed only where verified-contact authority must apply consistently.
- Final privacy and content policy, store disclosures, credentials, provider branding approval, real-device walks, production signing, deployment, seeding, and release remain outside this source block.
- The next independent review should inspect this block together with the remaining pre-freeze source work, in line with Andrew's requested consolidated review cadence.

## Post-review addendum

Exact PR 18 head `db40f42` passed all eight clean-runner jobs in run `33206487262` and received the consolidated independent review. The review found no source-freeze blocker and identified nine bounded recovery, authority, copy, throttling, persistence, and touch-target findings. Andrew approved their correction. The completed local result and its replacement-CI gate are recorded in `docs/changes/2026-08-28-post-auth-independent-review-corrections.md`; decision 023 carries the durable state-machine consequences.
