# dashboard — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does: the dashboard is the four-tab work hub for overview, bookings, work, and inbox; it is mounted in the main navigation stack and exposed as the `/dashboard` route. File Reference: `lib/app/main_navigation_screen.dart:39-51`, `lib/main.dart:166-182`, `lib/main.dart:294-300`, `lib/features/dashboard/view/dashboard_screen.dart:96-149`, `lib/core/app_enums.dart:62-63`
- Boundaries (in scope): this audit covers `lib/features/dashboard/**` plus direct dependencies imported or called by the dashboard for bookings, tasks, tender payment, wallet snapshot, cache, profile enrichment, and services data. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:4-16`, `lib/features/dashboard/view/tabs/inbox_tab.dart:7-9`, `lib/features/dashboard/view/widgets/work_item_card.dart:11-15`, `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart:7-8`
- Boundaries (out of scope): deeper feature internals that the dashboard does not directly call were not audited; deployed SQL objects without a matching repository migration are marked `UNVERIFIED`. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:349-879`, `Sline_everything/SUPABASE_SETUP.md:934-986`
- Entry points (screens/routes/calls): `DashboardScreen`, the role switcher inside the dashboard settings dialog, tab changes through `DashboardViewModel.setTab`, and tender award/payment flows launched from `InboxTab`. File Reference: `lib/features/dashboard/view/dashboard_screen.dart:61-123`, `lib/features/dashboard/view/dashboard_screen.dart:156-229`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:243-347`, `lib/features/dashboard/view/tabs/inbox_tab.dart:21-105`

## 1) Feature Map (Current Repo State)
- Primary feature files:
  - `lib/features/dashboard/view/dashboard_screen.dart` renders the shell and tab wiring. File Reference: `lib/features/dashboard/view/dashboard_screen.dart:15-229`
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart` owns role state, loading, work actions, booking actions, inbox actions, management data, and cache hooks. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:24-964`
  - `lib/features/dashboard/data/dashboard_repository.dart` performs dashboard reads for work items, activity, counters, finance views, wallet view, and awarded-offer RPCs. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:13-478`
  - `lib/features/dashboard/view/tabs/overview_tab.dart`, `bookings_tab.dart`, `work_tab.dart`, and `inbox_tab.dart` consume the view model and render the active feature surface. File Reference: `lib/features/dashboard/view/tabs/overview_tab.dart:13-72`, `lib/features/dashboard/view/tabs/bookings_tab.dart:10-89`, `lib/features/dashboard/view/tabs/work_tab.dart:11-304`, `lib/features/dashboard/view/tabs/inbox_tab.dart:11-193`
  - Dashboard-specific cards and lists currently live under the dashboard feature even when they present booking/task/wallet domain data. File Reference: `lib/features/dashboard/view/widgets/booking_card.dart:16-271`, `lib/features/dashboard/view/widgets/offer_card.dart:13-360`, `lib/features/dashboard/view/widgets/work_item_card.dart:17-280`, `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart:10-112`
- Direct dependencies:
  - Bootstrapping and DI: dashboard provider is registered in `main.dart`, but the cache service is registered separately and not injected into the dashboard provider. File Reference: `lib/main.dart:166-182`
  - Booking dependency: dashboard calls booking list, accept, decline, cancel, and direct status updates through `BookingService`. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:479-525`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:753-809`, `lib/features/booking/services/booking_service.dart:22-336`
  - Task dependency: dashboard calls task list, offer list, offer award/pay/refund/reject, and direct task status updates through `TaskService`. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:493-745`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:812-879`, `lib/features/tasks/services/task_service.dart:184-875`
  - Tender payment dependency: `InboxTab` launches `TenderPaymentScreen`, which creates `QiCardPaymentService` and `TaskService` in widget state and calls `TaskService.payAwardedOffer`. File Reference: `lib/features/dashboard/view/tabs/inbox_tab.dart:21-105`, `lib/features/tasks/view/tender_payment_screen.dart:39-109`
  - Wallet dependency: overview uses `WalletSnapshotCard`, which reads `WalletViewModel`; wallet loading currently happens in `WalletScreen.initState`, not in dashboard flow. File Reference: `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart:14-75`, `lib/features/wallet/viewmodels/wallet_view_model.dart:14-49`, `lib/features/wallet/view/wallet_screen.dart:19-26`
  - Profile enrichment dependency: dashboard profile enrichment uses `ProfileSummaryService.fetchByIds`, which calls the `rpc_get_profile_summaries` RPC. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:118-160`, `lib/features/profile/services/profile_summary_service.dart:13-58`
  - Services data dependency: dashboard management data and `MyServicesScreen` both depend on `DashboardViewModel.myServices`. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:111-116`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:459-477`, `lib/features/profile/view/my_services_screen.dart:13-75`, `lib/features/services/services/services_service.dart:11-24`
  - Cache dependency: `DashboardCacheService` exists, but the active dashboard provider does not pass it into `DashboardViewModel`. File Reference: `lib/main.dart:167-180`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33-52`, `lib/core/services/dashboard_cache_service.dart:14-229`
  - Cross-feature duplicate flow: the task-request feature has a second award/pay orchestration and launches the same `TenderPaymentScreen`. File Reference: `lib/features/tasks/viewmodels/task_requests_view_model.dart:115-169`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:127-167`
- Supabase touchpoints (tables/RPC/storage/realtime):
  - Tables read or mutated by dashboard code: `profiles`, `activity_log`, `tasks`, `task_requests`, `bookings`, `services`. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:31-35`, `lib/features/dashboard/data/dashboard_repository.dart:223-229`, `lib/features/tasks/services/task_service.dart:187-190`, `lib/features/tasks/services/task_service.dart:520-542`, `lib/features/booking/services/booking_service.dart:30-41`, `lib/features/services/services/services_service.dart:13-17`
  - Views read by dashboard code: `vw_unified_work_items`, `vw_financial_metrics_realtime`, `vw_financial_metrics_period`, `vw_wallet_balances_user`. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:78-89`, `lib/features/dashboard/data/dashboard_repository.dart:322-325`, `lib/features/dashboard/data/dashboard_repository.dart:362-366`, `lib/features/dashboard/data/dashboard_repository.dart:399-402`
  - RPCs called by dashboard or its direct dependencies: `rpc_get_profile_summaries`, `award_task_offer`, `pay_awarded_offer`, `process_payment_event_ledger`, `get_client_awarded_unpaid_offers`, `get_freelancer_awarded_unpaid_offers`. File Reference: `lib/features/profile/services/profile_summary_service.dart:22-25`, `lib/features/tasks/services/task_service.dart:712-718`, `lib/features/tasks/services/task_service.dart:763-767`, `lib/features/wallet/services/ledger_service.dart:36-49`, `lib/features/dashboard/data/dashboard_repository.dart:439-461`
  - RLS and documented contracts touched by dashboard flows: `profiles_select_self`, `tasks_update_involved`, `tr_select`, `tr_update`, `bookings_update_status_only`, and the documented `vw_unified_work_items` definition. File Reference: `Sline_everything/SUPABASE_SETUP.md:1003-1078`, `Sline_everything/SUPABASE_SETUP.md:934-986`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:16-40`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:69-102`
  - Storage buckets: no direct storage bucket access was found in the audited dashboard code paths. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:13-478`, `lib/features/tasks/services/task_service.dart:184-875`, `lib/features/booking/services/booking_service.dart:22-336`, `lib/features/wallet/services/ledger_service.dart:21-57`
  - Realtime channels: no direct realtime `channel(...)` usage was found in the audited dashboard code paths. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:13-478`, `lib/features/tasks/services/task_service.dart:184-875`, `lib/features/booking/services/booking_service.dart:22-336`, `lib/features/wallet/services/ledger_service.dart:21-57`
  - Edge functions: no direct `functions.invoke(...)` usage was found in the audited dashboard code paths. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:13-478`, `lib/features/tasks/services/task_service.dart:184-875`, `lib/features/booking/services/booking_service.dart:22-336`, `lib/features/wallet/services/ledger_service.dart:21-57`

