# V1 basic share-out

**Completed in repository:** 2026-08-24
**Type:** Lane 2 external platform handoff and future public-link boundary
**Application behavior changed:** Live chant detail

## Change identity and boundary

- **Change:** Add one native text-share action that remains useful without a public chant route.
- **Target:** Stacked branch `codex/v1-basic-share-out`, based on Saved Matchday Songbook draft PR 8.
- **Included:** Pure payload construction, exact trust wording, optional validated HTTPS input, native share gateway, dependency injection seam, iPad source rectangle, duplicate-tap guard, recoverable invocation failure, hidden and removed guard, tests, one golden, one runtime dependency, and durable framework records.
- **Excluded:** Public website or deep-link routes, direct social SDKs, rich previews, files, images, audio, video, sharing from saved detail, analytics, Firebase, backend, rules, indexes, seed, deployment, merge, and release.
- **Approval:** Andrew explicitly approved the exact `docs/CHANGE_SPEC.md` contract before runtime implementation began on 2026-08-24.

## Outcome

- Live chant detail places `Share this chant` between Save and Report. The action is disabled while one native handoff is outstanding and for a current hidden or removed chant.
- The payload uses the current stream value and contains title, optional already-known team, full main lyrics, tune, honest trust wording, and `Shared from Chants` in a stable plain-text order.
- Canonical content says `Terrace Proven`. Community content remains explicitly Chant Lab and distinguishes Already sung, Original idea, and a legacy unknown origin without implying verification.
- Current production wiring supplies no URL. The pure builder accepts only an optional HTTPS URI with a non-empty host so a separately approved public-route change can reuse the handoff without guessing a dead destination.
- The gateway passes title, email subject, text, and the laid-out button rectangle to `share_plus`. Returned success, dismissal, and unavailable states create no delivery claim. An invocation exception shows one recoverable snackbar.
- No payload contains creator identity, scores, votes, comments, reports, evidence, media, context notes, variations, or authentication data.

## Invariants preserved

- Sharing does not alter chant trust, visibility, counters, saved state, or any backend data.
- Votes remain popularity signals, and evidence plus operator review remain the Terrace Proven boundary.
- Stable chant IDs remain the future public-link identity; mutable titles do not become URLs.
- Saved Matchday Songbook remains a read-only offline copy without live share behavior.
- Chants controls only the text passed to the operating system. It does not claim delivery, deletion, compatibility, or retention after the external handoff.

## Verification

- The focused share suite passed 16 tests covering exact payloads, every trust state, excluded data, CRLF normalization, maximum lyrics, absent team, valid and invalid URLs, gateway parameters and outcomes, source geometry, duplicate taps, current stream data, recoverable failure, hidden and removed content, semantics, and enlarged text.
- `flutter test`: 271 passed locally, including the new 390 by 844 golden.
- `flutter analyze lib test`: no issues.
- `cd functions && npm test`: 35 passed.
- `cd seed && npm test`: 42 passed.
- `cd test_rules && npm exec tsc -- --noEmit`: exit 0.
- The Java-backed Firestore emulator suite was not run locally because Java is unavailable. Rules and backend are untouched; clean-runner CI remains the independent emulator gate.
- Red check: temporarily omitting main lyrics from the production payload made the exact builder test fail on the missing lyrics. Restoring the approved payload made the same focused test pass.
- Visual evidence: `chant_detail_share.png` was generated at 390 by 844 and visually inspected. Save, Share, Report, provenance, title, lyrics, context, comments, composer, and voting remain legible without visible clipping. The detail action test also passes at 1.8x text.
- Android debug compilation was blocked before build because no Android SDK is configured locally.
- The iOS simulator build reached Xcode and failed in inherited Cloud Firestore 6.4.1 Swift Package sources with unavailable Objective-C initializers. Flutter's attempted CocoaPods-to-SwiftPM project migration was fully removed from the diff after the failure. Native compilation remains an explicit release gate.

## Security, privacy, abuse, and infrastructure impact

The feature performs one user-triggered local platform handoff and adds no permission, account connection, network read, database write, analytics event, background task, server cost, or hosted data. Plain text is bounded by existing chant model limits. The receiving application becomes an external data controller after the user chooses it.

The one new runtime dependency is `share_plus: ^11.1.0`, maintained by Flutter Community and used only for the operating-system share sheet. Version 11.1.0 fits the repository's tracked Android build tools. Newer package majors require an Android Gradle Plugin upgrade that is outside this block and overlaps user-owned changes.

## Rollout, rollback, and follow-up

Clean-runner CI, independent PR review, native compilation, and the combined device walk remain required before release. The walk covers one Terrace Proven chant, one community chant, send and dismiss outcomes, a second tap, Android and iPhone payload shape, and iPad anchoring. It must confirm that no URL is present.

Rollback is client-only: remove the detail action, provider, gateway, payload builder, and dependency. No data migration or server recovery exists. A future stable public route may supply one validated HTTPS URL only through a separately approved change with visible, hidden, removed, unknown, web-fallback, and app-not-installed behavior.
