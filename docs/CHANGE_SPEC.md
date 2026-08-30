# Change spec: V1 Premier League live seed rollout

**Status:** Implemented and locally verified; packaging and production holds remain
**Updated:** 2026-08-30
**Risk lane:** Lane 2 production data writes with a Lane 3 hold point before the first write
**Base:** `1a509c80d88bfd92370f3974cd9f2f50c307f519`, merged PR 22
**Approval:** Andrew approved `V1 Premier League live seed rollout spec` on 2026-08-30, approved the exact Arsenal amendment with owner overrides for Fábio Vieira, Reiss Nelson, and Marli Salmon, then approved `exact Arsenal live reconciliation spec`. These approvals authorize source implementation and verification only. Production writes retain separate hold points.

## Outcome

- **Problem:** The reviewed 20-club catalogue is merged, but only Arsenal is known to exist in production. Current production identity, exact runtime projection, and post-write readback are not yet proved. The first complete roster-currentness check also found real Arsenal transfer changes plus three cases where the official feed lagged or did not represent the owner's reviewed squad decision. The repository had no readback-only CLI mode, so a successful write command was not sufficient evidence that production matched the source.
- **Desired behavior:** Refresh only Arsenal's reviewed squad membership while preserving canonical display names and every retained player ID, keep explicit owner membership overrides visible in the currentness gate, prove all planned chant IDs are safe against project `chants-f95b4`, compare the exact runtime projection through a readback-only path that cannot call a writer, write one low-footprint club, verify source-owned runtime fields and orphans, then widen only after the canary is clean.
- **Non-goals:** No lyric, tune, context, chant source, non-Arsenal club roster, app, Functions, rules, index, authentication, deployment, provider, signing, store, release, automatic orphan deletion, historic-player model, or public evidence change. No credential enters source, logs, prompts, or project memory.
- **Review boundary:** Seed CLI planning and verification, focused seed tests, the active execution record, this contract, one scoped completion record, and the named Firebase project. Catalogue wording and all unrelated source remain unchanged.

## Current evidence and source of truth

1. PR 22 merged the reviewed catalogue at `7c95cb60894180724dcfe071a4f4f55a80ca4beb`; exact-head run `33319138653` passed all eight jobs.
2. The official Fantasy Premier League bootstrap feed refreshed on 2026-08-30 reports the approved 20 clubs and 623 raw player rows. After 17 reviewed display aliases and three explicit owner membership overrides, the reviewed source contains 622 squad rows across those clubs.
3. Arsenal source adds Bruno Guimarães, Christos Tzolis, Ezri Konsa, and Illan Meslier. It removes Christian Norgaard, Leandro Trossard, and Tommy Setford. Fábio Vieira and Reiss Nelson are not added because the owner confirmed they have left or are leaving. Marli Salmon remains as an owner-confirmed young Arsenal player even though the official feed omits him.
4. None of the three removed Arsenal players owns a player-linked chant in the reviewed source. Trossard therefore loses no existing content; a future hero or historic chant can use the established club-linked historic-subject path. Retained players keep their existing canonical display names and document IDs.
5. `seed_data/clubs/` is the content source of truth. Live Firestore is the source of truth for collision, ownership, and orphan state. The readback comparison must project source through `buildSeededChantData` rather than maintain a second runtime schema.
6. The named-project Arsenal preflight reports all 12 chant targets safe. The all-club preflight reports all 192 targets safe. Both completed without writes.
7. The production baseline contains the foundation plus Arsenal only. Across the reviewed target it reports 19 missing teams, 598 missing players, 180 missing chants, four missing Arsenal players, 12 Arsenal chants differing only on `origin`, and three departed Arsenal player documents. The three departed documents have zero chant references. No other mismatch or orphan was found.

## Acceptance criteria and invariants

