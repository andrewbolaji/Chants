# Chants: Roadmap

The path from code-complete to public launch, with concrete triggers on every gate.

---

## Status (as of August 2026)

**Built and verified by automated checks:**
- v1 feature set: auth, agnostic Sport/Competition/Team/Chant data model, browse and search, chant detail, user submission, moderation (report, remove, ban, unban, rate limits, audit log), voting with counter reconciliation, one-level comment replies with likes, user blocking, and suggestion box.
- v1 hardening in source: account deletion, App Check client wiring, complete native Crashlytics delivery hooks, bounded abandoned-media cleanup, and privacy-safe stale deletion-job detection. iOS App Attest is registered but unenforced; two operational policies and the alert-only budget are saved. Android registration, first Crashlytics delivery, observed alert delivery, and deployment remain release-verification items.
- Stable seeded chant identity in source: explicit immutable IDs, collision preflight, and transactional ownership checks. The separately authorized live preflight remains pending.
- The complete V1 feature and remediation stack from PRs 4 through 10 and 12 through 14 is merged to `main`. It includes provenance and evidence, Songbook and Chant Lab, Saved Matchday Songbook, Basic Share-Out, parser-safe authority boundaries, server-authoritative report and feedback intake, durable account deletion, and the final freeze corrections.
- Creator and authentication feature source merged at `e8f2591740963f87623aacb82a806328cb1a98fe`. GitHub Actions run `33256843751` passed all eight jobs there: 463 Flutter tests, analysis, 142 Functions tests, 42 seed tests, 165 Firestore and Storage assertions, governance, and both native compile and identity checks. Documentation-only PR 19 later advanced `main` to `9c6286a` without changing executable input.
- Claude independently reviewed the freeze ranges through final closure. The last review approved the minimal disposed-Home correction and dormant merge privacy gate with no new defect.
- The approved V1 core-journey interface-readiness and bounded Home hierarchy blocks are merged through PR 15. Home, competition, and player have inspected 390 by 844 baselines; the immutable competition-list crash is fixed; recovery copy is truthful; and Home explains Matchday Songbook, Terrace Proven, and Chant Lab without new navigation or data authority.
- Claude's one-shot review of `9189c71...e810318` judged PR 16 freeze-defensible with no production defect. Its evidence closure and corrections merged at `86603c2` before the creator stack.
- PR 18 merged its launch authentication, recoverable onboarding, and Android readiness into PR 17 at combined head `5350b8a`. The final independent review declared that combined creator and authentication source clear for freeze. Minor-closure implementation `e1474ad` closed the remaining two findings, documentation head `c1c4ea4` passed all eight jobs in run `33255542646`, and PR 17 merged as `e8f2591` with exact-main run `33256843751` green across all eight jobs.
- Dedup matching engine (backend only): token-overlap matcher exists. Operator `mergeChants` is disabled because its retained sequential implementation has no resumable cursor or complete undo snapshot. Its legacy audit payload also embeds authored source content and raw `createdBy`; any re-enable must redesign that payload and re-review the deletion-retention allowlist.
- Visual identity: complete "matchnight, warmed with playful" redesign, tokenized, AA contrast proven.

**Not yet done:**
- Complete remaining provider dashboards and credentials, Android association, deployed Apple association, production signing, policy, observed cost and abuse controls, and the combined iOS and Android V1 device walkthrough. Feature source at `e8f2591` compiles and passes identity inspection on both clean runners.
- The read-only live chant-identity preflight before the next production seed write.
- The remaining verified club seed.
- Saved Matchday Songbook airplane-mode device walk; its iOS client compilation now passes.
- Camera and library permission, upload recovery, playback, public sharing, Following, activity, threaded conversation, moderation, block, and deletion device walks.
- Content policy, privacy, terms, association deployment, store destinations, URL-signing IAM, cleanup deployment, Android App Check, observed alert and billing delivery, deployed parity, signing, and store assets.
- Store launch prep.

---

## Phase 1: Private v1 sign-off

