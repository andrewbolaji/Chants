# Linux browse golden provenance

These five synthetic screenshots are byte-exact test images retained from pull request 38 clean-runner run [34666948003](https://github.com/andrewbolaji/Chants/actions/runs/34666948003). The run used source head `7c86ca9713a2beea208110d705fd86fbd6dce1b5`, merge ref `324139327cfaffc00ac8f9029611b050abdf4ec4`, Flutter 3.47.3, and Ubuntu 24.04.

The CI workflow pins Flutter 3.47.3 so these exact references do not drift when the stable channel advances.

All five current test images and their isolated or masked differences were inspected on 2026-09-11. They match the approved dark Club Signal palette, compact Terrace Proven badge, plain trust explanation, chant card and vote hierarchy, normal and enlarged Call-Ups, and chant-detail controls. The retained source is artifact `flutter-golden-failures-324139327cfaffc00ac8f9029611b050abdf4ec4`, artifact ID `10289527858`, with artifact digest `494c6c2b80648271cbf54b4e7c78c5fee260eed606122f3aa5fb9a8cbd91dc6b`. The failure was the expected stale Linux visual boundary after intentional cross-platform source changes, not a behavior or layout regression.

| File | SHA-256 |
|---|---|
| chant_detail_share.png | 581a470ec4350a15db8872b8190ff0bccd2c568961dc03faa8d9a05c4917aced |
| club_call_up.png | 360902dfa86a1d36667a97f8694486cb3be8d4494b0d2de92be71ad9b82a117b |
| club_call_up_large_text.png | 5466aafd52285dbf84dc035aa001f33c192b72d8d7b49c742e08ff721e143da6 |
| team_songbook.png | 9546b95a95955528cd0cdf666ee8d68345dd5d8b03af9fadb084228dd2aba171 |
| team_chant_lab.png | 917283de252bc0dab30d35f1e4dd39b09c93aebb7d01aee6cc5e4d6e125f84df |

The three test files choose this folder on Linux and retain the parent-folder references elsewhere. The chant-detail share reference is compared strictly on both platforms; no broad tolerance conceals visual drift. Semantic assertions check the invitation, player and club-specific copy, vote state, share action, and safety distinction independently of pixels. Normal and enlarged Call-Ups run independently so one failure cannot skip the other.

For an intentional visual change, run the three browse test files with `flutter test --update-goldens` on the relevant platform, inspect the rendered result, then run without updates. Do not replace the other platform's references without its rendered evidence. Failed CI PNGs are retained privately for seven days; a failed job remains failed. These synthetic images are not device, live catalogue or release evidence.
