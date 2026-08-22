# Change spec: V1 chant provenance and evidence

**Status:** Approved, implemented and locally verified, PR CI pending
**Updated:** 2026-08-22
**Risk lane:** Lane 2, persistent schema, authorization, moderation, and external links
**Stack base:** Draft PR 5, `codex/stable-chant-identity`

This is the one active implementation specification on the stacked provenance branch. It replaces the stable-identity specification only on this branch. Andrew approved the product direction in decision 004 and explicitly approved this technical contract on 2026-08-22 before application, Functions, or Firestore rules implementation began.

## Outcome

- **Problem:** Community chants do not record whether the submitter heard the chant sung or invented it, external evidence has no safe storage or link-out contract, promotion to `canonical` requires no evidence, and the existing duplicate matcher is not connected to submission. The UI therefore blurs terrace history and new ideas, while an operator or callable can mark an unsupported user submission as verified.
- **Desired behavior:** Every new user submission records one honest origin. It may carry one normalized YouTube or X evidence link, but evidence remains optional at posting. User-created chants stay in Chant Lab until valid evidence exists and an operator promotes them. Existing seeded chants remain Terrace Proven through the retained sourcing ledger. Submission warns about likely duplicates without blocking an intentional post.
- **Non-goals:** The separate Songbook and Chant Lab browse surfaces, Top/New/Rising ranking, hosted or embedded media, uploads, evidence added after submission, deep-link sharing, public creator profiles, notifications, challenges, unlimited comment nesting, changing seeded source data, or touching live Firebase.
- **Review boundary:** Chant provenance and evidence models, URL normalization and external link-out, submission and duplicate nudge, honest provenance labels, promotion and evidence-removal moderation, Firestore rules, focused tests, one Flutter dependency, and framework records.

## Acceptance criteria and invariants

1. Every new client-created chant stores `origin` as exactly `alreadySung` or `originalIdea`. Neither `chantType` nor score stands in for origin.
2. Evidence is optional for both origins. When present it is stored as one `evidence` map containing only a derived `provider` and normalized `url`.
3. Stored evidence has one of two canonical forms: `https://www.youtube.com/watch?v={11-character-video-id}` or `https://x.com/{handle}/status/{1-to-25-digit-numeric-id}`. Input from approved YouTube, youtu.be, X, and Twitter URL forms is normalized before create. Unrelated query parameters and fragments are removed. HTTP, credentials, ports, deceptive hosts, non-video/profile links, malformed IDs, and unsupported providers are rejected.
4. Evidence opens only through the operating system as an external application or browser. Chants does not fetch, preview, scrape, download, host, transcode, autoplay, or play it in the background.
5. A user-created chant cannot transition from `community` to `canonical` unless its stored evidence is valid and an authenticated operator explicitly invokes promotion. The callable revalidates the stored record because the Admin SDK bypasses Firestore rules.
6. Raw operator Firestore writes enforce the same promotion invariant. Existing and future `createdBy: "system"` chants may remain canonical without public evidence because their proof is the operator sourcing ledger.
7. Origin is immutable after client creation. Authors may edit the existing content allowlist only while their chant remains `community`. Promotion therefore freezes author editing at the trust boundary.
8. Removing evidence from a user-created canonical chant also demotes it to `community` in one server-side transaction and records one audit entry. Removing evidence from a system chant does not change its canonical status.
9. Existing documents without `origin` or `evidence` remain readable. Existing community documents receive a neutral legacy-community label, and existing canonical system documents remain Terrace Proven. No destructive migration is required.
10. Before create, submission checks visible chants for the same team and subject and runs the existing pure matcher. If likely matches exist, the fan can open an existing chant, cancel, or post theirs anyway. No match, a failed advisory lookup, or an explicit continue leads to at most one create.
11. Form text and choices survive validation, duplicate review, external-link validation, and a failed create. The submit action remains disabled while the duplicate check or write is in flight.
12. User-facing copy says Terrace Proven, Already sung, I made this, Original idea, or Community chant. It never presents votes or the word verified as proof on its own.

Invariants:

