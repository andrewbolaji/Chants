# Linux submission golden provenance

These three references are the exact Linux test images retained from pull request 38 clean-runner run [34595868541](https://github.com/andrewbolaji/Chants/actions/runs/34595868541). The run used source head `f2e405f92f5ac0592e5c5c959f3b1a9d68e4aea7`, merge ref `3e08a9bf196dfdaf3bfddea35806ccdaebb28585`, Flutter 3.47.3, and Ubuntu 24.04.

The CI workflow pins Flutter 3.47.3 so these exact references do not drift when the stable channel advances.

The master images, test images, isolated differences, and masked differences were inspected on 2026-09-11. The differences trace glyph, icon, and border-edge antialiasing. Layout, copy, color, component state, and geometry match the inspected macOS references. The retained source was artifact `flutter-golden-failures-3e08a9bf196dfdaf3bfddea35806ccdaebb28585`, artifact ID `10261508050`, with artifact digest `dd50def5348b947ff4fb529e34f6c8b5fdae4523309ad0b4a59fc8571d868811`.

| File | SHA-256 |
|---|---|
| submit_chant_evidence.png | dcf425331502ee7e2cca914e0295e7e353000829082d54853c357fc4c5c2fee8 |
| submit_chant_origin.png | 540a1c568342169b9745afc1f4b4eb05257c0ad2fc0b55976785c07a8fb57b08 |
| submit_chant_stale_player.png | 6724464e302ac418b8a367189bb89f6910aa51115734ad0504f067e56c962484 |

The tests select this directory only on Linux. Other platforms continue to use the parent references, and the shared 1.5 percent comparator ceiling remains unchanged. For an intentional visual change, regenerate and inspect each affected platform reference independently.
