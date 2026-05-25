# Chants: Wishlist

## v1.1 (committed, fast follow after v1 ships and gets real use)

### v1.1: Comments, replies, and collaborative lyric suggestions
**The idea:** Threaded discussion on a chant, plus a lyric-suggestion mechanic where the most-upvoted tweaks surface at the top, turning comments into a refinement engine.
**Why v1.1:** The social layer is what makes the app sticky, but v1 has to prove find-and-add first. Reporting and moderation apply.

### v1.1: Follow accounts and personalized feeds
**The idea:** Follow other users, plus a For You feed and a Following feed.
**Why v1.1:** Needs a base of users and content to be worth anything. Build on the seeded-plus-submitted archive.

### v1.1: New-signing creation prompts
**The idea:** A focused creation flow tied to the squad, "make a chant for [new signing]," self-refreshing every transfer window.
**Why v1.1:** Sits on top of v1 submission. A centerpiece for retention once the base exists.

### v1.1: Share out to X, YouTube, TikTok
**The idea:** First-class sharing so a chant made here goes viral on the platforms fans already use.
**Why v1.1:** The app is the workshop, those are the stage. Add once there is content worth sharing.

### v1.1: Fuller moderation console
**The idea:** Operator-side queue, flag thresholds, bulk actions, on top of Block 3's basic remove-and-ban.
**Why v1.1:** v1 ships the basics that keep it safe; the console is an efficiency layer once volume justifies it.

---

## v2 candidates (pin, do not build, need real usage data)

### v2: Full-text search via external index (Algolia or Typesense)
**The idea:** Free-text search across lyrics, player names, and tune names, using the Firebase extension that mirrors the chants collection into a search index.
**Why pin, not build:** Browse-and-filter covers v1. The add is purely additive (it reads existing chant docs and runs alongside, no schema or screen rewrite), so there is zero penalty for waiting.
**Trigger to promote:** the first time a real user asks to search by a lyric fragment, OR when any club's chant count grows past what scan-the-list browsing handles comfortably.

### v2: Other leagues and other sports
**The idea:** La Liga, then beyond, then other sports. Architecture already supports it.
**Why pin, not build:** Launching broad-but-shallow is how you lose to a focused competitor. Depth in PL first.
**Trigger to promote:** proven PL traction, or a concrete market reason. Each new area is data entry plus a content-policy pass.

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

## v3+ candidates (need scale or customer pull)
(Empty.)

## Business tier candidates (pricing, packaging, model)
(Empty. Passion project first, business bet second.)

## Skipped (deliberately not building, with reason)

### Skipped: streaming licensed master recordings
**Reason:** Chants ride existing copyrighted melodies. TikTok and Instagram have licensing deals, a small app will not. Streaming masters is direct copyright exposure. The flexible-media approach (lyrics plus tune name as the low-risk core, optional light recordings) sidesteps it deliberately.

---

## Promotion rule
An item earns a real spec when all four are true: 3+ users (or one strong own-use reason) asked; the user problem fits one sentence; the smallest version is describable; building it does not break the existing surface. Items 6+ months old with no pull get deleted.
