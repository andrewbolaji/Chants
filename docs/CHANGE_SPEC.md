# Change spec: V1 Saved Matchday Songbook

**Status:** Proposed, exact technical approval required before runtime implementation
**Updated:** 2026-08-22
**Risk lane:** Lane 2, device-local persistent state, account identity isolation, deletion lifecycle, and material offline UI
**Stack base:** Draft PR 7, `codex/v1-songbook-chant-lab`

This is the one active implementation specification on the stacked Saved Matchday Songbook branch. It replaces the completed browse specification only on this branch. Andrew approved the product boundary in decision 003 and selected this as the next v1 block. Product approval does not approve the technical storage and lifecycle contract below.

## Outcome

- **Problem:** Chants is most useful shortly before or during a match, when stadium connectivity is unreliable. Firestore's incidental device cache cannot make a clear or testable promise that a fan's chosen lyrics will survive an airplane-mode relaunch. The app also has no explicit place to collect matchday material.
- **Desired behavior:** A signed-in fan can save one currently visible chant or a club's current Terrace Proven Songbook to this device, open the saved lyrics after an airplane-mode relaunch, refresh a complete snapshot when the server is available, and remove it locally. The interface always states when a copy was refreshed and never presents saved counters or conversation as live.
- **Non-goals:** Cross-device sync, cloud favorites, background refresh, push or match reminders, offline audio or video, hosted media, offline voting, comments, reports, evidence links, creator profiles, analytics, a generic favorites system, Firestore schema or rules changes, Cloud Functions changes, seed changes, live Firebase access, deployment, or release.
- **Review boundary:** One versioned mobile file store, saved-snapshot models and repository, server refresh orchestration over existing visible team queries, account-deletion cleanup, Saved Songbook navigation and screens, save and refresh controls on Team Songbook and chant detail, focused persistence and UI tests, representative goldens, and current framework records.

## Acceptance criteria and invariants

1. Only a currently authenticated Firebase UID can open or mutate its own local snapshot. Every operation requires that UID explicitly, and storage for a different UID is never loaded into the current user's state.
2. An individual save is available for any currently server-visible canonical or community chant. A club save contains only the club's currently server-visible `status == canonical` Songbook, in deterministic Songbook order.
3. A first save or refresh requires a successful server-visible result. Cache-only or retained-after-error browse data remains readable but cannot be stamped as freshly saved. Removing local data never requires a network connection.
4. The saved overview loads the local snapshot before making any network request and remains navigable after the repository and widgets are reconstructed with Firebase reads unavailable. The release walk must prove an actual airplane-mode process relaunch on a supported device.
5. Each persisted chant contains only the public, bounded data needed for honest offline reading: chant ID, team ID, optional player ID, subject tag, title, lyrics, tune name, optional context notes, variations, `status`, optional origin, and source creation and update timestamps. It excludes scores, vote counts, comment counts, comments, reports, flags, creator ID, evidence URL, cover URL, media URL, audio, and video.
6. Each persisted team identity contains only ID, sport ID, competition ID, and name. Each individual or club record stores UTC save and refresh timestamps. The UI displays a clear last-refreshed date without claiming continuous freshness.
7. Saving a chant individually and through a club preserves both save intents but renders that chant only once in the overview. Removing the club reveals any still-individual save. Removing the individual save does not remove a copy still owned by a saved club.
8. A club refresh replaces that club's complete canonical list in one successful local commit. Chants no longer visible or no longer canonical are removed. A successful targeted refresh reconciles that chant ID across every local source: replace visible canonical copies, remove a visible community chant from club lists while updating any individual save, or remove a no-longer-visible ID everywhere.
9. A failed server refresh, failed serialization, oversized result, or failed file replacement leaves the last complete file and in-memory snapshot unchanged. The UI says refresh failed and that the saved copy is still available.
10. Concurrent local mutations for one process are serialized in call order. State is emitted only after the corresponding file replacement succeeds, so the visible state never gets ahead of durable state.
11. The file format has schema version 1. An unsupported future version is never overwritten by an older client. Malformed or oversized files fail closed into a recoverable local-storage error and are not silently treated as an empty Songbook.
12. The persisted payload is capped at 2 MiB per UID and 500 unique chant IDs. A write over either limit is rejected before replacing the prior snapshot.
13. Signing out leaves that UID's local snapshot for a later sign-in on the same device. A successful account deletion removes the UID's active local snapshot. Another account on the device cannot see it before, during, or after deletion cleanup.
14. Offline saved detail is explicitly read-only. It shows lyrics, tune, context, variations, club identity, trust or origin wording, and snapshot age, but no vote, comment, report, evidence, media, or share action.
15. Home exposes one obvious `MATCHDAY SONGBOOK` entry. Team Songbook exposes `SAVE FOR MATCHDAY` or `REFRESH SAVED COPY`; chant detail exposes an accessible save state. Empty, busy, saved, cache-only, refresh-error, corrupt, unsupported-version, and remove-confirmation states use text as well as icons or color.
16. At 390 by 844 and enlarged text, the home entry, saved overview, club snapshot, saved detail, save controls, dates, errors, and destructive confirmation remain readable without overflow or clipped tap targets.
17. No Firestore collection, field, index, security rule, Cloud Function, seed record, remote configuration, production data, or analytics event changes in this block.

