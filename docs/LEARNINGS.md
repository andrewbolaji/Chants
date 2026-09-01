# Engineering learnings

This is durable, evidence-backed project memory. It prevents the same failure or investigation from being repeated. It is not a diary, backlog, or place for guesses.

## Rules

- Add an entry only after a reproduced failure, measured result, incident, or verified correction yields a reusable lesson.
- Search before adding an entry. Update or supersede an existing lesson instead of creating a duplicate.
- State the scope, evidence, reusable rule, applied control, and revisit trigger.
- Promote mature lessons into code, tests, `AGENTS.md`, an ADR, or a runbook, then retain their provenance here.
- Never store prompts, chain-of-thought, secrets, personal data, or raw production payloads.

## Entries

### 2026-09-01T07:20:00Z Declared routes do not prove entry-state reachability

- **Status:** promoted
- **Scope:** Signed-out and stale-policy access to help, support, account deletion, and sign out.
- **Observed:** The router and six policy screens existed, but the real signed-out welcome linked only four destinations. The stale-policy gate displayed policy links while withholding the actual deletion and sign-out actions. Direct screen tests therefore overstated user access.
- **Evidence:** A production-widget journey now starts on the signed-out welcome, opens the policy hub, and reaches all six destinations. A real `ChantApp` gate test starts with a stale `v1` profile, opens the shared deletion action, proves the server request is called, then signs out without accepting. A 320 by 568, 1.8x test exposed and corrected a fixed-footer overflow in the same gate.
- **Rule:** Test critical access from the user state that needs it. Route declarations, direct screen construction, and text presence are not evidence that a signed-out or blocked user can reach or complete an action.
- **Applied control:** The signed-out welcome has one Help and Policies entry, the stale gate reuses the real deletion action and sign-out repository, and the whole gate is one scrollable surface.
- **Revisit:** Any auth-shell redesign, policy-version migration, deletion-action move, new launch document, or change to blocked-account recovery.

### 2026-09-01T02:33:30Z Policy-version migrations must cover every authority surface

- **Status:** promoted
- **Scope:** Versioned Terms and Community Rules across app, callable, Firestore, and Storage authorization.
- **Observed:** Dart, the acceptance callable, Firestore, and fixtures moved to `v2`, but Storage and five Functions feature handlers still required placeholder `v1`. The first full Java-backed run passed 167 assertions and denied six legitimate Storage cases; source inspection found the same drift in feature handlers.
- **Evidence:** The initial full rules run failed all six positive Storage paths. After correction, the full 173-case Firestore/Storage suite, 229 Functions tests, and policy conformance test pass.
- **Rule:** A versioned acceptance change is an authorization migration, not a copy edit. Inventory and verify every reader of the version, including server helpers, cross-service rules, fixtures, and signed-out gates.
- **Applied control:** Functions use `functions/src/policy.ts` as shared authority. Firestore and Storage duplicate `v2` explicitly, while `scripts/test-launch-policy.mjs` pins both rule files and rejects stale feature-handler comparisons.
- **Revisit:** Any policy version change, new authenticated service, new rule language, or new server helper that checks account admission.

### 2026-09-01T02:00:30Z Deterministic cleanup IDs still require payload validation

- **Status:** promoted
- **Scope:** Account deletion that reuses cross-service media-cleanup work.
- **Observed:** The deletion worker used a deterministic performance ID for cleanup, but an unconditional set could overwrite an existing server-owned row whose stored media path did not match that identity.
- **Evidence:** A focused regression seeds the exact job ID with a conflicting path. The corrected worker stops before performance redaction or cleanup mutation, while a separate exact-row case preserves the original request time and adds the deletion correlation. Another regression advances the deletion phase after the page query and proves neither a performance nor a draft is changed by the stale worker.
- **Rule:** A deterministic document ID prevents duplicate rows, not conflicting payloads. Read and validate every retained target field and the current lifecycle authority inside the write transaction before reusing or updating cross-service cleanup authority.
- **Applied control:** Published-performance and draft deletion now recheck phase, owner, exact Storage path, and existing cleanup identity in the same transaction that changes the job and source row.
- **Revisit:** Any new durable cleanup queue, retry key, migration that adopts existing jobs, or worker that can create the same deterministic ID from another lifecycle.

### 2026-09-01T01:12:01Z Authentication status checks must not emit credentials

- **Status:** promoted
- **Scope:** Firebase CLI authentication verification during production read-only inventory.
- **Observed:** The JSON form of a login-status command emitted active OAuth credential material into local tool output even though the intended question was only whether a session existed.
- **Evidence/control:** The session was immediately logged out to revoke it, then reauthenticated through the normal browser flow. No token, account or raw response is stored in project memory. No production request occurred before containment.
- **Rule:** Never use a credential-bearing login-status response as an authentication probe. Prove access with a narrow, non-token-bearing read against the explicitly named project and return only the minimum sanitized field. If credential material is exposed, revoke first, then resume.
- **Revisit:** Firebase CLI changes, a new release workstation, any authentication failure or any tool output that unexpectedly contains credential fields.

