# Architect Full Review Report — 2026-03-02

**Scope:** Full_Review (entire codebase: lib/, direct_offers, dashboard, wallet, booking, migrations, and all features)  
**Plan reference:** Plan Missing — Risk Elevated. Proceeded with full scan; did not block on missing plan.  
**Constraints:** No code changes; analysis and report only. Strict MVVM. No breaking changes to other features.

---

## 1. Architecture and Logic Findings

### 1.1 MVVM Boundary Check

- **Violation (single instance):**  
  **`lib/features/direct_offers/view/direct_offer_details_screen.dart`** (line 40)  
  The View constructs `DirectOfferDetailsViewModel` and passes  
  `currentUserId: Supabase.instance.client.auth.currentUser?.id`.  
  **Rule:** Views must not reference `Supabase.instance` or call `.auth`, `.from()`, `.rpc()`, etc.  
  **Impact:** Direct Supabase usage in a feature View; weakens testability and breaks the documented “Views obtain data via ViewModels / context.read” contract.

- **All other feature views under `lib/features/*/view/`:**  
  Grep for `Supabase.instance` and `supabase.(from|rpc|auth|storage)` in `lib/**/view/**/*.dart` shows **no other matches**. Chat, dashboard, wallet, booking, and other feature views use `context.read<ViewModel>()` or `Consumer<ViewModel>` only.

- **App shell / main.dart:**  
  Uses `Supabase.instance.client` in provider factories and in `_AppWithAuthListener` for auth-based routing. This is app-level composition and auth gating, not a feature view; acceptable per project conventions.

### 1.2 Data Flow Map (Validated Paths)

| Domain / Concept              | Single source / query path | Location |
|-------------------------------|----------------------------|----------|
| Dashboard work items          | `DashboardRepository.fetchWorkItems()` → `vw_unified_work_items` + `_fetchDirectOffers()` + `_enrichWithProfiles()` | `lib/features/dashboard/data/dashboard_repository.dart` |
| Current user ID (dashboard)   | `DashboardViewModel.currentUserId` from `_repository.currentUser?.id` | `lib/features/dashboard/viewmodels/dashboard_view_model.dart` |
| Wallet balance                | `WalletRepository.getWalletBalance()` → `WalletService` → `vw_wallet_balances_user` | `lib/features/wallet/` |
| Wallet activity               | `WalletRepository.getActivity()` → `WalletService` → `vw_wallet_activity_user` | `lib/features/wallet/` |
| Ledger payment events         | `LedgerService.submitPaymentEvent()` → RPC `process_payment_event_ledger` | `lib/features/wallet/services/ledger_service.dart` |
| Direct offer CRUD + state     | `DirectOffersService` (create, accept, pay, deliver, complete) + ledger RPC | `lib/features/direct_offers/services/direct_offers_service.dart` |
| Booking list/detail           | `BookingRepository` → `BookingService` | `lib/features/booking/` |

- **N+1:** Dashboard uses batch profile enrichment (`_enrichWithProfiles` via `ProfileSummaryService.fetchByIds`); no async DB calls inside loops were found in the scanned lib code.
- **Duplicate query paths:** No duplicate “source of truth” for the same domain concept was identified; dashboard merges unified work items and direct offers in one repository method.

### 1.3 Path / Contract Validation

- **File paths and classes:**  
  Referenced files and class names exist:  
  `DirectOfferDetailsScreen`, `DirectOfferDetailsViewModel`, `DirectOffersService`, `DashboardRepository`, `DashboardViewModel`, `WalletRepository`, `WalletService`, `LedgerService`, `BookingRepository`, `BookingService`, `process_payment_event_ledger` (RPC), `direct_offers` (table), `vw_unified_work_items` (view).

- **Supabase objects (docs vs code vs migrations):**  
  - `direct_offers`: table and RLS in `supabase/migrations/20260303_direct_offers_table_rls_trigger.sql`; status/payment_status and columns align with `lib/features/direct_offers/models/direct_offer_model.dart`.  
  - `process_payment_event_ledger`: RPC present in migrations (e.g. `20260304_direct_offer_accept_then_pay.sql`, `20260307_fix_ledger_event_type_enum.sql`); called from `LedgerService` and edge functions.  
  - `vw_unified_work_items`, `wallet_balances`: documented in `Sline_everything/SUPABASE_SETUP.md`.  
  - Wallet app code uses `vw_wallet_balances_user` and `vw_wallet_activity_user`; these are documented in `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md`.

- **Feature folder vs docs:**  
  `lib/features/direct_offers/` exists (model, service, viewmodel, view) but is **not** listed in the “Current feature folders” list in `Sline_everything/STRUCTURE.md` (doc gap only).

---

## 2. Proposed Refactors (File Paths and Severity)

