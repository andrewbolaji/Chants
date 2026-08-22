# Interface memory

This is the current design contract and decision history for Chants. Read the relevant section before UI work so new screens extend the existing product instead of inventing another visual or interaction system.

## Current interface contract

- **Primary users and context:** Premier League supporters, from casual fans to regular matchgoers, using a phone at home, in the pub, while travelling, or at a crowded ground. The interface must work for a first-time fan without explaining football-product jargon.
- **Experience principles:** Find, learn, save, or add a chant in seconds. Keep archive truth distinct from community creativity. Use one obvious placement and action for each job. Let the frame carry personality while lyrics and forms remain calm and readable.
- **Design-system source:** `lib/app/colors.dart`, `lib/app/theme.dart`, `lib/app/spacing.dart`, `lib/presentation/shared/`, and `docs/DESIGN_DIRECTION_V2.md`.
- **Supported viewports/platforms:** Mobile iOS and Android. The current representative golden viewport is 390 by 844; platform behavior still requires a live-device walk.
- **Accessibility target:** WCAG AA color contrast, semantic controls and headings, minimum comfortable touch targets, text-scaling resilience, clear focus and validation, no meaning conveyed only through color, and motion that never blocks reading.
- **Content voice:** Fan-written, plain, warm, and witty. Never corporate or preachy. Use Songbook, Chant Lab, Rising, and Terrace Proven consistently. Never describe community work as fake.
- **Evidence surfaces:** Widget tests, targeted goldens under `test/presentation/**/goldens/`, runtime console inspection, and the release-device walk in `docs/CHANGE_SPEC.md`.

## State and interaction patterns

| Pattern or component | Required states/behavior | Accessibility and responsive rules | Source/evidence |
|---|---|---|---|
| Browse and club lists | Loading, empty, populated, error, hidden/removed item disappearance, and offline behavior when the surface promises offline access | Preserve reading order, semantic section headings, text scaling, and one-handed navigation | `lib/presentation/browse/`, `lib/presentation/shared/empty_state.dart`, `lib/presentation/shared/error_state.dart` |
| Chant card | Show title, who it is for, useful provenance, tune, score, and comments without turning the card into a metadata wall | Entire card target is semantic and tappable; badges cannot rely on color alone | `lib/presentation/shared/chant_card.dart`, `docs/DESIGN_DIRECTION_V2.md` |
| Chant detail | Loud identity header, calm lyrics, context, vote, report, comments, and any safe external evidence action | Long lyrics fall back to left alignment; link purpose is explicit; text scaling and screen readers retain logical order | `lib/presentation/browse/chant_detail_screen.dart`, `docs/DESIGN_DIRECTION_V2.md` |
| Submission form | Preserve entered work on validation or network failure; distinguish required from optional fields; denied and banned states explain the next action | Every choice has a text label and semantic group; keyboard never hides the active field or submit result | `lib/presentation/submit/submit_chant_screen.dart` |
| Comments and replies | One visible reply level, recoverable failed writes, reporting, blocking, moderation disappearance, and no orphan promotion | Reply context and hierarchy are announced without indentation alone; tap targets and text scale remain usable | `lib/presentation/comments/`, `docs/decisions/002-comment-reply-depth-and-retention.md` |

## Decision log

### 2026-08-22T00:00:35Z Separate Songbook truth from Chant Lab creativity

- **Status:** active
- **Surface and user problem:** Club, player, submit, and chant-detail flows need to welcome new and funny chant ideas without making the trusted archive feel unreliable.
- **Decision:** Club and player journeys present Terrace Proven content as the Songbook and community submissions as Chant Lab. Chant Lab supports Top and New order, plus a Rising signal that never implies verification. Submission requires the fan to choose Already sung or I made this. An evidence link is optional for posting and required before a user submission can become Terrace Proven.
- **Why:** One mixed ranked list asks a single score to represent both terrace truth and entertainment. Separate labels let the archive stay credible while giving creation a visible competitive home.
- **Alternatives considered:** Archive only, which suppresses the product's creator loop; one undifferentiated feed, which blurs provenance; a TikTok-style video feed, which makes media infrastructure and moderation the product before the archive is proven.
- **Required states:** Songbook and Chant Lab loading, empty, partial, error, denied, hidden/removed, offline, and populated states; Top and New order in Chant Lab; no-evidence and dead-link states; player-with-no-chant creation prompt; successful and failed origin-aware submission.
- **Accessibility/responsive impact:** Songbook versus Chant Lab and Proven versus Rising must use words and semantics, not color alone. Nested filters must remain usable at narrow widths and with enlarged text. External evidence actions state that they open another app or browser.
- **Implementation evidence:** Product direction approved by Andrew on 2026-08-21. Implementation has not started; the later Lane 2 change requires its own approved `docs/CHANGE_SPEC.md`, tests, screenshots, and device inspection.
- **Revisit when:** Closed-beta users cannot find one of the two surfaces, community volume is too low for Top and New to be useful, or users consistently misunderstand evidence and verification.
- **Related:** `docs/decisions/004-songbook-and-chant-lab.md`, `docs/ROADMAP.md`

## Open interface questions

None. Exact microcopy and visual treatment remain implementation details to verify in the dedicated change block.
