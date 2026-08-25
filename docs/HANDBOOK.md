# Chants Handbook

A plain-language manual for Chants. Read this to understand exactly how every feature works and to explain it to anyone. Mostly plain English, light technical detail where it helps. Updated one feature at a time as Blocks close.

## What Chants is

Chants is the home for football chants. Fans use it to find the songs, learn the words, add chants that are missing (the classics and brand-new ones), and vote the good ones up. It launches with the Premier League and a starter set of iconic chants for every club, and it grows as fans add their own. The one-sentence value: know the words, and add the next one.

---

## Auth (Block 1)

**What it does.** Lets you create an account, sign in, and reset your password. Your account is how the app knows who submitted a chant, who voted, and who reported something. Every account starts with the "user" role. The "operator" role exists for moderation and is assigned behind the scenes, not through the app.

**How to use it.**
1. Open the app. You land on the Sign In screen.
2. To create an account, tap "No account yet? Sign up." Enter a display name, email, password (at least 6 characters), and confirm the password. Tap "Create Account."
3. To sign in, enter your email and password, then tap "Sign In."
4. To reset your password, tap "Forgot password?" on the Sign In screen. Enter your email and tap "Send Reset Link." Check your inbox (and spam folder) for the link.
5. To sign out, use the overflow menu on the home screen.
6. All password fields have a show/hide toggle (eye icon) so you can check what you typed.

**Behind the scenes.** Auth uses Firebase Authentication (email and password). When you sign up, the app creates a profile in Firestore with your display name, a "user" role, and timestamps. Your email is never exposed to other users; only your display name is public. The password reset flow always shows the same message ("If that email is registered, you will get a reset link") whether the email exists or not, so it never leaks account information. The confirm-password field is validated client-side before the sign-up request is sent.

**Limits and gotchas.**
- Email and password only for now. Apple and Google sign-in are noted for later.
- You cannot change your own role. Only the system can set a user to "operator."
- If you enter a wrong email or password, the error message says "Wrong email or password. Check both and try again." It does not say which one was wrong, for security.
- Passwords must be at least 6 characters (Firebase minimum).
- The confirm-password field catches typos before sign-up; mismatched passwords show "Passwords do not match."

**Where it shows up.** Sign In, Sign Up, and Password Reset are standalone screens. The home screen shows a sign-out button. Auth state drives the entire app: signed out shows the sign-in screen, signed in shows the home screen.

> [screenshot: Sign In screen]
> [screenshot: Sign Up screen]
> [screenshot: Password Reset confirmation]

---

## Account deletion

**What it does.** Permanently removes your account and private activity. Chants and comments you added remain as community content under `Deleted user`, so active song and conversation pages do not break.

**How to use it.**
1. Open the home-screen menu and choose Delete account.
2. Read the confirmation. It explains that private activity and the device's Saved Matchday Songbook are removed, while submitted chants and comments stay anonymized.
3. Confirm deletion. Once Chants safely queues the request, the app removes the local Songbook and signs you out.
4. Remote cleanup may continue briefly after sign-out. You can close the app and do not need to keep it online.

**Behind the scenes.** The request first creates a private durable deletion job and marks the profile as pending. A retry-enabled server worker disables new sign-ins, removes votes, reports, feedback, likes, blocks, and private rate state in bounded pages, anonymizes retained contributions, writes one audit event, deletes Firebase Auth, then atomically removes the profile and job. Repeated requests and duplicate server events resume safely rather than starting over.

If the request fails before it is safely queued, the account and exact local Songbook stay available. If a pending session is reopened before sign-out completes, the app shows only the deletion-in-progress screen and Sign out.

**Limits and gotchas.**
- There is no undo or account restoration in v1.
- Submitted chants and comments are retained without your identity. The confirmation states this before deletion starts.
- The app does not show internal phases or an estimated completion time.
- A permanently failing server job requires operator investigation. There is no in-app recovery console in v1.

**Where it shows up.** Delete account confirmation from Home, the signed-out Sign In screen after acceptance, and the deletion-in-progress fallback screen for a retained pending session.

> [screenshot: Account deletion confirmation]
> [screenshot: Deletion in progress]

---

## Browse and Navigation (Block 2)

**What it does.** Lets you explore chants by drilling down from the Premier League to a club, then to a player, then to a specific chant. A discovery shuffle on the home screen mixes chants across all clubs so you can stumble on something new.

**How to use it.**
1. Open the app. The home screen shows a search bar, a "Premier League" entry, and a shuffled mix of chants from all clubs.
2. Type in the search bar to filter chants by title, lyrics, tune name, or club name. Results update as you type. If nothing matches, a fanzine-style empty state tells you.
3. Tap "Premier League" to see all 20 clubs listed alphabetically.
4. Tap a club to see its chants. Club anthems appear first, then players who have chants, then the full squad (tap to expand).
5. Tap a player to see their chants. Most players have none yet, and that is normal.
6. Tap any chant to see the full detail: lyrics, tune name, context, and badges (verified/community, parody flag).
7. On the home screen, tap the shuffle icon to get a fresh mix.

