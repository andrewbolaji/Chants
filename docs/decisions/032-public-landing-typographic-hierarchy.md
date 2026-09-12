# Decision 032: Public landing typographic hierarchy

- **Date:** 2026-09-09
- **Status:** Accepted
- **Scope:** Public landing typography only

## Context

The original public hero used very heavy Nunito at poster scale. Owner review found that treatment too rounded, too large, and too generic for a football product. The floating Stage and Club Signal phones already carried the right product character and did not need redesign.

## Decision

Keep the two existing local font files and give each a clearer job. Loud dark moments use condensed uppercase Oswald for matchnight and programme energy. Calm cream product sections retain Nunito, but with lower weight and smaller display ceilings. The hero stays the same sentence and keeps the gold emphasis. Its intended rhythm is three fixed phrase lines: `Every chant`, `starts with`, and `one voice.` The phone composition, color system, actions, and trust meaning remain unchanged. The compact header links gain one restrained size and weight step. The light phone remains club-neutral, but its placeholder `Club A`, `Club B`, and `Club C` rows become an honest three-step product flow: choose a club, learn the songs, and save for matchday.

The typography must fit without horizontal scroll at 320, 390, and desktop widths. No remote font or third type family is added.

Final owner review keeps that direction but reduces the hero scale one further restrained step and opens its line height slightly. The three phrase lines remain fixed; this is a balance correction between the copy and phones, not another type or layout direction.

## Consequences

- The first viewport reads as football culture instead of a rounded startup poster.
- Alternating display voices create rhythm without a site-wide redesign.
- Header links remain secondary while becoming easier to scan, and the light phone explains the product without club favoritism or placeholder copy.
- Local assets, page weight, semantics, and reduced-motion behavior stay stable.
- Future public-site headings should follow the loud-dark versus calm-cream distinction unless owner review changes the direction again.

## Verification

The public-landing contract passes 12 cases. Browser inspection covers the large desktop owner view plus the earlier 1280 by 900, 1000 by 800, 390 by 844, and 320 by 780 checks with the same three phrase lines and no horizontal overflow. The final desktop balance reduces the headline from about 100 to 88 CSS pixels at a 1700-pixel viewport while preserving the phone composition. Firebase Hosting released the final source, and a cache-busted live-domain inspection returned stylesheet `hero-balance`, the same semantic structure, and the final visual treatment.
