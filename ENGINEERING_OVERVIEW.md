# Chants engineering overview

This is a milestone snapshot of why the code is shaped the way it is, written for someone with read access who has never opened the repo. Every behavioral claim points at the file and symbol behind it, `path/to/file.ext :: symbolName`. Where a document in this repo disagrees with the code, the code wins and the disagreement is recorded here rather than quietly resolved. Historical rationale through 2026-07-18 is in `docs/DECISIONS.md`; new durable decisions live in `docs/decisions/`.

This repo carries two whole-repo handover documents. This one, `ENGINEERING_OVERVIEW.md`, is the map: read it first if you are new here and want to understand the shape of the system before changing it. `docs/IMPLEMENTATION_RATIONALE.md` is a differently structured, more mechanical document written to a fixed external-review template (coverage ledger, invariant and failure tables, a verification log with the actual commands run, a known-compromises table with owner and revisit-trigger columns). They overlap on purpose. Read that one if you are the reviewer that template was built for.

Baseline: commit `f780628` ("Fix the lint issues flutter analyze now actually gates on", 2026-08-10). Before these review and framework documents were added, the working tree had three modified tracked files (`android/app/build.gradle.kts`, `android/settings.gradle.kts`, `pubspec.lock`) and two untracked additions (`AGENTS.md`, `.codex/`). Written 2026-08-17.

## Post-review implementation amendment, 2026-08-17

The original audit narrative below was written before the approved reply and interaction-safety block. Its inherited-system explanations still apply, but findings described there as open are historical when they conflict with this amendment or `docs/CHANGE_SPEC.md`.

The current working tree now implements one direct reply level and the safety prerequisites that the audit identified:

- `lib/data/models/comment.dart :: Comment.parentCommentId` preserves missing/null legacy comments as top-level and identifies direct replies. `lib/presentation/comments/comment_section.dart` groups top-level comments by rank, renders replies oldest-first, never promotes an orphan reply, preserves a failed reply draft, and filters blocked users. `comment_card.dart` never offers Reply on a reply.
- `firestore.rules :: validReplyParent` proves the parent exists, is visible, belongs to the same chant, and has no parent. Interaction creates prove their chant/comment/profile target exists. Directional `blocks` are owner-private, and a block in either direction prevents replies and likes between the two accounts.
- `functions/src/index.ts :: handleChantReportWritten` and `handleCommentReportWritten` replace blind increments with transactional ground-truth counts of pending reports. Duplicate and racing deliveries converge, status changes/deletes lower the count, and falling below the threshold never auto-unhides content.
- Both submission rate limiters now classify account age monotonically. Rules constrain profile, chant, comment, vote, and like client timestamps to the current one-hour window, closing the raw-SDK backdating bypass used by the velocity queries.
- `mergeChants` moves the source chant's full comment/reply thread before deletion. `deleteAccount` now removes `userReports` and both directions of blocks, reconciles report-derived counters, discloses retained anonymized comments/replies, and deletes Auth before the profile so a late Auth failure leaves a retryable account.
- Profiles, votes, and comment likes are no longer world-readable. Profile owners can change only `displayName` and `updatedAt`; chant updates retain the create-time content constraints.
- Failed sign-up completion now attempts the server account-deletion path, with a safe local cleanup/fallback when no profile was created.

Verification performed after the change: `flutter analyze lib test` passed; `flutter test` passed all 182 tests, including the reply-thread and operator-access goldens; Functions passed 26 tests; seed passed 23; and the Firestore emulator passed all 106 rule assertions using the installed Homebrew JDK. The real widgets were rendered and inspected at a 390 x 844 phone viewport in `test/presentation/comments/goldens/comment_reply_thread.png` and at 390 x 300 in `test/presentation/moderation/goldens/user_ban_button.png`. The reply-order guard was proven red by temporarily reversing production reply order, then green after restoration. A live-device keyboard, offline-write, and moderation walk remains the only uncompleted release check because no simulator was booted for the implementation session.

Still open from the original audit: the moderation queue's narrow query, report/feedback rate limits, scalable/batched and resumable account deletion, backup/restore evidence, user-data export, and live deployment-state verification. Product-level unban is now implemented through the operator-only callable and audited in the same way as ban.

## What the product is

Chants is a Flutter mobile app where football supporters find, learn, and add the chants sung on the terraces. A chant is not just lyrics: it carries the tune it is set to, the context that explains when and why it is sung, and optionally a set of alternate versions. Fans vote chants up or down, comment on them, and submit the ones that are missing.

There is no money in the system. There is no payment provider, no subscription, no ads, and no server-side billing logic anywhere in the tree. The entire risk surface of this product is **content safety and moderation**, and the code reflects that: roughly half the Cloud Functions and roughly half the Firestore rules exist to make user-generated content reportable, hideable, rate-limited, and auditable.

The scope is deliberately narrow. One sport (football), one competition (Premier League), one seeded club (Arsenal, `seed_data/clubs/arsenal.json`, 27 squad members and 12 chants). But the data model is agnostic by rule, not by accident: `docs/DECISIONS.md` records "Differentiation through data, never forks. No hardcoded league or sport checks anywhere. Enabling a new league or sport is a data change." Be precise about how far that holds. The **model** is fully agnostic; the **home screen is not**. `lib/presentation/home/home_screen.dart` hardcodes a single "PREMIER LEAGUE" entry tile with the literal ID `'premier-league'`, and `lib/presentation/browse/discovery_section.dart :: allTeamsProvider` hardcodes `competitionId: 'premier-league'` for its team-name lookup. Adding a second competition is a data change plus two small UI changes, not a data change alone.

## What you can and cannot run

Flutter 3.44.8 / Dart 3.12.2 was used to verify this document. `pubspec.yaml :: environment.sdk` pins `^3.10.8`. Node 20 for both `functions/` (declared in `functions/package.json :: engines.node`) and `seed/`.

