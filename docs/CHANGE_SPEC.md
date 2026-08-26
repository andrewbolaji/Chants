# Change spec: V1 Home hierarchy refresh

**Status:** Implemented and locally verified; packaging and clean-runner CI pending
**Updated:** 2026-08-26
**Risk lane:** Lane 1, bounded client presentation and deterministic visual evidence
**Base:** Locally stacked above the completed V1 core-journey interface-readiness block on `codex/framework-ui-readiness`
**Approval:** Andrew selected the refined redesign direction and explicitly directed Codex to implement it, make the typography and sizing judgment, balance fun with basic clarity, and complete one last visual-potential pass using Vouch only as a modern layout reference on 2026-08-26.

## Outcome

- **Problem:** Current Home is coherent and usable, but it reads mainly as a catalogue. It does not immediately express the product's three return reasons: matchday utility, trusted Terrace Proven material, and community creativity in Chant Lab.
- **Desired behavior:** Home keeps the existing routes and data authority while presenting a compact fan-voiced header, clearer search, prominent Matchday Songbook utility, simple Premier League entry, and separate Terrace Proven and Chant Lab previews. Type, spacing, and ornament remain disciplined enough for a basic utility app.
- **Non-goals:** Persistent bottom navigation, a global route rewrite, a global design-system replacement, a new feed query, pagination, hosted media, a generic submit route, a View all destination, schema or repository changes, Firebase rules or Functions, seed work, dependency changes, deployment, signing, or release.
- **Review boundary:** `lib/presentation/home/home_screen.dart`, Home-mode presentation in `lib/presentation/browse/discovery_section.dart`, a narrowly optional Home presentation mode in shared chant cards, one color token if required, focused widget and golden evidence, interface memory, execution, and scoped rationale.

## Acceptance criteria and invariants

1. Home uses existing `discoveryProvider`, `allTeamsProvider`, `authStateProvider`, profile stream, named routes, and current-live chant stream. No network query, repository, authorization, or persistence contract changes.
2. The title and chant names use the condensed display face. Search and explanatory copy use the legible UI face. Monospace is limited to short labels and metadata. Lyrics remain calm and readable.
3. The representative normal-text scale is approximately: Home title 30 to 32, chant preview title 19 to 21, utility title 18 to 20, section label 11 to 13, body and search 14 to 16, metadata 10 to 12.
4. Spacing uses existing tokens, aligned 16-pixel primary page insets, 12 to 16-pixel content rhythm, and at least 44-pixel interactive targets.
5. Visual personality comes from the type voices, warm ink and gold palette, one restrained community accent, and the existing Terrace Proven badge. Cards and ordinary navigation remain flat, calm, and readable.
6. Signed-in Home exposes Matchday Songbook with honest device-local and offline wording. Signed-out behavior remains readable and never exposes an unavailable saved action.
7. Premier League remains the one obvious route to clubs and preserves the exact named-route argument contract.
8. When not searching, Home separates current discovery results into Terrace Proven and Chant Lab previews without changing each chant's status or trust meaning. No community score or Rising label implies verification.
9. When searching, Home keeps one combined result list across title, lyrics, tune, and club name. Empty, loading, initial error, current-live permission denial, cache authority, and retry behavior remain intact.
10. There is no bottom navigation, View all action, or global Add action. The selected concept's unsupported controls do not enter runtime.
11. The account and operator controls retain their routes, labels, and authorization behavior. Account deletion lifecycle behavior remains byte-for-byte unchanged.
12. Home and its first meaningful scroll segment render without overflow at 390 by 844 with normal text. At 1.8x text, search, utility routes, section labels, and chant previews remain reachable and unclipped through scrolling.
13. Primary controls have stable labels and logical reading order. Meaning is not conveyed by color alone.
14. Focused Home, discovery authority, saved entry, and golden tests pass before the complete Flutter suite and scoped analysis.
15. The implementation receives an inspected updated Home golden, formatter check, governance checks, ownership check, and scoped rationale. Native device sign-off remains a later release gate.

## Design

