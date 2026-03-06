# Auth Profile Provisioning – What We Did & App Verification Checklist

**Date:** 2026-03-06  
**Scope:** Fixes from Master Report + Auth Profile Provisioning implementation

---

## In short: what we did and why

### Added
- **Config & messages:** `AuthConfig` (retry attempts, delay) and `AuthMessages` (user-facing strings for profile failure, session invalid, banned/suspended). So retry and copy live in one place.
- **Profile retry:** `AuthRepository.getCurrentUserProfileWithRetry()` – after signup or when restoring a session, it retries fetching the profile a few times with a short delay so a slow DB trigger doesn’t break the session.
- **Orphan sweeper (DB):** View `vw_orphaned_auth_users` and function `sweep_orphaned_auth_users()`, plus a pg_cron job every 15 minutes to delete auth users that never got a profile (cleanup only).
- **Docs:** Subsection “Profile provisioning retry” in DEVELOPER_GUIDE (Auth Feature) and updates in SUPABASE_SETUP / Sline_Log for trigger, retry, and cron.

### Removed
- **Nothing.** No features or files were removed.

### Modified
- **AuthRepository:** Uses `.maybeSingle()` for profile fetch (no throw when missing); optional `SupabaseClient` in constructor for tests.
- **AuthSessionViewModel:** Loads profile via `getCurrentUserProfileWithRetry()`; if profile is null after retries → logout + “Profile provisioning failed”; on exception → logout + “Session invalid”; **and** on `logout()` we now call `clearError()` so the next login doesn’t show a stale error.
- **AuthFormViewModel:** After signup, calls `getCurrentUserProfileWithRetry()`; if null → sign out + “Profile provisioning failed”. **Logging:** we no longer put the raw exception in the log message (no `$e`); we use `AppLogger.e('Login failed', tag: 'Auth', error: e)` (and same for registration, password reset, password update) so logs stay safe and consistent.
- **LoginScreen:** On load, if `AuthSessionViewModel` has an `error`, it shows a SnackBar and then clears it.

**Why:** So the app handles slow profile creation and missing profiles without showing a broken session, cleans up orphan auth users, and logs auth failures without leaking exception text.

---

## App verification checklist

Use this on a real device or simulator with the app running against your Supabase project.

### 1. Login (happy path)
- [ ] Open app → Login screen.
- [ ] Enter valid email + password → tap Sign in.
- [ ] You land on the main app (e.g. dashboard/home), no crash.
- [ ] No “Profile provisioning failed” or “Session invalid” message.

### 2. Login (wrong credentials)
- [ ] On Login, enter wrong email or password → tap Sign in.
- [ ] You see a user-friendly error (e.g. “Email or password is incorrect”), not a raw exception.
- [ ] You stay on Login; you can try again or go to Sign up / Forgot password.

### 3. Sign up (happy path)
- [ ] Tap Sign up, fill email, password, full name → tap Register.
- [ ] You are signed in and land in the app (profile was created and fetched, possibly after retry).
- [ ] No “Profile provisioning failed” message.

### 4. Session restore (cold start)
- [ ] Sign in, then fully close the app (kill process).
- [ ] Reopen the app.
- [ ] You are still signed in and see the main app (profile loaded, possibly after retry).
- [ ] No unexpected logout or “Profile provisioning failed” on normal network.

### 5. Stale error cleared on logout
- [ ] If you ever see “Profile provisioning failed” or “Session invalid” (e.g. after forcing a bad state), tap Logout / Sign out.
- [ ] After signing in again, the old error message should **not** still appear (we clear error on logout).

### 6. LoginScreen shows session error once
- [ ] If the session had failed (e.g. profile missing) and you land on Login, a SnackBar may show the error once.
- [ ] After that, the error is cleared so it doesn’t stick on screen.

### 7. Password reset & update
- [ ] Forgot password: request reset → receive email → open link → set new password. No crash; you can sign in with the new password.
- [ ] If you enter a wrong or expired link, you see a friendly error, not a raw exception in the UI.

### 8. No raw exceptions in UI
- [ ] On any auth failure (login, signup, reset, update password), the user sees a short, readable message (from `AuthMessages` / `ErrorMapper`), not stack traces or server error text.

---

## Quick reference: files touched

| Area            | Files |
|-----------------|--------|
| Config          | `lib/core/config/auth_config.dart`, `lib/core/constants/auth_messages.dart` |
| Data            | `lib/features/auth/data/auth_repository.dart` |
| ViewModels      | `lib/features/auth/viewmodels/auth_session_view_model.dart`, `auth_form_view_model.dart` |
| View            | `lib/features/auth/view/login_screen.dart` |
| DB              | `supabase/migrations/20260306120000_*`, `20260306120100_*` |
| Docs            | `Sline_everything/DEVELOPER_GUIDE.md`, `SUPABASE_SETUP.md`, `Sline_Log.md` |

If every item in the checklist passes on the actual app, the implementation and report fixes are verified end-to-end.
