# Chants: Product Specification

**Build pace:** Build at the pace each feature deserves. Ship when ready. No corner-cutting for dates.
**Status:** Living product contract, reconciled August 2026. Current implementation and release state live in `docs/ROADMAP.md`; the one approved implementation boundary lives in `docs/CHANGE_SPEC.md`.

---

## Primary user (v1), pin this and check every decision against it

A football supporter, casual to die-hard, who follows a Premier League club closely and cares about matchday culture. Comfortable on Twitter/X, TikTok, and Instagram. Wants to learn the songs to join in at the ground or the pub, enjoys the humor and creativity, and would happily add a chant or vote if it is fun and low friction. Not a music professional, not a developer. Wants the app fast, funny, and obviously useful, not corporate or preachy. Every UX decision gets checked against this person: would they get it instantly, would they feel it was made by someone who actually goes to games.

---

## 1. Product summary

Chants is the songbook of the terraces and the workshop for what gets sung next. Fans learn trusted chants in the Songbook, publish funny or sincere ideas in Chant Lab, back the best new work, and help a chant move from an idea to Rising to Terrace Proven. The product keeps archive truth and creative competition visibly distinct without treating either as secondary.

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
12. Media is optional and never required to show a face. V1 may link out to allowlisted external evidence, but does not upload, host, download, extract, transcode, autoplay, or provide background playback for audio or video.
13. Differentiation flows through data, never through forks. Sport, league, and team are data. No hardcoded league checks. Enabling a new league or sport is a data change, not a code change.
14. Simplest sensible placement. Every chant has a name and lives under its natural parent: a player's chant under that player, a club anthem under the club, a manager's chant under the manager. Users drill down the obvious way (club, then its players and club-level chants, then the chant). Show only what makes sense at each level, never dump everything at once. If a fan cannot find or place something in one obvious tap, the layout is wrong, not the fan.

---

## 3. Tech stack (locked, no "or")

**Flutter plus Firebase.** Decided deliberately on Day 1. Reasoning: genuinely mobile first for a phone-in-hand product, and Firebase covers auth, database, storage, functions, and push without standing up infrastructure.

- **Client:** Flutter (mobile first).
- **Auth:** Firebase Auth (email plus password for v1; sign up, sign in, password reset).
- **Database:** Cloud Firestore.
- **Media:** No upload or storage dependency in v1. Allowlisted evidence opens on the external platform. A future hosted-media block may evaluate Firebase Storage, CDN, and transcoding only after its legal, moderation, privacy, cost, and operating contract is approved.
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

## 6. Feature scope for v1

A credible, differentiated, launchable product. It is useful before community scale because the Songbook is seeded, and worth contributing to because Chant Lab gives new work a visible route upward.

1. **Auth and account safety.** Sign up, sign in, password reset, policy acceptance, age gate, account deletion, user blocking, and operator ban and unban.
2. **Sport / Competition / Team / Chant data model.** Football and the Premier League enabled, with an architecture ready for other leagues or sports through data rather than product forks.
3. **Operator seed.** Roughly five iconic, must-be-there chants per Premier League club, externally sourced, human verified, and policy checked. This is the cold-start Songbook.
4. **Songbook.** Terrace Proven chants remain the trusted, learn-focused archive. Existing `canonical` records map to this surface unless a later approved migration changes the internal contract.
5. **Chant Lab.** Original ideas and not-yet-verified Already sung claims have a clear community surface with Top and New order. Rising highlights momentum but never implies verification.
6. **Origin-aware submission.** Every fan chooses Already sung or I made this. An evidence link is optional at posting. A user submission requires valid retained evidence and operator review before Terrace Proven promotion. A soft duplicate nudge appears before create.
7. **Creation from need.** Club and player journeys expose a clear Start a chant action, especially when a player has no chant yet.
8. **Upvote and downvote.** Score ranks community work and helps identify Rising entries. Votes never prove that a chant has been sung.
9. **Browse and discovery.** Browse by club and player, distinguish Songbook from Chant Lab, sort Lab by Top or New, and retain a labeled cross-club discovery surface.
10. **Learn-focused chant detail.** Lyrics stay central, tune and provenance are explicit, and a valid evidence link can open externally as Watch it sung.
11. **Comments and one reply level.** Fans can joke, debate, like, report, block, and answer a top-level comment once. Deeper nesting and notifications are deferred.
12. **Saved Matchday Songbook.** Save one chant or a club's visible Songbook as a device-local offline snapshot with refresh, removal, stale-state disclosure, and UID isolation.
13. **Basic share-out.** Use the platform share sheet with a stable public chant URL when available and an honest text-only fallback otherwise.
14. **Content safety.** Policy, reporting, blocking, rate limits, fail-safe hiding, removal, ban, unban, and audit logging ship with every relevant user-content surface.
15. **Suggestion box.** In-app feedback channel.