Invariants:

- Firestore remains the source of current visibility and Terrace Proven status. The local file is a user-requested, timestamped reading snapshot, never a moderation or authorization source.
- A saved stale copy can exist while the device is offline. The interface discloses its timestamp and never calls it current without a successful server refresh.
- Public chant text is stored locally, but account isolation and deletion are still enforced as product privacy promises.
- Existing live Team, Player, Chant Lab, voting, comments, reporting, evidence, and submission behavior remains unchanged outside the explicit save controls.
- No production or staging read, write, deployment, dashboard change, merge, or release is authorized by this specification.

## Storage and data contract

### Versioned envelope

The repository stores one UTF-8 JSON file per Firebase UID under the platform application-support directory. The filename uses unpadded base64url encoding of the UID, not a raw path component. The root shape is:

```text
schemaVersion: 1
clubSnapshots: teamId -> SavedClubSongbook
individualSnapshots: chantId -> SavedIndividualChant
```

`SavedClubSongbook` stores the team identity, `savedAt`, `refreshedAt`, and an ordered list of saved chant snapshots. `SavedIndividualChant` stores the team identity, `savedAt`, `refreshedAt`, and one saved chant snapshot. Timestamps are encoded as UTC ISO-8601 strings and decoded strictly. Map keys must match the embedded IDs.

The repository validates the whole payload before exposing it. Wrong types, missing required fields, duplicate chant IDs inside one club snapshot, invalid status or origin values, mismatched keys, a future schema version, more than 500 unique chants, or more than 2 MiB are errors. Unknown additive fields in schema version 1 are ignored so a compatible patch release can add optional metadata without breaking old readers.

### Atomic persistence

The local store obtains `getApplicationSupportDirectory()` from Flutter's `path_provider` package. For every mutation it:

1. loads or uses the last validated snapshot for the exact UID;
2. computes and validates a complete replacement in memory;
3. writes the complete JSON to a same-directory temporary file with `flush: true`;
4. renames the temporary file over the active file;
5. emits the new immutable state only after replacement completes.

Mutations are serialized by one repository-owned future chain. A failed temporary write or rename deletes only the temporary artifact when possible and preserves the active file. Tests inject read, write, and replacement failures through a small `SongbookStorage` boundary. Production has one filesystem implementation; the boundary exists for deterministic persistence and fault tests, not speculative storage switching.

### Dependency decision

Add direct dependency `path_provider: ^2.1.6`, published by `flutter.dev` under BSD-3-Clause, solely to resolve the application-support directory on supported iOS and Android versions. Dart `File` APIs perform the actual JSON reads and atomic replacement.

Rejected alternatives:

- `shared_preferences`: its maintained documentation says writes are asynchronous without a persistence guarantee and the store is not designed for larger data. That does not support the explicit relaunch promise.
- Firestore offline cache: it is incidental, not user-selected, UID-lifecycle owned, or explainable as a complete snapshot.
- SQLite, Hive, Isar, or another database: v1 stores one bounded document per UID and needs no query engine. A database adds schema, native, update, and migration surface without buying required behavior.
- Platform-specific hand-written directory lookup: duplicates a maintained Flutter plugin and increases native test surface.

The package owner is the Flutter toolchain owner. Update it with normal Flutter dependency maintenance. Removal means replacing the directory provider, reading the versioned JSON once, and preserving the same repository contract.

## Server refresh and deduplication contract

### Visible source reads

Add a one-shot server method to `ChantRepository` that reuses the current visible team query predicates (`teamId`, `hidden == false`, `removed == false`) with `Source.server`. It returns a complete team result or throws. It introduces no new query shape or index.

