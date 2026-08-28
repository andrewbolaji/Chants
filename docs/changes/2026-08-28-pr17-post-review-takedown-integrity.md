# PR 17 post-review takedown and integrity correction

## Change identity

- **Approval:** Andrew approved `PR 17 post-review takedown and integrity correction spec` on 2026-08-28.
- **Starting head:** `946ab0c04360e30a0f380ff10e0c3941c72c4cf1` on `codex/v1-creator-platform-foundation`.
- **Scope:** One consolidated correction of the accepted independent review findings. No feature expansion, deployment, live Firebase access, seed write, signing, store action, PR merge, or release.
- **Durable decision:** `docs/decisions/022-current-source-performance-eligibility.md`.
- **Execution evidence:** `docs/EXECUTION.md`.

## Problem and reproduced failure

The initial creator-platform implementation was authorization-conscious at admission time, but publication did not form a complete lifecycle boundary. Focused pre-fix regressions proved seven related failures:

1. Banning a creator changed one private field while their public identity, approved performances, public pages, and media remained available.
2. Hidden performance media could not be previewed by an operator, so it could not be assessed for terminal removal from the Hidden queue.
3. Terminal removal changed Firestore state but had no writer that deleted `performance-media/{performanceId}/source`.
4. Stage and public creator profiles did not expose Block, and Stage did not filter creators the viewer had already blocked.
5. `creatorProfiles.performanceCount` incremented on approval but had no general convergence writer.
6. Chant hide, removal, status change, or title change did not reconcile dependent performance eligibility or trust text.
7. Durable documentation claimed Block, hidden preview, and bounded cost more broadly than source supported.

The failures shared one cause: a published performance was treated as an isolated projection instead of a dependent view of current creator, chant, moderation, and viewer authority.

## Corrected authority model

| Boundary | Current source checked | Query projection used | Outcome |
|---|---|---|---|
| Stage and creator performance lists | Viewer block stream in the client | Approved, unhidden, unremoved, creator eligible, chant eligible | Blocked or source-ineligible cards do not render |
| Playback and interactions | Actor, private creator account, deletion job, public creator, current chant, performance | Performance flags are additionally required | Stale projections fail closed |
| Public performance destination, HTML, and media | Private creator account, public creator, current chant, performance | Performance flags are additionally required | Takedown closes new signed URL resolution |
| Public creator destination and HTML | Private creator account and public creator | Public visibility fields | A current ban cannot retain a public profile page |
| Operator hidden preview | Current active operator and approved, nonremoved performance | Hidden and source flags may be false | Review is possible without restoring public visibility |

Client rules require the two server-owned source predicates for performance reads. Callables and public HTTP handlers independently recheck source documents because a trigger projection may be stale. A private ban therefore closes the server boundary before fan-out finishes.

Public creator identity remains available by exact document ID. Public collection listing is denied and operator listing is preserved. V1 has no creator directory, and the rules engine cannot safely prove a private-account join for every possible public list result.

## Takedown, restoration, and cleanup

The Hidden moderation queue now excludes terminally removed content and offers Preview, Restore, and Remove for eligible hidden video or comments. Remove requires confirmation. Active operators may preview hidden approved video; ordinary fans cannot.

Performance removal hides and marks the projection removed, resolves pending reports, writes audit, and creates deterministic deletion work in the same Firestore transaction. The worker accepts only the exact safe performance ID and media path, treats an already absent object as success, and removes the job only after Storage cleanup succeeds. A failed or duplicated worker cannot make content public again. Restoration remains unavailable after terminal removal.

## Blocking and interface behavior

Stage cards and public creator profiles expose a confirmed Block creator action for a signed-in nonowner. Both use the existing server-owned block repository. Stage watches the viewer's private blocked-user stream and removes matching cards immediately. Block preference loading or failure is fail-closed. If a fetched page contains only blocked creators, Stage says no unblocked performances are present and offers Load More or Browse Clubs instead of inviting creation as though the feed were empty.

## Aggregate and source reconciliation

`functions/src/performance_source.ts` owns creator and chant eligibility, dependent fan-out, and exact performance-count reconstruction. Every dependent update rereads current source inside its projection transaction, so an older or overlapping trigger retries if source truth changes. Approval keeps its idempotent immediate count update. Lifecycle repair includes only approved, unhidden, unremoved performances whose creator and chant source flags are both true. It recomputes in a creator-profile transaction after visibility-affecting performance writes and once per creator after source fan-out. Counter-only likes, views, shares, and comments do not trigger a full count scan.

Creator authority changes reconcile `sourceCreatorVisible`. Chant changes reconcile `sourceChantVisible`, `chantStatus`, and `chantTitle`. A chant demoted from canonical to community can remain an eligible performance but loses the Terrace Proven snapshot; a hidden or removed chant makes the performance ineligible.

## Failure, recovery, and compatibility analysis

- **Projection fan-out fails:** Current server actions and public resolvers still fail closed from source truth. Retry restores query projection and creator count.
- **Storage deletion fails:** Public state is already terminally removed. The deterministic job remains for retry.
- **Duplicate or reordered triggers:** Each projection transaction rereads its current source and conflicts on a concurrent change; aggregate reconstruction serializes on the creator profile.
- **Block preference read fails:** Stage and public creator actions fail closed instead of showing an unauthorized card.
- **Missing public creator during unban:** Performances do not revive until a current public creator exists and reconciliation succeeds.
- **Already issued media URL:** New resolution stops, but an existing signed URL has a bounded residual. Immediate recall is not claimed.
- **Schema rollout:** PR 17 has not shipped. Required source flags are part of its initial schema, so this block performs no live backfill.
- **Scale:** Feed reads are bounded. Creator and chant fan-out plus exact count scans are not globally bounded and need measurement before creator volume grows.

Compatible deployment order remains Firestore and Storage rules, Functions, Hosting, then client. Media admission must remain closed until policy, moderation staffing, deletion-job monitoring, billing, and alerting are operational. Recovery can pause admission while retaining Songbook and words-only Chant Lab.

## Verification record

Focused regressions cover current ban and chant authority, public creator closure, hidden operator preview, deterministic deletion work, exact cleanup paths, source reconciliation, count repair, Stage and profile blocking, hidden moderation actions, parser-safe performance flags, and hostile rules access. The full local and clean-runner results are recorded in `docs/EXECUTION.md`; the Java-backed rules suite and exact-head CI remain pending until the correction is packaged and pushed.

## Deliberately unchanged or deferred

- The 30-second media limit, manual pre-publication review, ranking formula, performance comment depth, and five-tab product shell are unchanged.
- No automated large-scale screening, karaoke editor, licensing system, payout flow, or personalized ranking is added.
- Native device walkthrough, policy, production configuration, deployment, seeding, signing, and store work remain separate gates.
- The next review is one narrow independent closure review of the full correction range, not a new product review.
