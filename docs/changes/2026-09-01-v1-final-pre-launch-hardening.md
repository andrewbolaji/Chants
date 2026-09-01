# V1 final pre-launch hardening

## Approval and scope

Andrew approved `V1 final pre-launch hardening spec` on 1 September 2026. This Lane 1 block closes the residual launch-reveal overflow band found after PR 31 and updates the two existing GitHub artifact upload steps to the current official major. It does not change launch timing, navigation, authentication, policy meaning or version, the 17+ rule, backend behavior, Hosting, DNS, store state, or production data.

## Interface correction

The compact launch layouts already preserve a spinner-only visual cue and the complete semantic loading announcement. The adjacent non-compact band still overflowed when unresolved progress and enlarged text were active together.

Two production-widget regressions were added before runtime source changed. The merged PR 31 source overflowed by 18 pixels at 320 by 481 with 1.5x text and by 0.144 pixels at 320 by 558 with 2x text. The correction wraps only the non-compact launch column in a vertical scroll surface. Normal portrait content remains centered when it fits. Enlarged text keeps its requested scale, the written progress cue remains part of the non-compact presentation, and the root announcement remains `Chants. Getting things ready.`

The breakpoint therefore continues to choose the compact or non-compact presentation while each branch owns its own overflow safety.

## CI maintenance

The failed-golden and Android debug artifact steps move from `actions/upload-artifact@v4` to `actions/upload-artifact@v7`. Artifact names, paths, missing-file behavior, seven-day Android retention, workflow triggers, job permissions, and job topology remain unchanged. No new action, script, service, permission, secret, cache, or artifact is introduced.

## Verification

- Known-bad evidence reproduces both non-compact overflow points before the runtime correction.
- Thirty-six focused launch-reveal, app-gate, and policy-gate tests pass after correction.
- The complete Flutter suite passes 528 cases, and CI-equivalent `flutter analyze lib test` reports no issues.
- Writing style, governance regressions, native-project, launch-services, 37 device, guide, policy, and landing cases, workflow-version count, staged project memory, and whitespace checks pass.
- Exact-head clean-runner CI and bounded independent review remain required after separately authorized packaging.

## Remaining gates

One commit, push, PR 32, exact-head clean-runner CI, independent review, merge, physical-device walkthrough, Hosting publication, domain connection, store configuration, and production mutation remain separate decisions.