### 2026-09-01T00:44:49Z Existing ignored client configuration must prove its environment

- **Status:** promoted
- **Scope:** Physical Firebase client builds prepared from one of several local Git worktrees.
- **Observed:** A readable ignored iOS configuration from the launch-services worktree matched the Chants bundle but belonged to the deliberate CI fixture project. The signed app installed, then Firebase Installations aborted before Flutter's first frame because the fixture API key was intentionally invalid.
- **Evidence/control:** Native device logs named the Firebase options failure. A bounded check of existing local candidates compared project identity, bundle identity and API-key format without printing keys. Replacing both ignored generated client files with the matching `chants-f95b4` pair removed the native abort; the debug app reached the policy gate and the release app built, installed and launched.
- **Rule:** File presence and bundle agreement do not prove environment authority. Before a configured device build, validate the ignored Dart and native client files as one environment-specific pair against the intended project and bundle. Never infer production identity from a worktree name or reuse an obvious CI fixture.
- **Revisit:** Any Firebase project change, app registration refresh, regenerated client file, new platform target or additional local environment.

### 2026-08-31T05:37:26Z Live UI fixtures must preserve stream lifetime

- **Status:** promoted
- **Scope:** Flutter goldens for screens that distinguish active data from a completed subscription.
- **Observed:** Stream.value supplied valid club data, then completed. TeamScreen correctly removed Call-Ups, so two main club screenshots passed while omitting an eligible player's invitation.
- **Evidence/control:** `songbook_chant_lab_golden_test.dart` now asserts the invitation and player before each screenshot. Those assertions failed with the old fixture. Controllers keep both streams open until the screen is disposed, then close during teardown.
- **Rule:** Match the production stream's lifetime as well as its values and metadata. Assert the important semantic state before generating or accepting a golden; pixels alone can approve the wrong state.
- **Revisit:** Changes to subscription completion, snapshot authority or fixture lifecycle. The runtime closed-stream guard remains independently tested.

### 2026-08-31T00:49:27Z Passing rules emulators do not prove cross-service quotas

