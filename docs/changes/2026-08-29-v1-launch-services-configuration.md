# V1 launch services configuration

## Change identity

- **Approval:** Andrew approved `V1 launch services configuration spec` on 2026-08-29.
- **Starting head:** `ba5a47cdffd9a7ee0c7b1c3af30f4ef1f500ff75`, documentation-only PR 19 head.
- **Scope:** Source-ready domain association, native Crashlytics completion, bounded abandoned-media cleanup, privacy-safe retained-job monitoring, and the approved reversible Firebase and Google Cloud configuration.
- **Excluded authority:** No authentication provider exposure, SMS send, magic-link send, private-key upload, Play Integrity terms, App Check enforcement, Cloudflare DNS write, production deployment, billing disablement, seed write, signing, store action, or release.
- **Durable decision:** `docs/decisions/024-staged-launch-integrity-controls.md`.

## Production baseline

The read-only audit found one Firebase project on Blaze with both mobile app records active. Email and password was the only enabled authentication provider. The custom domain was not authorized or hosted. Both apps were unregistered in App Check, and Firestore and Authentication were unenforced. Crashlytics had Flutter handlers but no complete native delivery path or received report. Cloud Monitoring had no notification channel or policy, and Cloud Billing had no project budget.

Only nine inherited Functions were deployed. Current source exports more Functions and owns public Hosting rewrites that depend on them, so deploying Hosting alone would produce an incompatible public boundary. This block prepares and tests the association artifacts but does not deploy Hosting, Functions, rules, indexes, Storage rules, or a client.

## Domain association boundary

`hosting/.well-known/apple-app-site-association` names only `J7V95LBCWR.com.chants.chants` and the four native path groups already present in iOS entitlements or the Android manifest. Firebase Hosting no longer excludes every dotfile directory and supplies reviewed JSON and cache headers for both association endpoints.

Android remains deliberately absent. `scripts/generate-android-assetlinks.mjs` accepts only package `com.chants.chants` and one or more uppercase SHA-256 fingerprints. The launch-service check validates a generated file if one exists, but the repository contains no `assetlinks.json` until Andrew supplies the production or Google Play App Signing fingerprint.

The local Hosting emulator returned 200 JSON for Apple association and 404 for Android association. This proves the source manifest and absence contract only. HTTPS, no-redirect delivery, custom-domain routing, Apple CDN pickup, Android verification, and device opening remain deployment and device gates.

## Crashlytics boundary

Android applies Crashlytics Gradle plugin 3.0.8 and Google Services plugin 4.5.0, matching current official setup guidance and the existing AGP 8.11.1 boundary. iOS enables FlutterFire symbol upload and adds a release-only CocoaPods-backed upload phase. Debug and simulator builds skip the phase, while a release archive fails clearly if the Crashlytics pod script or FlutterFire CLI is missing.

The existing Flutter framework and asynchronous fatal handlers remain the only runtime telemetry additions. This block adds no Analytics or Performance Monitoring package and no user content, email, handle, report text, media URL, or credential metadata. A first received and symbolicated test report still requires the controlled device walkthrough.

## Bounded cleanup and backlog signal

`cleanupAbandonedPerformanceDraftsJob` runs daily in `europe-west2`. It reads at most 100 drafts in `awaiting_upload` or `cleanup_pending` whose `createdAt` is at least 24 hours old. A transaction rechecks schema, owner, state, age, and exact `performance-staging/{ownerId}/{draftId}/source` identity before changing the state to `cleanup_pending`. Storage removal precedes final document deletion. Storage or finalization failure retains the claim for a later idempotent run. Invalid rows produce an aggregate error and are never guessed or removed.

`monitorOperationalBacklogsJob` runs every 15 minutes in the same region. Account-deletion jobs older than 30 minutes without progress and media-deletion jobs older than 15 minutes produce one structured error signal. Each collection query stops at 101 rows, reports at most 100 plus a more-than-limit bit, and emits no document ID, UID, media path, user content, or raw payload.

