# Interface memory

This is the current design contract and decision history for Chants. Read the relevant section before UI work so new screens extend the existing product instead of inventing another visual or interaction system.

## Current interface contract

- **Primary users and context:** Premier League supporters, from casual fans to regular matchgoers, using a phone at home, in the pub, while travelling, or at a crowded ground. The interface must work for a first-time fan without explaining football-product jargon.
- **Experience principles:** Find, learn, save, or add a chant in seconds. Keep archive truth distinct from community creativity. Use one obvious placement and action for each job. Let the frame carry personality while lyrics and forms remain calm and readable.
- **Design-system source:** `lib/app/colors.dart`, `lib/app/theme.dart`, `lib/app/spacing.dart`, `lib/presentation/shared/`, and `docs/DESIGN_DIRECTION_V2.md`.
- **Supported viewports/platforms:** Mobile iOS and Android. The current representative golden viewport is 390 by 844; platform behavior still requires a live-device walk.
- **Accessibility target:** WCAG AA color contrast, semantic controls and headings, minimum comfortable touch targets, text-scaling resilience, clear focus and validation, no meaning conveyed only through color, and motion that never blocks reading.
- **Content voice:** Fan-written, plain, warm, and witty. Never corporate or preachy. Use Songbook, Chant Lab, Rising, and Terrace Proven consistently. Never describe community work as fake.
- **Evidence surfaces:** Widget tests, targeted goldens under `test/presentation/**/goldens/`, runtime console inspection, and the release-device walk in `docs/CHANGE_SPEC.md`.

## State and interaction patterns

| Pattern or component | Required states/behavior | Accessibility and responsive rules | Source/evidence |
|---|---|---|---|
| Browse and club lists | Songbook-first tabs, separate Chant Lab Top and New order, loading, surface-specific empty states, cached and recoverable-error notices, hidden/removed disappearance, and fail-soft player metadata. Discover retains safe content through transient errors but removes a card on permission denial or authoritative absence. A cache-only card stays readable and navigable but its vote control stays disabled | Preserve reading order, explicit trust words, semantic section headings, stable controls during vote changes, text scaling, and one-handed navigation | `lib/presentation/browse/`, `lib/data/services/chant_browse.dart`, `lib/presentation/shared/empty_state.dart`, `lib/presentation/shared/error_state.dart`, decision 015 |
| Chant card | Show title, who it is for, useful provenance, tune, score, and comments without turning the card into a metadata wall. Stateful controls are keyed by chant ID and cache-only vote controls are disabled | Entire card target is semantic and tappable; badges cannot rely on color alone | `lib/presentation/shared/chant_card.dart`, `docs/DESIGN_DIRECTION_V2.md` |
| Chant detail | Loud identity header, calm lyrics, context, vote, save, share, report, comments, and any safe external evidence action. Route or cache text may remain readable. Share, Report, Vote, Comment, and a new save wait for an active, error-free, non-cache current visible chant. Opening or removing an existing device save stays available offline | Long lyrics fall back to left alignment; disabled authority states remain understandable; local saved ownership remains explicit; link purpose is explicit; Share has a text alternative and valid iPad anchor; text scaling and screen readers retain logical order | `lib/presentation/browse/chant_detail_screen.dart`, `lib/data/services/chant_share.dart`, decisions 009 and 015 |
| Saved Matchday Songbook | Local-first overview, club snapshots, read-only chant detail, explicit refresh and remove, last-refreshed disclosure, UID lock, corrupt and future-version recovery states | Ownership and freshness use words as well as icons; saved detail omits live controls; 390 by 844 and enlarged text remain scrollable and unclipped | `lib/presentation/saved/`, `lib/data/models/saved_songbook.dart`, decision 003 |
| Submission form | Preserve entered work on validation or network failure; distinguish required from optional fields; denied and banned states explain the next action; clear a stale prefilled Player with recovery copy instead of asserting or spinning | Every choice has a text label and semantic group; subject labels stay on one line at 390 by 844; keyboard never hides the active field or submit result | `lib/presentation/submit/submit_chant_screen.dart` |
| Comments and replies | One visible reply level, recoverable failed writes and preference reads, reporting, blocking and failed Undo recovery, moderation disappearance, and no orphan promotion | Reply context and hierarchy are announced without indentation alone; tap targets and empty states remain usable at 390 by 844 and 1.8x text | `lib/presentation/comments/`, `docs/decisions/002-comment-reply-depth-and-retention.md` |
| Reports and feedback | Submit through one server-authoritative boundary. Duplicate reports use `You already reported this.`; report and feedback limits explain that several items were sent recently; other failures retain the existing retry copy. Every failure keeps the entered category, note or message, and follow-up choice, then restores the submit control | Error copy appears in the existing snackbar pattern without replacing or clearing the form. Controls retain stable placement and labels; no limit state relies on color alone | `lib/presentation/report/report_sheet.dart`, `lib/presentation/feedback/feedback_screen.dart`, decision 010 |
| Account deletion | Confirmation distinguishes reports the user sent, whose actor ID and submitted text are removed, from safety history about the account, which may retain its target ID. Before a request, local data is prepared. Prepared state actively recovers before Home; unknown acknowledgement persistently replaces Home with retry and Sign out. Positive acceptance shows queued deletion; a local recovery failure also fails closed. None of these states implies cancellation | Recovery uses text, icon, and stable labeled actions; both screens scroll without clipping at 390 by 844 and 1.8x text; uncertainty, prepared recovery, retry, and sign-out failures keep a truthful next action | `lib/presentation/home/home_screen.dart`, `lib/presentation/auth/account_deletion_recovery_screen.dart`, `account_deletion_pending_screen.dart`, decisions 011, 012, and 016 |

