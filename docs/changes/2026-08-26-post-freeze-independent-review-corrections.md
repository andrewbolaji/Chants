# Change implementation rationale: Post-freeze independent review corrections

> **Document contract:** This file explains the bounded correction made after the independent review of `c57815c...f5cb748`. It is not a whole-repository architecture handoff.

## Change identity and boundary

- **Change:** Correct verified post-freeze deletion recovery, audit privacy, offline action, retry, dead-code, and documentation findings.
- **Implementation agent:** Codex
- **Base:** `f5cb748a8e5fbc0bc36eec5f686729e9b1c0f4bc`
- **Target:** Current `codex/v1-freeze-remediation` working tree
- **Included paths/services:** Saved Songbook storage and app gate, two account-deletion screens, report audit writers, deletion worker, report admission, chant detail, Discover permission classification, focused tests, goldens, decisions, and current milestone records.
- **Explicit non-goals:** Restore or cancellation after ambiguous deletion; a new server receipt; retained-job monitoring; counter aggregation redesign; dependency changes; rules changes; Firebase, seed, native, device, deployment, merge, or release actions.
- **Request/acceptance criteria:** Approved `docs/CHANGE_SPEC.md` after Claude's independent review.
- **Date:** 2026-08-26

The owner's `android/app/build.gradle.kts`, `android/settings.gradle.kts`, and `pubspec.lock` modifications and untracked `docs/CODE_REVIEW_FREEZE_2026-08.md` remain outside the change.

## Outcome

Unknown account-deletion acknowledgement is now a persistent signed-in gate instead of a transient snackbar only. The user can retry the same idempotent request or sign out. A positive pending marker can advance local cleanup, while false or unavailable profile state never unlocks uncertain data. Confirmed cleanup removes active, temporary, prepared, and unknown artifacts before the accepted marker.

The deletion worker now redacts audit rows authored by the deleted UID in bounded pages and writes a completion record with no UID. Report audit writers transactionally redact pending or missing reporters, closing the delayed-trigger race. The deletion dialog and pending screen disclose retained anonymous safety history.

Cached detail keeps two device-local actions available for an existing save: open its saved club or remove its individual copy. A new save and every server or external target action still require current server authority. Initialization can retry after transient I/O failure, permission denial requires a typed Firebase error, user-report admission checks the target deletion job, unused report lookups are removed, and SHA padding boundaries have explicit vectors.

## Impacted capability map

| Capability/boundary | Before | After | Key paths/interfaces | Why affected |
|---|---|---|---|---|
| Unknown deletion recovery | Snackbar was lost after process death | Local state gates Home with persistent retry and Sign out | `lib/app/app.dart`, `savedSongbookDeletionStateProvider`, `AccountDeletionRecoveryScreen` | Persistent state needs persistent recovery |
| Local deletion cleanup | Successful retry could leave a conflicting active file | Accepted marker is deleted last after all other artifacts | `songbook_storage.dart :: _finishAcceptedDeletion` | Preserve privacy across partial I/O |
| Audit retention | Reporter UID and reason remained; final audit embedded UID | Actor and detail redacted; final record is non-identifying | `account_deletion.ts`, `audit.ts`, report triggers | Deletion must minimize retained personal data |
| Report target authority | Pending profile was checked | Pending profile or deletion job is checked transactionally | `safety_submission.ts :: handleSubmitReport` | Match the rules' lifecycle guard |
| Cached detail | All bookmark branches were disabled | Existing local navigation and removal work; new save stays gated | `chant_detail_screen.dart` | Offline Songbook actions need no server authority |
| Initialization and error classification | Failed init was memoized; string errors could impersonate permission denial | Failed init evicts its future; only typed Firebase denial is authoritative | repository and Discover helpers | Allow real recovery and avoid false revocation |

## Implementation choices

| Choice with file/symbol | Why this approach | Alternatives considered | Tradeoff accepted | Evidence or ADR |
|---|---|---|---|---|
| Positive-only reconciliation in `savedSongbookDeletionStateProvider` | A true pending marker proves acceptance; false can be stale or race a late commit | Restore on false profile, or never reconcile | Unknown stays locked longer when the server cannot be confirmed | Decision 012 and app-gate tests |
| App gate before Home | A snackbar cannot survive process death | Home banner or rediscovering Delete account | One extra local check on signed-in launch | Interface memory and inspected golden |
| Accepted-marker-last cleanup | Any partial cleanup must remain unreadable | Delete marker first or only marker | Unreadable bytes may remain until retry | Storage reconstruction and conflict tests |
| Bounded audit phase plus transactional writers | Page-only cleanup cannot stop a delayed trigger | Delete all audits or disclosure only | Target-side audit history remains | Decision 016 and Functions tests |
| Branch-specific bookmark gate | Existing local actions do not use target authority | Uniformly disable or allow all save branches | Button authority depends on saved ownership | Decision 015 and widget tests |
| Remove dead report lookup paths | Rules now deny their reads and no caller remains | Keep speculative code | Future duplicate checks must use the callable contract | Complete `lib/` and `test/` caller search |

## Changed flow and state

1. The signed-in app receives a profile and resolves the active UID's local deletion state before Home.
2. Unknown renders persistent recovery. Retry uses `AccountDeletionService.deleteAccount`, which reuses the unknown marker and idempotent callable.
3. A positive pending profile causes the provider to mark local state accepted and retry accepted-last cleanup. A negative profile leaves unknown unchanged.
4. The server worker redacts actor-owned audit rows in pages of 200 before writing the anonymous completion audit.
5. A report trigger reads the reporter profile and writes its audit in one transaction. Pending or missing profile state writes no reporter UID or reason.

