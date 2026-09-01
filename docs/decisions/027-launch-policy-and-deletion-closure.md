# Decision 027: Launch policy and deletion closure

- **Status:** Accepted in source; independent review, publication, deployment, and live use remain separate
- **Date:** 2026-08-31
- **Approval:** Andrew approved the V1 launch policy and deletion closure specification plus daily moderation review, urgent safety prioritization, ordinary support and video acknowledgement within two business days, verified deletion within 30 calendar days, and no 24/7 promise.
- **Scope:** Policy acceptance, signed-out help routes, public Hosting copy, user-authored deletion semantics, exact media cleanup, private externally verified deletion dispatch, and retention operations.

## Context

The first device launch exposed placeholder Content Policy copy. Users accepted one vague policy version, signed-out help had no complete Privacy, Terms, Rights, Support, or web deletion route, and account deletion preserved authored chant/comment bodies. Owned published video had no account-deletion media job, upload limits were omitted, and a deleted draft depended on a later event to retain staging cleanup evidence. A user who could not open the app had instructions but no reviewed route into the durable job.

Public policy cannot promise behavior the source does not perform. Privacy notice access is not blanket consent, while Terms and Community Rules do require an explicit accepted version. Deletion needs to preserve reply structure without preserving authored content, and external support must not become an unauthenticated target-selection endpoint.

## Decision

Use `v2` as the first real accepted Terms and Community Rules contract. Dart, one shared Functions authority, Firestore rules, and Storage rules pin the same version. A source conformance test covers every duplicate boundary. New onboarding names those two accepted documents; returning stale profiles re-gate. Privacy remains a separately linked notice. The 17+ account rule does not change.

Expose six matching signed-out destinations from the real app welcome and in Hosting source: Privacy, Terms, Community Rules, Rights and takedown, Delete account, and Support. A returning user blocked on the current contract keeps all six destinations, support, actual account deletion, and sign out without accepting. The app and web source give the same complete urgent child-safety instructions. They name ThunderRiver Tech LLC, `support@chantsfc.com`, the selected response targets, daily moderation, and the absence of a 24/7 promise. Source presence is not publication.

Account deletion removes authored chant fields and external references from user-created rows, replaces comment bodies and identity with non-identifying structural tombstones, deletes private activity and upload limits, and closes owned performance visibility. Seeded `createdBy == "system"` chants are outside user ownership and remain unchanged.

A performance requires a currently visible source chant. When deletion turns a user-authored chant into a hidden and removed tombstone, source reconciliation closes `sourceChantVisible` and removes the chant-title projection from every dependent performance. This includes a performance owned by another creator. The consequence makes that performance unavailable without deleting the other creator's account or treating their media as owned by the deleting account.

Before creator identity is removed from an owned performance, the same transaction creates or reuses its exact `performanceMediaDeletionJobs/{performanceId}` row. Before an owned draft row is removed, the same bounded transaction creates or links exact staging cleanup evidence with private `accountDeletionOwnerId`. Each transaction rechecks the current deletion phase, live owner, exact path, and existing cleanup identity. A stale worker or invalid/conflicting payload fails before mutation. Older schema-one jobs migrate to schema two and replay from authored-content cleanup so they cannot skip the stronger privacy phases.

The public deletion page supplies in-app and email instructions. A private local plan/apply command is the only support-side dispatch mechanism in source. It requires a clean reviewed source including Functions and both rule files, approved project and credential, active distinct operator, exact private plan and digest, non-identifying case reference, and an operator-attested account-control verification time within 24 hours. The command validates attestation freshness; it does not perform or independently prove the challenge. It passes the verified target into the same durable deletion workflow and writes a minimal operator audit. Email sender address, handle, password, sign-in code, or a public endpoint never becomes authority.

Retention uses approved operating targets, not an automatic blanket TTL. Unresolved cleanup evidence remains until exact closure. Ordinary correspondence, moderation evidence, routine logs, and terminal cleanup evidence receive separate review periods in the runbook. Provider periods are stated conditionally until read back.

## Consequences and alternatives

- Structural tombstones preserve reply relationships and remove authorship. Every comment and reply row follows that structural rule. Hard-deleting every comment would orphan conversations; retaining bodies would contradict the deletion promise.
- Decision 016 still permits restricted target-side safety or moderation records created by someone else to retain the deleted account ID until their own retention rule deletes or genuinely de-identifies it. This is disclosed in Privacy and deletion copy rather than mislabeled as authored content.
- A creator can lose public availability for a performance when the separate author of its source chant deletes their account. Preserving the performance as live would retain or sever the chant context that makes it intelligible, while deleting the other creator's media would exceed the deleting account's ownership.
- Replaying schema-one jobs may repeat idempotent cleanup and create another anonymous completion audit. That is safer than allowing an active old job to bypass new authored-content and upload-limit phases.
- Exact cleanup jobs retain private identifiers until physical cleanup is verified. Removing them merely to make deletion appear complete would lose recovery authority.
- A public deletion API was rejected because it would need a new unauthenticated identity and abuse boundary. Email plus private verified dispatch keeps target choice operator-controlled.
- Automatic retention deletion was rejected for this block because pending, blocked, attempted, legal, and safety states need different terminal evidence. The manual runbook is a launch hold until rehearsed and calendared.
- The six pages intentionally duplicate final copy between Flutter constants and static Hosting. A conformance test pins shared commitments, routes, version, and age while publication still requires human copy review.

## Evidence and revisit triggers

Functions tests cover schema migration, authored redaction, system-chant preservation, dependent third-party performance closure, exact media and draft cleanup, stale-phase refusal, invalid/conflicting paths, retry, operator authorization, verification freshness, idempotent cases, and missing-Auth recovery. A dedicated real-emulator case executes the maximum 200-performance and 200-draft pages through actual Firestore transactions. Flutter tests cover the real signed-out six-document journey, accepted-document copy, stale-gate support/deletion/sign-out, no-login deletion instructions, narrow width, and enlarged text. A source contract tests all six Hosting routes, exact effective dates, complete child-safety instructions, support and timing commitments, Dart/Functions/Firestore/Storage version parity, absence of stale Functions feature gates, approved negative 24/7 wording without positive promise variants, Privacy separation, retention wording, and unchanged age. Firestore rules include an exact stale-`v1` profile denial.

Revisit when law or qualified review changes a public document; a new market or under-17 model is proposed; support volume needs a case system; deletion can expose verified status safely; reply storage can hard-delete without orphaning other users; a cleanup worker gains provable terminal state; retention automation can distinguish unresolved and held evidence; or the public route architecture changes.
