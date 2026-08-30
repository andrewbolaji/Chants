# Decision 025: Living Songbook updates remain reviewed, private intake

- **Status:** Accepted
- **Date:** 2026-08-29
- **Owner:** Andrew
- **Related:** Decisions 004, 006, 009, 010, 015, and 023

## Context

Chants is intended to be both a useful terrace archive and a place where new chants can emerge. A static seed cannot remain correct by itself. Wording changes by stand and supporter group, players and managers move, old songs become historic, and an original Chant Lab idea may later gain real public proof.

The inherited app had a safety report flow and generic feedback, but neither is the right authority for these changes. A safety report can hide content and affects abuse controls. Generic feedback loses the chant, version, variation, and provenance context. Decision 006 also recorded that a submitter had no way to add evidence after the original post.

## Decision

Chant detail exposes a distinct `Suggest an edit` action with three purposes: correct something, preserve another version, or add proof that a chant is being sung. These submissions are private to their submitter and operators, created only through a verified server callable, deduplicated against the server-read chant version, and protected by an independent anchored rate budget.

A suggestion is intake, not truth. Corrections and variations are applied through the reviewed canonical content or seed path, then the operator records the result. The request itself never rewrites title, lyrics, tune, player, club, era, or variations.

Evidence retains the narrow YouTube or X contract from Decision 006. An operator can attach reviewed evidence to a current visible Terrace Proven chant, attach it without promotion to a system-owned community chant, or attach it and promote a current visible user-created community chant in one transaction. Replacing different existing evidence requires explicit acknowledgement and preserves only the prior public evidence map in the operator-only audit. Only a real promotion creates at most one private milestone notification for a nonsentinel chant creator.

The source version is durable. A changed chant displays as stale in the queue. Evidence acceptance always rejects stale work. Other resolutions require explicit operator acknowledgement after reviewing the current chant. If the chant becomes missing, hidden, or removed, `Not changed` remains available as the only action so private intake cannot become unclosable work.

Safety reports remain separate in copy, collection, counters, moderation queue, and side effects. A chant update never increments a flag, hides content, resolves a safety report, or claims popularity is proof.

## Reasons

1. A living archive needs supporter input without surrendering editorial truth.
2. Variations should coexist when they are real, not be forced into a single winner.
3. Post-submission evidence completes the path from original idea to real terrace adoption.
4. Server-read versioning prevents an old suggestion from silently changing a newer chant.
5. Private resolution gives submitters closure without turning factual review into a public argument thread.
6. Keeping canonical edits in the reviewed content path prevents seed refreshes and one-off operator writes from diverging.

## Consequences

- Positive: supporters can improve the Songbook from the exact chant they are reading.
- Positive: historic, clean, away, local, and supporter-group versions can be preserved intentionally.
- Positive: an original idea can become Terrace Proven after real evidence and review.
- Positive: submitters can see Received, Planned, Updated, or Not changed with an optional resolution note.
- Positive: safety reporting retains its original moderation meaning and abuse budget.
- Negative: accepted wording and variation requests still require a deliberate operator content update.
- Negative: the operator queue performs one live chant read per open request so staleness is visible. It takes the oldest 50 open rows first and must be revisited before operator volume grows.
- Negative: the submitter history keeps only the newest 100 rows in one bounded live view. Older retained rows are not paginated in V1.
- Negative: V1 supports only YouTube and X evidence and depends on those public links remaining available.
- Operational: both composite indexes, rules, and compatible Functions must deploy before a client exposes the form. Account deletion removes suggestion content before profile finalization. Submitter-readable rows do not retain operator identity.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Reuse safety reports | Existing queue and schema | Correction volume can hide content and corrupt abuse signals | Accuracy and safety are different jobs |
| Reuse generic feedback | Small implementation | Loses chant version, purpose, evidence, and resolution state | Cannot support a trustworthy Songbook loop |
| Let users edit canonical chants | Fast correction | Makes unreviewed claims public and creates seed drift | Canonical truth stays reviewed |
| Public edit voting | Visible community decision | Popularity becomes fact and invites brigading | Votes rank taste, not truth |
| Auto-promote from a performance | Strong creator loop | A performance inside Chants does not prove terrace adoption | External evidence and operator review remain required |
| Store a public edit history | Strong transparency | Adds privacy, harassment, moderation, and permanent-content work | Private status is sufficient for V1 |

## Validation and revisit triggers

- **Validation:** Focused Functions tests cover exact parsing, derived identity, authority denials with no writes, dedupe, independent limits, retry behavior, unavailable closure, stale handling, evidence replacement, exact audit privacy, system-community attachment, atomic promotion, sentinel exclusion, and notification idempotence. Flutter tests cover payload authority, typed failures, malformed-row isolation, form purpose, evidence normalization, retained values, private history, stale acknowledgement, unavailable closure, replacement confirmation, and attach-versus-promote copy. Rules tests cover owner and operator reads plus complete direct-write denial. Account-deletion tests cover request removal.
- **Revisit when:** more than 50 open requests make the operator queue costly, a second operator needs assignment or service targets, correction acceptance needs an automated seed pull request, supporter volume justifies public version history, another evidence provider has an approved parser and moderation contract, or false submissions show the independent budget is too loose.
