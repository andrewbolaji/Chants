# Creator entry polish

## Outcome

The words-first and performance entry paths now use a calmer, clearer mobile form hierarchy. The player list is searchable and dismissible without a selection, lyrics retain useful writing room without forcing a verse model, and club crests cannot paint outside their assigned list-row bounds.

The Perform a Chant screen now distinguishes the public posting handle in a bordered identity chip. iOS also skips the Android-only lost-picker-data recovery call, so an untouched screen no longer reports an interrupted video selection. An active transfer now becomes a blocking in-place task instead of a quiet inline bar, making it clear that the app must stay open until the upload or private review handoff finishes. Cancellation immediately changes that surface to a separate confirming state, so a slow server acknowledgement never looks like an ignored tap. The final independent review also closed the admission and final-handoff cancellation races, preserved the cancel action for screen readers, removed the inert app-bar back action during an operation, and added written permission recovery.

## Interface changes

- Gave chant title, lyrics, tune, context, and evidence fields external labels and compact field typography.
- Kept lyrics as one flexible five-to-ten-line field, with a simple instruction to put each sung line on a new line.
- Replaced the full-screen player dropdown with a 78-percent-height searchable sheet, an explicit Close action, and a selected-player check.
- Separated the player field label from its value and retained written stale-player recovery.
- Added a bounded crest viewport, asset clipping, and slightly taller club rows.
- Rendered `POSTING AS` as quiet metadata and the public `@handle` as a clear, bordered identity chip.
- Reduced the performance caption to the calm Nunito UI role with an external label.
- Limited lost-data recovery to Android, matching the image-picker platform contract.
- Replaced inline upload progress with a centered, scrim-backed panel that names the upload and review-queue phases, shows determinate progress when available, blocks route back navigation, keeps cancellation explicit, and repeats that nothing is public before approval.
- Made cancellation its own blocking, indeterminate phase with `CANCELLING UPLOAD` and `CONFIRMING CANCELLATION`; retry, replacement, back navigation, and duplicate cancellation stay unavailable until acknowledgement.
- Treats a cancellation requested before draft admission completes as pending intent. Once the exact draft arrives, the client cancels that draft and never starts the media transfer.
- Removes cancellation once transfer completes and the private review handoff begins, preventing a submit-versus-cancel race from reporting the wrong terminal state.
- Keeps the real Cancel button in the accessibility tree while limiting live-region semantics to changing status copy.
- Removes the visible app-bar back action for the complete upload and cancellation operation, rather than leaving an inert control.
- Maps camera and media-library permission denial to written Settings guidance and names the alternate picker.
- Pads the searchable player sheet above the active keyboard so the final result remains reachable.
- Gives the selected onboarding destination a gold outline and stronger type weight, in addition to surface tone.

## Evidence

- Added selector regressions for supported and unsupported lost-data recovery.
- Added player search, close-without-selection, lyric typography, and sung-line cue regressions.
- Added and inspected a 390 by 844 Perform a Chant golden.
- Added and inspected a separate 390 by 844 active-upload golden at 42 percent progress.
- Regenerated and inspected the three Add a Chant references and the Clubs directory reference.
- Focused media, submission, competition, and crest set: 29 tests passed.
- Focused corrected Flutter set: 43 tests passed, including admission cancellation before a ticket exists, failed admission during cancellation, no cancellation action during final review handoff, accessible active-upload cancellation, written permission recovery, keyboard-safe player selection, and a non-color-only onboarding destination.
- Scoped `flutter analyze --no-pub lib test`: no issues.
- Complete Flutter suite: 563 tests passed.
- The strict Linux chant-detail reference was regenerated with Flutter 3.47.2 inside the documented Linux container, inspected, and passed its exact golden comparison. Its SHA-256 is `3de74f47f98bdef1b0bbff260ed43de20006f78f99b895d026d96199173120ee`.

## Operational boundary

Production remains independently closed at schema 1, generation 35, mode `maintenance`, with destructive workers false by the previously recorded receipt. One successful canary draft and its matching object remain private in `pending_review`, no active upload grant remains, and no performance is public. This correction phase did not read or change production, deploy backend source, moderate the canary, publish content, mutate Hosting or DNS, upload a store binary, request store review, release, commit, push, or merge. The prior installed-iPhone observations came from an older build. Fresh local Android and iOS release artifacts now carry the corrected source, but no physical-phone or store-installed proof is claimed for them.
