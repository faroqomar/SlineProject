# Observability Report: Direct Offers Work Contract (Plan 19)

**Scope:** DirectOffersWorkContract (Plan 19)  
**Plan:** `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/PLAN_DirectOffersWorkContract_2026-03-07.md`  
**Date:** 2026-03-07  
**Agent:** @Observability (per `.agents/workflows/Orchestrator.md` pipeline)

---

## 1. Telemetry Gaps

### 1.1 What is logged (evidence)
- **Evidence:** `lib/features/direct_offers/services/direct_offers_service.dart`
  - Create: AppLogger.i (offer id, conversation id).
  - acceptOfferWithoutPayment: AppLogger.w on offer not found; AppLogger.i on success (offerId, fee_rate_applied_bps, currency).
  - payNow: AppLogger.w on offer not found; AppLogger.i on success.
  - recoverPaymentAfterCallback: AppLogger.w on offer not found; AppLogger.e on failure (offerId, msg); AppLogger.i on success.
  - cancelAcceptedOffer, markDelivered, completeOffer: AppLogger.w on offer not found; AppLogger.i on success; completeOffer also AppLogger.w for not-client/invalid state, AppLogger.e on RPC failure with stackTrace.
  - rejectOffer, cancelOffer: AppLogger.i on success; no log on "offer not found" (inconsistent).
- **Gap:** rejectOffer and cancelOffer do not log when offer is null (LOW — same pattern as other methods would improve traceability).

### 1.2 What NOT to log
- No PII logged (no email, no full name). Offer ID and conversation ID are non-PII identifiers. No tokens or secrets. PASS.
- AppLogger.e for recoverPaymentAfterCallback includes server message (may be user-facing); acceptable. Stack traces only in completeOffer catch block (appropriate).

### 1.3 Correlation strategy
- Tag `DirectOffers` used consistently. Offer ID (and conversation ID where relevant) allows correlating logs for a single offer. No correlation ID passed across service boundaries; acceptable for current scope.
- WorkLogService used for lifecycle events (offer_accepted_waiting_payment, delivery_submitted, completed); provides audit trail in DB.

---

## 2. Event Taxonomy

| Event | Level | When | Safe |
|-------|--------|------|------|
| created offer | info | createOffer success | ✅ |
| acceptOfferWithoutPayment: offer not found | warn | getOffer null | ✅ |
| acceptOfferWithoutPayment completed | info | update + work_log done | ✅ |
| payNow: offer not found | warn | getOffer null | ✅ |
| payNow completed | info | ledger + work_log done | ✅ |
| recoverPaymentAfterCallback: offer not found | warn | getOffer null | ✅ |
| recoverPaymentAfterCallback failed | error | edge returned !ok | ✅ |
| recoverPaymentAfterCallback completed | info | edge ok | ✅ |
| cancelAcceptedOffer: offer not found | warn | getOffer null | ✅ |
| markDelivered: offer not found | warn | getOffer null | ✅ |
| completeOffer: offer not found | warn | getOffer null | ✅ |
| completeOffer: not client / invalid state | warn | auth/state check | ✅ |
| completeOffer failed | error | rpc_approve_delivery throw | ✅ |
| Direct offer completed | info | success | ✅ |

---

## 3. Recommendations

1. **Optional (LOW):** Add AppLogger.w for "offer not found" in `rejectOffer` and `cancelOffer` for consistency.
2. **No changes required** for privacy or structured logging; AppLogger only, no print(); tag and identifiers are appropriate.

---

## 4. Summary

| Area | Status | Notes |
|------|--------|--------|
| AppLogger only | ✅ | No print() in changed code |
| Privacy-safe | ✅ | No PII/secrets in logs |
| Critical flows | ✅ | Create, accept, pay, recover, deliver, complete covered |
| Consistency | ⚠️ LOW | rejectOffer/cancelOffer missing "offer not found" log |

**Observability:** Ready. One optional consistency improvement.
