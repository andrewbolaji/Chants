# Decision 024: Stage launch integrity controls before enforcement

- **Status:** Accepted
- **Date:** 2026-08-29
- **Owner:** Andrew
- **Related:** Decisions 011, 018, 019, 021, and 023; V1 launch services configuration

## Context

Chants has release source for App Check, Crashlytics, public destinations, authentication providers, account deletion, and moderated performance video. The production services did not match that source. Neither mobile app was registered in App Check, Crashlytics had no complete native delivery path, custom domains were not associated, and no Cloud Monitoring alert or project budget existed.

Turning on every control immediately would not make the system safer. App Check enforcement before valid release traffic is observed can reject legitimate users. Publishing Android association before the production signing identity exists makes a false trust claim. A budget that automatically disables billing can take Songbook, moderation, and account recovery offline because of a configuration mistake. Cleanup and monitoring also need bounded behavior so the safety control does not become an unbounded cost source.

## Decision

Launch integrity is staged in this order:

1. Complete source integration and checks.
2. Register providers whose exact signed identity is already known.
3. Keep App Check unenforced while a controlled beta produces valid telemetry.
4. Configure notification and cost alerts that do not mutate service availability.
5. Enable enforcement only through a later, evidence-backed release decision.

The Apple association names only `J7V95LBCWR.com.chants.chants` and the four native route groups already declared in source. Android Asset Links is generated only from package `com.chants.chants` plus a supplied uppercase SHA-256 release or Google Play App Signing fingerprint. A missing fingerprint produces no hosted Android association file.

Crashlytics retains the existing privacy-minimal Flutter handlers and adds the required Android Gradle plugin plus release-only iOS symbol upload. No Analytics or Performance Monitoring dependency is added in this block. A first received and symbolicated report remains a controlled device-walk gate, not something source can claim.

Abandoned performance cleanup runs daily. It inspects at most 100 `awaiting_upload` or previously claimed `cleanup_pending` drafts whose creation time is at least 24 hours old. A transaction rechecks and claims the row before the exact staging path is removed. The document is deleted only after Storage removal succeeds. A failed removal preserves `cleanup_pending` for an idempotent retry. Pending review, approved, rejected, cancelled, or newer drafts are outside the cleanup query.

Operational backlog monitoring runs every 15 minutes. An account-deletion job becomes stale after 30 minutes without an `updatedAt` advance. A performance-media-deletion job becomes stale after 15 minutes. Each collection query reads at most 101 rows, reports at most 100, and records only counts plus a more-than-limit bit. Logs contain no UID, performance ID, media path, content, or raw document.

The initial billing control is a USD 25 monthly alert-only budget with actual thresholds at 50, 75, 90, and 100 percent and forecast at 100 percent. The billing account currently links only Chants, so Google persists the scope as `All projects (1)`. Linking another project requires a scope review before that change, because the budget must continue to represent Chants rather than a blended account. Function error and stale-job policies notify the owner through a confirmed channel. No control automatically disables billing or service admission.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Enforce App Check immediately | Strong rejection from the first build | Legitimate release traffic has not proved valid, and Android registration is blocked | Registration and observation must precede enforcement |
| Publish a placeholder Android fingerprint | Makes the association path look complete | Claims trust in an app identity that will not sign production installs | Absence is more truthful and safer |
| Delete every old performance draft in one scan | Simple cleanup implementation | Unbounded reads, writes, Function time, and Storage work | One capped page gives predictable cost and retry |
| Remove Storage before claiming the draft | Fewer Firestore writes | A concurrent submit can lose active media | Transactional state claim closes the race |
| Log stale document IDs for diagnosis | Easier direct lookup | Operational notifications retain private identifiers outside Firestore | Aggregate signal is sufficient to alert; diagnosis remains authorized and in-console |
| Disable billing when the budget fires | Hard spend ceiling | A false positive or small spike can take the product and safety workflows offline | Alert first, then use an explicitly authorized incident action |
| Add Analytics and Performance Monitoring now | Broader product and latency telemetry | New data collection, policy, dependency, and dashboard scope | Crash, server error, backlog, and cost signals are the launch minimum |

## Consequences

- Positive: missing or unverified provider configuration remains invisible and unenforced.
- Positive: association files cannot claim an invented signing identity.
- Positive: abandoned staging cost is bounded and recoverable after duplicate delivery or Storage failure.
- Positive: retained destructive jobs become alertable without exporting their identities.
- Positive: budget thresholds warn early without coupling a billing estimate to destructive automation.
- Negative: Android association, Play Integrity, several authentication providers, and DeviceCheck fallback remain incomplete until Andrew supplies external credentials and signing facts.
- Negative: the scheduled workers add a small fixed Function and Firestore cost after deployment.
- Negative: App Check does not reject invalid traffic during the observation window.
- Compatibility: no existing profile, public content, approved performance, rule, or client schema is migrated. `cleanup_pending` is server-owned and appears only on abandoned private drafts.

## Validation and revisit trigger

- **Evidence:** `hosting/.well-known/apple-app-site-association`, `scripts/generate-android-assetlinks.mjs`, `scripts/check-launch-services.mjs`, native Gradle and Xcode configuration, `functions/src/operations.ts`, scheduled exports in `functions/src/index.ts`, focused Functions tests, the Hosting emulator probe, and `docs/changes/2026-08-29-v1-launch-services-configuration.md`.
- **Revisit when:** valid iOS and Android beta traffic has been observed for 1 to 2 weeks, the Android production or Play signing fingerprints exist, a stale-job alert fires, cleanup approaches its 100-row cap, the USD 25 budget is repeatedly noisy, media cost per active creator is measured, or an automatic admission circuit breaker receives a separate recovery design.
