# Chants: Wishlist

## Promoted into v1

### One-level replies and rival banter
**Status:** Implemented in source and automated checks. One reply level reuses comment likes, reports, moderation, blocking, deletion, and rate limits. Unlimited nesting and reply notifications remain v1.1 candidates.

### Saved Matchday Songbook
**Status:** Implemented and locally verified on stacked draft PR 8. Clean-runner CI, native client compilation, review, and the airplane-mode device walk remain before release.
**The idea:** A fan can save one chant or a club's current visible songbook before leaving for the ground, then reopen the lyrics with no signal. The v1 contract is an explicit device-local snapshot with refresh and remove actions. It does not rely on an earlier Firestore read happening to remain in cache.
**Why v1:** Looking up the words at the match is the product's sharpest real-world use case, and stadium connectivity is unreliable. This provides a concrete return habit without waiting for social scale or finished seeding.
**V1 boundary:** Individual and club-level saves, offline relaunch, clear saved/last-refreshed state, refresh, remove, and graceful handling when the live chant is later hidden or removed. Cross-device sync, automatic background downloads, push reminders, and storage of audio or video remain out of scope.

### Songbook and Chant Lab
**The idea:** Keep the trusted Terrace Proven archive as the Songbook and give original or not-yet-verified submissions a separate Chant Lab with Top, New, and Rising discovery. Every submission says Already sung or I made this. A link is optional to post but valid evidence plus operator review is required before a user submission becomes Terrace Proven.
**Why v1:** This is the product identity, not a later social extra. Fans can learn what is genuinely sung while also competing to create what gets sung next. Votes rank work but never manufacture verification.
**V1 boundary:** Backward-compatible provenance, optional allowlisted YouTube or X evidence, honest unverified states, evidence-gated promotion, Songbook and Lab club/player navigation, Top and New sorting, a Rising signal, a player-scoped Start a chant action, and the existing report/remove path.

### Soft duplicate nudge
**The idea:** During submission, show similar chants and ask "Is it one of these?" before creating another record. Let the fan continue when it is genuinely new.
**Why v1:** Chant Lab invites more submissions, so the archive needs a gentle protection against splitting one chant's votes and conversation across duplicates. The matching engine already exists.

### Basic share-out
**The idea:** Share a chant through the phone's normal share sheet from chant detail, using a stable public URL when one exists and an honest text-only fallback otherwise.
**Why v1:** The app is the workshop and existing fan networks are the stage. V1 needs a safe way for a promising chant to leave the app without pretending to publish directly to X, TikTok, or YouTube.

### Stable chant identity
**Status:** Implemented and verified in the repository. The read-only live preflight remains an operator-authorized rollout gate before the next production seed write.
**The idea:** Replace title-derived seed document IDs with stable IDs before the remaining clubs are written live. Freeze the existing Arsenal IDs and confirm live references stay attached so title edits no longer create a new chant and orphan votes, comments, reports, saved snapshots, evidence, or public links.
**Why v1:** This is already a reproduced failure and the Chant Lab plus sharing direction increases the cost of every future rename. It is cheaper and safer before public engagement and the remaining seed land.
**V1 boundary:** A dedicated Lane 2 migration spec, representative dependent records, old and new reader compatibility where required, invariant counts before and after, recovery steps, and a rename regression test. Andrew's sourcing work can continue in parallel; only live seed writes wait for this gate.

## v1.1 (committed, fast follow after v1 ships and gets real use)

### v1.1: Home screen rotating quote
**The idea:** A single shared quote everyone sees on the home screen, rotating roughly every 3 days, chosen date-deterministically from a curated quotes collection (no per-user randomness, no server cron). Andrew appends entries over time, each copyright-cleared before adding. Real attributed football quotes preferred over copyrighted song lyrics. Goes on the home screen, NOT the OS launch or splash screen (platform guidance keeps that minimal, and it flashes too fast to read).
**Why v1.1:** Home-screen polish once the core content is proven.

### v1.1: Collaborative variants and corrections
**The idea:** Keep one entry per chant while the crowd proposes alternate versions and corrections, votes on them, and an operator confirms the primary version. Operator merge remains the backstop for duplicates that pass the v1 soft nudge. Avoid hard automatic duplicate blocking because it can reject genuinely new chants.
**Why v1.1:** The v1 nudge protects creation without adding another moderated contribution and voting model. Collaborative refinement earns its own focused safety and lifecycle block.

### v1.1: Reply notifications and collaborative lyric suggestions
**The idea:** Notify a user when someone answers their comment, plus a lyric-suggestion mechanic where the most-upvoted tweaks surface at the top, turning discussion into a refinement engine.
**Why v1.1:** One-level discussion is already in v1. Notifications introduce delivery preferences, privacy, unread state, and deep-link behavior, while lyric suggestions introduce another moderated voting surface.

### v1.1: Follow accounts and personalized feeds
**The idea:** Follow other users, plus a For You feed and a Following feed.
**Why v1.1:** Needs a base of users and content to be worth anything. Build on the seeded-plus-submitted archive.

