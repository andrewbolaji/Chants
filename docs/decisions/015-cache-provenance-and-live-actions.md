# Decision 015: Firestore cache snapshots never authorize live actions

- **Status:** Accepted
- **Date:** 2026-08-26
- **Owner:** Andrew
- **Related:** Decision 009; V1 freeze correctness remediation

## Context

An active Firestore stream can emit a visible document from local cache before the server confirms its current existence or moderation state. Connection state and absence of an error therefore do not prove current authority.

## Decision

The single-chant repository preserves `SnapshotMetadata.isFromCache` and listens for metadata changes. Cached route and Discover content may remain readable. Save, Share, Report, Vote, Comment, and other live-target actions require a non-cache, active, error-free, visible document from the server.

Authoritative absence, hidden, removed, or permission denial still removes the live target. An ordinary transient error may retain readable fallback without restoring action authority.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Treat active stream as authoritative | Minimal repository change | Active can still mean cache-only | Connection state does not express provenance |
| Hide all cached content | Simple authority | Removes useful lyrics during poor connectivity | Reading and acting have different risk |
| Allow actions and rely on rules | More controls appear available | Local save and native share escape server rules | Authority must precede irreversible side effects |

## Consequences

- Positive: cached lyrics remain useful without reviving moderated or deleted targets as actionable.
- Positive: metadata-only server confirmation can enable actions without a content mutation.
- Negative: controls can remain disabled while the device has only cache, even if that cache is recent.
- Operational: every future live-target action must consume the same provenance-aware authority state.

## Validation and revisit trigger

- **Evidence:** Detail and Discover widget tests emit cached visible data followed by server-confirmed data and verify readability, disabled actions, and later enablement.
- **Revisit when:** an approved offline action queue defines target versions and conflicts, or a shared repository authority type replaces the current stream contract.
