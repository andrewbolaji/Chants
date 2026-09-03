# Decision 029: Stage and Club Signal release system

**Status:** Accepted

**Date:** 2026-09-02

## Context

Chants had a recognizable black, gold, and fanzine language, but too many surfaces used the same poster volume. That weakened the difference between watching supporter performances, reading verified lyrics, browsing clubs, and using an offline matchday tool. Andrew selected the Terrace Broadcast and Club Signal redesign directions for the V1 release.

## Decision

Use one product language at two intentional speeds.

- Terrace Broadcast owns Chant Stage. It concentrates expression around one performance-first media frame and keeps creator, trust, subject, popularity, safety actions, and lyrics visible.
- Club Signal owns club browsing and saved Songbook entry surfaces. It uses a calmer club-neutral utility canvas, flatter rows, precise rules, and stronger information hierarchy.
- The five-destination shell is Stage, Clubs, Create, Songbook, and You. Navigation state and route ownership do not change.
- Ink, supporter gold, warm off-white, restrained coral, Anton, Space Mono, Fraunces, and Nunito remain the shared identity.
- Task, policy, form, error, empty, offline, and recovery states stay quieter than the Stage.

## Reasons

Stage needs collective energy and immediate feedback to support creation and sharing. Club and Songbook journeys need speed, trust, readability, and stadium resilience. One visual treatment cannot serve both jobs equally well. The two-speed system lets the app feel distinctive without making every screen loud.

## Consequences

- Store screenshots must be recaptured from the final release candidate because the primary hierarchy changes materially.
- A scoped light utility palette is allowed on Club Signal screens, but trust and actions must remain written and contrast-safe.
- Stage may use a functional media scrim for legibility, but generic decorative gradients and invented live state remain disallowed.
- Existing tests that assert the visible Feed label must move to Stage.
- Any broader conversion must reuse shared tokens and preserve route, query, authority, and recovery behavior.

## Revisit triggers

Revisit if device testing shows the light Club Signal context is disorienting, media overlay contrast varies unsafely with real uploads, navigation labels clip under supported text scaling, or a later personalized club home creates a genuinely different information architecture. Do not revisit only to follow a design trend.
