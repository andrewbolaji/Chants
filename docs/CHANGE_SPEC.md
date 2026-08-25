# Change spec: V1 basic share-out

**Status:** Implemented and locally verified; clean-runner CI, native compilation, review, and device walk pending
**Updated:** 2026-08-24
**Risk lane:** Lane 2, user-triggered external platform side effect and future public-link contract
**Stack base:** Draft PR 8, `codex/v1-saved-matchday-songbook`

This is the one active implementation specification on the stacked basic share-out branch. It replaces the completed Saved Matchday Songbook plan only on this branch. Decision 004 and the product spec already place basic share-out in V1, but they do not approve this technical plan.

## Outcome

- **Problem:** A fan can find, learn, save, and discuss a chant, but cannot send it through Messages, WhatsApp, X, email, or another installed app. Chants also has no live public chant route, so sharing a guessed `chantsfc.com` URL would create a dead destination.
- **Desired behavior:** Live chant detail has one accessible Share action. It opens the operating system share sheet with useful plain text containing the current chant's title, optional known club name, full main lyrics, tune, and honest trust wording. A verified public chant URL may be appended later, but an absent or invalid URL always produces a complete text-only share instead of a broken link.
- **Non-goals:** Direct posting to X, TikTok, Instagram, WhatsApp, or any other service; platform SDK integrations; link previews; universal links; Android App Links; iOS Universal Links; website work; Firebase Dynamic Links; generated cards; images, files, audio, or video; clipboard controls; share counts or analytics; notifications; background work; sharing comments, evidence, context notes, variations, scores, creator identity, or reports; sharing from the read-only Saved Matchday Songbook; Firestore, rules, Functions, indexes, seed, Firebase access, deployment, merge, or release.
- **Review boundary:** One pure share-payload builder, one narrow native-share gateway, one provider, one live chant-detail action, one runtime dependency, focused tests, one representative visual, and current framework records.

## Acceptance criteria and invariants

1. Live chant detail shows a Share action between the existing matchday bookmark and report actions. Its tooltip and screen-reader label are `Share this chant`.
2. One tap opens the platform share sheet with exactly one plain-text payload. While that invocation is outstanding, repeated taps cannot open another sheet.
3. The payload uses the current chant rendered by the detail stream, not the route's older snapshot when a newer visible value has arrived.
4. The text-only payload has this order: title, optional known club name, full main lyrics, `Tune: <tune name>`, one trust line, optional public link, and `Shared from Chants`. Sections use blank lines. Leading and trailing whitespace is removed and CRLF input is normalized to LF without rewriting words.
5. Trust wording is derived only from existing status and origin values: canonical is `Terrace Proven`; community Already sung is `Chant Lab: Already sung, not yet Terrace Proven`; community original is `Chant Lab: Original idea`; legacy community with no origin is `Chant Lab: Community chant`.
6. A team name is included only when the current route already knows it. Sharing never performs a team, player, chant, profile, or other network read to enrich the payload.
7. The payload never includes `createdBy`, evidence URL, media URL, cover URL, context notes, variations, scores, vote counts, comment counts, comments, reports, flags, hidden state, removed state, or authentication identity.
8. No URL is emitted in current builds because no public chant resolver exists. The payload builder accepts an optional already-validated HTTPS public URL so a later approved website or deep-link block can add one without changing the share-sheet boundary. A missing or rejected URL leaves the text share fully useful.
9. The system share result never creates a delivery claim. Dismissed, success, and result-unavailable outcomes return silently because the plugin cannot prove that a recipient received anything. An invocation exception leaves chant detail usable and shows `Could not open sharing. Try again.`
10. The action passes the laid-out button's non-zero global rectangle as `sharePositionOrigin`, which the package requires for safe iPad presentation. If a valid rectangle cannot be resolved, no platform call occurs and the same recoverable error appears.
11. A hidden or removed current chant cannot start a share. Existing visible content behavior and Firestore enforcement remain the authority for whether live detail is reachable.
12. The action is a normal operating-system handoff. It does not request contacts, account, photo, storage, tracking, or social-platform permissions, and does not send content to Chants infrastructure.
13. At 390 by 844 and enlarged text, bookmark, Share, and Report remain reachable with comfortable tap targets and no clipped or overlapping app-bar action.
14. Existing live detail reading, provenance, evidence, save, vote, report, and comment behavior remains unchanged outside the Share action.
15. No backend, public web route, persistent data, analytics event, or production configuration changes in this block.

Invariants:

- The native share sheet is an external user-controlled destination boundary. Chants supplies plain text and never claims control over the receiving app, delivery, retention, or later redistribution.
- Votes remain popularity signals, evidence remains verification material, and the share payload never upgrades a community chant's trust status.
- Stable chant IDs remain the future public-link identity. Mutable titles are never proposed as URL identity.
- Saved Matchday Songbook remains read-only and without a share action under decision 003.
- No production or staging read, write, deployment, dashboard change, merge, or release is authorized by this specification.

