# Decision: Canonical Create and Webhook (Hardened Payment Linking)

**Plan:** `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Owner:** @Architect / Executor

---

## D1: Canonical create path

**Decision:** **Option 1** — Migrate booking and direct_offer to use a single intent-based create path. For implementation we use **`create_payment_intent`** as the canonical edge that:

- Accepts entity_type (booking | direct_offer), entity_id, and any flow-specific params (e.g. task_id, note, package_id for booking; offer_id, amount for direct_offer).
- For **booking:** calls `rpc_create_booking_draft_validated` (or equivalent) to create/validate the booking, then creates a row in `payment_intents` (with HMAC signature), then calls QiCard with metadata including intent_id and signature, then returns `{ intent_id, checkout_url }` (or form_url).
- For **direct_offer:** validates the offer and creates a row in `payment_intents` (with HMAC signature), then calls QiCard, then returns `{ intent_id, checkout_url }`.

**Deprecate for new flows:**  
- **`qicard_payment_create`** and **`qicard_payment_create_direct_offer`** remain available for backward compatibility until Flutter is fully switched; then they can be deprecated or refactored to delegate to the canonical create path.  
- **Flutter** must call the canonical create edge (or the migrated create that returns intent_id) for booking and direct_offer so that intent_id is always returned and Realtime subscription can run.

**Result:** One create endpoint used by Flutter for booking and direct_offer that always returns intent_id + checkout_url.

---

## D2: Canonical webhook

**Decision:** **Option 2** — Harden **`qicard_webhook_handler`** to support the intent path and keep a single webhook URL for QiCard:

- **QiCard** continues to call `qicard_webhook_handler`.
- **qicard_webhook_handler** will:
  1. Verify QiCard RSA signature (existing).
  2. Insert into `payment_events` (gateway_event_id, intent_id when available, payload) for audit.
  3. Look up intent by `gateway_intent_id` or `additionalInfo.intent_id`.
  4. If intent not found → insert `orphan_payments`, return 200.
  5. If intent.status = 'succeeded' → return 200 (idempotency).
  6. Verify amount and internal HMAC; on mismatch → orphan_payments, return 200.
  7. In a transaction: update payment_intents (status=succeeded, paid_at), call `process_payment_event_ledger(..., p_payment_intent_id)`, update entity (booking/direct_offer/task_request).

**Deprecate for new flows:**  
- **`finalize_payment_webhook`** is not used by QiCard today; we do not route QiCard to it. All logic for intent-based success is implemented inside `qicard_webhook_handler` so one URL suffices.

**Result:** Single webhook URL; one handler with intent lookup, payment_events, HMAC and amount check, and ledger link.

---

## D3: payment_events when intent unknown

**Decision:** **Option 2** — Do **not** insert into `payment_events` when intent lookup fails. Only insert into `orphan_payments` with the raw payload and reason (e.g. intent_not_found). Schema keeps `payment_events.intent_id` NOT NULL so every row in payment_events is tied to an intent.

**Result:** Append-only audit for payment_events only when we have an intent; orphans are still recorded in orphan_payments with full payload.
