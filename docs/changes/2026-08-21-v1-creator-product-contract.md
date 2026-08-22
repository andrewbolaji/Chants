# V1 creator product contract

**Completed:** 2026-08-21
**Type:** Product, interface, and engineering-workflow documentation
**Application behavior changed:** No

## Change identity and boundary

- **Change:** Define Chants as a trusted Songbook plus a competitive Chant Lab, adopt the framework's project-memory records, and reconcile v1 versus later scope.
- **Target:** Local working tree on `main`.
- **Included:** `AGENTS.md`, the product spec, roadmap, wishlist, new project-memory files, and durable decision 004.
- **Excluded:** Flutter, Cloud Functions, Firestore rules, indexes, seed data, Firebase state, package manifests, commits, pushes, and deployment.
- **Request:** Decide whether evidence is optional or mandatory, place the approved creator ideas in v1, move heavier work to the future roadmap, and follow the updated Codex framework.

## Outcome

- Evidence is optional when a fan posts. A user submission cannot become Terrace Proven without valid retained evidence and operator review.
- Songbook, Chant Lab, Top, New, Rising, Already sung, I made this, and Terrace Proven now have one consistent product meaning.
- V1 is split into reviewable blocks: close the current interaction work, stabilize chant identity, add provenance and evidence, expose the two surfaces, add offline saves, then add basic share-out.
- Hosted media, creator profiles, follows, notifications, scheduled challenges, collaborative variants, deeper replies, and richer sharing remain explicitly sequenced later.
- `docs/EXECUTION.md`, `docs/LEARNINGS.md`, and `docs/INTERFACE.md` now provide the separate memory surfaces required by the updated framework.

## Important choices

| Choice | Reason | Alternative rejected | Follow-up |
|---|---|---|---|
| Optional evidence at admission, required evidence at promotion | A matchgoer may know a chant is sung without having a clip, while the verified label must remain factual | Mandatory link for every post, or vote-based verification | Lane 2 promotion and rules spec |
| Songbook and Chant Lab as separate meanings | One score cannot represent both terrace truth and creative popularity | Archive only, or one unlabeled mixed feed | UI slice with state and accessibility evidence |
| External link-out only in v1 | Tests demand without storage, transcoding, or hosted-media operations | Hosted or embedded video | Revisit only after the controls in decision 004 exist |
| Stable IDs before the remaining live seed and public links | Title-derived IDs have already orphaned a renamed record | Continue manual cleanup | Dedicated migration spec and recovery evidence |
| Preserve the active replies/security spec | The current working tree is already a large, separately approved release block | Fold the creator rebuild into it | Complete its device walk and archive it first |

## Security, privacy, abuse, and infrastructure impact

No runtime boundary changed. The future implementation is classified Lane 2 because it changes persistent chant data, operator promotion, external URL handling, and user-content trust claims. Its plan must include URL allowlisting and normalization, hostile input, dead links, report and removal behavior, migration compatibility, authorization, idempotency, recovery, and operator audit evidence.

No dependency, service, storage bucket, index, rule, function, or live Firebase state changed in this documentation block.

## Verification

- Confirmed the active `docs/CHANGE_SPEC.md` was not replaced or broadened.
- Inspected the current chant model, submit flow, ranking queries, Firestore create/update rules, moderation promote action, and seed data before documenting compatibility.
- Confirmed every new local path and cited source file exists.
- Project-memory structure check passed for all three files and their `AGENTS.md` references.
- Changed-guidance searches returned zero em dashes, unresolved template placeholders, or stale duplicate placements for the moved v1 features.
- `git diff --check` returned zero errors.
- `git diff --name-only -- seed seed_data` returned no paths.
- Reviewed the documentation-only diff and verified that no seed or application file was changed by this block.

## Known boundary and next step

This record approves no application implementation by itself. After the current interaction block passes its device walk, the next active `docs/CHANGE_SPEC.md` should cover stable chant identity because public share URLs, evidence records, saves, votes, comments, and later creator attribution all need identity that survives a title edit. The provenance slice follows that migration.

`docs/IMPLEMENTATION_RATIONALE.md` and `ENGINEERING_OVERVIEW.md` do not need refresh because runtime architecture and capability did not change.
