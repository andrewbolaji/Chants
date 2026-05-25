# Block Recaps

Running log of completed Blocks with deliverables, decisions, and closure status.

A Block is not closed until its commit hash is recorded here.

---

## Block 1: Foundation and the Agnostic Data Model
**Status:** CLOSED
**Commit:** `e4ed772`
**Tests:** 74 passing (30 Dart unit tests + 44 Firestore rules emulator tests)
**Analyze:** `flutter analyze` -- 0 issues
**Gates verified:** All 3 gates (flutter analyze, flutter test, rules emulator) each proven to catch a deliberate break, then reverted.

### What was built
- Flutter project scaffold (mobile-first, iOS + Android) with Riverpod state management
- Firebase wiring via FlutterFire CLI to project chants-f95b4 (europe-west2)
- 10 typed Dart models with fromJson/toJson serialization: Sport, Competition, Team, Player, Chant, Vote, Report, AuditLogEntry, FeedbackEntry, UserProfile
- 10 repositories behind the data layer boundary (presentation never imports Firebase SDK)
- Auth: email/password sign up, sign in, password reset (behind AuthRepository)
- Profile creation at sign-up (profiles collection with id, displayName, role, createdAt, updatedAt)
- Firestore security rules deployed to production (all 10 collections)
- Storage rules (deny all) in repo for Block 3
- Cloud Functions scaffold (no business logic)
- Content policy screen stub
- Home screen placeholder

### Disposition table

**Security frame** (mandatory: auth, PII, public read, security rules boundary)

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Password reset does not leak email existence | N/A | Verified: AuthRepository catches user-not-found and returns same success message regardless |
| Counters (upvotes, downvotes, score, commentCount) never client-writable | N/A | Verified: create rule enforces all = 0; update rule blocks these fields for non-operators |
| Status never client-writable on create (forced to 'community') | N/A | Verified: rules test confirms canonical create is rejected |
| auditLog has no client write path | N/A | Verified: `allow write: if false` tested and confirmed |
| User email is never exposed (profiles surface displayName only) | N/A | Verified: no email field in UserProfile model or profiles collection |
| hidden/removed fail-safe defaults (false) enforced on create | N/A | Verified: create rule enforces hidden == false and removed == false |
| User cannot change own role | N/A | Verified: rules test confirms role change is rejected |
| Vote doc ID convention prevents duplicate votes | N/A | Verified: voteId must equal userId + '_' + chantId, tested with wrong ID |
| Vote value constrained to 1 or -1 | N/A | Verified: rules test confirms value of 5 is rejected |
| Reports are insert-only (no update, no delete) | N/A | Verified: no update/delete rules exist |
| Feedback message length capped at 1000 chars | N/A | Verified: rules test confirms 1001-char message is rejected |
| Storage bucket locked (deny all) until Block 3 | N/A | Verified: storage.rules denies all reads and writes |
| Operator role check uses get() on profile doc | Low | Defended: at Block 1 volume (single operator), one get() per action is fine. Trigger to migrate to custom claims recorded in DECISIONS. |

**Taste frame** (mandatory every Block)

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Data layer boundary established: presentation never imports Firebase SDK | N/A | Verified: all Firebase imports are in data/repositories/ and data/models/ only |
| No hardcoded league or sport checks anywhere | N/A | Verified: Football and PL appear purely because their enabled flag is true. No string checks in app code. |
| contextNotes is nullable (optional) per fix C | N/A | Verified: Chant model accepts null contextNotes |
| 9th-grade copy on auth screens | N/A | Verified: "Wrong email or password. Check both and try again." / "Pick a display name." / "At least 6 characters." |
| No em dashes in any file | N/A | Verified: grep for em dash returns 0 hits across all Dart files and docs |
| Resource disposal: all TextEditingControllers disposed in auth screens | N/A | Verified: dispose() called in SignInScreen, SignUpScreen, PasswordResetScreen |
| Async safety: mounted check after every await in auth screens | N/A | Verified: `if (!mounted) return;` after sign-in, sign-up, and password-reset awaits |

**Operational frame** (mandatory: Firestore persistence)

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Firestore location permanently set to europe-west2 (London) | N/A | Correct for UK audience. Recorded in DECISIONS. |
| Chants in flat top-level collection with denormalized IDs | N/A | Verified: matches DECISIONS topology. No subcollections. |
| Firestore query-vs-rules constraint noted for Block 2 | Low | Defended: documented in DECISIONS notes. Block 2 queries must include hidden/removed filters. |

