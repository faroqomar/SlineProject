# Architect Report: 14a Dispute Extension

**Date:** 2026-03-08  
**Scope:** Plan 14a (Phases 6–9) — Frozen guards, partial unique indexes, `rpc_submit_dispute`, task/direct_offer dispute UI, open/active banners.  
**Plan:** `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`  
**Spec:** `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md`

---

## 1. Architecture / Logic Findings

### 1.1 MVVM Boundaries — **COMPLIANT**

- **Views:** No direct Supabase usage in any of the three screens. Verified:
  - `lib/features/work/view/work_item_details_screen.dart` — no `Supabase.instance`, `.from()`, or `.rpc()`.
  - `lib/features/booking/view/booking_details_screen.dart` — same.
  - `lib/features/direct_offers/view/direct_offer_details_screen.dart` — same.
- **Data flow:** Dispute state flows correctly:
  - **Service:** `DisputeService` owns all Supabase/RPC calls (`rpc_submit_dispute`, `disputes` select for hasOpen/getStatus, `bookings` select for booking→task_id).
  - **ViewModel:** `SafetyViewModel` exposes `hasOpenDisputeForTask/ForBooking/ForDirectOffer`, `getDisputeStatusForTask/ForBooking/ForDirectOffer`, and `submitDispute`; uses `_disputeService` only; maps errors via `ErrorMapper` and fallbacks in `_mapError`.
  - **UI:** Screens use `context.read<SafetyViewModel>()` for dispute checks and submit; work item details use `WorkItemDetailsViewModel` for submit delivery/request revision and `ErrorMapper.map(e)` for those errors.
- **Guards/banners:** Implemented as view-level widgets that call VM/service through `SafetyViewModel` only (e.g. `_DisputeBannerContent`, `_ReportIssueGuard`, `_ReviewWithDisputeGuard`, `_DirectOfferDisputeBanner`, `_ReportIssueGuardDirectOffer`, `_ApproveWithDisputeGuard`, `_BookingDisputeBanner`). No direct DB access.

### 1.2 Data Flow Summary

| Concern              | Source of truth     | Consumed by UI via                          |
|----------------------|--------------------|---------------------------------------------|
| Has open/active dispute | DisputeService → SafetyViewModel | FutureBuilder + hasOpenDispute*             |
| Dispute status (open/active) | DisputeService → SafetyViewModel | FutureBuilder + getDisputeStatus* (banners)  |
| Submit dispute       | SafetyViewModel → DisputeService → rpc_submit_dispute | Report Issue dialogs                         |
| Submit delivery error | WorkManagementService (rethrow) → WorkItemDetailsViewModel (ErrorMapper.map) | SnackBar / vm.error in modals                |
| Request revision error | Same as above       | Same                                        |

---

## 2. Contract Checks

### 2.1 RPC `rpc_submit_dispute` — Params vs DisputeService — **MATCH**

- **Migration:** `p_task_id uuid DEFAULT NULL`, `p_direct_offer_id uuid DEFAULT NULL`, `p_reason text DEFAULT NULL`, `p_defendant_id uuid DEFAULT NULL`.
- **DisputeService** (`lib/features/safety/services/dispute_service.dart`): builds params `p_task_id`, `p_direct_offer_id`, `p_reason`, `p_defendant_id`; validates exactly one of taskId/directOfferId and non-empty reason; calls `_client.rpc('rpc_submit_dispute', params: params)`.
- **Conclusion:** Parameter names and semantics align. App does not use the returned uuid; RPC returns uuid — no conflict.

### 2.2 Eligibility Rules vs 14a §5 — **MATCH**

- **Spec §5:**  
  - Task: `in_progress` \| `delivered`.  
  - Direct offer: `active` \| `delivered`.  
  - Booking: `active` \| `delivered` (booking disputes use `task_id`; eligibility enforced on task in RPC when caller passes task_id from booking).
