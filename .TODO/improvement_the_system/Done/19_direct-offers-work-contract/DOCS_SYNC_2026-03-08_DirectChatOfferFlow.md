# DOCS_SYNC: Direct Chat Offer Flow (Master Report Fixes)

**Date:** 2026-03-08  
**Scope:** DirectChatOfferFlow — all fixes from `.TODO/MASTER_REPORT_2026-03-08_DirectChatOfferFlow.md`

---

## 1. Code changes

| Item | File | Change |
|------|------|--------|
| Recover success log | `lib/features/direct_offers/services/direct_offers_service.dart` | Added `payment_request_id` to success log (both branches) with `json: {'offerId', 'payment_request_id'}`. |
| repro_test | `test/services/repro_test.dart` | Removed `print()` calls to fix `avoid_print` lints. |
| Trigger extension | `supabase/migrations/20260319130000_direct_offer_protect_fee_in_trigger.sql` | Extended `fn_direct_offer_protect_price_currency` to also block UPDATE of `fee_rate_applied_bps` when not sent/unpaid. Applied via Supabase MCP. |

---

## 2. Documentation updates

| Doc | Updates |
|-----|---------|
| **SUPABASE_SETUP.md** | §5.14: added idx_direct_offers_processing, trg_direct_offer_protect_price_currency, Cron run_auto_release_expired_direct_offers. §5.24: added direct_offer_id column, chk_dispute_entity, RLS disputes_insert_own. §9.5: added migration 20260319110000 (fee from row). §17 Changelog: new bullet Direct Chat Offer Flow hardening (20260319* migrations). |
| **Direct_Offers_Feature.md** | Last Updated 2026-03-08; full column ref and lifecycle (delivered_at, review_expires_at, auto-release); §4.5 Deliver and complete with auto-release step; contract ref .TODO/06_direct_offer_contract.md; triggers line includes trg_direct_offer_protect_price_currency. |
| **STRUCTURE.md** | New bullet: Direct Chat Offer Flow hardening (20260319000000, 20260319110000, 20260319120000, 20260319130000). |
| **Sline_Log.md** | New entry: Direct Chat Offer Flow — Hardening (2026-03-08) with migrations, model, service, tests, .TODO artifacts, plan/execution/Master Report links. |
| **AppDigram 06_direct-chat-offer-flow.md** | last_verified 2026-03-08; "pending" → "sent" in diagram and text; removed direct_offer_status_enum (status is text); added trg_direct_offer_protect_price_currency and run_auto_release_expired_direct_offers; delivered → completed note (client or cron). |

---

## 3. Verification

- `dart format` run on direct_offers and repro_test (0 changed).
- Trigger migration applied via Supabase MCP `apply_migration` (success: true).
- Reference integrity: all paths in Master Report fix plan addressed; no broken refs.

---

## 4. References

- Master Report: `.TODO/MASTER_REPORT_2026-03-08_DirectChatOfferFlow.md`
- Plan: `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md`
- Execution log: `.TODO/EXECUTION_LOG_DirectChatOfferFlow_2026-03-07_CRITIC.md`
