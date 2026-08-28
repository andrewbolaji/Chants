# Chants: Roadmap

The path from code-complete to public launch, with concrete triggers on every gate.

---

## Status (as of August 2026)

**Built and verified by automated checks:**
- v1 feature set: auth, agnostic Sport/Competition/Team/Chant data model, browse and search, chant detail, user submission, moderation (report, remove, ban, unban, rate limits, audit log), voting with counter reconciliation, one-level comment replies with likes, user blocking, and suggestion box.
- v1 hardening in source: account deletion, App Check client wiring, and Crashlytics wiring. Live enforcement and dashboard controls remain release-verification items.
- Stable seeded chant identity in source: explicit immutable IDs, collision preflight, and transactional ownership checks. The separately authorized live preflight remains pending.
- The complete V1 feature and remediation stack from PRs 4 through 10 and 12 through 14 is merged to `main`. It includes provenance and evidence, Songbook and Chant Lab, Saved Matchday Songbook, Basic Share-Out, parser-safe authority boundaries, server-authoritative report and feedback intake, durable account deletion, and the final freeze corrections.
- Final merged `main` is `9189c71d99c52539cb3d1b02f51701fa4334c144`, including PR 15. GitHub Actions run `33012771517` passed project governance, 353 Flutter tests, analysis, 78 Functions tests, 42 seed tests, and 136 Firestore rules assertions for that exact SHA.
- Claude independently reviewed the freeze ranges through final closure. The last review approved the minimal disposed-Home correction and dormant merge privacy gate with no new defect.
- The approved V1 core-journey interface-readiness and bounded Home hierarchy blocks are merged through PR 15. Home, competition, and player have inspected 390 by 844 baselines; the immutable competition-list crash is fixed; recovery copy is truthful; and Home explains Matchday Songbook, Terrace Proven, and Chant Lab without new navigation or data authority.
- Claude's one-shot review of `9189c71...e810318` judged draft PR 16 freeze-defensible with no production defect. Exact-head run `33025564912` passed all six jobs. One evidence-only closure for the native harness and unmeasured golden ceilings is locally green; its replacement CI and the combined device evidence remain pending.
- PR 16 and its reviewed correction are merged to `main` at `86603c22fbd7647f89c9276af9a60a0b3d63113b`. The creator-platform expansion is packaged in draft PR 17 through review head `946ab0c`. Product Clear navigation, separate public creator identity, Chant Stage, moderated 30-second performance upload, popularity signals, public destinations, private follows, activity, mentions, continued performance replies, and published-media safety are implemented. Replacement clean-runner run `33181165940` passed all six jobs at implementation head `641281e`; `946ab0c` added durable records. Claude's initial independent review accepted the architecture but found seven connected takedown and integrity gaps. Their approved correction passes 422 Flutter, 135 Functions, 42 seed, analysis, and governance checks locally and is packaged by the commit carrying this record. Java-backed exact-head CI and one narrow closure review remain external gates.
- Dedup matching engine (backend only): token-overlap matcher exists. Operator `mergeChants` is disabled because its retained sequential implementation has no resumable cursor or complete undo snapshot. Its legacy audit payload also embeds authored source content and raw `createdBy`; any re-enable must redesign that payload and re-review the deletion-retention allowlist.
- Visual identity: complete "matchnight, warmed with playful" redesign, tokenized, AA contrast proven.

