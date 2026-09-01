# Change spec: V1 final pre-launch hardening

**Status: Approved, with evidence correction approved.** Andrew approved `V1 final pre-launch hardening spec` and later approved `PR 32 documentation evidence correction spec` on 1 September 2026.

**Owner:** Andrew, through ThunderRiver Tech LLC

**Lane:** 1, bounded interface correctness and CI maintenance

**Baseline:** merged `main` at `ff6587d8b800f7ff4722d0ef6b3da6c68a331aa7`, containing PR 31 and its eight-job green exact-head run `33541666404`

**Authority requested:** local source, tests, durable records, one reviewable commit, push, pull request, and exact-head clean CI. Merge, Hosting deployment, DNS, domain connection, store changes, backend deployment, and production mutation remain outside this block.

## Outcome

Close the last independently measured launch-layout overflow band before public release and remove the current GitHub-hosted artifact upload deprecation warning without changing app behavior outside that loading surface.

## Evidence and current defect

The final PR 31 reviewer independently swept the unresolved launch state and found that the non-compact column still overflows just above the 480-logical-pixel compact threshold when text is enlarged. The reproduced band includes 320 by 481 at 1.5x text and extends through 320 by 558 at 2x text. No standard portrait device height occupies the full band, but split-screen, freeform, foldable transitions, iPad multitasking, and display-size settings can reach it.

PR 31 CI also emitted a GitHub-hosted runner warning because both artifact steps use `actions/upload-artifact@v4`. The official action source now documents `actions/upload-artifact@v7` for GitHub.com. The current inputs used by Chants remain supported.

## Included

- Make the non-compact launch column vertically scrollable only when its content exceeds available height.
- Keep the current compact row choice, spinner-only compact progress cue, normal-portrait written progress cue, reduced-motion behavior, and root semantic announcement.
- Add known-bad-capable widget coverage at representative lower and upper points of the independently reproduced band, with unresolved progress and enlarged text active together.
- Change both existing CI artifact upload steps from `actions/upload-artifact@v4` to `actions/upload-artifact@v7` without changing artifact names, paths, retention, failure behavior, job permissions, triggers, or job topology.
- Update execution, interface, learning, and scoped change records only where the verified result changes current truth.

## Excluded

- Another compact threshold adjustment, text shrinking, font-size reduction, copy removal, animation timing change, or navigation change.
- A new package, workflow, job, script, dependency, service, permission, secret, cache, or artifact.
- Changes to authentication, policy meaning or version, the 17+ rule, Functions, Firestore, Storage, seed data, native signing, Hosting, DNS, domain connection, analytics, store state, or production data.
- The physical-device walkthrough, public deployment, rich-preview cache verification, and verified store buttons. Those remain separate launch gates.

## Design and invariants

1. The breakpoint chooses presentation, not safety. Both branches must remain overflow-safe at reachable bounded geometry.
2. The non-compact branch preserves enlarged text at its requested scale. It scrolls instead of scaling content down.
3. A normal portrait still displays `GETTING THINGS READY` and its spinner while initialization remains unresolved.
4. Compact geometry still displays the spinner without the redundant written cue.
5. Both forms retain the root semantic announcement `Chants. Getting things ready.`
6. Reduced-motion users continue to receive the final reveal frame immediately.
7. Artifact upload remains failure evidence only for failed goldens and a seven-day debug APK for successful Android builds.
8. CI continues to build and verify the exact Android and iOS application identities from the pull-request head.

## Failure and recovery

| Trigger | Required behavior |
|---|---|
| Non-compact launch content exceeds available height | Preserve content and semantics in a vertical scroll surface with no render overflow |
| Content fits normally | Keep the current centered composition and visible written progress cue |
| Artifact path is absent | Preserve the existing `ignore` behavior for optional golden failures and `error` behavior for the required APK |
| Artifact action migration fails on GitHub-hosted runners | Do not merge; restore the reviewed workflow version or repair forward, then run replacement exact-head CI |

The runtime correction is reverted by removing the scroll wrapper. The CI correction is reverted by restoring the prior action major. Neither rollback changes data, schemas, credentials, production state, or public routes.

## Verification

1. Before runtime correction, new production-widget cases reproduce the overflow at 320 by 481 with 1.5x text and 320 by 558 with 2x text while unresolved progress is shown.
2. After correction, the shipped cases render without exception and preserve the spinner, written non-compact progress, and complete semantic announcement. The shipped cases assert that the written cue remains in the widget tree; the independent review's separate drag probe confirms that the scroll surface can bring it fully into view.
3. Existing exact compact cases at 568 by 320 with 2x text and 320 by 480 with 1.5x text remain spinner-only and overflow-free.
4. Existing normal portrait, animation, reduced-motion, app-gate, and policy-gate evidence remains green.
5. The complete Flutter suite and `flutter analyze lib test` pass with the repository's documented non-secret Firebase analysis fixture.
6. Workflow inspection confirms exactly two `actions/upload-artifact@v7` uses and no `upload-artifact@v4` use.
7. Project memory, writing style, governance regressions, native-project, launch-services, and whitespace checks pass.
8. One exact-head pull-request run completes all eight jobs, produces the Android artifact through the migrated action, and has no Node 20 artifact annotation. A green golden job skips the failed-golden upload step, so that second migration is verified from workflow source rather than claimed as executed evidence.
9. A bounded independent review finds no unresolved blocker before merge.

## Packaging and next gate

The implementation was packaged at `1e2ce93a3b46879fd1b59c0d4a8efa80ae67efb7`, pushed to PR 32, and verified by all eight jobs in exact-head run `33550474487`. A bounded independent review approved the source for merge with no Critical or High finding. This documentation-only evidence correction is not yet committed or pushed; any new PR head requires replacement exact-head CI. Merge remains Andrew's decision. Hosting publication and `chantsfc.com` connection begin only in the separately approved deployment phase.
