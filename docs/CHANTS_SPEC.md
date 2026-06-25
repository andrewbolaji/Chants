# Chants: Product Specification

**Build pace:** Build at the pace each feature deserves. Ship when ready. No corner-cutting for dates.
**Build agent:** Claude Code, with Andrew Bolaji approving outputs and answering preference questions. Strategic review held by the chat AI across Blocks.
**Status:** Day 1 setup complete. Planning Block 1. No code until the Block 1 plan is approved.

---

## Primary user (v1) — pin this, check every decision against it

A football supporter, casual to die-hard, who follows a Premier League club closely and cares about matchday culture. Comfortable on Twitter/X, TikTok, and Instagram. Wants to learn the songs to join in at the ground or the pub, enjoys the humor and creativity, and would happily add a chant or vote if it is fun and low friction. Not a music professional, not a developer. Wants the app fast, funny, and obviously useful, not corporate or preachy. Every UX decision gets checked against this person: would they get it instantly, would they feel it was made by someone who actually goes to games.

---

## 1. Product summary

Chants is the home for finding and learning real football chants: a verified archive with user creativity (parody chants, new-signing prompts) as a layer on top. Fans can add chants (new ones and the existing classics), so the archive grows through contribution. The app is where a chant is found, refined, voted on, and learned.

---

## 2. Core build principles

**Above everything: ruthless simplicity for the user.** A messy app is one nobody opens twice, and no amount of good content survives a confusing layout. Every screen, label, and placement defaults to the simplest, most obvious option. When in doubt: fewer choices, clearer names, and "where would a fan expect this to be" always wins. Every principle below serves this one.

1. Boring beats clever in the architecture. The novelty is the product, not the stack.
2. Do exactly what is asked. No inventing features. If something seems missing, ask.
3. Validate as you build. Each feature works end to end before the next starts.
4. Names map to function. A new user knows what every menu item does without help text.
5. Mobile first. A phone app for fans on the move and at the ground.
6. No em dashes anywhere in copy or generated text.
7. Voice: reads like a fan wrote it. Witty, knowledgeable, never corporate, never preachy.
8. Respect the user's time. Find, learn, or add a chant in seconds.
9. No mock data in production. Seed with real, verified, policy-compliant chants only.
10. Audit-log everything that matters, moderation actions especially.
11. Content safety is a build principle, not a feature. Every user-content surface ships with reporting and a moderation path.
12. Media is optional and flexible, never required to show a face. A chant can be lyrics only, lyrics plus a tune recording, a lyric video, a screen recording, or a crowd clip.
13. Differentiation flows through data, never through forks. Sport, league, and team are data. No hardcoded league checks. Enabling a new league or sport is a data change, not a code change.
14. Simplest sensible placement. Every chant has a name and lives under its natural parent: a player's chant under that player, a club anthem under the club, a manager's chant under the manager. Users drill down the obvious way (club, then its players and club-level chants, then the chant). Show only what makes sense at each level, never dump everything at once. If a fan cannot find or place something in one obvious tap, the layout is wrong, not the fan.

---

## 3. Tech stack (locked, no "or")

**Flutter plus Firebase.** Decided deliberately on Day 1. Reasoning: genuinely mobile first for a phone-in-hand product, and Firebase covers auth, database, storage, functions, and push without standing up infrastructure.

- **Client:** Flutter (mobile first).
- **Auth:** Firebase Auth (email plus password for v1; sign up, sign in, password reset).
- **Database:** Cloud Firestore.
- **Media storage:** Firebase Storage, with a CDN in front for playback. Transcoding considered when heavy video is promoted (v2).
- **Server logic:** Cloud Functions (vote counter updates, moderation actions, audit logging, future email delivery for the suggestion box).
- **Push:** Firebase Cloud Messaging (later, when matchday and social features warrant it).

**Known architectural watch-item (not a v1 blocker):** Firestore has no native full-text search and is weak at live ranked queries. We handle ranking from Block 1 with denormalized counter fields (see schema). Full-text search across lyrics and player names will need an external index (Algolia or Typesense via the Firebase extension) when browse-and-filter stops being enough. This is additive, not a rewrite: the index reads existing chant documents and runs alongside them. It is pinned in WISHLIST with a trigger.

---

## 4. Branding

