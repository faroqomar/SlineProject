# Architect Report: Dispute Lifecycle Implementation

**Scope:** Dispute Lifecycle (escrow guard, RLS, dispute status enum, UI dispute guards, Submit Evidence wiring)  
**Plan:** `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`  
**Execution log:** `.TODO/EXECUTION_LOG_DisputeLifecycle_2026-03-08.md`  
**Date:** 2026-03-08  
**Agent:** @Architect

---

## 1. Architecture / Logic Findings (MVVM Boundary Check)

### 1.1 Views do NOT call Supabase

- **booking_details_screen.dart:** No direct Supabase usage. Uses `context.read<BookingViewModel>()`, `context.read<SafetyViewModel>()`. Dispute check via `_ApproveWithDisputeGuard` → `SafetyViewModel.hasOpenDisputeForTask(taskId)`.
- **work_item_details_screen.dart:** No direct Supabase usage. Uses `WorkItemDetailsViewModel`, `SafetyViewModel`. Dispute guard via `_ReviewWithDisputeGuard` → `SafetyViewModel.hasOpenDisputeForBooking(entityId)` or `hasOpenDisputeForTask(entityId)`. Disputed banner from `vm.status == UnifiedWorkStatus.disputed` (ViewModel state from unified work item).
- **direct_offer_details_screen.dart:** No direct Supabase usage. Uses `DirectOfferDetailsViewModel`, `SafetyViewModel`. Dispute guard via `_ApproveWithDisputeGuard` → `SafetyViewModel.hasOpenDisputeForDirectOffer(offerId)`.

**Verdict:** MVVM boundary is respected; no View calls Supabase directly.

### 1.2 Single source of truth for “has open dispute”

- **CTA / Approve gating:** All three screens use **SafetyViewModel** → **DisputeService** for the live “has open dispute?” check. That is one code path (service + viewmodel).
- **Dashboard / list state:** Disputed state for list and buckets comes from **vw_unified_work_items** (`unified_status = 'disputed'`) via dashboard repository → `UnifiedWorkStatus.disputed`. This is a second source (view column) used for display and permission buckets, not for the Approve button.
- **Detail screens:** Use the **live** check (SafetyViewModel) to enable/disable Approve/Review. Work item details also show `_buildDisputedBanner` when `vm.status == UnifiedWorkStatus.disputed` (from the same unified work load that includes the view’s disputed flag).

So there are two intentional sources:
1. **DisputeService** (via SafetyViewModel): authoritative for **gating Approve/Review** on detail screens.
2. **vw_unified_work_items.unified_status**: used for **dashboard buckets**, list display, and “disputed” banner on work item details.

Both rely on the same business rule (open/active dispute). No duplicate dispute lookup logic in the UI layer; Views only call ViewModels/Services.

### 1.3 Logic bug: direct_offer not handled in Review guard

**File:** `lib/features/work/view/work_item_details_screen.dart`  
**Widget:** `_ReviewWithDisputeGuard` (lines 757–789)

The guard branches only on `sourceType == 'booking'`; otherwise it calls `hasOpenDisputeForTask(entityId)`:

```dart
final Future<bool> hasDisputeFuture = sourceType == 'booking'
    ? safetyVm.hasOpenDisputeForBooking(entityId)
    : safetyVm.hasOpenDisputeForTask(entityId);
```

For a work item with **sourceType == 'direct_offer'**, `entityId` is the **direct_offer** id. Calling `hasOpenDisputeForTask(entityId)` queries `disputes` by **task_id**, so the check is wrong and can allow Review when a direct-offer dispute exists, or block incorrectly.

**Required fix:** Add a branch for `sourceType == 'direct_offer'` and call `safetyVm.hasOpenDisputeForDirectOffer(entityId)`.

---

## 2. Data Flow Map (Where Dispute Check Is Called, Who Calls SafetyViewModel)

| Call site | View | Method used | Flow |
|-----------|------|-------------|------|
| Booking “Approve & Release” | booking_details_screen | `_ApproveWithDisputeGuard` | `SafetyViewModel.hasOpenDisputeForTask(booking.taskId)` → DisputeService.hasOpenDisputeForTask |
| Direct offer “Approve & release payment” | direct_offer_details_screen | `_ApproveWithDisputeGuard` | `SafetyViewModel.hasOpenDisputeForDirectOffer(offerId)` → DisputeService.hasOpenDisputeForDirectOffer |
| Work item “Review” button | work_item_details_screen | `_ReviewWithDisputeGuard` | `SafetyViewModel.hasOpenDisputeForBooking(entityId)` or `hasOpenDisputeForTask(entityId)` (no direct_offer branch) |

**SafetyViewModel** is registered in `lib/main.dart` (line 229):  
`ChangeNotifierProvider(create: (_) => SafetyViewModel())`.  
All three screens use `context.read<SafetyViewModel>()`; no View creates or holds a SafetyViewModel instance.

