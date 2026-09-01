# Change spec: V1 launch policy and deletion closure

**Status: Approved.** Andrew approved `V1 launch policy and deletion closure spec` on 31 August 2026. He also approved daily moderation review, urgent safety prioritization, ordinary support and video acknowledgement within two business days, verified deletion within 30 calendar days, and no 24/7 promise.

**Independent-review correction:** Approved on 1 September 2026 as `post-launch-policy independent review correction spec`. The correction must make all six documents reachable from the real signed-out welcome, preserve support, actual account deletion, and sign-out for a returning user who does not accept `v2`, put complete urgent child-safety instructions and the accepted version/date in the app, strengthen stale-policy and real-transaction evidence, and correct the review records. Decision 016 target-side safety retention and the 17+ rule remain unchanged. No commit, push, merge, deployment, publication, provider change, or production mutation is authorized.

**Owner:** Andrew, through Thunderriver Tech LLC
**Lane:** 2
**Baseline:** merged PR 29 at `c3a071cfea70f68cd4d8f76d26561843d7478c31`, tree `2d59b99cd2539c42007ae728b54b25e397fad2b2`, with all eight jobs green in run `33408526284`
**Source-only authority:** implementation, local verification, durable records, and a review-ready handoff. No commit, push, merge, deployment, policy publication, email delivery, cloud mutation, age-rule change, store-territory change, or production deletion is authorized.

## Outcome

Make the V1 client and source policy surfaces tell the truth before the backend rollout:

1. Users can read Privacy, Terms, Community Rules, Rights and takedown, Delete account, and Support without signing in.
2. New and returning users accept one versioned Terms and Community Rules contract. Privacy remains a notice, not blanket consent.
3. Account deletion removes account-authored text, public creator identity, private activity, upload limits, drafts, and published performances while preserving only structural tombstones and justified safety or cleanup evidence.
4. Published performance removal queues the exact media path before creator ownership is replaced.
5. A public, no-login deletion page explains both the in-app and email request routes. A private operator procedure can dispatch only an identity-verified request into the same durable job.
6. Public copy and the runbook state the approved service and retention targets without claiming 24/7 coverage, immediate deletion, immediate storage erasure, or unverified provider behavior.

## Baseline evidence before this block

- `lib/presentation/content_policy/content_policy_screen.dart` says the full policy and detailed rules are coming soon.
- `lib/app/policy.dart`, `functions/src/index.ts`, and `firestore.rules` all enforce policy version `v1`, but that version points only to the placeholder Content Policy.
- Signed-out users have one Content Policy link, not the six required destinations.
- `functions/src/account_deletion.ts` anonymizes chant, comment, performance-comment, and performance attribution while retaining user-authored bodies.
- The deletion phases omit `performanceUploadLimits` and do not create `performanceMediaDeletionJobs` for the deleting creator's published videos.
- Hosting has no `/privacy`, `/terms`, `/community`, `/rights`, `/delete-account`, or `/support` page.
- `deleteAccount` correctly derives the caller from Firebase Auth, but there is no private support-side dispatch path for a verified request from someone who cannot use the app.
- Retention targets exist in `docs/LAUNCH_POLICY_PACK.md`; automation and operator evidence remain incomplete.

## Behavior and source of truth

### Policy contract

- The accepted contract is named **Terms and Community Rules** and uses one server-owned version.
- The first real version is `v2`, replacing placeholder `v1`. Dart, shared Functions authority, Firestore rules, Storage rules, and tests must move together.
- New onboarding requires an explicit checkbox for Terms and Community Rules. Privacy is linked separately and is not part of the checkbox wording.
- Existing profiles whose accepted version is not `v2` remain behind the acceptance gate.
- `acceptPolicy` and `completeOnboarding` derive the version and acceptance timestamp on the server. No client-supplied version is trusted.
- The six documents are readable before authentication in the app. Hosting source provides matching no-login routes, but publication requires a later explicit deployment approval.
- Chants remains 17+. This block must not change `kMinimumAge`, collect a server-side birth date, or alter store age settings.

### Deletion contract

