# Change rationale: V1 Stage and Club Signal release redesign

## Identity and authority

- **Date:** 2026-09-03. **Owner:** Andrew. **Author:** Codex.
- **Baseline:** PR 33 exact green head `e24c9ccf32669fac5962f2e0d9f1bdbb8d6ca153`, stacked above `main` at `88ce483f1ea18df6a7a2b4e790803773164ac9a5`.
- **Authority:** Andrew approved `V1 Stage and Club Signal release redesign spec`. The approval covers local application presentation, focused tests, goldens, and durable records. It excludes backend, data, production, store, signing, release, commit, push, and merge actions.

## Outcome

The release journey now uses one product language at two intentional speeds.

- **Terrace Broadcast** gives Stage one dominant performance frame, visible creator and chant identity, written trust, real popularity, filters, playback entry, lyrics, comments, sharing, reporting, and blocking.
- **Club Signal** gives the Premier League directory, club Songbook and Chant Lab, saved Songbook overview, saved club, and saved chant reader a calmer light utility system with flatter hierarchy and precise rules.
- **The shell** labels the persistent destinations Stage, Clubs, Create, Songbook, and You. It preserves lazy mounting, tab state, safe-area ownership, and the existing destination widgets.
- **Shared presentation controls** accept an explicit Club Signal appearance where needed instead of inferring a theme from route or data.
- **The public landing page** now previews the same release system: one expressive Stage phone, one light Club Signal phone, a calm Club Signal Songbook panel, and restrained sound-level marks in place of decorative glows. It preserves the approved copy hierarchy, trust destinations, club-neutral examples, and honest coming-soon status.

No route, query, permission, server action, ranking rule, trust definition, saved-data format, playback boundary, or recovery meaning changed.

## Interface and recovery proof

Stage remains user initiated. It does not autoplay or prefetch playback authority. `#1 MOST SHARED` still requires the real eligible weekly leader with a positive unique-share count. Block authority remains fail-closed while loading or failed, and successful blocking removes the creator immediately. Empty, all-blocked, loading, and failure states retain written next actions.

Club Signal keeps Songbook, Chant Lab, Rising, and Terrace Proven meanings written. Missing crest media does not remove the club action. Saved routes retain ownership checks, empty-state guidance, freshness, stale-copy disclosure, corrupt-copy recovery, newer-version refusal, and retry behavior. The added production-widget regression proves the saved chant reader remains scrollable and exception-free at 320 logical pixels with 1.8x text.

The broader pass stopped at the complete high-value release journey. Authentication, onboarding, policy, Create forms, moderation, and account actions keep their reviewed task-specific presentation because converting them safely would require separate state and accessibility inspection rather than mechanical token replacement.

## Evidence

- The complete affected group passes 60 widget and golden tests across Stage, shell, Clubs, team Songbook and Chant Lab, Chant Call-Up, saved Songbook, saved detail, and creator-profile shell integration.
- The complete Flutter suite passes 539 tests.
- Scoped Flutter analysis reports no issues across every changed Dart and test file.
- Dart formatting, authored-text checks, and `git diff --check` pass before durable-record completion.
- Updated goldens were inspected for Stage, competition browse, team Songbook, team Chant Lab, Chant Call-Up at normal and enlarged text, saved overview, saved detail, Home shell integration, and creator-profile shell integration.
- The static public-root contract passes 10 tests. The real local page was inspected at 1440 by 900, 390 by 844, and 320 by 700. Each rendered without horizontal overflow. The uncached render confirms the Stage and Club Signal treatments, local fonts, and all six trust destinations.
- The risk-calibrated adversarial pass covered impatient repeated actions, block and playback authority failure, all-blocked results, long content, tab changes during loading, missing crest media, narrow enlarged saved reading, and saved-data recovery. Existing proof was reused where the composition did not change behavior.

## Remaining gates

A physical iPhone walkthrough must confirm the final release presentation, Stage entry and filters, all five tabs, Clubs, club Songbook and Chant Lab, saved Songbook and chant reading, long content, and one truthful failure or retry state. The current phone cannot pass policy acceptance because production remains intentionally in maintenance; that is a truthful closed-system result, not acceptance proof. Store screenshots must then be recaptured from the accepted release candidate because the primary Stage, Clubs, Songbook, and navigation hierarchy changed materially.

Packaging, independent review, exact-head clean-runner CI, production reopening, distribution signing, store configuration, and submission remain separately authorized work.
