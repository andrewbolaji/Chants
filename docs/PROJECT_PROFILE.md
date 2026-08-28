# Project profile

This is the compact source of truth to read before changing Chants. Detailed current-state reasoning remains in `ENGINEERING_OVERVIEW.md` and `docs/IMPLEMENTATION_RATIONALE.md`.

## Product and users

- **Name:** Chants
- **Purpose:** A mobile football songbook and creator stage where supporters learn Terrace Proven chants, build and rank new ideas in Chant Lab, and publish short performances around the chant itself.
- **Primary users:** Premier League supporters using iOS or Android at home, in transit, in pubs, and at crowded grounds with unreliable connectivity. The interface must remain understandable to first-time users and resilient to text scaling and assistive technology.
- **Failure cost:** Authority or privacy failure can expose restricted data or accept unsafe actions. Content corruption can publish inaccurate lyrics. Offline or lifecycle failure can strand saved matchday content. Ordinary presentation defects mainly cost trust, comprehension, and retention.
- **Non-goals for V1:** Beat-synced karaoke editing, licensed backing tracks, duet or remix tools, paid creator opportunities, fully personalized recommendations, cloud sync for Saved Matchday Songbook, automated large-scale media screening, and automated lyric generation. Public creator identity, short moderated performance video, follows, public destinations, mentions, and continued performance replies are implemented locally and remain subject to packaging, independent review, deployment configuration, and the release gates below.

## Architecture map

| Path or service | Responsibility | Source of truth | Owner |
|---|---|---|---|
| `lib/app/` | Flutter theme, routing, policy constants, and Riverpod composition | Yes for client composition | Andrew |
| `lib/data/` | Models, Firestore repositories, callable and platform services, ranking, matching, sharing, and device storage | Yes for client data behavior | Andrew |
| `lib/presentation/` | User-facing screens and shared widgets | Yes for shipped client interface | Andrew |
| `firestore.rules` and `firestore.indexes.json` | Client authorization, direct-write schemas, visibility, and query requirements | Yes for Firestore client access | Andrew |
| `functions/src/` | Server-owned admission, counters, moderation, account deletion, and audit behavior | Yes for server behavior in source | Andrew |
| `seed/` and `seed_data/` | Canonical seed validation, planning, stable identity, writes, and reconciliation | Yes for seed mechanics and reviewed JSON | Andrew |
| `.github/workflows/ci.yml` | Clean-runner automated verification | Yes for repository CI | Andrew |
| `docs/INTERFACE.md` | Current interaction and visual contract | Yes for UI decisions | Andrew |
| `docs/ROADMAP.md` | Product and release sequence | Yes for sequencing | Andrew |

## Critical journeys and invariants

| Journey or invariant | Why critical | Verification |
|---|---|---|
| Hidden, removed, or unauthorized content cannot remain actionable | Prevents moderation bypass and stale destructive targets | Firestore rules tests, repository tests, and current-live widget regressions |
| Songbook and Chant Lab never imply that votes prove a chant has been sung | Preserves archive trust while supporting creativity | Browse projection tests, team and player widget tests, and interface copy |
| A performance is popularity around a chant, never evidence that the chant is Terrace Proven | Preserves the difference between reach, community backing, and verified stadium use | Performance model, feed, moderation, ranking, and public-preview tests as each approved block lands |
| Public creator identity never exposes private account authority | Keeps handle, name, bio, and aggregates public while ban, age, policy, deletion, report, and email state remain private | Creator callable tests, hostile Firestore rules tests, public-profile model tests, and account-deletion finalization tests |
| Counters converge from stored child documents | Duplicate or reordered triggers must not drift visible totals | Functions overlap and duplicate-delivery tests |
| Comment hierarchy stays readable and acyclic | Legacy chant comments remain one-level. Performance replies may continue to depth 50 but never show more than three inline visual levels | Rules, server parser, focused-thread widget tests, mention fan-out tests, and moderation tests |
| Saved Matchday Songbook is UID-scoped, bounded, atomic, and locally readable | Prevents cross-account disclosure and supports poor stadium connectivity | Repository reconstruction, migration, widget, and deletion tests |
| Account deletion is durably accepted before local cleanup and fails closed when acknowledgement is unknown | Avoids false completion, lost local evidence, or a pending account regaining authority | Functions failure injection, rules tests, service tests, and app-gate tests |
| Seeded chant identity is explicit and stable across title edits | Prevents duplicate live documents and broken future links | Seed validation, plan, and identity tests; live read-only preflight still required |
| Lyrics, squads, tunes, and cultural context are externally sourced and manually verified | Generated or guessed terrace content would damage trust and may create legal or safety problems | Reviewed source documents, seed JSON review, and seed validation |
| Release UI remains usable at 390 by 844 and enlarged text | Core mobile journeys must not clip or hide their next action | Targeted goldens, widget tests, and final live-device walkthrough |