- `accountDeletionJobs/{uid}` remains the durable source of truth and the user's Firebase UID remains derived from authenticated context for the in-app path.
- The job is upgraded compatibly. A job created by the current source must have the exact current schema and phase. Malformed or unsupported jobs fail closed and retain evidence.
- User-created chants are identified only by `createdBy == uid`. Seeded catalogue chants use `createdBy == "system"` and must never be redacted by account deletion.
- A deleted chant row becomes a hidden, removed structural tombstone with authored lyrics, title, tune, context, evidence, variations, and external media references removed. The document ID and relationship fields remain so dependent records do not point to a missing parent.
- Chant comments and performance comments keep their IDs and parent/root relationships, but authored body, display identity, handle, and mention projection are replaced with non-identifying tombstone values. Existing hidden or removed state is never reopened.
- Owned performances are hidden and removed, captions and creator identity are removed, and current-source visibility is closed. Each valid `performance-media/{performanceId}/source` path is written to the existing durable media-deletion queue in the same transaction before ownership is replaced. The transaction rechecks the live deletion phase, ownership, media path, and any existing cleanup payload before writing.
- Invalid performance/media identity fails the phase before mutation. It is never converted into a broad or guessed Storage path.
- Draft documents and account-owned upload-limit rows are removed in bounded pages. The same draft-deletion transaction rechecks current phase, owner, media path, and cleanup identity, then creates or links exact-path cleanup evidence with private account correlation before removing each draft, so later event delivery does not own that correlation.
- The job disables Auth first and remains retryable. Duplicate events, lost acknowledgements, page failure, already-missing Auth users, and finalization failure must preserve or resume progress.
- Safety and audit retention follows Decision 016. Unknown or user-authored audit detail is removed; allowlisted generated operator detail may remain under a non-identifying actor role. Target-side safety history is not silently broadened.

### External request contract

- `/delete-account` is public, usable without the app, and gives a copyable email request to `support@chantsfc.com`.
- An email From address, public handle, client-supplied UID, password, or one-time code is never deletion authority.
- Andrew verifies control through the current account contact or an equivalent provider reauthentication outside the repository, records only a minimal private case reference, then uses a source-bound private plan/apply command.
- The private command requires the exact project, reviewed source SHA, owner-only plan, approved digest, target UID, non-identifying case reference, recent verification time, and active operator identity. It writes no contact address or raw support message to Firestore or logs.
- Dispatch calls the same `requestAccountDeletion` workflow. It does not delete only Firebase Auth, expose a public operator endpoint, or invent a second cleanup implementation.
- Completion is not inferred from email receipt, callable acknowledgement, Auth absence, or account-job disappearance alone. The operator procedure checks remaining profile/content/limit/media/draft evidence before confirming completion.

### Service and retention contract

- Public wording: moderation is reviewed daily and urgent safety concerns are prioritized. Chants does not promise 24/7 monitoring or instant action.
- Ordinary support and video-review acknowledgement target: within two business days.
- Verified account-deletion target: within 30 calendar days, subject to any earlier legal deadline and explained permitted delay.
- Ordinary closed support/deletion correspondence target: delete after 90 days unless a separately justified safety or legal record is required.
- Closed reports, appeals, and moderation evidence target: delete or genuinely de-identify no later than 12 months after closure unless a documented legal hold applies.
- Routine logs and expired upload-limit/session rows target: 30 days.
- Unresolved cleanup evidence remains until verified closure. After verified terminal closure it is reviewed for removal within 30 days.
- Provider backup or recovery copies, if enabled, follow their configured periods and are not live Chants content. Source must not claim a setting or duration that has not been read back.
- Provider-controlled retention and mailbox cleanup remain operator/configuration evidence. Source must not claim those settings are already active.

## Invariants

1. No public client can create, edit, or delete an account-deletion job, media-cleanup job, support case, or audit row.
2. No external request can choose a target without an active operator and separately completed identity verification.
3. No account deletion can mutate a `createdBy == "system"` chant.
4. Authored body text and owned public media do not survive as public content after the relevant deletion phase.
5. Structural tombstones preserve IDs and reply relationships and never reopen hidden or removed content.
6. Exact-path cleanup is durable before performance ownership is removed.
7. A retry cannot enqueue a different path, regress a phase, recreate a deleted profile, or delete another user's handle reservation.
8. Privacy notice access never implies consent, and Terms/Community acceptance never implies consent to unrelated processing.
9. Missing live configuration, support-mail proof, legal review, or deployment evidence remains an explicit release hold. The approved virtual correspondence address is not evidence for a registered office or provider identity record.

