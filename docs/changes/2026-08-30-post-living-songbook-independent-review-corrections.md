# Post-Living Songbook independent review corrections

## Change identity

- **Approval:** Andrew approved `post-Living Songbook independent review correction spec` on 2026-08-30.
- **Base:** Committed head `ef7195cf5159c45afd5f92eaf427c698f6d62b16` plus the staged Living Songbook implementation.
- **Scope:** One high, five medium, and eight low independent review findings, plus two production-widget defects exposed by the new regressions.
- **Excluded authority:** No deployment, seed write, provider change, commit, push, merge, store action, or release.

## Result

Unavailable, hidden, removed, or missing source chants no longer trap private update requests. The server and UI permit only Not changed in that state. Every chant-mutating action still requires a current visible source, and stale evidence remains rejected.

Evidence cards show current and proposed proof. Replacing different existing proof requires explicit UI confirmation and a server acknowledgement. The operator-only audit retains only the prior public evidence map for that replacement. Proposed evidence, request text, proposed wording, and submitter identity remain absent. System-owned community chants can receive proof without promotion. User-created community chants retain the explicit promotion path.

Callable preconditions now carry stable reason codes. Flutter maps deletion, unavailable source, stale version, evidence conflict, action mismatch, closed request, duplicate intake, and rate limits to distinct states and copy. Suggestion streams isolate malformed or future-version rows. Supporter-readable request rows no longer store operator UID.

The operator queue is oldest-first within its open-row bound and renders submitted plus current timestamps. Promotion milestones exclude system and deleted-user sentinels. Invalid abandoned-draft rows emit a bounded aggregate warning without retrying the complete scheduled job, while real cleanup failures still throw and retry.

## Additional defects found by regression work

The first production-widget run reproduced two defects outside the independent report's exact list. Review dialogs disposed text controllers while their route was still animating, and the canonical-path dropdown overflowed in the tested narrow dialog. The dialogs now keep values in local state without controller ownership, and the dropdown expands within its available width.

## Evidence

- Focused Functions tests cover inactive submitters, nonoperator moderation, unavailable closure, exact failure reasons, replacement acknowledgement, exact audit content, system-community attachment, sentinel milestones, and cleanup retry classification.
- Flutter repository tests cover every stable callable reason and malformed-row isolation.
- Production widget tests cover unavailable closure, current and proposed proof, replacement confirmation, attach versus promote labels, stale acknowledgement, all four private statuses, and review notes.
- Complete local suites pass 163 Functions tests, 488 Flutter tests, 42 seed tests, production Functions build, rules and seed TypeScript, index JSON validation, and zero-issue fixture-backed `flutter analyze lib test`.
- Lane 2 project memory, writing style, governance regressions, native project contract, Dart formatting, and staged diff integrity pass against the complete 42-path handoff. Clean-runner evidence remains pending.
- The first clean runner measured 2.28% Linux renderer drift for the inspected Chant Detail golden. Its image-local bound is 2.3%, while a separate production widget test requires the new action and safety distinction.

## Remaining gates

Java-backed Firestore rules, native compilation, exact-head clean CI, combined device walkthrough, deployment, and release remain pending. The staged schema has not shipped, so removing `resolvedBy` requires no migration.
