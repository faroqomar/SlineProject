# Architecture Guard Report: Tender Payment Flow

## Scope
- **Change Type**: MEDIUM (payment flow, MVVM boundaries)
- **Areas**: View / ViewModel / Service / MVVM
- **Files Reviewed**: 7 (tender_payment_screen, inbox_tab, offer_card, task_requests_view_model, dashboard_view_model, task_service, dashboard_repository)

## Checklist Verified

### 1. View files do not call Supabase.instance, SupabaseClient, raw HTTP, or heavy business logic
- **tender_payment_screen.dart**: ❌ **VIOLATION (fixed)** — Line 71 used `Supabase.instance.client.auth.currentUser?.id`
- **inbox_tab.dart**: ✅ Pass — Uses `Consumer<DashboardViewModel>`, delegates to VM
- **offer_card.dart**: ✅ Pass — Pure UI, callbacks only, no Supabase

### 2. Dependency direction: View → ViewModel → Service → Supabase
- **tender_payment_screen.dart**: ⚠️ **Partial** — Screen still instantiates `QiCardPaymentService` and `TaskService` directly and runs payment orchestration in `_processPayment()`. Ideal: introduce `TenderPaymentViewModel`.
- **inbox_tab.dart**: ✅ Pass — View → DashboardViewModel → TaskService
- **offer_card.dart**: ✅ Pass — View → callbacks (parent VM)

### 3. ViewModels extend ChangeNotifier, expose safe state, notifyListeners() on real changes
- **task_requests_view_model.dart**: ✅ Pass — Extends ChangeNotifier, `List.unmodifiable`, notifyListeners in try/finally
- **dashboard_view_model.dart**: ✅ Pass — Extends ChangeNotifier, `_safeNotify()`, dispose guard

### 4. Services do not import UI files
- **task_service.dart**: ✅ Pass — No view/widget imports
- **dashboard_repository.dart**: ✅ Pass — No view/widget imports

---

## Violations (Before Fix)

| File | Line | Issue |
|------|------|-------|
| `lib/features/tasks/view/tender_payment_screen.dart` | 71 | Direct `Supabase.instance.client.auth.currentUser?.id` in View |

---

## Applied Fixes

| File | Summary |
|------|---------|
| `tender_payment_screen.dart` | Removed Supabase import; added `clientId` parameter; use `widget.clientId` instead of Supabase call |
| `dashboard_view_model.dart` | Added `currentUserId` getter for passing to child screens |
| `inbox_tab.dart` | Pass `clientId: vm.currentUserId ?? ''` when navigating to TenderPaymentScreen (both Award and Pay Later flows) |
| `requests_list_screen.dart` | Pass `clientId: context.read<AuthViewModel>().currentUserId ?? ''` when navigating to TenderPaymentScreen |

---

## Passed Checks

- ✅ inbox_tab.dart — Uses Consumer, delegates to VM, no Supabase
- ✅ offer_card.dart — Pure UI, callbacks, UnifiedCtaResolver (utility)
- ✅ task_requests_view_model.dart — ChangeNotifier, safe state, services only
- ✅ dashboard_view_model.dart — ChangeNotifier, _safeNotify, repository pattern
- ✅ task_service.dart — No UI imports, Supabase via injected client
- ✅ dashboard_repository.dart — No UI imports, data layer only

---

## Follow-ups

1. **TenderPaymentViewModel (technical debt)** — `TenderPaymentScreen` still holds payment orchestration in `_processPayment()` and instantiates `QiCardPaymentService` and `TaskService` directly. Recommended: introduce `TenderPaymentViewModel` to own `processPayment()`, loading/error state, and service calls. Track in `.TODO/TECHNICAL_DEBT.md`.
2. **Pre-existing lints** — `use_build_context_synchronously` (tender_payment_screen:82), `withOpacity` deprecation (tender_payment_screen:227), `deprecated_member_use` (inbox_tab:148) — address separately.

---

## Final Decision

- **Status**: **PASS** (after applied fixes)
- **Next actions**: Consider TenderPaymentViewModel refactor for full MVVM compliance; fix pre-existing lints as needed.
