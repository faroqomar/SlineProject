# Architect Report: Work Contract Revisions

**Scope:** Work Contract Revisions (RPC hardening + app error mapping + UI)  
**Plan:** `.TODO/PLAN_WorkContractRevisions_2025-03-08_PlanCritic.md`  
**Date:** 2025-03-08  
**Agent:** @Architect

---

## 1) Files Scanned

- `lib/core/utils/error_mapper.dart` (revision branches)
- `lib/features/work/viewmodels/work_item_details_view_model.dart` (requestRevision)
- `lib/features/work/services/work_management_service.dart` (requestRevision)
- `lib/features/work/view/widgets/review_delivery_modal.dart` (canRequestRevision, getRevisionError)
- `lib/features/work/view/work_item_details_screen.dart` (_showReviewModal)
- `supabase/migrations/20260308120000_harden_rpc_request_revision.sql`

---

## 2) MVVM Boundary Check

| Layer | Finding | Evidence |
|-------|---------|----------|
| View | No direct Supabase | `work_item_details_screen.dart` and `review_delivery_modal.dart` only use ViewModel (vm.requestRevision, vm.workItem, vm.error) and callbacks. No `Supabase.instance` or `.rpc()`. |
| ViewModel | Calls service only | `requestRevision` calls `_workService.requestRevision(...)`; sets `_error = ErrorMapper.map(e)` on catch. |
| Service | Single RPC call | `WorkManagementService.requestRevision` calls `_supabase.rpc('rpc_request_revision', ...)` and rethrows. |

**Verdict:** MVVM boundaries respected. View → ViewModel → Service → Supabase.

---

## 3) Data Flow Map

- **Request revision:** User taps "Request Changes" → modal `onReject(reason)` → `vm.requestRevision(reason)` → `_workService.requestRevision(entityId, entityType, note)` → RPC. On success: `loadData` refresh. On failure: `_error = ErrorMapper.map(e)`, `notifyListeners()`; modal catch uses `getRevisionError?.call()` → `vm.error` → SnackBar.
- **Revisions cap:** `workItem.revisionsUsed` / `workItem.revisionsTotal` come from `UnifiedWorkItemModel` (loaded via existing work item fetch). Single source of truth; no duplicate queries for revision counts.

---

## 4) Contract Checks

- **RPC contract:** Params `entity_type`, `entity_id`, `p_note` match migration and service. Exception messages ("Can only request revision on delivered work", "No revisions remaining", "Only client can request revision") documented in SUPABASE_SETUP §9.2 and mapped in ErrorMapper.
- **Modal contract:** `ReviewDeliveryModal` receives `canRequestRevision` (bool) and `getRevisionError` (callback). Screen passes `vm.workItem!.revisionsUsed < vm.workItem!.revisionsTotal` and `() => vm.error`. No ViewModel type leaked into view; callback keeps modal generic.

---

## 5) Proposed Refactors / Notes

| Item | Severity | Recommendation |
|------|----------|----------------|
| Consistency | LOW | `acceptChangeRequest` in same ViewModel still sets `_error = 'Failed to accept change request'`. For consistency, consider using `ErrorMapper.map(e)` there in a follow-up (out of scope for this plan). |
| Edge case | INFO | When `revisionsTotal == 0`, `revisionsUsed < revisionsTotal` is false; button disabled. Matches DB guard (COALESCE(revisions_total,0) allows no revisions). No change needed. |

---

## 6) Path / Name Validation

- All referenced paths exist: `error_mapper.dart`, `work_item_details_view_model.dart`, `work_management_service.dart`, `review_delivery_modal.dart`, `work_item_details_screen.dart`, migration file.
- RPC name `rpc_request_revision` matches migration and SUPABASE_SETUP.
- `UnifiedWorkItemModel.revisionsUsed` / `revisionsTotal` exist and are used correctly.

---

## 7) Conclusion

Architecture and MVVM compliance are satisfied. Data flow is clear, contract is aligned with DB and docs. One optional consistency improvement (ErrorMapper for acceptChangeRequest) noted for later. No blockers.
