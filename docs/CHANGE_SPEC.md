# Change spec: V1 Lane 3 production rollout packet

**Status:** Gates 0 through 2 completed with readback. Gate 3 ran four separately approved core openings on 2026-09-02. All returned safely to maintenance, most recently generation 9 with destructive workers false. The approved explicit-engine correction removed the reproducible pre-Dart startup crash on the paired ProMotion iPhone. Repeated cold launches, force quit, background, resume, the final 2.8-second presentation, visible acceptance progress, and a truthful maintenance denial now have owner-observed device evidence. The first independent review found one policy-recovery defect, four documentation corrections, and several bounded guard improvements. Andrew approved and Codex implemented the combined correction. The independent closure review found no blocking or correction-required defect. Its four low findings are also closed inside the approved recovery and evidence boundary, and the complete corrected local matrix passes. The closure is packaged in PR 33. Its first exact-head clean-runner attempt measured 2.05 percent policy-golden drift from cross-platform font-edge antialiasing with identical geometry. A test-local 2.2 percent allowance now reflects that runner evidence, while separate widget tests enforce the screen semantics. Replacement exact-head clean-runner CI remains. No production retry or Gate 4 is approved.

**Owner:** Andrew, through ThunderRiver Tech LLC

**Lane:** 3, production recovery, containment, backend cutover, and controlled admission

**Source baseline:** `main` at `88ce483f1ea18df6a7a2b4e790803773164ac9a5`, tree `c3fb5fa80d35b0b029c0e94212ef484d74b77303`

**Clean-runner evidence:** fresh exact-main run `33562025155` completed all eight jobs successfully at exact source `88ce483f1ea18df6a7a2b4e790803773164ac9a5`.

**Authority exercised:** Andrew approved `V1 Lane 3 production rollout packet`, authorizing Gate 0 only. After reviewing its sanitized receipt and exact next scope, Andrew separately approved `V1 Lane 3 Gate 1 recovery and containment` on 2026-09-01. After Gate 1 closed, Andrew separately approved `V1 Lane 3 Gate 2 core cutover while closed`. After Gate 2 closed, Andrew separately approved `V1 Lane 3 Gate 3 first core opening`. After that opening closed, Andrew confirmed the phone was ready and separately approved `V1 Lane 3 Gate 3 owner walkthrough retry`. After confirming he missed that attempt's tap instruction and was watching, Andrew separately approved `V1 Lane 3 Gate 3 immediate owner walkthrough retry`. Andrew then separately approved `V1 Lane 3 Gate 3 30-second countdown owner walkthrough retry` and committed to tap without waiting for another prompt. Each Gate 3 authority was consumed by its opening, observation, and default close. None authorizes another retry, Gate 4, media infrastructure, destructive-worker activation, schedules, Hosting, DNS, App Check enforcement, signing, store action, or release.

## Outcome

Bring the production backend from the recovered July state to the reviewed V1 source without overlapping blind report writers, exposing media or destructive work early, losing the ability to recover, or treating an old bundle as a safe blanket rollback.

The first live objective is core-only private verification. Media admission, destructive workers, schedules, public widening, Hosting, DNS, and store release remain closed until their later gates.

## Gate 0 sanitized production receipt

Gate 0 observed the exact production project from 2026-09-01T22:09:36Z through 2026-09-01T22:18:59Z. The detailed per-writer, per-key, and principal worksheet is local, ignored, mode 600, and intentionally excluded from Git, chat, screenshots, and CI.

- project `chants-f95b4`;
- nine active July Node 20 Gen 2 Functions in `europe-west2`, all using one legacy runtime account class, while source exports 48 Node 22 Functions;
- six event Functions, three HTTPS or callable Functions, nine matching Cloud Run services, six Eventarc triggers, six Pub/Sub topics, and six subscriptions;
- Firestore `(default)` in Native mode and `nam5`, with point-in-time recovery and database delete protection disabled, no backup schedule, and no backup;
- a July Firestore rules release and only two of the 16 required composite indexes, both ready;
- created-only report handlers that blindly increment counts, while current source uses written handlers and ground-truth repair, plus a live merge endpoint without the reviewed source stop;
- no `operationalControls/v1` document;
- two Storage buckets with nine objects by metadata-only listing, no Firebase app-media bucket, and no user object downloaded;
- Cloud Scheduler, Firebase Storage, Secret Manager, and Billing Budgets APIs disabled; Eventarc, Cloud Run, IAM, IAM Credentials, Artifact Registry, Pub/Sub, Cloud Storage, and App Check APIs enabled;
- 20 project IAM bindings, no public project binding, no IAM deny policy, two public Cloud Run invoker policies, and two enabled user-managed service-account keys requiring the private dispositions below;
- three service accounts, but no dedicated `chants-v1-runtime` account, so deployer `iam.serviceAccounts.actAs` cannot yet be tested against that target;
- Firebase active with one iOS app, one Android app, no web app, email/password signup enabled, phone and anonymous disabled, no enabled external provider, no Auth blocking Function, and exactly one enabled verified password account;
- iOS App Attest and Android Play Integrity provider configurations present, while Firestore and Authentication App Check enforcement remain off;
- two enabled Monitoring alert policies, two log metrics, and one enabled email notification channel whose delivery verification metadata was not returned;
- billing enabled, but the disabled Billing Budgets API blocked a fresh budget readback with `SERVICE_DISABLED`;
- 192 chants, four comments, one report, one profile, and zero comment reports, creator profiles, performances, drafts, deletion jobs, cleanup jobs, update suggestions, follows, and notifications; and
- one Hosting site, with no Hosting or DNS mutation in Gate 0.