- Club save from Team Songbook can use the current route snapshot only when `isFromCache == false` and no recoverable chant error is active.
- Club refresh from Saved Songbook fetches the complete visible team result from the server, projects only canonical chants, applies the existing deterministic Songbook order, strips live-only fields, then atomically replaces the club snapshot.
- Individual save or refresh fetches the complete visible result for that chant's team and selects the stable chant ID. A visible canonical result replaces the same ID wherever stored. A visible community result is removed from club lists and retained only when there is individual save intent. A missing ID in a successful result is removed everywhere. A failed fetch is not treated as removal.
- Team identity is passed from Team or Discovery when already known. Otherwise it is resolved through `TeamRepository` before a first individual save. A failed identity lookup prevents the first save. Refresh retains the last team identity if the chant result succeeds but the team metadata read fails.

The service that joins server reads to local mutations remains separate from the pure file repository. This keeps the repository usable and testable without Firebase and prevents a partial remote result from entering the local file.

### Ownership and one-render rule

Club and individual records remain separate because they represent different removal intent. A pure projection builds the overview:

1. render saved clubs first, in team-name then team-ID order;
2. collect every chant ID embedded by those club records;
3. render only individual records whose chant ID is not already represented by a club;
4. retain the hidden individual record so it reappears if the covering club is removed.

No score is persisted. A club snapshot keeps the deterministic server-side Songbook order calculated at refresh time. Individual items order by most recent `refreshedAt`, then chant ID.

## Account lifecycle contract

Sign-out does not mutate local files. Every saved provider and screen keys state by the current UID and is disposed when auth changes.

The account-deletion service captures the UID and atomically renames any active local file to a UID-scoped deletion tombstone before invoking the existing callable. This works without decoding the file, so corrupt local state cannot block account deletion cleanup. If the rename fails, the callable is not invoked. If the callable fails, the service renames the exact tombstone bytes back to the active path and reports the existing account-deletion failure. If the callable succeeds, no active snapshot remains and the tombstone is deleted. A failed restore reports possible local-save loss with the callable error as the primary cause. A failed final tombstone deletion can never make the data readable by another UID and is retried during the next repository initialization. The deletion confirmation copy adds Saved Matchday Songbook to the data removed from this device.

This orchestration is implemented in a small account-deletion service rather than duplicated in the Home widget. The service owns only ordering and compensation between the existing callable and the local repository. It does not change server deletion semantics.

## Interface and interaction design

### Home and entry

- Add one signed-in home card below search and before the competition entry: `MATCHDAY SONGBOOK`, supporting copy `Saved on this device, ready when the signal drops`, a bookmark icon, and a chevron.
- The card opens the local overview immediately. It never waits for a Firestore query.
- The empty overview says `PACK YOUR MATCHDAY SONGBOOK` and offers `FIND A CLUB`, returning to the normal club browse journey.

### Team Songbook

- Place one full-width matchday control after the Songbook introduction and before the chant sections.
- Unsaved plus fresh server data: `SAVE FOR MATCHDAY`.
- Saved plus fresh server data: `REFRESH SAVED COPY`, with last-refreshed supporting text.
- Cache-only, retained-error, empty, or in-flight data: keep the control visible but disabled and explain `Connect for a fresh copy`. An existing saved copy remains openable from Matchday Songbook.
- Successful save or refresh confirms the chant count. Failure states that the previous saved copy is still available.
- Removal lives in the Saved Songbook club view behind a confirmation dialog, avoiding an easy destructive toggle on the live club screen.

### Live chant detail

- Add a bookmark action with explicit tooltip and semantics: `Save for matchday`, `Saved individually`, or `Saved with club`.
- Unsaved action performs a fresh visible-team read before saving. While busy, the control is disabled and announced as saving.
- If individually saved, the action can remove that individual intent after confirmation. If covered only by a club snapshot, it opens the saved club view rather than implying that one tap removes the club copy.
- A failed save or refresh leaves any prior state unchanged and names the safe next action.

### Saved overview and club view

- The overview app bar says `MATCHDAY SONGBOOK`. Intro copy says the material is saved on this device and shows that timestamps indicate freshness.
- Saved club cards show team name, number of chants, and last-refreshed date. Individually saved chants not covered by a club appear under `SAVED CHANTS`.
- A club view is entirely local on first render. It shows `LAST REFRESHED`, ordered saved chant cards, `REFRESH`, and `REMOVE FROM DEVICE`.
- Refresh is an explicit network action. A spinner disables duplicate taps. A failed refresh keeps every old lyric visible with `Could not refresh. Your saved copy is still here.`
- If a successful refresh yields no canonical chants, keep the club record with an honest empty state and current refresh timestamp until the user removes it.

