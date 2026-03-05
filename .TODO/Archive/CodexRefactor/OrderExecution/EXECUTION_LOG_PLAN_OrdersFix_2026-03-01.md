> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# Execution Log — PLAN_OrdersFix_2026-03-01

## Phase 0 — Hard-Gate Scan
- Executor workflow loaded from `.agents/workflows/executor.md`.
- Relevant implementation skills loaded:
  - `.agents/skills/architecture_guard/SKILL.md`
  - `.agents/skills/bug_fixer/SKILL.md`
- Documentation inventory scanned from `Sline_everything/`.
- Code inventory scanned from `lib/`, `test/`, and `integration_test/`.
- Live Supabase verified for:
  - `public.tasks`
  - `public.task_requests`
  - `public.notifications`
  - `public.conversations`
  - `public.messages`
  - `accept_task_request`
  - `reject_task_request`
  - `replace_task_request`
  - storage buckets and `storage.objects` policies

## Phase 0 — Execution Assumptions
- `orders` remains a standalone feature and should route to `OrdersDashboardScreen`.
- Runtime read contract for orders is owner-based, using `owner_id` with compatibility coverage for `user_id` and `client_id`.
- Offer-decision client flow will use the canonical two-argument `accept_task_request(task_id, request_id)` and `reject_task_request(task_id, request_id)` RPC variants, then re-fetch the updated request row.
- Live DB migrations are allowed in this execution when the repo and live contract diverge on owner authorization or notification trust.

## Phase 0 — Risks
- Live docs still describe `tasks.user_id` as the orders owner contract.
- Overloaded RPCs remain live and disagree on owner semantics.
- Notification insert policy remains broad (`notifications_insert_any`), so app-side behavior must not widen.

## Phase 0 — Artifacts
- `.TODO/CONTRACT_Orders_Runtime_2026-03-01.md`
- `.TODO/THREAT_MODEL_Orders_2026-03-01.md`
- `.TODO/TEST_INFRA_Orders_2026-03-01.md`

## Phase 1+ Progress
- Restored the `orders` navigation slot to `OrdersDashboardScreen` and relabeled the bottom-nav item to `Orders`.
- Normalized orders/runtime parsing:
  - `Task.fromJson()` now reads owner-compatible ids and maps `in_progress` safely.
  - `TaskRequest.fromMap()` now preserves unknown offer states and supports fallback fields (`duration_days`, `message`).
- Reworked orders state handling:
  - `OrdersViewModel` now exposes explicit error state instead of collapsing failures into empty UI.
  - `OrderOffersViewModel` isolates sheet loading and per-offer processing state.
  - `OfferListSheet` disables unknown/non-actionable offer states and surfaces friendly action errors.
- Fixed direct dependency drift:
  - `TaskRequestsService.accept()` / `reject()` now call the live two-argument owner RPCs and re-fetch the updated row.
  - `TaskRequestsService.replaceOffer()` now matches the live `replace_task_request(...) -> void` contract by re-fetching the active offer after RPC success.
- Applied live owner-contract migration:
  - `supabase/migrations/20260301_reconcile_orders_owner_contract.sql`
  - Canonicalized owner auth on `tasks.owner_id` for `tasks`, `task_requests`, and owner-side tender payment RPCs.
  - Added server-side task-request owner notification trigger.
  - Replaced mixed-contract one-arg/two-arg offer decision RPCs with canonical owner-based implementations and compatibility wrappers.
- Applied live notification-hardening migration:
  - `supabase/migrations/20260301_harden_notification_writes.sql`
  - Added server-side conversation notification upsert trigger on `messages`.
  - Added server-side task status notification trigger on `tasks`.
  - Removed client notification writes from orders-adjacent app services.
  - Dropped `notifications_insert_any`.

## Verification Evidence
- `flutter analyze`
  - Result: passed with `No issues found!`
- `flutter test test/unit/models/task_model_test.dart test/unit/models/task_request_model_test.dart test/unit/features/orders/orders_view_model_test.dart test/unit/features/orders/order_offers_view_model_test.dart test/widget/app/main_navigation_screen_test.dart`
  - Result: passed, 21 tests green.
- `rg -n "createNotification\\(|createOrUpdateNotification\\(|from\\('notifications'\\)\\.insert|from\\(\"notifications\"\\)\\.insert" lib`
  - Result: no matches. Direct client-side notification inserts have been removed from app code.
- Live Supabase metadata re-check used during execution:
  - `public.replace_task_request(p_task_id uuid, p_freelancer_id uuid, p_message text, p_price integer, p_days integer) -> void`
  - `public.accept_task_request(p_task_id uuid, p_request_id uuid) -> uuid`
  - `public.reject_task_request(p_task_id uuid, p_request_id uuid) -> uuid`
  - `public.accept_task_request(p_request_id uuid) -> task_requests`
  - `public.reject_task_request(p_request_id uuid) -> task_requests`
  - `public.private_create_notification(...) -> void`
  - `public.private_upsert_notification(...) -> void`
  - `public.trg_task_requests_after_insert_notify_owner`
  - `public.trg_messages_after_insert_notify_receiver`
  - `public.trg_tasks_after_status_change_notify_parties`
  - `public.notifications_insert_any` removed

## Docs Sync
- Updated:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
  - `Sline_everything/SUPABASE_SETUP.md`
