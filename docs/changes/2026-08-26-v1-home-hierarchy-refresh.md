# Change implementation rationale: V1 Home hierarchy refresh

> **Document contract:** This file explains the bounded Home change approved on 2026-08-26. It does not approve persistent navigation, new discovery queries, a teamless submission flow, backend work, seed work, deployment, or release.

## Change identity and boundary

- **Change:** Make Home communicate matchday utility, trusted terrace material, and community creativity while retaining the existing application architecture.
- **Implementation agent:** Codex
- **Base:** The locally completed V1 core-journey interface-readiness block on `codex/framework-ui-readiness`, itself based on final merged `main` at `2df9fa04a839f88a19fe43c2bcc8ed9a583627c3`
- **Included paths:** Home presentation, Home-mode discovery grouping, an optional Home chant-card presentation, one community accent token, focused tests, updated Home golden, concept record, and framework documentation.
- **Explicit non-goals:** Bottom navigation, global route changes, new repositories or queries, pagination, teamless Add, hosted media, persistence, Firebase rules or Functions, seed data, dependencies, native builds, deployment, signing, or release.
- **Approval:** Andrew selected the redesign direction, approved the V1 core-journey interface-readiness spec, directed Codex to use judgment over fonts, sizing, fun, and basic clarity, then supplied Vouch only as modern native-app layout inspiration for one final visual-potential pass on 2026-08-26.

## Outcome

Home now explains the product in one scrollable hierarchy. The signed-in state exposes Matchday Songbook with explicit device-local offline wording, then the existing Premier League route, one Terrace Proven chant, and one Chant Lab idea. The signed-out state omits the unavailable saved utility. Search still returns one combined list across chant, lyric, tune, and known club text.

The V2 pass intentionally removed the first concept's bottom navigation, View all actions, global Add control, and heavy terrace decoration. A final V3 comparison used Vouch only for modern information architecture, spacing, grouping, and action alignment. It explicitly rejected food imagery, ranks, daily claims, a light palette, and bottom tabs. Product personality comes from the existing Anton display face, warm gold, fan-voiced tagline, trust labels, and one restrained red Chant Lab accent. Navigation and content containers remain familiar cards, rows, and scrolling lists.

## Impacted capability map

| Capability | Before | After | Authority impact |
|---|---|---|---|
| Home identity | Compact title followed immediately by search and catalogue entries | Larger title, quiet fan-voiced line, clearer search hierarchy | None |
| Matchday utility | Existing signed-in Songbook entry with longer support copy | More obvious outlined utility with concise device-local and offline copy | Existing named route and UID argument unchanged |
| Competition browse | Existing Premier League tile | Calmer outlined route card with explicit club count | Existing named route and arguments unchanged |
| Trust hierarchy | One Discover list mixed canonical and community results | One Terrace Proven and one Chant Lab preview from the already-fetched result | Status and current-live authority unchanged |
| Search | Combined filtered results | Same combined results after the utilities yield to search | Existing provider and filter inputs unchanged |
| Account actions | Popup account menu | Labelled circular account control using the same menu and routes | Authorization and account-deletion behavior unchanged |

## Implementation choices

| Choice | Reason | Alternative declined | Evidence |
|---|---|---|---|
| One preview per trust lane | Both product meanings become visible without making Home a long feed | Two or more cards per lane delayed Chant Lab and repeated content already available in search and club browse | Inspected 390 by 844 golden |
| Existing discovery result, grouped in presentation | Avoids reads, listeners, indexes, loading states, and ranking changes | Separate canonical and community queries would expand cost and authority surface | Source and diff inspection |
| Optional `homePreview` card presentation | Lets Home use stronger type, consistent outlines, internal dividers, and page insets without changing Team, Player, or search cards | Global ChantCard restyle would widen visual regression scope | Shared-card and complete Flutter suites |
| Red only for Chant Lab accents and Rising | Adds a playful creator identity while keeping gold as the trusted archive voice | Multi-color decoration would weaken trust hierarchy and basic clarity | Text labels plus inspected golden |
| No persistent navigation or invented actions | Every visible control must have an approved destination and back behavior | Concept-only bottom tabs, View all, and Add had no bounded route contract | Absence assertions and exact-route test |

The image-generation pass influenced hierarchy and visual restraint only. The runtime implementation uses repository fonts, colors, widgets, routes, and data. No generated bitmap ships in the application.

## State, interaction, and accessibility coverage

| State or action | Expected result | Evidence |
|---|---|---|
| Signed out | Songbook utility absent; search, Premier League, and trust lanes remain | Home widget test |
| Signed in | Songbook utility present with explicit local ownership and offline meaning | Songbook entry and Home route tests |
| Search and clear | Utilities yield to combined results; labelled clear restores Home | Home search test |
| No match | Truthful no-result state | Home search test |
| Initial error | Real Try again action | Home state test |
| Canonical and community content | Separate headings, trust words, one preview each | Home golden and widget test |
| Current permission denial or cache | Existing removal and action-authority behavior persists | Inherited discovery authority tests |
| Songbook, competition, chant, and account action | Exact existing route and arguments | Home route test |
| Enlarged text | Header controls, utilities, both sections, and chant content remain reachable through scrolling at 390 by 844 and 1.8x | Responsive Home test |

