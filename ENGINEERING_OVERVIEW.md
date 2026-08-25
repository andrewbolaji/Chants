# Chants engineering overview

This is the current whole-project map for Chants. It describes the combined state of stacked draft PRs 4 through 9 at commit `b72f4abddea0cd8a3b201de2d4dda246c62a413c`, reviewed on 2026-08-25. The stack changes 136 files relative to `main`, with 14,557 insertions and 1,546 deletions. Every material claim names the implementation path and symbol that supports it.

This document is descriptive, not an approval record. `docs/CHANGE_SPEC.md` is the one active remediation proposal. `docs/EXECUTION.md` records review evidence. `docs/IMPLEMENTATION_RATIONALE.md` is the companion coverage ledger and verification record. Completed feature reasoning lives in `docs/changes/`, and durable decisions live in `docs/decisions/`.

Three unrelated working-tree changes predated this review and remain unstaged: `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock`. The review did not overwrite or stage them.

## Review outcome

The stacked product work is coherent and unusually well tested for a pre-v1 mobile app. The combined client, Functions, seed, and rules design now supports one-level replies, blocking, audited unban, stable seeded chant IDs, explicit provenance and evidence, separate Songbook and Chant Lab browse surfaces, device-local Saved Matchday Songbook, and native plain-text share-out.

The stack is not release-ready yet. The review found four implementation defects that should be remediated before the combined device walk:

1. **P1, raw-write schema and deserialization denial of service.** `firestore.rules :: validChantContent` validates the headline chant fields but does not validate `sportId`, `competitionId`, `playerId`, media URL field types, or `variations`, and chant create has no exact-key allowlist. `lib/data/models/chant.dart :: Chant.fromJson` casts those fields directly. A raw authenticated client can therefore create a rule-valid visible chant whose malformed `variations` or typed fields throw while a whole Team, Player, or Discover query is being mapped. Votes, comment likes, reports, comments, user reports, and feedback also lack complete exact-schema controls; vote and like owners can mutate the Function-owned `appliedValue` bookkeeping field. This is a data-integrity and availability boundary, not cosmetic validation.
2. **P1, moderation revocation in Discover and Share.** `lib/presentation/browse/discovery_section.dart :: _LiveChantCard` falls back to its route snapshot whenever the live document stream errors or emits null. A focused widget probe reproduced a moderated chant remaining in Discover after a permission-denied stream error. That stale card can open `ChantDetailScreen`, where `initialData` currently enables Share before a current live document has been confirmed. Team and Player query streams correctly remove hidden or removed documents; Discover is the inconsistent path.
3. **P1, missing-parent trigger guard during merge.** `functions/src/index.ts :: handleVoteWritten` always batches an update to the parent chant. `mergeChants` deletes source vote documents and later deletes the source chant. A delayed delete-trigger delivery can therefore update a missing source chant and fail with `NOT_FOUND`. `handleCommentLikeWritten` already demonstrates the required existence guard. The merge callable is also sequential, non-resumable, not end-to-end tested, and its audit payload is partial despite comments in `functions/src/index.ts` calling it full.
4. **P2, comments reliability and accessibility.** `lib/presentation/comments/comment_section.dart :: _loadUserLike` is started without awaiting or catching its Firestore read. A focused test proved a failed lookup escapes as an unhandled asynchronous error and is marked loaded, so it never retries. The empty-comments `Row` in the same file overflows at 390 logical pixels and 1.8x text; the focused probe measured a 430-pixel right overflow. The current enlarged-text share test uses a nonempty comment fixture and therefore misses this state.

Release gates also remain outside those defects:

- `android/app/build.gradle.kts :: android.buildTypes.release` signs with the debug keystore, which blocks a store release.
- `lib/presentation/content_policy/content_policy_screen.dart :: ContentPolicyBody` still tells users the full policy is coming later.
- `.github/workflows/ci.yml :: flutter-analyze` exits successfully when `FIREBASE_OPTIONS_DART` is absent, so a green job can mean analysis never ran. The checked-in `lib/firebase_options.dart.example` is sufficient for static analysis and removes the need for this fail-open behavior.
- Native client compilation and the combined iPhone, Android, iPad share, keyboard, moderation, account deletion, and airplane-mode walk remain incomplete.

