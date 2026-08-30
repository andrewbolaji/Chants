# Decision 006: User chants require origin and evidence before promotion

- **Status:** Accepted
- **Date:** 2026-08-22
- **Owner:** Andrew
- **Related:** Decision 004, Songbook and Chant Lab

## Context

The existing `canonical` and `community` status distinguishes seeded archive content from user submissions internally, but it did not record whether a submitter heard a chant or invented it. Votes and an operator action could promote a user chant without supporting evidence. The existing media fields also could not safely serve as proof because they carried no bounded provider or normalization contract.

The v1 product needs to welcome funny and original work without presenting popularity as terrace history. It also needs to preserve existing sourced seed records and avoid taking on hosted-media storage, playback, moderation, and licensing work.

## Decision

Every new user chant stores an immutable `origin` of `alreadySung` or `originalIdea`. Evidence remains optional at submission and is stored separately as either null or a strict two-key map:

```text
evidence: {
  provider: "youtube" | "x",
  url: canonical HTTPS content URL
}
```

The only canonical stored URL forms are a YouTube watch URL with an exact 11-character video ID and an X status URL with a bounded handle and a 1-to-25-digit numeric status ID. The client derives the provider while normalizing approved YouTube, youtu.be, X, and Twitter inputs. Firestore rules and Cloud Functions independently validate the canonical stored form.

A user-created chant can become `canonical`, shown as Terrace Proven, only after valid evidence is retained and an operator explicitly promotes it. Votes never promote or prove a chant. The `createdBy: "system"` sourcing-ledger exception preserves seeded canonical records without requiring a public clip on every document. New seed projections explicitly set `origin: alreadySung`; dated review sources remain offline catalogue metadata and are not misrepresented as canonical public YouTube or X evidence.

Origin is immutable. Authors may edit the existing content allowlist only while a chant is `community`. Removing evidence from a user-created canonical chant deletes the evidence and demotes it to `community` in the same server transaction. Existing documents with absent or malformed provenance remain readable and moderatable, but malformed evidence is never rendered as a link or accepted for promotion.

Evidence opens only through an explicit operating-system link-out. Chants does not fetch, preview, embed, download, host, transcode, autoplay, or play the linked media in the background.

## Alternatives considered

| Alternative | Benefit | Cost or risk | Why not chosen |
|---|---|---|---|
| Require evidence for every post | Strong intake proof | Excludes honest matchgoers without a clip and slows creation | Evidence is required at promotion, not admission |
| Let votes promote | Cheap community automation | Popularity or brigading becomes false proof | Votes rank taste and momentum only |
| Reuse `mediaUrl` and `mediaType` | No new fields | Blurs playback media with provenance and lacks a strict proof contract | Evidence has a distinct trust purpose |
| Host or embed video | Richer consumption | Adds media safety, privacy, copyright, storage, playback, and cost work | V1 validates demand through explicit link-out |
| Automatically trust any operator write | Simpler rules | Raw Firestore writes can bypass the callable invariant | Direct-client and Admin SDK boundaries must agree |

## Consequences

- Positive: Cards and detail can distinguish Terrace Proven, an unverified Already sung claim, an Original idea, and a legacy community record without relying on color.
- Positive: Submission stays open to fans without immediate evidence, while promotion remains evidence-gated.
- Positive: The stored link surface is small, canonical, provider-bound, and removable.
- Negative: The client, rules, and Functions validators duplicate a security contract and must change together.
- Positive: Decision 025 adds a private, reviewed post-submission evidence path without changing this provider or promotion contract.
- Operational: Firestore rules must reach clients before the origin-aware release, and Functions must reach operators before the new promotion workflow. Exact projects and deployment commands require separate authorization.

## Validation and revisit trigger

- **Evidence:** Focused Dart, widget, Functions, and rules tests cover accepted and deceptive URLs, absent legacy fields, required origin, one-write duplicate review, honest labels, link launch failure, promotion rejection, system compatibility, and evidence-removal demotion. Representative 390 by 844 goldens cover the new form hierarchy.
- **Revisit when:** YouTube or X link availability is too low for legitimate promotion, another provider has an approved moderation and canonicalization contract, or hosted media has proven demand plus approved legal, safety, privacy, cost, and operational controls.
