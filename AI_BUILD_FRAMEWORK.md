# AI Build Framework

How to build software with AI as the primary implementer while holding the quality bar of a top engineering team. Stack-agnostic. Portable to any project. Distilled from Roster (React \+ Supabase, 14 Blocks, 240 tests) and Vouch (Flutter).

**This is the file you read to understand the method.** Two companions:

- `TEMPLATES_AND_PROTOCOLS.md`: the copy-paste prompts (Block kickoff, recap, handbook, audit verification) and the framework maintenance protocol.  
- `NEW_PROJECT_SETUP.md`: the Day 1 checklist, the per-project file skeletons, and the handoff a fresh chat reads to get oriented.

---

## The spirit (read first, internalize)

The job is to ship work that meets a top-5 engineering company bar with AI doing most of the typing. That works only if you keep the discipline real senior engineers bring: thinking before coding, reviewing adversarially, documenting decisions, capturing lessons, and treating AI output as work product that needs review, not as gospel.

Speed comes from removing friction (no meetings, no context-switching, no "let me research that"), not from skipping steps. The discipline IS the speed.

A note on this framework itself: its value is in being sharp and re-read, not comprehensive. The framework does not build the app; it is a short list of disciplines that prevent the predictable failures (shallow planning, unverified claims, scope creep, silent debt, shipping broken or ugly). Those failure modes are finite and mostly captured. Past a point, every page added is a page less likely to be re-read, and a framework you do not re-read is decoration. The bugs that actually bite are caught by a few habits held deeply (plan first, verify do not trust, walk the real flow), not by completeness. So when this framework feels like it is missing something, the honest fix is almost always to compress an existing section to make room, not to grow. The best version of it a few projects from now is probably shorter than today's, because more of it will have become automatic and dropped to one-line reminders. Resist length. Sharpen and shrink.

---

## Three roles, one human, two AIs

- **You (the human):** product owner. Vision, decisions, devil's advocate, audience checks, killing bad ideas. Final authority on UX, copy, scope, and pricing.  
- **Strategic reviewer (a chat AI):** holds context across Blocks, reviews plans before they become code, reviews code after it's written, drafts handoffs to the implementer, catches the implementer rubber-stamping its own work.  
- **Implementer (Claude Code or similar):** writes code, runs tests, surfaces edge cases during planning, produces disposition tables, executes the work. Each session starts fresh with no memory of prior Blocks.

Why three nodes: the reviewer holds full context the implementer lacks, and is adversarial about the implementer's output. Single-AI workflows lose the adversarial layer (the implementer rubber-stamps itself). Don't collapse the roles. Don't do the strategic review in your own head either; you're the product owner, not the engineering team.

---

## Mount Rushmore: the patterns that matter most

If you carry only these to your next project, you keep most of the leverage.

### 1\. The Block kickoff and end-of-Block recap structure

Every meaningful unit of work (a "Block") starts with a structured kickoff and ends with a structured recap. Without the structure, plans drift, scope balloons, reviews go shallow.

**Kickoff:** state the cadence. List 5 to 8 things to think hard about during planning (reuse from prior Blocks, threat-model concerns, edge cases needing product input, standing rules). End with "devil's advocate yourself, surface 2-3 risks during planning, not after." Demand "plan first, do not code until I approve."

**Recap (9 sections):** what was built, disposition table, new DECISIONS entries, schema changes, sensitive-data analysis, final test/lint/type results, files created and modified, anything deferred with triggers, and the commit hash. Actual prompt text lives in `TEMPLATES_AND_PROTOCOLS.md`.

The kickoff prevents shallow planning. The recap prevents shallow review.

### 2\. The three-way collaboration model

You direct the reviewer. The reviewer drafts instructions for the implementer. The implementer reports back to the reviewer. The reviewer surfaces issues to you. Three nodes, four handoffs per cycle. This is how AI substitutes for an engineering team: not by being smarter, but by playing different roles with different context and different blind spots.

### 3\. Trust nothing the implementer claims without verifying it

This is the pattern that earned the most scar tissue on Roster, so it gets the most words. AI is fast at producing plausible-sounding completion claims. Speed is not evidence of completeness. Specificity is. Three concrete rules grew out of this:

**a. Verify audit-style claims with enumeration.** When the implementer says it ran a comprehensive scan, sweep, audit, or review, make it enumerate what it actually checked. "Enumerate at least 20 specific items you scanned. For each: where it lives (file and line), the verdict, and if changed, the new version." If it can produce the list with specifics, the work happened. If it can only point to a subset, it didn't. (Roster Block 7: an "8-minute reading level audit" had only covered empty states, not the modals, validation messages, and labels that were requested. The enumeration request caught it.)

