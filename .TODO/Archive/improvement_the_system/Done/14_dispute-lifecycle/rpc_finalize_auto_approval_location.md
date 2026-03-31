# rpc_finalize_auto_approval — Location & Scope

**Plan:** PLAN_DisputeLifecycle_2026-03-08  
**Date:** 2026-03-08

## Location

- **In repo:** Not present in any file under `supabase/migrations/`. Grep for `rpc_finalize_auto_approval` or `finalize_auto_approval` in migrations returns no definition.
- **In DB:** Function exists (confirmed via Supabase MCP `execute_sql` on `information_schema.routines`).
- **Definition source:** Live DB only. Current body retrieved via `pg_get_functiondef(oid)` (see execution log).

## Scope (current)

- **Parameters:** `entity_type text`, `entity_id uuid`.
- **Branches:** `task` and `booking` only. No `direct_offer` branch.
- **Behavior:** If `entity_type = 'task'`: selects `status`, `review_expires_at` from `tasks`; if `status = 'delivered'` and `now() > review_expires_at`, updates `tasks` set `status = 'completed'`. If `entity_type = 'booking'`: same for `bookings`. Does **not** call `process_payment_event_ledger`; only sets row status. Any ledger release for auto-approval must happen elsewhere (e.g. trigger or separate cron).
- **Dispute guard:** None. Must be added in Phase 1: at start of each branch, if an open/active dispute exists for that task (or for booking’s task_id), return without updating (do not set status to 'completed').

## Patch strategy (Phase 1)

1. Create a new migration that replaces `rpc_finalize_auto_approval` with a version that:
   - After `auth.uid()` check, for **task**: if `EXISTS (SELECT 1 FROM disputes WHERE task_id = entity_id AND status IN ('open','active'))` then return current status (no update).
   - For **booking**: get `task_id` from `bookings` where `id = entity_id`; then same `EXISTS` on `disputes`; if true, return without update.
2. No `direct_offer` branch in current function; no change for direct_offer in this RPC.

## Verification

- After migration: call `rpc_finalize_auto_approval('booking', booking_id)` with a booking that has an open dispute on its task → function must return without setting status to 'completed'.
