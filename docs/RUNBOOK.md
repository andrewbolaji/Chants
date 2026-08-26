# Operator runbook

This runbook describes the source-backed recovery paths that exist today. Dashboard names, alerts, backups, deployed versions, and production credentials are not represented in the repository and must be verified by the operator before public launch.

## Service and ownership

- **Purpose:** Let football supporters browse, learn, save, submit, discuss, vote on, and report chants while operators preserve archive trust and community safety.
- **Owner and escalation:** Andrew is the current product and system owner. A second operator and external escalation channel are not yet recorded.
- **Dependencies:** Firebase Auth, Firestore, Cloud Functions, App Check, Crashlytics, mobile operating-system storage, the native share sheet, and the system browser for evidence links.
- **Dashboards, logs, and traces:** Firebase and store dashboards are external and not linked from the repository. `firebase functions:log` is available from `functions/package.json`; use it only with explicit environment authorization and avoid copying sensitive payloads into project memory.
- **Deployments and recent changes:** Git history, merged pull requests, GitHub Actions, `docs/EXECUTION.md`, and scoped rationales under `docs/changes/`.

## Health

| Signal | Healthy | Degraded | Owner or action |
|---|---|---|---|
| Public browse | Current visible chants load; transient cache states are labelled | Permission errors, authoritative absence, or repeated load failure | Confirm deployed rules, indexes, client version, and Firestore availability |
| Live actions | Vote, comment, report, feedback, share, and new save obey current authority | Repeated callable or rule rejection for a valid current target | Confirm Auth, App Check posture, rules, Functions, target visibility, and client compatibility |
| Counters | Stored child rows and visible totals converge | Score, comments, likes, user reports, or flags remain inconsistent | Run read-only diagnosis first, then use the reviewed reconciliation path that matches the counter |
| Account deletion | Accepted jobs advance and pending accounts remain gated | A job remains in one phase, retry count grows, or a pending user regains authority | Preserve job state, inspect worker error without exposing payloads, and use forward recovery |
| Saved Matchday Songbook | Same user can reopen saved copies without network | Corrupt, UID-mismatched, missing, or cleanup-locked local state | Use the built-in recovery or removal path; do not hand-edit application files |
| Crash and error telemetry | No new release-correlated spike | Crashlytics or Function errors rise after a change | Stop rollout, identify exact version and first failing journey, then choose rollback or forward fix |
| Seed identity | Read-only preflight reports no collision and reviewed IDs remain stable | A live ID is owned by a different source or a rename would create a duplicate | Stop before writes and prepare a migration-specific Lane 2 plan |

No numeric alert thresholds or observation windows are approved yet. Set them before beta from an observed baseline rather than inventing them here.

## First response

1. Confirm the exact environment, app version or commit, affected account class, start time, and user-visible impact.
2. Check recent merges, deployments, rules, Functions, index changes, seed writes, and configuration changes.
3. Preserve minimal evidence without storing credentials, personal data, report text, or raw production payloads.
4. Reproduce against local tests or an authorized emulator when possible. Do not use production writes as a diagnostic probe.
5. Choose the smallest compatible mitigation: stop a rollout, disable a risky entry point, redeploy a reviewed prior server boundary, ship a forward client fix, or use an existing reconciliation path.
6. Verify recovery from the affected user journey and authority boundary, not only process health.
7. Record the incident or substantial correction in `docs/EXECUTION.md`; promote a reusable lesson only after evidence supports it.

## Common symptoms

### Public content does not load

- **Likely causes:** Firestore outage, missing index, deployed rules mismatch, permission denial, target removal, or incompatible client query.
- **Diagnosis:** Reproduce the exact query in an authorized emulator; inspect current rules and indexes; distinguish a transient error from typed permission denial and authoritative absence.
- **Mitigation:** Restore a compatible rules, index, Functions, and client set. Do not weaken read authorization merely to make a query pass.
- **Recovery verification:** Signed-out and signed-in browse load current visible content; hidden and removed content stays absent; cache-only content remains labelled and non-actionable.
- **Escalate when:** A broad rules rollback would reopen private collections or direct-write boundaries.

### Valid users cannot submit or interact

- **Likely causes:** Auth expiry, App Check enforcement mismatch, pending deletion state, rate budget, hidden or removed target, callable deployment mismatch, or restrictive rules deployed before a compatible client or Function.
- **Diagnosis:** Identify the exact action and typed error. Verify target visibility and deletion state. Compare deployed boundary order with the relevant decision and change rationale.
- **Mitigation:** Fix deployment compatibility or the narrow failing boundary. Do not bypass pending-account, report-budget, or current-target checks.
- **Recovery verification:** The valid action succeeds, duplicate or rate-limited input remains deterministic, entered report or feedback work is preserved on failure, and unauthorized direct writes still fail.
- **Escalate when:** The correction would change authorization, moderation, privacy, or stored schema without a reviewed Lane 2 plan.

