# Change spec: Stacked v1 authority and integration remediation

**Status:** Proposed, pending Andrew's explicit approval
**Updated:** 2026-08-25
**Risk lane:** Lane 2, direct-write authorization, moderation lifecycle, asynchronous server triggers, and release gates
**Stack base:** `b72f4abddea0cd8a3b201de2d4dda246c62a413c`, exact head of stacked draft PR 9

This is the one active implementation proposal produced by the whole-project stacked engineering review. It replaces the completed Basic Share-Out spec, whose reasoning is retained in `docs/changes/2026-08-24-basic-share-out.md`.

Approval of the review did not approve this remediation implementation. No runtime, rules, Functions, CI, or release file changes begin until Andrew approves this exact specification.

## Outcome

- **Problem:** The stacked v1 features pass their existing suites, but adversarial integration review found a mismatch between Firestore write rules and Dart deserialization, stale Discover behavior after moderation revokes a read, a missing parent-existence guard in the vote trigger, two comment-state failures, a stale player-prefill assertion, and a CI analysis job that can pass without running.
- **Desired behavior:** Every direct-client document accepted by rules fits the shipped model contract; server-only bookkeeping remains server-only; moderated content cannot remain actionable through a stale Discover snapshot; Share requires current visible confirmation; child triggers tolerate a deleted parent; comments contain lookup failure and enlarged text; stale player metadata fails soft; and a green analysis job proves analysis ran.
- **Non-goals:** Report or feedback velocity limiting; redesigning moderation; rewriting `mergeChants` into a resumable job; making account deletion resumable; production signing credentials; changing the user's unstaged Gradle or lockfile work; writing the real content policy; native dependency upgrades; public URLs; deep links; hosted media; notifications; analytics; pagination; deployment; Firebase access; live seed preflight or writes; merge; release; device actions; dependency upgrades; or whole-tree formatter normalization.
- **Review boundary:** Firestore rules and adversarial rules tests, focused Flutter state and layout fixes, one Functions parent guard and test, the CI analysis gate, factual current-document corrections, and the verification needed for those paths.

## Acceptance criteria and invariants

### Exact direct-write schemas

1. A user-created chant has an exact allowed key set. It contains the fields emitted by the current `Chant.toJson` submission path and no unknown field.
2. Direct user chant creation requires string `sportId`, `competitionId`, and `teamId`; nullable string `playerId`, `coverImageUrl`, and `mediaUrl`; an empty `variations` list; and the existing valid title, lyrics, tune, context, subject, style, status, origin, evidence, counters, owner, visibility, and timestamps.
3. Direct user creation pins v1 media to `mediaType == 'none'`, `coverImageUrl == null`, and `mediaUrl == null`. Seed and operator Admin SDK paths remain outside this direct-client rule and preserve current canonical media compatibility.
4. The referenced Team must exist. Stored `sportId` and `competitionId` must match that Team. A player subject must name a non-null existing Player on that Team. A non-player subject must have `playerId == null`.
5. Author chant updates preserve the exact stored schema and can change only the current user-editable text and classification fields: title, lyrics, tune, optional context, subject, style, optional valid Player, and `updatedAt`. Origin, evidence, identity, Team hierarchy, media, variations, ownership, status, counters, dates, and visibility remain immutable on the direct author path.
6. Existing legacy chant reads are not migrated or rejected. Exact-schema enforcement applies to new direct writes and direct author updates. Operator compatibility remains governed by the current trust-state checks and gains safe type validation without forcing legacy untouched optional fields into existence.
7. Vote create allows exactly `chantId`, `userId`, `value`, and `createdAt`. Vote update may change exactly `value`. Function-written `appliedValue` cannot be created, changed, or deleted by the owner.
8. Comment-like create allows exactly `commentId`, `userId`, `value`, and `createdAt`. Comment-like update may change exactly `value`. Function-written `appliedValue` remains server-owned.
9. Comment create permits only the current comment fields plus optional `parentCommentId`. Required strings, booleans, zero counters, relationship, body length, display-name equality, and recent timestamps stay enforced.
10. Chant, comment, and user reports each permit only their current five fields. Target and reporter IDs are strings, status is `pending`, reason is a nonempty string of at most 250 characters, and creation time is recent. The 250-character stored boundary preserves the current category prefix plus the UI's 200-character optional note. Existing one-per-target IDs and visibility or existence checks stay enforced.
11. Feedback permits only `userId`, `category`, `message`, `followUpOk`, `resolved`, and `createdAt`. Category is one of the model values, message is nonempty and at most 1,000 characters, booleans have the correct type, creation time is recent, and `resolved` starts false.
12. Block rules retain their existing exact schema and relationship checks. Profile rules retain their existing exact schema and privileged-field pinning.
13. Rules tests prove both accepted client payloads and hostile raw writes: unknown fields, malformed `variations`, wrong nullable types, forged media, mismatched Team hierarchy, wrong Player Team, `appliedValue` create/update/delete, oversized or nonstring reasons, invalid feedback category, and timestamp abuse.

