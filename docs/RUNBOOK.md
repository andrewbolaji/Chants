# Operator runbook

This runbook describes the source-backed recovery paths that exist today. Dashboard setting names and non-sensitive configuration state are recorded when verified. Credentials, private notification destinations, raw production payloads, and user identities stay outside the repository.

## Service and ownership

- **Purpose:** Let football supporters browse, learn, save, submit, discuss, vote on, and report chants while operators preserve archive trust and community safety.
- **Owner and escalation:** Andrew is the current product and system owner. A second operator and external escalation channel are not yet recorded.
- **Dependencies:** Firebase Auth, Firestore, Cloud Functions, App Check, Crashlytics, mobile operating-system storage, the native share sheet, and the system browser for evidence links.
- **Dashboards, logs, and traces:** Firebase Authentication, App Check, Crashlytics, Hosting, Google Cloud Monitoring, Cloud Logging, and Cloud Billing own the launch controls. Store dashboards remain external. `firebase functions:log` is available from `functions/package.json`; use it only with explicit environment authorization and avoid copying sensitive payloads into project memory.
- **Deployments and recent changes:** Git history, merged pull requests, GitHub Actions, `docs/EXECUTION.md`, and scoped rationales under `docs/changes/`.

## Health

### Current backend rollout hold

Read-only inventory on 2026-08-30 established that production is still the July backend, not the reviewed V1 source. The 2026-08-31 07:37 UTC recheck confirmed the same nine identities, source generations and old rules. See `docs/changes/2026-08-30-v1-backend-rollout-readiness.md` for pinned predecessor hashes and `docs/changes/2026-08-31-v1-production-rollout-planning.md` for the latest bounded observations. The proposed sequence is now in `docs/CHANGE_SPEC.md`; it is not permission to execute. Node 22 source verification does not change live state.

Do not use an all-Functions deploy or ordinary update for the two report handlers: the deployed created-only versions blindly increment, while current written handlers rebuild counts. The old live merge endpoint lacks the reviewed stop. Never invoke it or restore that bundle as blanket rollback. Admission, bounded repair and a cutover evidence validator now exist in source under decision 026; actual containment, drain, replacement and repair still require a separate production amendment.

Production has only two ready chant indexes, no expected media bucket or Storage rules release, and disabled Storage/Scheduler APIs. Bucket location/provisioning, IAM, retention, resource caps, fourteen index creations, and destructive worker/schedule activation remain owner-approved gates. Firestore and Eventarc are in `nam5`; Functions compute stays `europe-west2`. The data location must not be inferred from the compute region.

The recheck found zero historical performances, drafts and all three deletion/cleanup job collections; the control document was absent. One profile is not an Auth-user or private-cohort inventory. Firestore PITR and delete protection are off. Artifact Registry now has a one-day DELETE/ANY cleanup policy, unlike the prior no-policy observation; its origin was not established. No settings were changed. Re-observe all facts before an approved live operation.

Claude independently closed PR 26 F1-F5 and reviewed the earlier staged Call-Ups tree. Source and later corrections merged through PR 28 at `42f20dc675a1de4fe85956783774a4cdc67f3a01`; exact-main run `33368497566` passed all eight jobs. The next proposed review covers bounded deployment-preparation code and the exact operational manifest. Production approval and configured-device inspection remain separate; no additional seed write is needed.

### Source operational control, not yet deployed

The exact private `operationalControls/v1` schema is version 1, positive safe-integer generation, mode maintenance/core/media, and Boolean destructiveWorkersEnabled. No client may read or write it. Source now contains a local read/plan/apply command, not a deployed control endpoint or permission to change production.

| State | New protected work | Existing work |
|---|---|---|
| Missing, malformed, unreadable or maintenance | Client/operator mutations and protected callable/HTTP paths denied | Reconcilers and monitoring may drain; workers preserve evidence |
| Core, workers false | Nonmedia journeys only; no new account deletion or media | No destructive workers |
| Core, workers true | Nonmedia journeys and accepted account deletion | Workers only after reviewed backlog/replay readiness |
| Media, workers true | Media paths may also pass existing authority checks | Normal moderation and cleanup authority remain |

Increase generation on every approved mode or flag transition, including close and reopen. Never reuse or roll back an earlier generation: it could revive an unexpired upload grant. Readers cannot prove Admin edit history. Media with workers false is invalid and closes admission.

A control read admits an invocation; it does not cancel work already inside its handler. New uploads check control/profile, but admitted transfers and signed URLs may finish. Rules do not fence console writes, old revisions or arbitrary Admin scripts. Quiet logs or a fixed sleep do not prove drain.

