# V1 device-test preparation

## Change identity and boundary

- **Request:** Andrew merged PR 25 and requested the proposed local check, improved existing walkthrough and one combined later Claude review.
- **Agent/lane/date:** Codex, Lane 1, 2026-08-31 UTC. Plan and acceptance are in the active execution entry. The existing Lane 2 safety spec is preserved, not replaced with a second active spec.
- **Base:** `72a39b1738622f196da7fab5b040a2fc76c18c67`, merged PR 25. Target is the single preparation commit on `codex/v1-device-test-preparation`. Packaging, push and exact-head CI are authorized; the PR will retain their immutable receipt after completion. This precommit record does not claim CI success.
- **Population:** One diagnostic and its test; adopted private HTML guide plus adjacent browser script and test; existing governance CI job; AGENTS and affected execution/profile/interface/runbook/roadmap/overview/rationale records.
- **Non-goals:** App, Functions, rules, seed content or data, dependencies, Firebase configuration, credentials, native builds/installations, provider/domain changes, production inspection/mutations, signing, merge and release.

## Outcome

Implemented a passive local setup inventory with explicit opt-in device enumeration, plus one ordered walkthrough with observations beside instructions. Corrected the guide's stale claim that seeding is unfinished and removed its broad Functions deployment recipe. Source/logic tests pass. The browser safety policy rejected opening the local file, so visual/interactive-browser verification is not complete and no workaround was used.

The existing staged guide in `chants-v1-launch-services` was read and adopted, not edited or unstaged. Its original SHA-256 is `9ba2dc583e42f9bc4b568041b96438ec37be9110919116f761b67e9df91d9a8a`. The older untracked guide and owner edits in `chants-repo` are untouched. The guide in this worktree is the maintained version going forward; old copies are historical, not competing current instructions. No original file was deleted.

## Impacted capability map

| Boundary | Before | After / source |
|---|---|---|
| Local preparation | Manual commands and easily confused checkouts | `check-device-readiness.mjs :: collectReadiness` resolves its own checkout, checks presence/access and tool locations without reading config bytes |
| Device inventory | Raw SDK output can expose names and IDs | Explicit `--devices` with exact SDK argument arrays, bounded execution/output and aggregate counts only |
| Walkthrough | Old staged guide mixed unfinished seed instructions with later launch work | Existing HTML gains stage 0, completed catalogue status, rollout-specific holds, ordered physical-device journeys and Living Songbook checks |
| Evidence capture | Checkmarks/notes without candidate-sensitive per-platform observations | `recordObservation`, `observedStatus`, `buildReport`: platform-specific context, explicit record action, stale results and copyable notes |
| Verification | No preparation-tool gate | Existing governance job runs the two dependency-free Node test files; no new job or workflow |

## Implementation choices

| Choice | Reason / alternative / tradeoff | Evidence |
|---|---|---|
| Presence-only default | Running Flutter can initialize SDK state, resolve packages or migrate native files. Avoid invoking it during a claimed passive inventory. File existence does not prove valid config or supported versions | Passive runner is never called in tests; real config fixture bytes unchanged; output says NOT validated |
| Opt-in SDK discovery | Useful connected-target check without building a custom discovery system. OS/ADB services may start; not a zero-OS-side-effect promise | Exact xcrun/adb arguments, no shell, 15-second SIGKILL timeout, 256 KiB output cap; invalid/failed/interrupted output is unknown |
| Fixed local source root | Stops Terminal's current directory silently selecting an older checkout | Real CLI invoked from temporary directory still identifies its own pubspec |
| Reuse guide and plain JS | No UI framework, package or server added. Classic adjacent script keeps the file pair usable offline | Static script linkage and actual shipped script executed against a minimal DOM fixture |
| Separate v3 browser key | Changed tasks must not inherit old v2 completion. Old data is not removed or automatically migrated | Storage-key roundtrip fixture; visible migration note |
| Explicit result recording and context stamp | Source/backend/platform changes invalidate earlier observations. Notes alone cannot revalidate a pass | Pure stale-context tests plus actual button/input wiring fixture |
| No new ADR | Local reversible tooling does not change product authority or durable architecture | Scoped rationale and interface memory hold the small design decisions |

## Changed flow and state

CLI validates arguments, inspects fixed local paths, optionally runs one allowlisted discovery process, parses its output into aggregates and renders fixed sanitized text/JSON. Exit 0 means no local inventory issue, 1 means missing/unknown/attention, 2 means invalid usage. Unrequested discovery stays Not checked. Simulator-only results cannot pass a physical-device check. Neither exit code nor file presence authorizes production work.

The guide restores only local v3 progress. Per-platform results require source, backend and that platform's build context for Passed/Failed; Blocked may be recorded before rollout. Result notes are text, not markup. A changed context marks previous observations stale. Record result is explicit so a retest can re-record the same selected value. Clipboard failure falls back to selection and reports failure if copying still fails. Storage refusal preserves in-memory use and warns about reload loss. Confirmed reset remains usable even if persistence is denied.