The active remediation contract in `docs/CHANGE_SPEC.md` covers the four implementation defects plus the CI gate. Signing credentials, final policy wording, live deployment, and device actions require separate owner input or authorization.

## What the product is now

Chants is both a trusted terrace archive and a creator workshop. `docs/decisions/004-songbook-and-chant-lab.md` assigns `canonical` chants to the Terrace Proven Songbook and `community` chants to Chant Lab. New submissions declare either `alreadySung` or `originalIdea`; an external YouTube or X evidence link is optional at admission and required, with operator review, before a user submission can become canonical.

The current user journey is:

- Email and password authentication, 17-plus confirmation, and versioned content-policy acceptance through `lib/presentation/auth/`, `lib/app/app.dart :: _SignedInGate`, and `functions/src/index.ts :: acceptPolicy`.
- Premier League browse, Discover, search, Team and Player Songbook, Team and Player Chant Lab, live detail, voting, comments, direct replies, reporting, blocking, and submission through `lib/presentation/`.
- Explicit local offline copies through `lib/data/repositories/saved_songbook_repository.dart`, `lib/data/services/saved_songbook_service.dart`, and `lib/presentation/saved/`. Saved content is a bounded read-only device snapshot, not a Firestore sync feature.
- Plain-text native sharing from live chant detail through `lib/data/services/chant_share.dart` and `lib/presentation/browse/chant_detail_screen.dart`. Current builds intentionally emit no public URL because no chant web resolver exists.

The data model can represent more sports and competitions, but the current product route is not fully data-only. `lib/presentation/home/home_screen.dart` hardcodes the Premier League tile and `lib/presentation/browse/discovery_section.dart :: allTeamsProvider` hardcodes the Premier League ID.

## How to read the repository

Start with `AGENTS.md`, the active `docs/CHANGE_SPEC.md`, and accepted records in `docs/decisions/`. Read `firestore.rules` before assuming any client UI restriction is authoritative. Then read `functions/src/index.ts`, followed by the client repositories and these load-bearing state boundaries:

- `lib/presentation/shared/vote_controls.dart :: OptimisticVoteState`
- `lib/presentation/comments/comment_card.dart :: CommentLikeState`
- `lib/presentation/comments/comment_section.dart :: _CommentSectionState`
- `lib/data/repositories/chant_repository.dart :: _visibleChants`
- `lib/data/repositories/saved_songbook_repository.dart :: SavedSongbookRepository`
- `lib/data/services/chant_browse.dart :: projectChants`

Historical `docs/DECISIONS.md` and `docs/BLOCK_RECAPS.md` explain earlier work but are not current implementation authority. Their statement that `mergeChants` records a complete undo snapshot is superseded by the current source and this review.

## Runtime stack

| Layer | Current repository state | Authority |
|---|---|---|
| Client | Flutter, Dart, Material 3, Riverpod, dark theme | `pubspec.yaml`, `lib/app/` |
| Authentication | Firebase Auth, email and password | `lib/data/repositories/auth_repository.dart` |
| Database | Cloud Firestore, flat top-level collections | `firestore.rules`, `firestore.indexes.json` |
| Server | Eleven Cloud Functions v2 exports, Node 20, TypeScript, `europe-west2` | `functions/src/index.ts`, `functions/package.json` |
| Integrity | App Check with Apple App Attest/DeviceCheck fallback and Android Play Integrity in release | `lib/main.dart` |
| Crash reporting | Firebase Crashlytics for Flutter and platform-dispatched errors | `lib/main.dart` |
| Local persistence | One schema-versioned JSON Saved Songbook per encoded Firebase UID | `lib/data/repositories/songbook_storage.dart`, `saved_songbook_repository.dart` |
| Seeding | Admin SDK CLI with explicit chant IDs and read-only preflight mode | `seed/seed.ts`, `seed/chant_identity.ts`, `seed/seed_plan.ts` |
| CI | Flutter test, Flutter analysis, Functions, seed, and Java-backed rules jobs | `.github/workflows/ci.yml` |