### Future operational-control command

Do not run against production until the exact live release is approved. The preparation implementation and unresolved private IAM/recovery checklist are in `docs/changes/2026-08-31-v1-production-rollout-preparation.md`.

Use the final reviewed, completely clean checkout and rebuild locked Functions output with Node 22. The CLI checks HEAD and Git cleanliness, not the provenance of an arbitrarily edited ignored build directory. Record build identity separately. Reuse the ignored `.private-report-repair/` directory for owner-only control plans; do not put credentials or plans in Git. The credential must be an explicitly approved, isolated service-account JSON file for `chants-f95b4`. Firebase CLI login is not that credential. No credential is created by this tool.

Read is the default; spelling it out makes intent clear:

```sh
node functions/lib/operational_control_cli.js read \
  --project chants-f95b4 \
  --source-sha "REPLACE_WITH_REVIEWED_40_CHARACTER_SHA" \
  --credential "REPLACE_WITH_ABSOLUTE_PRIVATE_CREDENTIAL_PATH"
```

Plan the initial closed state only if the control is still absent. For subsequent transitions, replace mode/workers only with the separately approved values; the command derives the expected data/version and next generation from the real document.

```sh
node functions/lib/operational_control_cli.js plan \
  --project chants-f95b4 \
  --source-sha "REPLACE_WITH_REVIEWED_40_CHARACTER_SHA" \
  --credential "REPLACE_WITH_ABSOLUTE_PRIVATE_CREDENTIAL_PATH" \
  --plan "REPLACE_WITH_ABSOLUTE_PRIVATE_REPORT_REPAIR_CONTROL_PLAN_PATH" \
  --mode maintenance --workers false
```

Planning reads only the control and exclusively creates a local 0600 plan file. It never replaces an existing plan. Review its exact target and expected state/version plus the live admission prerequisites. A digest is not a substitute for that approval.

```sh
node functions/lib/operational_control_cli.js apply \
  --project chants-f95b4 \
  --source-sha "REPLACE_WITH_THE_SAME_REVIEWED_SHA" \
  --credential "REPLACE_WITH_ABSOLUTE_PRIVATE_CREDENTIAL_PATH" \
  --plan "REPLACE_WITH_THE_SAME_ABSOLUTE_PRIVATE_CONTROL_PLAN_PATH" \
  --digest "REPLACE_WITH_APPROVED_64_CHARACTER_DIGEST"
```

Apply creates or changes only `operationalControls/v1`, in one exact-state/version transaction with at most three SDK transaction attempts. It requires separate readback and reports `target-observed`. This proves the current four-field target, not that this invocation authored it. A duplicate or lost-response retry cannot advance a second generation. A different current state/version, malformed control or failed readback stops. Inspect the same plan and current state before deciding to retry; never generate a new transition merely because acknowledgement was lost.

The CLI rejects emulator redirection; emulator tests call the same transaction functions against a fixed demo database instead. It is not an IAM fence, operator approval system, historical audit, malformed-state repair tool or retained-job executor. A later out-of-band deletion/restoration can violate generation history. Keep that boundary restricted and preserve private execution receipts outside the exact-schema document.

### Upload and retained cleanup recovery

One upload slot per account lasts 30 minutes. The form retains selected media and explains waiting for service, finishing/cancelling another upload, cancelling an expired draft, or using Send feedback in You. Never hand-author a grant or backfill it from a legacy draft. Cancellation can also wait during maintenance, so choose and communicate a bounded maintenance window.

The deleted-draft event retains `deferredDraftCleanupJobs/{draftId}` before acknowledgement. Pending means no successful attempt recorded. Attempted means exact-path removal returned, not permanent absence of later bytes. Mode changes do not replay these or existing account/media deletion jobs. Paused-worker logs are aggregate and omit private identifiers.

Permanent invalid identity or path conflict instead records `deferredDraftCleanupJobs/blocked:<sha256(draftId)>`. The fixed warning is `draft-cleanup-blocked`; inspect the private collection under separately authorized operator access. The blocked row keeps only sourceDigest, a syntax-validated draftId (null for an invalid ID), reason, schema/state and first timestamps, not a raw event, owner or executable path. An existing valid job stays untouched. Duplicate events acknowledge the same block; database failure still retries. Do not treat blocked as cleaned, delete its evidence, or replay it as a path.