The private worksheet maps all nine live writers, all 48 source exports, and both user-managed keys. One current key matches the protected ignored local rollout credential and is retained only as a temporary recovery, control, and repair path. The other key needs owner or workload proof; if it is unused, Gate 1 may disable and observe it, but deletion stays outside Gate 1. These observations are dated evidence, not continuing permission. Every approved mutation must re-read its exact target immediately before action.

## Source release shape

- `functions/src/index.ts` exports 48 Functions.
- General runtime: CPU 1, 256 MiB, 60 seconds, minimum 0, maximum 3, concurrency 20.
- Serial workers: 512 MiB, 300 seconds, maximum 1, concurrency 1.
- Media validation: 512 MiB, 60 seconds, maximum 1, concurrency 1.
- Operational monitor: maximum 1, concurrency 1.
- Dedicated runtime identity: `chants-v1-runtime@chants-f95b4.iam.gserviceaccount.com`.
- The private operational-control contract is schema version 1, a positive increasing generation, mode `maintenance`, `core`, or `media`, and Boolean `destructiveWorkersEnabled`.
- Missing, unreadable, malformed, or invalid control closes protected admission.
- `media` is invalid unless destructive workers are enabled.
- Every transition increases generation. An earlier generation is never reused because it could revive an unexpired grant.
- Reconcilers and monitoring may drain while admission is closed. An admitted invocation is not cancelled by a later control change.
- `mergeChants` remains disabled.

## Included

1. Refresh the read-only production inventory against exact source and preserve only sanitized evidence in Git.
2. Build a private worksheet for resource locations, recovery, IAM, keys, old writers, deployer authority, cost exposure, and the exact intended command sequence.
3. Prove a usable recovery surface before cutover.
4. Isolate or retire old writers and overly broad credentials before they can race the reviewed release.
5. Establish the initial closed operational control, required indexes, and reviewed rules.
6. Deploy the reviewed Functions in bounded named groups while admission remains closed.
7. Replace the two report triggers without overlap, then repair and read back report state.
8. Open core admission for a time-bounded private smoke test, observe it, and return to maintenance by default.
9. Produce a privacy-safe receipt that makes every live action, result, stop, and recovery step independently reviewable.
10. Update the command-center regression so it requires the exact current source, all four completed Gate 3 observation-only attempts, maintenance generation 9, and an explicit Gate 4 hold.

## Excluded

- Media admission, media upload testing, destructive-worker activation, and scheduled jobs.
- Public or broad user access, Hosting, DNS, public policy publication, App Check enforcement, store changes, signing, submission, and release.
- A blanket redeploy of the July backend.
- Restoring production data into the default database without a new exact approval.
- Re-enabling `mergeChants`.
- Creating a staging environment as an improvised substitute for the approved production gates.
- Logging credentials, private key IDs, raw user data, account emails, device identifiers, or complete IAM bindings in repository records.

## Approved post-iOS startup independent review correction

Andrew approved `post-iOS startup independent review correction spec` on 2026-09-02. This correction remains inside the current client and documentation boundary and authorizes no production or external mutation.

1. End the policy acceptance busy state after a successful callable response instead of depending indefinitely on the profile listener. Add a bounded client wait so a stalled request restores the action and explains the available retry and support path.
2. Keep Other options reachable while acceptance is in flight. Help and Support remain usable; account mutation actions may remain disabled only during the bounded in-flight request.
3. Distinguish maintenance, authentication, account-state, missing-profile, internal-service, and likely connectivity failures with accurate user copy.
4. Add regression coverage for successful-callable recovery, stalled-callable timeout, secondary-action access during saving, error mapping, and the app-level reduced-motion launch bypass.
5. Strengthen the iOS source contract around the lifecycle-forwarding order, the Boolean ProMotion plist value, and exclusion of the obsolete Main storyboard from the packaged resource phase without deleting the source file.
6. Correct the stale Gate 3 generation and attempt counts, the rollout change record, and the reproducible source-contract test count.
7. Record the successful final physical-iPhone presentation check and the independent review honestly. Keep verified, reviewed, packaged, merged, and production-open states distinct.
8. Preserve the current golden tolerance until exact-head CI exercises it. Adjust it only from measured clean-runner evidence, never preemptively.
9. Package every required tracked source, test, golden, script, and change record together. Staged governance and writing-style checks must pass before commit.

