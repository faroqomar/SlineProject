# CodeGuard Review: Unified Work View

**Scope:** Unified Work View (12_unified-work-view)  
**Plan:** `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`  
**Date:** 2026-03-08  
**Agent:** @CodeGuard

---

## 1. Performance

| Check | Result | Evidence |
|-------|--------|----------|
| Single query for list | ✅ | `DashboardRepository.fetchWorkItems` — one select from view, no N+1. |
| Filter at DB | ✅ | `client_id` / `freelancer_id` in query; view uses security_invoker so RLS applies. |
| Profile enrichment | ✅ | Batch `fetchByIds`; no per-item profile fetch. |
| listUnifiedWorkItems | ✅ | Single view query; ordering by sort_rank, last_activity_at. |

No pagination on view list (existing behavior); acceptable for "My Work" list size. No BLOCKER.

---

## 2. Security

| Check | Result | Evidence |
|-------|--------|----------|
| View RLS | ✅ | Migration creates view with `WITH (security_invoker = true)`. RLS on tasks, bookings, task_requests, direct_offers applies. |
| No sensitive data in logs | ✅ | Only id, type, count, role; no client_id/freelancer_id or PII in log payloads. |
| UI → Supabase | ✅ | No direct Supabase in views; all via service/repository. |

RLS check matrix in `.TODO/RLS_check_unified_work_view.md`. No BLOCKER.

---

## 3. Compatibility

| Check | Result | Evidence |
|-------|--------|----------|
| View column contract | ✅ | 20 columns; model and fromJson match. Optional `conversation_id` for backward compatibility if rollback view (19 cols) is used. |
| WorkItemType.directOffer | ✅ | Already present; dashboard and next actions already support it. |
| fromJson type safety | ⚠️ LOW | `WorkManagementService.listUnifiedWorkItems` uses `fromJson(e)`; Supabase may return Map. Prefer `Map<String, dynamic>.from(e as Map)` for consistency. |

No BLOCKER.

---

## 4. Risk Rating

| Area | Rating | Notes |
|------|--------|------|
| Security | LOW | security_invoker, no PII in logs. |
| Performance | LOW | Single query, batch enrichment. |
| Compatibility | LOW | Optional model field; one minor fromJson consistency fix. |
| Regression | LOW | Tests added for view contract; fallback mapper removed cleanly. |

**Overall:** LOW risk.

---

## 5. Verification Commands

```bash
flutter analyze lib/features/work lib/features/dashboard/data/dashboard_repository.dart
flutter test test/unit/work/unified_work_item_view_contract_test.dart test/unit/models/unified_work_item_model_test.dart
```

Grep for no remaining fallback references in lib:

```bash
rg -n "UnifiedWorkItemFallbackMapper|_fetchAwardedPendingPaymentFallback|_fetchDirectOffers" lib/
# Expected: 0 matches
```

---

## 6. Decision

**APPROVED ✅** — No BLOCKER. Optional LOW-severity fixes (fromJson cast, comment, optional logging/tag) may be applied in a follow-up.
