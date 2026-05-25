# Chants: Roadmap

Compliance and external-scope content here is AUTHORITATIVE. The content-safety posture, the IP / licensing posture, and the expansion phasing are built on the strategic analysis in the handoff and are not second-guessed during build. Architecture, tests, schema, and UX remain open for debate.

This roadmap exists because two of the three cross-cutting risks are external (app-store policy and music IP), not just product preferences. They get tracked with concrete triggers, not buried in the spec.

---

## Risk 1: Moderation and content safety (existential, addressed from v1)

Chant culture contains genuinely harmful material: racism, homophobia, sectarian abuse, tragedy chanting (Hillsborough, Munich, and others), and targeted threats. An app that centralizes and amplifies chants will attract this. Unhandled, it becomes a reputational and legal liability and gets pulled by Apple and Google for hosting hate speech.

**Confirmed stance:** no homophobic chants, no protected-class hate, no tragedy chanting, no targeted threats, nothing that oversteps. The real-versus-parody tag is a discovery mechanic, NOT a moderation system.

**Shipped in v1 (Block 3, alongside submission):**
- A clear written content policy (Andrew drafts the actual line; the framework helps write it).
- A report / flag flow on every piece of user content.
- The ability to remove content and ban users fast, all audit-logged.
- Rate-limiting and fail-safe defaults for new or unproven accounts (content auto-hides pending review once flagged past a threshold).
- The operator seed is policy-checked before entry.

**Trigger to promote the fuller moderation console (v1.1, Block 10):** submission volume produces a review backlog the basic remove-and-ban cannot keep up with.

**Open decision gating Block 3:** Andrew writes the actual content policy text. The line is his. Required before submission ships.

## Risk 2: Music and IP licensing (designed around from v1, not a v1 blocker)

Chants ride existing copyrighted melodies. Streaming the underlying recorded track raises copyright. TikTok and Instagram have licensing deals, a small app will not.

**v1 posture (authoritative):**
- Lyrics plus tune-name text is the lowest-risk core and is the required minimum for any chant.
- Media is optional and flexible: tune recordings, lyric videos, a cappella, screen recordings, crowd clips. These carry less risk than streaming masters.
- Do NOT build anything that streams licensed master recordings. (Pinned in WISHLIST: Skipped.)

**Trigger to revisit (before any v2 heavy-video work):** engagement on the light media formats proves demand AND the licensing exposure of the specific proposed format is understood and written down first.

## Risk 3: Cold-start and retention (addressed by design)

Solved by the operator-seeded primer (credible day one), user submission completing the archive, the cross-club discovery surface, the matchday rhythm, and the new-signings engine. No separate roadmap action; it is built into the v1 and v1.1 feature order.

---

## Expansion phasing (the anti-outflank plan)

The architecture is sport-agnostic and league-agnostic from Block 1, so expansion is data, not code.

- **Now (v1):** Football and the Premier League only. All 20 PL clubs and squads. Depth and credibility first.
- **v2, on trigger (proven PL traction or a concrete market reason):** add La Liga or another league (rows plus a content-policy pass per new area).
- **v2, on trigger:** add another sport (a sport plus its teams, plus a content-policy pass).

The point: we cannot be outflanked on breadth because a new league or sport is an afternoon of data entry. We CHOOSE focus for depth, then expand at the speed the market demands.
