# Execution Log: Direct Chat Offer Flow (Plan Critic)

**Plan:** `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md`  
**Started:** 2026-03-07  
**Executor:** @Executor (AppLogger + Supabase MCP)

---

## Full Context Scan (Pre-Execution)

### Evidence (what exists)

- **Docs:** DEVELOPER_GUIDE.md, SUPABASE_SETUP.md, MVP_ROADMAP.md, ARCHITECTURE_ANALYSIS.md, CODE_REVIEW.md, STRUCTURE.md, Direct_Offers_Feature.md present and referenced.
- **Code:** `lib/features/direct_offers/` — DirectOffersService (createOffer, acceptOfferWithoutPayment, payNow, recoverPaymentAfterCallback, cancelOffer, cancelAcceptedOffer, markDelivered, completeOffer); DirectOffer model (no delivered_at/review_expires_at/payment_* fields); view + viewmodel. AppLogger already used in DirectOffersService for create, accept, pay, reject, cancel, markDelivered, completeOffer.
- **Live DB (Supabase MCP):**
  - **direct_offers:** id, conversation_id, client_id, freelancer_id, task_id, title, description, price, days, status, payment_status, created_at, updated_at, **fee_rate_applied_bps**, fee_amount, net_amount. **Missing:** currency, payment_request_id, payment_gateway_id, payment_correlation_id, payment_expires_at, payment_recovered_at, delivered_at, review_expires_at.
  - **disputes:** id, task_id, complainant_id, reason, status, resolution, created_at, resolved_at, defendant_id. **Missing:** direct_offer_id. task_id is required (no nullable).
  - **Triggers on direct_offers:** trg_direct_offer_guard (fn_direct_offer_guard), trg_direct_offers_updated_at, trg_lock_fee_on_escrow_direct_offers (fn_lock_fee_on_escrow), trg_protect_fee_rate_applied_direct_offers (fn_protect_fee_rate_applied).
  - **Cron:** Only `cleanup-expired-awards` (task requests). **No cron for review_expires_at / auto-release** for tasks, bookings, or direct_offers in this query result.

### Gaps (what must be created)

- direct_offers: ADD currency, payment_request_id, payment_gateway_id, payment_correlation_id, payment_expires_at, payment_recovered_at, delivered_at, review_expires_at.
- disputes: ADD direct_offer_id; allow task_id OR direct_offer_id (constraint + possibly make task_id nullable).
- Cron or scheduled function for auto-release of delivered direct_offers (and optionally tasks/bookings) when review_expires_at < now().
- Contract file, threat model doc, migration plan doc, test/features/direct_offers/direct_offers_service_test.dart, RLS matrix file.
- DirectOffer model new fields; markDelivered to set delivered_at + review_expires_at; acceptOfferWithoutPayment to set fee_rate_applied_bps + currency; edge to persist payment_* before redirect.

### Risks (what can break)

- disputes.task_id may be NOT NULL — adding direct_offer_id requires constraint (task_id OR direct_offer_id) and possibly ALTER task_id DROP NOT NULL.
- Cron for auto-release does not exist; must create new job or function.
- Fee from row: ledger may already use fee_rate_applied_bps for direct_offer (triggers exist); confirm process_payment_event_ledger reads from row.

### Observability notes

- AppLogger used in DirectOffersService; add logs for: acceptOfferWithoutPayment (fee stamp), markDelivered (timestamps), recoverPaymentAfterCallback (payment_* match), createDisputeForDirectOffer (if added). No PII in logs.

---

## Phase Status

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 0: Test Infrastructure & Preconditions | Done | Contract, threat model, migration plan, test file, live scan |
| Phase 1: Data & Contracts Gate | Done | DDL + trigger + RLS + ledger + cron all applied via MCP |
| Phase 2: Security Gate | Done | RLS disputes INSERT; trigger price/currency |
| Phase 3: Backend/API Gate | In Progress | Model + service + ledger fee done; edge + dispute creation pending |
| Phase 4: UI/Integration Gate | Not Started | |
| Phase 5: Release/QA Gate | Not Started | |

---

## Step-by-Step Log

### Phase 0 — Step 1: direct_offers_service_test.dart

- **Agent:** @Sentinel / @Architect  
- **Action:** Create test/features/direct_offers/ and direct_offers_service_test.dart with (1) client cannot call cancelOffer, (2) freelancer cannot call payNow, (3) markDelivered throws when !isActive. Use mocks; AppLogger in tests (tag).  
- **Evidence:** `flutter test test/features/direct_offers/direct_offers_service_test.dart` — 3 tests passed. File: test/features/direct_offers/direct_offers_service_test.dart.

### Phase 0 — Step 2: Contract file