### Saved chant detail

- Use a dedicated read-only route backed only by `SavedChantSnapshot`, not a fabricated live `Chant` and not a Firestore stream.
- Reuse extracted lyric, tune, context, variations, provenance wording, and layout components where their inputs stay honest.
- Show `SAVED COPY` and the refresh timestamp near the top. Omit live score, votes, comments, report, evidence, media, and creator actions completely.
- Refresh and removal are explicit controls. If the item is also in a saved club, removal copy explains that the club copy remains.

### Local storage errors

- First load shows a bounded progress state while reading the file.
- Missing file is the normal empty state.
- Malformed or oversized schema shows `SAVED COPY NEEDS ATTENTION`, preserves the file, and offers `RESET LOCAL COPY` behind destructive confirmation.
- A future schema version shows `UPDATE CHANTS TO OPEN THIS COPY`, with no reset or mutation from the older client.
- Do not claim the device is offline from a caught exception. Say only that fresh updates are unavailable.

## Failure and abuse analysis

| Condition | Expected behavior | Evidence |
|---|---|---|
| Same mutation is tapped twice | UI disables duplicate taps; serialized idempotent map replacement produces one record | Repository and widget tests |
| Two different local mutations overlap | They commit in call order and the later operation starts from the prior committed state | Deferred-storage concurrency test |
| Temporary write or rename fails | Old file and emitted state remain intact; temporary artifact is cleaned when possible | Fault-injected file-store test |
| Process is reconstructed without network | New repository instance reads the same UID file and local routes render without Firebase access | Temporary-directory integration test plus device walk |
| Cache-only Team data is visible | Live chants remain readable; save or refresh is disabled and no new freshness timestamp is written | Team widget test |
| Server refresh fails | Existing snapshot and timestamps remain unchanged; recoverable copy is shown | Service and widget tests |
| Successful club refresh omits hidden, removed, or demoted chant | Complete atomic replacement removes it | Refresh service test |
| Successful individual refresh returns canonical, community, or no target | Canonical replaces every copy; community leaves only individual intent; missing removes every copy; unrelated records remain | Refresh service test |
| Same chant has club and individual ownership | One overview entry renders; removal of one owner preserves the other | Pure projection and widget tests |
| Different UID signs in on the device | Only its encoded file is loaded; the first UID's titles and counts never appear | Negative identity-isolation integration test |
| Account deletion callable fails | Exact tombstone bytes are restored even when the payload is corrupt; account error remains visible | Account-deletion compensation test |
| Account deletion callable succeeds | No active UID file exists, a new repository load is empty, and tombstone cleanup completes or remains unreadable pending retry | Account-deletion integration test |
| JSON is malformed, wrong-shaped, too large, or schema is newer | It is never rendered as valid or overwritten; state distinguishes corrupt from unsupported | Codec and repository tests |
| Local file is manually altered | Strict validation rejects invalid IDs, enums, dates, and shape before UI exposure | Hostile-fixture tests |
| No canonical chants remain after club refresh | Club stays as a zero-item, freshly timestamped record until removal | Service and widget test |
| Large text or narrow viewport | Controls, dates, lyrics, dialogs, and empty/error copy remain usable | 390 by 844 goldens and enlarged-text test |

## Performance and cost

- **Workload:** V1 launches with 20 Premier League clubs and roughly five operator-seeded chants per club. The supported local ceiling is 500 unique chant IDs or 2 MiB for one UID, whichever arrives first.
- **Storage:** One active JSON file plus one transient replacement file per UID. No media bytes, indexes, WAL, database runtime, background job, or cloud storage.
- **Client budget:** Decode, validate, and project a 500-chant fixture in under 100 ms at p95 on the representative local test machine. Saved lists remain lazy. No filesystem work runs synchronously on the UI isolate.
- **Network cost:** Club save from a fresh Team route adds zero reads. A saved-screen club refresh reads one team document plus every currently visible chant for that team. An individual save or refresh uses the same bounded team-visible read so hidden content can be identified without weakening rules. There are no background reads.
- **Measurement:** Retain a deterministic 500-chant codec benchmark-style test and record elapsed time as diagnostic evidence without a noisy CI timing gate. Verify the 2 MiB rejection structurally.
- **Revisit trigger:** Move to SQLite or another indexed store only if snapshots exceed 500 chants or 2 MiB, measured decode exceeds 100 ms p95 on a representative supported device, partial updates become necessary, or offline media is approved.

## Rollout and recovery