**b. Measure, do not estimate. Every numeric claim.** Line counts, test counts, file counts, item counts, row counts. If a number is going into a recap or summary, it must come from an actual measurement (`wc -l`, test-runner output, `ls`/`find`) taken seconds ago, not from memory or projection. Roster had SIX separate instances of numeric drift across Blocks (line numbers off, file count said 8 when it was 9, mid-build "166 lines" that was actually 211). Measuring takes two seconds. Estimating under time pressure produces drift every time.

**c. Verify that your verification commands actually verify.** A passing gate that checks nothing is worse than a missing gate, because it manufactures false confidence. Before you trust a check, prove it catches the failure class it claims to, by introducing a deliberate failure and watching it fail. Roster's entire v1.1 ran with a vacuous type-check gate: the root `tsconfig.json` had `files: []`, so `tsc --noEmit` type-checked nothing, and 80+ real type errors silently accumulated across 8 Blocks until the production build surfaced them all at once. Lock the real command into the build config explicitly (for that project, `tsc -b` against the app config, not `tsc --noEmit` against a stub root). The general rule outlives the specific command.

**d. Prove the diagnosis before coding the fix.** Sub-point c is about trusting a passing check; this is about trusting a root-cause theory. When a fix rests on "this is probably why," confirm it cheaply against the real system first (run the actual failing operation, read the actual error, reproduce it directly) before writing the fix. Hedged language in a plan ("this can be problematic," "may not see the row") is the signal to stop and prove it, not a license to build on a guess. This matters most the third time you touch the same component: an unverified fix to a subtle bug often just trades it for another. (Roster: a row-level-security INSERT failure was diagnosed with a hedged theory; running the exact failing statement two ways against production turned "probably the RETURNING path" into a proven cause before a line of the fix was written, and the fix then worked on the first try.)

The thread connecting all four: a confident report can make work look more thorough than it was, and a confident theory can make a fix look more certain than it is. Senior reviewers spot both and lose trust in the whole document. Make the work, and the diagnosis, prove themselves.

---

## Standing rules (apply across every project)

Universal. Do not relitigate per project.

