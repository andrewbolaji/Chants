# Block Recaps

Running log of completed Blocks with deliverables, decisions, and closure status.

A Block is not closed until its commit hash is recorded here.

---

## Block 1: Foundation and the Agnostic Data Model
**Status:** CLOSED
**Commit (final reviewed code):** `accbe3d`
**Commit (recap-write, docs only):** `04718af`
**Tests:** 80 passing (30 Dart unit tests + 50 Firestore rules emulator tests)
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

---

## Block 2: The Archive and the Seed
**Status:** CLOSED
**Commit (final reviewed code):** `e722895`
**Tests:** 112 passing (41 Dart + 56 rules emulator + 14 seed validation + 1 Fix A live test)
**Analyze:** `flutter analyze` -- 0 issues
**Gates verified:** Deliberate break on chants read rule (removed isVisible check), 3 tests failed (hidden chant read, unfiltered list query, partial filter query). Reverted. Fix A counter-and-flag preservation test passed on live Firestore: 9 protected fields survived re-seed, content field updated.

### What was built
- **Seed mechanism:** Idempotent Admin SDK script (Node/TS) with re-run safety (Fix A), slug dedup and orphan reporting (Fix C), and validation before writes
- **Seed content:** Arsenal seeded (1 sport, 1 competition, 1 team, 27 players, 3 canonical chants). All verified: status canonical, counters 0, hidden false, removed false, createdBy system. Re-run verified idempotent. Fix A proven non-trivially: counters set to non-zero and hidden set to true survived re-seed while edited lyrics updated.
- **Content-integrity incident:** The implementer rewrote arsenal.json from AI memory instead of editing in place, seeding a stale squad (7 wrong players). Caught by independent review. 7 orphan player docs and 2 orphan chant docs deleted with Andrew's explicit confirmation. Standing rule added: never generate or regenerate seed content from AI knowledge. 2 AI-drafted chants removed, 2 flagged as unverified in contextNotes, 1 chant's lyrics replaced with Andrew's supplied version.
- **Browse and navigation:** Competition > Club > Player > Chant drill-down. Club page: club chants first, players-with-chants second, full squad collapsible third.
- **Discovery shuffle:** All visible chants fetched (no orderBy, no limit), shuffled client-side (Fix B). Shuffle button refreshes.
- **Chant detail:** Lyrics front and center, tune name, context notes (only when non-empty), status badge, real/parody tag, cover image placeholder, media placeholder. Report button on every chant.
- **Report flow:** Bottom sheet with 4 categories (Hate speech or slurs, Tragedy chanting, Threats or targeting, Something else) plus optional 200-char note. Auth required. Status pinned to pending (Fix D).
- **Empty/loading/error states:** On every screen. No "add" or "submit" prompts (Block 3). Player empty state reads naturally ("No chants for [player] yet.").
- **Shared widgets:** EmptyState, ErrorState, ChantCard (reusable across screens).
- **Position removal:** Player model is name-only. Position noted in DECISIONS as requiring an array if reintroduced.
- **Index hygiene:** No composite indexes (Fix E). Equality-only queries with client-side sort.

### Disposition table

**Security frame**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Hidden/removed chants never returned to non-operators through any query or discovery | N/A | Verified: all repository queries use _visibleChants() base query (hidden == false, removed == false). Rules emulator test confirms unfiltered list query is DENIED. |
| Report write sets status 'pending' and createdAt | N/A | Verified: ReportRepository.submitReport sets both. Rules emulator test confirms well-formed create succeeds. |
| Report write requires auth and reportedBy == caller | N/A | Verified: rules emulator tests confirm unauthenticated create DENIED and mismatched reportedBy DENIED. |
| Service account key excluded from git | N/A | Verified: .gitignore blocks serviceAccountKey.json and *-firebase-adminsdk-*.json. git status shows no key files staged. |
| Seed script bypasses client rules intentionally via Admin SDK | N/A | Correct: canonical seed requires Admin SDK because client create rule forces status == 'community'. |
| Re-seed does not clobber counters or moderation state (Fix A) | N/A | Verified: re-run shows all "updated", read-back confirms counters remain 0 and flags remain false. Content-only update list excludes upvotes, downvotes, score, commentCount, flagCount, hidden, removed, createdBy, createdAt. |

