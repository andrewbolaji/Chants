# Linux browse golden provenance

These four synthetic screenshots are byte-exact test images from GitHub Actions run [33362066687](https://github.com/andrewbolaji/Chants/actions/runs/33362066687), Flutter 3.47.2 on Ubuntu. Source head: `3ef81c9afb87290812dce0fefb39b0bd57a8c0f7`. Artifact ID: `9747065673`, named `flutter-golden-failures-6ff5639e1782ec0851b4b923ca80cb9db733d427`.

All four rendered images and their isolated or masked differences were inspected against the macOS Flutter 3.44.8 references on 2026-08-31. Differences follow glyph and curve edges; content, layout, trust labels and controls remain intact. Measured differences: normal Call-Up 2.25%, enlarged Call-Up 2.93%, team Songbook 2.83%, team Chant Lab 2.74%.

| File | SHA-256 |
|---|---|
| club_call_up.png | e8af48d6b636e5b0f38b5aeba5afa897e4eb9da037217d23adad0e235325fd1e |
| club_call_up_large_text.png | 3c287a5ae60414a5ea11661d358a2adeb12f5506ff395be79c90902355bac64b |
| team_songbook.png | dd67a1f8d625ad1e2f550bfe99f5e053ada08756ac5458bdb189f4fc64368fa5 |
| team_chant_lab.png | e49a603edbdaf4a6e4964294083f8d12594fb2be380b6d17bcc661045cf62759 |

The two test files choose this folder on Linux and retain the parent-folder references elsewhere. Existing 1.5% Call-Up and 2.2% main-club tolerances are unchanged. Semantic assertions check the invitation, player and club-specific copy independently of pixels. Normal and enlarged Call-Ups run independently so one failure cannot skip the other.

For an intentional visual change, run the two browse test files with `flutter test --update-goldens` on the relevant platform, inspect the rendered result, then run without updates. Do not replace the other platform's references without its rendered evidence. Failed CI PNGs are retained privately for seven days; a failed job remains failed. These synthetic images are not device, live catalogue or release evidence.
