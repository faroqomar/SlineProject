# Work Full Remediation — App Verification Checklist

**Date:** 2026-03-05  
**Purpose:** Confirm on device/emulator that Work changes behave as intended.

---

## Pre-check

- [ ] App builds: `flutter run`
- [ ] Logged in as a user who has (or can get) at least one **task** in Work and, if possible, one **booking**

---

## 1. Work detail loads (task)

- [ ] Open **Dashboard → Work** tab
- [ ] Tap a **task** row (assigned or waiting payment)
- [ ] **Expected:** Work detail opens with Overview / Extensions / Contract tabs; no “Work item not found” unless the item really doesn’t exist
- [ ] **Note:** If contract or extension requests fail in the background, the screen should still show the work item (partial-failure fix)

---

## 2. Work detail loads (booking)

- [ ] From Work tab, tap a **booking** row
- [ ] **Expected:** Booking work detail opens; status and info match the booking (completed shows as completed, not “delivered”)

---

## 3. Message from work detail (task)

- [ ] On a **task** work detail, tap **Message**
- [ ] **Expected:** Task-linked conversation opens (or is created); you’re in the correct chat for that task

---

## 4. Message from work detail (booking)

- [ ] On a **booking** work detail, tap **Message**
- [ ] **Expected:** DM conversation with the other party opens (no task-linked thread for booking)

---

## 5. Pay & refresh (task, client)

- [ ] As **client**, open a task in **Waiting payment**
- [ ] Tap **Pay** → complete payment flow (or cancel)
- [ ] After paying (or after closing payment screen), **Expected:** You return to work detail or list; Work tab / list reflects the update (e.g. item moves out of “Waiting payment”)

---

## 6. Cancel award (task, client)

- [ ] As **client**, open a task in **Waiting payment**
- [ ] Tap **Cancel award**
- [ ] **Expected:** Award is cancelled; you’re taken back and the list refreshes (task no longer in your Work as waiting payment)

---

## 7. Optional: revision / change / extension

- [ ] If you have a delivered item: **Request revision** — expected: request is sent, no crash
- [ ] If you have a change request: **Accept change request** — expected: accepts, no crash
- [ ] If the flow exists: **Request extension** — expected: request is sent, no crash

---

## 8. No regression on other tabs

- [ ] **Dashboard (Home), Inbox, Profile** still open and behave as before
- [ ] **Chat** from Inbox or from Work detail still works

---

## Sign-off

| Result        | Initials | Date |
|---------------|-----------|------|
| All passed    |           |      |
| Issues (list) |           |      |

---

## What we did — short summary

### Why

- **One place for work data:** Task and booking work items were mapped in different ways in different screens; behavior could drift.
- **Clear chat path:** Task = task-linked conversation; booking = DM. The app had to use the right path and not mix them.
- **Safer and clearer:** Success logs with IDs at info level; one failed request (e.g. contract) was able to blank the whole work detail screen.

So we: unified mapping, fixed chat entry, improved logging and load behavior, and documented the DB.

---

### Added

| What | Where | Why |
|------|--------|-----|
| **UnifiedWorkItemFallbackMapper** | `lib/features/work/models/unified_work_item_fallback_mapper.dart` | Single place to turn “task request + task” or “booking” into a work item. Same status rules everywhere (e.g. completed → completed, not delivered). |
| **Work tables + RPCs in DB** | Migrations `20260305180000_*`, `20260305180100_*` | Tables for work_contracts, change_requests, extension_requests and RPCs for revision/change. Source of truth in repo. |
| **Optional Chat/Dashboard in ViewModel** | `WorkItemDetailsViewModel` | Screen injects Chat and Dashboard VMs so “Message”, “Cancel award”, “refresh after Pay” go through the VM instead of the view calling them directly. |
| **Partial-failure in loadData** | `WorkItemDetailsViewModel.loadData()` | Contract and extension/change requests are optional; if one fails, we still show the work item instead of a blank “Failed to load” screen. |
| **Doc and log entries** | SUPABASE_SETUP, Sline_Log, DEVELOPER_GUIDE | Migration refs and Work Remediation summary so future work and DB stay in sync with docs. |

---

### Removed

| What | Where | Why |
|------|--------|-----|
| **Entity IDs in success logs** | `work_management_service.dart` | Logs like “Delivery approved: &lt;uuid&gt;” at **info** were reduced to **debug** and IDs dropped from the message so we don’t log identifiers at info level. |
| **All-or-nothing load** | `WorkItemDetailsViewModel.loadData()` | Replaced with optional fetches that catch errors so a single failed optional call doesn’t set a generic “Failed to load work details”. |

---

### Modified

| What | Where | Why |
|------|--------|-----|
| **Work item resolution** | `WorkManagementService`, `WorkItemDetailsViewModel`, `DashboardRepository` | They now use `UnifiedWorkItemFallbackMapper` for task and booking fallbacks so status and fields are consistent (e.g. completed, task vs booking). |
| **“Message” from work detail** | View calls `vm.openConversation()`; VM uses `taskId: item.isTask ? item.id : null` | Task → task-linked conversation; booking → DM. No wrong path. |
| **Pay / Cancel award / Refresh** | Work detail screen | Uses `vm.refreshDashboard()` and `vm.cancelAward(requestId)` instead of the view reading Chat/Dashboard VMs directly. Keeps orchestration in the ViewModel. |
| **SUPABASE_SETUP** | `Sline_everything/SUPABASE_SETUP.md` | Added migration refs for work tables and for `rpc_request_revision` / `rpc_accept_change_request`. |
| **Sline_Log** | `Sline_everything/Sline_Log.md` | New “Work Full Remediation” entry describing what was implemented and impact. |

---

### Not changed (by design)

- **Screen layout:** Work detail is still one screen with tabs (Overview, Extensions, Contract). Splitting into smaller widgets was left for later.
- **Service shape:** One `WorkManagementService`; a future split into query/action/facade was not done.
- **User-visible copy:** No intentional change to button labels or error messages except that “Work item not found” and “Failed to load work details” now apply only when the main work item (or booking fallback) is actually missing or when a hard error happens in the required load path.
