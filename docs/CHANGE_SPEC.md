# Change spec: V1 Stage and Club Signal release redesign

**Status:** Approved for local implementation on 2026-09-02

**Approval:** Andrew approved `V1 Stage and Club Signal release redesign spec` and authorized the bounded release redesign. If the shared system makes the remaining visual conversion mechanical and the verified core stays stable, the pass may extend to adjacent screens without changing product behavior. On 2026-09-03, Andrew also requested a source-only pass over the existing approved public landing page using the same current interface principles.

**Owner:** Andrew, through ThunderRiver Tech LLC

**Lane:** 2, reviewed source implementation and release-device verification

**Source baseline:** PR 33 exact green head `e24c9ccf32669fac5962f2e0d9f1bdbb8d6ca153`, stacked above `main` at `88ce483f1ea18df6a7a2b4e790803773164ac9a5`

## Outcome

Make Chants feel like one distinctive supporter product before store submission. Stage should feel immediate and collective. Club browsing and the saved Songbook should feel calm, clear, and useful at a ground. The redesign must preserve the reviewed authority, safety, recovery, playback, and navigation behavior already in source.

The release system has two intentional speeds:

1. **Terrace Broadcast:** the expressive Stage. Performance media, creator, chant trust, subject, and popularity read as one broadcast frame.
2. **Club Signal:** the calmer utility system. Club lists, club pages, and offline Songbook use stronger information hierarchy, flatter surfaces, precise rules, and restrained club-neutral color.

## Product identity brief

- **Promise:** Find the songs supporters already sing, give the next one a first voice, and carry the useful ones into matchday.
- **Primary qualities:** collective, immediate, credible.
- **Audience context:** one-handed use at home, in the pub, on the way to a match, and in an unreliable stadium connection.
- **Signature moment:** a performance-first Stage frame that feels live without autoplay, invented urgency, or hidden trust context.
- **Avoid:** generic social-video cloning, card soup, decorative noise on every screen, club-owned branding, gradients used only for fashion, or typography that competes with lyrics and controls.
- **Preserve:** ink black, supporter gold, warm off-white, restrained coral, Anton signage, Space Mono labels, Fraunces lyrics, Nunito UI copy, and explicit Terrace Proven, Chant Lab, and Rising language.

## Included

1. Add named release design tokens for Stage, Club Signal, navigation, rules, surfaces, and text hierarchy. No raw color literals in redesigned widgets.
2. Restyle the five-destination shell as Stage, Clubs, Create, Songbook, and You. Preserve lazy mounting, tab state, route ownership, safe areas, and labelled navigation targets.
3. Recompose Chant Stage into a performance-first broadcast frame. Preserve user-initiated playback, every filter, creator actions, block and report behavior, real winner logic, chant trust, subject, metrics, sharing, comments, and lyrics access.
4. Apply Club Signal to the Premier League club entry, club Songbook and Chant Lab framing, and saved Matchday Songbook entry surfaces.
5. Keep Stage expressive and reading or task surfaces calmer. Decorative treatments must never obscure lyrics, policy, form, error, loading, empty, disabled, offline, or recovery states.
6. Update targeted widget and golden evidence for changed hierarchy and labels.
7. Verify representative 320, 390, and intermediate widths, 1.8x text, semantics, 48 logical-pixel actions, safe areas, and no horizontal overflow.
8. Inspect rendered populated, loading, empty, error, blocked, offline or saved, and recovery-adjacent states before packaging.
9. Record actual execution and a completed change record. Recapture App Store and Play Store screenshots only after the release UI and device walkthrough are final.
10. Bring the existing static public landing page into the same two-speed product language. Its Stage preview may carry the expressive moment, while its Club Signal and Songbook previews stay light, calm, club-neutral, and truthful. Preserve all trust routes, launch-status limits, no-JavaScript operation, reduced-motion support, and responsive behavior.

## Conditional broader pass

After the Stage, shell, Clubs, and Songbook slice is visually inspected and its focused tests pass, adjacent screens may adopt only the shared tokens and mechanical components in this same change when all of the following are true:

