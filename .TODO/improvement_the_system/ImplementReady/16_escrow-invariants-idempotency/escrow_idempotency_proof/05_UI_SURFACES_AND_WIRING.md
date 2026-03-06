# UI Surfaces & Wiring: Escrow Release

## E1) App UI Surfaces (Flutter)

### Surface 1: Work Item Details Screen — "Review" Button

| Field                    | Value                                                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Widget file**          | [work_item_details_screen.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/view/work_item_details_screen.dart#L562-L568) |
| **Visibility condition** | `canReview = isClient && status == delivered` (L60, L493, L562)                                                                                      |
| **Tap handler**          | `_showReviewModal(context, vm)` (L567)                                                                                                               |

### Surface 2: Review Delivery Modal — "Approve" Button

| Field                | Value                                                                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Widget file**      | [review_delivery_modal.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/view/widgets/review_delivery_modal.dart#L119-L128) |
| **Button text**      | `'Approve'` (L123)                                                                                                                                     |
| **Tap handler**      | `_handleApprove()` (L125)                                                                                                                              |
| **Loading guard**    | `isLoading: _isLoading` on AppButton (L124)                                                                                                            |
| **Approve callback** | `widget.onApprove()` → `vm.approveDelivery` (L39)                                                                                                      |

### Surface 3: ViewModel — `approveDelivery()`

| Field              | Value                                                                                                                                                              |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **File**           | [work_item_details_view_model.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/viewmodels/work_item_details_view_model.dart#L149-L168) |
| **Method**         | `approveDelivery()` (L149)                                                                                                                                         |
| **Service call**   | `_workService.approveDelivery(entityId: _workItem!.id, entityType: _workItem!.sourceType)` (L155)                                                                  |
| **Post-success**   | `loadData()` to refresh work item state (L160)                                                                                                                     |
| **Error handling** | `_error = 'Failed to approve delivery'` (L162)                                                                                                                     |

### Surface 4: Service — `WorkManagementService.approveDelivery()`

| Field      | Value                                                                                                                                                  |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **File**   | [work_management_service.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/services/work_management_service.dart#L263-L281) |
| **RPC**    | `rpc('rpc_approve_delivery', params: {'entity_type': entityType, 'entity_id': entityId})` (L268-271)                                                   |
| **Return** | `void` — no response data propagated to UI                                                                                                             |

### UI Response Handling

| Scenario                      | UI Behavior                                                                                             | Evidence                   |
| ----------------------------- | ------------------------------------------------------------------------------------------------------- | -------------------------- |
| **Success**                   | Modal closes (`Navigator.pop(context, true)` in modal L40), data reloads, status changes to `completed` | view_model L160, modal L40 |
| **Network failure**           | Exception caught → `_error = 'Failed to approve delivery'` → modal stays open, `_isLoading` reset       | view_model L162, modal L43 |
| **Already processed (retry)** | RPC throws `'Work not delivered'` (status changed) → same error path as above                           | `rpc_approve_delivery` SQL |
| **Concurrent tap**            | `AppButton(isLoading: _isLoading)` disables tap during load                                             | modal L124                 |

### ⚠ UI Gaps

1. **No confirmation dialog**: Client can approve with a single tap on "Approve" button → no "Are you sure?" step for a financial action.
2. **Generic error message**: "Failed to approve delivery" doesn't distinguish between auth error, status error, or network error.
3. **No "already processed" awareness**: If a retry succeeds (backend says already_processed), the UI would show the same error, then `loadData` would show `completed` state on refresh.

---

## E2) Admin Dashboard UI Surfaces

### ❌ No Admin Dashboard Exists

**Evidence**: `find_by_name` for `*admin*` directories in the repo returned 0 results.

**Current workaround**:

- Supabase Table Editor → `journal_entries` table → filter by `related_entity_id`
- Supabase SQL Editor → ad-hoc queries

**What admin would need**:
| Surface | Purpose | Query |
|---|---|---|
| Escrow Monitor | Show all entities with `payment_status = 'held'` | `SELECT * FROM bookings WHERE payment_status = 'held'` |
| Ledger Trace | Show journal entries + ledger lines per entity | `SELECT je.*, ll.* FROM journal_entries je JOIN ledger_lines ll ON ll.journal_entry_id = je.id WHERE je.related_entity_id = $1` |
| Double-release detector | Find entities with >1 `release_with_fee` journal entry | `SELECT related_entity_id, COUNT(*) FROM journal_entries WHERE event_type = 'release_with_fee' GROUP BY related_entity_id HAVING COUNT(*) > 1` |
| Audit Logs | Show all `payment.release_with_fee` events | `SELECT * FROM audit_logs WHERE action = 'payment.release_with_fee' ORDER BY created_at DESC` |

---

## E3) UI "Truth Tests"

### Test 1: Network failure after DB commit, then retry

- **Setup**: Tap Approve → RPC succeeds (DB committed) → simulate network cut
- **Expected**:
  - UI shows "Failed to approve delivery" (generic error)
  - User taps Approve again
  - RPC throws `'Work not delivered'` (status is now `completed`)
  - UI shows "Failed to approve delivery" again
  - User pulls to refresh or navigates back → data shows `completed`
- **Verdict**: ✅ Backend safe (no double-release). 🟡 UX poor (error on retry instead of "already processed")

### Test 2: Rapid double-tap

- **Setup**: Tap Approve twice rapidly
- **Expected**:
  - First tap sets `_isLoading = true`, `AppButton` disables via `isLoading`
  - Second tap is **ignored** (button disabled)
  - Only one RPC call fires
- **Verdict**: ✅ Safe (UI + backend both protect)
- **⚠ Edge case**: If `setState` hasn't re-rendered between taps (frame budget), second tap could fire. Backend's `FOR UPDATE` blocks it.

### Test 3: Approval when `payment_status != 'held'`

- **Setup**: Entity has `payment_status = 'released'` (already completed)
- **Expected**:
  - `canReview` returns `false` (status != `delivered`)
  - "Review" button is hidden
  - Even if API is called directly, RPC blocks with `'Work not delivered'`
- **Verdict**: ✅ UI hides button + backend blocks
