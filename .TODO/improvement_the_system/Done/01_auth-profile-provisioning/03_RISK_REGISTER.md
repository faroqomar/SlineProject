# 03 Risk Register

## J1) Risks if we keep the current system

1. **Race Condition on Profile Fetch**: The client app assumes immediate profile availability. In a high-load production environment, the DB trigger may lag, causing `fetchProfile` to fail and the app to crash or hang for a new user.
   - _Severity_: High
   - _Likelihood_: Medium
   - _Impact_: UX failure on registration.
2. **Silent Trigger Failure (Orphaned User Unrecoverable State)**: If the automatic `public.profiles` trigger fails (due to a check constraint or missing metadata), the `auth.users` record is successfully committed but the `profiles` record is not. The user is permanently broken. They cannot login (no profile) and cannot re-register (email taken).
   - _Severity_: High
   - _Likelihood_: Low
   - _Impact_: Permanent account lockout requiring manual DB intervention.
3. **Session Restore Bypass (Cold Start Gap)**: Banned or suspended users whose session tokens haven't naturally expired yet can bypass the login screen `AccountGuardService` check if the app cold-start flow restores their session directly without re-verifying their account status.
   - _Severity_: Critical
   - _Likelihood_: High
   - _Impact_: Adversarial users continue accessing the platform post-ban.

## J2) Risks introduced by improvements

1. **Polling Complexity**: Implementing a retry loop in Flutter adds state complexity to the auth flow and could lead to UI hanging if unbounded.
   - _Migration/Mitigation_: Implement a strict Max 3-loop bound with a clean fallback failure UI and a `signOut()` action to reset the state.
2. **Orphan Purge Cron Job Dependency**: To fix Risk J1-2 (Orphaned Users), the database needs a scheduled cleanup job `pg_cron` to delete `auth.users` older than 15 minutes that have no profile.
   - _Migration/Mitigation_: Low risk, requires a simple SQL script during migration: `DELETE FROM auth.users WHERE id NOT IN (SELECT id FROM public.profiles) AND created_at < NOW() - INTERVAL '15 minutes';`.
