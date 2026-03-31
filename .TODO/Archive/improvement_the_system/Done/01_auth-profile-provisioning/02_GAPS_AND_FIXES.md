# 02 Gaps and Fixes

## Gaps

1. **Race Condition on Signup**: The client app assumes the profile exists immediately after `signUp()` returns. Supabase triggers are synchronous `AFTER INSERT`, but network latency or transaction commits might cause the immediate client `select()` to fail or hit a stale read replica.
2. **Orphaned Auth Users**: If the trigger fails (e.g., due to a constraint violation like full name being null if passed via raw_user_meta_data improperly), the user is created in `auth.users` but has no profile.
3. **Missing Guardrails**: Current diagram lacks the `AccountGuardService` checks that were discovered in `AuthFormViewModel.login`.

## Fixes

1. **Profile Polling/Retry**: App must implement a retry mechanism when fetching the profile post-signup.
2. **Robust Trigger**: Ensure the Supabase trigger sets default values and swallows non-critical errors so it doesn't fail the auth transaction, or explicitly fails the auth transaction if profile creation is strictly required. (Standard Supabase approach is to make it an atomic transaction where trigger failure aborts signup).
3. **Include Guard Service in Flow**: The new sequence diagram must show the App calling `evaluateCurrentUser` to check for bans/suspensions before navigating.
