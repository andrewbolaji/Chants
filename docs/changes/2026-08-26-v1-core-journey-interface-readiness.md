# Change implementation rationale: V1 core-journey interface readiness

> **Document contract:** This file explains the bounded framework and interface-readiness block approved on 2026-08-26. It does not approve or implement the separate Home redesign concept.

## Change identity and boundary

- **Change:** Install the completed Codex framework surface, correct final merged engineering truth, and establish current Home, competition, and player readiness evidence.
- **Implementation agent:** Codex
- **Base:** `2df9fa04a839f88a19fe43c2bcc8ed9a583627c3`, final merged V1 engineering stack on `main`
- **Target:** `codex/framework-ui-readiness`
- **Included paths/services:** Project governance documents and checks, CI governance job, Home search semantics, browse recovery copy, competition list handling, focused widget tests, three 390 by 844 goldens, and an exploratory Home concept.
- **Explicit non-goals:** New navigation, new visual identity, backend or repository contracts, Firestore rules, Functions, seed data or mechanics, dependencies, Firebase access, native builds, device actions, deployment, signing, merge, or release.
- **Request/acceptance criteria:** Andrew explicitly approved `V1 core-journey interface readiness spec` on 2026-08-26.
- **Date:** 2026-08-26

The separate concept at `docs/mockups/chants-home-redesign-concept-v1.png` remains exploratory. Its persistent navigation and broader hierarchy require a new product decision and change spec before runtime work.

## Outcome

The repository now contains the completed framework's project profile, operator runbook, project-memory check, writing-style check, agent routing, and CI governance job. Both new checks were proved against temporary known-bad cases before CI integration, then passed clean.

Home, competition, and player now have deterministic current baselines at 390 by 844. The rendered images were inspected for hierarchy, clipping, action placement, and alignment. Focused tests cover signed-in and signed-out Home behavior, search and no-result states, loading, empty, error, cached and stale browse states, route actions, and enlarged text. Existing authority tests continue to cover typed permission denial and cache-only action gating.

The evidence run exposed one real crash. `CompetitionScreen` sorted the repository snapshot in place, which throws when the stream supplies an immutable list. It now sorts a private copy. The run also verified that four screens promised pull-to-refresh without implementing that gesture. Discover now says `Try again` beside its real retry action. Competition, Team, and Player say `Go back and try again`, which matches their available navigation. Home's clear-search button now has the stable accessible label `Clear search`.

## Impacted capability map

| Capability or boundary | Before | After | Key paths or interfaces | Why affected |
|---|---|---|---|---|
| Project governance | Framework memory and style rules existed outside the repository | Profile, runbook, checks, agent references, and CI job are repository-local | `AGENTS.md`, `docs/PROJECT_PROFILE.md`, `docs/RUNBOOK.md`, `scripts/`, `.github/workflows/ci.yml` | Future work needs deterministic project-specific governance |
| Competition browse | Mutated the list supplied by the repository stream | Copies, sorts, and renders without changing repository-owned data | `competition_screen.dart :: CompetitionScreen.build` | Immutable snapshots are valid inputs and previously crashed |
| Browse failure recovery | Four surfaces promised a pull-down gesture they did not implement | Discover names its retry; route screens name back navigation | `discovery_section.dart`, `competition_screen.dart`, `team_screen.dart`, `player_screen.dart` | Copy must not promise unavailable behavior |
| Home search accessibility | The visible clear icon had no stable semantic label | Clear control exposes `Clear search` and still clears the controller and state | `home_screen.dart :: _HomeScreenState.build` | Icon meaning must not depend on sight or platform inference |
| Core visual evidence | Home, competition, and current player lacked current representative goldens | Three deterministic 390 by 844 baselines are tracked and inspected | `core_journey_golden_test.dart`, `test/presentation/browse/goldens/` | Release review needs current evidence for the primary browse path |
| Product direction | Redesign discussion had no concrete comparison artifact | One high-fidelity Home concept is tracked with exact prompt and checksum | `docs/mockups/` | Product direction can be judged without changing runtime |

## Implementation choices

