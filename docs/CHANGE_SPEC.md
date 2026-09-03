# Change spec: V1 store submission presentation packet

**Status:** Approved for local implementation on 2026-09-03

**Approval:** Andrew approved `V1 store submission presentation packet spec` and asked that light and dark mode be pinned for early V1.1.

**Visual acceptance:** Andrew approved the corrected Google Play feature graphic and screenshot storyboard on 3 September 2026. This does not approve absent final release-candidate screenshots.

**Owner:** Andrew, through ThunderRiver Tech LLC

**Lane:** 2, public claims, store disclosure, and release-presentation evidence

**Source baseline:** PR 34 exact green head `b952389e20b7c510f204f5cbbeb87af70b4c2574`, stacked above PR 33 and `main` at `88ce483f1ea18df6a7a2b4e790803773164ac9a5`

## Outcome

Prepare one copy-pasteable App Store and Google Play submission packet grounded in the actual V1 app. The packet must state what can be entered now, what still requires owner or exact-binary evidence, what screenshots to capture, and which claims must stay out. It must not imply that an app, site, provider, production system, or store listing is live when it is not.

## Included

1. Canonical US English name, subtitle or short description, promotional text, long descriptions, keywords, categories, URLs, review notes, and release boundaries for both stores.
2. A source-backed Apple App Privacy and Google Play Data safety worksheet that includes Firebase SDK collection and separates current launch behavior from disabled provider paths.
3. A five-scene screenshot plan for iOS and Android, with truthful content, exact target files, device requirements, caption copy, and a clean-capture checklist.
4. A machine-readable metadata file and screenshot manifest.
5. A local validator for store field limits, identity, URLs, screenshot inventory, PNG dimensions, alpha restrictions, and honest readiness state.
6. Known-good and known-bad tests for the validator, integrated into the existing governance job.
7. A deterministic 512 by 512 Google Play icon derived from the current no-alpha 1024 App Store icon.
8. Durable rationale, execution evidence, roadmap status, and an early V1.1 light and dark theme commitment.
9. A reproducible 1024 by 500 Google feature graphic candidate and one reusable, exact-size presentation frame for all ten final screenshot outputs.

## Excluded

- Capturing or publishing final screenshots before the redesigned release candidate passes its device walkthrough.
- Entering, submitting, releasing, or changing anything in App Store Connect or Google Play Console.
- Creating or storing review-account credentials in the repository.
- Changing the app's 17+ account rule or guessing either store's questionnaire-derived rating.
- Enabling Apple, Google, Facebook, magic-link, or phone authentication.
- Deploying Hosting, Firebase, production data, App Check enforcement, DNS, IAM, signing, or binaries.
- Claiming club, league, player, music-rightsholder, or supporter-group affiliation.
- Promising autoplay, live scores, fixtures, chat, notifications, licensed music, karaoke generation, or any future feature.
- Building light or dark mode in V1.

## Source facts that control the packet

1. The product name is `Chants FC`; the installed display name remains `Chants`; bundle and package identity are `com.chants.chants`.
2. ThunderRiver Tech LLC operates Chants. Public support is `support@chantsfc.com`.
3. The approved first markets are the United States, United Kingdom, and Canada.
4. Chants includes Premier League club and player songbooks, community chant submission, optional evidence, one-level replies, voting, creator profiles and follows, short reviewed performance video, blocking, reporting, sharing, and device-local saved Songbooks.
5. Performance video is at most 30 seconds and stays private until operator approval.
6. A chant can become Terrace Proven only through current operator-reviewed evidence. Popularity never proves provenance.
7. The current binary uses Firebase Authentication, App Check, Firestore, Functions, Storage, and Crashlytics. It does not include Firebase Analytics or Performance Monitoring.
8. Apple, Google, Facebook, magic-link, and phone entry points are compile-time disabled unless explicitly configured. Launch copy cannot advertise them.
9. Public trust routes exist in source at `chantsfc.com`, but publication and signed-out readback remain separate gates.
10. Production remains closed until a separately approved opening and walkthrough. Store assets cannot portray a maintenance denial as a working journey.

