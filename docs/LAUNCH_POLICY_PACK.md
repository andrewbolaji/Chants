# Chants launch policy pack

**Status:** Approved source candidate, 31 August 2026. Not published or deployed.

This pack records the reviewed product decisions and points to the exact copy implemented in source. It is not legal advice or a finding that Chants is ready for public release. Publication still requires the holds below and a separate deployment authorization.

## Approved decisions

| Topic | Decision |
|---|---|
| Operator | Thunderriver Tech LLC operates Chants. Andrew is the initial human operator. |
| Initial markets | United States, United Kingdom, and Canada after their launch gates pass. Worldwide remains a later direction, not current approval. |
| Support | `support@chantsfc.com`, after inbound and branded outbound delivery are tested. |
| Business correspondence | Thunderriver Tech LLC, 5667 Treaschwig Rd #1014, Spring, TX 77373, United States. This is the approved virtual business mailbox, not the Texas registered office. |
| Moderation | Review daily and prioritize urgent safety concerns. Do not promise 24/7 coverage or instant action. |
| Ordinary acknowledgement | Aim to acknowledge ordinary support and video-review requests within two business days. |
| Account deletion | Aim to complete verified deletion within 30 calendar days, subject to an earlier legal deadline or an explained permitted delay. |
| Age | Keep the existing 17+ account rule unchanged. |
| Accepted contract | Users accept versioned Terms and Community Rules. Privacy is a separate notice and is not blanket consent. |

The approved virtual business mailbox is the only street address in source and public copy. The residential address supplied privately remains absent.

## Canonical public copy

The six source routes below are the publication candidates. They are mutually linked, reachable from the actual signed-out app welcome, readable without login, use the approved support address and service wording, and contain no unresolved copy placeholders.

| Public route | Canonical source | What it tells a user |
|---|---|---|
| `/privacy` | `hosting/privacy/index.html` | Information used, public and private boundaries, providers, retention targets, deletion, and user choices |
| `/terms` | `hosting/terms/index.html` | 17+ use, account conduct, contribution license, rights responsibility, moderation, and service independence |
| `/community` | `hosting/community/index.html` | Football-culture boundary, hate and safety rules, rights/privacy, integrity, moderation, child-safety escalation, and appeals |
| `/rights` | `hosting/rights/index.html` | No-login rights and takedown instructions, necessary notice details, review behavior, and appeals |
| `/delete-account` | `hosting/delete-account/index.html` | In-app deletion, copyable email request, identity-verification warning, timing target, and what is removed or retained |
| `/support` | `hosting/support/index.html` | Support categories, safe diagnostic information, response target, daily moderation, and no 24/7 promise |

`hosting/policy.css` is the shared presentation source. The root Hosting page links all six destinations. Matching in-app documents live in `lib/presentation/content_policy/policy_documents_screen.dart` and the Community Rules body lives in `lib/presentation/content_policy/content_policy_screen.dart`.

The exact acceptance copy is:

> I agree to the Terms and Community Rules.

The returning-user gate also states that the Privacy Notice explains information handling and is not part of that agreement. Policy version `v2` is enforced together by Dart, Functions, Firestore rules, and Storage rules.

## Actual behavior behind the copy

| Claim | Source-backed behavior | Qualification |
|---|---|---|
| Birth date | The client checks age and sends only `ageConfirmed17Plus: true` | Chants does not store the onboarding birth date as a birth date |
| New performance publication | Upload enters a private draft and requires operator approval | Approval is not rights clearance |
| Public profiles and shares | Approved visible creator, chant, and performance projections can be read publicly | Hidden, removed, banned, and unavailable source states are rechecked server-side |
| Reports and blocks | Signed-in users can report supported targets and block creators in supported app views | Blocking cannot erase a public copy already made elsewhere |
| Policy access while blocked on acceptance | A returning stale-policy account can read all six documents, contact support, request actual account deletion, or sign out without accepting `v2` | Product write authority remains closed until the current contract is accepted |
| In-app deletion | The authenticated callable creates a server-owned durable deletion job | Acceptance is not completion |
| External deletion | A no-login page sends the user to support; a private source-bound operator command can dispatch a recently verified account into the same durable job | Email sender address or a public handle alone is not identity proof |
| Authored content deletion | User-created chant text and media references are removed; comment and reply rows remain as non-identifying structural tombstones | Seeded system catalogue chants are not altered. Target-side safety or moderation records created by another person may retain the deleted account ID under Decision 016 until their own retention rule applies |
| Performance media deletion | Performance visibility closes and an exact-path media job is created before creator identity is replaced | Physical object cleanup is a separate retryable step |
| Draft media deletion | Account deletion creates retained exact-path staging cleanup evidence in the same bounded step that deletes each draft | Retained evidence is not proof that a late upload can no longer appear |
| Offline Songbook | Local data on the initiating device is locked and cleared after server acceptance | Email deletion cannot remotely wipe another device or external backup |

