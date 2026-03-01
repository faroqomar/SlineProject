> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# CodeGuard Review — orders

- Date: 2026-03-01
- Scope: `orders`
- Plan Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_OrdersFix_2026-03-01.md`
- Workflow: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.agents/workflows/orchestrator.md`

## Freshness Checks
- Repo check: `flutter analyze` on 2026-03-01 -> passed with no issues.
- Repo check: targeted orders tests on 2026-03-01 -> passed.
- Live DB check: `pg_policies` and `pg_proc` re-scanned on 2026-03-01 for `tasks`, `task_requests`, `notifications`, `accept_task_request`, `reject_task_request`, `replace_task_request`.

## Performance Review
- PASS: orders list filtering is cached in VM state instead of being recomputed ad hoc in the widget tree.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart:15-26`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart:90-123`
- PASS: offer sheet owns its own loading state and no longer depends on dashboard-global loading.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/widgets/offer_list_sheet.dart:39-62`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/order_offers_view_model.dart:18-99`

## Security Review
- BLOCKER: live `tasks` authorization is still mixed across `user_id`, `client_id`, and `owner_id`.
  - Live policy evidence from 2026-03-01:
    - `tasks_select_authenticated_open_or_involved` uses `user_id`, `client_id`, and `owner_id`
    - `Allow delete own tasks` uses `user_id`
    - `tasks_delete_policy` uses `client_id`
    - `tasks_update_owner` uses `owner_id`
  - Evidence captured in the orchestrator session from `pg_policies` and summarized in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/EXECUTION_LOG_PLAN_OrdersFix_2026-03-01.md:21-30`
- BLOCKER: live `accept_task_request`/`reject_task_request` still have overloaded auth-critical signatures with different owner checks.
  - Live function evidence from 2026-03-01:
    - one-arg `accept_task_request(p_request_id uuid)` checks `tasks.user_id`
    - two-arg `accept_task_request(p_task_id uuid, p_request_id uuid)` checks `tasks.client_id`
    - one-arg `reject_task_request(p_request_id uuid)` checks `tasks.user_id`
    - two-arg `reject_task_request(p_task_id uuid, p_request_id uuid)` checks `tasks.client_id`
  - App code uses the two-arg variants in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:237-241` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:273-277`, but the live project still exposes the conflicting legacy path.
- BLOCKER: `notifications_insert_any` still allows any authenticated insert, while offer decisions still create notifications client-side.
  - Notification writes are initiated in:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:245-255`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:281-291`
  - Live policy evidence from 2026-03-01:
    - `notifications_insert_any` -> `with_check = (auth.role() = 'authenticated')`
- MEDIUM: UI-facing sanitization is improved but not fully hardened. `_messageFromError(...)` still returns arbitrary non-empty exception text when the exception is not prefixed with `Exception:`.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart:404-409`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart:125-130`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/order_offers_view_model.dart:101-106`

## Compatibility Review
- PASS: the current app wiring now exposes the standalone orders screen again.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart:37-45`
- PASS: a compatibility alias remains for `dashboardNavKey`, reducing immediate integration-test breakage.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/widgets/custom_bottom_nav_bar.dart:24-26`
- MEDIUM: compatibility currently lives in app code, not in the database contract. This is safe enough for compile/runtime, but not strong enough for release confidence.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:301-345`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_model.dart:136-205`

## Verification Commands
- `flutter analyze`
- `flutter test test/unit/models/task_model_test.dart test/unit/models/task_request_model_test.dart test/unit/features/orders/orders_view_model_test.dart test/unit/features/orders/order_offers_view_model_test.dart test/widget/app/main_navigation_screen_test.dart`
- SQL freshness checks used for this review:
  - `select schemaname, tablename, policyname, cmd, qual, with_check from pg_policies ...`
  - `select p.proname, pg_get_function_identity_arguments(...), pg_get_function_result(...), pg_get_functiondef(...) from pg_proc ...`

## Risk Rating
- Overall risk: HIGH

## Decision
- BLOCKED ❌

## Blockers To Resolve Before Re-Run
1. Converge live owner authorization for `tasks` and `task_requests` onto one canonical rule.
2. Remove or formally deprecate the overloaded one-argument accept/reject RPCs, or align them to the same owner rule as the canonical client path.
3. Remove client-side dependence on `notifications_insert_any`, or narrow that policy and move offer-decision notifications server-side.