To investigate a block, use its private draftId locator and match its digest against authorized draft/grant/job evidence. If draftId is null, obtain the original identity from separately retained authoritative incident evidence; the digest alone is not reversible. There is deliberately no raw deleted snapshot in quarantine. If that identity or path ownership cannot be proved from retained authoritative evidence, keep media admission closed for the affected recovery and escalate; never derive a deletion path from a hash or caption. A later well-shaped event cannot silently revive the source. Resolving the block requires a separate exact-target recovery approval, current grant comparison, transfer drain and readback. No automatic repair/clear command is shipped.

Legitimate pending/attempted jobs retain the owner UID inside uploadPath, including after account deletion. No TTL exists. Account-deletion completion therefore does not mean every identifier-bearing operational path is erased. Retention must balance privacy with cleanup of late admitted uploads; deleting these records on an arbitrary timer would lose cleanup authority. The production retention/replay decision is still open.

If a supporter receives `upload-needs-recovery`, inspect the private profile's activePerformanceUpload, current deletion/ban state, draft and retained cleanup evidence under explicit authorization. Preserve the observed generation and exact identity; never mint or backfill a grant from a draft. A malformed grant has no trustworthy expiry, so waiting 30 minutes is not a guaranteed fix. Prove no newer valid slot is being replaced and contain/drain any prior transfer before proposing an exact compare-and-set revocation. Only a separately approved operator correction may clear the bad slot; the normal callable may then issue a fresh grant under current authority. If those facts cannot be proved, remain closed and escalate.

Before workers open, approve read-only inventory, bounded exact replay targets, transfer drain, observation and retention. Include cancelled/rejected draft rows: existing best-effort cancellation and the daily awaiting/cleanup scanner do not sweep every terminal state. Do not discard retained paths or claim final cleanup without approved readback.

### Report cutover and repair procedure

This is source guidance for a future separately approved production operation. Do not run the commands now.

1. Obtain exact-head-green source, the combined Claude review and a Lane 3 production amendment. Rebuild Functions from that clean reviewed checkout. The CLI verifies source HEAD/cleanliness, not provenance of an arbitrarily modified ignored build directory.
2. Prove each pause surface: client rules, onModerationAction, deleteAccount, mergeChants, report intake, destructive workers, repository Admin, external Admin and legacy report events. Record exact revisions, alternate invocation containment, maximum runtimes from deployed settings, containment start, observation references, in-flight drain and queued-delivery disposition.
3. Keep maintenance at the approved generation. Isolate old targets, then replace only onReportCreated and onCommentReportCreated with reviewed written handlers, europe-west2 compute, nam5 events and original document paths. If either replacement is missing, stay closed and recover forward. No overlapping incrementers or blind rollback.
4. Prepare private owner-only regular schema-2 JSON cutover evidence using `functions/src/report_cutover.ts`. Each surface requires UTC containmentStartedAt and observedAt. The observation must be at least maximumRuntimeSeconds after containment began, not future-dated, and no more than 15 minutes old. This is a conservative re-observation ceiling, not a verified cloud timeout or proof of drain. All four containment/drain/queue attestations remain required. Refresh evidence from actual observations, never merely edit its timestamp to pass. Old schema-1 evidence is rejected. Every repair transaction binds source and evidence generation to the actual maintenance control; apply also binds the reviewed plan. The validator cannot inspect live IAM/traffic or prove whole-database coverage. Plans belong directly in ignored `.private-report-repair/`; inputs must be nonsymlink regular files, owner-only and at most 1 MiB.
5. Plan one page, starting each collection from the beginning. Even plan-only requires both replacement and containment attestations. Replace every quoted placeholder after authorization:

```bash
node functions/lib/report_repair_cli.js plan \
  --project chants-f95b4 \
  --source-sha "REPLACE_WITH_REVIEWED_40_CHARACTER_SHA" \
  --credential "REPLACE_WITH_ABSOLUTE_OWNER_ONLY_CREDENTIAL_PATH" \
  --cutover "REPLACE_WITH_ABSOLUTE_OWNER_ONLY_EVIDENCE_PATH" \
  --plan "REPLACE_WITH_ABSOLUTE_PRIVATE_REPORT_REPAIR_PAGE_PATH" \
  --kind chants
```

6. Privately review scope, before/after hashes and exact digest. Pages contain at most 25 chants or one comment; zero-report parents must be covered. Pending, reviewed and dismissed are valid report states, but only pending counts. Unknown, missing or resolved states stop the page for investigation. Overflow beyond 500 reports or 1,000 visible comments stops the target. Never increase bounds or skip a failure automatically.
7. Apply only that reviewed digest. There is no automatic all-pages apply:

