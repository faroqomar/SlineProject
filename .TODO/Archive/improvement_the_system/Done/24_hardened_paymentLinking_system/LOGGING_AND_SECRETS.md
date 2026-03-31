# Hardened Payment Linking — Logging and Secrets (Phase 2)

**Plan:** PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic  
**Date:** 2026-03-08

---

## 1. PAYMENT_HMAC_SECRET

- **Where:** Supabase Edge Function secrets (or Vault). Set for production and staging.
- **Usage:** HMAC-SHA256(PAYMENT_HMAC_SECRET, entity_id|gross_amount|currency|payer_id) when creating payment_intent; webhook re-computes and compares to metadata.signature.
- **Rotation:** Document in runbook; rotate key and redeploy edge; existing intents with old signature will orphan if webhook re-validates (by design, only new intents use new key).
- **Verification:** Edge create logs "intent created" (no secret in logs); webhook logs "signature_valid" or "orphan" reason only.

---

## 2. Logging rules (observability)

- **Flutter (AppLogger):** Tag `Payment`. Log: intent_id, correlation_id, task_id/offer_id; do NOT log raw amount, card data, or PII. Already in place in qicard_payment_service.
- **Edge (create):** Log intent_id (UUID) after insert; do not log gross_amount or payer_id in plaintext. Log "intent_created" with intent_id.
- **Edge (webhook):** Log gateway_event_id, intent_id (when found), outcome (processed | orphan), orphan reason (e.g. intent_not_found, amount_mismatch, signature_mismatch). Do not log raw payload or amount.
- **Correlation:** Use request_correlation_id / intent_id / gateway_intent_id for tracing across create → webhook → ledger.

---

## 3. RLS tests (T-RLS-1, T-RLS-2)

- **T-RLS-1 (payer impersonation):** As authenticated user A, attempt to create a payment_intent for a booking owned by B. Expected: RPC or edge validates client_id = auth.uid(); intent creation fails or is rejected.
- **T-RLS-2 (payment_events append-only):** As authenticated user, attempt UPDATE or DELETE on payment_events. Expected: RLS/trigger raises; no policy allows UPDATE/DELETE; trigger trg_payment_events_append_only raises exception.
- **Run:** Via Supabase client with anon/authenticated key; or integration test that uses service_role for allowed ops and anon for negative tests.
