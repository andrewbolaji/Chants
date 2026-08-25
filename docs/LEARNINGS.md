# Engineering learnings

This is durable, evidence-backed project memory. It prevents the same failure or investigation from being repeated. It is not a diary, backlog, or place for guesses.

## Rules

- Add an entry only after a reproduced failure, measured result, incident, or verified correction yields a reusable lesson.
- Search before adding an entry. Update or supersede an existing lesson instead of creating a duplicate.
- State the scope, evidence, reusable rule, applied control, and revisit trigger.
- Promote mature lessons into code, tests, `AGENTS.md`, an ADR, or a runbook, then retain their provenance here.
- Never store prompts, chain-of-thought, secrets, personal data, or raw production payloads.

## Entries

### 2026-08-25T00:41:42Z Native verification can mutate project scaffolding before it fails

- **Status:** applied
- **Scope:** Flutter native build checks on an inherited iOS project whose dependency manager or lifecycle template predates the current Flutter tool
- **Observed:** `flutter build ios --simulator --debug --no-codesign` began CocoaPods-to-SwiftPM and UIScene project migrations before Xcode failed inside inherited Cloud Firestore sources. The failed verification left tracked project files changed and generated package-resolution files present.
- **Evidence:** The post-build diff showed changes to AppFrameworkInfo, AppDelegate, Info.plist, the Xcode project and scheme, a collapsed Podfile lock, and two generated SwiftPM resolution files even though no native migration was approved.
- **Learning:** A native compile command is not necessarily read-only. Treat the platform tree and lockfiles as possible outputs, inspect them after every attempt, and separate intentional plugin registration from tool-driven template migration.
- **Applied control:** The share block restored every tracked iOS file exactly to branch HEAD, removed the generated SwiftPM files, and records native compilation as blocked rather than accepting unrelated migration work.
- **Revisit when:** The iOS dependency-manager and UIScene migrations receive their own approved change, or the Flutter tool provides a verified no-migration compilation mode.
- **Related:** `docs/changes/2026-08-24-basic-share-out.md`

### 2026-08-22T19:38:09Z Queue-time identity checks prevent stale-account local writes

- **Status:** applied
- **Scope:** Device-local repositories whose asynchronous operations are scoped to the currently authenticated account
- **Observed:** A screen-level UID gate prevents normal cross-account navigation, but an operation queued before an auth transition can begin after the active account changes unless the persistence boundary checks again.
- **Evidence:** The repository access test saves under UID A, switches the guard to UID B, and proves both a later load and a queued mutation for UID A fail while UID A's bytes remain unchanged. The mismatched-route widget test also proves UID A's titles do not render for UID B.
- **Learning:** Identity must be revalidated at the durable operation boundary, not inferred only from the screen that initiated work. UI gates explain access; repository guards enforce it when asynchronous work actually starts.
- **Applied control:** Production `SavedSongbookRepository` receives an auth-backed access guard, checks every load and queued mutation at execution time, and keeps account-deletion cleanup inside its already-authorized serialized operation.
- **Revisit when:** Saved state moves to a server-authorized store or a shared local database with a stronger transaction-scoped identity primitive.
- **Related:** `lib/data/repositories/saved_songbook_repository.dart`, `lib/app/providers.dart`, decision 003

### 2026-08-22T16:57:38Z Recoverable stream errors need retained route state

- **Status:** applied
- **Scope:** Flutter screens that promise to keep previously usable live data visible through a later stream error
- **Observed:** A `StreamBuilder` error snapshot is not a durable store for the last successful payload. Treating `snapshot.data` as retained would turn a reconnect failure into a full-screen error even after the fan had readable chants.
- **Evidence:** The Player-route retained-data widget test first receives a usable chant snapshot and then a stream error. Deliberately clearing the retained snapshot in the error handler made the test fail because the chant disappeared. Restoring the retained route state made the focused and full Flutter suites pass.
- **Learning:** When stale data is explicitly more useful than an error replacement, own the last successful payload and the current error independently. Show a full error only before any usable payload has arrived.
- **Applied control:** Team and Player routes own one stream subscription each, retain the last `ChantBrowseSnapshot`, clear the error on fresh data, and render `LAST LOADED CHANTS` supporting copy after a later error.
- **Revisit when:** A shared asynchronous state abstraction provides the same tested data-plus-error semantics without adding duplicate subscriptions or hiding cache provenance.
- **Related:** `lib/presentation/browse/team_screen.dart`, `lib/presentation/browse/player_screen.dart`, `test/presentation/browse/player_screen_test.dart`

### 2026-08-22T12:45:35Z Long validated forms must retain every field

- **Status:** applied
- **Scope:** Flutter forms whose controls extend beyond one viewport
- **Observed:** The submit form used a lazy `ListView`. When the origin control scrolled out of the retained child range, its `FormField` could be disposed, so whole-form validation no longer represented every visible step in the draft.
- **Evidence:** The origin-required submit widget test and the 390 by 844 submission golden exercise the offscreen origin and submit controls in one retained form.
- **Learning:** A form that must validate all fields at once cannot rely on lazily disposed descendants unless their state is retained explicitly. Use a retained child structure for bounded forms, or give each lazy field durable state and an independently verified validation contract.
- **Applied control:** `SubmitChantScreen` uses one `SingleChildScrollView` with a retained `Column`; the focused test proves a missing offscreen origin stops both duplicate lookup and create.
- **Revisit when:** The submission form grows enough that retaining the full bounded form causes measured performance or memory problems.
- **Related:** `lib/presentation/submit/submit_chant_screen.dart`, `test/presentation/submit/submit_chant_screen_test.dart`