- **Migration `rpc_submit_dispute`:**  
  - Task: `_status NOT IN ('in_progress', 'delivered')` → raise.  
  - Direct offer: `_status NOT IN ('active', 'delivered')` → raise.  
- **Conclusion:** Backend eligibility matches 14a §5. Booking disputes are submitted with `taskId: booking.taskId`; task branch in RPC enforces task status.

### 2.3 Frozen Guards — rpc_submit_delivery / rpc_request_revision

- **Migration:** Both RPCs check at start: for `entity_type = 'task'` — EXISTS dispute on `task_id = entity_id` with status IN ('open','active'); for `entity_type = 'booking'` — resolve task_id from bookings then same EXISTS. On match, raise `Cannot submit delivery: dispute in progress` / `Cannot request revision: dispute in progress`.
- **App:** `WorkManagementService.submitDelivery` and `requestRevision` pass `entity_type` and `entity_id`; used from work item details for **task** and **booking** only (unified work item id/type). Direct offers use a different flow (`DirectOfferDetailsViewModel.markDelivered`, not `rpc_submit_delivery`).
- **Conclusion:** No `direct_offer` branch in `rpc_submit_delivery` / `rpc_request_revision`; app does not call these RPCs with `entity_type = 'direct_offer'`. Contract is consistent. If a future change calls these RPCs for direct_offer, the migration would need a direct_offer Frozen branch.

### 2.4 ErrorMapper vs RPC Messages — **MATCH**

| RPC / guard message (migration) | ErrorMapper handling (lib/core/utils/error_mapper.dart) |
|--------------------------------|----------------------------------------------------------|
| `Cannot submit delivery: dispute in progress` | Mapped to user message |
| `Cannot request revision: dispute in progress` | Mapped to user message |
| `Entity not eligible for dispute: task must be...` / `...direct offer must be...` | `Entity not eligible for dispute` → friendly message |
| `An open or active dispute already exists for this task` / `...for this direct offer` | `open or active dispute already exists` → friendly message |
| `Reason is required` | Mapped |
| `Exactly one of task_id or direct_offer_id must be provided` | `Exactly one of task_id or direct_offer_id` → friendly message |

---

## 3. Path and Naming Validation

### 3.1 Files — **ALL EXIST**

