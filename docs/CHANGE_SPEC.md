# Change spec: V1 backend rollout readiness

**Status:** Approved; bounded source change locally verified and read-only inventory recorded; production deployment is not authorized
**Updated:** 2026-08-30
**Risk lane:** Lane 2 source/runtime readiness; later production cutover is a separate Lane 3 hold point
**Base:** `83711bc1a41ca656258ea87f7ff4451019705399`, merged PR 24
**Approval:** Andrew approved `approved V1 backend rollout readiness spec` on 2026-08-30, then authorized one readiness commit, push, and exact-head CI with `ok go ahead`. The owner completed development-certificate setup separately; provisioning and device execution remain unverified.

## Outcome and authority

Prepare the already-built V1 backend for a controlled deployment so the configured-device walkthrough can exercise the real app. Approval of this readiness block permits the bounded source changes and read-only deployment planning below. It does not authorize production deployment, Function deletion, scheduler activation, IAM changes, signing-key creation by the agent, test-account creation, or a store release. One readiness commit, push, draft PR, and exact-head CI are now authorized. The following deployment-safety implementation still needs its own approved specification.

The completed seed rollout is preserved in the prior spec at the base commit and `docs/changes/2026-08-30-v1-live-seed-safety-controls.md`. All 20 clubs, 622 players, and 192 chants were exact in production. Its final configured-device criterion remains open and is not replaced by this readiness work.

## Independently observed baseline

Read-only `firebase functions:list --json --project chants-f95b4` on 2026-08-30 reports nine active second-generation Functions, all in `europe-west2` on `nodejs20`:

`deleteAccount`, `mergeChants`, `onChantCreated`, `onCommentLikeWritten`, `onCommentReportCreated`, `onCommentWritten`, `onModerationAction`, `onReportCreated`, and `onVoteWritten`.

The merged `functions/src/index.ts` exports 48 Functions. Thirty-nine names are not deployed, including `completeOnboarding`, `acceptPolicy`, creator/media callables and workers, and Living Songbook intake and moderation. Name presence does not prove deployed implementation parity for the other nine.

Two deployed trigger types differ from the reviewed source:

| Function identity | Deployed event | Reviewed source event |
|---|---|---|
| `onReportCreated` | Firestore document created | Firestore document written |
| `onCommentReportCreated` | Firestore document created | Firestore document written |

