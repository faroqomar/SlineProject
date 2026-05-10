# Docs Report: Direct Offers Work Contract (Plan 19)

**Scope:** DirectOffersWorkContract (Plan 19)  
**Plan:** `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/PLAN_DirectOffersWorkContract_2026-03-07.md`  
**Date:** 2026-03-07  
**Agent:** @DocsKeeper (per `.agents/workflows/Orchestrator.md` pipeline)

---

## 1. Documentation Delta (What Changed)

| Doc | Change |
|-----|--------|
| `Sline_everything/SUPABASE_SETUP.md` | §5.14 updated: triggers (self-offer), admin views, admin_refund_direct_offer, GRANT/REVOKE. |
| `Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md` | Triggers (self-offer), admin tooling (views + RPC), contract link. |
| `Sline_everything/STRUCTURE.md` | New bullet: Plan 19 migrations (admin schema, views, self-offer guard, admin RPC). |
| `.TODO/.../19_.../CONTRACT_admin_refund_direct_offer.md` | Created. |
| `.TODO/.../19_.../RLS_CHECK_MATRIX_direct_offers_admin.md` | Created. |
| `.TODO/.../19_.../EXECUTION_SUMMARY_2026-03-07.md` | Created. |
| `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/EXECUTION_LOG_PLAN_DirectOffersWorkContract_2026-03-07.md` | Created and updated. |

---

## 2. Reference Integrity Scan

### 2.1 References in docs (verified)
- SUPABASE_SETUP §5.14: `direct_offers`, `fn_direct_offer_guard`, `fn_direct_offer_guard_insert`, `admin.vw_direct_offer_money_story`, `admin.vw_direct_offer_stuck_funds`, `admin_refund_direct_offer` — all exist (DB or migration files).
- Direct_Offers_Feature.md: links to CONTRACT under `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/` — path exists.
- STRUCTURE.md: migration filenames `20260307180000_admin_direct_offer_views`, etc. — files exist under `supabase/migrations/`.

### 2.2 Broken refs / outdated statements
- **Potential gap:** SUPABASE_SETUP §5.14 does not list `delivered_at`, `review_expires_at`, or `fee_rate_applied_bps`/`fee_amount`/`net_amount` for `direct_offers` if they exist in the live schema. Execution log and migrations list show `direct_offer_flow_harden` and backfill migrations; schema may have been extended elsewhere. If those columns exist, §5.14 should list them for reference integrity.
- **Finding:** MED — Align §5.14 with live `direct_offers` columns (add delivered_at, review_expires_at, fee columns if present).

### 2.3 Cross-links
- Plan → Execution log: referenced in execution summary. ✅
- DEVELOPER_GUIDE → CONTRACT: path correct. ✅
- No broken internal links detected in changed docs.

---

## 3. Required Doc Updates (If Any)

1. **SUPABASE_SETUP.md §5.14:** If `direct_offers` has `delivered_at`, `review_expires_at`, `fee_rate_applied_bps`, `fee_amount`, `net_amount` in live DB, add them to the table and mention any migration that added them.
2. **Sline_Log.md (optional):** Add one-line entry for Plan 19 completion (admin views, RPC, self-offer guard, docs sync) if project convention requires.

---

## 4. Summary

| Area | Status | Notes |
|------|--------|--------|
| Delta list | ✅ | All doc changes listed |
| Reference integrity | ⚠️ MED | §5.14 vs live schema columns to be confirmed and synced |
| Broken refs | ✅ | No broken links found |
| Required updates | 1 optional | §5.14 column list vs schema |

**Docs:** Minor follow-up (schema/doc alignment for direct_offers columns). No blockers.
