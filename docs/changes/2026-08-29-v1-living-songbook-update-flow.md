# V1 Living Songbook update flow

## Change identity

- **Approval:** Andrew approved `V1 Living Songbook update flow spec` on 2026-08-29.
- **Starting head:** `ef7195cf5159c45afd5f92eaf427c698f6d62b16`, merged launch-services source.
- **Scope:** Private chant correction, variation, and evidence intake; submitter status; stale-aware operator resolution; evidence attachment and promotion; creator milestone; deletion coverage; and durable V1.1 and market memory.
- **Excluded authority:** No automatic chant edit, deployment, seed write, content-policy decision, provider change, production notification claim, commit, push, merge, store action, or release.
- **Durable decision:** `docs/decisions/025-living-songbook-update-authority.md`.

## Product result

Every live chant detail now offers `Suggest an edit` separately from safety reporting. A supporter can identify a correction, preserve another legitimate version, or add a canonical YouTube or X proof link. `My chant updates` shows private Received, Planned, Updated, and Not changed outcomes without promising a deadline or claiming that a submission is true.

Submitters receive their newest 100 valid requests, and operators receive the oldest 50 valid open requests first. Malformed or future-version rows are isolated instead of failing the whole stream. Each operator row rechecks current non-cache chant authority and compares the stored chant version with the current one. Corrections and variations may be planned, marked updated after the reviewed content path changes, or closed with a reason. A missing, hidden, or removed source leaves only Not changed available. Evidence may be attached to a current canonical or system-owned community chant, or attached while a current user-created community chant becomes canonical in one transaction. Content-resolution actions are unavailable for evidence requests in both UI and server authority.

When evidence causes a real community-to-canonical transition, the chant creator receives one deterministic private milestone: `Your chant made the terrace.` Opening it fetches the current chant and refuses hidden, removed, or missing content.

## Authority and recovery

All suggestion writes are callable-owned. The server derives identity, target version, title snapshot, timestamps, status, and resolution fields. The deterministic document ID rejects the same user, chant version, purpose, and correction category before rate budget is spent. Separate anchored limits allow five accepted requests per hour and twenty per day without changing report or feedback budgets.

Direct client mutation is denied. Only the submitter and an active operator may read a request. Evidence acceptance rejects any stale source version. Other stale resolutions require explicit acknowledgement. Different existing evidence requires separate replacement acknowledgement. Terminal rows cannot create a second audit or promotion notification. The operator query filters Received and Planned, orders oldest first, and then applies its 50-row bound, so terminal history and newer intake cannot hide the oldest pending work.

Account deletion removes private suggestion rows through the durable paged job. Suggestion rows do not retain operator identity. Ordinary retained operator audits include the action, chant ID, suggestion ID, and result only. An explicitly confirmed evidence replacement may also retain the prior public evidence map. Audits never retain the submitted explanation, proposed lyrics, proposed evidence, or submitter identity.

## FanChants and V1.1 memory

The read-only FanChants audit validated team-first songbooks, lyric search, historic preservation, offline access, new-chant alerts, and the long-term possibility of a separate owned-recording licensing business. It also exposed boundaries Chants should keep: popularity is not proof, one genre is too coarse, recording ownership does not clear the melody, broad commercial upload licenses need plain language, and external catalogue text is discovery evidence rather than seed content.

The roadmap now pins eight V1.1 candidates with a smallest slice and decision trigger: Chant Call-Ups, Matchday Mode, Tune Families, Heard at the Ground, followed-club chant alerts, lyric-level search and historic filters, creator lyric-video tools, and commercial creator opportunities. These are evaluation candidates, not launch promises.

## Verification evidence

- Functions production TypeScript build passes and all 163 Functions tests pass after the independent review corrections.
- The complete Flutter suite passes 488 tests, including the current-authority milestone destination and new operator plus private-history production widgets.
- Focused form, repository, chant detail, promotion activity, moderation, typed failure, malformed-row, unavailable closure, replacement, audit, and cleanup tests pass. The intentional Chant Detail golden change was inspected and accepted.
- Seed passes 42 tests.
- `flutter analyze lib test` passes with the same gitignored placeholder Firebase fixture used by CI, and the fixture was removed afterward.
- Firestore rules TypeScript and `firestore.indexes.json` validation pass. Java is absent locally, so the new owner, cross-user, operator-query, and direct-write emulator cases remain a clean-runner gate.
- Project memory, project-governance regressions, and `git diff --check` pass before final staging.

## Remaining gates

Package only after explicit authorization. Then run exact-head clean CI, including Java-backed Firestore rules and native compile jobs. The combined device walkthrough must cover signed-out entry, retained form values, duplicate and rate-limit copy, private history, stale operator review, evidence link-out, promotion activity navigation, account deletion, and degraded network states before deployment or release.
