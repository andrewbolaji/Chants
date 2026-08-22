# Active change specification

**Status:** Implementation and automated verification complete; live-device release walk pending
**Updated:** 2026-08-18
**Change:** V1 one-level comment replies

This file is the only active implementation specification. Andrew approved this technical boundary and sequence on 2026-08-17. Product direction is recorded in `docs/decisions/002-comment-reply-depth-and-retention.md`.

## Outcome

Let a signed-in user reply directly to a top-level comment. Keep the conversation visually and structurally limited to one reply level for v1.

The retention hypothesis is simple: the funniest and most useful parts of a football conversation often happen in the responses. One reply level adds that back-and-forth without introducing an unlimited tree, notification system, or another vote model before launch.

## Product boundary

### In scope

- A reply action on each visible top-level comment.
- A composer state that identifies the comment being answered and can be cancelled.
- Replies rendered directly below their parent.
- The existing comment like, report, hide, remove, ban, and account-deletion behavior applied to replies.
- A hard maximum depth of one, enforced in both Firestore rules and the client.
- Backward compatibility for every existing flat comment document.

### Out of scope

- Replies to replies or any deeper nesting.
- Reply notifications, mentions, activity feeds, or push notifications.
- Comment downvotes.
- Collaborative lyric suggestions.
- Changes to chant voting.

Those items remain v1.1 candidates. They require their own evidence, specification, and approval.

## Preconditions

The reply code must not ship until these existing interaction-safety gaps are resolved or explicitly waived in writing:

1. User blocking is available and affects comment visibility and interaction.
2. Comment writes cannot reference a missing chant, and reply writes cannot reference a missing, hidden, removed, or cross-chant parent.
3. Account deletion has defined behavior for comments, replies, reports, and report-derived counters.
4. Chant merge no longer leaves comments and replies attached to a deleted source chant.
5. Report counters used for auto-hide are idempotent under duplicate trigger delivery.

These are prerequisites because replies increase the volume and reach of the existing user-content surface. They are not optional polish.

## Proposed data contract

Keep all comments in the existing top-level `comments` collection.

- Add nullable `parentCommentId` to the Dart `Comment` model and serialized document.
- A missing or null `parentCommentId` means a top-level comment. This preserves all existing documents without migration.
- A non-null `parentCommentId` means a direct reply.
- The parent must exist, have the same `chantId`, be visible, and itself have no parent.
- Do not add `replyCount` in this block. The existing chant comment stream already returns the visible comments needed to group replies under parents.
- `commentCount` continues to mean all visible comment documents, including replies.

The client guard improves the experience, but the Firestore rule is the actual depth and relationship boundary.

## Proposed behavior

1. Load the existing visible comment stream for a chant.
2. Partition it into top-level comments and replies by `parentCommentId`.
3. Keep the current top-level ranking: likes descending, then newest first.
4. Render each parent's replies chronologically, oldest first, immediately below it.
5. Tapping Reply opens the normal composer with a clear `Replying to <display name>` context and a cancel action.
6. A reply has like and report actions, but no Reply action.
7. If a parent disappears through moderation while the screen is open, its replies disappear from the rendered thread rather than becoming top-level comments.
8. A failed write keeps the typed text recoverable and shows an actionable error.

## Security and lifecycle rules

- Only the authenticated author may create a reply under their own UID.
- Existing comment length, policy acceptance, ban, and create-rate limits apply to replies.
- `parentCommentId` is immutable after creation.
- A top-level comment cannot be converted into a reply, and a reply cannot be moved to another parent or chant.
- The parent lookup must prove same-chant membership and maximum depth.
- A reply cannot be created under hidden or removed content.
- Moderation and deletion logic must treat replies as comments, not as a separate content type.
- Blocking must prevent the blocker from seeing or interacting with the blocked user's comments and replies.

## Implementation sequence

1. Close the interaction-safety preconditions in separately approved change blocks.
2. Add the nullable model field and backward-compatibility tests.
3. Add Firestore rule constraints and emulator tests for every relationship and depth failure.
4. Add repository write support and grouping logic.
5. Add reply composer and rendering UI with widget tests.
6. Run the full Flutter, Functions, seed, and Firestore-rules suites.
7. Perform a device walk covering keyboard behavior, rapid actions, offline or failed writes, blocking, moderation, and account deletion.

