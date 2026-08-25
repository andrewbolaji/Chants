# Change spec: V1 report and feedback abuse controls

**Status:** Approved, implemented, and locally verified; packaging, clean-runner CI, and independent review pending
**Updated:** 2026-08-25
**Risk lane:** Lane 2, moderation intake, server authority, persistent rate state, and client-to-Function migration
**Stack base:** `625217940e9817d9801b90f28aa4025e48dfbd48`, exact head of stacked PR 10
**Branch:** `codex/v1-abuse-controls`, stacked above PR 10

This is the one active implementation proposal for the next v1 block. PR 10 is clean-runner green. Its completed authority-remediation reasoning remains in `docs/changes/2026-08-25-stacked-v1-authority-integration-remediation.md` and decision 009.

## Outcome

- **Problem:** Report documents use deterministic one-per-target IDs and now have exact schemas, but a raw authenticated client can still report many different chants, comments, or users as quickly as writes can be issued. Feedback uses random IDs and can be created without a velocity bound. Post-write triggers cannot prevent storage, moderation-queue, audit-log, counter, and Function load that has already occurred.
- **Desired behavior:** All report and feedback admission moves behind authenticated Cloud Functions that derive identity and server fields, validate the current target, enforce one atomic server-owned per-user budget, and create the accepted document in the same transaction. Direct clients can read only their existing allowed views and cannot create these documents. The UI distinguishes duplicate, rate-limited, and recoverable failures without losing entered work.
- **Non-goals:** Changing report categories, auto-hide threshold, report resolution, moderation queue design, report or feedback deletion policy, operator tools, App Check enforcement state, account-deletion resumability, merge resumability, user appeals, notifications, analytics, pagination, hosted media, dependencies, indexes, deployment, Firebase access, live data, seed work, signing, merge, release, device actions, or formatter normalization.
- **Stop boundary:** This block closes unauthenticated-shape and authenticated-velocity abuse at moderation intake. It does not turn the reporting system into a general trust-and-safety platform.

## Acceptance criteria and invariants

### Server-authoritative submission

1. Add callable Functions `submitReport` and `submitFeedback` in `europe-west2`. Authentication is required. The actor UID is derived only from `request.auth.uid`.
2. Both callables require an existing profile whose `banned` field is exactly false. A missing or malformed profile returns `failed-precondition`; a banned reporter returns `permission-denied`.
3. `submitReport` accepts exactly `targetType`, `targetId`, and `reason`. `targetType` is one of `chant`, `comment`, or `user`; `targetId` is a trimmed string from 1 through 512 JavaScript characters; `reason` is trimmed, nonempty, and at most 250 characters. Unknown fields, wrong types, and client-supplied identity, time, status, or collection names are rejected as `invalid-argument`.
4. Chant and comment targets must exist and currently have `hidden == false` and `removed == false`. A user target must have an existing profile and cannot equal the reporter. Missing targets return `not-found`; unavailable content returns `failed-precondition`.
5. Accepted reports retain the current collection and deterministic ID contracts: `reports/{uid}_{chantId}`, `commentReports/{uid}_{commentId}`, and `userReports/{uid}_{reportedUserId}`. The server writes exactly the current five fields with `reportedBy` from auth, `createdAt` from server time, and `status == pending`.
6. An existing deterministic report returns `already-exists` and does not consume rate budget, overwrite the original reason, reopen a resolved report, or produce another audit or counter event.
7. `submitFeedback` accepts exactly `category`, `message`, and `followUpOk`. Category is one of `suggestion`, `bug`, `question`, or `other`; the trimmed message is nonempty and at most 1,000 characters; `followUpOk` is boolean. The server chooses the document ID and writes UID, server time, and `resolved == false`.
8. Callable validation and accepted document construction live in testable handlers that receive their Firestore and clock boundaries rather than hiding all behavior inside exported wrappers.

### Atomic velocity budgets

