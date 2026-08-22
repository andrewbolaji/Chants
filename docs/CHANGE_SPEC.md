# Change spec: V1 Songbook and Chant Lab browse split

**Status:** Implemented and locally verified, PR review pending
**Updated:** 2026-08-22
**Risk lane:** Lane 2, trust presentation, ranking behavior, navigation, and cached-state handling
**Stack base:** Draft PR 6, `codex/v1-provenance-evidence`

This is the one active implementation specification on the stacked browse branch. It replaces the completed provenance specification only on this branch. Andrew approved the two-surface product direction in decision 004, then explicitly approved this exact technical contract on 2026-08-22.

## Outcome

- **Problem:** Team and player screens still mix `canonical` and `community` chants into one ranked list. Provenance labels now tell the truth at card level, but fans cannot deliberately browse the trusted archive separately from the creator workshop. Player pages also treat an empty list as a dead end rather than an invitation to start the missing chant.
- **Desired behavior:** Team and player journeys default to a clearly named Songbook containing only Terrace Proven chants and offer a separate Chant Lab containing only community work. Chant Lab supports deterministic Top and New order, marks recent ideas with early support as Rising without implying proof, and makes starting a chant obvious. Status changes move a chant between surfaces without changing its identity.
- **Non-goals:** Changing chant status semantics, automatic promotion, changing the evidence contract, new Firestore fields or indexes, backend ranking, personalization, following creators, challenges, notifications, share-out, Saved Matchday Songbook, hosted media, evidence attachment after posting, edits to seed content, live Firebase access, or deployment.
- **Review boundary:** Pure browse projection and ranking, cache metadata exposure, Team and Player screen hierarchy and empty states, a reusable Chant Lab view, the Rising presentation signal, focused tests and goldens, and framework records.

## Acceptance criteria and invariants

1. The existing `status` field is the only surface-membership authority. `canonical` appears in Songbook and never Chant Lab; `community` appears in Chant Lab and never Songbook.
2. Votes, score, origin, evidence, creator, chant type, age, and Rising state never change surface membership.
3. Team and Player screens expose text-labeled `SONGBOOK` and `CHANT LAB` tabs, default to Songbook on a fresh visit, and retain the selected tab while that route remains mounted.
4. Songbook preserves the existing score-descending total order within its canonical set: score descending, creation time ascending, then document ID ascending.
5. Chant Lab defaults to `TOP`. Top orders community chants by score descending, creation time ascending, then document ID ascending. `NEW` orders them by creation time descending, then document ID ascending.
6. Top and Songbook survivor order stays stable during a route visit when only vote counters change. Hidden, removed, or status-changed records disappear immediately. Newly eligible records append in deterministic rank order. New may prepend newer records because its order does not depend on votes.
7. Rising is a presentation-only signal on a community chant whose `createdAt` is not in the future, is no more than seven days old, and whose net score is at least 3. The seven-day boundary is inclusive. Rising never changes status, promotion eligibility, provenance copy, or Top/New membership.
8. Chant Lab explains in text that Rising means early community support and is not Terrace Proven. The meaning does not rely on gold, position, iconography, or score alone.
9. Team Songbook retains club-chant and player-chant grouping plus full-squad access. A chant is never dropped because its player record is missing or still loading; unresolved player chants remain visible with their existing subject label.
10. Team Chant Lab is one team-wide competitive list across club, player, coach, and rival subjects. Known player names are shown on cards without affecting ranking.
11. Player Songbook and Chant Lab are scoped to that player only. Signed-in users see `START A CHANT` with that player prefilled. Signed-out users can browse but no write action is implied.
12. A surface can be empty while the other is populated. Empty Songbook copy points toward Chant Lab without calling community work untrusted or fake. Empty Chant Lab gives a signed-in fan a direct start action and gives a signed-out fan honest sign-in guidance.
13. The existing visible-query boundary remains intact: every browse query filters `hidden == false` and `removed == false`, so hidden or removed chants never appear in either surface.
14. Query snapshots expose whether their data came from the Firestore device cache. Cached chants remain usable and receive neutral `DEVICE CACHE` supporting copy; the UI does not claim a live network failure from cache metadata alone. A terminal chant-stream error with no usable data shows the existing error state.
15. Player metadata loading or failure does not replace an already available chant list with a full-screen spinner or error. It degrades only player names, player grouping, and the squad subsection.
16. No new Firestore composite index, collection, field, security rule, Cloud Function, runtime package, analytics event, or remote configuration is introduced.
17. Promotion and demotion received through the existing live stream move the same chant ID to the correct surface. Votes may update the displayed score without making a card jump within Top or Songbook during that visit.
18. At 390 by 844 and at enlarged text, both tab labels, Top/New controls, Rising explanation, cards, empty actions, and full-squad controls remain readable without overflow or clipped tap targets.

