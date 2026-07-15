# Chants: Wishlist

## v1.1 (committed, fast follow after v1 ships and gets real use)

### v1.1: Home screen rotating quote
**The idea:** A single shared quote everyone sees on the home screen, rotating roughly every 3 days, chosen date-deterministically from a curated quotes collection (no per-user randomness, no server cron). Andrew appends entries over time, each copyright-cleared before adding. Real attributed football quotes preferred over copyrighted song lyrics. Goes on the home screen, NOT the OS launch or splash screen (platform guidance keeps that minimal, and it flashes too fast to read).
**Why v1.1:** Home-screen polish once the core content is proven.

### v1.1: Duplicate and variants model (the first v1.1 feature)
**The idea:** One entry per chant with the crowd refining it (the Genius and Wikipedia model), not many competing uploads. Reached through three soft moves: (1) Nudge on submit: show similar existing chants ("is it one of these?") and funnel to the existing entry, creating a new one only if genuinely new. Reuses search, cheap, pull forward as the first v1.1 feature. (2) Variants live inside the entry: a primary version plus alternate versions and suggested corrections, surfaced by votes and confirmed by the operator. (3) Operator merge as the backstop for duplicates that slip through. Avoid hard automatic duplicate-blocking: it is brittle and wrongly blocks genuinely new chants.
**Why v1.1:** Prevents the archive from fragmenting as user submissions grow. Without it, popular chants get multiple near-identical entries that dilute votes and confuse users.

### v1.1: Comments, replies, and collaborative lyric suggestions
**The idea:** Threaded discussion on a chant, plus a lyric-suggestion mechanic where the most-upvoted tweaks surface at the top, turning comments into a refinement engine.
**Why v1.1:** The social layer is what makes the app sticky, but v1 has to prove find-and-add first. Reporting and moderation apply.

### v1.1: Follow accounts and personalized feeds
**The idea:** Follow other users, plus a For You feed and a Following feed.
**Why v1.1:** Needs a base of users and content to be worth anything. Build on the seeded-plus-submitted archive.

### v1.1: Subtle surface grain
**The idea:** A faint print grain on card and scaffold surfaces, part of the locked "matchnight, warmed with playful" design direction, to add tactile programme-paper texture.
**Why deferred:** The grain asset was generated during the redesign but never wired to any surface, so it was removed rather than shipped as a dead asset. The design reads well without it.
**Trigger to promote:** If, on device review, the warm surfaces feel flat or too clean and want more texture. Implement as a cheap static tiled low-opacity PNG overlay (3 to 5%) on card and scaffold surfaces, not a runtime ShaderMask on scrolling lists, and confirm scroll stays smooth.

### v1.1: New-signing creation prompts
**The idea:** A focused creation flow tied to the squad, "make a chant for [new signing]," self-refreshing every transfer window.
**Why v1.1:** Sits on top of v1 submission. A centerpiece for retention once the base exists.

### v1.1: Share out to X, YouTube, TikTok
**The idea:** First-class sharing so a chant made here goes viral on the platforms fans already use.
**Why v1.1:** The app is the workshop, those are the stage. Add once there is content worth sharing.

### v1.1: Fuller moderation console
**The idea:** Operator-side queue, flag thresholds, bulk actions, on top of Block 3's basic remove-and-ban.
**Why v1.1:** v1 ships the basics that keep it safe; the console is an efficiency layer once volume justifies it.

### v1.1: Link a video of the chant
**The idea:** An optional field on a chant for a link to a video of it (YouTube or X), shown as a "Watch it sung" button that opens the link. Any rendition counts: a crowd clip, a famous version, a lyric video, or the creator's own. Never required, never about showing a face.
**Why v1.1, not now:** Complements submission and the sharing layer and reinforces the workshop-versus-stage positioning. Not a launch blocker.
**Why this is not the v2 video feature:** Link-out only, not hosting. No storage, no transcoding, and a far safer IP posture, since the copyrighted audio lives on YouTube or X, not on us. The v2 hosting-and-playback item stays separate.
**Guardrails:** Domain-allowlist to YouTube and X, validate the URL format, and route the link through the existing report-and-remove moderation path. No open URLs. Handle dead or removed links gracefully.
**Trigger:** Build alongside or right after the comments and lyric-suggestions block, since it shares the submission and moderation surfaces.