---

## 7. Scope for v1.1 (post-launch fast follow)

Cross-reference `docs/WISHLIST.md` for triggers and boundaries.

- Reply notifications and mentions, while keeping the accepted one-level thread unless evidence supports more depth.
- Collaborative lyric suggestions and community-voted variants.
- Follow accounts and personalized For You and Following feeds after user and content volume exists.
- Scheduled new-signing challenges built on the v1 player-scoped submission path.
- Rich branded share cards and platform-aware previews built on the v1 system share action.
- Multiple linked renditions per chant, still opened externally and individually reportable.
- A fuller moderation queue, thresholds, and bulk actions once volume justifies operator tooling.

---

## 8. Data model (Firestore)

Hierarchy is **Sport contains Competition contains Team contains Chant,** modeled as data from Block 1. Differentiation flows through data, never through forks or hardcoded league checks.

**Collections (top-level, flat, with denormalized reference fields):**

- `sports`: { id, name (e.g. "Football"), enabled }
- `competitions`: { id, sportId, name (e.g. "Premier League"), enabled }
- `teams`: { id, sportId, competitionId, name, crestImageUrl }
- `players`: { id, teamId, name, position }
- `chants` is the heart of the app. It is stored top-level, not as deep subcollections, so both drill-down and cross-club discovery remain straightforward.
  - Identity / placement: `id`, `title`, `sportId`, `competitionId`, `teamId`, `playerId` (nullable; null means club-level or manager-level), `subjectTag` (player | coach | club | rival)
  - Content: `lyrics`, `tuneName` (text), `contextNotes`, `coverImageUrl`, `mediaUrl` (nullable), `mediaType` (none | audio | tuneRecording | lyricVideo | screenRecording | crowdClip). The current media fields predate the narrower v1 link-out decision and must not be treated as approval for uploads.
  - Classification: `status` (canonical | community), `chantType` (sincere | novelty). The older name `realOrParody` in this document is not the implemented field.
  - **Denormalized counters (defined from Block 1, default 0, written by Cloud Functions):** `upvotes`, `downvotes`, `score`, `commentCount`
  - Provenance / safety: `createdBy`, `createdAt`, `updatedAt`, `flagCount`, `hidden` (bool, fail-safe), `removed` (bool)
- `votes`: { id, chantId, userId, value (1 or -1), createdAt }. One per user per chant, enforced.
- `reports`: { id, chantId, reportedBy, reason, createdAt, status }
- `auditLog`: { id, actorId, action, targetType, targetId, detail, createdAt }. Moderation actions especially.
- `feedback`: the suggestion box. { id, userId, category (suggestion | bug | question | other), message (<= 1000 chars), followUpOk, resolved, createdAt }

**Approved v1 extension, field names finalized only in the Lane 2 change spec:** retain an immutable or tightly controlled submission origin (Already sung or I made this), an optional normalized evidence URL and platform, and enough operator-audited evidence state to prevent promotion without proof. Existing documents must remain readable without a destructive migration. Do not overload `chantType`, which describes sincere versus novelty, or let score act as verification.

**Why this topology (DECISIONS entry):** a single top-level `chants` collection with denormalized `teamId` / `playerId` gives drill-down (query chants where `teamId` equals X) and the cross-club shuffle (query across all chants, or a collectionGroup) without expensive joins, and it makes the future search index trivial because everything searchable already lives on one document.