Meaning is never color-only. Terrace Proven, Chant Lab, Original Idea, and Rising remain written labels. The account button, shuffle action, and clear-search action have stable tooltips. Primary controls retain at least 44-pixel target geometry.

## Security, privacy, abuse, and data impact

- No Firestore query, rule, Function, model, repository, persistence, or server mutation changed.
- Home continues to use the current-live per-chant stream. Permission denial, authoritative absence, hidden, and removed states still suppress a card. Cache-only cards remain readable without authorizing vote.
- Community score and Rising do not promote or verify a chant. Only current status controls the Terrace Proven lane.
- No production data, Firebase project, user record, seed file, or external service was read or mutated.

## Performance and cost

The change groups the already-fetched discovery list by status and takes one item from each lane. It adds no network request, listener, storage access, index, dependency, or platform integration. Existing full discovery fetch cost remains unchanged and is still a later scale boundary.

## Verification performed

- Generated and inspected the V2 product direction and V3 final visual-potential comparison; both exact edit prompts, methods, and SHA-256 values are recorded in `docs/mockups/README.md`.
- Generated and inspected the updated runtime Home golden at 390 by 844.
- Focused Home tests pass for signed state, search, clearing, error, exact routes, and 1.8x scrolling.
- Saved Songbook entry, shared ChantCard, and inherited discovery live-authority tests pass.
- The complete Flutter suite passes 353 tests.
- Scoped Flutter analysis over all changed Home runtime and focused test files reports no issues.
- Touched Dart files are formatter-clean.

Functions, rules, and seed suites were not rerun locally for this presentation-only block. Their exact merged-main evidence remains GitHub Actions run `32993748570` at `2df9fa0`. Draft PR 15 run `33011415224` passed governance, analysis, Functions, seed, and rules, while Flutter found a measured 2.40 percent Linux Home golden difference against the original 2.20 percent ceiling. The scoped ceiling is now 3.00 percent, the comparator's known-bad guard still passes, and replacement run `33011936510` passed all six jobs.

## Rollout, observation, and recovery

- **Deployment:** None authorized.
- **Healthy signals:** Clean-runner CI passes, native fonts match the inspected hierarchy, each route opens correctly, both trust meanings are understood, and no clipping appears during the combined device walk.
- **Recovery:** Revert the Home presentation files and golden. No data rollback or migration is required.
- **Observation:** The Flutter renderer cannot prove iOS and Android font rasterization, physical touch comfort, platform back behavior, or stadium-light legibility. Those remain device-walk gates.

## Known compromises and revisit triggers

| Item | Consequence | Revisit trigger |
|---|---|---|
| One preview per lane | Home favors explanation over feed depth | Closed-beta evidence shows fans expect deeper Home browsing |
| Signed-out Songbook is absent | Matchday value is less visible before authentication | Product decision introduces an honest sign-in prompt without exposing unavailable saved state |
| Premier League count is static presentation copy | League expansion needs the Home entry revised | A second supported competition is approved |
| No persistent navigation | Some top-level routes remain one extra tap away | Usage evidence plus an approved route and back-stack specification |
| Native sign-off pending | Renderer evidence may differ from real devices | Before release packaging |

## Material artifacts

- `lib/app/colors.dart`
- `lib/presentation/home/home_screen.dart`
- `lib/presentation/browse/discovery_section.dart`
- `lib/presentation/shared/chant_card.dart`
- `test/presentation/browse/core_journey_golden_test.dart`
- `test/presentation/saved/saved_songbook_entry_points_test.dart`
- `test/presentation/browse/goldens/core_home.png`
- `docs/mockups/chants-home-redesign-concept-v2.png`
- `docs/mockups/chants-home-redesign-concept-v3.png`
- `docs/mockups/README.md`
- `docs/CHANGE_SPEC.md`
- `docs/INTERFACE.md`
- `docs/EXECUTION.md`
- `docs/ROADMAP.md`
- `ENGINEERING_OVERVIEW.md`
- `docs/IMPLEMENTATION_RATIONALE.md`

## Documentation impact conclusion

- `ENGINEERING_OVERVIEW.md` and `docs/IMPLEMENTATION_RATIONALE.md` were refreshed because Home behavior and verification evidence changed.
- `docs/INTERFACE.md` records the active interface decision and retains persistent navigation as a later evidence-triggered question.
- No new architectural decision record is needed. The change preserves routes, providers, repositories, persistence, and backend authority. A future persistent-navigation architecture would require its own approved specification and durable decision.
