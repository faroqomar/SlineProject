# Architect Report: Direct Offers Work Contract (Plan 19)

**Scope:** DirectOffersWorkContract (Plan 19)  
**Plan:** `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/PLAN_DirectOffersWorkContract_2026-03-07.md`  
**Date:** 2026-03-07  
**Agent:** @Architect (per `.agents/workflows/orchestrator.md` pipeline)

---

## 1. Architecture / Logic Findings

### 1.1 MVVM boundary check
- **Evidence:** `lib/features/direct_offers/services/direct_offers_service.dart` — all Supabase/ledger/edge calls are in the service. Views use ViewModels only; no grep hit for `Supabase.instance` or `.from('direct_offers')` in `lib/features/direct_offers/view/`.
- **Finding:** PASS. Strict MVVM preserved; no UI → Supabase.

### 1.2 Data flow map
- **Create:** ViewModel → DirectOffersService.createOffer → `direct_offers` INSERT + MessageService.sendMessage.
- **Accept:** DirectOffersService.acceptOfferWithoutPayment → `direct_offers` UPDATE (status accepted, fee_rate_applied_bps, currency) + WorkLogService.
- **Pay/Complete:** Service → LedgerService / rpc_approve_delivery. No duplicate payment paths.
- **Finding:** Single source of truth per operation; no duplicate query paths for the same domain concept.

### 1.3 Contract checks
- **Admin RPC:** Not used from app (grep: no `admin_refund_direct_offer` or `admin.` in lib/). Admin tooling is server/dashboard only. CONTRACT_admin_refund_direct_offer.md matches RPC signature and admin resolution (admin_users).
- **Finding:** PASS. App does not call admin objects; contract aligns with implementation.

### 1.4 Path / name validation
- **Files scanned:** `lib/features/direct_offers/` (model, service, viewmodel, view); `supabase/migrations/` (3 Plan 19 migrations); `test/sql/` (guard script).
- **Referenced DB objects:** `direct_offers`, `rpc_approve_delivery`, `process_payment_event_ledger` (via LedgerService), `qicard_payment_recovery_direct_offer` — all exist per SUPABASE_SETUP and execution log.
- **Schema note:** Service updates `delivered_at` and `review_expires_at` in `markDelivered`. SUPABASE_SETUP §5.14 does not list these columns for `direct_offers`. If they were added in a later migration (e.g. `direct_offer_flow_harden`), docs should be updated; if not, the UPDATE will fail at runtime.
- **Finding:** MED — Verify `direct_offers.delivered_at` and `direct_offers.review_expires_at` exist in live schema; if yes, update SUPABASE_SETUP §5.14.

---

## 2. Proposed Refactors

- None required for Plan 19 scope. Optional: add AppLogger.w for "offer not found" in `rejectOffer` and `cancelOffer` for consistency with other methods (LOW priority).

---

## 3. Summary

| Area | Status | Notes |
|------|--------|--------|
| MVVM | ✅ | Service-only backend access |
| Data flow | ✅ | Single path per operation |
| Contract | ✅ | Admin RPC not in app; contract matches |
| Paths/names | ✅ | All referenced paths/objects exist |
| Schema/docs | ⚠️ MED | Confirm delivered_at/review_expires_at on direct_offers; sync SUPABASE_SETUP if present |

**Contract checks:** Complete. No blocking architecture issues.
