# Change spec: V1 launch services configuration

**Status:** Implemented and locally verified; exact-head clean-runner verification pending
**Updated:** 2026-08-29
**Risk lane:** Lane 2 authentication, public-domain, telemetry, operational, and cost configuration
**Base:** `ba5a47cdffd9a7ee0c7b1c3af30f4ef1f500ff75`, now contained in documentation merge `9c6286abe08856642e01f1466b6848411f7a586f`
**Approval:** Andrew approved `V1 launch services configuration spec` on 2026-08-29.

## Outcome

- **Problem:** Chants is source-ready for provider entry, App Check, Crashlytics, public destinations, and creator video, but the corresponding production services are incomplete. Only email and password authentication is enabled. The custom domains are not authorized or hosted. Both mobile apps are unregistered in App Check. Crashlytics has client handlers but incomplete native setup and no received report. Cloud Monitoring has no notification channels or policies, and Cloud Billing has no project budget.
- **Desired state:** Complete every safe, reversible source and production-control step that does not depend on missing signing fingerprints, provider credentials, policy approval, production deployment, or device evidence. Keep all provider buttons fail-closed and all App Check products unenforced until their explicit release gates pass.
- **Review boundary:** Hosting association support, native Crashlytics integration, bounded operational cleanup and stale-job detection, exact configuration and recovery documentation, and the approved Firebase or Google Cloud settings listed below.
- **Non-goal:** No provider is exposed in the app, no SMS or magic link is sent, no App Check enforcement is enabled, no billing account is disabled, no production rules, Functions, Hosting, client, seed, store, or signed artifact is deployed, and no private credential is committed.

## Read-only production baseline

The 2026-08-29 audit established these facts without changing external state:

1. Firebase project `chants-f95b4` is on Blaze and has active Android `com.chants.chants` and iOS `com.chants.chants` app records.
2. Firebase Authentication enables email and password only. Its authorized domains are `localhost`, `chants-f95b4.firebaseapp.com`, and `chants-f95b4.web.app`.
3. Google, Apple, Facebook, phone, and email-link entry are disabled. The source keeps all five behind explicit compile-time flags.
4. `chantsfc.com`, `www.chantsfc.com`, and `auth.chantsfc.com` have no published A or CNAME answers. The zone uses Cloudflare nameservers, and the inspected browser session is not authenticated to Cloudflare.
5. The default Firebase Hosting site exists but has never been initialized or deployed. Current source rewrites depend on public Functions that are not among the nine Functions deployed today.
6. App Check shows both mobile apps as unregistered. Firestore and Authentication are unenforced. Source selects App Attest with DeviceCheck fallback on Apple and Play Integrity on Android release builds.
7. The Apple team ID is present in the signed native project as `J7V95LBCWR`. No DeviceCheck P8 key is available to this work. No Android release or Play App Signing SHA-256 fingerprint exists in the repository.
8. Crashlytics error handlers are active in Flutter source. The Android Crashlytics Gradle plugin is absent, iOS symbol upload is disabled in `firebase.json`, and the dashboard has not received its first report.
9. Cloud Monitoring has no notification channel or alert policy. Cloud Billing has no budget for this project. Current August cost and forecast were both zero at audit time.

## Source work

### 1. Domain association support

1. Stop excluding the exact `hosting/.well-known/` association directory while continuing to ignore unrelated dotfiles.
2. Add a valid `apple-app-site-association` file for `J7V95LBCWR.com.chants.chants`, limited to `/finish-sign-in`, `/chants/*`, `/performances/*`, and `/creators/*`.
3. Serve the Apple association file as JSON with a short operational cache. It must remain available over HTTPS with no redirect when the custom domains are later attached.
4. Add a deterministic Android association generator and validator. It must require package `com.chants.chants` plus one or more syntactically valid uppercase SHA-256 certificate fingerprints.
5. Do not commit or deploy an empty, debug-only, invented, or placeholder `assetlinks.json`. The production file remains blocked until Andrew supplies the release or Google Play App Signing fingerprint.
6. Add checks proving that the hosted paths and native manifest or entitlement paths agree.

### 2. Complete Crashlytics native integration

