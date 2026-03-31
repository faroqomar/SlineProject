# Observability Report: Hardened Payment Linking

**Scope:** Hardened Payment Linking System (24)  
**Plan:** `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Agent:** @Observability (per orchestrator pipeline)

---

## 1. What to log (current vs required)

### 1.1 Flutter (AppLogger)
- **Required (LOGGING_AND_SECRETS):** Tag `Payment`. Log intent_id, correlation_id, task_id/offer_id. Do NOT log raw amount, card data, PII.
- **Current:** `qicard_payment_service.dart` logs with tag `Payment`, includes `intent_id` in json when present; `payment_checkout_screen.dart` and `payment_webview_screen.dart` log "Payment intent realtime status" with intent_id and status. No amount or card data in logs. **Compliant.**

### 1.2 Edge (webhook)
- **Required:** Log gateway_event_id, intent_id (when found), outcome (processed | orphan), orphan reason. Do NOT log raw payload or amount.
- **Current:** 
  - `console.warn("Intent not found...", { intentId, paymentId })` — no amount, no full payload. **OK.**
  - `console.error("payment_events insert failed", insertErr)` — logs error object (may contain DB message; no PII). **OK.**
  - `console.error("Intent path direct_offer escrow error", err)` / "Intent path booking escrow error" — logs exception; no amount in message. **OK.**
  - No explicit "outcome=processed" or "outcome=orphan" structured line for success path; caller returns 200 with body. **Gap (LOW):** add one structured log per intent path outcome (e.g. "intent_path_done" with outcome, intent_id, gateway_event_id) for dashboards.

### 1.3 Edge (create)
- **Required:** Log intent_id after insert; do not log gross_amount or payer_id.
- **Current:** Create edges were not modified in this implementation. Assumed to follow LOGGING_AND_SECRETS when HMAC is added. **N/A for this review.**

---

## 2. Telemetry gaps

| Gap | Severity | Location | Recommendation |
|-----|----------|----------|----------------|
| **Structured outcome event** | LOW | `qicard_webhook_handler/index.ts` | After successful intent path (direct_offer or booking), log one line e.g. `console.log(JSON.stringify({ event: 'intent_path_processed', intent_id: intentIdResolved, gateway_event_id: paymentId, entity_type: entityType }))` so log aggregators can count success/orphan by reason. |
| **Correlation in Edge** | OK | Webhook | correlationId is built from additionalInfo or `intent:${intentIdResolved}`; passed to submit and audit. No change needed. |

---

## 3. Event taxonomy (suggested)

| Event | Where | When | Safe fields |
|-------|--------|------|--------------|
| `intent_path_processed` | Edge webhook | After ledger + intent update | intent_id, gateway_event_id, entity_type |
| `intent_path_orphan` | Edge webhook | When inserting orphan_payments | gateway_event_id, reason (intent_not_found \| amount_mismatch) |
| `payment_intent_realtime_status` | Flutter | On stream update | intent_id, status (succeeded \| failed) — already logged |

---

## 4. Privacy-safe logging

- **Verified:** No raw amount or PII in Flutter Payment logs (only intent_id, correlation_id, booking_id/offer_id, status).
- **Verified:** Webhook intent path does not log payload or amount; only intentId, paymentId, and error messages.
- **Recommendation:** Keep LOGGING_AND_SECRETS.md as the single reference for future Edge create logging when HMAC is implemented.

---

## 5. Correlation strategy

- **Create → Webview:** correlation_id from create result; passed to PaymentWebViewScreen and in return args.
- **Webhook:** correlationId from additionalInfo.correlation_id or `intent:${intentIdResolved}`; passed to submit* and recordBookingAudit. Journal meta includes payment_intent_id for forensics.
- **Conclusion:** Correlation is in place; no change required for this scope.

---

## 6. Conclusion

- **Observability:** Flutter and Edge intent path comply with "what to log" / "what NOT to log". One optional improvement: structured outcome log in webhook for metrics.
- **Blockers:** None.
