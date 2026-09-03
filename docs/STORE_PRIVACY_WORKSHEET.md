# Chants FC V1 store privacy worksheet

**Status:** Source-backed working answer set, not entered in either store

**Exact-binary recheck required:** Yes

This worksheet translates the current Chants behavior and included SDKs into conservative store-console answers. It is not a substitute for the exact release binary's Apple privacy report, Google Play SDK guidance, Firebase configuration, or the operator's final confirmation of how data is used.

## 1. Product boundary

Current V1 includes Firebase Authentication, App Check, Firestore, Functions, Storage, and Crashlytics. It does not include Firebase Analytics, Firebase Performance Monitoring, advertising SDKs, or a location feature.

Apple, Google, Facebook, phone, and magic-link entry points are disabled unless their explicit release flags and external configuration are approved. Email and password is the current launch path. Reopen this worksheet before enabling another provider.

Chants does not sell personal data, run targeted advertising, or use data to track people across other companies' apps or websites. Firebase is treated as an infrastructure processor only if the final contracts and configuration satisfy the applicable store service-provider exception. The operator must confirm that statement before selecting `not shared` in Google Play.

## 2. Data inventory from actual behavior

| Data | Example | Collected by server or SDK | Public | Required | Main purpose |
|---|---|---:|---:|---:|---|
| Email address | Sign-in, verification, recovery | Yes | No | Yes for email launch path | Authentication, account management, security |
| User ID | Firebase UID | Yes | No | Yes | Authentication, account ownership, security |
| Display name and creator handle | Comment name, public creator profile | Yes | Yes when the user participates publicly | Display name required, handle optional until creator setup | App functionality, community identity |
| Bio | Creator profile text | Yes | Yes if entered | No | App functionality |
| Chant and feedback text | Chant title, lyrics, context, suggestion, report reason | Yes | Some chant and comment content is public after applicable checks; reports are private | No | App functionality, moderation, support |
| Comments and one-level replies | Public discussion | Yes | Yes after current visibility rules | No | App functionality |
| Performance video and recorded voice | Up to 30-second upload | Yes | Only after operator approval | No | App functionality, moderation |
| Interaction activity | Follow, like, vote, share, comment, report, submit | Yes | Aggregate counts or content may be public; private edges stay restricted | No | App functionality, integrity, moderation |
| Saved Matchday Songbook | Saved chant IDs and local refresh state | Device-local only in V1 | No | No | App functionality |
| Crash and diagnostic data | Stack trace, device and OS state, app version, installation and session identifiers | Yes, automatically through Crashlytics and Firebase support services | No | Automatic when diagnostics are enabled | Reliability, diagnostics, security |
| Device or installation identifiers | Firebase installation, session, App Check or attestation identifiers | Yes, automatically | No | Automatic | App functionality, fraud prevention, security, diagnostics |
| IP address and connection metadata | Firebase service request | Yes, through infrastructure | No | Automatic | Service delivery, security, abuse prevention |
| Precise location | None | No | No | No | Not used |
| Contacts, health, financial, purchase, browsing, search-history, or advertising profile data | None | No | No | No | Not used |

Camera, microphone, and photo-library access happens only after the user chooses to record or select a performance. The selected or recorded video is collected only when the user continues with an upload.

## 3. Apple App Privacy working answers

Use `Yes` for data collection. Use `No` for tracking.

The table below is a conservative starting point. `Linked` means the product can associate the data with the account or content owner. Crash and device diagnostics are listed as not linked because the Chants source does not set a Crashlytics user identifier or attach account identity. Recheck that against the exact binary and Firebase console before entry.

| Apple category | Collected | Linked | Tracking | Purposes to select |
|---|---:|---:|---:|---|
| Contact Info, Email Address | Yes | Yes | No | App Functionality, Account Management |
| User Content, Photos or Videos | Yes | Yes | No | App Functionality |
| User Content, Audio Data | Yes | Yes | No | App Functionality |
| User Content, Other User Content | Yes | Yes | No | App Functionality |
| Identifiers, User ID | Yes | Yes | No | App Functionality, Account Management |
| Usage Data, Product Interaction | Yes | Yes | No | App Functionality |
| Diagnostics, Crash Data | Yes | No, subject to exact-binary check | No | Analytics, App Functionality |
| Diagnostics, Other Diagnostic Data | Yes | No, subject to exact-binary check | No | Analytics, App Functionality |
| Identifiers, Device ID | Yes | No, subject to exact-binary check | No | App Functionality, Fraud Prevention, Security |

Do not select advertising, third-party advertising, developer advertising or marketing, or cross-app tracking. Do not select precise location. Before final entry, inspect whether Apple's generated privacy report or the exact Firebase SDK guidance classifies IP-derived information or installation tokens under an additional type.

