# Contract: Hardened Payment Linking (Edge ↔ App ↔ DB)

**Plan:** `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Owner:** @APIContract

---

## 1. Canonical create edge (request)

**Endpoint:** POST to canonical create function (e.g. `create_payment_intent` or migrated `qicard_payment_create`).

**Request body (booking):**

- `task_id` (string, required)
- `note` (string, optional)
- `package_id` (string, optional)
- `requirements` (object, optional)
- `finish_url` (string, optional)
- `request_correlation_id` (string, optional)

**Request body (direct_offer):**

- `offer_id` (string, required) — direct_offers.id
- `amount` (number, required)
- `finish_url` (string, optional)
- `request_correlation_id` (string, optional)

**Request body (generic intent-based):**

- `entity_type` ('booking' | 'direct_offer' | 'task')
- `entity_id` (UUID string)
- Plus flow-specific fields as above.

---

## 2. Canonical create edge (response)

**Success (200):**

- `intent_id` (string, UUID) — **required** for Realtime subscription.
- `checkout_url` or `form_url` (string) — URL to redirect user to gateway.
- Optional: `booking_id`, `request_correlation_id`, etc.

**Error (4xx/5xx):**

- `error` (string)
- `request_correlation_id` (string, optional)
- Optional: `error_code` (string).

**Contract rule:** Flutter must receive `intent_id` on success to subscribe to `payment_intents(id)` and resolve checkout via Realtime. If response omits `intent_id`, app must use existing recovery/polling fallback.

---

## 3. Webhook payload (QiCard → qicard_webhook_handler)

**Incoming (gateway):**

- Top-level: `paymentId`, `requestId`, `status`, `amount`, `currency`, `creationDate` (or `createdDate`), etc.
- `additionalInfo` (object): may contain `intent_id`, `entity_id`, `entity_type`, `payer_id`, `signature`, `booking_id`, `client_id`, `correlation_id`, etc.

**Contract rules:**

- Webhook must identify intent by `additionalInfo.intent_id` or by lookup on `payment_intents.gateway_intent_id` = `paymentId`.
- Internal signature to verify: recompute HMAC(PAYMENT_HMAC_SECRET, entity_id|gross_amount|currency|payer_id) and compare to `additionalInfo.signature`.
- Amount match: `intent.gross_amount` must equal webhook `amount` (and currency) before calling ledger.

---

## 4. Ledger RPC (process_payment_event_ledger)

**New optional parameter:**

- `p_payment_intent_id` (UUID, optional, default NULL).

**Behavior:**

- When provided, store in `journal_entries.meta` as: `meta = COALESCE(meta,'{}'::jsonb) || jsonb_build_object('payment_intent_id', p_payment_intent_id)`.
- Applied in `escrow_hold` and `gateway_escrow` branches.

**Contract rule:** All new escrow/gateway_escrow journal entries created by the hardened webhook must include `payment_intent_id` in meta for audit.

---

## 5. payment_events schema (D3)

- `intent_id` is NOT NULL. Rows are inserted only when an intent is found (by gateway_intent_id or additionalInfo.intent_id).
- When intent is not found, only `orphan_payments` is written; no row in `payment_events`.

---

## 6. Observability (logging)

- **Flutter:** Use AppLogger for all payment flows (create start/success/failure, Realtime subscription start/status update, recovery fallback). Tag: `Payment`. No PII or raw amounts in logs; intent_id and correlation_id allowed.
- **Edge:** Log intent_id, gateway_intent_id, and orphan reason only; no amount/PII in plaintext. Use structured fields for correlation.
