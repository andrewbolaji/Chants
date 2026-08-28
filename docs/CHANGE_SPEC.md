# Change spec: Creator platform expansion

**Status:** Implemented and packaged in draft PR 17; implementation-head clean-runner CI green; independent review and release gates pending
**Updated:** 2026-08-28
**Risk lane:** Lane 2, public identity, uploaded media, persistent social data, public routes, moderation, privacy, and cost
**Base:** `86603c22fbd7647f89c9276af9a60a0b3d63113b`, merged PR 16 main
**Approval:** Andrew approved Feed Pass 3, Chant Stage, and Navigation Pass 3, Product Clear, after reviewing three feed passes and three navigation passes. He also approved 30-second record or upload performances, performance popularity signals, creator bios, follows before V1, public chant URLs with rich previews, mentions, and deeper conversations.

## Outcome

- **Problem:** The current app is a useful trusted songbook and Chant Lab, but it understates the original creator-led vision. Fans cannot perform a chant, build a public creator identity, compete on reach, follow creators, or share a public destination that can travel outside the app.
- **Desired behavior:** Chants becomes the home of the chant idea and the performances around it. A fan can still learn and save a chant for matchday, but can also publish an original idea, attach or create a short performance, earn visible reach, participate in threaded conversation, and build a following. Public links carry the chant back into the app without confusing popularity with terrace proof.
- **Product position:** The Songbook remains the trusted archive. Chant Lab remains the workshop. Performances are a third object attached to a chant, not a replacement for chants or proof that a chant is sung in a stadium.

## Approved product decisions

1. The primary shell is `Feed`, `Clubs`, `Create`, `Songbook`, and `You`.
2. The feed uses the Chant Stage hierarchy. Performance media earns attention, but the creator, underlying chant, club or player, trust state, popularity, and route to lyrics remain visible.
3. Feed filters begin with `Rising`, `New`, and `Terrace`. Ranked labels are derived from real metrics and never appear on every item.
4. A performance is a separate persistent entity. Many performances may reference one chant.
5. A performance video may be recorded in the app or selected from the device library. The maximum duration is 30 seconds. The first version does not provide a beat-synced karaoke editor, licensed backing tracks, duet, remix, or general video editing.
6. Existing words-only chants and external evidence links remain supported. A creator does not have to sing or upload media to contribute.
7. Performance popularity is separate from chant backing. Performance views, likes, comments, and shares measure the performance. `Back it` continues to rank the underlying chant idea.
8. The weekly competition uses unique sharers, then likes and qualified views as deterministic tie breakers. A share means the app handed a public performance link to an operating-system share destination. It does not claim the recipient opened it.
9. Public creator identity lives in an allowlisted public document separate from the private account profile. It includes a unique handle, public display name, short bio, and server-owned aggregate counts. Ban state, age confirmation, report counts, policy acceptance, deletion state, and email remain private.
10. Creator profiles and follows ship before V1 release. The identity and bio boundary remains separate from the private account profile, and the follow graph exposes aggregates rather than public edge lists.
11. Public chant and performance URLs plus rich social previews ship before V1 release. Preview copy must name the trust state honestly and cannot imply stadium adoption from votes or performance reach.
12. Conversations support mentions and continued replies. Stored threads may continue beyond three replies, but the mobile interface never indents beyond three visible levels. Deeper replies open in a focused thread so text remains readable and screen-reader hierarchy remains explicit.
13. Low-volume V1 video moderation is manual before public visibility. Pending media is readable only by its owner and operators. Automated provider-scale media screening is deferred until upload volume or moderation response time crosses a recorded operational trigger.
14. The completed creator-platform range receives one independent exact-range review after local integration hardening and clean-runner CI. This supersedes the earlier plan for a review after each block. Corrections remain separate from implementation review.

## Delivery blocks

### Block A: Product shell and creator identity

**Local status:** Complete.