Invariants:

- Terrace Proven remains a reviewed trust state, never a popularity state.
- Rising remains a reversible, local presentation signal and never a moderation or authorization input.
- Existing provenance labels remain visible on cards and detail; this block changes hierarchy, not their meanings.
- The repository continues to read one visible chant stream per Team or Player route. Client-side projection does not add Firestore reads.
- Existing chant IDs, counters, comments, votes, evidence, and seed records are unchanged.
- No production or staging read, write, deployment, dashboard change, or release is authorized by this specification.

## Browse and ranking contract

### Surface projection

A pure Dart browse service accepts an iterable of already-visible chants and returns projections without mutating the input:

```text
Songbook = status == "canonical"
Chant Lab = status == "community"
```

Unknown future statuses are shown in neither surface and are surfaced to tests as unsupported input. The current model and rules already allow only `canonical` and `community`; this fail-closed projection prevents a later status from accidentally gaining trust presentation.

### Total orders

Songbook and Top use:

```text
score descending
createdAt ascending
id ascending
```

New uses:

```text
createdAt descending
id ascending
```

Status is not a tie-breaker after projection because each list contains exactly one status. Negative scores remain present. No score floor hides a community chant.

### Stable visit order

Each Songbook or Top view owns a small in-memory order reconciler. On first usable data it records the pure ranked IDs. Later emissions remove IDs no longer present, retain survivor positions, and append unseen IDs in their current deterministic rank order. This prevents an optimistic vote or counter reconciliation from moving the control under the fan's finger. The state is route-local and resets on a new visit.

New is recomputed on each data emission because its order uses immutable creation time. A genuinely new post may appear at the top.

### Rising

Rising is true only when all conditions hold at evaluation time:

```text
status == "community"
createdAt <= now
createdAt >= now - 7 days
score >= 3
```

The screen supplies the current client time to a pure helper. Clock manipulation can change only this decorative signal, so it is not a security boundary. The signal refreshes on a chant-stream emission or widget rebuild; v1 does not schedule a midnight timer.

## Interface and interaction design

### Shared hierarchy

- The route app bar carries a two-item `TabBar`: `SONGBOOK` then `CHANT LAB`.
- Songbook opens first and includes a short plain-language introduction: Terrace Proven chants belong here after sourcing or operator review.
- Chant Lab begins with the line `NEW SONGS START HERE`, a Top/New segmented control, and supporting copy that says Rising reflects early support, not Terrace Proven status.
- `RISING` is rendered as secondary text in the card footer, separate from the provenance label. It is never styled as the gold Terrace Proven sticker.
- The route-level creation action says `START A CHANT`. On a Player route it retains the existing player-prefilled submission arguments.

### Team Songbook

- Canonical chants with no `playerId` remain under `CLUB CHANTS`.
- Canonical chants with a known player remain under `PLAYER CHANTS`, retaining the player row and route to that player.
- Canonical chants with a missing or not-yet-loaded player record remain under `PLAYER CHANTS` as cards rather than disappearing.
- The current collapsible Full squad control remains at the bottom of Songbook. Player metadata loading or failure receives a compact inline state there.

### Team Chant Lab

