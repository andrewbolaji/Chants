# Linux creation golden provenance

These two references are the exact Linux test images retained from pull request 38 clean-runner run [34666948003](https://github.com/andrewbolaji/Chants/actions/runs/34666948003). The run used source head `7c86ca9713a2beea208110d705fd86fbd6dce1b5`, merge ref `324139327cfaffc00ac8f9029611b050abdf4ec4`, Flutter 3.47.3, and Ubuntu 24.04.

The CI workflow pins Flutter 3.47.3 so these exact references do not drift when the stable channel advances.

The current test images and their isolated or masked differences were inspected on 2026-09-11. Layout, copy, color, component state, and geometry match the inspected macOS and physical-iPhone references: the compact Terrace Proven badge, plain trust explanation, content-sized posting identity, and upload-state panel are intact. The retained source is artifact `flutter-golden-failures-324139327cfaffc00ac8f9029611b050abdf4ec4`, artifact ID `10289527858`, with artifact digest `494c6c2b80648271cbf54b4e7c78c5fee260eed606122f3aa5fb9a8cbd91dc6b`.

| File | SHA-256 |
|---|---|
| perform_chant_entry.png | d56592264a3919b86e213341304c53576bfb8c61ae8f0fccddb7f8af0e6f562f |
| perform_chant_upload.png | 36d8527e834e6fd888634b1073988c4408816266dec6e628a324d540e1947d92 |

The tests select this directory only on Linux. Other platforms continue to use the parent references, and the shared 1.5 percent comparator ceiling remains unchanged. For an intentional visual change, regenerate and inspect each affected platform reference independently.