**Dashboard / CTA:** Disputed state for list and primary action comes from `vw_unified_work_items` (dashboard_repository, dashboard_view_model) and `dashboard_permission_service` (UnifiedWorkStatus.disputed → submitEvidence). No SafetyViewModel used there; single source for that path is the view.

---

## 3. Path / Name Validation

### 3.1 Files scanned (all exist)

| File | Status |
|------|--------|
| lib/features/safety/services/dispute_service.dart | ✅ Exists |
| lib/features/safety/viewmodels/safety_view_model.dart | ✅ Exists |
| lib/features/booking/view/booking_details_screen.dart | ✅ Exists |
| lib/features/work/view/work_item_details_screen.dart | ✅ Exists |
| lib/features/direct_offers/view/direct_offer_details_screen.dart | ✅ Exists |
| supabase/migrations/20260308140000_dispute_lifecycle_escrow_guard_rls.sql | ✅ Exists |
| supabase/migrations/20260308150000_dispute_enum_guard_resolved_at.sql | ✅ Exists |

### 3.2 DB objects referenced (implementation vs migrations / SUPABASE_SETUP)

| Object | Referenced in | Status |
|--------|----------------|--------|
| `disputes` | dispute_service (from 'disputes'), migrations | ✅ Table in SUPABASE_SETUP §5.24 |
| `dispute_messages` | migration 20260308140000 | ✅ Table in SUPABASE_SETUP §5.25 |
| `dispute_evidence` | migration 20260308140000 | ✅ Table in SUPABASE_SETUP §5.26 |
| `bookings` (task_id) | dispute_service.hasOpenDisputeForBooking, migration (booking branch) | ✅ |
| `rpc_approve_delivery` | migration 20260308140000 (CREATE OR REPLACE) | ✅ §9.5 |
| `rpc_finalize_auto_approval` | migration 20260308140000 (CREATE OR REPLACE) | ✅ §9.4 |
| `vw_unified_work_items` | migration 20260308150000 (recreate), dashboard, work item model | ✅ View recreated with enum-safe disputed check |
| `dispute_status_enum` | migration 20260308150000 | ✅ Created in same migration |
| `fn_dispute_guard`, `trg_dispute_guard` | migration 20260308150000 | ✅ |
| `fn_dispute_set_resolved_at`, `trg_dispute_set_resolved_at` | migration 20260308150000 | ✅ |

All referenced paths and DB object names exist and match.

---

## 4. Proposed Refactors

### 4.1 (Required) Handle direct_offer in _ReviewWithDisputeGuard

**File:** `lib/features/work/view/work_item_details_screen.dart`  
**Widget:** `_ReviewWithDisputeGuard` (lines 769–774)

**Change:** Add an explicit branch for `direct_offer` so the correct service method is used.

```dart
final Future<bool> hasDisputeFuture;
if (sourceType == 'booking') {
  hasDisputeFuture = safetyVm.hasOpenDisputeForBooking(entityId);
} else if (sourceType == 'direct_offer') {
  hasDisputeFuture = safetyVm.hasOpenDisputeForDirectOffer(entityId);
} else {
  hasDisputeFuture = safetyVm.hasOpenDisputeForTask(entityId);
}
```

This keeps a single source of truth (SafetyViewModel → DisputeService) and aligns the guard with the DB (disputes.direct_offer_id) and with direct_offer_details_screen behavior.

### 4.2 (Optional) UX: Booking details guard when taskId is null

**File:** `lib/features/booking/view/booking_details_screen.dart`  
**Widget:** `_ApproveWithDisputeGuard` (lines 458–462)

When `taskId.isEmpty`, the widget currently shows the button enabled and calls `onRelease`. The RPC will still reject if the booking branch runs (entity_id = booking id); the guard uses task_id from the row. So behavior is safe, but the button could be disabled with a tooltip (“Task data missing”) for consistency with `_showDisputeDialog`, which blocks and shows a message when taskId is missing. Low priority.

### 4.3 (Optional) Reduce duplicate FutureBuilder pattern

The same pattern (FutureBuilder + SafetyViewModel.hasOpenDispute* + “Checking…” / disable when true) appears in three places. A small shared widget (e.g. `DisputeAwareActionButton`) could take `Future<bool> hasDisputeFuture`, label, and onPressed callback to avoid repetition. Not required for correctness.

---

## 5. Contract Checks (RPC / RLS vs Implementation)

### 5.1 Escrow guard alignment

- **rpc_approve_delivery:** Task branch checks `disputes WHERE task_id = entity_id AND status IN ('open','active')`. Booking branch gets `v_task_id` from `bookings WHERE id = entity_id`, then same EXISTS on task_id. Direct_offer branch checks `disputes WHERE direct_offer_id = entity_id AND status IN ('open','active')`. All raise before releasing.
- **DisputeService:** `hasOpenDisputeForTask` / `hasOpenDisputeForDirectOffer` use `.in_('status', ['open', 'active'])`. `hasOpenDisputeForBooking` loads `task_id` from bookings then calls `hasOpenDisputeForTask`. Status set and checked match the RPC.

