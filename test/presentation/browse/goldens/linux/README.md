# Linux browse golden provenance

These five synthetic screenshots are byte-exact test images from Flutter 3.47.2 on Ubuntu. The unchanged chant-detail image came from GitHub Actions run [34198061885](https://github.com/andrewbolaji/Chants/actions/runs/34198061885), source head `5a95c93d0749796af65dc6c9a43707944dc66855`, artifact `10044757299`. The two named-player Call-Up images came from run [34268596203](https://github.com/andrewbolaji/Chants/actions/runs/34268596203), source head `966017f5b0e71ca425836c8bbe8625e6df43b8f9`, artifact `10072958024`. The two team images came from run [34269648962](https://github.com/andrewbolaji/Chants/actions/runs/34269648962), source head `3b30ac8bb4714eee6f1de635e67139c97242b968`, artifact `10073373473`.

All five rendered images and their isolated or masked differences were inspected on 2026-09-08. They match the approved Chants palette, Club Signal crest treatment, North London Forever fixture, vote clarity, named-player Call-Up hierarchy, enlarged text, and chant-detail controls. The two correction runs intentionally compared changed renders with stale or cross-platform references to obtain actual Linux output. The first exposed only the normal and enlarged Call-Ups; the second proved those replacements and exposed only the two larger team references. Neither revealed a behavior or layout regression.

| File | SHA-256 |
|---|---|
| chant_detail_share.png | ba423a6cd23d6a4c5f47622681e509e295448879d34bd0949451cfd336be8351 |
| club_call_up.png | 56960597f4061c3e0d3250b4b5f40355191079cc73c2a6a3a62239f1ac801786 |
| club_call_up_large_text.png | 9ed2b0d6e22e3d0ca65f809f0fc73730bc1f22f524153107f484e10c16a13238 |
| team_songbook.png | 52faa6c069bdd6eb7eec05bfc2e9248df60728844c740382d31b605bd5d84929 |
| team_chant_lab.png | 4098fb64f095740dbbde92c6240217e8be2feb8b1343f208246ae3b2ef3a2e39 |

The three test files choose this folder on Linux and retain the parent-folder references elsewhere. The chant-detail share reference is compared strictly on both platforms; no broad tolerance conceals visual drift. Semantic assertions check the invitation, player and club-specific copy, vote state, share action, and safety distinction independently of pixels. Normal and enlarged Call-Ups run independently so one failure cannot skip the other.

For an intentional visual change, run the three browse test files with `flutter test --update-goldens` on the relevant platform, inspect the rendered result, then run without updates. Do not replace the other platform's references without its rendered evidence. Failed CI PNGs are retained privately for seven days; a failed job remains failed. These synthetic images are not device, live catalogue or release evidence.
