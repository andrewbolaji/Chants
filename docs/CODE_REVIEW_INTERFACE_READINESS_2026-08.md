# Independent review: V1 interface readiness and Home hierarchy

**Review range:** `2df9fa04a839f88a19fe43c2bcc8ed9a583627c3...9189c71d99c52539cb3d1b02f51701fa4334c144`

**Commits:** `cd54107`, `a2e463c`, `587c14a`, merged as `9189c71` (PR 15)

**Disposition:** One high finding blocks. It is a two-line runtime fix plus a test. Everything else is medium or lower.

## Overall take

This block does what it says. The runtime diff is presentation only. No Firestore query, rule, Function, model, repository, provider, or persistence contract changed, and the Home grouping is a pure `where`/`take` over the list the existing discovery provider already returned. The live-authority path is preserved: Home cards still go through `_LiveChantCard`, still carry `actionsEnabled: hasAuthoritativeValue`, and still key by chant ID.

The block's own headline correction is real and correctly scoped. `CompetitionScreen` sorted a repository-owned snapshot in place and crashed on an immutable list. I checked every other `.sort` call in `lib/`, and this was the only instance of that class. `block_repository.dart:17`, `moderation_screen.dart:230` and `:622`, `submit_chant_screen.dart:387`, `chant_browse.dart`, and `chant_ranking.dart` all sort a list they just built. The fix is correct and complete.

The documentation is unusually accurate. I verified the claims that are checkable and they hold, which is worth stating because it is rare:

- `flutter test` at `9189c71` in a clean worktree: 353 passing, exactly the count the rationale claims.
- CI is green at the exact merge head, run `33012771517`. The rationale's account of the failure at `cd54107` (run `33011415224`) and the passing replacement at `a2e463c` (run `33011936510`) is accurate.
- All three mockup SHA-256 values in `docs/mockups/README.md` verify byte exact.
- `ENGINEERING_OVERVIEW.md` claims merged `main` carries the freeze closure. `git diff 0b64dcf 2df9fa0 -- lib functions firestore.rules seed` is empty, so the closure content is in `main` under different SHAs from the squash merge. The claim is true even though the branch commits are not ancestors.

What the block gets wrong is narrow and specific: it introduces an unearned trust badge on Home, and it loosened the visual gate that was supposed to catch exactly that kind of change.

## Fix these first

1. Derive Home's Rising badge instead of hardcoding it (H1).
2. Assert Home's trust strings in a widget test so the golden's pixel tolerance cannot absorb their loss, and scope the 3 percent tolerance to the Home image only (M1).
3. Replace the Terrace Proven empty action, which cannot change its own outcome (M2).
4. Wire or downgrade the project-memory staged gate, which no caller invokes (M3).

## Findings by severity

### High

#### H1. DEFECT: Home labels every Chant Lab chant RISING, regardless of score or age

**Evidence:**

- `lib/presentation/browse/discovery_section.dart:146`
- `lib/data/services/chant_browse.dart:71` (`isRisingChant`)
- `lib/presentation/browse/chant_lab_view.dart:137`
- `test/presentation/shared/chant_card_test.dart:81`
- `test/presentation/browse/team_screen_test.dart:135`

Everywhere else in the app the badge is derived. `isRisingChant` requires `status == 'community'`, `score >= 3`, a non-future `createdAt`, and creation inside the last seven days. `ChantLabView` computes it against an injected clock. The new Home lane passes `rising: true` for whatever community chant the shuffle happened to surface.

**Failure scenario:** A community chant with score 0, created in 2024, is the only community chant in the visible collection. Home shows it under Chant Lab with a RISING badge. No score, age, or trend condition was evaluated.

I reproduced this. A probe widget test with exactly that chant asserts `isRisingChant(chant, now: 2026-08-26)` is false and then finds one `RISING` text on the rendered Home. Both assertions pass.

**Why the existing suite does not catch it:** the golden fixture `super-saka-weekly` has `score: 7` and `createdAt: 2026-08-25`, so it is genuinely rising. The hardcoded value and the derived value agree on the only community chant any Home test renders.

This contradicts three of the project's own stated invariants: the `chant_card_test` case named "shows Rising only when explicitly requested", the `team_screen_test` case named "separates Songbook and Chant Lab with honest Rising copy", and the new `docs/INTERFACE.md` Home row requiring that the red accent always pair with a truthful Rising word. `docs/PROJECT_PROFILE.md` states the invariant directly: Songbook and Chant Lab never imply that votes prove a chant has been sung.

**Required fix:** pass `isRisingChant(chant, now: ...)` on the Home lane, using an injectable clock the way `ChantLabView` does. Add a Home test with a stale, zero-score community chant that asserts no RISING badge. That test should fail against the current implementation.

### Medium

#### M1. The Home golden's 3 percent tolerance is wide enough to hide a missing trust label

**Evidence:**

- `test/presentation/browse/core_journey_golden_test.dart:377`
- `test/helpers/tolerant_golden_file_comparator.dart`
- `a2e463c` raised `precisionTolerance` from `0.022` to `0.03`

The single `installTolerantGoldenComparator` call sets a process-wide comparator for the whole test, so the 3 percent ceiling also covers `core_competition.png` and `core_player.png`, neither of which had any measured cross-renderer drift. The calibration was needed for one text-heavy image and was applied to three.