1. **Tests are deliverables, not nice-to-haves.** A Block does not close with zero tests. Tests ship with the feature. If "done" means "the test passes," the test is part of done.  
2. **Architectural correctness is what makes a test EASY to write, not unnecessary to write.** "We built it right so no test is needed" is the wrong frame. Tests lock correctness against future refactors. If a thing is hard to test, the architecture probably needs revisiting.  
3. **Cross-implementation invariant tests catch real drift.** When the same logic lives in two places (for example a calculation in app code and again in a database query), write one test that runs both against the same input matrix and asserts they agree. Roster's F3-T17 caught a genuine timezone bug this way (calendar-day vs 24-hour-interval math between `date-fns` and SQL) that would otherwise have shipped as a subtle flag-flipping bug.  
4. **Plan before building.** The implementer does not code until the plan is approved. The plan is where bugs are cheapest to fix.  
5. **Disposition every finding.** Silence on a finding is not a disposition. Every finding gets a severity (High / Medium / Low / N/A) and a disposition (Fixed / Defended / ROADMAP-with-trigger).  
6. **Fix the class of bug, not just the instance.** When you find one example, ask "where else could this exist?" and fix preemptively. Prevents whack-a-mole across Blocks.  
7. **Trigger-based deferral, never "later."** Deferred work gets a concrete, testable trigger (an event that, when it occurs, is the right moment), not a vague "after v1" or "when we have time." Without a trigger, deferral is just silent technical debt.  
8. **A Block is not closed until the commit hash is recorded in the recap.** Memory state saying "closed" with no commit is not closed; a crashed session loses the work. Recap-plus-commit is the close-out gate.  
9. **Document version and scope drift the moment it happens,** in DECISIONS, with reasoning. Not at retrospective. (React 19 instead of 18, a different library than spec'd, a scope cut.)  
10. **No em dashes or en dashes anywhere,** in the app, user-facing copy, or your own writing. Use commas, periods, parentheses, or rewrite. It is an AI tell.  
11. **9th-grade reading level for all user-facing copy.** Errors, empty states, confirmations, buttons, helper text, audit displays. No jargon unless load-bearing. Concrete next steps in error messages, not "something went wrong." Does not apply to code comments, DECISIONS, or internal tooling.  
12. **Hold the bar at the highest version of itself.** When a piece of work clears the bar, the bar moves to that level. Small features get the same definition of done as large ones. The checklist does not shrink with scope. Regression because "this one's smaller" is how codebases rot.  
13. **Walk the real flow on a fresh production environment.** Bugs that hide in local dev because of leftover state (an existing session, a pre-seeded row, a profile that already exists) appear the moment the code runs on a clean production database with empty tables, fresh auth, and real access policies. A passing test suite that mocks the data layer can sit happily on top of a flow that is broken in production. So after any deploy to a fresh environment, click through the core user journey by hand on production, not just the test suite. (Roster: three separate bugs, an auth loop, a policy recursion, and an insert rejection, were all invisible locally and only surfaced on the empty cloud database. Every one was caught by the manual walk, none by the 260-plus passing tests.) Corollary: know which of your change types deploy independently. Config, application code, and data or schema often ship through different channels on different timelines. A change committed to source control is not a change live in production until its specific channel has carried it there. Track them separately so "is this live?" is never a guess.

---

## Universal senior signals (language-agnostic)

These separate senior code from merely working code, in any stack. Use them as a checklist in the Taste frame.

- **Side-effect-free render/build functions.** Whatever your framework calls "render" must be pure. Side effects (API calls, mutations, logging, writes) live in effects, lifecycle hooks, or commands. Never in render.  
- **No magic numbers or hardcoded strings in UI code.** Numbers go in a spacing/token scale. Strings go in constants or a localization layer.  
- **Resource disposal is checked, not assumed.** Anything that opens a connection, subscription, controller, listener, or handle has a matching close/dispose/unsubscribe. Audit explicitly. Leaks are a senior-level disqualifier.  
- **Async safety.** Anything that crosses an `await` and then touches state checks that the context is still alive (`if (!mounted)`, `AbortSignal`, cancellation token).  
- **Make impossible states unrepresentable.** Use discriminated unions or equivalent instead of hand-rolling `isLoading` \+ `error?` \+ `data?` that can contradict each other.  
- **All async UI states exist:** loading, success, empty, error. Empty is not a subset of success. Error is not optional.  
- **Heavy compute off the UI thread.** Anything that could block rendering goes to a worker, isolate, or background queue.  
- **Meaningful names, no generic prefixes.** Banned: `Custom*`, `My*`, generic `App*`. Name what the thing is.  
- **Data access behind a repository/context layer.** Presentation never imports the database SDK directly. The data layer returns domain models, not raw rows.

---

## Anti-patterns to kill on sight

Fix these when you see them regardless of which feature you are "supposed" to be on. Note the fix in the commit.

- Iteration returning "first match" with no empty-case branch.  
- Building large lists eagerly when a virtualized/builder list would do.  
- State mutation after an async gap without a liveness check.  
- Inline anonymous components that should be named and memoized.  
- Repeated context/media-query lookups in one render. Cache once at the top.  
- `print`/`console.log` in committed code. Use a logger.  
- Hardcoded color literals outside the theme system.  
- Direct database/SDK calls in presentation or controller layers.  
- Missing keys on items in reorderable lists.  
- Disposal gaps (missing dispose/unsubscribe/close).

---

## The review method

Run an adversarial review before closing any Block. Three frames, each catching a different class of issue. Frame diversity is the technique, not pass count: two passes with the same frame give diminishing returns, two different frames find different bugs. Cap at two to three passes with deliberate frame diversity.

### Frame 1: Taste (required on every Block)

"You are a salty principal engineer who hates this work. What would you criticize? What edge cases are missing? What is the laziest part? What will age poorly?"

Catches: code quality, naming, duplication, missing tests, architectural shortcuts, API design that ages poorly, UX inconsistency, lazy copy. Run the universal senior signals and the audience check inside this frame.

### Frame 2: Operational (required when the Block touches data persistence, async, or external calls)

"You are the on-call engineer at 2am on launch night. What is going to wake you up?"

Catches: unhandled exceptions, silent data loss, corrupted-state recovery, clock skew and timezone bugs, orphaned data after schema changes, retry gaps, race conditions, resource leaks.

### Frame 3: Security (required on any Block touching auth, payments, tiers, public endpoints, file storage, or user PII)

"You are a security auditor reviewing this before public launch. What is exploitable? What data leaks? What is checked client-side that should be server-side?"

Catches: client-side gating with no server enforcement, restricted content leaking through the rendered output, input-validation gaps, plaintext sensitive data, predictable tokens/IDs, rate-limit bypasses, cross-tenant access, PII in logs/URLs/responses.

If a Security frame on a public endpoint returns zero findings, that is suspicious. Push: "Walk through every auth and authorization point. For each, what is the failure mode if bypassed?"

### Dispositions and severity

Every finding gets one of three dispositions:

1. **Fixed.** Done this session. Use when cheap (under 30 minutes, no architectural change).  
2. **Defended.** Explain why it is correct as-is. Not "this is fine" but "the component is single-use and co-located with its caller; extraction earns its place at instance 3."  
3. **ROADMAP with concrete trigger.** Real work, not worth doing this Block. Pin with a trigger.

Severity: **High** (ships only after fix, blocks close), **Medium** (fix or documented defense), **Low** (can ship with disposition), **N/A** (verification of correct behavior, not a finding). The N/A rows matter; they prove the posture was checked, not assumed.

Use a markdown table grouped by frame: Finding | Severity | Disposition.

### The audience check (lives inside the Taste frame)

Before approving any user-facing copy, feature, or interaction, ask: **"Is this for THIS user, or for me?"** Most software bugs are not logic errors, they are audience errors: a feature designed for the founder, not the actual user. Pin a one-paragraph description of the real user somewhere visible and test every UX decision against it:

- Would they understand this language without context?  
- Would they feel respected, or talked down to?  
- Would they want to use this daily, or grudgingly when forced?  
- Is the assumption I am making true for THIS user, or for me?

### Walk-back is senior behavior

If during disposition you re-read and conclude a finding was wrong, walking it back is correct, not flip-flopping. Document: "On re-read this is correct as-is; the concern was X, but Y handles it."

### Adversarial passes are a safety net, not the primary detector

If a pass finds something major (a whole missing test suite, a whole missed feature), that is not the system working, it is a signal the planning step was incomplete. The recovery worked but the plan didn't. Tighten the planning checklist so passes catch things you couldn't have anticipated, not things you forgot to list.

---

## Reporting discipline

The single most important reporting rule: **the writeup must not do work the diff didn't.** A confident, well-organized report can make work look more thorough than it was. Under-claim, never over-claim. An under-claiming report is always more trustworthy.

- **Do not frame a scope cut as judgment.** Say "I deferred X, trigger: Y." Not "after careful consideration X was determined premature." That is marketing.  
- **Do not bury what was not done.** If the brief had 8 items and you did 5, the 5/8 is visible in the structure, not hidden in the conclusion.  
- **Audits report counts and file references, not assertions.** "Disposal audit: 7/7 state classes, table below" with the table. Not "checked, all good." Zero hits is a real result; report it the same way as fifteen hits, with the count audited. Silence on an audit category reads as "didn't run," because that is usually what it means.

---

## Documentation discipline

Three living documents per project compound across the build. Total upkeep is about 10 minutes per Block.

### DECISIONS.md

Every architectural or product decision that had multiple defensible options, a non-obvious reason, could be questioned later, or sets a pattern others follow. Plain markdown table: Date | Decision | Reason. Add entries DURING the Block, when the reasoning is freshest. Pin extraction triggers, deferral triggers, and standing rules here too so they are searchable. Does not include obvious choices, implementation details (those are code comments), or daily logs (those are commit messages). Roster reached 88 entries by Block 7 and was still navigable; do not split until 200+.

### WISHLIST.md (tiered)

Capture every "good idea but not now" with a reason and a tier. Lost ideas do not come back, and a written "v2 candidate, here's why" entry stops you relitigating the same idea every few months.

- **v1.1 (committed):** decided, scheduled after v1 ships and gets real usage. Strong deferral reason. Expect 3 to 7 by v1 ship.  
- **v2 candidates (pin, don't build):** need real usage data first. Promote when warranted.  
- **v3+ candidates:** need scale, customer pull, or operational maturity.  
- **Business tier:** pricing, packaging, model items.  
- **Skipped:** came up, does not fit the vision. Document the reason so you don't revisit.

An item earns a real spec when ALL FOUR are true: at least 3 customers (or one strong reason from your own use) asked for it; you can state the user problem in one sentence; you can describe the smallest version that solves it; building it does not break the existing surface. Items 6+ months old with no pull get deleted. A stagnant wishlist is noise.

### Lessons captured live

A section in the project spec, appended at each Block close (1 to 3 entries). What surprised you, any disposition you walked back, any pattern across Blocks, any AI behavior that needed correction, any product call that almost went wrong. Short title plus 2 to 4 sentences. By project end you have 15 to 25 lessons that feed the next version of this framework. Run the maintenance protocol (in `TEMPLATES_AND_PROTOCOLS.md`) to fold the universal ones in.

---

## Recurring product patterns

Patterns worth considering in every app, not just the one that birthed them.

### The suggestion box (in-app feedback channel)

Every app where a user could have input gets a low-friction way to send it from inside the app. On Roster this was a "Send Feedback" item in the user menu opening a small modal: a category selector (suggestion / bug / question / other), a text area with a character cap, an optional "OK to follow up by email" checkbox, and a confirmation toast ("Got it. We read every one."). It writes a row to a `feedback` table and emails the contents to an admin.

The reusable shape:

create table feedback (

  id uuid primary key default gen\_random\_uuid(),

  user\_id uuid references profiles(id),

  category text check (category in ('suggestion','bug','question','other')),

  message text not null check (length(message) \<= 1000),

  follow\_up\_ok boolean default false,

  resolved boolean default false,

  created\_at timestamptz default now()

);

Access rule: users can INSERT their own and SELECT their own. No UPDATE or DELETE (they cannot retract or alter). Admin reads through the dashboard. Email delivery can be database-only at first and wired to a mail service once you have a server-side function to hold the API key.

The broader principle: **look for captive surfaces where a small input or message adds value, and use them.** The feedback modal is the obvious one. But the same instinct produced the "daily message on the resident check-in success screen" idea (a screen the user already sees, repurposed to carry rotating local resources and practical advice). When you build any screen a user returns to, ask whether it is a place to capture input or deliver a small piece of value. Add it where it makes sense; skip it where it would be noise.

### The self-generating handbook

Every app maintains a `HANDBOOK.md`: a plain-language manual that explains what every feature does and how it works, written so you (or anyone) can read it and confidently explain the app to a customer, an inspector, or a new hire. It is mostly layman's language with light technical depth where that helps understanding.

It self-generates because the end-of-Block recap produces or updates the handbook section for the feature just shipped (the recap template includes this step). You are never writing the manual all at once at the end; it accrues one feature at a time while the details are fresh.

Per-feature section shape:

- **What it does** (plain language, two or three sentences).  
- **How to use it** (numbered steps, the way you would tell a person).  
- **What happens behind the scenes** (light technical: what gets stored, what triggers an email, what an inspector can and cannot see).  
- **Limits and gotchas** (what it does not do, where it can trip someone up).  
- **Where it shows up** (other surfaces it touches, for example Inspector View or the audit log).

Leave a `> [screenshot: ...]` placeholder line wherever an image will eventually go. Pictures come later; the words come now. The handbook skeleton is in `NEW_PROJECT_SETUP.md`.

---

## Working with the human

- **Explain why, not just what.** For every non-trivial change the writeup answers why, not only what. The human is learning the architecture, not just receiving it. An engineer who cannot explain their choices is not senior.  
- **Escalate, do not decide unilaterally,** on: any product or UX behavior change, any new paid dependency or service (cost is fine when justified, still surface it), schema migrations that backfill existing data, anything touching the business model, and any single change whose diff exceeds roughly 1,500 lines. When in doubt, surface it. An extra check-in is cheap; an unwound architectural mistake is not.

---

## When to break the framework

Do not be religious. Apply the full discipline when the output ships to real users, handles money/PII/compliance, is hard to undo (migrations, contracts), or is a foundation others build on. Use lighter discipline for one-off scripts, throwaway prototypes, and personal tools. Knowing which is itself a senior skill.

---

## Reference

- Built from: Roster (React \+ Supabase, v1 6 Blocks \+ v1.1 8 Blocks, 240 tests, 17 migrations) and Vouch (Flutter).  
- Consolidated May 2026 from seven files (AI\_BUILD\_FRAMEWORK, REVIEW\_FRAMEWORK, DECISIONS\_AND\_WISHLIST\_DISCIPLINE, BLOCK\_TEMPLATES, FRAMEWORKMAINTENACETOOL, plus the legacy SENIOR\_CODER\_AI\_PROMPT\_FRAMEWORK and SENIOR\_REVIEW\_FRAMEWORK) into three, preserving the legacy senior-signals and reporting-discipline content the interim split had dropped.  
- Living document. Update via the maintenance protocol, not ad hoc.