| Referenced path | Status |
|----------------|--------|
| `supabase/migrations/20260308160000_14a_dispute_extension_frozen_guards.sql` | Exists, read and validated |
| `lib/features/safety/services/dispute_service.dart` | Exists |
| `lib/features/safety/viewmodels/safety_view_model.dart` | Exists |
| `lib/core/utils/error_mapper.dart` | Exists |
| `lib/features/work/viewmodels/work_item_details_view_model.dart` | Exists |
| `lib/features/work/services/work_management_service.dart` | Exists |
| `lib/features/work/view/work_item_details_screen.dart` | Exists |
| `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Exists |
| `lib/features/booking/view/booking_details_screen.dart` | Exists |

### 3.2 DB Objects (migration)

| Object | Name in migration | Plan / spec |
|-------|-------------------|-------------|
| RPC | `rpc_submit_delivery(entity_type, entity_id, note)` | Restored with Frozen guard (task, booking) |
| RPC | `rpc_request_revision(entity_type, entity_id, p_note)` | Frozen guard (task, booking) |
| RPC | `rpc_submit_dispute(p_task_id, p_direct_offer_id, p_reason, p_defendant_id)` | Insert guard + eligibility |
| Partial unique index | `uq_disputes_one_open_active_per_task` | One open/active per task_id |
| Partial unique index | `uq_disputes_one_open_active_per_direct_offer` | One open/active per direct_offer_id |

All names and behaviours align with the plan and 14a spec.

---

## 4. Proposed Refactors (Non-Blocking)

1. **Booking details — Hide “Report Issue” when dispute exists**  
   Plan 8.3.1 / 10.1: hide Dispute button when `hasOpenDisputeForBooking(booking.id)` is true. Currently the button is shown whenever `booking.status == BookingStatus.delivered` with no dispute check. Submitting a second dispute is correctly rejected by `rpc_submit_dispute` and ErrorMapper, but UX would be clearer if the button were hidden when a dispute already exists (e.g. wrap in a guard similar to `_ReportIssueGuard` / `_ReportIssueGuardDirectOffer`).

2. **Booking eligibility — “Report Issue” when active**  
   14a §5 allows booking in `active` \| `delivered`. Plan noted “optionally show when active”. Currently booking details show “Report Issue” only when `delivered`. Optional follow-up: show when `active` or `delivered` and no open/active dispute.

3. **Work item details — Report Issue for booking-type work item**  
   Plan 8.1.1: “for task (and booking when shown as work item)”. `_canShowReportIssue` currently allows only `sourceType == 'task'`. Booking-type work items therefore never show Report Issue on work item details (user uses booking details). Acceptable as-is; if product wants a single entry from unified work, extend `_canShowReportIssue` to include booking and have `_showDisputeDialog` pass `taskId: vm.workItem!.taskId` (or equivalent) for booking.

4. **rpc_submit_delivery / request_revision — direct_offer branch**  
   If the app ever submits delivery or request revision for a direct_offer via these RPCs, the migration would need a `direct_offer` Frozen branch (resolve direct_offer_id and check disputes by direct_offer_id). Currently not required; document as a known limitation if direct_offer delivery/revision are added later.

---

## 5. Evidence — Files / Scopes Validated

| Area | Files / scopes |
|------|-----------------|
| Plan & spec | `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`, `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md` |
| Migration | `supabase/migrations/20260308160000_14a_dispute_extension_frozen_guards.sql` (full read) |
| Service | `lib/features/safety/services/dispute_service.dart` (submitDispute, hasOpen*, getDisputeStatus*, RPC params) |
| ViewModel | `lib/features/safety/viewmodels/safety_view_model.dart` (submitDispute, hasOpen*, getDisputeStatus*, error mapping) |
| Error mapping | `lib/core/utils/error_mapper.dart` (PostgrestException branches for dispute and Frozen messages) |
| Work VM | `lib/features/work/viewmodels/work_item_details_view_model.dart` (submitDelivery/requestRevision catch using ErrorMapper.map(e)) |
| Work service | `lib/features/work/services/work_management_service.dart` (submitDelivery, requestRevision — entityType usage; no direct_offer path to these RPCs) |
| Work item details UI | `lib/features/work/view/work_item_details_screen.dart` (no Supabase; _buildDisputedBanner, _ReportIssueGuard, _ReviewWithDisputeGuard, _canShowReportIssue, _showDisputeDialog; _DisputeBannerContent uses getDisputeStatus*) |
| Direct offer details UI | `lib/features/direct_offers/view/direct_offer_details_screen.dart` (no Supabase; _DirectOfferDisputeBanner, _ReportIssueGuardDirectOffer, _ApproveWithDisputeGuard; submit via SafetyViewModel.submitDispute(directOfferId:)) |
| Booking details UI | `lib/features/booking/view/booking_details_screen.dart` (no Supabase; _BookingDisputeBanner, _ApproveWithDisputeGuard, _showDisputeDialog with taskId: booking.taskId; Report Issue visibility by status only) |
| Docs | `Sline_everything/SUPABASE_SETUP.md` (§9.1, §9.2, §9.2a, changelog) — 14a migration and RPCs documented |

---

## 6. Blockers / Major Contract Mismatches

**None.** No BLOCKER or major contract mismatch found. Implementation is consistent with the plan and 14a spec; MVVM is respected; RPC parameters and eligibility match; ErrorMapper covers the new messages; paths and DB object names are valid. The refactors above are improvements only and do not block sign-off.

---

**Report produced by @Architect. No code changes made.**
