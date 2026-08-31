# V1 backend rollout readiness

## Identity and disposition

- **Approval:** Andrew approved `V1 backend rollout readiness spec` on 2026-08-30.
- **Base:** `83711bc1a41ca656258ea87f7ff4451019705399`, merged PR 24.
- **Lane:** 2 for source readiness and read-only inventory. Actual production cutover remains a separately approved Lane 3 amendment.
- **Implemented:** Functions Node 22 manifest and root lock metadata, plus Node 22 and an explicit production build in the existing Functions CI job.
- **Locally verified:** Node `v22.23.2`, npm `10.8.2`, locked install, production build, and all 163 Functions tests. Dependency package records are byte-equivalent after normalizing only the root engine field. Compiled source exposes exactly 48 deployed-function definitions.
- **Packaging authority:** Andrew authorized one readiness commit, push, draft PR, and exact-head clean CI on 2026-08-30. At this record's precommit boundary those actions are pending; their exact SHA and CI result belong in the PR evidence.
- **Owner certificate closure:** One valid development-signing identity was verified after owner-controlled certificate creation and WWDR G3 import. No private key was exported, old certificate removed, or trust override applied. Device provisioning, signed build/install, and distribution signing remain unverified.
- **Not done:** Consolidated Claude review, production cutover, provider enablement, or device observation. No Firebase mutation occurred during readiness. The next deployment-safety implementation requires its own approved spec.

## Why this change

