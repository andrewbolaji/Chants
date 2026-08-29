# Decision 022: Require current source eligibility for published performances

- **Status:** Accepted
- **Date:** 2026-08-28
- **Owner:** Andrew
- **Related:** Decisions 017, 018, 019, 021; PR 17 post-review takedown and integrity correction

## Context

A published performance refers to both a creator and a chant. The first creator-platform implementation copied creator and chant facts into the performance, but later bans, creator removal, chant hiding, chant removal, or trust demotion did not close every downstream feed, action, playback, or public-share path. The same review found that creator performance totals only incremented, while terminal performance removal retained the published Storage object without a durable cleanup job.

Firestore clients need queryable fields for feed filtering, but a copied field cannot be the sole authority for a live action because trigger delivery is asynchronous. Media cleanup also cannot be part of the moderation transaction because Firestore and Storage do not share an atomic transaction.

## Decision

Every public performance carries server-owned `sourceCreatorVisible` and `sourceChantVisible` booleans. Firestore list and get rules require both fields, and every client feed query supplies both predicates. Server triggers reconcile the creator flag after private account, deletion-job, or public creator lifecycle changes and reconcile the chant flag, title, and status after chant changes. Each dependent update rereads the current source inside the same Firestore transaction as the projection write. A concurrent source change therefore conflicts and retries instead of letting an older delivery overwrite newer truth.

The flags are a query projection, not final authority. Playback, interaction, public page, public media, and destination handlers re-read the current private creator account, public creator projection, deletion job, and chant before granting access. Active operators have one narrow exception: they may resolve approved, nonremoved hidden media for moderation preview. The exception does not grant ordinary social interaction.

`creatorProfiles.performanceCount` is recomputed from current live performance rows in a transaction that serializes on the creator profile. Visibility-affecting performance changes invoke the recomputation; source fan-out invokes it once per affected creator. Counter-only performance writes do not rescan the aggregate.

Terminal performance removal transactionally hides the public projection and creates deterministic `performanceMediaDeletionJobs/{performanceId}` work bound to the exact `performance-media/{performanceId}/source` path. A retry-enabled server trigger validates that identity, deletes the object idempotently, and deletes the job only after successful cleanup. Failure leaves the content unavailable and the job recoverable.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Trust only copied performance flags | Cheapest live action | Source changes remain public until fan-out completes or can stay stale after failure | Current authority must close synchronously at the action boundary |
| Join creator and chant in Firestore rules for every feed row | Fewer copied fields | Queries can fail because a list rule must prove every result; cross-document reads also add cost | Exact query predicates are the practical client boundary |
| Delete Storage inside moderation | Looks synchronous | Firestore and Storage cannot commit atomically; failure can lose retry state | Durable work must be committed with terminal removal |
| Increment and decrement `performanceCount` | Constant work | Duplicate, reordered, or partial trigger delivery drifts | Ground-truth recomputation favors correctness at V1 volume |
| Revoke already issued signed URLs immediately | Strongest takedown | Current Firebase signed URLs cannot be recalled | New resolution stops immediately; residual lifetime stays explicit and short |

## Consequences

- Positive: a current ban, deletion, creator takedown, chant hide, chant removal, or trust demotion closes new playback, interaction, feed, and public resolution.
- Positive: Stage and public creator surfaces can hide blocked creators immediately without exposing the private block graph.
- Positive: creator performance totals converge after moderation and source changes.
- Positive: terminal removal has retryable physical media cleanup without coupling availability to Storage success.
- Negative: live server actions add current creator and chant reads.
- Negative: creator and chant reconciliation run one current-source transaction per dependent performance; exact creator totals scan that creator's performance rows. These operations are not globally bounded at scale.
- Negative: a signed URL already issued before takedown can remain usable for its residual lifetime, currently two minutes for public media and ten minutes for in-app playback.
- Compatibility: PR 17 is unmerged and unreleased, so the two required flags enter the initial performance schema. No live backfill or migration is authorized or required by this correction.

## Validation and revisit trigger

- **Evidence:** `functions/src/performance_source.ts`, `functions/src/performance.ts`, `functions/src/public_share.ts`, `functions/src/published_performance_moderation.ts`, `functions/src/index.ts`, `firestore.rules`, `firestore.indexes.json`, Stage and creator-profile block regressions, moderation regressions, Functions authority and cleanup tests, and Firestore rules assertions.
- **Revisit when:** dependent performance fan-out or exact count reconstruction crosses a measured duration or cost budget, a creator can hold enough rows to threaten transaction limits, immediate signed-URL revocation becomes a requirement, or a queue service replaces Firestore deletion jobs.
