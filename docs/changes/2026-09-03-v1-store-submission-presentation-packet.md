# V1 store submission presentation packet

## Status

Implemented from PR 34 exact green head `b952389e20b7c510f204f5cbbeb87af70b4c2574` and corrected after independent review in PR 35. The screenshot storyboard retains owner visual acceptance. Andrew approved the corrected canonical Google feature graphic PNG on 7 September 2026. Final capture, console entry, submission, and release remain separate.

## Why this change exists

Chants had a launch command center and public policy source, but it did not have one canonical, validated handoff for Apple and Google. Copy spread across chat or launch notes can drift from the app, exceed a store limit, imply disabled features, omit SDK data, or be paired with stale screenshots. This block turns the actual V1 behavior into one owner-facing packet without touching a store or production.

## What changed

- Added `docs/STORE_SUBMISSION_PACKET.md` with copy-paste Apple and Google metadata, categories, public URLs, reviewer instructions, asset requirements, forbidden claims, and a final evidence-gated prerequisite checklist.
- Added `docs/STORE_PRIVACY_WORKSHEET.md` covering account data, public user content, 30-second video and recorded voice, interactions, diagnostics, identifiers, App Check, deletion, and provider-dependent reopen conditions.
- Added `store/submission.json` as the machine-readable copy and readiness authority.
- Added `store/screenshots/manifest.json`, a capture runbook, and a reusable exact-size presentation frame for five truthful scenes on each platform. A missing release-candidate source remains visibly unpublishable.
- Derived `store/assets/google-play-icon.png` deterministically from the current 1024 no-alpha App Store icon as a 512 by 512 alpha-bearing Play asset with a conservative visible-mark safe zone.
- Added a 1024 by 500 RGB Google feature graphic with a deterministic renderer and hash-bound PNG.
- **Superseded first candidate:** Used one Nunito promise and overlapping Stage plus Club Signal product surfaces after removing the split-poster layout, giant supporter mark, and repeated loud display treatment.
- **Superseded second candidate:** Used a full-bleed Stage and Club Signal composition with a chorus waveform, one Fraunces lyric phrase, and a matchday strip.
- Made a bare `frame.html` open a useful five-scene storyboard with exact iOS and Android links. Exact frame routes now reserve most of the canvas for the real release capture and show a quiet, explicit hold state until that source exists.
- Added a store validator and meaningful known-good and known-bad tests, then wired both into project governance CI.
- Rejected the old 1320 by 2663 documentation captures as pre-redesign and outside the 1320 by 2868 iPhone target.
- Pointed the launch command center and roadmap to this packet instead of introducing another parallel store checklist.
- Moved System, Light, and Dark appearance to the first V1.1 presentation fast follow, after the V1 release candidate and screenshots are locked.
- Corrected the native Apple V1 boundary to iPhone only and pinned a complete adaptive iPad release block for V1.1.
- Bound the source baseline, intentional native drift, store assets, future release artifacts, source captures, and framed outputs to exact commits or SHA-256 digests.
- Added decoded-pixel screenshot inspection so a correctly sized solid hold image cannot pass as store evidence.
- Reconciled the privacy worksheet with the linked Meta SDK while keeping the unconfigured Facebook entry point honest.
- Standardized the prepared metadata on US English, version 1.0.0 (1), the five-destination route order, and the actual Create review path.

## Decisions and tradeoffs

### Prepared is not submitted

The metadata is useful now, but every readiness field begins false. A status string alone cannot make the packet ready. `ready_for_submission` requires merged release source, open-production walkthrough, live trust routes and support, review access, distribution artifacts, both screenshot sets, Google feature graphic, privacy and rating forms, and console metadata evidence.

### Sports first, social second

Apple uses Sports as primary and Social Networking as secondary. Google uses Sports. This reflects the product's main job, learning and using football chants, while honestly acknowledging Stage and creator interaction.

### Conservative privacy mapping