- All community subjects compete in one Top/New list.
- A known `playerId` adds the player's name to the card. Unknown player metadata leaves the existing `PLAYER` subject tag visible.
- Empty copy invites a signed-in fan to start the first idea for the club. The signed-out version explains that sign-in is required without showing an enabled creation control.

### Player route

- Songbook contains only canonical chants for that player.
- Chant Lab contains only community chants for that player with Top/New and Rising behavior identical to Team.
- When Songbook is empty, copy says no chant has reached the Songbook yet and offers a path to Chant Lab.
- When Chant Lab is empty, a signed-in user gets `START A CHANT`; the existing navigation passes the player's ID. The same action remains available when the list is populated.

### Cached, partial, error, and status-change states

- Repository browse snapshots carry `chants` and `isFromCache`, using `includeMetadataChanges: true`. A compact `DEVICE CACHE` note appears while the current snapshot is cache-backed. It does not block taps or imply guaranteed offline permanence.
- If a later stream error retains usable data, the list remains visible with recoverable supporting copy. If no chant data has ever arrived, use the full existing ErrorState.
- Team chant data renders as soon as available. Player metadata enriches it later. A player-stream problem cannot erase the chant surfaces.
- A promotion removes the card from Chant Lab and appends it to Songbook for that visit. A demotion performs the inverse. Hidden and removed records vanish from both.

## Design and implementation seams

- Add a pure `chant_browse.dart` service for surface projection, Top/New ranking, Rising evaluation, and route-local stable order reconciliation.
- Add a small immutable `ChantBrowseSnapshot` repository value with `chants` and `isFromCache`. Team and Player browse methods use the same existing visible queries with metadata changes enabled.
- Keep the current list-returning repository methods only if another caller still needs them. Do not duplicate live subscriptions in one route.
- Add a reusable stateful `ChantLabView` for its introduction, Top/New control, stable Top ordering, Rising copy, card list, empty state, and creation action.
- Extend `ChantCard` with an explicit `rising` presentation input. The card never derives or trusts Rising by itself.
- Refactor TeamScreen into a shared data boundary plus separate Songbook and Chant Lab tab bodies. Preserve the current frozen-order intent through the new reconciler rather than screen-specific ID maps.
- Refactor PlayerScreen to the same tab hierarchy and player-prefilled creation path.
- Use existing theme, spacing, card, provenance, EmptyState, ErrorState, SectionEyebrow, and tolerant golden utilities. Add no new dependency.
- Do not edit `firestore.rules`, Cloud Functions, indexes, model persistence, seed files, or Firebase configuration in this block.

## Failure and abuse analysis

| Condition | Expected behavior | Evidence |
|---|---|---|
| Canonical and community records arrive together | Each appears in exactly one correct surface | Pure projection and screen tests |
| Unknown future status appears | It appears in neither trusted nor community surface | Pure fail-closed projection test |
| Community chant has high score | It may rank first in Top but remains outside Songbook | Pure ranking and widget tests |
| Canonical chant has a negative score | It remains in Songbook | Projection test |
| Chant is seven days old with score 3 | Rising is true at the inclusive boundary | Clock-controlled unit test |
| Chant is future-dated, older than seven days, or below score 3 | Rising is false | Unit tests |
| Vote count changes in Top or Songbook | Card content updates but survivor order does not jump | Stable-order test and widget test |
| New community post arrives | It appends in Top and may prepend in New | Reconciler and widget tests |
| Operator promotes or demotes a chant | Same ID leaves one surface and appears in the other | Stream-driven widget test |
| Chant becomes hidden or removed | It disappears immediately and is not retained by frozen order | Reconciler and repository-boundary checks |
| Player metadata is loading, missing, or errors | Chants remain visible; only name, grouping detail, and squad state degrade | Team widget tests |
| Cache-backed snapshot arrives | Existing cards remain usable with neutral cache copy | Widget test |
| Stream errors before data | Full recoverable error state | Widget test |
| Player has no Songbook entry | Songbook points to Chant Lab; signed-in Lab can start a prefilled chant | Player widget test |
| Signed-out viewer sees empty Lab | Guidance mentions sign-in; no enabled write control appears | Widget test |
| Large text or narrow viewport | Tabs, selector, explanation, cards, and actions do not overflow | Golden and text-scale widget test |

