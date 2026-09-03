# Change rationale: V1 Lane 3 production rollout packet

## Identity and authority

- **Date:** 2026-09-01. **Owner:** Andrew. **Author:** Codex.
- **Baseline:** Exact `main` at `88ce483f1ea18df6a7a2b4e790803773164ac9a5`, tree `c3fb5fa80d35b0b029c0e94212ef484d74b77303`.
- **Checkout:** `chants-v1-production-rollout-packet`, branch `codex/v1-production-rollout-packet`.
- **Boundary:** Andrew approved the packet for Gate 0, then separately approved `V1 Lane 3 Gate 1 recovery and containment`, `V1 Lane 3 Gate 2 core cutover while closed`, `V1 Lane 3 Gate 3 first core opening`, and three bounded Gate 3 retries. Each Gate 3 approval authorized only its exact short core opening, named owner actions, observation, and default close. Media infrastructure, worker activation, schedules, Hosting, DNS, App Check enforcement, signing, stores, and release remained excluded.
- **Result:** Gates 0 through 2 are complete with sanitized durable receipts and ignored mode-600 private evidence. Gate 3 and its three separately approved retries opened core generations 2, 4, 6, and 8 and closed at maintenance generations 3, 5, 7, and 9. Workers stayed false. No window received a request or data change, so functional journeys remain incomplete. Subsequent physical-device diagnosis proved a Flutter iOS 26 ProMotion implicit-engine startup crash before Dart. A later approved source block corrects that client defect while production stays closed. Gate 4 remains unapproved.

## Why a fresh packet is required

PR 32 completed the V1 source and documentation boundary after the prior production plan was written. Production itself was last observed behind source: nine July Functions, old rules, two ready indexes, no control document, no application-media bucket, disabled Scheduler, and no proven recovery surface. That evidence is useful for risk identification but too old to authorize a live operation.

The rollout is not a normal deploy. The two old report handlers blindly increment on create while current source rebuilds counts from writes, so old and new handlers must not overlap. The old live merge endpoint also lacks the reviewed stop. A blanket rollback to the July bundle would restore those defects.

## Structure chosen

The packet uses five gates:

1. Fresh read-only inventory and a private per-writer, per-key worksheet.
2. Recovery and containment prerequisites, including isolated restore proof, narrow runtime and deployer authority, closed operational control, indexes, and rules.
3. Bounded named-function deployment while admission stays closed, with a special delete-confirm-deploy-repair sequence for report handlers.
4. A short attended core-only smoke test with workers and media closed, followed by a return to maintenance by default.
5. A later amendment for media, workers, schedules, and their operating evidence.

Every live gate requires a new exact approval, readback, stop conditions, and forward recovery. The packet never treats a successful command as sufficient evidence.

## Product and operational tradeoffs

Production has no source-backed private-cohort gate. The first core smoke can therefore be short and attended, but it is not cryptographically limited to named testers. Andrew must explicitly accept that bounded exposure or require a cohort-control change before core admission.

The proposed two-hour window and 30-minute checkpoints keep the operator, monitoring, and close path present. Returning to maintenance after the first smoke is safer than leaving core open merely because the test passed. Media and destructive work remain separate because their Storage, App Check, signed URL, cleanup, moderation, cost, and scheduler dependencies have a wider failure surface.

## Recovery and privacy boundary

Point-in-time recovery does not provide a complete historical window immediately after enablement, and an export is not recovery proof until restoration is rehearsed in an isolated target. The packet requires both timing evidence and an isolated restore before cutover.

Exact principals, key identifiers, private IAM bindings, credentials, raw user data, and secret-bearing commands stay in a private local worksheet. Git receives only sanitized role-level outcomes, counts, hashes where safe, and exact source/resource identities.

The private worksheet is ignored, mode 600, and maps all nine live writers, all 48 source exports, and both user-managed keys. One key matches the protected local rollout credential and remains enabled temporarily for recovery, control, and repair. The other had no local match or retained audit use, is disabled, and had zero observed post-disable use. Gate 1 deleted no key.