### A visible counter is wrong

- **Likely causes:** Trigger delivery lag or failure, missing parent during a child event, unreviewed manual write, or a defect in aggregate reconstruction.
- **Diagnosis:** Compare the parent aggregate with its stored child documents using read-only access. Identify which counter owner and trigger applies.
- **Mitigation:** Use or extend a reviewed ground-truth reconciliation path. Never patch the counter from the client.
- **Recovery verification:** Recomputed totals match stored children and remain correct after duplicate and reordered test delivery.
- **Escalate when:** Reconciliation would scan an unbounded production population or overwrite data whose source of truth is unclear.

### An account-deletion job does not finish

- **Likely causes:** A bounded page failed, Auth deletion failed transiently, a delayed writer appeared, or the worker reached its retry limit.
- **Diagnosis:** Inspect the private job phase, cursor, retry metadata, and minimal error classification through authorized operator access. Confirm the pending profile remains authoritative.
- **Mitigation:** Correct the failing compatible boundary and retrigger the idempotent worker. Do not delete the job, clear the pending marker, or restore local data to guess at acknowledgement.
- **Recovery verification:** The worker advances through all phases, private data is removed, retained contributions and allowed audit history satisfy the anonymization contract, Auth deletion tolerates already-missing users, counters converge, and the final job and profile disappear atomically.
- **Escalate when:** Progress requires changing retained-data policy, audit allowlists, or the durable job schema.

### A seed preflight reports a collision

- **Likely causes:** A reviewed ID was changed, live content predates explicit ownership metadata, or a source file points at an ID owned by another club or chant.
- **Diagnosis:** Stop before writes. Compare reviewed JSON, planned operations, live document identity, and the last known seed record through the authorized read-only preflight.
- **Mitigation:** Prepare a migration-specific plan with coexistence, rollback, and link implications. Do not rename IDs or rely on title-derived identity.
- **Recovery verification:** The plan is collision-free, a title rename preserves the document ID, a second run is idempotent, and the reviewed source round-trips.
- **Escalate when:** Any existing public or externally referenced identity would change.

### Saved matchday content is unavailable offline

- **Likely causes:** Snapshot was never saved, UID changed, local file is corrupt or from a future schema, deletion lock is active, or the operating system removed application data.
- **Diagnosis:** Reproduce with the same signed-in UID, then use the product's labelled local recovery state. Distinguish a missing local copy from a live refresh failure.
- **Mitigation:** Refresh while online or remove and save again when current authority permits. Preserve deletion locks and UID isolation.
- **Recovery verification:** Force-stop, enable airplane mode, relaunch, open overview, club, and chant detail, then confirm freshness and saved-copy labels remain visible.
- **Escalate when:** Recovery would require cross-account file access or bypassing an account-deletion marker.

## Rollback and forward recovery

- **Application:** Stop distribution of a bad candidate and ship a corrected build. Store rollback mechanics and signed artifact ownership are not yet documented.
- **Configuration:** Restore a reviewed compatible configuration through the owning Firebase or store console. Record the exact before and after values without copying secrets.
- **Rules and Functions:** Verify deployed baseline first, then deploy a reviewed compatible prior or forward version. CI success does not prove deployed parity.
- **Schema and data:** Prefer backward-compatible additions and forward recovery. Stable seed identity, account deletion, counters, and safety records each have specific decisions that take precedence over generic rollback.
- **External side effects:** Native sharing and evidence links leave the app boundary. Chants cannot recall third-party copies, browser history, or recipient data.
- **Disabled merge:** `mergeChants` remains stopped before parsing or mutation. Do not re-enable it as incident mitigation.

## Backup and restore

- **Backup policy:** No source-backed Firebase backup, point-in-time recovery, or export policy is verified.
- **Last restore exercise:** None recorded.
- **Restore steps:** Not approved. Before public launch, document the configured Firebase backup surface, retention, access owner, restore target, and a dated non-production restore exercise.

## Post-incident

- Record timeline, impact, affected versions and boundaries, detection gap, mitigation, recovery evidence, and durable actions.
- Give each action an owner, trigger, and verification method.
- Keep private reports, credentials, identities, and raw production payloads out of repository records.