- no route, query, permission, product term, authority, or lifecycle behavior changes;
- the change removes a visible inconsistency rather than inventing a third design direction;
- existing focused evidence remains meaningful;
- the screen is inspected at its consequential narrow, enlarged-text, and failure states; and
- the broader pass does not delay correction of a core regression.

Anything requiring new data, new navigation meaning, new animation authority, a new asset pipeline, or new backend behavior remains a later approved block.

## Excluded

- Production, Firebase, Hosting deployment, DNS, App Check, IAM, data, seed, store, signing, submission, or release mutations.
- Autoplay, prefetch, infinite vertical paging, media capture changes, ranking changes, follower changes, matchday chat, or API-Football integration.
- Invented live labels, listener counts, club affiliations, endorsements, fixtures, scores, or supporter relationships.
- Rewriting legal, safety, account deletion, authentication, or onboarding behavior.
- Hiding trust state, popularity provenance, errors, or recovery actions for visual cleanliness.

## Invariants

1. Stage media remains user initiated and does not prefetch playback authorization.
2. `#1 MOST SHARED` remains restricted to the real eligible weekly leader with at least one unique share.
3. Popularity never implies Terrace Proven evidence. Trust stays written and visible.
4. Blocked creators remain fail-closed while authority loads or errors and disappear immediately after a successful block.
5. Every current Stage action remains reachable with its existing authorization and failure behavior.
6. Club Songbook, Chant Lab, Rising, and saved-copy meanings do not change.
7. Offline Songbook ownership, freshness, corruption, and future-version recovery stay explicit.
8. Five primary destinations remain visible, labelled, stateful, and at least 48 logical pixels tall.
9. Visual hierarchy cannot depend only on color, motion, hover, or media content.
10. No authored file contains an em dash.

## Devil's-advocate scenarios

The verified pass must cover risk where failure has a meaningful consequence:

- an impatient person taps Like or Share repeatedly while a request is pending;
- playback, block authority, or feed loading fails;
- every fetched performance belongs to a blocked creator;
- a long creator, player, club, or chant name meets a narrow phone or 1.8x text;
- a person switches tabs during loading and returns;
- a saved copy is empty, stale, corrupt, written by a newer version, or belongs to another UID;
- crest media is absent or fails without removing the club action;
- the keyboard, system safe area, or enlarged navigation label does not cover a primary action.

Existing evidence should be reused. Add a test only when the changed composition creates a meaningful unproved failure mode.

## Acceptance criteria

1. The shell says Stage, Clubs, Create, Songbook, and You and preserves every existing tab destination and mounted-state behavior.
2. Stage has one dominant media frame per performance, a clear filter rail, visible creator and action authority, written trust and subject, popularity, and lyrics access.
3. Club and saved surfaces read as one calmer Club Signal family without losing current data, actions, offline truth, or recovery copy.
4. Populated, loading, empty, error, blocked, and saved or offline states use the same system and remain understandable without color.
5. Targeted widget tests and goldens pass after intentional updates. The full Flutter suite and scoped analysis pass.
6. Governance, writing-style, whitespace, and staged project-memory checks pass before packaging.
7. A physical iPhone walkthrough confirms Stage playback entry, filters, tabs, Clubs, Songbook, long content, and a truthful failure or retry state.
8. Store screenshots are recaptured from the final release candidate because the user-visible hierarchy changed materially.
9. The public root presents Stage and Club Signal as the same product without inventing clubs, users, metrics, partnerships, or store availability. Its static tests pass and rendered inspection confirms no horizontal overflow at 320, 390, or desktop widths.

## Stop conditions

Stop and correct before broadening if the redesign changes authority, loses an action or trust label, clips at 320 pixels or 1.8x text, introduces unreadable media overlays, makes a failure look like an empty result, or requires backend work.

Commit, push, PR, clean-runner CI, merge, production reopening, signing, store assets, and store submission remain separate owner-authorized actions.
