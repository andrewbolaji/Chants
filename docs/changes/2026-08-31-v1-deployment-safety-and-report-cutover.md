# Change implementation rationale: V1 deployment safety and report cutover

## Change identity and boundary

- **Implementation:** Codex; approved Lane 2 source block and Storage amendment
- **Base:** `d7b8b6fe9c421e321ada2790c9410d52f1f81cc8`, draft PR 25
- **Target:** The 44-file safety commit containing this record on `codex/v1-device-readiness`, PR 25. Packaging is authorized; this precommit record reports local evidence only. The immutable resulting head and replacement CI are recorded in PR 25.
- **Date:** 2026-08-31 UTC
- **Included:** Functions admission/repair/grants/cleanup and tests, both rules files and tests, seed writer interlocks, upload recovery copy/tests, existing rules CI job and project memory.
- **Excluded:** Other worktrees, owner credentials, catalogue content, dependency versions, native configuration, cloud services/IAM, live control writes, deletion/replay, deployment, device installation, merge and release.
- **Acceptance:** `docs/CHANGE_SPEC.md`; durable reasoning in decision 026. The prior readiness contract remains at the base and its own completed record.

## Outcome

Source now refuses new protected work unless the private operational control permits it. Upload permission fits Storage's two-document limit without removing account authority. Paused deletion events retain cleanup instructions. Report repair defaults to one private planned page, with explicit apply, bounded reads and deterministic resumable evidence.

These controls are implemented, not active in production. They do not establish a live pause or authorize deployment. The actual nine-Function baseline and all earlier production seed evidence remain unchanged.

## Impacted capability map

| Boundary | Before | After | Key source |
|---|---|---|---|
| Admission | No common source interlock | Exact control, 48 endpoint classes, 19 direct-write branches | `operational_control.ts`, `operational_gate.ts`, `index.ts`, `firestore.rules` |
| Upload creation | Draft/profile/deletion-job lookups exceeded documented Storage limit | Profile grant plus global control, two reads | `upload_grant.ts`, `performance.ts`, `storage.rules` |
| Paused deletion event | Only deleted snapshot held cleanup identity | Deterministic retained exact-path job before acknowledgement | `deferred_draft_cleanup.ts` |
| Seed/Admin repository writes | Bypassed any app maintenance state | Control read in each mutation transaction; read-only paths unchanged | `seed/operational_control.ts`, `seed.ts`, `reconcile.ts` |
| Historical report counters | Live recompute helper, no bounded operator wrapper | Plan/apply, audit, checkpoint and readback | `report_projection.ts`, `report_repair.ts`, `report_repair_cli.ts` |
| Event-type cutover | Conditional operational prose | Executable evidence validator and interrupted-state rehearsal, no cloud executor | `report_cutover.ts` |

## Implementation choices

| Choice | Reason and alternatives | Accepted tradeoff | Evidence |
|---|---|---|---|
| Uncached control reads at real wrappers | Helper-only gating misses HTTP/jobs and stale-open caches | One added read per protected invocation; issue/submit also read transactionally | Compiled endpoint population, real wrapper refusal/open controls, HTTP no-store, worker tests |
| Authoritative single profile grant | Fits documented two-document Storage ceiling; mirrored flags or weakened account checks rejected | One 30-minute slot per account; no multi-upload manager | Grant unit and emulator concurrency tests; Storage helper-call budget mutation |
| Retain deleted-draft paths before acknowledgement | Returning success while paused would lose event-only work | Private retained data and explicit later replay/retention decision | Actual paused exported trigger; failure and late-completion unit cases |
| One comment per repair page | Shared parent counts otherwise invalidate later exact preconditions in the same page | More explicitly reviewed pages, still within approved ceiling | Comment transaction and cursor tests |
| Separate commit and readback transactions | A lost response is not proof of failed mutation | Applied checkpoint can remain incomplete until investigated/resumed | Post-commit acknowledgement/control/audit faults |
| Reuse pending-report definition | Preserve existing live-handler semantics rather than fork the threshold | Existing unbounded live scans remain; operator scans are capped | Existing counter suite plus real overlapping emulator deliveries |

## Changed flow and state

Protected callable: existing authentication, fresh control, existing private actor/target handler. Anonymous public wrappers check admission before resolution and return generic no-store 503 when paused. Core mode refuses performance targets while preserving nonmedia paths. Merge stays stopped. Monitoring and aggregate/source reconciliation are explicitly ungated.