- `status` remains the internal Songbook trust state: `canonical` maps to Terrace Proven and `community` does not.
- Votes rank taste and momentum only. They never create or imply evidence.
- Seed content and its sourcing ledger remain authoritative and are not rewritten by this block.
- Moderation and authorization checks exist at the real trust boundaries, Firestore rules for direct clients and Cloud Functions for Admin SDK writes.
- External evidence is untrusted user input even after normalization. Opening it is always an explicit fan or operator action.
- No production or staging read, write, deployment, or dashboard change is authorized by this specification.

## Persistent contract

### Chant fields

New optional fields are added to the existing flat `chants/{chantId}` document:

```text
origin: "alreadySung" | "originalIdea"
evidence: null | {
  provider: "youtube" | "x",
  url: canonical HTTPS URL
}
```

- New client creates require `origin` and may use `evidence: null`.
- Reads treat an absent field the same as null for backward compatibility.
- The model exposes a neutral legacy state when a community document has no origin. It does not invent an origin during read.
- `origin` and `evidence` are not overloaded into the existing `mediaUrl` or `mediaType` fields. Those fields describe the older media contract and do not prove provenance.
- The evidence provider is derived from the parsed URL. The client never trusts a separately selected provider.
- The evidence map has a strict key allowlist so later moderation metadata cannot be forged by a raw client.

### Evidence URL normalization

One pure Dart helper validates user input and emits the stored evidence record. A matching pure TypeScript helper validates stored evidence before promotion. Firestore rules accept only the two canonical stored patterns.

Accepted input families:

- YouTube `youtube.com/watch?v=...`, `youtu.be/...`, and `youtube.com/shorts/...`, including common `www` and mobile host variants.
- X or legacy Twitter `x.com/{handle}/status/{id}` and `twitter.com/{handle}/status/{id}`, including common `www` and mobile host variants.

Normalization removes unrelated query parameters and fragments, converts YouTube links to the canonical watch URL, and converts Twitter hosts to `x.com`. Exact known-good and known-bad fixtures are asserted independently in Dart, Functions, and Firestore rules tests. The three validators are a security contract and must change together.

### Trust and moderation transitions

```text
new user post
  -> community + required origin + optional evidence

operator promote
  -> reject if createdBy != system and evidence is absent or invalid
  -> canonical after valid evidence and review

operator remove evidence
  -> delete evidence
  -> if canonical and createdBy != system, set community in the same transaction
  -> append audit entry
```

- Promotion is idempotent when the chant is already canonical, but it never repairs or silently accepts an invalid user-created canonical state.
- A legacy user-created canonical chant without evidence may still be hidden or removed by an operator, but cannot be newly created through this change. Any such live document is reported for manual review rather than automatically rewritten.
- Raw operator updates keep `createdBy` and `createdAt` immutable, preserve valid status values, and cannot leave a newly promoted or evidence-stripped user chant canonical.

## Interface and interaction design

### Submission

- Add a required semantic choice near the start of the form:
  - **Already sung**, helper: `I have heard fans sing this.`
  - **I made this**, helper: `This is my chant idea.`
- Rename the current `Type` labels from the conflicting `Original` and `Novelty` to **Serious** and **Funny** while retaining the internal `sincere` and `novelty` values.
- Add `Evidence link (optional)` with copy naming YouTube and X and stating that the link opens outside Chants.
- Validate evidence locally before any duplicate lookup or Firestore create. An empty field is valid.
- Run the soft duplicate lookup only after the complete form is locally valid. The comparison uses visible same-team, same-subject candidates, title, and tune.
- The duplicate sheet says `Is it one of these?`, shows up to three candidates, and offers `View chant`, `Post mine anyway`, and `Go back` paths. It does not accuse the fan of copying and it does not merge content.
- Advisory lookup failure fails open to the create path because duplicate detection is not an authorization or data-integrity boundary. Create failure remains recoverable with the draft intact.

### Provenance and evidence display

- Replace the current `VERIFIED` badge copy with `TERRACE PROVEN` wherever canonical chants appear.
- Community cards and detail show one text label:
  - `Already sung, unverified` for `alreadySung` without canonical status.
  - `Original idea` for `originalIdea` without canonical status.
  - `Community chant` for a legacy community document with no origin.
- A valid evidence record adds a button whose label names its destination, such as `Watch on YouTube` or `View on X`, followed by `Opens outside Chants` in accessible supporting copy.
- A failed launch leaves the screen in place and shows a retryable message. Missing or malformed legacy evidence is not rendered as a tappable link.

