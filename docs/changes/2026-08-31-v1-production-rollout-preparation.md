# Change implementation rationale: V1 production rollout preparation

## Change identity and boundary

- **Owner:** Andrew. **Implementation:** Codex. **Date:** 2026-08-31.
- **Base:** Main `42f20dc675a1de4fe85956783774a4cdc67f3a01`. **Target:** Precommit preparation snapshot on `codex/v1-production-rollout-plan`; the review PR's packaging receipt must name the final SHA, tree and exact-head CI.
- **Approval:** The source-preparation portion of `docs/CHANGE_SPEC.md` is approved. Andrew subsequently authorized one commit, push, a review PR and exact-head CI. Cloud writes, credential access, deployments, control transitions, repair, paid rehearsal and merge remain excluded.
- **Population:** Runtime settings and seven wrapper overrides; one local control CLI; two existing repair-CLI helpers exposed for reuse; two focused test files and the existing demo integration suite; directly affected records. The six earlier staged planning documents are included intentionally. Other worktrees remain untouched.
- **Non-goals:** New endpoint, admission class, event path, collection, dependency, CI job, replay service, product feature, rules/seed change or cloud executor.

## Outcome and capability map

| Boundary | Before | Implemented source |
|---|---|---|
| Runtime deployment | Most resource settings and runtime identity implicit | `runtime_options.ts` pins Node-22-compatible SDK settings, with seven approved resource overrides in `index.ts` |
| Operational transitions | Readers only; operator edits could reuse a generation | Local read/plan/apply command, exact-state transaction and separate readback |
| Existing repair command | Source/private-file guards were private implementation details | Same repair behavior, guards exported and reused by the control command |
| Release authority | Planning facts and unresolved live prerequisites | Explicit approval checklist below; no setting or live predicate silently treated as complete |

## Implementation choices, state and failure

`setGlobalOptions(V1_RUNTIME)` runs before endpoint construction. General settings are CPU 1, 256 MiB, 60s, min 0, max 3, concurrency 20 and the dedicated runtime account. Four cleanup workers use 512 MiB/300s/max 1/concurrency 1; draft submission/approval use 512 MiB/60s/max 1/concurrency 1; monitoring uses max 1/concurrency 1. Regions, triggers, event paths, schedules, retries and business handlers are unchanged. These are deploy-time settings, not a global cost cap, distributed lock, throughput benchmark or existing cloud account.

`operational_control_cli.ts` is a local entrypoint, never exported from `index.ts`. No command defaults to apply. All modes require exact project and source SHA plus a private credential path. The command requires a completely clean Git checkout, rejects emulator redirection, validates arguments and plan before initializing the Admin SDK, and checks credential project/type. It does not authenticate human approval or inspect the credential's effective permissions. The live manifest must isolate that identity separately.

A plan holds schema/project/source, canonical expected data with Firestore update time, and a target with exactly the existing four fields. The shared parser owns valid control states. First creation must be maintenance/workers false at generation 1. Existing transitions must change mode or worker flag and increment exactly once; overflow, unknown fields and media without workers are rejected. Hashing canonicalized JSON makes key order irrelevant, while changing any approved value changes the digest.

Apply checks the approved digest/source before database access. A transaction reads only `operationalControls/v1`, compares data and update time, then creates or replaces only that document. Firestore may retry the transaction at most three times. Version matching rejects an intervening change-and-restoration even when the four fields match again. A literal no-op set can preserve the timestamp because it did not change stored data.

An already-matching target is observed without another write. After either acknowledged execution or a transport exception, a separate read must match the exact target. The output deliberately says `target-observed`, not that this plan authored the state. A competing writer could have produced the same target. A stale different target stops; missing/invalid/read-failed state never becomes success. There is no compensation, automatic next transition, rollback, queue replay or generation repair.