## Invariants

1. Production project identity and every target resource are re-read immediately before action.
2. No live mutation occurs from a dirty checkout or a source identity different from the reviewed exact commit.
3. Protected admission is closed before and throughout dependency setup and cutover.
4. Old and new blind report writers never overlap.
5. Core opens before media, and media never opens while destructive workers are false.
6. Schedules remain held in this packet.
7. No destructive action runs without a tested forward-recovery path, exact target, owner, and stop condition.
8. Production readback, not command exit alone, proves success.
9. Failures close admission and preserve evidence. They do not trigger a blanket old-backend rollback.
10. Private identifiers and credentials stay in the private worksheet, never in Git, chat, screenshots, or CI logs.

## Approval gates

Each gate stops for Andrew's explicit approval. Completing one gate does not authorize the next.

### Gate 0: fresh inventory and private worksheet

Completed read-only after Andrew's packet approval:

1. Confirm exact source commit, clean tree, toolchain, Firebase project alias, authenticated principal, and billing project.
2. Re-read Functions, trigger types, regions, runtime versions, service accounts, ingress, IAM invokers, and resource caps.
3. Re-read Firestore location, rules release, indexes, database protections, backups, and current collection counts relevant to report repair and deletion.
4. Re-read Storage buckets, locations, rules, lifecycle, retention, and object counts without downloading user content.
5. Re-read Scheduler, Eventarc, Pub/Sub, Artifact Registry, Secret Manager, Auth providers, authorized domains, account count, App Check, alerts, and budget state.
6. Privately enumerate each legacy writer, user-managed key, deployer principal, and proposed disposition.
7. Compared the fresh state with this packet. The Android App Check registration, absent dedicated runtime identity, and API-state differences are incorporated into Gate 1 below rather than concealed.
8. Produced the sanitized receipt above and the ignored private worksheet. No live mutation occurred.

### Gate 1: recovery and containment prerequisites

Completed under Andrew's separate exact approval. Gate 1 included:

1. Re-read project identity, authenticated principal, database size, billing linkage, alert channel, and current budget. If a fresh budget read still requires enabling the Billing Budgets API, that service enablement is an explicit Gate 1 mutation and must be read back before proceeding.
2. Apply only the approved Firestore recovery protections: enable point-in-time recovery and database delete protection, then record when usable coverage begins. Do not claim a full recovery window immediately.
3. Create a 30-day retained export in the approved existing recovery location, then rehearse restoration into an isolated named database. A successful export alone is not restore proof. Do not restore into `(default)`.
4. Create the absent dedicated V1 runtime service account. Grant only the reviewed runtime roles and an account-scoped deployer `iam.serviceAccounts.actAs` path, then verify effective permission privately. Do not use a project-wide Editor or Token Creator substitute.
5. Apply the private key dispositions exactly. Keep the locally matched key temporarily as the recovery, control, and repair credential. Prove the second key has no owner or workload; if unused, disable it and observe. Do not delete either key in Gate 1.
6. Prove every legacy writer's intended disposition from the private worksheet. Do not delete or replace a live Function in Gate 1; writer cutover remains Gate 2.
7. Set the initial control to `maintenance`, generation 1, `destructiveWorkersEnabled: false`, only if the document is still absent and the exact plan matches current state.
8. Create the 14 missing indexes and wait until all 16 required indexes are ready.
9. Publish reviewed Firestore rules while protected admission is closed, then execute exact hostile and allowed-path checks.
10. Keep the app-media bucket absent. Its immutable location, Storage rules, lifecycle, cost, and creation require a separate explicit approval before media dependency setup.
11. Present recovery, containment, index, rules, IAM, key, budget, cost, and readback evidence before Gate 2.

### Gate 1 sanitized production receipt

Gate 1 executed from the clean exact source baseline and stopped before Gate 2. Exact principals, key identifiers, recovery resource names, database names, commands, and complete bindings remain only in ignored mode-600 receipts.