```bash
node functions/lib/report_repair_cli.js apply \
  --project chants-f95b4 \
  --source-sha "REPLACE_WITH_REVIEWED_40_CHARACTER_SHA" \
  --credential "REPLACE_WITH_ABSOLUTE_OWNER_ONLY_CREDENTIAL_PATH" \
  --cutover "REPLACE_WITH_ABSOLUTE_OWNER_ONLY_EVIDENCE_PATH" \
  --plan "REPLACE_WITH_THE_SAME_ABSOLUTE_PRIVATE_PAGE_PATH" \
  --digest "REPLACE_WITH_REVIEWED_64_CHARACTER_DIGEST"
```

8. Complete means counter, necessary parent count, deterministic audit and readback all succeeded. After ambiguous acknowledgement, retain the same page/digest and inspect its checkpoint. Changed generation, source, parent or audit, or expired evidence, stops further work. If evidence expires after apply but before readback, the checkpoint remains applied, not complete. Refresh actual observations before resuming the same compatible plan; never roll generation back to make a stale plan pass. Investigate applied/incomplete work and obtain a new reviewed plan if needed.
9. After every page target completes, plan the next page using its exact `--after` cursor and a new private filename. Repeat with `--kind comments`. A full-size page requires another explicit page, including an empty terminal page, to prove the end. Preserve the complete start-to-end page chain for both collections. One successful page cannot establish whole-collection coverage.
10. Independently verify both target inventories, full repair/readback, source-trigger convergence, dependencies, retained-job replay and the approved observation window. Only a separate generation-increasing transition can reopen admission. Historical false hides remain human moderation; repair never unhides.

Plans and checkpoints contain private target IDs. Never paste them, raw reports, credentials or production payloads into Git or review artifacts. Record aggregates and evidence references only.

| Signal | Healthy | Degraded | Owner or action |
|---|---|---|---|
| Public browse | Current visible chants load; transient cache states are labelled | Permission errors, authoritative absence, or repeated load failure | Confirm deployed rules, indexes, client version, and Firestore availability |
| Live actions | Vote, comment, report, feedback, share, and new save obey current authority | Repeated callable or rule rejection for a valid current target | Confirm Auth, App Check posture, rules, Functions, target visibility, and client compatibility |
| Counters | Stored child rows and visible totals converge | Score, comments, likes, user reports, or flags remain inconsistent | Run read-only diagnosis first, then use the reviewed reconciliation path that matches the counter |
| Published media takedown | Removed performances are unavailable and no deletion job remains after Storage cleanup | A `performanceMediaDeletionJobs` row persists, source eligibility is stale, or removed media resolves again | Preserve terminal state, inspect exact job identity, and retrigger only the reviewed worker |
| Account deletion | Accepted jobs advance and pending accounts remain gated | A job remains in one phase, retry count grows, or a pending user regains authority | Preserve job state, inspect worker error without exposing payloads, and use forward recovery |
| Saved Matchday Songbook | Same user can reopen saved copies without network | Corrupt, UID-mismatched, missing, or cleanup-locked local state | Use the built-in recovery or removal path; do not hand-edit application files |
| Crash and error telemetry | No new release-correlated spike | Crashlytics or Function errors rise after a change | Stop rollout, identify exact version and first failing journey, then choose rollback or forward fix |
| Abandoned staging | No `cleanup_pending` draft remains after the next daily cleanup; ordinary uploads are newer than 24 hours | Cleanup reports an invalid row or Storage or finalization failure | Keep media admission closed, inspect through authorized consoles, and correct the exact state or path boundary before retry |
| Retained deletion jobs | No account-deletion job remains unchanged for 30 minutes and no performance-media-deletion job remains unchanged for 15 minutes | The `stale-deletion-jobs` signal fires | Confirm worker deployment and error class, preserve terminal state, then use the matching forward-recovery path |
| Seed identity | Read-only preflight reports no collision and reviewed IDs remain stable | A live ID is owned by a different source or a rename would create a duplicate | Stop before writes and prepare a migration-specific Lane 2 plan |

## Launch control thresholds

| Control | Approved initial value | Meaning and response |
|---|---|---|
| Abandoned performance draft | `awaiting_upload` or `cleanup_pending`, at least 24 hours old, daily page of 100 | Stop new media admission if invalid or failed cleanup persists; never include active review or approved states |
| Account-deletion backlog | No `updatedAt` progress for 30 minutes | Investigate the private phase and worker error through authorized access |
| Performance-media-deletion backlog | No `updatedAt` progress for 15 minutes | Confirm the performance remains removed, then repair the exact-path worker without reopening media |
| Backlog alert payload | At most 100 rows plus a more-than-limit bit per collection | Notifications contain aggregate counts only, never IDs, paths, or user content |
| Cloud Billing budget | USD 25 monthly; actual 50, 75, 90, 100 percent; forecast 100 percent | Alert-only. Review Storage, egress, Functions, and abuse before changing product availability |
| App Check observation | 1 to 2 weeks of valid iOS and Android release traffic before enforcement | Keep products unenforced until legitimate requests are classified and device gates pass |

