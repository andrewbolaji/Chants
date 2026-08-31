# Change spec: V1 Chant Call-Ups

**Status:** Approved
**Implementation state:** Implemented, reviewed at the stated staged tree, and locally verified again after both low corrections. Packaging and new exact-head CI are authorized and pending at this precommit snapshot. No merge or release claim.
**Date:** 2026-08-31
**Lane:** 2, current-data presentation and creation integration
**Base:** `2d362a2709ccdc1dd8b18bedea9d72b432f3556b`, PR 26 correction head
**Approval:** Andrew approved the bounded Call-Ups implementation on 2026-08-30 local time. After Claude's combined review, Andrew approved both low corrections, one feature commit, push and exact-head clean CI. Merge, deployment and a new competition service remain outside this approval.
**Prior contract:** Preserved at the base. `docs/changes/2026-08-31-post-combined-review-corrections.md` owns PR 26 corrections; its eight-job exact-tree CI passed in run `33354752226`. Claude independently closed F1-F5 while reviewing head `2d362a2` plus staged tree `91213af707f4c6dc4bd3d3334b7adaea35a1ea0b`.

## Outcome and boundary

Make the existing player creation invitation discoverable on the club page. Show one clearly labelled Chant Call-Up for a player listed at that club who has no visible chant for that club in Chants. Let fans choose another eligible player, write using the real prefilled form, and reach that player's Chant Lab after successful submission. Current listed membership is not a claim about a transfer, contract or the absence of a stadium song.

Keep Feed, Clubs, Create, Songbook and You unchanged. No generated lyrics, squad edits, media changes, new rankings, prizes, deadlines, winners, badges, paid promotion, notifications, persistent call-up records, dependencies, indexes or services. Matchday Mode remains a future candidate.

## Acceptance criteria and invariants

1. Club Songbook and Chant Lab expose the same single spotlight, visually separate from Terrace Proven content. The copy names the club whose catalogue was checked, never implying global catalogue or real-world absence.
2. Eligibility uses the complete existing team chant query and current listed squad. Any visible chant for that club, including community and unknown future trust status, excludes the player. Other-club, blank-ID and blank-name players are excluded. A prior-club chant does not exclude a player at this club. Ordering is deterministic by name then ID; choosing another player cycles locally and survives tab changes.
3. Initial loading, cache-only data, pending local writes, errors and closed streams cannot produce an absence claim or call-up action. Preserve existing readable fallback and generic creation routes. A fresh snapshot restores the spotlight; new chants and squad removals replace an ineligible target without changing stored data.
4. Preserve cache and pending-write metadata for the squad and chants. TeamScreen still owns exactly one squad and one chant subscription. No per-player queries, extra background fetch, discovery scan, timer or polling.
5. Signed-in Write this chant opens the real form with correct club, sport, competition and player. Origin stays an explicit user choice. Signed-out fans see Sign in to write, which uses the existing sign-in route without promising automatic return or draft restoration.
6. Successful submission returns the acknowledged chant; only that result opens its player's Chant Lab. If the author changes the subject or that player is no longer listed, return to club Chant Lab instead. Cancel and failure never claim success or navigate there. Existing callers may ignore the result. Current form validation, duplicate review, server/rules admission and stale-player recovery remain intact.
7. Cards and actions work at 390 by 844 and 320-pixel width with 1.8x text, long player names, semantic labels and at least 48-pixel targets. No auto-advance, texture behind body text, truncation of the target or horizontal carousel.
8. Focused projection, repository metadata and actual route/widget tests prove eligibility, freshness transitions, exact prefill and completion/cancel behavior. Inspect rendered UI and run full Flutter tests, scoped analysis and staged governance. Claude reviews PR 26 corrections plus this completed block in one explicitly bounded handoff.
9. Post-review corrections preserve query scope, freshness guards and color tokens. Assert club-specific copy independently of pixels. Keep the two main club golden fixtures open until disposal, assert the eligible player's invitation on both tabs, regenerate and inspect those baselines plus the two copy-affected Call-Ups images. Existing golden tolerances stay unchanged.
10. CI follow-up: first run `33361604474` reports Linux screenshot drift with no retained images. Reuse the existing artifact-upload action to retain only failed synthetic PNG evidence for seven days, without changing job success or permissions. Run the two Call-Ups viewports as independent cases so failure of one cannot skip evidence for the other. Inspect actual runner images before deciding any renderer-baseline correction; do not widen tolerance from percentages alone.
11. Inspected runner evidence from diagnostic run `33362066687` confirms glyph/curve-edge differences in all four images without missing content or altered layout. Keep these four byte-exact Linux references separately and retain the macOS references. Select by test-host platform, preserve semantic assertions and existing thresholds, then verify the final amended head with the full eight-job workflow. No renderer upgrade, pinning change or app redesign is included.