- **Selected direction:** V2 defines the product structure in `docs/mockups/chants-home-redesign-concept-v2.png`; the Vouch-informed but football-specific final polish reference is `docs/mockups/chants-home-redesign-concept-v3.png`.
- **Runtime adaptation:** The mockup is a hierarchy and typography reference, not a pixel-copy contract. Fixture-only counts become truthful generic copy unless current local state is already available without adding load or failure complexity.
- **Home header:** A slightly larger `CHANTS` title, quiet `THE TERRACES, IN YOUR POCKET.` line, and existing account and operator controls.
- **Utilities:** Compact outlined Matchday Songbook card when signed in, followed by a calm raised Premier League card.
- **Content:** Gold-accented Terrace Proven heading and restrained community-accented Chant Lab heading. Each group shows a small preview set from the already-fetched shuffled discovery result. Search restores the existing combined result behavior.
- **Empty community state:** If there is trusted material but no community idea in the current result, Home may point to the real Premier League browse route so the fan can choose a club. It must not invent a teamless submission route.
- **Shared card adaptation:** A Home-only emphasis option may adjust title size, padding, and margins without changing card semantics, vote authority, route arguments, or other screens.

## Failure and abuse analysis

| Condition | Expected behavior | Evidence |
|---|---|---|
| Discovery loading | Header and utility routes remain stable; one progress state appears in content | Widget state test |
| Discovery initial error | Real Try again action remains; no stale authority is implied | Widget test |
| One trust group absent | The present group remains useful; absent group copy is honest and routes only to a real destination | Widget test |
| Permission denial or current absence | Existing live wrapper removes the stale card | Inherited authority test |
| Cache-only live value | Card remains readable; vote stays disabled | Inherited authority test |
| Signed out | Songbook utility is absent; browse and search remain | Widget test |
| Enlarged text | Page scrolls; no horizontal overflow or hidden route | 390 by 844 at 1.8x test |
| Rapid shuffle or route tap | Existing provider invalidation and Navigator behavior apply; no new server mutation occurs | Existing and focused interaction tests |

## Performance and cost

- No additional Firestore read, listener, Function, or persistent file access is approved.
- Grouping is one linear pass over the already-fetched discovery list, bounded by the existing response.
- Home renders at most a small preview from each trust group before search. Search retains the existing result cap.
- Added visual tests must remain proportionate and use deterministic fixtures.

## Rollout and recovery

- No migration or deployment is authorized.
- Presentation changes can be reverted without data work.
- Healthy source evidence is focused and complete Flutter green, clean analysis, inspected golden, governance checks, and later native walkthrough approval.
- If the Home hierarchy confuses trust meaning or hides a current route, revert the Home presentation while retaining the preceding readiness corrections.

## Verification plan

| Claim | Check | Expected evidence |
|---|---|---|
| Existing routes remain | Tap Songbook, Premier League, account menu, and preview chant under test | Exact route name and arguments |
| Trust sections are honest | Fixture includes canonical and community chants | Correct headings, badges, order, and no View all or bottom navigation |
| Search remains broad and clearable | Query title, team, tune, and no result | Combined results, stable clear label, utility suppression, truthful empty state |
| Responsive hierarchy | Home at 390 by 844 normal and 1.8x | No exception or overflow; actions reachable by scroll |
| Authority is unchanged | Existing discovery live-authority suite | Permission denial removal and cache-disabled vote still pass |
| Whole client remains intact | `flutter test --no-pub` and CI-equivalent scoped analysis | Complete pass |
| Framework remains intact | Memory, writing, YAML, formatting, diff, and ownership checks | Pass with no backend, rules, seed, dependency, native, or owner-file change |

## Open decisions

- The bounded Home hierarchy direction is approved, including Codex's final typography and spacing judgment.
- The final preview count is one Terrace Proven chant and one Chant Lab idea. This keeps both meanings legible in the first meaningful scroll segment while search remains the complete discovery surface.
- Persistent global navigation remains deferred. It needs a later route and back-stack specification if product evidence supports it.
