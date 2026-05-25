# Architectural Decisions

## Standing Rules
| Date | Rule | Detail |
|------|------|--------|
| 2026-05-24 | Measure, do not estimate | Every numeric claim in a summary or recap comes from an actual count (wc -l, test output, ls/find), taken seconds before typing it. |
| 2026-05-24 | Verify the verification | Before trusting a check, prove it fails when it should by introducing a deliberate failure. Lock the real command and config into the build. |
| 2026-05-24 | Recap-plus-commit close-out | A Block is closed only when the commit hash is recorded in the recap. |
| 2026-05-24 | No em dashes (standing rule) | Anywhere in app, copy, or docs. Commas, periods, parentheses, or rewrite. |
| 2026-05-24 | 9th-grade reading level (standing rule) | All user-facing copy. Concrete next steps in errors. |
| 2026-05-24 | Content safety is standing, not a feature | Every user-content surface ships with a report path and a moderation route. Security frame is mandatory on any Block touching user content. |
| 2026-05-24 | Simplicity check is part of done | A fan finds or places anything in one obvious tap. Simplest sensible layout, never dump everything at once. |
| 2026-05-24 | Differentiation through data, never forks | No hardcoded league or sport checks anywhere. Enabling a new league or sport is a data change. |

## Decisions
| Date | Decision | Reason |
|------|----------|--------|
| 2026-05-24 | App name is "Chants" | Clean, obvious, maps to function. Tifo rejected on diligence: Tifo Football is an established NYT / The Athletic football brand expanding into other sports, creating brand-confusion, trademark, and discoverability risk in our exact lane. |
| 2026-05-24 | Stack is Flutter plus Firebase (locked, no "or") | Genuinely mobile first, reuses Vouch experience, Firebase covers auth, Firestore, Storage, Functions, and push without standing up infrastructure. React plus Supabase rejected as it pulls web first and relearns a stack. |
| 2026-05-24 | Agnostic data model: Sport > Competition > Team > Chant, modeled as data from Block 1 | The anti-outflank move. Breadth is the cheapest thing to copy; the moat is depth. Architecture absorbs a new league or sport as rows, never a rewrite. |
| 2026-05-24 | Chants stored in one flat top-level collection with denormalized sportId / competitionId / teamId / playerId | Gives both drill-down (chants where teamId == X) and the cross-club shuffle (across all chants) cheaply, with no expensive joins, and makes a future search index trivial because everything searchable lives on one document. Deep subcollections rejected: collectionGroup queries for the shuffle are harder and the topology is costly to undo later. |
| 2026-05-24 | Vote ranking via denormalized counter fields (upvotes, downvotes, score, commentCount) on each chant, written by Cloud Functions | Firestore is weak at live ranked queries. Counters defined from Block 1 at 0 (even though voting ships in Block 4) so write paths and security rules account for them and we never backfill. Adding the fields later is free, but defining now avoids a retrofit. |
| 2026-05-24 | Full-text search deferred to an external index (Algolia or Typesense via the Firebase extension), not built in v1 | Firestore has no native full-text search. Browse-and-filter covers v1. The index is additive (reads existing chant docs, runs alongside), not a rewrite, so deferring costs nothing. Trigger pinned in WISHLIST. |
| 2026-05-24 | Submission and moderation ship together in Block 3 | A user-content surface cannot exist without a report-and-remove path. One is not safe without the other. |
| 2026-05-24 | State management: Riverpod (flutter_riverpod + riverpod_annotation) | Compile-safe, stream-friendly (Firestore snapshots, auth state), testable by design (easy provider overrides), no BuildContext needed in the data layer. Lighter than Bloc for our needs (no complex state machines). The most common choice for new Flutter+Firebase projects. |
| 2026-05-24 | Operator role via profile get() in security rules, not custom claims | At Block 1 volume, a single get() per operator action is fine. Trigger to migrate to custom auth claims set via Cloud Function: when any single rule would need to chain a second get(), OR before operator actions extend beyond the founder account. |
| 2026-05-24 | Firestore and Storage start locked (production mode, deny by default) | Real security rules deployed immediately. No test-mode window. Storage denies all reads and writes until Block 3 adds scoped media-upload rules. |
| 2026-05-24 | Auth: email and password only for v1 | Apple and Google sign-in noted for later. No code change to the repository pattern needed when added. |
| 2026-05-24 | profiles collection includes updatedAt timestamp | Supports display name changes and future profile edits. |
| 2026-05-24 | Storage and Cloud Functions deployment deferred to Block 3 | Trigger: media upload needing a live bucket, which is also when we decide Blaze billing. Block 1 stays on the free Spark plan (Auth and Firestore only). storage.rules (deny all) stays in the repo for Block 3. |
| 2026-05-24 | Firestore location: europe-west2 (London) | Permanent. Chosen for the UK audience (Premier League fans). Cannot be changed after creation. |

## Notes for Later Blocks
| Date | Note | Relevant Block |
|------|------|----------------|
| 2026-05-24 | Firestore query-versus-rules constraint: because the chants read rule requires hidden == false and removed == false, every browse/search query in Block 2 MUST include where('hidden', isEqualTo: false) and where('removed', isEqualTo: false), or Firestore rejects the whole query. Block 2 will need composite indexes in firestore.indexes.json for teamId, playerId, score, and createdAt sorts combined with those filters. | Block 2 |
| 2026-05-24 | Canonical seed mechanism: the chants create rule forces status == 'community' and zero counters, so the Block 2 canonical seed MUST run via an Admin SDK script or function (bypasses security rules), NOT through a client or operator UI create path. | Block 2 |
| 2026-05-24 | subjectTag and playerId consistency (subjectTag 'player' implies playerId non-null; 'club', 'coach', 'rival' imply playerId null) is validated at submission time in Block 3, not in security rules. | Block 3 |
| 2026-05-25 | Sign-up should client-validate displayName (1 to 50 chars, non-empty) so the user gets a clear error message instead of a raw permission-denied from Firestore rules. Address when sign-up UX is polished. | Block 6 |
| 2026-05-25 | profiles are world-readable, so the role field is publicly visible (reveals who operators are). Low severity, accepted for v1. Goes away when operator role moves to custom auth claims. | Future (custom claims migration) |
