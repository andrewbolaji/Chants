# Decision 023: Gate product authority on verified identity and server onboarding

- **Status:** Accepted
- **Date:** 2026-08-28
- **Owner:** Andrew
- **Related:** Decisions 011, 012, 016, and 017; V1 launch authentication, onboarding, and Android readiness

## Context

The inherited client created a private profile directly during email and password signup. It did not verify email ownership, recover a missing profile, support linked providers, or distinguish a successful Firebase identity from an account allowed to mutate Chants. Adding Apple, Google, Facebook, magic email links, and phone authentication makes Firebase Auth the stable identity source, but provider UI alone cannot grant product authority.

Firebase does not represent every valid identity in the same way. Password and magic-link accounts can carry a verified email. Phone accounts carry a verified phone number. A federated identity can be the current sign-in provider or a provider linked to an account that later signs in another way. Facebook authentication specifically cannot be reduced to the email-verified bit.

The app also needs one recoverable initial profile write. A direct client create would let the client choose protected fields or leave policy, age, and profile state split across partial writes.

## Decision

Firebase Auth owns the stable UID, authentication credentials, contact verification, and linked-provider set. A protected Chants mutation requires at least one of these Firebase token facts:

1. `email_verified` is true.
2. `phone_number` is present.
3. The current sign-in provider or linked identity set includes Apple, Google, or Facebook.

Callable and Firestore or Storage rules enforce the same boundary. The Flutter gate mirrors it from the live Firebase user only to choose the correct screen. UI state is never server authority.

Initial `profiles/{uid}` creation is server-only. `completeOnboarding` derives the UID from verified Firebase auth, accepts only display name plus explicit 17-plus and current-policy confirmations, and transactionally creates the pinned private profile and deterministic policy audit. A duplicate request returns the existing coherent result. An existing banned, deleting, policy-incoherent, or age-incoherent profile is not overwritten.

The exact date of birth stays in the current device form. Only the confirmed 17-plus result crosses the callable boundary. Account-deletion recovery is evaluated before verification or onboarding so a pending account cannot escape its existing gate by changing providers.

Provider linking is a signed-in Firebase operation that preserves the current UID. A credential collision does not trigger an application-level merge or deletion. The user signs in through the owning method and links deliberately from Sign-in methods. The final usable method cannot be unlinked.

Apple, Google, Facebook, magic link, and phone entry are fail-closed build features. Their buttons remain absent unless an operator intentionally enables the matching compile-time flag after native, provider-console, policy, callback, cost, and device checks. Magic-link pending email, request time, and optional linking UID share one versioned device-local record for no more than one hour. Completion, explicit cancellation, terminal invalidity, or expiry clears it; an ambiguous send failure retains it because Firebase may have accepted the request. One phone attempt owns manual entry, automatic verification, and every resend so two callbacks cannot consume two credentials. Cancelling that attempt is terminal, including when an in-flight credential later fails. The visible cooldown guards every new SMS request path.

Provider initialization and status feedback follow confirmed outcomes. A rejected Google initialization is not cached for the rest of the process. Email verification reports whether Firebase was actually asked to send. A requested magic link remains pending until the user opens it; returning from the request screen cannot claim the method is already connected.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Treat any Firebase session as verified | Simplest gate | An unverified password account could create content and interact through raw SDK paths | Authentication alone does not prove a reachable identity |
| Trust only `email_verified` | One token bit | Phone and Facebook users can be stranded; linked-provider sessions become inconsistent | Valid Firebase identities use different claims |
| Trust only the most recent sign-in provider | Easy callable check | A linked federated identity loses authority after a later password sign-in | Authority belongs to the verified linked identity set, not the last button used |
| Keep direct client profile creation | No callable | The client owns protected defaults and can leave partial policy or age state | Initial authority must be coherent and server-owned |
| Store date of birth in Firestore | Easier future age checks | Retains more personal data than V1 needs | The product needs the admission result, not the date |
| Merge accounts automatically when emails match | Less recovery UI | Can combine two distinct UIDs and ownership graphs without deliberate proof | Linking must preserve explicit account control |
| Show every requested provider immediately | Demonstrates breadth | Unconfigured OAuth, SMS, callback, or policy state becomes a broken launch surface | Availability is a release assertion, not a design placeholder |

## Consequences

- Positive: a password account cannot enter onboarding or mutate protected data until its email is verified.
- Positive: Apple, Google, Facebook, phone, and magic-link users do not repeat a redundant challenge when Firebase already proves the identity.
- Positive: onboarding retries converge without a half-created profile or client-selected authority fields.
- Positive: linked providers preserve creator identity, follows, interactions, Songbook ownership, moderation history, and deletion work under one UID.
- Positive: missing provider or SMS setup removes the button instead of exposing a predictable runtime failure.
- Positive: transient initialization, delayed profile projection, and ambiguous email delivery preserve a retry or escape path.
- Positive: Storage operator preview requires the same verified-contact proof as other operator authority.
- Negative: existing unverified password accounts are placed behind verification before their next protected action.
- Negative: provider enablement requires coordinated Firebase, Apple, Google, Meta, domain, signing, privacy, and device work outside source.
- Negative: the client carries several native provider SDKs before every provider is publicly enabled.
- Compatibility: existing coherent profiles need no schema migration. New direct profile creates are denied, so the callable and compatible client must deploy before new signup is opened.

## Validation and revisit trigger

- **Evidence:** `functions/src/onboarding.ts`, `functions/src/safety_submission.ts`, `functions/src/index.ts`, `firestore.rules`, `storage.rules`, `lib/data/repositories/auth_repository.dart`, `lib/app/app.dart`, `lib/presentation/auth/`, `lib/presentation/settings/sign_in_methods_screen.dart`, auth and app-gate tests, native contract checks, `docs/changes/2026-08-28-v1-launch-auth-onboarding-android.md`, and `docs/changes/2026-08-28-post-auth-independent-review-corrections.md`.
- **Revisit when:** a new provider has no trustworthy token representation, the product needs verified identity recovery across merged UIDs, age requirements change, magic-link retention must cross devices, passkeys replace a launch method, or provider SDK and binary cost exceed measured value.
