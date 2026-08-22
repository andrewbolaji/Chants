# Stable seeded chant identity

**Completed:** 2026-08-21
**Type:** Lane 2 persistent identity and seed safety
**Application behavior changed:** Operator seed behavior only

## Change identity and boundary

- **Change:** Replace title-derived seeded chant document IDs with explicit immutable source IDs and refuse unsafe live collisions.
- **Target:** Stacked branch `codex/stable-chant-identity` and draft PR 5.
- **Included:** Seed identity resolution, club-file validation, pre-write collision checks, transactional ownership checks, Arsenal's 12 explicit IDs, tests, and durable documentation.
- **Excluded:** Flutter, Cloud Functions, Firestore rules, indexes, dependencies, community chant IDs, live Firebase access, production seeding, automatic migration, and all cultural content edits.
- **Approval:** Andrew explicitly approved `docs/CHANGE_SPEC.md` before implementation on 2026-08-21.

## Outcome

- `chants[].id` is now required source data for every club seed.
- The document reference uses the explicit ID and no longer resolves from `title`.
- IDs must be lowercase single-hyphen slugs, begin with the club prefix, stay within 120 characters, and be unique in the file.
- Duplicate normalized titles remain invalid even when the IDs differ.
- A preflight reads the team's chants and each explicit target before the first team, player, or chant write. It rejects non-system ownership, a different team, or a same-title system chant at another ID.
- `--preflight-only` exposes that check as a read-only operator command and does not call any seed writer.
- Every chant create or update rechecks target ownership and team membership inside its Firestore transaction.
- The 12 Arsenal IDs exactly equal the former algorithm's output. The expected rollout updates the same documents and requires no dependent-reference migration.

## Invariants preserved

- Arsenal titles, lyrics, tunes, context, subjects, players, variations, classifications, and squad data are byte-for-byte equivalent after removing only the added `chants[].id` keys.
- Existing counters, flags, timestamps, and engagement remain outside the update allowlist.
- Community content cannot be overwritten by a predictable seed ID.
- An unexpected live state aborts and requires a separate migration plan. It is never automatically deleted or rewritten.
- No production compatibility is claimed from repository tests alone.

## Verification

- `cd seed && npm test`: 42 passed.
- `cd seed && npx tsc --noEmit`: exit 0.
- Focused cases cover title independence, all 12 Arsenal legacy IDs, missing and malformed IDs, maximum length, duplicate IDs, duplicate normalized titles, safe rename, community collision, cross-team collision, same-title collision, transactional create, transaction-time community claim, allowlisted update, read-only preflight order and read failure, normal write order, and unknown CLI flags.
- Red-check: temporarily restoring title-derived resolution failed the rename guard with `arsenal-one-nil-arsenal` instead of the frozen ID. Restoring explicit resolution returned the full suite to green.
- Structural source comparison: after deleting only the 12 new ID keys, the current Arsenal JSON equals the stack-base JSON.
- `git diff --check`: clean before commit handoff.

## Security, privacy, abuse, and infrastructure impact

The change adds defensive Admin SDK reads and Firestore transactions to an operator-only seed. It stores no new user data, changes no client authorization, and introduces no dependency or service. Error output contains conflict classes and document IDs, not credentials or raw document payloads.

## Rollout and follow-up

Repository implementation is complete. The next production step is a separately authorized `cd seed && npx ts-node seed.ts --preflight-only arsenal.json` against `chants-f95b4`. If all expected Arsenal targets are same-team and system-owned with no duplicate system title, a later authorized normal seed may proceed. Any mismatch stops the rollout and opens a migration-specific Lane 2 plan.