- Billing remained enabled. The Billing Budgets API was enabled under Gate 1, and a fresh read confirmed one USD 25 monthly launch budget with actual alerts at 50, 75, 90, and 100 percent plus a forecast alert at 100 percent. Two alert policies and one enabled email channel remain present.
- Firestore held 1,968,369 bytes, or 0.001833 GiB, far below the approved stop thresholds. Point-in-time recovery and database delete protection are now enabled. Coverage begins only from the recorded enablement time and does not imply a pre-enable or immediately complete seven-day window.
- A dedicated US recovery bucket uses Standard storage, uniform bucket access, enforced public-access prevention, 30-day unlocked retention, a 30-day delete lifecycle, and zero soft-delete retention. The completed export contains nine objects and 283,548 bytes.
- The export was imported into an isolated named `nam5` database. Twelve top-level collections and 849 documents matched the source count exactly, with zero mismatch. The isolated database remains intact because its deletion was not approved.
- The dedicated runtime account is keyless and has exactly the three reviewed predefined roles plus a custom role containing only `firebaseauth.users.update` and `firebaseauth.users.delete`. The deployer has one account-scoped `actAs` binding. Project-wide Editor, Token Creator, and Run Invoker are absent for that runtime identity.
- The locally matched recovery credential remains enabled. The second user-managed key had no matching local credential or retained audit use, was disabled, and had zero observed use after disablement. Neither key was deleted.
- All nine July writers remain active and unchanged. Each maps to an exact Gate 2 disposition in the private worksheet. No Function was deleted or deployed.
- `operationalControls/v1` now reads exactly schema version 1, generation 1, mode `maintenance`, and destructive workers false.
- All 16 required composite indexes are ready, with zero missing, unexpected, or duplicate definitions.
- The live Firestore rules hash matches exact source. Five non-mutating production reads produced two intended allows and three intended denials. No production write probe occurred.
- Firebase still has no default Storage resource, so the app-media bucket remains absent. Media creation, rules, IAM, admission, workers, and schedules remain outside Gate 1.
- Final readback re-confirmed the exact clean source, recovery protections, isolated restore, bucket policy, keyless runtime authority, key containment, maintenance control, rules, absent media bucket, unchanged writers, budget, alerts, and indexes.

The final local rules suite passed 174 Java-backed Firestore and Storage assertions. Earlier evidence attempts were stopped by local Java discovery, a stale emulator port, one local hook timeout, a missing ignored iOS config file, an overstrict Auth response-shape assertion, and CLI field-name normalization. None of those attempts widened authority or produced a semantic production failure; corrected runs passed.

### Gate 2: core cutover while closed

Completed under Andrew's separate exact approval. The named deployment sequence was:

| Stage | Exact selector members | Purpose |
|---|---|---|
| A | `mergeChants`, `onModerationAction`, `onChantCreated`, `onVoteWritten`, `onCommentLikeWritten`, `onCommentWritten` | Install the merge stop, moderation, and core counter behavior |
| B1 | `onReportCreated` | Delete the legacy created-event identity first, then deploy the written-trigger implementation |
| B2 | `onCommentReportCreated` | After B1 readback, delete the second legacy created-event identity and deploy its written-trigger implementation |
| C | `onChantWrittenForPerformances`, `onProfileAuthorityWrittenForPerformances`, `onPerformanceWritten`, `onPerformanceLikeWritten`, `onPerformanceViewWritten`, `onPerformanceShareWritten`, `onPerformanceCommentWritten` | Install source authority and performance reconciliation |
| D | `updateCreatorProfile`, `setCreatorFollow`, `markCreatorNotificationRead`, `onCreatorFollowWritten` | Install creator identity and follow projection while admission is closed |
| E1 | `onAccountDeletionJobWritten`, `onPerformanceMediaDeletionJobWritten`, `onPerformanceDraftDeleted` | Install destructive event workers while workers remain disabled |
| E2 | `deleteAccount` | Replace old sequential deletion intake without running a deletion test |
| F1 | `onUserReportCreated`, `onUserReportDeleted` | Install user-report lifecycle support |
| F2 | `acceptPolicy`, `completeOnboarding`, `submitReport`, `submitFeedback`, `submitChantUpdateSuggestion`, `moderateChantUpdateSuggestion` | Install onboarding, intake, and Living Songbook callables after report repair |
| G | `createPerformanceDraft`, `submitPerformanceDraft`, `cancelPerformanceDraft`, `moderatePerformance`, `moderatePublishedPerformance`, `resolvePerformanceDraftPlayback`, `resolvePerformancePlayback` | Install closed media callables; media admission stays denied |
| H | `setPerformanceLike`, `recordPerformanceShare`, `recordQualifiedPerformanceView`, `createPerformanceComment`, `deletePerformanceComment`, `resolvePublicShareDestination`, `publicSharePage`, `publicPerformanceMedia` | Install interaction and public-resolution code without publishing Hosting |
| I, held | `monitorOperationalBacklogsJob`, `cleanupAbandonedPerformanceDraftsJob` | Do not deploy or enable schedules in this packet |

The two report handlers are a special cutover:

