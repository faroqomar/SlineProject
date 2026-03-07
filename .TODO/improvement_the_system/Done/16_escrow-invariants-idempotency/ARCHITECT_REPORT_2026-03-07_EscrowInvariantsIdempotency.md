# Architect Report: Escrow Invariants & Idempotency

**Scope:** EscrowInvariantsIdempotency  
**Plan:** `.TODO/PLAN_EscrowInvariantsIdempotency_2026-03-07_CRITIC.md`  
**Date:** 2026-03-07  
**Agent:** @Architect

---

## 1) Architecture / Logic Findings

### 1.1 MVVM Boundary Check

| Layer | Path | Finding | Evidence |
|-------|------|---------|----------|
| View | `lib/features/work/view/widgets/review_delivery_modal.dart` | ✅ No Supabase. Calls `widget.onApprove()` only. | No `Supabase.instance` or `.rpc()` in file. |
| ViewModel | `lib/features/work/viewmodels/work_item_details_view_model.dart` | ✅ Delegates to `_workService.approveDelivery()`. No direct DB. | `approveDelivery()` calls `_workService.approveDelivery(entityId, entityType)`. |
| Service | `lib/features/work/services/work_management_service.dart` | ✅ Single RPC call `_supabase.rpc('rpc_approve_delivery', ...)`. | Lines 267–277. |

**Verdict:** MVVM boundaries respected. View → ViewModel → Service → Supabase RPC. No UI direct backend calls.

### 1.2 Data Flow Map

- **Entry:** Work item details screen → Approve → `WorkItemDetailsViewModel.approveDelivery()` → `WorkManagementService.approveDelivery(entityId, entityType)` → `_supabase.rpc('rpc_approve_delivery', params)`.
- **Modal:** `ReviewDeliveryModal` receives `onApprove` callback (wired to VM’s `approveDelivery`). One-shot guard `_hasApproved` prevents double-tap; on error, guard reset allows retry.
- **Backend:** `rpc_approve_delivery` (SECURITY DEFINER) locks booking row (FOR UPDATE), computes stable idempotency key, calls `process_payment_event_ledger`; idempotency enforced in DB.

**Single source of truth:** Approval flow goes through one service method and one RPC; no duplicate approval paths found.

### 1.3 Contract Checks

- **RPC contract:** Params `entity_type`, `entity_id` unchanged. No new params; backward compatible.
- **Migration:** `20260307000001_escrow_idempotency_stable_key.sql` — function signature unchanged; only body changed (booking branch: FOR UPDATE + stable key). Task branch untouched.
- **CONTRACT:** `.TODO/.../16_escrow-invariants-idempotency/CONTRACT_escrow_idempotency_key.md` documents key formula and FOR UPDATE; aligns with migration.

### 1.4 Path / Name Validation

- `lib/features/work/services/work_management_service.dart` — exists; `approveDelivery` exists.
- `lib/features/work/view/widgets/review_delivery_modal.dart` — exists; `ReviewDeliveryModal`, `_handleApprove`, `_hasApproved` present.
- `lib/features/work/viewmodels/work_item_details_view_model.dart` — exists; `approveDelivery` present.
- `rpc_approve_delivery` — exists in DB (verified via MCP). `process_payment_event_ledger` — referenced in migration; exists.
- `journal_entries` — index drop targets `idx_journal_entries_idempotency`; confirmed dropped post-migration.

---

## 2) Proposed Refactors

- **None required.** Changes are minimal and scoped; no structural refactor needed.

---

## 3) Risks / Notes

- **Task branch:** Migration explicitly leaves task branch unchanged (no ledger call). Confirmed in SQL.
- **Replay behavior:** `process_payment_event_ledger` returns on idempotent key collision (verified in codebase); `rpc_approve_delivery` does not re-raise. No change required.

---

## 4) Summary

- **MVVM:** Compliant.  
- **Data flow:** Single path; no duplicate logic.  
- **Contract:** Unchanged API; docs and migration aligned.  
- **Paths/names:** Validated.  
- **Blockers:** None. Proceed to @Observability.
