# Change spec: V1 deployment safety and report cutover controls

**Status:** Approved for source implementation, including the Storage authorization amendment. Production use remains unauthorized.
**Updated:** 2026-08-31
**Implementation state:** Implemented and locally verified. Packaging and exact-head CI were authorized on 2026-08-31 UTC; their result is recorded in PR 25 after this precommit snapshot. Independent review and all production actions remain gates.
**Risk lane:** Lane 2 source controls and emulator rehearsal; actual cutover requires a separate Lane 3 approval
**Base:** `d7b8b6fe9c421e321ada2790c9410d52f1f81cc8`, draft PR 25
**Approval:** Andrew confirmed `yes` on 2026-08-30 after the explicit clarification naming this deployment-safety and report-cutover spec, not the prior readiness spec.
**Prior contract:** The approved readiness spec is preserved at this base. Its inventory and conditional 48-Function sequence remain in `docs/changes/2026-08-30-v1-backend-rollout-readiness.md`.

## Outcome and authority

The app is built, but production still runs the old nine-Function backend. Two old report handlers blindly increment counts; current source reconstructs them. Prepare a verified pause, bounded counter repair, and server-side admission controls so partial rollout cannot admit work without its dependencies.

Original approval authorizes source implementation, synthetic local/emulator verification and records. Andrew separately authorized one commit, push and exact-head CI on 2026-08-31 UTC. No deployment, production control write, IAM/service change, bucket creation, trigger deletion, account/media deletion, historical-job replay, seed write, provider enablement, device installation, merge or release is authorized.

No product expansion, dependency update, new permanent public repair endpoint, catalogue/lyric change, or Function rename. Preserve the 48 final identities, compute region, event paths/location, current account authority, and unconditional merge stop.

## Design

### Approved amendment: Storage lookup budget

**Approved by Andrew on 2026-08-30.** The pre-build integration check invalidated the original upload portion before runtime edits began.