## 2) Evidence Index (Ground Truth)
| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| SEC-01 | Financial metrics views are documented as admin/service-role only, but the migration grants `SELECT` on both views to `authenticated`, and the dashboard repository exposes direct client methods for them. | `supabase/migrations/20260225_create_wallet_views.sql:161-255`, `supabase/migrations/20260225_create_wallet_views.sql:412-430`, `lib/features/dashboard/data/dashboard_repository.dart:316-386` | Critical | Current UI does not render these methods, but the client data surface exists. |
| SEC-02 | Dashboard task and booking transitions are still client-issued direct row updates while current policies only check row involvement, not allowed state transitions. | `lib/features/dashboard/viewmodels/dashboard_view_model.dart:753-879`, `lib/features/tasks/services/task_service.dart:184-212`, `lib/features/booking/services/booking_service.dart:117-143`, `Sline_everything/SUPABASE_SETUP.md:1019-1027`, `Sline_everything/SUPABASE_SETUP.md:1071-1078` | Critical | RLS is ownership/involvement, not a workflow guard. |
| SEC-03 | Cross-user profile summaries return more fields than the dashboard uses. | `lib/features/dashboard/data/dashboard_repository.dart:139-143`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47` | High | Dashboard only uses `full_name` and `avatar_url`. |
| SEC-04 | The repository documents a `vw_unified_work_items` definition, but no matching migration was found in `supabase/migrations`; deployed authorization parity is `UNVERIFIED`. | `Sline_everything/SUPABASE_SETUP.md:934-986` | Medium | Repo cannot prove the deployed SQL matches the docs. |
| INT-01 | Tender award/pay flow has a status mismatch: award sets `accepted/unpaid`, but escrow hold only allows `pending/unpaid`. | `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:518-569`, `lib/features/tasks/services/task_service.dart:731-759`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:107-160` | Critical | Happy-path payment can fail after a successful award. |
| INT-02 | Ledger RPC returns JSON payloads, including `{ok:false}`, but `LedgerService` returns the payload without validating `ok`; `TaskService.payAwardedOffer` proceeds to the next RPC call. | `lib/features/wallet/services/ledger_service.dart:21-57`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:52-69`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:151-170`, `lib/features/tasks/services/task_service.dart:752-775` | Critical | Business-rule failures can be treated as success by callers. |
| INT-03 | Client cancellation from a confirmed booking uses a direct status update path instead of the booking refund/release flows. | `lib/features/dashboard/view/widgets/booking_card.dart:236-263`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:753-773`, `lib/features/booking/services/booking_service.dart:117-143`, `lib/features/booking/services/booking_service.dart:189-245` | High | A confirmed booking can move to canceled without refund ledger logic. |
| INT-04 | `getPendingPaymentTenders` comments describe assigned/payment-pending work, but the live query fetches `assigned_freelancer_id = uid` with `status = 'open'`. | `lib/features/tasks/services/task_service.dart:815-875` | High | Dashboard pending-tender counts/data can be silently wrong. |
| ARC-01 | `DashboardViewModel` owns too many responsibilities in one class. | `lib/features/dashboard/viewmodels/dashboard_view_model.dart:24-964` | High | Role state, loading, work actions, booking flows, inbox flows, management data, and cache hooks all live together. |
| ARC-02 | `TenderPaymentScreen` instantiates services inside widget state instead of receiving a view model/service through DI. | `lib/features/tasks/view/tender_payment_screen.dart:39-50` | High | Breaks `View -> ViewModel -> Service` direction for a high-risk flow. |
| ARC-03 | `DashboardCacheService` is provided at app level but not injected into `DashboardViewModel`, leaving cache paths dormant. | `lib/main.dart:167-180`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33-52`, `lib/core/services/dashboard_cache_service.dart:206-228` | Medium | SWR cache behavior is not active in the default app wiring. |
| QUAL-01 | `WorkItemCard` suppresses `startWork` buttons even though permission tests expect `canStart` for confirmed freelancer bookings. | `lib/features/dashboard/view/widgets/work_item_card.dart:234-253`, `test/unit/dashboard/dashboard_permission_service_test.dart:7-18` | High | Work items can expose a permission in logic but no action in UI. |
| QUAL-02 | Removed Manage tab code and management widgets still exist, and `MyServicesScreen` still depends on dashboard-owned state. | `lib/features/dashboard/view/dashboard_screen.dart:124-149`, `lib/features/dashboard/view/tabs/manage_tab.dart:10-83`, `lib/features/dashboard/view/widgets/manage_service_list.dart:9-136`, `lib/features/dashboard/view/widgets/manage_task_list.dart:9-115`, `lib/features/profile/view/my_services_screen.dart:14-17` | Medium | Dead code and feature coupling remain. |
| PERF-01 | Every dashboard refresh fetches six datasets regardless of active tab. | `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-425` | High | Overview loads bookings, inbox, pending items, and management data even when hidden. |
| PERF-02 | Broad `watch`/`Consumer` usage rebuilds large parts of the dashboard for small state changes. | `lib/features/dashboard/view/dashboard_screen.dart:87-94`, `lib/features/dashboard/view/tabs/overview_tab.dart:24-25`, `lib/features/dashboard/view/tabs/bookings_tab.dart:15-17`, `lib/features/dashboard/view/tabs/work_tab.dart:34-39`, `lib/features/dashboard/view/tabs/inbox_tab.dart:109-112`, `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart:15-18`, `lib/features/dashboard/view/widgets/next_actions_list.dart:13-18`, `lib/features/dashboard/view/widgets/activity_feed_preview.dart:17-19`, `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart:14-18` | Medium | Rebuild scope is larger than the mutated state. |
| TEST-01 | Existing dashboard tests cover shell tabs, permission mapping, a narrow work-tab review state, booking-card labels, and cache serialization only. | `test/widget/dashboard/dashboard_screen_test.dart:42-88`, `test/widget/dashboard/work_tab_test.dart:80-125`, `test/widget/dashboard/booking_card_test.dart:56-108`, `test/unit/dashboard/dashboard_permission_service_test.dart:5-70`, `test/unit/core/dashboard_cache_service_test.dart:39-108` | High | Critical payment, cache injection, and transition flows are untested. |