| Changed invariant or failure condition | Enforcement point | Verification |
|---|---|---|
| Unknown state never falls through to Home | `_SignedInGate._screenFor` | Profile-false unknown and local-read failure widget tests |
| Negative server observation never restores uncertain data | `savedSongbookDeletionStateProvider` and storage API | Unknown reconstruction and positive-only reconciliation tests |
| Confirmed cleanup cannot leave readable conflict without a lock | `_finishAcceptedDeletion` | Real-file active-plus-unknown regression |
| Deleted actor UID and report text do not survive audit cleanup | `anonymize-audit-by`, `writePrivacySafeReportAuditEntry` | 201-row page, pending, and missing-profile tests |
| New against-user report cannot race a deletion job | `handleSubmitReport` transaction | Job-present, marker-false Functions test |
| Cached detail authorizes only existing local saved branches | `saveActionEnabled` and `_toggleSaved` | Individual removal, club navigation, and empty-cache tests |

## Security, privacy, and abuse impact

- **Identity/authorization/tenant effect:** User-report admission now matches the profile-or-job lifecycle guard. Client rules are unchanged.
- **Input/output boundary:** Permission classification accepts only typed Firebase codes. No new untrusted input is introduced.
- **Sensitive data/logging/retention:** Deleted actor UIDs and user-authored report reasons are redacted. Target-side anonymous safety history may remain and is disclosed. No raw production data was accessed.
- **Secrets and external services:** None. No credential, Firebase, registry, or device action occurred.
- **Abuse and rate-limit cases:** Existing budgets are unchanged. The added target-job read prevents a late against-user row.

## Dependency and infrastructure impact

None. No manifest, lockfile, index, rule, service, CI workflow, runtime, or deployment configuration changed. The existing owner-modified lockfile remains excluded.

## Performance, scale, and cost impact

- **Affected workload:** Account deletion adds one bounded audit page per worker invocation and report-user admission adds one document read. Signed-in launch adds one local filesystem state check.
- **Expected resource/cost change:** Audit cleanup is linear in actor-owned audit rows with a 200-row invocation cap. User reports add one transactional read. No normal chant or comment report read was added.
- **Budget:** Existing deletion page size remains 200. No production latency or cost budget is defined.
- **Measured evidence:** No production workload was accessed. Tests cover a 201-row audit population and exact phase advancement.

## Verification performed

| Command/scenario | Target/config/environment | Result | Artifact/evidence checked |
|---|---|---|---|
| `flutter test` | Local macOS, Flutter 3.44.8 | PASS, 336 | Complete client suite and goldens |
| `cd functions && npm test` | Local Node 20 | PASS, 77 | Source compilation and complete Functions suite |
| Focused deletion, cached-action, permission, and SHA tests | Local Flutter renderer | PASS | Named regression behavior |
| Recovery and pending goldens | 390 by 844 Flutter surface | PASS and visually inspected | Hierarchy, copy, actions, and clipping |
| Remaining repository matrix | Local repository | PASS | Analysis, seed, rules, 16-file scoped formatting, memory structure, writing style, caller searches, and diff checks |

The regression guards were added at the smallest affected boundaries. The prior independently reviewed code and tests establish the failing paths: no durable unknown screen, marker-only successful cleanup, retained audit actor and reason, uniform bookmark disablement, memoized initialization failure, and string-based permission classification.

## Rollout, observation, and recovery

- **Deploy/migration order:** If later authorized, deploy Functions before the corrected client. Rules are unchanged. Seed remains separate.
- **Compatibility during rollout:** The updated unreleased worker adds one accepted phase. Existing clients depend only on callable acceptance and pending profile state. No deployment was performed or inspected; if an older worker ever has in-flight jobs, prove they drained or approve a separate audit backfill before rollout.
- **Healthy signals and observation window:** Replacement clean-runner CI, then the combined device walk. Deployed observation is not authorized or available.
- **Rollback or forward recovery:** Audit redaction is forward-only. Client UI can roll back only while unknown markers remain locked. A bad deployed privacy phase requires a forward fix.
- **Operator/user documentation:** Current overview, rationale, interface memory, decisions 011, 012, 015, and 016, deletion copy, and this record are updated.

## Known compromises and uncertainty

| Item | Consequence | Why accepted | Owner | Revisit trigger |
|---|---|---|---|---|
| No retained-job alert or recovery console | A permanently failing deletion can remain invisible | Separate operations block and external cloud authority | Andrew | Before public beta or first retained job |
| Target-side audit history may remain | Deleted account can remain the subject of an anonymous safety event | Other actors and operator history have a separate purpose | Andrew | Approved legal retention policy |
| Aggregate transactions scan all children | Popular targets can exceed practical transaction cost | No measured v1 workload justifies redesign | Andrew | Measured latency, retries, or read cost breach |
| No durable rejection receipt | Unknown local state requires retry to resolve | Current protocol cannot safely prove rejection | Andrew | Server receipt design is approved |

## Material files and artifacts

- `lib/app/app.dart`, `lib/app/providers.dart`, deletion screens, Saved Songbook repository and storage.
- `functions/src/account_deletion.ts`, `functions/src/audit.ts`, `functions/src/index.ts`, `functions/src/safety_submission.ts`.
- Focused Flutter and Functions regressions plus two deletion goldens.
- Decision 016 and refinements to decisions 011, 012, and 015.
- Current milestone, interface, execution, roadmap, and setup records.

## Repository rationale reconciliation

- **Does `docs/IMPLEMENTATION_RATIONALE.md` need refresh?** Yes. This changes account-deletion architecture, audit privacy and retention, app-gate behavior, report authority, and residual-risk statements.
- **Sections refreshed:** Coverage ledger, critical report and deletion flows, implementation choices, lifecycle and retention, invariants, security, performance, verification, operations, documentation consistency, risks, and artifact inventory.
