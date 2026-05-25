# Chants

The home of football chants. Find them, learn them, add them, vote them up.

## Prerequisites
- Flutter SDK (stable channel)
- Firebase project with Auth (email/password) and Firestore enabled
- Node.js (for Cloud Functions and rules testing)
- Java (for the Firestore emulator)
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)

## Setup
1. Clone the repo.
2. Install Flutter dependencies: `flutter pub get`
3. Configure Firebase: `flutterfire configure --project=YOUR_PROJECT_ID`
4. Deploy Firestore rules: `firebase deploy --only firestore:rules`
5. Run the app: `flutter run`

## Scripts
- Dev: `flutter run`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Rules tests: `firebase emulators:exec --only firestore "cd test_rules && npm test"`

## Tech stack
Flutter (mobile first), Firebase Auth, Cloud Firestore. Storage and Cloud Functions activate in Block 3.

## Project docs
See CHANTS_SPEC.md, DECISIONS.md, WISHLIST.md, ROADMAP.md, BLOCK_RECAPS.md, and HANDBOOK.md for product, decisions, and history.