Run on device, confirm font weights render bold and heavy, walk all core flows and states.

**Trigger to exit:** Andrew confirms the current interface reads correctly and no flow is broken. The exploratory Home redesign remains a separate product choice.

---

## Phase 2: Stable identity and seed

Andrew can continue source and lyric verification without waiting on engineering. The repository now uses explicit seeded chant IDs and freezes Arsenal to its expected legacy IDs. Before the remaining clubs are written to live Firestore or chant URLs are made public, run the separately authorized read-only preflight against the named project. If live state differs, stop and prepare a migration-specific plan instead of writing.

Then seed around five verified, externally sourced, policy-checked chants per Premier League club for the 19 unseeded clubs, plus verifying the Arsenal placeholder set. Content-integrity rule applies: lyrics and squads are sourced and verified externally, never authored from model memory.

Source verification in this phase and the application work in Phase 3 may run in parallel. The stable-ID gate applies to live data writes, not to Andrew's sourcing documents or club JSON preparation.

**Trigger to exit:** The live identity preflight reports no collision, stable IDs preserve the document through a rename test, and all 20 clubs have a verified canonical primer set.

---

## Phase 3: v1 interaction and creator loop

V1 is a trusted songbook and a creator workshop. The work is sequenced as bounded review blocks so the product direction does not become one high-risk rebuild.

1. **Close the current interaction block.** Replies, blocking, lifecycle fixes, and audited unban are done in source and automated checks. Complete the device walk in `docs/CHANGE_SPEC.md`, then archive its implementation rationale before replacing the active spec.
2. **Add provenance end to end.** Merged and exact-main CI verified. Submission requires Already sung or I made this. Evidence is optional at posting, an Already sung claim without one stays visibly unverified, and a user submission needs valid evidence plus operator review before Terrace Proven promotion. The device walk remains.
3. **Expose Songbook and Chant Lab.** Merged and exact-main CI verified. Club and player journeys distinguish Terrace Proven content from community work, with Top and New in Chant Lab and a non-verification Rising signal. The device walk remains.
4. **Build Saved Matchday Songbook.** Merged and exact-main CI verified. One chant or a club's current visible Songbook can be stored as a UID-scoped device snapshot, refreshed explicitly, read without live social dependencies, and removed locally. iOS simulator compilation passes; the airplane-mode force-stop and relaunch walk remains. Cross-device sync stays deferred.
5. **Add basic share-out.** The original text-only block is merged and exact-main CI verified. The active creator-platform range now resolves current visible chants, performances, and creators to stable public URLs before native sharing. Production Hosting, domain, app or store routing, and the destination device walk remain.
6. **Close report and feedback velocity abuse.** Merged, independently reviewed as part of the freeze range, and exact-main CI verified. Admission uses authenticated callables with server-owned fields and atomic anchored-window budgets. Direct client creates remain denied and failed forms retain entered work.
7. **Make account deletion recoverable.** Merged, independently reviewed through final closure, and exact-main CI verified. Durable acceptance precedes local cleanup and sign-out; one retry-enabled server worker performs bounded idempotent cleanup while pending accounts lose active authority.
8. **Establish core interface readiness.** Merged and exact-main CI verified. Home, competition, and player have current baseline renders and state coverage. One immutable-list crash and four misleading recovery messages are corrected.
9. **Refresh the V1 Home hierarchy.** Merged and exact-main CI verified. Home keeps existing routes and providers while surfacing Matchday Songbook, Premier League browse, one Terrace Proven chant, and one Chant Lab idea.
10. **Close the independent interface review.** Merged through PR 16. Home derives Rising from the current live community chant, empty Terrace Proven recovery opens real club browse, semantic trust assertions sit outside golden tolerance, and governance checks state and test their real manual and CI boundaries.
11. **Establish Product Clear navigation and public creator identity.** Merged in PR 17 and exact-main CI verified. The signed-in shell exposes Feed, Clubs, Create, Songbook, and You. A callable transaction owns normalized unique handles and an allowlisted public creator document while private profile authority remains private.
12. **Build the Chant Stage performance block.** Merged in PR 17 and exact-main CI verified. A separate performance entity uses private Storage staging, record or library selection up to 30 seconds, manual approval, bounded paginated feed queries, explicit playback, and server-owned likes, qualified views, comments, unique shares, and weekly ranking. Existing words-only chants remain valid.
13. **Build public and social destinations.** Merged in PR 17 and exact-main CI verified. Chants, performances, and creators have stable server-rendered destinations and safe previews. Public performance pages use a current-authority media route. Private follows, aggregate counts, Following fallback, validated mentions, continued performance replies, and bounded activity notifications are integrated.
14. **Integrate and freeze the creator expansion.** Merged in PR 17, clean-runner green, and independently accepted. The correction closes current creator and chant authority, source reconciliation, exact performance counts, Stage and profile blocking, hidden-content escalation, and durable media deletion.
15. **Build launch authentication, onboarding, and Android readiness.** Merged through PRs 18 and 17, clean-runner green across eight jobs at exact `main`, and independently accepted for source freeze. Chants has a product-specific welcome, verified email and automatic return, recoverable server-owned onboarding, Apple, Google, Facebook, magic-link and phone paths behind fail-closed flags, explicit same-UID linking, truthful reset, native entitlements and paths, fail-closed Android signing, and native CI.
16. **Close post-auth review findings.** Merged, independently verified, and exact-main clean-runner green. The nine corrections align Storage operator authority, retry provider initialization, restore onboarding escape paths, make phone cooldown and cancellation monotonic, retain ambiguous magic-link state, distinguish requested from connected or complete, and enlarge the onboarding destination target.
17. **Close final source-freeze minor findings.** Merged and exact-main CI verified. Runtime commit `e1474ad` freezes saved onboarding values while profile projection catches up, documentation commit `c1c4ea4` records the evidence, and merge commit `e8f2591` passes all eight jobs in run `33256843751`.
18. **Stage launch services without premature enforcement.** In progress on the approved launch-services branch. Source now contains exact Apple association, complete native Crashlytics delivery hooks, daily bounded abandoned-draft cleanup, capped aggregate stale-job monitoring, and CI contract checks. Firebase Auth authorizes both planned domains; iOS App Attest is registered at the default one-hour TTL and remains unenforced; two privacy-safe operational policies and the USD 25 alert-only budget are saved and re-read. Deployment, observed alert delivery, Android signing identity, device proof, and clean-runner evidence remain open.