## Approved retention targets

| Data | Target |
|---|---|
| Account, public profile, private activity, authored text, drafts, and owned performance uploads | Remove through verified account deletion |
| Ordinary closed support and deletion correspondence | Delete 90 days after closure unless separately justified safety or legal evidence is required |
| Closed moderation, report, and appeal evidence | Review and delete or genuinely de-identify within 12 months unless a documented hold applies |
| Routine logs and expired upload limits or sessions | 30 days, subject to verified provider capability |
| Unresolved cleanup evidence | Retain until exact cleanup is verified; review at least monthly; remove within 30 days after verified terminal closure |
| Provider backup, recovery, and diagnostic copies | Follow the configured and disclosed provider period; do not describe them as live Chants content |

A legal hold needs a reason, restricted access, owner, review date, and release condition. It is not permission to retain every related record indefinitely.

## Implementation gaps before publication

| Gap | Why it still matters | Closure evidence |
|---|---|---|
| Legal review for the United States, United Kingdom, and Canada | The service admits 17-year-olds and hosts fan lyrics, video, voices, faces, and external music/evidence links | Qualified review of the final six pages, store disclosures, rights process, child-safety duties, privacy bases/transfers, and consumer terms |
| Support delivery | Source names `support@chantsfc.com`, but mailbox receipt and branded outbound reply are not yet evidence | Test message from an outside account, reply from the branded address, spam check, and saved non-sensitive result |
| Child-safety escalation readiness | App and web source give the exact urgent subject, no-download/no-forward instruction, Chants location or ID request, and emergency-services direction, but copy is not an operating capability | Current reporting contacts, operator training, evidence-handling rules, and an escalation rehearsal |
| External deletion rehearsal | The source-bound plan/apply path is new and has not touched production | Independent source review, exact-head CI, a non-production rehearsal, and a private operator checklist |
| Retention operation | Targets are public copy, but mailbox, cloud logs, moderation records, and cleanup-evidence reviews are not yet proven end to end | Config/readback evidence or a dated manual review ledger for each target, with no deletion of unresolved recovery evidence |
| Store disclosures | Apple privacy labels and Google Data Safety must match the final SDK and behavior | Final console answers cross-checked against the release binary and this pack |
| Deployment | These pages and `v2` acceptance are source only | Separate approved rollout, compatible backend/rules/client order, signed builds, and post-deploy route/readback checks |

## Public address status

Andrew confirmed on 1 September 2026 that the commercial mail receiving agency approved the notarized USPS Form 1583 for Thunderriver Tech LLC. Source uses the assigned address only as public business correspondence. Private identity documents, the completed Form 1583, account details, and the residential address stay outside Git.

The mailbox is not represented as the Texas registered office, a staffed Chants location, or proof that Apple, Google, D&B, tax, licensing, or other provider records accept it. Those records must use their own verified requirements. Re-open the publication hold if the mailbox approval lapses or mail cannot be received.

## Publication sequence

1. Complete the implementation gaps above and independently review the exact source range.
2. Verify `support@chantsfc.com` and obtain final legal copy decisions.
3. Update only the canonical source files if review changes copy. Keep Dart, Functions, rules, and tests on the same policy version.
4. Package and run exact-head CI. Build signed iOS and Android release candidates from that head.
5. Under a separate approval, deploy compatible Functions, rules, indexes, Storage, and Hosting while admission remains closed.
6. Verify all six public routes signed out, then deploy the compatible client and observe the reacceptance journey.
7. Record publication date, effective date, deployed source, operator coverage, and retention evidence. Only then remove the publication hold.

Rollback must not restore the old placeholder policy or silently accept `v1`. Close admission, preserve deletion and cleanup jobs, and repair forward on the `v2` contract.
