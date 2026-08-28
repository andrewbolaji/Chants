# Decision 018: Separate chant performances from chant trust

- **Status:** Accepted
- **Date:** 2026-08-27
- **Owner:** Andrew
- **Related:** Decisions 004, 009, 010, 015, and 017; creator platform expansion

## Context

The original Chants vision includes short fan performances that can spread because they are funny, rough, inventive, or genuinely excellent. The existing model stores a chant idea and its archive trust state. Reusing that record for uploaded video would mix authorship, moderation, popularity, and stadium evidence into one authority boundary.

## Decision

A performance is a separate entity attached to one current visible chant. Many creators may perform the same chant. A performance cannot alter the chant's `canonical` or `community` status.

The client creates a private draft, receives an exact UID-scoped Storage path, uploads one MP4, MOV, or M4V object, and submits the draft for server verification. Duration is capped at 30 seconds and bytes at 50 MiB. Media remains private until an active operator approves it. Approval creates the public parser-safe projection and moves media to `performance-media/{performanceId}/source`. Rejected, cancelled, removed, and failed work remains non-public and has a bounded cleanup path.

Chant Stage exposes Rising, New, Terrace, and Following filters. Every query is bounded to ten records and paginated. Rising uses documented recent popularity inputs. Terrace selects performances whose underlying chant was already canonical. Following reads no more than the 30 most recent private follow edges and falls back honestly to Rising when the viewer is signed out or follows nobody.

Performance likes, qualified views, shares, and comments are separate from chant votes. One account contributes at most once to each ranking signal. A qualified view is recorded only after three seconds of playback. The weekly winner uses unique shares, then likes and qualified views as deterministic tie breakers, and appears only when the winning record has at least one unique share.

Playback requires current performance authority and returns a short signed URL. The feed does not autoplay or prefetch video. A visible poster and explicit play action keep data use and accessibility predictable.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Put video fields on chants | Fewer collections | One upload can overwrite the chant concept and confuse popularity with terrace proof | Chant and performance have different creators, trust, and moderation lifecycles |
| Publish immediately and moderate later | Faster creator feedback | Unsafe media becomes public before review | V1 volume supports manual pre-publication review |
| Count every play and share tap | Larger numbers | Self-refresh and retries distort competition | Deterministic per-account records make the meaning defensible |
| Autoplay a vertical feed | Familiar social pattern | Unbounded egress, surprise audio, and weaker user control | V1 uses deliberate playback and no background prefetch |
| Build karaoke editing now | Closer to the long-term vision | Audio licensing, timing, rendering, and moderation multiply launch risk | Record or import preserves creator freedom without an editor platform |

## Consequences

- Positive: creator reach can grow without changing archive truth.
- Positive: private staging and operator approval make public visibility explicit.
- Positive: counters can be recomputed from deterministic source records after duplicate trigger delivery.
- Positive: Stage can support multiple performances around one chant.
- Negative: every approved video adds Storage, signed-URL, and egress cost.
- Negative: manual review limits safe upload volume.
- Negative: current Following pagination is bounded by Firestore's 30-value `whereIn` limit.
- Operational: abandoned staged objects need scheduled cleanup, and billing plus moderation alerts are launch gates.

## Validation and revisit trigger

- **Evidence:** `functions/src/performance.ts`, `storage.rules`, `firestore.rules`, `lib/data/repositories/performance_draft_repository.dart`, `lib/data/repositories/performance_repository.dart`, `lib/presentation/create/perform_chant_screen.dart`, `lib/presentation/feed/chant_stage_screen.dart`, Functions tests, rules emulator assertions, Flutter repository tests, widget tests, and an inspected Stage golden.
- **Revisit when:** manual review misses its chosen response target, Storage or egress crosses the launch budget, Stage needs cursoring across more than 30 followed creators, qualified views need anonymous support, or karaoke, remix, and licensed-audio work receives a separate approved design.
