# V1 live seed safety controls

## Change identity

- **Approval:** Andrew approved `V1 Premier League live seed rollout spec` on 2026-08-30, then approved the exact Arsenal amendment and owner membership overrides.
- **Starting head:** `1a509c80d88bfd92370f3974cd9f2f50c307f519`, merged PR 22.
- **Scope:** Add a complete 20-club roster-currentness gate, fail-closed CLI parsing, an exact Firebase project credential guard, writer-free production readback, the approved Arsenal squad refresh, and an exact guarded action for its three unreferenced departures.
- **Excluded authority:** Read-only named-project inspection was authorized. No production write, deletion, identity migration, deployment, commit, push, merge, store action, or release. Clean preflight does not release the Arsenal reconciliation or Leeds canary.
- **Durable decisions:** Existing stable seed identity and runtime provenance remain governed by Decisions 005 and 006. This block changes no Firestore schema or product authority.

## Arsenal source amendment

The reviewed Arsenal squad adds Bruno Guimarães, Christos Tzolis, Ezri Konsa, and Illan Meslier. It removes Christian Norgaard, Leandro Trossard, and Tommy Setford. None of those removed players owns a player-linked source chant, so the change drops no chant content. A future Trossard hero or historic chant can use the existing club-linked historic-subject path.

The official feed still contains Fábio Vieira and Reiss Nelson, but the owner confirmed they have left or are leaving, so the currentness gate excludes them explicitly. The feed omits young Arsenal player Marli Salmon, whom the owner confirmed should remain, so the gate retains him explicitly. These three overrides are named code, counted in output, and covered by tests. They cannot silently disappear during a later feed refresh.

## Safety architecture

`seed/roster_currentness.ts` maps the exact approved 20 clubs, preserves reviewed display names through 17 explicit aliases, applies the three owner membership overrides, and reports club-scoped additions and removals. The real refreshed comparison now reconciles 623 raw official-feed rows to 622 reviewed rows with no unreviewed difference.

`seed/seed_plan.ts` parses one mutually exclusive mode: normal seed, `--preflight-only`, `--readback-only`, or the exact no-argument `--retire-approved-arsenal-players`. Unknown or conflicting options fail before credential or Firebase work. Focused writer-spy tests prove that both read-only modes invoke no seed writer. The retirement mode cannot accept a club filename or widen its target set.

`seed/seed_credential.ts` accepts only an Admin credential whose `project_id` is exactly `chants-f95b4`. The ignored service-account file remains outside source, logs, prompts, and project memory.

`seed/seed_readback.ts` compares only source-owned runtime fields. Team, player, and chant readback uses the existing source-to-runtime projection, checks expected IDs and team linkage, and reports missing, mismatching, and orphan rows. Extra system-owned chants are seed orphans; legitimate community chants are not. The already bounded team chant read also counts references to every departed player before any removal is considered. Counters, moderation, timestamps, and other server-owned fields are intentionally not compared or overwritten.

`seed/approved_player_retirement.ts` pins Christian Norgaard, Leandro Trossard, and Tommy Setford by exact document ID, Arsenal team ID, and expected name. It reads all three identities and global aggregate chant-reference counts inside one Firestore transaction before scheduling any delete. A changed identity, any reference, or an invalid count aborts without deletion. Missing targets are idempotent. Arsenal readback independently performs exact document reads and the same global player-ID reference queries, including after the player documents are gone.

## Verification evidence

- The first complete roster run failed correctly after aliases, reporting six apparent Arsenal additions and four apparent departures.
- The owner decision reduced that to four real additions, three real removals, two explicit exclusions, and one explicit retention.
- The complete seed suite passes 71 tests. Retirement regressions pin the three targets, all-reads-before-deletes ordering, idempotence, identity refusal, reference refusal, invalid-count refusal, and persistent dangling-reference detection.
- `npx tsc --noEmit` passes in `seed/`.
- The refreshed real roster command passes with 20 clubs, 622 reviewed rows from 623 raw rows, 17 aliases, three owner overrides, and zero unreviewed membership differences.
- `seed_data/clubs/arsenal.json` parses successfully, and no other club or chant content changed.
- An unknown CLI option fails before the absent credential is evaluated, proving argument validation precedes Firebase initialization.
- The ignored credential identifies only `chants-f95b4`, has owner-only permissions, and remains absent from Git status.
- Named-project preflight reports all 12 Arsenal and 192 all-club chant targets collision-free with no writes.
- Baseline readback reports 19 missing teams, 598 missing players, 180 missing chants, four missing Arsenal players, 12 Arsenal chants differing only on `origin`, and three departed Arsenal player documents. Each departed player has zero current chant references. No other mismatch or system-owned chant orphan exists.
- No Firebase write occurred during implementation or verification.

## Remaining gates

PR 23 merged the complete source boundary after exact-head run `33325900749` passed all eight jobs at `b3f5099`. Andrew then released the bounded Arsenal production step. Immediate pre-write checks matched the prior baseline exactly. The normal upsert created the four approved additions and reconciled all 12 chant projections. Post-upsert readback left only the three approved zero-reference departures. The guarded transaction deleted exactly those three documents, and final Arsenal readback reports one matching team, 28 matching players, 12 matching chants, and zero missing, mismatching, or orphan rows.

Andrew separately released Leeds United as the canary. Immediate preflight remained safe, the writer created only one team, 27 players, and six chants, and exact readback reports every row matching with no mismatch or orphan. The post-canary all-club preflight keeps all 192 chant identities safe. Readback reports only the expected absent 18 teams, 567 players, and 174 chants, with no mismatch or orphan.

Andrew released the recorded six-group widening sequence. Every group passed a fresh identity preflight, wrote only its three named club files, and completed exact same-group readback before the next group began. The final all-club preflight reports all 192 chant identities safe. Final production readback reports 20 matching teams, 622 matching players, 192 matching chants, and zero missing, mismatching, or orphan rows.

No seed recovery or retry is pending. PR 24 packaged the evidence as one documentation-only commit, `bb74ffd4ef545bc8e1291795954747560386e340`. Exact-head run `33328925712` passed all eight jobs, and PR 24 merged at `83711bc1a41ca656258ea87f7ff4451019705399` on 2026-08-30. Configured-device catalogue inspection remains; its preparation and prerequisites are recorded in `docs/EXECUTION.md` and the seed runbook. Any later seed write, deletion, or identity change requires a new or exact rerun authorization.
