# Decision 030: Ship Apple V1 on iPhone only

**Status:** Accepted

**Date:** 2026-09-07

## Context

The PR 35 store packet contains five exact iPhone screenshot scenes but no iPad capture, layout, or device evidence. The native Xcode project still declared device family `1,2`, which tells App Store Connect that the app runs on both iPhone and iPad. Apple requires an iPad screenshot set when an app runs on iPad. Treating the missing set as a documentation detail would leave the advertised device support wider than the tested release.

## Decision

V1 targets iPhone only.

- Every iOS build configuration uses device family `1`.
- The V1 Info.plist has no iPad-specific orientation declaration.
- The Apple submission packet and screenshot manifest describe only the 1320 by 2868 iPhone set.
- iPad support is pinned for V1.1 as one complete product block: adaptive layout, navigation, media, sharing anchors, forms, loading, empty, permission, offline, and recovery states; physical and simulator testing; App Store screenshots; and renewed store review evidence.
- The native and store validators fail if iPad support returns without the corresponding approved evidence boundary.

## Reasons

The iPhone journey has current design and device evidence. iPad does not. A narrower truthful V1 avoids submitting an interface and screenshot obligation that has not been inspected. It also keeps iPad from becoming an unplanned store-blocking repair late in the release sequence.

## Consequences

- V1 cannot be installed as a native iPad app.
- App Store Connect receives only the approved iPhone device declaration and five-scene iPhone screenshot set.
- A future iPad change must update native targeting, orientation and adaptive behavior, the store packet, release tests, screenshots, and privacy or product claims if the larger layout enables anything new.
- Android phone support and its five screenshot scenes are unchanged.

## Revisit triggers

Revisit after V1 when the iPhone release is stable and the V1.1 iPad block has an approved specification, representative mockups where layout uncertainty remains, adaptive widget proof, device walkthrough evidence, and a complete App Store screenshot plan. Do not re-enable device family `2` as an isolated project-setting change.
