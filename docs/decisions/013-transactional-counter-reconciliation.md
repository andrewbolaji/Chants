# Decision 013: Ground-truth counters serialize through their parent document

- **Status:** Accepted
- **Date:** 2026-08-26
- **Owner:** Andrew
- **Related:** Historical counter decisions in `docs/DECISIONS.md`; V1 freeze correctness remediation

## Context

Recomputing an absolute counter from child rows is idempotent for duplicate delivery, but it is not sufficient under concurrent delivery. Two handlers can read different child snapshots and a slower older batch can overwrite a newer aggregate after it commits.

## Decision

Every ground-truth aggregate handled in this block reads the parent and matching child query, then writes the absolute aggregate, in one Firestore transaction. Vote and comment-like reconciliation also read the surviving interaction and stamp `appliedValue` in that transaction only when its current identity and value still match the event.

The shared parent write is the serialization point. A racing transaction retries and reruns its query against current ground truth. A missing parent is a successful no-op and is never recreated.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Absolute query plus batch | Idempotent for duplicate delivery | A stale handler can overwrite a newer result | It has no shared read-write conflict |
| Incremental deltas | Lower read amplification | Duplicate and reordered delivery can drift | At-least-once triggers require dedup state |
| Scheduled repair only | Cheap write path | User-facing counters remain wrong between repairs | Repair remains a fallback, not primary correctness |

## Consequences

- Positive: duplicate, reordered, and overlapping handlers converge to stored child truth.
- Positive: delayed cleanup events cannot recreate deleted parents.
- Negative: each aggregation scans the matching children and may retry under contention.
- Operational: measure read amplification before public volume and replace the design if contention or cost becomes material.

## Validation and revisit trigger

- **Evidence:** Functions tests cover duplicate, burst, delete, missing-parent, and a controlled overlap where an older vote transaction retries after a newer aggregate commits.
- **Revisit when:** aggregate volume makes query transactions too expensive, Firestore contention is observed, or an event ledger provides an equally durable deduplication boundary.
