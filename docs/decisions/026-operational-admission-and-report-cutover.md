# Decision 026: Operational admission and report cutover

- **Status:** Accepted in source; packaging is separately authorized, production use is not
- **Date:** 2026-08-31
- **Approval:** Andrew approved the deployment-safety specification and its two-lookup Storage amendment on 2026-08-30.
- **Scope:** The existing 48 Function identities, direct-write rules, repository seed writers, upload permissions, retained cleanup, and bounded report repair.

## Context

Production still runs nine July Functions. Its report-created handlers increment blindly and its merge handler lacks the reviewed stop. Current source cannot safely replace those event types with overlapping handlers or restore that predecessor as blanket recovery. Rules do not constrain Admin SDK writers.

The old Storage upload path also used three distinct Firestore documents. Firebase documents a two-document limit. Five successful old emulator tests did not establish that production quota. Adding a global control without redesigning the permission would require four documents.

## Decision

Use one private `operationalControls/v1` document: exact schema version 1, positive safe-integer generation, mode maintenance/core/media, and a destructive-worker flag. Missing, malformed or unreadable means closed. Media requires worker readiness. The 48-name `ENDPOINT_ADMISSION` table is checked against compiled endpoints. Nineteen permitted Firestore write expressions check the control first. Existing reads and per-account authority remain.

This is admission control, not cancellation or an Admin-wide lock. Already admitted operations, URLs and uploads may finish. Aggregate/source reconcilers and monitoring remain active so safety state can converge. The merge runtime stop remains unconditional. Every approved mode or flag transition must increase generation; readers validate its shape, not historical monotonicity. No control writer or IAM fence is included.

Co-locate one authoritative `activePerformanceUpload` grant with the owner's private profile. Grant issue reads current account and deletion-job state and commits the draft, budget and grant together. Legacy profiles get explicit `deletionPending: false` only after that transaction confirms no deletion job. No permission is inferred from a legacy draft. Storage now reads control plus profile only.

The grant binds owner, draft, path, bytes, MIME, generation and a 30-minute lifetime. One unexpired slot per account prevents silent cross-device replacement. Submit, cancel, moderation, deletion acceptance, ban and cleanup revoke only matching permission; stale cleanup cannot clear a newer grant. Submit checks current generation and expiry before entering review. Missing/malformed permissions fail closed.

Event-only deleted-draft cleanup first retains the exact path in private `deferredDraftCleanupJobs/{draftId}`. Paused work stays pending. A completed removal attempt is marked attempted, never permanently cleaned: an admitted transfer can finish late. No mode toggle replays historical jobs. The later rollout must inventory retained paths, choose a bounded replay and retention policy, and prove cleanup after the chosen transfer-drain window.

Report repair is a local plan/apply tool, not a deployed endpoint. It pins project, source SHA, maintenance generation and reviewed digest. Pages cover parents, including zero-report parents. Chant pages allow 25 targets; comment pages contain one because comments can share an exact parent-count precondition. Reads refuse overflow at 500 reports or 1,000 visible comments. Repair changes only flags, necessary false-to-true hiding, and the parent visible-comment count.

Counter, parent count, deterministic privacy-safe audit and applied checkpoint commit together. A separate transaction verifies source fingerprints, target, parent and audit before marking complete. Lost acknowledgements resume the same identity. Changed state requires investigation or a new reviewed plan, not automatic widening or unhide.

The cutover validator requires evidence for nine pause surfaces and exactly the two written-event replacements in europe-west2 compute and nam5 events. It never changes traffic, deletes Functions, deploys, repairs automatically or opens admission. Evidence references and coverage booleans are operator attestations, not independent proof of live containment or whole-database completion.

## Alternatives and consequences

- A mirrored global-open flag on draft rows would not provide an immediate current check. Removing account checks would weaken authority. A new upload gateway would expand the client protocol. The single-profile grant preserves Firebase upload integration within the documented limit.
- A general flag platform, unlimited upload slots, automatic repair loop, bulk job replay and deployment executor are unnecessary for this source block.
- A maintenance read adds latency and billable work. Grant issue/submit also read control transactionally. No production latency or cost claim follows from emulator timings.
- The 30-minute slot is deliberate friction. Existing selected media stays available in the form, with pause, occupied-slot, expiry and recovery copy. Expiry bounds new permission, not an in-flight transfer.
- A one-comment page costs more operator steps but avoids one planned correction invalidating another on the same parent. Never advance a cursor past a failed or unread-back target.
- Retained cleanup paths include owner identity and require restricted retention. Existing cancelled/rejected draft rows also retain paths; this block does not invent an automatic sweep for every terminal state.
- An operator can still bypass the source interlock through old scripts, console writes, old revisions or a generation rollback. Real containment, drain evidence, bounded replay and source review are production gates.

## Evidence and revisit triggers

`functions/test/operational_gate.test.ts` exercises real wrappers and a deliberately bypassed gate. `test_rules/storage_budget.test.ts` detects a third lookup in a helper, independently of emulator acceptance. Rules tests cover closed/open direct writes and upload bindings. Real-emulator repair tests cover transaction conflicts, lost acknowledgement, altered audit, stale generation, overflow, cursor bounds and retained cleanup. Exact counts and final verification are in the scoped rationale and execution log.

Revisit before increasing slots, adding an endpoint/writer or rule branch, changing account/draft transitions, replaying retained work, expanding repair bounds, altering Firebase quota behavior, or opening public media. Any production cutover needs a fresh approved plan with precise commands, identities, containment, observation and forward recovery.
