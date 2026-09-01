# V1 launch policy and deletion closure

## Approval and boundary

Andrew approved `V1 launch policy and deletion closure spec` on 31 August 2026. He separately approved daily moderation review, urgent safety prioritization, ordinary support and video acknowledgement within two business days, verified deletion within 30 calendar days, and no 24/7 promise.

This is a Lane 2 source implementation from merged PR 29 at `c3a071c`. It does not publish policies, deploy Hosting, Functions, rules, Storage, or clients, configure retention, send support mail, mutate production, change store territories, or change the 17+ account rule.

## Why the shape changed

The device walk reached a placeholder Content Policy that told users detailed rules were coming soon. That was not a defensible accepted contract for a public creator product. Signed-out users also lacked complete privacy, terms, rights, support, and deletion routes. The earlier account worker removed attribution while leaving authored chant and comment text, omitted upload-limit rows, and did not queue owned published media for physical deletion.

The closure uses one `v2` accepted Terms and Community Rules contract and treats Privacy as a separate notice. Six public-source pages and matching in-app destinations describe actual source behavior. The pages are not considered published until a separately approved Hosting deployment and readback.

Deletion uses structural tombstones only where relationships require a row. User-created chant bodies and external references are removed; seeded system chants remain. Comment bodies and projected identity are replaced. Owned performances close and create exact-path media jobs before ownership changes. Owned drafts create correlated exact-path staging cleanup evidence before removal. Both media transactions recheck the live phase, owner, path, and any existing cleanup identity before writing, so a stale page cannot mutate after authority moves. Older jobs replay the stronger privacy phases during schema migration.

The external request route remains instructions plus email. A local private plan/apply command requires recent independently completed account-control verification and an active operator, then enters the exact same durable job. It stores a non-identifying case reference and never stores the support email or message in Firestore audit detail.

## Privacy, safety, and recovery

- The user cannot choose the deletion UID through a public callable.
- Missing Auth is accepted only when the exact durable deletion job already exists.
- An unexpected published-media or staging path stops before content redaction or draft deletion.
- `createdBy == "system"` is never treated as account-owned chant content.
- Schema-one work at or after authored-content cleanup rewinds to that phase under schema two.
- A delayed draft-deletion event finds the already retained cleanup row; account correlation does not depend on event delivery order.
- An attempted cleanup is not terminal proof if an admitted upload can finish late. Completion confirmation remains an operator readback decision.
- Retention targets have a manual runbook. No blanket TTL deletes pending, blocked, attempted, safety, legal, or unknown evidence.

## Verification status

After the approved post-review correction, the production Functions build and 229 locally runnable Functions tests pass; all 24 dedicated real-emulator integration cases pass, including maximum 200-performance and 200-draft deletion pages; all 519 Flutter tests and scoped analysis pass; all 74 seed tests pass; rules TypeScript passes; and the 26 launch-guide, policy, and device tests plus launch-services, native-source, and structural-memory checks pass. All 174 Java-backed Firestore and Storage assertions pass, including the exact stale-`v1` denial. The first rules run exposed stale placeholder `v1` gates in Storage and five Functions feature handlers. Shared Functions policy authority, Storage rules, fixtures, and the conformance test now pin `v2`. All six policy screens render at 320 by 568 with 1.8x text. Andrew confirmed approval of the notarized virtual business mailbox on 1 September 2026, and source now uses that correspondence address. The Android SDK is absent locally. A fresh iOS simulator build entered Xcode but produced no terminal completion receipt before the bounded wait ended. Native compilation, staged governance, exact-head CI, corrected-range independent review, deployment, support-email delivery, legal, and live-device evidence remain open before publication.

## Publication holds

The canonical holds are in `docs/LAUNCH_POLICY_PACK.md`: qualified United States, United Kingdom, and Canada review; branded support-email receipt and reply; child-safety operating readiness; external deletion and retention rehearsal; store disclosure reconciliation; exact-head CI; compatible deployment; and signed-device observation. The virtual business correspondence-address hold is closed in source, but the pages remain unpublished.