## 3) Findings
### 3.1 Security (Highest Priority)
- `SEC-01` File Reference: `supabase/migrations/20260225_create_wallet_views.sql:161-255`, `supabase/migrations/20260225_create_wallet_views.sql:412-430`, `lib/features/dashboard/data/dashboard_repository.dart:316-386`. Impact: platform-wide financial metrics are reachable from client code, and the migration explicitly grants those views to `authenticated` even though the comment says they should be service-role/admin only. Exploit/Failure scenario: any authenticated client build path or debug shell that reaches `DashboardRepository.fetchFinancialMetrics()` or `fetchPeriodFinancialMetrics()` can read platform GMV, revenue, escrow, and refund totals.
- `SEC-02` File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:753-879`, `lib/features/tasks/services/task_service.dart:184-212`, `lib/features/booking/services/booking_service.dart:117-143`, `Sline_everything/SUPABASE_SETUP.md:1019-1027`, `Sline_everything/SUPABASE_SETUP.md:1071-1078`. Impact: dashboard write authorization depends on broad row-level ownership/involvement checks, not a server-side transition contract. Exploit/Failure scenario: an involved user can bypass dashboard UX and issue direct updates for task or booking rows that jump to disallowed states.
- `SEC-03` File Reference: `lib/features/dashboard/data/dashboard_repository.dart:139-143`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`. Impact: cross-user profile reads expose `bio`, `active_role`, `skills`, `created_at`, and `seller_level` even though the dashboard only consumes `full_name` and `avatar_url`. Exploit/Failure scenario: any caller with access to the RPC can fetch a broader user profile dataset than this feature requires.
- `SEC-04` File Reference: `Sline_everything/SUPABASE_SETUP.md:934-986`. Impact: authorization behavior for `vw_unified_work_items` is `UNVERIFIED` from repository SQL because only documentation, not a migration, is present. Exploit/Failure scenario: docs and deployed SQL drift, and the dashboard silently trusts a view contract that is no longer enforced in the database.

### 3.2 Data Integrity
- `INT-01` File Reference: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:518-569`, `lib/features/tasks/services/task_service.dart:731-759`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:107-160`. Impact: the current tender happy path is internally inconsistent; award creates `accepted/unpaid`, then pay calls an escrow-hold branch that only accepts `pending/unpaid`. Exploit/Failure scenario: a client awards an offer successfully, then the follow-up payment fails because the ledger gate rejects the already-awarded status.
- `INT-02` File Reference: `lib/features/wallet/services/ledger_service.dart:21-57`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:52-69`, `lib/features/tasks/services/task_service.dart:752-775`. Impact: business-rule failures from `process_payment_event_ledger` can be treated as success because the client only throws on SQL exceptions, not on `{ok:false}` payloads. Exploit/Failure scenario: escrow hold is rejected for insufficient funds or status mismatch, but `TaskService.payAwardedOffer()` still advances to `pay_awarded_offer`, creating task/request state drift without a posted ledger entry.
- `INT-03` File Reference: `lib/features/dashboard/view/widgets/booking_card.dart:236-263`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:753-773`, `lib/features/booking/services/booking_service.dart:117-143`, `lib/features/booking/services/booking_service.dart:189-245`. Impact: confirmed booking cancellation can bypass the refund/release flow entirely and mutate only the booking status row. Exploit/Failure scenario: a client taps `Cancel` on a confirmed booking, the row becomes canceled, and no corresponding ledger reversal runs.
- `INT-04` File Reference: `lib/features/tasks/services/task_service.dart:818-856`. Impact: the dashboard's pending-payment tender data source does not match its own documented intent. Exploit/Failure scenario: freelancers see empty or incorrect pending-payment sections because the query filters `status = 'open'` while the comments describe assigned or payment-pending work.
- `INT-05` File Reference: `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart:15-24`, `lib/features/wallet/viewmodels/wallet_view_model.dart:19-49`, `lib/features/wallet/view/wallet_screen.dart:21-25`. Impact: overview wallet state can remain at zero even when the ledger has real balances because the dashboard path never loads the wallet. Exploit/Failure scenario: a user lands on dashboard overview after login and sees a zero snapshot until they manually visit the wallet screen.

