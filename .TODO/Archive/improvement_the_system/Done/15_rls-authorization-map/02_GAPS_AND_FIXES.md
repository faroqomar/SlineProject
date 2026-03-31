# 02_GAPS_AND_FIXES

## 1. Governance Gaps

### G1: `SECURITY DEFINER` View Leakage

- **Observation**: `SUPABASE_SETUP.md:952` and `14.1` state that `tasks_mvp`, `users`, and `user_conversations` use `SECURITY DEFINER`.
- **Risk**: These views bypass RLS completely. Any `authenticated` or even `public` user (depending on VIEW permissions) can see all rows.
- **Fix**: Re-create views with `SECURITY INVOKER` or apply explicit RLS to the views (Postgres 15+).

### G2: Exposed `auth.users`

- **Observation**: `SUPABASE_SETUP.md:1007` and `14.1` report that `public.users` exposes sensitive auth data to the `anon` role.
- **Risk**: Leakage of user emails and PII to unauthenticated actors.
- **Fix**: Immediately drop `public.users` and replace with a restrictive RPC (e.g., `get_profile_summaries`).

### G3: Role Ambiguity (`public` vs `authenticated`)

- **Observation**: Multiple policies (e.g., `profiles_Users can insert...`, `bookings_update_status_only`) use the `public` role instead of `authenticated`.
- **Risk**: Bypassing Auth check. If SLine intends for only authenticated users to interact, these policies should be bound to the `authenticated` role.
- **Fix**: Audit all `public` role policies. Migrate to `authenticated` where session is required.

## 2. Policy Logic Gaps

### G4: Missing `WITH CHECK` Validation

- **Observation**: Many `INSERT` policies are documented with simple `uid = owner_id` checks but omit business-level `WITH CHECK` constraints (e.g., preventing a client from inserting an offer on their own task).
- **Evidence**: `task_requests` insertion rules are complex (trigger-based) but not fully reflected in the RLS map.
- **Fix**: Explicitly define `WITH CHECK` clauses that mirror trigger logic to provide defense-in-depth.

### G5: `conversations_insert_client_only` Complexity

- **Observation**: This policy relies on a "favorites" relationship (`DECISION_Favorites_DM`).
- **Risk**: Hard to maintain; behavior is "hidden" in trigger logic (`conversations_before_insert_guard`).
- **Fix**: Move the favorites check directly into the RLS policy `USING` clause where possible to make the RLS map the source of truth.

## 3. Auditability Gaps

### G6: Hidden Predicates

- **Observation**: The current diagram (v1) only shows Table, Role, and CMD. It hides the `WHERE` clauses (the "magic").
- **Fix**: The final improved diagram must include the "Authorization Predicate" column.
