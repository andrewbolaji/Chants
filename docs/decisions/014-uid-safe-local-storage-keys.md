# Decision 014: UID-scoped local files use lowercase SHA-256 keys

- **Status:** Accepted
- **Date:** 2026-08-26
- **Owner:** Andrew
- **Related:** Decision 003; V1 freeze correctness remediation

## Context

Saved Matchday Songbook filenames previously used base64url-encoded Firebase UIDs. Base64 identity is case-sensitive, while common mobile filesystems compare filenames without case. Distinct UIDs could therefore resolve to the same local path.

## Decision

New UID-scoped Songbook paths use the lowercase hexadecimal SHA-256 digest of the UID's UTF-8 bytes. The result is a fixed 64-character filename component whose identity does not depend on filesystem case behavior.

The active UID lazily migrates its matching legacy active, temporary, and deletion-state files. The old ambiguous deletion suffix maps to unknown because it did not record whether the server accepted deletion. Migration does not enumerate and open other UID files.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Lowercase the old base64 key | Small change | Deliberately merges case-distinct identities | It preserves the collision |
| Use raw UID text | Easy inspection | Filename and platform-character assumptions leak into storage | Hashing gives a bounded portable component |
| Add a hashing dependency | Standard implementation | Changes dependency and lockfile scope for one small primitive | A locally tested SHA-256 implementation keeps the freeze block bounded |

## Consequences

- Positive: future case-distinct UIDs cannot share a path on a case-insensitive filesystem.
- Positive: filenames are fixed length and reveal no raw UID.
- Negative: legacy files do not contain an ownership marker, so migration can only follow the currently authenticated UID's prior key.
- Operational: future local stores must reuse the digest helper or record an explicit owner inside a stronger storage container.

## Validation and revisit trigger

- **Evidence:** Known SHA-256 vector, mixed-case collision pair, file reconstruction, and active legacy migration tests.
- **Revisit when:** local state moves into an encrypted database with account-scoped namespaces, the UID format changes, or a platform storage API supplies case-sensitive keyed isolation.
