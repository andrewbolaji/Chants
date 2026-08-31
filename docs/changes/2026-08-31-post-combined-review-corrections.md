# Change implementation rationale: Post-combined-review corrections

## Identity and outcome

- **Lane:** 2, approved source correction and packaging.
- **Base:** fe0ea9232ad7d34250dee9e8429f39e3e36c6188, draft PR 26.
- **Prior review:** Claude reviewed cb50d3c through fe0ea92, covering PRs 22-26. Its report is [the combined independent review](https://claude.ai/code/artifact/125c3cb5-544f-4212-a1ae-052a4cc61021).
- **Contract:** docs/CHANGE_SPEC.md. Decision 026 owns lasting recovery and cutover constraints.
- **State:** Implemented and locally verified; final staged checks and replacement CI are recorded in EXECUTION and the PR receipt. No deployment, production inspection, seed mutation, signing, install, merge or release.

The five findings are one correction block. The next Claude review starts at fe0ea92 and ends at the new exact-head-green correction commit, not at the earlier 94-file range.

## Finding-to-source ledger

| Finding | Change | Verification |
|---|---|---|
| F1: Valid moderated reports stop repair | report_repair.ts accepts pending/reviewed/dismissed and counts only pending; resolved remains invalid | Four real-emulator regressions fail on the base, then pass: mixed/terminal-only histories and malformed states for both parent kinds |
| F2: Dead cleanup helper carries misleading coverage | Remove cleanupDeletedPerformanceDraft and its two assertions; live handler owns path/owner regression coverage | Production build, caller search, live-handler matrix and exported-trigger emulator |
| F3: Permanent identity faults repeatedly fail the event | Existing private collection gets deterministic blocked records, fixed aggregate warning and no automatic revival; infrastructure exceptions still propagate | Wrong owner/path/ID, conflict, database outage, duplicate timestamps, Storage retry, late upload and actual exported trigger |
| F4: Seed entrypoint is not compiled by CI | Existing seed job runs npx tsc --noEmit before tests | Deliberate type error in seed.ts fails with TS2322; restoration passes typecheck and 74 tests |
| F5: Ancient/future cutover evidence passes and CLI self-compares generation | Schema-2 UTC containment/drain timestamps, 15-minute age ceiling, injected clocks, live-control binding in each repair transaction | Time-boundary unit matrix, known-bad stale acceptance failure, and real transaction expiry after apply before readback |

## Contracts and recovery

Report repair retains the 25-chant/one-comment pages, 500-report and 1,000-visible-comment bounds, complete ordered parent coverage, exact report/parent fingerprints, no-unhide rule, atomic counter/audit/checkpoint and separate readback. No report content, lyrics, trust, or evidence is rewritten.

Deleted-draft cleanup uses the existing server-only deferredDraftCleanupJobs collection. Accepted jobs keep their existing schema/path. Permanent failures use blocked:<sha256(draftId)>, a namespace outside valid draft-ID syntax. The allowlist is schemaVersion, sourceDigest, draftId (validated syntax or null), state, reason, createdAt and updatedAt. The locator makes valid-ID incidents investigable without storing a deleted snapshot, owner, caption or executable path. A hostile ID has only its digest and requires separately retained authoritative incident evidence.

The blocked row commits before successful acknowledgement. Conflicting valid work and profile grants remain unchanged. Duplicate delivery preserves the original timestamps; later well-shaped delivery cannot clear the block. Storage failure leaves valid pending work; database failure cannot be mistaken for successful quarantine. The wrapper emits only draft-cleanup-blocked and a fixed operator-review action. It does not log IDs or the raw SDK error.

Firebase retries enabled event failures until success or its retry window expires, so permanent input faults should not be treated as recoverable dependency failures. This source path records a recoverable operator disposition instead of exhausting that window. The deployed retry configuration and actual delivery still require verification. [Firebase retry guidance](https://firebase.google.com/docs/functions/retries).

No cleanup replay executor, TTL, collection, index, dependency, Function identity, or permission is added. Legitimate paths still retain owner identifiers after account deletion; completion does not promise full identifier erasure or absence of late bytes. The runbook now states that retention tradeoff and the exact-evidence requirements for blocked cleanup and malformed activePerformanceUpload. An invalid grant is not automatically cleared, backfilled, or made valid by waiting.

Cutover evidence changes from schema 1 to 2. Every pause surface requires UTC containmentStartedAt and observedAt, with observedAt at least the declared maximum runtime after containment began, not in the future, and at most 15 minutes old. Exactly 15 minutes is allowed; one millisecond older is rejected. The maximum runtime must come from reviewed deployed settings. The source age ceiling is conservative re-observation policy, not a cloud timeout or proof of quiescence. All revision, alternate-path, in-flight and queue attestations remain required.

The CLI checks the evidence envelope before creating its Admin client. Internal repair APIs now require evidence and a clock; each transaction compares source/evidence generation with the actual control, and apply additionally checks the reviewed plan generation. Freshness is rechecked after reads before writes. Expiry after an apply commit leaves the checkpoint applied and stops readback/remaining targets. Fresh observations may resume the same otherwise-compatible plan. No generation rollback, silent evidence migration or automatic reopening.

## Tests and evidence limits

| Check | Result |
|---|---|
| Functions production build and unit suite, Node 22.23.2 | 205 pass; 18 emulator-only cases intentionally skip outside the fixed local emulator |
| Dedicated transaction suite, Java 21, demo-chants-repair | 18 pass, including real exported cleanup and mid-page evidence expiry; credentials not used |
| Seed, Node 20 | 74 tests and full-program typecheck pass; entrypoint execution/production dry run not claimed |
| F1 pre-fix run | Four failures at the actual defects: reviewed/dismissed rejection and resolved acceptance |
| F3 pre-fix run | Two live-handler failures at invalid identity and conflicting retained path |
| F5 known-bad run | Accepting a stale observation instead of throwing produces a missing-expected-exception failure; restoring the source returns green |
| Seed known-bad run | seed.ts string assigned number causes TS2322; source restored byte-for-byte |

An initial F5 mutation using an unreachable condition failed TypeScript narrowing, so it was not credited as semantic test evidence; the subsequent compilable mutation above supplies that proof. Local emulator startup first failed sandbox port binding, then passed with approved localhost access. Neither event required a production connection or dependency change.

Flutter, native project files, rules, catalogue and dependencies are unchanged. Their current-tree complete checks run in replacement CI rather than repeating expensive local native builds. The prior preparation run 33350239642 is attributable only to fe0ea92; new CI is recorded on PR 26 after this precommit snapshot. The private guide still has no visual/browser proof following the earlier policy rejection.

## Remaining gates and limits

Andrew owns the next production amendment: exact legacy containment/drain, timeout values, target replacement, complete repair coverage/readback, retained-job inventory and bounded replay, retention, resource limits and explicit admission transitions. No source test proves those live facts.

Closure, 2026-08-31: correction commit `2d362a2709ccdc1dd8b18bedea9d72b432f3556b` passed all eight jobs in run `33354752226`. Claude independently verified that exact head/tree and closed F1-F5 in the [combined closure and Call-Ups review](https://claude.ai/code/artifact/2d4276b6-e5d2-4ab3-aa43-4ca7ae3c19e7). The new Call-Ups tree has separate local and CI evidence; this receipt does not certify its later changes. Backend rollout, provider/domain/signing setup, the iOS/Android walkthrough and public-launch evidence remain later gates.
