---
description: Take a change from plan to shipped: plan, build, adversarial review until the reviewer approves, verify like a user, then present. Never a first draft.
argument-hint: [what to build or fix]
---

Ship this change: **$ARGUMENTS**

Do not hand back a first draft. Work the full loop below and only present what survives it. The definition of done in `CLAUDE.md` is the bar.

## 1. Plan

Read the relevant code first. Write a short plan: what changes, which files, how you will test it, and the risks. For anything non-trivial, get the plan approved before writing production code.

## 2. Build

Implement in small, reviewable steps. Add or update tests alongside the change so the new behavior is covered, not just the happy path. Reverting the production change should make a test fail.

## 3. Adversarial review, loop until approved

Invoke the `reviewer` subagent on the diff. The reviewer runs the tests itself and reports BLOCKERS, SHOULD FIX, and a verdict.

- Fix every BLOCKER and every SHOULD FIX, or make an explicit, defensible case for deferring a SHOULD FIX.
- Re-invoke the reviewer on the updated diff.
- Repeat until the verdict is `Approved`. Do not overrule the reviewer to save time, and do not present while any blocker stands.

## 4. Verify like a user

Tests passing is not proof the feature works. Run it the way a user would: run the app (or the affected flow), exercise the happy path and at least one failure path. For any UI change, capture a screenshot and look at it.

## 5. Present

Only now, present the result: what changed, how it was tested, the reviewer verdict, and the user-level verification (screenshot for UI). Confirm `flutter analyze` and the touched suites are clean, and that the work is committed and pushed. Uncommitted work does not exist.