**Behind the scenes.** All chants live in one flat Firestore collection with denormalized team and player IDs. Every query filters out hidden and removed chants at the database level (Firestore security rules reject queries without those filters). The discovery shuffle fetches all visible chants and shuffles client-side. The seed script writes canonical chants via the Admin SDK, bypassing the client create rule that forces community status.

**Limits and gotchas.**
- Most players have no chants yet. The empty state says "No chants for [player] yet." This is expected, not an error.
- Hosted media does not ship in v1. The approved v1 direction is an optional allowlisted external evidence link, opened outside Chants; Storage remains locked.
- Voting is live. The score updates immediately when you tap (optimistic update). If the network write fails, it reverts. Tapping the same vote again removes it. Switching from up to down (or vice versa) swings the score by 2.

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

**Behind the scenes.** The app sends only the target and reason to an authenticated Cloud Function. The server validates your current profile and the visible target, derives your user ID and timestamp, checks a private atomic budget, and creates a pending report. Direct app or raw-SDK report creates are denied. Reports remain insert-only for clients, and only operators can read them.

**Limits and gotchas.**
- You must be signed in to report.
- You cannot see or retract your own reports.
- Chant, comment, and user reports share one anchored hourly budget: 5 accepted reports for accounts under 24 hours and 20 for older accounts.
- Repeating the same target shows "You already reported this." and does not replace the first report or consume more budget.
- Reaching the current budget shows "You have sent several reports recently. Try again later." The selected reason and note stay in the form.
- No confirmation that a specific action was taken. The operator reviews and acts behind the scenes.

**Where it shows up.** The flag icon on the chant detail screen app bar.

> [screenshot: Report bottom sheet]

---

## Seed and Data Pipeline (Block 2)

**What it does.** An Admin SDK script that populates Firestore with the sport, competition, clubs, squads, and canonical chants from structured JSON files. Idempotent: re-running updates content without duplicating or clobbering vote tallies or moderation state.

**How to use it.**
1. Place a service account key at seed/serviceAccountKey.json (never committed).
2. Fill seed_data/clubs/[club].json files with team, squad, and chants. Give every chant a permanent lowercase `id` beginning with the club slug, such as `arsenal-one-nil-to-the-arsenal`.
3. Before the next live write, run the separately authorized read-only check: `cd seed && npx ts-node seed.ts --preflight-only arsenal.json`. It reads identity metadata and calls no seed writer.
4. Run `npx ts-node seed.ts` (all clubs) or `npx ts-node seed.ts arsenal.json` (one club) only after the preflight is reviewed and the write is authorized.
5. The script validates every club file before that club's first write. If validation fails, it stops and reports errors.
6. After writing, it prints an orphan report: any docs in Firestore for that club not present in the seed file.

**Behind the scenes.** Team and player docs get deterministic slug IDs. Seeded chant IDs are explicit immutable source data, so correcting a title still updates the same document. Before the first club write, the script rejects unsafe ID ownership, cross-team collisions, and a duplicate system chant at another ID. Each chant write repeats the ownership check inside a transaction. On re-run, only content fields are updated (title, lyrics, tuneName, etc.); counters, flags, createdBy, and createdAt are never touched. This protects live engagement and moderation state across content corrections and squad refreshes.

**Limits and gotchas.**
- The service account key is a secret. Never commit it.
- Orphan docs are reported but not auto-deleted. Review them manually and never assume they are safe to remove.
- Duplicate explicit IDs and duplicate normalized titles are caught by validation. An unexpected live collision stops the club before its first write and requires a separate migration plan.

> [screenshot: seed terminal output]

---

## Suggestion Box (Block 5)

**What it does.** Lets you send feedback, report a bug, ask a question, or make a suggestion directly from the app.

**How to use it.**
1. Tap the three-dot menu in the top right of the home screen.
2. Tap "Send feedback."
3. Pick a category: Suggestion, Bug report, Question, or Other.
4. Write your message (up to 1000 characters).
5. Optionally check "OK to follow up by email" if you want a response.
6. Tap "Send." You will see "Got it. We read every one."

**Behind the scenes.** The app sends the category, trimmed message, and follow-up preference to an authenticated Cloud Function. The server derives your user ID and timestamp, checks a private atomic budget, and creates an unresolved feedback row. Direct client creates are denied. You can read your own feedback; the operator can read all feedback. Clients cannot edit or delete an entry.

**Limits and gotchas.**
- Messages are capped at 1000 characters, enforced in the app and callable.
- Feedback is limited to 3 accepted entries per anchored 24 hours. Reaching the limit keeps the complete form and shows "You have sent several messages recently. Try again later."
- The operator cannot mark feedback as resolved in v1. That comes with the moderation console in v1.1.
- Banned accounts cannot submit through this channel. A dedicated appeal path is not part of v1.
- No email notification in v1. The operator reads feedback in the moderation screen.

**Where it shows up.** The three-dot overflow menu on the home screen. The operator sees a "Feedback" tab in the moderation screen.

> [screenshot: Feedback form]
> [screenshot: Feedback confirmation]

---

## Chant Variations (Variations Block, v1: seed only, display only)