- **Order:** Merge after draft PRs 4 through 7. No Firebase deployment or data migration exists. Release the client only after automated checks, independent PR review, and the combined device walk.
- **Compatibility:** Older clients ignore the new file. Schema version 1 readers accept their own known fields and ignore additive unknown fields. They refuse a future schema version rather than overwriting it. Sign-out preserves the file; app uninstall removes it according to platform behavior.
- **Canary:** On an authorized local or non-production iOS or Android device, save one community chant, one canonical chant, and one club; force-stop; enable airplane mode; relaunch; verify exact lyrics and UID isolation; reconnect; refresh after hiding or demoting a fixture in the authorized environment; then test removal and account-deletion cleanup.
- **Healthy signals:** Local routes open immediately, every expected lyric survives relaunch, no live controls appear offline, timestamps are honest, failed refresh retains the old copy, successful refresh removes stale content, and another UID sees an empty or its own Songbook.
- **Observation window:** Complete the scenario once on iOS and once on Android before release. No production analytics are added, so production health is assessed through feedback and crash reporting already in the app.
- **Rollback:** Revert the client entry points and repository provider. The versioned file can remain dormant for forward recovery. Do not delete it in a rollback build. If schema version 1 itself is faulty, ship a forward fix that can read or explicitly quarantine it.
- **Owner:** Andrew authorizes review, merge, device/environment access, release, and any live moderation fixture. Codex implements and verifies repository changes only.

## Verification plan

| Claim | Check | Expected evidence |
|---|---|---|
| Codec is strict and versioned | Focused model and hostile-fixture tests | Round trip succeeds; malformed, mismatched, oversized, invalid enum/date, and future version cases fail distinctly |
| Writes survive reconstruction | Repository integration test over a temporary directory | A second repository instance reads exact saved lyrics, timestamps, ownership, and ordering |
| Atomic failure preserves state | Fault-injected storage test | Failed write and replacement leave prior file bytes and emitted state unchanged |
| Mutations are serialized | Deferred-storage concurrency test | Completion and final state follow invocation order with no lost update |
| UID isolation is enforced | Two-UID temporary-directory test | Neither title, count, nor snapshot from UID A appears for UID B |
| Club and individual ownership dedupe correctly | Pure projection tests | One rendered ID, correct reveal after either owner is removed |
| Refresh honors server visibility | Refresh-service tests with fake complete team results | Hidden, removed, demoted, and missing targets leave no stale rendered copy after success; failures retain old copy |
| Account deletion clears safely | Account-deletion service tests | Success leaves no active file; callable failure restores exact bytes, including a corrupt fixture; cleanup retry never exposes a tombstone |
| Saved routes never initialize live social behavior | Widget tests with throwing Firebase repositories | Overview, club, and saved detail render while chant, vote, comment, report, and evidence boundaries are unavailable |
| Live entry controls are honest | Team and chant-detail widget tests | Fresh, cache-only, busy, saved-individual, saved-with-club, failure, and removal states match the contract |
| Interface holds at launch viewport | 390 by 844 overview, club, and saved-detail goldens plus enlarged-text test | Hierarchy, dates, offline wording, controls, and lyrics are readable without overflow |
| Package integrates on supported clients | Android debug build and iOS simulator build before release | `path_provider` plugin registration compiles without Android Gradle or iOS project edits |
| Existing app remains green | `flutter test`, `flutter analyze lib test`, Functions, seed, rules TypeScript, and clean-runner CI | All changed and untouched repository gates pass |
| New test proves the product promise | Temporarily bypass the file read or replace active-before-temp | Relaunch or atomic-failure test fails for the intended reason, then passes after restoration |
| Diff stays inside the contract | Compare against `codex/v1-songbook-chant-lab`, run `git diff --check`, project-memory checks, writing-style check, and inspect dependency diff | Only approved Flutter, dependency, test, and framework paths; no unrelated Android, backend, rules, index, seed, or Firebase config changes |
| Actual airplane-mode promise holds | Combined device walk after implementation | Force-stop and relaunch shows exact saved lyrics without connectivity on iOS and Android |

## Approval

**Proposed.** Replying with approval of this exact Saved Matchday Songbook specification authorizes repository implementation and local or clean-runner verification within this boundary. It does not authorize Firebase access, moderation fixture changes, deployment, merge, release, or production observation.

## Open decisions

None. Decision 003 already fixes device-local UID scope, individual and club snapshots, atomic refresh, deletion cleanup, and deferred cross-device sync. This contract selects the exact filesystem, schema, refresh, deduplication, lifecycle, interface, workload, and verification behavior required to implement it.