## Invariants

1. Every store claim maps to current source behavior or is labelled pending evidence.
2. Store copy uses no profanity, rankings, testimonials, invented metrics, or unsupported availability language.
3. The listing does not imply official affiliation or rights clearance.
4. Privacy answers cover the app and included SDKs, not only fields typed by a user.
5. Disabled authentication providers remain excluded from launch claims and conditional in disclosure notes.
6. Final screenshots come from release-mode iOS and Android builds at the exact submitted source and configuration.
7. Screenshots contain no debug banner, external-app return affordance, personal account detail, transient error, fake engagement, copyrighted broadcast footage, club crest, or player photo.
8. App Store screenshots use an accepted size, contain no alpha, and show the actual interface.
9. Review credentials stay out of Git and are entered only in the private store consoles.
10. The app's 17+ account rule is unchanged. Store rating forms are answered from actual content and are not pre-decided here.
11. `prepared_not_submitted` cannot become `ready_for_submission` while any required capture, URL, form, review-access, signing, or exact-binary gate remains false.
12. No authored file contains an em dash.
13. A missing release-candidate screenshot remains visibly unpublishable in the presentation frame.

## Devil's-advocate scenarios

- A hurried operator copies the wrong platform's short description or exceeds a field limit.
- An old screenshot survives the redesign and looks plausible despite having the wrong dimensions and navigation.
- A screenshot includes a debug ribbon, Instagram return bar, owner email, moderation controls, unavailable action, or maintenance message.
- A store reviewer cannot enter because production is closed or the supplied account expires, is unverified, is policy-stale, or lacks useful seeded content.
- The listing promises Apple, Google, Facebook, phone, or magic-link sign-in although that exact binary disables it.
- The privacy form omits Crashlytics installation identifiers, crash data, recorded audio inside a video, or public user content.
- A later editor marks the packet ready by changing one status string while required evidence is still missing.
- A PNG has accepted width and height but contains alpha, or an Android image is silently reused as iOS evidence.
- The public support, privacy, or deletion URL is valid in source but unavailable on the live domain.
- A future theme change alters screenshots without invalidating the captured-source record.

## Acceptance criteria

1. `store/submission.json` parses and every Apple and Google text field passes the official limit encoded by the validator.
2. The packet identifies Sports as the primary category, recommends Social Networking only as Apple's secondary category, and explains the choice.
3. Privacy and Data safety answers cover email, public creator and user content, video and recorded audio, identifiers, product interaction, crash data, and device information with conservative linked, purpose, and sharing notes.
4. The screenshot manifest has five distinct scenes per platform, exact paths, captions, content requirements, and pending states until real captures exist.
5. Existing 1320 by 2663 documentation screenshots are explicitly rejected as pre-redesign and not App Store-ready.
6. The validator rejects over-limit copy, identity drift, non-HTTPS or off-domain trust URLs, missing screenshot scenes, invalid PNG dimensions, alpha-bearing iOS PNGs, and false readiness.
7. A known-good metadata fixture passes and each meaningful known-bad mutation fails.
8. The current icon source and derived Google Play icon pass dimension and alpha checks.
9. The launch command center and roadmap can point the owner to one stable packet without duplicating field copy.
10. Light and dark mode is pinned as an early V1.1 fast follow with System, Light, and Dark choices, persisted explicit preference, token-only implementation, contrast proof, and screenshot invalidation as a release concern.
11. Writing-style, whitespace, project-memory, store-validator, and focused tests pass locally.
12. The feature graphic passes exact size and alpha checks and becomes final only after recorded owner visual acceptance.

## Stop conditions

Stop and correct if source behavior cannot support a claim, a disclosure depends on an unverified SDK assumption, a screenshot requires fabricated data or rights-sensitive media, a real URL is not live, or final readiness would depend on a secret stored in Git.

Commit, push, PR, independent review, clean-runner CI, live URL verification, screenshot capture, console entry, signing, submission, and release remain separate owner-authorized actions.