## Security, privacy and abuse impact

- No changes to application identity, authorization, moderation, counters, deletion or server-owned state. No Firebase client/Admin SDK import or production call.
- The default diagnostic uses filesystem metadata only. It never reads service-account files, Firebase config contents, Keychain or private signing material. SDK stdout/stderr/errors are not echoed. Test identifiers are synthetic.
- Browser notes are owner-entered and may contain sensitive material if the warning is ignored. The guide does not claim automatic redaction. Only context and per-journey observations enter the report; unrelated launch notes are excluded. No external requests or automatic uploads are added.
- The guide is private and outside public Hosting. Keep HTML and JS together. Local progress is not trusted release evidence or an approval mechanism.

## Dependency, infrastructure, performance and cost impact

No dependency/lock/runtime/cloud/native changes. The existing governance job gains one Node test command; fixtures are local and synthetic. Default work is bounded filesystem metadata checks. Optional discovery is one process with a 15-second execution limit and 256 KiB output cap. Browser note fields are capped at 4,000 characters. No performance improvement or hosting-cost claim is made; live Android discovery and version compatibility remain unverified.

## Verification performed

| Check | Observed result |
|---|---|
| `node --test scripts/test-device-readiness.mjs scripts/test-launch-guide.mjs` | 19 focused cases pass after final CLI cwd regression. Covers missing/unreadable files, no passive command execution, wrong host, simulator-only, malformed/error/signal output, redaction, exact options, CLI usage, storage refusal, stale context, report boundaries, real guide event wiring, copy failure and reset |
| Actual passive CLI on new worktree | Correctly exits 1 for absent local Flutter package config and Firebase client files. Does not create them or read the prepared checkout's copies |
| Actual opt-in iOS CLI | At 01:58:33 UTC: one available physical iOS target and eleven simulator targets. Names/identifiers omitted. Overall exit 1 still correctly reflects missing configuration; no app install or signing proof |
| Static JavaScript/HTML | JS syntax, unique IDs, local anchors, labels and copy targets checked. Deprecated seed task and broad deploy command negative fixtures are covered |
| Known-bad mutation evidence | Temporarily allowing zero physical targets to pass and bypassing candidate staleness produced four failing tests, including actual guide event wiring. Both mutations were restored and all 19 tests passed again |
| Browser | Local-file navigation rejected by Browser Use safety policy before render. No visual, keyboard, narrow/enlarged-layout, real clipboard or persistence observation claimed. No alternate server/browser used to evade the rejection |
| Broader source suites | Flutter, Functions, rules and seed inputs untouched, so their costly suites/native builds are not rerun. Prior safety CI 33346847132 belongs to 421463e, not this block |

Final staged governance, authored-text and diff results are recorded in the execution log. The full changed-source review includes the adopted artifact and checks its changed ownership/state claims; legacy external service/store steps remain reference aids, not freshly verified live or legal instructions.

## Rollout, observation and recovery

No deployment or data migration. Andrew authorized one commit, push and exact-head CI. The preparation PR records the resulting SHA/run after they exist. Combined Claude review keeps the last sign-off base `cb50d3cc966c6a367309c887a8c765891155cf0e` and extends through that exact preparation head. PR 25's merge does not close its pending independent review. Merge and all production work remain separately gated.

Human inspection of the guide remains necessary before calling its UI verified. Backend rollout and service/provider/domain gates precede relevant live journeys; destructive tests require disposable approved targets and separate permission. Reverting this tooling has no app/server effects. Copy observations before changing browser or file location; old v2 data is not destroyed.

## Known compromises and uncertainty

| Item | Consequence / owner / revisit trigger |
|---|---|
| Browser policy blocked visual QA | Andrew needs an allowed human/verification surface to check desktop, narrow width, enlarged text, keyboard and real clipboard/storage behavior |
| Presence is not configuration validation | Andrew must confirm project identity and compatibility in separately controlled client setup before building |
| Fresh checkout lacks local config/dependencies | Expected inventory failure; do not copy credentials or overwrite prepared files to make the check green |
| Device discovery is not provisioning | iOS inventory is observed; Android inventory parsing is fixture-tested only. Revisit on the actual Android host/device |
| Legacy staged-guide adoption | Historical source is preserved; current guide removes known stale seed/deployment claims, but service/store instructions still need contemporary verification at their own gate |
| Local browser records are self-reported | No server synchronization, identity enforcement or secret detector. Keep reports sanitized and retain observation evidence separately |

## Repository reconciliation

Overview/rationale/profile identify merged PR 25 separately from the preparation block and its own CI receipt. Runbook owns local commands and remaining live gates; interface memory owns this guide's interaction; roadmap owns the extended combined-review sequence. No second active change specification or architectural decision system was created.
