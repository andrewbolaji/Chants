# Post-launch-policy independent review correction

## Approval and scope

Andrew approved `post-launch-policy independent review correction spec` on 1 September 2026. This Lane 2 correction addresses the independent review of the uncommitted V1 launch policy and deletion closure. It changes source, tests, and durable records only. It does not commit, push, merge, deploy, publish policy, configure a provider, mutate production, or change the 17+ rule.

Decision 016 remains authoritative for target-side safety retention. The correction does not remove that deliberate private boundary. It restores precise disclosure that a restricted safety or moderation record created by another person may retain the deleted account ID until the record's own retention rule deletes or genuinely de-identifies it.

## Corrections

The real signed-out welcome now exposes Help and Policies, which reaches Privacy, Terms, Community Rules, Rights and takedown, Delete account, and Support. Evidence begins at the signed-out entry state and opens each destination rather than constructing the hub directly.

The returning-user `v2` gate is one scrollable surface. It shows the accepted contract version and effective date and preserves Help and Policies, Support, the shared real account-deletion action, and Sign out without requiring acceptance. The narrow enlarged-text regression caught the fixed-footer overflow during implementation.

Community Rules and Support now contain complete urgent child-safety instructions in the app: the exact email subject, a direction not to download or forward abusive material, a request for the Chants location or ID plus description, and emergency-services direction for immediate danger. Each of the six Hosting routes now carries its own exact effective date, and the source contract requires it on every route.

Policy-version evidence now includes an exact Firestore denial for a stale `v1` profile and an exact stale `v1` Storage fixture. The Functions dispatch command's reviewed-source scope includes `storage.rules`. Documentation identifies `verificationCompletedAt` as operator-attested evidence whose freshness is validated by source, not a challenge performed by the command.

The deletion integration suite adds a real-emulator case with 200 owned performances and 200 owned drafts. It executes the maximum performance page, checks 200 deterministic media jobs and redaction, advances the empty boundary, executes the maximum draft page, and checks 200 retained cleanup jobs and exact private account correlation. The case passes inside the complete 24-case local Firestore-emulator suite.

The runbook now states that transaction failures leave durable work retryable but event retry is finite and there is no periodic account-job re-kick. A stale signal or private phase-age check must detect exhaustion or a missed event before an operator diagnoses and triggers the reviewed forward-recovery path.

## Documentation reconciliation

The execution-log contract now appears before every entry. The engineering overview points to `functions/src/policy.ts` as shared Functions policy authority. Current test counts distinguish locally run evidence from Java-backed clean-runner evidence. The interface record, policy pack, runbook, decision, rationale, learning memory, and change specification describe the same reachability, deletion, attestation, child-safety, and recovery boundaries.

## Verification

- Focused auth, policy-document, and app-gate regression run: 55 passing.
- Complete Flutter suite: 519 passing.
- Production Functions TypeScript build and unit suite: 229 passing, 24 emulator cases compiled and skipped outside the emulator.
- Seed suite: 74 passing.
- Policy contract: 7 passing.
- Launch guide: 9 passing.
- Device readiness: 10 passing.
- Launch-services and native-source contracts: passing.
- Java-backed Firestore and Storage rules: 174 passing locally on Homebrew OpenJDK 21.
- Dedicated real-Firestore-emulator transaction suite: 24 passing locally, including the maximum deletion pages.

Analysis, complete governance, writing-style, whitespace, secret-pattern, and final-diff checks are recorded in `docs/EXECUTION.md` when the correction handoff closes.

## Remaining holds

The correction remains uncommitted and unpushed. Local verification is complete. It needs packaging authorization, exact-head clean-runner CI including 174 rules assertions and 24 real transaction cases, and one independent review of the corrected range. Legal review, branded email delivery, child-safety operations, retention and external-deletion rehearsal, compatible deployment, publication, store reconciliation, and signed-device acceptance remain separate launch holds.