## Decision log

### 2026-08-26T12:06:39Z Persist account-deletion uncertainty before Home

- **Status:** active
- **Surface and user problem:** The first unconfirmed response used a snackbar. Process death removed that explanation while the durable unknown marker still locked the local Songbook, so a later launch could appear normal until the user rediscovered Delete account.
- **Decision:** The signed-in gate checks local deletion state before policy or Home. Unknown state shows `REQUEST NOT CONFIRMED`, explains that the Songbook remains locked, and offers `TRY DELETION AGAIN` plus `SIGN OUT`. Prepared state actively retries local artifact recovery. If it cannot recover, the screen shows `RECOVERY NEEDED` and `TRY RECOVERY`; that action reruns recovery and does not merely reread the marker. Positive profile pending state can advance local cleanup and then shows the existing queued-deletion screen. A false pending value never unlocks unknown data.
- **Why:** A persistent state needs a persistent recovery surface. Only positive server evidence can safely advance an ambiguous destructive request.
- **Alternatives considered:** Keep the snackbar, which disappears on process death; restore on a false pending value, which can be stale or race a late commit; expose file markers, which do not help a fan decide what to do.
- **Required states:** Prepared recovery without relaunch, prepared recovery failure and real retry, unknown at relaunch, another unconfirmed retry, successful retry and sign-out, positive pending reconciliation, queued deletion, and sign-out failure.
- **Accessibility/responsive impact:** Both actions have explicit text labels. The hierarchy does not depend on color. The unknown and status-check layouts pass at 390 by 844, including status-check at 1.8x text, and the unknown golden was visually inspected.
- **Implementation evidence:** App-gate, repository, service, screen, and golden tests cover prepared same-process recovery, persistent unknown state, and positive-only acceptance boundaries. Decision 016 and the deletion copy disclose that target-side safety history may retain the account ID while authored reports lose actor identity and submitted text.
- **Revisit when:** A durable server receipt can prove both acceptance and rejection, or localization requires a different action hierarchy.
- **Related:** `docs/decisions/012-account-deletion-acknowledgement.md`, `docs/decisions/016-account-deletion-audit-privacy.md`

### 2026-08-26T04:40:55Z Say when deletion acknowledgement is unknown