Gate 1 created the dedicated V1 runtime identity keyless, gave it exactly three reviewed predefined roles plus a two-permission Firebase Auth custom role, and proved one account-scoped deployer `actAs` path. Both App Check provider configurations still exist, while Firestore and Authentication enforcement remain off. The Billing Budgets API is enabled and freshly read; Secret Manager remains disabled, so its inventory remains blocked rather than proven empty.

## Verification and remaining evidence

- Source export, index, runtime-option, operational-control, prior rollout, runbook, and command-center claims were re-derived from exact `main`.
- Fresh exact-main run `33562025155` is attributed to `88ce483` and completed all eight jobs successfully.
- Gate 0 re-read Functions, Cloud Run, Firestore, Storage metadata, Auth, App Check, IAM, keys, Eventarc, Pub/Sub, Hosting, Monitoring, billing state, API state, and privacy-safe collection counts. No user object or raw document content was downloaded.
- Gate 1 measured 0.001833 GiB of Firestore data and a 283,548-byte export, freshly confirmed the USD 25 monthly budget and its five thresholds, and remained below the approved USD 5 one-time and USD 1 monthly recovery-storage stops.
- Firestore PITR and delete protection are enabled. A 30-day retained export imported into an isolated `nam5` database, where 12 top-level collections and all 849 documents matched exactly.
- Gate 1 established maintenance generation 1 with workers false. Gate 3 and its three retries opened core generations 2, 4, 6, and 8 and closed at maintenance generations 3, 5, 7, and 9. Workers stayed false. All 16 required indexes are ready. Live Firestore rules match exact reviewed source, and five non-mutating Gate 1 probes produced two intended allows and three intended denials.
- Gate 2 replaced the July Function set with exactly 46 non-scheduled Node 22 Functions from one reviewed source build. Both created-only report triggers were removed before their written-event replacements, and the bounded repair closed with 196 complete checkpoints, 196 deterministic audits, and zero projection mismatch.
- One report against a missing chant remains retained and inert for operator review. It was not deleted or rewritten. No comment report is orphaned, and no destructive job, performance, draft, follow, or user-report row exists.
- The app-media bucket remains absent, destructive workers remain denied, and no release surface opened. All four Gate 3 core windows recorded zero backend requests and zero severity errors, then returned to a higher maintenance generation, most recently generation 9. Firebase CLI analysis enabled the Scheduler API incidentally, but the two scheduled Functions remain absent and there are zero Scheduler jobs.
- The exact V1 client compiled, installed, and launched on the paired physical iPhone. Debug App Check attestation was rejected without changing enforcement. No owner journey reached the backend, no synthetic workflow ran, and every Auth and collection count matched baseline after closure. This is opening-and-containment evidence, not a functional smoke pass.
- Andrew's live phone readiness was not confirmed before the first opening. The first retry corrected that precondition, but Andrew later confirmed he missed its tap instruction. The immediate retry also received no request after repeated prompts. The deterministic countdown retry removed that coordination ambiguity, safely closed at generation 9, and still received no request because the app had not foregrounded. Direct launches afterward produced three matching native Flutter-engine crash reports before Dart. This establishes a source blocker rather than backend uncertainty.
- Project memory, writing style, governance, launch-guide regressions, whitespace, and final diff inspection are required before handoff.
- The original rollout packet changed no runtime, rules, index, seed, Hosting, native, or dependency source file. Gate 1 changed only its approved cloud recovery, IAM, key, control, index, and Firestore rules state. Gate 2 deployed reviewed source and made only the narrow transport-IAM corrections required for exact Firebase HTTPS routing while maintenance remained closed. Gate 3 and its retries changed only the operational control through generation 9, ending in maintenance. A later explicitly approved correction in the same working handoff changes native startup and launch presentation source; its rationale and verification are recorded separately.
- Production claims are explicitly dated to the Gate 0 through Gate 3 observation windows and must be re-read immediately before each later approved mutation.

## Approval meaning

`approved V1 Lane 3 production rollout packet` authorized Gate 0. The six later exact phrases separately authorized Gates 1, 2, the first Gate 3 opening, and its three retries. Each authority was consumed by its completed action and close. The later explicit-engine correction received its own approval and does not authorize production. No production retry is prepared. Media, workers, schedules, public widening, Hosting, DNS, App Check enforcement, stores, and release remain separately gated, and Gate 4 is not next.
