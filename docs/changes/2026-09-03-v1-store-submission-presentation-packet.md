# V1 store submission presentation packet

## Status

Implemented locally from PR 34 exact green head `b952389e20b7c510f204f5cbbeb87af70b4c2574`. The corrected feature graphic and screenshot storyboard have owner visual acceptance. Packaging, independent review, exact-head CI, final capture, console entry, submission, and release remain separate.

## Why this change exists

Chants had a launch command center and public policy source, but it did not have one canonical, validated handoff for Apple and Google. Copy spread across chat or launch notes can drift from the app, exceed a store limit, imply disabled features, omit SDK data, or be paired with stale screenshots. This block turns the actual V1 behavior into one owner-facing packet without touching a store or production.

## What changed

- Added `docs/STORE_SUBMISSION_PACKET.md` with copy-paste Apple and Google metadata, categories, public URLs, reviewer instructions, asset requirements, forbidden claims, and a final ordered readiness sequence.
- Added `docs/STORE_PRIVACY_WORKSHEET.md` covering account data, public user content, 30-second video and recorded voice, interactions, diagnostics, identifiers, App Check, deletion, and provider-dependent reopen conditions.
- Added `store/submission.json` as the machine-readable copy and readiness authority.
- Added `store/screenshots/manifest.json`, a capture runbook, and a reusable exact-size presentation frame for five truthful scenes on each platform. A missing release-candidate source remains visibly unpublishable.
- Derived `store/assets/google-play-icon.png` deterministically from the current 1024 no-alpha App Store icon.
- Added a 1024 by 500 RGB Google feature graphic and reproducible HTML source using the current Stage and Club Signal identity. The final corrected asset has owner visual acceptance.
- Replaced the owner-rejected first graphic with one focused Nunito promise and overlapping Stage plus Club Signal product surfaces. Removed the split-poster layout, giant supporter mark, and repeated loud display treatment.
- Replaced the still-too-corporate second candidate with a full-bleed Stage and Club Signal composition. A chorus waveform and one Fraunces lyric phrase carry the expressive moment; the matchday strip keeps the three V1 jobs grounded without cards or a fake device.
- Made a bare `frame.html` open a useful five-scene storyboard with exact iOS and Android links. Exact frame routes now reserve most of the canvas for the real release capture and show a quiet, explicit hold state until that source exists.
- Added a store validator and eleven meaningful tests, then wired both into project governance CI.
- Rejected the old 1320 by 2663 documentation captures as pre-redesign and outside the 1320 by 2868 iPhone target.
- Pointed the launch command center and roadmap to this packet instead of introducing another parallel store checklist.
- Moved System, Light, and Dark appearance to the first V1.1 presentation fast follow, after the V1 release candidate and screenshots are locked.

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

The store creative follows the same two-speed interface as the release product. Nunito carries the setup and reading hierarchy, Fraunces is limited to the lyric-like `one voice.` phrase, and Oswald stays in compact signage. The feature graphic uses no fake phone, crest, badge, metric, testimonial, glow, card stack, or generic decorative gradient. The screenshot system uses thin rules, open space, and narrow mode-colored rails around the actual release capture rather than filling the frame with poster styling.

## Adversarial review

The validator covers the mistakes most likely to survive a hurried console session: over-limit text, wrong operator or app identity, changed age rule or market list, off-domain or insecure trust routes, false ready status, missing scene inventory, repeated paths, missing capture files, wrong dimensions, and alpha-bearing images. It validates the feature graphic whenever the candidate file exists, even while final approval remains false. The capture guide and frame also treat debug UI, personal data, maintenance messages, fake engagement, disabled providers, missing sources, and source changes as rejection conditions.

## Evidence

- `node scripts/check-store-submission.mjs`: passes in `prepared_not_submitted` state.
- `node --test scripts/test-store-submission.mjs`: eleven tests pass, including known-bad limits, identity, URLs, readiness, capture, alpha, feature-graphic, frame-contract, and legacy-size cases.
- Exact-size browser QA after the visual correction: all five scenes pass at 1320 by 2868 iOS and 1080 by 1920 Android with no horizontal or vertical overflow; every absent source displays the unpublishable warning.
- Bare-storyboard browser QA: five scenes and ten platform links render without horizontal overflow at 390 CSS pixels and as one editorial planning view on desktop.
- App Store icon source: 1024 by 1024 RGB PNG, no alpha.
- Derived Google Play icon: 512 by 512 RGB PNG, no alpha, below 1 MiB.
- Approved Google feature graphic: 1024 by 500 RGB PNG, no alpha, below 15 MiB.
- Final writing, memory, whitespace, and complete governance checks remain before handoff.

## Remaining gates

The release candidate must be merged, opened and walked. All public routes and support delivery must work signed out. A dedicated reviewer account and exact distribution artifacts must pass. Ten real screenshots still require capture and owner visual acceptance. Apple App Privacy, Google Data safety, both store rating questionnaires, console metadata, and store previews must be entered and read back. Store submission needs separate owner authority.