- Firebase documents a maximum of two distinct Firestore document lookups per Storage request. The current `accountIsActive` and `ownsUploadTicket` path in `storage.rules` reads `profiles/{uid}`, `accountDeletionJobs/{uid}`, and `performanceDrafts/{draftId}`. Adding `operationalControls/v1` would require four. Repeated access caching does not combine distinct documents. [Official Storage limits](https://firebase.google.com/docs/rules/rules-behavior#security_rules_limits_1), [cross-service quota explanation](https://firebase.blog/posts/2022/09/announcing-cross-service-security-rules/).
- The five existing Storage tests pass locally on the unchanged rules, including the successful first-upload case. That is Boolean/behavioral emulator evidence, not proof of the documented production lookup budget. No production upload was attempted; the production impact is inferred from source and the official limit.
- Simply removing current account checks weakens authority. Mirroring an open global mode asynchronously into tickets does not provide the required immediate check for a newly initiated upload. Adding a separate upload gateway would change the client transfer protocol and expand the endpoint contract.

Recommended bounded amendment, preserving direct Firebase uploads and all 48 Function identities:

1. Put one server-owned, versioned `activePerformanceUpload` grant on the existing private account profile. Store only exact ticket bindings: draft identity, owner/path, allowed bytes and MIME, issued/expiry time, and operational-control generation. It is authoritative upload permission, not an asynchronously copied account-status flag. Keep the full content draft in `performanceDrafts`.
2. Mint the grant atomically with a newly created draft after current account, deletion-job, creator, chant, limit, and global-control checks. Permit one outstanding upload per account, including across devices. An unexpired existing grant causes an actionable rejection rather than silently replacing another upload. Existing uploaded or pending-review videos do not occupy the slot.
3. Storage upload authorization reads exactly the global control and the owner's private profile. It checks fresh ban, age, policy, explicit deletion state, grant bindings/expiry/generation, metadata, maximum size, type, and first creation. Missing or malformed fields deny. There is no third draft or deletion-job lookup on that path.
4. Clear the matching grant in the same transaction as submit, cancel, or any transition out of upload eligibility. Deletion acceptance already writes `deletionPending` with its job; extend it to revoke the grant atomically. A ban is immediately observed through the same profile. A stale cleanup must never revoke a newer draft's grant. Inspect every draft mutation/deletion writer and record coverage before claiming this invariant.
5. Keep deletion-job checks in the server grant issuer and subsequent submit/approval boundaries. Existing jobs or malformed account state cannot obtain a grant. Do not backfill permission from old drafts; legacy tickets without the new grant remain closed and require a fresh authorized attempt. Owner and operator read permissions are not broadened.
6. Grants last 30 minutes from server issuance, comfortably below the existing 24-hour abandoned-draft cutoff. This bounds permission and slot occupancy, not transfer duration. The existing cancel/retry path remains available; a concurrent request receives the outstanding draft identity so it can be cancelled deliberately. Expiry/revocation prevents a newly authorized request; it does not cancel an already admitted transfer. Retain the original in-flight-work and deferred-cleanup requirements, and test late completion rather than promising instant revocation.
7. Add an explicit two-document rule dependency check with a known-bad third-document mutation, plus emulator and transactional tests for grant issue, concurrency, tampering, ban/deletion, expiry, close/reopen generation changes, cancellation, submission, and stale cleanup. A green emulator suite alone is insufficient budget evidence. Real Storage smoke testing remains a separately authorized rollout gate.

Expected additional footprint: a bounded private-profile field and grant helper, draft/account-deletion/cleanup transactions, Storage rules, focused tests, and any necessary existing upload-screen error handling. No new collection, service, dependency, permanent endpoint, or general multi-upload manager. No lyrics/catalogue changes and no production actions. The original source block resumes under this approved amendment.

### One private operational control

Introduce one versioned, server-owned document at `operationalControls/v1`, with client reads and writes denied. This is an operational interlock, not a general remote feature-flag platform.

- Allowlisted fields: `schemaVersion: 1`, monotonic integer `generation`, `mode: maintenance | core | media`, and `destructiveWorkersEnabled: boolean`. Missing, malformed, unsupported, or unreadable control means closed. Media mode requires workers enabled. No cached-open fallback across invocations.
- Maintenance denies client Firestore mutations, including operator writes, and mutation callables before their handlers. Preserve existing read permissions without widening them.
- Core enables existing nonmedia journeys only. Media admission, approval, playback-session creation, interactions, and public performance resolution stay closed. Media mode enables those paths only under their existing authority and limits.
- Storage upload creation reads the same control in addition to every ticket, owner, byte, and MIME check. An old ticket cannot start a new upload after closure. This is not cancellation of an in-flight upload or revocation of an issued signed URL.
- Account-deletion requests require worker readiness. Account/media deletion workers and abandoned-draft cleanup require both nonmaintenance mode and explicit worker enablement. Maintenance overrides that flag. Preserve jobs and source documents; never mark unprocessed work complete.
- Read-only monitoring may run independently. Existing aggregate and source-eligibility reconcilers may run during maintenance to drain and restore safety. Classify them explicitly instead of dropping all events.
- Opening a mode never re-enables `mergeChants`.

Read control only when handling an operation, never during module import or Firebase deployment discovery. For event-only cleanup such as `onPerformanceDraftDeleted`, a paused success return would lose the only cleanup instruction. Persist a deterministic private deferred-cleanup record before acknowledging, or refuse that activation until an explicitly reviewed durable path exists. Do not assume retry alone preserves work indefinitely. Test pause/resume for this case separately from workers that already have job documents.

Maintain an exact classification table and a test over all 48 compiled endpoints, including anonymous HTTP, job, and scheduler wrappers. New or unclassified endpoints fail the contract. Preserve authentication errors and private-authority checks. An authenticated paused callable returns a stable `unavailable` maintenance reason without disclosing internal configuration.

Gate every permitted direct-write expression: sports, competitions, teams, players, allowed profile updates, chants, votes, comments, comment likes, and blocks. Include separate operator and delete branches. Existing deny-only collections stay denied. Test Firestore/Storage document-access budgets, not only Boolean helpers.

### Pause, containment, and drain

A control read does not cancel an already-running handler. Rules do not constrain Admin SDK writers. Do not advertise the interlock as an instantaneous global lock.

Build a testable cutover state machine and surface ledger for client writes, `onModerationAction`, `deleteAccount`, `mergeChants`, report intake, deletion workers, and repository Admin/seed writers. Repository writers must refuse mutation during the cutover while preserving read-only preflight. Source cannot fence an unmodified script or console session: external Admin writers require a separately approved containment decision.

The later rollout must first install and verify gated existing mutation callables, preserve the merge stop, close client writes, and keep new workers/intake unactivated. Before baseline/repair, account for old revisions, traffic and alternate invocation paths, in-flight requests, queued delivery, and external writers. Record exact runtime timeouts and required observation for each surface. Neither a fixed sleep nor quiet logs alone proves the pause.

Google documents that traffic changes are not instantaneous and in-flight requests continue. That requires live verification; a unit test cannot prove live quiescence. [Cloud Run traffic transitions](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration).

If complete containment and drain cannot be proved, stop before deletion. A compatibility alias, overlapping old incrementers, or broad credential revocation requires an amended approved design.

### Bounded report-counter repair

Create a local operator tool with an injected Firestore adapter and credential-free tests. Default to plan-only; no new deployed callable or automatic real connection in tests.

1. Require explicit project `chants-f95b4`; reject mismatches, unknown options, and unresolved identity before constructing a writer. Apply needs its own explicit mode and exact reviewed plan digest.
2. Plans identify source SHA, schema, control generation, target scope, bounds, expected state, and cursor. Keep private plans ignored and owner-readable. Logs and durable records contain aggregates, not reporter identity or text.
3. Page chants and comments by document ID, at most 25 parents per invocation. Include parents with zero reports. Scanning only existing reports misses inflated counters that must become zero. Missing parents or malformed relationships are findings, not permission to invent/delete documents.
   Implementation stays within this ceiling: 25 chants or one comment per page. Comments may share a parent counter, so a one-comment page preserves exact reviewed parent preconditions without allowing earlier writes in the same page to invalidate later targets.
4. Recompute pending-report totals in parent-serialized transactions, reusing the existing ground-truth definition. Limit per-parent reads to 500 plus one overflow sentinel. On overflow, refuse the target; never truncate and publish a partial total.
5. Each apply transaction checks maintenance, expected control generation, and relevant source/target preconditions. Reopening, stale plans, changed relationships, or exceeded bounds stop further work. These checks supplement the verified drain of previously admitted Admin work.
6. Write only `flagCount`, necessary false-to-true `hidden` at the existing threshold, and required parent `commentCount`. Never unhide, restore, remove, edit lyrics, change trust/evidence, or rewrite reports. Historical false hides remain a human moderation decision.
7. Reconstruct parent counts from visible comments with a 1,000-row cap plus one sentinel. Refuse an oversized dependent repair before changing its state. Retry must also repair the parent after a partially completed comment step.
8. Use deterministic privacy-safe audit identity and resumable progress. A committed write with lost acknowledgement must not duplicate its audit. Mark a target complete only after counter, necessary parent count, audit, and readback succeed.
9. One explicit page per invocation; no automatic whole-database apply loop or promotion of plan into apply. Test any new repair audit action against deletion-retention/privacy allowlists. Preserve existing live-trigger semantics outside the operator path.

### Exact replacement and forward recovery

Only `onReportCreated` and `onCommentReportCreated` change from created to written events under their same final names. Compute stays `europe-west2`; database/events stay `nam5`. Firebase requires an explicit event-type migration, not an ordinary update. [Firebase Function lifecycle](https://firebase.google.com/docs/functions/manage-functions).

Rehearse: verified pause, old targets isolated, first replacement, second replacement, bounded repair, readback, explicit admission release. Use synthetic deployment metadata plus real emulator counter behavior. The source tool must not execute cloud deletion/deployment commands. Exact commands and live prerequisites belong to the later production amendment.

An interrupted replacement leaves admission closed and identifies the incomplete target. Recover forward to the reviewed written handler, never to old blind increments or weak rules. Current duplicate, delayed, and reordered events must converge with repair. Reopening requires both trigger inventories, complete repair coverage/readback, and dependencies, not only successful CLI exit.

Paused historical jobs require a bounded replay decision before workers open. Installing a trigger or toggling the control does not replay old documents. This block proves retained evidence is not lost; it does not build or run bulk account/media deletion replay.

## Acceptance criteria and invariants

1. Missing/invalid/unreadable controls reject protected work with no handler, upload, or destructive side effect. Open-mode tests preserve current authority and behavior.
2. All 48 endpoint wrappers and every permitted direct-write branch are classified and tested. An omitted branch or new unclassified endpoint fails.
3. Raw client/operator writes cannot bypass maintenance; old upload tickets cannot start uploads; client fields cannot select mode/generation.
4. Paused workers preserve pending evidence and do not delete accounts, media, or jobs. Reopening is not assumed to replay work.
5. The pause ledger distinguishes current source, legacy revisions, in-flight work, and external Admin writers. Missing containment blocks cutover.
6. Repair defaults to no writes, checks exact project/plan, covers zero-child parents, obeys bounds, and refuses stale or oversized targets.
7. Counter, parent count, audit, and progress retries are exercised at meaningful failure/acknowledgement boundaries. No automatic unhide or content mutation.
8. Failure after either replacement cannot reopen intake, broaden the two-target allowlist, or select the legacy bundle as rollback.
9. Known-bad mutations prove the new gates and regressions fail. Helper tests alone are insufficient evidence for exported wrappers or rules.
10. Production build, complete Functions/rules suites, affected seed tests, Flutter regression/analysis, governance, and exact-head CI pass after authorized packaging.
11. Overview, rationale, runbook, execution, and a completed scoped record separate implemented source, local rehearsal, independent review, and deployed observation.
12. One combined Claude review spans last-reviewed `cb50d3cc966c6a367309c887a8c765891155cf0e` through this block's final exact-CI head. Required findings and the separate production amendment must close before deployment.

## Failure and cost boundaries

| Condition | Required response |
|---|---|
| Closed/stale/unavailable control | Reject new protected work; preserve jobs; no cached-open fallback |
| Previously admitted or unknown Admin writer remains possible | No cutover/repair; resolve containment and drain |
| Plan or control generation changes | Abort the next write; retain resumable evidence |
| Query overflows or data is malformed | Stop affected page; no estimated count or automatic wider scan |
| Write commits but acknowledgement/audit/progress fails | Retry the same deterministic operation before marking complete |
| Current events duplicate or overlap repair | Parent-serialized reconstruction converges; preserve moderation |
| Worker paused with retained work | Keep work; aggregate blocked status; no false completion or silent endless retries |
| Live metadata differs from baseline | Stop and amend exact targets |

Uncached control reads add latency and billable work; rule lookups may also be billable. Measure synthetic/emulator per-request reads and access budgets without claiming production performance. Repair caps bound a page, not every future workload. Larger bounds need evidence and approval. USD 25 remains an alert-only budget.

## Verification plan

Use existing locked installs and suites. Add Functions tests for control parsing, compiled-wrapper coverage, side-effect short circuits, plan/apply, retries, and cutover state transitions. Add emulator cases for closed/open controls, operator branches, old tickets, zero-child parents, bounded repair, overlapping events, and interrupted resume. Add seed mutation-refusal tests while preserving read-only preflight. No production data or real accounts/media as fixtures.

## Separate production decisions

- Source approval does not resolve any of the following external choices or permit their execution.
- Exact containment of legacy revisions and external Admin writers, any narrow IAM/traffic changes, and live drain evidence.
- Maintenance timing, maximum window, abort owner, and recovery so account deletion is not left unavailable indefinitely.
- Named deploy/removal commands, durable artifact retention, resource limits, runtime/build identities, bucket location/permissions, fourteen additive indexes, compatible rules, URL signing, and schedules.
- Retained-job inventory and any replay, dedicated smoke identities/media, observation window, and approved transitions reopening core/media.
- Provider/domain/policy, App Check, real-device, store, and public-release sign-off. Development-certificate setup is already complete.
