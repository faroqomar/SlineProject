# Direct Offer Payment & Release Contract

**Plan:** PLAN_DirectChatOfferFlow_2026-03-07_CRITIC  
**Owner:** @APIContract  
**Date:** 2026-03-07

---

## 1) Payment intent (edge ↔ DB ↔ app)

- **Before redirect to QiCard:** Edge `qicard_payment_create_direct_offer` MUST write to `direct_offers`: `payment_request_id`, `payment_correlation_id`, `payment_expires_at` (WHERE id = offer_id AND status = 'accepted' AND payment_status = 'unpaid'). Same ids returned to app.
- **Recovery idempotency key:** Deterministic from entity_id + payment_request_id (or gateway_id) so duplicate webhook/callback does not double-apply escrow_hold.
- **After success:** Edge/recovery sets `payment_gateway_id`, `payment_recovered_at` on `direct_offers`.

## 2) Release (fee from row)

- **release_with_fee for direct_offer:** `process_payment_event_ledger` MUST read `fee_rate_applied_bps` and amount (`price`) from `direct_offers` row; MUST NOT use client-supplied p_meta for fee. If `fee_rate_applied_bps` is null, use platform default or safe fallback.
- **Idempotency:** Same stable key as `rpc_approve_delivery` (entity_id + ':release_with_fee:' + status + payment_status).

## 3) Disputes

- **direct_offer_id:** disputes row may reference `direct_offer_id` (FK to direct_offers). Constraint: exactly one of task_id or direct_offer_id set. Complainant must be client or freelancer of that direct_offer.