- Install the approved five-tab shell without breaking policy or account-deletion gates.
- Preserve useful Home discovery as the initial Feed foundation until real performances exist.
- Add a real `You` surface for public identity, bio editing, account settings, and existing account actions.
- Reserve unique normalized handles through a server-authoritative transaction.
- Keep public creator data separate from the private profile document.

### Block B: Performance creation and Chant Stage feed

**Local status:** Complete.

- Add the performance model, repository, indexes, rules, and deletion treatment.
- Add camera recording and library selection with the same 30-second and size limits.
- Provide explicit upload, retry, cancellation, pending-review, rejected, removed, and playback-failure states.
- Publish only operator-approved media.
- Replace the Feed foundation with the approved Chant Stage cards and real pagination.
- Add deterministic performance likes, qualified unique views, unique shares, comments, counters, and weekly ranking.

### Block C: Public destinations

**Local status:** Complete for server-rendered pages and stable public URLs. Native universal links, store fallback, domain association, and production hosting remain launch configuration gates.

- Add stable public chant, performance, and creator routes.
- Generate safe server-rendered social metadata and deep-link or store fallback behavior.
- Update native share-out to use the public destination only after resolver availability is proved.
- Preserve a complete text fallback when a destination is unavailable.

### Block D: Follows, mentions, and deeper threads

**Local status:** Complete for the V1 bounded graph, inbox, mention fan-out, and continued performance conversations.

- Add private follow edges and public aggregate counts.
- Add Following as a feed signal without making an empty graph a dead end.
- Add validated mentions and notification inbox records with bounded fan-out.
- Migrate comment threading additively so legacy chant comments remain readable.
- Keep visible indentation bounded while allowing focused continued conversation.

### Block E: Integration and release hardening

**Local status:** Complete for source authority, reports, blocking, moderation, deletion integration, focused interface evidence, and local automated verification. Native compile and device evidence, policy copy, production configuration, deploy, and release remain open.

- Extend blocking, reports, moderation, account deletion, audit privacy, rate limits, and operational recovery to every new entity.
- Measure read, write, storage, egress, and Function amplification against the stated budgets.
- Complete representative viewport, text-scale, screen-reader, keyboard, permission, offline, lifecycle, upload, and playback evidence.
- Complete Android and iOS builds, the combined device walkthrough, independent freeze review, policy text, live configuration checks, signing, and release only under their own authority gates.

## Data and authority design

| Surface | Public data | Private or server-owned data | Write authority |
|---|---|---|---|
| `profiles/{uid}` | None | Role, ban, age gate, policy acceptance, deletion state, report count, account display name | Existing owner allowlist plus server-owned fields |
| `creatorProfiles/{uid}` | Handle, public display name, bio, aggregate counts, visibility | Moderation reason and internal history stay elsewhere | Callable transaction for identity fields; server for counters and visibility |
| `creatorHandles/{normalizedHandle}` | None | Handle-to-UID reservation | Server only |
| `performances/{performanceId}` | Approved performance metadata and server counters | Pending or rejected owner state and moderation detail | Server admission and moderation; direct client writes denied |
| Media storage | Approved playback object | Staged and rejected upload objects | UID-scoped upload ticket; server-owned publication state |
| Performance likes, views, shares | Aggregate counts only | UID-scoped deterministic interaction records | Server-authoritative or rules-pinned deterministic writes |
| Follow edges | Aggregate counts only | Follower and followed UID edge | Authenticated owner of the follow action |
| Mentions and notifications | None | Recipient-scoped inbox data | Server-derived from an accepted comment or reply |

## Invariants and acceptance criteria