1. Arsenal source applies exactly the four additions and three removals named above, retains Marli Salmon, and excludes Fábio Vieira and Reiss Nelson. No other club file or chant changes.
2. A pure roster-currentness check accepts the refreshed feed only when all 20 reviewed club memberships match after explicit display aliases and named owner membership overrides. An unreviewed added, removed, moved, or renamed player fails with a club-scoped difference.
3. `--preflight-only` remains read-only and first passes for Arsenal, then for all 20 club files against project `chants-f95b4`.
4. A new `--readback-only` mode performs no sport, competition, team, player, or chant write. It validates exact allowlisted runtime content, expected document IDs, ownership, team linkage, and reported orphans.
5. Seed and readback modes remain mutually exclusive. Unknown or conflicting flags fail before Firebase work.
6. The service credential is an ignored local file, targets only `chants-f95b4`, and is never printed or retained in project memory.
7. Leeds United is the canary because its 27 players plus six chants tie for the smallest new-club document footprint and it has no dependency on a roster alias.
8. The canary write starts only after clean all-club preflight evidence and an explicit production-write hold-point release.
9. Canary readback must report exact expected runtime fields, no identity mismatch, and no unexpected orphan before widening.
10. Remaining clubs are written only from the reviewed source. Each club receives an immediate readback before the next bounded group continues.
11. Orphans are reported and stop widening. They are never deleted automatically.
12. Any approved departed-player removal must re-read the exact document identity and require zero current chant references in the same bounded operation. A changed document or new reference fails without deletion.

Invariants:

- Seeded chant IDs and existing Arsenal IDs remain unchanged.
- A non-system chant can never be overwritten by the seed.
- Existing counters, moderation fields, timestamps not owned by the seed projection, and engagement documents remain untouched.
- Offline catalogue provenance never enters unsupported Firestore fields.
- A failed, timed-out, partial, or ambiguous operation stops the rollout. It is never reported as successful based only on process exit.
- No cleanup or rollback deletion is implied by this plan.

## Design

- **Approach:** Extend the existing CLI plan with a readback-only branch and a pure current-roster comparison. Reuse existing validation, stable-ID resolution, and runtime projection. Keep network acquisition and credentials outside the repository.
- **Interfaces/contracts:** `seed.ts --preflight-only [club.json...]` stays unchanged. `seed.ts --readback-only [club.json...]` reads and compares only. Normal positional club arguments retain their existing write behavior. `seed.ts --retire-approved-arsenal-players` is an exact no-positional-argument writer for the three reviewed departures and cannot be combined with another mode.
- **Data/migrations:** No schema migration. The source-only Arsenal membership refresh changes three removed and four added player documents in the expected set. Normal seed behavior creates or content-updates through the current allowlist but does not delete departed players. A separate exact allowlisted retirement action fails unless each target still has the expected Arsenal identity and zero chant references. Display aliases preserve reviewed canonical player IDs, and explicit owner membership overrides prevent a lagging feed from undoing settled membership decisions.
- **Alternatives rejected:** A one-off shell readback would duplicate runtime schema and be difficult to review. Updating public player names to raw FPL field order would create unstable IDs and worse names without a real transfer. Bulk-writing all 19 clubs before a canary would unnecessarily increase blast radius.

## Failure and abuse analysis

| Condition | Expected behavior | Evidence |
|---|---|---|
| Duplicate or retry | Seed remains idempotent for reviewed identities; readback returns the same result | Existing transaction tests plus canary rerun and readback |
| Timeout or ambiguous exit | Stop. Run readback-only before deciding whether any retry is needed | Fault-path unit test and operator evidence |
| Concurrent target creation | Transaction-time chant ownership and team checks reject unsafe overwrite | Existing chant identity tests and live readback |
| Wrong Firebase project | Abort before queries or writes without printing credential material | Project-ID gate and focused test |
| Roster member added, removed, or moved | Fail currentness check and update the reviewed source or a named owner override through a new approved content change | Known-bad roster fixture |
| Exact expected target differs after write | Stop widening and preserve the production row for diagnosis | Readback mismatch test and canary gate |
| Orphan is reported | Stop widening; prepare a separate reconciliation decision | Readback and existing orphan reporting |
| Departed player gains a chant reference or changes identity | Refuse deletion and preserve the document | Exact retirement guard and focused regression |
| Credential missing or rejected | Stop before Firebase access; do not substitute another project or credential | CLI failure and execution record |

