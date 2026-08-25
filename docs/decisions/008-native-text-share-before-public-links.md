# Decision 008: Native text share precedes public chant links

- **Status:** Accepted
- **Date:** 2026-08-24
- **Owner:** Andrew
- **Related:** Decisions 004 and 005, Songbook and Chant Lab and stable seeded identity

## Context

Sharing is part of the approved v1 creator and distribution loop, but Chants currently has no deployed public chant resolver, universal-link contract, or web fallback. A guessed URL would send recipients to a dead destination. Waiting for the website would also leave a useful, low-cost distribution job unfinished even though the chant itself is enough to share.

The receiving application is outside Chants' control. A native share API can present available destinations, but its result does not prove that a recipient received or retained the text.

## Decision

Live chant detail uses the operating-system share sheet with a complete plain-text rendition:

- current chant title;
- optional team name already known by the route;
- full main lyrics;
- tune;
- honest Terrace Proven or Chant Lab wording;
- an optional validated HTTPS public URL, omitted in current builds; and
- `Shared from Chants`.

The action uses the current visible stream value, allows only one outstanding platform invocation, passes a non-zero source rectangle for iPad, and never claims delivery after any returned status. Invocation failure is recoverable and does not erase detail state.

Current production wiring passes no URL. A later public-route change may supply one only after defining stable-ID resolution and visible, hidden, removed, unknown, web-fallback, and app-not-installed behavior. Mutable titles never become URL identity.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Wait for a public website | Every share could link back | Delays a useful v1 action behind a separate product and hosting boundary | The lyrics are a useful text share now |
| Guess a chant URL | Fastest link-shaped implementation | Recipients reach a broken destination | A dead link damages trust |
| Share only title and marketing copy | Very short payload | Does not help the recipient learn or pass on the chant | The fallback must stand alone |
| Generate branded images or video | More visual distribution | Adds rendering, temporary files, media QA, accessibility, moderation, and platform variance | Deferred until the text boundary is proven |
| Integrate individual social SDKs | Tailored posting | Adds accounts, permissions, policies, tracking, and service-specific failures | The system sheet covers the v1 user job |

## Consequences

- Positive: fans can distribute a useful chant through any compatible installed destination without waiting for a website.
- Positive: share copy preserves provenance and does not let popularity become proof.
- Positive: no new backend, permission, hosted data, analytics, or recurring cost exists.
- Negative: current shares have no route back into Chants.
- Negative: plain text has no branded preview and can be reformatted or retained by the receiving application.
- Operational: `share_plus 11.1.0` becomes a client runtime dependency and native compilation plus device presentation become release gates.

## Validation and revisit trigger

- **Evidence:** Exact payload and gateway tests, production-detail widget tests, a deliberate missing-lyrics red check, a visually inspected 390 by 844 golden, and the local repository verification matrix. Clean-runner CI, native compilation, independent review, and device destination tests remain pending.
- **Revisit when:** A stable public resolver is live, sharing is a measured acquisition surface, users need branded previews, a receiving platform drops critical text, or package compatibility requires a build-tool upgrade.