1. Close all known report write paths and verify drain.
2. Delete the two legacy created-only triggers.
3. Confirm they are absent before deploying the written handlers with the reviewed names.
4. Run the bounded report repair from ground truth.
5. Compare stored reports, rebuilt counts, hidden state, and repair receipts.
6. Any mismatch keeps maintenance closed and requires a reviewed forward correction.

The two scheduled Functions are not deployed or enabled in this packet. After every group, function identity, trigger, region, runtime, service account, ingress, caps, and operational-control behavior were read back. No group mismatch remained at final readback.

### Gate 2 sanitized production receipt

Gate 2 executed from the clean exact source baseline and stopped before Gate 3. Exact principals, command history, trigger resource identifiers, report identities, and complete IAM bindings remain only in ignored mode-600 receipts.

- Preflight re-confirmed maintenance generation 1, destructive workers false, the exact keyless runtime authority, all nine predecessor writers, a clean exact source checkout, a passing production build, 230 locally runnable Functions tests, and 24 dedicated emulator cases held outside that unit run.
- Stages A through H deployed exactly 46 non-scheduled source Functions on Node 22 in `europe-west2`, all from one reviewed source build and the dedicated runtime identity. Runtime caps, concurrency, ingress, callable or HTTPS kind, Firestore event path, retry flag, and event location matched compiled source. The two scheduled exports stayed absent.
- The report paths were contained before replacement. Each created-only predecessor trigger was deleted and proved absent before its written-event replacement was deployed. The replacements target `reports/{reportId}` and `commentReports/{reportId}` in the Firestore event location.
- Ground-truth repair covered all 192 chants and four comments. It produced 196 complete checkpoints and 196 deterministic audits, with zero counter, hide-state, or visible-comment-count mismatch. The single stored chant report points to a missing chant, cannot affect a live counter, and remains retained for operator review rather than being silently deleted or rewritten. No comment report is orphaned.
- Final data readback found zero account-deletion, media-deletion, or deferred-draft-cleanup jobs and zero performance, performance-draft, follow, or user-report rows. No deletion or media execution test ran.
- The three destructive event workers are installed with control still denying execution. Firebase reported retry-enabled delivery may continue for up to seven days, so the earlier 24-hour planning reference is not treated as deployed truth. Gate 4 must inspect actual retry history and recovery behavior before worker activation.
- All 27 HTTP or callable Cloud Run services finally have the exact public transport invoker needed by Firebase HTTPS routing, with no additional Run Invoker member. Two services needed a narrow forward IAM correction after legacy containment or deployment left transport absent. Application admission still fails closed through maintenance control and server authorization.
- Firebase CLI source analysis automatically enabled the Cloud Scheduler API during deployment. No scheduled Function or Scheduler job exists, so no schedule can run. This service enablement is recorded as an incidental Gate 2 side effect, not authority to add or activate schedules.
- Final readback confirms three infrastructure or recovery buckets, no Firebase default app-media bucket, zero scheduled jobs, and no severity-error log entry in the rollout observation window.
- Production remains at schema version 1, generation 1, mode `maintenance`, and destructive workers false. Core admission, media, workers, schedules, Hosting, DNS, App Check enforcement, signing, stores, and release remain closed.

### Gate 3: first core opening

Gate 3 ran under Andrew's separate exact approval. Its authorized procedure was:

1. Confirm the exact client build, test accounts, test actions, expected writes, operator, monitors, cost view, and close command.
2. Change control to the next generation with mode `core` and workers false.
3. Perform a time-bounded private smoke test of sign-in, onboarding, catalogue read, chant submission, vote, comment, report, correction suggestion, and account recovery boundaries.
4. Do not test video, upload, destructive deletion execution, schedules, public widening, or store paths.
5. Observe Functions errors, denied requests, report counts, reconciliation, Auth account count, Firestore writes, latency, and spend for 30 minutes.
6. Unless Andrew separately approves continued core access, return to the next generation in `maintenance` after the test and verify closure.
7. Produce the core receipt and update the command center before any device walkthrough or Gate 4 proposal.

Because production has no source-backed private-cohort control, Gate 3 was a short attended exposure rather than cryptographically restricted access. Andrew explicitly accepted that limit through the exact Gate 3 approval. Any retry keeps the same limit unless a separately reviewed cohort-control change lands first.

### Gate 3 sanitized production receipt

Gate 3 used the clean exact source baseline and finished closed. Exact device identifiers, debug attestation material, principals, commands, and private logs remain only in ignored mode-600 receipts.

