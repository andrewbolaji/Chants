# Templates and Protocols

The copy-paste prompts you send the implementer, plus the maintenance protocol the AI executes on the framework itself. Companion to `AI_BUILD_FRAMEWORK.md` (the why) and `NEW_PROJECT_SETUP.md` (the Day 1 setup).

This is a reference file. You dip into it during work; you do not read it cover to cover.

---

# Part A: Block prompts

## Block kickoff

Send at the start of every substantial Block. Customize the bracketed parts.

```
Begin Block N: [feature or work unit]. Same cadence as previous Blocks:

1. Plan first. Do not code until I approve. Enumerate deliverables, files to create, files to modify, migrations needed, and tests to write.

2. After plan approval, build with tests as deliverables. Tests ship with the feature, not after.

3. Adversarial review with [Taste / Operational / Security] frames. (Taste always. Operational if data persistence, async, or external calls. Security if auth, PII, payments, tiers, public endpoints, or file storage.)

4. End-of-Block recap, then we close.

Think hard about, during planning:

a. Reuse from prior Blocks: [storage layer, contexts, shared components, established patterns].

b. Architectural concerns specific to this Block: [1-3, e.g. "first feature with multi-table writes" or "first public endpoint"].

c. Security / threat-model considerations: [PII exposure, public access, file uploads, etc.].

d. Edge cases needing my input before building: [2-3 specific product decisions].

e. Standing rules: 9th-grade copy, no em dashes, tests as deliverables, measure-don't-estimate on every number, [project-specific rules: .def.ts pattern, schema-prefix extension calls, etc.].

f. Devil's advocate yourself. Surface 2-3 edge cases or risks during planning, not after. Flag any policy ambiguities or assumptions to confirm before building.

Plan first.
```

Notes: Taste is always required. Operational triggers on persistence/async/external calls. Security triggers on auth, payments, tiers, public endpoints, file storage, or PII. Step f is the highest-leverage part of planning; it surfaces bugs that are expensive to fix later.

## End-of-Block recap

Send when the Block is built. The structure forces a consistent, reviewable close-out.

```
Block N is built. Before I review, give me the standard recap:

1. What was built. Concise summary of features, files, architectural pieces.

2. Disposition table. Full adversarial review, all applicable frames. Each finding: severity (High/Medium/Low/N/A) and disposition (Fixed / Defended / ROADMAP-with-trigger). Silence is not a disposition.

3. New DECISIONS.md entries. Architectural choices made and why. Include extraction or follow-up triggers.

4. Schema or migration changes. Actual SQL of new tables, columns, indexes, policies, triggers, and any changes to existing tables.

5. Sensitive-data analysis. What new PII or regulated data this Block introduces, how it is protected, and what downstream surfaces (especially any read-only or public view) must account for it.

6. Final checks, each as a MEASURED number, not an estimate: type-check result (state the exact command and config used, and confirm it actually checks the code), lint result, test count broken down by Block. If you typed a number, you just measured it.

7. Files created and files modified. Full lists with measured line counts.

8. Anything deferred, with the concrete trigger for when it gets built.

9. Commit hash and remote URL. The Block is NOT closed until this hash exists. If not pushed, say why.

10. Handbook entry. Write or update the HANDBOOK.md section for this feature in plain language (what it does, how to use it, what happens behind the scenes, limits and gotchas, where it shows up). Leave screenshot placeholders.

Do not proceed to the next Block until I review and approve.
```

Customize Section 5's label to the domain (PII, regulated data, user content). Customize Section 6's commands to the stack and, per the verification rule, name the real command and config, not a stub.

## Verifying an audit-style claim

When the implementer reports a comprehensive scan, sweep, audit, or review:

```
Verification before closing. The recap reports the [audit type] complete. Enumerate at least 20 specific items you scanned. For each: the item (string, file content, dependency), where it appears (file + line), whether it passed or changed, and the new version if changed.

If the audit covered only a subset, say so explicitly so I know what level actually shipped. If it was thorough, the enumeration is easy to produce.
```

## Multi-task batching

When you have a kickoff plus follow-up doc tasks, send them in one message, not three:

```
[Block kickoff per template]

---

Also [N] doc tasks while you are in there:

A) [Specific task, full detail. e.g. "Append to the spec's lessons section under 'From Block N': [lesson]."]

B) [Specific task, full detail.]
```

One context, one review cycle, no forgotten follow-ups.

## Closing a Block

After review fixes are in:

```
Block N is formally closed. Commit [hash], pushed.
[1-2 line summary of what was achieved.]
Next: Block N+1, [name].
```

---

# Part B: Handbook generation

The handbook is the plain-language manual that self-generates one feature at a time (Section 10 of the recap). Use this prompt to write or refresh a section, or to assemble the whole thing at a milestone.

## Per-feature handbook entry

```
Write the HANDBOOK.md section for [feature], in plain language a non-technical person could follow. Use this shape:

## [Feature name]

**What it does.** Two or three plain sentences. No jargon.

**How to use it.** Numbered steps, the way you would walk a person through it out loud.

**Behind the scenes.** Light technical detail: what gets stored, what triggers an email or notification, what an inspector or other limited viewer can and cannot see, any automatic behavior.

**Limits and gotchas.** What it does not do. Where someone could get confused or trip up.

**Where it shows up.** Other surfaces this touches (dashboard, Inspector View, audit log, exports).

> [screenshot: describe the shot to capture later]

Rules: 9th-grade reading level, no em dashes, match the app's actual current behavior (read the code, do not assume). If behavior changed since the last handbook update, update the section to match.
```