### v1.1: Chant quiz and greatest-chant bracket
**The idea:** Two shareable, fun surfaces built on the verified archive. A chant quiz (guess the club or player from the lyrics or tune, share your score) and a greatest-chant bracket (real chants head to head, crowd votes through rounds, crown a champion). Both make the app fun and shareable and reinforce the real-chants-board identity.
**Why v1.1:** Part of the engagement and feels-alive layer that gates the public launch. The bracket reuses the existing voting mechanic, so it is the cheaper build and the v1.1 anchor; the quiz is the fast follow right behind it.
**Sequencing within v1.1:** Both need the seeded archive to be good, so they come after seeding. Real chants only, club-neutral, same content policy.
**Trigger:** Build alongside or right after the comments and lyric-suggestions block, bracket first.

### v1.1: Top and New tabs on the club screen
**The idea:** Split each club's chants into a default Top tab ranked by score and a New tab in time order, the Reddit Hot/New pattern, so a flood of new submissions lives in New while the proven chants stay in Top. A score floor can drop heavily downvoted chants out of the Top tab entirely.
**Why v1.1:** At launch clubs hold a handful of chants and all seed scores are 0, so a tab bar over a near-empty flat list looks worse and solves a saturation problem that does not exist yet. The score ranking shipping now is the foundation these tabs sit on.
**Trigger:** A club's visible chant list passes about 25 chants, or submissions start producing regular low-value entries that bury the good ones. Build it then, together with the score floor.

### v1.1: Community-submitted, votable chant variations
**The idea:** The full version of the seed-only variations shipping in v1. Users suggest an alternate line, others vote, and the most-sung variation surfaces on the chant detail.
**Why v1.1:** It is the natural evolution of the v1 display-only variations and reuses the voting that already exists.
**Trigger:** v1 seed-only variations are live and users start asking for or proposing alternates. Build it as a user-content surface with the same reporting and content-policy path as chant submission.

### v1.1: Terrace Classics (general cross-club chants)
**The idea:** A browse section for the generic chants every club sings with only the name swapped: "you're going down", "you're not singing any more", "is this a library", "can you hear the [X] sing? No no", "who are ya", "you're shit and you know you are", and the "Allez Allez Allez" template. These are not tied to one club, so they do not belong under any single club. Store each once, tagged by the tune it uses, and surface them in their own section instead of duplicating them under all 20 clubs.
**Why v1.1:** The per-club archive is the v1 job and lands first. General chants are a separate sourcing pass and a separate piece of navigation. Adding them now would clutter every club page.
**Trigger to promote:** v1 shipped with the per-club Premier League archive live, plus either users asking for the generics or the generics starting to clutter club sections. Same sourced-and-verified, no-generated-lyrics rule as all other content.

### v1.1: Light and dark theme toggle
**The idea:** A user-facing theme toggle in settings, defaulting to the current dark "Ink and Gold" theme, with a new light theme as the alternative. It respects the device system setting on first launch and persists the user's explicit choice after that.
**Why v1.1:** v1 ships in one polished dark theme. A light option is a comfort and accessibility win (bright environments, personal preference) but it is not a launch blocker, and it should wait until the core surfaces are stable so we theme a fixed set of screens once rather than chasing a moving target.
**Design direction:** The light theme is derived from the marketing site palette (cream and paper surfaces, ink text, the same gold, a blue accent), so the website and the app light mode share one identity. Both themes run entirely through the existing tokens in colors.dart, theme.dart, and spacing.dart, so the switch is a token-map swap with zero hardcoded hex in any screen. Every surface, including the Fraunces lyric view and the Verified elements, is checked for WCAG AA contrast in both themes.
**Trigger to build:** After v1 is live with 30 days of real use, and once no core screen is still changing shape.

---

## v2 candidates (pin, do not build, need real usage data)

### v2: Full-text search via external index (Algolia or Typesense)
**The idea:** Free-text search across lyrics, player names, and tune names, using the Firebase extension that mirrors the chants collection into a search index.
**Why pin, not build:** Browse-and-filter covers v1. The add is purely additive (it reads existing chant docs and runs alongside, no schema or screen rewrite), so there is zero penalty for waiting.
**Trigger to promote:** the first time a real user asks to search by a lyric fragment, OR when any club's chant count grows past what scan-the-list browsing handles comfortably.