Upload: transaction reads control and current account/deletion/creator/content/limit state, then writes grant plus draft and budget. Storage reads exactly control and profile. Submit checks the current grant in its transaction before clearing it and writing pending review. Cancellation, moderation, account-deletion acceptance, bans and cleanup clear only matching eligibility. Ban revocation shares the profile write; deletion revocation shares the durable-job transaction. Stale cleanup cannot clear a newer slot.

Grant-writer coverage: create/submit/cancel/approve/reject in `performance.ts`; deletion acceptance in `account_deletion.ts`; ban in `index.ts :: handleUserBanAction`; abandoned claim/deletion in `operations.ts`; arbitrary deleted-draft event in `deferred_draft_cleanup.ts`; onboarding initializes explicit nondeleting state. Account-deletion draft removal occurs after permission revocation, and its deletion event preserves the path.

Repair: validate identity/options/private files and reviewed checkout before client construction; require verified pause/replacement attestations; plan one document-ID page; explicitly review its digest; apply each target in maintenance at the expected generation; commit count, parent, audit and applied checkpoint together; read back all material state; then mark complete. Empty pages also recheck generation. No automatic next-page invocation, unhide, content edit, report rewrite or admission release.

| Failure/invariant | Enforcement | Evidence |
|---|---|---|
| Invalid/missing/unreadable control | No cached-open fallback; deny before handler or destructive gateway | Exported callable/HTTP/job tests and direct-write rules |
| Newly initiated upload after pause, expiry or generation change | Control/profile grant read and exact bindings | Storage positive and negative tests |
| Concurrent creators or stale cleanup | Shared profile serialization and matching-draft revocation | Real emulator concurrent issue, cancel/new grant/deletion, abandoned claim |
| Repair source changed or query overflowed | Fingerprints and overflow sentinels; no estimated counts | Real 501-report and 1,001-comment rejection |
| Committed work loses acknowledgement | Same plan identity resumes one audit | Real commit/readback fault injection |
| Audit changed before readback | Exact privacy-safe payload comparison; incomplete checkpoint retained | Real-emulator tampered-audit test |
| Events overlap repair | Shared parent transaction; stale plan stops or events converge | Concurrent real-emulator reconstruction |
| Partial trigger replacement | Exact two-name inventory and held release state | Cutover test interrupted after each target |

## Security, privacy, and abuse impact

- Current Firebase identity, ban, age, policy, deletion and target checks remain. Clients cannot choose the private control or upload grant. Protected fields remain server-owned.
- Private plans contain IDs and hashes, not report bodies or reporter identity. Plans and cutover evidence must be regular owner-only JSON files, at most 1 MiB; plans live directly in ignored `.private-report-repair/`. Files are not published or attached to review.
- CLI validation rejects unknown/duplicate options, wrong project/source/digest and unsafe file paths before constructing an Admin client. It uses the already-validated credential object. Tests use synthetic adapters or `demo-chants-repair`, never the real credential.
- Repair audits use system actor, target identity and generic detail. Their unknown-action deletion fallback remains private; no retention allowlist was broadened.
- Deferred cleanup retains an exact owner-containing path for recovery. It is server-only and requires a later approved retention/replay policy. Public account-deletion completion is not a claim that an already admitted upload cannot arrive late.
- Existing daily upload, content and abuse limits remain. One occupied slot does not spend another upload admission budget.

## Dependency and infrastructure impact

| Surface | Change | Reason | State |
|---|---|---|---|
| Existing rules CI job | Node 20 to 22, builds Functions and runs dedicated demo-Firestore transaction rehearsal | Match production Functions runtime for tests importing its source | Source only; still eight jobs |
| Functions and npm/Flutter locks | No dependency or lock changes | Reuse current installed graph | Node 22.23.2 build verified |
| Firestore/Storage schema | Private control, one private profile grant, retained cleanup and repair checkpoints | Admission, two-read quota and recovery | Not deployed or backfilled |
| Rules | Direct mutations require core/media; upload requires current media grant | Fail closed before new work | Emulator verified only |

Firebase's documented Storage limit and the old emulator contradiction are recorded in the active spec with primary-source links. No service, bucket, index, schedule, resource cap or IAM state changed.

## Performance, scale, and cost impact

Control reads add latency and billable reads. Storage upload source contains exactly two Firestore lookup call sites; Firestore direct-write paths add one shared control document. Valid open-mode rule cases still pass, but this is not a production latency or cost measurement.