9. Add one server-only `safetyRateLimits/{uid}` document per account. Firestore rules allow no direct client read or write. The document contains independent report and feedback window timestamps and counters plus server `updatedAt`; absent fields initialize safely.
10. All three report target types share one anchored one-hour window. Accounts younger than 24 hours may create at most 5 accepted reports in that window. Older accounts may create at most 20. Classification uses the server-read profile `createdAt`; missing or malformed creation time takes the safer new-account limit.
11. Feedback permits at most 3 accepted entries in one anchored 24-hour window for every account.
12. The callable transaction reads the reporter profile, target, deterministic report when applicable, and rate document before writing. Budget increment and submission creation commit atomically. Concurrent calls cannot exceed the accepted count through a read-then-write race.
13. Expired windows reset on the next accepted attempt. A rejected invalid, unavailable, duplicate, or over-limit submission consumes no budget.
14. Limit rejection uses `resource-exhausted` with stable server messages. The response may return success and target type, but it never returns another user's state, exact budget history, or operator data.
15. No scheduled cleanup or TTL is added. The bounded rate document remains one small server-only row per submitting UID and is deleted by `deleteAccount` with that user's other private data.

### Client migration and interface behavior

16. Add one replaceable client repository boundary for safety submissions using `FirebaseFunctions.instanceFor(region: 'europe-west2')`. Report and feedback screens never send a reporter UID, timestamp, status, resolved value, or collection name.
17. The report sheet sends one typed target plus reason through that boundary. Remove the three direct report-create methods from the production repository APIs. Existing Firestore repositories may retain read-only checks, but no direct report-create method or provider remains on a shipped path.
18. Feedback uses the same server-authoritative boundary and returns `Future<void>` or a typed success result rather than exposing a Firestore `DocumentReference`.
19. The client translates `already-exists` to `You already reported this.`, `resource-exhausted` to `You have sent several reports recently. Try again later.` or `You have sent several messages recently. Try again later.`, and other failures to the existing retry copy.
20. A failed report keeps the sheet open with category and note intact and restores the submit control. A failed feedback attempt keeps category, message, and follow-up choice intact. Successful copy remains unchanged.
21. Existing signed-out behavior remains fail-closed. Tests cover enlarged text only if the new error copy changes measured layout; no visual redesign or new golden is required otherwise.

### Rules, triggers, deletion, and compatibility

22. Firestore rules deny all direct client creates in `reports`, `commentReports`, `userReports`, and `feedback`. Existing allowed reads remain unchanged. Operators and Admin SDK Functions continue to use their current server authority.
23. Existing report documents remain valid data. `onReportCreated`, `onCommentReportCreated`, and `onUserReportCreated` retain ground-truth counters, auto-hide behavior, and audit logging without a counter or schema migration.
24. Existing feedback rows remain readable to their owner and operators. No stored document is rewritten.
25. Account deletion removes `safetyRateLimits/{uid}`. Failure to find that document is a successful no-op. The broader sequential deletion redesign stays outside this block.
26. No Firestore index, dependency, scheduled Function, or new client permission is introduced.

### Verification and delivery

27. Functions tests prove authentication, exact payload validation, banned and missing profiles, each target type, hidden and removed content, self-report rejection, deterministic deduplication, server-owned fields, new and established limits, feedback limit, window reset, malformed rate state, rejected-attempt non-consumption, and concurrent transaction retry behavior at the handler boundary.
28. Rules tests replace prior valid direct-create expectations with denial for all four collections while preserving owner/operator read coverage and Admin-seeded compatibility fixtures.
29. Flutter tests prove target mapping, no client identity fields, duplicate and limit copy, retained form state, success behavior, and generic retry behavior on the production report and feedback surfaces.
30. Existing Flutter, Functions, seed, rules, and analysis suites remain green. New load-bearing tests receive a deliberate red check before restoration. `git diff --check` passes and only approved paths are staged.
31. Planning, implementation, local verification, clean-runner verification, review, deployment, and observation remain separate states. This specification authorizes none of deployment, Firebase access, live data reads or writes, seed operations, merge, signing, release, or device actions.

Invariants:

- Reporting is available only to an authenticated, profiled, non-banned account.
- The server, not the client, owns reporter identity, stored time, status, resolution state, collection routing, and velocity counters.
- One reporter can contribute at most one report to one target document.
- Duplicate and rejected attempts do not consume budget or alter accepted evidence.
- Report counts remain ground-truth recomputations; rate budgets never become moderation evidence.
- Popularity, reporting volume, and rate-limit state never change provenance or Terrace Proven status.
- Existing client-visible report and feedback data is not migrated or deleted by this block.

## Design

### Callable boundary

Introduce a small `SafetySubmissionRepository` used by both report and feedback UI. Its public API accepts domain values only. The repository maps those values to `submitReport` or `submitFeedback` callable payloads and translates `FirebaseFunctionsException.code` into a small typed failure enum. Widget code owns user-facing copy.