### Operator review

- Promotion candidates show origin, evidence state, and an explicit external evidence action.
- Promote is disabled with explanatory copy when a user-created candidate lacks valid evidence. The server remains authoritative if the UI is bypassed.
- Evidence removal is available on applicable moderation cards and requires confirmation. The result copy states when removal also returned the chant to Chant Lab.

## Design and implementation seams

- Add typed `ChantOrigin`, `EvidenceProvider`, and `ChantEvidence` model values with backward-compatible Firestore decoding.
- Add a pure Dart evidence parser/normalizer and a small external-launch widget or service seam so success and failure are testable without opening a real application.
- Add `url_launcher` as the only new runtime package. The current unrelated local `pubspec.lock` version bumps remain unstaged; only dependency-owned lockfile hunks may enter this branch.
- Add a one-shot visible-team query to `ChantRepository`; filter subject locally before invoking `ChantMatcher`, avoiding a new Firestore index.
- Keep `ChantMatcher` pure. The submit screen owns the advisory orchestration and one-write guard.
- Extract a pure TypeScript promotion/evidence action helper from the callable so missing, malformed, valid, idempotent, and evidence-removal transitions have unit tests without deploying Functions.
- Keep Firestore rule URL validation strict to canonical stored forms. Input flexibility belongs only in the normalizers.
- Replace the author chant-update blocklist with an explicit content-field allowlist and require the existing resource status to be `community`.

## Failure and abuse analysis

| Condition | Expected behavior | Evidence |
|---|---|---|
| New post has no origin | Client validation stops; raw SDK create is denied | Widget and rules tests |
| Evidence field is empty | Submission succeeds with null evidence | Widget, model, and rules tests |
| Deceptive host such as `youtube.com.example.test` | Rejected before create and by rules or callable if bypassed | Shared known-bad cases across three suites |
| YouTube or X tracking URL | Normalized to the bounded canonical stored form | Dart and Functions unit tests |
| Generic profile, playlist, or home URL | Rejected as non-evidence | Parser and rules tests |
| Duplicate lookup times out or is denied | Advisory check fails open; one create is attempted | Submit orchestration test |
| Likely duplicate found | No write until the fan explicitly continues | Widget test with repository spies |
| Repeated tap during lookup or create | Submit stays disabled; at most one create | Widget test |
| Raw author changes origin or evidence | Denied | Rules tests |
| Author edits after promotion | Denied even for ordinary content fields | Rules tests |
| Raw operator promotes user chant without evidence | Denied | Rules test |
| Callable promotes user chant without or with malformed evidence | `failed-precondition`; no status or audit write | Functions tests |
| Valid user evidence plus operator review | Status becomes canonical and audit is appended | Functions unit test plus rules parity case |
| Evidence removed from user canonical chant | Evidence is deleted and status becomes community atomically | Functions unit test |
| Seeded canonical chant has no evidence | Remains readable and Terrace Proven | Model/widget compatibility tests |
| Legacy community chant has no origin | Remains readable with neutral Community chant label | Model/widget compatibility tests |
| Stored legacy evidence is malformed | No tappable link; promotion rejects it | Model/display and Functions tests |
| External application cannot open | Stay in Chants and show a retryable message | Widget test through launcher seam |

## Performance and cost

- **Submission read:** One extra visible-team query before a new chant create. Expected v1 team volume is small. The query reuses the existing visibility and team index path and is not run during ordinary browsing.
- **Client work:** Matching is bounded to one team's visible chants and returns at most three candidates. Record candidate count and elapsed time in local debug instrumentation only if the list becomes materially large.
- **Backend work:** Promotion adds one chant read before one update and one audit write. Evidence removal uses one transaction plus one audit write.
- **External cost:** No media bytes are proxied or stored by Chants. The only new behavior is an explicit OS link-out.
- **Revisit trigger:** Paginate or server-assist duplicate matching when a team exceeds 500 visible chants or local p95 matching exceeds 100 ms on the representative device.

## Rollout and recovery