### 3.3 Architecture
- `ARC-01` File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:24-964`. Impact: a single `ChangeNotifier` now spans role sync, cache wiring, tab state, work bucketing, bookings, inbox, tender payment orchestration, and management data. Exploit/Failure scenario: small feature changes create cross-feature regressions because one state container owns unrelated responsibilities.
- `ARC-02` File Reference: `lib/features/tasks/view/tender_payment_screen.dart:39-50`. Impact: the tender payment UI violates the project MVVM boundary by constructing `QiCardPaymentService` and `TaskService` directly in the view. Exploit/Failure scenario: payment logic becomes hard to test, hard to mock, and easy to fork across screens.
- `ARC-03` File Reference: `lib/main.dart:167-180`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33-52`. Impact: the cache service is registered but never injected into the active dashboard view model instance. Exploit/Failure scenario: repository reads stay cold-start only, while cache code appears active in the class but is dead in production wiring.
- `ARC-04` File Reference: `lib/features/profile/view/my_services_screen.dart:14-17`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:111-116`. Impact: the profile feature reads service state through the dashboard view model instead of a services-owned abstraction. Exploit/Failure scenario: dashboard refactors break unrelated profile screens.
- `ARC-05` File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:554-651`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:115-169`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:127-167`. Impact: award/pay orchestration is duplicated in two feature stacks and both launch the same payment screen. Exploit/Failure scenario: one flow gets fixed while the other continues using stale state sequencing.

