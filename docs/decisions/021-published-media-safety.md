# Decision 021: Extend the existing safety system to published media

- **Status:** Accepted
- **Date:** 2026-08-27
- **Owner:** Andrew
- **Related:** Decisions 010, 011, 012, 014, 016, 018, and 020; creator platform expansion

## Context

Adding public video, creator profiles, follows, and deeper performance comments creates new abuse, privacy, retention, and operational paths. A media feed cannot rely on the earlier chant-only report and moderation model. It also cannot claim automatic media safety that the product does not operate.

## Decision

Report admission now accepts performance and performance-comment targets in addition to the existing chant, comment, and user targets. Reports remain callable-only, deterministic per reporter and target, atomically budgeted, and private to operators. The client offers report actions on Stage, performance comments, and public creator profiles.

Published-media moderation is a separate operator callable. An active operator can dismiss reports, hide or remove a performance, hide or remove a performance comment, and restore eligible content. Each action rechecks current operator authority, resolves associated reports, updates the public projection, and writes a bounded audit record. The moderation screen exposes Reported media and Hidden queues with video preview and explicit Videos or Comments scope.

Directional blocks suppress creator interaction, follows, new comments, mention fan-out, and ordinary media interaction in either direction. Operators may inspect blocked creators' media for moderation, but that inspection does not grant regular social authority.

Account deletion removes new private drafts, staged upload state, deterministic interaction records, follow edges in both directions, notifications, and user-authored report material. Retained public performances and comments lose the live creator linkage according to the existing deletion retention boundary. Cleanup remains phased and retryable.

V1 uses manual pre-publication media review. Automated provider-scale screening is deferred. If review time or queue size crosses an operator-chosen limit, new admissions stay pending or are paused rather than silently publishing.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Reuse chant moderation fields for performances | Fewer callables | Confuses separate targets and report lifecycles | Published media and chant trust need independent action history |
| Let operators edit public documents directly | Less backend code | Bypasses audit, report resolution, and authority checks | Moderation is one server transaction boundary |
| Auto-publish under report-only moderation | Faster feed growth | Unsafe video is public before review | V1 volume supports manual admission |
| Add a screening vendor immediately | Greater automation | New disclosure, cost, false-positive, and recovery contracts | Defer until a measured operational trigger |
| Leave new collections out of deletion | Less work | Orphaned private graph and report data | Every new persistent entity joins the lifecycle model before release |

## Consequences

- Positive: the existing safety mental model extends to every new public creator surface.
- Positive: report and moderation actions remain private, audited, and server-owned.
- Positive: deletion does not leave an active social graph or private notification history.
- Negative: manual moderation does not scale automatically.
- Negative: restored content requires careful state and report reconciliation.
- Operational: policy text, response expectations, staffing, billing alerts, abandoned-upload cleanup, and queue monitoring remain release gates.

## Validation and revisit trigger

- **Evidence:** `functions/src/published_performance_moderation.ts`, `functions/src/safety_submission.ts`, `functions/src/account_deletion.ts`, `lib/presentation/moderation/moderation_screen.dart`, `lib/presentation/report/report_sheet.dart`, Firestore and Storage rules, Functions failure and overlap tests, rules emulator assertions, and app-gate regressions.
- **Revisit when:** the pending queue exceeds the chosen response target, repeated harmful uploads justify automated screening, restoration requires a second reviewer, or privacy and retention policy changes the treatment of retained creator media.