## Real commands

| Check | Command | Config or target | Expected artifact or evidence |
|---|---|---|---|
| Install Flutter dependencies | `flutter pub get` | Repository root | Resolved packages and `pubspec.lock` consistency |
| Full Flutter tests | `flutter test` | Repository root, no live Firebase required | Passing model, service, repository, widget, and golden suite |
| Scoped static analysis | `cp lib/firebase_options.dart.example lib/firebase_options.dart && flutter analyze lib test` | Repository root with deterministic non-secret fixture | No analyzer issues in project Dart source and tests |
| Functions tests | `npm ci && npm test` | `functions/`, Node 20 | TypeScript test build and Mocha results |
| Seed tests | `npm ci && npm test && npx tsc --noEmit` | `seed/`, Node 20 | Mocha results and TypeScript type check |
| Firestore and Storage rules | `npm ci` in `test_rules/`, then `firebase emulators:exec --only firestore,storage --project chants-f95b4 "cd test_rules && npm test"` from the repository root | Java, Node 20, Firebase emulator, configured project ID | Java-backed authority assertions and emulator exit status |
| Project-memory structure | `./scripts/check-project-memory.sh` | Repository root | Required memory files and agent references present |
| Project-memory handoff | `./scripts/check-project-memory.sh --staged` after staging, or `./scripts/check-project-memory.sh --range <base>` in CI | Repository root | Implementation changes include a `docs/EXECUTION.md` update in the same handoff or review range unless a confirmed Lane 0 run sets `PROJECT_MEMORY_LANE=0` |
| Writing style | `./scripts/check-writing-style.sh` after staging | Repository root and tracked Git index | No em dash in tracked Markdown, MDX, or text; scan errors fail closed |
| Governance regressions | `./scripts/test-project-governance.sh` | Repository root; also CI | Whitespace-safe memory classification, required execution evidence, index-scoped prose, and error propagation hold |
| Native project contract | `./scripts/check-native-project.sh` | Repository root; also CI | CocoaPods ownership pin, required native share pods, and absence of tracked Flutter SwiftPM state |
| Local debug run | `flutter devices`, then `flutter run -d <device-id>` | One booted simulator or connected device with local Firebase config | Installable debug client and interactive console |
| iOS simulator compile | `flutter build ios --simulator --debug --no-pub` | Project-pinned CocoaPods graph with ignored local Firebase config | `build/ios/iphonesimulator/Runner.app`; this is not distribution signing or a device walk |
| Build or package | Not yet canonicalized | Native release target | A signed distribution artifact is still a release gate |
| Dependency advisory scan | Not yet authorized or canonicalized | Flutter and three npm lockfile surfaces | Dated advisory output; absence of a run is not a safety claim |
| Infrastructure validate or plan | Not applicable as code today | No checked-in IaC | Firebase source configuration can be inspected, but deployed parity requires separately authorized access |

The project has proved the Flutter, Functions, seed, rules, analysis, and clean-runner gates can fail through prior red regressions and CI corrections recorded in `docs/EXECUTION.md` and `docs/changes/`. CI checks project-memory linkage across the pull request or push range. The manual staged gate checks the same contract before handoff. The writing check scans tracked index prose. Their regression harness proves whitespace classification, required execution evidence, forbidden prose, index scope, and scan-error behavior.