### 3.4 Code Quality
- `QUAL-01` File Reference: `lib/features/dashboard/view/widgets/work_item_card.dart:234-253`, `test/unit/dashboard/dashboard_permission_service_test.dart:7-18`. Impact: the UI hides the primary action for `startWork` even though the permission layer explicitly marks confirmed freelancer bookings as startable. Exploit/Failure scenario: a valid work item has no visible CTA to begin work from the Work tab.
- `QUAL-02` File Reference: `lib/features/dashboard/view/widgets/work_item_card.dart:29-78`, `lib/features/dashboard/view/widgets/booking_card.dart:51-86`, `lib/features/dashboard/view/widgets/offer_card.dart:349-359`. Impact: raw status label/color rules are duplicated across cards instead of coming from one domain formatter. Exploit/Failure scenario: the same backend status renders differently in different dashboard sections after future edits.
- `QUAL-03` File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:122-158`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:182-186`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:747-750`, `lib/features/dashboard/view/tabs/bookings_tab.dart:21-60`. Impact: `bookingFilter`, `inboxGroupedByTask`, `pendingRequests`, and `pendingPaymentTenders` add live state and fetches that the current dashboard surface does not consume. Exploit/Failure scenario: dead state continues to accumulate and obscures what is actually required by the UI.
- `QUAL-04` File Reference: `lib/features/dashboard/view/tabs/manage_tab.dart:10-83`, `lib/features/dashboard/view/widgets/manage_service_list.dart:94-109`, `lib/features/dashboard/view/widgets/manage_task_list.dart:94-109`, `lib/features/dashboard/view/dashboard_screen.dart:124-149`. Impact: removed Manage-tab code remains in the repo, and its widgets still contain TODO-only actions. Exploit/Failure scenario: dead files mislead future work and reintroduce partially implemented UI by accident.
- `QUAL-05` File Reference: `lib/features/dashboard/view/tabs/inbox_tab.dart:131-148`, `lib/features/dashboard/view/widgets/booking_card.dart:239-243`. Impact: unsupported states are hidden behind no-op callbacks and TODOs rather than explicit disabled UI or error states. Exploit/Failure scenario: regressions ship silently because the app does not expose an actionable failure when state handling is incomplete.

### 3.5 Performance
- `PERF-01` File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-425`. Impact: every dashboard refresh downloads work items, activity, bookings, inbox offers, pending items, and management data in one batch regardless of which tab the user opened. Exploit/Failure scenario: opening Overview pays the cost of hidden Bookings/Inbox/Manage queries and slows time-to-first-content.
- `PERF-02` File Reference: `lib/features/dashboard/view/dashboard_screen.dart:87-94`, `lib/features/dashboard/view/tabs/overview_tab.dart:24-25`, `lib/features/dashboard/view/tabs/bookings_tab.dart:15-17`, `lib/features/dashboard/view/tabs/work_tab.dart:34-39`, `lib/features/dashboard/view/tabs/inbox_tab.dart:109-112`, `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart:15-18`, `lib/features/dashboard/view/widgets/next_actions_list.dart:13-18`, `lib/features/dashboard/view/widgets/activity_feed_preview.dart:17-19`, `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart:14-18`. Impact: broad provider subscriptions expand rebuild scope for unrelated state changes. Exploit/Failure scenario: toggling one inbox or loading flag rebuilds overview widgets, counters, and work lists.
- `PERF-03` File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:580-600`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:776-809`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:871-872`. Impact: post-mutation refreshes often reload the entire dashboard instead of patching local state. Exploit/Failure scenario: a single booking accept or offer payment triggers a full screen data fan-out and multiplies backend load.
- `PERF-04` File Reference: `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart:15-24`, `lib/features/wallet/viewmodels/wallet_view_model.dart:21-49`. Impact: wallet snapshot reads a separate provider with no ownership for initial load, producing stale zero state and extra rebuilds once the wallet eventually loads elsewhere. Exploit/Failure scenario: overview renders once with zero values, then repaints later when an unrelated wallet screen loads data.

### 3.6 Testing Gaps
- `TEST-01` File Reference: `test/widget/dashboard/dashboard_screen_test.dart:42-88`, `test/widget/dashboard/work_tab_test.dart:80-125`, `test/widget/dashboard/booking_card_test.dart:56-108`, `test/unit/dashboard/dashboard_permission_service_test.dart:5-70`, `test/unit/core/dashboard_cache_service_test.dart:39-108`. Impact: the current suite only verifies shell tabs, narrow card labels, permission mapping, and cache serialization. Exploit/Failure scenario: critical workflow regressions in award/payment, cache injection, or state transitions are not caught before merge.
- `TEST-02` File Reference: `lib/features/tasks/services/task_service.dart:710-783`, `lib/features/tasks/view/tender_payment_screen.dart:56-109`, `lib/features/wallet/services/ledger_service.dart:21-57`. Impact: there are no targeted tests for the tender payment happy path, deadline expiry, ledger rejection, or `{ok:false}` handling. Exploit/Failure scenario: the current payment mismatch reaches production without automated detection.
- `TEST-03` File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:753-879`, `lib/features/dashboard/view/widgets/work_item_card.dart:234-253`, `lib/features/dashboard/view/tabs/inbox_tab.dart:21-105`. Impact: dashboard direct status mutations and primary CTA rendering are untested. Exploit/Failure scenario: start-work, cancel, pay-now, and no-op action regressions ship silently.
- `TEST-04` File Reference: `lib/main.dart:167-182`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33-52`, `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart:14-24`. Impact: there is no test proving the app-level DI wiring activates dashboard cache behavior or initializes the wallet snapshot from dashboard entry. Exploit/Failure scenario: the code appears to support cache/SWR and snapshot loading while production wiring does not.

## 4) Dead/Unused Code Candidates
- `lib/features/dashboard/view/tabs/manage_tab.dart` is a dead UI surface because `DashboardScreen` now mounts only `OverviewTab`, `BookingsTab`, `WorkTab`, and `InboxTab`. File Reference: `lib/features/dashboard/view/dashboard_screen.dart:123-149`, `lib/features/dashboard/view/tabs/manage_tab.dart:10-83`. Why likely unused: no live tab registration remains. How to confirm: remove the file and run `flutter analyze`.
- `lib/features/dashboard/view/widgets/manage_service_list.dart` and `lib/features/dashboard/view/widgets/manage_task_list.dart` are only imported by the dead `ManageTab`. File Reference: `lib/features/dashboard/view/tabs/manage_tab.dart:7-8`, `lib/features/dashboard/view/widgets/manage_service_list.dart:9-136`, `lib/features/dashboard/view/widgets/manage_task_list.dart:9-115`. Why likely unused: no other dashboard surface imports them. How to confirm: remove both files and run `rg -n "ManageServiceList|ManageTaskList" lib test`.
- `lib/features/dashboard/data/mock/mock_dashboard_repository.dart` and `lib/features/dashboard/models/activity_item.dart` appear unused outside the mock path itself. File Reference: `lib/features/dashboard/data/mock/mock_dashboard_repository.dart:1-139`, `lib/features/dashboard/models/activity_item.dart:1-21`. Why likely unused: no production or test references were found beyond the mock file. How to confirm: run `rg -n "MockDashboardRepository|ActivityItem" lib test`.
- `DashboardViewModel.bookingFilter`, `setBookingFilter`, `inboxGroupedByTask`, `pendingRequests`, and `pendingPaymentTenders` are dead-state candidates in the current dashboard UI. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:122-158`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:182-186`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:413-415`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:747-750`, `lib/features/dashboard/view/tabs/bookings_tab.dart:21-60`. Why likely unused: the live tabs read `vm.bookings` and `vm.inboxOffers` directly. How to confirm: remove each field one at a time and run `flutter analyze`.
- `DashboardRepository.fetchFinancialMetrics`, `fetchPeriodFinancialMetrics`, `fetchWalletBalances`, `fetchClientAwardedUnpaidOffers`, and `fetchFreelancerAwardedUnpaidOffers` are unused-method candidates. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:316-477`. Why likely unused: no audited dashboard view or view model calls these methods. How to confirm: run `rg -n "fetchFinancialMetrics\\(|fetchPeriodFinancialMetrics\\(|fetchWalletBalances\\(|fetchClientAwardedUnpaidOffers\\(|fetchFreelancerAwardedUnpaidOffers\\(" lib test`.

## 5) Duplicate Code Candidates
- Award/pay orchestration is duplicated between dashboard and task-request flows. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:554-651`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:115-169`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:127-167`. Proposed shared abstraction: create `lib/features/tasks/services/tender_payment_coordinator.dart` and move award/pay sequencing there.
- Tender payment screen launching is duplicated in `InboxTab` and `RequestsListScreen`. File Reference: `lib/features/dashboard/view/tabs/inbox_tab.dart:36-58`, `lib/features/dashboard/view/tabs/inbox_tab.dart:86-105`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:139-156`. Proposed shared abstraction: create `lib/features/tasks/view/navigation/tender_payment_launcher.dart`.
- Status presentation logic is duplicated across work, booking, and offer cards. File Reference: `lib/features/dashboard/view/widgets/work_item_card.dart:29-78`, `lib/features/dashboard/view/widgets/booking_card.dart:51-86`, `lib/features/dashboard/view/widgets/offer_card.dart:349-359`. Proposed shared abstraction: create `lib/features/dashboard/presentation/status_presentation.dart` or move domain-specific formatters into booking/task features.
- Awarded-unpaid-offer access is duplicated between `DashboardRepository` and `TaskService`. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:436-477`, `lib/features/tasks/services/task_service.dart:785-813`. Proposed shared abstraction: keep these RPC wrappers only in `TaskService` and remove them from `DashboardRepository`.

## 6) Refactor Plan (Exact Paths)
- Split `lib/features/dashboard/viewmodels/dashboard_view_model.dart` into:
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart` as a thin facade for Provider compatibility
  - `lib/features/dashboard/viewmodels/dashboard_role_view_model.dart`
  - `lib/features/dashboard/viewmodels/dashboard_overview_view_model.dart`
  - `lib/features/dashboard/viewmodels/dashboard_work_view_model.dart`
  - `lib/features/dashboard/viewmodels/dashboard_inbox_view_model.dart`
  - `lib/features/dashboard/viewmodels/dashboard_management_view_model.dart`
