# Decision 009: Direct writes and live actions fail closed at authority boundaries

- **Status:** Accepted
- **Date:** 2026-08-25
- **Owner:** Andrew
- **Related:** Decisions 004, 006, and 008; stacked v1 authority remediation

## Context

Chants accepts direct Firestore writes from authenticated clients while Dart models deserialize public documents with concrete types. Before this decision, several write rules validated individual values but did not enforce the complete client shape. A raw SDK could therefore create data that passed authorization and later failed a public query mapper. Vote and comment-like owners could also alter the Function-owned `appliedValue` reconciliation stamp.

The client also retains readable route data through ordinary network failure. That is useful for lyrics, but a stale route snapshot is not proof that content is still visible. A moderator's permission denial must not leave a Discover card or live write, save, report, vote, comment, or share action usable.

## Decision

Direct client writes use exact collection-specific schemas. Required fields have rule-level types and bounds, unknown fields are denied, chant Team and Player relationships are checked, and v1 user-created media and variations are pinned to the client capability that actually ships. Admin SDK seed and Function writes remain a separate authority boundary.

Vote and comment-like clients create only their public intent fields and may later change only `value`. `appliedValue` is server-owned. The client uses transactions so a missing interaction can be created once while an existing interaction preserves the Function stamp.

Readable fallback and action authority are separate UI states. Ordinary transient errors may retain previously safe public text. A Firestore permission denial, current missing document, or current hidden or removed document removes Discover content. Live detail may keep route text readable, but Save, Share, Vote, Report, and Comment actions require an active, error-free, current visible chant.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Trust the shipped forms | Fewer rules expressions | Raw SDK and older clients bypass form validation | Client validation is assistance, not authorization |
| Validate only fields the UI edits | Lower rules complexity | Unknown or malformed stored values can still break public readers | Rule-valid public data must fit the parser |
| Clear all retained content on any error | Simple state machine | Ordinary stadium connectivity loss erases useful lyrics | Connectivity loss and moderation denial have different authority meaning |
| Keep all stale controls and rely on write rejection | Stronger offline appearance | External share and local save can escape before server rejection | Side effects need current target authority before invocation |

## Consequences

- Positive: a newly accepted direct-client chant fits the shipped parser and referential model.
- Positive: Function reconciliation stamps cannot be forged, deleted, or rewritten by their owner.
- Positive: moderation revocation removes Discover content and prevents stale live-target actions.
- Positive: ordinary network errors may still retain readable content.
- Negative: direct author edits to legacy documents that do not fit the current exact schema are denied until an operator or migration normalizes them.
- Negative: valid chant creation and author edits spend bounded rule reads on Team and optional Player validation.
- Operational: changes to direct-write models must update rules and hostile raw-write tests in the same block.

## Validation and revisit trigger

- **Evidence:** 131 Java-backed emulator assertions, including exact-shape, type, timestamp, Team, Player, report, feedback, vote, and like abuse cases; current-authority Discover and detail widget tests; repository transaction tests; 282 passing Flutter tests; and decision-specific evidence in `docs/changes/2026-08-25-stacked-v1-authority-integration-remediation.md`.
- **Revisit when:** a write moves entirely behind a server API, user media or variations become a shipped capability, an explicit offline mutation queue is approved, or Firestore Rules limits prevent a new parser-safe schema from being expressed safely.
