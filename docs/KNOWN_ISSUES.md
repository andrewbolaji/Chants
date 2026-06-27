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
- **Symptom:** Tapping the up arrow on a chant detail leaves the count at 0;
  no visible change.
- **Where:** Chant detail vote bar and list vote chips.
- **Suspected cause:** Either the optimistic UI update is not wired (counters
  are written by the vote Cloud Function and the screen only reflects after
  the function runs plus a stream refresh), or the vote write is failing
  silently. Needs investigation during the redesign vote-bar rebuild: confirm
  a vote doc is actually written to the votes collection on tap, confirm the
  counter function runs, and add optimistic UI so the number moves
  immediately.
- **Priority:** High — core interaction.

#### Search is missing from the UI
- **Symptom:** No search entry point on the Chants home or club screens; only
  the discovery shuffle is present.
- **Where:** Home / discover screen.
- **Note:** Spec lists browse-and-search for v1; the shuffle works but search
  is not surfaced.
- **Priority:** High.

#### Account / password email link not tappable
- **Symptom:** The link in the Chants email (password reset / verification)
  is not clickable.
- **Where:** Transactional email template.
- **Suspected cause:** Email link / template formatting.
- **Priority:** High — blocks the reset flow.

---

### MEDIUM

#### Password reset UX
- **Requests:** Require the new password to be entered twice (confirm field)
  and add a show-password toggle on the entry fields.
- **Where:** Password reset screen (and consider the same show-password
  toggle on sign-up / sign-in).
- **Priority:** Medium.

---

### LOW / EXPECTED

#### Report confirmation
- **Symptom:** After submitting a report the app shows "we will take a look"
  and nothing else visibly changes.
- **Note:** This is expected. A report is logged and content only auto-hides
  once the flag threshold is reached. No action needed unless we want a
  clearer post-report state.