The privacy worksheet includes infrastructure and SDK collection, not just form fields. Crash and diagnostic linkage, IP-derived location treatment, and Firebase processor status stay explicit exact-binary checks instead of being guessed. Disabled providers are conditional and cannot silently expand launch disclosure.

### Five product jobs, not ten near-duplicates

The screenshot plan uses Stage, Clubs, chant detail, Create, and Songbook. Each scene has a different purpose and a visible-truth list. No count, affiliation, rights-sensitive asset, or availability claim may be fabricated for presentation.

### One expressive promise, then product proof

The final feature-graphic direction removes the rejected split panels, cards, route grid, waveform, echo effect, and competing typographic voices. One Anton statement, one Space Mono product line, and the established supporter mark make the matchday purpose legible at thumbnail size. It uses no fake phone, crest, badge, metric, testimonial, glow, card stack, or generic decorative gradient. Its renderer now emits the declared sRGB colors, binds every input, and reproduces identical bytes. The preview displays the canonical PNG directly. The screenshot system uses thin rules, open space, and narrow mode-colored rails around the actual release capture rather than filling the frame with poster styling.

## Adversarial review

The validator covers the mistakes most likely to survive a hurried console session: over-limit text, wrong operator or app identity, changed age rule, locale, version, market list, or device family, off-domain or insecure trust routes, false ready status, missing scene inventory, repeated paths, stale hashes, unbound source drift, missing capture files, placeholder-like image content, wrong dimensions, unsafe icon extent, and incorrect alpha behavior. It validates assets whenever they exist. Separate approved asset and renderer digests prevent changed feature-graphic evidence from retaining owner acceptance, and the HTML contract prevents a second preview composition from drifting away from the PNG. The capture guide and frame also treat debug UI, personal data, maintenance messages, fake engagement, disabled providers, missing sources, and source changes as rejection conditions.

## Evidence

- `node scripts/check-store-submission.mjs`: passes in `prepared_not_submitted` state.
- `node --test scripts/test-store-submission.mjs`: 19 tests pass, including known-bad limits, identity, locale, version, device support, URLs, baseline ancestry, hashes, stale approval, cleared approval, readiness, direct and production-file placeholder rejection, capture evidence, alpha, safe-zone, explicit-sRGB feature-graphic pixels, canonical preview parity, frame-contract, and legacy-size cases.
- Exact-size browser QA after the visual correction: all five scenes pass at 1320 by 2868 iOS and 1080 by 1920 Android with no horizontal or vertical overflow; every absent source displays the unpublishable warning.
- Bare-storyboard browser QA: five scenes and ten platform links render without horizontal overflow at 390 CSS pixels and as one editorial planning view on desktop.
- App Store icon source: 1024 by 1024 RGB PNG, no alpha.
- Derived Google Play icon: 512 by 512 RGBA PNG with alpha, below 1 MiB, visible mark inside the 192-pixel radius guard.
- Final Google feature graphic: 1024 by 500 explicit-sRGB PNG, no alpha, below 15 MiB, with exact PNG, preview, renderer, font, and supporter-mark input digests. Deterministic macOS re-rendering is byte-identical. Andrew approved the canonical PNG on 7 September 2026, and separate approved asset and renderer digests match current evidence.
- Final local verification passes: all 539 Flutter tests; scoped Flutter analysis; the packet validator and all 19 focused regressions; project memory; governance regressions; native-project, launch-service, and iOS startup contracts; all 11 startup regressions; the 37 device-readiness, guide, policy, and public-landing regressions; writing style; and whitespace.

## Remaining gates

The release candidate must be merged, opened and walked. All public routes and support delivery must work signed out. A dedicated reviewer account and exact distribution artifacts must pass. Ten real screenshots still require capture and owner visual acceptance. Apple App Privacy, Google Data safety, both store rating questionnaires, console metadata, and store previews must be entered and read back. Store submission needs separate owner authority.