## 4. Google Play Data safety working answers

### Top-level answers

| Question | Working answer | Final check |
|---|---|---|
| Does the app collect or share required user data types? | Yes, collects | Confirm exact binary and SDKs |
| Is all user data encrypted in transit? | Yes | Verify every production URL and Firebase transport |
| Can users request deletion? | Yes | Verify in-app deletion and https://chantsfc.com/delete-account signed out |
| Is data shared with third parties? | No under the service-provider exception | Confirm Firebase contracts, configuration, and no later SDK |

### Data types

| Google category | Collect | Share | Required or optional | Purposes |
|---|---:|---:|---|---|
| Personal info, Name | Yes | No | Required display name; optional public creator identity | App functionality, Account management |
| Personal info, Email address | Yes | No | Required for current launch sign-in | App functionality, Account management, Fraud prevention/security |
| Personal info, User IDs | Yes | No | Required | App functionality, Account management, Fraud prevention/security |
| Photos and videos, Videos | Yes | No | Optional | App functionality |
| Audio files, Voice or sound recordings | Yes | No | Optional, as part of performance video | App functionality |
| Messages, Other in-app messages | Yes | No | Optional comments and replies | App functionality |
| App activity, App interactions | Yes | No | Optional actions plus automatic service interaction | App functionality, Fraud prevention/security |
| App info and performance, Crash logs | Yes | No | Automatic | Analytics, App functionality |
| App info and performance, Diagnostics | Yes | No | Automatic | Analytics, App functionality |
| Device or other IDs | Yes | No | Automatic | App functionality, Fraud prevention/security |
| Files and docs, Other files and docs | Recheck before final answer | No | The selected performance is already disclosed as video | Avoid double-counting unless Play requires it |
| Location, Approximate location | Recheck Firebase IP treatment | No | Automatic infrastructure metadata only | Do not select without the exact SDK or console basis |

Google can change the wording and taxonomy of the form. If the console separates public posts, reports, or creator biography differently, map them to the closest user-content or personal-info type and keep the more conservative answer.

## 5. Public content, moderation, and deletion disclosures

The store forms and reviewer notes must match these facts:

- Chant text and comments can become public. New performance video stays private until operator approval.
- Users can report supported content and accounts and can block creators in supported signed-in views.
- An operator can hide, restore, remove, ban, and unban through protected workflows.
- Account deletion is available in the app under You and by public web request.
- Deletion removes or anonymizes data according to the published retention and legal-hold policy. It is not described as instantaneous erasure of every backup or audit record.
- Saved Matchday Songbook is local to the device and is not advertised as server-synced.

## 6. Conditional provider disclosures

Do not select these data types merely because dormant source exists. Reopen the worksheet when any path is enabled in the exact release candidate.

| Provider or feature | Additional likely disclosure work |
|---|---|
| Apple or Google sign-in | Provider identifiers, email or name returned by the provider, provider privacy review |
| Facebook sign-in | Provider identifiers, email or name, Facebook SDK behavior and data-use review |
| Phone sign-in | Phone number and SMS authentication processing |
| Magic email link | Email delivery provider and link telemetry |
| Notifications | Device push token and notification interaction |
| API-Football matchday features | Match and fixture data only unless a new user-data flow is introduced |
| Analytics or ad SDK | Usage categories, sharing, tracking, consent, and regional requirements |
| Light and dark mode | No expected server data if preference stays local; verify implementation |

## 7. Exact submission checklist

Before entering either form:

1. Build the exact release binary with the exact provider flags.
2. Confirm the dependency lockfiles and included native SDKs.
3. Search source for Analytics, Performance Monitoring, advertising, user-ID attachment to Crashlytics, location APIs, push tokens, and new third-party SDKs.
4. Read Apple's generated privacy manifest report for the archive.
5. Read the current Google Play SDK Index and Firebase disclosure guidance for the locked Android dependencies.
6. Reconfirm whether Firebase is a processor under the store's current sharing definition.
7. Verify in-app and public-web deletion from a disposable account.
8. Enter the forms, save screenshots or exports privately, and set the matching readiness fields in `store/submission.json` only after readback.

## 8. Official references

- [Apple App Privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Google Play user-data and deletion policy](https://support.google.com/googleplay/android-developer/answer/10144311)
- [Google Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
- [Firebase privacy and security](https://firebase.google.com/support/privacy)
- [Firebase Android Play data disclosure](https://firebase.google.com/docs/android/play-data-disclosure)
- [Firebase Apple App Store data collection](https://firebase.google.com/docs/ios/app-store-data-collection)