### 5.2 RLS assumptions

- Migration adds **deny** policies: `disputes_deny_update`, `disputes_deny_delete` (USING (false)). App does not UPDATE/DELETE disputes; only INSERT (submit) and SELECT (has-open check). Consistent.
- **dispute_messages** / **dispute_evidence:** Participant-only SELECT/INSERT in migration. App currently uses DisputeService for submit and has-open only; no messages/evidence API in scope. No conflict.

### 5.3 Enum and view

- **20260308150000:** status becomes `dispute_status_enum` ('open','active','resolved','canceled'); trigger restricts transitions; resolved_at set on status → resolved. View recreated with `d.status IN ('open', 'active')` for disputed. Flutter still uses string status from API; Supabase client returns enum as string. No contract break.

### 5.4 Safe default on error

DisputeService returns **true** (treat as “has dispute”) on catch in all three hasOpen* methods, so Approve/Review stay disabled on failure. Aligns with plan (fail closed).

---

## 6. Evidence: Files Scanned and Key References

### 6.1 Files scanned

- `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`
- `.TODO/EXECUTION_LOG_DisputeLifecycle_2026-03-08.md`
- `lib/features/safety/services/dispute_service.dart` (full)
- `lib/features/safety/viewmodels/safety_view_model.dart` (full)
- `lib/features/booking/view/booking_details_screen.dart` (full)
- `lib/features/work/view/work_item_details_screen.dart` (full)
- `lib/features/direct_offers/view/direct_offer_details_screen.dart` (full)
- `supabase/migrations/20260308140000_dispute_lifecycle_escrow_guard_rls.sql` (full)
- `supabase/migrations/20260308150000_dispute_enum_guard_resolved_at.sql` (full)
- `lib/main.dart` (SafetyViewModel provider)
- `lib/features/work/models/unified_work_item_model.dart` (sourceType, isDirectOffer)
- `lib/features/dashboard/data/dashboard_repository.dart` (_mapUnifiedStatusToBucket, disputed)
- `lib/features/dashboard/services/dashboard_permission_service.dart` (disputed → submitEvidence)
- `Sline_everything/SUPABASE_SETUP.md` (disputes, dispute_messages, dispute_evidence, §9.4, §9.5)

### 6.2 Key line/symbol references

| Location | Symbol / line | Note |
|----------|----------------|------|
| dispute_service.dart | `hasOpenDisputeForTask` (40–67) | Task check; error → true |
| dispute_service.dart | `hasOpenDisputeForDirectOffer` (70–98) | Direct offer check |
| dispute_service.dart | `hasOpenDisputeForBooking` (101–121) | Booking → task_id then task check |
| safety_view_model.dart | `hasOpenDisputeForTask/ForDirectOffer/ForBooking` (50–62) | Delegation to service |
| booking_details_screen.dart | `_ApproveWithDisputeGuard` (453–489) | FutureBuilder, hasOpenDisputeForTask(taskId) |
| booking_details_screen.dart | 646 | future: hasOpenDisputeForTask(taskId) |
| work_item_details_screen.dart | `_buildDisputedBanner` (184–208) | vm.status == UnifiedWorkStatus.disputed |
| work_item_details_screen.dart | `_ReviewWithDisputeGuard` (457–489) | sourceType booking vs else; missing direct_offer |
| work_item_details_screen.dart | 771–774 | hasDisputeFuture: booking → ForBooking, else ForTask |
| direct_offer_details_screen.dart | `_ApproveWithDisputeGuard` (394–429) | hasOpenDisputeForDirectOffer(offerId) |
| direct_offer_details_screen.dart | 433 | future: hasOpenDisputeForDirectOffer(offerId) |
| main.dart | 229 | ChangeNotifierProvider SafetyViewModel |
| 20260308140000 | 29–31, 45–46, 81–84 | Escrow guard task, booking, direct_offer; rpc_finalize_auto_approval task/booking |
| 20260308140000 | 191–248 | RLS dispute_messages, dispute_evidence; indexes |
| 20260308150000 | 71–77, 110–111, 167–168 | vw_unified_work_items disputed: d.status IN ('open','active') |

---

## Summary

- **MVVM:** No View calls Supabase; dispute gating goes through SafetyViewModel → DisputeService. Single source for “has open dispute” in the UI is SafetyViewModel (dashboard uses vw_unified_work_items for list/buckets only).
- **Bug:** `_ReviewWithDisputeGuard` must handle `sourceType == 'direct_offer'` with `hasOpenDisputeForDirectOffer(entityId)`.
- **Paths/DB:** All referenced files and DB objects exist; RPC/RLS and app status checks align; safe default on error is in place.
- **Recommended:** Implement the direct_offer branch in `_ReviewWithDisputeGuard`; optional improvements for empty taskId and shared button widget can follow.
