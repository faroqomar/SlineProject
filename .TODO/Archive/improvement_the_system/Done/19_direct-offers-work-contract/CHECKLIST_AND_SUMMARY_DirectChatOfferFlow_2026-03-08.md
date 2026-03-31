# Direct Chat Offer Flow — Checklist & Summary

**Date:** 2026-03-08  
**Scope:** What was implemented and fixed (plan + Master Report)

---

## Part 1: What was done (short)

### Goal
Harden the Direct Chat Offer flow so: offers have a review window, auto-release after 3 days, payment is traceable, price/currency/fee cannot be changed after accept, and disputes can be linked to direct offers.

### Why
- Avoid permanent escrow lock when the client never taps “Approve”.
- Lock fee and currency at accept so platform revenue is correct.
- Allow “Report issue” (disputes) for direct offers and trace payment via DB.

---

## Part 2: Add / Remove / Modify

| Area | Added | Removed | Modified |
|------|--------|---------|----------|
| **Database (Supabase)** | New columns on `direct_offers`: `currency`, `payment_request_id`, `payment_gateway_id`, `payment_correlation_id`, `payment_expires_at`, `payment_recovered_at`, `delivered_at`, `review_expires_at`. New column on `disputes`: `direct_offer_id`. Constraint `chk_dispute_entity` (exactly one of task_id or direct_offer_id). Trigger `trg_direct_offer_protect_price_currency`. Function `run_auto_release_expired_direct_offers()` + cron job hourly. Partial index `idx_direct_offers_processing`. RLS policy `disputes_insert_own` (allow INSERT when complainant is party to the offer). | Nothing. | `rpc_approve_delivery`: direct_offer branch now reads `fee_rate_applied_bps` from the row (no longer hardcoded 0). Trigger later extended to also block changes to `fee_rate_applied_bps`. |
| **Flutter app (model)** | On `DirectOffer`: nullable fields `currency`, `feeRateAppliedBps`, `paymentRequestId`, `paymentGatewayId`, `paymentCorrelationId`, `paymentExpiresAt`, `paymentRecoveredAt`, `deliveredAt`, `reviewExpiresAt`. | Nothing. | `fromJson` (and related mapping) to fill the new fields. |
| **Flutter app (service)** | Logging: `payment_request_id` in recover-success log (both success paths). | Nothing. | `acceptOfferWithoutPayment`: now sets `fee_rate_applied_bps = 1000` and `currency = 'IQD'`. `markDelivered`: now sets `delivered_at` and `review_expires_at` (now + 3 days) in the same UPDATE. |
| **Tests** | `test/features/direct_offers/direct_offers_service_test.dart`: 3 tests (client cannot cancelOffer, freelancer cannot payNow, markDelivered throws when !isActive). | Nothing. | `test/services/repro_test.dart`: removed `print()` calls (fix linter). |
| **Docs** | Contract, threat model, migration plan, RLS matrix, execution log, Master Report, DOCS_SYNC note. Sline_Log entry. Changelog and diagram updates. | Reference to “direct_offer_status_enum” in diagram (DB uses text). | SUPABASE_SETUP §5.14, §5.24, §9.5, §17; Direct_Offers_Feature (lifecycle, columns, contract, §4.5); STRUCTURE (migration bullet); AppDigram 06 (sent vs pending, trigger, cron, last_verified). |

---

## Part 3: Checklist to check on the actual app

Use this on a real device or simulator to confirm behavior.

### Before you start
- [ ] Log in as **client** in one account and **freelancer** in another (or use two devices).
- [ ] Have a 1:1 conversation between them.

---

### 1) Create & accept offer (no payment)
- [ ] **Freelancer:** In chat, create a direct offer (price, days, title).
- [ ] **Client:** In chat, tap **Accept** (no payment here).
- [ ] **Check:** Offer appears in Dashboard as “Pending Payment” or similar. In DB (or via app state), the offer has `status = accepted`, `payment_status = unpaid`, `fee_rate_applied_bps` and `currency` set (e.g. 1000, IQD).

---

### 2) Pay from Dashboard
- [ ] **Client:** Open Dashboard, find the offer, tap **Pay** (or open offer detail and pay).
- [ ] **Check:** QiCard (or wallet) flow runs; after success, offer becomes “Active” / “Work in progress”. In DB: `status = active`, `payment_status = held`. Optionally: after payment create, row has `payment_request_id` / `payment_expires_at` (if edge was updated).

---

### 3) Recover payment (if you return from gateway)
- [ ] **Client:** If you were redirected to browser/WebView and come back with `payment_return=1&offer_id=...&payment_request_id=...`, app runs recovery.
- [ ] **Check:** Offer ends up active + held. In logs (if you have access), recover success line includes `payment_request_id` for correlation.

---

### 4) Mark delivered
- [ ] **Freelancer:** On offer detail, tap **Mark Delivered**.
- [ ] **Check:** Offer shows as “Delivered”. In DB: `status = delivered`, `delivered_at` and `review_expires_at` are set (e.g. review_expires_at = delivered_at + 3 days).

---

### 5) Complete (client approve)
- [ ] **Client:** On offer detail, tap **Approve & release** (or “Complete”).
- [ ] **Check:** Offer shows as “Completed”. In DB: `status = completed`, `payment_status = released`. Wallet/ledger shows release and fee from row (no double release on second tap).

---

### 6) Auto-release (optional, needs DB or time)
- [ ] Either set one offer’s `review_expires_at` in the past and run cron, or wait until after review window.
- [ ] **Check:** That offer moves to `completed` / `released` without the client tapping Approve (cron runs hourly).

---

### 7) Guards (no need to do in UI; DB/service enforce)
- [ ] **Price/currency/fee:** After accept, no one can change price, currency, or fee on that offer (trigger blocks it in DB).
- [ ] **Roles:** Only client can pay and approve; only freelancer can mark delivered and cancel a sent offer. Service tests already cover client cannot cancelOffer, freelancer cannot payNow, markDelivered throws when not active.

---

### 8) Disputes (when implemented in UI)
- [ ] When “Report issue” exists: as client or freelancer of the offer, open a dispute linked to the offer.
- [ ] **Check:** New row in `disputes` with `direct_offer_id` set; RLS allows only the offer’s client or freelancer to create it.

---

## Part 4: Quick reference — files touched

| Purpose | Files |
|--------|--------|
| **SQL** | `supabase/migrations/20260319000000_direct_offer_flow_harden.sql`, `20260319110000_direct_offer_guard_rls_ledger.sql`, `20260319120000_direct_offer_auto_release_cron.sql`, `20260319130000_direct_offer_protect_fee_in_trigger.sql` |
| **App** | `lib/features/direct_offers/models/direct_offer_model.dart`, `lib/features/direct_offers/services/direct_offers_service.dart` |
| **Tests** | `test/features/direct_offers/direct_offers_service_test.dart`, `test/services/repro_test.dart` |
| **Docs** | `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md`, `Sline_everything/STRUCTURE.md`, `Sline_everything/Sline_Log.md`, `Sline_everything/AppDigram/All_Diagrams/06_direct-chat-offer-flow.md` |
| **.TODO** | Plan CRITIC, execution log, contract, threat model, migration plan, RLS matrix, Architect/Observability/Docs/CodeGuard reports, Master Report, DOCS_SYNC, this checklist. |

---

**Summary in one line:** We added DB columns and triggers for review window and payment traceability, a cron to auto-release after 3 days, fee-from-row on release, dispute linkage and RLS; updated the app model and service (accept stamps fee/currency, markDelivered sets timestamps, recover logs payment_request_id); fixed tests and docs so you can verify everything with this checklist.