The original Songbook and Chant Lab boundary remains in `docs/decisions/004-songbook-and-chant-lab.md`; creator-platform decisions are 017 through 022 and the active post-merge documentation contract is `docs/CHANGE_SPEC.md`. Beat-synced karaoke editing, licensed backing tracks, duet or remix tools, payouts, scheduled challenges, automated large-scale media screening, and personalized recommendation models remain later work.

The complete reviewed V1 source stack is merged at `e8f2591`. Exact-main run `33256843751` passes all eight jobs, including both native builds and 165 Java-backed Firestore and Storage cases. Provider setup, production signing, association deployment, policy, observed telemetry and alert delivery, and the combined device walkthrough remain gates that turn source confidence into release sign-off.

**Trigger to exit:** The final minor closure is exact-head green; both native clients still compile; recording or choosing, upload recovery, approval, playback, sharing, Following, comments, activity, moderation, blocking, deletion, authentication, verification, and offline Songbook pass the combined device walk; provenance and promotion rules still work end to end; and public share-out never produces a broken destination.

---

## Phase 4: Public launch prep

- Apple Developer and Google Play accounts, store listings and data-safety declarations, app icon and branding, 17+ age rating.
- Host the privacy policy and a light terms of service on Firebase Hosting, stamp the effective date.
- Flip App Check from soft to full enforcement after one to two weeks of clean telemetry.

**Trigger to launch:** All of the above complete and Phase 3 signed off.

---

## Cross-cutting risks (unchanged, tracked with triggers)