## Milestone handbook assembly

```
Assemble or refresh the full HANDBOOK.md. One section per shipped feature, in the order a new user would meet them. Add a short intro (what the app is, who it is for, the one-sentence value). Confirm every section matches current behavior by checking the code, and flag any section you could not verify. List which sections still need screenshots.
```

---

# Part C: Framework maintenance protocol

**For the AI to execute. Not for the human to read every time.** This keeps the framework sharp instead of letting it bloat or go stale. The human invokes it; the AI applies it strictly.

## Trigger phrases
"Run the framework maintenance protocol," "update my framework with lessons from [project]," "time to update the framework," "prune the framework," "lessons-learned pass."

## Files in scope
The three framework files: `AI_BUILD_FRAMEWORK.md`, `TEMPLATES_AND_PROTOCOLS.md`, `NEW_PROJECT_SETUP.md`. Plus the project's lessons source (its lessons-captured-live section, a lessons file, or a transcript the human points to). If you lack any of these, ask which to start with before proceeding.

## Execute in this order

**Step 1: Project count.** Ask "what project number is this? (Project 1 was Roster.)"
- Projects 2-4: active growth. Add 1-3 lessons. Compress 1-3 existing entries.
- Projects 5-7: stabilization. Add at most 1-2. Compress aggressively. Watch for internalization.
- Projects 8+: mature. Stop adding by default. Refinements only. The framework should be flat or shrinking. If the human insists on adding, ask whether it is truly universal.

**Step 2: Re-read time check.** Read all three files start to finish. Estimate read time at ~200 words/minute. Under 45 min: healthy. 45-60 min: borderline, flag it. Over 60 min: bloated, no additions until a compression pass brings it back under 45. Report current word count and read time before proceeding.

**Step 3: Source and classify lessons.** Read every project lesson. Classify each as Universal (applies to any AI-assisted software, any stack), Project-specific (stays in the project's own docs), or Internalized (the human does it without thinking now). Default is project-specific. The bar for universal is high: would it apply to a Flutter app, a Python script, a Rust CLI, and a web app? If only two of those, not universal.

**Step 4: Compression pass (before any addition).** Mark each section Still-essential, Internalized, or Stale. Compress internalized entries to a one-line reminder. Replace or remove stale entries (replace, do not append). Leave essential entries alone unless wordy. Show proposed cuts to the human in this format and wait for per-item approval:
```
PROPOSED CUTS:
1. [file / section] : [text or summary] -> [new text or DELETE]
   Reason: [internalized / stale / contradicts newer lesson / wordy]
```

**Step 5: Add new lessons (only universal, only after compression).** Place each in the right file (method/philosophy -> AI_BUILD_FRAMEWORK; prompts/protocols -> TEMPLATES_AND_PROTOCOLS; setup/skeletons -> NEW_PROJECT_SETUP). If a lesson fits none, it is probably project-specific; push back. Do not modify Mount Rushmore patterns unless something fundamental about AI-assisted development changed; if asked to, require explicit justification of the fundamental change. Show each addition before making it:
```
PROPOSED ADDITION:
File: [filename]   Section: [where]
Text: [the entry]
Why universal (not project-specific): [reasoning]
```

**Step 6: Contradiction check.** If two sections give different rules for the same situation, keep the newer/more-nuanced one, remove the other, note "refined after Project N." Two contradicting rules is worse than one outdated rule.

**Step 7: Specificity drift check.** Scan for stack-specific tactics in the universal files (named libraries, file extensions, specific commands, specific architectures). Propose generalizing the principle or moving the tactic to a stack-specific patterns doc. Show before executing.

**Step 8: Re-time.** Count words again. Same size or smaller with more sharpness: success. Grew under 10%: acceptable. Grew over 10%: push back and cut more.

**Step 9: Summary.** Report project, number, mode, before/after word count and read time, counts of cuts/compressions/additions/refinements, project-specific lessons NOT added, Mount Rushmore status, health signals (re-read time, contradictions, specificity drift), and recommended next maintenance.

## Hard rules
1. No bulk changes without per-item approval.
2. No additions to a bloated framework (over 60 min read) until pruning brings it under 45.
3. Mount Rushmore is protected; modifying it requires a justified fundamental change.
4. The universal bar is high; default is project-specific.
5. Replace, do not append, when contradicting.
6. Mature mode (project 8+) means stop adding by default.
7. No em dashes in your own output during this protocol.
8. No editorializing ("great lesson!"). Execute cleanly.

## Edge cases
- **No lessons captured live:** ask the human for a 15-minute retrospective first. Do not mine code or commits; lessons are about how the work happened, not what was built.
- **"I want to rewrite the whole thing":** push back. Rewrites lose accumulated wisdom. Compress the stale sections instead. If they insist, keep Mount Rushmore and re-derive the rest, warning about lost context.
- **"Add a new file":** the three files cover most territory. Warranted only for a genuinely new template type, a stack-specific patterns doc, or a new role in the model. Ask for 3+ concrete items that would live there; if they cannot list 3, it is premature.
- **"Skip the protocol, just add a lesson":** run it anyway, abbreviated. The compression check and universal check are the point. "5 minutes, so the framework does not bloat."

---

## Reference
- Merged May 2026 from BLOCK_TEMPLATES.md and FRAMEWORKMAINTENACETOOL.md, with a new handbook-generation section and recap steps for commit-gating, measured numbers, and handbook updates.
- Living document.