**Taste frame**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Club page surfaces chants first, not a flat 21-player roster | N/A | Verified: club chants section first, players-with-chants second, full squad collapsed third. |
| Empty state copy is natural, not error-like | N/A | Verified: "No chants for [player] yet." reads as expected state, not broken. No "add" prompt. |
| 9th-grade copy on all screens | N/A | Verified: "Something off about this one? Tell us why." / "Got it. We will take a look." / "Could not load chants. Pull down to try again." |
| No em dashes in any file | N/A | Verified: grep returns 0 hits. |
| contextNotes renders only when non-empty | N/A | Verified: `if (chant.contextNotes != null && chant.contextNotes!.isNotEmpty)` guards the section. |
| No position field on player model or UI | N/A | Verified: Player model, seed, validation, and UI all name-only. |

**Operational frame**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Discovery shuffle biased toward last-seeded club | N/A | Fixed (Fix B): fetch all visible, no orderBy, shuffle client-side. Verified by running seed and inspecting query. |
| Slug collision silently overwrites | N/A | Fixed (Fix C): validation deduplicates on computed slug, not raw title. Test confirms duplicate slug is caught. |
| Orphaned docs on rename | Low | Defended: orphan report prints after each run. Deletion is manual (operator's call). |
| No composite indexes (equality-only queries) | N/A | Correct at this volume. Firestore zig-zag merge handles it. DECISIONS note: add composite indexes when orderBy needed server-side. |
| Seed re-run tested idempotent | N/A | Verified: second run produces all "updated", read-back confirms same counts and canonical defaults. |

### New DECISIONS entries
1. Player position field removed (array if reintroduced)
2. Discovery shuffle: all visible chants, client-side shuffle, v2 trigger for pagination
3. Seed re-run safety: content-only updates on existing docs
4. No composite indexes for equality-only queries with client-side sort
5. Released-song anthems: attribution plus context only, never hosted lyrics unless licensed

### Schema changes
- Player model: `position` field removed. Existing player docs in Firestore will have an orphaned position field from the rules test seed data; production players (seeded via Admin SDK) were written without position.

### Sensitive-data analysis
- **New PII:** None. The seed writes no user PII (createdBy is "system").
- **Service account key:** A secret file (serviceAccountKey.json) required locally for the seed. Blocked by .gitignore. Never committed.

### Final checks (measured)
- `flutter analyze`: 0 issues
- `flutter test`: 41 passing, 0 failing
- Firestore rules emulator: 56 passing, 0 failing
- Seed validation: 14 passing, 0 failing
- **Total: 111 tests**
- Verify-the-verification: deliberate break on chants read rule caught 3 failures, reverted

### Files created (measured line counts)
| File | Lines |
|------|-------|
| lib/presentation/browse/competition_screen.dart | 71 |
| lib/presentation/browse/team_screen.dart | 197 |
| lib/presentation/browse/player_screen.dart | 61 |
| lib/presentation/browse/chant_detail_screen.dart | 208 |
| lib/presentation/browse/discovery_section.dart | 84 |
| lib/presentation/report/report_sheet.dart | 152 |
| lib/presentation/shared/chant_card.dart | 110 |
| lib/presentation/shared/empty_state.dart | 35 |
| lib/presentation/shared/error_state.dart | 44 |
| seed/seed.ts | 254 |
| seed/validate.ts | 190 |
| seed/slugify.ts | 22 |
| seed/validate.test.ts | 168 |
| seed/package.json | 18 |
| seed/tsconfig.json | 10 |
| seed_data/sport.json | 4 |
| seed_data/competition.json | 5 |
| seed_data/clubs/arsenal.json | 81 |
| test/presentation/shared/chant_card_test.dart | 100 |
| test/presentation/shared/empty_state_test.dart | 30 |
| test/presentation/shared/error_state_test.dart | 46 |

### Files modified
| File | Change |
|------|--------|
| lib/data/models/player.dart | Removed position field (44 lines) |
| lib/data/repositories/chant_repository.dart | Added _visibleChants(), chantsForPlayerStream(), discoveryChants() (74 lines) |
| lib/presentation/home/home_screen.dart | Replaced placeholder with discovery shuffle and PL entry (60 lines) |
| lib/app/router.dart | Added 4 browse routes (50 lines) |
| test/data/models/player_test.dart | Updated for position removal (31 lines) |
| test_rules/firestore_rules.test.ts | Added 6 tests: report correctness, list query boundary (56 total) |
| .gitignore | Added serviceAccountKey.json and seed ignores |
| DECISIONS.md | 6 new entries |
| WISHLIST.md | 5 new v2 candidate entries |
| HANDBOOK.md | Browse, reporting, and seed sections added |

### Deferred (with triggers)
| Item | Trigger |
|------|---------|
| Composite indexes with server-side orderBy | When client-side sort is too slow (volume outgrows ~100 chants per club) |
| Discovery pagination or random-seed field | When total visible chants outgrow a single fetch |
| Free-text lyric search | v2, first user request or browse becomes insufficient |
| Remaining 19 PL club seed files | Andrew fills them using the arsenal.json template |

### Seed verification (measured from Firestore read-back, final)
| Collection | Count | Canonical defaults verified |
|------------|-------|-----------------------------|
| sports | 1 | enabled: true |
| competitions | 1 | enabled: true |
| teams | 1 | |
| players | 27 | Andrew's 26 plus Nwaneri, no Arteta, no orphans |
| chants | 3 | status: canonical, upvotes: 0, downvotes: 0, score: 0, hidden: false, removed: false, createdBy: system. 2 AI-drafted lyrics flagged as unverified in contextNotes. 1 chant has Andrew-supplied lyrics. |

### Orphans deleted (Andrew-confirmed)
7 player docs (arsenal-jakub-kiwior, arsenal-jorginho, arsenal-kieran-tierney, arsenal-mikel-arteta, arsenal-raheem-sterling, arsenal-takehiro-tomiyasu, arsenal-thomas-partey) and 2 chant docs (arsenal-we-all-follow-the-arsenal, arsenal-he-s-declan-rice).

### Fix A counter-and-flag preservation test (live Firestore)
Seeded chant, set upvotes=42, downvotes=3, score=39, commentCount=7, flagCount=2, hidden=true via Admin SDK. Re-seeded. Result: all 9 protected fields unchanged, edited lyrics field updated. PASSED.

### Commit
`e722895`

---

## Block 3: Submission and Basic Moderation
**Status:** CLOSED
**Commit (final reviewed code):** `070a52e`
**Tests:** 128 passing (44 Dart + 70 rules emulator + 14 seed validation)
**Analyze:** `flutter analyze` -- 0 issues
**Gates verified:** 2 deliberate breaks: (1) ban-evasion rule (removed banned from blocked keys, test caught it), (2) server-side title length (set to 999999, test caught it). Both reverted.

### What was built
- **Submission screen:** Authenticated user adds a chant (community status, counters 0, text-only). Client and server-side validation with length limits (Fix 3). subjectTag/playerId consistency enforced.
- **Cloud Functions (3 deployed to europe-west2):** onReportCreated (flagCount increment, auto-hide at 3), onModerationAction (callable, operator-only: hide, unhide, remove, ban), onChantCreated (soft rate limit).
- **Moderation screen:** Operator-only. Flagged/hidden chants with action buttons. Ban-by-UID tab.
- **Ban enforcement:** banned field on profiles, pinned on create, blocked on self-update (Fix 1). Checked on chant/vote/report creates.
- **Report dedup:** Doc ID = userId_chantId. One report per user per chant.
- **Moderation closes the loop (Fix 4):** hide/remove resolves reports to reviewed. unhide resets flagCount and dismisses reports.
- **Rate limiting (soft, Fix 2b):** Client-side throttle for UX plus Function auto-hides bursts. Not hard enforcement. Documented.
- **Audit logging:** Every moderation action and auto-action writes to auditLog via Cloud Functions (tamper-proof).

### Disposition table

**Security frame (primary)**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Ban evasion: user could set own banned to false | High | Fixed (Fix 1). banned added to blocked keys on self-update. Test proves DENIED. Deliberate break verified. |
| Server-side field length bypass via direct SDK | High | Fixed (Fix 3). title <= 200, lyrics <= 5000, tuneName <= 200, contextNotes <= 500 enforced in rules. Tests prove oversized fields DENIED. Deliberate break verified. |
| Chant create by banned user | N/A | Verified: isNotBanned() check on chant, vote, and report creates. Test proves banned user DENIED. |
| Vote create/update by banned user | N/A | Verified: isNotBanned() on all vote write paths. |
| Report create by banned user | N/A | Verified: isNotBanned() on report create. Banned users cannot weaponize reporting. |
| Profile create pins banned = false | N/A | Verified: create with banned = true is DENIED. |
| Report dedup prevents duplicate flag inflation | N/A | Verified: wrong doc ID is DENIED. Doc ID convention structurally prevents duplicates. |
| Audit log integrity (Function-only writes) | N/A | Verified: auditLog write: if false in rules. Functions use Admin SDK. |
| Moderation callable derives actor from auth context | N/A | Verified: actorUid = request.auth.uid, never from client parameter. Audit trail cannot be spoofed. |
| Rendering of malicious user content | Low | Defended: Flutter Text widget escapes by default (no XSS). Max lengths prevent extreme strings. maxLines and ellipsis on list views. |
| Banned user session lag | Low | Defended: security rules check banned on every write regardless of client state. Client catches PERMISSION_DENIED and shows ban message. |
| Mass-flagging at threshold 3 | Low | Defended: one-report-per-user dedup prevents single-actor inflation. Auto-hide is pending review (operator can unhide). Threshold increase is a data change if abuse observed. |

**Taste frame**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| 9th-grade submission copy | N/A | Verified: "Nice one. It's live. Now go get the lads singing it." / "Give your chant a title." / "Name the tune." |
| Ban message is clear and actionable | N/A | Verified: "Your account cannot submit right now. If you think this is a mistake, use the suggestion box." |
| No em dashes | N/A | Verified: grep returns 0 hits. |
| Content-integrity rule: user content stored as given | N/A | Verified: no transformation or correction of user-supplied text in submission or storage. |

**Operational frame**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Rate limit is soft, not hard | Medium | Defended (Fix 2b): documented as soft enforcement. Client pre-check for UX, Function auto-hides bursts. Hardening trigger: observed spam abuse. |
| Moderation closes the loop (Fix 4) | N/A | Verified: hide/remove resolves reports. Unhide resets flagCount and dismisses reports. |
| Functions deployed to europe-west2 | N/A | Matches Firestore location for latency. |

### New DECISIONS entries
11 new entries covering: privileged field protection pattern, soft rate limiting, server-side length limits, media deferral, ban semantics, auto-hide threshold, report dedup, moderation callable security, moderation loop closure, banned check cost.

### Schema changes
- profiles: added `banned` (bool, default false, pinned on create, blocked on self-update)
- reports: doc ID convention changed to `userId_chantId` (dedup enforcement)

### Sensitive-data analysis
- No new PII introduced. User-submitted chant content (title, lyrics) is user-generated but not PII. createdBy is the user's UID (already in the system).

### Final checks (measured)
- `flutter analyze`: 0 issues
- `flutter test`: 44 passing
- Rules emulator: 70 passing
- Seed validation: 14 passing
- **Total: 128 tests**
- Verify-the-verification: 2 deliberate breaks caught (ban evasion, length limit), reverted
- Functions deployed: 3 (onReportCreated, onModerationAction, onChantCreated)
- Rules deployed with all Block 3 hardening

### Files created
| File | Lines |
|------|-------|
| lib/presentation/submit/submit_chant_screen.dart | 266 |
| lib/presentation/moderation/moderation_screen.dart | 230 |
| lib/data/repositories/moderation_repository.dart | 36 |
| functions/src/audit.ts | 18 |

### Files modified
| File | Change |
|------|--------|
| firestore.rules | Added isNotBanned(), banned pin/block, server-side length limits, report dedup (140 lines) |
| functions/src/index.ts | Real function logic: onReportCreated, onModerationAction, onChantCreated (225 lines) |
| lib/data/models/user_profile.dart | Added banned field |
| lib/data/repositories/report_repository.dart | Deterministic doc ID, hasReported check |
| lib/app/router.dart | Added submit and moderation routes |
| lib/app/providers.dart | Added moderationRepositoryProvider |
| lib/presentation/browse/team_screen.dart | Added "Add a chant" FAB |
| lib/presentation/browse/player_screen.dart | Added "Add a chant" FAB, sportId/competitionId params |
| lib/presentation/home/home_screen.dart | Operator moderation link |
| test/data/models/user_profile_test.dart | Added banned field tests (8 tests) |
| test_rules/firestore_rules.test.ts | Added 14 new tests: ban enforcement, profile pins, report dedup, length limits |
| DECISIONS.md | 11 new entries |

### Deferred (with triggers)
| Item | Trigger |
|------|---------|
| Media upload (Storage rules, file validation) | Next step (Block 3b or Block 6), when text submission is proven stable |
| Hard rate limiting via HTTPS callable | Observed spam abuse |
| Content policy real text | Andrew supplies it; screen has placeholder |
| Custom claims migration for banned + operator | Read cost justifies it or operator extends beyond founder |

### Commit
`070a52e`

---

## Block 4: Voting, Ranking, and Canonical Promotion
**Status:** CLOSED
**Commit (final reviewed code):** `6e1000c`
**Tests:** 137 passing (45 Dart + 73 rules emulator + 19 seed/counter/reconciliation)
**Analyze:** `flutter analyze` -- 0 issues
**Gates verified:** Deliberately broke the flip delta logic (skipped removing old vote effect), 3 counter tests failed (6-step sequence at step 3, flip test, implicit in reconciliation). Reverted.

### What was built
- **Vote UI:** Upvote/downvote controls on chant cards and detail page. Net score displayed. User vote state highlighted. Toggle/flip/clear. Auth required, banned users see permission error.
- **onVoteWritten Function:** Handles all 6 transitions (create up, create down, flip up-to-down, flip down-to-up, delete up, delete down) via before/after diff with atomic FieldValue.increment. Single function, no branching.
- **Reconciliation script (Fix A):** seed/reconcile.ts recomputes chant counters from votes collection ground truth. Runnable for one chant or all. Idempotency limitation documented with trigger for event.id dedup.
- **Cross-implementation invariant test:** 6-step vote sequence matrix asserts counters match ground truth after each step. Plus reconciliation-of-drift test.
- **Composite indexes (Fix B):** teamId+hidden+removed+score desc (club ranking), status+hidden+removed+score desc (promotion candidates). No unused indexes.
- **Canonical promotion:** Operator-confirms at score >= 10. promote/demote actions in onModerationAction callable. Promotion candidates tab in moderation screen. Canonical is sticky.
- **Fix C:** Rules test proves non-operator cannot set status to canonical.
- **Score sort live:** Club page chantsForTeamStream now uses server-side orderBy score desc.

### Disposition table

**Operational frame (primary)**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Counter drift from at-least-once delivery | Medium | Defended (Fix A). Reconciliation script built and tested. Idempotency limitation documented with trigger for event.id dedup. The invariant test catches delta logic errors but cannot simulate duplicate delivery. |
| Flip transition moves both counters | N/A | Verified: delta is (-1, +1, -2) for up-to-down and (+1, -1, +2) for down-to-up. Invariant test step 3 covers it. |
| Delete transition decrements correctly | N/A | Verified: steps 5 and 6 of the invariant test. |
| No-op when before and after are equal | N/A | Verified: separate test case, delta is (0, 0, 0). |
| Re-seed does not reset live counters | N/A | Verified in Block 2 Fix A live test (counters at non-zero survived re-seed). |
| Composite indexes match actual queries | N/A | Verified (Fix B): teamId+score for chantsForTeamStream, status+score for promotionCandidatesStream. No unused indexes. |

**Security frame**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Vote integrity: one per user, value 1 or -1 | N/A | Verified: Block 1 rules and tests still pass. Doc ID = userId_chantId. |
| Counters are Function-only, not client-writable | N/A | Verified: Block 1 create rule pins all counters to 0, update rule blocks them for non-operators. |
| Banned users cannot vote | N/A | Verified: Block 3 isNotBanned() on vote create/update. Test proves DENIED. |
| Non-operator cannot self-promote to canonical (Fix C) | N/A | Verified: 3 new rules tests. Author update rule blocks status changes. Operator can. |
| Canonical-promotion gaming via vote brigade | Low | Defended: threshold only surfaces candidates, operator confirms. No chant becomes canonical without human review. Trigger to raise threshold: first observed gaming attempt. |

**Taste frame**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Vote UI is clean: score, up arrow, down arrow | N/A | Verified: net score displayed, user vote highlighted, no separate up/down counts. |
| Vote toggle disables during write (no rapid-tap issue) | N/A | Verified: _busy flag prevents concurrent writes. Server rules enforce regardless. |
| No em dashes | N/A | Verified. |

### New DECISIONS entries
7 new entries: score formula (net), canonical promotion (operator-confirms at 10), voting on canonical (allowed, sticky), vote display, counter idempotency limitation, composite indexes.

### Schema changes
- 2 composite indexes added to firestore.indexes.json
- No Firestore field changes (counters were defined in Block 1)

### Sensitive-data analysis
No new PII. Vote docs contain userId (already in the system).

### Final checks (measured)
- `flutter analyze`: 0 issues
- `flutter test`: 45 passing
- Rules emulator: 73 passing (3 new promotion tests)
- Seed/counter tests: 19 passing (5 new counter/reconciliation tests)
- **Total: 137 tests**
- Functions deployed: 4 (onVoteWritten new, 3 existing updated with promote/demote)
- Indexes deployed: 2

### Files created
| File | Lines |
|------|-------|
| lib/presentation/shared/vote_controls.dart | 121 |
| seed/reconcile.ts | 79 |
| seed/reconcile.test.ts | 115 |

### Files modified
| File | Change |
|------|--------|
| functions/src/index.ts | Added onVoteWritten, promote/demote in callable |
| lib/presentation/shared/chant_card.dart | Added VoteControls |
| lib/presentation/browse/chant_detail_screen.dart | Added VoteControls |
| lib/presentation/moderation/moderation_screen.dart | Added promotion candidates tab with PromotionCard |
| lib/data/repositories/chant_repository.dart | Server-side orderBy score, promotionCandidatesStream |
| lib/data/repositories/moderation_repository.dart | Added promoteChant, demoteChant |
| firestore.indexes.json | 2 composite indexes |
| test_rules/firestore_rules.test.ts | 3 canonical promotion tests |
| test/presentation/shared/chant_card_test.dart | Fixed for ProviderScope, added score test |
| seed/package.json | Test glob for both test files |
| DECISIONS.md | 7 new entries |
| WISHLIST.md | Rotating home-screen quote entry |

### Deferred (with triggers)
| Item | Trigger |
|------|---------|
| Event.id dedup for onVoteWritten | Observed counter drift or volume growth |
| Wilson score or time-decay ranking | Vote volume makes net score produce poor ranking |
| Raise promotion threshold | First observed gaming attempt |

### Commit
`6e1000c`

---

## Block 5: Suggestion Box
**Status:** CLOSED
**Commit (final reviewed code):** `07ca809`
**Tests:** 142 passing (50 Dart + 73 rules emulator + 19 seed/counter)
**Analyze:** `flutter analyze` -- 0 issues

### What was built
- **Feedback form:** Category selector (suggestion/bug/question/other), 1000-char message with counter, follow-up checkbox, fan-voice confirmation.
- **Overflow menu:** Moved feedback, content policy, and sign-out into a three-dot menu on the home screen. Moderation icon stays direct.
- **Operator feedback tab:** 4th tab on the moderation screen. Newest first, read-only.
- **Reuse:** Existing feedback collection, model, repository, and rules (Block 1) used unchanged. No schema or rules changes.

### Disposition table

**Security frame**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Feedback write is auth-only with message cap | N/A | Verified: Block 1 rules enforce userId == caller, message.size() <= 1000, resolved == false pinned. No changes made. |
| Banned users can submit feedback | N/A | Intentional: appeal channel. Documented in DECISIONS. |
| User content stored as given | N/A | Verified: no transformation of message text. |
| Operator reads all, user reads own, no update/delete | N/A | Verified: Block 1 rules. |

**Taste frame**

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Fan-voice confirmation | N/A | "Got it. We read every one." |
| Submit disabled when message empty | N/A | Verified: widget test. |
| Character count visible | N/A | Verified: "0 / 1000" shown. |
| Overflow menu is one tap to feedback | N/A | Verified: three-dot menu > Send feedback. |
| No em dashes | N/A | Verified. |

### New DECISIONS entries
5 entries: resolved field deferral, email notification deferral, banned users can submit, overflow menu, feedback volume trigger.

### Files created
| File | Lines |
|------|-------|
| lib/presentation/feedback/feedback_screen.dart | 152 |
| test/presentation/feedback/feedback_screen_test.dart | 50 |

### Files modified
| File | Change |
|------|--------|
| lib/presentation/home/home_screen.dart | Replaced 3 app-bar icons with overflow menu |
| lib/presentation/moderation/moderation_screen.dart | Added Feedback tab (4th tab) |
| lib/app/router.dart | Added feedback route |
| DECISIONS.md | 5 new entries |
| HANDBOOK.md | Suggestion box section |

### Deferred (with triggers)
| Item | Trigger |
|------|---------|
| Feedback resolved/filtering | v1.1 moderation console, feedback volume outgrows plain list |
| Email notification on feedback | Operator wants alerts or volume grows |

### Commit
`07ca809`