### Moderation and content safety (existential, addressed from v1)
Shipped in source: content policy stub, server-authoritative report and feedback admission, atomic report and feedback budgets, remove, ban, unban, fail-safe auto-hide, and audit log. Open: Andrew writes the real content policy text. Trigger for the fuller moderation console: accepted submission volume outgrows basic remove-and-ban.

### Music and IP licensing (active design constraint)
Lyrics plus tune-name text remains the core, and optional evidence links still open on allowlisted external platforms. The approved performance block hosts short user-created video or audio captured with the video, not licensed master recordings or an extracted platform stream. Upload terms, takedown handling, privacy, moderation, storage cleanup, and cost controls are release gates. Beat-synced karaoke and licensed backing tracks remain deferred until a separately approved rights and operations model exists.

### Cold-start and retention (addressed by design)
The operator-seeded Songbook makes the app useful on day one. Chant Lab, player creation prompts, voting, comments, sharing, and Saved Matchday Songbook provide creation, competition, conversation, distribution, and matchday return loops without waiting for a personalized feed.

### Expansion
Architecture is sport-agnostic and league-agnostic from Block 1. Expansion is data, not code. v1 is Football and the Premier League. v2 adds leagues or sports based on usage data.

### Living Songbook

**DONE IN SOURCE FOR V1:** Chant detail has a correction, variation, and post-submission evidence block. The source implementation keeps it separate from safety reporting, gives the submitter a private status view, gives operators a stale-aware review queue, and lets reviewed evidence promote a user chant to Terrace Proven atomically. Local Functions, Flutter, seed, analysis, typecheck, and governance evidence is green. Clean-runner rules, device walk, deployment, and release remain open.

The product loop is: idea to performances to sharing to sung live to evidence to Terrace Proven.

The durable authority is Decision 025. A suggestion never edits canonical wording automatically. Accepted corrections and variations still travel through the reviewed content or seed path.

## V1.1 candidate backlog

These ideas are pinned for deliberate V1.1 evaluation. They are not launch promises or hidden V1 scope. Each begins with a small slice and has a trigger for deciding whether it deserves a full build.

### 1. Chant Call-Ups

- **Purpose:** Turn transfer windows and players without chants into a visible creation competition.
- **Smallest first slice:** A club or player page card that names one active player with no visible chant and opens the existing words-first submission path with club and player prefilled.
- **Success signal:** meaningful submissions per call-up, shares, repeat creators, and at least one idea later supported by real evidence.
- **Keep out initially:** prizes, brackets, automatic winners, paid promotion, and a separate contest backend.
- **Decision trigger:** ship the first call-ups when the V1 creator flow is stable and current player data can be maintained reliably.

### 2. Matchday Mode

- **Purpose:** Make the Saved Matchday Songbook faster to use in a noisy stand with unreliable connectivity.
- **Smallest first slice:** A full-screen offline reader with oversized lyrics, high contrast, swipe between saved chants, and an optional user-arranged club setlist.
- **Success signal:** saved-songbook opens on matchdays, offline completion, repeat use within the same fixture, and low accidental-exit rate.
- **Keep out initially:** live score integration, location tracking, background audio, stadium chat, and synchronized crowd playback.
- **Decision trigger:** build after the V1 airplane-mode walk passes and real users save enough chants to justify a dedicated mode.

### 3. Tune Families

- **Purpose:** Help supporters learn a new chant by recognizing the shared melody behind it.
- **Smallest first slice:** Normalize operator-reviewed tune names and link chants that share that label. No audio is hosted.
- **Success signal:** tune-family opens lead to chant detail, saves, or successful submissions.
- **Keep out initially:** melody fingerprinting, copyrighted backing tracks, automatic tune identification, and unreviewed user tags.
- **Decision trigger:** proceed when seed cleanup shows tune names can be normalized without creating misleading families.

### 4. Heard at the Ground