## Technology and infrastructure sources

| Surface | Authoritative manifest or config | Lock or deployed identity | Support or security source | Owner |
|---|---|---|---|---|
| Flutter and Dart | `pubspec.yaml` | `pubspec.lock`; Flutter 3.44.8 and Dart 3.12.2 are the verified native toolchain; CI follows movable stable | Flutter SDK and package registry release notes when an upgrade is proposed; no lower Flutter bound is claimed for `FlutterImplicitEngineDelegate` | Andrew |
| Firebase mobile SDKs | `pubspec.yaml`, `firebase.json` | `pubspec.lock`; project ID `chants-f95b4` in source config | Firebase and package advisories when reviewed | Andrew |
| Riverpod | `pubspec.yaml` | `pubspec.lock` | Package release notes when reviewed | Andrew |
| Cloud Functions | `functions/package.json`, `functions/tsconfig.json`, `firebase.json` | `functions/package-lock.json`; Node 20 | Firebase, Node, and npm advisories when reviewed | Andrew |
| Seed Admin client | `seed/package.json`, `seed/tsconfig.json` | `seed/package-lock.json` | Firebase Admin and npm advisories when reviewed | Andrew |
| Rules emulator | `test_rules/package.json`, `firebase.json` | `test_rules/package-lock.json`; CI pins Java 21 and firebase-tools 15 | Firebase emulator release notes when reviewed | Andrew |
| Android client | `android/` Gradle files | Gradle wrapper and plugin versions in source | Android and Flutter release guidance when reviewed | Andrew |
| iOS client | `ios/Podfile`, Xcode project, Flutter-generated configuration | iOS deployment target 15; local CocoaPods resolution | Apple and Flutter release guidance when reviewed | Andrew |
| GitHub Actions | `.github/workflows/ci.yml` | Checkout, Node setup, and Java setup v5 on the Node 24 action runtime | Action release and security advisories when changed | Andrew |

No version in this table is an instruction to upgrade. A change needs a compatibility, security, support, or measured product reason.

## Data and trust

- **Data classes:** Public chant, team, player, approved performance, approved performance-comment, and allowlisted creator identity data; private account authority, drafts, follow edges, notifications, per-user interactions, blocks, reports, feedback, local Songbook snapshots, handle reservations, safety budgets, deletion jobs, and operator audit data; restricted credentials and Admin access remain outside the repository.
- **Tenant or isolation model:** Chants is a single public community, not a multi-tenant product. User and operator isolation is enforced by Firebase Auth identity, Firestore rules, private collection rules, and callable authorization.
- **Authentication:** Firebase Auth email and password.
- **Authorization:** `firestore.rules` for client data access and Cloud Functions for callable and trigger-owned behavior. UI visibility is not an authority boundary.
- **Secrets:** Admin credentials and native Firebase configuration are not committed. Production secret storage and rotation are dashboard-owned and not verified from source.
- **Retention, deletion, and export:** Durable account deletion removes private interactions, anonymizes retained contributions, and redacts authored report data. Target-side safety history may retain an account identifier. No user export or repository-backed retention schedule exists.
- **External integrations:** Firebase Auth, Firestore, Storage, Functions, Hosting, App Check, and Crashlytics; operating-system camera or media library, video playback, and share sheet; allowlisted YouTube or X evidence links through the system browser. Timeout, retry, current-authority, and idempotency behavior is documented in the repository rationale and decisions.

## Reliability, scale, and cost

