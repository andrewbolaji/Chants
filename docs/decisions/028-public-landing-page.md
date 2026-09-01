# Decision 028: Launch presentation surfaces

- **Status:** Accepted visually and in source; review, exact-head CI, merge, deployment, DNS, and live readback remain separate gates
- **Date:** 2026-09-01
- **Approval:** Andrew approved the V1 Chants public landing page specification.
- **Scope:** Static root Hosting presentation, Flutter launch reveal, native splash continuity, current-policy gate composition, product positioning, trust explanations, local brand assets, responsive behavior, and source verification.

## Context

The canonical origin had a placeholder root while the product had grown into three connected experiences: a reviewed matchday Songbook, a community Chant Lab, and a moderated creator Stage. The native splash ended on a generic gray frame, and the current-policy gate looked like uncomposed copy. Those three first impressions did not express the identity already established in the product. The root also needed to preserve the six public policy and help routes without creating a new user-data system before launch operations are ready.

## Decision

Use one static, no-JavaScript root page to explain the complete Chants product. The first viewport names Chants FC, uses the existing promise, and says the app is coming soon on iOS and Android. Songbook, Chant Lab, and Stage each receive one clear job. A separate trust section states that Terrace Proven is reviewed stadium evidence, Rising is community momentum, and performance views or shares measure reach rather than stadium use.

Build the visual with the existing scarf asset and local app fonts. Apply the locked matchnight direction and `LOUD FRAME, CALM WORDS` discipline through ink black, supporter gold, warm off-white, restrained coral, generous negative space, thin rules, and product-led device composition. Lead with `Every chant starts with one voice.` beside one dominant Stage phone and one supporting offline Songbook phone, then use three spacious product rows and a restrained trust ledger. The globally legible headline keeps `terrace` available as supporting football culture language without making knowledge of its UK standing-area meaning a prerequisite. Use `Explore the app` for the product-explanation action. The phones are CSS-native illustrations using club-neutral interface language, not screenshots or claims about real creators, chants, performances, metrics, testimonials, store listings, or club relationships. Avoid radar rings, generic stadium decoration, giant poster lettering, trendy editorial serif, fake print grit, heavy rotation, and sticker-like action pills. Preserve semantic reading order when CSS or images fail. Keep the six public trust routes and support visible from the root.

The landing page must not inherit another product's exact composition. Chants translates premium app-launch principles through its own dark matchnight palette, supporter gold, Stage performance surface, offline Songbook utility, supporter authorship, and existing type sources.

Continue the same launch vocabulary inside Flutter. The operating-system splash uses ink black. The first Flutter-owned frame reveals `CHANTS` once while Firebase and account gates resolve behind it, but the reveal never owns authority or delays reduced-motion users. The current-policy gate uses a loud football header followed by a calm constrained reading surface. It explicitly names Terms and Community Rules as the accepted documents, keeps Privacy separate, and preserves Help, Support, Delete account, and Sign out before acceptance.

Do not add a waitlist, form, analytics, cookies, advertising, external scripts, remote fonts, guessed store links, embedded social feed, or social handle in this block. A handle can be added only after Andrew confirms ownership and publication intent. A store button can be added only after its exact public listing works.

The root inherits the existing Firebase Hosting tree. It does not alter public chant, performance, creator, or media rewrites; policy pages; the Apple association source; Android association header configuration; backend authority; authentication; media delivery; or the 17+ rule. Source completion is not publication.

## Consequences and alternatives

- The page presents Chants as both matchday utility and supporter creativity platform. It does not reduce the app to either a lyrics archive or a short-video feed.
- Three local font copies add static bytes but avoid third-party requests and preserve the app's existing visual system. Nunito carries display and reading copy, Oswald handles compact signage, and Anton remains available to inherited launch surfaces without driving the public page.
- Reusing the approved scarf mark avoids rights and provenance uncertainty from stock or generated football imagery.
- The two product devices make the app legible before launch without adding image rights, a new dependency, or another visual asset provenance boundary. Their club-neutral CSS composition can evolve with the product and deliberately avoids both generic stadium graphics and unsupported production screenshots.
- The one-shot Flutter reveal adds bounded motion but no new route, permission, network request, or persistence. Reduced motion shows its completed state immediately.
- The policy makeover changes hierarchy and composition, not policy meaning, version, acceptance authority, deletion behavior, or the 17+ rule.
- Brick can identify authored or changing product moments and can provide a restrained decorative accent. Trust meaning is always written and never encoded only by brick, gold, or any other color.
- A static source contract can prove meaning, routes, and exclusions. It cannot prove DNS, HTTPS, live Hosting, rich-card cache behavior, or store availability.
- A waitlist was rejected for V1 because it creates collection, consent, delivery, retention, abuse, and support obligations before the smallest launch page needs them.
- A social embed was rejected because it adds remote code, tracking, failure, moderation, and platform-dependence boundaries.
- Guessed store links and unconfirmed handles were rejected because a dead or unowned destination is worse than honest coming-soon copy.

## Evidence and revisit triggers

Deterministic Node tests cover root metadata, each product lane, trust meaning, launch honesty, all six trust routes, absence of collection, remote resources, fabricated audience metrics, seeded club names, chant or lyric-shaped illustration copy, stadium-proof conflation and store CTAs, the Apple association source, and existing Firebase rewrites. Focused Flutter tests cover reveal timing, reduced motion, semantics, gate meaning, route access, pending and failure behavior, narrow width, and enlarged text. The complete Flutter suite, CI-equivalent analysis, Functions, seed, source contracts, launch-service contracts, staged governance, writing-style controls, and native-project contract pass locally. Local HTTP checks cover the root, all six trust routes, association source, stylesheet, fonts, and preview asset. Desktop, 390-pixel, and 320-pixel browser inspection cover the current public source. Java-backed rules execution, a physical-device pass, independent review, and clean-runner CI remain handoff gates.

The existing square `og-default.png` remains the social-preview source because it is already the app identity asset and introduces no new rights boundary. Its centered scarf/supporter mark survives common center crops. A purpose-built, owned landscape preview should replace it when one is approved and verified across the major preview surfaces.

Revisit when verified public store URLs exist; social ownership is confirmed; a translated page needs a different layout; a real release screenshot is more accurate than the source composition; a measured acquisition need justifies a separately approved signup system; or Hosting architecture and public-route ownership change.
