# Change spec: Stable chant document identity

**Status:** Proposed, awaiting Andrew's technical approval
**Updated:** 2026-08-21
**Risk lane:** Lane 2, persistent identity and live-data compatibility
**Stack base:** Draft PR 4, `codex/v1-interaction-safety-replies`

This is the one active implementation specification on the stacked branch. It replaces the prior branch's reply specification only in this branch. No stable-identity implementation or live data action is authorized until the status is changed to Approved.

## Outcome

- **Problem:** Operator-seeded chant document IDs are recomputed from mutable titles. Renaming a seed title therefore targets a new Firestore document and leaves the old chant plus its votes, comments, reports, saved references, evidence, and future public link behind.
- **Desired behavior:** Every seeded chant has an explicit, immutable source ID. Editing its title updates the same Firestore document. The current Arsenal IDs are frozen in place so the normal case requires no live document rename or dependent-reference migration.
- **Non-goals:** Stable team or player IDs, changing community auto-generated IDs, editing lyrics or squads, migrating a mismatched live database automatically, changing app models, adding public links, or running the seed against production.
- **Review boundary:** `seed/`, `seed_data/clubs/arsenal.json`, focused documentation, and tests. No Flutter, Functions, Firestore rules, index, dependency, or Firebase deployment change.

## Acceptance criteria and invariants

1. Every seed chant carries a non-empty explicit `id` that is slug-safe, bounded, globally collision-resistant through the club prefix, and unique within its club file.
2. The seed writes `chants/{chant.id}` and never computes a chant document ID from `title`.
3. Changing only a chant title leaves the resolved document ID unchanged in a focused regression test.
4. The Arsenal IDs added to source data exactly equal the IDs produced by the current legacy algorithm, so adopting the new source contract does not rename the expected live documents.
5. Duplicate normalized titles remain a validation error even when explicit IDs differ, so stable identity does not weaken duplicate-content protection.
6. A preflight runs before chant writes and aborts on an unsafe collision, including an explicit ID owned by community content, an ID belonging to another team, or a same-title system chant at another ID.
7. A same-team, system-owned document at the explicit ID is safe to update even when its stored title differs. That is the rename case this change exists to support.
8. Preflight failure performs no chant write and prints a corrective message without exposing credentials or document payloads.
9. The change does not edit any Arsenal title, lyric, tune, context, subject, player, variation, squad member, or classification value.

Invariants:

- Seed input remains authoritative and externally verified. The build never invents or rewrites cultural content.
- Existing engagement stays attached to the same chant document in the expected rollout path.
- Community content is never overwritten by a predictable operator seed ID.
- Orphans are reported, never automatically deleted.
- No production read or write is claimed as verified unless run against the named Firebase project with explicit operator authorization.

## Design

- **Approach:** Add an explicit `id` to `ChantData` and every Arsenal seed chant. Introduce one small pure identity/preflight module used by both tests and `seed.ts`. Use the explicit ID for the document reference and orphan set. Query existing chants for the team before any club write, pass only minimal identity metadata into the pure preflight, and abort on conflicts. Each chant then uses a Firestore transaction that rechecks target ownership and team membership before creating or applying the existing content-field allowlist.
- **Failure prevented by the new helper:** A later refactor must not silently reintroduce title-derived document IDs, and the seed must not overwrite a community document that happens to use a predictable ID.
- **Existing alternative considered:** Keep calling `compositeSlug(teamSlug, chant.title)` and manually delete or merge orphans after a rename. Rejected because public links and user engagement make cleanup destructive and increasingly expensive.
- **Expected footprint:** One small seed identity module and focused test, changes to the chant interface and validator, a narrow `seed.ts` call-site change, explicit IDs added to the one existing club file, and documentation updates. No new package or service.
- **Interfaces/contracts:** Club seed JSON now requires `chants[].id`. Titles remain mutable display content. The Dart `Chant.id` contract is unchanged because it already reads the Firestore document ID.
- **Data/migrations:** Freeze each Arsenal chant's current legacy ID as the new explicit ID. No default-path document move or dependent-reference rewrite. If the live preflight finds a mismatch, abort and write a separate approved migration spec based on the observed IDs and dependent counts.