| Choice with file or symbol | Why this approach | Alternatives considered | Tradeoff accepted | Evidence |
|---|---|---|---|---|
| `snapshot.data!.toList()..sort(...)` | Preserves alphabetical presentation without assuming ownership or mutability | Sort the repository result in place; force every repository to return mutable lists | One small allocation per competition snapshot | Pre-fix `Unsupported operation` and immutable-list widget regression |
| Truthful recovery copy without a new reload lifecycle | Removes a false promise with no subscription or state-machine expansion | Add pull-to-refresh; add route-local resubscription controls | Competition, Team, and Player use back navigation for a new route read in v1 | Exact-copy tests and current navigation |
| Tooltip on the existing clear icon | Adds a stable semantic name without changing layout | Replace with text; add a second visible action | Visual design remains unchanged | Widget interaction test clears the query through the labelled control |
| Fixture-backed goldens before redesign | Captures the real shipped hierarchy and makes future visual change reviewable | Adopt the concept directly; rely on historical screenshots | Current sparse states remain visible as current truth | Three inspected baseline images and alignment assertions |
| Separate exploratory asset from runtime approval | Lets Andrew compare a stronger direction without accidental scope expansion | Treat mockup generation as implementation approval | A later redesign needs another decision and spec | `docs/mockups/README.md` and `docs/INTERFACE.md` open question |

## State and interaction coverage

| State | Surface and evidence | Result |
|---|---|---|
| Loading | Home discovery, competition, and player widget checks | One stable progress state; navigation frame remains |
| Empty | Home discovery, competition list, player Songbook and signed-out Chant Lab | Surface-specific explanation and valid next action |
| Populated | Home, competition, player goldens and route tests | Core hierarchy renders and primary routes work |
| Search | Home match, clear, and no-result checks | Competition entry yields to results; clear restores browse |
| Initial error | Home, competition, Team, and player checks | Copy names only a real retry or back-navigation path |
| Later transient error | Existing Discover, Team, and player regressions | Last usable readable content stays labelled where permitted |
| Permission denial | Existing typed Firebase Discover and detail regressions | Stale authority disappears and live actions remain unavailable |
| Cached or stale | Existing Discover and Team checks plus new player enlarged-text check | Readable fallback stays explicit; live actions remain bounded |
| Signed in | Home Songbook entry, player creation route, baseline images | Saved and creation actions appear in their existing locations |
| Signed out | Home browse and player empty-Lab checks | Browse remains readable; gated creation control is absent |

Competition has no cache metadata in its repository contract, so it cannot expose a distinct cache label. Home's one-shot discovery failure has no last usable provider value after a fresh root construction; later per-card failures are covered by the existing live authority suite.

## Changed flow and invariants

1. Home opens with current browse, Songbook, competition, and Discover behavior unchanged.
2. Search exposes a labelled clear control and filters the same fixture-backed content.
3. Competition consumes any `List<Team>` snapshot, copies it, sorts the copy, and routes the selected Team unchanged.
4. Initial read failures explain only the action the current screen can support.
5. Player and Team retain their existing last-usable-data behavior after a later stream failure.

| Invariant | Enforcement point | Verification |
|---|---|---|
| Repository-owned collections are not mutated by presentation | Competition list copy | Immutable-list regression |
| Visible copy does not promise unavailable behavior | Four error messages | Exact-copy tests and source search |
| Songbook and Chant Lab retain separate trust meanings | Existing projections and labels unchanged | Player, Team, authority, and golden suites |
| UI visibility is not server authority | No data or service change; inherited current-live guards remain | Existing discovery, detail, vote, comment, save, and share tests |
| Redesign exploration cannot silently become runtime | Separate artifact status and open decision | Scope and diff inspection |

## Security, privacy, and abuse impact

- **Identity and authorization:** Unchanged. No rule, callable, repository, provider authority, or profile contract changed.
- **Sensitive data and retention:** Unchanged. The mockup uses invented fixture values and contains no production payload.
- **External services:** Built-in image generation created one local concept. No Firebase, live database, account, deployment, or third-party publishing action occurred.
- **Abuse controls:** Unchanged. Existing report, feedback, vote, comment, block, moderation, and deletion boundaries remain outside this runtime diff.

## Dependency and infrastructure impact

No manifest, lockfile, package, Firebase config, index, rule, Function, or seed change exists. CI gains one Linux job that runs two POSIX shell checks after checkout. Both scripts use repository and operating-system tools only.

The new governance job passed on draft PR 15 in run `33011415224`, alongside analysis, Functions, seed, and rules. The first Flutter job found one measured Home renderer difference. After the scoped calibration, replacement run `33011936510` passed all six jobs.

## Performance, scale, and cost impact