- **Availability or freshness target:** No formal service-level objective is defined. Live actions require current authority; saved reading is explicitly local and may be stale.
- **Latency budget:** No measured percentile budget is defined. User-visible writes use busy guards or recoverable states, and deletion uses bounded background pages.
- **Current or target workload:** Pre-launch. Seed target is a verified primer set for 20 Premier League clubs, with Arsenal currently the only club JSON in source.
- **Resource or cost budget:** Performance pages load at most ten records, video does not autoplay or prefetch, upload is capped at 30 seconds and 50 MiB, and signed media URLs expire after two minutes. No production Firebase budget is recorded. Billing alerts and staged-media cleanup are launch gates.
- **AI compute or context routing:** Not applicable to the shipped product. AI agents may support engineering, but generated lyrics, squads, tune claims, and cultural context are prohibited.
- **Telemetry and alerts:** Crashlytics is wired in source. App Check enforcement, dashboard parity, Function alerts, billing alerts, and deletion-job alerts are not verified.
- **Runbook:** `docs/RUNBOOK.md`

## Release and recovery

- **Environments:** Local and emulator are evidenced. One Firebase project ID is in source. No repository-defined staging environment exists, and deployed production parity is unverified.
- **Deployment path:** CI verifies and does not deploy. Firebase and store deployment require explicit authorization and an operator-owned release procedure.
- **Migration order:** Verify deployed baseline first. For the current authority model, compatible rules and Functions precede clients. Live seed writes require the read-only stable-identity preflight.
- **Feature flags or staging:** No general feature-flag system. `mergeChants` is stopped in runtime source before request parsing or mutation.
- **Healthy after deploy means:** Core signed-in and signed-out journeys work on representative iOS and Android devices, rules and Functions reject unauthorized cases, Crashlytics and Function errors stay within an explicitly chosen observation window, and no retained deletion job or counter drift is observed.
- **Rollback or forward recovery:** Redeploy a reviewed prior rules or Functions version when compatible, ship a corrected client, reconcile counters from stored documents, and reproduce seed state from reviewed JSON. Account deletion is forward-recovered by its durable worker. Merge has no approved recovery design and remains disabled.
- **Backup or restore evidence:** No checked-in backup, point-in-time recovery, or restore-exercise evidence. This is a release-readiness gap.

## Risk lane overrides

Default lanes come from the Codex Engineering Framework.

- **Lane 2 when:** A change touches authentication, authorization, moderation, reports, user blocking, account deletion, private data, seed identity, live writes, external media or evidence contracts, persistent schema, migrations, cross-service contracts, public routes, concurrency, or material performance and cost.
- **Lane 3 when:** A change performs an irreversible live migration, bulk destructive production action, signing or store release, safety-critical policy enforcement, or a high-blast-radius change without a tested recovery path.

## Known constraints and debt

| Item | Consequence | Owner | Revisit trigger |
|---|---|---|---|
| Android release uses debug signing | Store release is blocked | Andrew | Before the first production Android build |
| Current creator-platform Android compilation, iOS compile completion, and combined device walk are incomplete | Android SDK is absent locally. The iOS 12.18 dependency graph resolves, but the first Xcode compile was terminated after an extended silent wait | Andrew | Before creator-platform source freeze and V1 sign-off |
| App Check enforcement and operational alerts are unverified | Abuse and retained-job failures may be detected late | Andrew | Before public beta and during the first telemetry window |
| Content policy is placeholder copy | User consent and store compliance are incomplete | Andrew | Before public user submission |
| Domain association, store fallback, URL-signing IAM, Storage cleanup, and media billing alerts are unverified | Public links or media delivery may fail or cost more than expected in production | Andrew | Before emitting public links from a release build |
| Manual pre-publication video review has no measured service target | Uploads may wait indefinitely as volume grows | Andrew | Before public beta and when the first queue forms |
| Only Arsenal has reviewed seed JSON in source | Most clubs have no canonical live primer set | Andrew | As each club clears external lyric and context verification |
| No staging environment, backup restore evidence, or user export | Recovery and regulatory posture depend on manual Firebase operations | Andrew | Before public launch or when risk or user volume justifies it |
| Forty-one of 143 Dart files are not formatter-normalized after the readiness block's touched-file formatting | A repository-wide format gate would create unrelated churn | Andrew | Separate mechanical normalization block |
| `mergeChants` has no resumable recovery or privacy-safe legacy audit payload | Duplicate merge remains unavailable | Andrew | Before any proposed re-enable |