The cleanup query adds the required `performanceDrafts.state + createdAt` composite index. Deployment order therefore remains indexes and compatible server boundaries before scheduled work is expected to succeed.

## Verification evidence

- The new Functions test first failed to compile because `functions/src/operations.ts` did not exist. After implementation, the full Functions suite passed 146 tests.
- Focused tests cover the 100-row limit, exact state and age selection, malformed path refusal, Storage failure recovery, duplicate retry, the two stale-age boundaries, count capping, and a privacy-safe log object.
- The launch-service contract and its mutation tests pass. Removing the Apple identity or Crashlytics plugin and adding an invalid Asset Links file each makes the guard fail.
- Firebase Hosting emulator probing serves the Apple file with the reviewed content type and preserves Android 404.
- TypeScript production build, native project contract, Xcode project parsing, and diff integrity pass.
- The full Flutter suite passed 465 tests, including two regressions for the previously unrecognized server-owned cleanup state. Static analysis remains clean.
- The iOS simulator build passed locally and its built bundle reports `com.chants.chants`. Android cannot compile locally because this machine has no Android SDK, so replacement clean-runner CI remains required.
- Seed passed 42 tests and typecheck. Rules TypeScript passes, but Java is absent locally, so the 165 Firestore and Storage assertions remain a clean-runner gate.
- Governance, staged-boundary, exact-head clean-runner, and remaining live-setting evidence is recorded separately as it completes. No incomplete gate is claimed here.

## Live configuration state

The approved reversible settings are recorded only after each console value is saved and re-read:

| Setting | Intended state | Current evidence |
|---|---|---|
| Firebase Auth authorized domains | Add `chantsfc.com` and `auth.chantsfc.com` | Saved and re-read as custom authorized domains on 2026-08-29 |
| iOS App Check | Register App Attest for team `J7V95LBCWR`, default TTL, unenforced | Saved and re-read as Registered with a one-hour TTL on 2026-08-29; enforcement remains off |
| Monitoring notification | One owner-confirmed email channel | Saved and re-read as `Chants owner alerts` on 2026-08-29; the private destination is withheld from repository records |
| Server error policy | Alert on production Function or Cloud Run failures | Enabled and re-read as `Chants production server errors`; two OR conditions use the aggregate `chants_server_error_events` metric for Cloud Run and Cloud Functions |
| Retained-job policy | Alert on `stale-deletion-jobs` structured errors | Enabled and re-read as `Chants stale deletion jobs`; the aggregate `chants_stale_deletion_jobs` metric carries no document identity or payload |
| Billing budget | USD 25 monthly, actual 50, 75, 90, 100 percent, forecast 100 percent | Saved and re-read as `Chants monthly launch budget`, linked to `Chants owner alerts`, alert-only, and without Pub/Sub automation or spend enforcement. The console records `All projects (1)` because Chants is the billing account's sole linked project; adding another project requires a scope review |

## Deliberately deferred

- Android App Check and Asset Links wait for the trusted production or Google Play App Signing SHA-256 fingerprint.
- Google authentication waits for a production SHA-1 fingerprint and physical Android proof.
- Apple, Facebook, phone, and magic-link enablement wait for their credential, policy, callback, quota, domain, and device gates.
- DeviceCheck fallback waits for Andrew's Apple P8 key and Key ID through an approved credential path.
- App Check enforcement waits for valid traffic from both release apps and a 1 to 2 week observation window.
- Cloudflare DNS, custom-domain attachment, and Hosting deployment wait for authenticated access and a separate compatible server deployment approval.
- Automatic billing disablement and performance-admission pause automation require a separate recovery design.
- Monitoring policy delivery, closure notification, and budget-message delivery remain unobserved until a controlled signal or real threshold event occurs.
- Content policy, privacy, terms, moderation response target, production IAM, backup or restore, remaining verified seed, signing, store work, and release remain open.
