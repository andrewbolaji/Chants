# Change rationale: V1 production rollout planning

## Identity, authority and outcome

- **Date:** 2026-08-31. Owner: Andrew. Author: Codex.
- **Boundary:** Documentation-only planning after PR 28 merged. No runtime implementation, cloud write, deploy, repair, control transition, account/media deletion, signing, commit, push or merge is authorized here.
- **Checkout:** `chants-v1-production-rollout-plan`, branch `codex/v1-production-rollout-plan`, from main `42f20dc675a1de4fe85956783774a4cdc67f3a01`. Other worktrees and owner changes are untouched.
- **Source provenance:** Main tree `f2e39c2d10e5ac7d7c09873a9d1fc83d6a04745e` matches the earlier PR 28 CI tree. [Exact-main run 33368497566](https://github.com/andrewbolaji/Chants/actions/runs/33368497566) subsequently completed with all eight jobs green. Neither that run nor PR 28's run covers this proposal or future preparation code.
- **Changed records:** Active spec, roadmap sequencing, runbook status, affected deployment-status paragraphs in the milestone rationale, execution trail and this scoped record. The previous approved Call-Ups contract remains in baseline Git history; its scoped rationale is not overwritten.
- **Result:** One proposed source-preparation block, followed by separate exact core-rollout and media-canary approvals. No additional product feature is proposed.

## Verification and observations

Source inspection covered decision 026, the readiness/safety/correction records, operational readers/gates, report cutover and repair CLI, all exported endpoint names and wrappers, source indexes, installed Firebase CLI and project governance. The predecessor's sequential deletion code was read from its already pinned local archive, without invoking it. The local framework path remains `/Users/andrewbolaji/Documents/ChatGPT/CodexFrameworkAndCodeReviewer`; no nonexistent framework remote was pulled.

The read-only cloud probe observed project `chants-f95b4` between 07:37:34 and 07:37:43 UTC. Existing Firebase CLI authentication was used in memory; no service-account file, token, raw user document or Auth-user inventory was printed or copied. Infrastructure GETs and read-only IAM/Firestore aggregation POSTs changed no cloud configuration. Counts are independent observations, not a transactionally paused snapshot.

| Surface | Observed fact |
|---|---|
| Functions | Nine ACTIVE Node 20 functions; same regions, predecessor source generations and revisions as the readiness record |
| Resources | 256 MiB, 60-second timeouts, concurrency 80; eight max-instance fields are 20, one omitted. Min-instance fields omitted |
| Runtime/build identity | The shared default Compute service account has project Editor; effective inherited permissions, impersonation and existing-key scope were not established |
| Event/compute location | Firestore events and database in `nam5`; compute in `europe-west2` |
| Database recovery | PITR and delete protection disabled |
| Rules | Same July Firestore ruleset `a41a4e58-820e-4cfc-b330-e0f0af96ff33`, SHA-256 `5460df3e6e5400c8f3f816bacfc07ec7789a61b3420aa8ebd390fee616cd8316`; no Storage rules release |
| Indexes | Two READY chant indexes exactly match source definitions after normalizing the implicit document-name field; fourteen of sixteen are missing, no extra live composite |
| Storage | Expected default media bucket absent. Two infrastructure buckets only, not application-media storage |
| Services | Firebase Storage and Scheduler disabled. Scheduler listing returned 403, not proof of zero configured schedules |
| Artifact Registry | `europe-west2/gcf-artifacts` has `firebase-functions-cleanup`, DELETE/ANY, olderThan 86400s. The prior no-policy observation is superseded; origin not established |
| Operational control | Exact document returned 404 |
| Content counts | 192 chants, four comments, one report, zero comment reports, one profile |
| Empty populations | Creator profiles, performances, drafts, account-deletion jobs, media-deletion jobs, deferred-draft-cleanup jobs, update suggestions, follows and creator notifications each count zero |

No fresh team/player count was taken; the completed 20-team/622-player/192-chant readback remains historical seed evidence. One profile is not proof that no other Auth users or enabled signup paths exist. Cloud Run's nine services direct traffic to latest revisions, but that is not effective alternate-revision containment or in-flight drain proof.

Local probe evidence:

- `/private/tmp/chants-production-plan.gZgEgR/inventory.cjs`, SHA-256 `79beb3984b8ca237e1670ad10f0b2e3aa878e2d02afab1fccf7f1dd76fda0a36`.
- `/private/tmp/chants-production-plan.gZgEgR/inventory.jsonl`, SHA-256 `2c1c1638bb91a82c787b5b90d1c2688b41745c7e61ca93e4064a2381ad29dd30`.
- Temporary files are diagnostic evidence, not durable execution approval. Exact live metadata must be read again at rollout.

## Choices and tradeoffs

| Proposal | Reason and limitation |
|---|---|
| Resource/identity source preparation first | Current wrappers do not pin the proposed caps/account. Deploying first could inherit broad or inconsistent settings. The expected compiled manifest needs tests and independent review |
| One transactional control CLI | Readers fail closed but cannot prove generation history. Plan/apply, exact compare-and-set and lost-response readback keep mode changes explicit. No new service or automatic progression |
| Dedicated runtime; verified old-writer fence | Rules cannot stop old Admin code. The exact IAM identities, inheritance, revision paths and negative probes remain unresolved live-approval holds, not assumed facts |
| Core before media | Diagnose ordinary app journeys before upload/signing/cleanup. Core without workers also pauses account deletion, so it is private test state, never public-release readiness |
| Zero-backlog route | Avoid speculative replay machinery when every observed historical queue is empty. Fresh nonzero work stops for an exact recovery plan; ongoing cleanup still needs proof |
| Regional default media bucket | Match existing UK compute without relocating the US multi-region database. New default Storage location is independent of Firestore; this is a recommendation, not a saved setting |
| Explicit soft-delete/recovery retention | Balance recovery with privacy/cost. Live-object deletion is not physical erasure during retention. Final policy and owner approval precede public media |
| One consolidated next review | Review only the preparation diff and operational manifest, while preserving earlier source-review evidence. No claim that this proposal or later fixture corrections already received that review |

The source's 48 exports were compared mechanically with the plan's selectors: 48 unique exact names, no omissions/extras/duplicates, twelve groups of sizes 6/1/1/7/4/3/1/2/6/7/8/2. The 16-index source was compared with both observed live definitions. These are documentation consistency checks, not deployed-runtime verification.

The report repair estimate follows actual `endOfCollection` logic: 192 chants suggest eight pages; four comments at one per page require a fifth empty terminal page. Actual page markers and complete cursor chains, not these independent counts, govern completion. Existing privacy, bounded reads, digest, maintenance-generation and separate-readback requirements remain unchanged.

## References and unresolved gates

Official references were checked for current platform constraints, not substituted for project-specific cloud evidence:

- Source runtime settings override external values: [Firebase Functions management](https://firebase.google.com/docs/functions/manage-functions).
- Default Storage location and provisioning: [locations](https://firebase.google.com/docs/storage/locations), [default-bucket API](https://firebase.google.com/docs/reference/rest/storage/rest/v1alpha/projects.defaultBucket/create).
- Recovery and retention: [Firestore PITR](https://firebase.google.com/docs/firestore/use-pitr), [Storage soft delete](https://docs.cloud.google.com/storage/docs/soft-delete).
- Candidate IAM fencing needs supported permissions and propagation proof: [deny permission support](https://docs.cloud.google.com/iam/docs/deny-permissions-support), [access-change propagation](https://docs.cloud.google.com/iam/docs/access-change-propagation).
- An admitted transfer is not cancelled by grant expiry: [Cloud Storage resumable uploads](https://docs.cloud.google.com/storage/docs/resumable-uploads). The Firebase SDK's actual transfer/cancellation behavior still needs observed proof.

Approval of the proposed preparation spec would authorize only local source/tests. Exact IAM/probe principals and policy, repair credential isolation, backup/restore targets, maintenance window and actual private-cohort restriction must be resolved before live approval. Runtime/resource and retention values are proposals, not tested production capacities or agreed settings. A USD 25 budget is an alert, not a hard cap.

No runtime suite, emulator, native build, production smoke, paid backup/restore rehearsal or independent review was newly run for this documentation-only block. Staged governance/whitespace checks and the final owned-file handoff are recorded in `docs/EXECUTION.md` after completion. Recovery from this planning change is a normal documentation edit; no production rollback is needed.
