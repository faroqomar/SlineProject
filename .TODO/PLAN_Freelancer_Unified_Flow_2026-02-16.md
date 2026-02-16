# 📌 Plan: Freelancer Unified Flow (Final v1)

## 1) Goal

- **Goal:** Implement the "Unified Work Engine" where Tenders and Bookings merge into a single "Active Work Item" flow with strict state management (Frozen Requirements, Change Requests, Extensions, Disputes).
- **Why:** To eliminate ambiguity in work scope, prevent scope creep, and ensure secure escrow handling for all work types.
- **Result:** A single, robust "Work" experience for Freelancers that handles all edge cases (delays, changes, disputes) identically for both Tenders and Bookings.

## 2) Scope

### In-Scope

- **Database:**
  - New tables: `change_requests`, `extension_requests`.
  - Updates to `tasks` and `bookings` constraints/triggers if needed.
- **Backend (Supabase):**
  - RLS policies for new tables.
  - Triggers for status transitions (e.g., auto-update task deadline on extension accept).
- **App Logic (Flutter):**
  - Refactor `WorkItemDetailsViewModel` to be the "Unified Controller".
  - Implement `ChangeRequestService`, `ExtensionRequestService`.
  - Update `DashboardViewModel` to strictly follow spec priorities.
- **UI:**
  - "Unification" of Work Details screen (same tabs/actions for both types).
  - Integration of Change/Extension request actions.

### Out-of-Scope

- **Client-side changes** (focusing on Freelancer experience first, though underlying DB logic affects both).
- **Payment Gateway** details (assumed handled by `PaymentService`).
- **Notification System** overhaul (using existing system).

## 3) Evidence & Findings (From Scan)

### Existing

- **Tables:** `tasks`, `bookings`, `task_requests` (bids), `conversations`, `messages`, `disputes` (exists!).
- **Enums:** `booking_status_enum` (matches spec), `task_type_enum`.
- **Code:** `WorkItemDetailsViewModel` exists but is skeletal. `DashboardViewModel` has basic logic but lacks strict priority rules for "Request Pending".

### Missing

- **Tables:** `change_requests`, `extension_requests`.
- **Logic:** "Requirements Frozen" enforcement, Change Request flow, Extension Request flow.
- **UI:** Unified view for these new flows.

### Risks

- **Drift:** `tasks` table uses string status while `bookings` uses enum. Need to ensure `tasks.status` aligns with `booking_status_enum` conceptually.
- **Complexity:** "Unified" view might complexify the code if not strictly abstracted.

## 4) System Impact Map

- **UI:** drastic updates to `WorkItemDetailsScreen` and `DashboardScreen`.
- **MVVM:** `WorkItemDetailsViewModel` becomes complex state machine.
- **Database:** new tables + foreign keys to `tasks` and `bookings` (polymorphic relationship using `related_entity_id`).
- **RLS:** strict ownership rules on requests.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Confirm "Requirements Frozen" means NO edits to `tasks.description` or `bookings.requirements` after `active`.
- [ ] (@Architect) Confirm `WorkItemDetailsViewModel` will wrap both `Task` and `BookingModel`.

### 0.2 Threat Model

- [ ] (@ThreatModeler) Abuse: ensure freelancer cannot "accept" their own change request.
- [ ] (@Sentinel) Negative test: try to edit active task description (should fail RLS/trigger).

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.1 Schema (New Tables)

- [ ] (@Supabase_Ops) Create `change_requests` table:
  - `id`, `task_id` (nullable), `booking_id` (nullable), `requester_id` (FK profiles), `scope_diff` (text), `price_diff` (numeric), `days_diff` (int), `status` (pending/accepted/rejected), `created_at`.
  - Check constraint: `task_id IS NOT NULL OR booking_id IS NOT NULL`.
- [ ] (@Supabase_Ops) Create `extension_requests` table:
  - `id`, `task_id` (nullable), `booking_id` (nullable), `requester_id`, `new_deadline` (timestamptz), `reason`, `status` (pending/accepted/rejected).

### 1.2 RLS & Triggers

- [ ] (@Supabase_Ops) RLS: Select (participants), Insert (participants), Update (recipient only for status).
- [ ] (@Supabase_Ops) Trigger: `trg_apply_extension`: on `status='accepted'`, update `tasks.deadline` or `bookings.ends_at` (conceptually).
- [ ] (@Supabase_Ops) Trigger: `trg_freeze_requirements`: Prevent UPDATE on `tasks.description` / `bookings.requirements` if `status` is active.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Services

- [ ] (@Architect) Generate `ChangeRequestModel` + `ExtensionRequestModel`.
- [ ] (@Architect) Create `WorkManagementService`:
  - `createChangeRequest(...)`
  - `acceptChangeRequest(...)`
  - `createExtensionRequest(...)`
  - `acceptExtensionRequest(...)`

### 2.2 Unified ViewModel

- [ ] (@Architect) Enhance `WorkItemDetailsViewModel`:
  - Add `loadChangeRequests()`, `loadExtensionRequests()`.
  - Expose `canRequestChange`, `canRequestExtension`.
  - Implement `freeze` check (is Active?).

### 2.3 Dashboard Refinement

- [ ] (@Architect) Refactor `DashboardViewModel._calculateNextActions()`:
  - Priority 1: `booking.status = paid_request_pending` (Escrow Held).
  - Priority 2: `change_requests.status = pending` (Action required by me).
  - Priority 3: `disputes.status = open`.

---

## Phase 3: UI (Freelancer View)

> Primary: @Pixel

### 3.1 Work Item Details Screen

- [ ] (@Pixel) "Requirements" Tab: Read-only view of blocked scope.
- [ ] (@Pixel) "Management" Tab (New):
  - List active Change Requests.
  - Button: "Request Scope Change" (Sheet).
  - Button: "Request Extension" (Sheet).
  - "Deliver Work" button (only if Active).

### 3.2 Dashboard Overhaul

- [ ] (@Pixel) "Next Actions" card for "New Booking Request" (High visibility, Green/Gold).
- [ ] (@Pixel) "Work" tab: Group by Active, Delivered, Done.

---

## Phase 4: QA + Verification

> Primary: @Sentinel

### 4.1 Functional Tests

- [ ] (@Sentinel) Plan: Create booking -> Pay -> "Request Pending" shows on dashboard.
- [ ] (@Sentinel) Plan: Accept -> Active -> Verify "Requirements" are read-only.
- [ ] (@Sentinel) Plan: Create Change Request -> Verify pending state -> Accept -> Verify budget updated (mock).

### 4.2 Security Tests

- [ ] (@Sentinel) Try to update `tasks.description` via SQL when status is `in_progress`. Expect: Fail.

---

## 5) Acceptance Criteria

- [ ] Freelancer sees "Request Pending" bookings at top of dashboard.
- [ ] Freelancer cannot edit task/booking details once active.
- [ ] Change Request flow works (create -> view -> accept/reject UI exists).
- [ ] Dashboard correctly categorizes items into Active/Delivered/Completed.

## 6) References

- Spec: `.TODO/Fixing_Dashbowrd.md`
- DB: `SUPABASE_SETUP.md`
- Code: `lib/features/work/viewmodels/work_item_details_view_model.dart`
