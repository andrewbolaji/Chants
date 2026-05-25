# Chants Handbook

A plain-language manual for Chants. Read this to understand exactly how every feature works and to explain it to anyone. Mostly plain English, light technical detail where it helps. Updated one feature at a time as Blocks close.

## What Chants is

Chants is the home for football chants. Fans use it to find the songs, learn the words, add chants that are missing (the classics and brand-new ones), and vote the good ones up. It launches with the Premier League and a starter set of iconic chants for every club, and it grows as fans add their own. The one-sentence value: know the words, and add the next one.

---

## Auth (Block 1)

**What it does.** Lets you create an account, sign in, and reset your password. Your account is how the app knows who submitted a chant, who voted, and who reported something. Every account starts with the "user" role. The "operator" role exists for moderation and is assigned behind the scenes, not through the app.

**How to use it.**
1. Open the app. You land on the Sign In screen.
2. To create an account, tap "No account yet? Sign up." Enter a display name, email, and password (at least 6 characters). Tap "Create Account."
3. To sign in, enter your email and password, then tap "Sign In."
4. To reset your password, tap "Forgot password?" on the Sign In screen. Enter your email and tap "Send Reset Link." Check your inbox (and spam folder) for the link.
5. To sign out, tap the sign-out icon in the top bar of the home screen.

**Behind the scenes.** Auth uses Firebase Authentication (email and password). When you sign up, the app creates a profile in Firestore with your display name, a "user" role, and timestamps. Your email is never exposed to other users; only your display name is public. The password reset flow always shows the same message ("If that email is registered, you will get a reset link") whether the email exists or not, so it never leaks account information.

**Limits and gotchas.**
- Email and password only for now. Apple and Google sign-in are noted for later.
- You cannot change your own role. Only the system can set a user to "operator."
- If you enter a wrong email or password, the error message says "Wrong email or password. Check both and try again." It does not say which one was wrong, for security.
- Passwords must be at least 6 characters (Firebase minimum).

**Where it shows up.** Sign In, Sign Up, and Password Reset are standalone screens. The home screen shows a sign-out button. Auth state drives the entire app: signed out shows the sign-in screen, signed in shows the home screen.

> [screenshot: Sign In screen]
> [screenshot: Sign Up screen]
> [screenshot: Password Reset confirmation]

---

## Browse and Navigation (Block 2)

**What it does.** Lets you explore chants by drilling down from the Premier League to a club, then to a player, then to a specific chant. A discovery shuffle on the home screen mixes chants across all clubs so you can stumble on something new.

**How to use it.**
1. Open the app. The home screen shows a "Premier League" card and a shuffled mix of chants from all clubs.
2. Tap "Premier League" to see all 20 clubs listed alphabetically.
3. Tap a club to see its chants. Club anthems appear first, then players who have chants, then the full squad (tap to expand).
4. Tap a player to see their chants. Most players have none yet, and that is normal.
5. Tap any chant to see the full detail: lyrics, tune name, context, and badges (Canonical/Community, subject tag, real/parody).
6. On the home screen, tap the shuffle icon to get a fresh mix.

**Behind the scenes.** All chants live in one flat Firestore collection with denormalized team and player IDs. Every query filters out hidden and removed chants at the database level (Firestore security rules reject queries without those filters). The discovery shuffle fetches all visible chants and shuffles client-side. The seed script writes canonical chants via the Admin SDK, bypassing the client create rule that forces community status.

**Limits and gotchas.**
- Most players have no chants yet. The empty state says "No chants for [player] yet." This is expected, not an error.
- "Most popular" sorting exists but is inert until voting ships in Block 4 (all scores are 0).
- Cover images and media are placeholders until Storage goes live in Block 3.
- Search is structured filter and sort, not free-text lyric search (deferred to v2).

**Where it shows up.** Home screen (discovery shuffle and PL entry), Competition screen, Club screen, Player screen, Chant detail screen.

> [screenshot: Home screen with discovery shuffle]
> [screenshot: Club screen showing club chants and players-with-chants]
> [screenshot: Chant detail screen]

---

## Reporting (Block 2)

**What it does.** Lets you flag a chant that breaks the content policy. Every chant, including canonical ones, has a report button.

**How to use it.**
1. Open any chant's detail page.
2. Tap the flag icon in the top bar.
3. If you are not signed in, you will be prompted to sign in first.
4. Pick a reason: "Hate speech or slurs," "Tragedy chanting," "Threats or targeting," or "Something else."
5. Optionally add a short note (up to 200 characters).
6. Tap "Report this chant." You will see "Got it. We will take a look."

**Behind the scenes.** A report document is created in the reports collection with status "pending," your user ID as reportedBy, and a timestamp. Reports are insert-only (you cannot edit or delete a report). Only operators can read reports. The Block 1 security rule enforces that status must be "pending" on create and reportedBy must match your auth UID.

**Limits and gotchas.**
- You must be signed in to report.
- You cannot see or retract your own reports.
- No confirmation that a specific action was taken. The operator reviews and acts behind the scenes.

**Where it shows up.** The flag icon on the chant detail screen app bar.

> [screenshot: Report bottom sheet]

---

## Seed and Data Pipeline (Block 2)

**What it does.** An Admin SDK script that populates Firestore with the sport, competition, clubs, squads, and canonical chants from structured JSON files. Idempotent: re-running updates content without duplicating or clobbering vote tallies or moderation state.

**How to use it.**
1. Place a service account key at seed/serviceAccountKey.json (never committed).
2. Fill seed_data/clubs/[club].json files with team, squad, and chants.
3. Run `cd seed && npx ts-node seed.ts` (all clubs) or `npx ts-node seed.ts arsenal.json` (one club).
4. The script validates every file before writing. If validation fails, it stops and reports errors.
5. After writing, it prints an orphan report: any docs in Firestore for that club not present in the seed file.

**Behind the scenes.** Each doc gets a deterministic slug ID (team name, player name, chant title). On first run, docs are created fully. On re-run, only content fields are updated (title, lyrics, tuneName, etc.); counters, flags, createdBy, and createdAt are never touched. This protects live vote tallies and moderation state across transfer-window squad refreshes.

**Limits and gotchas.**
- The service account key is a secret. Never commit it.
- Orphan docs (renamed chants or removed players) are reported but not auto-deleted. You review and delete manually.
- Slug collisions (two different titles that slugify identically) are caught by validation before any writes.

> [screenshot: seed terminal output]
