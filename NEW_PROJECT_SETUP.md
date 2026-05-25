# New Project Setup and Handoff

Read this when starting a new app. It is the Day 1 setup and the handoff a fresh chat reads to get oriented. Companions: `AI_BUILD_FRAMEWORK.md` (the method) and `TEMPLATES_AND_PROTOCOLS.md` (the prompts and protocols).

---

## Handoff: orientation for a fresh chat or new project

If you are an AI reading this at the start of a new project, here is how the pieces fit:

- There are three portable framework files (this one, `AI_BUILD_FRAMEWORK.md`, `TEMPLATES_AND_PROTOCOLS.md`). They define HOW Andrew builds, across every project. They do not change per project.
- Each project also has its own set of living documents: a SPEC, a DECISIONS log, a WISHLIST, a ROADMAP (if there is external/compliance scope to track), a BLOCK_RECAPS log, a HANDBOOK, and a README. Skeletons for all of these are below.
- The working model is three roles: Andrew is the product owner and final authority on UX, copy, scope, and pricing. The chat AI (you, if you are the strategic reviewer) holds context across Blocks, reviews plans before they become code, reviews code after, and drafts handoffs to the implementer. The implementer (Claude Code) writes the code and reports back.
- Build proceeds in Blocks. Each Block: kickoff prompt, plan approval, build with tests, adversarial review, recap with commit hash, handbook update, close. Templates are in `TEMPLATES_AND_PROTOCOLS.md`.
- Read the SPEC first, then DECISIONS, then the latest BLOCK_RECAPS entry to know where things stand.

These three framework files plus the project's own SPEC are sufficient as a handoff. No separate handoff document is needed.

---

## Day 1 checklist

About 1 to 2 hours before any code. It pays off across the whole project.

1. Create the project repo.
2. Copy the three framework files into the project's `docs/` folder.
3. Create `docs/[PROJECT]_SPEC.md` from the skeleton below: vision, one-paragraph user description, core build principles, stack, v1 scope, out-of-scope, build order, definition of done, and an empty lessons section.
4. Create `docs/DECISIONS.md` from the skeleton: standing-rules table seeded with the universal rules, plus an empty decisions table. Add your first stack-choice entries.
5. Create `docs/WISHLIST.md` with the tier headers (v1.1, v2, v3+, Business, Skipped). Empty is fine; structure matters.
6. Create `docs/ROADMAP.md` only if the project has external scope to track (compliance research, ordinance citations, a phased plan with triggers). If it does, mark its compliance content authoritative.
7. Create `docs/BLOCK_RECAPS.md` with just the header. It fills as Blocks close.
8. Create `docs/HANDBOOK.md` from the skeleton. It fills one feature at a time via the recap.
9. Write the README from the skeleton (setup steps and a pointer to the docs).
10. Pin the one-paragraph description of the actual user somewhere visible in the SPEC. Every UX decision gets checked against it.
11. Plan Block 1 (the foundation) using the kickoff template.

---

## Skeletons

### `[PROJECT]_SPEC.md`

```markdown
# [Project]: Product Specification

**Build pace:** Build at the pace each feature deserves. Ship when ready. No corner-cutting for dates.
**Primary user (v1):** [who, in one paragraph: their background, vocabulary, goals, what they use today]
**Build agent:** Claude Code, with [you] approving outputs and answering preference questions.

## 1. Product summary
[2-3 sentences: what it is, who it is for, the one differentiating feature.]

## 2. Core build principles
1. Boring beats clever. Standard solutions, common patterns, plain English. If a senior engineer would call it overengineered, it is.
2. Do exactly what is asked. No more, no less. Do not invent features. If something seems missing, ask.
3. Validate as you build. Each feature works end-to-end before the next starts.
4. Names map to function. A new user knows what every menu item does without help text.
5. [Platform note, e.g. mobile-first at 375px, or desktop-first, as fits.]
6. No em dashes anywhere in copy or generated text.
7. Voice: direct, helpful, never corporate. Reads like a person who knows what they are doing wrote it.
8. Respect the user's time. Every screen answers "what do I do here" in under 3 seconds.
9. No mock data in production. Seed data only in development.
10. Audit-log everything that matters. The trust surfaces (exports, read-only views) depend on the trail.

## 3. Tech stack
[Frontend, backend, hosting, email, key libraries. Pick decisively, no "or".]

## 4. Branding
[Name, tagline options, color palette, typography, logo plan.]

## 5. Voice and copy
[3-5 examples of GOOD copy and 3-5 of BAD copy for this product.]

## 6. Feature scope for v1
[Numbered features, in build order. Include the suggestion-box / feedback channel as a feature where it fits.]

## 7. Scope for v1.1 (post-MVP, after 30 days of real v1 use)
[Committed-but-deferred features. Cross-reference WISHLIST.]

## 8. Database schema (or data model)
[Tables/collections, key fields, and the access/security model.]

## 9. UI structure
[Public routes, authed routes, navigation.]

## 10. Pricing
[Tiers, but do not integrate billing in v1 unless that is the point of v1.]

## 11. Out of scope for v1
[Explicit list of what NOT to build, to protect the ship.]

## 12. Build order
[Block 1 foundation, then feature Blocks, then a polish/ship Block.]

## 13. Definition of done (per feature)
[Works end-to-end; responsive; empty/error/loading states; audit logged; access control verified with a second account; no em dashes; no console errors; adversarial review passed with disposition table; handbook section written.]

## 14. Lessons captured live
[Append 1-3 entries at each Block close. Folded into the framework at project end via the maintenance protocol.]
```

