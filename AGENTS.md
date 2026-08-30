# AGENTS.md

## What this is

Chants is a Flutter (Dart) mobile app where football fans find, learn, and add the chants sung on the terraces, backed by Firebase (Auth, Firestore, Cloud Functions). The Dart app is most of the code; server logic lives in TypeScript Cloud Functions, and `firestore.rules` is the real access-control layer.

## Start here

Read `docs/PROJECT_PROFILE.md` before changing code. Search relevant active entries in `docs/LEARNINGS.md` before repeating a previously touched investigation. For UI work, read the relevant contract and decisions in `docs/INTERFACE.md`. For a whole-project or release review, read `docs/IMPLEMENTATION_RATIONALE.md`. For a feature, fix, PR, diff, or commit-range review, read the matching scoped rationale under `docs/changes/`.

## First 10 minutes

```bash
# Flutter app, most of the code.
flutter pub get
flutter test                              # models, services, widgets. Needs no Firebase config.

# Backend suites, each self-contained. Use the package's runtime:
cd functions && npm ci && npm run build && npm test  # Node 22, 163 tests
cd seed && npm install && npm test        # Node 20, seed and rollout controls, 71 tests

# Firestore rules tests need Java plus firebase-tools:
npm --prefix test_rules install
firebase emulators:exec --only firestore,storage --project chants-f95b4 "cd test_rules && npm test"  # 168 tests

# To run the actual app you need your own Firebase project:
cp lib/firebase_options.dart.example lib/firebase_options.dart   # then add real keys
flutter run

# Framework structure and tracked-prose checks.
./scripts/check-project-memory.sh
./scripts/check-writing-style.sh
node scripts/check-launch-services.mjs
node scripts/test-launch-services-check.mjs

# After staging an implementation handoff.
./scripts/check-project-memory.sh --staged
./scripts/test-project-governance.sh
```

## Architecture map

- `lib/app/` theme, colors, spacing, router, Riverpod providers. `lib/data/` models, repositories and services for Firestore, callable, local-storage, matching, and ranking boundaries.
- `lib/presentation/` screens and widgets grouped by feature (auth, browse, comments, moderation, submit, feedback, shared).
- `functions/src/` Cloud Functions for counters, rate limits, moderation, and durable account deletion. Vote, comment, like, content-report, and user-report counters are recomputed from stored docs inside parent-serialized transactions so duplicates and overlapping delivery converge.
- `firestore.rules` denies by default. `seed/` writes canonical content via the Admin SDK. Tests live in `test/`, `functions/test/`, and `test_rules/`.

## Gotchas

- `lib/firebase_options.dart` and the platform Google services files are gitignored by the current setup. They contain Firebase client configuration, not Admin credentials. `flutter test` runs without them, but analyze and run commands that import `lib/main.dart` need a local config. Copy the `.example` and use your own Firebase project.
- Riverpod providers are hand-written in `lib/app/providers.dart`. There are no annotated providers or generated `.g.dart` files in `lib/`; do not run `build_runner` unless a later approved change introduces code generation deliberately.
- Counters (score, commentCount, likeCount, flagCount) are owned by Cloud Functions. Never write them from the client; the rules reject it.
- Firestore queries must carry the hidden and removed visibility filters or the rules reject the whole query.
- Seed content is externally sourced and verified by hand. The pipeline transforms supplied data in place; it never generates or rewrites lyrics or squads. This is the highest-priority standing rule.

## Documentation workflow

- `docs/PROJECT_PROFILE.md` is the compact source of truth for architecture, commands, data, release, and project-specific risk escalation.
- Lane 1 work needs a short recorded plan and checkable acceptance criteria. Lane 2 and Lane 3 work uses the one active `docs/CHANGE_SPEC.md`, and its status must say `Approved` before implementation. Approval is also required for unresolved product choices, hard-to-reverse decisions, or external cost.
- `docs/EXECUTION.md` is the timestamped evidence trail for every Lane 1-3 change and other multi-step state-changing work. Keep implemented, locally verified, reviewed, merged, deployed, and observed states separate.
- Search `docs/LEARNINGS.md` before repeating an investigation. Add only reusable lessons backed by a reproduced failure, measurement, incident, or verified correction.
- Read `docs/INTERFACE.md` before material UI work and update it when hierarchy, interaction, content, accessibility, or responsive behavior changes materially.
- `docs/changes/` records what a completed block changed, why, and how it was verified.
- `docs/decisions/` records durable decisions, their reasons, consequences, and revisit triggers.
- `docs/ROADMAP.md` owns product and release sequencing.
- `docs/RUNBOOK.md` owns source-backed diagnosis and recovery guidance. It must state when production or dashboard evidence is missing.
- `ENGINEERING_OVERVIEW.md` and `docs/IMPLEMENTATION_RATIONALE.md` are milestone review snapshots, not per-change ledgers.
- `docs/DECISIONS.md`, `docs/BLOCK_RECAPS.md`, and `docs/KNOWN_ISSUES.md` are historical archives. Do not add parallel current records there.
- `CLAUDE.md` is a compatibility pointer to this file. Keep this file canonical.
- After `.codex/hooks.json` or a referenced hook script changes, review and trust the new repo-local hook definition through Codex's `/hooks` screen before expecting it to run.
- Treat persistent schema changes, moderation or authorization changes, external media links, migrations, and cross-service contracts as Lane 2 work. Complete and approve the written change spec before implementation.
- Project memory must never contain prompts, chain-of-thought, secrets, credentials, personal data, or raw production payloads.
- CI runs project-memory checks across the PR or push range with `--range`. After staging a handoff, run `./scripts/check-project-memory.sh --staged` manually so implementation changes require a staged `docs/EXECUTION.md` update. A confirmed Lane 0 mechanical change may use `PROJECT_MEMORY_LANE=0`. The writing check scans tracked prose from the Git index, so run it after staging the intended diff.

## Definition of done

A change is done only when: the required plan and approval for its risk lane are recorded; tests pass and changed behavior has evidence capable of failing on the prior implementation; `flutter analyze lib test` and every touched suite are clean; the resulting artifact and full diff were inspected; material UI changes are verified at representative viewport, state, accessibility, and runtime boundaries; the intended handoff is staged; `./scripts/check-project-memory.sh --staged`, `./scripts/check-writing-style.sh`, and `./scripts/test-project-governance.sh` pass against that staged boundary; the completed record is written under `docs/changes/`; and any durable decision is recorded under `docs/decisions/`. Prepare a clean commit handoff, but commit or push only when Andrew explicitly asks.

## House style

Applies to every file and every commit message, subject and body. No em dashes, ever. Use commas, periods, or parentheses instead. Headings in sentence case.
