# Decision 010: Safety intake is server-authoritative and atomically budgeted

- **Status:** Accepted
- **Date:** 2026-08-25
- **Owner:** Andrew
- **Related:** Decision 009; v1 report and feedback abuse controls

## Context

Chant, comment, and user reports used deterministic one-per-target document IDs, and Firestore rules enforced exact client shapes. Feedback also had an exact client shape. Those controls limited forgery and duplication for one target, but an authenticated raw client could still create reports across many targets or random-ID feedback as quickly as Firestore accepted writes.

Post-write triggers could recompute counters and auto-hide content, but they could not prevent the storage, trigger, audit, moderation, and counter work already caused by an accepted write. Querying recent client-authored timestamps would also leave the budget forgeable and vulnerable to read-then-write races.

## Decision

All v1 report and feedback admission uses authenticated `europe-west2` callable Functions. The server derives identity, time, status, resolution state, collection routing, and document ID. Direct client creates in `reports`, `commentReports`, `userReports`, and `feedback` are denied.

One private `safetyRateLimits/{uid}` document stores independent anchored report and feedback windows. Report validation, deterministic duplicate detection, the shared report budget, and report creation run in one Firestore transaction. Feedback validation, its budget, and feedback creation also run in one transaction.

The report window accepts 5 reports per hour for accounts under 24 hours and 20 for older accounts. Missing or malformed profile creation time uses the 5-report limit. Feedback accepts 3 entries per anchored 24 hours. Rejected and duplicate attempts do not spend budget. Rate state is not moderation evidence and is deleted during account deletion.

This decision narrows decision 009 for these four collections. Parser-safe direct-write schemas remain required where direct client writes still exist. Reports and feedback instead use the server callable as their parser and admission authority.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Count recent submitted documents | No new rate collection | Queries grow with use, timestamps and direct writes complicate authority, and admission is not one atomic decision | The private rate row gives bounded reads and transaction serialization |
| Store counters on profiles | Fewer collections | Expands the client-visible profile schema and mixes abuse state with user data | Rate state should stay private and operational |
| Keep direct creates and delete excess later | Small client change | Excess writes have already caused the load the control is meant to prevent | Admission must happen before storage |
| Rate each report target type separately | More allowances for legitimate users | Automated callers can multiply the budget across collections | All report types consume one moderation resource |
| Calendar buckets | Simple keying | A caller can receive two full allowances across one clock boundary | Anchored windows avoid that burst reset |

## Consequences

- Positive: reporter identity and stored server fields cannot be forged by a raw client.
- Positive: concurrent accepted writes serialize on one private document and cannot race past the limit.
- Positive: existing report IDs, trigger behavior, counters, audit rows, and owner/operator read boundaries remain compatible.
- Positive: duplicate retries preserve the original report and spend no additional budget.
- Negative: reporting and feedback now require a reachable callable even when Firestore itself is reachable.
- Negative: every accepted report uses four document reads and two writes; accepted feedback uses two reads and two writes.
- Negative: rate documents persist until account deletion because v1 adds no TTL or scheduled cleanup.
- Operational: deploy Functions first, a compatible client second, and restrictive rules last. Rules-first rollout would break the old client.

## Validation and revisit trigger

- **Evidence:** 56 Functions tests, 132 Java-backed rules assertions, 294 Flutter tests, scoped clean analysis, three deliberate red checks, and the completed record in `docs/changes/2026-08-25-v1-report-feedback-abuse-controls.md`.
- **Revisit when:** beta data shows legitimate users reaching the limits, moderation load justifies per-category budgets, App Check enforcement is approved, a distributed rate service is needed, or account deletion becomes resumable.