- **Order:** Merge the stacked code, deploy Firestore rules before exposing the origin-aware client, deploy Functions before enabling operator promotion, then release the client. The exact deployment commands and named Firebase project require separate authorization.
- **Backward compatibility:** The released reader accepts absent provenance fields. New rules require origin only on new client creates, so no bulk migration gates rollout.
- **Canary:** In a non-production or explicitly authorized operator test, create one post per origin, one post without evidence, and one with each provider. Confirm the labels, link-out warning, duplicate nudge, promotion rejection, valid promotion, and removal-demotion behavior.
- **Healthy signals:** No increase in denied legitimate creates, no callable promotion without evidence, no unsupported stored domains, link launch errors remain bounded, and duplicate review does not materially reduce completed submissions.
- **Rollback:** The client can be rolled back because readers are backward compatible. Do not roll back rules or Functions to versions that allow evidence-free user promotion while the new trust labels remain visible. If link abuse appears, disable evidence entry and external actions in a forward fix while retaining stored records for operator review.
- **Data recovery:** No automatic deletion or migration. An invalid record found after release is hidden or has evidence removed through audited moderation.
- **Owner:** Andrew authorizes deploys and release. Codex implements and verifies repository changes only.

## Verification plan

| Claim | Check | Expected evidence |
|---|---|---|
| Models remain backward compatible | `flutter test test/data/models/chant_test.dart` | Absent and populated provenance records decode and round-trip as specified |
| URL contract is strict | Focused Dart, Functions, and rules cases over the same accepted and rejected examples | Every layer agrees on canonical stored values and rejects deceptive inputs |
| Submission requires origin and preserves the draft | Focused submit widget/orchestration tests | Validation and failure paths retain all entered fields |
| Duplicate nudge is soft and one-write | Repository-spy widget tests | No write before continue; view/cancel writes zero; continue and lookup failure write once |
| Provenance is understandable | Card/detail widget tests and 390 by 844 golden or screenshot | Terrace Proven, unverified sung claim, original idea, and legacy state are distinct in text |
| Link-out is explicit and recoverable | Widget tests with success/failure launcher | Destination named, outside-app warning present, failure stays on screen |
| Promotion invariant holds through direct clients | Firestore emulator suite | Missing and malformed evidence cannot become canonical; system compatibility remains |
| Admin SDK cannot bypass the product rule | Functions unit suite | Pure action helper rejects unsupported promotion and atomically demotes on evidence removal |
| Existing suites stay green | `flutter test`, `flutter analyze lib test`, `cd functions && npm test`, rules emulator suite, and `cd seed && npm test` | All touched and regression suites pass |
| New test proves behavior | Temporarily revert one core guard and run its focused test | Test fails for the intended reason, then passes after restoration |
| Interface is reviewable | Screenshot or golden at representative viewport plus later device walk | No overflow at normal and enlarged text; semantics remain readable |
| Stack remains scoped | `git diff --name-only codex/stable-chant-identity...HEAD`, `git diff --check`, and changed-prose dash search | Only approved provenance paths; no unrelated Android or lockfile version bump hunks |

## Approval

Andrew explicitly approved this technical specification on 2026-08-22. That approval authorizes repository implementation and verification on draft PR 6. It does not authorize Firebase deployment, live-data access, or release.

## Implementation evidence

- The typed origin and evidence contract, strict Dart normalizer, explicit external link-out, provenance labels, origin-aware submission, and soft duplicate review are implemented in the Flutter source.
- The callable now revalidates evidence before promotion and removes evidence transactionally, including demotion for user-created canonical chants. Firestore rules independently enforce origin, evidence, author-edit, and raw operator promotion boundaries while retaining moderation access to untouched malformed legacy records.
- Local verification passed 206 Flutter tests, 35 Functions tests, 42 seed tests, rules TypeScript compilation, and `flutter analyze lib test`. The two 390 by 844 submission goldens were generated and visually inspected without overflow or truncated helper copy.
- The required red-check was demonstrated by temporarily disabling the Functions promotion guard. Its focused test failed on the missing exception, then passed after restoration.
- The Firestore emulator suite could not run locally because this machine has no Java runtime. PR CI remains the required independent rules verification. No Firebase project was accessed and nothing was deployed.

## Open decisions

None. Exact spacing and component treatment may be refined during screenshot review without changing the schema, trust boundary, external-link contract, or duplicate behavior above.
