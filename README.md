# Chants

The home of football chants. Find them, learn them, add them, and vote them up. Built on a sport- and league-agnostic data model, so adding a new sport or competition is a matter of data, not new code.

## What it does

- **Find and learn chants** for clubs and competitions, with a clean browse and search experience.
- **Community-driven.** Users add chants and vote them up, with rankings that surface the best.
- **Sport-agnostic core.** The data model is not hard-coded to football, so expanding to other sports is configuration rather than a rewrite.
- **Moderation built in.** A full moderation stack covers reporting, removal, banning, rate limits, auto-hide at a flag threshold, and an audit log.
- **Production hardening.** An idempotent seed pipeline preserves vote tallies across runs, and billing alerts include a kill-switch.

## Tech stack

- Flutter and Dart
- Firebase (Firestore, Auth, Cloud Functions, App Check, Crashlytics)
- Riverpod for state management
- Firebase emulator suite for rules and function tests

## Getting started

### Prerequisites

- Flutter SDK (stable channel)
- A Firebase project with Auth (email/password) and Firestore enabled
- Node.js, for Cloud Functions and rules testing
- Java, for the Firestore emulator
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)

### Setup

```bash
git clone https://github.com/andrewbolaji/Chants.git
cd Chants
flutter pub get
flutterfire configure --project=YOUR_PROJECT_ID
flutter run
```

### Scripts

```bash
flutter analyze     # static analysis
flutter test        # unit and widget tests
firebase emulators:exec --only firestore "cd test_rules && npm test"   # security-rules tests
```

## Project docs

See `docs/` for the product spec, decisions log, roadmap, and feature wishlist.
