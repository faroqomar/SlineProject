# API Contract & QA Acceptance Test Criteria: Hardened Payment Gateway

## 1. Acceptance Criteria (@Sentinel)

### Positive Flows (Happy Path)

1. **Checkout Initiation:** User taps "Pay" -> Flutter client calls `create_payment_intent` Edge Function -> Function returns a checkout session URL -> User is redirected.
2. **Payment Completion:** Webhook receives successful payload -> `finalize_payment_webhook` verifies signature -> Ledger RPC processes payment -> Client UI realtime listener detects `payment_intents.status` = 'succeeded' and unlocks screen.
3. **Wallet Balance Update:** After payment success, querying `vw_wallet_balances_user` reflects identical changes.

### Negative Flows & Security

1. **Tamper Prevention:** If client sends a custom `gross_amount` to `create_payment_intent`, the function MUST ignore it, fetch original price from DB, calculate fees via `platform_settings.fee_rate_default_bps`, and mint intent securely.
2. **Signature Failure:** If a Webhook HTTP POST contains a bad or missing HMAC signature, the `finalize` function MUST HTTP 401/403 and NOT invoke the ledger RPC.
3. **Idempotency Guarantee:** If the same Webhook POST is sent twice (same gateway event ID), the `payment_events` table logic and RPC must silently ignore/return success without duplicating the ledger entries.
4. **Client-Side Restrictions:** A malcontent client attempting an `UPDATE payment_intents SET status = 'succeeded'` MUST receive a 401 via RLS enforcement.

---

## 2. API Contracts (@APIContract)

### Edge Function: `create_payment_intent`

**Request Payload:**

```json
{
  "entity_type": "string", // "task", "booking", "direct_offer"
  "entity_id": "uuid",
  "success_url": "string",
  "cancel_url": "string"
}
```

_Note: `gross_amount` and `fee_rate` are intentionally excluded to prevent client spoofing._

**Response Payload:**

```json
{
  "checkout_url": "string",
  "intent_id": "uuid"
}
```

### Edge Function: `finalize_payment_webhook`

_(Triggered by QiCard / Payment Gateway directly)_

**Request Payload:**

```json
{
  "gateway_intent_id": "string",
  "status": "string", // "succeeded", "failed"
  "amount_received": "integer",
  "signature": "string" // Typically inside headers, but verified inside function
}
```
