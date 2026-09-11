# Linux creation golden provenance

These two references are the exact Linux test images retained from pull request 38 clean-runner run [34595868541](https://github.com/andrewbolaji/Chants/actions/runs/34595868541). The run used source head `f2e405f92f5ac0592e5c5c959f3b1a9d68e4aea7`, merge ref `3e08a9bf196dfdaf3bfddea35806ccdaebb28585`, Flutter 3.47.3, and Ubuntu 24.04.

The CI workflow pins Flutter 3.47.3 so these exact references do not drift when the stable channel advances.

The master images, test images, isolated differences, and masked differences were inspected on 2026-09-11. The differences trace glyph, icon, and border-edge antialiasing. Layout, copy, color, component state, and geometry match the inspected macOS references. The retained source was artifact `flutter-golden-failures-3e08a9bf196dfdaf3bfddea35806ccdaebb28585`, artifact ID `10261508050`, with artifact digest `dd50def5348b947ff4fb529e34f6c8b5fdae4523309ad0b4a59fc8571d868811`.

| File | SHA-256 |
|---|---|
| perform_chant_entry.png | c4f37fd81323de871a297b43132fde6d4f692c630690fe1fba1c5b3eee5c4a24 |
| perform_chant_upload.png | d6c11fb07aa09ceeae3e2a002aa911b2b826e61bc63bbe6cbccf7909948527b4 |

The tests select this directory only on Linux. Other platforms continue to use the parent references, and the shared 1.5 percent comparator ceiling remains unchanged. For an intentional visual change, regenerate and inspect each affected platform reference independently.
