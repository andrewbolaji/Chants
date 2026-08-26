# AGENTS.md

## What this is

Chants is a Flutter (Dart) mobile app where football fans find, learn, and add the chants sung on the terraces, backed by Firebase (Auth, Firestore, Cloud Functions). The Dart app is most of the code; server logic lives in TypeScript Cloud Functions, and `firestore.rules` is the real access-control layer.

## First 10 minutes

```bash
# Flutter app, most of the code.
flutter pub get
flutter test                              # models, services, widgets. Needs no Firebase config.

# Backend suites (Node 20), each self-contained. Verified green here:
cd functions && npm install && npm test   # Cloud Functions, 77 tests
cd seed && npm install && npm test        # seed validation, 42 tests

# Firestore rules tests need Java plus firebase-tools:
npm --prefix test_rules install
firebase emulators:exec --only firestore --project chants-f95b4 "cd test_rules && npm test"  # 136 assertions

# To run the actual app you need your own Firebase project:
cp lib/firebase_options.dart.example lib/firebase_options.dart   # then add real keys
flutter run
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

- `docs/CHANGE_SPEC.md` is the one active implementation plan. Read it before non-trivial code. Product agreement alone does not approve a technical plan; its status must say `Approved`.
- `docs/EXECUTION.md` is the timestamped evidence trail for every Lane 1-3 change and other multi-step state-changing work. Keep implemented, locally verified, reviewed, merged, deployed, and observed states separate.
- Search `docs/LEARNINGS.md` before repeating an investigation. Add only reusable lessons backed by a reproduced failure, measurement, incident, or verified correction.
- Read `docs/INTERFACE.md` before material UI work and update it when hierarchy, interaction, content, accessibility, or responsive behavior changes materially.
- `docs/changes/` records what a completed block changed, why, and how it was verified.
- `docs/decisions/` records durable decisions, their reasons, consequences, and revisit triggers.
- `docs/ROADMAP.md` owns product and release sequencing.
- `ENGINEERING_OVERVIEW.md` and `docs/IMPLEMENTATION_RATIONALE.md` are milestone review snapshots, not per-change ledgers.
- `docs/DECISIONS.md`, `docs/BLOCK_RECAPS.md`, and `docs/KNOWN_ISSUES.md` are historical archives. Do not add parallel current records there.
- `CLAUDE.md` is a compatibility pointer to this file. Keep this file canonical.
- After `.codex/hooks.json` or a referenced hook script changes, review and trust the new repo-local hook definition through Codex's `/hooks` screen before expecting it to run.
- Treat persistent schema changes, moderation or authorization changes, external media links, migrations, and cross-service contracts as Lane 2 work. Complete and approve the written change spec before implementation.
- Project memory must never contain prompts, chain-of-thought, secrets, credentials, personal data, or raw production payloads.

## Definition of done

A change is done only when: the plan was approved before any non-trivial code; tests pass and the new behavior has its own test (revert the change and that test should fail); `flutter analyze lib test` and every touched suite are clean; you have read your own diff; UI changes are verified by screenshot; the completed record is written under `docs/changes/`; and any durable decision is recorded under `docs/decisions/`. Prepare a clean commit handoff, but commit or push only when Andrew explicitly asks.

## House style

Applies to every file and every commit message, subject and body. No em dashes, ever. Use commas, periods, or parentheses instead. Headings in sentence case.