- **Purpose:** Capture a useful fan signal that a chant has moved beyond the app.
- **Smallest first slice:** One rate-limited, match-scoped confirmation with visible wording that it is a fan signal, not proof.
- **Success signal:** geographically and temporally diverse confirmations correlate with later reviewed evidence without abuse spikes.
- **Keep out initially:** automatic Terrace Proven promotion, location collection, anonymous mass voting, and a public factual claim.
- **Decision trigger:** reconsider only after beta volume supports an abuse model and the Living Songbook evidence queue has real operating data.

### 5. Followed-club chant alerts

- **Purpose:** Give supporters a reason to return when their club gains a new or newly verified chant.
- **Smallest first slice:** A private club-follow preference and one in-app activity item for a new Terrace Proven chant. No push notification until consent and delivery operations are approved.
- **Success signal:** alert opens, club follows, return sessions, and low mute or complaint rate.
- **Keep out initially:** marketing blasts, match alerts, inferred fandom, and notification to every user.
- **Decision trigger:** build after the seed is complete enough that alert cadence represents real new information.

### 6. Lyric-level search and historic filters

- **Purpose:** Make large club collections useful as they grow and preserve departed-player songs instead of deleting them.
- **Smallest first slice:** Search normalized lyric text plus explicit Current, Historic, and Variations filters within a club.
- **Success signal:** successful searches that would have missed title, club, and player matching; historic chant opens and saves.
- **Keep out initially:** semantic search, automatic era inference, universal web indexing, and unreviewed age claims.
- **Decision trigger:** add when launch collections are large enough that current navigation produces measurable zero-result or long-scroll friction.

### 7. Creator lyric-video tools

- **Purpose:** Let shy or editing-focused creators publish a performance format closer to karaoke without singing on camera.
- **Smallest first slice:** Review whether users already upload externally edited lyric videos through the existing 30-second media path, then add safe templates only if that behavior is common.
- **Success signal:** approved lyric-video submissions, completion rate, sharing, and no material moderation or rights increase.
- **Keep out initially:** beat detection, licensed backing tracks, copyrighted master audio, duet or remix, and a full mobile editor.
- **Decision trigger:** prototype only after V1 media operations are stable and real upload patterns justify it.

### 8. Commercial creator opportunities

- **Purpose:** Preserve the long-term path from a widely shared creator performance to club, supporter-group, event, or brand opportunity.
- **Smallest first slice:** Research opt-in contact and attribution terms after the creator graph has real traction. No marketplace is implied.
- **Success signal:** credible inbound opportunities and creators who explicitly want them.
- **Keep out initially:** payouts, sponsorship matching, rights representation, exclusivity, and rankings presented as professional worth.
- **Decision trigger:** legal and rights review plus meaningful creator and share volume.

Deep comment mentions and nesting beyond the current performance-thread design, duet or remix, licensed music, beat-synced karaoke, personalized recommendations, automated large-scale media screening, and creator payouts remain future work with their existing safety, rights, privacy, cost, and operations gates.

## FanChants reference audit, checked 2026-08-29

FanChants is useful market evidence, not seed authority and not a design template.

### What Chants should learn from

- Team-first discovery, lyric search, deep club songbooks, newest and curated fallbacks, historic or vintage preservation, offline access, and new-chant alerts solve real supporter jobs.
- FanChants' large global archive shows that club songbooks can become a long-lived product, while Chants should prove the Premier League loop before widening the catalogue.
- Its commercial business shows that owned recordings and licensing can become a separate future revenue route. It also confirms that recording rights and underlying melody rights are different clearance problems.
- Historic songs for departed players should normally become archive content, not disappear. Currentness, trust, subject, and popularity should remain separate fields.

### What Chants should not copy

- Spotify plays or in-product popularity must never prove that a chant is genuinely sung.
- One genre per chant is too coarse. Chants needs separate trust, era, subject, tone, and evidence dimensions.
- FanChants' downloadable recordings, ringtones, Spotify releases, and licensing inventory depend on a rights chain Chants does not own.
- A broad commercial sublicense for user uploads should not be hidden in general terms. Creator ownership, right-to-share, platform use, moderation, and takedown terms need plain language before release.
- Rivalry content cannot be excused as banter when it crosses the Chants safety policy.
- FanChants content may help discover a lead or corroborate evidence, but its lyrics and descriptions are not copied into the seed and are never the sole verification source.
- Core learning should not require signup solely to unlock an arbitrary audio preview limit.

