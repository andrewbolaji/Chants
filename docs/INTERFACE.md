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
| Browse and club lists | Songbook-first tabs, separate Chant Lab Top and New order, loading, surface-specific empty states, cached and recoverable-error notices, hidden/removed disappearance, and fail-soft player metadata | Preserve reading order, explicit trust words, semantic section headings, stable controls during vote changes, text scaling, and one-handed navigation | `lib/presentation/browse/`, `lib/data/services/chant_browse.dart`, `lib/presentation/shared/empty_state.dart`, `lib/presentation/shared/error_state.dart` |
| Chant card | Show title, who it is for, useful provenance, tune, score, and comments without turning the card into a metadata wall | Entire card target is semantic and tappable; badges cannot rely on color alone | `lib/presentation/shared/chant_card.dart`, `docs/DESIGN_DIRECTION_V2.md` |
| Chant detail | Loud identity header, calm lyrics, context, vote, report, comments, and any safe external evidence action | Long lyrics fall back to left alignment; link purpose is explicit; text scaling and screen readers retain logical order | `lib/presentation/browse/chant_detail_screen.dart`, `docs/DESIGN_DIRECTION_V2.md` |
| Saved Matchday Songbook | Local-first overview, club snapshots, read-only chant detail, explicit refresh and remove, last-refreshed disclosure, UID lock, corrupt and future-version recovery states | Ownership and freshness use words as well as icons; saved detail omits live controls; 390 by 844 and enlarged text remain scrollable and unclipped | `lib/presentation/saved/`, `lib/data/models/saved_songbook.dart`, decision 003 |
| Submission form | Preserve entered work on validation or network failure; distinguish required from optional fields; denied and banned states explain the next action | Every choice has a text label and semantic group; keyboard never hides the active field or submit result | `lib/presentation/submit/submit_chant_screen.dart` |
| Comments and replies | One visible reply level, recoverable failed writes, reporting, blocking, moderation disappearance, and no orphan promotion | Reply context and hierarchy are announced without indentation alone; tap targets and text scale remain usable | `lib/presentation/comments/`, `docs/decisions/002-comment-reply-depth-and-retention.md` |

## Decision log

### 2026-08-22T19:38:09Z Make saved lyrics a timestamped device copy

- **Status:** active
- **Surface and user problem:** Fans need lyrics at a crowded ground where connectivity is unreliable, but incidental Firestore cache behavior cannot support a clear offline promise.
- **Decision:** Home exposes one signed-in Matchday Songbook. Team and live chant detail save explicit UID-scoped device snapshots. Saved overview, club, and detail routes read locally first, label the copy and refresh date, omit live social and media actions, and require explicit refresh or removal.
- **Why:** The feature supports the app's sharpest matchday job without turning favorites into another cloud product or implying stale counters and conversation are live.
- **Alternatives considered:** Generic cloud favorites, which do not prove lyrics are present offline; Firestore cache, which is incidental and lifecycle-unclear; background downloads, which add scheduling and consent surface before demand is proven.
- **Required states:** Loading, empty, populated, individually saved, saved with club, cache-disabled save, busy, refresh failure with retained copy, zero-item refreshed club, corrupt, unsupported version, UID mismatch, removal confirmation, and account-deletion cleanup.
- **Accessibility/responsive impact:** Bookmark ownership and freshness are explicit text and semantics. Destructive actions require confirmation. Read-only detail follows the live lyric hierarchy without vote, comment, report, evidence, or media affordances. The overview and detail goldens pass at 390 by 844, and the overview passes at 1.6x text.
- **Implementation evidence:** The approved Lane 2 implementation, focused widget and persistence tests, deliberate reconstruction red check, and two inspected goldens are recorded in `docs/changes/2026-08-22-saved-matchday-songbook.md`. Clean-runner CI and the live airplane-mode device walk remain pending.
- **Revisit when:** Users expect cross-device sync, snapshot volume approaches the 2 MiB or 500-ID boundary, moderation requires online revocation stronger than refresh, or offline audio and video are separately approved.
- **Related:** `docs/decisions/003-saved-matchday-songbook-offline-v1.md`, `docs/CHANGE_SPEC.md`

### 2026-08-22T00:00:35Z Separate Songbook truth from Chant Lab creativity

- **Status:** active
- **Surface and user problem:** Club, player, submit, and chant-detail flows need to welcome new and funny chant ideas without making the trusted archive feel unreliable.
- **Decision:** Club and player journeys present Terrace Proven content as the Songbook and community submissions as Chant Lab. Chant Lab supports Top and New order, plus a Rising signal that never implies verification. Submission requires the fan to choose Already sung or I made this. An evidence link is optional for posting and required before a user submission can become Terrace Proven.
- **Why:** One mixed ranked list asks a single score to represent both terrace truth and entertainment. Separate labels let the archive stay credible while giving creation a visible competitive home.
- **Alternatives considered:** Archive only, which suppresses the product's creator loop; one undifferentiated feed, which blurs provenance; a TikTok-style video feed, which makes media infrastructure and moderation the product before the archive is proven.
- **Required states:** Songbook and Chant Lab loading, empty, partial, error, denied, hidden/removed, offline, and populated states; Top and New order in Chant Lab; no-evidence and dead-link states; player-with-no-chant creation prompt; successful and failed origin-aware submission.
- **Accessibility/responsive impact:** Songbook versus Chant Lab and Proven versus Rising must use words and semantics, not color alone. Nested filters must remain usable at narrow widths and with enlarged text. External evidence actions state that they open another app or browser.
- **Implementation evidence:** Product direction was approved by Andrew on 2026-08-21. The provenance slice and separate browse hierarchy were approved and implemented in source on 2026-08-22. Team and Player routes now open on Songbook, place only community work in Chant Lab, retain stable Top and Songbook survivor order, expose New separately, explain that Rising is early support rather than proof, and keep the last usable cards through a later stream error. Player metadata failure is inline and never erases chants. Team Songbook and Chant Lab goldens at 390 by 844, an enlarged-text route test, stream-driven widget tests, and pure ranking tests retain the interface boundary. Live-device inspection and PR review remain pending.
- **Revisit when:** Closed-beta users cannot find one of the two surfaces, community volume is too low for Top and New to be useful, or users consistently misunderstand evidence and verification.
- **Related:** `docs/decisions/004-songbook-and-chant-lab.md`, `docs/ROADMAP.md`

## Open interface questions

None. Exact microcopy and visual treatment remain implementation details to verify in the dedicated change block.