The repository declares Flutter SDK `^3.10.8` and Node 20. This review ran on Flutter 3.44.8 and Dart 3.12.2. CI follows unpinned Flutter `stable`, which makes the runner version movable without a repository change.

## Data and authority

All Firestore collections are top-level. Reference collections are `sports`, `competitions`, `teams`, and `players`. Content and interaction collections are `chants`, `votes`, `comments`, `commentLikes`, `reports`, `commentReports`, `userReports`, `profiles`, `feedback`, `auditLog`, and `blocks`.

`firestore.rules` is the direct-client authority. Admin SDK code in Functions and the seed pipeline bypasses those rules, so callable role checks and seed validation are separate load-bearing controls.

Deterministic interaction document IDs enforce one row per relationship:

- `votes/{userId}_{chantId}`, mirrored by `lib/data/models/vote.dart :: Vote.documentId`
- `commentLikes/{userId}_{commentId}`, mirrored by `lib/data/models/comment_like.dart :: CommentLike.documentId`
- report IDs built from reporter and target in the three report repositories
- `blocks/{blockerId}_{blockedUserId}`, mirrored by `lib/data/models/blocked_user.dart :: BlockedUser.documentId`

Profiles are owner-private and operator-readable. Votes and comment likes are owner-private and operator-readable. Visible chants and comments are publicly readable. Reports and the audit log are operator-readable. Blocks are private to the blocker. Those policies are implemented in the matching blocks in `firestore.rules`.

The principal open authority problem is not who may write, but what a permitted writer may shape. Exact schema, type, bounded-string, server-bookkeeping, and referential checks are complete for profiles and blocks but incomplete across other client-created collections. `docs/CHANGE_SPEC.md` proposes closing those gaps without migrating existing documents.

## Counters and asynchronous reconciliation

Chant vote totals, comment like totals, visible comment counts, and report-derived counts are denormalized for live reads. Their ground truth remains the child collections.

`functions/src/index.ts :: handleVoteWritten`, `handleCommentLikeWritten`, `recomputeCommentCount`, `handleChantReportWritten`, `handleCommentReportWritten`, and `handleUserReportCreated` recompute absolute totals instead of blindly incrementing. This is the correct response to at-least-once trigger delivery: duplicate and out-of-order events converge on stored ground truth.

Votes and comment likes also write `appliedValue` in the same batch as the parent counter. `OptimisticVoteState` and `CommentLikeState` use that stamp to distinguish a local write that the server count has already absorbed from one still waiting for its trigger. The no-op guards in both Functions prevent the `appliedValue` write-back from looping.

The missing chant-existence guard in `handleVoteWritten` is the exception. It matters during `mergeChants` and any future parent deletion. The remediation should make its behavior match the existing comment-like missing-parent guard and add a focused regression test.

## Browse, moderation, and live state

`lib/data/repositories/chant_repository.dart :: _visibleChants` applies `hidden == false` and `removed == false` to list queries. `TeamScreen` and `PlayerScreen` subscribe to query snapshots, preserve their last usable result through ordinary connection errors, and remove a chant when the query authoritatively removes it.

Discover is different. `discoveryChants()` performs a one-shot full visible fetch and shuffles it. Each card then listens to a single document only to update the score. On any stream error or null, `_LiveChantCard` restores the one-shot `initialChant`. That retention policy cannot distinguish a transient network failure from a permission denial caused by moderation, which is why the focused review probe left hidden content rendered.

`ChantDetailScreen` also receives a route snapshot. Retaining text is defensible for ordinary connectivity loss, but external sharing should require a current, visible live confirmation. The proposed remediation makes that distinction explicit instead of treating every stale snapshot as equally actionable.

Discover currently reads all visible chants with no page size in `ChantRepository.discoveryChants()`. Saved club refresh also reads the complete visible Team set from the server. Both are acceptable at the current 12-chant seed, but Discover must paginate or adopt a server-supported random-selection strategy when content volume grows.

