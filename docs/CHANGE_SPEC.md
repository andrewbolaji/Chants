# Change spec: Post-combined-review deployment safety corrections

**Status:** Approved
**Implementation state:** Implemented and locally verified. One correction commit, push and replacement exact-head CI are authorized; use PR 26 for the immutable result after packaging. Independent correction review remains open.
**Date:** 2026-08-31
**Lane:** 2, source correction and synthetic verification only
**Base:** `fe0ea9232ad7d34250dee9e8429f39e3e36c6188`, draft PR 26
**Approval:** Andrew accepted the proposed F1-F5 correction block, one commit, push and replacement exact-head CI on 2026-08-30 local time. Claude reviews the finished correction range, not each individual fix.
**Prior contract:** Deployment-safety source contract remains in Git at the base; its completed rationale is `docs/changes/2026-08-31-v1-deployment-safety-and-report-cutover.md`.

## Outcome and boundary

Close the five independently reported source defects without reopening app feature work. The review of PRs 22-26 is complete at the base; this block requires a focused correction review after CI. No production access, credential inspection, seed mutation, deployment, signing, device installation, merge or release. No dependencies, endpoints, rules permissions, media protocols, public collections or replay executors are added.

## Acceptance criteria and invariants

1. Repair accepts exactly pending, reviewed and dismissed report states for chants and comments. Only pending counts. Mixed and terminal-only histories complete planning, apply and readback; unknown/missing/resolved states stop rather than skip a target. Existing bounds, cursor coverage, fingerprints and no-unhide behavior remain.
2. Delete the uncalled draft cleanup helper and test the actual retained-work handler and exported trigger, including cross-owner/path rejection.
3. Invalid event identity or an existing cleanup-path conflict leaves a deterministic blocked record in the existing private collection before a successful return. Never delete guessed media, change an unrelated upload grant, overwrite the original valid job, or silently revive a blocked source.
4. Blocked evidence contains only an allowlisted reason, source-ID digest, syntactically safe draft ID (null otherwise), schema/state and timestamps. No raw deleted payload, owner, path or caption. The separate blocked namespace cannot collide with accepted draft IDs. Duplicate delivery preserves the first record. Database failure still rejects; Storage failure leaves pending work retryable. A fixed aggregate warning identifies blocked cleanup without private identifiers.
5. The seed CI job typechecks the entire configured seed program, including seed.ts. A known-bad entrypoint type error fails the same command. No new CI job or dependency.
6. Cutover evidence schema 2 adds containmentStartedAt per surface. UTC observations must be no later than the injected current clock, at most 15 minutes old, and at least the declared maximum runtime after containment began. All revision, alternate-path, in-flight and queue attestations remain mandatory. Elapsed time alone never proves drain.
7. Every planning/apply/readback transaction binds evidence source and generation to the actual maintenance control, and apply also binds the reviewed plan. Reject stale evidence during a page or before completion; retain any already-applied checkpoint. Eliminate the CLI's self-comparison. Old schema-1 evidence must be refreshed, not silently migrated. Plans keep their schema and require fresh evidence.
8. Document owner-identifier retention inside legitimate deferred paths and the safe escalation route for malformed upload grants. No TTL, auto-clear, new grant or automatic replay.
9. Local affected tests, known-bad regressions, governance and all eight replacement clean-runner jobs pass at the new source head/tree. Independent Claude review, visual/device evidence and live gates remain separately open.

## Design and compatibility

- Keep the existing report projection/count definition and transaction architecture.
- Reuse deferredDraftCleanupJobs. Valid work retains the existing draft-ID key and schema. Permanent failures use `blocked:<sha256(draftId)>`, schema 1, state blocked and reason invalid-identity or path-conflict. Read the blocked record before valid-path execution; only an explicitly approved operator recovery may resolve it. The colon namespace is outside accepted draft-ID syntax. This is a diagnostic quarantine, not executable cleanup work.
- The cleanup handler returns a narrow disposition for the existing wrapper's fixed warning. Infrastructure errors propagate. No raw payload is retained or logged.
- Require cutover evidence and an injected clock in the internal repair APIs. Revalidate inside transactions, not only once in the CLI. Fifteen minutes is a conservative source re-observation ceiling, not a claim about cloud timeout or a production observation-window approval. The maximum runtime must come from reviewed deployed settings.
- Add npx tsc --noEmit to the existing seed job.

## Failure and abuse analysis

| Condition | Expected result | Evidence |
|---|---|---|
| Duplicate cleanup or lost database acknowledgement | Deterministic blocked/pending row; no duplicate identity or guessed deletion | Handler and exported-trigger tests |
| Wrong owner, hostile draft ID, conflicting retained path | Durable block, original job and grants preserved, zero media calls | Negative matrix and emulator |
| Transient database/Storage failure | Reject for retry; retain recoverable work | Failure injection |
| Mixed moderated report history | Count pending only, preserve reports, finish ordered pages | Real Firestore emulator |
| Unknown report state | Stop page before apply; never skip cursor | Negative plan/apply tests |
| Stale/future evidence or changed generation | Stop transaction; no false completion | Clock and transaction tests |
| Unverified containment with enough elapsed time | Reject; time is necessary but not sufficient | Missing-attestation tests |

## Cost and operating limits

Existing 25-chant/one-comment pages, 500-report and 1,000-visible-comment bounds remain. Cleanup adds one private blocked-record read per valid event and at most one fixed-size blocked record per source; no recurring scan or automatic replay. Retention has no TTL and remains a launch decision because late uploads may recreate bytes. All measurements in this block are synthetic, not production latency or cost claims.

## Rollout and recovery

Source only. Rebuild from the reviewed exact-head-green checkout before any later approved rollout. Refresh private cutover evidence to schema 2; never roll back generation to revive a stale plan. Quarantine recovery requires exact private source evidence, current grant comparison, verified path ownership, containment/drain, and separate approval. If identity cannot be proved, do not delete or mint permission. Infrastructure retry remains enabled. Andrew owns production policy, retention, recovery and launch approval.

## Verification plan

- Functions production build and complete unit suite.
- Demo-project Firestore transaction suite, with no credentials or production fallback.
- Seed tests and typecheck, including a restored known-bad entrypoint mutation.
- Focused pre-fix/known-bad checks for moderated states, permanent cleanup and stale evidence.
- Affected rules remain unchanged; replacement CI repeats the complete rules, Flutter, native, governance and other existing jobs.
- Inspect staged diff, project-memory linkage, writing style and governance; preserve other worktrees.
- One correction commit and ordinary push to PR 26, then capture immutable source/tree/run attribution on the PR.

## Open decisions

No unresolved source decision. Production containment, actual timeout values, retained-path replay/retention, provider configuration, signing and walkthrough remain later explicitly approved gates. Do not fill the waiting period with another feature.
