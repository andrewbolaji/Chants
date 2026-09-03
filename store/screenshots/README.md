# Chants FC store screenshot capture

The manifest in this directory is the authority for scenes, captions, paths, sizes, and status. Final images must come from the exact submitted release candidate after production is open and the owner walkthrough passes.

## Before capture

1. Confirm the exact Git SHA and release configuration.
2. Use a dedicated clean account with no personal email, phone number, moderation role, draft text, or private report visible.
3. Prepare truthful content with real counts. Do not invent likes, views, comments, followers, ratings, or testimonials.
4. Use only original or cleared chant text and supporter-created media. Do not show broadcast footage, club crests, player photos, copyrighted album art, or another app.
5. Remove the Flutter debug banner and any Instagram or X return affordance.
6. Confirm production is open and every pictured control works.
7. Set the device clock, battery, network, text size, and appearance to an intentional, consistent state.
8. Capture the app itself, not a camera photo of a device.

## iOS set

Use the connected iPhone's native 1320 by 2868 portrait screenshots. Keep PNG output and no alpha.

1. `ios/01-stage.png`: Stage feed with one approved performance, creator identity, chant context, honest trust label and counts, plus the five labelled destinations.
2. `ios/02-clubs.png`: Club Signal with Premier League scope, search or browse, and no unsupported marks.
3. `ios/03-chant.png`: Readable chant detail with origin or provenance label, context, and Save.
4. `ios/04-create.png`: Creation choice showing Already sung and I made this, with evidence clearly optional.
5. `ios/05-songbook.png`: Saved Matchday Songbook with real saved content and honest device-local wording.

## Android set

Capture the same five scenes from the exact Android release candidate at 1080 by 1920 portrait. The scene meaning must match iOS, but the image must show the real Android interface rather than an iPhone crop.

## Presentation frame

`frame.html` is the reusable presentation source for both platform sets. Opening it without query values shows a compact five-scene storyboard with links and capture status. That storyboard is a planning view, not a store image. Each linked exact-size frame adds only the scene headline, short deck, sequence number, and Chants FC line around an unmodified release-candidate screenshot.

1. Put the clean source captures in `source/ios/` and `source/android/` using the exact five manifest filenames.
2. Open `frame.html?platform=ios&scene=01-stage` or `frame.html?platform=android&scene=01-stage` through a local static server. Change only the platform and scene query values for the other nine outputs.
3. Render the full page at 1320 by 2868 for iOS or 1080 by 1920 for Android.
4. Save outputs to the final `ios/` and `android/` paths in the manifest.
5. Reject any output that shows `Final app capture pending.` or `Do not publish this frame`.

The frame must not crop away product truth, cover a required control, retouch app content, combine platforms, or make a development state look released. If a caption no longer describes the exact candidate, correct the manifest and frame before rendering.

## Reject a capture if

- any pixel shows a debug ribbon, external-app return label, permission sheet, keyboard, snackbar error, maintenance message, loading stall, or clipped text;
- a name, count, date, evidence label, save state, or moderation state is fabricated;
- a disabled sign-in provider or V1.1 feature is visible;
- text is unreadable at store-preview scale;
- a modal or sticky action hides the product job;
- the image is not the manifest size, contains alpha, or uses the wrong platform;
- the source SHA or release configuration changed after capture.

The existing `docs/screenshots/*.png` files are product-development evidence. They are 1320 by 2663, predate the final redesign, and are not valid for this store set.

## After capture

1. Open all ten images at full size and at a narrow store-preview width.
2. Run `node scripts/check-store-submission.mjs`.
3. Change only the corresponding manifest statuses from `pending_capture` to `captured`.
4. Set the platform screenshot readiness field in `store/submission.json` only when all five images for that platform pass.
5. If the release source, appearance, content, navigation, or trust wording changes, return affected scenes to `pending_capture` and recapture them.
