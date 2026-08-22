# Decision 007: Browse surfaces are status projections with stable visit order

- **Status:** Accepted
- **Date:** 2026-08-22
- **Owner:** Andrew
- **Related:** Decisions 004 and 006, Songbook and Chant Lab

## Context

Team and Player routes previously mixed canonical and community chants into one score-ranked list. Provenance labels made each card more honest, but one feed still asked popularity to carry both archive trust and creative competition. The Team route froze an initial order and could omit newcomers, while the Player route could move a vote control when a score emission reranked the list. Neither route exposed Firestore cache provenance or retained readable data through a later stream error.

The existing `canonical` and `community` values already express the approved v1 trust boundary. A separate backend ranking system, new status, or new query would add cost and another authority without improving that boundary.

## Decision

Team and Player routes expose two text-labeled surfaces from one visible chant subscription:

- Songbook contains only `status == canonical` and opens first.
- Chant Lab contains only `status == community`.
- Unknown future statuses appear in neither surface until a later decision assigns their meaning.

Songbook and Chant Lab Top share one deterministic total order: score descending, creation time ascending, then document ID ascending. Each route keeps survivor positions stable during its visit, removes ineligible IDs immediately, and appends newcomers in current deterministic order. Chant Lab New recomputes creation time descending, then ID ascending, so a genuinely new post may appear first.

Rising is true only for a community chant with score at least 3 whose creation time is not in the future and falls within the inclusive previous seven days. It is presentation only and never changes status, promotion eligibility, or trust copy.

Firestore queries keep the existing hidden and removed filters and expose snapshot cache metadata with `includeMetadataChanges: true`. Each route owns one chant subscription and retains its last successful snapshot independently from a later error. Player metadata is a separate enrichment stream whose loading or failure can affect names, grouping, and squad controls but never chant visibility.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Keep one mixed ranked feed | Smallest UI change | Popularity and verification remain visually entangled | It contradicts the approved product contract |
| Query Songbook and Chant Lab separately | Server-side membership split | Adds subscriptions and reads per route, plus more index surface | The route already has the complete visible set |
| Rerank Top after every vote | Always reflects current score order | Moves controls under the fan's finger and makes browsing unstable | A route visit prioritizes interaction stability |
| Use score alone to make Rising or Proven | Very simple | Popularity can be mistaken for historical proof | Votes measure momentum, not evidence |
| Replace prior data on reconnect error | Simpler transient state | Discards useful readable chants and overstates failure | Last usable data plus honest copy is more resilient |

## Consequences

- Positive: Songbook trust and Chant Lab creativity are legible without reading individual scores.
- Positive: vote updates refresh card content without moving surviving controls during the visit.
- Positive: promotion and demotion move the same chant identity between surfaces without data migration.
- Positive: cached or previously loaded chants remain usable with explicit, neutral supporting copy.
- Negative: Top may temporarily differ from a fresh visit after score changes because interaction stability is intentional.
- Negative: Rising depends on client time, but it remains decorative and non-authoritative.
- Operational: no new Firestore field, index, rule, Function, dependency, migration, Firebase access, or deployment is introduced.

## Validation and revisit trigger

- **Evidence:** Pure tests cover fail-closed projection, deterministic Top and New order, negative scores, inclusive Rising boundaries, and stable reconciliation. Team and Player widget tests cover surface separation, promotion movement, stable score-time order, player-prefilled creation, signed-out empty behavior, cache copy, player failure, pre-data error, and retained data after a later error. Inspected 390 by 844 goldens and an enlarged-text test cover the hierarchy.
- **Revisit when:** A team exceeds 500 visible chants, client projection exceeds 16 ms at p95 on the representative device, lifetime Top makes old entries immovable, closed-beta users misunderstand either surface, or a server ranking contract becomes necessary for pagination.