## Design and compatibility

- Reuse the club's two query streams and existing color, type and spacing tokens. Add a small pure eligibility projection and one shared card, not a call-up controller or backend entity.
- Add a metadata-bearing squad snapshot with the existing list stream retained as a compatibility adapter. Add pending-write provenance to chant browse snapshots with a false default for existing synthetic fixtures. Both source streams request metadata events.
- Track only the selected player ID in TeamScreen. A new eligible set preserves that choice when possible; otherwise display the first deterministic candidate. No popularity claim or fair-exposure promise.
- Extend the existing player route with an optional initial Chant Lab selection. Submit returns the submitted `Chant` only after create acknowledgement, not a fabricated document ID. The call-up caller checks mounting and the actual submitted subject before continuing navigation.
- Rejected: Stage-wide fetches or a new tab (unnecessary queries and scope); authoritative claims from cached lists (false absence); another writing form (duplicate validation); automatic origin or lyrics (misrepresents authorship); pinned weekly contests (persistent policy/backend needed).

## Failure and abuse analysis

| Condition | Expected behavior | Evidence |
|---|---|---|
| Empty or partial cached catalogue | Omit call-up; retain normal browse notices | Metadata and widget transitions |
| Pending write, stream error or completion | Remove opportunity claim; no stale callback can authorize a write | Actual route tests |
| New chant or player leaves club list | Recompute eligible set; preserve other readable chants | Live stream tests |
| Concurrent creation by another fan | Advisory prompt may become outdated; existing duplicate review and admission remain authoritative, no reservation | Source trace and duplicate-review regressions |
| Signed out or account changes | No direct new write path; current form and server/rules reauthorize | Sign-in route and existing submission tests |
| Cancel, failed create, disposed club | No false success, no forced player navigation or disposed context use | Widget route tests |

## Performance and cost

The current catalogue is 622 players and 192 chants across 20 clubs. Projection is linear in team chants plus sorting the team's eligible players. One card is rendered per visible tab. Query shapes and subscription counts remain unchanged; metadata events add local render notifications but no extra query or per-player read. No production latency, conversion or billing improvement is claimed.

## Verification and recovery

Run focused tests first, then `flutter test`, `flutter analyze lib test` using only the example client fixture, changed-file formatter checks, diff inspection and staged memory/writing/governance checks. Demonstrate at least one acceptance regression failing on the pre-feature boundary. Keep pixel evidence separate from semantic trust and action assertions; do not raise golden tolerances without measured renderer evidence.

Client-only rollout, no migration. Revert this feature to the base to remove the spotlight; created chants remain ordinary community chants and readable by the prior client. The scoped rationale separates Claude's reviewed tree from the two locally verified low corrections. Packaging, clean-runner CI for this new tree and device proof remain distinct gates. Andrew owns release. Before launch, walk club to call-up to submission to player Chant Lab on a configured device, including cancel and lost connectivity.

## Open decisions

None for this bounded source slice. Wider call-up distribution, exposure fairness, contests, analytics and Matchday Mode need separate evidence and approval.
