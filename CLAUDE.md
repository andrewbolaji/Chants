# Chants: build instructions for Claude Code

This project follows a documented build framework. Before any work:
1. Read CHANTS_SPEC.md (product spec), DECISIONS.md (locked decisions and standing rules), ROADMAP.md (content-safety and IP posture), WISHLIST.md (deferred scope).
2. Read AI_BUILD_FRAMEWORK.md, TEMPLATES_AND_PROTOCOLS.md, NEW_PROJECT_SETUP.md (how we build).

Working model: Andrew owns product and approves everything. A separate strategic reviewer plans Blocks and reviews your output. You are the implementer.

Hard rules (from DECISIONS standing rules):
- Plan before coding. No code until the plan is approved.
- Tests ship WITH each feature, not after.
- Measure, do not estimate: every number in a recap comes from an actual count run seconds before typing it.
- Verify the verification: prove a gate fails when it should before trusting it.
- No em dashes anywhere, in code, copy, or docs.
- 9th-grade reading level for user-facing copy. Concrete next steps in errors.
- Content safety is standing: every user-content surface ships with a report path and a moderation route.
- Differentiation through data, never forks: no hardcoded league or sport checks.
- Stack is Flutter plus Firebase. App name is Chants.
- Data access lives behind repositories; presentation never imports the Firebase SDK directly.
- A Block is closed only when its commit hash is recorded in BLOCK_RECAPS.md.

Work in Blocks using the kickoff and recap templates in TEMPLATES_AND_PROTOCOLS.md. State: Day 1 done, Block 1 (Foundation) in planning.