### Sources

- [FanChants home and account offering](https://www.fanchants.com/)
- [Manchester United team songbook example](https://www.fanchants.com/football-team/manchester_united/)
- [FanChants search](https://www.fanchants.com/search/)
- [FanChants about](https://www.fanchants.com/about/about-fanchants/)
- [FanChants commercial licensing](https://www.fanchants.com/commercial/)
- [FanChants submission and licensing terms](https://www.fanchants.com/legals/disclaimer/)
- [FanChants genre model](https://www.fanchants.com/genres/)

---

## v1 Launch Readiness

Parallel track (not a v1 launch blocker): flip the GitHub repo public for job applications; delete the two local backup folders once a fresh clone builds clean; Firebase client-key rotation remains optional since security rules and App Check are the primary protection.

### Build status

- **DONE** Blocks 1-5 built and working: auth, agnostic data model (Sport > Competition > Team > Chant), browse/search/detail, user submission, basic moderation (report/remove/ban/rate-limit/audit log), voting with optimistic UI, feedback channel.
- **DONE** Fanzine visual redesign across all surfaces (commit 4f9f8ae).
- **DONE** Vote rapid-tap reconciliation fixed (commit 9912adf).
- **DONE** Vote stale-load mismatch fixed via appliedValue reconciliation; detail screen now subscribes to a live chant stream (commit 38f559a).
- **DONE IN SOURCE** Launch authentication, onboarding, the nine-finding correction, Android source readiness, and the two-finding minor closure are merged and exact-main clean-runner green. Provider setup and device evidence remain before release.

### Comments on chants (v1, likes plus one reply level)

**Current:** one direct reply level, one like per user, reporting, moderation, blocking, rate limiting, lifecycle handling, and comment counts are implemented and covered by automated checks.

**Next:** complete the live-device keyboard, failed-write, block/unblock, moderation, and account-deletion walk recorded in `docs/CHANGE_SPEC.md`.

**Implemented creator V1 block:** performance comments support validated mentions, private activity notifications, continued replies with no more than three visible indentation levels, and a focused deeper-thread view. Legacy chant comments remain one-level. Unlimited inline nesting, collaborative lyric suggestions, and comment downvotes remain outside V1.

The implementation boundary and remaining verification gate live in `docs/CHANGE_SPEC.md`.

### Songbook and Chant Lab (v1)

**Approved product contract:** Chants keeps Terrace Proven content in the trusted Songbook and gives original or not-yet-verified submissions a visible Chant Lab. Submission origin is required. Evidence is optional to post and required to promote a user submission to Terrace Proven. Votes rank ideas but never verify a factual claim.

**Implementation status:** The provenance slice, browse split, Saved Matchday Songbook, Basic Share-Out, authority remediation, report and feedback abuse controls, durable account deletion, creator platform, authentication, Android readiness, and final freeze remediation are merged to `main` and exact-main clean-runner green. Both native clients compile on clean runners; the combined device walk remains.

**Source of truth:** `docs/decisions/004-songbook-and-chant-lab.md` and the interface contract in `docs/INTERFACE.md`.

### Content (owner: Andrew, critical path)

- **IN PROGRESS** Arsenal seeded and verified. Lyrics confirmed, three context notes confirmed factual and unflagged, plus several more verified chants added (player, club, and manager subjects). Arsenal is the showcase club and is effectively complete.
- **TODO** Seed the other 19 Premier League clubs. Target about 5 chants per club, roughly 100 total. Floor: no club below 3 genuinely iconic chants. All externally sourced and verified against a real version, never generated. Ship trigger: every club clears the floor and the marquee clubs sit at about 5.
- **IN PROGRESS** Premier League chant seed. Arsenal is the only club JSON currently in source. The working handoff records lyric gathering and review from Aston Villa through Fulham, nine clubs, but those clubs still need final decisions, reviewed JSON packaging, validation, and live writes. Hull City onward, ten clubs, still needs manual lyric and context verification. Content-integrity rule remains absolute: lyrics and source claims are never generated.
  - Status: manual verification is roughly halfway; technical packaging and live seed completion remain 1 of 20 clubs.
  - Trigger to prepare a club seed file: its chants have verified lyrics filled in. Source work can continue now. The live Firestore write waits for the stable-ID precondition above, then follows the tested seed path with round-trip and duplicate checks, using the current `chantType` values `sincere` and `novelty`.
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
- **IN PROGRESS** App Check production: iOS App Attest is registered and remains unenforced. Register Android Play Integrity only after trusted release signing exists, observe one to two weeks of valid release traffic, then approve enforcement separately. DeviceCheck fallback still requires an approved private-key path.
- **TODO** Production build, signing, and deploy.

---

## Launch and marketing plan

### Pre-launch (start now, needs weeks of runway)

- **One-sentence pitch**, used everywhere (store subtitle, site headline, social bios): *Chants is the songbook of the terraces and the workshop for what gets sung next.*
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
- Make the v1 native share action excellent. Rich platform-specific cards and generated social video remain later growth work.
- Add an in-app prompt asking happy users to rate the app after a good moment; store ratings drive organic discovery more than anything.
- SEO groundwork: repurpose handbook and chant content into public help and lyrics pages on chantsfc.com, which compounds over time.

### Budget (hold under 500 dollars)

- Domain and hosting: roughly 30 dollars a year, already committed.
- Hold off on paid ads until the free channels prove the app resonates.
- Best paid dollar is one football-culture micro-influencer (roughly 100 to 300 dollars) rather than scattershot ads.
- Skip PR firms, broad untargeted ads, and anything promising download counts.

### Pre-v1 engineering hardening gates

- CI via GitHub Actions. Status: complete for source verification across governance, Flutter, Functions, seed, Firestore and Storage rules, and both native debug builds. Automated deployment is not built or implied.
- Observability: Crashlytics delivery hooks, bounded staging cleanup, and privacy-safe stale-job logging are wired in source, and two operational policies are saved. First received and symbolicated crash, deployment, and observed alert delivery remain next. Firebase Performance Monitoring and Analytics remain deferred unless a later approved data and product case justifies them.
- Firestore and Storage security-rules suites use `@firebase/rules-unit-testing`; 165 Java-backed cases pass on exact merged `main`.
- Code coverage via `flutter test --coverage` uploaded to Codecov, added alongside CI. Surface the badge only once coverage is respectable.

### Store compliance gates (user content), from the compliance audit

- Policy acceptance before posting. DONE. Sign up and the first submit or comment are gated on accepting the content policy, and the acceptance is recorded server side. Google user-content requirement. Merged and CI-enforced (flutter, functions, and rules jobs all green on main).
- Age check at sign up. DONE. Date of birth entered at sign up, age computed locally, sign up blocked under 17. The date of birth itself is never stored, only the pass or fail result. Google age-screening requirement. The 17+ store rating is still the main lever, this is the in-app backup. Merged and CI-enforced.
- Report a user. DONE. Reporting now covers a user account, not just a chant or comment. Google user-content requirement. All three report types share one server-authoritative atomic budget in the current stack. Known gap: a user who only submits chants and never comments cannot be reported through this UI, since no screen currently shows a chant's author.
- User blocking. DONE in source and automated checks. Directional block records hide comment interactions in the client, rules deny reply and like interaction in either direction, and users can review and undo their blocks.
- Content policy text. Not done. The real policy wording still needs writing and wiring into content_policy_screen.dart to replace the current placeholder. Required before store submission regardless of the feature gates above.

Priority note: the real content policy text and live-device enforcement walk remain before a clean pre-v1 compliance pass.