| # | Severity   | Description | File(s) / location |
|---|------------|-------------|--------------------|
| 1 | **High**   | Remove direct Supabase usage from View. Obtain `currentUserId` from a provider (e.g. `context.read<DashboardViewModel>().currentUserId` or a dedicated auth/session provider) and pass it into `DirectOfferDetailsViewModel`. When opened from deep link, the same context tree under `MainNavigationScreen` still has `DashboardViewModel` (and optionally `AuthViewModel`); ensure one of them exposes current user id so the View never touches Supabase. | `lib/features/direct_offers/view/direct_offer_details_screen.dart` |
| 2 | **Low**    | Optional: Tighten DI so ViewModels that today fall back to `Supabase.instance.client` (e.g. `DashboardViewModel`, `ChatViewModel`, `SavedTasksViewModel`) receive `SupabaseClient` via `context.read<SupabaseClient>()` or an explicit provider where the View creates the ViewModel. Reduces hidden dependencies; not blocking. | `lib/features/dashboard/viewmodels/dashboard_view_model.dart`, `lib/features/chat/viewmodels/chat_view_model.dart`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart`, and similar |
| 3 | **Doc**    | Add `direct_offers` to the “Current feature folders” list and, if desired, a one-line highlight in “Feature Highlights” in `Sline_everything/STRUCTURE.md` so the folder is discoverable and consistent with other features. | `Sline_everything/STRUCTURE.md` |

---

## 3. Evidence (Key Files and Scans Validated)

- **Documentation:**  
  - `Sline_everything/DEVELOPER_GUIDE.md` (system map, MVVM rules, feature map, direct chat offers flow).  
  - `Sline_everything/SUPABASE_SETUP.md` (tables, views, enums, RLS, ledger, `direct_offers`, `process_payment_event_ledger`).  
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md` (MVVM, data flow, current live notes).  
  - `Sline_everything/CODE_REVIEW.md` (guardrails, error handling, pagination).  
  - `Sline_everything/STRUCTURE.md` (lib layout, feature list, structure rules).  
  - `Sline_everything/MVP_ROADMAP.md` (status of dashboard, wallet, booking, direct offers).

- **Features (scanned):**  
  - **direct_offers:** `lib/features/direct_offers/models/direct_offer_model.dart`, `services/direct_offers_service.dart`, `viewmodels/direct_offer_details_view_model.dart`, `view/direct_offer_details_screen.dart`.  
  - **dashboard:** `lib/features/dashboard/data/dashboard_repository.dart`, `viewmodels/dashboard_view_model.dart`, `view/dashboard_screen.dart`; widgets under `view/widgets/`, `view/tabs/`.  
  - **wallet:** `lib/features/wallet/data/wallet_repository.dart`, `services/wallet_service.dart`, `services/ledger_service.dart`, `viewmodels/wallet_view_model.dart`, `view/`.  
  - **booking:** `lib/features/booking/data/booking_repository.dart`, `services/booking_service.dart`, `viewmodels/booking_view_model.dart`, `view/`.  
  - **chat:** `lib/features/chat/view/chat_screen.dart`, `viewmodels/chat_view_model.dart`, `services/message_service.dart`, `data/chat_repository.dart`.

- **Core / app:**  
  - `lib/main.dart` (providers, `DirectOffersService`, `PaymentService`, `DashboardViewModel`, auth listener).  
  - `lib/core/services/deep_link_service.dart` (navigation to `DirectOfferDetailsScreen`).

- **Migrations:**  
  - `supabase/migrations/20260303_direct_offers_table_rls_trigger.sql`, `20260303_direct_offer_ledger_rpc.sql`, `20260304_direct_offer_accept_then_pay.sql`, `20260305_gateway_escrow_direct_offer.sql`, `20260306_direct_offer_guard_accept_to_active.sql`, `20260307_fix_ledger_event_type_enum.sql`.

- **Grep / validation:**  
  - `Supabase.instance` / `supabase.(from|rpc|auth|storage)` in `lib/features` (all matches: services, data, viewmodels, or the single view violation above).  
  - Same pattern in `lib/**/view/**/*.dart`: only `direct_offer_details_screen.dart` (line 40).

---

## 4. Contract Mismatches and Missing Plan

- **Contract mismatches:**  
  No major contract mismatch found. Table/views/RPC used by app code are present in migrations and/or `SUPABASE_SETUP.md`; `DirectOffer` model aligns with `direct_offers` schema; ledger RPC and wallet views are documented and used consistently.

- **Missing plan:**  
  As stated, no plan file was referenced (Risk Elevated). This report does not block the pipeline on the missing plan alone; the only blocking-level finding is the MVVM violation in the direct_offers View, which should be fixed before or soon after merge.

---

## Pipeline Gate

**Pipeline gate: PROCEED**

- One **High**-severity refactor (remove Supabase from `direct_offer_details_screen.dart`) is recommended; it is a clear MVVM violation but does not constitute a DB or API contract break.  
- No major contract mismatch or missing DB/backend object was identified that would require blocking the pipeline.  
- Plan missing is noted; risk is elevated for future changes; recommend adding a small plan or task for the direct_offers View fix and optional DI/doc updates above.