Crashlytics and general Function-error alerts begin with event detection rather than an invented error-rate objective. During beta, record a real baseline and then add a separate approved rate or crash-free threshold. A budget alert does not cap spend and never authorizes automatic billing disablement.

## First response

1. Confirm the exact environment, app version or commit, affected account class, start time, and user-visible impact.
2. Check recent merges, deployments, rules, Functions, index changes, seed writes, and configuration changes.
3. Preserve minimal evidence without storing credentials, personal data, report text, or raw production payloads.
4. Reproduce against local tests or an authorized emulator when possible. Do not use production writes as a diagnostic probe.
5. Choose the smallest compatible mitigation: stop a rollout, disable a risky entry point, redeploy a reviewed prior server boundary, ship a forward client fix, or use an existing reconciliation path.
6. Verify recovery from the affected user journey and authority boundary, not only process health.
7. Record the incident or substantial correction in `docs/EXECUTION.md`; promote a reusable lesson only after evidence supports it.

## Common symptoms

### Public content does not load

- **Likely causes:** Firestore outage, missing index, deployed rules mismatch, permission denial, target removal, or incompatible client query.
- **Diagnosis:** Reproduce the exact query in an authorized emulator; inspect current rules and indexes; distinguish a transient error from typed permission denial and authoritative absence.
- **Mitigation:** Restore a compatible rules, index, Functions, and client set. Do not weaken read authorization merely to make a query pass.
- **Recovery verification:** Signed-out and signed-in browse load current visible content; hidden and removed content stays absent; cache-only content remains labelled and non-actionable.
- **Escalate when:** A broad rules rollback would reopen private collections or direct-write boundaries.

### Valid users cannot submit or interact

- **Likely causes:** Auth expiry, App Check enforcement mismatch, pending deletion state, rate budget, hidden or removed target, callable deployment mismatch, or restrictive rules deployed before a compatible client or Function.
- **Diagnosis:** Identify the exact action and typed error. Verify target visibility and deletion state. Compare deployed boundary order with the relevant decision and change rationale.
- **Mitigation:** Fix deployment compatibility or the narrow failing boundary. Do not bypass pending-account, report-budget, or current-target checks.
- **Recovery verification:** The valid action succeeds, duplicate or rate-limited input remains deterministic, entered report or feedback work is preserved on failure, and unauthorized direct writes still fail.
- **Escalate when:** The correction would change authorization, moderation, privacy, or stored schema without a reviewed Lane 2 plan.

### A visible counter is wrong

- **Likely causes:** Trigger delivery lag or failure, missing parent during a child event, unreviewed manual write, or a defect in aggregate reconstruction.
- **Diagnosis:** Compare the parent aggregate with its stored child documents using read-only access. Identify which counter owner and trigger applies.
- **Mitigation:** Use or extend a reviewed ground-truth reconciliation path. Never patch the counter from the client.
- **Recovery verification:** Recomputed totals match stored children and remain correct after duplicate and reordered test delivery.
- **Escalate when:** Reconciliation would scan an unbounded production population or overwrite data whose source of truth is unclear.

### An account-deletion job does not finish

- **Likely causes:** A bounded page failed, Auth deletion failed transiently, a delayed writer appeared, or the worker reached its retry limit.
- **Diagnosis:** Inspect the private job phase, cursor, retry metadata, and minimal error classification through authorized operator access. Confirm the pending profile remains authoritative.
- **Mitigation:** Correct the failing compatible boundary and retrigger the idempotent worker. Do not delete the job, clear the pending marker, or restore local data to guess at acknowledgement.
- **Recovery verification:** The worker advances through all phases, private data is removed, retained contributions and allowed audit history satisfy the anonymization contract, Auth deletion tolerates already-missing users, counters converge, and the final job and profile disappear atomically.
- **Escalate when:** Progress requires changing retained-data policy, audit allowlists, or the durable job schema.

### Published media remains after terminal removal

