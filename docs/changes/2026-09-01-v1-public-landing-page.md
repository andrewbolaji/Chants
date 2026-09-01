# V1 launch presentation polish

## Approval and scope

Andrew approved `V1 Chants public landing page spec` and then directly requested the final app-entry, policy-gate, and landing-page presentation pass on 1 September 2026. He subsequently granted visual acceptance and authorized packaging, exact-head CI, independent review, and a gated public Hosting and `chantsfc.com` rollout. This block replaces the static Hosting root placeholder, continues the native splash into a bounded Flutter reveal, and redesigns the existing current-policy gate without changing its meaning or authority. Source packaging remains separate from deployment evidence. The approved rollout does not collect information, add analytics, add store availability, change backend behavior, change the 17+ rule, or authorize an unrelated DNS change.

## Product and interface

The root now explains the full product in one visit:

- Songbook teaches and saves reviewed matchday chants.
- Chant Lab lets supporters write and rank what could be sung next.
- Stage gives moderated short performances a creator and popularity surface.
- Terrace Proven, Rising, and Stage popularity keep distinct meanings.
- Saved Matchday Songbook remains useful when stadium connectivity fails.

The final owner-led pass uses the existing scarf mark and three local app fonts. Nunito carries the main display and reading voice, Oswald handles compact signage, and Anton remains available without dominating the public page. The page is built as a premium product launch rather than a poster, a card catalogue, or an imitation of another app. Ink black, supporter gold, warm off-white, restrained coral, generous negative space, and thin rules lead from `Every chant starts with one voice.` and a believable two-phone product composition into spacious Songbook, Chant Lab, and Stage explanations. The clearer headline keeps the supporter-origin idea without relying on the UK-specific meaning of `terrace`; `Explore the app` replaces the vaguer `Meet Chants` action.

Andrew's refinement requests were evaluated against `docs/DESIGN_DIRECTION.md`, the detailed `LOUD FRAME, CALM WORDS` rules, the V2 and V3 Home concepts, the current Stage and Songbook evidence, and five owner-supplied app-landing references. The references were used for principles only: believable product UI, restrained type, generous spacing, one dominant visual idea, and a clear download-status action. Chants keeps its own matchnight palette, trust language, offline utility, and supporter-creator meaning. Fake social proof, stock football imagery, radar graphics, giant decorative mastheads, heavy rotation, and interchangeable feature cards are absent.

The composition uses product vocabulary without inventing a real creator, video, view count, club relationship, or store listing. It adds no stock, generated, licensed, or remote imagery.

The three Hosting font binaries are mechanical copies of already tracked files under `assets/fonts/`. SHA-256 comparison must confirm each destination is byte-identical to its source before handoff. No new font download or uncertain asset provenance enters the repository.

## App entry and policy gate

The operating-system splash now uses the app's ink black instead of gray. Flutter initializes Firebase and account state behind a one-shot launch surface that reveals `CHANTS`, the scarf mark, and a compact sound signal. Reduced-motion users receive the completed frame immediately. The reveal adds no route, permission, network dependency, persistence, or authority decision.

The current-policy gate now begins with `KEEP THE TERRACE LOUD. KEEP IT SAFE.` and clearly states that Terms and Community Rules are the two accepted documents. Privacy remains a separate notice. Help, Support, Delete account, Sign out, pending acceptance, and failure recovery retain their existing behavior. Long rule copy moves into a calm constrained section beneath the loud frame.

## Public and privacy boundaries

The page requires no JavaScript and adds no form, waitlist, cookie, analytics, advertising, remote font, external script, social embed, or persistent state. The only contact action is the approved support email. Social handles remain absent until ownership is confirmed. Store buttons remain absent until exact public listing URLs work.

Privacy, Terms, Community Rules, Rights and takedown, Delete account, and Support remain visible in the root footer. Existing public chant, performance, creator, and media rewrites, the Apple association source, and the Android association header configuration remain unchanged.

## Verification

- Nine landing-page source tests pass and remain in the clean-runner governance job. The contract requires all three product lanes independently, rejects fabricated audience metrics, seeded club claims, chant or lyric-shaped illustration text, stadium-proof conflation, store CTAs, and remote embeds or resources, and proves representative known-bad mutations are rejected.
- Eight launch-policy source tests pass in the same focused run.
- The local static server returns the root and representative trust routes successfully.
- Semantic DOM inspection confirms one ordered document with a skip link, header, main regions, footer, headings, support link, and all six trust destinations.
- Current same-origin browser inspection covers the premium product hero and representative cream and dark sections at the default desktop viewport. Captures at 390 by 844 and 320 by 780 confirm the product phones, editorial section rhythm, readable type, exact viewport-width geometry, and no horizontal overflow. Physical-device inspection remains before source freeze.
- Visible links have at least a 44 CSS-pixel target height in source. The scarf art remains the only content image, with a written fallback and no new image-rights boundary.
- Focused Flutter verification covers the launch reveal, current-policy gate, and app gate. The complete Flutter suite passes 521 cases, CI-equivalent analysis passes with the non-secret generated-config fixture, Functions pass 230 cases with 24 emulator-only cases pending, seed passes 74 cases, and all 36 device, guide, policy, and landing contracts pass. Staged project memory, writing style, governance, native-project, launch-service, and whitespace checks pass across the 29 intended paths. Java-backed rules execution, independent review, physical-device acceptance, and clean-runner CI are still required before merge. Publication remains separately authorized.

## Owner acceptance and remaining gates

Andrew granted visual acceptance for the final public direction on 1 September 2026. Independent review, one commit, push, exact-head clean-runner CI, merge, gated Hosting deployment, DNS/domain connection, live root and trust-route readback, rich-preview cache verification, and verified store buttons remain separate. The live origin is unchanged until rollout evidence says otherwise.
