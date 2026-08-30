# V1 Premier League seed catalogue

## Change identity

- **Approval:** Andrew approved the offline catalogue block with `ok lets do it` on 2026-08-30.
- **Starting head:** `35feff9bb5f45fd24df835bc9a4e4f9a98470651`, merged PR 21.
- **Scope:** Consolidate the completed owner research into the 19 missing club files, retain dated roster and chant review metadata, add a safe runtime projection, and verify the source catalogue without accessing Firebase.
- **Excluded authority:** No live preflight, service-account use, Firebase read or write, deployment, commit, push, merge, store action, or release.
- **Durable decisions:** Decisions 005 and 006 now record the complete source catalogue, runtime provenance, and pending live boundary.

## Catalogue result

Source now contains all 20 approved 2026-27 Premier League clubs. The 19 new files add 180 chants and 594 dated squad rows. Together with Arsenal, the repository has 192 seed chants across 20 clubs. Every new club clears the three-chant floor, while larger owner-supported songbooks remain intact instead of being cut to the former five-chant target.

The settled exclusions remain enforced: no Wagner-specific Ipswich chant, Bruno Guimaraes Newcastle chant, violent Banks of the Royal Blue Mersey, or Tottenham Yid Army entry. Mohamed Salah remains a historic Liverpool subject, Bruno Fernandes remains a current Manchester United player, and the owner-confirmed Chelsea Carefree wording is retained.

## Identity, currentness, and provenance

Every new chant has an explicit club-prefixed immutable ID, an era, a 2026-08-30 review date, an owner-verification marker, and at least one HTTPS source URL. A normalized roster snapshot records the display names derived from the official Fantasy Premier League feed for the 19 squads. Current player chants fail validation unless their player name matches the relevant source squad.

Departed players and managers remain searchable within their club's Songbook without polluting the current squad. Until a separately reviewed historic-player model exists, those chants use club-level runtime linkage, a clear historic context note, and offline `historicSubject` metadata.

## Runtime boundary

`seed/seed_chant_data.ts` owns the pure source-to-runtime projection. Seeded chants now publish `origin: alreadySung`, including safe content-only updates to existing system-owned targets. Offline `era`, `reviewedAsOf`, `ownerVerified`, `historicSubject`, `sources`, `catalogue`, and roster-snapshot data do not enter Firestore.

The seed retains its existing safety sequence: validate source, preflight every target identity before club writes, and recheck target ownership inside each chant transaction. Orphans are reported and never deleted automatically.

## Verification evidence

- The focused catalogue test was red before the new files existed: only Arsenal was present, and the settled Liverpool inclusion could not be found.
- The complete seed suite passes 54 tests.
- Seed TypeScript compilation passes with `npx tsc --noEmit`.
- All 20 club files parse and validate. The 19 new squads match the checked-in dated roster snapshot value for value.
- Audit totals are 20 clubs, 621 source squad rows including the inherited 27-player Arsenal file, 192 chants, 180 new chants, 22 current-subject chants, 12 historic-subject chants, 42 distinct retained source URLs, and zero duplicate chant IDs.
- Independent staged review re-derived the runtime, identity, roster, metadata, inclusion, exclusion, and count claims without relying on this record. It found no implementation defect. A read-only reachability pass found one Crystal Palace citation trapped in a publisher-owned case-redirect loop; the row now uses the already retained Palace roundup that supports the same chant. FanChants returned bot-denial responses during automation, which is recorded as unverified reachability rather than treated as a missing source.
- `git diff --check` passes for the implementation boundary.

## Remaining gates

The 2026-08-30 roster is transfer-sensitive and must be refreshed before a live write. Andrew must separately authorize the named-project read-only identity preflight. If it is clean, write one named club, inspect exact document IDs and fields, run readback and orphan checks, and only then widen. Exact-head clean-runner CI, production writes, and release remain outside this local source block.
