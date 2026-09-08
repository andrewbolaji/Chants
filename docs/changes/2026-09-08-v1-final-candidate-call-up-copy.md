# V1 final candidate Call-Up copy closeout

## Scope

Andrew approved `approved V1 final candidate closeout and player call-up copy correction`. The bounded source change replaces the generic Call-Up pronoun with the already selected player's display name in the question and the club-qualified absence explanation. It also records the sanitized receipts from the completed North London Forever production window.

The correction does not change eligibility, current-data requirements, player selection, routes, submission, authentication, backend authority, production data, or operational controls. Production remains generation 13 `maintenance` with destructive workers false.

## Interface decision

The invitation now asks `Who's got a song for Ben White?` and explains `No chant for Ben White at Arsenal in Chants yet.` The same `playerName` already shown as the card heading supplies both lines. This is clearer than a generic pronoun, avoids pronoun metadata, and keeps the team-scoped claim explicit.

The card must remain usable with a long player name at 320 logical pixels and 1.8x text. Cycling to a different player must update the heading, question, and explanation together.

That combined viewport and state check exposed a 26-pixel overflow in the nearby `Full squad` row after the card cycled back to the shorter player. The row now gives its label bounded flexible width instead of forcing it beside a spacer. This keeps the existing label and expand action while making the approved enlarged-text journey safe.

## Production closeout carried forward

- Reviewed source `f4b3891a68eefdd3d006d7947589efe71f0c6564` passed all eight jobs in run `34227869269` before the live window.
- The exact create-only target `arsenal-north-london-forever` was created once and matched its reviewed source-owned projection.
- Immediate and final readback reported 193 total chants and 13 Arsenal chants, with all privacy-safe non-target counts unchanged.
- The paired-iPhone walkthrough approved all 20 crests, the long Brighton & Hove Albion name, Arsenal identity, the exact short North London Forever entry, neutral to up to down to neutral voting, route convergence, connection-loss recovery, offline reading and local removal, and the Stage, Create, Songbook, and You shell.
- The saved Songbook returned to empty and the production vote-row count returned to its baseline of three.
- Thirty observation checkpoints remained free of severity errors. Production then closed once to schema 1, generation 13, `maintenance`, destructive workers false. Independent readback and a final severity-error query were clean.

No credential, account identifier, raw log, comment, report, profile, or other user content is recorded here.

## Verification contract

Focused tests assert the exact selected-player copy for the initial and cycled player, both main club tabs, and the existing enlarged-text journey. Normal, enlarged, Songbook, and Chant Lab goldens are refreshed only from inspected platform output, with no tolerance increase. Full Flutter tests, analysis, governance, store validation, and replacement exact-head CI remain required before this amended candidate is complete.

The store packet adds the Call-Up widget to its allowed and hash-bound source drift while retaining `prepared_not_submitted`, null release artifacts, and all ten screenshots pending. PR merge, tag, store-console action, submission, and release require later authority.
