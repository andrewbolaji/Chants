# V1 final pre-launch hardening

## Approval and scope

Andrew approved `V1 final pre-launch hardening spec` on 1 September 2026. This Lane 1 block closes the residual launch-reveal overflow band found after PR 31 and updates the two existing GitHub artifact upload steps to the current official major. It does not change launch timing, navigation, authentication, policy meaning or version, the 17+ rule, backend behavior, Hosting, DNS, store state, or production data.

## Interface correction

The compact launch layouts already preserve a spinner-only visual cue and the complete semantic loading announcement. The adjacent non-compact band still overflowed when unresolved progress and enlarged text were active together.

Two production-widget regressions were added before runtime source changed. The merged PR 31 source overflowed by 18 pixels at 320 by 481 with 1.5x text and by 0.144 pixels at 320 by 558 with 2x text. The correction wraps only the non-compact launch column in a vertical scroll surface. Normal portrait content remains centered when it fits. Enlarged text keeps its requested scale, the written progress cue remains part of the non-compact presentation, and the root announcement remains `Chants. Getting things ready.` The shipped regressions prove overflow safety and retained content. They do not drag the surface; the independent review's separate production-widget probe confirmed that a drag fully exposes the written cue.

The breakpoint therefore continues to choose the compact or non-compact presentation while each branch owns its own overflow safety.

## CI maintenance

The failed-golden and Android debug artifact steps move from `actions/upload-artifact@v4` to `actions/upload-artifact@v7`. Artifact names, paths, missing-file behavior, seven-day Android retention, workflow triggers, job permissions, and job topology remain unchanged. No new action, script, service, permission, secret, cache, or artifact is introduced. Exact-head CI executed the Android upload successfully. The failed-golden upload was skipped because its tests passed, so that step's migration is verified from workflow source rather than an executed upload.

## Verification

- Known-bad evidence reproduces both non-compact overflow points before the runtime correction.
- Thirty-six focused launch-reveal, app-gate, and policy-gate tests pass after correction.
- The complete Flutter suite passes 528 cases, and CI-equivalent `flutter analyze lib test` reports no issues.
- Writing style, governance regressions, native-project, launch-services, 37 device, guide, policy, and landing cases, workflow-version count, staged project memory, and whitespace checks pass.
- Commit `1e2ce93a3b46879fd1b59c0d4a8efa80ae67efb7` was pushed to PR 32. Exact-head run `33550474487` completed all eight jobs successfully and produced the seven-day Android debug artifact.
- A bounded independent review reran the relevant local evidence, inspected the exact PR and CI boundary, and approved the source for merge with no Critical or High finding.
- Andrew approved the resulting documentation evidence correction, which fixes the true baseline and separates executed evidence from source-inspected evidence without changing product source.

## Remaining gates

This documentation-only correction still needs separate commit and push authority, followed by replacement exact-head CI for the resulting PR 32 head. Merge, physical-device walkthrough, Hosting publication, domain connection, store configuration, and production mutation remain separate decisions.