The configured-device preparation exposed a source/deployment gap, not a missing feature build. Production has nine July Functions; source has 48. New-account onboarding and creator journeys cannot work against that baseline. Node 20 is deprecated and has a listed 2026-10-30 decommission date, while Node 22 is supported. This is a narrow lifecycle upgrade, not a dependency update. [Google runtime support](https://docs.cloud.google.com/functions/docs/runtime-support).

`functions/package.json` still deploys `lib/index.js`. The test command compiles to `lib-test`, so passing tests alone did not prove the production build. `.github/workflows/ci.yml :: functions` now runs `npm run build` before `npm test`. Seed and rules-test jobs remain on Node 20; action runtimes remain unchanged. No handler, endpoint identity, region, rules, client, seed, or native source changed.

## Read-only production baseline, 2026-08-30

The inventory used the already authenticated Firebase CLI account and GET-only Google APIs. No application endpoint was called and no user documents were read. `gcloud` has no active account on this Mac; that is not evidence of missing Firebase authorization. Only allowlisted metadata, hashes, source code, and aggregate configuration are retained. Tokens, environment-variable values, private destinations, and signed download URLs are excluded.

| Surface | Observed state | Consequence |
|---|---|---|
| Project and Functions | `chants-f95b4`; nine `GEN_2`, `ACTIVE`, `nodejs20` Functions, updated 2026-07-02, all compute in `europe-west2` | Name presence does not imply current behavior |
| Database and event location | `(default)`, Firestore Native, `nam5`; existing Eventarc triggers also in `nam5` | Preserve event location independently of compute region. No database relocation is proposed |
| Database protection | PITR disabled; delete protection disabled | Source archives are not a user-data backup or restore exercise |
| Build/runtime identity | All nine use project-number `66623447919` default Compute service account; build `1fbbfdf5-1063-4a82-b926-7a4b1292236c` reports success | Current role sufficiency, deployer permissions, and signing IAM need explicit verification before deployment; no grant was made |
| Runtime config | 256 MiB, 60-second timeout, concurrency 80, allow-all ingress; eight report max instances 20, `onCommentWritten` omits it; no secret references reported | Do not silently normalize resource settings. Explicit resource/cost expectations belong in the production amendment |
| Firestore release | `projects/chants-f95b4/releases/cloud.firestore`, ruleset `a41a4e58-820e-4cfc-b330-e0f0af96ff33`, last updated `2026-07-02T07:22:09.609294Z` | Downloaded source is older than reviewed rules; public profile/vote reads and direct report creates remain in that source |
| Storage | Rules API returns no Storage release. Firebase Storage API is disabled. Complete bucket listing contains only two Functions infrastructure buckets | Expected client bucket `chants-f95b4.firebasestorage.app` does not exist in the inventory. Media is not operational; bucket provisioning/location and cross-service IAM need separate approval |
| Indexes | Exactly two composites, both `READY`, matching source entries 1 and 2 for chants | Entries 3-16 are missing. Create those 14 and await `READY` before dependent queries; delete no existing index |
| Scheduler | Cloud Scheduler API is disabled; jobs list returns 403 `SERVICE_DISABLED` | Cannot claim an empty historical job inventory. No scheduler was enabled or activated |
| Artifact storage | `europe-west2/gcf-artifacts` exists, no cleanup policy returned; source bucket has versioning, both infrastructure buckets have seven-day soft-delete settings | Confirm retention deliberately before later deployment. Do not accept an automatic artifact-cleanup default |

The initial index GET with `pageSize=100` returned HTTP 400. Repeating the supported no-page-size list, following any continuation token, succeeded with the two entries above. Scheduler failure was separately resolved to a disabled service via Service Usage metadata, not assumed to be an IAM failure.

### Every existing Function and actual source identity

All source objects are in `gcf-v2-sources-66623447919-europe-west2`, at `<Function name>/function-source.zip`. Generation-specific downloads for all nine succeeded, matched object size and MD5, and produced the same 129,909-byte archive with SHA-256:

`9af87597f21969a4563af4a0964d454fb9be47c2811fd95aa9c708fc9d14ef36`

| Existing identity | Live trigger | Cloud Run revision | Source generation | Proposed treatment |
|---|---|---|---|---|
| `mergeChants` | Callable | `mergechants-00003-not` | `1782998208696465` | Update to reviewed unconditional stop; never restore old active merge as recovery |
| `onModerationAction` | Callable | `onmoderationaction-00006-zuh` | `1782998208690771` | Update, with Admin mutation pause resolved for the cutover |
| `onChantCreated` | `chants/{chantId}` created | `onchantcreated-00006-bas` | `1782998209099951` | Update unchanged trigger identity |
| `onVoteWritten` | `votes/{voteId}` written | `onvotewritten-00010-lev` | `1782998209047361` | Update unchanged trigger identity |
| `onCommentLikeWritten` | `commentLikes/{likeId}` written | `oncommentlikewritten-00002-jom` | `1782998209059482` | Update unchanged trigger identity |
| `onCommentWritten` | `comments/{commentId}` written | `oncommentwritten-00001-gor` | `1782998168379389` | Update unchanged trigger identity |
| `deleteAccount` | Callable | `deleteaccount-00004-kam` | `1782998209038720` | Replace legacy sequential behavior only with worker and recovery gates satisfied |
| `onReportCreated` | `reports/{reportId}` created | `onreportcreated-00006-das` | `1782998206915974` | Two-target maintenance cutover to written event, not an ordinary update |
| `onCommentReportCreated` | `commentReports/{reportId}` created | `oncommentreportcreated-00002-nof` | `1782998209083953` | Two-target maintenance cutover to written event, not an ordinary update |

All six existing document triggers report no retry. Preserve this distinction from the two new retry-enabled deletion workers. Full read-only source/configuration downloads remain in a private temporary directory, not Git. The generation identifiers above are the reproducible retrieval authority; temporary files are not durable backups.

### What the predecessor proves, and does not prove

The archive contains both TypeScript and actual `lib/index.js`, the package main. Its compiled JS SHA-256 is `f1bd2431e384fc85f3fdb5013d1be73b43148404a60772d07c5dd548da8878f9`; source `src/index.ts` is `c386c7834ab2be7e07212ae13e75ad136c1f9ec8fefda8b8c4a6a970daa103ec`. Read the compiled handlers, not the older `lib-test` copy in the same archive.

- Compiled lines 16-50 and 645-681 define created-only report handlers, each using `FieldValue.increment(1)`. Both can inflate counts on duplicate delivery; overlap with current absolute reconstruction can also leave inflated counts or premature hiding, depending on execution order.
- Compiled `mergeChants` begins at line 407 and enters the old operator-checked sequential implementation. It has no reviewed unconditional stop. Do not invoke it. Source-only statements that merge is disabled do not describe this deployed predecessor.
- Downloaded Firestore rules SHA-256 is `5460df3e6e5400c8f3f816bacfc07ec7789a61b3420aa8ebd390fee616cd8316`. Its old public/private and direct-write boundaries are not an acceptable blanket rollback after V1 admission.
- The actual predecessor is recoverable today, but has not been redeployed or restore-tested. Known weaker authority, old deletion, and active merge mean it is forensic evidence, not a safe whole-backend fallback. Re-download and recheck exact generations immediately before the later rollout; archive them under an approved durable retention policy before relying on them for recovery.

## Proposed production sequence, not authorized or executable yet

No `firebase deploy --only functions` sweep is appropriate. Firebase requires an explicit replacement for changed event types and recommends groups of ten or fewer. Every source Function is named below exactly once. [Firebase lifecycle guidance](https://firebase.google.com/docs/functions/manage-functions).

### Hold point P0: source review, inventory, and recovery

Require an exact committed head, green replacement clean-runner CI, the consolidated Claude review, and Andrew's approval of a completed production amendment. Re-read the nine identities, event paths/location, revisions, runtime, rules release, source hashes, indexes, bucket, and services. Any unexpected live change stops the plan.

The amendment must first settle:

1. A tested, externally enforceable pause for report intake and all Admin paths that create, resolve, move, redact, or delete reports. Current source has no general maintenance flag. Closing client writes alone is insufficient: `onModerationAction`, old `deleteAccount`, old `mergeChants`, seed/Admin tools, and later deletion workers can still mutate data. An operator promise not to click is not a verified pause.
2. A specific recovery implementation and emulator rehearsal for the two-target cutover, including interrupted deletion/recreation and a bounded post-cutover repair. There is no reviewed executable maintenance/repair wrapper in this block. Do not advertise the outline below as a runnable rollback.
3. The new Storage bucket's location, identity, retention, Firebase registration, rules release, Firestore cross-service access, runtime permissions, and URL-signing permission. Recommend comparing `europe-west2` compute locality with the existing `nam5` data locality before choosing; do not create or relocate anything implicitly.
4. Exact deployer/build/runtime permission checks, Artifact Registry retention, and resource limits. Firebase's `maxInstances` defaults must not silently change the eight observed caps or conceal the ninth omission.
5. Aggregate deletion/draft backlog inspection and a separately approved activation/replay procedure. A newly installed Firestore trigger does not by itself process historical documents. Zero retained work must be proved or a bounded forward-replay action approved.
6. Enforced admission isolation for newly deployed callables until their dependent workers, schedules, policies, and smoke checks pass. A hidden client control does not prevent raw callable access. In particular, deploying media callables must not open uploads before cleanup group I is operational. The exact access/configuration mechanism needs its own review; no mechanism is silently invented here.

### Hold point P1: compatible rules and index boundary

Create only the 14 missing composites from `firestore.indexes.json` and await all 16 `READY`. Retain the two existing chant indexes and reject unexpected deletion prompts.

Preserve the actual predecessor rules, then release reviewed Firestore rules with the tested maintenance boundary. Source rules deny direct report writes and close old public profile/vote access; they do not stop Admin SDK calls. Onboarding may be temporarily unavailable until its callables are present, which is an acknowledged maintenance state, never a reason to loosen rules. Provision and verify the approved Storage boundary before any media admission. Hosting and clients remain held.

### Named Function groups

All compute targets remain `chants-f95b4/europe-west2`. Existing and new Firestore events target the existing `(default)` database in `nam5`; do not recreate the database in the compute region. Groups are conditional planning units, not permission to start A while P0 is incomplete.

| Group | Count | Exact Functions | Gate and narrow smoke evidence |
|---|---|---|---|
| A, existing nondeletion safety | 6 | `mergeChants`, `onModerationAction`, `onChantCreated`, `onVoteWritten`, `onCommentLikeWritten`, `onCommentWritten` | Verified pause; exact runtime/event inventory; merge fails with reviewed stop before parsing or mutation; hostile callable authority remains denied |
| B, explicit report cutover | 2 | `onReportCreated`, `onCommentReportCreated` | P2 below; never overlap old incrementers, never include these in an ordinary update |
| C, source and aggregate projections | 7 | `onChantWrittenForPerformances`, `onProfileAuthorityWrittenForPerformances`, `onPerformanceWritten`, `onPerformanceLikeWritten`, `onPerformanceViewWritten`, `onPerformanceShareWritten`, `onPerformanceCommentWritten` | Approved workload baseline; event inventory matches; controlled duplicate/lifecycle smoke proves convergence and takedown propagation |
| D, creator identity and social foundation | 4 | `updateCreatorProfile`, `setCreatorFollow`, `markCreatorNotificationRead`, `onCreatorFollowWritten` | Private/public authority and unique handle smoke; owner-authorized test identity only |
| E, deletion lifecycle, separately held | 4 | `onAccountDeletionJobWritten`, `onPerformanceMediaDeletionJobWritten`, `onPerformanceDraftDeleted`, `deleteAccount` | Destructive activation release, retained-work inspection, Storage readiness, worker first then callable, approved dedicated disposable account/media only |
| F, onboarding and safety intake | 8 | `acceptPolicy`, `completeOnboarding`, `submitReport`, `submitFeedback`, `submitChantUpdateSuggestion`, `moderateChantUpdateSuggestion`, `onUserReportCreated`, `onUserReportDeleted` | Report maintenance closure and worker readiness precede intake; verify valid, duplicate, stale, unauthorized, and rate-limited paths |
| G, media admission and review | 7 | `createPerformanceDraft`, `submitPerformanceDraft`, `cancelPerformanceDraft`, `moderatePerformance`, `moderatePublishedPerformance`, `resolvePerformanceDraftPlayback`, `resolvePerformancePlayback` | Policy, manual review, bucket/rules, signer, cleanup and cost gates; ticket mismatch denied; upload is not publication; hidden preview stays operator-only |
| H, performance interaction and public resolution | 8 | `setPerformanceLike`, `recordPerformanceShare`, `recordQualifiedPerformanceView`, `createPerformanceComment`, `deletePerformanceComment`, `resolvePublicShareDestination`, `publicSharePage`, `publicPerformanceMedia` | Verify current-source rejection, self-interaction exclusion, escaped previews and generic unavailable response; public URLs remain unreleased until Hosting/domain/device closure |
| I, operational schedules, separately held | 2 | `monitorOperationalBacklogsJob`, `cleanupAbandonedPerformanceDraftsJob` | Approve API enablement and actual schedule activation; cleanup is destructive. Observe aggregate alert delivery and exact-path cleanup without exposing payloads |

Each group needs successful deployment exit plus actual post-read inventory; an ambiguous exit stops the next group. No automatic retry, `--force`, broad deletion, or scheduler activation is approved. Expected final count is 48, not 48 plus replacement aliases. The only proposed later Function deletions are the two same-name report identities during P2; all other existing endpoints are updated or retained. Temporary replacement names would require an amended source contract and revised count.

Groups name bounded sets, not a promise of within-command deployment ordering. Split E into its three workers first, verify, then update `deleteAccount` alone. In F, install and verify the two user-report triggers before its six callables. Keep G/H callable admission isolated until I and all media gates pass. The final production amendment must spell out those ordered CLI targets and the isolation mechanism.

### Hold point P2: report maintenance cutover

The verified predecessor rejects an overlap strategy. The later amendment must turn the following outline into tested executable operations before permission to deploy:

1. Prove the pause covers clients and Admin writers, including moderation and deletion. Record paused surfaces and their eventual restoration; keep public content reads available only if doing so does not bypass the pause.
2. Establish a bounded affected-parent/report baseline and a drain criterion for old events. No quiet log interval alone guarantees there is no later delivery. Include verification that the old Eventarc targets cannot write after removal.
3. Delete and recreate only `onReportCreated` and `onCommentReportCreated` as written-event handlers under the same names, checking each actual event type/path, `nam5` event location, and `europe-west2` compute location. Keep intake paused if either half fails.
4. Reconcile exact affected chant/comment counters from stored pending reports using the reviewed transaction handlers, including parents with no remaining reports. Preserve hidden/removed decisions. The existing helpers are not a deployed repair API; a bounded tested caller and approved audit semantics are still required. A count correction cannot automatically undo a historic false hide.
5. Test current create/status-change/delete and duplicate delivery; check flags, hidden state, parent comment count and privacy-safe audit behavior. Record data bounds and observations without private rows.
6. Restore only the paused surfaces after explicit successful readback. If recreation fails, keep the pause and forward-fix or redeploy the reviewed written handler. Do not restore the old blind incrementer, reopen weak rules, or leave one report family silently unhandled.

### Hold point P3: workers, admission, and observation

Before E, read aggregate counts for retained `accountDeletionJobs`, `performanceMediaDeletionJobs`, and draft cleanup states. Approve exact replay or repair if nonzero; never delete a job to clear the queue. Before I, approve the daily cleanup and 15-minute monitor activation, confirm no accidental schedule fired early, and observe the configured alert channel. No existing user, media, or job deletion is authorized by readiness.

After the separately approved rollout, inventory must match 48 Functions, approved runtimes/resources/events, current rules and bucket, and all 16 ready indexes. Perform the configured-device catalogue walk and then the complete V1 journeys. Hosting/domain, provider credentials/flags, content policy, public release, and stores remain separate gates. The USD 25 budget is an alert, not a cost ceiling.

## Consolidated Claude review handoff

Andrew asked for one combined review instead of another series of one-change reviews. The last supplied Claude sign-off cleared PR 21 at `cb50d3cc966c6a367309c887a8c765891155cf0e`, with no required fixes. That SHA is an ancestor of this branch. PRs 22-24 changed the seed catalogue, live controls, and evidence; `lib/`, `functions/`, both rules files, and CI are unchanged between that reviewed SHA and this block's base.

After separately authorized packaging and green exact-head CI, review the two-dot range from that SHA to the eventual packaged head in `chants-v1-seed-live-rollout`. Include `ENGINEERING_OVERVIEW.md`, `docs/IMPLEMENTATION_RATIONALE.md`, this record, the two 2026-08-30 seed records, the active spec, runbook, execution log, and PR/CI evidence. Claude should verify the actual diff, dependency/engine boundary, live/source separation, retrieved predecessor provenance, no unsafe overlap or rollback, and every proposed rollout hold. This review is before production cutover. Deployment and device observations then need a short evidence closure, not a fresh feature build.

The base is fixed; the end is not frozen prematurely. Any separately approved maintenance/repair or admission-isolation implementation needed before deployment joins that same final review head, with exact-head CI refreshed. Do not insert one Claude review per tiny runtime or safety commit.

Carry the previous optional follow-ups forward without smuggling them into a Node-only block: combined replace-proof/promote dialog copy; stream resubscription on moderation rebuild; system-owned evidence action status mismatch; malformed-source Not changed residue; stale tab comments; image-local 2.3 percent golden tolerance; and historical CI status wording. The CI status fact is now recorded: PR 21 run `33298536085` passed all nine jobs at `cb50d3c`. The other six remain optional review candidates, not unrecorded required fixes.

## Acceptance and remaining evidence

Source runtime alignment, production build, full Functions tests, dependency preservation, complete Function/index inventory, predecessor retrieval, and no-live-write scope are verified. There is no new product behavior, so no new behavior regression is claimed; existing counter, authority, deletion, and merge-stop regressions pass unchanged. The explicit build gate checks a previously untested artifact path.

Additional checks pass: rules TypeScript, 168 localhost Firestore/Storage tests using Node 20 and Homebrew OpenJDK 26.0.2, zero-issue Flutter analysis, native contract, launch-services contract/self-test, and governance regressions. The first emulator attempt stopped at missing Mocha before running assertions; `npm ci` with the unchanged rules lock resolved it. The Java 26 runtime is installed outside normal macOS discovery; Java 21 clean-runner evidence remains a separate gate. Full Flutter tests and native builds were not repeated locally because no client/native input changed.

The approved contract's compatible recovery requirement is not yet satisfied: the actual predecessor is retrieved but unsafe as a blanket rollback, and the forward pause/repair sequence is an outline, not a tested executable. The Scheduler listing is also held by its disabled service. These are explicit unsatisfied production-readiness conditions, not a claim that the entire deployment acceptance matrix is complete.

Production is intentionally held: no executable pause/reconciliation path is yet approved, no media bucket exists, scheduler inventory requires service activation authority, recovery is not restore-tested, and exact-head CI/Claude review remain. A planning outline is not deployment readiness. The final seed criterion is still a real configured-device observation, not another seed write.