## Design

### Pure payload contract

Add a small immutable request or payload value and a pure builder under `lib/data/services/`. The builder accepts a `Chant`, optional known team name, and optional already-validated public URL. It returns the share title, email subject, and text without reading Firebase, providers, platform state, or the filesystem.

The plain-text shape is:

```text
<chant title>
<known team name, omitted when unavailable>

<full main lyrics>

Tune: <tune name>
<trust line>

<public URL, omitted in current builds>

Shared from Chants
```

The optional team line does not leave an extra blank section when absent. The builder normalizes line endings and trims field boundaries, but preserves internal lyric lines and wording. It does not truncate the current 5,000-character lyrics boundary or add variations, because the fallback must remain a usable rendition of the main chant.

The optional URL is an input, not a resolver owned by this block. It is appended only when its scheme is HTTPS and it has a non-empty host. Current production wiring passes no URL. A later public-route change must define the host, stable path, hidden or removed behavior, metadata, app or web fallback, and live smoke gate before enabling links.

### Native share boundary

Add `share_plus: ^11.1.0`, published by `fluttercommunity.dev` under BSD-3-Clause. Version 11.1.0 supports the current Flutter, Dart, iOS, Java, Android Gradle Plugin, and Gradle versions and exposes `SharePlus.instance.share(ShareParams(...))`. The current latest major requires Android Gradle Plugin 8.12.1, while the repository tracks 8.11.1 and has unrelated user changes in the same settings file. This block does not expand into an Android build-tool upgrade.

Use one narrow gateway because the platform invocation is an external side effect that widget tests must replace. Production passes text, title, subject, and the button's `sharePositionOrigin` to `SharePlus`. The gateway treats every returned `ShareResultStatus` as a completed handoff and lets invocation exceptions reach the screen boundary for one user-facing translation. It adds no retry because a retry could open a second share sheet after an ambiguous platform outcome.

The dependency owner is Flutter Community. Update within the compatible major through normal dependency maintenance. Removal means deleting the detail action, provider, gateway, and package; no data or server cleanup exists.

### Chant-detail interaction

The Share icon sits in the live detail app bar between Save for matchday and Report. A `Builder` or equivalent button-local context supplies the laid-out render rectangle. The screen owns one `_sharing` flag, disables the action until the platform future settles, and reads the current `live` chant already selected by the stream builder.

The action needs no sign-in branch beyond the app's existing signed-in shell, no network loading state, and no success snackbar. A thrown platform error shows the bounded failure copy and preserves every current screen state. The screen does not log the payload, target application, result identifier, user identity, or error contents.

### Alternatives rejected

- `url_launcher` alone: it can open a specific URL or application scheme but cannot present the general native share sheet already required by the product contract.
- Hand-written Android intents and iOS activity controllers: duplicates maintained platform code and creates a larger native compatibility and test surface than one established plugin.
- Latest `share_plus` plus an Android Gradle upgrade: expands a small product feature into build-tool work and overlaps unrelated user edits. Revisit as separate dependency maintenance.
- A guessed `https://chantsfc.com/chants/<id>` link: the route does not exist, so the recipient would reach a dead destination.
- Share only a title or promotional sentence: the text fallback would be an advertisement instead of a useful chant.
- Share images or generated lyric cards: creates rendering, temporary-file, accessibility, platform compatibility, and brand-preview work already deferred to v1.1.
- Direct social-platform integrations: adds accounts, SDKs, permissions, platform review, tracking, and service-specific failure modes without improving the basic user job.

## Failure and abuse analysis

| Condition | Expected behavior | Evidence |
|---|---|---|
| Share tapped twice quickly | Only the first native call starts; the action stays disabled until completion | Widget test with deferred fake gateway |
| Share sheet dismissed | No success or failure claim appears; detail remains unchanged | Gateway and widget test |
| Platform reports result unavailable | Treat as a completed handoff, not a failure or delivery proof | Gateway test |
| Platform invocation throws | One recoverable snackbar appears; no crash, retry, or lost detail state | Throwing-gateway widget test |
| Button origin is absent, zero, or outside its render box | No platform call; show the recoverable failure | Geometry helper and widget test |
| Chant stream updates after route open | Payload contains the newer rendered title, lyrics, tune, and trust state | Stream-driven widget test |
| Chant is hidden or removed in current data | Share action is disabled or absent and the gateway is not called | Negative widget test |
| Team route did not provide a Team | Payload omits the team line without a placeholder or extra blank section | Pure builder test |
| Community chant is popular | Payload still says Chant Lab and never Terrace Proven unless status is canonical | Pure provenance matrix test |
| User-controlled text contains CRLF, URLs, or markup-like characters | It remains plain text; line endings normalize and no value is executed or interpreted by Chants | Hostile-text unit test |
| Optional URL is missing or invalid | Complete text-only payload is shared with no dead or malformed link | Pure builder test |
| Receiving app mishandles or retains text | Chants makes no delivery, deletion, privacy, or compatibility claim about third-party behavior | Interface copy and device walk |

