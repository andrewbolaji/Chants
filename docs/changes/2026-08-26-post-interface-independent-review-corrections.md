# Change implementation rationale: Post-interface independent review corrections

## Change identity and boundary

- **Change:** Close the material findings from the independent review of merged PR 15.
- **Base:** `9189c71d99c52539cb3d1b02f51701fa4334c144`, exact merged PR 15 head.
- **Branch:** `codex/post-interface-review-corrections`.
- **Risk lane:** Lane 1.
- **Approval:** Andrew approved `post-interface independent review correction spec` on 2026-08-26.
- **Included:** Home trust presentation, useful empty recovery, deterministic Home time, focused widget and golden evidence, project-memory and writing checks, governance regression tests, CI governance coverage, and current framework records.
- **Excluded:** Queries, repositories, models, persistence, Firebase rules, Functions, seed, manifests, lockfiles, native projects, deployment, signing, release, device actions, and production state.

## Outcome

Home no longer equates Chant Lab membership with momentum. The community preview evaluates the canonical `isRisingChant` predicate against the chant currently rendered by the live stream and a deterministic evaluation time. A stale score-zero idea remains labelled `ORIGINAL IDEA` without `RISING`. If the live score changes from qualifying to unqualified, the badge disappears without changing the chant's origin.

The Terrace Proven empty state no longer offers a shuffle that cannot help. Discovery already fetches the complete visible set, so zero canonical rows remains zero after reordering. The empty action now opens the existing Premier League club route with its existing arguments.

Home trust words have direct widget assertions independent of pixel comparison. The measured 3 percent Linux renderer allowance applies only to Home; competition and player return to the earlier 2.2 percent ceiling.

Project governance now says what it can prove. CI checks required memory structure and tracked prose, then runs durable script regressions. Change-to-execution linkage remains the explicit manual `--staged` pre-handoff check because CI cannot infer a confirmed Lane 0 exception from a diff alone. The staged script consumes NUL-delimited paths. The writing script scans tracked index prose and treats execution errors as failures.

## Finding disposition

| Finding | Correction | Evidence |
|---|---|---|
| H1 false Rising | Derive with `isRisingChant(live, now: evaluationTime)` | Stale score-zero and live score-transition widget tests |
| M1 broad golden tolerance | Reinstall 2.2 percent comparator after Home and add semantic trust assertions | Core Home, competition, and player golden test plus exact text checks |
| M2 impossible empty action | Replace shuffle with Premier League club browse | Exact message, action, route name, and route argument regression |
| M3 overstated memory enforcement | State structure CI and manual staged linkage separately | AGENTS, project profile, script contract, and governance harness |
| L1 path splitting | Consume `git diff --cached -z` through a Bash NUL loop | Documentation-only path containing spaces passes as one path |
| L2 fail-open prose scan | Distinguish Git grep status 1 from higher errors | Corrupt index fixture returns nonzero |
| L3 broad working-tree scan | Search tracked Markdown, MDX, and text from the Git index | Untracked scratch fixture is excluded; tracked bad prose fails |

## Implementation choices

### Evaluate the live entity

Passing a derived boolean from the discovery list would fix the reproduced stale fixture but could become wrong as soon as the per-card live stream updates the chant. `_LiveChantCard` therefore receives only the evaluation time and computes the predicate from `live`, the same entity given to `ChantCard`.

`HomeScreen` and `DiscoverySection` accept an optional evaluation time. Production defaults to the current clock. Tests inject `2026-08-26`, which keeps the time-sensitive fixture and golden stable in future runs.

### Keep useful shuffle behavior

The section-header shuffle remains when canonical content exists because reordering can select a different preview. Only the empty action changes. That distinction preserves a useful lightweight discovery control without promising recovery from an impossible state.

### Separate semantic and visual gates

Cross-platform renderer tolerance remains necessary for the text-heavy Home image. It is not allowed to become the only evidence for words carrying trust meaning. The test now asserts those words before comparing the image and lowers the comparator before rendering the two surfaces without measured 3 percent drift.