Private JSON must be a nonsymlink owner-only regular file of at most 1 MiB. Plans live directly in the already ignored `.private-report-repair/` directory, whose resolved path must match; plan creation uses exclusive `wx` and mode 0600. No new private-storage convention is added. The filesystem checks assume a trusted local operator; they are not protection against a malicious process racing local files. No new credentials are created. SDK errors and private command arguments are not printed by the entrypoint.

## Dependency, security and cost impact

No package/lock/runtime version or CI job changes. Node 22 remains pinned by the existing engine and CI. The compiled SDK manifest, not a count of source annotations, verifies every endpoint's effective settings. Source-controlled runtime options can override external configuration, as documented in [Firebase Functions management](https://firebase.google.com/docs/functions/manage-functions).

The proposed runtime principal is `chants-v1-runtime@chants-f95b4.iam.gserviceaccount.com`. Source now selects it; creation, grants, impersonation and effective access are not verified. Existing app/operator authorization, schema, admission classification, privacy and cleanup semantics are unchanged. The control CLI is an Admin tool: its digest is an operator mistake-prevention boundary, not authorization against an attacker who already holds production credentials.

Control planning/read takes one document read. Apply uses at most three transaction attempts plus a separate readback. No production latency or cost measurement is claimed. Resource limits reduce burst capacity but may cause queuing/timeouts at real load and do not eliminate cross-revision overlap or all platform overshoot. Review observed load before raising them; keep USD 25 as alert-only, never promise a hard spend cap.

## Operational approval manifest

**HOLD: not a deployment authorization or executable IAM policy.** Source settings below are built; cloud settings are not applied. The 07:37 UTC inventory and IAM etag `BwZaMxx+C7A=` are historical observations. All policy versions and identities need a fresh read immediately before the later live approval.

| Surface | Exact proposed target or known identity | Required evidence before live release |
|---|---|---|
| Candidate | Final preparation commit/tree and built endpoint/source hashes | Packaging, all eight exact-head CI jobs and one consolidated Claude review; current uncommitted code is not an immutable candidate |
| New runtime | `chants-v1-runtime@chants-f95b4.iam.gserviceaccount.com` | Create keyless under separate approval; verify database reads/writes, required Auth get/update/delete, bucket get/create/delete and self-scoped signing. Exact roles/custom permissions must be reviewed, not inferred from the name |
| Legacy runtime/build | `66623447919-compute@developer.gserviceaccount.com` | Preserve necessary build/Eventarc behavior while denying old data mutation. Review inherited rights, impersonation, all revisions and drained calls. Do not remove project Editor broadly without an impact inventory |
| Other known writers | Appspot/default/cloud-services and Firebase Admin SDK principals in the historical inventory | Fresh principal/key metadata and effective-access inventory, including human and external writers. No key material in Git. A repository script pause alone is not containment |
| Deployer and control/repair principal | Exact private identities intentionally unresolved | Approve a dedicated, temporary, least-privileged execution identity and private credential handling. Neither CLI accepts a Firebase CLI login as its service-account file. No shared Admin key exemption by convenience |
| Negative probe | Proposed `operationalControls/containment-probe`, never `v1` or a seeded/user target | Separately approve harmless create/update/delete denial probes under each exact old writer and allowed rollout identity; record policy/revision and observed denial. No probe has run; unexpected success stops and requires exact cleanup approval |
| Report replacements | `onReportCreated`, then `onCommentReportCreated`, original document paths | Individually remove only these created-event identities after containment, then deploy/read back the reviewed written versions. Full repair/readback before intake opens |
| Media storage | `chants-f95b4.firebasestorage.app`, Standard `EUROPE-WEST2` | Firebase default linkage, access/signing, rules, explicit seven-day soft delete and cleanup evidence; no bucket exists in the last observation |
| Recovery | Proposed `chants-f95b4-rollout-recovery` in `us-central1`; isolated database `chants-rollout-restore-20260831` | Check name availability and export/location compatibility; approve cost, PITR/delete protection, backup/restore, restrictive access and 30-day export retention before creating anything. No production triggers or client access on the restored database |
| Artifacts | Existing `europe-west2/gcf-artifacts`, named cleanup policy | Approve one-to-30-day retention change and verify exact readback; don't attribute the observed one-day policy to an unverified actor |
| Schedules/workers | Existing source daily 03:00 UTC cleanup and 15-minute monitor | Enabling/deploying Scheduler may activate immediately. Keep workers closed, inventory jobs and terminal drafts; fresh nonzero backlog requires an exact recovery plan |
| Private test scope | Owner preserved; newly created disposable test account, normal Auth/onboarding | Inventory actual signup/provider and Auth scope. Project-wide core/media flags are not a per-UID canary. Approve real admission restrictions or actual exposure before opening |

