# 001: Canonical engineering documentation

**Status:** Accepted
**Date:** 2026-08-17

## Context

The repository accumulated an engineering overview, an implementation-rationale snapshot, a roadmap, a dated decision table, block recaps, known issues, and duplicated agent instructions. Each document had value, but ownership overlapped and several measured claims drifted from the code. Maintaining two active documentation systems would create competing versions of engineering truth.

## Decision

Use one documentation framework with distinct lifecycle roles:

- `docs/CHANGE_SPEC.md` is the only active implementation specification. Non-trivial code starts only after its status is `Approved`.
- `docs/changes/` records completed change blocks and the verification actually performed.
- `docs/decisions/` records durable architectural and product decisions with reasons and revisit triggers.
- `docs/ROADMAP.md` owns product and release sequencing, not implementation detail.
- `ENGINEERING_OVERVIEW.md` and `docs/IMPLEMENTATION_RATIONALE.md` are milestone snapshots for reviewers. They are refreshed at meaningful review or release boundaries, not maintained as per-change ledgers.
- `AGENTS.md` is the canonical Codex working guide.
- `docs/DECISIONS.md`, `docs/BLOCK_RECAPS.md`, and `CLAUDE.md` are legacy compatibility entry points. They do not receive parallel new records.

When documents disagree with verified code, tests, or deployed-state evidence, the verified evidence wins and the document is corrected.

## Reasons

- A proposal, an implementation record, and a durable decision answer different questions.
- One active spec makes approval state unambiguous.
- Per-change records preserve why a diff exists without turning the roadmap into a technical diary.
- Individual decision files are easier to supersede and link than an indefinitely growing table.
- Snapshot documents remain useful to reviewers without pretending to be continuously current.

## Consequences

- New work must update the correct canonical path instead of appending to every historical file.
- Closing a non-trivial block includes writing its completed change record.
- A decision that constrains future blocks requires its own decision record.
- Historical claims remain available, but their legacy headers must be respected.

## Revisit triggers

- Codex or the repository gains a native change-management format that replaces these files.
- The team grows enough to require generated indexes or an automated documentation check.
- Reviewers consistently cannot determine current approval or decision status from this structure.