- Split `lib/features/dashboard/data/dashboard_repository.dart` into:
  - `lib/features/dashboard/data/dashboard_work_repository.dart`
  - `lib/features/dashboard/data/dashboard_activity_repository.dart`
  - `lib/features/dashboard/data/dashboard_profile_repository.dart`
  - `lib/features/dashboard/data/dashboard_admin_metrics_repository.dart`
- Move domain-owned widgets out of dashboard:
  - `lib/features/dashboard/view/widgets/booking_card.dart` -> `lib/features/booking/view/widgets/dashboard_booking_card.dart`
  - `lib/features/dashboard/view/widgets/offer_card.dart` -> `lib/features/tasks/view/widgets/dashboard_offer_card.dart`
  - `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart` -> `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`
- Extract tender payment logic from the view:
  - add `lib/features/tasks/viewmodels/tender_payment_view_model.dart`
  - add `lib/features/tasks/services/tender_payment_coordinator.dart`
  - keep `lib/features/tasks/view/tender_payment_screen.dart` as a thin view bound to the new view model
- Remove dead files after compatibility cleanup:
  - delete `lib/features/dashboard/view/tabs/manage_tab.dart`
  - delete `lib/features/dashboard/view/widgets/manage_service_list.dart`
  - delete `lib/features/dashboard/view/widgets/manage_task_list.dart`
  - delete `lib/features/dashboard/data/mock/mock_dashboard_repository.dart`
  - delete `lib/features/dashboard/models/activity_item.dart`
- Remove cross-feature dashboard coupling:
  - stop using `DashboardViewModel` inside `lib/features/profile/view/my_services_screen.dart`
  - add `lib/features/services/viewmodels/my_services_view_model.dart`
- Migration strategy:
  - keep `lib/features/dashboard/viewmodels/dashboard_view_model.dart` as a wrapper for one release while widgets are moved to the new feature-owned paths
  - add temporary re-export files for moved widgets if route churn must be minimized
  - delete wrapper exports only after `flutter analyze` and dashboard/widget tests pass

## 7) Fix Plan (Phases)
### Phase 1: Critical security & correctness
- What to change: restrict finance-view access so authenticated clients cannot read platform-wide metrics directly.
  - Exact file(s) to edit/create: edit `lib/features/dashboard/data/dashboard_repository.dart`; create `supabase/migrations/20260301_restrict_dashboard_finance_views.sql`
  - Acceptance criteria: `vw_financial_metrics_realtime` and `vw_financial_metrics_period` are not directly readable by non-admin authenticated users, and dashboard client code no longer exposes those reads.
- What to change: replace direct dashboard task/booking status updates with server-authoritative RPCs that validate actor, current status, and next status.
  - Exact file(s) to edit/create: edit `lib/features/dashboard/viewmodels/dashboard_view_model.dart`, `lib/features/tasks/services/task_service.dart`, `lib/features/booking/services/booking_service.dart`; create `supabase/migrations/20260301_add_dashboard_transition_rpcs.sql`
  - Acceptance criteria: dashboard no longer calls raw `update()` for task/booking workflow transitions, and unauthorized status jumps fail server-side even if a client bypasses the UI.
- What to change: repair the tender payment state machine and make ledger failures terminal for the client path.
  - Exact file(s) to edit/create: edit `lib/features/wallet/services/ledger_service.dart`, `lib/features/tasks/services/task_service.dart`, `lib/features/tasks/view/tender_payment_screen.dart`; create `supabase/migrations/20260301_fix_tender_payment_state_machine.sql`
  - Acceptance criteria: award -> pay succeeds once on the happy path, ledger `{ok:false}` stops the flow, and task/task-request state does not advance without a successful ledger event.