### 2026-08-22T01:01:47Z Cross-platform goldens need a bounded visual threshold

- **Status:** promoted
- **Scope:** Flutter widget goldens generated on one operating system and verified on another
- **Observed:** The reply and operator-control goldens passed on macOS with Flutter 3.44.8 but failed on Ubuntu with Flutter 3.47.1 at 1.02% and 0.49% pixel difference. Later text-heavy full-screen Songbook and Chant Lab goldens differed by 2.09% and 1.94%. The Saved Songbook detail differed by 2.25%, and the chant-detail share screen by 1.85%, on the same platform pair while their non-visual tests passed.
- **Evidence:** Draft PR 4 workflow run `32541324140`, draft PR 7 workflow run `32587305522`, draft PR 8 workflow run `32594555589`, draft PR 9 workflow run `32794917851`, and the focused local comparator test.
- **Learning:** Exact pixels are too strict across renderers, but removing visual checks would hide real regressions. Use a documented, measured tolerance with a known-bad test that proves the boundary still rejects material changes.
- **Applied control:** `test/helpers/tolerant_golden_file_comparator.dart` keeps a 1.5% default. The measured share-detail test opts into 1.9%, the full-screen browse test into 2.2%, and the Saved Songbook test into 2.3%, while the comparator test proves a small synthetic difference passes and a fully changed image fails.
- **Revisit when:** A pinned renderer or platform-specific baselines make exact comparison stable, or observed benign drift approaches a test's measured boundary.
- **Related:** `.github/workflows/ci.yml`

### 2026-08-22T00:00:35Z Seed content must come from authoritative supplied sources

- **Status:** promoted
- **Scope:** `seed/` and `seed_data/`
- **Observed:** Regenerating Arsenal seed content from non-authoritative material produced a stale squad and unverified chants presented as real data.
- **Evidence:** The incident and cleanup are retained in `docs/BLOCK_RECAPS.md`; seed validation and the current externally verified workflow are described in `docs/IMPLEMENTATION_RATIONALE.md`.
- **Learning:** Transform supplied seed data in place. Never generate or rewrite squads, lyrics, or cultural claims from model memory.
- **Applied control:** Highest-priority rule in `AGENTS.md`, historical decision in `docs/DECISIONS.md`, and seed validation tests.
- **Revisit when:** Never for the source-integrity requirement. The accepted authoritative-source format may change through a new decision.
- **Related:** `docs/DECISIONS.md`, `seed/validate.ts`

### 2026-08-22T00:00:35Z Server-owned fields must be constrained on create

- **Status:** promoted
- **Scope:** Firestore authorization rules
- **Observed:** Update restrictions alone allowed a crafted create to set privileged or server-owned fields, including a profile role.
- **Evidence:** The 2026-05-25 field-pinning decision is retained in `docs/DECISIONS.md`, and the negative boundary is covered by the Firestore rules suite and `docs/IMPLEMENTATION_RATIONALE.md`.
- **Learning:** Pin or reject every privileged and derived field at document creation as well as update.
- **Applied control:** `firestore.rules` create rules and negative assertions in `test_rules/firestore_rules.test.ts`.
- **Revisit when:** A write moves behind a server-only boundary that makes the direct-client create path impossible.
- **Related:** `docs/IMPLEMENTATION_RATIONALE.md`

### 2026-08-22T00:00:35Z Timing-sensitive UI regressions need a real-widget guard

- **Status:** promoted
- **Scope:** Flutter state reconciled from live streams
- **Observed:** A unit test encoded vote snap-back as the expected result while the real control was visibly wrong. A widget test on the production control failed when the fix was deliberately reverted.
- **Evidence:** Red-green verification is retained in `docs/DECISIONS.md` and the current vote and reply widget tests.
- **Learning:** For stream timing, optimistic state, and rendering order, test the real widget boundary and prove the guard can fail against the regression.
- **Applied control:** `test/presentation/shared/vote_controls_widget_test.dart` and `test/presentation/comments/comment_reply_golden_test.dart`.
- **Revisit when:** A higher-fidelity integration test replaces the widget as the smallest reliable boundary.
- **Related:** `docs/IMPLEMENTATION_RATIONALE.md`

### 2026-08-22T00:00:35Z Title-derived document IDs make renames destructive

- **Status:** promoted
- **Scope:** Chant identity and seed reconciliation
- **Observed:** Renaming a chant created a new document and left the title-derived old document orphaned.
- **Evidence:** The pre-framework orphan-on-rename control is retained in `docs/BLOCK_RECAPS.md`, and the stable-ID remediation boundary is recorded in `docs/WISHLIST.md` and `docs/ROADMAP.md`.
- **Learning:** User-visible mutable text is not a stable identity. Move to non-title-derived IDs before engagement data makes rename cleanup risky.
- **Applied control:** Seeded chants now require explicit immutable IDs. Preflight and transaction-time checks reject unsafe ownership or team collisions, and decision 005 preserves the contract.
- **Revisit when:** A verified production collision requires migration, or public identity moves away from the Firestore document ID.
- **Related:** `docs/decisions/005-explicit-seeded-chant-identity.md`
