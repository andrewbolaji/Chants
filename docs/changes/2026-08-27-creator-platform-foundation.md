# Change implementation rationale: V1 creator platform

## Change identity and boundary

- **Change:** Restore the creator-led Chants vision on top of the trusted Songbook and Chant Lab foundation.
- **Implementation agent:** Codex
- **Base:** Merged PR 16 main at `86603c22fbd7647f89c9276af9a60a0b3d63113b`
- **Branch:** `codex/v1-creator-platform-foundation`
- **Risk lane:** Lane 2
- **Approval:** Andrew selected Feed Pass 3, Chant Stage, and Navigation Pass 3, Product Clear, then approved performance media, popularity signals, public creator identity and bio, follows, public destinations, mentions, deeper performance conversation, and one final independent review after the large range.
- **Included:** Product Clear shell, creator identity, moderated performance creation, Chant Stage, playback, performance interactions and ranking, public creator and content destinations, private follows, activity, mentions, continued performance replies, report and block integration, published-media moderation, account-deletion integration, rules and indexes, native dependency graph, CI contract correction, tests, and durable records.
- **Excluded:** production deploy, live data or seed writes, native signing, store submission, automatic large-scale media screening, beat-synced karaoke editing, licensed backing tracks, duets, remixes, payouts, opportunity marketplace, and personalized recommendation models.

## Outcome

The signed-in product now presents Feed, Clubs, Create, Songbook, and You as five stable destinations. Feed is the real Chant Stage rather than a chant-catalogue bridge. It shows approved performances in Rising, New, Terrace, and Following lanes while keeping the underlying chant, club or player, creator, trust state, lyrics route, and popularity meaning visible.

A creator can reserve a unique public handle, add a short bio, choose an existing chant, record or select a video of at most 30 seconds, upload with explicit progress and recovery, and track private draft status. Upload completion does not publish content. A server-owned admission path verifies account, creator, chant, object path, content type, bytes, and duration. An active operator must approve the draft before its public performance projection and media are visible.

Approved performances support explicit playback, likes, qualified views after three seconds, comments, unique shares, and a deterministic weekly most-shared distinction. These signals rank the performance only. They never promote the chant to Terrace Proven and never replace chant votes.

Fans can follow creators without exposing the follower graph, open public creator pages, continue a performance conversation, mention up to five valid handles, and receive private follow, mention, or reply activity. Deep conversation is stored without cycles but visually capped at three indentation levels, with a focused thread for deeper branches.

Stable public chant, performance, and creator destinations render bounded safe social metadata. Public performance video uses a no-autoplay same-origin route that rechecks current visibility and redirects to a two-minute signed media URL. Hidden, removed, missing, and malformed public targets share one unavailable response.

The existing safety and lifecycle system now covers the new entities. Reports accept performances and performance comments. Directional blocks suppress social action and notification fan-out. Operators have reported and hidden media queues with dismiss, hide, remove, and restore actions plus audit. Account deletion cleans private drafts, interactions, follow edges, notifications, and report authorship while preserving only the already approved retained-content boundary.

## Capability and authority impact

| Capability | Before | After | Authority |
|---|---|---|---|
| Signed-in navigation | Push-oriented Home | Feed, Clubs, Create, Songbook, You shell | Existing policy and deletion gates remain ahead of shell |
| Creator identity | Private account display name | Separate public handle, name, bio, visibility, and aggregates | Callable transaction and server-owned counters |
| Performance media | None | Private draft, staged upload, manual approval, public projection | Callables, Storage rules, operator authority |
| Feed | Chant discovery | Bounded approved performance pages with four filters | Firestore visibility predicates and client pagination |
| Popularity | Chant vote score | Separate performance like, qualified view, share, and comment totals | Deterministic records and server recomputation |
| Creator graph | None | Private follow edges and public aggregate totals | Callable and server trigger |
| Conversation | One-level chant replies | Continued performance replies, mentions, focused deep threads | Callable parser, block checks, current target authority |
| Activity | None | Private recipient inbox for follows, mentions, and replies | Server-derived rows and recipient-only read |
| Public sharing | Native text only | Stable public chant, performance, and creator pages | Current-authority Functions and Hosting rewrites |
| Media moderation | Chant and comment actions | Manual draft approval plus published performance and comment queues | Active operator callable and audit |
| Deletion | Existing account and interaction phases | New media, graph, notification, report, and interaction phases | Bounded retryable worker |

## Data and lifecycle choices

`creatorProfiles` is the public identity allowlist. `creatorHandles` is a private reservation index. `creatorFollows` and `creatorNotifications` are private. `performanceDrafts` tracks owner-visible upload and review state. `performances` is the approved public projection. Deterministic `performanceLikes`, `performanceViews`, and `performanceShares` are private source records. Approved `performanceComments` are public under exact visibility rules. Performance and performance-comment reports are operator-only.

Storage permits an owner to write only the exact staged object named by a current draft. Public media is not directly readable through Firebase client rules. The server media resolver confirms the exact current performance projection and media path before signing a short URL.

Deletion is additive and retryable. It removes private graph and inbox data in both relationship directions, clears owned draft and staged state, removes deterministic interactions and user-authored report data, and anonymizes retained approved contributions according to decisions 011 through 016. A pending deletion immediately blocks new creator, upload, social, and report authority.

## Failure, privacy, and recovery choices

