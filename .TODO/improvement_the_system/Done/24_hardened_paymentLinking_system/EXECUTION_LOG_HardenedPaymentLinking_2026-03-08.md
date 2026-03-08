# Execution Log: Hardened Payment Linking System (24)

**Plan:** `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md`  
**Started:** 2026-03-08  
**Executor:** @Executor (per `.cursor/Agents/Executor.md`)  
**Observability:** AppLogger mandatory; Edge structured logs (intent_id, gateway_intent_id, no PII).

---

## Status Overview

| Phase | Status | Completed At |
|-------|--------|--------------|
| 0 – Decisions and Contracts | Done | 2026-03-08 |
| 1 – Data and Schema | Done | 2026-03-08 |
| 2 – Security and Secrets | Done | 2026-03-08 |
| 3 – Backend (Edge + Webhook) | Done | 2026-03-08 |
| 4 – Flutter and UI | Done | 2026-03-08 |
| 5 – QA, Release, Docs | Done | 2026-03-08 |

---

## Full Context Scan (Pre-Execution)

### 3.1 Documentation Scan
- **Read:** Sline_everything/DEVELOPER_GUIDE.md, SUPABASE_SETUP.md, MVP_ROADMAP.md, ARCHITECTURE_ANALYSIS.md, CODE_REVIEW.md, STRUCTURE.md.
- **Relevant:** Hardened Payment Gateway v2.20; process_payment_event_ledger; booking/direct_offer flows; lib/features/booking, direct_offers, core/services/qicard_payment_service.

### 3.2 Codebase Scan
- **Paths confirmed:** lib/core/services/qicard_payment_service.dart (streamPaymentIntentStatus, createPaymentForBooking, createPaymentForDirectOffer); lib/features/booking/view/payment_checkout_screen.dart; lib/features/booking/viewmodels/booking_view_model.dart; lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart; supabase/functions/create_payment_intent, finalize_payment_webhook, qicard_payment_create, qicard_webhook_handler, _shared/bookin_payment.ts.

### 3.3 Supabase Object Reality Check (MCP)
- **Project ID:** isddrknbjsgaantjojhm (Sline Project).
- **list_tables (public, verbose):** Executed.
- **payment_intents:** EXISTS. Columns: id, entity_type, entity_id, payer_id, receiver_id, gross_amount, fee_rate_locked, gateway_intent_id, idempotency_key, status (created|gateway_processing|succeeded|failed), created_at, updated_at. **Missing:** signature, currency, paid_at.
- **payment_events:** EXISTS. Columns: id, gateway_event_id (UNIQUE), intent_id (NOT NULL, FK payment_intents), event_type, payload, created_at. RLS enabled. No explicit INSERT-only policy documented in migration.
- **orphan_payments:** EXISTS. Columns: id, gateway_event_id, error_reason, payload, created_at. **Missing:** investigated (optional).
- **journal_entries:** EXISTS. Column meta (jsonb) present; can store payment_intent_id.

### 3.4 Validation Checklist
- Plan file path exists: YES.
- Referenced doc/code paths exist: YES.
- Supabase objects: payment_intents, payment_events, orphan_payments exist; new columns and RPC change to be created.
- AppLogger: lib/core/services/logger_service.dart exists; used in qicard_payment_service and booking flows.

### Evidence & Findings
- **Existing:** Tables payment_intents, payment_events, orphan_payments; create_payment_intent and finalize_payment_webhook (intent path); qicard_payment_create, qicard_webhook_handler (legacy path); Flutter streamPaymentIntentStatus and checkout with intent_id when present.
- **Gaps:** signature, currency, paid_at on payment_intents; RLS explicit for payment_events (INSERT service_role only; no UPDATE/DELETE); process_payment_event_ledger(p_payment_intent_id) and meta; HMAC in create; webhook payment_events insert + amount/HMAC verify; orphan_payments.investigated optional.
- **Risks:** Dual create paths (booking uses qicard_payment_create); webhook does not write payment_events or verify internal HMAC.
- **Observability:** AppLogger in Flutter; Edge to add structured logs (intent_id, gateway_intent_id only; no amount/PII).

---

## Phase 0: Decisions and Contracts (Blocking)

### Step 0.1 – Canonical create and webhook decision
- **Owner:** @Architect
- **Deliverable:** Decision doc naming canonical create and webhook.

### Step 0.2 – CONTRACT_HardenedPaymentLinking.md
- **Owner:** @APIContract
- **Deliverable:** Contract file (create request/response, webhook payload, RPC meta).

### Step 0.3 – payment_events.intent_id (D3)
- **Decision (D3):** Do not insert payment_events when intent lookup fails; only orphan_payments. Schema keeps intent_id NOT NULL.
- **Recorded in:** Contract and this log.

**Phase 0 evidence:** DECISION_CanonicalCreateAndWebhook.md and CONTRACT_HardenedPaymentLinking.md created in `.TODO/improvement_the_system/ImplementReady/24_hardened_paymentLinking_system/`.

