# CLAUDE.md

## What this is

Chants is a Flutter (Dart) mobile app where football fans find, learn, and add the chants sung on the terraces, backed by Firebase (Auth, Firestore, Cloud Functions). The Dart app is most of the code; server logic lives in TypeScript Cloud Functions, and `firestore.rules` is the real access-control layer.

## First 10 minutes

```bash
# Flutter app, most of the code.
flutter pub get
flutter test                              # models, services, widgets. Needs no Firebase config.

# Backend suites (Node 20), each self-contained. Verified green here:
cd functions && npm install && npm test   # Cloud Functions, 12 tests
cd seed && npm install && npm test        # seed validation, 23 tests

# Firestore rules tests need the emulator (Java plus firebase-tools):
cd test_rules && npm install && npm test  # runs against 127.0.0.1:8080

# To run the actual app you need your own Firebase project:
cp lib/firebase_options.dart.example lib/firebase_options.dart   # then add real keys
flutter run
```

## Architecture map

- `lib/app/` theme, colors, spacing, router, Riverpod providers. `lib/data/` models, repositories (one per Firestore collection), and pure services (chant matching, ranking).
- `lib/presentation/` screens and widgets grouped by feature (auth, browse, comments, moderation, submit, feedback, shared).
- `functions/src/` Cloud Functions for counters, rate limits, moderation, and account deletion. Counters are recomputed from stored docs, never blind-incremented, so they self-correct.
- `firestore.rules` denies by default. `seed/` writes canonical content via the Admin SDK. Tests live in `test/`, `functions/test/`, and `test_rules/`.

## Gotchas

- `lib/firebase_options.dart` and the platform Google services files are gitignored. `flutter test` runs without them (nothing under `test/` imports them), but `flutter analyze` and `flutter run` need them because `lib/main.dart` imports `firebase_options.dart`. Copy the `.example` first.
- Riverpod providers are code-generated. After editing an annotated provider, run `dart run build_runner build --delete-conflicting-outputs`.
- Counters (score, commentCount, likeCount) are owned by Cloud Functions. Never write them from the client; the rules reject it.
- Firestore queries must carry the hidden and removed visibility filters or the rules reject the whole query.
- Seed content is externally sourced and verified by hand. The pipeline transforms supplied data in place; it never generates or rewrites lyrics or squads. This is the highest-priority standing rule.

## Definition of done

A change is done only when: the plan was approved before any non-trivial code; tests pass and the new behavior has its own test (revert the change and that test should fail); `flutter analyze` and the touched suite are clean; you have read your own diff; UI changes are verified by screenshot; and the work is committed and pushed. Uncommitted work does not exist.

## House style

Applies to every file and every commit message, subject and body. No em dashes, ever. Use commas, periods, or parentheses instead. Headings in sentence case.