### v1.1: Creator profiles and contribution reputation
**The idea:** Give a fan a public contribution page showing original ideas, Rising chants, and chants that later became Terrace Proven. Reputation comes from visible contribution history, not an opaque universal score.
**Why v1.1:** Chant Lab creates creator identity naturally, but public profiles expand blocking, privacy, deletion, attribution, and moderation semantics. Launch with the content loop first, then add identity once real contributors exist.

### v1.1: Subtle surface grain
**The idea:** A faint print grain on card and scaffold surfaces, part of the locked "matchnight, warmed with playful" design direction, to add tactile programme-paper texture.
**Why deferred:** The grain asset was generated during the redesign but never wired to any surface, so it was removed rather than shipped as a dead asset. The design reads well without it.
**Trigger to promote:** If, on device review, the warm surfaces feel flat or too clean and want more texture. Implement as a cheap static tiled low-opacity PNG overlay (3 to 5%) on card and scaffold surfaces, not a runtime ShaderMask on scrolling lists, and confirm scroll stays smooth.

### v1.1: Scheduled new-signing creation challenges
**The idea:** Turn the v1 player-scoped Start a chant action into featured, time-bound challenges for a new signing, with a winner or highlighted Rising entries.
**Why v1.1:** V1 provides the creation path. Editorial scheduling, challenge state, expiry, winner semantics, and notifications are a separate retention system.

### v1.1: Rich platform share cards
**The idea:** Extend the v1 system share action with branded cards, platform-aware previews, attribution, and campaign measurement.
**Why v1.1:** The safe outbound path belongs in v1. Custom assets, attribution policy, analytics, and platform-specific optimization should follow real sharing behavior.

### v1.1: Fuller moderation console
**The idea:** Operator-side queue, flag thresholds, bulk actions, on top of Block 3's basic remove-and-ban.
**Why v1.1:** v1 ships the basics that keep it safe; the console is an efficiency layer once volume justifies it.

### v1.1: Multiple renditions and richer linked media
**The idea:** Expand the single v1 evidence link into a moderated set of crowd clips, creator renditions, or lyric videos without hosting the files.
**Why v1.1:** One evidence link is enough to prove the product and verification flow. A gallery needs ordering, duplicate handling, per-link reporting, attribution, and dead-link maintenance.
**Guardrails:** Keep the allowlist, open externally, and never download or separate audio or video.

### v1.1: Chant quiz and greatest-chant bracket
**The idea:** Two shareable, fun surfaces built on the verified archive. A chant quiz (guess the club or player from the lyrics or tune, share your score) and a greatest-chant bracket (real chants head to head, crowd votes through rounds, crown a champion). Both make the app fun and shareable and reinforce the real-chants-board identity.
**Why v1.1:** Part of the engagement and feels-alive layer that gates the public launch. The bracket reuses the existing voting mechanic, so it is the cheaper build and the v1.1 anchor; the quiz is the fast follow right behind it.
**Sequencing within v1.1:** Both need the seeded archive to be good, so they come after seeding. Real chants only, club-neutral, same content policy.
**Trigger:** Build alongside or right after the comments and lyric-suggestions block, bracket first.

### v1.1: Hot ranking and score floors
**The idea:** Extend v1 Chant Lab Top and New order with time-decayed Hot ranking and a tested score floor that keeps heavily rejected work out of discovery.
**Why v1.1:** V1 can use the existing score and creation time. Time decay and thresholds need real submission and voting distributions, not guesses.
**Trigger:** A club's Chant Lab regularly has enough submissions that lifetime score makes old entries immovable or low-value entries bury useful work.

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

### v1.1: Marketing website (Astro)
**The idea:** A standalone Astro landing site (separate repo) in the app's own design system (warm charcoal and gold, Anton, Space Mono, Fraunces, loud frame and calm words). Sections: hero, order of play, a featured interactive chant, a songbook of cards, the terrace-notes manifesto, honest club status, and a CTA with coming-soon store pills. It is the public front door and hosts the privacy policy, terms, and support pages the app stores require.
**Why v1.1:** Built and living in its own repo. It is a launch dependency (the stores need its legal pages live and a support URL), not an app code change, so it is tracked here for planning but shipped and hosted separately.
**Trigger to promote:** Before store submission the site must be hosted on chantsfc.com with live privacy, terms, and support pages. At launch, its store pills flip from coming-soon to the real App Store and Play URLs. Content rule holds: only original or fan-written chant lyrics on the site, no lyrics lifted from licensed songs, no crests or player images.

### v1.1: Integration and end-to-end tests
**The idea:** A Flutter `integration_test` suite, run on Firebase Test Lab across a device matrix, covering full user flows on real devices rather than widgets in isolation.
**Why v1.1:** Confirms the app works end to end on real hardware and OS versions, a check the unit and widget suite cannot give on its own.
**Trigger:** v1 shipped and stable.

