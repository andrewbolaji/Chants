# Chants FC V1 store submission packet

**Status:** Prepared, not submitted

**Source baseline:** `b952389e20b7c510f204f5cbbeb87af70b4c2574`

**Use this packet for:** App Store Connect and Google Play Console preparation for Chants FC V1.

**Do not submit yet.** Final screenshots, public URL readback, review access, release signing, exact-binary checks, store questionnaires, and the open-production walkthrough are still gates. The machine-readable source for the copy below is `store/submission.json`.

## 1. Identity to use everywhere

| Field | Value |
|---|---|
| Store name | Chants FC |
| Installed name | Chants |
| Operator | ThunderRiver Tech LLC |
| Support | support@chantsfc.com |
| iOS bundle ID | com.chants.chants |
| Android package name | com.chants.chants |
| V1 markets | United States, United Kingdom, Canada |
| Account minimum age | 17+ |

The 17+ value is the app's account rule. It does not pre-answer either store's content-rating questionnaire. Complete each questionnaire from the exact release behavior and content.

## 2. Public URLs

Enter these only after each URL opens successfully in a signed-out private window and on a phone using mobile data.

| Purpose | URL |
|---|---|
| Marketing | https://chantsfc.com/ |
| Support | https://chantsfc.com/support |
| Privacy | https://chantsfc.com/privacy |
| Terms | https://chantsfc.com/terms |
| Community Rules | https://chantsfc.com/community |
| Rights and takedown | https://chantsfc.com/rights |
| Account deletion | https://chantsfc.com/delete-account |

For every page, verify the visible operator name is exactly `ThunderRiver Tech LLC`, the support address works, there is no maintenance or placeholder copy, and the page does not require an account.

## 3. Apple App Store Connect

Open the existing Chants FC record. Use locale `English (U.K.)`.

### App information

| Field | Copy |
|---|---|
| Name | Chants FC |
| Subtitle | Football chants, together |
| Primary category | Sports |
| Secondary category | Social Networking |
| Privacy Policy URL | https://chantsfc.com/privacy |

Sports is primary because the first job is finding, learning, and saving football chants. Social Networking is secondary because Stage, creator profiles, follows, likes, comments, and shares are meaningful but support the football purpose.

### Version information

**Promotional text**

```text
Learn your club's songs, save them for matchday, and take the Stage with original 30-second performances. Follow creators and help the next chant travel.
```

**Keywords**

```text
football,soccer,songbook,supporters,terrace,matchday,fan songs,stadium,lyrics
```

**Description**

```text
Football sounds better together.

Chants FC brings the supporter songbook and the workshop for what gets sung next into one place.

LEARN THE SONGBOOK
Browse Premier League clubs and players, read clear chant lyrics, see which songs are Terrace Proven, and keep community ideas separate in Chant Lab.

TAKE IT TO MATCHDAY
Save one chant or a club's Songbook to your device before you leave. Open those saved lyrics again when stadium connectivity lets you down.

BUILD WHAT GETS SUNG NEXT
Submit a chant as something already sung or something you made. Evidence is optional when you post, but only current real-world evidence and operator review can make a chant Terrace Proven.

STEP ONTO THE STAGE
Record or upload a video up to 30 seconds. New performances stay private until review. Watch supporter performances, like, comment, share, follow creators, report abuse, and block accounts.

KEEP THE SONGBOOK LIVING
Suggest a correction, variation, or better evidence when a chant is wrong or dated. An operator reviews suggestions before any catalogue change.

Chants FC is an independent supporter service. It is not affiliated with or endorsed by any club, league, player, or music rightsholder. You must be at least 17 to create an account.
```

**Support URL**

```text
https://chantsfc.com/support
```

**Marketing URL**

```text
https://chantsfc.com/
```

### App Review information

Create a dedicated reviewer account. Do not put its credentials in Git, a document, a screenshot, or chat. Enter them only in App Store Connect.

**Review notes**

```text
Chants FC is a supporter songbook and moderated creator platform. Account creation and most interactions require sign-in. Use the dedicated review account supplied privately in App Store Connect. The account must be verified, 17+ confirmed, on current policy v2, and able to browse seeded Premier League content. Performance uploads are limited to 30 seconds and remain private until operator approval. The reviewer can browse Stage, Clubs, Songbook, and You; open chant lyrics; save a local Matchday Songbook; submit feedback; report or block supported content; and request account deletion from You. Public deletion instructions are at https://chantsfc.com/delete-account. Chants is independent and is not affiliated with clubs, leagues, players, or music rightsholders. If production is in maintenance, do not submit the build because review access will fail honestly.
```

Before submission, use the exact reviewer credentials on a clean device. Confirm the account is not banned, deletion-pending, policy-stale, unverified, empty, or dependent on an operator role.

### Apple screenshots

Use the five scenes in `store/screenshots/manifest.json`, the capture runbook in `store/screenshots/README.md`, and the reusable presentation source in `store/screenshots/frame.html`. Target 1320 by 2868 portrait PNGs with no alpha. One to ten screenshots are allowed, but this packet uses five distinct product jobs. Do not reuse the old 1320 by 2663 documentation images or publish a frame that still shows its missing-source warning.

### Apple App Privacy and rating

