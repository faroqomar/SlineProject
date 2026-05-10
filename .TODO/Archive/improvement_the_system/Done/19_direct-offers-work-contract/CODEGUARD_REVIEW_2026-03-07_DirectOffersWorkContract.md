# CodeGuard Review: Direct Offers Work Contract (Plan 19)

**Scope:** DirectOffersWorkContract (Plan 19)  
**Plan:** `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/PLAN_DirectOffersWorkContract_2026-03-07.md`  
**Date:** 2026-03-07  
**Agent:** @CodeGuard (per `.agents/workflows/Orchestrator.md` pipeline)

---

## 1. Review Mode

**STANDARD** — Business logic (service), DB migrations (admin views, trigger, RPC), security-sensitive (admin refund). No UI-only change.

---

## 2. Performance

- **N+1:** DirectOffersService uses getOffer per call; getOffersByIds exists for batch (ChatViewModel). No new N+1 introduced. ✅
- **Migrations:** Admin views are LEFT JOINs on existing tables; no heavy computation. Self-offer trigger is a simple equality check. Admin RPC uses FOR UPDATE and single-row operations. ✅
- **Flutter:** No new rebuild storms or heavy work in view layer. ✅

**Performance:** No issues identified.

---

## 3. Security

- **RLS:** direct_offers RLS unchanged. Admin views live in `admin` schema; no GRANT to anon/authenticated (service_role only). ✅
- **Admin RPC:** Explicit check `auth.uid() IN (SELECT id FROM public.admin_users)`; REVOKE EXECUTE FROM anon; GRANT to authenticated + service_role. Non-admin authenticated users get exception from function body. ✅
- **Secrets:** No tokens or API keys in code or migrations. ✅
- **SECURITY DEFINER:** admin_refund_direct_offer and fn_direct_offer_guard_insert use SET search_path = public. ✅
- **Idempotency:** admin_refund_direct_offer uses idempotency_key and returns existing journal_entry_id on replay. ✅

**Security:** No blockers. Least privilege and admin check in place.

---

## 4. Compatibility

- **Supabase:** Migrations use standard Postgres (schema, views, trigger, function, REVOKE/GRANT). Enum casts use public.payment_event_type_enum and public.related_entity_type_enum — match existing schema. ✅
- **Flutter:** No new dependencies. AppLogger and existing Supabase/Ledger usage unchanged. ✅

**Compatibility:** No issues.

---

## 5. SLine Compliance

- **MVVM:** All backend access in DirectOffersService; no Supabase in view. ✅
- **Single source of truth:** One service per operation; no duplicate payment paths. ✅
- **AppLogger:** Used throughout; no print() in changed files. ✅

---

## 6. Verification Commands

```bash
flutter analyze lib/features/direct_offers/
# Expected: No issues found.
```

```sql
-- Verify admin objects (run as service_role)
SELECT COUNT(*) FROM admin.vw_direct_offer_money_story;
SELECT COUNT(*) FROM admin.vw_direct_offer_stuck_funds;
-- Verify non-admin cannot call (as authenticated non-admin): expect exception
SELECT admin_refund_direct_offer('00000000-0000-0000-0000-000000000000', 'test', 'key');
```

---

## 7. Risk Rating

| Risk | Level | Mitigation |
|------|--------|------------|
| Admin RPC abuse | LOW | admin_users check; REVOKE anon |
| View leakage | LOW | admin schema not granted to anon/authenticated |
| Self-offer guard | LOW | Trigger prevents bad INSERT |
| Schema drift (delivered_at etc.) | MED | Verify direct_offers columns; sync docs |

**Overall risk:** LOW. No critical or blocker issues.

---

## 8. Decision

**APPROVED ✅**

No BLOCKER. One MED finding (schema/doc alignment for direct_offers columns) and optional LOW items (logging consistency, §5.14 column list). Safe to merge; recommend resolving schema/docs alignment in a follow-up.