## Submission, provenance, and evidence

`lib/presentation/submit/submit_chant_screen.dart` requires origin, title, lyrics, tune, subject, and style. Evidence remains optional and is normalized by `lib/data/services/chant_evidence.dart :: ChantEvidenceParser` to canonical YouTube watch or X status URLs.

The soft duplicate nudge is implemented, despite stale wording in `docs/ROADMAP.md`. `SubmitChantScreen :: _reviewLikelyDuplicates` fetches the Team's visible chants, runs `ChantMatcher`, and requires an explicit View, Post mine anyway, or Go back choice. Failure of the advisory lookup does not become an authorization boundary.

Promotion is not vote-driven. `functions/src/chant_trust.ts :: planChantTrustAction` requires valid stored evidence for user-created canonical promotion. System-owned seed content is the documented sourcing-ledger exception. Evidence removal demotes user-owned canonical content in the same transaction.

One client robustness gap remains in the player-prefilled submission route. `SubmitChantScreen` passes `_selectedPlayerId` as the dropdown initial value without first proving that the asynchronously loaded player list contains it. A removed or stale player can therefore trip Flutter's exactly-one-matching-item assertion. This is included as a lower-severity fix in the active remediation proposal.

## Comments, replies, blocks, and reports

Comments are flat Firestore documents. A nullable or absent `parentCommentId` means top-level; a non-null parent means one direct reply. `firestore.rules :: validReplyParent` rejects missing, hidden, cross-chant, reply-to-reply, and block-conflicting parents. `CommentSection` ranks parents by likes then recency and sorts replies oldest first.

Blocking is directional for storage and private visibility, but reply and like rules check both directions. The client filters blocked authors from the rendered thread. The block snackbar's Undo callback currently starts `unblockUser` without awaiting or translating failure, which is a smaller reliability gap to handle with the comments remediation.

Report counters are computed from pending report rows inside a Firestore transaction. Chant and comment content auto-hide at three pending reports and never auto-remove. User reports only increase an operator-review count. Report and feedback creation have no velocity limit, and report reason schemas are not currently bounded by rules. Schema bounds are in the active remediation; rate limiting remains a separate abuse-control follow-up.

## Saved Matchday Songbook

Saved Matchday Songbook is local-only by design. `SavedSongbookRepository` stores at most 500 unique chants and 2 MiB of encoded JSON, isolates files by base64url-encoded Firebase UID, serializes mutations, and writes through a temporary file plus atomic replacement. It refuses future schema versions and malformed shapes.

Fresh save and refresh paths use explicit server reads in `SavedSongbookService`. Saved detail is read-only and excludes votes, comments, reports, evidence, media, and share. Account deletion stages the local file behind a tombstone, invokes remote deletion, restores exact bytes on remote failure, and finalizes the local deletion only after remote success.

This design has strong unit and widget coverage. Its remaining evidence boundary is physical-device force-stop and relaunch in airplane mode. No test renderer can prove operating-system filesystem survival or real background lifecycle behavior.

## Seed pipeline and content integrity

Only `seed_data/clubs/arsenal.json` exists: 27 squad entries, 12 chants, and one chant with variations. The remaining clubs are still Andrew's content task.

Seeded chants use explicit club-prefixed IDs from source. `seed/chant_identity.ts :: findChantIdentityConflicts` refuses community ownership, wrong-Team collisions, and same normalized seeded titles at another ID. `upsertSeededChantInTransaction` repeats the ownership check at write time. `seed/seed_plan.ts` guarantees `--preflight-only` performs no sport, competition, or club write.

The seed updates only content allowlists and preserves engagement counters and ownership. It reports orphans but never deletes them. No service account file was read and no live preflight or write occurred in this review.

## CI and verification

Local verification on 2026-08-25:

