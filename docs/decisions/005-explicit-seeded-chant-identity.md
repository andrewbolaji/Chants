# Decision 005: Seeded chants use explicit immutable document IDs

- **Status:** Accepted
- **Date:** 2026-08-21
- **Owner:** Andrew
- **Related:** Decision 004, Songbook and Chant Lab

## Context

The seed previously derived each chant document ID from its mutable title. A title correction therefore targeted a new Firestore document and left the old document plus its votes, comments, reports, saves, evidence, and future public links behind. This failure was reproduced before the framework was adopted. Its cost grows as engagement and public references accumulate.

Community chants already use Firestore-generated identities. The problem is limited to operator-seeded canonical chants. Arsenal was the only club seed file when this decision was accepted, which allowed its compatibility boundary to be established before the remaining clubs were written live. Source now contains all 20 approved clubs, and named-project preflight found all 192 targets collision-free. Arsenal reconciliation and the 19 new club writes remain behind explicit production hold points.

## Decision

Every seeded chant carries an explicit source-controlled `id`. The ID is immutable identity, while `title` remains editable display content.

Seeded IDs must:

- be non-empty lowercase slugs with single hyphen separators;
- begin with the club slug and a hyphen;
- be at most 120 characters;
- be unique within the club file.

The current Arsenal IDs are frozen to the exact values produced by the legacy title-derived algorithm. This makes the expected rollout an in-place contract change, not a document move.

Before the first club write, the seed reads the club's existing chants and every explicit target. It aborts if a target is not system-owned, belongs to another team, or a same-title system chant exists at another ID. `--preflight-only` exposes the check without calling any seed writer. Each chant create or update then repeats the target ownership and team check inside its Firestore transaction. A mismatch stops the run. Normal seed and readback paths never guess at, delete, or automatically migrate conflicting live state.

One separately approved reconciliation exception can retire only `players/arsenal-christian-norgaard`, `players/arsenal-leandro-trossard`, and `players/arsenal-tommy-setford`. The command accepts no club argument. One transaction re-reads all three exact Arsenal identities and chant-reference counts before scheduling a delete; any changed identity, reference, or invalid count aborts the entire action. Missing targets are idempotent. This is not a general orphan-deletion facility, and any target expansion requires a new decision and production hold point.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Continue deriving IDs from titles | No source-format change | Every rename can orphan engagement and links | Mutable display text is not identity |
| Generate new random IDs for all seeded chants | Strong future identity | Requires an immediate live migration of every dependent reference | The existing IDs can be frozen without a planned rename |
| Automatically move conflicting documents | Fewer operator steps | A mistaken collision policy could overwrite community content or lose dependent records | Unexpected live state requires evidence and a separate approved migration |

## Consequences

- Positive: title edits update the same expected document.
- Positive: remaining club files receive a stable contract before live engagement exists.
- Positive: predictable IDs cannot silently overwrite community content.
- Negative: every seed source must choose and retain an explicit club-prefixed ID.
- Negative: a live mismatch stops seeding and requires operator investigation.
- Operational: the 19 new source files retain offline review metadata and a dated roster snapshot, but the runtime projection writes only supported chant fields. Historic subjects remain club-linked until a separately reviewed archive model exists.
- Operational: read-only source compatibility does not authorize production mutation. Andrew must separately release Arsenal upsert and retirement, Leeds canary, and bounded widening after exact-head evidence.

## Validation and revisit trigger

- **Evidence:** Focused tests prove title independence, exact Arsenal legacy equivalence, duplicate-ID and normalized-title rejection, each collision class, transactional ownership recheck, safe create, content-only update, the exact 20-club source roster, current-player linkage, offline metadata validation, exclusion of that metadata from runtime writes, the exact three retirement targets, all checks before deletes, idempotence, identity and reference refusal, and persistent dangling-reference detection. The complete seed suite and TypeScript compiler pass.
- **Revisit when:** Seeded identity must span multiple clubs for one chant, a verified live collision requires migration, or the public URL design needs an identity layer that is not the Firestore document ID.
