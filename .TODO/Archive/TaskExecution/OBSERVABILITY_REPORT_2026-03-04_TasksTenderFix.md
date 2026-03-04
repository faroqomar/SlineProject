# Observability Report: Tasks Tender Fix

**Scope:** Tasks Tender Fix (tender payment fail-closed, replace_task_request, active_role removal)  
**Plan reference:** `.TODO/PLAN_Tasks_Fix_All_2026-03-01.md`  
**Date:** 2026-03-04  
**Agent:** @Observability

---

## 1. Files Reviewed

| Path | Purpose |
|------|--------|
| `lib/features/tasks/services/tender_payment_coordinator.dart` | Payment orchestration; fail-closed logging |
| `lib/features/tasks/services/task_requests_service.dart` | Submit/replace; RLS error logging |
| `lib/features/wallet/services/ledger_service.dart` | Referenced (ledger ok:false logging) |
| `lib/features/tasks/services/task_service.dart` | Referenced (payAwardedOffer logging) |

---

## 2. What Is Logged (Current)

| Location | Event | Level | Tag | PII/Sensitive |
|----------|--------|-------|-----|----------------|
| TenderPaymentCoordinator.executePayment | Start | info | TenderPaymentCoordinator | requestId only (UUID) ✅ |
| TenderPaymentCoordinator | Skip (demo) | warning | TenderPaymentCoordinator | None ✅ |
| TenderPaymentCoordinator | Skip (QiCard fallback) | warning | TenderPaymentCoordinator | None ✅ |
| TenderPaymentCoordinator | Payment confirmed, calling ledger+pay | info | TenderPaymentCoordinator | requestId ✅ |
| TenderPaymentCoordinator | Pay completed | info | TenderPaymentCoordinator | requestId ✅ |
| TaskRequestsService.submitOffer | Duplicate pending | warning | Offers | None ✅ |
| TaskRequestsService.submitOffer | RLS deny (e.g. not freelancer) | warning | Offers | None ✅ |
| TaskRequestsService.submitOffer | Failed to submit | error | Offers | error/stackTrace ✅ |
| TaskRequestsService | Offer submitted | info | Offers | model.id only ✅ |
| TaskRequestsService.replaceOffer | Replacing offer | debug | Offers | taskId ✅ |
| TaskRequestsService.replaceOffer | Failed to replace | error | Offers | error/stackTrace ✅ |

No tokens, amounts in logs (amount/price not logged in coordinator messages). requestId/taskId/model.id are non-PII identifiers. ✅

---

## 3. Gaps and Recommendations

| Gap | Severity | Recommendation |
|-----|----------|----------------|
| replaceOffer success | LOW | Add AppLogger.i on successful replace (e.g. after getExistingActiveOfferForCurrentUser) for consistency with submitOffer. |
| Ledger failure path | N/A | Already covered in LedgerService (ok:false) and TaskService.payAwardedOffer (logs + throw). No change needed. |
| Correlation ID | LOW | No correlation ID is passed from coordinator → taskService → ledger. For future: consider a flow/correlation id for award → pay → ledger for traceability. |

---

## 4. What NOT to Log (Verified)

- No payment tokens, gateway payloads, or raw payment details. ✅
- No email/phone/names in these paths. ✅
- Stack traces only on error; no sensitive data in messages. ✅

---

## 5. Summary

- **Logging:** AppLogger used; no print(). Tags and levels appropriate.
- **Privacy:** No PII or secrets in log messages.
- **Actionable:** Fail-closed and RLS-denial paths are visible for support/debugging.
- **Blockers:** None. Optional: log replace success; consider correlation ID in a future pass.