- **Status:** active
- **Surface and user problem:** A lost callable response can mean either that account deletion never started or that its durable job already exists. Copy that claims failure, restores saved data, or signs out would choose a state the client cannot prove.
- **Decision:** An unconfirmed request keeps the local Songbook locked and keeps the user signed in. The immediate snackbar uses the existing uncertainty copy, and every later signed-in launch replaces Home with the persistent recovery screen above. A retry uses the same deletion action. Explicit acceptance keeps the queued completion and sign-out flow.
- **Why:** The interface must preserve uncertainty at the same boundary as storage and server state. It should give one safe next action without implying that deletion can be cancelled.
- **Alternatives considered:** Say deletion failed, which may be false; say deletion started, which may also be false; expose prepared, unknown, and accepted implementation labels, which do not help the user act.
- **Required states:** Local preparation failure, unconfirmed remote outcome, retry after uncertainty, explicit acceptance, accepted local cleanup failure, pending-session fallback, and sign-out failure.
- **Accessibility/responsive impact:** The distinction is stated in complete text, first through the announced snackbar and then through a persistent labeled screen. It does not rely on color or a transient icon alone.
- **Implementation evidence:** Repository and app-gate tests cover ambiguous response, process relaunch, retry acceptance, exact copy, and sign-out boundaries. The later recovery-screen decision changes hierarchy only while local uncertainty exists.
- **Revisit when:** A durable deletion status receipt lets the app replace uncertainty with confirmed queued or rejected state.
- **Related:** `docs/decisions/012-account-deletion-acknowledgement.md`, `docs/changes/2026-08-26-v1-freeze-correctness-remediation.md`

### 2026-08-25T21:22:57Z Show account deletion as queued, not instantly finished

- **Status:** active after explicit acceptance; request-failure behavior refined by the 2026-08-26 decision above
- **Surface and user problem:** Durable deletion is accepted before every remote row is physically removed. A delayed sign-out or reopened session must not expose the app or falsely claim completion.
- **Decision:** The confirmation explains the retained anonymized contributions, removed local Songbook, and brief background completion. After acceptance the normal path signs out. If a pending session remains, the app gate replaces Home and policy acceptance with one deletion-in-progress screen and a retryable Sign out action.
- **Why:** The interface should describe the real durability boundary without exposing internal phases or giving the user controls that cannot safely cancel server cleanup.
- **Alternatives considered:** Claim immediate deletion, which is false; show worker phases and counters, which exposes private operational state and implies control; leave Home visible until finalization, which conflicts with the pending-account authority boundary.
- **Required states:** Confirmation, pre-request local failure, unconfirmed remote outcome with locked Songbook, accepted and signed out, pending fallback, sign-out pending, and sign-out failure with retry.
- **Accessibility/responsive impact:** The queued meaning is stated in words and not color alone. The centered content is scrollable, constrained in width, and verified at 390 by 844 with normal and 1.8x text.
- **Implementation evidence:** Service, repository, app-gate, copy, and screen tests plus inspected 390 by 844 pending and recovery goldens. The current complete local Flutter suite passes 341 tests.
- **Revisit when:** Deletion gains undo, progress becomes user-actionable, localization makes the copy exceed the current layout, or support data shows users misunderstand anonymized retention.
- **Related:** `docs/decisions/011-durable-account-deletion-recovery.md`, `docs/changes/2026-08-25-v1-account-deletion-recovery.md`

### 2026-08-25T19:29:54Z Keep safety failure recovery inside the existing form

- **Status:** active
- **Surface and user problem:** A report or feedback attempt may be a duplicate, exceed a server budget, or fail in transit. Losing the fan's selected reason or written context would make a protective control feel punitive and invite repeated submissions.
- **Decision:** Keep the report sheet or feedback screen open after every failed callable attempt. Preserve every entered value, restore the submit control, and use specific duplicate and limit copy while retaining the existing generic retry copy. Successful confirmation remains unchanged.
- **Why:** Rate limiting is an admission result, not a form reset. The user can understand the outcome, edit if appropriate, or retry later without recreating useful context.
- **Alternatives considered:** Clear after any server response, which discards work; show one generic error for every condition, which makes a deliberate budget look broken; add a dedicated error screen, which breaks the lightweight report and feedback flow.
- **Required states:** Success, duplicate report, report limit, feedback limit, unauthenticated or rejected caller, target unavailable, ordinary callable failure, and repeat submission after control restoration.
- **Accessibility/responsive impact:** Copy is textual, uses the existing announced snackbar surface, does not shift the form hierarchy, and leaves the active form scrollable. Temporary 800 by 600 renders showed no clipping.
- **Implementation evidence:** Widget and repository tests cover typed mapping, exact copy, retained values, restored controls, and success for all three report target types. The full Flutter suite passes 294 tests.
- **Revisit when:** Snackbar announcements prove unreliable with assistive technology, longer localization copy is introduced, or the product adds inline retry timing.
- **Related:** `docs/decisions/010-server-authoritative-safety-intake.md`, `docs/changes/2026-08-25-v1-report-feedback-abuse-controls.md`

