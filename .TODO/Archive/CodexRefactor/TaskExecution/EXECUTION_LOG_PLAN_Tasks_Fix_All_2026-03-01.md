# Execution Log: PLAN_Tasks_Fix_All_2026-03-01

**Plan reference:** `.TODO/PLAN_Tasks_Fix_All_2026-03-01.md`  
**Supporting:** `.TODO/tasks.TODO.md`  
**Started:** 2026-03-04  
**Executor:** @Executor (with AppLogger and test-everything mandate)

---

## Status by Phase

| Phase | Status | Notes |
|-------|--------|------|
| 0 Preconditions & Gates | In Progress | Spec lock, contract, threat model, migration plan |
| 1 Database & Security | Pending | replace_task_request migration; RLS/hydration |
| 2 App Layer (MVVM) | Pending | Services, ViewModels, observability |
| 3 UI | Pending | Wiring, polish |
| 4 QA + Security | Pending | Contract checks, security tests, functional QA |
| 5 Documentation Sync | Pending | DEVELOPER_GUIDE, SUPABASE_SETUP, MVP_ROADMAP |

---

## Evidence & Findings (Pre-Execution Scan)

### Evidence (what exists)
- `TaskService.payAwardedOffer()` calls `LedgerService.submitPaymentEvent()` then `pay_awarded_offer`; `LedgerService` already throws on `ok: false` (ledger gate enforced).
- `TenderPaymentScreen` uses `TenderPaymentViewModel` and `TenderPaymentCoordinator`; coordinator uses `PaymentService.processPayment()` then `TaskService.payAwardedOffer()`.
- `PaymentService` is created via `createPaymentService()` in `main.dart`; default is QiCard (`kUseQiCardPayment = true`); Demo used when `USE_QICARD_PAYMENT=false`.
- `TaskRequestsService.submitOffer()` still mutates `profiles.active_role` to `freelancer` before insert (TSK-SEC-03).
- `TaskRequestsService.replaceOffer()` calls RPC `replace_task_request`; **no migration in `supabase/migrations/` defines it** (TSK-DI-03).
- `TaskStatus` in `app_enums.dart` has no `delivered`; task model may collapse it to `inProgress` (TSK-DI-04).
- `TaskRepository` uses injected `_client` for `currentUser` but `TaskService()` is constructed with no client (uses global Supabase internally) (TSK-ARC-02).
- AppLogger is used in `TaskService`, `LedgerService`, `TenderPaymentViewModel`, `TenderPaymentCoordinator`, `TaskRequestsService`; some code paths may lack consistent logging.
- Tests exist: `tender_payment_screen_test.dart`, `tender_payment_coordinator_test.dart`, `task_view_model_test.dart`, `task_filter_view_model_test.dart`, `create_task_screen_test.dart`, `tenders_screen_test.dart`. No dedicated `task_service_payment_test` or `task_requests_service_test` for payment/replace failure paths.

### Gaps (what must be created)
- Tender flow fail-closed when Demo payment is used (no advance to `pay_awarded_offer` after demo success).
- Migration defining `replace_task_request` **or** safe replacement (remove call / use alternative).
- Remove client-side `profiles.active_role` mutation from offer submission; rely on RLS/UX message.
- Add `TaskStatus.delivered` and map in task model (Phase 2).
- Observability: ensure AppLogger on all critical paths (award, pay, replace, hydration failures).
- Unit tests: tender payment failure (ledger ok:false, expired, missing RPC), replace-offer contract, owner_id/delivered model tests.

### Risks
- Adding `replace_task_request` migration may conflict with live DB if already present; additive-only.
- active_role removal may require RLS/policy change so freelancer insert is allowed without client setting role.
- Enum/status change (`delivered`) can affect dashboard and permission services.

### Observability notes
- Log at: award start/success/failure, pay start/ledger success/failure/pay_awarded_offer success/failure, replace start/success/failure, profile hydration failure, coordinator payment start/skip (demo)/success/failure.
- No PII or raw payment tokens in logs.

