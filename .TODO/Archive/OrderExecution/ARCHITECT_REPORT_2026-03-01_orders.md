> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# Architect Report — orders

- Date: 2026-03-01
- Scope: `orders`
- Plan Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_OrdersFix_2026-03-01.md`
- Workflow: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.agents/workflows/orchestrator.md`

## Evidence
- Navigation wiring exists and points the `orders` slot to `OrdersDashboardScreen` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart:37-45`.
- Bottom-nav labeling and keys exist for the dedicated orders tab in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/widgets/custom_bottom_nav_bar.dart:21-27` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/widgets/custom_bottom_nav_bar.dart:57-63`.
- Orders screen, viewmodel, service, and offer-sheet VM all exist at:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart:18-45`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart:8-44`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/services/orders_service.dart:9-45`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/order_offers_view_model.dart:6-99`
- Direct dependency owner/status compatibility logic exists in:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_model.dart:136-205`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:301-345`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:233-334`

## MVVM Boundary Check
- Pass: no direct Supabase access is present in the audited orders view files. The screen talks to `OrdersViewModel`, and the offer sheet talks to `OrderOffersViewModel`.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart:51-57`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/widgets/offer_list_sheet.dart:39-62`
- Pass: data access remains in services.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/services/orders_service.dart:23-45`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:301-345`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:43-82`
- Residual issue: `OrdersDashboardScreen` still owns cross-feature orchestration for chat launch and post-edit refresh. That is better than direct DB access, but it still makes the view a coordinator for non-trivial flow.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart:327-397`

## Data Flow Map
- `NavView.orders` -> `MainNavigationScreen` -> `OrdersDashboardScreen`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/widgets/custom_bottom_nav_bar.dart:57-63`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart:37-45`
- `OrdersDashboardScreen.initState()` -> `OrdersViewModel.loadOrders()`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart:39-45`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart:29-44`
- `OrdersViewModel` -> `OrdersService.getMyPublishedTasks()` -> `TaskService.getTasksByOwner()`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart:34-39`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/services/orders_service.dart:23-31`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:301-345`
- `OfferListSheet` -> `OrderOffersViewModel` -> `OrdersService.acceptOffer/rejectOffer()` -> `TaskRequestsService.accept/reject()`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/widgets/offer_list_sheet.dart:43-50`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/order_offers_view_model.dart:30-99`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/services/orders_service.dart:33-39`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:233-303`

## Contract Checks
- App-side owner contract is now compatibility-based: reads use `owner_id`, then `user_id`, then `client_id`.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_model.dart:136-148`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:305-345`
- App-side offer decision contract is now pinned to the two-argument RPCs.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:237-241`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:273-277`
- App-side unknown-status behavior is safer than before.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_model.dart:179-201`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_request_model.dart:71-80`
- Residual mismatch remains at the server contract level: live `tasks`/`task_requests` authorization still mixes `user_id`, `client_id`, and `owner_id`, so the app contract is compatibility logic over drift, not a true canonical backend contract yet.
  - Live DB evidence captured in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/EXECUTION_LOG_PLAN_OrdersFix_2026-03-01.md:50-56`

## Findings
- MEDIUM: `OrdersDashboardScreen` still owns chat launch and edit-refresh orchestration. Move those actions behind a feature coordinator or VM-facing interface to reduce view responsibility.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart:327-397`
- MEDIUM: `OrdersViewModel` remains app-root scoped, which is broader than the feature requires and increases stale state risk if more tabs begin sharing it.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:152-154`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart:15-26`
- HIGH: the architecture is app-compatible but still backend-dependent on mixed owner semantics. This is not fixable in the view/viewmodel layers alone.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:301-345`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/EXECUTION_LOG_PLAN_OrdersFix_2026-03-01.md:21-30`

## Proposed Refactors
- Move chat launch and post-edit refresh orchestration out of `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart` into a dedicated `OrdersCoordinator` or VM method.
- Localize `OrdersViewModel` provider scope to the orders tab composition path once navigation ownership is stable.
- Keep `OrderOffersViewModel` local to the offer sheet. That split is correct and should not be collapsed back into the dashboard VM.

## Path Validation Notes
- All referenced repo paths in scope exist.
- No missing feature files were found for the current orders UI path.
- Live DB contract remains the only structural blocker; repo paths themselves are valid.

## Verdict
- Architecture status: PASS at the MVVM boundary level.
- Release status: NOT READY because backend owner/RLS drift is still unresolved outside the repo boundary.
