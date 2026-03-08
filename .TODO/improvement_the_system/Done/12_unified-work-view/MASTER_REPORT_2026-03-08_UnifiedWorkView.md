# Master Report: Unified Work View (Orchestrator)

**Scope:** Unified Work View (12_unified-work-view)  
**Plan:** `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`  
**Date:** 2026-03-08  
**Pipeline:** @Architect → @Observability → @SlineDocs → @CodeGuard

---

## A) Executive Summary

- **What was reviewed:** All code and docs changed for the Unified Work View implementation: view upgrade (4 branches, disputes, security_invoker, conversation_id), removal of fallback mappers, single source of truth in `WorkManagementService` and `DashboardRepository`, `UnifiedWorkItemModel` and `WorkItem` mapping for `direct_offer`, AppLogger usage, tests, and documentation (SUPABASE_SETUP §6.4, DEVELOPER_GUIDE).
- **Overall risk level:** LOW. MVVM respected, single query path, no PII in logs, view RLS via security_invoker.
- **Final decision:** **Ready ✅** — No BLOCKER. Optional LOW-severity fixes below.

---

## B) Consolidated Findings (Deduplicated)

### Security

| # | Finding | Severity | Owner | File / Object | Fix |
|---|---------|----------|--------|----------------|-----|
| 1 | View RLS enforced via security_invoker | — | — | vw_unified_work_items | No change. ✅ |
| 2 | No sensitive data in new logs | — | — | WorkManagement, dashboard.repo, VM | No change. ✅ |

### Data Integrity

| # | Finding | Severity | Owner | File / Object | Fix |
|---|---------|----------|--------|----------------|-----|
| 3 | fromJson in listUnifiedWorkItems receives raw `e` | LOW | @Architect | `work_management_service.dart:86-88` | Use `UnifiedWorkItemModel.fromJson(Map<String, dynamic>.from(e as Map))` for type safety and consistency. |

### Architecture / MVVM

| # | Finding | Severity | Owner | File / Object | Fix |
|---|---------|----------|--------|----------------|-----|
| 4 | MVVM boundaries respected; single source of truth | — | — | All touched files | No change. ✅ |
| 5 | Stale comment "and booking fallback" | LOW | @Architect | `work_item_details_view_model.dart:74` | Rephrase to "work item (and optional booking for booking-type detail)". |

### Performance

| # | Finding | Severity | Owner | File / Object | Fix |
|---|---------|----------|--------|----------------|-----|
| 6 | Single view query; batch profile enrichment | — | — | DashboardRepository | No change. ✅ |

### Observability

| # | Finding | Severity | Owner | File / Object | Fix |
|---|---------|----------|--------|----------------|-----|
| 7 | AppLogger used; no print() | — | — | All | No change. ✅ |
| 8 | WorkItemDetailsViewModel success log has no tag | LOW | @Observability | `work_item_details_view_model.dart` | Add tag e.g. `WorkDetails` for filterability. |
| 9 | listUnifiedWorkItems has no success log | LOW | @Observability | `work_management_service.dart` | Optional: add AppLogger.d with count on success. |

### Docs / Reference Integrity

| # | Finding | Severity | Owner | File / Object | Fix |
|---|---------|----------|--------|----------------|-----|
| 10 | SUPABASE_SETUP §6.4 and DEVELOPER_GUIDE updated | — | — | — | No change. ✅ |
| 11 | Sline_Log.md may still mention UnifiedWorkItemFallbackMapper | MED | @SlineDocs | `Sline_everything/Sline_Log.md` | Optional: remove or soften reference in changelog/history. |

---

## C) Fix Plan (Ordered, Step-by-Step)

Optional (non-blocking) fixes; can be done in one small follow-up.

| Step | Owner | Action | Verification |
|------|--------|--------|--------------|
| 1 | @Architect | In `work_management_service.dart`, change `listUnifiedWorkItems` to use `UnifiedWorkItemModel.fromJson(Map<String, dynamic>.from(e as Map))`. | `flutter analyze`; `flutter test test/unit/work/`. |
| 2 | @Architect | In `work_item_details_view_model.dart`, update comment at line 74 to remove "and booking fallback". | Read-through. |
| 3 | @Observability | Add tag `WorkDetails` (or similar) to success log in WorkItemDetailsViewModel loadData. | Grep for tag. |
| 4 | @Observability | (Optional) Add debug log in listUnifiedWorkItems with item count on success. | Grep for log. |
| 5 | @SlineDocs | (Optional) In Sline_Log.md, adjust or remove reference to UnifiedWorkItemFallbackMapper if present. | Grep Sline_Log for fallback mapper. |
| 6 | @CodeGuard | Re-run `flutter analyze` and tests; confirm no new issues. | All pass. |

---

## D) Regression Checklist

- **My Work list:** As client and freelancer, open Dashboard → Work tab; list loads from view (task, booking, direct_offer if present); no crash.
- **Work detail:** Open a task, booking, and direct_offer from the list; detail loads or shows "Work item not found" when view has no row.
- **Not-found:** Use invalid id/type; expect "Work item not found" and no crash.
- **Pay / Review:** For pending_payment and delivered items, primary actions (Pay, Review) still resolve correctly from permissions.
- **Unit tests:** `flutter test test/unit/work/unified_work_item_view_contract_test.dart test/unit/models/unified_work_item_model_test.dart` — pass.
- **Grep:** `rg "UnifiedWorkItemFallbackMapper|_fetchAwardedPendingPaymentFallback|_fetchDirectOffers" lib/` → 0 matches.

---

## E) Rollback Notes

- **DB:** Run `supabase/migrations/20260308100000_rollback_unified_work_view.sql` (or apply via Supabase MCP/dashboard) to restore 3-branch view. App model has optional `conversationId` so old view (19 columns) still works.
- **App:** Revert commit(s) that removed fallback mapper and added direct_offer in _mapUnifiedToWorkItem if needed; restore `unified_work_item_fallback_mapper.dart` and usages from version control if full rollback required.
- **Order:** Prefer DB rollback first if view is broken; then app revert if necessary.

---

## F) Next Actions

1. **Ship as-is** — Implementation is Ready; no BLOCKER.
2. ~~**Optional:** Apply fix plan steps 1–5~~ **Done (2026-03-08):** All report fixes applied — type-safe fromJson in listUnifiedWorkItems, comment updated, WorkDetails tag and success log in VM, listUnifiedWorkItems success log, Sline_Log.md updated (fallback mapper → single source of truth). `flutter analyze` and unit tests pass.
3. **Verification:** Run regression checklist before release.