`flutter test` needs **no** Firebase configuration and runs on a fresh clone: 182 tests after this amendment, all passing in the verified slices described above. Nothing under `test/` imports `lib/firebase_options.dart`, which is the property that makes this true, and it is worth preserving deliberately.

`cd functions && npm test` runs 26 tests with no credentials. It compiles with `tsconfig.test.json` and runs mocha against exported pure handlers and rate-limit classification, using hand-written fake Firestore objects rather than the emulator.

`cd seed && npm test` runs 23 tests with no credentials, covering slug generation, seed-file validation, and counter reconciliation arithmetic.

`cd test_rules && npm test` is the one suite that needs infrastructure: a Java runtime plus `firebase-tools` running the Firestore emulator on `127.0.0.1:8080`. The shell-visible `java` launcher is unconfigured, but Homebrew OpenJDK exists at `/usr/local/opt/openjdk`. With that JDK supplied to `firebase emulators:exec`, all 106 assertions passed locally. CI also runs the suite (`.github/workflows/ci.yml :: rules`) on Java 21 with `firebase-tools@15`.

`flutter analyze` needs `lib/firebase_options.dart`, which the current repository setup gitignores (`.gitignore:72`). Firebase client configuration contains public project identifiers, not a server secret; protection depends on Security Rules, App Check, and appropriate API-key restrictions. Copy `lib/firebase_options.dart.example` first and use configuration for your project. One caveat that will waste your time otherwise: in a tree with a populated `build/` directory, full `flutter analyze` reports 115 issues, all inside generated `build/ios/SourcePackages/` content. Run `flutter analyze lib test` for a clean project-code check, and exclude generated `build/**` paths in a future analyzer cleanup instead of filtering output text.