- **Likely causes:** The retry-enabled deletion trigger failed, deployed Function and rules versions are incompatible, the job contains malformed historical data, or the Storage object is already absent while job acknowledgement failed.
- **Diagnosis:** Through authorized operator access, verify the performance is `removed: true`, the job ID equals the performance ID, and `mediaPath` equals `performance-media/{performanceId}/source`. Check the worker's minimal error classification without copying user media or signed URLs into repository records. Also verify that new app and public media resolution is denied.
- **Mitigation:** Preserve the removed projection and deterministic job. Correct the compatible worker or permission boundary and retrigger its idempotent handler. Do not unremove the performance, delete the job by hand, weaken Storage reads, or substitute a different path merely to clear the queue.
- **Recovery verification:** The exact object is absent, the deletion job is gone only after cleanup, repeated worker delivery succeeds harmlessly, ordinary and signed-out resolution stays unavailable, and operator audit still records the terminal action.
- **Escalate when:** The job identity is malformed, cleanup would target any path other than the exact performance source, or retry requires a retention-policy change.

### Abandoned staged media is not cleaned

- **Likely causes:** The daily scheduled Function is not deployed, its composite index is not ready, Storage deletion failed, final document deletion failed, or a malformed server-owned draft did not match its exact path.
- **Diagnosis:** Confirm the schedule and deployed source. Read the aggregate cleanup error first. Through authorized access, inspect only the affected private draft state, creation time, owner identity, and exact `performance-staging/{ownerId}/{draftId}/source` path. Do not copy the media, signed URL, or identity into project memory.
- **Mitigation:** Keep new performance admission closed if the failure is systemic. Correct the index, permission, or exact-path worker and let `cleanup_pending` retry. Do not reset the state to `awaiting_upload`, delete an unverified path, or include `pending_review` and approved rows in cleanup.
- **Recovery verification:** A rerun treats a missing object as success, deletes the claimed draft only after Storage cleanup, produces no private identifier in logs, and leaves active or moderated drafts unchanged.
- **Escalate when:** The stored owner and path disagree, a row uses an unknown schema, more than 100 stale rows persist, or recovery requires deleting media whose identity is uncertain.

### Performance eligibility or creator totals are stale

- **Likely causes:** A creator or chant fan-out trigger failed, a deployed index or schema is incompatible, or exact count reconstruction timed out at unexpected volume.
- **Diagnosis:** Read the current private creator authority, public creator state, chant state, dependent `sourceCreatorVisible` and `sourceChantVisible` flags, and live performance rows. Distinguish a stale projection from current source truth. Do not use a cached card as evidence of current authority.
- **Mitigation:** Keep server actions and public resolvers on current-source checks. Retrigger or run the reviewed source reconciliation path after correcting the failure. Never patch source flags or `performanceCount` from the client.
- **Recovery verification:** Dependent flags match current creator and chant eligibility, chant title and trust status are current, feed queries exclude ineligible rows, and the creator total equals approved, unhidden, unremoved rows with both source flags true.
- **Escalate when:** One creator or chant has enough dependent rows that fan-out or exact reconstruction approaches Function, transaction, or cost limits.

### A seed preflight reports a collision

- **Likely causes:** A reviewed ID was changed, live content predates explicit ownership metadata, or a source file points at an ID owned by another club or chant.
- **Diagnosis:** Stop before writes. Compare reviewed JSON, planned operations, live document identity, and the last known seed record through the authorized read-only preflight.
- **Mitigation:** Prepare a migration-specific plan with coexistence, rollback, and link implications. Do not rename IDs or rely on title-derived identity.
- **Recovery verification:** The plan is collision-free, a title rename preserves the document ID, a second run is idempotent, and the reviewed source round-trips.
- **Escalate when:** Any existing public or externally referenced identity would change.

### Prepare and verify a live seed rollout

