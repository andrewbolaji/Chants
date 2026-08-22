# Decision 003: Saved Matchday Songbook is an explicit offline v1 feature

**Status:** Accepted
**Date:** 2026-08-18
**Owner:** Andrew

## Context

The clearest real-world use for Chants is checking the words shortly before or during a match. Mobile connectivity at a crowded ground is unreliable. A normal favorite flag backed only by Firestore would not promise that the lyrics are actually present on the device when the network disappears, and relying on incidental Firestore cache behavior would make the product promise impossible to explain or test.

Andrew approved placing Saved Matchday Songbook in v1 and delegated the smallest useful boundary.

## Decision

V1 will provide an explicit device-local offline snapshot:

- A signed-in fan can save one chant from chant detail or save a club's current visible songbook from the club screen.
- The saved screen reads the local snapshot first and remains usable after an airplane-mode app relaunch.
- A snapshot stores only public display data needed for the offline songbook: stable source IDs, club identity, title, lyrics, tune, context, variations, and source/update timestamps. It does not store votes, comments, reports, profiles, audio, or video.
- Saves are namespaced by Firebase UID on the device. Successful account deletion clears that user's local songbook. Cross-account visibility on a shared device is not allowed.
- Refresh replaces a saved item or club atomically from the current visible server result. If refresh fails, the last complete snapshot remains available and the UI reports that it may be stale.
- A successful refresh removes chants that are no longer visible. An already-offline device cannot learn that remote moderation occurred, so the UI shows when the snapshot was last refreshed.
- Saving a club and saving one of its chants must not create duplicate rendered entries.

## Consequences

- The feature is an offline utility, not another public social collection. It requires no Firestore rules, Cloud Function, account-level counter, or seed mutation.
- Device-local state will not follow a user to a second phone in v1.
- The storage format needs a version so a later schema can migrate or safely discard old snapshots.
- Tests must cover individual save, club save, deduplication, UID isolation, atomic refresh failure, moderated-content removal on successful refresh, account-deletion cleanup, and airplane-mode relaunch from persisted data.

## Deferred

- Cross-device sync.
- Automatic background downloads or match reminders.
- Push notifications.
- Offline audio or video.
- Unlimited historical versions.

## Revisit triggers

- Users expect saved songbooks to follow them across devices.
- Snapshot size becomes material after expansion beyond the Premier League.
- Moderation policy requires an online revocation mechanism stronger than refresh-on-connect.
- Audio or video becomes part of the approved offline product and changes storage, licensing, or cost assumptions.
