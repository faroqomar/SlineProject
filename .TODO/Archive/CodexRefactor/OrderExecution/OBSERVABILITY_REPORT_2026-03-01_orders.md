> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# Observability Report — orders

- Date: 2026-03-01
- Scope: `orders`
- Plan Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_OrdersFix_2026-03-01.md`
- Workflow: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.agents/workflows/Orchestrator.md`

## Evidence
- Central logger exists and is the active mechanism used by the orders path.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart:18-208`
- Orders dashboard VM logs load/delete/accept/reject failures.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart:34-44`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart:54-87`
- Offer sheet VM logs load and mutation failures with the `OrdersOffers` tag.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/order_offers_view_model.dart:35-48`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/order_offers_view_model.dart:78-98`
- Task request service logs submit/replace/accept/reject actions with the `Offers` tag.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:49-82`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:91-186`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:196-303`

## Current Telemetry Assessment
- Pass: the orders path uses `AppLogger` and does not use `print()` in the audited feature files.
- Pass: crash reporting is wired through `AppLogger.e(...)`.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart:162-181`
- Gap: there is no correlation identifier linking one user action across dashboard VM, offer sheet VM, service RPC, and notification side effect.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/order_offers_view_model.dart:51-99`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:233-303`
- Gap: there is no structured audit event for authorization denial vs stale-offer rejection vs notification side-effect failure.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:157-159`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:258-265`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:294-301`
- Gap: `AppLogger` masks access and refresh tokens, but it does not provide a policy for task notes, offer messages, bidder names, storage paths, or arbitrary JSON payloads beyond token patterns.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart:40-79`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart:118-139`

## What To Log
- `orders_load_started`, `orders_load_succeeded`, `orders_load_failed`
  - minimum fields: `actor_id_hash`, `active_tab`, `result_count`, `error_class`, `error_code`
- `order_offer_decision_started`, `order_offer_decision_succeeded`, `order_offer_decision_failed`
  - minimum fields: `task_id`, `request_id`, `decision`, `rpc_signature`, `ui_surface=offer_sheet`, `result_status`
- `order_chat_open_started`, `order_chat_open_succeeded`, `order_chat_open_failed`
  - minimum fields: `task_id`, `conversation_id`, `error_class`
- `notification_side_effect_failed`
  - minimum fields: `task_id`, `request_id`, `decision`, `target_user_id_hash`, `error_class`

## What NOT To Log
- Offer `note` or `message` content.
- Bidder names or avatar paths when not needed for debugging.
- Raw access tokens, refresh tokens, session payloads, or full auth headers.
- Raw PostgREST payloads if they can include user-entered text or storage paths.

## Correlation Strategy
- Generate one `order_action_id` at the UI edge for each accept/reject/delete/chat action.
- Propagate `order_action_id` through:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/order_offers_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/services/orders_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart`
- Use `AppLogger` tags plus `jsonPayload` to emit stable machine-readable fields instead of only free-text messages.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart:118-124`

## Privacy-Safe Logging Plan
- Keep UI-facing messages sanitized and English-only.
- Keep service logs outcome-focused: task/request ids, decision type, result code, not user-entered text.
- Log notification failures as side effects, not as reasons to change the user-visible mutation outcome.

## Required Follow-Up
- Add structured event payload support to the orders/offer paths.
- Add `order_action_id` propagation.
- Add explicit denial/stale side-effect taxonomy in `TaskRequestsService._mapDecisionError(...)` and the corresponding logs.

## Verdict
- Observability status: PARTIAL PASS.
- No standalone blocker from logging alone.
- The lack of correlation and least-privilege audit events increases incident triage cost and should be fixed with the backend contract work.
