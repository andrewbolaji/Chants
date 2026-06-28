# Chants Design Direction v2: Fanzine (terrace cut-and-paste)

## Spirit

The app should feel like a photocopied terrace fanzine and sticker-bombed
away end: hand-made, loud, funny, unmistakably football and fan-made, never
corporate.

Governing rule for the whole system: **LOUD FRAME, CALM WORDS.**

Personality lives on the chrome and no-reading-load surfaces (headers,
badges, eyebrows, vote stamps, empty states, splash, error/offline screens).
The surfaces that carry meaning (lyrics on the chant detail, the
browse/discover list, forms) stay clean, ordered, and highly legible.
Texture must earn its place; it is never applied to a reading surface.

---

## Palette (tuned from mockup review)

Text tokens have been softened off pure white. Pure white glares on bright
screens; this range stays AA-legible while comfortable for long reading.
Backgrounds and surfaces are unchanged.

| Role               | Value                              |
|--------------------|------------------------------------|
| Base background    | `#16140F` (warm charcoal)          |
| Surface 1          | `#1E1A14`                          |
| Surface 2          | `#231B11`                          |
| Title/headline     | `#E9E0CE` (warm off-white)         |
| Reading/body text  | `#D9CFBD`                          |
| Secondary/muted    | `#A1937D`                          |
| Faint              | `#6B5F4A` (decorative only, never body text) |
| Gold accent        | `#F2AE2E`                          |
| Gold bright        | `#FFC94D`                          |
| Gold-foil gradient | `#F2AE2E` to `#FFC94D` (verified mark) |
| Error              | `#EF6461`                          |

All contrast must meet WCAG AA on text.

---

## Type system (three voices, each with a strict job)

### DISPLAY / SHOUT: Anton

Heavy condensed, uppercase. Used for screen titles, chant titles, big
numbers, the splash. May carry a subtle 1.5px print-echo gold text-shadow
(not a heavy 3px offset, which creates a blurry double image) and a very
slight rotation (max 2 degrees) on headers only. Never used for body or
lyrics.

### ZINE VOICE: Space Mono

Monospace. Used ONLY for small chrome: tune lines, tags, eyebrows, captions,
context labels, vote-stamp numbers, metadata. Never used for lyrics or long
text (mono hurts long-form readability).

### READING FACE: Fraunces

A warm, characterful serif for all lyrics and any multi-line readable text.
More personality than Nunito while staying highly legible at body size on
dark backgrounds with generous line height. Lyrics are the hero: large, high
contrast, dead legible. This is the calm in "calm words."

### UI BODY (secondary): Nunito

Warm rounded sans, available for UI body text, secondary copy, and anywhere
a neutral readable sans fits. Not the lyrics face.

### Font implementation note

Bundled variable fonts must pin their weight axis with `FontVariation`
(the v1 lesson). `pubspec` weight alone does not set the `wght` axis. Every
`TextStyle` that uses a variable font must include:

```dart
fontVariations: [FontVariation('wght', 700)]
```

This applies to Anton, Fraunces, and Nunito. Failing to pin the axis
produces the wrong weight at runtime. Do not regress this.

---

## Texture map: where grit is ALLOWED vs BANNED

### ALLOWED (no reading load)

- App splash
- Screen headers
- Verified badge (stuck-on sticker, slight rotation, hard shadow)
- Vote control (stamped/stenciled block)
- Eyebrows and section labels
- Empty/loading/error/offline states
- A sparing accent scrawl (e.g. a hand-drawn number), at most once per
  screen
- Halftone dot texture as a faint background wash behind headers only, low
  opacity

### BANNED (reading surfaces)

- The lyric block on the chant detail
- The body of list/discover cards
- Any form field or input
- Any long text

No rotation, no halftone, no tape, no scrawl overlapping text a user must
read. List rows stay aligned and orderly.

---

## Component specs

The design block implements each of these. Specs describe intent and
constraints; the build determines exact sizing and spacing.

### Verified badge

Gold sticker, uppercase, slight rotate, hard offset shadow, optional dark
border. Community chants show no badge.

### Vote control

A stamped/stenciled block with mono numbers and up/down arrows. Must support
an immediate optimistic state change on tap (ties to the known upvote
issue in `docs/KNOWN_ISSUES.md`). Highlighted state when the user has voted.