- What to change: remove direct confirmed-booking cancel mutations that bypass refund/release logic.
  - Exact file(s) to edit/create: edit `lib/features/dashboard/view/widgets/booking_card.dart`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart`, `lib/features/booking/services/booking_service.dart`; create `supabase/migrations/20260301_add_booking_cancel_rpc.sql`
  - Acceptance criteria: canceling a confirmed booking either executes the correct refund/cancel RPC or is blocked with a user-visible error.
- What to change: shrink `rpc_get_profile_summaries` to the minimum field set required by dashboard/profile preview consumers.
  - Exact file(s) to edit/create: edit `lib/features/dashboard/data/dashboard_repository.dart`, `lib/features/profile/services/profile_summary_service.dart`; create `supabase/migrations/20260301_shrink_rpc_get_profile_summaries.sql`
  - Acceptance criteria: dashboard still renders counterparty names/avatars, and the RPC no longer returns unused fields unless another audited caller proves they are required.

### Phase 2: Refactor/structure
- What to change: split the dashboard view model by responsibility and keep a temporary facade at the existing path.
  - Exact file(s) to edit/create: edit `lib/features/dashboard/viewmodels/dashboard_view_model.dart`; create `lib/features/dashboard/viewmodels/dashboard_role_view_model.dart`, `lib/features/dashboard/viewmodels/dashboard_overview_view_model.dart`, `lib/features/dashboard/viewmodels/dashboard_work_view_model.dart`, `lib/features/dashboard/viewmodels/dashboard_inbox_view_model.dart`, `lib/features/dashboard/viewmodels/dashboard_management_view_model.dart`
  - Acceptance criteria: each new view model has one bounded responsibility, and the shell dashboard provider remains backward compatible during migration.
- What to change: activate or remove dormant cache logic by wiring `DashboardCacheService` into the actual dashboard provider.
  - Exact file(s) to edit/create: edit `lib/main.dart`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
  - Acceptance criteria: the dashboard either uses cache paths in production wiring or the dead cache code is deleted; no fake cache hooks remain.
- What to change: move booking/offer/wallet presentation widgets into their owning features and replace status formatting duplication with shared presenters.
  - Exact file(s) to edit/create: move `lib/features/dashboard/view/widgets/booking_card.dart`, `lib/features/dashboard/view/widgets/offer_card.dart`, `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart`; create `lib/features/dashboard/presentation/status_presentation.dart`
  - Acceptance criteria: dashboard imports feature-owned widgets, and status labels/colors come from one formatter per domain.
- What to change: delete dead Manage-tab code and remove dashboard-owned service state from profile screens.
  - Exact file(s) to edit/create: delete `lib/features/dashboard/view/tabs/manage_tab.dart`, `lib/features/dashboard/view/widgets/manage_service_list.dart`, `lib/features/dashboard/view/widgets/manage_task_list.dart`, `lib/features/dashboard/data/mock/mock_dashboard_repository.dart`, `lib/features/dashboard/models/activity_item.dart`; edit `lib/features/profile/view/my_services_screen.dart`; create `lib/features/services/viewmodels/my_services_view_model.dart`
  - Acceptance criteria: no live feature depends on removed dashboard management files, and profile/service screens no longer require `DashboardViewModel`.

### Phase 3: Tests
- What to change: add unit coverage for dashboard orchestration, cache injection, and direct transition guards.
  - Exact file(s) to edit/create: create `test/unit/dashboard/dashboard_view_model_test.dart`, `test/unit/dashboard/dashboard_cache_injection_test.dart`, `test/unit/booking/booking_service_transition_test.dart`, `test/unit/tasks/task_service_pay_awarded_offer_test.dart`
  - Acceptance criteria: tests fail on raw direct-update regressions, cache wiring regressions, and tender-payment sequencing regressions.
- What to change: add widget coverage for inbox pay-now, tender payment, wallet snapshot, and missing CTAs.
  - Exact file(s) to edit/create: create `test/widget/dashboard/inbox_tab_test.dart`, `test/widget/tasks/tender_payment_screen_test.dart`, `test/widget/dashboard/wallet_snapshot_card_test.dart`, `test/widget/dashboard/work_item_card_test.dart`
  - Acceptance criteria: award/pay-now flows, start-work CTA visibility, and overview wallet initialization are asserted in widget tests.
- What to change: add SQL contract checks for dashboard RLS/view permissions.
  - Exact file(s) to edit/create: create `supabase/tests/dashboard_security_contract.sql`, `supabase/tests/dashboard_payment_contract.sql`
  - Acceptance criteria: CI or manual SQL execution proves finance-view access restrictions, payment-RPC sequencing, and transition RPC guards.

### Phase 4: Polish/perf
- What to change: lazy-load data per active dashboard tab instead of doing a six-query fan-out on every refresh.
  - Exact file(s) to edit/create: edit `lib/features/dashboard/viewmodels/dashboard_overview_view_model.dart`, `lib/features/dashboard/viewmodels/dashboard_work_view_model.dart`, `lib/features/dashboard/viewmodels/dashboard_inbox_view_model.dart`, `lib/features/dashboard/viewmodels/dashboard_management_view_model.dart`, `lib/features/dashboard/view/dashboard_screen.dart`
  - Acceptance criteria: opening Overview does not fetch hidden Bookings/Inbox/Manage datasets.
- What to change: replace broad provider watches with narrower selectors or feature-scoped consumers.
  - Exact file(s) to edit/create: edit `lib/features/dashboard/view/dashboard_screen.dart`, `lib/features/dashboard/view/tabs/overview_tab.dart`, `lib/features/dashboard/view/tabs/bookings_tab.dart`, `lib/features/dashboard/view/tabs/work_tab.dart`, `lib/features/dashboard/view/tabs/inbox_tab.dart`, `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart`, `lib/features/dashboard/view/widgets/next_actions_list.dart`, `lib/features/dashboard/view/widgets/activity_feed_preview.dart`, `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`
  - Acceptance criteria: role changes, inbox refreshes, and loading flags rebuild only the widgets that depend on that state slice.
- What to change: patch local dashboard state after successful mutations instead of full refreshes where safe.
  - Exact file(s) to edit/create: edit `lib/features/dashboard/viewmodels/dashboard_work_view_model.dart`, `lib/features/dashboard/viewmodels/dashboard_inbox_view_model.dart`, `lib/features/dashboard/viewmodels/dashboard_overview_view_model.dart`
  - Acceptance criteria: common actions such as accept, pay, and refund do not require a full dashboard reload unless the affected section changed globally.
- What to change: make wallet snapshot own an explicit initialization contract.
  - Exact file(s) to edit/create: edit `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`, `lib/features/wallet/viewmodels/wallet_view_model.dart`, `lib/features/dashboard/view/tabs/overview_tab.dart`
  - Acceptance criteria: dashboard overview shows real wallet balances on first entry without requiring the wallet screen to be opened first.

## 8) Verification Checklist
### Commands
- `flutter analyze`
- `flutter test test/widget/dashboard test/unit/dashboard test/unit/core/dashboard_cache_service_test.dart`
- `flutter test test/widget/tasks/tender_payment_screen_test.dart test/unit/tasks/task_service_pay_awarded_offer_test.dart test/unit/booking/booking_service_transition_test.dart`
- `rg -n "fetchFinancialMetrics\\(|fetchPeriodFinancialMetrics\\(|fetchWalletBalances\\(|fetchClientAwardedUnpaidOffers\\(|fetchFreelancerAwardedUnpaidOffers\\(" lib/features/dashboard`
- `rg -n "updateTaskStatus\\(|updateBookingStatus\\(" lib/features/dashboard lib/features/tasks lib/features/booking`
- `rg -n "ManageTab|ManageServiceList|ManageTaskList|MockDashboardRepository|ActivityItem|bookingFilter|inboxGroupedByTask|pendingPaymentTenders" lib test`

### Manual Scenarios
- Scenario 1: launch the app into dashboard overview as a client and verify only the four live tabs render, wallet snapshot loads real balances, and opening Overview does not require visiting Wallet first. File Reference: `lib/app/main_navigation_screen.dart:39-51`, `lib/features/dashboard/view/tabs/overview_tab.dart:28-69`, `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart:26-70`
- Scenario 2: as a client, award a pending offer from Inbox, land on tender payment, complete payment, and verify the offer moves from `accepted/unpaid` to `held`, the task moves to active work only after ledger success, and dashboard refreshes correctly on return. File Reference: `lib/features/dashboard/view/tabs/inbox_tab.dart:30-58`, `lib/features/tasks/view/tender_payment_screen.dart:72-109`, `lib/features/tasks/services/task_service.dart:729-783`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:573-649`
- Scenario 3: force a ledger rejection (`insufficient funds`, expired deadline, or wrong status) and verify the app stops before `pay_awarded_offer` mutates task/request state. File Reference: `lib/features/wallet/services/ledger_service.dart:21-57`, `lib/features/tasks/services/task_service.dart:745-775`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:151-218`
- Scenario 4: as a provider, open a `paid_request_pending` booking and verify accept/decline follow server-backed transitions only; as a client, attempt to cancel a confirmed booking and verify refund/cancel rules are enforced rather than a raw status update. File Reference: `lib/features/dashboard/view/widgets/booking_card.dart:183-266`, `lib/features/booking/services/booking_service.dart:189-312`
- Scenario 5: as a freelancer, verify a confirmed/startable work item actually shows a visible CTA to start work. File Reference: `lib/features/dashboard/view/widgets/work_item_card.dart:234-253`, `test/unit/dashboard/dashboard_permission_service_test.dart:7-18`

### Supabase/RLS Contract Checks
- Finance-view contract: verify non-admin authenticated users no longer have direct `SELECT` on `vw_financial_metrics_realtime` or `vw_financial_metrics_period`.
  - SQL:
    ```sql
    select table_name, grantee, privilege_type
    from information_schema.role_table_grants
    where table_schema = 'public'
      and table_name in ('vw_financial_metrics_realtime', 'vw_financial_metrics_period')
    order by table_name, grantee;
    ```
  - Expected: `authenticated` is absent, or reads are routed through a locked-down admin RPC.
  - Current repo contract reference: `supabase/migrations/20260225_create_wallet_views.sql:412-430`
- Transition contract: verify dashboard writes use RPCs with explicit actor/current/next-status checks instead of raw row updates.
  - SQL:
    ```sql
    select proname
    from pg_proc
    where pronamespace = 'public'::regnamespace
      and proname in (
        'pay_awarded_offer',
        'award_task_offer',
        'rpc_dashboard_update_task_status',
        'rpc_dashboard_update_booking_status'
      )
    order by proname;
    ```
  - Expected: dashboard-specific transition RPCs exist, and the client no longer relies on `tasks_update_involved` / `bookings_update_status_only` as the only workflow guard.
  - Current repo contract reference: `Sline_everything/SUPABASE_SETUP.md:1019-1027`, `Sline_everything/SUPABASE_SETUP.md:1071-1078`
- Tender payment contract: verify award status, ledger gate, and pay RPC agree on the same state machine.
  - SQL:
    ```sql
    select pg_get_functiondef('public.award_task_offer(uuid,uuid)'::regprocedure);
    select pg_get_functiondef('public.pay_awarded_offer(uuid,uuid)'::regprocedure);
    select pg_get_functiondef('public.process_payment_event_ledger(text,text,uuid,text,numeric,text,jsonb)'::regprocedure);
    ```
  - Expected: award output status and ledger preconditions line up, and ledger failures do not allow follow-up state mutation.
  - Current repo contract reference: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:472-649`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:4-260`
- Profile-summary contract: verify the summary RPC only returns the minimum approved fields.
  - SQL:
    ```sql
    select pg_get_functiondef('public.rpc_get_profile_summaries(uuid[])'::regprocedure);
    ```
  - Expected: returned columns match the minimal dashboard/profile-preview requirement.
  - Current repo contract reference: `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`

## 9) Risks & Rollback Notes
- Finance-view permission changes can break any internal admin reporting that currently depends on direct client access. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:316-386`, `supabase/migrations/20260225_create_wallet_views.sql:412-430`. Rollback: restore the prior grants and repository methods together if an internal admin UI still depends on them.
- Tender payment changes touch money movement and work activation in the same flow. File Reference: `lib/features/tasks/services/task_service.dart:729-783`, `lib/features/tasks/view/tender_payment_screen.dart:72-109`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:518-649`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:107-260`. Rollback: revert the new payment-state migration and restore the previous client/service sequencing only after reconciling affected `task_requests` rows.
- Splitting `DashboardViewModel` can break both dashboard widgets and profile/service screens that currently depend on dashboard-owned fields. File Reference: `lib/features/dashboard/view/dashboard_screen.dart:87-149`, `lib/features/dashboard/view/tabs/overview_tab.dart:24-67`, `lib/features/profile/view/my_services_screen.dart:14-17`. Rollback: keep a compatibility facade at `lib/features/dashboard/viewmodels/dashboard_view_model.dart` until all callers are migrated.
- `vw_unified_work_items` deployment parity is `UNVERIFIED` because the repo contains documentation but not a matching migration. File Reference: `Sline_everything/SUPABASE_SETUP.md:934-986`. Rollback: do not change dashboard authorization assumptions for that view until the actual deployed definition is exported and checked into `supabase/migrations`.