- The exact V1 client at `88ce483f1ea18df6a7a2b4e790803773164ac9a5` compiled, installed, and launched on the paired physical iPhone with the reviewed bundle identity. No tracked runtime source changed.
- Debug App Check attestation was rejected because its temporary debug registration was absent. The token was not registered, App Check enforcement remained off, and no enforcement posture changed.
- Before opening, control read schema version 1, generation 1, mode `maintenance`, and workers false. Auth contained one enabled verified account. The privacy-safe collection baseline was one profile, three votes, four comments, one report, one feedback row, zero chant-update suggestions, and 198 audit rows. Destructive jobs, media rows, follows, and user reports were all zero.
- One pre-open `acceptPolicy` request received the expected maintenance denial. It occurred before core admission and is not a Gate 3 runtime error.
- The reviewed control transition opened generation 2 in `core` with workers false. The attended observation ran for 51 minutes, then the reviewed close transition set generation 3 in `maintenance` with workers false.
- No Cloud Run request reached the backend during the exact core window. Severity-error logs were empty. Auth and every counted collection matched the pre-open baseline at the midpoint and after closure.
- Andrew's live phone readiness was not confirmed before the control opened. That missed the intended attended precondition even though the prior exact Gate 3 approval authorized the bounded opening. The lack of a private-cohort control made prompt closure especially important. A retry must not open until Andrew confirms the paired phone is in hand and Codex confirms monitoring and the close path are active.
- The owner did not complete the phone actions during the open window. Sign-in continuation, onboarding, catalogue, chant submission, vote, comment, report, correction suggestion, and account-recovery behavior therefore remain unverified by this Gate 3 attempt.
- No synthetic production workflow ran. A proposed automated path was stopped before execution because it would have created public test records, a temporary account, and an external recovery message without separate authority.
- Billing linkage remained active. A fresh Billing Budgets enumeration returned an authorization denial for both available operator paths, so Gate 3 does not claim a fresh budget-object read. The verified Gate 1 USD 25 budget and thresholds remain dated evidence, not a new Gate 3 measurement.
- The opening and close controls, exact observation bounds, count snapshots, and sanitized log queries are retained privately. No token, email, UID, device identity, private key, or raw user payload is recorded here.

This is an operational opening-and-closure receipt, not a functional core-smoke pass. The separately approved retry below also returned closed without a functional request. Gate 4 remains held.

### Gate 3 owner walkthrough retry receipt

Andrew confirmed the paired phone was ready, agreed the exact reversible action list, and separately approved `V1 Lane 3 Gate 3 owner walkthrough retry`. The retry stayed within that authority and finished closed.

- Preflight recognized the connected iPhone and re-read schema version 1, generation 3, mode `maintenance`, and workers false. Auth and every counted collection matched the prior close, and recent severity-error logs were empty.
- A private one-use plan opened schema version 1, generation 4, mode `core`, with workers false. Separate readback confirmed the target before the owner was told to tap.
- The authorized phone sequence was policy acceptance, real onboarding only if prompted, Arsenal and Leeds catalogue reads, one vote change and restoration, and one Songbook save and removal. Chant submission, comments, reports, corrections, recovery, deletion, media, synthetic accounts, public records, and external messages remained excluded.
- No Cloud Run request or severity error appeared after the tap instruction or during the bounded attended wait. No listed owner action therefore produced functional evidence.
- The default close created a fresh plan from the observed generation 4 state and applied schema version 1, generation 5, mode `maintenance`, with workers false. Final Auth and collection counts exactly matched the retry pre-open baseline.
- Exact device, command, control, and log evidence remains ignored and mode 600. No private identity, token, raw payload, or complete binding is recorded here.

This second attempt proves the fresh plan, open, monitoring, and higher-generation close path again. It does not prove policy acceptance, onboarding, catalogue, vote, or Songbook behavior. Andrew later identified the missed tap instruction and approved the immediate attempt below. Gate 4 remains held.

### Gate 3 immediate owner walkthrough retry receipt

Andrew confirmed the prior no-action result was a missed tap instruction, confirmed he was watching, and separately approved `V1 Lane 3 Gate 3 immediate owner walkthrough retry`. The attempt remained within its one-use authority and finished closed.

- Fresh preflight recognized the connected iPhone and re-read schema version 1, generation 5, mode `maintenance`, and workers false. Auth and every counted collection matched the prior close, and recent severity-error logs were empty.
- A private one-use plan opened schema version 1, generation 6, mode `core`, with workers false. Separate readback confirmed the target.
- Codex immediately sent the policy-acceptance tap instruction, repeated it after the first wait, and announced a final 30-second interval. No Cloud Run request or severity error appeared.
- The default close created a fresh plan from the observed generation 6 state and applied schema version 1, generation 7, mode `maintenance`, with workers false. Final Auth and collection counts exactly matched the immediate pre-open baseline.
- No synthetic workflow, content mutation, account action, external message, media action, or destructive job ran. Exact device, command, control, and log evidence remains ignored and mode 600.

This third attempt again proves the safe open and close path, not a functional journey. The same chat-dependent tap workflow must not be repeated. Before another proposal, Andrew and Codex must agree a deterministic countdown or another synchronous owner action that does not depend on noticing a second message after approval. No further retry phrase is prepared. Gate 4 remains held.

