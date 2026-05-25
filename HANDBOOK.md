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