Firebase documents that event types cannot be changed with an ordinary in-place deployment. Its replacement approach temporarily overlaps old and new handlers and therefore requires compatible idempotent behavior. The recovered deployed handlers blindly increment report counts, so overlap with current reconstruction is unsafe. Neither blind overlap nor delete-first is approved. [Firebase deployment and trigger guidance](https://firebase.google.com/docs/functions/manage-functions).

Google lists Node 20 as deprecated from 2026-04-30 and decommissioning on 2026-10-30. Node 22 is supported and is the proposed smallest runtime move. This observation is a deployment-lifecycle reason for a bounded upgrade, not permission for a dependency sweep. [Runtime lifecycle](https://docs.cloud.google.com/functions/docs/runtime-support).

The initial preparation found zero valid code-signing identities. After the owner created an Apple Development certificate and imported Apple's WWDR G3 intermediate with default trust, the 2026-08-30 packaging check reports one valid identity matching the existing Chants team. The old certificate was left intact. This completes certificate setup, not device provisioning, a signed build, installation, or distribution signing. Matching native Firebase client files already exist locally; the continuation checkout has derived, ignored client configuration for `chants-f95b4`. No Admin credential was used to create those files.

## Scope and design

1. Move only the Functions runtime contract to Node 22: `functions/package.json`, the root package entry's engine metadata in `functions/package-lock.json`, and the Functions test/build CI job. Preserve dependency versions, function behavior, region, names, rules, and storage policy. If Node 22 exposes a source defect or demands broader changes, stop and amend the spec.
2. Use existing verification commands to prove the production TypeScript build and complete Functions suite on Node 22. No new runtime wrapper, service, dependency, deployment automation, or CI job is proposed.
3. Complete a read-only release inventory: deployed trigger/resource identities and runtime, Firestore/Storage rules release identity, index readiness, scheduler state, deployment identity, and retrievable prior source/configuration needed for recovery. Retain only configuration and aggregate evidence, never credentials, user documents, or signed artifact-download URLs.
4. Resolve the two report-trigger cutovers in a separate exact production amendment. First inspect the deployed implementation or a verified matching predecessor artifact. Choose replacement overlap only if both sides are proven safe; otherwise propose a verified intake pause, exact two-target maintenance cutover, and post-cutover reconciliation. An inability to prove the pause, recovery, or overlap is a stop condition.
5. Produce a named deployment sequence with at most ten Functions per group, explicit before/after inventory, index/rules compatibility order, and narrow smoke checks. Do not execute it in this block. Keep cleanup activation and any retained deletion backlog behind a separate, explicit destructive-work hold point.
6. Keep the phone walkthrough instructions beside the seed runbook. Owner-controlled signing and actual app observations remain distinct from automated tests.

## Acceptance criteria

1. Node 22 is explicit in the Functions manifest, root lock metadata, and that package's CI job. No dependency package version changes.
2. The production build and complete Functions suite pass on an identified Node 22 runtime; the emulator/rules integration and exact-head clean CI remain packaging gates.
3. The deployment inventory still targets only `chants-f95b4` and `europe-west2`. Every proposed create, update, retained endpoint, and later deletion is named. Any new live endpoint or trigger difference stops the plan for review.
4. The known two event-type changes are explicit cutovers, never described as ordinary updates. No production Function is deleted or renamed during readiness.
5. Recovery evidence identifies a compatible prior artifact or an executable forward-recovery path. A Git commit alone is not asserted to be the deployed baseline.
6. Existing public/private authority, counter convergence, merge runtime stop, source-eligibility checks, and account/media deletion invariants remain unchanged.
7. No rule loosening, provider flag enablement, service-account role grant, scheduler activation, Hosting/DNS change, seed write, or live diagnostic mutation occurs.
8. The local client configuration matches existing registered Android/iOS app identities, has no unresolved placeholders, and remains ignored and untracked. No credential is recorded in project memory.
9. The staged handoff, scoped rationale, and execution record separate source-ready, CI-verified, deployed, and observed states.
10. Andrew receives the exact production amendment and hold points before any cloud write. The final seed/device criterion stays incomplete until observed in the app.

## Failure and recovery boundaries

| Condition | Required response |
|---|---|
| Node 22 incompatibility | Preserve prior manifests; diagnose narrowly, amend scope before changing behavior or dependencies |
| Deployed code or rules baseline cannot be recovered | Stop before deployment; do not invent a rollback from historical source |
| A legacy report handler is non-idempotent | Do not overlap it with the new writer trigger; require a reviewed compatibility or maintenance cutover |
| Existing deletion/cleanup work could execute under new workers | Retain source state; inspect aggregate backlog and exact recovery design under the later approved rollout before activating workers |
| Partial deployment or ambiguous CLI exit in the later rollout | Stop the next group; inspect exact deployed identities and health before considering retry |
| New client reaches a missing callable | Treat as deployment incompatibility, never bypass client/server authority or manufacture profile state |
| Signing unavailable | Owner completes Apple development signing; do not switch teams, strip capabilities, or create distribution credentials to force a build |
| Public destinations unavailable | Keep public-share sign-off open; do not equate a callable deployment with Hosting/domain readiness |

## Cost and excluded work

Readiness has only local verification and bounded metadata-read cost. A later deployment introduces build/artifact storage and operational workload; two scheduled Functions would run daily and every 15 minutes. The existing USD 25 alert-only budget is not a spending cap. Confirm artifact retention and scheduler activation in the later deployment amendment rather than accepting unplanned CLI defaults.

No feature expansion, lyric/roster change, identity migration, broad formatter pass, Flutter upgrade, authentication-provider completion, policy rewrite, domain/Hosting rollout, Android signing/association, App Check enforcement, user/media deletion, or public release belongs in this block.

## Verification and handoff

- Current results and unresolved production prerequisites are in `docs/changes/2026-08-30-v1-backend-rollout-readiness.md`. The actual predecessor was retrieved and proves blind report increments and an active legacy merge. Both Storage and Scheduler APIs are disabled, the media bucket is absent, and fourteen indexes are missing. Firestore/Eventarc remain in the existing `nam5` location; `europe-west2` denotes Functions compute, not a request to relocate data. A tested pause/repair path and separate production amendment are required before cutover.
- Inspect the exact diff and verify dependency versions are unchanged.
- Run the Functions production build and full test suite under Node 22.
- Run project-memory, writing-style, native, launch-services, governance, and diff checks at the intended handoff.
- Package and obtain exact-head clean CI and independent review only after requested.
- Consolidated Claude review must cover the last Claude-reviewed source `cb50d3cc966c6a367309c887a8c765891155cf0e` through this block's eventual packaged head, including PRs 22-24. Do not treat the seed checks as a later Claude sign-off. Review source, rollout decisions, recovery evidence, and remaining gates before any production cutover; actual deployment and device observations need a subsequent evidence closure.
- If the required pause/repair or admission-isolation implementation is approved as a following block, extend the same consolidated review end to its final exact-CI head. The base remains PR 21; do not require a separate Claude review for every small readiness commit.
- Before a later production release, approve the named cutover, baseline/recovery evidence, index/rules order, worker activation, smoke-test account authority, and observation window.
- After the backend and phone-signing gates pass, complete the seed catalogue walkthrough in `docs/RUNBOOK.md`, followed by the broader V1 journeys. Do not conflate that with store readiness.
