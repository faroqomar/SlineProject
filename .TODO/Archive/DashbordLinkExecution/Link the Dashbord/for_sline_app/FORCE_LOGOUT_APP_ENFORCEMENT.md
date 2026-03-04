# Force Logout — App (Flutter) Enforcement

**PAGE 06** adds admin force-logout: the dashboard calls `POST /api/v1/users/:userId/force-logout`, which sets `profiles.force_logout_after = now()` and writes an audit row. **The marketplace app (Flutter) must enforce** this so the user is actually signed out.

## Required behavior in the app

1. **Read revocation state**  
   When the app uses the current session (e.g. on startup, or before sensitive operations), read the user’s `profiles.force_logout_after` (e.g. via a “me” or profile endpoint that returns this field, or via a direct Supabase read if the app has it).

2. **Compare with session**  
   If `force_logout_after` is set and is **after** the token’s `iat` (issued-at) or the session start time, treat the session as revoked.

3. **Force re-auth**  
   Clear the local session (Supabase `signOut()`), clear any cached tokens, and redirect the user to the login screen. Do not allow further authenticated requests until they sign in again.

## Optional: periodic check

- On app resume or on a timer, call an endpoint that returns the user’s `force_logout_after` (or include it in an existing “me”/profile response) and apply the same logic.

## Migration

- Ensure the app repo has the same schema: `profiles.force_logout_after timestamptz`.  
- Copy `20260302140000_force_logout.sql` from this folder into **sline_app** and apply with your migration flow.

## Rollback

- Migration is additive. Rollback = revert the migration (drop the RPC, optionally drop the column if no other use).  
- Apps that do not yet check `force_logout_after` continue to work until they are updated to enforce it.
