# Chants: Roadmap

The path from code-complete to public launch, with concrete triggers on every gate.

---

## Status (as of 2 September 2026)

**Built and verified by automated checks:**

- The complete V1 source, launch-policy closure, public landing presentation, and final pre-launch hardening are merged through PR 32 at `88ce483f1ea18df6a7a2b4e790803773164ac9a5`. Fresh exact-main run `33562025155` completed all eight jobs successfully. Gate 2 deployed its 46 non-scheduled Functions while production stayed closed. No Hosting, DNS, store, or public-release action is implied.
- Backend safety, review corrections and Chant Call-Ups are merged through PR 28 at `42f20dc675a1de4fe85956783774a4cdc67f3a01`. [Exact-main run 33368497566](https://github.com/andrewbolaji/Chants/actions/runs/33368497566) passed all eight jobs. This is source/build evidence, not deployment or device proof.
- v1 feature set: auth, agnostic Sport/Competition/Team/Chant data model, browse and search, chant detail, user submission, moderation (report, remove, ban, unban, rate limits, audit log), voting with counter reconciliation, one-level comment replies with likes, user blocking, and suggestion box.
- v1 hardening in source: account deletion, App Check client wiring, complete native Crashlytics delivery hooks, bounded abandoned-media cleanup, and privacy-safe stale deletion-job detection. Gate 0 found iOS App Attest and Android Play Integrity configurations, both unenforced at the Firestore and Authentication products; two operational policies remain enabled. Gate 1 refreshed the budget. First Crashlytics delivery, App Check release-traffic observation, alert delivery, and deployment remain release-verification items.
- Stable seeded chant identity in source and the Arsenal production boundary: explicit immutable IDs, collision preflight, transactional ownership checks, writer-free readback, and exact guarded retirement. Named-project preflight is clean for all 192 targets, and final Arsenal readback is exact.
- V1 Premier League catalogue source and production: complete for all 20 approved clubs. The files contain 192 chants and 622 reviewed squad rows, dated squad and source metadata, explicit current or historic treatment, and named owner overrides where the refreshed official feed lags reviewed Arsenal membership. All-club production readback is exact. No club write remains; configured-device inspection does.
- The complete V1 feature and remediation stack from PRs 4 through 10 and 12 through 14 is merged to `main`. It includes provenance and evidence, Songbook and Chant Lab, Saved Matchday Songbook, Basic Share-Out, parser-safe authority boundaries, server-authoritative report and feedback intake, durable account deletion, and the final freeze corrections.
- Creator and authentication feature source merged at `e8f2591740963f87623aacb82a806328cb1a98fe`. GitHub Actions run `33256843751` passed all eight jobs there: 463 Flutter tests, analysis, 142 Functions tests, 42 seed tests, 165 Firestore and Storage assertions, governance, and both native compile and identity checks. Documentation-only PR 19 later advanced `main` to `9c6286a` without changing executable input.
- Claude independently reviewed the freeze ranges through final closure. The last review approved the minimal disposed-Home correction and dormant merge privacy gate with no new defect.
- The approved V1 core-journey interface-readiness and bounded Home hierarchy blocks are merged through PR 15. Home, competition, and player have inspected 390 by 844 baselines; the immutable competition-list crash is fixed; recovery copy is truthful; and Home explains Matchday Songbook, Terrace Proven, and Chant Lab without new navigation or data authority.
- Claude's one-shot review of `9189c71...e810318` judged PR 16 freeze-defensible with no production defect. Its evidence closure and corrections merged at `86603c2` before the creator stack.
- PR 18 merged its launch authentication, recoverable onboarding, and Android readiness into PR 17 at combined head `5350b8a`. The final independent review declared that combined creator and authentication source clear for freeze. Minor-closure implementation `e1474ad` closed the remaining two findings, documentation head `c1c4ea4` passed all eight jobs in run `33255542646`, and PR 17 merged as `e8f2591` with exact-main run `33256843751` green across all eight jobs.
- Dedup matching engine (backend only): token-overlap matcher exists. Operator `mergeChants` is disabled in reviewed source because its retained sequential implementation has no resumable cursor or complete undo snapshot. The recovered July deployment lacks that stop and must not be invoked; the rollout must bring it to reviewed source. Its legacy audit payload also embeds authored source content and raw `createdBy`; any re-enable must redesign that payload and re-review the deletion-retention allowlist.
- Visual identity: complete "matchnight, warmed with playful" redesign, tokenized, AA contrast proven.

**Not yet done:**

- **Next, updated 2026-09-02:** Four Gate 3 attempts all returned safely to maintenance, most recently generation 9, without an owner request. The approved explicit-engine correction then removed the paired-iPhone pre-Dart startup crash. Cold launch, force quit, background, resume, the owner-confirmed 2.8-second reveal, compact policy hierarchy, visible acceptance progress, and truthful maintenance denial have physical evidence. The first independent review found one bounded policy-recovery defect plus documentation and guard corrections. The independent closure review found no blocker; its four low findings are closed, and the corrected 537-test Flutter matrix plus the backend and source-contract suites pass locally. Packaging and exact-head CI are next. Do not prepare another production opening. Gate 4 is not next. The maintained owner checklist is `docs/CHANTS_LAUNCH_COMMAND_CENTER.html`.
- **Live rollout hold:** Production has exactly 46 non-scheduled Node 22 Functions from one reviewed source build. The two report migrations completed without overlap; 196 repair checkpoints and audits have zero projection mismatch. Maintenance generation 9 is active with destructive workers false. All four Gate 3 windows had zero backend requests, zero severity errors, and no Auth or collection-count change, so the core journeys remain unverified rather than passed. The client startup and policy-recovery corrections are local, physically presentation-verified, locally verified, and not yet merged. The Firebase app-media bucket remains absent. Scheduler API is enabled as a recorded Firebase CLI side effect, but no scheduled Function or job exists.
- **Safe preparation in parallel:** `scripts/check-device-readiness.mjs` and the existing private command-center guide now provide local inventory and per-platform walkthrough capture. Focused source/logic evidence is recorded locally; use the preparation PR receipt for exact-head CI. Browser visual proof remains open. No runtime feature or live service changes are included.
- Complete remaining provider dashboards and credentials, Android association, deployed Apple association, production signing, policy, observed cost and abuse controls, and the combined iOS and Android V1 device walkthrough. Feature source at `e8f2591` compiles and passes identity inspection on both clean runners.
- Configured-device catalogue inspection for the source-complete and production-exact 20-club catalogue. Transfer-sensitive roster review, named-project identity preflight, guarded Arsenal reconciliation, Leeds canary, six-group widening, and final all-club readback are complete.
- Saved Matchday Songbook airplane-mode device walk; its iOS client compilation now passes.
- Camera and library permission, upload recovery, playback, public sharing, Following, activity, threaded conversation, moderation, block, and deletion device walks.
- Content policy, privacy, terms, association deployment, store destinations, URL-signing IAM, cleanup deployment, App Check release-traffic observation and enforcement, observed alert and billing delivery, deployed parity, signing, and store assets.
- Store launch prep.

---

## Phase 1: Private v1 sign-off

Claude reviewed PRs 22-26 through fe0ea92, then closed F1-F5 at `2d362a2` and reviewed Call-Ups staged tree `91213af707f4c6dc4bd3d3334b7adaea35a1ea0b`. Later club copy and platform fixtures merged through PR 28; no independent re-review of those fixtures is implied. Claude reviewed PR 29 preparation through `5280c3a` with no code/merge blocker. Its documentation/comment closure is exact-head green and merged as recorded above. Core proof now precedes private media activation; provider/domain/signing, operations and configured-device evidence precede release. Prior optional Living Songbook findings remain in the readiness record.

Run on device, confirm font weights render bold and heavy, walk all core flows and states.

**Trigger to exit:** Andrew confirms the current interface reads correctly and no flow is broken. The exploratory Home redesign remains a separate product choice.

---

## Phase 2: Stable identity and seed

The repository uses explicit seeded chant IDs and freezes Arsenal to its expected legacy IDs. The owner review is complete, and source contains all 20 approved clubs. The 2026-08-30 refresh compares 623 raw official-feed rows to 622 reviewed rows after 17 display aliases and three named Arsenal membership overrides. Named-project preflight is clean for all 192 targets. PR 23 merged the reviewed controls after all eight exact-head CI jobs passed. The bounded production sequence then created Arsenal's four additions, reconciled all 12 chants, removed only the three exact zero-reference departures, and finished with one matching team, 28 matching players, 12 matching chants, and zero missing, mismatching, or orphan rows.

The prepared catalogue has 192 chants in total, including 180 across the 19 new files. Every new club clears the three-chant floor, and larger supported songbooks were retained instead of applying the old five-chant cap. Content-integrity remains fail-closed: correct source JSON rather than improvising a lyric, player, context claim, or evidence link during rollout.

The stable-ID and current-roster gates apply to live data writes, not only the completed source catalogue. Arsenal reconciliation and Leeds canary passed their separate hold points. The approved six-group widening sequence then completed with exact readback after every group. Final all-club verification reports all 192 chant identities safe, 20 matching teams, 622 matching players, 192 matching chants, and zero missing, mismatch, or orphan. The remaining seed gate is configured-device catalogue inspection, not another write.

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
18. **Stage launch services without premature enforcement.** Merged in source. Exact Apple association, complete native Crashlytics delivery hooks, daily bounded abandoned-draft cleanup, capped aggregate stale-job monitoring, and CI contract checks exist. Firebase Auth authorizes both planned domains. Gate 0 found both App Check provider configurations and two enabled privacy-safe operational policies, and Gate 1 refreshed the budget. Product enforcement, deployment, observed alert delivery, Android signing identity, and device proof remain open.

The original Songbook and Chant Lab boundary remains in `docs/decisions/004-songbook-and-chant-lab.md`; creator-platform decisions are 017 through 022 and the active post-merge documentation contract is `docs/CHANGE_SPEC.md`. Beat-synced karaoke editing, licensed backing tracks, duet or remix tools, payouts, scheduled challenges, automated large-scale media screening, and personalized recommendation models remain later work.

The complete reviewed V1 source stack is merged at `e8f2591`. Exact-main run `33256843751` passes all eight jobs, including both native builds and 165 Java-backed Firestore and Storage cases. Provider setup, production signing, association deployment, policy, observed telemetry and alert delivery, and the combined device walkthrough remain gates that turn source confidence into release sign-off.

**Trigger to exit:** The final minor closure is exact-head green; both native clients still compile; recording or choosing, upload recovery, approval, playback, sharing, Following, comments, activity, moderation, blocking, deletion, authentication, verification, and offline Songbook pass the combined device walk; provenance and promotion rules still work end to end; and public share-out never produces a broken destination.

---

## Phase 4: Public launch prep

- Apple Developer and Google Play accounts, store listings and data-safety declarations, app icon and branding. Keep the existing 17+ in-app minimum distinct from each store's questionnaire-derived rating.
- Package and run exact-head review of the corrected [launch policy pack](LAUNCH_POLICY_PACK.md), then close its remaining legal, support-mailbox delivery, child-safety, retention-operation, store-disclosure, and deployment holds. The approved virtual business correspondence address, actual signed-out access to six public routes, matching in-app documents, `v2` Terms and Community Rules acceptance, no-login deletion instructions, and strengthened deletion source exist but are not published. The age rule remains 17+.
- Review and package the responsive public landing-page source, then publish it only with the compatible Hosting rollout. It explains Songbook, Chant Lab, Stage, and their trust boundaries, but it has no store buttons, social links, signup form, tracking, or live-domain evidence yet.
- Prove real-device App Check traffic and obtain separate enforcement-target and rollback approval; elapsed time alone does not authorize enforcement.

**Trigger to launch:** All of the above complete and Phase 3 signed off.

### Automated media-cleanup monitoring

- **Status/owner:** Planned at Andrew's request on 2026-08-31; Codex scopes and implements after separate Lane 2 approval, Andrew owns operational response. Not built, deployed or assigned a PR number.
- **Placement:** Scope after the first private media/cleanup canary supplies actual delivery and late-upload evidence, before public media widening. It is launch operations work, not a V1.1 user-feature promise. If the manual checks cannot support even the canary safely, bring the scope forward.
- **Outcome:** Reduce Andrew's recurring manual checks without hiding missed events or unprocessed media. The existing monitor covers account and published-media deletion jobs only; deferred pending/attempted/blocked rows and never-persisted events need different evidence.
- **Smallest defensible scope:** Reuse existing telemetry where it works; define a bounded, privacy-safe reconciliation of delivery failures, cleanup state and exact object/draft/grant evidence, including cases with no job row. Name complete scan coverage, pagination/freshness, read/latency/cost budgets, alert owner, deduplication and response. Exhausted or incomplete coverage must say unknown, not healthy. Preserve late-transfer and soft-delete distinctions; retained attempted rows alone must not generate false stale-work alarms.
- **Proof before replacing manual checks:** Inject a missed/pre-persistence event, stuck/blocked work, late object arrival, permission/read failure and scan-budget exhaustion; show actionable detection and no false alarm on legitimately retained evidence. Verify real alert delivery during the approved canary.
- **Out of scope:** Automatic object deletion, historical replay, TTL/retention changes, broad bucket scans without a budget, a new monitoring platform or spending increase. Any necessary expansion gets its own approval.
- **Until then:** The runbook's attended delivery/object checks stay active. Public media needs implemented and observed automation or an explicitly accepted, demonstrated sustainable manual owner/cadence. Planning this block does not satisfy that gate.

---

## Cross-cutting risks (unchanged, tracked with triggers)

### Moderation and content safety (existential, addressed from v1)
Shipped in source: versioned Terms and Community Rules acceptance, real signed-out policy/help navigation, stale-gate support/deletion/sign-out, complete child-safety directions, an approved virtual business correspondence address, server-authoritative report and feedback admission, atomic report and feedback budgets, remove, ban, unban, fail-safe auto-hide, audit log, authored-content deletion, exact performance-media cleanup, and private verified external deletion dispatch. Open: corrected-range review, configuration and publication evidence, plus the policy pack's legal, child-safety operations, support delivery, retention-operation, store, and deployment holds. Trigger for the fuller moderation console: accepted submission volume outgrows basic remove-and-ban.

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

## Approved V1 addition: Chant Call-Ups

Andrew approved the bounded first slice on 2026-08-30 local time. A single club-page spotlight invites a chant for a currently listed player with no visible chant for that club in Chants, using only the existing complete live club streams. The copy names the club; prior-club songs remain discoverable in player browse. The fan can choose another eligible player locally and open the existing prefilled writing form. Successful creation leads to the submitted player's Chant Lab, or club Chant Lab if the subject changed. Cache, pending writes, failed or closed streams never authorize the absence claim.

This is a creation invitation, not a contest or a claim that no stadium song exists. No automatic winner, prize, paid promotion, exposure guarantee or separate backend. Implementation and subsequent corrections are merged through PR 28; exact-main CI is green. The independent review covers the earlier staged tree, not every later fixture/reference correction. Configured-device proof remains open. The completed contract is in Git history at `42f20dc6`; scoped reasoning remains in `docs/changes/2026-08-31-v1-chant-call-ups.md`. The active spec now owns rollout preparation.

Current listed membership is only as accurate as the reviewed catalogue.

## V1.1 candidate backlog

These ideas are pinned for deliberate V1.1 evaluation. They are not launch promises or hidden V1 scope. Each begins with a small slice and has a trigger for deciding whether it deserves a full build.

### 1. Broader Chant Call-Ups

- **Purpose:** Help worthwhile player ideas reach more supporters after the club-page slice proves useful.
- **Evaluate:** distribution, exposure fairness, repeat creators, meaningful submissions and subsequent sharing or real-world evidence.
- **Keep out without a separate decision:** prizes, paid placement, automatic winners and a contest backend.
- **Decision trigger:** reliable catalogue maintenance and actual usage justify going beyond the existing club-page invitation.

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

### 9. API-Football Matchday Songbook foundation

- **Status:** Approved for V1.1 by Andrew on 2 September 2026 and queued behind V1 release closure. The active V1 Lane 3 rollout specification remains the only active change specification, so this work must not be mixed into the production-rollout branch. Before implementation, promote this approved scope into the single active `docs/CHANGE_SPEC.md` and re-check any material contract change.
- **Purpose:** Make the saved Songbook timely on matchday without turning Chants into another scores app.
- **Provider boundary:** Use the existing API-Football Pro access through a Chants-specific server-side key and environment. Never expose the provider credential to either client.
- **Smallest first slice:** Cache the next fixture, opponent, and kickoff for a followed club, then present that context above the already saved club Songbook. Missing or stale fixture data must fail quietly back to the normal offline-capable Songbook.
- **Success signal:** supporters open saved chants near kickoff and return to their club Songbook without depending on live connectivity at the ground.
- **Keep out initially:** live scores, timelines, tables, odds, predictions, automatic notifications, vendor player photos or club badges, and any provider data whose display or redistribution terms have not been verified.
- **Implementation gates:** document club identifier reconciliation, cache freshness, quota ceilings, provider outage behavior, deletion and retention boundaries, monitoring, and a no-provider fallback before enabling the integration.

### 10. API-Football roster watch

- **Status:** Pinned for V1.1 as a separate follow-on block. It is intentionally outside the approved Matchday Songbook foundation and requires its own Lane 2 specification and approval.
- **Purpose:** Reduce transfer-window cleanup while preserving human editorial judgment over chant history and currentness.
- **Smallest first slice:** Produce an operator-only advisory when a tracked player disappears from a club squad or appears in a transfer result. Link the alert to the affected chant records for manual review.
- **Safety boundary:** Never auto-delete, auto-hide, demote, relabel, or rewrite a chant from provider data. Historic songs for departed players remain archive candidates, and every public change stays an explicit operator action with an audit trail.
- **Success signal:** fewer stale current-player rows after operator review, with no incorrect automated content mutation.
- **Keep out initially:** automatic roster reconciliation, public transfer news, speculative transfer alerts, lineup-derived chant status, and player media.
- **Implementation gates:** verify squad and transfer coverage, identifier stability, false-positive handling, rate limits, cost, manual dismissal and recheck behavior, and the operator queue's privacy and audit contract.

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

- **DONE IN SOURCE** Arsenal remains the showcase seed with its frozen legacy-compatible IDs.
- **DONE IN SOURCE** All 19 remaining approved Premier League clubs have reviewed JSON. The new files contain 180 chants, all clubs clear the three-chant floor, and larger verified collections remain intact.
- **DONE IN SOURCE** Every new chant carries an era, review date, owner-verification marker, and source URL. Historic people remain club-linked rather than entering current squads. Current player chants must match the dated roster snapshot. The seed projection publishes `origin: alreadySung` but excludes offline review metadata.
  - Source verification: complete as of 2026-08-30.
  - Live status: all 20 clubs are exact in production. Configured-device catalogue inspection remains.
- **DONE IN SOURCE, NOT PUBLISHED** Replace the placeholder with versioned Terms and Community Rules, complete urgent child-safety directions, and separate Privacy. Exact-head review, compatible deployment, and device acceptance remain.

### Polish and ship

- **TODO** Access-control verification with a second non-operator account. Confirm a normal user cannot open moderation, cannot edit or remove others' content, and cannot query hidden or removed chants.
- **TODO** Device walk of degraded states and enforcement: empty, loading, and error states on every screen; flagged content actually hidden at threshold; rate limits firing on rapid submission; fail-safe defaults for new accounts.
- **TODO** Final copy and em-dash sweep across the redesigned screens.

### Legal, store, and launch mechanics

- **DONE IN SOURCE, NOT DEPLOYED** The root public landing page plus Privacy, Terms, Community, Rights, Delete account, and Support exist in Hosting source. The six trust routes are reachable from the signed-out app welcome and the root footer. Publication and signed-out production readback remain.
- **TODO** Apple Developer account ($99) and Google Play Developer account ($25).
- **TODO** Wire final app icon; set 17+ age rating.
- **TODO** Store listings, screenshots, and data-safety / app-privacy forms.
- **IN PROGRESS** App Check production: iOS App Attest and Android Play Integrity configurations exist, while Firestore and Authentication enforcement remain off. Observe one to two weeks of valid release traffic from trusted signing identities, then approve enforcement separately. DeviceCheck fallback still requires an approved private-key path.
- **TODO** Production build, signing, and deploy.

---

## Launch and marketing plan

### Pre-launch (start now, needs weeks of runway)

- **One-sentence pitch**, used everywhere (store subtitle, site headline, social bios): *Chants is the songbook of the terraces and the workshop for what gets sung next.*
- **Build in public** on one platform, 2 to 3 posts a week. Primary platform is the one where football fans actually gather, likely X or TikTok. `@chantsapp` is the preferred reservation candidate because it is readable, product-specific, and does not depend on punctuation that platforms handle differently. Reserve it consistently across Instagram, TikTok, X, and YouTube only if it remains available, and keep every handle off public product copy until the accounts are confirmed.
- **Keep the V1 site data-free.** Use the public explanation, support route, and owned social accounts before adding a mailing list. A future waitlist needs a separately approved privacy, delivery, retention, and abuse boundary.
- **Join five watering holes** as a real member, weeks before launch: Arsenal and other club subreddits, football fan Twitter, terrace-culture and fan forums. Be helpful, never spam, so at launch you are a member sharing something, not a stranger advertising.
- **Line up 5 to 10 soft-launch testers** who will try it early, give honest feedback, and leave a day-one rating.
- **Assemble a launch kit** in one folder: logo, 3 to 5 clean screenshots, the one-sentence pitch, a 100-word description, and the founder story in three sentences (English-born Arsenal supporter building the songbook the terraces never had).

### Launch day

- Post first to the confirmed owned social accounts, in the morning, with the live store destination.
- Post to the five watering holes, tailored to each, leading with the story and the problem, not the feature list.
- Launch on Product Hunt (Tuesday to Thursday), and Show HN if the technical angle fits.
- Post the LinkedIn launch piece the same day, only once the app is live with a working store link.
- Replace the coming-soon status with verified App Store and Play buttons only after both public listing URLs work.
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
- Content policy text. DONE IN SOURCE, NOT PUBLISHED. The versioned Terms and Community Rules replace the placeholder, Privacy stays separate, and urgent child-safety directions exist in app and web source. Corrected-range review, deployment, and device proof remain.

Priority note: exact-head policy review, publication, and the live-device enforcement walk remain before a clean pre-v1 compliance pass.