## Performance and cost

- **Workload:** 20 clubs, 623 raw official-feed rows, 622 reviewed squad rows after aliases and owner membership overrides, and 192 chants. The canary covers one team, 27 players, and six chants.
- **Budget:** Sequential club processing, bounded document reads and writes, no collection-wide cross-club scan, and no automatic retry loop. Expected Firebase cost is negligible at this pre-launch volume, but no zero-cost claim is made.
- **Measurement:** Record per-club planned, existing, matching, mismatching, and orphan counts without storing raw production documents.

## Rollout and recovery

1. Apply and locally verify only the approved four-addition, three-removal Arsenal squad refresh and the three named owner membership overrides. Complete.
2. Verify the ignored credential identifies `chants-f95b4` without printing secret fields. Complete.
3. Run the refreshed roster-currentness check and require zero membership differences across all 20 clubs. Complete.
4. Run Arsenal read-only identity preflight. Complete, 12 safe targets.
5. Run all-club read-only identity preflight. Complete, 192 safe targets.
6. Run all-club readback-only to establish the pre-write baseline and expected absence or existing-state counts. Complete; the exact result is recorded above.
7. Build the approved exact Arsenal reconciliation amendment. Complete locally: the fail-closed retirement action and persistent dangling-reference readback pass focused tests. Exact-head clean-runner verification remains.
8. Stop again for the explicit production-write hold point. If released, run the normal Arsenal upsert, then read back before any removal.
9. Remove only the three named departed Arsenal player documents after exact identity and zero-reference checks, then require exact Arsenal readback.
10. Write Leeds United only and run immediate Leeds readback and orphan checks.
11. If both bounded steps are exact, widen through approved club groups with immediate readback. If any result differs or is ambiguous, stop.
12. After all clubs, run all-club preflight and readback again, then inspect the app on a real configured device before calling the live seed complete.

Recovery is forward-only by default. Correct reviewed content and rerun the affected club when an allowlisted content field is wrong. If a created document must be removed or an identity must change, prepare a separate exact-target destructive plan. Do not improvise deletion or broad rollback. Andrew owns every write and destructive hold point.

## Verification plan

| Claim | Check | Expected evidence |
|---|---|---|
| Roster membership is current | Pure comparison against refreshed official bootstrap JSON | 20 clubs, 622 reviewed players from 623 raw rows, zero unreviewed membership differences after 17 display aliases and three owner overrides |
| Read-only modes cannot write | Focused seed plan tests with writer spies | No writer call in preflight or readback modes |
| Readback uses production projection | Focused runtime comparison tests | Exact match and distinct mismatch cases for every allowlisted field |
| Seed source remains valid | `npm test` and `npx tsc --noEmit` in `seed/` | Passing suite and typecheck |
| Governance remains linked | Project memory, writing style, governance, and diff checks | Passing staged boundary |
| Production identity is safe | Named-project Arsenal and all-club preflight | Zero conflicts before any write |
| Canary is correct | Leeds write followed by readback-only | Exact target counts and zero unexpected orphan |
| Full rollout is correct | Final all-club readback plus device inspection | Exact source projection and visible expected clubs and chants |

## Open decisions and hold points

1. The exact Arsenal reconciliation source amendment is implemented and locally verified. Packaging and exact-head clean-runner verification require the next authorization.
2. The validated credential is present only at the ignored local path and must not be pasted, printed, or committed.
3. Clean preflight does not itself release production writes. Andrew must explicitly approve the Arsenal upsert and three guarded removals after the reconciliation implementation is exact-head green.
4. Leeds and widening remain later hold points. Any other deletion, identity migration, or unexpected existing data requires a new plan.
