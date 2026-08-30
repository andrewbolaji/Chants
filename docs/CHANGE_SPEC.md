# Change spec: V1 Premier League seed catalogue

**Status:** Approved
**Updated:** 2026-08-30
**Risk lane:** Lane 2 persistent public content, stable identity, source provenance, and later production data writes
**Base:** `35feff9bb5f45fd24df835bc9a4e4f9a98470651`
**Approval:** Andrew approved the offline catalogue block with `ok lets do it` on 2026-08-30 after the remaining work was enumerated.

## Outcome

- **Problem:** Arsenal is the only club represented by reviewed seed JSON. Andrew has completed the lyric research for the other nineteen 2026-27 Premier League clubs across the seed workbook, owner Notes material, resolved decision records, and the completed three-item confirmation sheet, but those sources have not been consolidated into repository seed files.
- **Desired state:** Source contains one validated club file for every 2026-27 Premier League club, with stable chant IDs, a dated externally sourced squad snapshot, owner-supplied or independently supported chant wording, retained review provenance, settled exclusions, and no live Firebase mutation.
- **Review boundary:** `seed/`, `seed_data/clubs/`, the normalized dated roster snapshot under `seed_data/rosters/`, seed-focused tests, the active execution record, roadmap content status, and one scoped completion rationale.
- **Non-goal:** No Firebase read or write, service-account access, deployment, live preflight, orphan reconciliation, app runtime feature, full historic-player browsing model, legal conclusion, commit, push, merge, store action, or release.

## Source authority

1. The approved 2026-27 league roster is Arsenal, Aston Villa, Bournemouth, Brentford, Brighton, Chelsea, Coventry City, Crystal Palace, Everton, Fulham, Hull City, Ipswich Town, Leeds United, Liverpool, Manchester City, Manchester United, Newcastle United, Nottingham Forest, Sunderland, and Tottenham Hotspur.
2. West Ham United and Wolverhampton Wanderers remain intentionally excluded from this launch roster.
3. Exact chant wording comes from Andrew's supplied workbook, Notes paste, and completed confirmation sheet. The implementation may normalize punctuation, whitespace, masking, and line breaks, but it must not complete or rewrite missing lyrics.
4. Source URLs from the workbook and owner records are retained as offline review metadata. They are not promoted automatically into public Terrace Proven evidence because the runtime evidence contract accepts only canonical YouTube or X links.
5. The squad snapshot comes from the official Fantasy Premier League bootstrap feed fetched on 2026-08-30. Every live write requires a fresh roster review because the transfer window and registrations can change after this snapshot.

## Required catalogue behavior

1. Add the nineteen missing club JSON files using the existing Arsenal team, squad, and chant schema.
2. Preserve every real, meaningful, nonduplicate owner-approved chant. Do not enforce the old five-chant cap.
3. Every chant has an explicit lowercase stable ID prefixed by its team slug.
4. Every new chant records offline catalogue metadata for review date, era, owner verification, and at least one supplied source URL. Seed writes continue to publish only the existing allowlisted runtime fields.
5. Seeded Terrace Proven chants write `origin: alreadySung`. Source provenance remains review metadata unless it satisfies the separately reviewed public evidence contract.
6. Historic player or manager chants may remain in the club catalogue without being presented as current squad members. Until the planned historic-player model exists, they use club-level runtime linkage plus an explicit historic context note and offline historic subject metadata.
7. Current player chants link only to a name present in the dated squad snapshot. A transfer-sensitive mismatch fails validation instead of silently changing the subject.
8. Every club clears a three-chant floor. Larger collections are accepted when the supplied entries are real and nonduplicate.

## Settled content decisions

1. Remove Wagner-specific Ipswich wording.
2. Remove Bruno Guimaraes chants from Newcastle after his Arsenal move.
3. Keep Mohamed Salah as a historic Liverpool chant rather than a current squad entry.
4. Keep Bruno Fernandes at Manchester United.
5. Keep Chelsea `Carefree` using the owner-confirmed wording.
6. Exclude Everton `Banks of the Royal Blue Mersey` because it calls for violence.
7. Exclude Tottenham `Yid Army` from the launch catalogue because of protected-class slur risk and the club's public position.
8. Keep real crude rivalry banter inside the existing 17-plus policy line. Exclude protected-class hate, tragedy mockery, and threats or calls for violence.
9. For chants that reproduce an underlying commercial song rather than football-specific words, retain only the owner-approved short or football-specific section with a tune credit. Final legal review remains a launch gate.

## Invariants

1. The catalogue never invents lyrics, squad membership, evidence, cultural context, or popularity.
2. Offline provenance metadata is not written into unsupported Firestore fields.
3. Existing Arsenal document IDs and live compatibility remain unchanged.
4. Generating the catalogue performs no network or Firebase operation.
5. Preflight and live seed modes remain separate. This block does not authorize either.
6. Validation stops on an unknown era, empty source list, invalid stable ID, duplicate normalized title, missing current player, malformed roster snapshot, or a settled excluded chant.

## Verification plan

1. Add seed regressions for the twenty-club roster, nineteen new provenance-bearing files, three-chant floor, known inclusion and exclusion decisions, current-player linkage, and nonpublication of offline metadata.
2. Run the focused red tests before the catalogue exists.
3. Build the nineteen files from supplied chant wording and the dated official roster snapshot.
4. Run `npm test` and `npx tsc --noEmit` in `seed/`.
5. Parse every JSON file, inspect per-club chant and squad counts, scan duplicates and excluded terms, and compare the roster population with the downloaded snapshot.
6. Stage the intended boundary and run project memory, writing style, governance regressions, and diff integrity checks.
7. Keep clean-runner CI, independent review, live identity preflight, Firebase writes, readback, and release as later gates.

## Rollout and recovery

This block creates repository source only. If validation or review finds a source problem, correct or remove the affected offline row before any preflight. A later live rollout starts with a separately authorized read-only Arsenal identity preflight, then one named club write and readback. Any ownership, collision, roster, content, or orphan mismatch stops the rollout. The seed pipeline never deletes reported orphans automatically.