## Required regression tests

- Existing comment documents with no `parentCommentId` deserialize and render as top-level comments.
- A valid direct reply succeeds.
- Reply-to-reply, self-invented parent ID, cross-chant parent, hidden parent, and removed parent writes fail.
- `parentCommentId` and `chantId` cannot be changed after create.
- Replies group under the right parent and stay chronological.
- A moderated parent never promotes its replies to the top level.
- Likes and reports still target the correct comment document.
- A failed reply write preserves the draft and clears any busy state.
- The new widget test fails when reply grouping or submission is reverted.

## Verification gate

The block is complete only when:

- `flutter analyze lib test` passes.
- `flutter test` passes.
- `cd functions && npm test` passes if Functions are touched.
- `cd seed && npm test` passes if seed or reconciliation logic is touched.
- `cd test_rules && npm test` passes with the Firestore emulator.
- The relevant widget regression test has been proven red against the reverted production change, then green with the implementation.
- UI behavior has been checked on a real or emulated phone and captured by screenshot.
- The completed change is moved into `docs/changes/` and any new durable decision is added to `docs/decisions/`.

## Approval

Andrew approved this technical boundary and sequence on 2026-08-17. Implementation began with the interaction-safety prerequisites.

### Approved completion amendment, 2026-08-18

Andrew approved finishing the current interaction-safety block before starting the Saved Matchday Songbook. The completion amendment adds one recovery path exposed by the engineering review:

- Operators can unban a user from a reported-user card or by entering a user ID.
- Unban is performed by the existing operator-only callable Function, writes an audit entry, and cannot be performed through a direct client profile write.
- The Functions handler has a focused regression test for the state change, audit payload, and missing-profile failure.
- The roadmap and wishlist are corrected so completed replies and blocking are no longer described as future work.

This does not change reply depth, add notifications, or touch seed content.

## Implementation result

The approved code boundary is implemented in the working tree.

- One-level replies reuse `comments.parentCommentId`; missing/null remains top-level.
- Parents rank by likes then recency; replies render oldest-first; orphan replies never become top-level.
- Reply context is cancellable, replies cannot receive replies, and a failed write preserves both context and draft.
- Directional blocks have Block, Undo, a Blocked users screen, client visibility filtering, and server denial of reply/like interaction in either direction.
- Operators can reverse an accidental ban from a reported-user card or by user ID through the audited operator-only callable.
- Firestore rules enforce parent existence, visibility, same-chant membership, depth, immutable placement, visible interaction targets, private profile/vote/like reads, recent client timestamps, and lifetime chant constraints.
- Chant/comment report counters are transactional ground-truth recomputes rather than blind increments.
- Rate-limit account classification is monotonic and backdated new writes cannot escape the one-hour query.
- Chant merge moves comments/replies. Account deletion removes every report type and block relation, reconciles derived counts, preserves a retryable Auth/profile ordering, and accurately discloses anonymized retained content.
- Failed sign-up completion has compensating cleanup.

## Verification result

- `flutter analyze lib test`: pass, no issues.
- `flutter test`: pass, all 182 tests including the reply-thread and operator-access goldens.
- Focused reply golden: pass at 390 x 844, `test/presentation/comments/goldens/comment_reply_thread.png`.
- Reply grouping/order regression: deliberately proven red by reversing production reply order, then green after restoration.
- `cd functions && npm test`: pass, 26 tests after the approved unban amendment.
- `cd seed && npm test`: pass, 23 tests.
- Firestore emulator plus `cd test_rules && npm test`: pass, 106 assertions.

## Remaining release check

No iOS or Android simulator was booted during this implementation block. Before this spec moves to `docs/changes/`, perform the live-device walk for software-keyboard resizing, rapid reply/like actions, offline or denied writes, block/unblock, moderation of a parent with visible replies, and account deletion. The engine-rendered phone golden proves layout at the target viewport but does not substitute for platform keyboard and Firebase lifecycle behavior.