| Check | Result |
|---|---|
| `flutter test` | PASS, 271 tests |
| `flutter analyze lib test` | PASS, no issues |
| `cd functions && npm test` | PASS, 35 tests |
| `cd seed && npm test` | PASS, 42 tests |
| `cd seed && npx tsc --noEmit` | PASS |
| `git diff --check main...HEAD` | PASS |
| focused moderation-revocation probe | RED as expected: stale Discover card remained |
| focused comment-like read-error probe | RED as expected: unhandled `StateError` escaped |
| focused empty-comments enlarged-text probe | RED as expected: 430-pixel right overflow |
| focused live-share revocation probe | PASS: an active stream error disabled Share |

All temporary probes were removed after their result, and the worktree returned to only the three pre-existing unrelated modifications.

The Firestore emulator could not run locally because no Java runtime is configured. Draft PR 9's clean GitHub Actions run at this exact commit reported 117 passing Java-backed rules assertions along with green Flutter, analysis, Functions, and seed jobs. That proves the existing rules suite, not the missing adversarial schema cases discovered here.

`dart format --output=none --set-exit-if-changed lib test` reported that 56 committed Dart files would change. It made no files writable because output was disabled. Formatting is not a CI gate today; the active remediation keeps the large mechanical rewrite separate and proposes adding an enforceable gate only after the current tree is normalized in its own reviewable commit.

An attempted current npm production advisory audit was not completed. The sandboxed attempt could not reach the registry, and the elevated request was rejected because it would disclose the dependency manifest to the public npm advisory service without separate explicit authorization. Current advisory status is therefore unverified.

## Deployment, operations, and recovery

Repository configuration names one Firebase project, `chants-f95b4`, and no staging project. CI validates but does not deploy. Functions, rules, indexes, seed writes, store submission, and production observation remain manual owner actions.

Safe deployment order for the provenance-aware stack is indexes, rules, Functions, then clients. Seed writes remain separate and must start with the read-only stable-identity preflight. No live environment was inspected, so the deployed order and current parity are unknown.

Recovery is uneven:

- A bad app release requires another store release.
- Rules and Functions can be redeployed from an earlier commit, but no rollback runbook exists.
- Seeded canonical content is reproducible from reviewed JSON.
- User submissions and interaction data depend on unverified Firestore backup and point-in-time-recovery settings.
- `mergeChants` is not safely undoable from its partial audit payload.
- `deleteAccount` has no durable progress marker for resuming a timeout midway.

Crashlytics is wired, but there is no repository-defined alerting, function-error dashboard, deployment smoke test, or incident runbook. App Check enforcement, billing alerts, backup settings, authentication templates, and live indexes are dashboard state that this review did not inspect.

## Where I most want your eyes

1. **The exact Firestore write schema.** Review `firestore.rules` beside every Dart `fromJson` cast. A rule-valid document must never be able to crash a public query mapper.
2. **Moderation disappearance across cached and retained UI.** Review Discover, detail, comments, saved snapshots, and offline semantics as separate policies. Retention during network failure is useful; retention after an authoritative permission denial is not.
3. **Parent deletion and trigger delivery.** Add missing-parent guards anywhere a child trigger updates a parent, then test delayed delivery against merge and deletion.
4. **Release configuration.** The real policy, Android release signing, native compilation, App Check dashboard state, and device walk are release blockers even though repository unit tests are green.
5. **Destructive workflows.** `mergeChants` and `deleteAccount` both need resumable or idempotent execution before volume makes a partial run expensive.

## Unverified

- Deployed rules, indexes, Functions, Firebase Auth settings, App Check enforcement, Crashlytics symbol upload, billing alerts, backup/PITR, and live data were not inspected.
- No live stable-ID preflight or seed write ran.
- No Android build succeeded locally because the Android SDK is unavailable. No iOS build succeeded because inherited Cloud Firestore Swift Package sources failed compilation in the prior native check. No native file mutation from that attempt remains.
- No iPhone, Android, or iPad walkthrough ran in this review.
- Android release signing remains debug-only in the tracked configuration.
- The content policy remains placeholder copy.
- Dependency freshness and current security-advisory state are unverified.
- Formatter conformance is unverified as a passing repository gate; the read-only check identified 56 files needing normalization.