**What it does.** Shows alternate lyrics for a chant when they exist. Some chants have lines that changed over the years (a player left, a new signing arrived, fans started singing it differently). This feature shows those alternate versions on the chant detail screen under a section called "Also sung as."

**How it works for fans.**
1. Open a chant that has a variation (for example, "Super Mik Arteta").
2. Below the main lyrics and context, you will see the heading "ALSO SUNG AS."
3. Each variation shows a small label (like "Current version"), the alternate lyric in the same reading face as the main lyrics, and optionally a short note explaining when or why the lyric changed.
4. If a chant has no variations, nothing extra appears. The screen looks exactly as before.

**How it works for seeding.**
1. In the seed JSON file, add a `variations` array to any chant entry. Each item has `label` (required), `lyric` (required), and `contextNote` (optional).
2. Run the seed script. The `variations` field is in the content-fields allow-list, so it writes on both create and update without touching vote data.
3. Chants without a `variations` key are unaffected. The model defaults to an empty list.

**Behind the scenes.** Variations are stored as an optional array on the chant document in Firestore. The Dart model's `fromJson` defaults the field to an empty list when the key is absent, null, or an empty array, so every existing doc works without a migration. The detail screen conditionally renders the "Also sung as" section only when the list is non-empty.

**Limits and gotchas.**
- Seed only in v1. Users cannot submit or vote on variations yet. That is the v1.1 community-submitted variations feature.
- There is no per-variation voting. The vote chip on the chant detail is for the chant as a whole.
- The variation does not highlight which line of the main lyrics it replaces. The data does not track that, so the section stands on its own.

**Where it shows up.** The chant detail screen, below the main lyrics and context notes, above the media placeholder.

> [screenshot: Chant detail with "Also sung as" section]

---

## Comments

**What it does.** Lets people comment on a chant, like comments they enjoy, and flag ones that break the rules. Every chant has its own comment thread on the detail screen.

**How to use it.**
1. Sign in (commenting, liking, and reporting all require an account).
2. Open any chant's detail screen and scroll down to the comments section.
3. Type in the composer at the bottom (up to 500 characters) and tap the send icon to post.
4. Tap the heart on any comment to like it. Tap again to remove your like.
5. To delete your own comment, tap the trash icon on the right side of the card. A confirmation dialog appears first.
6. To report someone else's comment, tap the flag icon on the right side of their card. Pick a reason and optionally add a note, same flow as reporting a chant.

**Behind the scenes.** Comments remain flat Firestore documents. A top-level comment has no parent; one direct reply stores the top-level `parentCommentId`. Replies to replies are rejected. Each comment stores the author's display name, body text, a like count, a flag count, and hidden/removed flags.

Sorting is by most likes first, then newest first among comments with the same like count.

One like per person per comment, enforced by a deterministic document ID (`userId_commentId`). Liking is optimistic: the heart fills and the count updates instantly, then the write goes to the server. If the write fails, it reverts. A Cloud Function (`onCommentLikeWritten`) recomputes the like count from the actual stored like documents every time a like is created or removed, so the count stays correct even after reinstalling the app.

The comment count shown on the chant is also recomputed from ground truth. A Cloud Function (`onCommentWritten`) fires on every comment write (create, update, or delete) and counts the visible comments (not hidden, not removed) for that chant. This means the count self-corrects no matter what caused the change.

Deleting your own comment is a soft delete: it sets `removed: true` on the document. The query that loads comments excludes hidden and removed comments, so the comment disappears for everyone, but the document is not hard-removed from the database.

Reporting a comment uses the same server-authoritative report callable and shared hourly budget as chant and user reports. The accepted pending row lands in `commentReports`. A Cloud Function (`onCommentReportCreated`) recomputes the pending flag count from stored reports. If the count reaches 3, the comment is auto-hidden and an audit log entry is written. Operators can then review, unhide, or permanently remove the comment.

Rate limits apply per user per hour. New accounts (less than 24 hours old, or 3 or fewer total submissions) can post up to 5 comments per hour. Established accounts can post up to 20 per hour. If a user exceeds the limit, the extra comment is auto-hidden (never auto-removed) and an audit entry is logged. The rate limit runs only on comment creates, not on updates or deletes.

Banned users see "You cannot comment right now" in place of the composer.

**Limits and gotchas.**
- No replies to replies. V1 supports one direct reply level.
- No comment downvotes. The only reaction is a like (heart).
- No lyric-suggestion mechanic yet. All three are parked for v1.1.
- You cannot report your own comment. The card shows a delete icon for your own comments and a flag icon for everyone else's.
- A deleted comment cannot be undeleted by the user. The soft-delete confirmation dialog warns "This cannot be undone."
- The report button is not shown to signed-out users. Neither is the like button or the composer.
- Comment body max length is 500 characters, enforced in the text field.

**Where it shows up.** The chant detail screen (comment section and composer), the comment count on the chant document, the `commentReports` collection and audit log for moderation, and the report flow shared with chant reporting.

> [screenshot: comment section on a chant detail screen, showing a posted comment, the like heart, and the composer]
