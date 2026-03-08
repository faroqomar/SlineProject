# Work Contract Revisions — App Verification Checklist & Summary

**What was done:** Harden the "request revision" flow so the database enforces limits and the app shows clear errors.  
**Plan:** `.TODO/PLAN_WorkContractRevisions_2025-03-08_PlanCritic.md`

---

## 1) Checklist — What to Check in the Actual App

Use this list when testing on a real device or simulator.

### 1.1 Request revision (happy path)

- [ ] Log in as **client**.
- [ ] Open a work item (task or booking) that is **delivered** and has **revisions left** (e.g. "Request Changes" enabled in Review).
- [ ] Tap **Review** (or equivalent) → choose **Request Changes** → enter a note → **Submit Request**.
- [ ] **Expected:** Modal closes, work item refreshes; status becomes "active"; revision count increases. No error.
- [ ] **Logs:** In console, you should see a debug log like "Revision requested" (tag: WorkManagement).

### 1.2 No revisions left (button disabled)

- [ ] As **client**, open a delivered work item where **revisions are exhausted** (revisions used = revisions total, e.g. already requested 3 of 3).
- [ ] Open **Review**.
- [ ] **Expected:** "Request Changes" is **disabled**; text **"No revisions left."** is visible. You cannot tap Request Changes.
- [ ] **Expected:** No RPC call when opening the modal (button not tappable).

### 1.3 No revisions left (error message if RPC is called)

- [ ] If you ever see "Request Changes" enabled but the backend has no revisions left (e.g. stale data), submit a request.
- [ ] **Expected:** A **SnackBar** with a message like **"No revisions remaining. You have used all allowed revision requests."** (not a generic "Failed to request revision" or "Database error").
- [ ] **Logs:** Error log with tag WorkManagement and outcome `limit_reached`.

### 1.4 Wrong state (revision on non‑delivered — rare)

- [ ] If the UI ever lets you try to request a revision when the work is not delivered (e.g. race), or you simulate the RPC:
- [ ] **Expected:** SnackBar like **"You can only request a revision when the work is delivered."**
- [ ] **Logs:** Error with outcome `state_invalid`.

### 1.5 Change request error (consistency fix)

- [ ] As the **wrong role** (e.g. requester trying to accept their own change request) or in a failing change-request scenario:
- [ ] **Expected:** Error message comes from **ErrorMapper** (user-friendly), not a hardcoded "Failed to accept change request".

### 1.6 Other flows unchanged

- [ ] **Approve delivery:** Still works (client approves delivered work → completed, funds released if held).
- [ ] **Submit delivery:** Still works (freelancer submits delivery → status delivered).
- [ ] **General:** No crashes on work detail screen or review modal; loading states and back button behave as before.

---

## 2) What Was Done — Short Summary

### Why

- The database RPC `rpc_request_revision` did **not** check (1) that the work was **delivered** or (2) that the client had **revisions left**. So a client could request revisions forever and trap escrow, or call the RPC in the wrong state.
- The app showed a generic **"Failed to request revision"** for all errors and did not disable "Request Changes" when no revisions were left.

### What was added

| Where | What |
|-------|------|
| **Database (Supabase)** | New migration: `rpc_request_revision` now checks **status = 'delivered'** and **revisions_used < revisions_total** before doing anything. If not, it raises a clear error. |
| **ErrorMapper** | Three new mappings: "Can only request revision on delivered work", "No revisions remaining", "Only client can request revision" → user-friendly messages. |
| **ReviewDeliveryModal** | **canRequestRevision** (true/false) and **getRevisionError** (callback to read error text). When false: "Request Changes" is disabled and **"No revisions left."** is shown. On reject failure: SnackBar shows the message from **getRevisionError()**. |
| **Work item details screen** | Passes **canRequestRevision** = (revisions used < revisions total) and **getRevisionError** = () => vm.error into the modal. |
| **WorkManagementService** | Logging: on success (tag WorkManagement, entityType/entityId/note_length); on error (tag WorkManagement, outcome: limit_reached / state_invalid / error). |
| **Tests** | Unit tests in `error_mapper_test.dart` for the three revision error messages. |
| **Docs** | SUPABASE_SETUP §9.2 and §1 updated; DEVELOPER_GUIDE table note for revision + ErrorMapper; Sline_Log entry; execution log and plan/report refs. |

### What was removed

- **Nothing.** All changes are additive (new guards, new mappings, new props, new logs). No features or screens were removed.

### What was modified

| Where | Before | After |
|-------|--------|--------|
| **ViewModel `requestRevision`** | On error: `_error = 'Failed to request revision'` | `_error = ErrorMapper.map(e)` and clear `_error` at start of request. |
| **ViewModel `acceptChangeRequest`** | On error: `_error = 'Failed to accept change request'` | `_error = ErrorMapper.map(e)` (same pattern as revision). |
| **ReviewDeliveryModal** | Single "Request Changes" button, no error from VM | Button can be disabled when no revisions left; "No revisions left." text; on failure, SnackBar from **getRevisionError()**. |
| **RPC `rpc_request_revision`** | Only checked client; then always updated status and incremented revisions_used | First checks client, then **status = 'delivered'**, then **revisions_used < revisions_total**; only then updates. |

---

## 3) One-Line Summary

**Database:** Revision is only allowed when status is delivered and revisions remain; otherwise the RPC returns a clear error. **App:** Those errors are mapped to readable messages, shown in the Review modal (SnackBar), and "Request Changes" is disabled when there are no revisions left; logging and docs were added/updated.