### Moderation and live-state behavior

14. Discover may render its initial visible query copy while a live card subscription is waiting or during an ordinary recoverable connection error.
15. A single-document `permission-denied` error, an active null document, or a current hidden or removed document removes that card from Discover and prevents navigation from its stale route snapshot.
16. Discover tests use a Firebase-shaped permission-denied error separately from an ordinary transient error so moderation disappearance does not destroy the intended fail-soft offline behavior.
17. Live chant detail may retain readable route text through a connection failure, but Save, Share, Vote, Report, and Comment actions that require a live visible target are disabled until the stream has emitted a current visible chant. At minimum, Share must require `ConnectionState.active`, non-null current data, no error, and visible flags.
18. A stale Discover card followed by a permission denial cannot invoke the native Share gateway. The regression test exercises the actual Discover-to-detail route or an equivalent shared live-availability state, not only an injected hidden `Chant` object.
19. Current Team and Player retained-data behavior remains unchanged for ordinary errors. Query-authoritative removal still removes moderated content.

### Comments and submission resilience

20. A failed `getUserLike` call is caught inside `CommentSection`, does not escape to `PlatformDispatcher` or Crashlytics as an unhandled error, preserves a usable unliked display, and removes the comment ID from the loaded set so a later comment emission can retry.
21. The empty-comments state wraps or flexes at a 390-wide viewport with 1.8x text and has no overflow. Existing nonempty reply-thread layout remains unchanged.
22. Block snackbar Undo awaits or otherwise contains `unblockUser` failure and shows bounded recovery copy instead of emitting an unhandled Future error.
23. A player-prefilled submit route validates the loaded Player set before passing an initial dropdown value. A missing or moved Player clears the selection and shows a recoverable prompt instead of asserting or spinning forever. Player-stream failure renders a retry or explanatory state while the user can still switch the subject away from Player.

### Trigger lifecycle

24. `handleVoteWritten` reads the parent chant before querying votes or staging a batch. If the chant no longer exists, it returns without a batch or vote `appliedValue` write.
25. The new guard has a focused missing-parent test equivalent to `handleCommentLikeWritten`'s guard test. Existing create, update, delete, no-op, duplicate, and burst cases remain green.
26. This block corrects source comments that call the merge audit payload full or undo-capable. It does not claim to make `mergeChants` atomic, resumable, or reversible.

### CI and current documentation

27. Flutter analysis no longer exits successfully because `FIREBASE_OPTIONS_DART` is absent. CI copies the checked-in `lib/firebase_options.dart.example` for static analysis when the secret is missing, or uses another deterministic non-secret fixture that compiles the same source.
28. The analysis job records one unambiguous outcome: analysis ran and passed, or the job failed. It never prints skip and exits zero.
29. Formatter normalization remains separate because 56 committed files would change. This block does not add a format gate that the current tree cannot pass.
30. `README.md` and `docs/ROADMAP.md` receive factual status corrections only: implemented Songbook/Lab, Saved Songbook, Share, duplicate nudge, current measured test counts, CI status, and remaining review/device gates. No product scope is expanded.
31. `ENGINEERING_OVERVIEW.md`, `docs/IMPLEMENTATION_RATIONALE.md`, and `docs/EXECUTION.md` are refreshed after implementation with exact evidence. A completed record is added under `docs/changes/`. No ADR is added unless implementation requires a new durable tradeoff not already covered by existing decisions.

Invariants:

