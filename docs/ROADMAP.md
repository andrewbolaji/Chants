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
- Nested/threaded comment replies, the collaborative lyric-suggestion mechanic (propose a correction, crowd upvotes, most-upvoted tweak surfaces), and comment downvotes. (Flat comments with single likes are now v1; see v1 Launch Readiness below.)

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
- **DONE** Vote stale-load mismatch fixed via appliedValue reconciliation; detail screen now subscribes to a live chant stream (commit 38f559a).

### Comments on chants (v1, flat, with likes)

Build after the vote-fix device walk passes, as the last feature block before the remaining launch-prep (seed the other clubs, real content policy, store setup). Plan-first: it introduces a new collection and a new content-safety surface, so it gets a plan Andrew approves before any code.

**Scope in:** a comments collection; post a comment; delete your own comment; a flat comment list on the chant detail screen (single level); a single like per comment per user (upvote only, no downvote) with a denormalized like count; sort by likes descending then newest first; a comment count on the chant card; and the FULL moderation path reused from chant submissions (report a comment, operator remove, ban, rate-limit new or unproven accounts, audit-log every moderation action). Comment likes reuse the appliedValue reconciliation pattern from chant votes so cold loads show the correct count and do not reintroduce the stale-count bug.

**Scope out (stays v1.1):** nested or threaded replies; the collaborative lyric-suggestion mechanic where the most-upvoted tweak surfaces; comment downvotes.

**Note:** confirm at plan time that the chant card can carry a comment-count element without crowding the existing minimal card (tune line, title, who-it-is-for, one lyric line, vote chip, subject label); the like affordance itself lives on the comment, not the card. This is a deliberate density decision.

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

---

## Launch and marketing plan

### Pre-launch (start now, needs weeks of runway)

- **One-sentence pitch**, used everywhere (store subtitle, site headline, social bios): *Chants is the songbook of the terraces. Find the words, learn them, and add your own.*
- **Build in public** on one platform, 2 to 3 posts a week. Primary platform is the one where football fans actually gather (X or TikTok). Claim the @chantsfc handle everywhere for consistency but only post actively on the primary.
- **Collect waitlist emails** on chantsfc.com. Even 30 to 100 people means launch day is not silent.
- **Join five watering holes** as a real member, weeks before launch: Arsenal and other club subreddits, football fan Twitter, terrace-culture and fan forums. Be helpful, never spam, so at launch you are a member sharing something, not a stranger advertising.
- **Line up 5 to 10 soft-launch testers** who will try it early, give honest feedback, and leave a day-one rating.
- **Assemble a launch kit** in one folder: logo, 3 to 5 clean screenshots, the one-sentence pitch, a 100-word description, and the founder story in three sentences (English-born Arsenal supporter building the songbook the terraces never had).

### Launch day

- Email the waitlist first, in the morning.
- Post to the five watering holes, tailored to each, leading with the story and the problem, not the feature list.
- Launch on Product Hunt (Tuesday to Thursday), and Show HN if the technical angle fits.
- Post the LinkedIn launch piece the same day, only once the app is live with a working store link.
- Flip the store pills on chantsfc.com from coming-soon to the real App Store and Play URLs.
- Reply to every comment and email for the first 48 hours. Ask for ratings.

### Post-launch (the grind)

- Content cadence of 2 to 3 posts a week on the primary platform, tied to matchdays and the transfer window (every new signing needs a chant).
- Make in-app sharing native (share-out to X, TikTok, YouTube is already planned for v1.1) since user sharing is the real growth engine.
- Add an in-app prompt asking happy users to rate the app after a good moment; store ratings drive organic discovery more than anything.
- SEO groundwork: repurpose handbook and chant content into public help and lyrics pages on chantsfc.com, which compounds over time.

### Budget (hold under 500 dollars)

- Domain and hosting: roughly 30 dollars a year, already committed.
- Hold off on paid ads until the free channels prove the app resonates.
- Best paid dollar is one football-culture micro-influencer (roughly 100 to 300 dollars) rather than scattershot ads.
- Skip PR firms, broad untargeted ads, and anything promising download counts.