### Chant cards (list/discover)

Warm surface, rounded corners, clear gaps, orderly layout. Left-aligned and
orderly (calm words). Card titles are smaller than screen titles so stacked
cards do not overwhelm.

Card anatomy, top to bottom:

- **Eyebrow:** tune name or "ORIGINAL TERRACE CHANT" in Space Mono
- **Verified sticker** (if verified; community chants show none)
- **Title:** Anton (smaller than screen-level titles)
- **Who-it-is-for line:** prominent gold. Club name for club chants; player
  name + club for player chants, with a small crest marker. This is the
  primary context signal.
- **Lyric preview:** one line in Fraunces (the reading face)
- **Vote count** in Space Mono

Remove the redundant CLUB/PLAYER subject tag from the footer when it merely
repeats the who-line. Keep a small gold PARODY flag where it adds real
signal (parody chants are a distinct category worth calling out).

Texture limited to a faint accent, never behind the preview text.

### Chant detail

This screen is the clearest test of "loud frame, calm words."

1. **Loud header zone:** Anton title with a subtle 1.5px print-echo shadow,
   sticker badge, mono tune line, optional faint halftone wash, and a single
   accent scrawl.
2. **Clean lyric block:** Fraunces (reading face), large and legible,
   **centered** (short chant lines suit it; it borrows the anthem feel).
   Long or uneven lyrics fall back to left-aligned so centered text never
   becomes hard to track. No texture, no rotation, no overlays.
3. **Context box:** mono label, readable body.
4. **Stamped vote control** at the bottom.

### Eyebrows / section headers

Examples: CLUB CHANTS, PLAYER CHANTS.

Space Mono, uppercase, letter-spaced, muted or gold.

### Loud surfaces (splash, empty states, error/offline)

These surfaces have no reading load and carry the app's personality at full
volume. Allow stronger halftone, stickers, stamps, tape, scrawls, rotated
elements, and loud gold sticker/stamp buttons.

Copy stays fan-voiced, witty, 9th-grade, no em dashes, and always clear.

- **Empty state:** a stamped mark, a big Anton headline, a nudge to add a
  chant.
- **Error/offline:** clear statement of what happened plus a try-again
  action.

This is where spirit lives so the cards can rest.

### Auth screens (sign up, sign in, password reset)

Headers get the Anton treatment. Inputs stay clean and legible (no texture
on fields).

Note the pending auth fixes to fold into the rebuild:

- Password confirm field (require the new password to be entered twice)
- Show-password toggle on entry fields

See `docs/KNOWN_ISSUES.md` for the full list.

---

## Screens in scope for the rebuild

Each must honor the texture map above.

1. Splash
2. Auth (sign up / sign in / password reset)
3. Home/discover (with the missing search entry point added)
4. Club page
5. Player list
6. Chant detail
7. Add-a-chant
8. Report sheet
9. Feedback
10. Moderation (operator)

---

## Out of scope / guardrails

- No logic changes introduced by the visual pass. Logic fixes from
  `KNOWN_ISSUES.md` are tracked separately but may be wired during the same
  screen rebuilds where noted.
- Hold AA contrast everywhere.
- 9th-grade copy level.
- No em dashes.

---

## Decisions finalized (mockup review, June 27)

These items were open questions; they are now locked.

1. **Reading face:** Fraunces. Confirmed over Nunito, Quicksand, Varela
   Round. Nunito stays available for UI body/secondary.
2. **Text range:** softened off pure white. Titles `#E9E0CE`, body
   `#D9CFBD`, muted `#A1937D`. Comfortable for long reading, still AA.
3. **Title shadow:** subtle 1.5px print echo, not a heavy 3px offset.
4. **Lyric alignment:** centered on chant detail (anthem feel); falls back
   to left-aligned for long/uneven lines.
5. **Card who-line:** prominent gold line showing club or player + club,
   replacing redundant subject tags.
6. **Loud surfaces:** splash, empty, error/offline get full fanzine
   treatment (stamps, tape, halftone, rotated elements, loud buttons).
7. **Halftone intensity:** keep it faint behind headers (3-6% opacity,
   small dot). Loud surfaces can push higher.
8. **Splash latitude:** full fanzine allowed. Stacked type, stamps,
   halftone, rotated elements. Define the ceiling per build but the
   direction is "go loud."
