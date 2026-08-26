# V1 report and feedback abuse controls

**Completed in repository:** 2026-08-25
**Type:** Lane 2 moderation intake, server authority, persistent rate state, and client-to-Function migration
**Application behavior changed:** Chant, comment, and user reports plus product feedback

## Change identity and boundary

- **Change:** Move report and feedback admission from direct Firestore creates to authenticated, atomically rate-limited callables.
- **Target:** `codex/v1-abuse-controls`, based on exact stacked PR 10 head `6252179`.
- **Included:** Callable validation, target checks, deterministic deduplication, private anchored-window budgets, server-owned document fields, Flutter repository and error mapping, direct-create denial, account-deletion cleanup, tests, interface memory, and durable decision 010.
- **Excluded:** Categories, thresholds, moderation queue redesign, resolution, appeals, App Check enforcement, destructive-workflow resumability, notifications, analytics, pagination, dependencies, indexes, deployment, live data, seed work, signing, merge, release, and device actions.
- **Approval:** Andrew explicitly approved `approved v1 report and feedback abuse controls spec` on 2026-08-25 before runtime edits began.

## Outcome

- `submitReport` accepts one typed chant, comment, or user target. The authenticated profile and current target are authoritative. The Function preserves the existing report collection, deterministic ID, and five-field stored shape while owning reporter identity, time, and pending status.
- `submitFeedback` accepts category, message, and follow-up preference. The Function chooses the ID and owns UID, time, and unresolved status.
- One private `safetyRateLimits/{uid}` document serializes independent anchored report and feedback budgets. Reports share 5 per hour for accounts under 24 hours and 20 for older accounts. Feedback allows 3 per anchored 24 hours.
- Duplicate, invalid, unavailable, banned, and over-limit attempts produce no accepted row or budget increment. A duplicate never overwrites or reopens an existing report.
- The Flutter client sends domain fields only. Report and feedback forms retain their values after failure and show specific duplicate or rate-limit copy.
- Direct client creates are denied for all three report collections and feedback. Existing report triggers, counters, auto-hide, audit behavior, and read permissions remain unchanged.
- Account deletion removes the private rate row; a missing row is a successful no-op.

## Invariants preserved

- Reporting requires an authenticated profile whose `banned` value is exactly false.
- Popularity, report volume, and rate state never imply Terrace Proven status.
- Rate counters are an admission control, not public profile data or moderation evidence.
- Existing report and feedback rows are neither migrated nor rewritten.
- The user's pre-existing Gradle and lockfile modifications remained unstaged and were not overwritten.
- No production, staging, Firebase, seed, deployment, signing, merge, release, or device state changed.

## Verification

- `flutter test`: 294 passed.
- `flutter analyze lib test`: no issues.
- `cd functions && npm test`: 56 passed.
- `cd seed && npm test`: 42 passed.
- `cd test_rules && npm exec tsc -- --noEmit`: passed.
- Java-backed Firestore emulator: 132 passed with a 30-second local Mocha timeout. Two earlier runs each had one different inherited assertion time out at the 10-second test limit while every other assertion passed; the widened clean run completed in 15 seconds with no failure.
- `git diff --check`: passed before final documentation refresh and is rerun at handoff.
- Focused Flutter coverage proves all three target mappings, absence of identity fields, typed callable error mapping, duplicate and rate copy, generic retry copy, retained report and feedback work, restored controls, and unchanged success states.
- Focused Functions coverage proves auth, exact payloads, profile state, current targets, self-report denial, server fields, deterministic deduplication, both report limits, feedback limit, reset, malformed state, rejected non-consumption, transaction retry, and deletion cleanup.
- Deliberate red checks changed the new-account report limit from 5 to 6, mapped a comment report as a chant, and temporarily allowed direct report creates. Each focused guard failed for the intended reason before production behavior was restored.
- Temporary 800 by 600 widget captures of the actual report and feedback rate-limit states were inspected. Forms, controls, and error presentation remained stable with no clipping. The capture-only tests and images are not repository artifacts.

Independent review, clean-runner CI, native compilation, and the combined device walk remain pending. The source block is locally complete but uncommitted and unpushed until Andrew separately authorizes packaging.

## Security, privacy, abuse, and infrastructure impact

The change adds one private bounded document per submitting UID and two callable exports. An accepted report performs four document reads and two writes in one transaction. Accepted feedback performs two reads and two writes. Existing post-write triggers still run after acceptance. No index, dependency, scheduled job, public data field, or client permission is added.

The safe later rollout order is Functions, compatible client, then restrictive rules. A coordinated prelaunch deployment may ship the reviewed source together, but a rules-first partial rollout is unsafe. Rollback restores the compatible client and earlier create rules before removing the callables; retained private rate rows are harmless until separately cleaned.

## Review boundary and follow-up

The immutable baseline for the final external freeze review is commit `c57815c`, which contains the last whole-stack `ENGINEERING_OVERVIEW.md` and `docs/IMPLEMENTATION_RATIONALE.md`. The eventual review range is `c57815c...<freeze-head>`, not whichever versions happen to be at those paths later.

The next logical engineering risk is the non-resumable sequential account-deletion workflow. It needs its own approved Lane 2 contract and should be assessed before declaring the v1 freeze point.
