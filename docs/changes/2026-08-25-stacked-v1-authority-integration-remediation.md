# Stacked v1 authority and integration remediation

**Completed in repository:** 2026-08-25
**Type:** Lane 2 authorization, moderation lifecycle, trigger, UI resilience, and CI gate
**Application behavior changed:** Direct Firestore writes, Discover, live detail, comments, Player-prefilled submission, and vote-trigger deletion handling

## Change identity and boundary

- **Change:** Close the P1 and bounded P2 findings from the combined v1 feature-stack review.
- **Target:** `codex/v1-stacked-engineering-review`, based on exact stacked draft PR 9 head `b72f4ab`.
- **Included:** Exact direct-write schemas, server-owned reconciliation stamps, Team and Player referential checks, moderation-aware Discover retention, current-live detail action authority, comment failure containment and responsive states, stale Player recovery, missing-parent vote-trigger handling, deterministic CI analysis configuration, tests, goldens, and framework records.
- **Excluded:** Report velocity limits, destructive-workflow redesign, signing, policy copy, dependency upgrades, native compilation, Firebase deployment, live seed access or writes, merge, release, and device actions.
- **Approval:** Andrew explicitly approved `approved stacked v1 authority and integration remediation spec` on 2026-08-25 before runtime edits began.

## Outcome

- Firestore rules now enforce exact, typed client shapes for chants, votes, comment likes, comments, three report collections, and feedback. User chant creation requires the stored Team hierarchy, a same-Team Player for Player subjects, empty variations, and no direct media. Unknown or parser-hostile values are denied.
- Vote and comment-like repositories use transactions. The client creates the public intent shape only and changes only `value` thereafter, preserving Function-owned `appliedValue`.
- Discover keeps a safe card through an ordinary transient error but removes it on permission denial, a current missing document, or hidden or removed current content.
- Live detail treats route data as readable fallback only. Save, Share, Report, Vote, and Comment actions wait for an active, error-free, current visible chant.
- Comment-like hydration contains read failure and retries on a later emission. Empty comments fit a 390 by 844 viewport at 1.8x text. Failed block Undo shows bounded recovery copy.
- A stale or moved prefilled Player clears safely, explains the recovery, and lets the fan choose another Player or subject. Player loading failure no longer traps the form.
- The vote trigger now verifies the parent chant before querying votes or opening a batch. A deleted parent produces no query, write, or retry loop.
- CI always runs Flutter analysis, using the secret when available and the checked-in Firebase options example otherwise.

## Invariants preserved

- Firestore rules remain direct-client authority; Admin SDK seed and Function writes remain separately validated.
- Existing legacy visible chants remain readable. Strict schema enforcement applies to new direct writes and direct author updates.
- Ordinary connectivity failure may retain readable public content; moderation denial does not retain action authority.
- Function-owned counters and reconciliation stamps remain server-owned.
- No production, staging, seed, deployment, merge, release, signing, or device state changed.
- The user's pre-existing Gradle and lockfile modifications remained unstaged and were not overwritten.

## Verification

- `flutter test`: 282 passed locally.
- `flutter analyze lib test`: no issues.
- `cd functions && npm test`: 36 passed.
- `cd seed && npm test`: 42 passed.
- `cd test_rules && npx tsc --noEmit`: passed.
- Java-backed local Firestore emulator: 131 passed.
- `git diff --check`: passed.
- A separate repository-wide local `flutter analyze` traversed ignored `build/ios/SourcePackages` left by the earlier failed native build and reported errors in third-party package examples. The scoped first-party command is clean. The changed CI job runs repository-wide analysis on a clean checkout, so clean-runner CI remains the independent proof for that exact gate.
- Focused coverage includes Firebase-shaped permission denial versus transient failure, real Discover-to-detail stale authority, every live-target action before current confirmation, comment hydration retry, failed Undo, 1.8x empty state, missing and failed Player data, hostile raw writes, and deleted vote parent.
- Red evidence from the review reproduced stale Discover retention, escaping comment-like read failure, and the 430-pixel empty-state overflow before implementation. Existing deliberate payload, persistence, ranking, timing, and reply red guards remain in the full suite.
- Visual evidence: both submission goldens passed locally. The stale Player golden was inspected at 390 by 844; recovery copy and the one-line Player selector are readable with no clipping.

Independent review and clean-runner CI remain pending. Native Android and iOS compilation plus the combined device walkthrough remain release gates.

## Security, privacy, abuse, and infrastructure impact

This block narrows direct-client authority and adds no collection, index, analytics event, permission, hosted media, or background task. Chant creation may read one Team and, for Player subjects, one Player in rules. The vote trigger adds one parent read before its existing aggregate query and avoids work when the parent is absent.

Report and feedback shape and size are bounded, but velocity limiting remains a separate abuse-control task. Saved Songbook remains a local public-content copy; this change does not add cross-device or cloud persistence.

## Rollout, rollback, and follow-up

After separate authorization and review, deploy rules first, Functions second, and client last. No migration is required for reads. Before release, require clean-runner CI, native compilation, the combined device walk, real content-policy copy, and production signing.

Rollback uses the previous rules and Functions plus a client revert. Because client rollback is store-latent, the hostile rules suite and current-live action tests are required release gates. Future work should address report velocity, resumable merge and deletion, Discover pagination, formatter normalization, staging and recovery runbooks, and operational telemetry.