### 2026-08-25T10:25:44Z Separate readable fallback from live action authority

- **Status:** active
- **Surface and user problem:** Stadium connectivity makes retained lyrics useful, but a route snapshot or stale Discover card cannot prove that moderators still permit the target or that it still exists.
- **Decision:** Discover keeps its last safe card through an ordinary transient error and removes it on typed Firebase permission denial, current absence, hidden, or removed data. Detail may render route text while waiting. Opening or removing an existing device-local save remains available, while creating a new save, Share, Report, Vote, and Comment require an active, error-free, non-cache, current visible chant.
- **Why:** Reading public text and managing an existing local copy are reversible device-local operations. Creating a new saved representation or acting against a server or external target needs current authority.
- **Alternatives considered:** Clear everything on any error, which harms matchday reading; retain every stale action and rely on server rejection, which cannot stop a new local save or native share; disable every Songbook branch, which unnecessarily strands an existing local copy; gate only Share, which leaves the interface with inconsistent authority semantics.
- **Required states:** Waiting with route text, current visible, transient stream error, Firebase permission denial, current null, hidden, removed, signed in, and signed out.
- **Accessibility/responsive impact:** Disabled controls remain in their stable locations where useful, the comment composer explains that live updates are required, and moderation removal does not leave a tappable stale card.
- **Implementation evidence:** Real typed-permission and transient Discover tests, Discover-to-detail navigation, existing-save removal and local-club navigation tests, an all-actions pre-authority widget test, focused comment and vote regressions, and 341 passing Flutter tests.
- **Revisit when:** An offline mutation queue is approved with explicit target-version and conflict semantics, or one shared availability state replaces the widget-local implementation.
- **Related:** `docs/decisions/009-direct-write-and-live-action-authority.md`, `docs/changes/2026-08-25-stacked-v1-authority-integration-remediation.md`

### 2026-08-25T00:41:42Z Share a useful chant before a public destination exists

- **Status:** active
- **Surface and user problem:** Live chant detail had no distribution action, while the product has no public chant resolver and must not send recipients to a guessed dead link.
- **Decision:** Place one Share action between Save and Report on live detail. The system sheet receives the current title, optional known team, full main lyrics, tune, honest trust line, and Chants footer. Current builds are text-only. A later approved route may supply one validated HTTPS URL through the existing payload seam.
- **Why:** A useful rendition can travel through any installed application now without pretending Chants controls a destination, delivery, or third-party retention.
- **Alternatives considered:** A guessed website link, which is broken; title-only promotional copy, which is not useful to the recipient; generated cards or direct social integrations, which add media, permissions, SDK, and platform-policy scope.
- **Required states:** Current stream value, known or absent team, all provenance states, pending duplicate tap, dismissed or unavailable platform result, invocation failure, invalid source rectangle, and hidden or removed chant.
- **Accessibility/responsive impact:** The control is labeled `Share this chant`, uses the native sheet, passes the button's laid-out global rectangle for iPad, and remains reachable with Save and Report at 390 by 844 and 1.8x text.
- **Implementation evidence:** Pure payload and gateway tests, real-detail widget tests, a deliberate missing-lyrics red check, the current-live authority regression, 282 passing Flutter tests, an inspected launch-viewport golden, and green replacement CI on draft PR 9. Native compilation, remediation review, and device sharing remain pending.
- **Revisit when:** A stable HTTPS chant route exists, recipients need richer previews, device testing finds platform-specific payload loss, or direct publishing has evidence strong enough to justify its account and SDK surface.
- **Related:** `docs/decisions/008-native-text-share-before-public-links.md`, `docs/CHANGE_SPEC.md`

### 2026-08-22T19:38:09Z Make saved lyrics a timestamped device copy

