# Change implementation rationale: Final launch guide

## Change identity and boundary

- **Owner/request:** Andrew requested a stable, concise final-steps HTML and durable placement of cleanup monitoring in planning. Codex implementation, 2026-08-31, Lane 1 plan in `docs/EXECUTION.md`.
- **Base/target:** Merged PR 29, `c3a071cfea70f68cd4d8f76d26561843d7478c31`, to the uncommitted `codex/v1-final-launch-guide` handoff.
- **Scope:** Existing HTML/adjacent script, existing guide tests, roadmap, rollout status, guide runbook references, interface memory and execution evidence. No app/backend code, policy publication, dependency, service, seed, credential, cloud action, commit or push.

## Outcome and capability map

The guide remains at the same canonical path. Six sections and 19 tasks replace the longer pre-review checklist: owner setup, backend, sign-in/links, core walk, media/safety and release. Technical work is assigned to Codex; owner actions have nearby instructions and copyable handoffs. Completed source review and seeding are not assigned again. The seven existing candidate-bound device journeys share one report.

The roadmap places automated media-cleanup monitoring after the private canary and before public widening, with a separately approved Lane 2 scope. It must cover missed events and leftover objects, not only existing job rows. No automation or sustainable-public-observation proof is claimed.

## Implementation choices and changed state

- Reuse the existing local script and semantic disclosure pattern rather than introduce a dashboard framework, new service or second checklist.
- Start v4 local progress without reading/deleting v2/v3. Regrouped tasks cannot inherit old completion. This one-time separation is visible; later edits should preserve identifiers when meaning is unchanged.
- Put per-platform result controls inside a nearby disclosure. Expand all includes nested instructions/results, except filtered completed tasks. Show complete before printing the entire guide.
- Preserve source/backend/platform stamps, stale-result detection, explicit retest, notes-as-text and truthful copy/storage failure handling. None grants live authority.
- Record PR 29 merge and prior exact-tree CI accurately; no new exact-main CI or live inventory is implied. The runbook no longer directs the owner to run an old checkout simply because it contains configuration.

## Security, dependencies and cost

No identity, backend authorization, data schema, dependency, CI workflow or live infrastructure change. The private HTML has no analytics, external assets or automatic network requests. External dashboard/reference links require deliberate navigation. Only local checklist data is saved; warnings prohibit credentials and private account/device identifiers. No production cost changes or runtime performance claims.

## Verification performed

- `node --test scripts/test-launch-guide.mjs scripts/test-device-readiness.mjs`: 19 pass. Coverage includes actual script disclosure/expand/collapse wiring, prior-state isolation, candidate staleness, missing context, copy failure and storage refusal.
- One-use strict tag-stack/local-reference/style checks pass. Six stages and 19 tasks counted from HTML. The pre-final wording pass reduced approximate visible words from 10,143 to 3,665; this is text extraction, not a reading-time or rendered-layout benchmark.
- Prior committed HTML fails the new merge-status acceptance assertion; prior script fails the v4 isolation assertion. No test gate was weakened to accept stale claims.
- Browser skill verification is **blocked**. Initial loopback binding required sandbox escalation; the localhost-only two-file server started, but Browser Use rejected navigation under its URL policy. No alternate browser/rendering workaround was used. Server stopped. No desktop/mobile, keyboard, zoom, screenshot or visual-pass claim is made.
- Final staged governance and changed-line review outcomes are recorded in the execution log. Full Flutter/Functions/rules/native suites are not rerun for this private guide change; no clean-runner CI, independent Claude review or deployment occurred.

## Recovery, uncertainty and durable records

Reverting source restores the earlier guide/script without touching production. Older browser progress remains separate; no local-data deletion/migration is needed. The owner should copy the walk report before moving browsers or files. The current browser-policy block leaves visual verification for an allowed future surface or the owner's own viewing.

`docs/ROADMAP.md` owns monitoring sequence and release dependencies, `docs/INTERFACE.md` records this private-guide contract, and `docs/RUNBOOK.md` owns technical execution. Milestone `docs/IMPLEMENTATION_RATIONALE.md` is unchanged: no shipped architecture, app capability or infrastructure changed.

## 1 September evidence refresh

The guide's iPhone and backend steps were updated after the development-signed release client opened on a physical phone and a new read-only production inventory completed. The guide now distinguishes that launch proof from distribution signing and shows the actual next source gate instead of asking Andrew to repeat the preflight prompt.

The refresh found no basis for a live rollout approval. Production remains on the nine-function predecessor, while merged source still contains placeholder policy copy and deletion behavior that does not match the proposed public promise. The copyable next action is therefore one bounded source-spec approval, not a deployment command. No checklist state is automatically completed, no saved v4 data is migrated, and no runtime/cloud action follows from the guide change.