## Failure and abuse analysis

| Condition | Expected behavior | Evidence |
|---|---|---|
| Repeated seed run | Same explicit document IDs are updated through the existing content-field allowlist | Unit test plus existing upsert contract |
| Title rename | Same ID resolves before and after the title change | Focused identity regression test |
| Duplicate explicit ID | Validation fails before any club write | Validator test |
| Duplicate normalized title with different IDs | Validation still fails | Validator test |
| Community document occupies an explicit seed ID | Preflight aborts, no chant write | Known-bad preflight fixture |
| Explicit ID belongs to another team | Preflight aborts, no chant write | Known-bad preflight fixture |
| Same-title system chant exists at a different ID | Preflight aborts for manual reconciliation | Known-bad preflight fixture |
| Existing same-ID system chant has an older title | Preflight accepts update | Rename fixture |
| Network or credential failure during preflight | Seed exits nonzero before chant writes and reports a bounded error | Executable scenario or source-level error-path test |
| Concurrent user claims an ID after preflight | Per-chant transaction rechecks ownership and team membership atomically with create/update and aborts | Focused transaction-helper evidence |

## Performance and cost

- **Workload:** About 5 to 12 seeded chants per club at launch and roughly 100 to 250 total. One team-scoped preflight query per club is acceptable at this workload.
- **Budget:** No material user-facing latency or ongoing cost. The seed is an operator-only batch tool.
- **Measurement:** Tests assert query/write planning behavior; no production performance claim is needed.

## Rollout and recovery

- **Deploy/migration order:** Merge code, inspect the source-only ID additions, run seed tests and typecheck, then run an explicitly authorized read-only preflight against `chants-f95b4`. Only after that passes may an operator run a normal club seed.
- **Staging/canary/flag:** First apply to Arsenal, the only club currently in `seed_data/clubs/`, and inspect the seed output. Add remaining club IDs as their files enter the repository.
- **Healthy signals and window:** Preflight reports every existing expected Arsenal chant as same-ID and system-owned, normal seed reports updates rather than creates, and the orphan report does not gain a rename-created chant.
- **Rollback or forward fix:** Before any live seed run, revert the code and JSON additions. After a successful same-ID run, keep explicit IDs and forward-fix defects. If any mismatch is found, stop without writes and create a migration-specific recovery plan. Never delete or rewrite dependent records ad hoc.
- **Owner:** Andrew authorizes the live preflight and any seed run. Codex implements and verifies repository changes only.

## Verification plan

| Claim | Check | Expected evidence |
|---|---|---|
| Seed package remains valid | `cd seed && npm test` | Full seed suite passes with new identity and validation cases |
| Types compile | `cd seed && npx tsc --noEmit` | Exit 0 |
| ID no longer follows title | Focused identity test changes the title while preserving `id` | Test fails if resolution uses `title` |
| Unsafe collisions stop | Known-good and known-bad preflight fixtures | Every named collision class has a focused assertion |
| Arsenal content is untouched except IDs | Compare base and working JSON after deleting only `chants[].id` from the new side | Structural equality |
| Expected rollout is no-rename | Compare every explicit Arsenal ID with the legacy algorithm over the same base title | Exact equality for the full file |
| Changed prose follows house style | `git diff --check` plus em-dash search on changed prose | Zero findings |
| No unrelated paths entered the stack | Inspect `git diff --name-only codex/v1-interaction-safety-replies...HEAD` | Only approved seed, source-data, test, and documentation paths |

## Approval

Andrew approved stacking additional review branches on 2026-08-21. Because this block changes persistent identity and protects a hard-to-reverse live-data boundary, the repository framework still requires approval of this technical contract after it is visible. Implementation begins only after Andrew explicitly approves this spec.

## Open decisions

None in the repository design. Live preflight results may reveal a separate migration decision; the safe response is to stop, preserve evidence, and re-plan rather than expanding this block.