1. A public read cannot expose any private `profiles` field.
2. A handle is normalized, allowlisted, case-insensitively unique, and cannot be stolen by overlapping requests.
3. Identity updates cannot change role, ban state, age state, deletion state, policy state, report count, or server counters.
4. A banned or deletion-pending account cannot create or update public identity, performances, interactions, follows, mentions, or comments.
5. The shell retains the selected tab across child navigation and exposes every destination with a semantic label and at least a 48 by 48 logical-pixel target.
6. Account deletion, sign out, policy, blocked users, feedback, and operator moderation remain reachable after the Home account menu moves to `You`.
7. Existing Home, competition, team, player, chant detail, submission, Songbook, policy, deletion, and moderation routes keep their current authority behavior.
8. Performance duration over 30 seconds, unsupported media, oversized files, forged ownership, forged counters, and unapproved public reads fail closed.
9. Pending media is not publicly readable. Approval changes visibility without changing ownership or the underlying chant.
10. A performance never changes a chant from Chant Lab to Terrace Proven. Evidence and operator promotion remain the only trust path.
11. Likes, qualified views, unique sharers, comments, follows, and notifications converge from stored source records under duplicate or overlapping delivery.
12. Feed queries always include current visibility and approval predicates. Stale readable content cannot authorize a like, share count, comment, follow, save, or report.
13. Ranking uses server time and documented deterministic tie breakers. Clients cannot write rank or counters.
14. Public preview routes omit private identifiers and unsafe text, escape user content, use a fallback image, and return a valid destination for visible content only.
15. A removed or hidden target stops resolving publicly and loses current-live actions in the app.
16. Deeper comment storage cannot create cycles, cross-target parents, orphan promotion, unbounded inline indentation, or a mention notification to a blocked user.
17. Account deletion removes private interaction and follow edges, removes or anonymizes creator identity according to the approved retention policy, and leaves retained content without a live profile link.
18. Every material UI surface covers loading, empty, populated, error, stale or unavailable authority, destructive confirmation, and enlarged-text behavior where applicable.

## Failure and abuse analysis

| Failure or abuse | Required response |
|---|---|
| Two accounts claim the same handle | One transaction succeeds. The other receives a specific unavailable-handle error without partial profile mutation. |
| Identity save times out after commit | A subsequent profile read is authoritative and the form can reconcile without creating a second reservation. |
| Upload stops or app dies | The draft remains retryable or cancellable; abandoned staged objects are eligible for bounded cleanup. No public performance exists. |
| Duration or type metadata is forged | Server admission verifies trusted object metadata and rejects the performance. |
| Upload succeeds but admission fails | The object remains private and cleanup can remove it without affecting any published entity. |
| Approval and removal overlap | The parent performance transaction serializes current moderation state. Removed wins over public playback. |
| Trigger delivery duplicates or reorders | Aggregate writers recompute from source records and serialize on the parent document. |
| A creator self-refreshes views or shares | Deterministic per-account records prevent repeated contribution to ranking. Own views and shares do not contribute to competition rank. |
| A link is shared after moderation | The resolver returns an unavailable response and the app refuses current-live actions. |
| A mentioned or followed account blocks the actor | New interaction is denied. Server fan-out rechecks the block before writing a notification. |
| Account deletion begins during upload or interaction | New authority stops, staged media becomes cleanup work, and retained public content loses creator linkage. |
| Moderation queue grows beyond manual capacity | Pause new media admission or keep new work pending. Do not silently publish. Revisit automated screening at the recorded trigger. |

## Performance and cost budgets

- Maximum selected or recorded duration: 30 seconds.
- Initial maximum upload size: 50 MiB before server verification. Reduce only with measured device evidence.
- Feed page: at most 10 performances per request, with explicit pagination and no unbounded listeners.
- Profile and feed cards use denormalized public identity snapshots only where a documented reconciliation path exists; avoid one profile read per visible card.
- One account contributes at most one ranking like, one qualified view, and one unique share to a performance.
- New-account and established-account upload admission receive separate bounded daily limits before public beta.
- No background autoplay, background upload, unbounded prefetch, or automatic retry loop.
- Billing alerts and an explicit storage cleanup schedule are launch gates. No claim about production cost is made until observed.

## Interface evidence plan