### New DECISIONS.md entries
1. State management: Riverpod (flutter_riverpod + riverpod_annotation)
2. Operator role via profile get() in security rules (trigger to migrate: second get() needed or operator extends beyond founder)
3. Firestore and Storage start locked (production mode, deny by default)
4. Auth: email and password only for v1
5. profiles collection includes updatedAt timestamp
6. Storage and Cloud Functions deployment deferred to Block 3 (trigger: media upload)
7. Firestore location: europe-west2 (London)

### Schema changes
All collections created from scratch (new project). See the plan for exact field definitions. No migrations.

### Sensitive-data analysis
- **PII introduced:** user email address (in Firebase Auth, never stored in Firestore, never exposed to other users)
- **Protection:** profiles collection surfaces displayName only. Password reset does not leak email existence. No email field in any Firestore collection.
- **Downstream surfaces:** no public views expose email. Auth screens show only the current user's own input.

### Final checks (measured)
- `flutter analyze`: 0 issues (command: `flutter analyze`)
- `flutter test`: 30 passing, 0 failing (command: `flutter test`)
- Firestore rules emulator: 44 passing, 0 failing (command: `firebase emulators:exec --only firestore "cd test_rules && npm test"`)
- All 3 gates verified with deliberate break and revert

### Files created (measured line counts)
| File | Lines |
|------|-------|
| lib/data/models/sport.dart | 44 |
| lib/data/models/competition.dart | 52 |
| lib/data/models/team.dart | 56 |
| lib/data/models/player.dart | 50 |
| lib/data/models/chant.dart | 188 |
| lib/data/models/vote.dart | 46 |
| lib/data/models/report.dart | 46 |
| lib/data/models/audit_log_entry.dart | 50 |
| lib/data/models/feedback_entry.dart | 53 |
| lib/data/models/user_profile.dart | 62 |
| lib/data/repositories/auth_repository.dart | 47 |
| lib/data/repositories/profile_repository.dart | 50 |
| lib/data/repositories/sport_repository.dart | 25 |
| lib/data/repositories/competition_repository.dart | 28 |
| lib/data/repositories/team_repository.dart | 27 |
| lib/data/repositories/player_repository.dart | 25 |
| lib/data/repositories/chant_repository.dart | 42 |
| lib/data/repositories/vote_repository.dart | 46 |
| lib/data/repositories/report_repository.dart | 28 |
| lib/data/repositories/feedback_repository.dart | 29 |
| lib/app/app.dart | 31 |
| lib/app/providers.dart | 58 |
| lib/app/router.dart | 30 |
| lib/app/theme.dart | 19 |
| lib/presentation/auth/sign_in_screen.dart | 121 |
| lib/presentation/auth/sign_up_screen.dart | 125 |
| lib/presentation/auth/password_reset_screen.dart | 104 |
| lib/presentation/content_policy/content_policy_screen.dart | 35 |
| lib/presentation/home/home_screen.dart | 33 |
| lib/main.dart | 15 |
| lib/firebase_options.dart | 68 |
| firestore.rules | 109 |
| storage.rules | 10 |
| firebase.json | (generated by FlutterFire) |
| firestore.indexes.json | 4 |
| functions/src/index.ts | 6 |
| functions/package.json | 21 |
| functions/tsconfig.json | 13 |
| test/data/models/sport_test.dart | 33 |
| test/data/models/competition_test.dart | 38 |
| test/data/models/team_test.dart | 35 |
| test/data/models/player_test.dart | 24 |
| test/data/models/chant_test.dart | 104 |
| test/data/models/vote_test.dart | 44 |
| test/data/models/report_test.dart | 34 |
| test/data/models/audit_log_entry_test.dart | 31 |
| test/data/models/feedback_entry_test.dart | 41 |
| test/data/models/user_profile_test.dart | 69 |
| test_rules/firestore_rules.test.ts | 702 |
| test_rules/package.json | 13 |
| test_rules/tsconfig.json | 10 |
| CLAUDE.md | 22 |
| README.md | 26 |
| HANDBOOK.md | 40 |

### Files modified
| File | Change |
|------|--------|
| DECISIONS.md | Added 7 new decision entries + 3 notes for later Blocks |
| .gitignore | Added Firebase, functions, and test_rules ignores |
| ~/.zshrc | Added OpenJDK to PATH |

### Deferred (with triggers)
| Item | Trigger |
|------|---------|
| Storage deployment and rules | Block 3: media upload needs a live bucket |
| Cloud Functions deployment | Block 3: audit logging and rate-limiting need server logic |
| Migrate operator role to custom auth claims | When any single rule needs a second get(), OR before operator actions extend beyond the founder account |
| Composite indexes for chant queries | Block 2: browse/search queries need indexes for teamId + hidden + removed + sort fields |
| Canonical seed via Admin SDK script | Block 2: security rules force status == 'community' on client create |
| subjectTag/playerId consistency validation | Block 3: submission-time validation |

### Commit
`e4ed772`
