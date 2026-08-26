# Decision 012: Account deletion preserves unknown acknowledgement outcomes

- **Status:** Accepted
- **Date:** 2026-08-26
- **Owner:** Andrew
- **Related:** Decisions 003 and 011; V1 freeze correctness remediation

## Context

The server accepts account deletion by committing a durable job before returning. A client transport exception does not prove that transaction failed. The prior client restored the active Saved Matchday Songbook on every thrown request, which could make local data readable again after the server had accepted destructive completion.

## Decision

Local deletion staging has three durable meanings: `prepared` before the network attempt, `unknown` before awaiting the remote response, and `accepted` after the callable explicitly confirms durable acceptance. Startup may restore prepared data and remove accepted data. It must neither restore nor discard unknown data.

A repeated request reuses the unknown artifact and the idempotent server request. A thrown request produces a dedicated unconfirmed result, keeps the local copy locked, and does not sign out. On every later signed-in launch, the app gate checks local state before Home and shows a persistent retry and Sign out screen while unknown remains.

Callable success is positive acceptance evidence. A verified profile with `deletionPending == true` is also positive evidence and may advance unknown local state to accepted cleanup. A false or missing pending value never restores unknown data because it can be cached, stale, or observed immediately before a timed-out request commits. Confirmed cleanup removes all potentially readable artifacts before deleting the accepted marker.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Restore on every exception | Simple retry experience | A committed deletion can be followed by local data restoration | Transport failure is not negative acknowledgement |
| Delete on every exception | Strong local privacy | A rejected or never-sent request destroys the only local copy | The client lacks proof of acceptance |
| Restore after observing `deletionPending == false` | Appears to recover a failed request | The observation can be cached or race a request that commits later | Negative observation is not rejection proof |
| Query positive profile status | Can confirm accepted state | Cannot prove rejection when false or unavailable | Use only `true` to advance cleanup |

## Consequences

- Positive: process death or a lost response cannot turn accepted deletion into local restoration.
- Positive: retry remains safe because the server request is idempotent and does not reset job progress.
- Negative: an unknown local artifact stays unreadable until a later request or positive pending marker confirms acceptance.
- Operational: a local status-read failure also gates Home and offers a retry instead of assuming no deletion state.
- Operational: accepted cleanup is best effort, and filesystem failure can retain unreadable bytes for later cleanup.

## Validation and revisit trigger

- **Evidence:** Fresh storage and repository instances cover prepared recovery, unknown preservation, accepted-last cleanup, conflicting artifacts, transient initialization retry, ambiguous response, retry acceptance, positive pending reconciliation, and sign-out behavior. App-gate tests and an inspected 390 by 844 golden verify persistent uncertainty and status-check states.
- **Revisit when:** the server exposes a separately authenticated deletion-status receipt, the client gains a cryptographically durable acknowledgement, or platform storage provides a stronger atomic lifecycle primitive.
