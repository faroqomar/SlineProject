# CodeGuard Review: Hardened Payment Linking

**Scope:** Hardened Payment Linking System (24)  
**Plan:** `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Agent:** @CodeGuard (per orchestrator pipeline)

---

## 1. Risk rating

| Area | Rating | Notes |
|------|--------|--------|
| **Security** | LOW | Intent path validates UUID, amount/currency; RLS restricts payment_events INSERT to service_role; no PII in logs. HMAC not yet implemented (deferred). |
| **Data integrity** | LOW | Idempotency (status=succeeded early return); payment_events unique on gateway_event_id; ledger replay handled in RPC. |
| **Performance** | LOW | Single intent lookup, single insert, then RPC; no N+1. |
| **Compatibility** | LOW | Optional params (paymentIntentId, stream); backward compatible. |

**Overall risk:** LOW. No BLOCKER.

---

## 2. Security review

| Check | Result | Evidence |
|-------|--------|----------|
| **Input validation** | PASS | intentId trimmed and validated with isUuid() before use; amount/currency from payload compared to intent. |
| **RLS** | PASS | payment_events: INSERT service_role only; append-only trigger. payment_intents: service_role full access. Orphan insert via service_role. |
| **Secrets** | PASS | No secrets in code; PAYMENT_HMAC_SECRET referenced only in LOGGING_AND_SECRETS (not yet used in create). |
| **Injection** | PASS | intentId/paymentId used in Supabase client filters (parameterized); no raw SQL in Edge. |
| **Logging** | PASS | No amount or PII in intent-path logs; only intent_id, gateway_event_id, error messages. |

**Blockers:** None.

---

## 3. Performance

- **Webhook intent path:** 1 SELECT (payment_intents), 1 INSERT (payment_events), 0–1 INSERT (orphan_payments), 1 RPC (submit), 1 UPDATE (payment_intents). Acceptable.
- **Flutter:** Stream subscription per checkout; cancelled on dispose. No leak.
- **Migration DO block:** String replace on function body; run once. No ongoing cost.

---

## 4. Compatibility and freshness

- **Flutter:** Optional paymentIntentId and paymentIntentStatusStream; when null, behavior unchanged. Existing booking/direct_offer flows work with or without intent_id from create.
- **Edge:** submit* accept optional paymentIntentId; when absent, meta unchanged. Legacy webhook path unchanged.
- **DB:** Additive migrations; new columns nullable or default. RPC meta merge is additive (p_meta already existed).
- **process_payment_event_ledger patch:** If function body differs (e.g. different formatting), position(v_old IN v_def) = 0 and patch is skipped (NOTICE only). Recommendation: after deploy, verify with `SELECT meta FROM journal_entries WHERE event_type = 'gateway_escrow' ORDER BY created_at DESC LIMIT 1` and confirm meta can contain payment_intent_id when provided.

---

## 5. Verification commands

```bash
# Flutter analyze (payment-related)
flutter analyze lib/core/services/qicard_payment_service.dart lib/core/services/payment_service.dart lib/features/booking/view/payment_webview_screen.dart lib/features/direct_offers/view/direct_offer_details_screen.dart lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart

# Run tests (existing suite)
flutter test
```

**DB (Supabase):**
- Confirm payment_intents has signature, currency, paid_at: `SELECT column_name FROM information_schema.columns WHERE table_name = 'payment_intents' AND column_name IN ('signature','currency','paid_at');`
- Confirm payment_events trigger exists: `SELECT tgname FROM pg_trigger WHERE tgrelid = 'public.payment_events'::regclass;`
- Confirm RLS policy: `SELECT policyname FROM pg_policies WHERE tablename = 'payment_events';`

---

## 6. Decision

**APPROVED ✅**

- No BLOCKER.
- Security, data integrity, performance, and compatibility are acceptable.
- Follow-up: complete docs (SUPABASE_SETUP, DEVELOPER_GUIDE) and optional structured outcome log in webhook; HMAC in create edge remains deferred.
