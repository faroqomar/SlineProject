# 02_VIEW_BYPASS_AUDIT — Live Evidence

> Extracted: 2026-03-06, `pg_views` + `pg_class.relrowsecurity`

## Summary

**ALL 14 public views have `rls_status = 'no RLS'`**. Views in PostgreSQL do not have RLS by default. Whether they bypass RLS depends on `SECURITY DEFINER` vs `SECURITY INVOKER` configuration on the view or the functions they call.

In Supabase/Postgres, if a view is created without explicit `security_invoker = true` (PG15+), it defaults to `SECURITY INVOKER` behavior through `pg_views` but the Supabase documentation warns about `SECURITY DEFINER` views. The doc itself flags these.

## Critical Views

### 1. `public.users` 🔴 BLOCKER

**Definition**: `SELECT id, email, raw_user_meta_data->>'full_name', raw_user_meta_data->>'avatar_url' FROM auth.users u`

- **Exposes**: `id`, `email`, `full_name`, `avatar_url` for ALL users in `auth.users`.
- **Access**: Granted to `anon` and `authenticated` via default Supabase schema grants.
- **Impact**: Complete PII dump of all registered users.
- **Fix**: `DROP VIEW public.users;` — Use existing `rpc_get_profile_summaries(uuid[])` or `search_profiles(...)`.

### 2. `public.vw_orphaned_auth_users` 🔴 HIGH

**Definition**: `SELECT u.id, u.email, u.created_at FROM auth.users u LEFT JOIN profiles p ON u.id = p.id WHERE p.id IS NULL`

- **Exposes**: `id`, `email`, `created_at` for orphaned auth entries.
- **Fix**: Move to admin-only RPC or restrict privileges: `REVOKE SELECT ON public.vw_orphaned_auth_users FROM anon, authenticated;`

### 3. `public.tasks_mvp` ⚠️ HIGH

**Definition**: `SELECT id, owner_id AS client_id, title, ... FROM tasks`

- **Risk**: If `SECURITY DEFINER`, bypasses task RLS (all tasks visible, not just open/involved).
- **Evidence from SUPABASE_SETUP.md §14.1**: Documented as `SECURITY DEFINER`.
- **Fix**: `DROP VIEW public.tasks_mvp; CREATE VIEW public.tasks_mvp WITH (security_invoker = true) AS SELECT ... FROM tasks;`

### 4. `public.user_conversations` ⚠️ MEDIUM

**Definition**: `SELECT ... FROM conversations c WHERE user1_id = auth.uid() OR user2_id = auth.uid()`

- Contains inline `auth.uid()` filter but if `SECURITY DEFINER`, the base table RLS is bypassed.
- **Fix**: Same — recreate with `security_invoker = true`.

### 5. `public.wallet_balances` ⚠️ HIGH

**Definition**: `SELECT ... FROM profiles p LEFT JOIN wallet_transactions wt ...`

- Joins `profiles` with `wallet_transactions`. If definer, could expose ALL users' wallet data.
- **Fix**: Recreate with `security_invoker = true` or migrate to the new `vw_wallet_balances_user`.

### 6. `public.vw_admin_journal_ledger` ⚠️ HIGH

**Definition**: `SELECT ... FROM journal_entries je` with subqueries into `ledger_lines` and `accounts`.

- Exposes ALL journal entries and ledger details without any `auth.uid()` filter in the definition.
- **Fix**: `REVOKE SELECT FROM anon, authenticated; GRANT SELECT TO service_role;` or guard with admin check.

### 7. `public.vw_financial_metrics_realtime` / `vw_financial_metrics_period` ⚠️ MEDIUM

- Platform-level financial views. No user filter.
- **Fix**: Admin-only via privilege restriction.

### 8. `public.vw_analytics_monthly_revenue` / `vw_analytics_monthly_user_growth` ⚠️ MEDIUM

- Analytics views. No user filter.
- **Fix**: Admin-only via privilege restriction.

## Views That Are Safe (have `auth.uid()` inline filtering)

| View                       | Contains uid filter           | Risk                       |
| -------------------------- | ----------------------------- | -------------------------- |
| `vw_unified_work_items`    | No (relies on base table RLS) | Depends on invoker setting |
| `vw_wallet_balances_user`  | Yes (`auth.uid()`)            | LOW                        |
| `vw_wallet_activity_user`  | Yes (`auth.uid()`)            | LOW                        |
| `vw_unified_payable_items` | Yes (`auth.uid()`)            | LOW                        |