## Failure, abuse, and recovery

| Trigger | Required behavior |
|---|---|
| Policy version drift across Dart, Functions, and rules | Deterministic source test fails; no release |
| Prior `v1` profile opens new client | Gate on `v2`; no write authority until accepted |
| Deletion page batch fails | Data and job phase remain retryable; no false completion |
| Published performance has an unexpected ID/path | Fail closed before redaction or cleanup enqueue |
| Media job already exists | Reuse the deterministic document and exact path; no duplicate target |
| Lost deletion response | Existing unknown-state client recovery stays authoritative |
| Support request is spoofed or lacks account-contact access | Do not dispatch; use separate manual recovery review |
| Operator plan is stale, altered, outside the private directory, or targets another source/project | Stop without a write |
| Cleanup evidence remains unresolved | Do not send completion; retain and investigate under the runbook |
| Approved mailbox becomes unavailable or market-specific legal language remains unresolved | Keep Hosting and store publication on hold; do not silently fall back to a residential address |

## Verification

Evidence must be capable of failing against the old behavior:

1. Functions tests prove authored bodies are removed, structural relationships remain, system chants survive, upload limits are deleted, exact performance cleanup jobs are created before redaction, invalid paths fail closed, and retries converge.
2. Functions tests prove verified operator dispatch rejects nonoperators, stale/altered/private-plan violations, unverified input, and client-style target substitution.
3. Flutter tests prove prior `v1` profiles are gated by `v2`; the stale gate retains support, actual account deletion, and sign out without acceptance; acceptance copy names Terms and Community Rules; Privacy is separate; and the actual signed-out welcome reaches all six destinations at representative and enlarged-text layouts.
4. Hosting contract tests prove all six routes exist, each has the exact effective date, contain the approved email and service targets where applicable, give complete urgent child-safety instructions, have no bracketed placeholders, and do not claim 24/7 coverage.
5. Existing account-deletion ambiguity, authorization, rules, media, onboarding, app-gate, and public-read tests remain green.
6. Run Functions build/tests, Flutter focused then full tests, `flutter analyze lib test`, rules typecheck and emulator suite when Java is available, the maximum 200-performance and 200-draft deletion-page emulator case, seed tests if shared contracts change, native iOS/Android source builds, governance, writing, and diff checks.
7. Inspect the generated Hosting tree, representative policy screens, the staged boundary, and the exact verification artifact.
8. One independent review covers this bounded source range after packaging. No deployment proceeds on local evidence alone.

## Non-goals

- No policy publication, email-domain setup, mailbox purchase, store listing, deployment, production data change, or real deletion.
- No change to the 17+ rule.
- No automated copyright judgment, licensed music, proactive large-scale media screening, or guaranteed legal safe harbor.
- No general support CRM, public deletion API, unauthenticated callable, full self-service data export, or remote wipe of offline files on another device.
- No blanket retention engine or deletion of unresolved cleanup, safety, recovery, or legal-hold evidence.
- No launch beyond the approved United States, United Kingdom, and Canada plan.

## Rollout and rollback

This source remains inert until separately reviewed, merged, deployed, and observed. Compatible source order is policy pages and client plus the `v2` backend/rules contract before public user submissions. Existing `v1` users then re-gate. Deletion schema changes require the reviewed Functions worker and callable to deploy together while admission is closed.

Rollback must not restore placeholder acceptance or the old body-retention promise. If the client needs reversal, close admission and ship forward with the last reviewed `v2` contract. If deletion processing fails, leave the account disabled and the durable job intact, repair forward, and do not manually delete only Auth or the job row.

## Publication holds

- Confirm `support@chantsfc.com` receives and sends successfully from an outside inbox.
- Closed 1 September 2026: Andrew confirmed approval of the notarized virtual business mailbox for public correspondence. Keep provider identity evidence and the residential address outside Git, and re-open this hold if service lapses.
- Obtain qualified review for the United States, United Kingdom, and Canada copy, including the 17-year-old user boundary, music/UGC rights, child safety, transfers, consumer terms, and any DMCA designated-agent decision.
- Reconcile Apple privacy and Google Data Safety answers with the final release SDK behavior.
- Verify real retention, provider settings, App Check, alert delivery, backup/recovery, and both-device walkthroughs under later approvals.