- **Prerequisites:** Work from an exact reviewed source head. Keep the Firebase Admin JSON only at ignored path `seed/serviceAccountKey.json` with owner-only file permissions. The CLI accepts only project `chants-f95b4`; never paste, print, stage, or record credential contents.
- **Refresh the roster gate:** Save the official bootstrap response outside the repository, then run `cd seed && npm run roster:check -- /absolute/path/to/bootstrap-static.json`. Require exactly 20 clubs, 622 reviewed rows from 623 raw rows, 17 reviewed display aliases, three owner membership overrides, and zero unreviewed differences. Any new difference returns the work to content review.
- **Run read-only identity checks:** From `seed/`, run `npm run seed -- --preflight-only arsenal.json`, then `npm run seed -- --preflight-only`. Both commands are read-only. Stop on any collision, credential mismatch, rejected access, timeout, or ambiguous result.
- **Establish the baseline:** From `seed/`, run `npm run seed -- --readback-only`. Missing rows are expected before a new-club rollout; mismatches and orphans require diagnosis. Record only aggregate counts and source-safe IDs or field names, never raw production documents.
- **Arsenal reconciliation hold point:** Only after exact-head source review and explicit production approval, run `npm run seed -- arsenal.json`, then `npm run seed -- --readback-only arsenal.json`. If the only remaining differences are the three approved unreferenced departures, run `npm run seed -- --retire-approved-arsenal-players`, then repeat Arsenal readback. The retirement mode accepts no club argument, targets only the three reviewed IDs, rechecks exact Arsenal identity plus zero chant references in one transaction, and treats already-absent targets idempotently.
- **Canary hold point:** Do not run a normal seed command merely because preflight is clean. After explicit owner release, the bounded canary command is `npm run seed -- leeds-united.json`, followed immediately by `npm run seed -- --readback-only leeds-united.json`. Widening requires an exact canary and a separately recorded bounded sequence.
- **Widening sequence:** The 2026-08-30 rollout used six groups of three: Aston Villa, Bournemouth, Brentford; Brighton and Hove Albion, Chelsea, Coventry City; Crystal Palace, Everton, Fulham; Hull City, Ipswich Town, Liverpool; Manchester City, Manchester United, Newcastle United; then Nottingham Forest, Sunderland, Tottenham Hotspur. Each group passed preflight, wrote only its named files, and completed exact same-group readback. Do not treat this history as standing write permission. Any rerun or new write still requires explicit authorization and the same stop conditions.
- **Recovery:** A failed or ambiguous write stops the rollout. Run readback-only before deciding whether a retry is safe. Correct allowlisted source content and rerun only the affected club. Never improvise deletion, rename a stable ID, or remove an orphan without a separate exact-target destructive plan.
- **Escalate when:** The credential names another project, any source-owned field mismatches, an unexpected orphan exists, a stable identity would change, a write result is ambiguous, or recovery would delete data.

### Run the configured-device catalogue check

#### Local preparation before the live gates

The maintained private guide is `docs/CHANTS_LAUNCH_COMMAND_CENTER.html` with adjacent `docs/launch-command-center.js`. Keep the pair together. Its stage 0 contains local setup commands; stage 6 contains ordered iPhone/Android observations and a copyable report. Do not serve this private guide from public Hosting.

From the checkout containing the helper:

```sh
node scripts/check-device-readiness.mjs --platform ios
node scripts/check-device-readiness.mjs --platform android
# Optional local discovery, no build/install/Firebase calls:
node scripts/check-device-readiness.mjs --platform ios --devices --json
```

The default checks file presence/readability and executable locations without reading config contents or invoking SDK tools. `--devices` opts into bounded local discovery, which may start OS/ADB services; only counts and states are emitted. Exit 0 means no inventory issue, 1 means missing/unknown/attention, and 2 means invalid usage. None grants live-test or release authority. Config identity, tool compatibility, provisioning and signing remain unverified. The helper resolves its own checkout, not Terminal's current directory.

The fresh `chants-device-test-preparation` worktree has no copied Firebase configuration or Flutter package setup. The configured files remain in `chants-v1-seed-live-rollout`. Arrange explicit client-configuration/dependency setup before running the new checkout; do not overwrite existing files with examples or access the Admin credential for a device check. Use `flutter devices` and then one explicitly selected target only after the backend and test gates below. Keep the debug session for hot reload; do not archive repeatedly for layout edits.

The guide's result record is self-reported, not release approval. Fill candidate source, backend record and per-platform build references. Context changes make old results stale; notes do not renew a pass. Use Record result after observing/retesting and inspect the copied report for secrets. Browser storage may be unavailable; the page says so. Visual/browser verification of this new guide is pending because Browser Use rejected the local-file URL; source/logic tests are not a substitute.

#### Configured-device catalogue journey

The production seed is exact. This check verifies the mobile presentation and navigation, not the lyrics again. It is not a store-release sign-off.

Before running:

1. Confirm the backend rollout is approved and verified. On 2026-08-30 production had only nine of the 48 source Functions; `completeOnboarding` was absent. A new-account walkthrough cannot pass against that baseline. Do not bypass onboarding or create profile documents manually.
2. Connect and unlock the iPhone. Certificate setup was completed by the owner on 2026-08-30: an Apple Development certificate plus Apple's WWDR G3 intermediate now produce one valid code-signing identity. Do not create another certificate or remove the old one. Provisioning and installation still need verification. Keep team `J7V95LBCWR` and bundle `com.chants.chants`; do not switch personal teams, override certificate trust, or remove entitlements to force a run. Any further credential step remains owner-controlled. [Apple signing guidance](https://developer.apple.com/documentation/xcode/sharing-your-teams-signing-certificates).
3. Confirm the local Dart, iOS, and Android Firebase client configurations all identify `chants-f95b4` and remain ignored. The prepared files are in `chants-v1-seed-live-rollout`; the older checkouts' Dart placeholders must not be reused.
4. Run from the prepared checkout. If Flutter asks which target to use, select the physical iPhone, not Chrome or macOS. The first build is still a native build; later debug changes can use hot reload without rebuilding from scratch.