**Not yet done:**
- Obtain one narrow independent closure review of the pushed PR 17 correction at `8b457d8`. Exact-head clean-runner run `33190943182` is green across all six jobs.
- Package the locally verified V1 launch authentication and onboarding block, then prove Android compilation on the new clean-runner job. Provider dashboards, credentials, SMS, signing, and store actions remain separate release gates.
- Complete Android native compilation for the current dependency graph, followed by visual sign-off and the combined V1 device walkthrough. The final iOS simulator source build passes locally.
- The read-only live chant-identity preflight before the next production seed write.
- The remaining verified club seed.
- Saved Matchday Songbook airplane-mode device walk; its iOS client compilation now passes.
- Camera and library permission, upload recovery, playback, public sharing, Following, activity, threaded conversation, moderation, block, and deletion device walks.
- Content policy, privacy, terms, domain association, store destinations, URL-signing IAM, Storage cleanup, App Check, alerts, billing controls, deployed parity, signing, and store assets.
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
11. **Establish Product Clear navigation and public creator identity.** Packaged and clean-runner green in draft PR 17. The signed-in shell exposes Feed, Clubs, Create, Songbook, and You. A callable transaction owns normalized unique handles and an allowlisted public creator document while private profile authority remains private.
12. **Build the Chant Stage performance block.** Packaged and clean-runner green in draft PR 17. A separate performance entity uses private Storage staging, record or library selection up to 30 seconds, manual approval, bounded paginated feed queries, explicit playback, and server-owned likes, qualified views, comments, unique shares, and weekly ranking. Existing words-only chants remain valid.
13. **Build public and social destinations.** Packaged and clean-runner green in draft PR 17. Chants, performances, and creators have stable server-rendered destinations and safe previews. Public performance pages use a current-authority media route. Private follows, aggregate counts, Following fallback, validated mentions, continued performance replies, and bounded activity notifications are integrated.
14. **Integrate and freeze the creator expansion.** The initial range is packaged and clean-runner green. Claude's review found source-lifecycle gaps rather than a failed creator-platform premise. The packaged correction closes current creator and chant authority, source reconciliation, exact performance counts, Stage and profile blocking, hidden-content escalation, and durable media deletion. Run exact-head CI and obtain one narrow closure review before native and device evidence.
15. **Build launch authentication, onboarding, and Android readiness.** Implemented and locally verified in the approved worktree. Chants now has a product-specific welcome, verified email and automatic return, recoverable server-owned onboarding, Apple, Google, Facebook, magic-link and phone paths behind fail-closed flags, explicit same-UID linking, truthful reset, iOS entitlements, fail-closed Android signing, and clean-runner native build jobs. The 454 Flutter, 142 Functions, and 42 seed tests, analysis, source contracts, and iOS simulator build pass. Exact-head CI, the Android artifact, provider configuration, and device walkthrough remain gates.

The original Songbook and Chant Lab boundary remains in `docs/decisions/004-songbook-and-chant-lab.md`; creator-platform decisions are 017 through 022 and the active implementation contract is `docs/CHANGE_SPEC.md`. Beat-synced karaoke editing, licensed backing tracks, duet or remix tools, payouts, scheduled challenges, automated large-scale media screening, and personalized recommendation models remain later work.

The pre-creator V1 stack is merged through `86603c2`. PR 17 now carries the packaged post-review correction at `8b457d8`, and exact-head clean-runner run `33190943182` passed all six jobs. The current iOS 12.18 CocoaPods graph resolves and builds the simulator app from the final local auth source. Android is still blocked locally by the missing SDK. The narrow correction review, auth-block packaging and exact-head CI, Android build, provider setup, and combined device walkthrough remain gates that turn source confidence into release sign-off.

**Trigger to exit:** The independent creator-platform closure review is green; approved launch auth and onboarding are complete; both native clients compile; recording or choosing, upload recovery, approval, playback, sharing, Following, comments, activity, moderation, blocking, deletion, authentication, verification, and offline Songbook pass the combined device walk; provenance and promotion rules still work end to end; and public share-out never produces a broken destination.

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

---

## v1 Launch Readiness

Parallel track (not a v1 launch blocker): flip the GitHub repo public for job applications; delete the two local backup folders once a fresh clone builds clean; Firebase client-key rotation remains optional since security rules and App Check are the primary protection.

### Build status