| Risk | Behavior |
|---|---|
| Overlapping handle claims | One transaction owns the normalized reservation; the loser receives a specific collision |
| App dies during upload | Private draft persists and can retry or cancel; no public projection exists |
| Forged metadata or path | Admission rejects unsupported type, bytes, duration, ownership, or non-exact staged path |
| Duplicate trigger delivery | Visible aggregates recompute from deterministic source records in a serialized parent transaction |
| Self-refresh or repeat share | One UID contributes once; creator's own view or share does not improve competition rank |
| Following graph is empty | Stage explains and falls back to Rising instead of showing a dead feed |
| Block is created before notification delivery | Server fan-out rechecks both directions and suppresses the notification |
| Deep reply targets another performance | Server rejects the cross-target parent and root |
| Public target is hidden after sharing | New page and media requests return the generic unavailable response |
| Issued media URL outlives a hide briefly | Exposure is bounded by the remaining two-minute signed URL lifetime |
| Moderation queue outgrows staff | New work stays pending or admission pauses; it does not silently publish |
| Deletion begins during upload or interaction | New authority stops and the durable worker cleans the private state on retry |

## Interface evidence

The design follows Chant Stage rather than generic social chrome. Media receives attention, but every card retains football context and an obvious route to the chant. The palette remains warm black, gold, neutral paper, and restrained red. Anton carries chant and stage identity; Nunito carries reading and controls; Space Mono carries short factual labels.

The Stage golden at 390 by 844 shows a 4:5 media card, creator and chant hierarchy, trust label, popularity actions, filters, and the five-tab shell. The weekly-winner label has its own row so enlarged text cannot collide with trust. The creator profile golden shows private editing, public-profile entry, aggregates, activity, and the same shell. Chant detail adds a clear `PERFORM THIS CHANT` path without weakening lyrics or trust.

Video does not autoplay. Play, retry, comments, follow, share, report, moderation, and navigation have written semantic labels. Deep comments preserve width. Upload and moderation states keep a written next action rather than relying on color or animation.

## Verification performed locally

| Check | Result | Scope |
|---|---|---|
| Full Flutter suite | PASS, 415 tests | Models, repositories, services, shell, Stage, upload, playback, creator profile, follows, comments, activity, safety, lifecycle, and goldens |
| Cloud Functions suite | PASS, 122 tests | Identity, admission, moderation, interactions, counters, follows, notifications, public pages, safety, and deletion |
| Firestore and Storage emulator | PASS, 157 assertions | Public projections, private records, hostile writes, operator queries, staged upload, and media denial |
| Seed suite | PASS, 42 tests | Stable identity, validation, execution planning, and reconciliation |
| Full Flutter analysis | PASS exit 0 with the non-secret CI fixture | Project Dart source and tests; inherited initializing-formal info remains non-fatal |
| Governance regressions | PASS | Staged and range-based execution-memory enforcement, writing scan, native contract, and error propagation |
| Golden inspection | PASS | Chant detail, Chant Stage, and creator profile at 390 by 844 |
| iOS dependency resolution | PASS | CocoaPods resolved FlutterFire and Firebase Storage on one Firebase iOS 12.18 graph |
| iOS simulator compile | INCOMPLETE | Xcode entered compilation but was terminated after an extended silent wait; no source error was emitted |
| Android debug compile | BLOCKED | Android SDK is unavailable in the local environment |

The exact final counts may change if a later correction adds tests. `docs/EXECUTION.md` owns the final handoff numbers.

## Rollout, observation, and recovery

No deployment was authorized or performed. The compatible rollout order is Firestore and Storage rules, Functions, Hosting, then the client. Hosting and media resolution must be verified before a release client emits public links.

Before rollout, configure URL-signing IAM, verified domain association, App Links and universal links, store destinations, App Check, billing alerts, Function error alerts, a staged-object cleanup schedule, and a manual moderation response target. The placeholder content policy, privacy policy, terms, and creator-media rules must be replaced and reviewed.

If moderation or cost health is poor, pause new performance admission while leaving Songbook, Chant Lab, words-only submission, and already approved content available. If the client shell fails, a compatible client rollback can restore the earlier Home entry without deleting creator data. If a counter drifts, deterministic source rows support recomputation. Hidden media stops new public resolution; already signed URLs expire within two minutes.

## Known compromises and review focus

1. Following V1 queries at most the 30 most recent followed creators.
2. Manual pre-publication review has no measured service target yet.
3. Public media adds Function, signing, Storage, and egress cost without production measurements.
4. Firestore list rules rely on server-only writers and required query predicates; exact projection shape is also checked at point reads and parsers.
5. Native domain association and store fallback cannot be completed without production identifiers.
6. The current iOS dependency graph resolves but still needs a completed clean compile and device run; Android needs an SDK-backed compile.
7. Automatic large-scale media screening, karaoke timing, licensed audio, remix tools, push notifications, payouts, and personalized recommendations are deferred.

## Material artifacts

- `lib/presentation/shell/`, `feed/`, `create/`, and `profile/`
- `lib/data/models/creator_profile.dart`, `performance.dart`, `performance_comment.dart`, and `performance_draft.dart`
- `lib/data/repositories/creator_*`, `performance_*`, and `public_share_repository.dart`
- `functions/src/creator_profile.ts`, `creator_follow.ts`, `creator_notification.ts`, `performance.ts`, `public_share.ts`, and `published_performance_moderation.ts`
- `firestore.rules`, `storage.rules`, `firestore.indexes.json`, `firebase.json`, and `hosting/`
- `functions/src/account_deletion.ts` and `functions/src/safety_submission.ts`
- `.github/workflows/ci.yml`, `scripts/check-project-memory.sh`, and `scripts/test-project-governance.sh`
- Decisions 017 through 021, `docs/INTERFACE.md`, `docs/ROADMAP.md`, `docs/PROJECT_PROFILE.md`, and `docs/EXECUTION.md`

## Remaining gates

Package the exact branch, run clean-runner CI, obtain the one requested Claude review, correct accepted findings separately, complete both native builds and the combined device walkthrough, finish policy and production configuration, then request separate authority for deploy, seed writes, signing, and release.