1. Apply the supported Android Crashlytics Gradle plugin and a compatible Google Services plugin version without changing application ID, release signing, or build variants.
2. Enable FlutterFire iOS debug-symbol upload and add the FlutterFire-managed Xcode upload phase through the CocoaPods path already owned by the project.
3. Keep user content, email, handles, raw report text, media URLs, and authentication credentials out of crash metadata.
4. Add a verification check that fails if the Flutter handler, Android plugin, iOS upload phase, or symbol-upload setting disappears.
5. Do not add Analytics or Performance Monitoring in this block. Crash reporting and operational alerting are the approved telemetry surface.

### 3. Bound abandoned media and retained-job detection

1. Add one scheduled, region-pinned worker that processes a bounded page of `awaiting_upload` performance drafts older than 24 hours. It deletes only schema-valid draft identities, relies on the exact-path deletion boundary for staged media, and is safe under duplicate delivery.
2. Never expire a `pending_review`, `approved`, or otherwise actively moderated draft through this cleanup path.
3. Add one scheduled, region-pinned monitor that detects account-deletion and performance-media-deletion jobs whose `updatedAt` has exceeded an approved age. It emits aggregate structured error facts only, with no UID, performance ID, path, user content, or raw payload.
4. Use a bounded query and a capped count. The monitor reports that more stale work exists without scanning an unbounded collection.
5. Test exact state selection, age boundaries, duplicate delivery, malformed rows, bounded paging, storage failure, and privacy-safe logging data.

### 4. Operational records and recovery

1. Update the runbook with the exact dashboards, alert purpose, healthy and degraded meanings, cleanup cadence, and recovery order.
2. Record live configuration separately from source readiness. A console save is not a device verification, and green CI is not deployed parity.
3. Add one completed change record and one durable decision for soft App Check rollout, operational job detection, and non-destructive cost control.
4. Keep credentials, notification addresses, raw production payloads, and provider secrets out of repository memory.

## Approved live configuration after source verification

These settings may be applied only after this spec is approved and each action-time confirmation is obtained where required:

1. Add `chantsfc.com` and `auth.chantsfc.com` to Firebase Authentication authorized domains. Do not enable email-link entry until `auth.chantsfc.com/finish-sign-in` is live and device-tested.
2. Register the iOS Firebase app for App Attest with team ID `J7V95LBCWR`, retain the default token TTL, and keep every Firebase product unenforced.
3. Create one owner-controlled Cloud Monitoring email notification channel after Andrew confirms the destination at action time.
4. Create alert policies for production Function or Cloud Run server errors and the privacy-safe stale-job monitor. Policies must identify project, service, and failure class without copying user payloads into notifications.
5. Create a project-filtered monthly Cloud Billing budget of USD 25 with actual-spend thresholds at 50, 75, 90, and 100 percent plus a forecast threshold at 100 percent. Link the confirmed Monitoring email channel. The budget is alert-only and does not cap spend.
6. Record exact external setting names, dates, and verification results without recording private contact details.

## Blocked or deliberately deferred configuration

| Surface | Reason it cannot be completed honestly now | Release trigger |
|---|---|---|
| Android App Check registration | Play Integrity requires the production or Play App Signing SHA-256 certificate fingerprint and provider terms | Production signing identity exists and Andrew confirms any terms at action time |
| Android `assetlinks.json` | The trusted fingerprint is not yet available | Same release or Play App Signing fingerprint is supplied and independently checked |
| Apple DeviceCheck fallback | Firebase requires a private P8 key, Key ID, and Team ID | Andrew supplies the Apple key through an approved credential path |
| Google authentication | Firebase and Android setup require production SHA-1 plus native and device proof | Release signing exists and Google sign-in passes on a physical Android device |
| Apple authentication | Provider credentials and Apple capability or callback parity are not yet verified | Apple provider facts are supplied and physical iOS proof passes |
| Facebook authentication | Meta app identifiers, callback, data deletion, and policy work are incomplete | Meta console and policy gates pass |
| Phone authentication | Regions, quotas, SMS cost, test numbers, consent, and device proof are incomplete | Approved phone launch gate and measured cohort plan exist |
| Magic email links | The authentication domain is not live or associated | Custom domain and cold-start device verification pass |
| Custom-domain DNS and Hosting association deployment | Cloudflare is not authenticated, and current Hosting rewrites reference undeployed public Functions | Andrew signs in to Cloudflare, then a separate compatible deployment approval covers Functions, Hosting, and verification |
| App Check enforcement | No valid production telemetry exists yet, and Android remains unregistered | Both release apps are registered and a 1 to 2 week beta window shows legitimate traffic is valid |
| Automatic billing disable | It can take the whole product offline and budgets do not provide a safe cap | A separately approved circuit-breaker design defines authority, recovery, and false-positive handling |

