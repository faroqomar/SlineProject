# 04 Test Plan (Verification Checklist)

- [ ] **Tests (Integration - Registration Retry)**: Flutter test covering the "profile delayed by 1000ms" scenario to ensure the new retry loop resolves and logs the user in.
- [ ] **Tests (Integration - Registration Max Retries Failure)**: Disable the `profiles` trigger entirely. Run signup. Verify the app waits 3 retries, calls `signOut()`, and returns the user to the starting page with an error.
- [ ] **Tests (Unit - Guard Service on Login)**: `AuthFormViewModel.login` successfully blocks users when `AccountGuardService` returns `isRestricted = true`.
- [ ] **Tests (Integration - Session Restore Cold Start)**: Mock an active `auth.users` session, mark the matched `public.profiles` state as `banned`. Boot the app directly to Dashboard. Verify `AccountGuardService` intercepts the Session Restore and forces a logout.
- [ ] **RLS Checks**: Review `public.profiles` `SELECT` policies. The specific policy must evaluate `USING (id = auth.uid())` so the newly created auth user is mathematically guaranteed to query their own row immediately once the trigger commits.
- [ ] **Monitoring/Alerts**: Setup Postgres metric/alert for Orphaned Users (`count of auth.users missing in profiles`). Create a runbook for the automated 15-minute cleanup chron.
