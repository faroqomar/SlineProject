# Architect Report: Unified Work View

**Scope:** Unified Work View (12_unified-work-view)  
**Plan:** `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`  
**Date:** 2026-03-08  
**Agent:** @Architect

---

## 1. Architecture / Logic Findings

### 1.1 MVVM Boundary Check ✅

- **View layer:** No direct Supabase calls. Dashboard Work tab and Work detail screen consume `DashboardRepository` and `WorkItemDetailsViewModel` / `WorkManagementService` only. No UI → Supabase.
- **ViewModel:** `WorkItemDetailsViewModel` calls `_workService.getUnifiedWorkItem(id, type)` and sets `_error` when null; no direct DB access.
- **Service/Repository:** `WorkManagementService` and `DashboardRepository` are the only places querying `vw_unified_work_items`. Single source of truth respected.

**Evidence:**  
- `lib/features/work/services/work_management_service.dart` — `.from('vw_unified_work_items')` only.  
- `lib/features/dashboard/data/dashboard_repository.dart` — single query to `vw_unified_work_items`, no fallback tables.

### 1.2 Data Flow Map

```
vw_unified_work_items (Supabase)
    → WorkManagementService.getUnifiedWorkItem / listUnifiedWorkItems
    → DashboardRepository.fetchWorkItems (single query)
    → UnifiedWorkItemModel.fromJson (view row)
    → _mapUnifiedToWorkItem → WorkItem (task | booking | direct_offer)
    → UI (Work tab, Work detail)
```

- **Contract:** View columns match `UnifiedWorkItemModel.fromJson` and `.TODO/contract_vw_unified_work_items.md`. `source_type` and `conversation_id` handled.

### 1.3 Path and Contract Validation

- **UnifiedWorkItemModel** (`lib/features/work/models/unified_work_item_model.dart`): `conversationId` optional, `isDirectOffer` getter, `fromJson` reads `conversation_id` and all view columns. `_mapStatus` includes `disputed`, `pending_payment`. ✅
- **DashboardRepository._mapUnifiedToWorkItem:** Branch for `sourceType == 'direct_offer'` → `WorkItemType.directOffer`; passes `conversationId`. ✅
- **WorkItem** (`lib/features/dashboard/models/work_item.dart`): Has `conversationId`, `WorkItemType.directOffer`. No change required. ✅

### 1.4 Proposed Refactors / Fixes

| Finding | Severity | File / Location | Recommendation |
|--------|----------|-----------------|----------------|
| **listUnifiedWorkItems** passes raw `e` to `fromJson` | LOW | `work_management_service.dart:86-88` | Use `UnifiedWorkItemModel.fromJson(Map<String, dynamic>.from(e as Map))` for consistency with `getUnifiedWorkItem` and dashboard repo (avoids potential cast issues with Supabase response). |
| **Stale comment** in WorkItemDetailsViewModel | LOW | `work_item_details_view_model.dart:74` | Comment says "and booking fallback" but fallback was removed; rephrase to "work item (and optional booking for booking-type detail)". |

### 1.5 Contract Checks

- View returns 20 columns; model has 20 fields (including optional `conversationId`, `awardedRequestId`, `paymentDeadline`). ✅
- `source_type` values `task`, `booking`, `direct_offer` all mapped in `_mapUnifiedToWorkItem`. ✅
- No duplicate logic: single query path, no remaining fallback mapper references in lib. ✅

---

## 2. Summary

- **MVVM:** Compliant. No UI → Supabase; single source of truth from view.
- **Data flow:** Clear and aligned with plan. Contract respected.
- **Actions:** Two LOW-severity items (type-safe fromJson in listUnifiedWorkItems, comment update). No BLOCKER.
