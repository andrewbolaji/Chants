# Decision 012: Account deletion preserves unknown acknowledgement outcomes

- **Status:** Accepted
- **Date:** 2026-08-26
- **Owner:** Andrew
- **Related:** Decisions 003 and 011; V1 freeze correctness remediation

## Context

The server accepts account deletion by committing a durable job before returning. A client transport exception does not prove that transaction failed. The prior client restored the active Saved Matchday Songbook on every thrown request, which could make local data readable again after the server had accepted destructive completion.

## Decision

Local deletion staging has three durable meanings: `prepared` before the network attempt, `unknown` before awaiting the remote response, and `accepted` after the callable explicitly confirms durable acceptance. Startup may restore prepared data and remove accepted data. It must neither restore nor discard unknown data.

A repeated request reuses the unknown artifact and the idempotent server request. A thrown request produces a dedicated unconfirmed result, keeps the local copy locked, does not sign out, and tells the user to retry for confirmation. Only explicit acceptance allows accepted cleanup and sign-out.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Restore on every exception | Simple retry experience | A committed deletion can be followed by local data restoration | Transport failure is not negative acknowledgement |
| Delete on every exception | Strong local privacy | A rejected or never-sent request destroys the only local copy | The client lacks proof of acceptance |
| Query job status after failure | Could classify some outcomes | Auth or connectivity may already be unavailable and adds another ambiguous request | Retain uncertainty and use the idempotent request itself |

## Consequences

- Positive: process death or a lost response cannot turn accepted deletion into local restoration.
- Positive: retry remains safe because the server request is idempotent and does not reset job progress.
- Negative: an unknown local artifact stays unreadable until a later request confirms acceptance.
- Operational: accepted cleanup is best effort, and filesystem failure can retain unreadable bytes for later cleanup.

## Validation and revisit trigger

- **Evidence:** Fresh storage and repository instances cover prepared recovery, unknown preservation, accepted cleanup, ambiguous response, retry acceptance, deferred cleanup, and sign-out behavior. Interface tests verify uncertainty copy.
- **Revisit when:** the server exposes a separately authenticated deletion-status receipt, the client gains a cryptographically durable acknowledgement, or platform storage provides a stronger atomic lifecycle primitive.
