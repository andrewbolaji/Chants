# Change spec: V1 launch presentation polish

**Status: Approved for packaging and gated rollout.** Andrew approved `V1 Chants public landing page spec`, directly approved a final launch-presentation pass covering the app entry, policy gate, and public landing page, granted visual acceptance, and authorized one package, push, exact-head clean CI, independent review, and then public deployment and domain connection on 1 September 2026.

**Owner:** Andrew, through Thunderriver Tech LLC

**Lane:** 2 for source and packaging; 3 for the separately gated live rollout

**Baseline:** PR 30 correction head `75e1bc32dd277a47a829b636f739ea18856c8985`, with all eight jobs green in run `33487936863`

**Source authority:** implementation, local preview, verification, durable records, one commit, push, pull request, exact-head clean CI, and an independent review handoff.

**Production authority:** after exact-head clean CI and independent review return without an unresolved blocker, publish the reviewed Firebase Hosting source, connect the registered `chantsfc.com` domain using only the exact records Firebase supplies, and read back the live routes. Merge, store publication, analytics, account collection, unrelated DNS edits, backend deployment, and any other production change remain outside this authority.

## Outcome

Give the first public and in-app moments one coherent Chants identity while preserving every existing authority, trust, and deep-link boundary.

The page should make the product understandable in one visit:

1. Chants is the songbook of the terraces and the workshop for what gets sung next.
2. Songbook helps fans learn and save real matchday chants.
3. Chant Lab gives supporters a place to write, rank, and improve new ideas without presenting popularity as stadium proof.
4. Stage lets creators publish moderated short performances around a chant, with popularity distinct from Terrace Proven status.
5. The app is coming soon. No store availability, user count, testimonial, licensing relationship, or launch date is invented.

## Scope

### Included

- A responsive root landing page under `hosting/index.html` using the approved Chants visual language.
- Product-specific hero, positioning, Songbook, Chant Lab, Stage, trust, and launch-status copy.
- An honest app-preview composition built from existing approved brand assets and interface language.
- Clear links to Privacy, Terms, Community Rules, Rights and takedown, Delete account, Support, and `support@chantsfc.com`.
- Root Open Graph and X metadata using the existing approved Chants preview asset.
- Keyboard-visible focus, semantic headings and landmarks, reduced-motion handling, readable contrast, narrow-layout resilience, and no autoplay.
- Deterministic source tests that protect the root metadata, core product meaning, launch honesty, policy links, and existing Hosting boundaries.
- Interface, decision, execution, and completed-change records.
- A launch-time Flutter brand reveal that carries the static native splash into a short `CHANTS` word reveal without delaying Firebase initialization.
- A native splash color correction so the operating-system frame and Flutter frame do not flash between gray and the app's ink black.
- A redesigned current-policy gate with a loud, unmistakably Chants introduction, calm readable rule text, and the same acceptance, deletion, support, privacy, terms, policy-hub, and sign-out behavior.
- Focused animation, semantics, acceptance, route-access, narrow-layout, and enlarged-text regressions for the two app surfaces.
- A gated post-review Firebase Hosting deployment, exact `chantsfc.com` connection, HTTPS verification, and live readback of the root and public trust routes.

### Excluded

- Any Cloudflare DNS change other than the exact `chantsfc.com` records supplied by Firebase during the approved post-review connection.
- Mailing-list signup, contact forms, cookies, analytics, pixels, advertisements, remote fonts, external JavaScript, or new data collection.
- Live App Store or Google Play buttons before their verified public listing URLs exist.
- Embedded social feeds, account sign-in, app functionality, direct uploads, or web playback outside the existing current-authority share routes.
- New player, club, stadium, supporter, or licensed-media imagery.
- Changes to the meaning of policy copy, the policy version, the 17+ rule, authentication authority, Functions, Firestore, Storage, seed data, public share authority, or media delivery.
- A blocking animation, looping launch movie, audio, video, remote artwork, or new runtime permission.

## Interface contract

