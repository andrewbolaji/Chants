# 002: Comment reply depth and retention

**Status:** Accepted
**Date:** 2026-08-17

## Context

Flat comments are already built. Football banter, corrections, and jokes become more engaging when people can answer a specific person, which should help repeat use. Unlimited threaded comments multiply complexity across rendering, Firestore rules, moderation, deletion, blocking, deep links, pagination, and notifications. The current comment surface also has known integrity and lifecycle gaps that should not be amplified carelessly.

## Decision

V1 will add exactly one reply level after its interaction-safety prerequisites are complete.

- Top-level comments may have direct replies.
- Replies may not have children.
- Replies reuse the existing comment like. Comment downvotes are not added.
- Reply notifications, mentions, activity feeds, push notifications, and unlimited nesting remain deferred to v1.1.
- The implementation must use the existing comment moderation and lifecycle model, with security rules enforcing the depth boundary.

This accepts the product direction only. The code boundary and implementation sequence remain subject to approval in `docs/CHANGE_SPEC.md`.

## Reasons

- Direct responses capture most of the conversational and retention value.
- A maximum depth of one keeps the screen readable and the data model queryable without recursive UI or tree pagination.
- Deferring notifications avoids a new delivery, preference, privacy, and unread-state system before v1.
- Keeping the existing single like avoids introducing another optimistic upvote/downvote reconciliation surface.
- Requiring safety prerequisites acknowledges that more conversation also means more moderation and blocking pressure.

## Consequences

- The UI must distinguish top-level comments from replies and never offer Reply on a reply.
- Firestore rules, not only widgets, must reject a second level.
- Existing flat comment documents must remain valid without a destructive migration.
- Moderation, account deletion, user blocking, reporting, and chant merge must account for replies.
- V1.1 work must not assume notifications or unlimited depth were partially implemented here.

## Revisit triggers

- Closed-beta evidence shows users repeatedly need to answer replies rather than the top-level comment.
- Reply engagement is high enough that missing notifications measurably prevents return visits.
- Moderation load and block behavior are stable enough to justify expanding the conversation graph.
- A future implementation can define pagination, deletion, moderation, and notification semantics for arbitrary depth before code begins.