### Gate 3 countdown and client-crash receipt

Andrew separately approved `V1 Lane 3 Gate 3 30-second countdown owner walkthrough retry` and committed to tap without waiting for a follow-up message. That one-use authority was consumed and production finished closed.

- Fresh preflight read schema version 1, generation 7, mode `maintenance`, workers false, the expected Auth and privacy-safe collection counts, and no recent severity error.
- A private one-use plan opened schema version 1, generation 8, mode `core`, workers false. Separate readback confirmed the target. No Cloud Run request or severity error arrived during the window or final grace check.
- The default close derived a fresh plan from observed generation 8 and applied schema version 1, generation 9, mode `maintenance`, workers false. Final Auth and collection counts exactly matched the pre-open baseline.
- The app had not foregrounded for the countdown action. Subsequent direct launches while production was closed produced three fresh native Runner crash reports. Each reports `EXC_BAD_ACCESS (SIGSEGV)` at address zero on the main thread with the first frames `VSyncClient.initWithTaskRunner`, `FlutterViewController.createTouchRateCorrectionVSyncClientIfNeeded`, and `FlutterViewController.viewDidLoad`.
- The exact client uses Flutter 3.44.8's implicit-engine UIScene path. The crash occurs before Dart or plugin code can run and matches [Flutter issue 183900](https://github.com/flutter/flutter/issues/183900), [the App Store reproduction in issue 187565](https://github.com/flutter/flutter/issues/187565), and the open iOS-team-triaged [issue 190030](https://github.com/flutter/flutter/issues/190030). The production policy service received no request, so the user's tap did not persist acceptance or partially execute the callable.
- Private device identifiers and the complete crash reports remain outside Git. The sanitized fault signature, exact toolchain, source boundary, and upstream references are durable here.

This fourth opening proves only another safe open and close. The physical-device blocker is native startup, not backend admission. Do not open production again until a separately approved source correction replaces the implicit-engine startup path, passes physical cold-launch evidence without a debugger, and preserves app lifecycle behavior.

### Approved iOS 26 ProMotion startup and launch presentation correction

Andrew approved `V1 iOS 26 ProMotion explicit-engine startup correction spec` on 2026-09-02. After the corrected client completed repeated physical cold launches, he directly requested one bounded launch-presentation calibration: keep the Flutter-owned brand reveal visible long enough to register, quiet the current-policy gate, reduce duplicated rule copy, retain the full document routes and recovery actions, and make the closed-production acceptance result truthful. This combined source block is bounded to:

1. replace the iOS implicit-engine bootstrap with one explicit `FlutterEngine` created and run before the scene creates its root view controller;
2. register plugins exactly once against that engine and construct the scene window with `FlutterViewController(engine:)`;
3. preserve existing deep-link, authentication-return, application/scene lifecycle, launch-screen, entitlement, orientation, and plugin behavior;
4. add source-contract coverage for the explicit-engine topology and fail if the implicit storyboard/controller path returns;
5. strengthen the existing spinner-only policy busy state with an unmistakable saving label while retaining disabled duplicate-tap protection and a truthful recoverable error when production is closed;
6. compile debug, profile, and release iOS targets, then cold-launch the exact build repeatedly from the paired ProMotion device's Home Screen without a debugger, including force quit, relaunch, background, and resume; and
7. repeat the policy interaction while production remains in maintenance and confirm a visible denial rather than a crash or silent wait;
8. hold the one-shot Flutter-owned reveal for a measured 2.8-second cold-start interval without delaying resume, repeating it as onboarding, or overriding reduced-motion behavior; and
9. reduce decorative density and duplicated long-form copy on the current-policy gate, keep Privacy as a compact separate route, and place Help, Support, Delete account, and Sign out behind one visible secondary disclosure while preserving acceptance, failure recovery, and access without consent.

The reveal timer is presentation only and is not a crash workaround. The block does not patch the Flutter binary, disable ProMotion, change backend, rules, data, policy meaning, policy version, age rule, operational control, App Check enforcement, signing distribution, store state, or production admission. Any Flutter SDK upgrade requires separate evidence that an official release contains the fix; the current upstream release defect remains open.

### Gate 4: media and workers

Gate 4 is outside this packet. It requires a new amendment covering bucket evidence, App Check posture, signed URL authority, upload and playback recovery, deletion and cleanup jobs, Scheduler, monitoring, spend, media moderation, and the exact worker activation order.

## Stop conditions

Stop immediately and retain or restore safe closure when:

