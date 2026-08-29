# Decision 017: Separate creator identity and establish the product shell

- **Status:** Accepted foundation; Feed bridge and deferred social consequences superseded by decisions 018 through 020
- **Date:** 2026-08-27
- **Owner:** Andrew
- **Related:** Decisions 004, 011, 012, 015, and 016; creator platform expansion

## Context

Chants began as a trusted songbook and words-first Chant Lab. The approved product direction now restores the original creator-led vision: short performances can travel because they are funny, rough, impressive, or become the best-known rendition of a chant idea. The current push-only Home architecture does not make that loop legible, and the private `profiles` document contains authority fields that must never become a public creator page.

The media and social graph require their own bounded blocks. The first foundation still needs to make every future destination coherent without publishing fake performance data or exposing controls that cannot work.

## Decision

The signed-in product uses five persistent destinations:

1. Feed
2. Clubs
3. Create
4. Songbook
5. You

Feed initially renders the existing truthful Home discovery hierarchy. It becomes the Chant Stage only when real approved performance pagination exists. Create is visually central, remains text-labelled, and routes to the working words-first club flow until recording and library upload are implemented. You owns creator identity and every existing account action.

Public creator identity is stored in `creatorProfiles/{uid}`. Its allowlist is handle, public display name, short bio, server-owned aggregate counts, visibility, and timestamps. Private account authority stays in `profiles/{uid}`. Role, ban state, policy acceptance, age confirmation, deletion state, report count, email, and moderation detail are never copied to the public document.

Handles are lowercase, case-insensitively unique, three to 24 characters, and contain only letters, numbers, or underscores. A callable transaction reserves the normalized value in the server-only `creatorHandles/{handle}` collection, updates public identity, and safely releases the previous reservation only when the same account owns it. Direct client writes to either collection are denied. Hidden and removed creator documents are not publicly readable. Owners and operators may inspect them, but a removed identity cannot be republished by the client.

Account deletion removes the public creator document and an owned handle reservation in the final transaction. A reservation that belongs to another account is not deleted. Existing retained chants and comments remain governed by the deletion decisions and do not imply an active public profile.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Keep push-only Home navigation | Smallest client diff | Creator, creation, and matchday jobs remain hidden in unrelated routes | The approved product needs an understandable stable shell |
| Make `profiles` public | No second identity record | Exposes or risks exposing private authority and lifecycle fields | Public and private data require separate schemas and rules |
| Let clients claim handle documents directly | Fewer callable lines | Overlap, case normalization, and partial rename become unsafe | One transaction must own reservation and profile mutation |
| Show performance cards backed by fixtures | Faster visual impression | Pretends a data and moderation system exists | Feed stays honest until the performance block lands |
| Disable or label a Record action as coming soon | Signals direction | Creates a prominent dead control | Create exposes only working behavior |

## Consequences

- Positive: navigation now explains discovery, club browse, contribution, matchday saves, and personal identity in one stable frame.
- Positive: public creator reads cannot expose account authority by construction.
- Positive: handle collision and rename are server-serialized and case-insensitive.
- Positive: words-only creation remains available while media work proceeds.
- Positive: future performances, follows, and public routes have one stable creator identifier and privacy boundary.
- Historical negative, now resolved by decision 018: Feed looked like chant discovery until approved performance data existed.
- Negative: every creator identity update uses a callable and additional transaction reads and writes.
- Negative: public display name is duplicated from the private account name and needs the callable to keep both values aligned.
- Operational: a public web profile or bulk handle policy change must preserve the reservation and deletion contracts.

## Validation and revisit trigger

- **Evidence:** Functions tests cover exact parsing, overlapping handle ownership, rename, idempotence, private-account gates, and preserved server fields. Firestore emulator tests cover public visible reads, hidden and removed denial, owner and operator inspection, query predicates, and denied direct writes. Flutter tests cover parsing, repository failure mapping, five labelled destinations, representative and narrow layouts, enlarged text, set and unset identity, retained form state, removed state, and inspected golden evidence. Account-deletion tests cover creator and reservation cleanup plus a contested reservation.
- **Revisit outcome:** Decision 018 replaced Feed with real performance pagination; decisions 019 and 020 added the public and social consumers. Revisit again when device evidence shows five persistent destinations fail, creator names need independent account and public values, public web identity needs new fields, handle normalization must support additional scripts, or deletion policy changes retained creator attribution.
