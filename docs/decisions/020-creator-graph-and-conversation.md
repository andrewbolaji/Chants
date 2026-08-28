# Decision 020: Keep the creator graph private and conversation depth readable

- **Status:** Accepted
- **Date:** 2026-08-27
- **Owner:** Andrew
- **Related:** Decisions 002, 010, 017, and 018; creator platform expansion

## Context

Creator identity without follow or conversation loops does little for retention. Public follower lists would expose a social graph that is not necessary for discovery, while a strict one-reply model prevents the funny and collaborative conversations the product needs. Unlimited visual indentation becomes unreadable quickly on a phone.

## Decision

Follow edges are private, deterministic records owned by the follower and written through a callable that rechecks both accounts, creator visibility, blocks, and deletion state. Public profiles expose only recomputed follower and following totals. Following feed discovery uses the viewer's private edges without publishing who follows whom.

Performance comments support continued replies up to a stored depth of 50. Each reply preserves one root, references a current visible parent on the same performance, and cannot form a cross-target branch. The mobile sheet caps indentation at three visual levels. Deeper branches open in a focused thread with explicit reply context.

A comment may contain up to five normalized, validated handle mentions. Accepted comments fan out private notifications only after current creator, block, and deletion checks. Replies notify the parent author unless that would duplicate a mention notification. Follow, mention, and reply notifications use deterministic IDs, are readable only by the recipient, and expose a server-controlled read action.

Selecting a follow notification opens the public creator. Selecting a mention or reply fetches the current visible performance and opens its comments with the referenced item highlighted. If current authority is gone, the activity item stays readable but cannot reopen stale content.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Public follower edge collections | Easy public lists | Exposes social relationships and increases scraping risk | Aggregates satisfy the V1 product need |
| One reply level forever | Simpler queries | Cuts off the conversation loop | Stored depth can continue while the interface stays bounded |
| Unlimited indentation | Direct tree visualization | Collapses readable width on mobile | Focused threads preserve context and text width |
| Client-authored notifications | Less Functions work | Spoofing and blocked-user fan-out become possible | Notifications derive from accepted server actions |
| Notify every parsed `@word` | Simple parser | Spam and nonexistent identities | Mentions are normalized, unique, capped, and resolved through reserved handles |

## Consequences

- Positive: follows improve retention without publishing the graph.
- Positive: conversations can continue without turning the mobile sheet into a narrow staircase.
- Positive: deterministic notification IDs make duplicate delivery converge.
- Negative: Following V1 considers at most the 30 most recent followed creators per query.
- Negative: notifications are an in-app inbox only; push delivery is not part of this decision.
- Operational: account deletion must remove both directions of follow edges and private notifications while anonymizing retained public conversation according to the deletion policy.

## Validation and revisit trigger

- **Evidence:** `functions/src/creator_follow.ts`, `functions/src/creator_notification.ts`, `functions/src/performance.ts :: handleCreatePerformanceComment`, `lib/presentation/feed/performance_comments_sheet.dart`, `lib/presentation/profile/creator_notifications_screen.dart`, public creator profile tests, Functions tests, and rules emulator assertions.
- **Revisit when:** users commonly follow more than 30 creators, notification volume requires paging or push, moderation needs branch-level quarantine, or stored thread depth creates query or deletion costs beyond the recorded budgets.
