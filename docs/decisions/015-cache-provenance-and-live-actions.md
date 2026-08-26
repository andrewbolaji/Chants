# Decision 015: Firestore cache snapshots never authorize live actions

- **Status:** Accepted
- **Date:** 2026-08-26
- **Owner:** Andrew
- **Related:** Decision 009; V1 freeze correctness remediation

## Context

An active Firestore stream can emit a visible document from local cache before the server confirms its current existence or moderation state. Connection state and absence of an error therefore do not prove current authority.

## Decision

The single-chant repository preserves `SnapshotMetadata.isFromCache` and listens for metadata changes. Cached route and Discover content may remain readable. Share, Report, Vote, Comment, a new save, and other server or external target actions require a non-cache, active, error-free, visible document from the server.

Already-saved Songbook branches are local state, not live-target authority. Opening the locally saved club route and removing an individual device copy remain available from cached detail. They never create a new snapshot or call Firestore.

Authoritative absence, hidden, removed, or permission denial still removes the live target. An ordinary transient error may retain readable fallback without restoring action authority.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Treat active stream as authoritative | Minimal repository change | Active can still mean cache-only | Connection state does not express provenance |
| Hide all cached content | Simple authority | Removes useful lyrics during poor connectivity | Reading and acting have different risk |
| Allow every action and rely on rules | More controls appear available | A new local save and native share escape server rules | Authority must precede new target side effects |
| Disable already-saved local actions | One uniform gate | Breaks offline Songbook navigation and cleanup without reducing server risk | Gate each branch by its real authority requirement |

## Consequences

- Positive: cached lyrics remain useful without reviving moderated or deleted targets as actionable.
- Positive: metadata-only server confirmation can enable actions without a content mutation.
- Negative: server and external target controls can remain disabled while the device has only cache, even if that cache is recent.
- Operational: every future live-target action must consume the same provenance-aware authority state.

## Validation and revisit trigger

- **Evidence:** Detail and Discover widget tests emit cached visible data followed by server-confirmed data and verify readability, disabled target actions, later enablement, and cached removal or navigation for existing saves.
- **Revisit when:** an approved offline action queue defines target versions and conflicts, or a shared repository authority type replaces the current stream contract.
