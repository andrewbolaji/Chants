# Known Issues

## Device walkthrough, June 26

Sign-up and sign-in now work after Email/Password was enabled in Firebase
Auth. App Check is non-blocking in debug via the debug provider. Fonts and
core flows (browse, submit, feedback) verified rendering correctly on a
physical iPhone. Steps 6 and 7 of the walkthrough (empty/loading/error
states, moderation gating, rate limit) are pending the next walk.

---

### HIGH

#### Upvote does not increment
- **Status:** Addressed in Fanzine redesign block (June 27).
- **Fix:** Vote control now tracks an optimistic delta locally. Score
  updates on tap before the Firestore write completes. On error the delta
  reverts. On the next stream emission the server score reconciles. Toggle
  (vote then un-vote) and direction switch (up then down) are handled
  correctly. Unit tests cover all cases including rapid repeated taps.

#### Search is missing from the UI
- **Status:** Addressed in Fanzine redesign block (June 27).
- **Fix:** Search text field added to the home screen. Filters the
  discovery chant list by title, lyrics, tune name, and team name. Empty
  results show a fanzine-styled empty state ("Nothing matches that").

#### Account / password email link not tappable
- **Symptom:** The link in the Chants email (password reset / verification)
  is not clickable.
- **Where:** Transactional email template.
- **Suspected cause:** Email link / template formatting.
- **Priority:** High. Blocks the reset flow. This is a Firebase Console
  template issue, not an app code fix.

---

### MEDIUM

#### Password reset UX
- **Status:** Addressed in Fanzine redesign block (June 27).
- **Fix:** Confirm-password field added to sign-up. Show-password toggle
  added to sign-up, sign-in, and password reset screens.
- **Remaining:** The password-reset screen sends a reset link by email. The
  email template clickability issue (see above) is separate and still open.

---

### LOW / EXPECTED

#### Report confirmation
- **Symptom:** After submitting a report the app shows "we will take a look"
  and nothing else visibly changes.
- **Note:** This is expected. A report is logged and content only auto-hides
  once the flag threshold is reached. No action needed unless we want a
  clearer post-report state.