## Performance and cost

- **Workload:** One user-triggered payload per tap. Current model limits bound title and tune to 200 characters each and main lyrics to 5,000 characters.
- **Client cost:** One linear string construction and one platform-channel call. No network, database, filesystem, image encoding, or background work.
- **Budget:** Payload construction stays synchronous and allocation-bounded by the existing chant limits. Duplicate taps create one outstanding call at most. Native sheet presentation latency belongs to the operating system and is not described as Chants latency.
- **Server and financial cost:** Zero Chants reads, writes, functions, storage, analytics, scheduled work, or paid API calls.
- **Measurement:** Unit-test the maximum accepted text boundary and inspect that one gateway call receives the expected bounded payload. No timing gate is justified for a roughly 5 KiB string.

## Rollout and recovery

- **Order:** Stack after draft PR 8. Merge only after the preceding stack, automated checks, independent review, native compilation, and the combined device walk.
- **Compatibility:** The package adds normal Android and iOS plugin registration. It changes no persisted or remote data. Current builds remain text-only.
- **Device gate:** On authorized iPhone and Android devices, open one Terrace Proven and one Chant Lab detail, inspect the sheet, send to a test Messages or Notes destination, dismiss once, and verify a second tap works. On iPad or an iPad simulator, verify the sheet anchors without a crash or frozen interface.
- **Public-link gate:** No URL is enabled in this block. A later change may supply one only after the exact HTTPS route resolves for a visible stable chant ID and has honest hidden, removed, unknown, web, and app-not-installed behavior.
- **Healthy signals:** One sheet per tap, correct full text and provenance, no dead URL, no detail-state loss, no crash, and no false success message after dismissal.
- **Rollback:** Remove the Share action, provider, gateway, payload builder, and `share_plus` dependency. No migration, cleanup, compensating server action, or user-data recovery is needed.
- **Owner:** Andrew authorizes review, merge, release, public-route activation, deployment, and any live-device or external-destination test. Codex implements and verifies repository changes only.

## Verification plan

| Claim | Check | Expected evidence |
|---|---|---|
| Payload is useful and bounded | Pure builder tests for canonical, both community origins, legacy origin, absent team, CRLF, hostile text, maximum field lengths, and optional URL | Exact title, lyrics, tune, trust, optional URL, and footer with no excluded data |
| URL fallback is honest | Missing, HTTP, hostless, and valid HTTPS cases | Invalid or absent URL produces complete text only; valid supplied URL is appended once |
| Native dependency is isolated | Gateway unit test using the package platform test seam or a fake gateway | Parameters include text, title, subject, and non-zero origin; returned statuses create no delivery claim |
| Repeated taps are bounded | Deferred-gateway widget test | Two rapid taps produce one invocation; action re-enables after completion |
| Current stream data is shared | Stream-driven ChantDetailScreen test | Captured payload uses the post-route stream value |
| Failure is recoverable | Throwing-gateway and invalid-origin widget tests | Screen remains readable and shows `Could not open sharing. Try again.` |
| Hidden and removed data do not share | Negative widget tests | Gateway call count remains zero |
| Interface holds at launch viewport | 390 by 844 chant-detail golden and enlarged-text widget test | Save, Share, Report, trust, title, and lyrics remain reachable without clipping or overflow |
| Plugin compiles for supported clients | Android debug build and iOS simulator build before release | Native registration compiles without changing the current Android Gradle or iOS deployment settings |
| Existing app remains green | `flutter test`, `flutter analyze lib test`, Functions, seed, rules TypeScript, and clean-runner CI | All touched and repository gates pass |
| New behavior has a real red guard | Temporarily prevent the gateway call or remove lyrics from the payload | Focused widget or builder test fails for the intended reason, then passes after restoration |
| Diff stays inside the contract | Compare against `codex/v1-saved-matchday-songbook`, run `git diff --check`, project-memory checks, writing-style check, and inspect dependency diff | Only approved share, detail, dependency, test, visual, and framework paths; user Android and unrelated lockfile changes remain outside the commit |

## Approval

**Approved.** Andrew explicitly approved this exact basic share-out specification on 2026-08-24. Repository implementation and local or clean-runner verification are authorized within this boundary. Approval does not authorize Firebase access, a public website route, deep-link configuration, analytics, deployment, merge, release, or production observation.

## Open decisions

None. The accepted product contract already chooses the native share sheet, live chant detail, and honest text fallback. This specification selects the exact payload, trust wording, dependency compatibility boundary, failure behavior, iPad geometry control, and verification evidence.
