# Chants: Roadmap

The path from code-complete to public launch, with concrete triggers on every gate.

---

## Status (as of June 2026)

**Built and verified by static checks:**
- v1 feature set: auth, agnostic Sport/Competition/Team/Chant data model, browse and search, chant detail, user submission, moderation (report, remove, ban, rate limits, audit log), voting with counter reconciliation, suggestion box.
- v1 hardening: account deletion, App Check (soft enforce), Crashlytics, billing alerts with kill-switch.
- v1.1 dedup matching engine (backend only): token-overlap matcher, operator mergeChants function with source-payload snapshot.
- Visual identity: complete "matchnight, warmed with playful" redesign, tokenized, AA contrast proven.

**Not yet done:**
- Visual sign-off on device and the v1 flow walk-through.
- Real content seed.
- v1.1 social layer (frontend).
- Store launch prep.

---

## Phase 1: Private v1 sign-off

Run on device, confirm font weights render bold and heavy, walk all core flows and states.

**Trigger to exit:** Andrew confirms the redesign reads correctly and no flow is broken.

---

## Phase 2: Seed

Around five verified, externally sourced, policy-checked chants per PL club for the 19 unseeded clubs, plus verifying the Arsenal placeholder set. Content-integrity rule applies: lyrics and squads are sourced and verified externally, never authored from model memory.

**Trigger to exit:** All 20 clubs have a verified canonical primer set.

---

## Phase 3: v1.1 social layer

The reason public launch is gated to v1.1: the social and self-correction layer is core to the product feeling alive. Launching without it would feel static.

- Dedup nudge UI: wire the Block 8 matching engine into the submit flow as a soft "is it one of these?" nudge, not a hard block.
- Comments and replies, including collaborative lyric suggestions (propose a correction, crowd upvotes, most-upvoted surfaces), with reporting and moderation applied.

**Trigger to exit:** The social and self-correction surfaces work end to end on the seeded archive.

---

## Phase 4: Public launch prep

- Apple Developer and Google Play accounts, store listings and data-safety declarations, app icon and branding, 17+ age rating.
- Host the privacy policy and a light terms of service on Firebase Hosting, stamp the effective date.
- Flip App Check from soft to full enforcement after one to two weeks of clean telemetry.

**Trigger to launch:** All of the above complete and Phase 3 signed off.

---

## Cross-cutting risks (unchanged, tracked with triggers)

### Moderation and content safety (existential, addressed from v1)
Shipped: content policy stub, report/flag flow, remove/ban, rate limits, fail-safe auto-hide, audit log. Open: Andrew writes the real content policy text. Trigger for the fuller moderation console: submission volume outgrows basic remove-and-ban.

### Music and IP licensing (designed around, not a blocker)
v1 posture: lyrics plus tune-name text is the core. Media is optional and flexible. Never stream licensed master recordings. Trigger to revisit: engagement on light media formats proves demand and the licensing exposure is understood first.

### Cold-start and retention (addressed by design)
Solved by the operator-seeded primer, user submission, cross-club discovery, and the v1.1 social layer.

### Expansion
Architecture is sport-agnostic and league-agnostic from Block 1. Expansion is data, not code. v1 is Football and the Premier League. v2 adds leagues or sports based on usage data.

---

## v1 Launch Readiness

Parallel track (not a v1 launch blocker): flip the GitHub repo public for job applications; delete the two local backup folders once a fresh clone builds clean; Firebase client-key rotation remains optional since security rules and App Check are the primary protection.

### Build status

- **DONE** Blocks 1-5 built and working: auth, agnostic data model (Sport > Competition > Team > Chant), browse/search/detail, user submission, basic moderation (report/remove/ban/rate-limit/audit log), voting with optimistic UI, feedback channel.
- **DONE** Fanzine visual redesign across all surfaces (commit 4f9f8ae).
- **DONE** Vote rapid-tap reconciliation fixed (commit 9912adf).

### Content (owner: Andrew, critical path)

- **IN PROGRESS** Arsenal seeded and verified. Lyrics confirmed, three context notes confirmed factual and unflagged, plus several more verified chants added (player, club, and manager subjects). Arsenal is the showcase club and is effectively complete.
- **TODO** Seed the other 19 Premier League clubs. Target about 5 chants per club, roughly 100 total. Floor: no club below 3 genuinely iconic chants. All externally sourced and verified against a real version, never generated. Ship trigger: every club clears the floor and the marquee clubs sit at about 5.
- **TODO** Write the real content policy to replace the placeholder in content_policy_screen.dart. Required for app store review since submission is live. Andrew owns the wording.

### Polish and ship

- **TODO** Access-control verification with a second non-operator account. Confirm a normal user cannot open moderation, cannot edit or remove others' content, and cannot query hidden or removed chants.
- **TODO** Device walk of degraded states and enforcement: empty, loading, and error states on every screen; flagged content actually hidden at threshold; rate limits firing on rapid submission; fail-safe defaults for new accounts.
- **TODO** Final copy and em-dash sweep across the redesigned screens.

### Legal, store, and launch mechanics

- **TODO** Host a privacy policy and terms of service, link both in-app.
- **TODO** Apple Developer account ($99) and Google Play Developer account ($25).
- **TODO** Wire final app icon; set 17+ age rating.
- **TODO** Store listings, screenshots, and data-safety / app-privacy forms.
- **TODO** App Check production: register the DeviceCheck key, then flip soft to full enforcement after about one clean telemetry week.
- **TODO** Production build, signing, and deploy.