- The first viewport names **Chants FC**, leads with `Every chant starts with one voice.`, preserves the canonical product promise, and offers one honest `Coming soon on iOS and Android` status plus a clear `Explore the app` route into the product explanation.
- The public visual frame is a restrained premium app launch, not a Vouch imitation, generic template, radar scene, oversized poster, or grid of interchangeable feature cards. It uses the app's ink black, supporter gold, warm off-white, restrained community coral, local Oswald and Nunito, generous negative space, thin rules, and two club-neutral product devices. The phones show Stage and offline Songbook meaning rather than fake production screenshots or social proof. Reading surfaces remain calm, high contrast, and free of decorative clutter.
- Songbook, Chant Lab, and Stage each have one distinct job and one short truthful explanation.
- `Terrace Proven` means reviewed stadium evidence. `Rising` means community momentum. Performance popularity never proves stadium use.
- The app preview uses CSS-native, club-neutral Stage and Songbook surfaces plus the existing supporter-and-scarf mark at the closing moment. It must not imply a live feed, a real creator, or real popularity metrics.
- Footer trust links stay visible and use the exact existing public routes.
- The page remains useful with images disabled, motion reduced, JavaScript unavailable, or a narrow viewport.
- Native launch remains instant and static. The first Flutter frame continues the same black-and-gold scene, reveals `CHANTS` once, exposes a useful semantic label, and resolves immediately when reduced motion is requested.
- The policy gate leads with `KEEP THE TERRACE LOUD. KEEP IT SAFE.`, states exactly which two documents are being accepted, keeps Privacy separate, and preserves all six pre-acceptance escape and help routes. Long rule copy remains a calm, aligned reading surface below the loud frame.

## Invariants

1. Existing `/chants/**`, `/performances/**`, `/creators/**`, and `/media/performances/**` rewrites are unchanged.
2. Existing policy routes, the Apple association source, and the Android association header configuration remain present and semantically unchanged.
3. The landing page never exposes lyrics, user data, raw Storage paths, private identifiers, or production configuration.
4. No public CTA claims the app can be downloaded until a verified store listing exists.
5. No popularity copy is presented as proof that a chant is sung in a stadium.
6. No new network dependency, tracking, form submission, persistent state, or runtime permission is introduced.
7. Public contact copy uses `support@chantsfc.com`; social handles are omitted until Andrew confirms the accounts are reserved and ready to publish.
8. Policy acceptance still writes only through the existing callable and still advances only when the authoritative profile projection changes.
9. Account deletion and sign out remain usable before acceptance and are disabled only while acceptance is in flight.
10. Launch animation never changes authentication, profile, deletion, or policy-state authority.

## Failure and recovery

| Trigger | Required behavior |
|---|---|
| Brand image fails to load | Product name, promise, structure, and trust links remain readable |
| CSS is unavailable | Semantic document order still explains the product and exposes every public trust route |
| JavaScript is unavailable | The complete landing page still works; JavaScript is not required |
| Viewport is narrow or text is enlarged | Content reflows into one column with no hidden action or horizontal page scroll |
| Store URL is not verified | Show launch status as text, not a dead or guessed store link |
| Hosting deployment or DNS is absent | Record source completion only; do not call `chantsfc.com` live until the post-review rollout succeeds |
| A future homepage edit removes a trust link or changes product meaning | Deterministic source contract fails before handoff |
| Reduced motion is enabled | App launch and web decoration render their final state without animation |
| Policy acceptance fails | Keep the gate usable, preserve every route, and show the existing honest retry message |
| Policy copy is enlarged or the viewport is 320 pixels wide | Keep every document and account action reachable with no overflow or hidden agreement control |

## Verification

Evidence must be capable of failing against the placeholder page:

1. A root Hosting test requires the canonical title, description, Open Graph and X metadata, Songbook, Chant Lab, Stage, trust explanation, launch-status honesty, and all six public trust links.
2. The test rejects guessed store links, positive availability claims, fabricated audience metrics, seeded club names, chant or lyric-shaped illustration copy, popularity-as-stadium-proof copy, forms, remote embeds or resources, autoplay, trackers, and removal of any existing Firebase rewrite or the Apple association source.
3. A local static preview returns the root and representative policy routes successfully.
4. The complete source is inspected at desktop and narrow widths, with keyboard focus, enlarged text, reduced motion, missing-image fallback, and no-script behavior considered. Browser inspection requires an explicitly permitted surface; source and render evidence must not be mislabeled as live publication.
5. `git diff --check`, staged project-memory, writing-style, and governance checks pass.
6. A clean-runner result and independent review without an unresolved blocker are required before the separately gated live deployment.
7. Focused Flutter tests prove the reveal's start, completed, and reduced-motion states and the gate's exact agreement, route, failure, pending, and constrained-layout behavior.
8. Inspected renders cover the landing page at wide and narrow widths and the policy gate at its representative mobile viewport. Semantic assertions protect trust and agreement meaning independently of pixels.

## Rollout and rollback

Package and review the source first. Only after exact-head clean CI and independent review close without an unresolved blocker, publish the static Hosting tree, connect `chantsfc.com` using only Firebase-supplied DNS records, and read back the root, policy routes, Apple association source, Android association response behavior, share routes, and media route behavior. This rollout does not authorize a Functions, Firestore rules, Storage rules, seed, authentication-provider, store, analytics, or unrelated DNS change.

If the root page fails after publication, restore the last reviewed static root without changing rewrites or policy routes, then repair forward. Never use a rollback that removes the public deletion, rights, support, privacy, terms, or community destinations.
