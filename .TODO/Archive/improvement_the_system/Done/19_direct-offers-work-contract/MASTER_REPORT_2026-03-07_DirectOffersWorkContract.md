# Master Report: Direct Offers Work Contract (Plan 19)

**Scope:** DirectOffersWorkContract (Plan 19)  
**Plan:** `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/PLAN_DirectOffersWorkContract_2026-03-07.md`  
**Date:** 2026-03-07  
**Orchestrator:** Multi-agent pipeline per `.agents/workflows/Orchestrator.md`

---

## A) Executive Summary

- **What was reviewed:** Plan 19 (Direct Offers Work Contract) and all related code, SQL, and docs: `lib/features/direct_offers/services/direct_offers_service.dart`; migrations `20260307180000_admin_direct_offer_views.sql`, `20260307180100_direct_offer_self_offer_guard.sql`, `20260307180200_admin_refund_direct_offer.sql`; test SQL `test/sql/direct_offer_guard_verification.sql`; CONTRACT and RLS matrix in folder 19; SUPABASE_SETUP.md §5.14, Direct_Offers_Feature.md, STRUCTURE.md; execution log and execution summary.
- **Overall risk level:** LOW. No BLOCKER; one MED (schema/docs alignment), one optional LOW (logging consistency).
- **Final decision:** **Ready ✅** — Safe to merge. Follow-up fixes below are non-blocking.

---

## B) Consolidated Findings (Deduplicated)

| Category | Severity | Owner | Path / Object | Fix recommendation |
|----------|----------|--------|----------------|--------------------|
| **Data Integrity / Docs** | MED | @DocsKeeper | `Sline_everything/SUPABASE_SETUP.md` §5.14; live `direct_offers` table | Verify live `direct_offers` has `delivered_at`, `review_expires_at`, and fee columns (`fee_rate_applied_bps`, `fee_amount`, `net_amount`). If yes, add them to §5.14 table and note the migration that added them. |
| **Observability** | LOW | @Observability | `lib/features/direct_offers/services/direct_offers_service.dart` | Optionally add `AppLogger.w` for "offer not found" in `rejectOffer` and `cancelOffer` for consistency with other methods. |
| **Security** | — | @CodeGuard | — | No findings. RLS, admin check, REVOKE anon, idempotency in place. |
| **Architecture/MVVM** | — | @Architect | — | No findings. Service-only backend access; contract matches. |
| **Performance** | — | @CodeGuard | — | No findings. |

---

## C) Fix Plan (Ordered, Step-by-Step)

1. **Verify schema and sync docs (MED)**  
   - **Owner:** @Supabase_Ops or dev with DB access.  
   - **Action:** On live DB, run `SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'direct_offers' ORDER BY ordinal_position;`  
   - If `delivered_at`, `review_expires_at`, `fee_rate_applied_bps`, `fee_amount`, `net_amount` exist:  
     - **Owner:** @DocsKeeper  
     - **Action:** Update `Sline_everything/SUPABASE_SETUP.md` §5.14 to list these columns and reference the migration that added them.  
   - **Verification:** Grep §5.14 for `delivered_at` / `review_expires_at`; confirm they match schema.

2. **Optional: Logging consistency (LOW)**  
   - **Owner:** Dev or @Observability  
   - **Action:** In `direct_offers_service.dart`, in `rejectOffer` and `cancelOffer`, when `offer == null` (before throwing), add `AppLogger.w('DirectOffers', 'Offer not found for reject/cancel', ...)` with offerId/conversationId if available.  
   - **Verification:** `flutter analyze lib/features/direct_offers/`; manual test reject/cancel with invalid id.

3. **Gate re-run (optional)**  
   - **Owner:** @CodeGuard  
   - **Action:** Re-run review after steps 1–2 if changes are made.  
   - **Verification:** CODEGUARD_REVIEW remains APPROVED.

---

## D) Regression Checklist

- **Critical flows (quick test):**
  - Create direct offer → Accept (no payment) → Pay → Mark delivered → Complete (client). End-to-end in app; confirm no errors and status transitions.
  - Self-offer guard: INSERT into `direct_offers` with `client_id = freelancer_id` → expect trigger to reject.
  - Admin views: As service_role, `SELECT * FROM admin.vw_direct_offer_money_story` and `SELECT * FROM admin.vw_direct_offer_stuck_funds` (no error).
  - Admin RPC: As non-admin authenticated user, call `admin_refund_direct_offer` → expect exception. As admin, call with valid args + idempotency_key → success; same key again → same journal_entry_id (idempotent).
- **How to test quickly:** Run `test/sql/direct_offer_guard_verification.sql` with test IDs; run `flutter analyze`; execute one full Create→Complete flow in dev.

---

## E) Rollback Notes

- **DB (Supabase):**  
  - Drop RPC: `DROP FUNCTION IF EXISTS public.admin_refund_direct_offer(uuid, text, text);`  
  - Drop trigger: `DROP TRIGGER IF EXISTS trg_direct_offer_guard_insert ON public.direct_offers;` then `DROP FUNCTION IF EXISTS public.fn_direct_offer_guard_insert();`  
  - Drop admin views/schema: `DROP VIEW IF EXISTS admin.vw_direct_offer_stuck_funds;` `DROP VIEW IF EXISTS admin.vw_direct_offer_money_story;` then `DROP SCHEMA IF EXISTS admin;` (only if no other objects in `admin`).  
  - Re-run in reverse order of migrations if using migration runner.
- **App:** Revert `lib/features/direct_offers/services/direct_offers_service.dart` to revision before Plan 19 (removes AppLogger additions and any flow changes). No admin calls in app, so no feature dependency on new DB objects for normal flows.
- **Docs:** Revert changes to SUPABASE_SETUP.md §5.14, Direct_Offers_Feature.md, STRUCTURE.md; remove or archive CONTRACT, RLS matrix, execution summary in folder 19.

---

## Next Actions

1. **If merging now:** Proceed; no blockers. Schedule MED fix (schema/docs) and optional LOW (logging) in a follow-up.
2. **Before or after merge:** Run manual E2E (Create → Accept → Pay → Deliver → Complete) and record result in `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/EXECUTION_LOG_PLAN_DirectOffersWorkContract_2026-03-07.md`.
3. **Follow-up:** Complete Fix Plan steps 1–2 as needed; optionally re-run CodeGuard (step 3).