### `DECISIONS.md`

```markdown
# Architectural Decisions

## Standing Rules
| Date | Rule | Detail |
|------|------|--------|
| [date] | Measure, do not estimate | Every numeric claim in a summary or recap comes from an actual count (wc -l, test output, ls/find), taken seconds before typing it. |
| [date] | Verify the verification | Before trusting a check, prove it fails when it should by introducing a deliberate failure. Lock the real command and config into the build. |
| [date] | Recap-plus-commit close-out | A Block is closed only when the commit hash is recorded in the recap. |
| [date] | No em dashes (standing rule) | Anywhere in app, copy, or docs. Commas, periods, parentheses, or rewrite. |
| [date] | 9th-grade reading level (standing rule) | All user-facing copy. Concrete next steps in errors. |
| [date] | [project-specific rules as they emerge] | |

## Decisions
| Date | Decision | Reason |
|------|----------|--------|
| [date] | [first stack-choice entries] | |
```

### `WISHLIST.md`

```markdown
# [Project]: Wishlist

## v1.1 (committed, after 30 days of v1 use)
### v1.1: [name]
**The idea:** ...
**Why v1.1:** ...

## v2 candidates (pin, do not build; need real usage data)
### v2: [name]
**The idea:** ...
**Why pin, not build:** ...
**Trigger to promote:** ...

## v3+ candidates (need scale or customer pull)

## Business tier candidates (pricing, packaging, model)

## Skipped (deliberately not building, with reason)

## Promotion rule
An item earns a real spec when all four are true: 3+ customers (or one strong own-use reason) asked; the user problem fits one sentence; the smallest version is describable; building it does not break the existing surface. Items 6+ months old with no pull get deleted.
```

### `ROADMAP.md` (only if there is external/compliance scope)

```markdown
# [Project]: Roadmap

Compliance and external-scope content here is AUTHORITATIVE. Ordinance citations, retention periods, required categories, and scope decisions are built on verified research and are not second-guessed during build. Architecture, tests, schema, and UX remain open for debate.

[Phased plan, with a concrete trigger on every deferred item. Per-feature test specs if the project is compliance-driven, e.g. F1-T1 through F1-Tn.]
```

### `BLOCK_RECAPS.md`

```markdown
# Block Recaps

Running log of completed Blocks with deliverables, decisions, and closure status.

---

## Block N: [name]
**Status:** CLOSED
**Commit:** `[hash]`
**Tests:** [measured count] passing ([new] new)
**Type-check / lint:** [measured result, with the real command used]

### Files created / modified (with measured line counts)
[table]

### Disposition table
[by frame]

### Deferred (with triggers)
[table]
```

### `HANDBOOK.md`

```markdown
# [Project] Handbook

A plain-language manual for [project]. Read this to understand exactly how every feature works and to explain it to anyone. Mostly plain English, light technical detail where it helps. Updated one feature at a time as Blocks close.

## What [project] is
[The app in a few sentences: what it does, who it is for, the one-sentence value.]

---

## [Feature name]
**What it does.** [plain, 2-3 sentences]
**How to use it.** [numbered steps]
**Behind the scenes.** [light technical: what is stored, what triggers email, what limited viewers see]
**Limits and gotchas.** [what it does not do]
**Where it shows up.** [other surfaces it touches]
> [screenshot: to add later]

[Repeat per feature.]
```

### `README.md`

```markdown
# [Project]
[One-line description.]

## Prerequisites
[runtime, accounts]

## Setup
[numbered steps: clone, install, env vars, database migrations, run dev server]

## Scripts
[dev, build, test, lint]

## Tech stack
[list]

## Project docs
See docs/[PROJECT]_SPEC.md, docs/DECISIONS.md, docs/WISHLIST.md, docs/BLOCK_RECAPS.md, and docs/HANDBOOK.md for product and history.
```

---

## Reference
- Created May 2026 as part of the three-file framework consolidation. Pulls the Day 1 checklist and core build principles forward from the prior AI_BUILD_FRAMEWORK and Roster's spec, and adds the HANDBOOK skeleton.
- Living document.