## Performance and cost

- **Firestore:** No added query or read per route. Team and Player keep one visible chant subscription; metadata changes may add local snapshot events without document-read cost.
- **Client work:** Surface filters and sorts are `O(n log n)` over one team or one player's visible chants. V1 volume is expected to be small.
- **Memory:** Stable order retains only chant IDs for the mounted route. It is discarded on pop.
- **Rendering:** Tab bodies use lazy lists for chant cards. Empty and intro content remain bounded.
- **Revisit trigger:** Introduce paginated, server-assisted surface queries when one team exceeds 500 visible chants, route projection exceeds 16 ms at p95 on the representative device, or one snapshot materially increases billed reads.

## Rollout and recovery

- **Order:** Merge after PRs 4, 5, and 6. No backend or rules deployment is introduced by this block. Release only with the provenance and promotion boundary from PR 6 so Songbook membership remains honest.
- **Backward compatibility:** Every existing visible chant already has one of the two allowed statuses. Missing origin or evidence does not affect surface projection.
- **Canary:** On an authorized non-production or local device, inspect a team and player with canonical-only, community-only, mixed, empty, cached, promoted, demoted, and hidden data. Confirm Top/New and Rising boundaries with fixed fixtures.
- **Healthy signals:** Fans can identify both surfaces without instruction, creation starts increase from player pages, Top/New switches are used, and no community chant is reported as falsely Terrace Proven.
- **Rollback:** Revert the client hierarchy to the mixed browse list. No data or backend rollback is required. Keep PR 6's provenance, evidence, rules, and Functions controls intact.
- **Owner:** Andrew authorizes review, merge, release, and any live environment work. Codex implements and verifies repository changes only.

## Verification plan

| Claim | Check | Expected evidence |
|---|---|---|
| Projection is trust-correct | Pure service tests | Canonical and community partition exactly; unknown status fails closed |
| Top and New are deterministic | Pure ranking tests | Exact total order, negative retention, no input mutation |
| Rising is bounded and non-authoritative | Clock-controlled service tests | Inclusive seven-day and score thresholds; future, old, canonical, and low-score cases false |
| Vote updates do not move controls | Stable-order tests plus real Chant Lab widget test | Survivor IDs stay fixed while score text updates |
| Status changes move surfaces | Team and Player stream-driven widget tests | Same ID leaves one tab and appears in the other |
| Empty paths create correctly | Player and Team widget tests with route observers | Signed-in start passes exact team, sport, competition, and player arguments; signed-out has no write control |
| Partial and cached states stay usable | Widget tests over browse snapshot and player metadata states | Cached cards remain tappable; metadata failure does not erase chants; no-data error is full-screen |
| Hierarchy is understandable | 390 by 844 Songbook and Chant Lab goldens plus enlarged-text test | Clear tabs, selector, Rising explanation, empty path, and no overflow |
| Existing app remains green | `flutter test`, `flutter analyze lib test`, Functions, seed, rules TypeScript, and clean-runner CI | All regression and untouched boundary suites pass |
| New test proves behavior | Temporarily break the status projection or stable-order guard | Focused test fails for the intended reason, then passes after restoration |
| Stack remains scoped | Compare against `codex/v1-provenance-evidence`, run `git diff --check`, and search changed prose for forbidden dashes | Only approved Flutter, test, and framework paths; no Android, unrelated lockfile, backend, rules, index, seed, or dependency diff |

## Approval

**Approved.** Andrew explicitly approved this Songbook and Chant Lab technical specification on 2026-08-22. Implementation is authorized within this repository boundary. Approval does not authorize Firebase access, deployment, merge, or release.

## Open decisions

None. The product split, default Songbook surface, Top/New controls, Rising-as-non-proof direction, and player creation path were already approved in decision 004. This specification fixes the exact ranking, recency threshold, cache wording, ordering stability, partial-state behavior, and test seams needed to implement them safely.