### Make governance honest before making it broader

Automatic staged enforcement would require CI to infer the approved risk lane or introduce a separate trusted signal. This block does not invent that authority. It documents the manual handoff step explicitly and makes the command reliable. CI proves the structure mode and every script behavior through isolated temporary repositories.

## State and invariant coverage

| State or invariant | Result |
|---|---|
| Stale community idea, score 0, created in 2024 | Original Idea shown; Rising absent |
| Recent community idea, score 7 | Original Idea and Rising shown |
| Authoritative live score changes to 0 | Rising disappears from the rendered live card |
| No canonical chant exists | Honest empty copy and real Premier League browse action |
| Both trust lanes exist | Existing one-card hierarchy and routes remain |
| Home image | 3 percent renderer tolerance plus semantic assertions |
| Competition and player images | 2.2 percent renderer tolerance |
| Documentation path contains spaces | Staged memory classification remains documentation-only |
| Implementation without staged execution record | Manual staged gate fails |
| Forbidden punctuation in tracked prose | Writing check fails |
| Untracked scratch prose | Index-scoped writing check ignores it |
| Git index read failure | Writing check fails closed |

## Security, privacy, data, and cost impact

- Authorization and live-action gating are unchanged. The same current-live wrapper still removes permission-denied, missing, hidden, or removed chants and disables vote on non-authoritative values.
- No query, write, schema, server, seed, or storage behavior changes.
- No production data or external service was accessed.
- Home performs the same full discovery fetch and per-card listener work as before. The corrected predicate is constant-time and local.
- CI adds a short Bash harness that creates and removes temporary local Git repositories. It installs no package and makes no network request.

## Verification performed

Red evidence:

- The score-zero 2024 community fixture rendered one `RISING` label before correction.
- The canonical-empty fixture did not expose the approved useful copy or club action before correction.
- The governance harness rejected a documentation-only path containing spaces because the old loop split it.

Green evidence:

- All 8 core-journey tests pass, including static trust, live score transition, useful empty route, existing routes, search, error, enlarged text, and all three goldens.
- The complete Flutter suite passes 356 tests.
- `flutter analyze --no-pub lib test` reports no issue with the temporary non-secret Firebase fixture, which was removed afterward.
- `scripts/test-project-governance.sh` passes all memory, index-scope, forbidden-prose, and error-propagation cases.
- All three shell scripts pass Bash syntax checking.
- Touched Dart files are formatter-clean.
- `git diff --check` passes.
- `pubspec.lock` matches the base and is not part of the change.

Functions, rules, and seed were not rerun locally because their source, tests, manifests, and contracts do not change. Exact merged PR 15 evidence remains GitHub Actions run `33012771517` at `9189c71`. Correction clean-runner CI remains pending.

## Rollout, observation, and recovery

- No deployment or migration is authorized.
- Package one correction commit, run clean-runner CI, and obtain independent review closure before restoring the engineering freeze.
- The combined native walkthrough follows that closure.
- Reverting the Home correction would restore a reproduced false trust label. Recovery from a bad correction should be a forward fix or a complete removal of Rising from Home, not restoration of the hardcode.

## Known gaps

- Clean-runner CI has not run for this correction.
- The correction has not received independent closure review.
- Native fonts, touch behavior, route transitions, and device lifecycle remain unverified until the combined walkthrough.
- Discover still reads the complete visible collection and shuffles locally. That remains a measured-volume trigger, not a defect in this bounded correction.

## Documentation impact conclusion

- `ENGINEERING_OVERVIEW.md` and `docs/IMPLEMENTATION_RATIONALE.md` are refreshed because the exact merged head, review disposition, verification count, and governance truth changed.
- `docs/INTERFACE.md` records truthful live Rising and useful empty recovery.
- `docs/LEARNINGS.md` promotes the reusable rule that a lane does not confer every derived label.
- No new architectural decision is required. The correction uses the existing Rising predicate, route, live-authority wrapper, and governance model.
