# RLS verification checklist: Favorites & DM

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md  
**Locked rule**: Direct client-initiated DMs remain favorites-gated (DECISION_Favorites_DM).

## Favorites table

### Positive checks (must pass)

- **Own select**: As client A, `SELECT * FROM public.favorites WHERE client_id = auth.uid()` returns only A’s rows.
- **Own insert**: As client A, `INSERT INTO public.favorites (client_id, freelancer_id) VALUES (auth.uid(), :freelancer_id)` succeeds.
- **Own delete**: As client A, `DELETE FROM public.favorites WHERE client_id = auth.uid() AND freelancer_id = :id` succeeds for A’s row.

### Negative checks (must fail)

- **Cross-user select**: As client B, attempt to read client A’s favorites (e.g. by guessing IDs) → no rows or RLS denial.
- **Cross-user insert**: As client B, `INSERT ... client_id = A’s uid` → RLS denial (insert_self requires `client_id = auth.uid()`).
- **Cross-user delete**: As client B, delete a row where `client_id = A` → RLS denial.

## Conversations (DM) – direct insert

### Positive check

- **DM with favorite**: Client A has a favorite row for freelancer F. Insert direct conversation (user1_id, user2_id = A, F; task_id = NULL) → allowed if policy/trigger permits (favorites-gated).

### Negative check

- **DM without favorite**: Client A has no favorite row for freelancer F. Insert direct conversation (A, F; task_id = NULL) → must **fail** (policy or trigger enforces favorites gate).

## Verification commands (run against live/staging)

```sql
-- Policies on favorites
SELECT schemaname, tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'favorites';

-- Policies on conversations (INSERT)
SELECT schemaname, tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'conversations' AND cmd = 'INSERT';

-- Function used by conversations trigger
SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'conversations_before_insert_guard';
```

**Note**: Live scan must be run by team with DB access. Attach output to execution log when available. If live policy contradicts DECISION_Favorites_DM, block implementation until reconciled (docs-only or migration per MIGRATION_Favorites_DM_Reconcile).