- **Status:** promoted
- **Scope:** Storage authorization that reads Firestore
- **Observed:** All five old Storage tests passed even though upload authorization needed three distinct Firestore documents. Firebase documents a two-document Storage limit; adding a global control would have required four.
- **Evidence:** The unchanged-rule rehearsal is recorded at 2026-08-30T23:47:50Z. Current `test_rules/storage_budget.test.ts` counts two calls through the upload helper graph and detects a deliberately inserted third lookup. The full behavioral suite separately verifies authority.
- **Rule:** Treat emulator acceptance and documented service budgets as separate evidence. Count the real dependency graph before adding cross-service authorization. Do not weaken account checks merely to fit a quota.
- **Applied control:** Decision 026 co-locates an authoritative expiring upload grant with private profile authority, reducing uploads to profile plus control. Issuance and revocation are transactional; no asynchronous open-flag mirror is trusted.
- **Revisit:** Any new lookup, rule helper, grant writer, emulator or documented quota change. Real deployed Storage smoke remains required after separate authorization.
- **Primary sources:** [Firebase rule access limits](https://firebase.google.com/docs/rules/rules-behavior#security_rules_limits_1), [cross-service quota explanation](https://firebase.blog/posts/2022/09/announcing-cross-service-security-rules/).

### 2026-08-29T21:00:00Z Accuracy intake needs version authority and a separate safety meaning

- **Observation:** A chant-specific correction can look like generic feedback or a report, but those inherited paths either lose source context or carry hiding and abuse consequences. The same proposed correction can also become wrong while an operator reviews it if the chant changes, and the source can disappear before the private request is closed.
- **Why it matters:** Reusing a safety path can hide valid content and corrupt abuse counters. Storing only a chant ID lets an old suggestion overwrite a newer canonical version. Requiring a visible target for every resolution turns disappeared targets into permanent queue rows. Treating a supporter claim as an edit makes intake itself a truth boundary.
- **Rule or heuristic:** Accuracy intake gets its own collection, copy, budget, and queue. Capture the server-read source version, show staleness, reject stale evidence acceptance, require explicit replacement of existing proof, keep target mutation behind current authority, and preserve a nonmutating terminal closure when the target disappears.
- **Evidence:** Focused regressions reproduce the unavailable-request dead end, silent evidence replacement, and review-dialog controller disposal. `functions/src/living_songbook.ts`, `lib/presentation/moderation/chant_update_moderation_tab.dart`, and Decision 025 hold the corrected boundary.
- **Revisit trigger:** a reusable framework abstraction proves it can preserve these separate meanings without combining collections, counters, or side effects.

### 2026-08-28T15:42:35Z A dependent public projection needs current source authority

- **Status:** promoted
- **Scope:** Published creator media whose availability depends on a creator account, public identity, chant, and moderation state
- **Observed:** The first performance projection captured creator and chant facts at approval, but a later creator ban or chant takedown did not close every feed, action, playback, or public-page path. The same isolation let creator performance totals drift and left removed Storage media without retryable cleanup.
- **Evidence:** Focused pre-fix tests kept a banned creator's performance and public destination available, accepted stale chant authority, denied operator preview of hidden video, found no physical media deleter, and reproduced absent Stage blocking and count repair. The corrected tests cover current source reads, projection fan-out, exact aggregate reconstruction, block filtering, hidden escalation, and deterministic cleanup work.
- **Learning:** A denormalized public row is a query optimization, not sufficient live authority when its eligibility depends on other entities. Recheck source truth at action and public-delivery boundaries, reconcile the projection asynchronously, and commit durable cross-service cleanup work with terminal state.
- **Applied control:** Performance source flags gate Firestore reads, current creator and chant documents gate server actions and public resolution, source triggers reconcile dependent rows and exact creator counts, and performance removal creates an exact-path retryable deletion job.
- **Revisit when:** source fan-out or aggregate scans cross a measured budget, the data model gains another upstream authority source, or signed media requires immediate revocation.
- **Related:** Decision 022, `functions/src/performance_source.ts`, `docs/changes/2026-08-28-pr17-post-review-takedown-integrity.md`

### 2026-08-28T05:06:46Z A public page is not a public media delivery boundary

- **Status:** promoted
- **Scope:** Moderated user video shared outside the installed client
- **Observed:** The first public performance page produced safe metadata and a valid destination but could only say `Watch on Chants`; it had no route that could deliver media while rechecking current visibility. Reusing the in-app callable or exposing a Storage URL would either fail for signed-out web viewers or bypass the public current-authority contract.
- **Evidence:** The final page test requires a controlled video element, forbids autoplay and raw Storage paths, and the media resolver test proves exact path binding, current visible-state lookup, and a two-minute signed URL.
- **Learning:** Public HTML and public media are separate trust boundaries. Moderated media needs a same-origin delivery route that checks the current public projection at request time and gives any residual access an explicit short lifetime.
- **Applied control:** `publicPerformanceMedia` validates the route identity through `handleResolvePublicPerformanceMedia`, returns a no-store redirect, and uses one generic unavailable response. Direct Firebase Storage reads remain denied.
- **Revisit when:** Production egress or signing cost is measured, immediate revocation is required, or a CDN token design can preserve current authority.
- **Related:** Decision 019, `functions/src/public_share.ts`, `functions/test/public_share.test.ts`

### 2026-08-27T00:25:16Z Negative evidence must fail at the intended boundary

- **Status:** promoted
- **Scope:** Regression harnesses for layered validation and repository governance
- **Observed:** The SwiftPM-marker fixture also set an invalid dependency-manager flag. It failed before reaching the marker guard, so deleting the marker guard left the harness green even though durable records claimed that guard was proved.
- **Evidence:** The independent review mutated away the marker guard and the old harness still passed. With a valid flag, marker present, and exact error assertion, removing the guard makes the corrected harness fail.
- **Learning:** A negative test is not evidence merely because it exits nonzero. Its fixture must satisfy all earlier preconditions and assert the failure class or message belonging to the boundary it names. Repository-read errors must also be distinct from successful empty results.
- **Applied control:** Native-contract fixtures assert exact messages for the flag, marker, root and nested resolution files, both required pods, and a forced Git `ls-files` error.
- **Revisit when:** A new ordered native-project guard, parser gate, or governance predicate is added.
- **Related:** `scripts/check-native-project.sh`, `scripts/test-project-governance.sh`, final freeze independent review

### 2026-08-26T23:50:13Z Native dependency-manager choice must be project-owned

- **Status:** promoted
- **Scope:** Flutter iOS projects that already use CocoaPods while Flutter can automatically enable Swift Package Manager
- **Observed:** A global Flutter default silently introduced a mixed SwiftPM and CocoaPods graph. SwiftPM resolved a different Firebase iOS SDK family and `cloud_firestore 6.4.1` failed on Objective-C bridge initializers even though the pinned CocoaPods graph was internally compatible.
- **Evidence:** The inherited simulator build failed at `FLTPipelineParser.m`. With Flutter's supported project-level SwiftPM flag disabled and the CocoaPods graph reconstructed, the exact simulator build produced `Runner.app` and the RunnerTests bundle compiled and validated.
- **Learning:** A repository must own its native dependency manager. Ambient tool defaults must not be allowed to migrate a pinned native graph during an ordinary build. Switching managers belongs in one explicit dependency change with a clean generated-state rebuild.
- **Applied control:** `pubspec.yaml` pins `enable-swift-package-manager: false`; generated SwiftPM project and resolution state is absent; CocoaPods remains the V1 iOS graph.
- **Revisit when:** The FlutterFire versions and Firebase iOS SDK are verified together under SwiftPM, or the project deliberately migrates dependency managers through a separately reviewed change.
- **Related:** `pubspec.yaml`, `ios/Podfile.lock`, `docs/changes/2026-08-26-v1-native-build-readiness.md`

### 2026-08-26T21:26:27Z Derive labels from the rendered entity, not its lane

- **Status:** promoted
- **Scope:** Trust and momentum labels on live Flutter projections
- **Observed:** Home passed `rising: true` to every community preview. A stale zero-score 2024 idea therefore rendered `RISING`, while the same entity failed the shared `isRisingChant` predicate used elsewhere.
- **Evidence:** A focused Home regression failed on the hardcoded badge. A second regression starts with a qualifying idea, emits an authoritative score-zero live snapshot, and proves the corrected badge disappears while `ORIGINAL IDEA` remains.
- **Learning:** A collection lane identifies classification, not every derived property of its members. Compute user-visible status from the current rendered entity through the canonical predicate, and inject time when the predicate is time-dependent.
- **Applied control:** Home-mode `_LiveChantCard` and `TeamScreen` evaluate `isRisingChant` against the live chant and an injectable evaluation time. Tests inject a stable date. Semantic assertions protect trust words independently of golden tolerance.
- **Revisit when:** The Rising formula, live-card authority model, or Home projection changes.
- **Related:** `lib/presentation/browse/discovery_section.dart`, `test/presentation/browse/core_journey_golden_test.dart`, independent interface-readiness review

### 2026-08-26T14:18:08Z Mounted guards must dominate Consumer ref access

- **Status:** promoted
- **Scope:** Async Flutter callbacks owned by a Riverpod Consumer widget
- **Observed:** Both account-deletion error handlers invalidated a provider before checking whether Home still existed. A positive pending-profile update could replace and dispose Home while the request was in flight, after which either late error threw `Bad state: Cannot use "ref" after the widget was disposed`.
- **Evidence:** Two widget regressions start deletion from active Home, advance the profile to pending while the request remains unresolved, and then complete with an unconfirmed or generic error. Both failed at Riverpod invalidation before the correction and pass with the pending screen still authoritative afterward.
- **Learning:** A mounted check must dominate every Consumer `ref` access and every context-derived UI lookup after an `await`. Guarding only the scaffold call is too late because the provider container boundary is already disposed with the widget.
- **Applied control:** Both deletion catch paths return on an unmounted context before invalidating local deletion state or resolving the scaffold messenger.
- **Revisit when:** Async work moves into a longer-lived controller, Riverpod lifecycle ownership changes, or another widget callback retains `ref` across an external await.
- **Related:** `lib/presentation/home/home_screen.dart`, `test/app/app_gate_test.dart`, final freeze closure

### 2026-08-26T13:34:53Z Privacy cleanup must classify provenance before flattening detail

- **Status:** promoted
- **Scope:** Audit retention when one account may have acted both as a user and an operator
- **Observed:** Actor-wide replacement of every audit detail removed reporter text, but it also destroyed generated moderation context and made deleted operator actions indistinguishable from ordinary user actions.
- **Evidence:** Functions tests exercise all nine allowlisted operator actions, a mixed 201-row audit population, report and unknown actions, self-target policy acceptance, and duplicate completion delivery. Operator rows retain generated detail under `deleted-operator`; report and unknown rows fail private.
- **Learning:** Privacy cleanup should classify fields by origin and purpose, not only by document owner. Preserve only allowlisted trusted metadata that still serves accountability, replace user-authored or unknown text, and use a non-identifying role sentinel when raw identity is unnecessary.
- **Applied control:** `auditRedactionForDeletedActor` distinguishes generated operator actions, reports, policy acceptance, and unknown actions; decision 016 records the target-side retention and completion-transaction boundary.
- **Revisit when:** Operator detail becomes user-authored, the action vocabulary changes, a general retention engine replaces this allowlist, or approved policy requires target-side pseudonymization.
- **Related:** `functions/src/account_deletion.ts`, decision 016

### 2026-08-26T12:06:39Z Lifecycle cleanup must constrain late writers

- **Status:** promoted
- **Scope:** Privacy cleanup for asynchronously written audit or derived records
- **Observed:** Redacting every existing audit row authored by a deleting account did not close the boundary. A delayed report-create trigger could run after the deletion worker's audit scan and write the reporter UID and reason again.
- **Evidence:** Functions tests cover the bounded mixed 201-row cleanup path and separately deliver report audit work after the reporter becomes pending or its profile disappears. The writer produces the anonymous sentinel and generic detail in both delayed cases.
- **Learning:** Historical cleanup and future-write prevention are separate requirements. When asynchronous writers can outlive a lifecycle transition, cleanup must pair a bounded backfill with a writer-side check committed atomically with the new record.
- **Applied control:** Account deletion classifies actor-owned audit pages under a fail-private allowlist, while report audit writers read reporter lifecycle state in the same transaction as the audit write; decision 016 records the retention boundary.
- **Revisit when:** Audit intake moves behind one synchronous service, a general privacy ledger replaces profile-state checks, or approved retention policy changes which fields may survive deletion.
- **Related:** `functions/src/account_deletion.ts`, `functions/src/audit.ts`, decision 016

### 2026-08-26T04:40:55Z A transport exception is not negative acknowledgement

- **Status:** promoted
- **Scope:** Client compensation after a server transaction starts a destructive workflow
- **Observed:** The account-deletion callable commits its durable job before responding. A response can be lost after that commit, so restoring local data on every thrown request can reverse the privacy boundary after server acceptance. A transient snackbar also disappeared on process death while the durable unknown marker remained.
- **Evidence:** Lifecycle tests force an ambiguous remote exception, reconstruct storage across prepared, unknown, and accepted states, and prove that only prepared data restores while unknown data remains locked and retryable. Same-process tests prove prepared recovery can be retried without relaunch and a pre-network transition failure never calls the remote boundary. App-gate tests prove unknown, prepared-recovery failure, or unreadable local status cannot expose Home.
- **Learning:** Once a destructive request may have reached its commit point, classify a missing acknowledgement as unknown. Compensate only with positive rejection evidence and finalize only with positive acceptance evidence. A persistent uncertainty state also requires a persistent recovery surface.
- **Applied control:** Saved Songbook deletion uses prepared, unknown, and accepted artifacts; prepared actively recovers, unknown renders deletion retry and Sign out without claiming success, failure, or cancellation, and every signed-in launch resolves that state before Home; decision 012 preserves the boundary.
- **Revisit when:** The server exposes a durable status receipt or a stronger acknowledgement protocol removes the ambiguous state.
- **Related:** `lib/data/repositories/saved_songbook_repository.dart`, `lib/data/repositories/songbook_storage.dart`, decision 012

### 2026-08-26T04:40:55Z Absolute recomputation still needs a serialization point

- **Status:** promoted
- **Scope:** Firestore triggers that derive a parent aggregate from child documents
- **Observed:** Querying child ground truth and writing an absolute count survives duplicate delivery, but two handlers can still read different snapshots and let the slower older batch overwrite the newer value.
- **Evidence:** A controlled vote test lets an older transaction read one vote, commits a newer two-vote aggregate, and proves the older transaction retries to finish at two. Duplicate, burst, delete, and missing-parent cases remain green.
- **Learning:** Idempotency and concurrency safety are separate properties. Put the parent read, child query, and parent write in one transaction so every aggregate writer conflicts on the shared parent and reruns its query.
- **Applied control:** Vote, like, visible-comment, user-report, and explicit chant reconciliation now use parent-serialized Firestore transactions; decision 013 records the invariant.
- **Revisit when:** Measured volume makes transactional scans or retries material enough to justify a deduplicated event ledger or another aggregation service.
- **Related:** `functions/src/index.ts`, decision 013

### 2026-08-26T04:40:55Z Encoded identifiers can still collide at the filesystem boundary

- **Status:** promoted
- **Scope:** UID-derived local filenames on mobile filesystems
- **Observed:** Base64url preserves case distinctions, but common filesystems may not. Distinct Firebase UIDs whose encoded keys differ only by case can therefore resolve to one path.
- **Evidence:** The regression pair produces distinct lowercase SHA-256 keys, the known vector fixes digest behavior, and the file test proves active legacy migration to the bounded hash path.
- **Learning:** Storage identity must match the comparison semantics of the storage layer. Use a fixed lowercase digest rather than a case-sensitive reversible encoding when filenames may be case-insensitive.
- **Applied control:** Saved Songbook paths use SHA-256 of UTF-8 UID bytes and active-UID-only lazy legacy migration; decision 014 records the choice.
- **Revisit when:** Local state moves to an account-namespaced database or platform storage provides a stronger keyed identity primitive.
- **Related:** `lib/data/repositories/songbook_storage.dart`, decision 014

### 2026-08-25T21:22:57Z Authentication cannot be the retry token for account deletion

- **Status:** promoted
- **Scope:** Destructive workflows that remove the identity or authority needed to invoke them
- **Observed:** The synchronous deletion callable could remove interactions and Firebase Auth before its final profile cleanup. If execution then failed, the user had no durable phase and no longer had the authentication required to retry.
- **Evidence:** The old eleven-stage source order reproduced the authority gap. New failure-injection tests prove the job survives a failed batch, Auth deletion followed by failed finalization, duplicate delivery, and a missing Auth user. The next invocation resumes from stored server phase without client participation.
- **Learning:** A destructive workflow must persist its recovery authority and cursor before it destroys the caller's authority. Idempotent steps are necessary, but they do not replace a durable progress record and bounded retry ownership.
- **Applied control:** `deleteAccount` creates `accountDeletionJobs/{uid}` and the pending marker transactionally; `onAccountDeletionJobWritten` owns bounded retry through final profile-and-job deletion; decision 011 preserves the boundary.
- **Revisit when:** A shared workflow service replaces the Firestore cursor, legal policy changes retained content, or operational data shows a need for dead-letter handling and an operator recovery console.
- **Related:** `functions/src/account_deletion.ts`, `docs/decisions/011-durable-account-deletion-recovery.md`

### 2026-08-25T19:29:54Z Post-write triggers cannot enforce an admission budget

- **Status:** promoted
- **Scope:** Abuse controls for Firestore documents that cause storage, moderation, audit, counter, or Function work when created
- **Observed:** Deterministic report IDs stopped one account from reporting the same target twice, and report triggers converged counters, but a raw authenticated client could still create reports across many targets or random-ID feedback without a velocity bound. A trigger can delete or react only after the write and its downstream work have already been admitted.
- **Evidence:** The rule and client inspection reproduced all four direct create paths. The implemented Function tests now prove atomic accepted-row and budget writes, rejected non-consumption, deterministic duplicate preservation, anchored limits, and callback retry. The rules suite proves all direct creates are denied and passes 132 assertions.
- **Learning:** If the product must reject a write before it consumes a shared budget, validation, budget read, budget increment, and accepted document creation must share one server-authoritative transaction. Post-write repair is for convergence, not admission.
- **Applied control:** `submitReport` and `submitFeedback` use one private `safetyRateLimits/{uid}` row; direct client creates are denied; decision 010 preserves the boundary.
- **Revisit when:** Firestore transaction contention is measured, a distributed rate service replaces the per-user row, or a write no longer causes meaningful abuse or operational load.
- **Related:** `functions/src/safety_submission.ts`, `firestore.rules`, `docs/decisions/010-server-authoritative-safety-intake.md`

### 2026-08-25T10:25:44Z Rule-valid public writes must fit the shipped parser

- **Status:** promoted
- **Scope:** Firestore collections written directly by clients and deserialized by typed application models
- **Observed:** Field-level value checks still allowed unknown or wrongly typed data outside the form path. A permitted raw write could therefore pass rules and fail a public Dart query mapper. Owners could also mutate Function reconciliation stamps that the UI treats as server confirmation.
- **Evidence:** The review's rule-to-parser ledger found unchecked chant hierarchy, nullable, media, and variations fields. The implemented hostile matrix denies malformed and unknown fields, forged `appliedValue`, timestamp abuse, wrong Team and Player relationships, report reasons, and feedback types; all 131 Java-backed assertions pass.
- **Learning:** Authorization includes stored shape, not only writer identity. Every direct-write collection needs an exact parser-compatible schema, and server-owned bookkeeping must be absent from create plus immutable from client update.
- **Applied control:** `firestore.rules` now uses collection-specific exact shapes and bounds. Vote and like repositories create intent once and then change only `value`. Decision 009 makes rule and model parity a durable contract.
- **Revisit when:** A collection moves entirely behind a server API, or a new client field is approved with its parser, rule, abuse, and compatibility contract.
- **Related:** `firestore.rules`, `test_rules/firestore_rules.test.ts`, decision 009

### 2026-08-25T10:25:44Z Readable fallback is not live action authority

- **Status:** promoted
- **Scope:** Public content screens that retain route or stream data through connectivity failure while exposing local or external side effects
- **Observed:** Discover restored its initial card for every document-stream error, including a Firebase permission denial. Route `initialData` then made live-target controls available before a current visible document had been confirmed.
- **Evidence:** Review probes reproduced the stale moderated Discover card. The production regression tests now separate Firebase-shaped permission denial from transient failure, preserve Firestore cache provenance, exercise the Discover-to-detail route, and prove Save, Share, Report, Vote, and Comment remain unavailable until a server-confirmed current visible chant arrives.
- **Learning:** Stale public text may be safe and useful to read, but it cannot authorize a save, report, vote, comment, or external share. Classify authoritative revocation separately from ordinary transport failure and derive actions only from current visible state.
- **Applied control:** `ChantRepository.chantStream` retains `isFromCache`; `_LiveChantCard` and `ChantDetailScreen` keep cached text readable while gating every live-target action through one server-confirmed authority predicate. Decision 015 preserves the cache boundary.
- **Revisit when:** An approved offline mutation queue defines its own target version and revocation semantics, or a shared live-availability abstraction replaces these widget-local controls.
- **Related:** `lib/presentation/browse/discovery_section.dart`, `lib/presentation/browse/chant_detail_screen.dart`, decisions 009 and 015

### 2026-08-25T00:41:42Z Native verification can mutate project scaffolding before it fails

- **Status:** applied
- **Scope:** Flutter native build checks on an inherited iOS project whose dependency manager or lifecycle template predates the current Flutter tool
- **Observed:** `flutter build ios --simulator --debug --no-codesign` began CocoaPods-to-SwiftPM and UIScene project migrations before Xcode failed inside inherited Cloud Firestore sources. The failed verification left tracked project files changed and generated package-resolution files present.
- **Evidence:** The post-build diff showed changes to AppFrameworkInfo, AppDelegate, Info.plist, the Xcode project and scheme, a collapsed Podfile lock, and two generated SwiftPM resolution files even though no native migration was approved.
- **Learning:** A native compile command is not necessarily read-only. Treat the platform tree and lockfiles as possible outputs, inspect them after every attempt, and separate intentional plugin registration from tool-driven template migration.
- **Applied control:** The share block restored every tracked iOS file exactly to branch HEAD, removed the generated SwiftPM files, and records native compilation as blocked rather than accepting unrelated migration work.
- **Revisit when:** The iOS dependency-manager and UIScene migrations receive their own approved change, or the Flutter tool provides a verified no-migration compilation mode.
- **Related:** `docs/changes/2026-08-24-basic-share-out.md`

### 2026-08-22T19:38:09Z Queue-time identity checks prevent stale-account local writes

- **Status:** applied
- **Scope:** Device-local repositories whose asynchronous operations are scoped to the currently authenticated account
- **Observed:** A screen-level UID gate prevents normal cross-account navigation, but an operation queued before an auth transition can begin after the active account changes unless the persistence boundary checks again.
- **Evidence:** The repository access test saves under UID A, switches the guard to UID B, and proves both a later load and a queued mutation for UID A fail while UID A's bytes remain unchanged. The mismatched-route widget test also proves UID A's titles do not render for UID B.
- **Learning:** Identity must be revalidated at the durable operation boundary, not inferred only from the screen that initiated work. UI gates explain access; repository guards enforce it when asynchronous work actually starts.
- **Applied control:** Production `SavedSongbookRepository` receives an auth-backed access guard, checks every load and queued mutation at execution time, and keeps account-deletion cleanup inside its already-authorized serialized operation.
- **Revisit when:** Saved state moves to a server-authorized store or a shared local database with a stronger transaction-scoped identity primitive.
- **Related:** `lib/data/repositories/saved_songbook_repository.dart`, `lib/app/providers.dart`, decision 003

### 2026-08-22T16:57:38Z Recoverable stream errors need retained route state

- **Status:** applied
- **Scope:** Flutter screens that promise to keep previously usable live data visible through a later stream error
- **Observed:** A `StreamBuilder` error snapshot is not a durable store for the last successful payload. Treating `snapshot.data` as retained would turn a reconnect failure into a full-screen error even after the fan had readable chants.
- **Evidence:** The Player-route retained-data widget test first receives a usable chant snapshot and then a stream error. Deliberately clearing the retained snapshot in the error handler made the test fail because the chant disappeared. Restoring the retained route state made the focused and full Flutter suites pass.
- **Learning:** When stale data is explicitly more useful than an error replacement, own the last successful payload and the current error independently. Show a full error only before any usable payload has arrived.
- **Applied control:** Team and Player routes own one stream subscription each, retain the last `ChantBrowseSnapshot`, clear the error on fresh data, and render `LAST LOADED CHANTS` supporting copy after a later error.
- **Revisit when:** A shared asynchronous state abstraction provides the same tested data-plus-error semantics without adding duplicate subscriptions or hiding cache provenance.
- **Related:** `lib/presentation/browse/team_screen.dart`, `lib/presentation/browse/player_screen.dart`, `test/presentation/browse/player_screen_test.dart`

### 2026-08-22T12:45:35Z Long validated forms must retain every field

- **Status:** applied
- **Scope:** Flutter forms whose controls extend beyond one viewport
- **Observed:** The submit form used a lazy `ListView`. When the origin control scrolled out of the retained child range, its `FormField` could be disposed, so whole-form validation no longer represented every visible step in the draft.
- **Evidence:** The origin-required submit widget test and the 390 by 844 submission golden exercise the offscreen origin and submit controls in one retained form.
- **Learning:** A form that must validate all fields at once cannot rely on lazily disposed descendants unless their state is retained explicitly. Use a retained child structure for bounded forms, or give each lazy field durable state and an independently verified validation contract.
- **Applied control:** `SubmitChantScreen` uses one `SingleChildScrollView` with a retained `Column`; the focused test proves a missing offscreen origin stops both duplicate lookup and create.
- **Revisit when:** The submission form grows enough that retaining the full bounded form causes measured performance or memory problems.
- **Related:** `lib/presentation/submit/submit_chant_screen.dart`, `test/presentation/submit/submit_chant_screen_test.dart`

### 2026-08-22T01:01:47Z Cross-platform goldens need a bounded visual threshold

- **Status:** promoted
- **Scope:** Flutter widget goldens generated on one operating system and verified on another
- **Observed:** The reply and operator-control goldens passed on macOS with Flutter 3.44.8 but failed on Ubuntu with Flutter 3.47.1 at 1.02% and 0.49% pixel difference. Later text-heavy full-screen Songbook and Chant Lab goldens differed by 2.09% and 1.94%. The Saved Songbook detail differed by 2.25%, and the chant-detail share screen by 1.85%, on the same platform pair while their non-visual tests passed.
- **Evidence:** Draft PR 4 workflow run `32541324140`, draft PR 7 workflow run `32587305522`, draft PR 8 workflow run `32594555589`, draft PR 9 workflow run `32794917851`, and the focused local comparator test.
- **Learning:** Exact pixels are too strict across renderers, but removing visual checks would hide real regressions. Use a documented, measured tolerance with a known-bad test that proves the boundary still rejects material changes.
- **Applied control:** `test/helpers/tolerant_golden_file_comparator.dart` keeps a 1.5% default. The measured share-detail test opts into 1.9%, the full-screen browse test into 2.2%, and the Saved Songbook test into 2.3%, while the comparator test proves a small synthetic difference passes and a fully changed image fails.
- **2026-08-31 follow-up:** Four Call-Ups/main-club images exceeded their existing threshold on Ubuntu Flutter 3.47.2. Run `33362066687` retained the actual and difference PNGs, which showed glyph/curve-edge variation with matching content/layout. Those four tests now select inspected, checksummed Linux references alongside the existing macOS references, without increasing any tolerance. Independent viewport cases and failure-only artifact retention preserve diagnosis; `test/presentation/browse/goldens/linux/README.md` owns provenance.
- **Revisit when:** A pinned renderer or platform-specific baselines make exact comparison stable, or observed benign drift approaches a test's measured boundary.
- **Related:** `.github/workflows/ci.yml`

### 2026-08-22T00:00:35Z Seed content must come from authoritative supplied sources

- **Status:** promoted
- **Scope:** `seed/` and `seed_data/`
- **Observed:** Regenerating Arsenal seed content from non-authoritative material produced a stale squad and unverified chants presented as real data.
- **Evidence:** The incident and cleanup are retained in `docs/BLOCK_RECAPS.md`; seed validation and the current externally verified workflow are described in `docs/IMPLEMENTATION_RATIONALE.md`.
- **Learning:** Transform supplied seed data in place. Never generate or rewrite squads, lyrics, or cultural claims from model memory.
- **Applied control:** Highest-priority rule in `AGENTS.md`, historical decision in `docs/DECISIONS.md`, and seed validation tests.
- **Revisit when:** Never for the source-integrity requirement. The accepted authoritative-source format may change through a new decision.
- **Related:** `docs/DECISIONS.md`, `seed/validate.ts`

### 2026-08-22T00:00:35Z Server-owned fields must be constrained on create

- **Status:** promoted
- **Scope:** Firestore authorization rules
- **Observed:** Update restrictions alone allowed a crafted create to set privileged or server-owned fields, including a profile role.
- **Evidence:** The 2026-05-25 field-pinning decision is retained in `docs/DECISIONS.md`, and the negative boundary is covered by the Firestore rules suite and `docs/IMPLEMENTATION_RATIONALE.md`.
- **Learning:** Pin or reject every privileged and derived field at document creation as well as update.
- **Applied control:** `firestore.rules` create rules and negative assertions in `test_rules/firestore_rules.test.ts`.
- **Revisit when:** A write moves behind a server-only boundary that makes the direct-client create path impossible.
- **Related:** `docs/IMPLEMENTATION_RATIONALE.md`

### 2026-08-22T00:00:35Z Timing-sensitive UI regressions need a real-widget guard

- **Status:** promoted
- **Scope:** Flutter state reconciled from live streams
- **Observed:** A unit test encoded vote snap-back as the expected result while the real control was visibly wrong. A widget test on the production control failed when the fix was deliberately reverted.
- **Evidence:** Red-green verification is retained in `docs/DECISIONS.md` and the current vote and reply widget tests.
- **Learning:** For stream timing, optimistic state, and rendering order, test the real widget boundary and prove the guard can fail against the regression.
- **Applied control:** `test/presentation/shared/vote_controls_widget_test.dart` and `test/presentation/comments/comment_reply_golden_test.dart`.
- **Revisit when:** A higher-fidelity integration test replaces the widget as the smallest reliable boundary.
- **Related:** `docs/IMPLEMENTATION_RATIONALE.md`

### 2026-08-22T00:00:35Z Title-derived document IDs make renames destructive

- **Status:** promoted
- **Scope:** Chant identity and seed reconciliation
- **Observed:** Renaming a chant created a new document and left the title-derived old document orphaned.
- **Evidence:** The pre-framework orphan-on-rename control is retained in `docs/BLOCK_RECAPS.md`, and the stable-ID remediation boundary is recorded in `docs/WISHLIST.md` and `docs/ROADMAP.md`.
- **Learning:** User-visible mutable text is not a stable identity. Move to non-title-derived IDs before engagement data makes rename cleanup risky.
- **Applied control:** Seeded chants now require explicit immutable IDs. Preflight and transaction-time checks reject unsafe ownership or team collisions, and decision 005 preserves the contract.
- **Revisit when:** A verified production collision requires migration, or public identity moves away from the Firestore document ID.
- **Related:** `docs/decisions/005-explicit-seeded-chant-identity.md`
