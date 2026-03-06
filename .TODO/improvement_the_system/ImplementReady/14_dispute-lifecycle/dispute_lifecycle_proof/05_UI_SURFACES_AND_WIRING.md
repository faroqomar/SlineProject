# UI Surfaces & Wiring: Dispute Lifecycle

## E1) App UI Surfaces (Flutter)

### Client Surfaces

| Surface                       | Screen / Widget                                               | File Path                                                                    | Service / VM Method                                                  | DB / RPC                              |
| ----------------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------------------------- |
| **Open Dispute**              | "Report Issue" TextButton on Booking Details (delivered only) | `lib/features/booking/view/booking_details_screen.dart` L372-384             | `SafetyViewModel.submitDispute()` → `DisputeService.submitDispute()` | `INSERT INTO disputes`                |
| **Dispute Dialog**            | `_showDisputeDialog()` AlertDialog (reason text input)        | `booking_details_screen.dart` L425-488                                       | Same as above                                                        | Same as above                         |
| **See Dispute Status**        | Dashboard Work Tab — `disputed` status bucket (Active)        | `lib/features/dashboard/data/dashboard_repository.dart` L389                 | `vw_unified_work_items` view maps `disputed` to `Active` bucket      | `vw_unified_work_items`               |
| **Primary Action (Disputed)** | "Submit Evidence" button label                                | `lib/features/dashboard/services/dashboard_permission_service.dart` L132-134 | `PrimaryActionType.submitEvidence`                                   | N/A (placeholder — no handler exists) |
| **Can Dispute Permission**    | Permission flag `canDispute`                                  | `dashboard_permission_service.dart` L45-47                                   | Set when status is `active` or `delivered`                           | N/A                                   |

### Freelancer Surfaces

| Surface                  | Screen / Widget                         | File Path      | Service / VM Method | DB / RPC |
| ------------------------ | --------------------------------------- | -------------- | ------------------- | -------- |
| **Dispute Notification** | ❌ NOT IMPLEMENTED                      | N/A            | N/A                 | N/A      |
| **Respond to Dispute**   | ❌ NOT IMPLEMENTED                      | N/A            | N/A                 | N/A      |
| **Locked Task State**    | ❌ NOT IMPLEMENTED (no task-lock logic) | N/A            | N/A                 | N/A      |
| **See Dispute Status**   | Dashboard Work Tab (disputed bucket)    | Same as Client | Same                | Same     |

### Shared Surfaces

| Surface                      | Status             | Evidence                                |
| ---------------------------- | ------------------ | --------------------------------------- |
| Dispute Thread / Messages UI | ❌ NOT IMPLEMENTED | No screen references `dispute_messages` |
| Evidence Viewer              | ❌ NOT IMPLEMENTED | No screen references `dispute_evidence` |
| Status Timeline              | ❌ NOT IMPLEMENTED | No dispute activity log UI              |

---

## E2) Admin Dashboard UI Surfaces

### ❌ NO ADMIN UI EXISTS IN REPO

**Evidence:**

- `find_by_name` for `admin*` directories → 0 results.
- No `.tsx`, `.ts`, `.jsx`, `.js` files reference `dispute` outside of `build/web/main.dart.js` (compiled Flutter).
- No `/admin/disputes` route found anywhere.

> **Verdict:** Admin dispute management is either unbuilt or lives in another repo (external admin dashboard). The SLine Flutter app contains zero admin-facing dispute UI.

### Expected (Not Found)

| Surface                      | Route                              | Status       |
| ---------------------------- | ---------------------------------- | ------------ |
| Disputes list page           | `/admin/disputes`                  | ❌ NOT FOUND |
| Dispute detail + money story | `/admin/disputes/[id]`             | ❌ NOT FOUND |
| Admin resolution controls    | Resolve / Refund / Release actions | ❌ NOT FOUND |
| Audit / Logs view            | Admin log table                    | ❌ NOT FOUND |

---

## E3) UI Implementation "Truth Tests" (Checklist)

| #   | Test                                                                              | Expected Result                    | Current Status                                                                                 |
| --- | --------------------------------------------------------------------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------- |
| T1  | If dispute is `open`/`active`, "Approve & Release Funds" button is disabled in UI | Button hidden / disabled           | ❌ NOT IMPLEMENTED — CTA resolver does not check disputes                                      |
| T2  | If dispute is `open`/`active`, `rpc_approve_delivery` rejects                     | Server returns error               | ❌ NOT IMPLEMENTED — Server does not check disputes                                            |
| T3  | User tries `UPDATE disputes SET status='resolved'` directly                       | DB rejects (RLS)                   | ✅ PASS — No UPDATE policy exists for authenticated                                            |
| T4  | User A cannot open User B's evidence URLs                                         | Storage policy blocks              | ❌ NOT TESTABLE — No storage bucket exists                                                     |
| T5  | Both parties receive dispute state-change notifications                           | Push / Realtime update             | ❌ NOT IMPLEMENTED                                                                             |
| T6  | Admin resolution creates correct ledger event                                     | Atomic status change + ledger      | ❌ NOT IMPLEMENTABLE — No admin RPC for disputes                                               |
| T7  | "Report Issue" button only appears for delivered bookings                         | Visible only when status=delivered | ✅ PASS — `booking_details_screen.dart` L372: `if (booking.status == BookingStatus.delivered)` |
| T8  | Dispute auto-fills defendant_id from booking counterparty                         | Correct party                      | ✅ PASS — `booking_details_screen.dart` L470-472                                               |
