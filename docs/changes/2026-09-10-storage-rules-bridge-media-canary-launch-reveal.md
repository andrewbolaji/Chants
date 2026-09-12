# Storage Rules bridge, successful media canary, and launch-reveal simplification

- **Date:** 2026-09-10
- **Status:** Completed and contained at generation 35 maintenance
- **Authority:** Andrew approved the exact Storage-to-Firestore Rules bridge, one generation-34 private media canary, and the bounded launch-reveal simplification recorded in `docs/CHANGE_SPEC.md`.

## Result

The project IAM policy now grants the documented `roles/firebaserules.firestoreServiceAgent` role to the Google-managed Firebase Storage service agent. This is the single cross-service edge required because the existing Storage upload rules read Firestore authorization state. The rules, bucket controls, runtime identity, App Check posture, application data, and every other project binding were left unchanged by this correction.

Generation 34 opened from the reviewed server source only after safe baseline and exact IAM readback. The generation 35 close was prepared first. One 10.1-second, 19.5 MB iPhone video reached `IN THE REVIEW QUEUE`. Final proof found one matching pending-review draft and private staged object, no active upload grant, no public performance, no cleanup job, and generation 35 maintenance with destructive workers false. The video was not inspected, moderated, published, downloaded, or played.

The Flutter launch reveal no longer draws the two broad floodlight wedges, curved echo arc, or redundant background horizon that read as an accidental tuxedo shape on the phone. It retains the supporter-and-scarf shield, wordmark, divider, tagline, sound bars, crowd dots, timing, semantics, reduced motion, loading cue, and compact behavior. The complete Flutter suite passes 558 tests, scoped analysis reports no issues, and the inspected 390 by 844 golden passes. Current-source phone proof waits for the next candidate rebuild.

## Installed-build observations

The older iPhone build still invokes interrupted-picker recovery on iOS and renders `POSTING AS @handle` as a low-contrast inline string. Current local source limits lost-picker recovery to Android and gives the public handle its own bordered, high-contrast chip. Those source corrections already have focused tests and inspected goldens, but they are not device evidence until rebuilt and installed.

## Next gate

Freeze the accumulated candidate source, rebuild Android and iOS, run the complete planned consolidated independent review, resolve accepted findings, and rerun exact-head CI plus native release verification. Store upload, submission, moderation, publication, commit, push, merge, and release remain outside this completed block.
