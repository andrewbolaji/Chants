# Beautification Brief: Senior Product Designer Pass (any app)

A reusable prompt for running a design beautification pass on any app, at the quality bar of a senior product designer with 10+ years at the level of Apple, Google, Linear, and Stripe. Companion to `AI_BUILD_FRAMEWORK.md`, `TEMPLATES_AND_PROTOCOLS.md`, and `NEW_PROJECT_SETUP.md`. Point it at an app when the logic is sound but the surface needs to look and feel considered.

Use this when: an app works but looks unconsidered, inconsistent, or cramped; a project is approaching launch and the UI needs to read as intentional; or a design system needs to be established from scratch on an app that grew feature-first.

---

## The prompt (copy-paste)

Put on a specific hat for this work: a senior product designer with 10+ years at the level of Apple, Google, Linear, and Stripe, who makes things beautiful through restraint, not ornament. I want a beautification pass on this app. Not a logic overhaul, not new features. Go through the app, establish a real design system, and find the highest-impact opportunities to make it look and feel considered.

### Design philosophy to work from

- Simplicity is the beauty. The references for "beautiful" are Linear, Stripe, Notion, Things: calm, spacious, ruthlessly simple. Remove anything on screen that does not earn its place.  
- One design system, tokens not magic numbers. Every color, font size, spacing step, and radius comes from a defined scale, never a hardcoded literal in a component. That single discipline is what makes an app look consistent and intentional.  
- Restrained palette: a calm neutral base plus a tightly limited accent, used surgically on actions and key states, plus semantic colors (success, warning, danger) used only for meaning. No second decorative accent.  
- Strong, simple type hierarchy. Two or three weights, clear sizes, legibility first, especially for the app's core data and any read-only or export views where trust matters.  
- Generous spacing and rhythm. Hairline dividers over heavy boxes. Flat: no gradients, drop shadows, glow, or noise.  
- Accessible by default: WCAG AA contrast, real click and tap targets, text that respects system scaling.  
- Every state designed: empty, loading, error, and success, not just the happy path.  
- The audience check governs everything: design for this app's actual user. Read the product's own docs and decide who that is, then let the look follow from the audience. A professional or operational tool should read clean, efficient, and trustworthy, never flashy. A consumer product can carry more warmth and personality. Either way, consistency across screens beats local cleverness.

Critical adaptation: derive the app's own aesthetic from its product and audience. Do not import a look that does not fit it (a consumer or dark-mode social-app style on a professional tool, or a sterile enterprise style on a playful consumer app). Decide what this specific product's beauty is before styling anything.

### Process, plugged into the usual block cadence

1. First, read the product docs (spec, decisions, handbook, whatever exists), then review the actual current UI. Ask me for screenshots of each main screen, or review the component and styling files directly, before proposing anything. Tell me what you see: where it looks unconsidered, inconsistent, cramped, or off-brand for its audience.  
     
2. Produce a DESIGN\_DIRECTION.md for this app: the product's visual vibe, palette, typography, spacing scale, and component principles, all derived from its audience. Then show me a visual mockup of one or two real screens redesigned to that direction, an actual mockup rather than a description, so I can react to the look before any code. Get my sign-off on the direction.  
     
3. Give me a prioritized opportunities audit: the screens and components where a design pass buys the most, highest impact first, so we beautify where it matters and skip where it does not.  
     
4. Run it as a dedicated design block in the normal cadence: plan first and no code until I approve, define the design system in tokens, restyle screen by screen, no logic changes, adversarial review with the Taste frame and the audience check, recap with measured results, close on a commit hash. Tests as deliverables only where you touch testable logic, since most of this is visual.

No em dashes, sentence case, and hold the same quality bar we hold everywhere. Start with step 1: read the docs, then ask me for what you need to see the current state.

---

## Why this works (the reasoning behind the prompt)

- **Tokens are the whole game.** The difference between an app that looks intentional and one that looks improvised is almost never talent, it is whether every color, size, space, and radius traces to a defined scale. Establish the scale first; restyling then cascades instead of being fought screen by screen. An app whose theme is already tokenized in one place can often be re-skinned by editing that one file, so the first audit question is always "are components on the tokens, or did hardcoded values and stock framework classes creep in?"  
    
- **The audience is the variable, the principles are constant.** The restraint principles above are universal. What changes per app is who it serves, and that decision drives palette warmth, type personality, and density. Derive the audience from the product's own docs before proposing a look. Never import an aesthetic from a different kind of product.  
    
- **Trust surfaces deserve extra care.** Any read-only view, export, or screen an outside party reads (an inspector, an auditor, a customer's customer) is where legibility and calm matter most, because there beauty equals credibility. Identify these early and treat them as the highest-stakes screens.  
    
- **Fix the system once, hand-tune the few that earn it.** Most screens should inherit polish from restyled shared primitives (one button, one input, one card, one badge with semantic variants) and a restyled shell. Only a handful of high-traffic or high-stakes screens earn individual attention. The opportunities audit in step 3 is what separates the two so effort lands where it matters.  
    
- **No logic changes is the guardrail.** A beautification pass that quietly alters behavior is no longer a beautification pass and becomes un-reviewable. Hold the line: visual only, logic untouched, tests as deliverables only where testable logic is genuinely touched.

---

## Reference

- Created May 2026, generalized from the Roster design pass brief into a stack- and product-agnostic prompt.  
- Living document. Refine if a future design pass surfaces a principle these miss.

