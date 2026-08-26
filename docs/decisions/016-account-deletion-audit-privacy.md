# Decision 016: Account deletion redacts audit identity and report text

- **Status:** Accepted
- **Date:** 2026-08-26
- **Owner:** Andrew
- **Related:** Decisions 010, 011, and 012; post-freeze independent review corrections

## Context

The durable deletion job removed report documents but did not process `auditLog`. Report triggers stored the reporter UID and the submitted reason, which can include user-authored text. The completion audit also placed the deleted UID in its document ID, actor, and target. Account deletion could therefore complete while retained audit rows still linked the deleted account to report text.

Audit history still has a legitimate moderation and security purpose. Deleting every row about an account would also erase records created by operators or other reporters. The boundary needs to remove the deleting user's identity as an actor without pretending that all safety history disappears.

## Decision

Account deletion includes a bounded `anonymize-audit-by` phase. It queries at most 200 `auditLog` rows whose `actorId` is the deleting UID, replaces the actor with `deleted-user`, and replaces detail with deletion-safe generic text. The page is idempotent and uses the existing forward-only job heartbeat and phase transition.

New report audits read the reporter profile in the same Firestore transaction that writes the audit row. A pending or missing profile writes `deleted-user` and no report reason. This closes the delayed-trigger race where an old report-create event arrives after the deletion worker has already scanned audit rows.

The final deletion audit uses a random Firestore document ID, `system` as actor, `deleted-user` as target, and generic detail. It contains no raw deleted UID. Audit rows where the deleted account is only the target may remain as moderation or security history. User-facing copy discloses retained anonymous safety records.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Delete every audit row involving the UID | Broad erasure | Removes operator and third-party safety history | Target-side records have a different owner and purpose |
| Disclose existing retention without redaction | Smallest code change | Retains reporter identity and free text after deletion | Data minimization is achievable with the existing worker |
| Redact only in the deletion page | Reuses one phase | A delayed report trigger can write identifying data after the page advances | Writers must also respect the lifecycle boundary |
| Store only anonymous report audits for every account | Eliminates deletion-specific identity work | Removes active-account abuse investigation capability | The narrower deleting-or-missing profile condition is sufficient |

## Consequences

- Positive: completed deletion does not retain the user's UID or report text as an audit actor.
- Positive: delayed report triggers cannot reintroduce identity after the pending marker or profile deletion.
- Positive: page processing remains bounded, retryable, and compatible with the existing job model.
- Negative: audit rows about the deleted account can remain when another actor created them.
- Negative: the repository still has no time-based audit retention policy or export workflow.
- Operational: audit redaction is forward-only privacy work. A faulty deployed version needs a forward correction, not restoration of identity.

## Validation and revisit trigger

- **Evidence:** Functions tests cover a 201-row redaction population, empty-page advancement, pending and missing reporter writes, reason removal, and a non-identifying completion row. Flutter tests and inspected goldens cover the disclosed pending and unknown states.
- **Revisit when:** legal retention requirements are approved, an audit retention schedule is introduced, operator investigations require a different pseudonymous key, or a general privacy-deletion service replaces the current worker.