## Invariants

1. Missing configuration remains unavailable, never partially visible.
2. App Check registration and App Check enforcement remain separate actions.
3. An authorized domain does not by itself enable an authentication method.
4. Association files claim only real signed app identities and paths implemented by the native clients.
5. Operational telemetry contains no user content, raw identifiers, credentials, or signed media URLs.
6. Cleanup is bounded, state-specific, exact-path, idempotent, and recoverable from failure.
7. Budget alerts notify; they do not claim to cap or automatically disable spend.
8. No live deployment is inferred from source changes or CI.

## Acceptance criteria

1. The source work above passes focused red-then-green tests, full Functions tests, Flutter tests and analysis where native inputs changed, native contract checks, governance checks, writing checks, and both clean native compile jobs.
2. A dry-run Hosting manifest includes the Apple association file and excludes any Android association file until a trusted fingerprint is supplied.
3. iOS and Android debug builds still use App Check debug providers. Release source still selects App Attest with DeviceCheck fallback and Play Integrity.
4. No App Check enforcement, provider flag, provider console, SMS, seed, deployment, signing, store, or release state changes accidentally.
5. The scheduled cleanup cannot select pending review or approved media and cannot exceed its recorded batch limit.
6. The stale-job monitor is capable of producing an alertable error without logging a document identity or payload.
7. Every live setting applied under this block is re-read from its owning console and recorded as configured, unverified on device, or blocked.
8. Authored prose contains no literal or encoded em dash.

## Verification plan

1. Add focused tests first and prove the meaningful source checks fail on the inherited state.
2. Run Functions typecheck and tests, Flutter tests and scoped analysis, Hosting manifest inspection, native project validation, CocoaPods resolution, Android debug compile, and iOS simulator compile.
3. Stage the intended handoff and run project-memory, writing-style, governance, and diff checks.
4. Apply only the approved live settings, one surface at a time, with before and after evidence.
5. Do not force a production crash. Complete the first-report and symbolication proof during the controlled device walkthrough with an explicitly temporary debug-only trigger or debugger action.
6. Do not enable enforcement until the later telemetry-window decision.

## Rollout and recovery

1. Keep this branch stacked on PR 19 and do not modify the dirty owner checkout.
2. Revert source changes if either native build or focused operational test fails.
3. Authorized domains can be removed if they are entered incorrectly. App Attest registration stays unenforced while corrected.
4. Disable an alert policy before deleting its notification channel. A budget can be edited or removed without changing service availability.
5. If cleanup misclassifies any state in testing, do not deploy it. If a deployed worker ever misclassifies a row, disable the schedule, preserve the row and media evidence, and forward-fix the predicate.
6. Package, push, deploy, or merge only under separate explicit authorization. Production deployment remains outside this spec.

## References

- Firebase Crashlytics for Flutter and Android setup, checked 2026-08-29.
- Firebase App Check Flutter providers and enforcement guidance, checked 2026-08-29.
- Apple associated domains and Android Digital Asset Links documentation, checked 2026-08-29.
- Firebase Hosting deployment and response-header configuration, checked 2026-08-29.
- Google Cloud Monitoring notification-channel and alerting guidance, checked 2026-08-29.
- Google Cloud Billing budget guidance, including the fact that an alert-only budget does not cap spend, checked 2026-08-29.

## Excluded authority

Approval of this specification will authorize the bounded source implementation and the five live configuration items listed under "Approved live configuration after source verification." It will not authorize provider enablement, user-visible provider flags, SMS sends, private-key upload, Play Integrity terms, App Check enforcement, Cloudflare DNS changes, Hosting or Functions deployment, billing disablement, seed writes, signing, store actions, or release.