- **Status:** active
- **Surface and user problem:** Fans need lyrics at a crowded ground where connectivity is unreliable, but incidental Firestore cache behavior cannot support a clear offline promise.
- **Decision:** Home exposes one signed-in Matchday Songbook. Team and live chant detail save explicit UID-scoped device snapshots. Saved overview, club, and detail routes read locally first, label the copy and refresh date, omit live social and media actions, and require explicit refresh or removal.
- **Why:** The feature supports the app's sharpest matchday job without turning favorites into another cloud product or implying stale counters and conversation are live.
- **Alternatives considered:** Generic cloud favorites, which do not prove lyrics are present offline; Firestore cache, which is incidental and lifecycle-unclear; background downloads, which add scheduling and consent surface before demand is proven.
- **Required states:** Loading, empty, populated, individually saved, saved with club, cache-disabled save, busy, refresh failure with retained copy, zero-item refreshed club, corrupt, unsupported version, UID mismatch, removal confirmation, and account-deletion cleanup.
- **Accessibility/responsive impact:** Bookmark ownership and freshness are explicit text and semantics. Destructive actions require confirmation. Read-only detail follows the live lyric hierarchy without vote, comment, report, evidence, or media affordances. The overview and detail goldens pass at 390 by 844, and the overview passes at 1.6x text.
- **Implementation evidence:** The approved Lane 2 implementation, focused widget and persistence tests, deliberate reconstruction red check, two inspected goldens, and green clean-runner CI are recorded in `docs/changes/2026-08-22-saved-matchday-songbook.md`. Native compilation, PR review, and the live airplane-mode device walk remain pending.
- **Revisit when:** Users expect cross-device sync, snapshot volume approaches the 2 MiB or 500-ID boundary, moderation requires online revocation stronger than refresh, or offline audio and video are separately approved.
- **Related:** `docs/decisions/003-saved-matchday-songbook-offline-v1.md`, `docs/CHANGE_SPEC.md`

### 2026-08-22T00:00:35Z Separate Songbook truth from Chant Lab creativity

- **Status:** active
- **Surface and user problem:** Club, player, submit, and chant-detail flows need to welcome new and funny chant ideas without making the trusted archive feel unreliable.
- **Decision:** Club and player journeys present Terrace Proven content as the Songbook and community submissions as Chant Lab. Chant Lab supports Top and New order, plus a Rising signal that never implies verification. Submission requires the fan to choose Already sung or I made this. An evidence link is optional for posting and required before a user submission can become Terrace Proven.
- **Why:** One mixed ranked list asks a single score to represent both terrace truth and entertainment. Separate labels let the archive stay credible while giving creation a visible competitive home.
- **Alternatives considered:** Archive only, which suppresses the product's creator loop; one undifferentiated feed, which blurs provenance; a TikTok-style video feed, which makes media infrastructure and moderation the product before the archive is proven.
- **Required states:** Songbook and Chant Lab loading, empty, partial, error, denied, hidden/removed, offline, and populated states; Top and New order in Chant Lab; no-evidence and dead-link states; player-with-no-chant creation prompt; successful and failed origin-aware submission.
- **Accessibility/responsive impact:** Songbook versus Chant Lab and Proven versus Rising must use words and semantics, not color alone. Nested filters must remain usable at narrow widths and with enlarged text. External evidence actions state that they open another app or browser.
- **Implementation evidence:** Product direction was approved by Andrew on 2026-08-21. The provenance slice and separate browse hierarchy were approved and implemented in source on 2026-08-22. Team and Player routes now open on Songbook, place only community work in Chant Lab, retain stable Top and Songbook survivor order, expose New separately, explain that Rising is early support rather than proof, and keep the last usable cards through a later stream error. Player metadata failure is inline and never erases chants. Team Songbook and Chant Lab goldens at 390 by 844, an enlarged-text route test, stream-driven widget tests, and pure ranking tests retain the interface boundary. Live-device inspection and PR review remain pending.
- **Revisit when:** Closed-beta users cannot find one of the two surfaces, community volume is too low for Top and New to be useful, or users consistently misunderstand evidence and verification.
- **Related:** `docs/decisions/004-songbook-and-chant-lab.md`, `docs/ROADMAP.md`

## Open interface questions

None. Exact microcopy and visual treatment remain implementation details to verify in the dedicated change block.