### v2: Expansion beyond the Premier League (the ladder)
**The idea:** The data model is already Sport > Competition > Team > Chant, so widening coverage is data and configuration, never a rewrite or a rebrand. Three rungs, in order. Rung 1, wider English clubs (Championship and below): do not operator-seed these, instead open the submittable club list so fans add and grow their own club sections, with new entries arriving as community and earning Verified over time. This is user-driven seeding, not operator legwork. Rung 2, other football leagues and languages (La Liga, Serie A, and so on): football is the global center of chant culture (Madrid, Boca, the ultras scenes), so this is the strongest expansion, and each new region is a data load plus a content-policy pass. Rung 3, other sports (US basketball, NFL, and the like): a different motion, because those crowds have little to archive, so here the app is a creation tool trying to help start a singing culture rather than catalogue an existing one. Highest risk, furthest out.
**Why pin, not build:** Launching narrow and deep in the Premier League is what buys credibility and a sharp story. Empty or thin sections on day one read as unfinished and undo the seed's whole purpose. Every rung above costs almost nothing to switch on later precisely because the architecture already absorbs it, so deferring is free.
**The real gate is moderation, not tech:** Each new language or region needs people who know its chants, rivalries, and where the line sits (sectarian, political, tragedy chanting). Do not open a region until that content-policy capability exists for it.
**Trigger to promote each rung:** Rung 1 when the Premier League core is populated and actively used, with submissions and votes flowing. Rung 2 when rung 1 shows real cross-club demand and a per-region moderation path is ready. Rung 3 only if football is clearly won and a specific market reason appears.

### v2: Top chart leaderboard
**The idea:** A most-liked / most-viewed ordered leaderboard, per club and overall.
**Why pin, not build:** Needs real voting volume to be meaningful.
**Trigger to promote:** voting is live (Block 4 shipped) and there is enough volume that a ranking is interesting.

### v2: Weekly objective chant
**The idea:** A community challenge to write a chant for a chosen player.
**Why pin, not build:** Overlaps the new-signing engine; Andrew was unsure it is needed.
**Trigger to promote:** new-signing prompts ship and show appetite for prompted creation.

### v2: Heavy video at scale
**The idea:** Rich video upload, storage, transcoding, and playback at volume.
**Why pin, not build:** Brings the serious music-licensing question and real infrastructure cost.
**Trigger to promote:** media engagement on the light formats proves demand, with the IP exposure understood first.

### v2: Auto lyric-video generator (the growth engine)
**The idea:** From any chant, a fan taps one button and the app generates a clean vertical (9:16) video: the lyrics animating in time with the tune, over the club's colors, with a Chants watermark, ready to share to X, TikTok, and Instagram in seconds. Karaoke-style, on brand with the app's "know every word" identity.
**Why this is the headline v2 feature:** Video is what wins on X and TikTok for football content, so this is the app's real distribution engine. Every shared video is a watermarked ad made by the user for free. It is defensible because it only works on top of the app's own verified lyric and tune archive, which is the moat, so it cannot be copied without first building the archive. Impact is higher than much of v1.1, but readiness is not: it only pays off once there are users to share it and an archive to build from, so it is sequenced as the first big v2 feature, after v1 is live and the v1.1 social layer is in.
**The hard constraint to design around from day one:** audio. Animating the lyrics is straightforward; playing the actual licensed master under the video is the music-licensing exposure the project has deliberately avoided. The safe version uses crowd audio, an a cappella, or a generic instrumental, never the licensed recording. Decide the audio approach before building.
**Trigger to promote:** v1 live with real users, v1.1 social layer shipped, and a decision made on the allowed audio sources.

### v2: Fan-submitted chant videos (approve-then-post only)
**The idea:** Let fans submit videos they made in other apps (CapCut and the like) to accompany a chant. More interaction and fun, but done safely.
**Why pin, not build, and why it follows the generator:** Two hard problems ride along with user video: moderation at scale and music licensing. The moderation model is non-negotiable: it must be approve-then-post (a video sits in a queue and a moderator clears it before it is ever public), never submit-then-check-the-flagged-ones, because a single piece of illegal or hateful video sitting live even briefly is a real legal and app-store-removal risk. Even approved videos need an audio policy (a fan singing over a copyrighted backing track is still exposure). Do NOT build an in-app video editor: CapCut exists and is free, fans already use it, and it is a product unto itself.
**Trigger to promote:** the fuller moderation console exists, a written video content and audio policy exists, and the community is active enough that a moderation queue is worth running. Sequenced after the lyric-video generator, not before.

### v2: Fixture-calendar and matchday surfacing
**The idea:** Tie the app to the fixture calendar, spike content on matchdays.
**Why pin, not build:** Chants spike on matchdays, but this is an enhancement, not core.
**Trigger to promote:** steady matchday usage worth amplifying.

### v2: Trending / virality tracking from X and YouTube
**The idea:** Pull in chant mentions from external platforms to surface what is going viral.
**Why pin, not build:** Network-dependent and integration-heavy.
**Trigger to promote:** share-out (v1.1) is live and there is outbound virality to mirror.

### v2: View counts, reshare tracking, richer engagement metrics
**Trigger to promote:** there is a reason to measure beyond votes, e.g. a leaderboard or a creator-facing surface.

