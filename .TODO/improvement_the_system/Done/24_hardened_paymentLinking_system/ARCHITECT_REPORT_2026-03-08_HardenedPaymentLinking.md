# Architect Report: Hardened Payment Linking

**Scope:** Hardened Payment Linking System (24)  
**Plan:** `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Agent:** @Architect (per orchestrator pipeline)

---

## 1. Architecture / Logic Findings

### 1.1 MVVM boundary check
- **Flutter:** Views do not call Supabase directly. `DirectOfferDetailsScreen` uses `DirectOfferDetailsViewModel` for `createPaymentForCard()` and `streamPaymentIntentStatus()`; `PaymentWebViewScreen` receives a `Stream<String>?` from the caller. No `.from()` or `.rpc()` in view layer. **PASS.**
- **Evidence:** `lib/features/direct_offers/view/direct_offer_details_screen.dart` passes `vm.streamPaymentIntentStatus(result.intentId!)`; view has no Supabase import.

### 1.2 Data flow (intent path)
- **Webhook → DB → Ledger:** `handleIntentBasedPayment` loads intent (by `id` or `gateway_intent_id`), inserts `payment_events`, validates amount/currency, calls `submitGatewayEscrowHold` / `submitDirectOfferGatewayEscrow` with `paymentIntentId`, then updates `payment_intents` (status, paid_at). Order is correct: audit first, then idempotency check, then amount check, then ledger + intent update.
- **Flutter:** Booking checkout and direct-offer details get `intentId` from create result; both subscribe to `payment_intents(id)` via `streamPaymentIntentStatus` when present. Contract (intent_id required for Realtime) is satisfied.

### 1.3 Contract alignment
- **Create response:** Contract requires `intent_id` on success. Flutter parses `intent_id` from create response in `qicard_payment_service.dart` (booking and direct_offer). Create edges (`qicard_payment_create`, `qicard_payment_create_direct_offer`) are not changed in this implementation; they must return `intent_id` when they insert into `payment_intents` (assumed by plan).
- **Ledger meta:** Contract says "store in journal_entries.meta as payment_intent_id". Implementation passes `payment_intent_id` inside `p_meta` from Edge; migrations `20260308200100` ensure both `process_payment_event_ledger` (gateway_escrow) and `process_gateway_escrow_direct_offer` merge it into meta. No RPC signature change; contract satisfied.

### 1.4 Path validation
- **Files scanned:** `supabase/functions/qicard_webhook_handler/index.ts`, `_shared/bookin_payment.ts`, `lib/core/services/qicard_payment_service.dart`, `lib/core/services/payment_service.dart`, `lib/features/booking/view/payment_webview_screen.dart`, `lib/features/booking/view/payment_checkout_screen.dart`, `lib/features/direct_offers/view/direct_offer_details_screen.dart`, `lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart`, `supabase/migrations/20260308200000_*`, `20260308200100_*`. All paths exist and are consistent with plan.

---

## 2. Proposed Refactors (Non-blocking)

| Item | Location | Recommendation |
|------|----------|----------------|
| **Intent path fallback** | `handleIntentBasedPayment` | When `entityType` is neither `direct_offer` nor `booking`, function returns `null` and caller falls through to legacy path. If tender is added later, extend with `entityType === 'task_request'` branch or explicit orphan. |
| **Direct offer update order** | Webhook | After `submitDirectOfferGatewayEscrow` we UPDATE `payment_intents` (status, paid_at). If RPC throws, we do not update intent; on 400 we return error. Consider whether QiCard will retry; idempotency (replayed) is already handled in submit. No change required. |

---

## 3. Contract Checks Summary

| Contract item | Status | Evidence |
|---------------|--------|----------|
| Create returns intent_id | Assumed (create edges unchanged) | Flutter parses and uses it |
| Webhook identifies intent by intent_id or gateway_intent_id | Done | `.or(\`id.eq.${intentId},gateway_intent_id.eq.${paymentId}\`)` |
| Amount/currency match before ledger | Done | intentAmount !== amount \|\| intentCurrency !== currency → orphan |
| Ledger meta has payment_intent_id | Done | Migrations 20260308200100 + Edge p_meta |
| payment_events append-only | Done | RLS + trigger in 20260308200000 |

---

## 4. Conclusion

- **Architecture:** MVVM preserved; data flow and intent path logic are correct and aligned with the plan.
- **Contract:** Implemented behavior matches CONTRACT_HardenedPaymentLinking.md (ledger meta via p_meta; no new RPC param).
- **Blockers:** None. Optional: document that create edges must return `intent_id` when they insert into `payment_intents` (if not already guaranteed).