Use `docs/STORE_PRIVACY_WORKSHEET.md`. Reconcile every selection against Apple's final binary privacy report and the included SDK versions. Then answer the age-rating questionnaire from actual app content. Do not copy the app's 17+ account rule into the store rating as a shortcut.

## 4. Google Play Console

Use default language `English (United Kingdom)` unless the existing record has another approved default.

### Main store listing

| Field | Copy |
|---|---|
| App name | Chants FC |
| Category | Sports |
| Contact email | support@chantsfc.com |
| Website | https://chantsfc.com/ |
| Privacy policy | https://chantsfc.com/privacy |

**Short description**

```text
Learn football chants, save a matchday songbook, and share your own take.
```

**Full description**

```text
Football sounds better together.

Chants FC brings the supporter songbook and the workshop for what gets sung next into one place.

Learn the Songbook
Browse Premier League clubs and players, read clear chant lyrics, see which songs are Terrace Proven, and keep community ideas separate in Chant Lab.

Take it to matchday
Save one chant or a club's Songbook to your device before you leave. Open those saved lyrics again when stadium connectivity lets you down.

Build what gets sung next
Submit a chant as something already sung or something you made. Evidence is optional when you post, but only current real-world evidence and operator review can make a chant Terrace Proven.

Step onto the Stage
Record or upload a video up to 30 seconds. New performances stay private until review. Watch supporter performances, like, comment, share, follow creators, report abuse, and block accounts.

Keep the Songbook living
Suggest a correction, variation, or better evidence when a chant is wrong or dated. An operator reviews suggestions before any catalogue change.

Chants FC is an independent supporter service. It is not affiliated with or endorsed by any club, league, player, or music rightsholder. You must be at least 17 to create an account.
```

### App access

Choose that some functionality is restricted. Put credentials only in Play Console.

```text
Select that some functionality is restricted. Enter only the dedicated review account credentials in the private Play Console. The account must be verified, 17+ confirmed, on current policy v2, and able to browse seeded Premier League content. Start on Stage, then use Clubs, Songbook, Create, and You. Performance uploads stay private until operator approval. Account deletion is under You and public deletion instructions are at https://chantsfc.com/delete-account. Do not submit while production is in maintenance.
```

### Google graphics

- App icon: `store/assets/google-play-icon.png`, 512 by 512 PNG, no alpha required by this project even though Google permits it.
- Approved feature graphic: `store/assets/google-feature-graphic.png`, 1024 by 500 RGB PNG with no alpha. Its reproducible source is `store/assets/google-feature-graphic.html`. It uses the current Stage and Club Signal identity without club crests, player images, fake ratings, awards, rankings, or store badges. Andrew granted visual acceptance on 3 September 2026, so `googleFeatureGraphicFinal` is true.
- Phone screenshots: use the five 1080 by 1920 paths in the manifest. Capture from the exact release candidate or make a truthful crop only when it preserves the real interface and store rules.

### Data safety, content rating, and account deletion

Use `docs/STORE_PRIVACY_WORKSHEET.md`, verify the public deletion page, complete the content-rating questionnaire, declare the moderated user-generated-content behavior, and provide the reviewer account. Do not mark the listing ready while any of these remain incomplete.

## 5. Claims that must stay out

Do not claim or visually imply:

- official club, league, player, supporter-group, or music-rightsholder affiliation;
- licensed music, broadcast footage, player imagery, or club crests;
- a number-one ranking, award, testimonial, download count, rating, or engagement count that is not real;
- Apple, Google, Facebook, phone, or magic-link sign-in in a build where it is disabled;
- live scores, fixtures, match chat, notifications, karaoke generation, autoplay, or any V1.1 idea;
- cloud sync for Saved Matchday Songbook, which is device-local in V1;
- instant publication of performance video, which stays private until review;
- evidence as mandatory for a new chant, or popularity as proof that a chant is already sung.

## 6. Final readiness sequence

Complete these in order and change `store/submission.json` only when evidence exists:

1. Merge and tag the exact release candidate.
2. Open production under the approved rollout controls and pass the owner walkthrough.
3. Verify all seven public URLs signed out on Wi-Fi and mobile data.
4. Send and receive a support test through `support@chantsfc.com`.
5. Create and test the dedicated reviewer account on clean iOS and Android installs.
6. Verify the iOS distribution archive and Android release app bundle from the same source and configuration.
7. Capture the five iOS and five Android scenes, inspect every pixel, and mark each manifest scene captured.
8. Confirm the recorded final Google feature graphic approval. Complete on 3 September 2026.
9. Enter Apple App Privacy, Google Data safety, and both rating questionnaires from the exact binary.
10. Enter the metadata and private access instructions in both consoles.
11. Run `node scripts/check-store-submission.mjs` and the complete clean CI suite.
12. Review each store preview, then authorize submission separately.

`prepared_not_submitted` is the correct status until every gate above except actual submission is complete.

## 7. Official references used

- [Apple platform version information and field limits](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Apple app information, subtitle, and privacy URL](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
- [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple App Privacy management](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [Google Play store listing setup](https://support.google.com/googleplay/android-developer/answer/9859152)
- [Google Play graphic asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151)
- [Google Play metadata policy](https://support.google.com/googleplay/android-developer/answer/13393723)
- [Google Play user-data and deletion policy](https://support.google.com/googleplay/android-developer/answer/10144311)
- [Google Play Data safety form](https://support.google.com/googleplay/android-developer/answer/10787469)
