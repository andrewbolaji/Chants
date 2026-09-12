# Decision 033: Unify Club Signal on dark Chants surfaces and explain trust plainly

**Status:** Accepted

**Date:** 2026-09-11

## Context

Decision 029 deliberately allowed a light Club Signal context and named device disorientation as its revisit trigger. The final candidate iPhone walk reached that trigger. Moving from the black Stage shell into a large off-white Clubs directory felt like a different application rather than a calmer part of Chants. The same walk also showed that the rotated Terrace Proven strip read as decoration, the posting identity chip occupied more space than its content needed, and the trust phrase relied too heavily on football vocabulary to explain itself.

The Chants palette already has a quiet dark surface family capable of supporting crest-led rows and long-form reading without turning every screen into Stage. The Terrace Proven name still carries useful product identity, but it needs an immediate plain-language definition for a first-time supporter.

## Decision

- Keep the two-speed information hierarchy, but render in-app Club Signal and saved Songbook surfaces on the shared black and charcoal Chants canvas. Calmness comes from flat rows, restrained rules, spacing, and typography rather than a light-mode switch.
- Preserve local club crests, fallback behavior, routes, queries, vote semantics, save authority, and recovery behavior. This is a presentation correction, not a data or navigation redesign.
- Keep `Terrace Proven` as the branded trust term. On the performance entry surface, explain it as verified evidence that the chant has been sung at matches.
- Replace the rotated strip and foil treatment with a compact, level, outlined badge. Do not use shine, gradient, shadow, skew, or oversized decoration to communicate trust.
- Keep the posting identity in a bordered chip, but size it to its handle and align it with the `POSTING AS` metadata rather than making it resemble a separate primary control.
- Keep historical public-site and store evidence unchanged in this pass. Recapture or redesign those assets from the final exact candidate under their existing release gates.

## Reasons

The physical device is the right judge of route-to-route continuity. A shared dark canvas makes the five-tab shell feel coherent while the flatter Club Signal composition still protects scanning and reading. Plain language makes the trust system understandable without discarding a distinctive term that the rest of the product already uses.

## Consequences

- Club, team, saved Songbook, and related goldens must be refreshed and inspected.
- The light Club Signal portion of decisions 029 and 031 is superseded; their crest, hierarchy, vote, and product-identity rules remain in force.
- Current store screenshots and the light Club Signal phone on the public landing page become historical presentation evidence and must be replaced before their final release gates.
- Terrace Proven copy remains a trust statement about accepted evidence of match use. It is not a claim of club approval, factual accuracy, copyright clearance, popularity, or payment.

## Revisit triggers

Revisit if dark Songbook reading fails contrast or stadium-legibility checks, if the trust definition still fails first-time comprehension research, or if a future user-selectable appearance system is deliberately scoped. Do not reintroduce a light route in isolation.
