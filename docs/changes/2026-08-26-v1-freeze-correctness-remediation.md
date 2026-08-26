# V1 freeze correctness remediation

**Completed locally:** 2026-08-26
**Type:** Lane 2 destructive lifecycle, persistent local state, Firestore trigger concurrency, authorization, and live-action authority
**Application behavior changed:** Account-deletion uncertainty, cached live actions, interaction identity, and duplicate merge availability

## Change identity and boundary

- **Change:** Correct the locally reproducible findings in the independent freeze review without adding another V1 feature.
- **Target:** `codex/v1-freeze-remediation`, based on reviewed PR 13 head `267afa216ccf05ba88a928e93d4ee30a2334ea4c`.
- **Included:** Three-state local deletion acknowledgement, SHA-256 UID paths and legacy migration, transactional counter reconciliation, deletion-pending report and block targets, report ID byte bounds, cache-provenance action gates, chant-ID lifecycle guards, and a fail-closed merge stop.
- **Excluded:** Policy text, signing, native compilation, device actions, dependency advisory disclosure, live Firebase access, deployment, seed reads or writes, generic workflow infrastructure, resumable merge implementation, commit, push, PR, merge, and release.
- **Approval:** Andrew directed Codex to `make the fixes you think make logical sense` on 2026-08-25 after supplying the freeze review.

## Outcome

- Saved Songbook deletion artifacts now distinguish prepared, unknown, and accepted state. The client marks unknown before awaiting the remote call, never restores or deletes an unknown result, and reuses it for an idempotent retry. Explicit acceptance permits local cleanup and sign-out.
- New local Songbook filenames use lowercase SHA-256 of the UTF-8 UID. The active UID lazily migrates its legacy active, temporary, and deletion-state files. The old ambiguous deletion suffix maps to unknown.
- Vote, comment-like, visible-comment, user-report, content-report, and explicit chant reconciliation share their parent read, child query, and parent write in a Firestore transaction. Surviving vote and like stamps are written only when the current child still matches the event.
- User reports reject a deletion-pending target and reject deterministic document IDs beyond the 1,500-byte Firestore ID boundary. Block rules require an active target profile.
- Single-chant streams preserve Firestore cache provenance. Cached lyrics remain readable, but live-target actions wait for an active, error-free, non-cache visible value.
- Vote and comment state reset on chant-ID changes. Async hydration, writes, and stream callbacks carry the captured identity or generation and cannot update the next chant.
- `mergeChants` now returns failed-precondition after operator authorization and before target parsing or mutation. The retained sequential implementation is unreachable until a separate resumable design is approved.

## Invariants preserved

- A missing or lost remote response never claims deletion success or rejection.
- A missing parent is a successful reconciliation no-op and is never recreated.
- Cache remains a reading aid, not evidence of current moderation authority.
- Cleanup-reducing deletes remain available while new against-user rows stop at the pending boundary.
- The direct-write schema, one-level reply contract, server-owned stamps, stable seed identity, and V1 product scope remain unchanged.
- No dependency or lockfile change was introduced by the SHA-256 implementation.
- The owner's existing Android Gradle and lockfile modifications and the untracked freeze review were not edited or staged.
- No production, Firebase, seed, deployment, signing, native, device, merge, or release state changed.

## Verification

- `flutter test --machine`: 322 passed, zero failed.
- `flutter analyze lib test`: no issues.
- `cd functions && npm test`: 73 passed.
- `cd functions && npm run build`: passed.
- `cd seed && npm test`: 42 passed.
- `cd test_rules && npx tsc --noEmit`: passed.
- Java-backed Firestore emulator: 136 assertions passed. The first cold start exceeded the inherited 10-second setup timeout; the same suite passed with a 30-second hook allowance.
- Scoped `dart format` over 21 touched Dart files: no changes required.
- Focused Flutter suite: 30 passed across deletion, storage, cache authority, sharing, saved entry points, and vote/comment identity.
- Red evidence before correction reproduced ambiguous local restoration, cache-only action authority, old chant state crossing identity, pending-target acceptance, oversized report IDs, and non-transactional aggregate writers.
- `git diff --check` passed after the final documentation refresh. The Git index remained empty, and the new files had no trailing whitespace.

## Security, privacy, performance, and infrastructure impact

Unknown deletion data remains inside the operating system application container but is unreadable through the repository until retry confirms acceptance. Hash filenames remove future case-insensitive path collisions but do not encrypt the public chant snapshot. The active-UID-only legacy migration cannot add ownership metadata that old files never stored.

Transactional aggregate scans improve correctness and add contention retries and query read cost. The design remains appropriate for current volume, but production metrics must trigger a new plan before popularity makes full child scans material.

No collection, index, dependency, service, or deployment target was added. The safe rollout order remains backward-compatible rules, Functions, then clients. The disabled merge must stay disabled unless a cursor, retry, audit, and rollback contract is approved.

## Review boundary and follow-up

This work is locally complete but uncommitted. After Andrew separately authorizes packaging, run clean-runner CI on the exact remediation head. Claude's independent review range should then be `c57815c...<remediation-head>`, which includes every runtime change since the last whole-stack engineering review.

Remaining release work is the combined device walk, native compilation, verified club seeding after the live identity preflight, real policy and legal copy, signing, deployment preparation, observability, and release operations. It is not another open V1 feature block.
