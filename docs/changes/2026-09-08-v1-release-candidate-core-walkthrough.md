# V1 release-candidate core walkthrough

## Outcome

The exact merged candidate at `0cbab1dbe57c2d3fbfe673dfb7c2cb1f4d42aa31` completed its first functional owner walkthrough on a physical iPhone. Production opened only in `core` mode with destructive workers false, stayed under attended observation for more than 30 minutes, and returned to generation 11 `maintenance` with destructive workers false.

## Authority and boundary

Andrew approved `V1 release candidate core walkthrough retry spec`. The approval covered exact-candidate preparation, read-only live preflight, one generation-10 core opening, the named reversible owner actions, monitoring, and mandatory generation-11 closure. It excluded media, destructive workers, cleanup replay, schedules, seed writes, Hosting, DNS, App Check enforcement, providers, distribution signing, stores, submission, and release.

## Evidence

- Exact-main run `34170708368` passed all eight jobs at the candidate commit.
- Production preflight matched the reviewed 46-Function source, rules, 16 indexes, catalogue, IAM, recovery, budget, and alert boundaries. No app-media bucket or severity error existed.
- The installed app identified version `1.0.0 (1)`, bundle `com.chants.chants`, and SHA-256 `b5945b95a419fc2b1ba761ef75919c2be4740ec69f99404c72ccfd1b7f535145`.
- Generation 10 `core`, workers false, was applied once and separately read back at 2026-09-08T01:35:00Z. One earlier local digest validation stopped before Admin initialization and made no external change.
- Andrew completed policy acceptance, Stage, the 20-club directory, Arsenal and Leeds United Songbooks, the Odegaard player route, one restored vote, one saved-then-removed local chant, Create, and You. No content, media, report, follow, account, deletion, or sign-out action occurred.
- The observed vote switch from up to down correctly produced a two-point net change. The final neutral state and production vote-row count were restored, but delayed cross-route feedback made the transition unclear. This is an interface correction candidate, not counter drift.
- `REMOVE FROM DEVICE` accurately described removal of the local offline copy. Songbook returned to empty.
- The window ran for 30 minutes and 53 seconds. No severity error appeared. Counts matched the baseline except for the expected policy audit increase from 198 to 199.
- A fresh mode-600 close plan moved the exact observed generation 10 state to generation 11 maintenance with workers false. Independent readback recorded closure at 2026-09-08T02:05:53Z. Final privacy-safe inventory at 2026-09-08T02:06:25Z matched the expected state.

## Adversarial result

The walkthrough deliberately restored every reversible action and did not improvise around slow feedback. A confused or impatient user can reasonably read a direct up-to-down switch as an attempted cancellation when the selected state and other visible routes update at different times. Preserve one vote per user and the net-score rule, but make the selected intent explicit and synchronize or truthfully mark pending state across route copies.

## Verification

`git diff --check`, the nine launch-guide regressions, and the writing-style check pass with the sanitized evidence and completed command-center task. Private plans, credentials, device identity, and raw production data remain ignored and outside project memory.

## Remaining release gates

Public trust routes and support delivery, media and cleanup readiness, App Check canary, provider activation, Android device proof, distribution archives, exact final screenshots, reviewer access, store forms, final comprehensive independent review, submission, and release remain separate. Any later UI or seed change requires a new exact candidate and proportionate device evidence.
