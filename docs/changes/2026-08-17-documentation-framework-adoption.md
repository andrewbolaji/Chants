# Documentation framework adoption

**Completed:** 2026-08-17
**Type:** Documentation and agent-workflow change
**Application behavior changed:** No

## Why

The repository had useful engineering history, but future work did not have one clear path from proposal to completion. Active plans, completed block recaps, durable decisions, handoff snapshots, and agent instructions overlapped. Some older documents also described behavior that the code no longer had.

The project now uses one canonical framework:

- `docs/CHANGE_SPEC.md` for the one active, approved implementation plan.
- `docs/changes/` for completed change reasoning.
- `docs/decisions/` for durable decisions and revisit triggers.
- `docs/ROADMAP.md` for product and release sequencing.
- `ENGINEERING_OVERVIEW.md` and `docs/IMPLEMENTATION_RATIONALE.md` for milestone review snapshots.
- `AGENTS.md` for Codex working instructions.

## What changed

- Added the canonical directories and their ownership rules.
- Recorded the framework decision in `docs/decisions/001-canonical-engineering-documentation.md`.
- Recorded the v1 one-level reply decision in `docs/decisions/002-comment-reply-depth-and-retention.md`.
- Added a proposed technical change spec for one-level replies. It remains unapproved and does not authorize application code changes.
- Marked `docs/DECISIONS.md` and `docs/BLOCK_RECAPS.md` as legacy archives rather than parallel active systems.
- Made `CLAUDE.md` a compatibility pointer to `AGENTS.md` instead of a duplicated instruction set.
- Updated the Codex stop hook to resolve the repository dynamically and refer to the canonical guidance.
- Corrected measured or review-sensitive claims in the repository handoff documents and README.

## Verification

- Confirmed all new canonical paths exist and cross-links resolve.
- Parsed `.codex/hooks.json` as JSON.
- Checked `.codex/hooks/run_tests.sh` with `bash -n`.
- Exercised the Stop hook with `stop_hook_active: false`; it ran the full Flutter suite and exited 0. Exercised the loop guard with `stop_hook_active: true`; it exited 0 without rerunning tests.
- Searched active guidance and handoff documents for superseded claims.
- Reviewed the resulting diff and preserved the pre-existing Android and lockfile changes.

No Flutter, Functions, Firestore-rules, or seed behavior changed in this documentation block.

## Follow-up

- Approve or revise `docs/CHANGE_SPEC.md` before reply implementation.
- Specify and complete the interaction-safety prerequisite blocks listed there.
- Review and trust the changed repository hook in Codex's `/hooks` screen. Codex intentionally skips changed non-managed hooks until their current definition is trusted.
- Refresh the two milestone handoff snapshots after the P1 remediation work and reply block are complete.