Keep the server implementation explicit. A target descriptor maps `targetType` to the current collection, target field, and deterministic report collection. The server never accepts those storage names from the client. Validation happens before the transaction where possible, then the transaction re-reads every authoritative document used to approve and count the write.

### Rate state

Use one `safetyRateLimits/{uid}` document instead of queries over user-authored timestamps or counters on the public profile. The document is never client-readable, does not affect `UserProfile.fromJson`, and is deleted with the account. One document serializes concurrent report and feedback counters independently without a new index.

An anchored window begins with the first accepted submission after expiry. It is not a calendar-hour bucket, so a user cannot receive a full fresh allowance merely by crossing an hour boundary. Rate counts are abuse controls, not product analytics or moderation evidence.

### Rollout compatibility

The safe later deployment order is Functions first, client second, then restrictive rules after supported clients use the callable. Because Chants is not publicly released, these may be coordinated in one release after review. Deploying restrictive rules before the callable client would temporarily break reporting and feedback, so rules-first rollout is explicitly wrong for this block.

## Failure and abuse analysis

| Condition | Required behavior | Evidence |
|---|---|---|
| Raw SDK creates a valid-looking report | Rules deny before storage | Rules test for each report collection |
| Raw SDK creates feedback repeatedly | Rules deny before storage | Rules test |
| Caller supplies another UID or `status: reviewed` | Callable rejects unknown fields; server derives fields | Functions payload tests |
| Five new-account reports race simultaneously at the boundary | Transaction retries serialize the shared budget; accepted count cannot exceed 5 | Handler transaction test |
| Duplicate report is retried after a timeout | Returns `already-exists`; original row and budget remain unchanged | Functions idempotency test |
| Moderator resolved an earlier report | Reporter cannot overwrite or reopen it | Deterministic existing-document test |
| Content is hidden between request and commit | Target read participates in transaction and retry; no report is accepted against unavailable current state | Functions transaction test |
| Rate document has absent or malformed fields | Safer defaults apply; no unbounded admission or crash | Functions malformed-state test |
| Feedback limit is reached | Form remains intact with specific retry-later copy | Repository and widget tests |
| Account deletion runs after submissions | Private rate row is removed along with other user-private data | Deletion-focused test or handler proof |
| Callable succeeds and trigger is redelivered | Existing ground-truth report handlers converge | Existing Functions tests |

## Performance, cost, and privacy

- Each accepted report uses bounded document reads for reporter, target, deterministic report, and one rate row, then atomically writes the report and rate row. Feedback omits the deterministic-report read.
- Rejected malformed calls stop before storage work where possible. Duplicate and rate-limited calls write nothing.
- One private rate document per submitting UID is bounded state. No raw request history, device identifier, IP address, or third-party analytics data is stored.
- Accepted report and feedback storage remains unchanged, so moderation queries and triggers need no new index.
- Callable invocation and transaction cost are justified at a safety boundary and replace unbounded direct-write admission.

## Rollout and recovery

1. Implement pure validation and transaction handlers, then prove focused red and green tests.
2. Migrate Flutter submission paths and failure copy.
3. Deny direct creates in rules and run the Java-backed suite.
4. Require the full local matrix and clean-runner CI before review completion.
5. After separate deployment authorization, deploy Functions, then client, then restrictive rules. Confirm accepted report, duplicate, limit, trigger, and operator visibility in a non-production environment before production.

Rollback restores the prior direct-create rules and client repositories before removing the callables. The private rate collection may remain harmlessly if rollback occurs; a later approved cleanup may delete it. No accepted report or feedback migration is required.

Healthy signals are callable success without direct writes, bounded `resource-exhausted` responses, no duplicate overwrites, unchanged ground-truth counters, no rate-state permission exposure, and no increase in trigger errors.

## Approval

**Approved.** Andrew approved this exact boundary with `approved v1 report and feedback abuse controls spec` on 2026-08-25.

Approval authorizes repository implementation, tests, and proportionate local or clean-runner verification on `codex/v1-abuse-controls`. It does not authorize Firebase access, deployment, live observation, seed operations, merge, signing, release, device actions, App Check enforcement changes, account-deletion redesign, or merge redesign.

## Open decisions

None required before approval. This proposal chooses server callables, one private atomic budget row, 5 reports per anchored hour for accounts under 24 hours, 20 for older accounts, and 3 feedback entries per anchored 24 hours. These are conservative prelaunch defaults and can be revisited from observed non-production or beta usage through a separate approved change.
