# Engineering learnings

This is durable, evidence-backed project memory. It prevents the same failure or investigation from being repeated. It is not a diary, backlog, or place for guesses.

## Rules

- Add an entry only after a reproduced failure, measured result, incident, or verified correction yields a reusable lesson.
- Search before adding an entry. Update or supersede an existing lesson instead of creating a duplicate.
- State the scope, evidence, reusable rule, applied control, and revisit trigger.
- Promote mature lessons into code, tests, `AGENTS.md`, an ADR, or a runbook, then retain their provenance here.
- Never store prompts, chain-of-thought, secrets, personal data, or raw production payloads.

## Entries

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

- **Status:** active
- **Scope:** Chant identity and seed reconciliation
- **Observed:** Renaming a chant created a new document and left the title-derived old document orphaned.
- **Evidence:** The pre-framework orphan-on-rename control is retained in `docs/BLOCK_RECAPS.md`, and the stable-ID remediation boundary is recorded in `docs/WISHLIST.md` and `docs/ROADMAP.md`.
- **Learning:** User-visible mutable text is not a stable identity. Move to non-title-derived IDs before engagement data makes rename cleanup risky.
- **Applied control:** Not yet implemented. The migration is now a v1 engineering prerequisite in `docs/ROADMAP.md`.
- **Revisit when:** Reassess the migration design only if verified production references make the planned boundary unsafe.
- **Related:** `docs/WISHLIST.md`