- **DONE** Blocks 1-5 built and working: auth, agnostic data model (Sport > Competition > Team > Chant), browse/search/detail, user submission, basic moderation (report/remove/ban/rate-limit/audit log), voting with optimistic UI, feedback channel.
- **DONE** Fanzine visual redesign across all surfaces (commit 4f9f8ae).
- **DONE** Vote rapid-tap reconciliation fixed (commit 9912adf).
- **DONE** Vote stale-load mismatch fixed via appliedValue reconciliation; detail screen now subscribes to a live chant stream (commit 38f559a).
- **IN PROGRESS** Launch authentication and onboarding are implemented and locally verified with server-owned initial profile creation and requested providers hidden until configuration. Packaging, Android clean-runner proof, exact-head CI, provider setup, and device evidence remain before release.

### Comments on chants (v1, likes plus one reply level)

**Current:** one direct reply level, one like per user, reporting, moderation, blocking, rate limiting, lifecycle handling, and comment counts are implemented and covered by automated checks.

**Next:** complete the live-device keyboard, failed-write, block/unblock, moderation, and account-deletion walk recorded in `docs/CHANGE_SPEC.md`.

**Implemented creator V1 block:** performance comments support validated mentions, private activity notifications, continued replies with no more than three visible indentation levels, and a focused deeper-thread view. Legacy chant comments remain one-level. Unlimited inline nesting, collaborative lyric suggestions, and comment downvotes remain outside V1.

The implementation boundary and remaining verification gate live in `docs/CHANGE_SPEC.md`.

### Songbook and Chant Lab (v1)

**Approved product contract:** Chants keeps Terrace Proven content in the trusted Songbook and gives original or not-yet-verified submissions a visible Chant Lab. Submission origin is required. Evidence is optional to post and required to promote a user submission to Terrace Proven. Votes rank ideas but never verify a factual claim.

**Implementation status:** The provenance slice, browse split, Saved Matchday Songbook, Basic Share-Out, authority remediation, report and feedback abuse controls, durable account deletion, and final freeze remediation are merged to `main` and exact-main clean-runner green. iOS simulator compilation passes locally; Android compilation and the combined device walk remain.

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
- **TODO** App Check production: register the DeviceCheck key, then flip soft to full enforcement after about one clean telemetry week.
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

- CI/CD via GitHub Actions. Status: in progress.
- Observability: Crashlytics fully wired and verified, plus Firebase Performance Monitoring and Analytics. Status: next.
- Firestore security rules test suite using `@firebase/rules-unit-testing`, covering the deny-by-default posture and the pinning of role and other privileged fields. Recommended pre-v1, not a hard store gate.
- Code coverage via `flutter test --coverage` uploaded to Codecov, added alongside CI. Surface the badge only once coverage is respectable.

### Store compliance gates (user content), from the compliance audit

- Policy acceptance before posting. DONE. Sign up and the first submit or comment are gated on accepting the content policy, and the acceptance is recorded server side. Google user-content requirement. Merged and CI-enforced (flutter, functions, and rules jobs all green on main).
- Age check at sign up. DONE. Date of birth entered at sign up, age computed locally, sign up blocked under 17. The date of birth itself is never stored, only the pass or fail result. Google age-screening requirement. The 17+ store rating is still the main lever, this is the in-app backup. Merged and CI-enforced.
- Report a user. DONE. Reporting now covers a user account, not just a chant or comment. Google user-content requirement. All three report types share one server-authoritative atomic budget in the current stack. Known gap: a user who only submits chants and never comments cannot be reported through this UI, since no screen currently shows a chant's author.
- User blocking. DONE in source and automated checks. Directional block records hide comment interactions in the client, rules deny reply and like interaction in either direction, and users can review and undo their blocks.
- Content policy text. Not done. The real policy wording still needs writing and wiring into content_policy_screen.dart to replace the current placeholder. Required before store submission regardless of the feature gates above.

Priority note: the real content policy text and live-device enforcement walk remain before a clean pre-v1 compliance pass.