- Compare the approved Chant Stage and Product Clear reference against the Flutter result without copying food-app imagery or generic social chrome.
- Inspect Feed, Create, Songbook, and You at 390 by 844, a narrow phone width, and 1.8x text.
- Verify bottom navigation labels, selection, safe areas, keyboard behavior, tab restoration, and child-route back behavior.
- Verify words-only, video, pending, rejected, removed, blocked, empty-following, slow-network, offline, upload retry, playback failure, and reduced-motion states.
- Keep direct semantic assertions for creator identity, trust state, popularity meaning, and public-link availability outside golden tolerance.

## Verification plan

| Claim | Evidence |
|---|---|
| Client models and repositories | Focused unit and fake-Firestore tests where deterministic, plus emulator coverage for authority |
| Callable admission and counters | Extracted handler tests with duplicate, overlap, timeout, invalid input, and deletion-state cases |
| Firestore and Storage authority | Java-backed Firestore rules plus the appropriate Storage rules emulator or documented blocker |
| Shell and creator interface | Widget navigation, state, semantics, text-scale, and targeted golden evidence |
| Existing behavior did not regress | Full Flutter, Functions, rules, seed, governance, and scoped native checks |
| Public routes | Resolver unit and integration tests for visible, hidden, removed, missing, and unsafe content |
| Review boundary | One scoped rationale per completed block, exact commit range, clean runner CI, then the scheduled independent review |

## Rollout and recovery

- Every block remains isolated on a stacked branch and is not deployed by implementation work.
- New public collections are additive. Old clients continue using chants, profiles, and one-level comments until the compatible client is released.
- Rules and Functions deploy before a client that depends on them. Public resolvers deploy before share payloads begin emitting URLs.
- Uploaded media stays behind a server-owned admission and moderation state. If moderation, billing, or playback health is poor, pause admission and keep Songbook plus words-only Chant Lab available.
- Rollback the client shell to the prior Home entry without deleting creator data. Disable performance admission before rolling back media readers.
- Schema cleanup, live backfill, bulk moderation, deployment, seed writes, signing, and store release require separate explicit authorization.

## Deferred after V1

- Beat-synced karaoke recording and editing.
- Licensed backing-track catalog.
- Duet, remix, stitches, and collaborative video composition.
- Automated provider-scale media screening until the operational trigger is met.
- Paid creator opportunities, marketplace, payouts, sponsorship matching, or ranking-based compensation.
- Fully personalized recommendation models. The first feed uses transparent recency, trust, following, and popularity inputs.

## Implemented review boundary

The independent review boundary is `86603c22fbd7647f89c9276af9a60a0b3d63113b...641281e` in draft PR 17. It includes the five-tab product shell, creator identity, private follows, activity notifications, moderated performance upload and playback, Stage ranking and interactions, public destinations, published-media moderation, account-deletion integration, Firebase Hosting and Storage rules, CI contract corrections, and durable records.

The range is committed and pushed. Replacement GitHub Actions run `33181165940` passed all six clean-runner jobs at implementation head `641281e`. No production Firebase write, deployment, seed write, signing action, store submission, PR merge, or release has been performed in this implementation block.

## Remaining gates

1. Finish or rerun native iOS and Android compilation in an environment that completes Xcode and has the Android SDK.
2. Perform the combined device walkthrough for recording, device selection, permission denial, upload recovery, playback, sharing, Following fallback, comments, notification routing, moderation, blocking, deletion, text scale, and offline behavior.
3. Replace the placeholder content policy and finalize privacy policy, terms, reporting expectations, and creator-media rules.
4. Configure and verify `chantsfc.com`, Hosting rewrites, IAM URL signing, universal or app links, store destinations, App Check, billing alerts, Storage cleanup, Function alerts, and deployed rules parity.
5. Give Claude the one requested independent review of `86603c22...641281e` and preserve its findings as a separate review artifact.
6. Correct accepted review findings in a separate bounded record before declaring the creator-platform source freeze.
