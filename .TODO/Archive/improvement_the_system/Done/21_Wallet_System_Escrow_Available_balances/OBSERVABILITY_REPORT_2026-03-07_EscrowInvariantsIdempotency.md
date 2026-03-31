# Observability Report: Escrow Invariants & Idempotency

**Scope:** EscrowInvariantsIdempotency  
**Plan:** `.TODO/PLAN_EscrowInvariantsIdempotency_2026-03-07_CRITIC.md`  
**Date:** 2026-03-07  
**Agent:** @Observability

---

## 1) What Was Reviewed

- `WorkManagementService.approveDelivery` — request start, success, error.
- `WorkItemDetailsViewModel.approveDelivery` — call start, error.
- `ReviewDeliveryModal._handleApprove` — tap, success, error, and “already in progress” guard.

---

## 2) Telemetry Gaps

| Gap | Severity | Recommendation |
|-----|----------|----------------|
| No correlation ID across ViewModel → Service → RPC | LOW | Optional: pass a request id (e.g. UUID) from VM to service and log it; not required for current scope. |
| Idempotent replay (success on retry) not explicitly logged as “replay” | LOW | Backend could log when returning existing journal id; app sees success either way. Defer unless product asks. |

No HIGH/MED gaps; critical path is instrumented.

---

## 3) Event Taxonomy (Current)

| Event / Message | Where | Level | Payload | Privacy |
|-----------------|--------|--------|---------|--------|
| “Approve delivery requested” | work_management_service.dart | info | entityType, entityId | ✅ IDs only (no PII beyond entity ref) |
| “Delivery approved” | work_management_service.dart | debug | type, entityId | ✅ Same |
| “Failed to approve delivery” | work_management_service.dart | error | entityId, entityType, error, stackTrace | ✅ No tokens/secrets |
| “approveDelivery called” | work_item_details_view_model.dart | info | entityId, sourceType | ✅ Same |
| “Approve delivery error” | work_item_details_view_model.dart | error | error, stackTrace | ✅ Same |
| “Approve delivery tapped” | review_delivery_modal.dart | info | (none) | ✅ Safe |
| “Approve already in progress or done” | review_delivery_modal.dart | debug | (none) | ✅ Safe |
| “Approve delivery success” | review_delivery_modal.dart | debug | (none) | ✅ Safe |
| “Approve delivery failed” | review_delivery_modal.dart | error | error, stackTrace | ✅ No secrets |

All use **AppLogger**; no `print()`. Tags: `WorkManagement`, `WorkItemDetails`, `ReviewDelivery`.

---

## 4) What to Log (Confirmed)

- ✅ Request start (service + VM).
- ✅ Success (service debug).
- ✅ Errors with stack (service, VM, modal).
- ✅ One-shot guard hit (modal debug).

---

## 5) What NOT to Log

- ✅ No access tokens, refresh tokens, or session secrets.
- ✅ No full user profile or email in payloads; only entityId/entityType/sourceType.
- ✅ Error objects may contain DB messages; no deliberate logging of passwords or keys.

---

## 6) Correlation Strategy

- Same flow can be correlated by **entityId** + **tag** (WorkManagement / WorkItemDetails / ReviewDelivery) and timestamp in logs. No correlation ID added; acceptable for current scope.

---

## 7) Summary

- **AppLogger:** Used consistently; no print.  
- **Privacy:** No secrets or unnecessary PII.  
- **Actionable:** Start/success/error and guard hit are traceable.  
- **Blockers:** None. Proceed to @SlineDocs.