---

## Phase 0: Preconditions & Gates

### 0.1 Spec Lock
- **Owner:** @Sentinel / @Architect  
- **Deliverable:** Success criteria frozen for tender payment safety, task-request contract, task status, MVVM.  
- **Evidence:** (To be filled when step completes.)

### 0.2 Threat Model
- **Owner:** @ThreatModeler  
- **Deliverable:** `.TODO/THREAT_MODEL_tasks_tender_payment_2026-03-01.md`  
- **Evidence:** (To be filled when step completes.)

### 0.3 Contracts
- **Owner:** @APIContract  
- **Deliverable:** `.TODO/CONTRACT_tasks_tender_flow_2026-03-01.md`  
- **Evidence:** (To be filled when step completes.)

### 0.4 Migration Plan
- **Owner:** @DataMigration  
- **Deliverable:** `.TODO/MIGRATION_PLAN_tasks_tender_flow_2026-03-01.md`  
- **Evidence:** (To be filled when step completes.)

---

## Phase 1: Database & Security (Selected Items)

### 1.x Replace_task_request
- **Change:** Add migration defining `replace_task_request` (additive) or remove/replace call in Flutter.  
- **Verification:** Flutter build + test; migration applies cleanly.  
- **Evidence:** (To be filled.)

### 1.x active_role
- **Change:** Stop updating `profiles.active_role` in `TaskRequestsService`; rely on RLS; show clear UX if role blocks insert.  
- **Verification:** Submit offer as freelancer succeeds; submit as client-only fails with clear message.  
- **Evidence:** (To be filled.)

---

## Phase 1 Critical (App Layer): Tender Demo Fail-Closed + AppLogger

### Step: TenderPaymentCoordinator fail-closed when Demo
- **Change:** Before calling `processPayment()`, if payment service is `DemoPaymentService` or `QiCardPaymentService` (which delegates to demo for processPayment), throw and never call `payAwardedOffer`.  
- **Files:** `lib/features/tasks/services/tender_payment_coordinator.dart`  
- **AppLogger:** Added: log when tender payment is skipped (demo or QiCard fallback), and when proceeding to ledger+pay.  
- **Evidence:** Unit tests added in `test/unit/tasks/tender_payment_coordinator_test.dart`: "executePayment fail-closed: DemoPaymentService throws and never calls payAwardedOffer", "executePayment fail-closed: QiCardPaymentService throws and never calls payAwardedOffer". All 30 task-related tests pass; `flutter analyze` no issues.

### Step: AppLogger coverage
- **Change:** TaskService, TaskRequestsService, TenderPaymentCoordinator already use AppLogger; added RLS failure mapping with AppLogger.w in TaskRequestsService for offer submit.  
- **Evidence:** Logs observed in test run (TenderPaymentCoordinator, Offers tags).

---

## Phase 1: replace_task_request + active_role

### replace_task_request migration
- **Change:** Added `supabase/migrations/20260311000000_replace_task_request.sql` defining `replace_task_request(p_task_id, p_freelancer_id, p_message, p_price, p_days)` RETURNS VOID; withdraws caller's pending offer and inserts replacement; GRANT EXECUTE TO authenticated.  
- **Evidence:** Migration is additive; Flutter `TaskRequestsService.replaceOffer()` already calls this RPC with matching params.

### active_role removal
- **Change:** Removed client-side `profiles.active_role` update from `TaskRequestsService.submitOffer()`. On RLS denial (42501 or policy/row-level security message), throw user-facing: "You must be in freelancer mode to submit an offer. Switch your role in profile settings."  
- **Files:** `lib/features/tasks/services/task_requests_service.dart`  
- **Evidence:** `flutter analyze` clean; task unit/widget tests pass.

---

## Blocker Log

(No blockers.)

---

## Completion Summary

(To be filled at plan completion.)
