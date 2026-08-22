# Chant provenance and evidence

**Completed:** 2026-08-22
**Type:** Lane 2 persistent schema, authorization, moderation, and external links
**Application behavior changed:** Submission, chant trust labels, detail link-out, duplicate review, and operator promotion

## Change identity and boundary

- **Change:** Record a fan's claimed chant origin, allow one bounded external evidence link, require evidence plus operator review before a user chant becomes Terrace Proven, and connect the existing duplicate matcher to submission as a soft nudge.
- **Target:** Stacked branch `codex/v1-provenance-evidence` and draft PR 6.
- **Included:** Flutter models and form behavior, URL normalization and link-out, card and detail labels, duplicate review, moderation controls, callable trust transitions, Firestore rules parity, one runtime dependency, tests, goldens, and durable framework records.
- **Excluded:** Songbook and Chant Lab browse separation, evidence attachment after posting, hosted or embedded media, uploads, ranking changes, share-out, Saved Matchday Songbook, live Firebase access, deployment, migration, and release.
- **Approval:** Andrew explicitly approved `docs/CHANGE_SPEC.md` before runtime, Functions, or Firestore rules implementation began on 2026-08-22.

## Outcome

- Every new direct-client chant create requires `origin: alreadySung | originalIdea`; existing documents with no origin still decode and receive a neutral Community chant label.
- Evidence remains optional at posting. Approved YouTube, youtu.be, X, and Twitter content URLs normalize to one strict provider-bound canonical form. Deceptive hosts, credentials, ports, unsupported content, malformed IDs, oversized X IDs, and extra stored map keys are rejected.
- Evidence opens only through an explicit operating-system link-out that names the destination and says it leaves Chants. Missing or malformed legacy evidence is not tappable, and launch failure stays recoverable on the current screen.
- Canonical UI copy is Terrace Proven. Community records say Already sung unverified, Original idea, or Community chant instead of implying votes are proof.
- Submission keeps every field retained, requires origin before lookup, preserves the draft through validation and duplicate review, and permits View chant, Post mine anyway, Go back, or sheet dismissal. Advisory lookup failure fails open. The in-flight guard permits at most one create.
- User promotion requires valid retained evidence in both the operator callable and raw Firestore rules. The system sourcing-ledger exception preserves seeded records. Promotion freezes author edits.
- Evidence removal and any required user-chant demotion occur with the audit record in one Firestore transaction. Repeated trust actions do not add redundant audit records.
- Unchanged malformed legacy evidence does not prevent an operator from hiding or removing old content, but it cannot be mutated as malformed or used for promotion.

## Invariants preserved

- `canonical` remains the internal Terrace Proven state and `community` remains non-proven community work.
- Votes rank taste and momentum only. They never promote or prove a chant.
- Existing system-owned seed records continue to rely on the external sourcing ledger and are not migrated or rewritten.
- The flexible input normalizer, strict stored schema, Cloud Functions guard, and Firestore rules validator agree on the two canonical provider and URL pairs.
- Origin is immutable after create. Evidence is immutable from the author client and removable only through the audited operator action in this block.
- External media is not fetched, previewed, downloaded, hosted, transcoded, autoplayed, or played in the background.
- No live Firebase request, deployment, data migration, or release occurred.

## Verification

- `flutter test`: 206 passed locally, including model compatibility, parser cases, submission orchestration, provenance display, launcher success and failure, and the representative golden.
- `flutter analyze lib test`: no issues.
- `cd functions && npm test`: 35 passed, including 9 trust-planner cases.
- `cd seed && npm test`: 42 passed.
- `cd test_rules && npx tsc --noEmit`: exit 0.
- GitHub Actions run `32574241342`: Flutter tests, Flutter analysis, Functions, seed, and rules jobs all passed on the clean PR merge commit. The Java 21 Firestore emulator reported 117 passing assertions.
- Red-check: temporarily disabling the Functions evidence requirement made `rejects promotion of a user chant without valid evidence` fail on its missing exception. Restoring the guard made the focused and full suites pass.
- Visual evidence: `submit_chant_origin.png` and `submit_chant_evidence.png` were generated at a 390 by 844 logical viewport, passed the bounded cross-platform comparator, and were visually inspected for hierarchy, overflow, and complete helper copy.
- Scope evidence: `git diff --check` passed. The implementation commit excluded Android Gradle edits and unrelated `pubspec.lock` version and SDK bumps; only the new `url_launcher` dependency lock entries were committed.

## Security, privacy, abuse, and infrastructure impact

The evidence field is untrusted user input. The client normalizes it, rules validate direct writes, Functions revalidate Admin SDK promotion, and the UI reparses before rendering a link. Raw authors cannot change origin or evidence, raw operators cannot promote an unsupported user chant, and removing evidence cannot leave that chant canonical. Evidence links may disclose ordinary browser or external-app request metadata when the user explicitly opens them; Chants performs no background request.

`url_launcher 6.3.2` is the only new runtime dependency. The change requires coordinated Firestore rules, Functions, and client rollout, but exact Firebase projects and deploy commands still need separate authorization.

## Rollout, rollback, and follow-up

Deploy rules before exposing the origin-aware client, then deploy Functions before using the new operator promotion workflow. The client reader is backward compatible, so no bulk migration gates release. Do not roll back to rules or Functions that permit evidence-free user promotion while the new trust labels remain visible.

Draft PR 6 remains unreviewed and unmerged. Complete the stacked review after PRs 4 and 5, then include submission, duplicate review, evidence link-out, promotion rejection and success, and evidence-removal demotion in the combined live-device walk. The next independent product block is the Songbook and Chant Lab browse split.
