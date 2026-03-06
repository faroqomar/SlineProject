# 05_MINIMAL_PATCH_PLAN — Critical Fixes Only

> These are production blockers. Apply in order. Each step includes a verification query.

---

## Step 1: Drop `public.users` View (BLOCKER)

```sql
-- FIX: Remove PII exposure
DROP VIEW IF EXISTS public.users;
```

**Verify**:

```sql
SELECT viewname FROM pg_views WHERE schemaname = 'public' AND viewname = 'users';
-- Expected: 0 rows
```

---

## Step 2: Drop Messages Wide-Open Policies (BLOCKER)

```sql
-- FIX: Remove policies that allow reading/inserting ALL messages
DROP POLICY IF EXISTS "Allow users to read messages" ON public.messages;
DROP POLICY IF EXISTS "Allow users to insert messages" ON public.messages;
```

**Verify**:

```sql
SELECT policyname FROM pg_policies WHERE tablename = 'messages' AND policyname IN ('Allow users to read messages', 'Allow users to insert messages');
-- Expected: 0 rows
```

---

## Step 3: Fix admin_logs INSERT (BLOCKER)

```sql
-- FIX: Only service_role should insert logs
DROP POLICY IF EXISTS "Service Role can insert logs" ON public.admin_logs;
CREATE POLICY "admin_logs_insert_service_only" ON public.admin_logs
  FOR INSERT TO service_role
  WITH CHECK (true);
```

**Verify**:

```sql
SELECT policyname, roles FROM pg_policies WHERE tablename = 'admin_logs' AND cmd = 'INSERT';
-- Expected: 1 row, roles = {service_role}
```

---

## Step 4: Fix `bookings_update_status_only` (HIGH)

```sql
-- FIX: Add with_check and migrate to authenticated
DROP POLICY IF EXISTS "bookings_update_status_only" ON public.bookings;
-- Note: This policy is redundant with bookings_update_by_provider and bookings_cancel_by_client
-- which already have proper with_check clauses. Simply dropping it is the safest fix.
```

**Verify**:

```sql
SELECT policyname FROM pg_policies WHERE tablename = 'bookings' AND policyname = 'bookings_update_status_only';
-- Expected: 0 rows
```

---

## Step 5: Drop Redundant Messages Policies (HIGH)

```sql
DROP POLICY IF EXISTS "Users can insert their own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can view their messages" ON public.messages;
DROP POLICY IF EXISTS "Users can view their conversation messages" ON public.messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON public.messages;
```

**Verify**:

```sql
SELECT policyname, roles FROM pg_policies WHERE tablename = 'messages' AND roles::text LIKE '%public%';
-- Expected: 0 rows
```

---

## Step 6: Drop Redundant Bookings/Conversations `public` Policies (HIGH)

```sql
DROP POLICY IF EXISTS "bookings_insert_client" ON public.bookings;
DROP POLICY IF EXISTS "bookings_select_parties" ON public.bookings;
DROP POLICY IF EXISTS "Allow users to read conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can insert conversation if they are a participant" ON public.conversations;
```

---

## Step 7: Secure Admin/Analytics Views (HIGH)

```sql
-- Restrict admin views to service_role only
REVOKE SELECT ON public.vw_orphaned_auth_users FROM anon, authenticated;
REVOKE SELECT ON public.vw_admin_journal_ledger FROM anon, authenticated;
REVOKE SELECT ON public.vw_financial_metrics_realtime FROM anon, authenticated;
REVOKE SELECT ON public.vw_financial_metrics_period FROM anon, authenticated;
REVOKE SELECT ON public.vw_analytics_monthly_revenue FROM anon, authenticated;
REVOKE SELECT ON public.vw_analytics_monthly_user_growth FROM anon, authenticated;
```

**Verify**:

```sql
SELECT grantee, privilege_type FROM information_schema.role_table_grants WHERE table_name = 'vw_admin_journal_ledger' AND table_schema = 'public';
-- Expected: no rows for anon/authenticated
```

---

## Step 8: Recreate SECURITY DEFINER Views (HIGH)

```sql
-- tasks_mvp
DROP VIEW IF EXISTS public.tasks_mvp;
CREATE VIEW public.tasks_mvp WITH (security_invoker = true) AS
SELECT id, owner_id AS client_id, title, description, category_id, budget_cents,
       status, created_at, image_paths, assigned_freelancer_id, deadline, skills, task_type
FROM tasks;

-- user_conversations
DROP VIEW IF EXISTS public.user_conversations;
CREATE VIEW public.user_conversations WITH (security_invoker = true) AS
SELECT id, task_id, user1_id, user2_id, created_at
FROM conversations c
WHERE user1_id = auth.uid() OR user2_id = auth.uid();

-- wallet_balances (legacy)
DROP VIEW IF EXISTS public.wallet_balances;
CREATE VIEW public.wallet_balances WITH (security_invoker = true) AS
SELECT p.id AS user_id,
  COALESCE(sum(wt.amount) FILTER (WHERE wt.status = 'held'), 0::numeric) AS held_balance,
  COALESCE(sum(wt.amount) FILTER (WHERE wt.status = 'released'), 0::numeric) AS available_balance
FROM profiles p LEFT JOIN wallet_transactions wt ON p.id = wt.user_id
GROUP BY p.id;
```

---

## Execution Order

1. Step 1 (blocker)
2. Step 2 (blocker)
3. Step 3 (blocker)
4. Steps 4-6 (high priority cleanup)
5. Steps 7-8 (view hardening)

**Total changes**: 3 blockers, 5 high-priority cleanups. All can be applied in a single migration.