**Access / security model (enforced server-side in Firestore rules plus Functions, never client-only):**
- Reads: public for non-hidden, non-removed chants.
- Writes to `chants`: authenticated users may create (enters as `community`). Only the author may edit their own draft fields; counters and `status` are never client-writable.
- `votes`: one per user per chant, value constrained to 1 or -1. Counter updates happen in a Cloud Function, not the client.
- `reports`: any authenticated user may insert their own. No edit or delete.
- Moderation (hide, remove, ban, unban, and promote to canonical): operator-only and audit logged. Promotion of a user submission must reject missing or invalid evidence after the provenance block ships.
- Rate-limits and fail-safe defaults: new or unproven accounts are rate-limited; content past a flag threshold auto-hides pending review.

---

## 9. UI structure

Mobile first. Drill-down navigation and simplest sensible placement. The current design contract and decision history live in `docs/INTERFACE.md`.

- **Public / browse:** Home to Competition to Club. Club and Player expose Songbook and Chant Lab without mixing their trust meanings. Songbook favors learning. Chant Lab exposes Top and New plus clear creation actions.
- **Chant detail:** Lyrics first, tune named, origin and verification stated in words, vote and discussion available, report always reachable, evidence opened externally when valid, and basic share available.
- **Submission:** Select club or player context, declare Already sung or I made this, enter the chant, see a soft duplicate nudge, attach optional evidence, and recover the draft after a failed write.
- **Saved:** A local-first Matchday Songbook states what is saved, when it was last refreshed, and whether the device is offline or the snapshot may be stale.
- **Operator:** Review reports, remove content, ban or unban users, and promote only when the verification contract is satisfied.

Show only what makes sense at each level. Never dump everything at once. One obvious tap to find, learn, save, create, or share.

---

## 10. Pricing

No billing in v1. Business-tier ideas are parked in WISHLIST.

---

## 11. Out of scope for v1 (protect the ship)

- Replies to replies, unlimited nesting, reply notifications, mentions, follow, and personalized feeds.
- Scheduled creation challenges, winner workflows, and push notifications. The basic player-scoped Start a chant action is in v1.
- Rich platform-specific share cards, direct publishing integrations, and generated social video. The system share sheet is in v1.
- Multiple linked renditions and any hosted audio or video. V1 permits one allowlisted external evidence link.
- The fuller moderation console. V1 retains the current operator tools and adds only what evidence review requires.
- Other leagues and other sports (v2; architecture already supports it, gated on PL traction).
- Fixture-calendar and matchday surfacing, trending / virality tracking, view counts and richer metrics (v2).
- Full-text search index (Algolia / Typesense). Browse-and-filter covers v1; promote on trigger.

---

## 12. Build order

Completed foundation:

- Blocks 1 to 7: agnostic data model, archive, seed pipeline, submission, moderation, voting, feedback, visual system, and hardening.
- Interaction block: comments, one reply level, blocking, lifecycle corrections, and audited unban are implemented and automated-test verified. The live-device release walk is still open.
- Stable identity source block: seeded chants have explicit immutable IDs, collision preflight, and transactional ownership checks. Repository tests are green; the live read-only preflight remains separately gated.

Remaining v1 blocks, each separately planned and reviewed:

1. Close and archive the current interaction block.
2. Authorize and run the read-only live identity preflight before any remaining production seed write. A mismatch opens a separate migration plan.
3. Provenance slice: origin-aware submit, optional evidence, soft duplicate nudge, honest detail labels, and evidence-gated operator promotion.
4. Discovery slice: Songbook and Chant Lab on club and player journeys, Top and New, Rising, and Start a chant.
5. Saved Matchday Songbook.
6. Basic share-out with a stable URL or text-only fallback.
7. Final policy, seed, device, access-control, store, deployment, and observation gates from `docs/ROADMAP.md`.

---

## 13. Definition of done (per feature)

Works end to end on the real seeded data; mobile-responsive; empty, loading, and error states present; audit log records the action (moderation especially); access control verified with a second account; no em dashes; no console errors; code review passed with disposition table (Security frame mandatory on any user-content surface); content-policy and reporting path present on any user-content surface; handbook section written; passes the simplicity check (a fan finds or places it in one obvious tap, simplest sensible layout).

---

## 14. Engineering memory

Reusable, evidence-backed lessons now live in `docs/LEARNINGS.md`. Chronological work evidence lives in `docs/EXECUTION.md`, and the current visual and interaction contract lives in `docs/INTERFACE.md`. This product specification does not duplicate those records.