Repair reads at most 25 chant targets or one comment target per invocation, 500 reports plus one sentinel per target, and 1,000 visible comments plus one sentinel for a comment. Plan, apply, readback and transaction retries repeat reads. These are per-attempt bounds, not a fixed total request bill. Existing live counter/source fan-out remains unbounded at scale. The USD 25 saved budget remains alert-only.

## Verification performed

| Command/scenario | Environment | Result |
|---|---|---|
| `npm run build && npm test -- --reporter dot` | Functions, Node 22.23.2 | 202 unit tests pass; 12 emulator cases intentionally pending without emulator |
| Dedicated repair integration Mocha file | Java 21, Node 22.23.2, local `demo-chants-repair` Firestore | 12 pass, including actual paused exported deletion trigger |
| `npm test -- --reporter dot && npx tsc --noEmit` | Seed, Node 20, injected adapters only | 74 pass and typecheck passes |
| Complete Firestore/Storage emulator suite | Local synthetic fixtures | 173 pass, including independent two-lookup source contract |
| `flutter test --no-pub` and `flutter analyze --no-pub lib test` | Local source, existing Firebase config preserved | 493 pass; no analyzer issues. Includes eight upload-form cases and 390 by 844 at 1.8x text |
| Memory/native/launch-services contracts and launch-services self-test | Local source | Pass, including staged memory, index writing-style, governance regressions and diff checks |

The wrapper test temporarily bypasses the actual admission function, observes its refusal assertion fail, restores it and confirms refusal again. The Storage source test injects a third lookup through a called helper and observes the budget assertion fail. No tracked production code is left mutated. Existing old rules passing five Storage tests is explicitly not production quota proof.

No replacement exact-head CI is credited by this precommit snapshot; consult PR 25 for its result. No independent Claude review, production smoke, real upload, device install, native rebuild, live control transition or repair occurred during local implementation. Native source and dependencies are unchanged; native compilation is included in the now-authorized replacement CI.

## Rollout, observation, and recovery

Packaging and exact-head CI were authorized on 2026-08-31 UTC. After they pass, one combined Claude review spans `cb50d3cc966c6a367309c887a8c765891155cf0e` through the final source head, including PRs 22-25 and this block. Close required findings before a separate production amendment.

That amendment must specify exact legacy containment/drain, maintenance window/owner, command targets, dependencies, two event replacements, full reviewed page coverage/readback, retained-job inventory/replay, resource and retention settings, smoke identities and explicit core/media transitions. The validator checks attestations, not live cloud truth. Reopening a mode does not replay historical jobs. Never restore the old incrementers or weak rules as a blanket rollback.

## Known compromises and uncertainty

| Item | Consequence and reason | Owner/revisit |
|---|---|---|
| No automatic historical replay | Paused records survive but do not execute just because control opens | Andrew; before worker activation |
| In-flight upload/URL residual | Revocation prevents new permission, not completion of already admitted work; retained paths may need another exact cleanup attempt | Andrew; production transfer-drain and retention decision |
| Existing cancelled/rejected draft cleanup | Terminal rows retain paths; existing cancellation makes a best-effort removal and the daily scanner does not sweep every terminal state | Andrew; inventory and bounded cleanup plan before public media |
| Operator attestations and external Admin writers | Source cannot independently prove traffic/IAM containment, freshness or exhaustive repair coverage | Andrew and independent reviewer; production cutover approval |
| Generation monotonicity | Readers validate current shape, not history; an Admin rollback could revive old grants | Andrew; every transition must increase generation, no console reuse |
| Comment page size one | Operationally slower but preserves exact shared-parent preconditions | Revisit only with measured volume and a separately reviewed coordinated plan |
| Historical false hides | Repair deliberately never unhides content | Operator moderation review after source correctness |

## Material files and artifacts

- New policy, gate, grant, deferred cleanup, report projection/repair/CLI and cutover modules under `functions/src/`, and their focused tests.
- Existing Functions wrappers and account/draft lifecycle writers; `firestore.rules`, `storage.rules` and hostile tests.
- `seed/operational_control.ts`, existing seed and reconciliation writers, and tests.
- `PerformChantScreen` and its production widget regression; no navigation or visual redesign.
- Existing CI workflow, ignored private-plan directory, decision 026 and the current project records.

## Repository rationale reconciliation

The whole-repository rationale and overview require refresh because admission, upload authority, private collections, recovery and CI changed. Their current sections now point to this scoped evidence while preserving historical verification and the explicit source/deployed distinction. Runbook, project profile, interface, roadmap, execution and the demonstrated Storage learning carry the corresponding operational contract.