- Rules are authoritative for direct client writes; client form validation is assistance, never authorization.
- A rule-valid visible document must be safe for the shipped model parser.
- Admin SDK seed and Function writes remain separately validated and do not depend on client rules.
- Retaining public content during ordinary connectivity loss is distinct from retaining it after an authoritative moderation denial.
- External share requires current visible authority and never claims delivery.
- Function-owned counters and reconciliation stamps are not client-owned fields.
- No production, staging, seed, deployment, merge, release, signing, or device action is authorized by this specification.

## Design

### Firestore rule helpers

Add small collection-specific helpers instead of one unreadable monolith. Expected helpers include exact key checks, nullable-string checks, Team hierarchy checks, Player relationship checks, and bounded report shape. Reuse `validRecentClientTimestamp`, `validOrigin`, `validOptionalEvidence`, and current visibility helpers.

For user-created chants, v1 intentionally pins variations empty and media absent. That avoids attempting to validate arbitrary nested variation maps in Firestore Rules and matches the current submission UI. Seeded canonical variations continue through the Admin SDK. A later user-variation feature requires its own schema and rules contract.

Author updates should use an allowlist that matches an actual edit capability. Keeping dormant media and cover fields author-writable creates authority without a shipped user job. Remove that dormant authority here; a future upload or evidence feature can add the exact field and moderation contract deliberately.

Rules changes must be backward compatible with existing reads. Do not add a condition that makes a legacy visible chant unreadable only because an optional historic field is absent. New create and changed-field validation can be strict without performing a live migration.

### Live availability state

Do not treat every stream error identically. Discover should keep its last safe content through a generic connectivity failure but remove it on Firestore `permission-denied`, current null, hidden, or removed. Implement the classification in a small pure helper or explicit widget state so tests do not rely on fragile timing.

Detail should separate readable fallback from actionable current state. The route snapshot may remain on screen, but controls that write, report, save fresh data, or share externally require a current active visible stream value. If applying this to every action creates an unexpected offline behavior conflict, Share and external evidence are the minimum fail-closed boundary and the remaining actions must be documented with server-rule rejection evidence.

### Comment lookup retry

`_loadUserLike` owns its read failure. Add the ID to `_likeLoadedFor` before the request to deduplicate concurrent loads, then remove it in `catch` so the next server comment emission can retry. No snackbar is required for background preference hydration; the heart remains usable and its explicit write path already reverts on failure.

Undo is a user-triggered action and should surface failure. A small async helper can await the repository, restore or preserve the blocked state, and show `Could not unblock this user. Try again.` without throwing outside the widget.

### Vote parent guard

Mirror `handleCommentLikeWritten`: get `chants/{chantId}`, return if absent, then query votes and batch the chant plus live vote stamp. The guard intentionally drops work for deleted parents. It must not create a replacement chant or convert `update` to `set`.

### CI analysis fixture

Static analysis does not need a real Firebase project. CI can copy `lib/firebase_options.dart.example` to the ignored runtime path when the secret is absent, then always run `flutter analyze`. Same-repository protected runs may still use the secret, but secret absence cannot become success through an early exit.

## Failure and abuse analysis

| Condition | Required behavior | Evidence |
|---|---|---|
| Raw user writes string or map into `variations` | Rules deny; no public query sees it | Adversarial rules test |
| Raw user adds a 1 MiB unknown field | Rules deny exact key set | Adversarial rules test |
| Raw user forges `appliedValue` | Vote and like create/update deny | Rules tests plus existing Function batch tests |
| Raw user points Player chant at another Team | Rules deny relationship mismatch | Rules test with seeded Team and Player |
| Existing legacy chant lacks origin or optional fields | Read remains available if visible | Compatibility rules test and Dart model test |
| Moderator hides a Discover chant | Permission denial or null removes card; stale route cannot share | Discover and route widget tests |
| Network drops while Discover is open | Last safe card may remain with no moderation claim | Transient-error widget test |
| Comment-like preference read fails | No unhandled exception; later emission retries | Focused widget test |
| Empty thread at 1.8x text | Copy wraps without overflow | 390 by 844 widget test |
| Prefilled Player was removed | Selection clears, form remains usable | Submit widget test |
| Vote delete trigger arrives after source chant deletion | Handler no-ops without commit | Functions missing-parent test |
| CI secret is deleted | Analysis still runs using fixture | Workflow review and clean-runner CI |

