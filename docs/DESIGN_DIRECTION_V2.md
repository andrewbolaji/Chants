# Chants Design Direction v2: Fanzine (terrace cut-and-paste)

## Spirit

The app should feel like a photocopied terrace fanzine and sticker-bombed
away end: hand-made, loud, funny, unmistakably football and fan-made, never
corporate.

Governing rule for the whole system: **LOUD FRAME, CALM WORDS.**

Personality lives on the chrome (headers, badges, eyebrows, vote stamps,
empty states, splash). The surfaces that carry meaning (lyrics on the chant
detail, the browse/discover list) stay clean, ordered, and highly legible.
Texture must earn its place; it is never applied to a reading surface.

---

## Palette (UNCHANGED from v1, locked)

| Role               | Value                              |
|--------------------|------------------------------------|
| Base background    | `#16140F` (warm charcoal)          |
| Surface 1          | `#1E1A14`                          |
| Surface 2          | `#231B11`                          |
| Chalk text         | `#F6EEDC`                          |
| Muted text         | `#B0A083`                          |
| Faint              | `#6B5F4A` (decorative only, never body text) |
| Gold               | `#FFB627`                          |
| Gold bright        | `#FFC94D`                          |
| Gold-foil gradient | `#FFB627` to `#FFC94D` (verified mark) |
| Error              | `#EF6461`                          |

All contrast must meet WCAG AA on text.

---

## Type system (three voices, each with a strict job)

### DISPLAY / SHOUT: Anton

Heavy condensed, uppercase. Used for screen titles, chant titles, big
numbers, the splash. May carry a hard offset gold text-shadow for a
"printed" feel and a very slight rotation (max 2 degrees) on headers only.
Never used for body or lyrics.

### ZINE VOICE: Space Mono

Monospace. Used ONLY for small chrome: tune lines, tags, eyebrows, captions,
context labels, vote-stamp numbers, metadata. Never used for lyrics or long
text (mono hurts long-form readability).

### READING FACE: Nunito

Warm, highly legible rounded sans for all lyrics and any multi-line readable
text. Lyrics are the hero: large, high contrast, generous line height, dead
legible. This is the calm in "calm words."

### Font implementation note

Bundled variable fonts must pin their weight axis with `FontVariation`
(the v1 lesson). `pubspec` weight alone does not set the `wght` axis. Every
`TextStyle` that uses a variable font must include:

```dart
fontVariations: [FontVariation('wght', 700)]
```

This applies to Anton and Nunito. Failing to pin the axis produces the
wrong weight at runtime. Do not regress this.

---

## Texture map: where grit is ALLOWED vs BANNED

### ALLOWED (no reading load)

- App splash
- Screen headers
- Verified badge (stuck-on sticker, slight rotation, hard shadow)
- Vote control (stamped/stenciled block)
- Eyebrows and section labels
- Empty/loading/error states
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

Warm surface, rounded corners, clear gaps, orderly layout.

- **Eyebrow:** tune name or "ORIGINAL TERRACE CHANT" in Space Mono
- **Title:** Anton
- **Lyric preview:** one line in Nunito (the reading face)
- **Tags and vote chip:** Space Mono

Texture limited to a faint accent, never behind the preview text.

### Chant detail

This screen is the clearest test of "loud frame, calm words."

1. **Loud header zone:** Anton title, sticker badge, mono tune line,
   optional faint halftone wash, and a single accent scrawl.
2. **Clean lyric block:** Nunito (reading face), large and legible. No
   texture, no rotation, no overlays.
3. **Context box:** mono label, readable body.
4. **Stamped vote control** at the bottom.

### Eyebrows / section headers

Examples: CLUB CHANTS, PLAYER CHANTS.

Space Mono, uppercase, letter-spaced, muted or gold.

### Empty/loading/error states

Full fanzine personality allowed here. This is where spirit is free.

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

- No palette changes.
- No logic changes introduced by the visual pass. Logic fixes from
  `KNOWN_ISSUES.md` are tracked separately but may be wired during the same
  screen rebuilds where noted.
- Hold AA contrast everywhere.
- 9th-grade copy level.

---

## Open questions for the mockup review

1. **Reading face:** Confirm Nunito is the final choice. Alternatives to
   evaluate: Quicksand, Varela Round. The pick must be highly legible at
   body size on dark backgrounds with generous line height.
2. **Halftone intensity:** How visible should the dot texture be behind
   headers? Propose a specific opacity range (e.g. 3-6%) and dot size so
   it reads as texture, not noise.
3. **Splash latitude:** How far can the splash screen push the fanzine
   aesthetic? Full bleed collage? Stacked type with heavy rotation? Or keep
   it tight to a single Anton title with a halftone wash? Define the
   ceiling before the build starts.
