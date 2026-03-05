> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# Pipeline Blocked — orders

- Date: 2026-03-01
- Workflow: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.agents/workflows/orchestrator.md`
- Final Status: BLOCKED

## Why Blocked
- `@CodeGuard` returned `BLOCKED ❌` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/CODEGUARD_REVIEW_2026-03-01_orders.md`.
- The live Supabase project still has schema/RLS drift across owner semantics and auth-critical RPCs.
- The live notification insert policy is still broader than the offer-decision flow should rely on.

## Blocking Evidence
- Mixed owner authorization on `tasks` policies:
  - live `pg_policies` check on 2026-03-01 showed active policies keyed separately to `user_id`, `client_id`, and `owner_id`.
  - repo-side compatibility logic exists in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:301-345`, but the backend contract is still mixed.
- Overloaded offer-decision RPCs still disagree on owner semantics:
  - app uses the two-argument variants in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:237-241` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:273-277`
  - live one-argument variants still check `tasks.user_id`, while the two-argument variants check `tasks.client_id`
- Notification least-privilege gap remains:
  - client-side notification writes still happen in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:245-255` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:281-291`
  - live `notifications_insert_any` policy still allows any authenticated insert

## What To Fix First
1. Lock one canonical server-side owner contract for `tasks` and `task_requests`.
2. Align or retire the one-argument `accept_task_request` and `reject_task_request` functions.
3. Replace client-side offer-decision notification writes with a least-privilege server-side path, or narrow the notification insert policy.
4. Update `Sline_everything/SUPABASE_SETUP.md` to document the canonical RPC path once the DB contract is fixed.

## Which Agent Must Re-Run After Fix
- `@Supabase_Ops`
- `@SlineDocs`
- `@CodeGuard`

## Agent Outputs Produced Before Halt
- `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/ARCHITECT_REPORT_2026-03-01_orders.md`
- `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/OBSERVABILITY_REPORT_2026-03-01_orders.md`
- `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/DOCS_REPORT_2026-03-01_orders.md`
- `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/CODEGUARD_REVIEW_2026-03-01_orders.md`

## Next Actions
1. Patch the live DB contract first.
2. Re-run the orchestrator pipeline after the DB/RLS patch lands.
