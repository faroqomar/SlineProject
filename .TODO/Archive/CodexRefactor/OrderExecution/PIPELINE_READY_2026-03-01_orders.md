> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# Pipeline Ready — orders

- Date: 2026-03-01
- Workflow baseline: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.agents/workflows/Orchestrator.md`
- Final Status: READY
- Supersedes: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PIPELINE_BLOCKED_2026-03-01_orders.md`

## Why Ready
- Live owner authorization is now canonical on `tasks.owner_id` for `tasks`, `task_requests`, and owner-side tender payment RPCs.
- Offer-decision RPC drift is resolved. Both one-argument wrappers and two-argument canonical RPCs now converge on the same owner contract.
- Orders no longer relies on client-side notification inserts.
- Remaining notification-producing flows that were still client-side in repo code were moved server-side, allowing `notifications_insert_any` to be removed.

## Repo Evidence
- Orders uses the canonical owner-side RPCs in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:206` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:230`.
- Task status updates no longer perform client notification writes in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:184`.
- Message sends no longer perform client notification writes in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/services/message_service.dart:268`.
- Orders error states still sanitize raw backend/framework exceptions in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart:125` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/order_offers_view_model.dart:101`.
- Repo migration trail now documents the live contract in:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_reconcile_orders_owner_contract.sql`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_harden_notification_writes.sql`

## Live Supabase Evidence
- `pg_policies` now shows:
  - `tasks_select_authenticated_open_or_involved`
  - `tasks_insert_owner`
  - `tasks_update_involved`
  - `tasks_update_owner`
  - `tasks_delete_owner`
  - `tr_insert`
  - `tr_select`
  - `tr_update`
  - `tr_update_by_owner`
  - `tr_delete`
  - `notifications_select_own`
  - `notifications_update_own`
- `notifications_insert_any` is no longer present.
- `pg_proc` now includes:
  - `accept_task_request(uuid, uuid)`
  - `accept_task_request(uuid)`
  - `reject_task_request(uuid, uuid)`
  - `reject_task_request(uuid)`
  - `award_task_offer(uuid, uuid)`
  - `pay_awarded_offer(uuid, uuid)`
  - `get_client_awarded_unpaid_offers(uuid)`
  - `private_create_notification(...)`
  - `private_upsert_notification(...)`
- `pg_trigger` now includes:
  - `trg_task_requests_after_insert_notify_owner`
  - `trg_messages_after_insert_notify_receiver`
  - `trg_tasks_after_status_change_notify_parties`

## Verification
- `flutter analyze`
  - Passed
- `flutter test test/unit/models/task_model_test.dart test/unit/models/task_request_model_test.dart test/unit/features/orders/orders_view_model_test.dart test/unit/features/orders/order_offers_view_model_test.dart test/widget/app/main_navigation_screen_test.dart`
  - Passed
- `rg -n "createNotification\\(|createOrUpdateNotification\\(|from\\('notifications'\\)\\.insert|from\\(\"notifications\"\\)\\.insert" lib`
  - No matches

## Residual Notes
- This READY verdict is scoped to `orders`, its direct Dart dependencies, and the Supabase contract paths those flows touch.
- Full end-to-end manual device verification and a full-project test sweep were not run in this pass.