The competition screen performs one shallow copy of its Team list before sorting. At the current 20-club route this is negligible and prevents shared-state mutation. The Home tooltip and copy changes have no runtime cost. Three golden images and focused widget cases add test time only. CI adds a short checkout-and-shell job with no package installation.

## Verification performed

Red evidence:

- The first competition baseline run failed with `Unsupported operation: Cannot modify an unmodifiable list` at `competition_screen.dart` when the repository fixture supplied a constant list.
- Temporary known-bad prose containing an em dash failed `check-writing-style.sh` before removal.
- A temporary project missing required memory files failed `check-project-memory.sh` before removal.

Green evidence:

- Focused core and inherited authority suites passed 24 tests after the corrections.
- The complete Flutter suite passed 351 tests.
- `flutter analyze --no-pub lib test` passed with the checked-in non-secret Firebase options fixture copied temporarily, then removed.
- Nine changed Dart files passed formatter verification with no rewrite.
- The memory and writing checks pass, both shell scripts pass syntax checking, and `git diff --check` passes.
- Home, competition, and player goldens were generated at 390 by 844 and visually inspected. Competition row alignment also has a coordinate assertion.

Functions, Firestore rules, and seed suites were not rerun because this branch changes no backend, rules, seed, dependency, or shared contract. Their exact final-main evidence remains GitHub Actions run `32993748570` at `2df9fa0`.

## Rollout, observation, and recovery

- **Deploy order:** None authorized. Package one branch and obtain clean-runner CI before merge review.
- **Healthy signals:** Six CI jobs pass, the later combined native walkthrough has no clipping or route failure, and Andrew accepts or rejects the redesign separately.
- **Rollback:** All runtime changes are presentation-only and require no data migration. Reverting the list copy would reopen the reproduced immutable-input crash.
- **Observation:** The native combined walkthrough remains the only evidence for actual iOS and Android font rendering, keyboard behavior, platform navigation, and physical accessibility interaction.

## Known compromises and uncertainty

| Item | Consequence | Why accepted | Owner | Revisit trigger |
|---|---|---|---|---|
| Route screens do not gain in-place retry | A user returns and reopens the route after an initial read failure | Avoids a new subscription lifecycle in a readiness correction | Andrew | Device walk or support evidence shows back-navigation recovery is unclear |
| Home concept is not implemented | Current Home remains less expressive and has no persistent primary navigation | Product direction needs explicit comparison and global route design | Andrew | Explicit redesign approval after reviewing current and concept images |
| Native behavior is not verified | Renderer evidence cannot prove platform fonts or device lifecycle | Device walkthrough is deliberately deferred | Andrew | Before release sign-off |
| Flutter stable remains unpinned | Later renderer updates may require another measured golden calibration | Keep any tolerance change scoped and evidence-backed | Codex | A clean runner crosses the current 3.00 percent ceiling |

## Material files and artifacts

- `docs/PROJECT_PROFILE.md`, `docs/RUNBOOK.md`, `AGENTS.md`
- `scripts/check-project-memory.sh`, `scripts/check-writing-style.sh`
- `.github/workflows/ci.yml`
- `lib/presentation/home/home_screen.dart`
- `lib/presentation/browse/competition_screen.dart`
- `lib/presentation/browse/discovery_section.dart`
- `lib/presentation/browse/player_screen.dart`
- `lib/presentation/browse/team_screen.dart`
- `test/presentation/browse/core_journey_golden_test.dart`
- `test/presentation/browse/competition_screen_test.dart`
- `test/presentation/browse/player_screen_test.dart`
- `test/presentation/browse/team_screen_test.dart`
- `test/presentation/browse/goldens/core_home.png`
- `test/presentation/browse/goldens/core_competition.png`
- `test/presentation/browse/goldens/core_player.png`
- `docs/mockups/chants-home-redesign-concept-v1.png` and `docs/mockups/README.md`
- Current overview, rationale, interface, roadmap, active spec, README, and execution record

## Documentation impact conclusion

- **Does `ENGINEERING_OVERVIEW.md` need refresh?** Yes. It must distinguish final merged main from the locally verified interface branch and new CI job.
- **Does `docs/IMPLEMENTATION_RATIONALE.md` need refresh?** Yes. The coverage ledger, verification count, and governance status changed.
- **Does an ADR need to be created?** No. The corrections are local and reversible. Persistent navigation and the broader redesign remain an open product decision and would require a new spec before implementation.