### v1.1: Golden and visual regression tests
**The idea:** Golden image and visual regression tests for the key screens, catching unintended visual drift automatically.
**Why v1.1:** Protects the locked "matchnight, warmed with playful" (Ink and Gold) visual identity once it stops changing.
**Trigger:** The Ink and Gold UI is frozen. Do not add earlier, or intentional design changes churn the snapshots.

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
**The idea:** A recurring, club-neutral challenge to write a chant for a chosen player or moment, beyond the v1.1 new-signing challenges.
**Why pin, not build:** A recurring editorial calendar, judging model, archive, and reward loop should follow evidence that one-off new-signing challenges create worthwhile participation.
**Trigger to promote:** New-signing challenges ship and show sustained appetite for prompted creation.

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

### v2: Deeper discussion trees
**The idea:** Allow replies to replies beyond the v1 one-level thread when a real conversation needs it.
**Why pin, not build:** Arbitrary depth expands pagination, rendering, deletion, blocking, moderation, notification, and deep-link behavior. One level captures most direct back-and-forth without a recursive product.
**Trigger to promote:** Closed-beta evidence shows fans repeatedly need to answer a reply, and reply notifications plus current moderation are stable enough to carry a deeper graph.

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
**Reason:** Chants ride existing copyrighted melodies. Streaming masters creates direct copyright exposure. The v1 approach keeps lyrics and tune-name text as the core and opens allowlisted evidence on the external platform instead of hosting, downloading, or streaming it.

### Future: Real club crests on chant cards
**The idea:** Show the actual club crest next to the gold who-it-is-for line on chant cards. Adds instant visual recognition. Requires licensing or sourcing crest assets for every supported club. No placeholder icon (stock shields read as template). Wait until real assets are available.

---

## Future projects (separate apps, not Chants features)

_Sequence, one at a time after Chants ships: build idea 1 first (achievable solo, earns revenue, builds the audience and club relationships), then idea 3 (the highest-ceiling endgame, once there is a track record and capital), with idea 2 slotted in only after the legal path is cleared. One app at a time. Chants ships first, fully, before any of these start._

### Future project: Away Days (football travel booking)
**The idea:** The travel product for supporters following their club, home and abroad. Match found, the app bundles transport, hotel, the fan-friendly pub, ticket-collection logistics, and local safety and colours knowledge into a few taps. Revenue from affiliate and booking cuts on transport and hotels, and a fee on packages. It is a commerce play, not a content app.
**Why it fits the founder goal:** Away-day spend is real and high, so it makes money, and it keeps the founder physically at grounds while building the exact travelling-superfan audience and supporters-trust relationships that open club doors. Existing tools are guides, not booking products, so the space is open.
**Buildable from America:** Yes, in phases. Launch the Premier League first with knowledge gathered remotely (fan forums, supporters trusts, groundhopping communities, club guides, maps and street view) and completed by community contribution, since away-day fans will correct and fill it. Revenue then funds ground-truth trips, and existing UK contacts act as on-the-ground local editors from day one.
**Extra hook:** a groundhopping log built in, check in at every ground and collect them like stamps, which is a real subculture and a free viral loop.
**Status:** Build first after Chants is live. One app at a time.

### Future project: Football prediction and challenge game (free-to-play, no money held)
**The idea:** A social prediction game. Predict scorelines, first scorer, and weekend results, run private leagues with friends, climb a global table, streaks and badges. A friend-challenge feature (challenge a mate on a match, they accept or decline) and a "place a number on it" tracker that records the prediction and who was right. Makes every match already being watched more exciting. Revenue at scale through light ads, a premium tier, and sponsored prize rounds.
**The hard legal line (non-negotiable, confirm with a gaming-law attorney per market before building):** The app never touches a wager. It does not take, hold, move, or take a cut of any stake. Any bet between friends is agreed and settled by them entirely offline; the app only tracks the prediction and the outcome, as a scorekeeping and bragging-rights tool. The danger is feature drift toward in-app settlement, which would turn a legal product into a regulated gambling one. Do not cross that line, and get legal sign-off first, since the line is legal, not technical.
**Also note:** it needs a reliable football results feed, so factor that licensing and cost in early. Results and tables must be recomputed from real source data, never guessed or blindly incremented.
**Status:** Build only after the legal path is confirmed. Pairs with Away Days as one drop after Chants.

### Future project: Matchday experience marketplace (the endgame)
**The idea:** The trusted marketplace for getting into the game and everything around it: verified ticket resale and hospitality, bundled with the matchday experience, aimed at the travelling and international supporter who has money and no local knowledge and will pay a premium for trust and ease.
**Why it is the endgame:** Highest ceiling and the most direct route to real club relationships, because it means working directly with clubs' ticketing and hospitality (commercial) side. But it is the hardest and most regulated (trust, fraud, and rights holders from day one), so it is a company, not a side project.
**Status:** Attack last, once there is a track record and ideally capital or a partner, funded and de-risked by the earlier builds. Do not start solo and cold.

---

## Promotion rule
An item earns a real spec when all four are true: 3+ users (or one strong own-use reason) asked; the user problem fits one sentence; the smallest version is describable; building it does not break the existing surface. Items 6+ months old with no pull get deleted.
