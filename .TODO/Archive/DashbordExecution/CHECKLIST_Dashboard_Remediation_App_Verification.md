# Dashboard Remediation – Implementation Status & App Verification Checklist

**Plan**: Dashboard Full Remediation v2  
**Execution log**: `.TODO/EXECUTION_LOG_Dashboard_Full_Remediation_v2_2026-03-01.md`

---

## 1) Was the plan fully implemented?

**Partially.** Core security, tender payment MVVM, finance boundary, dead-code removal, and test infra are done. The following were **not** implemented in the last run:

| Area | Status | Notes |
|------|--------|------|
| **Dashboard ViewModel split** | Not done | Plan called for `dashboard_role_view_model`, `dashboard_overview_view_model`, `dashboard_bookings_view_model`, `dashboard_work_view_model`, `dashboard_inbox_view_model`; current code still has a single `DashboardViewModel`. |
| **Cache wiring** | Not done | `DashboardCacheService` is still not injected into `DashboardViewModel`; cache paths are dormant. |
| **MyServicesScreen ownership** | Not done | Still uses dashboard-owned state; no `lib/features/services/viewmodels/my_services_view_model.dart`. |
| **Wallet snapshot on first entry** | Not done | No explicit “load wallet when dashboard overview opens” contract. |
| **Widget moves** | Not done | `booking_card`, `offer_card`, `wallet_snapshot_card` still live under dashboard; not moved to booking/tasks/wallet features. |
| **Lazy-load by tab** | Not done | Dashboard still fetches all six datasets on refresh regardless of active tab. |
| **Shared status presentation** | Not done | No shared status presenter; cards still have their own label/color logic. |
| **Transition RPCs** | Not done | No new server RPCs for task/booking transitions; client still uses existing services. |
| **Profile-summary minimal RPC** | Not done | No migration or versioned RPC for minimal profile summary. |
| **Docs sync** | Not done | DEVELOPER_GUIDE, SUPABASE_SETUP, MVP_ROADMAP not updated for dashboard/tender changes. |

**Implemented:**

- Phase 0 artifacts (TEST_INFRA, FIXTURES, contracts, threat model, migration/reconciliation docs, checklists).
- Finance boundary: migration revoking `SELECT` on finance views from `authenticated`; repository no longer exposes `fetchFinancialMetrics` / `fetchPeriodFinancialMetrics`.
- Tender payment: single path via `TenderPaymentCoordinator` + `TenderPaymentViewModel`; `TenderPaymentScreen` uses ViewModel only (no services in widget); InboxTab and RequestsListScreen use coordinator.
- TaskService provided in `main.dart`; LedgerService already treats `{ok:false}` as terminal.
- Dead code removed: `manage_tab.dart`, `manage_service_list.dart`, `manage_task_list.dart`, `mock_dashboard_repository.dart`, `activity_item.dart`.
- AppLogger: TaskService `payAwardedOffer` start log; existing logs in DashboardViewModel, LedgerService, etc.
- RLS matrix and LIVE_SCAN (blocked) artifacts.
- Unit test: tender payment coordinator. Widget test: tender payment screen. Dashboard-related tests passing.

---

## 2) App verification checklist (what to check in the app)

Use this to verify the implemented parts in the running app and codebase.

### 2.1 Code / repo

- [ ] **No finance fetch in dashboard**  
  `rg "fetchFinancialMetrics|fetchPeriodFinancialMetrics" lib` → no matches.

- [ ] **Tender payment uses coordinator + ViewModel**  
  - `lib/features/tasks/services/tender_payment_coordinator.dart` exists.  
  - `lib/features/tasks/viewmodels/tender_payment_view_model.dart` exists.  
  - `lib/features/tasks/view/tender_payment_screen.dart` has no `TaskService()` or `QiCardPaymentService()` in the widget; it uses `Consumer<TenderPaymentViewModel>`.

- [ ] **TaskService in DI**  
  `lib/main.dart` has `Provider(create: (_) => TaskService())` (or equivalent).

- [ ] **Dead dashboard files removed**  
  - No `lib/features/dashboard/view/tabs/manage_tab.dart`.  
  - No `lib/features/dashboard/view/widgets/manage_service_list.dart`.  
  - No `lib/features/dashboard/view/widgets/manage_task_list.dart`.  
  - No `lib/features/dashboard/data/mock/mock_dashboard_repository.dart`.  
  - No `lib/features/dashboard/models/activity_item.dart`.

- [ ] **Finance views migration present**  
  `supabase/migrations/20260309_restrict_dashboard_finance_views.sql` exists and revokes `SELECT` on `vw_financial_metrics_realtime` and `vw_financial_metrics_period` from `authenticated`.

- [ ] **AppLogger (no print)**  
  In dashboard/tender/booking paths: `rg "print\\(" lib/features/dashboard lib/features/tasks/view/tender_payment lib/features/tasks/services/tender_payment` → no `print(` in those areas.

### 2.2 Build & tests

- [ ] **Analyze**  
  `flutter analyze` → no errors in dashboard/tender/booking touched files.

- [ ] **Dashboard + tender tests**  
  `flutter test test/widget/dashboard/ test/unit/dashboard/ test/unit/core/dashboard_cache_service_test.dart test/unit/tasks/tender_payment_coordinator_test.dart test/widget/tasks/tender_payment_screen_test.dart` → all pass.

- [ ] **Full test suite**  
  `flutter test` → all pass (optional but recommended).

### 2.3 In-app (manual)

- [ ] **Dashboard opens**  
  Open app → go to Dashboard → see 4 tabs: Overview, Bookings, Work, Inbox (no Manage).

- [ ] **Inbox → Award → Tender payment**  
  As client: Inbox → choose a pending offer → Award → navigate to “Complete Payment” screen → see task title, freelancer name, amount, deadline and Pay / Pay Later (no crash).

- [ ] **Pay path (if you have payment configured)**  
  On Tender Payment screen tap Pay → payment flow runs; on success, message and navigation back (or error message on failure).

- [ ] **Requests list → Award → Tender payment**  
  From task requests (tender flow): Award an offer → Tender Payment screen opens with correct data.

- [ ] **No platform finance metrics in UI**  
  Dashboard does not show platform-wide GMV/revenue/escrow (those reads were removed from the client).

### 2.4 Supabase (if you have DB access)

- [ ] **Finance view grants (after migration)**  
  Run:
  ```sql
  SELECT table_name, grantee, privilege_type
  FROM information_schema.role_table_grants
  WHERE table_schema = 'public'
    AND table_name IN ('vw_financial_metrics_realtime', 'vw_financial_metrics_period')
  ORDER BY table_name, grantee;
  ```
  After applying `20260309_restrict_dashboard_finance_views.sql`, `authenticated` should **not** have `SELECT` on these views.

---

## 3) Summary

- **Fully implemented:** Finance boundary (migration + repo), single tender payment path (coordinator + ViewModel), TenderPaymentScreen MVVM, TaskService in DI, dead dashboard/mock/activity_item removal, Phase 0 artifacts, RLS matrix, coordinator + tender screen tests, AppLogger in key paths.
- **Not implemented:** Dashboard ViewModel split, cache wiring, MyServices ownership, widget moves, lazy-load by tab, shared status presentation, transition RPCs, profile-summary minimal RPC, docs sync.

Use **Section 2** as your checklist to verify the current app and repo state.