- **Agent:** @APIContract  
- **Action:** Write .TODO/06_direct_offer_contract.md.  
- **Evidence:** File created: .TODO/06_direct_offer_contract.md (payment intent, release fee-from-row, disputes).

### Phase 0 — Step 3: Live Supabase scan

- **Agent:** @Supabase_Ops  
- **Action:** Run list_tables (verbose) + execute_sql for triggers and cron.  
- **Evidence:** direct_offers columns (fee_rate_applied_bps present; missing currency, payment_*, delivered_at, review_expires_at). disputes: no direct_offer_id. Triggers: trg_direct_offer_guard, trg_direct_offers_updated_at, trg_lock_fee_on_escrow_direct_offers, trg_protect_fee_rate_applied_direct_offers. Cron: only cleanup-expired-awards (no review_expires auto-release).

### Phase 0 — Step 4: Threat model

- **Agent:** @ThreatModeler  
- **Action:** Write .TODO/06_direct_offer_threat_model.md.  
- **Evidence:** File created: .TODO/06_direct_offer_threat_model.md (6 testable negative cases).

### Phase 0 — Step 5: Migration plan

- **Agent:** @DataMigration  
- **Action:** Write .TODO/06_direct_offer_migration_plan.md.  
- **Evidence:** File created: .TODO/06_direct_offer_migration_plan.md (additive columns, backfill, rollback).

---

### Phase 1 — Step 1: DDL migration

- **Agent:** @Supabase_Ops  
- **Action:** Migration 20260319000000_direct_offer_flow_harden.sql: add currency, payment_*, delivered_at, review_expires_at to direct_offers; add direct_offer_id to disputes; chk_dispute_entity; idx_direct_offers_processing.  
- **Evidence:** Applied via Supabase MCP apply_migration (success: true). Migration file: supabase/migrations/20260319000000_direct_offer_flow_harden.sql.

### Phase 1 — Step 2: Trigger + RLS + rpc_approve_delivery (fee from row)

- **Agent:** @Supabase_Ops  
- **Action:** Migration direct_offer_guard_rls_ledger: (1) Trigger trg_direct_offer_protect_price_currency — block UPDATE of price/currency when status != 'sent' or payment_status != 'unpaid'. (2) RLS disputes_insert_own — WITH CHECK complainant_id = auth.uid() and (task_id IS NOT NULL or (direct_offer_id IS NOT NULL and user is party to offer)). (3) rpc_approve_delivery direct_offer branch: read fee_rate_applied_bps from direct_offers row, pass COALESCE(v_fee_rate_bps, 1000) in p_meta to process_payment_event_ledger.  
- **Evidence:** Applied via Supabase MCP apply_migration (success: true). File: supabase/migrations/20260319110000_direct_offer_guard_rls_ledger.sql.

### Phase 1 — Step 3: Cron auto-release expired direct_offers

- **Agent:** @Supabase_Ops  
- **Action:** Migration direct_offer_auto_release_cron: CREATE FUNCTION run_auto_release_expired_direct_offers() SECURITY DEFINER; selects delivered + held + review_expires_at < now(); FOR UPDATE SKIP LOCKED; calls process_payment_event_ledger with same idempotency pattern; updates to released/completed. Schedule pg_cron 'auto-release-expired-direct-offers' hourly ('0 * * * *').  
- **Evidence:** Applied via Supabase MCP apply_migration (success: true). File: supabase/migrations/20260319120000_direct_offer_auto_release_cron.sql. list_migrations shows both direct_offer_guard_rls_ledger and direct_offer_auto_release_cron applied.

### Phase 3 (partial) — Model + Service + AppLogger

- **Agent:** @Architect  
- **Action:** DirectOffer model: add currency, feeRateAppliedBps, paymentRequestId, paymentGatewayId, paymentCorrelationId, paymentExpiresAt, paymentRecoveredAt, deliveredAt, reviewExpiresAt (fromJson). DirectOffersService: acceptOfferWithoutPayment stamps fee_rate_applied_bps=1000, currency=IQD; markDelivered sets delivered_at, review_expires_at (now + 3 days). AppLogger used for accept/markDelivered and existing flows.  
- **Evidence:** flutter analyze lib/features/direct_offers/ — no issues. flutter test test/features/direct_offers/direct_offers_service_test.dart — 3 passed.

### Phase 2 (artifact) — RLS matrix

- **Agent:** @Supabase_Ops  
- **Action:** Create .TODO/06_direct_offers_rls_matrix.md.  
- **Evidence:** File created: .TODO/06_direct_offers_rls_matrix.md.

---

## Blockers

- None yet.

---

## Rollback Triggers

- DB: additive only; disable cron branch for direct_offers if needed.  
- App: revert; backend tolerates null new columns.