- project, source, authenticated principal, region, trigger, runtime, or service-account identity differs from the approved plan;
- recovery proof is missing, stale, unreadable, or not isolated;
- a legacy writer or key has no exact disposition;
- an index is not ready or rules tests/readback differ;
- both legacy and replacement report writers could overlap;
- any protected endpoint admits while control is missing, malformed, maintenance, or otherwise incompatible;
- report repair does not converge exactly;
- a deployment group returns a partial or unexpected identity;
- error, denial, latency, write volume, Auth growth, or spend exceeds the approved observation threshold; or
- the owner, monitor, or close path becomes unavailable during the attended window.

## Forward recovery

1. Close admission with a new higher control generation when the control path is healthy.
2. Remove ingress or disable the exact offending revision when control cannot provide trustworthy containment.
3. Preserve logs and sanitized readback before correction.
4. Repair forward from the reviewed source or a new approved correction. Do not blindly restore the July bundle.
5. Use the isolated restore rehearsal to validate data recovery. Restoring into the production default database requires a new exact approval.
6. Re-run the affected readback and observation window before reopening.

## Capacity, cost, and attended window

- Proposed attended window: two hours with Andrew and Codex present.
- Checkpoint: 30 minutes after each live admission transition.
- First core observation: 30 minutes minimum, longer if any threshold is uncertain.
- Function caps remain those reviewed in source. Do not widen them during rollout.
- Current official [Firestore pricing](https://cloud.google.com/firestore/pricing) for `nam5` is approximately USD 0.15 per GiB-month for PITR, USD 0.03 per GiB-month for backup storage, and USD 0.20 per GiB restored. US multi-region Standard [Cloud Storage pricing](https://cloud.google.com/storage/pricing) is approximately USD 0.026 per GiB-month plus operations and transfer. Using a deliberately conservative 1 GiB working bound for the current counted prelaunch data and no media, Gate 1 recovery setup and one isolated rehearsal are expected to stay under USD 1. This is an estimate, not a cap or invoice.
- Gate 1 measured 0.001833 GiB of Firestore data and a 283,548-byte export, confirmed the current budget, and remained below the approved USD 5 one-time and USD 1 monthly recovery-storage stops.
- Gate 1 itemized and read back its paid recovery resources. Gate 2's Firebase CLI analysis enabled the Scheduler API automatically, but zero scheduled Functions and zero Scheduler jobs exist. Schedule creation and activation remain outside this packet.
- Alerting is evidence, not containment. The operator keeps the close path available throughout the window.

## Privacy-safe receipt

Record:

- exact source and tree;
- sanitized actor role, never a credential or full private binding;
- target project and resource names;
- precondition readback;
- approved action and timestamp;
- command category, not secret-bearing raw command history;
- post-action readback;
- counts and hashes where safe;
- stop, repair, and observation results; and
- remaining gates.

Do not record raw document content, emails, UIDs, IP addresses, tokens, key material, private worksheet contents, or unredacted logs.

## Owner decisions approved for this packet

1. Paid recovery resources and 30-day export retention were approved and completed below the refreshed Gate 1 size and cost stops above.
2. The two-hour attended window and 30-minute observation checkpoints are approved.
3. Per-writer and per-key dispositions are approved for the private local worksheet, with only sanitized outcomes in Git.
4. Gate 3 used a short attended core opening without a true private-cohort control under its separate exact approval.
5. All four approved openings returned production to a higher maintenance generation by default. None proved the functional core journeys.

## Acceptance criteria

1. This packet matches exact `main`; Gates 0 through 3 and all three Gate 3 retries each record dated reads and no unsupported continuing-state claim.
2. Every mutation is behind a distinct approval gate with owner, preconditions, stop conditions, readback, and forward recovery.
3. Recovery is proven before old-writer containment or deployment.
4. Report triggers cannot overlap and report state is rebuilt from ground truth.
5. Core, media, workers, schedules, Hosting, DNS, store, and release authority are separated.
6. All four core openings are bounded, observed, and closed by default, and their missing functional evidence is stated as incomplete rather than passed.
7. Durable records and the private command center agree with this packet.
8. Project governance, writing-style, whitespace, and guide regressions pass.
9. Gate 0 through Gate 3 and all three retry records contain no credential, private principal, raw payload, recovery resource name, key identifier, report identity, debug token, device identity, or complete binding, and the detailed receipts remain ignored and mode 600.
10. The packet, client correction, post-review correction, and command-center contract test remain uncommitted, unpushed, and undeployed until Andrew separately authorizes packaging.

## Next valid approval

The exact-device check, both independent reviews, all bounded review corrections, the complete local verification matrix, and initial PR 33 packaging are complete. The first clean-runner attempt supplied the measured evidence for the policy golden's test-local allowance. The remaining source gate is replacement exact-head clean-runner CI at the amended closure commit. Gate 4 is not next, and no production approval phrase is prepared. None of these source steps authorizes a production opening, backend or data mutation, deployment, Hosting, DNS, App Check enforcement, signing distribution, store action, or release. A later production retry requires a fresh plan and exact approval after this client correction is merged.