## Performance and cost

- Exact key, type, and relationship checks add bounded Security Rules evaluation. Chant creation may read one Team and, for Player subjects, one Player. This is acceptable at a user-triggered submission boundary and should be covered by rules access-call limits.
- No new Firestore query, Function, collection, index, background task, or persistent client state is introduced.
- The vote parent guard adds one document read per meaningful vote trigger. It prevents repeated failed retries and is expected to reduce operational noise around deletion.
- UI fixes are constant local state operations. No polling or retry timer is added.
- CI analysis uses a checked-in fixture and adds no paid service dependency.

## Rollout and recovery

1. Implement and prove Flutter/Functions logic locally, including deliberate red checks.
2. Compile rules tests locally if Java becomes available; otherwise push only after TypeScript compilation and require clean-runner Java-backed rules success before review completion.
3. Deploy order after later authorization: rules first, Functions second, client last. The rules must accept the current shipped client payload before the client reaches users.
4. No data migration is expected. Existing documents remain readable; stricter checks apply to new or changed direct-client documents.
5. Rollback is a prior rules and Functions deploy plus a client revert. Because a client rollback is store-latent, the fail-closed moderation and parser-safety tests are required before any release.
6. Do not deploy, seed, merge, or release in this block without separate authorization.

Healthy signals are zero parser failures from public snapshots, immediate Discover disappearance on moderation denial, no unhandled comment hydration errors, no enlarged-text overflow, no missing-parent Function retries, and an analysis job that visibly runs.

## Verification plan

| Claim | Check | Expected evidence |
|---|---|---|
| Exact raw-write schema | Expanded `test_rules/firestore_rules.test.ts` hostile matrix | All malformed and unknown payloads fail; current client shapes succeed |
| Legacy read compatibility | Admin-seeded legacy chant variations and absent provenance read | Visible legacy document still reads and renders |
| Model/rule parity | Ledger comparing each `Chant.fromJson` cast to rule type or pin | No direct-client parser field remains unvalidated |
| Moderation disappearance | Real `DiscoverySection` test with permission-denied stream | Card leaves and cannot navigate |
| Fail-soft network state | Generic transient stream error | Last safe card remains according to documented policy |
| Current share authority | Stale route plus no confirmed live data, then permission denial | Gateway call count stays zero; action enables after valid current emission |
| Like read containment | Throwing fake `getUserLike`, then successful retry emission | No `tester.takeException`; persisted state later reconciles |
| Enlarged empty state | 390 by 844 at 1.8x | No overflow; empty copy visible |
| Stale Player | Prefilled ID absent from loaded list and stream error | No assertion or endless spinner; form can recover |
| Missing parent | `handleVoteWritten` fake with absent chant | Zero batch commits and zero stamp writes |
| CI actually analyzes | Clean runner without real Firebase options secret | Fixture is written and `flutter analyze` passes visibly |
| Existing repository stays green | Flutter, Functions, seed, rules, analysis, diff check | All suites pass with exact counts recorded |
| New tests can fail | Temporary removal of each load-bearing guard | Focused test fails for intended reason, then passes after restoration |
| Scope remains bounded | Diff against `b72f4ab` and user-worktree inspection | Only approved rules, client, Functions, CI, tests, and current docs; user Gradle/lockfile changes unstaged |

## Approval

**Pending.** Andrew has approved beginning the stacked engineering review, not implementing this resulting Lane 2 remediation. Implementation begins only after an explicit approval such as `approved stacked v1 authority and integration remediation spec`.

Approval will authorize repository edits and proportionate local or clean-runner verification only. It will not authorize production or staging access, dependency disclosure, deployment, live preflight, seed writes, merge, signing credentials, store submission, release, or external device actions.

## Open decisions

None required before approval. The specification chooses exact direct-write parity, permission-denied moderation disappearance, readable-but-not-actionable detail fallback, retryable background like hydration, fail-soft stale Player handling, a missing-parent no-op, and deterministic static-analysis configuration. Production signing and real policy wording remain separate owner gates because their inputs are not present in the repository.
