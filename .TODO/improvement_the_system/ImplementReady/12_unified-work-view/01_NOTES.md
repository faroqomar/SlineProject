# Audit Notes: 12_unified-work-view

## Skills Selected

- **Repo Mapping**
- **Evidence-First Reading**
- **Threat Modeling (Security)**
- **State Machine & Lifecycle**
- **Diagram Crafting (Mermaid)**
- **RLS & Privilege Boundaries**

## Why these skills fit:

This diagram is about data aggregation (`vw_unified_work_items`) and its consumption in Flutter. Security (RLS) and Lifecycle mapping (State Machine) are the biggest risks here. Observability is key for a system that hides complexity.

## Skills intentionally not used:

- **Financial Modeling**: Handled by ledger, not this view.
- **Idempotency**: View is read-only.

---

## 1) System Evidence (Ground Truth)

### 1.1) Database View: `vw_unified_work_items`

- **File**: `supabase/migrations/Archive/20260315000000_award_to_work_cancel_and_view.sql:L91-183`
- **Current Structure**:
  - `Branch 1`: `tasks` (in_progress, delivered, completed)
  - `Branch 2`: `bookings` (active, delivered, completed)
  - `Branch 3`: `tasks` + `task_requests` (accepted/unpaid award state)
- **Status Mapping**:
  - `tasks.status: in_progress` → `unified_status: active`
  - `bookings.status: active` → `unified_status: active`
  - `awarded_unpaid` → `unified_status: pending_payment`

### 1.2) Flutter Model: `UnifiedWorkItemModel`

- **File**: `lib/features/work/models/unified_work_item_model.dart:L89-115`
- **Enum**: `UnifiedWorkStatus` in `lib/core/app_enums.dart:L75-85`
- **Gap**: The model handles `disputed`, but the SQL does not.

### 1.3) Flutter Service: `WorkManagementService`

- **File**: `lib/features/work/services/work_management_service.dart:L27-87`
- **Issue**: Implements a `_getTaskUnifiedWorkItemFallback` because the view is inconsistent or inaccessible under some RLS conditions (specifically when `assigned_freelancer_id` is null but an award exists).

---

## 2) Critical Gaps Identified

### G1: Direct Offers Missing

`SUPABASE_SETUP.md:L669-693` defines `direct_offers` (v2.17). These are not in the view. They must be added as a 4th branch.

### G2: Dispute Status Handling

The system has a `disputes` table, and `UnifiedWorkStatus` includes `disputed`. The view should join with `disputes` or check status on source tables to show work as "Disputed".

### G3: RLS & Shadowing

The view `vw_unified_work_items` doesn't have explicit RLS documentation. In a UNION ALL view, if one branch has a leak, the whole view is compromised. The service layer manually filters by `client_id` or `freelancer_id`, but the view should be `SECURITY_INVOKER` to respect source table RLS.

### G4: Metadata Inconsistency

`Branch 1` uses `COALESCE(t.budget, 0)`, while `Branch 2` uses `b.price` and `Branch 3` uses `tr.price`. This is correct but risks desync if price logic changes.

---

## 3) Preliminary Score

**Score NOW: 6/10**
**Reason**: Functional but incomplete. Missing `direct_offers` breaks the "Unified" promise. The fallback in the service is a maintenance debt.
