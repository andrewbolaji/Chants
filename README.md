# Chants

[![CI](https://github.com/andrewbolaji/Chants/actions/workflows/ci.yml/badge.svg)](https://github.com/andrewbolaji/Chants/actions/workflows/ci.yml)

**The songbook of the terraces and the workshop for what gets sung next.**

Chants is a mobile app where football fans find and learn terrace songs, contribute the ones that are missing, and back new ideas that deserve to be sung next. Every chant has its lyrics, the tune it is sung to, and the story behind it. The trusted Songbook keeps Terrace Proven material distinct from the community Chant Lab, where fans can create, compete, vote, and comment.

> **Status:** In active development and preparing for store submission; not yet live on the stores. Arsenal is fully seeded; the remaining Premier League clubs are being added.

---

## Screenshots and Demo

| Home and Discover | Chant detail: lyrics, tune, and context | Club screen: chants ranked by score |
|:-:|:-:|:-:|
| ![Home](docs/screenshots/home.png) | ![Chant detail](docs/screenshots/chant-detail.png) | ![Club screen](docs/screenshots/club-screen.png) |

**Live demo:** [chantsfc.com](https://chantsfc.com) (coming soon)

> TestFlight / Google Play testing link and a demo GIF will go here once the app is in review.

---

## Features

- **Browse by competition and club.** Drill down from the Premier League to a club, then to a player, then to a specific chant. Clubs show their chants ranked by score, with verified (canonical) content leading on ties.
- **Learn-focused chant detail.** Lyrics, tune name, context notes explaining the history, and an "Also sung as" section for alternate versions when they exist.
- **Community submission.** Any signed-in user can add a chant. Submissions enter as community content; operators can verify them.
- **Songbook and Chant Lab.** Terrace Proven chants form the trusted archive. Original and already-sung community submissions compete separately in Chant Lab, with optional YouTube or X evidence and a soft duplicate warning before posting.
- **Chant Stage and creator profiles.** Fans can record or choose a manually reviewed performance of up to 30 seconds, follow creators, like, share, comment, mention, and compete on server-owned popularity signals without changing the underlying chant's trust state.
- **Voting.** Upvote, downvote, or remove your vote. Score updates instantly (optimistic UI) and reconciles against the server.
- **Conversation and activity.** Chant comments keep one direct reply level. Performance conversation supports continued replies with bounded visual depth, validated mentions, and a private activity inbox. Users can block another account and manage their block list.
- **Reporting and moderation.** Flag a chant, comment, or user through server-authoritative, atomically rate-limited intake. Auto-hide at a configurable report threshold. Operator tools for hide, unhide, remove, ban, and unban, with an audit log.
- **Stage discovery.** Rising, New, Terrace, and Following feeds page through approved current-authority performances without autoplay or prefetch.
- **Search.** Filter chants by title, lyrics, tune name, or club name with results updating as you type.
- **Saved Matchday Songbook.** Save one chant or a club's Songbook as a bounded device copy for quick offline reading at the ground.
- **Public share-out.** Resolve current visible chants, performances, and creators to stable server-rendered destinations before invoking the native share sheet.
- **Launch authentication and account management.** Verified email, password reset, recoverable onboarding, and source-complete Apple, Google, Facebook, magic-link, phone, and same-UID linking paths. New providers remain hidden until configured. Durable account deletion preserves persistent unknown-request recovery, pending-account denial, bounded retry, contribution and audit anonymization, local Songbook cleanup, and counter reconciliation.

---

## Tech Stack

| Layer | Technology | Version / Detail |
|-------|-----------|-----------------|
| Mobile framework | Flutter (Dart) | SDK ^3.10.8 |
| State management | Riverpod | flutter_riverpod ^2.6.1, riverpod_annotation ^2.6.1 |
| Auth | Firebase Auth | ^6.5.1 |
| Database | Cloud Firestore | ^6.4.1 |
| Server logic | Cloud Functions (TypeScript, Node 20) | firebase-functions ^6.3.0, firebase-admin ^13.0.0 |
| Integrity | Firebase App Check | ^0.4.4+1 (soft-enforce, DeviceCheck / Play Integrity) |
| Observability | Firebase Crashlytics | ^5.2.2 |
| Testing | flutter_test, Mockito, Mocha | Widget, model, security-rules, and Cloud Functions tests |

---

## Architecture

### Project layout

```
lib/
  app/            # Theme, colors, spacing tokens, router, Riverpod providers
  data/
    models/       # Dart data classes (Chant, Comment, Vote, UserProfile, etc.)
    repositories/ # Firestore read/write layer (one per collection)
    services/     # Pure logic (chant matching, ranking)
  presentation/   # Screens and widgets, grouped by feature
    auth/         # Sign in, sign up, password reset
    browse/       # Home, competition, club, player, chant detail
    comments/     # Comment section and card
    settings/     # Blocked-user management
    moderation/   # Operator moderation screen
    report/       # Report bottom sheet (shared by chants and comments)
    shared/       # Reusable widgets (vote controls, chant card, empty/error states)
    submit/       # Chant submission screen
    feedback/     # Suggestion box

functions/src/    # Cloud Functions (TypeScript)
seed/             # Admin SDK seed script and validation
test/             # Flutter tests (models, widgets, services)
test_rules/       # Firestore security-rules tests
```

### Data model

```
Sport
  └── Competition (e.g. Premier League)
        └── Team
              └── Chant (flat top-level collection, denormalized teamId/playerId)
                    ├── Vote      (one per user per chant)
                    ├── Comment   (top-level or one direct reply)
                    │     ├── CommentLike (one per user per comment)
                    │     └── parentCommentId (null/missing for top-level)
                    └── Report / CommentReport

Block (directional, one per blocker/blocked-user pair)

CreatorProfile (public allowlist; private account authority remains in Profile)
  ├── CreatorFollow (private deterministic edge)
  └── CreatorNotification (recipient-only activity)

Performance (approved public projection attached to one chant and creator)
  ├── private draft and exact Storage staging object
  ├── Like / QualifiedView / Share (one deterministic record per account)
  ├── PerformanceComment (continued replies, bounded visual depth)
  └── report, moderation, source-reconciliation, and media-deletion lifecycle
```

Chants are stored in a single flat Firestore collection with denormalized IDs. Performances, public creator identity, private social edges, and activity use separate collections so popularity and creator reach cannot mutate chant trust or expose private account authority.

### Cloud Functions

Forty-four Functions exports are present in source (all configured for `europe-west2`; live deployment state is verified separately). This table shows the inherited chant, safety, account, and policy boundaries:

| Function | Trigger | Purpose |
|----------|---------|---------|
| `submitReport` | HTTPS callable | Validate the caller and current target, atomically enforce the shared report budget, and create a server-owned report |
| `submitFeedback` | HTTPS callable | Validate feedback, atomically enforce its private budget, and create the server-owned feedback row |
| `onVoteWritten` | Vote doc write | Recompute chant score, upvotes, downvotes from all vote docs |
| `onChantCreated` | Chant doc create | Rate-limit enforcement (auto-hide excess) |
| `onCommentWritten` | Comment doc write | Recompute commentCount on the parent chant; rate-limit on create |
| `onCommentLikeWritten` | CommentLike doc write | Recompute likeCount on the comment |
| `onReportCreated` | Report doc write | Recompute pending-report flagCount, auto-hide at threshold |
| `onCommentReportCreated` | CommentReport doc write | Recompute pending-report flagCount on comment, auto-hide at threshold |
| `onModerationAction` | HTTPS callable | Operator hide/unhide/remove/ban and promote/demote actions with audit log |
| `deleteAccount` | HTTPS callable | Durably accept account deletion and mark the profile pending |
| `onAccountDeletionJobWritten` | AccountDeletionJob doc write | Advance one bounded retryable cleanup phase or page |
| `mergeChants` | HTTPS callable | Disabled operator boundary that exits before request parsing or mutation until resumable recovery and privacy-safe audit design are approved |
| `acceptPolicy` | HTTPS callable | Validate and record acceptance of the current content policy |
| `onUserReportCreated` | UserReport doc create | Recompute the reported user's distinct-report count |
| `onUserReportDeleted` | UserReport doc delete | Repair a surviving reported user's count after cleanup |

The creator-platform exports add callable and trigger boundaries for creator identity, follows, activity, performance drafts, admission, playback, interactions, comments, moderation, source reconciliation, public pages, public media, and durable media deletion. The source files and generated export count are authoritative; deployment must be checked separately.

---

## Engineering Highlights

**Core interaction counters recomputed from ground truth.** Vote tallies, comment counts, comment like counts, user-report counts, and chant/comment flag counts are recomputed from stored documents. The report counters use transactions around their ground-truth query and target write, so duplicate and racing trigger deliveries converge without blind increments.

**Optimistic UI with server reconciliation.** Votes and comment likes update the display instantly, then reconcile when the server stream delivers the Cloud Function's recomputed value. A busy guard drops taps while a write is in flight, and a pending-intent latch collapses rapid taps into at most two writes, preventing the score drift that would otherwise occur from concurrent writes to the same document.

**Security-first Firestore rules.** Rules start locked (deny by default). Privileged profile and counter fields are constrained against client writes, interaction targets must exist and be visible, reply depth and relationships are enforced server-side, report and feedback creates are callable-only, and vote/like/profile reads are limited to their owner or an operator.

**Content integrity.** All seed content (lyrics, squads, cultural context) is externally sourced and verified by hand. The build process can only transform supplied data in place; it never generates or rewrites content. This is a standing rule with the highest priority in the project.

**Test coverage across layers.** Final merged `main` at `e8f2591` passed all eight jobs in run `33256843751`: 463 Flutter tests, zero-issue analysis, 142 Cloud Functions tests, 42 seed-pipeline tests, 165 Java-backed Firestore and Storage cases, project governance, Android debug compilation with package inspection, and iOS simulator compilation with bundle and exact-source inspection. Regression guards cover current authority, moderation and takedown, creator and chant source reconciliation, counters, upload admission, public destinations, authentication recovery, account deletion, offline Songbook, responsive layouts, and fail-closed native ownership. This is source and clean-runner evidence, not device, provider, deployment, signing, or store readiness.

---

## Getting Started

### Prerequisites

- Flutter SDK (^3.10.8)
- A Firebase project with Auth, Firestore, and Cloud Functions enabled
- Node 20 (for Cloud Functions)

### Setup

1. Clone the repo.
2. Create your own Firebase project and add your config files. `firebase_options.dart` and the platform-specific Google services files (`GoogleService-Info.plist`, `google-services.json`) are gitignored, so you need your own.
3. Deploy Cloud Functions:
   ```
   cd functions && npm install && npm run build && firebase deploy --only functions
   ```
4. Deploy Firestore rules and indexes:
   ```
   firebase deploy --only firestore
   ```
5. Install Flutter dependencies and run:
   ```
   flutter pub get
   flutter run
   ```

For an installation still using direct report and feedback writes, migrate that boundary first: Functions, compatible client, then the restrictive report and feedback rules. Once that PR 12 contract is established, add durable deletion in its reviewed order: backward-compatible pending-account rules, Functions, then client. Verify the actual deployed baseline before choosing either sequence.

### Running tests

```bash
# Flutter tests (models, widgets, services)
flutter test

# Cloud Functions tests
cd functions && npm test

# Firestore security-rules tests (requires the Firebase emulator)
cd test_rules && npm install && npm test

# Seed validation tests
cd seed && npm install && npm test
```

---

## Documentation

This project uses one documentation lifecycle:

- **[CHANGE_SPEC.md](docs/CHANGE_SPEC.md)** - the one active proposed or approved implementation block.
- **[PROJECT_PROFILE.md](docs/PROJECT_PROFILE.md)** - compact architecture, command, trust, release, and risk source of truth.
- **[EXECUTION.md](docs/EXECUTION.md)** - timestamped evidence and state transitions for substantial current work.
- **[LEARNINGS.md](docs/LEARNINGS.md)** - reusable lessons backed by reproduced or verified evidence.
- **[INTERFACE.md](docs/INTERFACE.md)** - the current UI contract and durable interaction decisions.
- **[Completed changes](docs/changes/README.md)** - what changed, why, and how it was verified.
- **[Durable decisions](docs/decisions/README.md)** - accepted decisions, reasons, consequences, and revisit triggers.
- **[ROADMAP.md](docs/ROADMAP.md)** - product sequencing and release gates.
- **[ENGINEERING_OVERVIEW.md](ENGINEERING_OVERVIEW.md)** and **[IMPLEMENTATION_RATIONALE.md](docs/IMPLEMENTATION_RATIONALE.md)** - milestone review snapshots.
- **[HANDBOOK.md](docs/HANDBOOK.md)** - plain-language manual for shipped features.
- **[RUNBOOK.md](docs/RUNBOOK.md)** - source-backed diagnosis and recovery guidance plus explicit operational gaps.
- **[CHANTS_SPEC.md](docs/CHANTS_SPEC.md)** - the product specification.

`docs/DECISIONS.md` and `docs/BLOCK_RECAPS.md` remain as historical archives for work completed before the current framework.

Run `./scripts/check-project-memory.sh` and `./scripts/check-writing-style.sh` before handing off substantial work.

---

Copyright (c) 2026 Andrew Bolaji. All rights reserved.