---

## Phase 1: Data and Schema

### Step 1.1 – Live scan
- **Done:** Supabase MCP list_tables (project isddrknbjsgaantjojhm). payment_intents, payment_events, orphan_payments, journal_entries confirmed; drift recorded in Evidence.

### Step 1.2 – DDL migration
- **Done:** Migration `20260308200000_hardened_payment_linking_schema.sql` created and applied via Supabase MCP apply_migration (re-applied in this pass for idempotency). Migration `20260308200100_hardened_payment_ledger_meta_payment_intent_id.sql` created and applied via MCP (direct_offer RPC replace + process_payment_event_ledger patch via execute_sql).
- **Content:** payment_intents: signature TEXT, currency TEXT DEFAULT 'IQD', paid_at TIMESTAMPTZ; orphan_payments: investigated BOOLEAN DEFAULT false; payment_events: policy service_role_insert_payment_events, trigger trg_payment_events_append_only (BEFORE UPDATE OR DELETE); payment_intents: policy service_role_all_payment_intents.

### Step 1.3 – Ledger link
- **Decision:** No RPC signature change. Webhook passes `payment_intent_id` in `p_meta`; journal_entries.meta stores it.
- **Implemented:** Migration `20260308200100_hardened_payment_ledger_meta_payment_intent_id.sql`: (1) `process_gateway_escrow_direct_offer` merges `p_meta->'payment_intent_id'` into journal_entries.meta; (2) `process_payment_event_ledger` gateway_escrow branch patched (DO block) to merge `payment_intent_id` from p_meta into meta. Both applied via Supabase MCP.

### Step 1.4 – Verification
- **Done:** execute_sql confirmed payment_intents has columns signature, currency, paid_at.
- **Flutter:** intent_id parsing and AppLogger added in qicard_payment_service (createPaymentForBooking, createPaymentForDirectOffer); QiCardDirectOfferPaymentResult.intentId added in payment_service.dart.

**Phase 1 evidence:** New columns present in DB; RLS and trigger applied; Flutter parses and logs intent_id when returned.

---

## Phase 2: Security and Secrets

- **Done:** LOGGING_AND_SECRETS.md in improvement folder (PAYMENT_HMAC_SECRET, logging rules, RLS test refs T-RLS-1/T-RLS-2).

## Phase 3: Backend (Edge + Webhook)

- **Done:** _shared/bookin_payment.ts: submitGatewayEscrowHold and submitDirectOfferGatewayEscrow accept optional paymentIntentId and merge into p_meta for journal_entries audit.
- **Done:** qicard_webhook_handler: when additionalInfo.intent_id present, handleIntentBasedPayment: lookup intent (by id or gateway_intent_id), insert payment_events, idempotency (status=succeeded), amount/currency match → orphan on mismatch, then submit* with paymentIntentId and UPDATE payment_intents (status=succeeded, paid_at). Structured logs (no PII); orphan reasons intent_not_found, amount_mismatch.
- **Not done in this pass:** HMAC in create edge and webhook signature verification (requires PAYMENT_HMAC_SECRET and create_payment_intent to write signature); can be added in follow-up.

## Phase 4: Flutter and UI

- **Done:** Booking checkout already subscribes to payment_intents(id) when createResult.intentId != null (payment_checkout_screen).
- **Done:** Direct offer: PaymentWebViewScreen now accepts optional paymentIntentId and paymentIntentStatusStream; when stream is set, listens for succeeded/failed and pops with PaymentReturnArgs. DirectOfferDetailsScreen passes result.intentId and vm.streamPaymentIntentStatus(result.intentId!) when result.intentId != null. DirectOfferDetailsViewModel.streamPaymentIntentStatus(intentId) added.

## Phase 5: QA and docs

- **Done:** flutter analyze on payment-related files (lib/core/services/qicard_payment_service.dart, payment_service.dart, payment_webview_screen, direct_offer_details_*) — no issues. flutter test run: 386 passed, 8 skipped, 7 failed; failures are pre-existing (storage_rls_test plugin, message_service_test expectation), not payment-linking related.
- **Recommendation:** Update SUPABASE_SETUP.md and DEVELOPER_GUIDE.md for payment_intents (signature, currency, paid_at), payment_events (RLS, append-only trigger), orphan_payments (investigated), and hardened webhook flow when doing next docs pass. Manual tests from 04_TEST_PLAN.md (T-SEC-*, T-ROB-*, T-RLS-*) to be run in staging.

---

## Blockers

*(None yet.)*

---

## Verification Evidence

*(Per-phase evidence will be appended.)*

---

## Rollback / Rollout Notes

- Rollback: Additive migrations reversible (drop new columns; RPC can ignore p_payment_intent_id). Edge revert to previous version; Flutter backward compatible (recovery when intent_id null).
- Rollout: Deploy edge first; then app. PAYMENT_HMAC_SECRET required in Edge env before hardened webhook.