The live owner must resolve every HOLD in a private execution packet containing exact IAM policy versions/principals, resource bodies, probe identities, rollback/forward-recovery actions and observations. This source block does not fabricate missing dashboard evidence. Source approval creates neither new privileges nor approval to probe or delete anything.

## Verification performed

The execution log owns exact times, commands, failures and final results. Local verification uses Node 22.23.2, Java 21.0.12.1 and only the fixed `demo-chants-repair` emulator for transactions. No production credential or user data is used.

| Check | Local result |
|---|---|
| Locked install, production `npm run build` | Pass, Node 22.23.2; install scripts/audit disabled, lockfile unchanged |
| Full `npm test` | 214 pass; 23 emulator-only cases intentionally pending without the fixed emulator |
| Existing demo integration command | 23 pass in 27 seconds, including all five new control scenarios and all 18 prior scenarios |
| Production artifact inspection | 48 endpoint definitions; manifest SHA-256 `3d273a88b09f41a49c83f09cd405937c9b392f1ca56af6a4fc533fed3b1a4f40`, local file `/private/tmp/chants-rollout-preparation-manifest.json` |
| Staged governance and source-contract checks | Final outcome in `docs/EXECUTION.md`; separate from runtime and cloud evidence |

- The runtime contract first compiled against the predecessor, then failed on the unset service account while unchanged trigger/schedule assertions passed. The completed contract checks all 48 effective compiled endpoints, not merely helper constants.
- CLI unit tests cover defaults, unknown/duplicate/missing arguments, project/SHA/digest, exact schemas, versions, overflow/no-op, unsafe initial state, credential shapes, private files/directories, dirty Git states and sanitized real-entrypoint failures.
- Five new real transaction cases cover creation and plan read-only behavior, every launch-mode transition, duplicate/lost acknowledgements, competing plans, change-and-restoration, source/digest rejection, retained malformed fields and readback failure. They run in the existing integration file/job alongside the prior repair/upload cases.
- No new Flutter/native/rules behavior exists in this diff; clean-runner CI remains the later full-platform gate. No production smoke, IAM probe, backup/restore rehearsal or independent review has run for this new block.

## Rollout and recovery

Use the exact stages and approval boundaries in `docs/CHANGE_SPEC.md`. `docs/RUNBOOK.md` contains future read/plan/apply examples. Rebuild clean production output from the eventual reviewed commit; the source guard cannot attest arbitrarily edited ignored JavaScript. Freeze that build identity in the execution packet.

Before deployment, a normal source revert removes this preparation without changing live state. After deployment, retain a reviewed compatible source artifact and forward-fix rather than restore the unsafe July backend. Close through a fresh higher-generation plan; do not reuse an earlier generation, overwrite a malformed control, or assume closing cancels admitted work. External generation rollback/deletion can still violate history, and this CLI cannot recover it automatically.

## Repository rationale reconciliation

The operational-control and deployment sections are refreshed in the repository rationale, runbook and profile. Decision 026 gains the source-only CAS writer and its limits. The full source map is not re-reviewed. The earlier planning record remains dated evidence, not a second current specification. No new learning or interface decision is manufactured for this non-UI block.
