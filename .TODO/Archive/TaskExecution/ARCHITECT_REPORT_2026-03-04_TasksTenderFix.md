# Architect Report: Tasks Tender Fix

**Scope:** Tasks Tender Fix (PLAN_Tasks_Fix_All_2026-03-01 — executed subset)  
**Plan reference:** `.TODO/PLAN_Tasks_Fix_All_2026-03-01.md`, `.TODO/EXECUTION_LOG_PLAN_Tasks_Fix_All_2026-03-01.md`  
**Date:** 2026-03-04  
**Agent:** @Architect

---

## 1. Files Reviewed

| Path | Purpose |
|------|--------|
| `lib/features/tasks/services/tender_payment_coordinator.dart` | Fail-closed for demo/QiCard; orchestration |
| `lib/features/tasks/services/task_requests_service.dart` | active_role removal; RLS error mapping |
| `supabase/migrations/20260311000000_replace_task_request.sql` | New RPC replace_task_request |
| `test/unit/tasks/tender_payment_coordinator_test.dart` | Unit tests for coordinator |

---

## 2. Architecture / Logic Findings

### 2.1 MVVM Boundary Check

- **TenderPaymentCoordinator:** Service-layer only; no UI. Consumed by `TenderPaymentViewModel` and dashboard flows. ✅
- **TaskRequestsService:** Service-layer only; no direct Supabase in views. Submit/replace are invoked via ViewModels. ✅
- **Views:** No changes in this set; `TenderPaymentScreen` already uses `TenderPaymentViewModel` only. ✅

### 2.2 Data Flow

- **executePayment:** PaymentService (interface) → processPayment → TaskService.payAwardedOffer (ledger + pay_awarded_offer). Type checks for Demo/QiCard before any payment call. ✅
- **submitOffer:** Direct insert to `task_requests`; RLS enforced; no profile mutation. ✅
- **replaceOffer:** RPC `replace_task_request` then re-fetch via `getExistingActiveOfferForCurrentUser`. ✅

### 2.3 Contract Checks

- **replace_task_request:** Flutter passes `p_task_id`, `p_freelancer_id`, `p_message` (note), `p_price`, `p_days`. Migration defines same params; `p_message` mapped to `note` column. ✅
- **Task status:** Migration uses `status = 'withdrawn'` for archived offer. App `OfferStatus` enum includes `withdrawn`; model should parse it (existing behavior). ✅

### 2.4 Path / Name Validation

- All referenced files and classes exist. `TaskService`, `PaymentService`, `DemoPaymentService`, `QiCardPaymentService` are real types. ✅
- RPC name `replace_task_request` matches migration and Flutter call. ✅

---

## 3. Proposed Refactors / Notes (Non-Blocking)

| Item | Severity | Recommendation |
|------|----------|----------------|
| Coordinator type check | LOW | Using `is DemoPaymentService` / `is QiCardPaymentService` ties the coordinator to concrete implementations. Acceptable for fail-closed; when a real tender payment service is added, either introduce a marker interface (e.g. `TenderPaymentCapable`) or remove the QiCard check and rely on that implementation not delegating to demo. |
| replace_task_request and RLS | MED | RPC is SECURITY DEFINER; INSERT may run with definer privileges. Function validates caller = p_freelancer_id and task open/not own, but does not enforce `is_freelancer(auth.uid())`. If RLS is bypassed, a non-freelancer could insert. Recommend: add an explicit check that `is_freelancer(v_me)` or equivalent before INSERT, or document that RLS still applies to INSERT (verify in Postgres). |
| Error mapping in submitOffer | LOW | 42501 and "policy"/"row-level security" in message is a reasonable heuristic; consider mapping other Postgrest codes if more RLS-related errors appear in production. |

---

## 4. Summary

- **MVVM:** Respected; no view-layer Supabase or service calls outside ViewModels.
- **Data flow:** Clear; fail-closed path prevents tender state advance on demo; replace flow matches contract.
- **Contracts:** Flutter ↔ RPC params aligned; migration is additive.
- **Blockers:** None. One MED recommendation: harden replace_task_request with is_freelancer check or confirm RLS behavior for SECURITY DEFINER INSERT.