- **Name:** Chants. (Decision 1, locked. Tifo was rejected on diligence: Tifo Football is an established New York Times / The Athletic football brand actively expanding into other sports, so it carried brand-confusion, trademark, and discoverability risk in our exact lane.)
- **Tagline options (Andrew's call):** "Every chant. Learn it, make it, sing it." / "The home of football chants." / "Know the words."
- **Palette, typography, logo:** Andrew to set. Keep it loud and terrace-flavored, not corporate.

---

## 5. Voice and copy

GOOD (fan voice, witty, plain, no em dashes):
- Empty state on a club with no chants yet: "No chants here yet. Be the one who starts it."
- Submit confirmation: "Nice one. It's live. Now go get the lads singing it."
- Report flow: "Something off about this one? Tell us why and we'll take a look."
- Vote nudge: "Heard it on the terraces? Give it an upvote."
- Suggestion box confirmation: "Got it. We read every one."

BAD (corporate, preachy, jargon, never ship):
- "Your submission has been received and is pending moderation review."
- "We are committed to fostering a safe and inclusive community experience."
- "An error occurred. Please try again later."
- "Engagement metrics indicate this content is trending."
- "Thank you for your valuable feedback."

---

## 6. Feature scope for v1 (Blocks 1 to 6)

A credible, differentiated, launchable product. Not a static archive. It does its actual job (find chants AND add them, safely) from day one on a primed archive.

1. **Auth.** Sign up, sign in, password reset.
2. **Sport / Competition / Team / Chant data model.** Football and the Premier League enabled, schema ready for any league or sport. All 20 PL clubs and their squads.
3. **Chant records,** each with: title; subject tag (player, coach/manager, club, or rival); lyrics; the tune it is set to (text); optional flexible media (audio, tune recording, lyric video, screen recording, crowd clip, never required to be self-video); a cover image / thumbnail; status (canonical or community); a real-versus-parody tag; context / notes.
4. **Operator seed.** Roughly five iconic, must-be-there chants per PL club, all canonical and policy-checked. The credibility primer.
5. **User submission.** Add a new chant, or add an existing one not yet in the app (enters as community, can earn canonical). This is the app's core purpose, so it is in v1.
6. **Upvote and downvote.** The quality signal that ranks chants and surfaces validation.
7. **Browse and search** by club, player, subject, status, newest, most popular, plus a simple cross-club discovery shuffle labeled by club. Navigation drills down the obvious way. Nothing buried, nothing dumped all at once.
8. **Learn-focused chant detail page.** Lyrics front and center, tune named, media if present.
9. **Content safety.** Content policy, report button on every chant, fast remove-and-ban, rate-limits, fail-safe defaults. Moderation ships with submission because they are inseparable.
10. **Suggestion box.** In-app feedback channel.

---

## 7. Scope for v1.1 (post-MVP, fast follow, do not let v1 linger)

Cross-reference WISHLIST.

- Comments and inner replies, including collaborative lyric suggestions (most-upvoted tweaks surface at the top).
- Follow accounts.
- Personalized feeds: a For You feed and a Following feed.
- New-signing creation prompts tied to the squad.
- Share out to X, YouTube, TikTok as a first-class action.
- The fuller moderation console (queue, thresholds, bulk actions).

---

## 8. Data model (Firestore)

Hierarchy is **Sport contains Competition contains Team contains Chant,** modeled as data from Block 1. Differentiation flows through data, never through forks or hardcoded league checks.

**Collections (top-level, flat, with denormalized reference fields):**

- `sports` — { id, name (e.g. "Football"), enabled }
- `competitions` — { id, sportId, name (e.g. "Premier League"), enabled }
- `teams` — { id, sportId, competitionId, name, crestImageUrl }
- `players` — { id, teamId, name, position }
- `chants` — the heart of the app. Stored top-level (not as deep subcollections) so both drill-down and the cross-club shuffle are cheap.
  - Identity / placement: `id`, `title`, `sportId`, `competitionId`, `teamId`, `playerId` (nullable; null means club-level or manager-level), `subjectTag` (player | coach | club | rival)
  - Content: `lyrics`, `tuneName` (text), `contextNotes`, `coverImageUrl`, `mediaUrl` (nullable), `mediaType` (none | audio | tuneRecording | lyricVideo | screenRecording | crowdClip)
  - Classification: `status` (canonical | community), `realOrParody` (real | parody)
  - **Denormalized counters (defined from Block 1, default 0, written by Cloud Functions):** `upvotes`, `downvotes`, `score`, `commentCount`
  - Provenance / safety: `createdBy`, `createdAt`, `updatedAt`, `flagCount`, `hidden` (bool, fail-safe), `removed` (bool)
- `votes` — { id, chantId, userId, value (1 or -1), createdAt }. One per user per chant, enforced.
- `reports` — { id, chantId, reportedBy, reason, createdAt, status }
- `auditLog` — { id, actorId, action, targetType, targetId, detail, createdAt }. Moderation actions especially.
- `feedback` — the suggestion box. { id, userId, category (suggestion | bug | question | other), message (<= 1000 chars), followUpOk, resolved, createdAt }

**Why this topology (DECISIONS entry):** a single top-level `chants` collection with denormalized `teamId` / `playerId` gives drill-down (query chants where `teamId` equals X) and the cross-club shuffle (query across all chants, or a collectionGroup) without expensive joins, and it makes the future search index trivial because everything searchable already lives on one document.

**Access / security model (enforced server-side in Firestore rules plus Functions, never client-only):**
- Reads: public for non-hidden, non-removed chants.
- Writes to `chants`: authenticated users may create (enters as `community`). Only the author may edit their own draft fields; counters and `status` are never client-writable.
- `votes`: one per user per chant, value constrained to 1 or -1. Counter updates happen in a Cloud Function, not the client.
- `reports`: any authenticated user may insert their own. No edit or delete.
- Moderation (hide, remove, ban, promote to canonical): operator-only, every action audit-logged.
- Rate-limits and fail-safe defaults: new or unproven accounts are rate-limited; content past a flag threshold auto-hides pending review.

---

## 9. UI structure

Mobile first. Drill-down navigation, simplest sensible placement.

- **Public / browse:** Home (cross-club discovery shuffle, newest, most popular) → Competition (Premier League) → Club (its players and its club-level chants) → Player (that player's chants) → Chant detail (lyrics front and center, tune named, media if present, vote, report).
- **Search:** by club, player, subject, status, newest, most popular.
- **Authed:** Submit a chant, vote, report, suggestion box, profile.
- **Operator:** remove / ban / promote (basic in v1, fuller console in v1.1).

Show only what makes sense at each level. Never dump everything at once. One obvious tap to find or place anything.

---

## 10. Pricing

No billing in v1. Business-tier ideas are parked in WISHLIST.

---

## 11. Out of scope for v1 (protect the ship)

- Comments, replies, follow, personalized feeds (v1.1).
- Share-out integrations and new-signing creation prompts (v1.1).
- The fuller moderation console (v1.1; v1 ships basic remove-and-ban).
- Other leagues and other sports (v2; architecture already supports it, gated on PL traction).
- Heavy video at scale and anything that streams licensed masters (v2, with the music-licensing question).
- Fixture-calendar and matchday surfacing, trending / virality tracking, view counts and richer metrics (v2).
- Full-text search index (Algolia / Typesense). Browse-and-filter covers v1; promote on trigger.

---

## 12. Build order

v1.0 (code-complete, hardened):
- **Block 1:** Foundation and the agnostic data model.
- **Block 2:** The archive and the seed.
- **Block 3:** Submission and basic moderation.
- **Block 4:** Voting.
- **Block 5:** Suggestion box.
- **Block 6:** Visual design and beautification.
- **Block 7:** Polish and hardening. Account deletion, App Check, Crashlytics, billing kill-switch, copy pass, audits.

v1.1 (social layer, the release target):
- v1.0 is the hardened foundation; v1.1 adds the social layer.
- **Block 8:** Comments, replies, and collaborative lyric suggestions.
- **Block 9:** Follow and feeds (For You, Following).
- **Block 10:** Creation prompts and share-out.
- **Block 11:** Moderation console.

---

## 13. Definition of done (per feature)

Works end to end on the real seeded data; mobile-responsive; empty, loading, and error states present; audit log records the action (moderation especially); access control verified with a second account; no em dashes; no console errors; adversarial review passed with disposition table (Security frame mandatory on any user-content surface); content-policy and reporting path present on any user-content surface; handbook section written; passes the simplicity check (a fan finds or places it in one obvious tap, simplest sensible layout).

---

## 14. Lessons captured live

### From Block 1

**All-N/A security pass is a red flag, not a green light.** The implementer's own security review returned all N/A and missed a High privilege escalation in the profiles create rule (role field not pinned, allowing self-promotion to operator via a crafted SDK write). The independent adversarial review caught it. A clean security sheet is a signal to push harder, not to close.

**Recap-commit self-reference always mismatches.** Recording a hash inside the file that the commit creates means the hash is always one behind. Resolution: record the final reviewed code commit (`accbe3d`), and treat the recap-write as a noted docs-only commit on top (`04718af`). Document both explicitly so it reads as intent, not drift.

**Field-pinning on CREATE is a bug class.** Every server-managed or privileged field must be pinned on create, not just blocked on update. profiles (role), reports (status), and feedback (resolved) all missed this initially, while chants and votes had it right. The pattern: if a field should never be client-set on creation, the create rule pins it. Default to pinning.

### From Block 2

**Never generate seed content from AI knowledge.** When asked to strip a field from a seed file, the implementer rewrote arsenal.json from memory instead of editing the existing entries in place. The result was a stale, incorrect squad (players who left the club years ago) seeded as real data. The fix: all seed content (squads, players, chants, lyrics) is supplied by Andrew. The implementer may only transform supplied data (remove a field, rename a key). Never rewrite content from memory. This is now the highest-integrity standing rule.

**An AI implementer will confidently regenerate domain content from its own memory, and that content is unverified by definition.** The stale squad was caught by independent review; the AI-drafted lyrics were flagged by the implementer itself after the rule was established. Both were presented as real data with no caveat until challenged. Seed credibility depends on human-verified content, supplied by Andrew, never authored by an AI. Every seed file entry is Andrew's content, and any AI-drafted content in an existing file must be visibly flagged as unverified.

### From beautification audit pass

**Point a brief at the work explicitly, even when it is already in the repo.** In Block 6, the design brief was in the project root but the kickoff did not cite it as the process spec. The right outcome was reached by parallel construction (the kickoff restated the same principles), but the brief was not consulted as the canonical reference. Mitigation: a standing rule now requires every design block to start by reading DESIGN_DIRECTION.md.