```sh
cd /Users/andrewbolaji/Desktop/projects/chants/chants-v1-seed-live-rollout
flutter devices
flutter run --no-pub
```

Catalogue walkthrough:

1. Sign in yourself with the intended test/owner account. Keep passwords, verification codes, and App Check debug tokens out of the task and repository.
2. Tap **Clubs** in the bottom navigation and scroll through the full 20-club list. Missing, duplicated, or permanently loading club cards fail the check.
3. Open Arsenal and Leeds United. Their reviewed Songbook counts are 12 and six chants. Open a chant, read through it, return to its club, then open a player-linked chant through the player route. Check club/player association, lyrics layout, tune/context text where supplied, and trust labels.
4. Open at least one club from the final rollout group, Nottingham Forest, Sunderland, or Tottenham Hotspur, and open a chant. This samples the end of the widening sequence. It does not claim visual inspection of every one of the 192 chants.
5. Confirm Songbook and Chant Lab are distinct. Empty community content is not evidence that the canonical seed is missing. Switch bottom tabs and return to **Clubs**; the app must retain usable navigation and avoid a stuck loading state.
6. Report a pass or the exact screen/action and visible error. Record source head, app build, platform, and observed paths without account identifiers. Do not rerun seed commands to repair a client or backend-deployment error.

The broader authentication, media, moderation, sharing, deletion, and airplane-mode walks remain separate release gates. Initial preparation lacked a valid signing identity and backend parity. The owner has since completed the certificate step; backend parity, device provisioning, and physical-device observations remain open.

### Saved matchday content is unavailable offline

- **Likely causes:** Snapshot was never saved, UID changed, local file is corrupt or from a future schema, deletion lock is active, or the operating system removed application data.
- **Diagnosis:** Reproduce with the same signed-in UID, then use the product's labelled local recovery state. Distinguish a missing local copy from a live refresh failure.
- **Mitigation:** Refresh while online or remove and save again when current authority permits. Preserve deletion locks and UID isolation.
- **Recovery verification:** Force-stop, enable airplane mode, relaunch, open overview, club, and chant detail, then confirm freshness and saved-copy labels remain visible.
- **Escalate when:** Recovery would require cross-account file access or bypassing an account-deletion marker.

## Rollback and forward recovery

- **Application:** Stop distribution of a bad candidate and ship a corrected build. Store rollback mechanics and signed artifact ownership are not yet documented.
- **Configuration:** Restore a reviewed compatible configuration through the owning Firebase or store console. Record the exact before and after values without copying secrets.
- **App Check:** Registration can remain while enforcement is disabled. If valid release traffic is misclassified, disable enforcement first, preserve metrics, correct the provider or signing identity, and repeat the observation window.
- **Alerts and budget:** Disable a noisy policy before deleting its notification channel. Edit or remove an incorrect budget without disabling billing. Treat any automated service shutdown as a separate destructive action.
- **Rules and Functions:** Verify deployed baseline first, then deploy a reviewed compatible prior or forward version. For performance-source eligibility, deploy compatible rules and Functions before the client. CI success does not prove deployed parity.
- **Schema and data:** Prefer backward-compatible additions and forward recovery. Stable seed identity, account deletion, counters, and safety records each have specific decisions that take precedence over generic rollback.
- **External side effects:** Native sharing and evidence links leave the app boundary. Chants cannot recall third-party copies, browser history, or recipient data.
- **Source-disabled merge:** Reviewed `mergeChants` stops before parsing or mutation. The actual July deployment recovered on 2026-08-30 lacks that guard; do not invoke the live endpoint. Deploying the reviewed stop requires the approved rollout, and restoring the old active merge is not incident recovery.

## Backup and restore

- **Backup policy:** No source-backed Firebase backup, point-in-time recovery, or export policy is verified.
- **Last restore exercise:** None recorded.
- **Restore steps:** Not approved. Before public launch, document the configured Firebase backup surface, retention, access owner, restore target, and a dated non-production restore exercise.

## Post-incident

- Record timeline, impact, affected versions and boundaries, detection gap, mitigation, recovery evidence, and durable actions.
- Give each action an owner, trigger, and verification method.
- Keep private reports, credentials, identities, and raw production payloads out of repository records.
