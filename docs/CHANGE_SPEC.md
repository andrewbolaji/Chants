# Change spec: Post-Living Songbook independent review corrections

**Status:** Implemented and locally verified; clean-runner CI pending
**Updated:** 2026-08-30
**Risk lane:** Lane 2 moderation authority, persistent schema, audit privacy, queue recovery, and external evidence behavior
**Base:** `ef7195cf5159c45afd5f92eaf427c698f6d62b16` plus the staged V1 Living Songbook implementation
**Approval:** Andrew approved `post-Living Songbook independent review correction spec` on 2026-08-30.

## Outcome

- **Problem:** The independent review found one operator-queue dead end, five medium correctness or evidence gaps, and eight lower-severity recovery, privacy, ordering, and documentation defects in the staged Living Songbook block.
- **Desired state:** Every open request can be closed safely, evidence replacement is explicit and auditable without exposing supporter content, callable failures retain their real meaning, operator and submitter interfaces tolerate stale or malformed records, and the durable records describe only behavior proved by tests.
- **Review boundary:** The staged Living Songbook source, Functions, Flutter models and repositories, operator and submitter interfaces, Firestore indexes, account cleanup scheduling, focused tests, and current engineering memory.
- **Non-goal:** No automatic chant edit, new evidence provider, public correction thread, production migration, Firebase deployment, seed write, commit, push, merge, store action, or release.

## Required corrections

### Queue closure and current authority

1. `Not changed` may close a received or planned request when the source chant is now missing, hidden, or removed. Every action that mutates chant content, trust, or evidence continues to require a current visible chant.
2. The operator interface keeps `Not changed` available for an authoritative unavailable source and explains that it is the only safe closure action. Cache-only, loading, and errored source states do not authorize any action.
3. A changed visible chant keeps the existing stale acknowledgement boundary. Evidence acceptance never accepts stale source state.

### Evidence replacement

1. A card shows both the chant's current evidence and the proposed evidence when either exists.
2. Attaching evidence to a chant with different existing evidence requires a separate explicit replacement acknowledgement in both UI and callable payload.
3. The server rejects an unacknowledged replacement without writing the chant, request, audit, or activity collection.
4. An accepted replacement preserves only the prior structured public evidence map in the operator-only audit record. It never copies the suggestion message, submitter identity, proposed wording, or proposed evidence URL into the audit.
5. Attaching the same evidence is not presented as destructive replacement.

### Typed failure meaning

Server `failed-precondition` responses include a stable reason for at least:

- account deletion in progress;
- chant unavailable;
- stale chant version;
- evidence replacement not confirmed;
- action and suggestion mismatch;
- request already closed.

The Flutter repository maps these reasons, duplicate admission, and request budgets to typed failures. User copy distinguishes retryable staleness from deletion, unavailable content, evidence conflict, duplicate intake, and limits.

### Authority and privacy tests

1. Functions regressions deny banned, under-17, wrong-policy, deletion-pending, deletion-job, and nonoperator callers at the intended boundary and assert no protected write occurred.
2. Operator widget regressions cover unavailable-source closure, stale acknowledgement, attach versus promote, and evidence replacement confirmation.
3. Submitter history widget regressions cover all status labels and optional resolution notes.
4. Audit tests compare complete stored rows. They prove that ordinary resolution contains no suggestion content or submitter identity and that explicit replacement adds only the approved prior evidence map.

### Remaining review corrections

1. A system-owned community chant may receive reviewed evidence without promotion. Promotion remains limited to user-created community chants.
2. Operator copy explains that another evidence acceptance can make a queued evidence request stale and that the submitter may need to resubmit against the current version.
3. Daily abandoned-draft cleanup emits a bounded aggregate warning for invalid rows without retrying the entire job. Actual cleanup failures still fail and retry.
4. Promotion milestones are never addressed to the `system` or `deleted-user` sentinels.
5. Suggestion list parsing isolates malformed or future-version rows instead of failing the complete queue or history stream.
6. Supporter-readable suggestion documents do not retain `resolvedBy`. Operator identity remains only in the operator-only audit collection.
7. Operator cards render both submitted and current source timestamps.
8. The open operator queue is oldest-first within its 50-row bound, and the matching composite index and query tests use the same order.

## Invariants

1. Accuracy intake never writes safety reports, counters, hiding state, title, lyrics, tune, player, club, era, or variations.
2. Direct suggestion writes remain denied. Server callables derive identity, timestamps, status, source version, and all resolution fields.
3. Evidence mutation requires current visible non-cache authority and exact source-version equality.
4. Closing an unavailable request cannot mutate a missing, hidden, or removed chant.
5. Operator audit rows never retain user-authored suggestion text, submitter identity, proposed lyrics, or proposed evidence.
6. Account deletion removes private suggestion rows, and supporter-visible rows contain no operator UID to redact.
7. One malformed stored row cannot hide other valid work.

## Verification plan

1. Add focused tests capable of failing on the staged implementation before applying runtime corrections.
2. Run focused Functions tests for admission authority, unavailable closure, replacement, audit privacy, sentinel notification behavior, and cleanup retry classification.
3. Run focused Flutter repository and widget tests for typed failures, malformed-row isolation, history states, stale acknowledgement, unavailable closure, and replacement confirmation.
4. Run the full Functions and Flutter suites, seed tests, rules TypeScript compilation, index JSON validation, and fixture-backed `flutter analyze lib test`.
5. Stage the complete intended handoff and run project memory, writing style, governance regressions, formatting, and diff integrity checks.
6. Keep Java-backed rules, native compilation, clean-runner CI, device walkthrough, packaging, push, deployment, and release pending separate authorization or environment evidence.

## Rollout and recovery

This schema has not shipped. Remove `resolvedBy` and adjust the evidence acknowledgement before packaging, so no data migration is required. If focused evidence fails, keep the correction local and restore the last testable implementation through bounded source edits. Do not deploy a client before compatible rules, indexes, and Functions are available.
