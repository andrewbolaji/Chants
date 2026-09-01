# PR 30 independent-review corrections

## Approval and scope

Andrew approved `PR 30 independent review correction spec` on 1 September 2026. This Lane 2 follow-up closes the one Medium and two Low findings from the read-only review of PR 30. It changes documentation and regression evidence around existing behavior. It does not change runtime behavior, policy version, the 17+ rule, deployment, publication, launch markets, or production state.

## Corrections

### Dependent performance consequence

Account deletion already redacts a user-authored chant into a hidden and removed tombstone. The existing chant-source reconciler consequently removes current source eligibility and the chant-title projection from every performance attached to that chant. This includes a performance owned by another creator. The other creator's account and media ownership are not deleted by that source-visibility consequence.

The launch policy pack, decision 027, engineering overview, and implementation rationale now state that behavior directly. A Functions regression executes the actual authored-chant deletion phase and actual source reconciler against a performance owned by a different creator. It verifies that the performance becomes unavailable, the projected title is removed, the owner's live performance total converges to zero, and the other creator identity remains intact.

### Dedicated emulator count

`AGENTS.md` now reports 24 dedicated emulator-only cases, matching the current suite. The locally runnable Functions count is 230 after the new cross-owner regression.

### No-24/7 copy guard

The launch-policy source contract now removes only the two approved negative statements before rejecting any residual `24/7` text. A direct guard test proves those negative statements pass and positive promise variants fail.

## Verification

- `npm test` in `functions/`: 230 passing and 24 pending emulator-only cases.
- Focused cross-owner regression: one passing after implementation restoration.
- Known-bad evidence: temporarily preserving source chant visibility made the direct regression fail with the dependent performance still eligible and the creator count still one. The approved implementation was restored immediately and the focused test passed.
- `node --test scripts/test-launch-policy.mjs`: eight passing.
- Staged project-memory, writing-style, governance, whitespace, and changed-path checks pass.
- No runtime source, rules, seed, native, dependency, or Firebase configuration changed in this correction.
- Replacement exact-head clean-runner CI is required before closure.

## Remaining gates

PR 30 remains a draft until owner review. Merge, policy publication, Hosting deployment, backend deployment, store changes, legal review, device acceptance, and production observation remain separate decisions.