I measured the consequence. I edited `chant_card.dart` so the RISING badge never renders, then ran the baseline test. `core_home.png` still passed. Two other suites caught the mutation (`chant_card_test` and `team_screen_test`), but Home itself has no assertion for its own trust badges, so the golden was the only Home-level evidence and it absorbed the change.

The tolerance is a reasonable answer to renderer drift. The problem is that it is currently the sole Home-level guard for content that the interface contract calls trust-critical.

**Required fix:** two parts. Scope the loose tolerance to the Home image and keep competition and player tight. Then add explicit Home assertions for the trust strings (the Terrace Proven badge, ORIGINAL IDEA, and the corrected RISING condition) so pixel tolerance never doubles as semantic tolerance.

#### M2. The Terrace Proven empty state offers an action that cannot change its outcome

**Evidence:**

- `lib/presentation/browse/discovery_section.dart:106-111`
- `lib/data/repositories/chant_repository.dart:92-97`

`discoveryChants()` fetches the entire visible chant collection with no `orderBy` and no `limit`, then shuffles client side. Home takes the first canonical chant from that set.

The empty branch is therefore reachable only when the visible collection contains zero canonical chants. `SHUFFLE` invalidates the provider, which refetches the same complete set and reorders it. The action is guaranteed not to help in the only state where it is visible, and "in this mix" tells the fan a different mix exists.

This is the same defect class this block just fixed. Four screens promised a pull-down gesture they did not implement, and the corrected `docs/INTERFACE.md` now requires that recovery copy names only an available action.

The Chant Lab empty lane does not have this problem. `BROWSE CLUBS` routes somewhere real.

**Required fix:** when the canonical lane is empty, point the fan at club browse the way the Chant Lab lane does, or state plainly that no Terrace Proven chant is published yet. Do not offer a reshuffle of a set that is already complete.

#### M3. The project-governance CI job does not enforce the project-memory contract

**Evidence:**

- `.github/workflows/ci.yml:9-16`
- `scripts/check-project-memory.sh`

The script has two modes. The default `structure` mode checks that `docs/EXECUTION.md`, `docs/LEARNINGS.md`, and `docs/INTERFACE.md` exist and that `AGENTS.md` mentions them. The `--staged` mode is the real gate: staged implementation changes require a staged `docs/EXECUTION.md` update unless `PROJECT_MEMORY_LANE=0`.

CI runs the default mode. No git hook is committed, no `core.hooksPath` is set, and no other caller of `--staged` exists in the tree. So the enforcing mode is unreachable in practice, while `AGENTS.md`'s definition of done and `docs/PROJECT_PROFILE.md` present the script as a gate.

**Required fix:** either run `--staged` from a committed hook or a CI step evaluated against the pull request diff, or state in `AGENTS.md` and `docs/PROJECT_PROFILE.md` that `--staged` is a manual pre-handoff command and CI checks structure only.

### Low

#### L1. `--staged` word-splits staged paths

`scripts/check-project-memory.sh` iterates `$memory_staged_paths` unquoted. A path containing whitespace splits into separate tokens that are then classified individually, so a documentation-only change can be misclassified as an implementation change. Use `git diff --cached -z --name-only --diff-filter=ACMR` with a NUL-delimited read loop.

#### L2. The writing-style scan can fail open

`scripts/check-writing-style.sh` ends its `find` pipeline with `2>/dev/null || true`. That discards traversal and grep errors as well as the intended no-match exit status, so a failed scan reports "Writing-style check passes." Capture grep's status explicitly and treat 0 as hits, 1 as clean, and 2 or higher as an error.

#### L3. The writing-style scan reads the working tree, not the index

The prune list covers `.git`, `node_modules`, `vendor`, `dist`, `build`, `.next`, and `.venv`, but not `ios/`, `macos/`, or `.dart_tool`, and the scan includes untracked files. This is harmless on a clean CI checkout and will produce local false failures for scratch Markdown. Worth a note in `AGENTS.md` rather than a code change.

## Things I checked that are fine

- **Immutable snapshot handling.** The competition fix is correct, and no other presentation or repository site mutates a collection it does not own.
- **Live authority.** Home cards still resolve through `chantStream`, still disable actions on cache-only snapshots, and still key by chant ID. Grouping does not touch that path.
- **Touch targets.** The theme sets 48 by 48 minimums for `IconButton` and `TextButton`, so the new shuffle control, the circular account control, and both empty-lane actions meet the claimed 44 pixel floor without per-widget geometry.
- **Color as meaning.** The new `AppColors.chantLab` red measures 5.01 to 1 against `AppColors.surface`, above the 4.5 to 1 threshold, and every accent it carries is paired with a written label.
- **Route arguments.** The Chant Lab empty action passes the same competition route and argument shape as the existing Premier League card.
- **Search path.** Grouping is skipped while searching, so search still returns one combined list over the same filter inputs.

## Watch items, not defects

- Home now renders two chant cards but still downloads the entire visible chant collection to do it, and the new shuffle control makes that a user-triggered full-collection read. The repository comment already marks pagination as the v2 trigger. At current volume this is fine. It gets worse per card, not better, and the ratio is now much worse than when Discover showed up to twenty.
- `ENGINEERING_OVERVIEW.md` records a scoped `flutter analyze` for this block rather than the full `flutter analyze lib test` that `AGENTS.md` requires in its definition of done. CI's analysis job covers the gap, so this is a documentation consistency point rather than a coverage hole.