---

### v2: Hear-the-tune link
**The idea:** An optional tuneLink field linking out to the tune on an external platform so fans can hear it. Link only, never host or stream audio in-app.
**Why pin, not build:** Needs the tune-name field (already present) and a UX pass on submission and detail.
**Trigger to promote:** Submission polish in v1.1, or users asking to hear the tune.

### v2: Community-validated context
**The idea:** Let the community confirm or refine a chant's context via the votes and suggestions mechanic.
**Why pin, not build:** Rides on Block 7 (comments and collaborative lyric suggestions). v1.1+.
**Trigger to promote:** Block 7 ships and context notes are actively read.

### v2: Song-type chant flag
**The idea:** A type marking a chant as an actual released copyrighted song, making the app show attribution plus a hear-it link plus an optional crowd clip and withhold hosted lyrics unless licensed. Recurring across clubs.
**Why pin, not build:** Needs the licensing posture to be codified per song type.
**Trigger to promote:** Seeding the first club anthems that are released songs.

### v2: Player aliases and nicknames
**The idea:** An aliases array on players so search resolves nicknames and full names (for example Kaka and Ricardo Izecson dos Santos Leite).
**Why pin, not build:** Pairs with the deferred full-text search index.
**Trigger to promote:** Full-text search ships, or a user fails to find a player by nickname.

### v2: Propose-from-player-page
**The idea:** Submitting a chant scoped to the player you are viewing, pre-filling that player.
**Why pin, not build:** Small UX on top of Block 3 submission. Relates to the v1.1 new-signing creation prompts.
**Trigger to promote:** Block 3 submission ships and users ask to scope their chant to a player page.

### v2: Stable, non-title-derived chant document IDs
**The idea:** Give each chant a stable ID that does not change when its title is edited, so renames stop creating new documents and orphaning the old ones.
**Why pin, not build:** Current title-slug IDs work and renames are cleanable by hand pre-launch; this only earns its cost once content volume or real engagement makes orphan cleanup risky.
**Trigger:** Before public launch, or the next time more than two chants need renaming at once.

### v2: Proper diacritic display for player names
**The idea:** Store an ASCII form of a player name for squad matching and render the correct characters in the UI, for example showing Odegaard with its proper diacritic.
**Why pin, not build:** The ASCII spelling matches the squad data and reads fine for now; correct diacritics are a polish detail, not a launch blocker.
**Trigger:** A player-display or profile polish pass.

### v2 / growth: Shareable and engagement ideas (backlog)
- Daily chant puzzle (guess the chant from progressively revealed lyrics)
- This day in chant history (daily throwback card)
- Chant of the Season community award and year-in-chants recap
- Lyrics card generator (branded shareable card for X or Instagram)
- Derby and rivalry angle on the weekly top-chant board
**Trigger to promote:** after launch, based on engagement data.

### v2: Order player sections by popularity on the club screen
**The idea:** On the club screen, sort the player sections by how loved their chants are (for example total or top chant score) so the most-supported players rise, instead of the current alphabetical order.
**Why pin, not build:** Alphabetical is predictable and keeps the club screen usable as a directory (a fan scans straight to a player). Popularity ordering makes players move between visits, hurts findability, needs an ambiguous aggregation rule, and does nothing while scores are near 0 pre-launch. The "surface the best" need is already served by score-ranking within each player's chants and by the planned Top tab.
**Trigger:** If, after real clubs are seeded and votes accumulate, users say the alphabetical squad list feels flat or hard to prioritize. If pursued, consider a stable axis like squad number or position rather than live vote counts.

## v3+ candidates (need scale or customer pull)
(Empty.)

## Business tier candidates (pricing, packaging, model)
(Empty.)

## Skipped (deliberately not building, with reason)

### Skipped: streaming licensed master recordings
**Reason:** Chants ride existing copyrighted melodies. TikTok and Instagram have licensing deals, a small app will not. Streaming masters is direct copyright exposure. The flexible-media approach (lyrics plus tune name as the low-risk core, optional light recordings) sidesteps it deliberately.

### Future: Real club crests on chant cards
**The idea:** Show the actual club crest next to the gold who-it-is-for line on chant cards. Adds instant visual recognition. Requires licensing or sourcing crest assets for every supported club. No placeholder icon (stock shields read as template). Wait until real assets are available.

---

## Promotion rule
An item earns a real spec when all four are true: 3+ users (or one strong own-use reason) asked; the user problem fits one sentence; the smallest version is describable; building it does not break the existing surface. Items 6+ months old with no pull get deleted.