To actually run the app you need your own Firebase project with Auth, Firestore, and Functions enabled, plus the platform config files (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`), all three of which are gitignored.

## How to read this repo

Start with `AGENTS.md`, then read the current approval state in `docs/CHANGE_SPEC.md` and the accepted decisions in `docs/decisions/`. `CLAUDE.md` is now only a compatibility pointer. The operational rules include server ownership of denormalized counters, mandatory visibility filters on user-content queries, and the seed-content integrity rule.

Then read `firestore.rules` end to end. At 330 lines after the reply/block hardening, it is the real access-control layer, and almost every security property of this system is decided there rather than in Dart. If you are asking "can a user do X", the answer is in that file, not in a screen.

Then read `functions/src/index.ts`, the single densest file at 1,105 lines. It holds all 11 Functions exports in source, the moderation action dispatch, the rate limiters, the counter recompute logic, and account deletion. Whether all 11 exports match the live deployment was not inspected in this review.

Then `lib/presentation/shared/vote_controls.dart :: OptimisticVoteState` and `lib/presentation/comments/comment_card.dart :: CommentLikeState`. These two small state classes carry more accumulated bug history than the rest of the app combined, and understanding them is understanding the hardest thing this codebase does.

Then use `docs/DECISIONS.md` for historical context through 2026-07-18. It is a valuable archive, but new decisions and supersessions live in individual records under `docs/decisions/`.

For anything about a specific collection's access rules, grep `firestore.rules` for the collection name. Rules are defined in one place per collection, which is a real advantage over systems where policy accumulates across migrations.

## Stack

| Layer | What shipped | Version |
|---|---|---|
| Client | Flutter, Dart, Material 3, dark theme only | SDK `^3.10.8`, verified on Flutter 3.44.8 |
| State | Riverpod, hand-written providers in one file | `flutter_riverpod ^2.6.1` |
| Auth | Firebase Auth, email and password only | `firebase_auth ^6.5.1` |
| Database | Cloud Firestore, repository records `europe-west2`; live location unverified | `cloud_firestore ^6.4.1` |
| Server | Cloud Functions v2, TypeScript, exports configured for `europe-west2` | `firebase-functions ^6.3.0`, `firebase-admin ^13.0.0` |
| Integrity | Firebase App Check, DeviceCheck and Play Integrity | `firebase_app_check ^0.4.4+1` |
| Crash reporting | Firebase Crashlytics | `firebase_crashlytics ^5.2.2` |
| Seeding | Node script using the Admin SDK | `firebase-admin ^13.0.0` |
| Tests | flutter_test, mockito, mocha, `@firebase/rules-unit-testing` | mocha 11, rules-unit-testing 4 |

`docs/DECISIONS.md` records the stack choice as locked with no "or": Flutter plus Firebase because the product is genuinely mobile-first, and Firebase covers auth, database, functions, and push without standing up infrastructure. React plus Supabase was rejected explicitly for pulling the product web-first. Riverpod over Bloc because the app has no complex state machines and Riverpod's provider overrides make testing cheap, which the test suite then actually exploits.

Two things are absent and worth knowing. There is **no code generation in the build**, despite `riverpod_generator`, `build_runner`, and `riverpod_annotation` sitting in `pubspec.yaml :: dev_dependencies`. There are no annotated providers. `lib/app/providers.dart` is 82 lines of hand-written `Provider` and `StreamProvider` declarations, and there is no `.g.dart` file anywhere in `lib/`. The generator dependency is vestigial; the canonical agent guidance no longer claims otherwise. Second, `firebase_storage` was deliberately removed from `pubspec.yaml` (`docs/DECISIONS.md`, C10) because no media upload ships in v1, and `storage.rules` is a 10-line deny-all placeholder held in the repo for whenever media does ship.

## Data model

Fifteen Firestore collections, all top-level, no subcollections anywhere. The fifteenth is the directional, owner-private `blocks` collection added by the interaction-safety block.

`sports`, `competitions`, `teams`, `players` are the reference hierarchy, publicly readable and operator-writable, populated only by the seed script. `chants` is the core content collection. `votes`, `comments`, `commentLikes` are the interaction collections. `reports`, `commentReports`, `userReports` are the three parallel abuse-report collections. `profiles` holds user state. `feedback` is the suggestion box. `auditLog` is the moderation trail.

The single most consequential modeling decision is that **chants live in one flat top-level collection with denormalized `sportId`, `competitionId`, `teamId`, and `playerId`** (`lib/data/models/chant.dart :: Chant`), rather than nested under team subcollections. `docs/DECISIONS.md` gives the reason directly: this makes both the drill-down query (`where teamId == X`) and the cross-club discovery shuffle (all chants, no parent constraint) cheap with no joins and no `collectionGroup` queries, and it means a future search index has one document type to read. Deep subcollections were rejected because the topology is expensive to undo later. This has held up well; nothing in the codebase fights the flat model.

Three document-ID conventions do structural work that would otherwise need enforcement code:

- `votes/{userId}_{chantId}` (`lib/data/models/vote.dart :: Vote.documentId`) makes one-vote-per-user-per-chant a property of the key space, not a check. `firestore.rules:119` asserts the ID matches `request.auth.uid + '_' + request.resource.data.chantId`, so a user cannot forge a vote under someone else's key even with a raw SDK write.
- `commentLikes/{userId}_{commentId}` (`lib/data/models/comment_like.dart :: CommentLike.documentId`), same pattern, same rule at `firestore.rules:178`.
- `reports/{userId}_{chantId}`, `commentReports/{userId}_{commentId}`, `userReports/{reporterId}_{reportedUserId}`, all three asserted in rules. Duplicate reports are structurally impossible, which is what makes the flag-count threshold mean "three distinct people complained" rather than "someone tapped three times".

Seed documents use slugs rather than random IDs: `seed/slugify.ts :: slugify` and `:: compositeSlug` produce `arsenal`, `arsenal-bukayo-saka`, `arsenal-north-london-forever`. This makes reseeding idempotent by construction, which is the whole point of the upsert path described below.

Counters (`upvotes`, `downvotes`, `score`, `commentCount` on chants; `likeCount` on comments; `userReportCount` on profiles) are denormalized onto the parent document. `docs/DECISIONS.md` explains this as working around Firestore's weakness at live ranked queries, and notes that the fields were defined at zero from the very first block even though voting shipped three blocks later, specifically so the write paths and security rules would never need a retrofit or a backfill.

## The counter architecture

This is the most distinctive engineering property of the codebase and the one worth understanding first.

Every counter is **recomputed from ground truth on every trigger invocation**, never incremented. `functions/src/index.ts :: handleVoteWritten` does not apply a delta; it queries every vote document for the chant, counts them, and writes absolute values. `:: handleCommentLikeWritten` does the same for likes. `:: recomputeCommentCount` does the same for comment counts. `:: handleUserReportCreated` does the same for user report counts.

The reason is recorded precisely in `docs/DECISIONS.md` (2026-07-02): the original implementation used blind `FieldValue.increment`, and Cloud Functions triggers are at-least-once. Duplicate deliveries double-applied deltas. The observed symptom was a chant sitting at `-11/-11` from a single `-1` vote. Recompute-from-ground-truth makes the function idempotent under duplicate delivery, out-of-order delivery, and bursts, all of which converge to the correct value. It also makes drift self-healing: whatever went wrong, the next write on that chant corrects it.

The cost is a full collection query per trigger invocation, which is the trade this codebase accepted knowingly.

There is a second-order piece to this that is easy to miss. `handleVoteWritten` commits the chant counter update and the `appliedValue` stamp on the vote document in **one `WriteBatch`** (`functions/src/index.ts:352-372`). The comment on that batch explains why: without atomicity, a client can observe the updated score before `appliedValue` lands, conclude that its own vote is not yet counted, and double-apply its optimistic delta. That is the "-2 flash". Writing `appliedValue` back to the vote document re-triggers `onVoteWritten`, and the early return at line 335 (`if (upDelta === 0 && downDelta === 0) return`) is what stops that from looping. The same pattern, with the same reasoning, is in `handleCommentLikeWritten`.

`flagCount` now follows the same rule. `functions/src/index.ts :: recomputeReportCount` counts pending chant or comment reports inside a transaction and writes the absolute result. The trigger wrappers write audit entries only after the transaction returns. Duplicate delivery, status changes, deletes, and transaction retries therefore converge without double-counting or producing an audit as a transaction side effect.

## The reconciliation problem, and why two state classes exist for it

Optimistic UI on a system where the authoritative counter is written by an asynchronous background function is genuinely hard, and this codebase learned that the expensive way. `docs/DECISIONS.md` and `docs/KNOWN_ISSUES.md` between them record four separate rounds of fixes for the same surface.

The invariant that finally worked is stated in the decision log for 2026-06-29 and implemented in `lib/presentation/shared/vote_controls.dart :: OptimisticVoteState`:

> displayed score = server score + (intended vote - last confirmed vote)

The delta is **assigned, never accumulated** (`:: applyVote` calls `deltaForTransition(confirmedVote, newVote)`, which is a pure subtraction). It collapses to zero only in `:: reconcileServerScore`, when the Firestore stream delivers a new server score, and specifically **not** in `:: confirmWrite`, which only clears the busy flag. The reason this distinction matters is written into the decision log: `confirmWrite` fires when the local Firestore write resolves, roughly a second before `onVoteWritten` updates the denormalized score. Collapsing the delta at that moment displays the stale pre-vote score, the user sees a snap-back, and a follow-up tap then computes against a stale baseline and produces a visibly wrong number.

The rapid-tap problem needed a second mechanism. `_VoteControlsState._onVote` holds a busy guard: if a write is in flight, the tap updates optimistic display state immediately (so the UI never looks frozen) but sets `_hasPendingChange` instead of firing a second concurrent write. When the in-flight write completes, `:: _writeSettledIntent` writes the **already-settled** `userVote` directly. It deliberately does not re-call `applyVote`. The decision log for 2026-07-04 explains why in detail: the earlier version stored the raw tap value and replayed it through `applyVote`, which re-toggled the intent (a settled "off" flipped back "on"), producing a wrong follow-up write and a transient `-2`. The latch became a boolean specifically to remove the re-toggle.

Cold load is the third piece, and it is why `appliedValue` exists at all. When the screen opens, the client cannot tell from the chant's score alone whether that score already includes this user's stored vote. `_loadUserVote` reads the vote document and compares `vote.appliedValue` with `vote.value`. Equal means the Cloud Function has processed exactly this vote and the score includes it (`confirmedVote = value`, delta 0). Not equal, or absent, means the function has not caught up, so `confirmedVote` is set to whatever the server has actually applied (null for a brand-new vote, the old value for a flip) and the delta is computed from that. `lib/data/models/vote.dart :: Vote.toJson` deliberately omits `appliedValue` so a client write can never clobber the server's stamp.

Comment likes reimplement the same three-part protocol in `lib/presentation/comments/comment_card.dart :: CommentLikeState`, as an **immutable** class with `copyWith`-style transitions rather than the mutable field bag `OptimisticVoteState` uses. That divergence is not explained anywhere. The comment on `CommentLikeState` argues that a like is a simpler thing (a binary toggle with a delta of 0 or +1, not a three-state vote), which justifies the different shape but not the different mutability idiom. Two implementations of the same protocol is a real maintenance cost, and if a fourth reconciliation bug appears it will need fixing twice.

One more thing on this surface, recorded in `docs/DECISIONS.md` for 2026-07-04. `lib/presentation/comments/comment_section.dart` reads comments through a `StreamSubscription` created in `initState` and re-created in `didUpdateWidget`, not through a `StreamBuilder`. That is unusual Flutter and looks like a mistake until you know the history: the `StreamBuilder` version called the like-state reconciler inside its builder, which called `setState` during build, and the comment section crashed whenever a like arrived while the widget was building. Moving reconciliation into the subscription listener made `build` pure. The trade-off is that the manual subscription has to handle chant swaps itself, which `didUpdateWidget` does. There is a regression test for the crash at `test/presentation/comments/comment_section_like_crash_test.dart`.

The strongest testing rule in this project comes out of this same surface, and is recorded as a standing decision on 2026-06-29: a stream-reconciled widget requires a **widget-level** regression test that pumps the real widget and asserts on rendered output. A unit test of the state class alone is explicitly not accepted. The reason is that the `OptimisticVoteState` unit test had asserted the snap-back **as the expected result**, so it stayed green while voting was visibly broken on device. `test/presentation/shared/vote_controls_widget_test.dart` is the test that rule produced, and per the log it was verified by reintroducing the bug and confirming it fails.

## Access control

`firestore.rules` denies by default and grants narrowly. Four helper functions carry most of the logic: `isAuth()`, `isOperator()` (a `get()` against the caller's profile document, checking `role == 'operator'`), `isVisible(res)` (`hidden == false && removed == false`), `isNotBanned()`, and `hasAcceptedPolicy()`.

Operator role lives in a Firestore document read via `get()`, not in a custom auth claim. `docs/DECISIONS.md` records this as a deliberate volume-appropriate choice with two explicit migration triggers: when any single rule would need to chain a second `get()`, or before operator actions extend beyond the founder account. Worth noting that a `chants` create by a signed-in user currently costs **two** `get()` calls already (`isNotBanned()` and `hasAcceptedPolicy()` each read the same profile document independently), so the first trigger is arguably closer than the log suggests.

**Privilege escalation is closed on both halves.** `docs/DECISIONS.md` states the rule as a standing principle: privileged fields must be *both* pinned on create *and* blocked on self-update, because create-pinning alone is half the protection. Concretely, `firestore.rules:57-75` pins `role == 'user'`, `banned == false`, `ageConfirmed17Plus == true`, `userReportCount == 0` on profile create, requires `acceptedPolicyVersion` and `acceptedPolicyAt` to be **absent** on create, and then blocks all six of those keys from ever appearing in an update diff. A user cannot promote themselves to operator, cannot unban themselves, cannot forge policy acceptance, cannot zero their own report count. `test_rules/firestore_rules.test.ts` has explicit assertions for every one of those.

**Query-shape enforcement** is the property most likely to surprise you. `firestore.rules:79` reads `allow read: if isVisible(resource) || isOperator()`. In Firestore, a `list` query is only permitted if the rules can be satisfied for every document the query *could* return, which means a chant query without `where('hidden', '==', false)` and `where('removed', '==', false)` is rejected **entirely**, not filtered. `lib/data/repositories/chant_repository.dart :: _visibleChants` is the single enforcement point on the client side, and `AGENTS.md` calls this out as a gotcha because the failure mode (whole query denied) does not look like a visibility problem. `test_rules/firestore_rules.test.ts :: "chant list query boundary"` asserts all three cases including the partial-filter case.

**Content moderation actions never trust the client for identity.** `functions/src/index.ts :: onModerationAction` derives the actor from `request.auth.uid` and re-reads the profile through the Admin SDK to verify the operator role. `:: mergeChants` repeats the same check. `:: deleteAccount` and `:: acceptPolicy` likewise derive the subject from auth context, which is what makes `acceptPolicy` the only source of truth for consent: the version string and the timestamp are both decided server-side, and the rules forbid the client from writing those two fields at all.

Three things about the rules are worth flagging rather than praising.

First, `profiles` are **publicly readable in full** (`firestore.rules:58`, `allow read: if true`). That exposes every user's `displayName`, `role`, `banned` flag, and `userReportCount` to any client, authenticated or not. `displayName` is already public on comments so that part is uncontroversial, but "is this user banned" and "how many people have reported this user" are moderation state, and there is no reason for the client to be able to enumerate them. Nothing in `docs/DECISIONS.md` records this as considered.

Second, `votes` are publicly readable (`firestore.rules:115`). Since the document ID is `{userId}_{chantId}`, anyone can enumerate exactly which chants any given user upvoted or downvoted. The client only ever reads its own vote (`lib/data/repositories/vote_repository.dart :: getUserVote` is a single-document get by composite ID), so this read permission is broader than any code path needs.

Third, **chant validation is enforced only on create, and only partially.** `firestore.rules:80-102` checks lengths for `title` (200), `lyrics` (5000), `tuneName` (200), `contextNotes` (500), and pins every counter to zero. But the update rule at `firestore.rules:104-108` is a pure blocklist: the author may change anything not in `['upvotes','downvotes','score','commentCount','flagCount','hidden','removed','status','createdBy','createdAt']`. That means an author can create a valid chant and then update `lyrics` past 5000 characters, or change `teamId` to move the chant to a different club. Neither the create nor the update rule validates that `subjectTag`, `chantType`, or `mediaType` are members of the valid sets that `lib/data/models/chant.dart` declares as `validSubjectTags`, `validMediaTypes`, and `validStatuses`; those constants exist in Dart and are asserted in model tests, but nothing enforces them at the write boundary.

## Timestamps, and the hole in rate limiting

This one deserves its own section because it undercuts a security control.

Nearly every client write in this app stamps its own `createdAt` from the device clock. `lib/data/models/chant.dart :: Chant.toJson` writes `Timestamp.fromDate(createdAt)` where `createdAt` came from `DateTime.now()` in `lib/presentation/submit/submit_chant_screen.dart :: _submit`. `Comment.toJson`, `Vote.toJson`, `Report.toJson`, `UserReport.toJson`, and `FeedbackEntry.toJson` all do the same. The one exception in the whole client is `lib/data/repositories/comment_repository.dart :: submitCommentReport`, which uses `FieldValue.serverTimestamp()`. Nothing in `firestore.rules` constrains `createdAt` on any of these collections (the profile rule requires it to *be* a timestamp, but not to be a plausible one).

Now look at what reads those timestamps. `functions/src/index.ts :: onChantCreated` rate-limits by counting `chants` where `createdBy == userId` and `createdAt >= oneHourAgo`. `:: onCommentWritten` does the same for comments. Both also compute account age from `profiles/{uid}.createdAt`, which is likewise client-written at sign-up (`lib/data/repositories/profile_repository.dart :: createProfile`).

So a client using the raw SDK can write `createdAt` far in the past and the velocity query will never see the document. The rate limiter is bypassable by anyone willing to skip the app. `docs/DECISIONS.md` is explicit that v1 rate limiting is "soft enforcement" and not hard server enforcement, with the stated hardening trigger being observed spam abuse and the stated fix being to route submission through an HTTPS callable. That is the right fix and it is already the recorded plan. But the decision log frames the softness as "auto-hide instead of auto-remove", not as "trivially evadable", and the gap between those two framings is worth closing in the log.

There is a second, smaller defect in the same rate limiter, independent of timestamps. `functions/src/index.ts:285-289` computes:

```ts
const isNew = accountAge < NEW_ACCOUNT_AGE_MS || totalSubmissions <= NEW_ACCOUNT_MIN_SUBMISSIONS;
const limit = isNew ? NEW_ACCOUNT_LIMIT : PROVEN_ACCOUNT_LIMIT;
if (totalSubmissions > limit) { /* auto-hide */ }
```

with `NEW_ACCOUNT_LIMIT = 2`, `PROVEN_ACCOUNT_LIMIT = 5`, `NEW_ACCOUNT_MIN_SUBMISSIONS = 3`. For an established account (older than 24 hours) posting its **third** chant in an hour: `totalSubmissions = 3`, so `3 <= 3` makes `isNew` true, the limit becomes 2, and `3 > 2` auto-hides it. For the **fourth**: `4 <= 3` is false, `isNew` is false, the limit becomes 5, and `4 > 5` does not fire. The third submission is hidden and the fourth and fifth are not. The `totalSubmissions <= NEW_ACCOUNT_MIN_SUBMISSIONS` clause was presumably meant to treat low-history accounts conservatively, but because `NEW_ACCOUNT_LIMIT` (2) is below `NEW_ACCOUNT_MIN_SUBMISSIONS` (3) it produces a non-monotonic limit. The comment path does not have this problem, because its new-account limit (5) is above the same threshold (3).

## The moderation system

Three parallel report collections feed one operator console.

`reports` targets chants, `commentReports` targets comments, `userReports` targets accounts. All three are insert-only for clients (no update or delete rule exists), operator-read-only, deduped by document ID, and blocked for banned users. `userReports` additionally forbids self-reporting (`firestore.rules:208`).

Chant and comment reports increment `flagCount` and auto-hide at three distinct reporters. User reports deliberately do **not** auto-act: `functions/src/index.ts :: handleUserReportCreated` only recomputes `userReportCount` so the profile surfaces in the moderation console, and the comment above it states the reasoning directly, that banning stays operator-only and manual. That asymmetry is correct. Auto-hiding a chant is reversible and low-cost; auto-banning a person is neither.

Auto-hide is always **hide, never remove**. This is consistent across every automatic path: the flag threshold, both rate limiters. Hidden content is invisible to users but recoverable by an operator; removed content is a deliberate human act.

`onModerationAction` closes the loop in a way that is easy to get wrong and this code gets right. On `unhide`, it sets `hidden: false` **and resets `flagCount` to 0** and dismisses the associated reports (`functions/src/index.ts:106-121`). Without the reset, a chant cleared by an operator would sit at `flagCount = 3` and re-hide on the very next report. `docs/DECISIONS.md` records this as "Fix 4" and it is the kind of detail that only shows up after someone has watched a false positive bounce back.

`mergeChants` handles part of the duplicate-content case: it moves votes and reports from a source chant to a target chant (skipping any where the user already has a row on the target, so the one-per-user invariant survives), deletes the source, reconciles the target's counters from ground truth as a safety net, and writes selected source fields into the audit log. The historical decision archive describes this as a full, recoverable snapshot, but the payload omits fields and related interaction documents. It is evidence for manual reconstruction, not a complete undo record.

`mergeChants` now moves every source comment, including replies, before deleting the source chant. Comment-like documents remain attached to stable comment IDs, so they move with the thread without a rewrite. The target vote and comment counters are recomputed after the move. The audit payload remains evidence for reconstruction rather than a transactional undo mechanism.

The operator console is `lib/presentation/moderation/moderation_screen.dart`, six tabs, 647 lines, entirely `StreamBuilder`s over raw `FirebaseFirestore.instance` queries rather than the repository layer used everywhere else. Two things about it are worth knowing. The "Flagged" tab's own comment says it queries "chants with flagCount > 0 or hidden or removed", but the query is `where('hidden', isEqualTo: true)` only. A chant sitting at one or two flags, below the auto-hide threshold, never surfaces for review, and neither does a removed chant. The comment describes an intent the code does not implement. Second, the "Reported users" tab carries a genuinely useful comment explaining why it uses an equality/range-only query with client-side sorting: to avoid needing a composite index, matching the tradeoff taken elsewhere in the app.

**Ban is reversible without weakening profile rules.** `onModerationAction` handles both `ban` and `unban` after proving the caller is an operator. `ModerationRepository` exposes both actions, and the moderation screen supports reversal from a reported-user card or by user ID. The direct client still cannot update `profiles.banned`; the Admin SDK callable owns the mutation and audit entry.

## Content policy and store compliance

Three compliance gates ship, all recorded as DONE in `docs/ROADMAP.md`, all built as tightly-coupled client/server/rules trios.

**Policy acceptance.** A version string, `'v1'`, is duplicated in three places that have no shared-constant mechanism between them: `lib/app/policy.dart :: kCurrentPolicyVersion`, `functions/src/index.ts :: CURRENT_POLICY_VERSION`, and the literal `'v1'` inside `firestore.rules :: hasAcceptedPolicy`. All three files carry a comment pointing at the other two and warning that a bump re-gates every existing user. That is the correct mitigation for a constraint that cannot be removed (Dart, TypeScript, and the CEL-like rules language genuinely cannot share a constant), and it is documented rather than hidden.

The enforcement is layered properly. The rules refuse chant and comment creates without acceptance (`firestore.rules:82` and `:151`), so the gate is real and not merely a UI screen. `lib/app/app.dart :: _SignedInGate` watches the profile stream and shows `PolicyAcceptanceGateScreen` when the stored version does not match. That gate has three carefully chosen edge behaviors, documented in the class doc comment: `loading` and `data(null)` both show a neutral loading screen rather than the gate, because a brand-new user has a live auth session for a moment before `createProfile` lands and must not be flashed a "you must accept" screen; and a stream **error fails open to HomeScreen**, on the stated reasoning that a transient read failure must never lock a user out of the app. Failing open is the right call here precisely because the rules layer is still closed: an unaccepted user who reaches HomeScreen simply cannot write anything.

**Age check.** `lib/data/services/age.dart :: calculateAge` is a pure function taking `now` as a parameter, which makes it directly testable with no clock injection, and `test/data/services/age_test.dart` exercises it. The date of birth is used once, at sign-up, and **never persisted**: only the boolean result reaches Firestore as `ageConfirmed17Plus`, and `lib/presentation/auth/sign_up_screen.dart` carries an explicit comment saying so. The rules then pin that field to `true` on create and block it from update, so a user cannot later flip it. Collecting the minimum and storing the derived answer rather than the raw personal datum is the correct privacy posture and it was clearly deliberate.

**Report a user.** Described above. `docs/ROADMAP.md` records its own known gaps honestly, and they are real: a user who only submits chants and never comments cannot be reported through the UI at all, because no screen displays a chant's author; and none of the three report collections are rate-limited the way chant and comment creation are.

User blocking is now implemented with owner-private directional block documents, client visibility filtering, server denial of reply and like interaction in either direction, an Undo path, and a blocked-users screen. The remaining compliance blocker is the content policy text: `lib/presentation/content_policy/content_policy_screen.dart :: ContentPolicyBody` still renders placeholder copy. The version string `'v1'` is stamped against placeholder text, so writing the real policy requires a deliberate version bump and re-gates existing accounts.

## Account deletion

`functions/src/index.ts :: deleteAccount` exists because Apple 5.1.1(v) and Google Play both require in-app account deletion. It removes votes, every report type, feedback, comment likes, and both directions of block relationships; reconciles affected counters; anonymizes retained chants, comments, and replies; writes the audit; deletes Auth; then deletes the profile. Auth is deleted before the profile so a failed Auth deletion leaves a retryable signed-in account. The flow is still sequential and non-resumable at scale.

The anonymize-rather-than-delete choice for chants and comments is deliberate. The confirmation dialog now discloses that submitted chants, comments, and replies stay with identifying account information removed.

Three problems with the implementation.

It does not touch `userReports` in either direction. Reports **filed by** the deleting user survive with their UID as `reportedBy` (the moderation console renders that raw UID). Reports **against** them survive too, and the `userReportCount` on any profile they reported is never recomputed after their reports are... actually left in place, so counts stay consistent, but their own reports remain attributable to a deleted account. `reports` and `commentReports` are both cleaned up. `userReports` was added later and the deletion path was not extended.

It is not atomic and not resumable. Ten sequential steps, each a separate await, no transaction, no batch, no idempotency marker. A failure at step 6 leaves the user with no votes and no reports but a live profile and a live auth account. Most early failures can be retried because the preceding deletions are idempotent. A late failure after profile deletion can strand an authenticated user without the profile the app expects, so the generic retry message is not a reliable recovery plan.

It does not scale. Every step is a sequential per-document `await` inside a `for` loop. A user with several hundred votes performs several hundred round trips inside a callable that has a default 60-second timeout. At current volume this is fine and at any real volume it is not.

## Seeding and content integrity

The highest-priority standing rule in this project, preserved in `AGENTS.md` and the historical decision archive, is that seed content is externally sourced and hand-verified, and the pipeline may only transform supplied data in place. It never generates or rewrites lyrics or squads. For an archive of real cultural material whose value is its authenticity, that is the correct rule, and it is stated as the highest-integrity rule in the project rather than as a preference.

`seed/seed.ts` is an Admin SDK script, run manually with a service account key that is gitignored (`.gitignore:60-61` covers both `serviceAccountKey.json` and `*-firebase-adminsdk-*.json`). It validates every file before writing anything (`seed/validate.ts`), and it computes deterministic slugs so a re-run targets the same documents.

The re-run safety property is the interesting part. `seed/seed.ts :: upsert` takes an explicit list of content fields per document type (`CONTENT_FIELDS_CHANT`, `CONTENT_FIELDS_PLAYER`, `CONTENT_FIELDS_TEAM`). On create it writes the full document; on update it writes **only** the listed content fields plus `updatedAt`. Counters, `flagCount`, `hidden`, `removed`, `createdBy`, and `createdAt` are structurally unreachable from a reseed. That means correcting a typo in a lyric cannot silently reset a chant's vote tally or un-hide something an operator hid. It is an allowlist, not a blocklist, which is the right direction for this kind of guard.

`seed/validate.ts :: validateClub` catches the class of error that would otherwise corrupt the archive quietly: it dedupes on the **computed slug** rather than the raw name, so two squad members or two chant titles that slugify to the same document ID are rejected at validation time rather than silently overwriting each other in Firestore. It also enforces `subjectTag`/`playerName` consistency in both directions (a `player` chant must name a squad member, a non-player chant must have a null `playerName`), which is exactly the integrity constraint the security rules do not enforce on user submissions.

`seed/seed.ts :: reportOrphans` reports but never deletes documents that exist in Firestore but not in the seed file. Reporting rather than deleting is right: an orphan might be a community submission, not a stale seed row, and the script cannot tell.

`seed/reconcile.ts` is the manual repair tool for counter drift, recomputing `upvotes`, `downvotes`, and `score` for one chant or all chants from the votes collection. It is the same computation as `handleVoteWritten`, implemented separately. Given that the trigger is already idempotent, this exists as a belt-and-braces operational tool.

## Testing

| Suite | Count | Needs | Verified here |
|---|---|---|---|
| `flutter test` | 182 | nothing | yes, all pass |
| `cd functions && npm test` | 26 | nothing | yes, all pass |
| `cd seed && npm test` | 23 | nothing | yes, all pass |
| `cd test_rules && npm test` | 106 assertions | Java plus emulator | yes, all pass with Homebrew OpenJDK |

The Cloud Functions tests take an approach worth noting. The four handlers with real logic are extracted as pure exported functions (`handleVoteWritten`, `handleCommentLikeWritten`, `handleAcceptPolicy`, `handleUserReportCreated`) that take a `Firestore` instance as a parameter, so the tests drive them with a hand-written fake and no emulator. The doc comments on `handleAcceptPolicy` and `handleUserReportCreated` explain the one constraint this creates: they deliberately do **not** write their own audit entries, because `writeAuditEntry` reaches for the global `admin.firestore()` and would break the injection. That is a clean seam, honestly documented. The consequence is that the untested code is exactly the thin trigger wrappers, plus the four callables with no extracted core (`onModerationAction`, `deleteAccount`, `mergeChants`), plus the two report triggers with the transaction and increment logic. The functions with the most branches have the least test coverage.

The Flutter suite is weighted toward models and the two reconciliation surfaces. Thirteen model round-trip tests, three service tests, and eleven presentation tests, several of which are named for the specific bug they guard (`comment_section_like_crash_test.dart`, `like_reconciliation_test.dart`, `vote_controls_widget_test.dart`). `test/app/app_gate_test.dart` covers the policy gate's loading, null-profile, error, and accepted branches against the real `ChantApp` widget with faked repositories.

The rules suite is the broadest by assertion count, and its structure is the reason to trust it: it seeds privileged state through `testEnv.withSecurityRulesDisabled` and then asserts from an ordinary authenticated context, so it is testing what a real client can do rather than what the test harness can do.

CI (`.github/workflows/ci.yml`) runs five jobs on every branch push: `flutter-test`, `flutter-analyze`, `functions`, `seed`, `rules`. The rules job pins Java 21 and `firebase-tools@15`, and commit `b0bf2e2` records that the Java version was reverted to 21 because `firebase-tools@15` requires it, which is the kind of thing worth having in the log.

One structural gap remains in CI. The `flutter-analyze` job depends on a `FIREBASE_OPTIONS_DART` repository secret, and when that secret is absent the job prints "Skipping analyze" and exits 0. The latest HEAD run inspected during this review, GitHub Actions run `31396879847`, passed all five jobs and executed analyze, so the secret was available to that run. The workflow still fails open for forks or future secret loss and should be changed to fail loudly or display an explicit non-passing skip. GitHub's API also reported no branch protection on `main`, so green jobs are evidence, not a merge requirement.

## Design system

Worth a short section because it is unusually disciplined for a solo project.

The design system is centralized in `lib/app/colors.dart`, `lib/app/spacing.dart`, and `lib/app/theme.dart`, but it is not absolute. A full search of `lib/presentation/` finds 17 literal `fontSize` declarations across 11 files and one raw color literal at `lib/presentation/shared/gold_foil_badge.dart:30`. The historical decision archive's claim of zero presentation-layer literals is stale. The token system is still the dominant pattern and new work should use it.

Two token decisions carry real reasoning. `AppColors.textFaint` (`#6B5F4A`) is documented as decorative only and never body text, with the contrast ratio (3.0:1 on near-black) that fails WCAG AA for normal text written into the decision log. And `docs/DECISIONS.md` for 2026-06-01 records that variable fonts require an explicit `FontVariation` on the `wght` axis, because a `pubspec.yaml` weight declaration alone leaves a variable font rendering at its default weight. `lib/app/theme.dart` carries that as a comment block at the top with `_fraunces400`, `_nunito400`, `_nunito700` constants, and it is the kind of platform gotcha that costs an afternoon if it is not written down.

Dark mode only, forced (`lib/app/app.dart` sets `themeMode: ThemeMode.dark` and passes the same `ChantTheme.dark` as both `theme` and `darkTheme`). `docs/DECISIONS.md`: the near-black palette is the identity, light mode is a separate design exercise, deferred.

## Corrections applied during this review

These claims were checked against the tree and corrected in the active documents as part of the 2026-08-17 framework adoption:

- README listed nine deployed functions. Source contains eleven exports, and live deployment state was not inspected.
- README's earlier unban claim is now backed by the operator-only implementation; account-deletion wording now matches retained anonymized content.
- README's Flutter test count was 141; the verified count is 174.
- The duplicated agent guides claimed Riverpod code generation that the project does not use. `AGENTS.md` is now canonical and `CLAUDE.md` is a compatibility pointer.
- The June roadmap still deferred all replies. The accepted decision now places one reply level in v1 and leaves deeper nesting and notifications for v1.1.
- `docs/DECISIONS.md` and `docs/BLOCK_RECAPS.md` are now clearly marked as historical archives.

Two stale code-adjacent documents still need later cleanup:

- `lib/presentation/moderation/moderation_screen.dart:19` says its query covers sub-threshold flagged and removed chants, but the query is `hidden == true` only.
- `docs/KNOWN_ISSUES.md` reads as current but omits July and August work. Treat it as an older snapshot until it is migrated or retired.

## Where I most want your eyes

Ordered by what I would want a reviewer to look at first.

1. **The moderation queue query remains narrower than its comment claims.** It loads hidden chants, not every sub-threshold flagged or removed chant, so operator review coverage is incomplete.

2. **Reports and feedback have structural deduplication but no velocity limit.** A single account cannot report the same target twice, but it can still flood distinct targets or feedback rows.

3. **Account deletion is sequential and non-resumable.** The ordering is safer and the covered collections are complete, but a mid-flow infrastructure failure still needs a retry rather than a durable job state.

4. **The real content policy text is still a launch blocker.** The current acceptance mechanics are sound, but the accepted text remains placeholder content and will require a version bump.

5. **User-content blocking is enforced asymmetrically by storage constraints.** Rules deny reply and like interaction in either direction, while hiding already-public comments is a client visibility filter because a public collection query cannot evaluate a viewer-specific block relation per returned document.

6. **Live Firebase state remains unverified from the repository.** App Check enforcement, deployed Functions, indexes, backup policy, and dashboard controls need explicit release verification.

7. **The full moderation callable lacks an emulator-level end-to-end test.** Focused handlers and rules are covered, but role and auth wiring across the deployed callable boundary is still source-inspected.

8. **The merge audit is not an automatic undo.** It records source data and move counts, but reversing a mistaken merge still requires an operator reconstruction procedure.

9. **Interaction writes do not prove their target exists.** Crafted votes, comments, likes, and report documents can point at missing parents because the rules validate ownership and key shape but do not use `exists()` for the target.

10. **Sign-up can strand an authenticated user without a profile.** `SignUpScreen._signUp` creates the Firebase Auth user and then writes the profile with no compensation if the second operation fails.

11. **Users are gated on accepting a content policy whose text is a placeholder.** Writing the real policy will force a version bump and re-gate every existing account.

12. **`ChantMatcher` is fully implemented and thoroughly tested but wired to nothing.** `lib/data/services/chant_matcher.dart` has 84 lines of Jaccard-similarity duplicate detection and 13 tests, and no screen calls it. The roadmap keeps the dedup nudge as future work, so it is dead code by plan rather than by accident, but it is dead code today.

13. **`android/app/build.gradle.kts` signs release builds with the debug key**, per the scaffold TODO that is still present. That blocks any real store release and is not tracked in `docs/ROADMAP.md`'s launch checklist.

## Unverified

Things stated in this document or in the repo that could not be confirmed against the tree or a running system at this baseline:

- Every claim about what the Firestore rules permit or deny is read from `firestore.rules` and cross-checked against `test_rules/firestore_rules.test.ts`, but the rules suite **was not executed** here (no Java runtime). CI is the only evidence that it passes.
- No deployed Firebase project was inspected. Whether the deployed rules, indexes, and functions match this tree is unknown. App Check mode, billing alerts, kill-switch state, and the current repository-secret dashboard were not inspected. The latest GitHub Actions run proves only that `FIREBASE_OPTIONS_DART` was available to that run.
- `firestore.indexes.json` declares two composite indexes. Whether they are built in the live project was not checked.
- Seed status: the tree contains exactly one club file (`seed_data/clubs/arsenal.json`). Whether anything beyond it has been seeded into a live project is not knowable from here. `README.md` says Arsenal is fully seeded and the rest are being added, which is consistent with the tree but is a claim about a database, not about code.
- No performance or cost measurement of any kind exists in this repo. The discovery shuffle fetches every visible chant with no limit (`lib/data/repositories/chant_repository.dart :: discoveryChants`), which is fine at Arsenal-only volume and is documented with an explicit revisit trigger, but nothing has been measured.
- The screenshots in `docs/screenshots/` were not compared against the current UI.
