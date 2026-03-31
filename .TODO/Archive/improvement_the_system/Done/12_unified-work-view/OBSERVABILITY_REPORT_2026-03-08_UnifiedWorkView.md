# Observability Report: Unified Work View

**Scope:** Unified Work View (12_unified-work-view)  
**Plan:** `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`  
**Date:** 2026-03-08  
**Agent:** @Observability

---

## 1. Telemetry Gaps

### 1.1 What Is Logged (Evidence)

| Location | Event | Tag | Payload | Privacy |
|----------|--------|-----|---------|--------|
| `WorkManagementService.getUnifiedWorkItem` | Loaded from view | WorkManagement | `id`, `type` | ✅ No PII beyond entity id/type |
| `WorkManagementService.getUnifiedWorkItem` | Not found in view | WorkManagement | `id`, `type` | ✅ Same |
| `WorkManagementService.getUnifiedWorkItem` | Error | WorkManagement | error, stack | ✅ No user data |
| `DashboardRepository.fetchWorkItems` | Fetch start | dashboard.repo | role name | ✅ |
| `DashboardRepository.fetchWorkItems` | Fetch success | dashboard.repo | count, role | ✅ |
| `DashboardRepository.fetchWorkItems` | Error | dashboard.repo | error, stack | ✅ |
| `WorkItemDetailsViewModel.loadData` | View returned no row | (none) | id, type | ✅ |
| `WorkItemDetailsViewModel.loadData` | Details loaded | (none) | work_item_id, source_type, unified_status, needs_review, can_review | ✅ No user ids in payload |

All use `AppLogger` (no `print()`). ✅

### 1.2 Gaps

| Gap | Severity | Recommendation |
|-----|----------|----------------|
| **listUnifiedWorkItems** has no success log | LOW | Optional: log count when list succeeds (e.g. `AppLogger.d` with item count and userId hash or "list" only) for debugging empty lists. Not required for correctness. |
| **WorkItemDetailsViewModel** success log has no tag | LOW | Use a stable tag (e.g. `WorkDetails`) for filterability. |

### 1.3 What NOT to Log

- No `client_id` / `freelancer_id` in logs (only entity `id` and `type`). ✅  
- No conversation content or payment amounts in these paths. ✅  
- Stack traces only on error. ✅  

### 1.4 Correlation Strategy

- No correlation ID is passed today. Plan mentioned optional `correlationId` for approve delivery; not in scope for this view change. For future: if tracing is added, pass a request/correlation id from VM → Service and include in log json.

---

## 2. Event Taxonomy

- **Debug:** Fetch start, “loaded from view”, “not found in view”, “view returned no row”, “details loaded”, profile enrichment count.
- **Info:** Fetched N work items, enriched M/N.
- **Error:** Failed to fetch UnifiedWorkItem, Failed to fetch dashboard work items, Profile enrichment failed, WorkItemDetails load error.

All align with existing AppLogger usage. ✅

---

## 3. Summary

- **Observability:** Adequate. Critical paths (get by id, list for dashboard, not-found) have debug/error logs; no PII leaked.
- **Actions:** Optional: add tag to WorkDetails log; optional success log for listUnifiedWorkItems. No BLOCKER.
