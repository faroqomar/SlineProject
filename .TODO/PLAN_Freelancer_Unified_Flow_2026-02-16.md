# 📌 Plan: Freelancer Unified Flow (Final v1.5 Execution Ready)

## 1) Goal

- **Goal:** Implement the "Unified Work Engine" where Tenders and Bookings merge into a single "Active Work Item" flow with strict state management (Frozen Requirements, Change Requests, Extensions, Disputes).
- **Why:** To eliminate ambiguity in work scope, prevent scope creep, and ensure secure escrow handling for all work types.
- **Result:** A single, robust "Work" experience for Freelancers that handles all edge cases (delays, changes, disputes) identically for both Tenders and Bookings.

## 2) Scope

### In-Scope

- **Database:**
  - New tables: `work_contracts`, `change_requests`, `extension_requests`.
  - Updates: Add Delivery/Revision columns to `tasks` and `bookings`.
  - Polymorphic linking with **strict constraints**.
  - **Unified View:** `vw_unified_work_items` with mapped status enums.
- **Backend (Supabase):**
  - RLS policies (strict recipient checks + No Update allowed on requests).
  - Triggers for status transitions, activations, **escrow guards**, and **revision limits**.
  - **RPC Functions** (SECURITY DEFINER) for accepting changes/delivery (Atomic Updates).
- **App Logic (Flutter):**
  - Refactor `WorkItemDetailsViewModel` to be the "Unified Controller".
  - Implement `WorkManagementService` (RPC-based).
  - Update `DashboardViewModel`: Priorities include "Delivery Pending Approval".
- **UI:**
  - Unified Work Details (Requirements, Management tabs).
  - Delivery Flow & Revision Request Flow (Freelancer "Resubmit" view).

### Out-of-Scope

- **Client-side UI:** (Focusing on Freelancer experience).
  - _Note:_ Revision Request _logic_ (DB/RPC) is implemented, but Client UI to trigger it is deferred. Verification via "Mock Client".
- **Payment Gateway** details (handled by `PaymentService`).
- **Edge Functions** (Logic defined in DB/RPC; Auto-Approve via "Lazy Finalize").

## 3) Evidence & Findings (From Scan)

### Existing

- **Tables:** `tasks`, `bookings`, `task_requests`, `conversations`, `messages`, `disputes`.
- **Enums:** `booking_status_enum` (authoritative), `task_type_enum`.
- **Code:** `WorkItemDetailsViewModel` exists but is skeletal.

### Critical Gaps Resolved in v1.5

- **Unified Status:** `vw_unified_work_items` maps Task strings -> Booking Enums for consistent logic.
- **Auto-Approve:** "Lazy Finalize" RPC handles expiration on view/load.
- **Security:** RPCs use `SECURITY DEFINER` with explicit participant validation.
- **Revisions:** Logic implemented; Freelancer UI handles "Resubmit" flow.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Definitions & Discovery

- [ ] (@Supabase_Ops) **Identify Exact Activation States:** Scan DB to confirm exact enum values (e.g., `confirmed`/`in_progress`).
- [ ] (@Supabase_Ops) **Identify Payment Status:** Confirm exact values like `'held'`, `'escrow'`.
- [ ] (@Supabase_Ops) **Ensure Freelancer Column:** functionality relies on `tasks.assigned_freelancer_id`.
  - **Backfill Strategy:** Update `tasks.assigned_freelancer_id` from `task_requests` WHERE `status='accepted'`.

### 0.2 Threat Model

- [ ] (@ThreatModeler) Abuse: ensure freelancer cannot "accept" their own change request.
- [ ] (@ThreatModeler) Abuse: ensure work cannot activate without payment held.

### 0.3 Observability & Contracts

- [ ] (@APIContract) Define RPC payloads.
- [ ] (@Observability) Logging: `AppLogger` + DB Audit logs.

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.1 Schema (Contracts, Requests, Delivery)

- [ ] (@Supabase_Ops) Create `work_contracts` table: `id`, `related_entity_type`, `related_entity_id`, `version`, `snapshot` (jsonb), `contract_hash`, `created_at`.
- [ ] (@Supabase_Ops) Update `tasks` and `bookings`:
  - Add `delivered_at` (timestamptz), `review_expires_at` (timestamptz).
  - Add `revisions_total` (int, default 3), `revisions_used` (int, default 0).
  - Add `revision_note` (text), `revision_requested_at` (timestamptz).
- [ ] (@Supabase_Ops) Create `change_requests`: `scope_diff`, `price_diff`, `days_diff`, `status`, `applied_contract_version`.
  - Constraint: `CHECK (related_entity_type IN ('task', 'booking'))`.
  - Trigger Validation: Ensure entity exists.
- [ ] (@Supabase_Ops) Create `extension_requests`: `new_deadline`, `reason`.

### 1.2 RLS, Triggers & Views

- [ ] (@Supabase_Ops) **Unified View (`vw_unified_work_items`):**
  - Columns: `id`, `unified_status` (Enum), `source_type`, `source_status`, `title`, `price`.
  - Logic: Maps `tasks.status` ('in_progress'->'active', 'review'->'delivered') to match `bookings` logic.
- [ ] (@Supabase_Ops) Trigger `trg_activate_contract`:
  - **ON UPDATE** of `tasks` or `bookings`.
  - **IF** `status` matches **Exact Activation Value**.
  - **GUARD:** Check `payment_status = 'held'`. If not, RAISE EXCEPTION.
  - **ACTION:** Insert Version 1 into `work_contracts`.
- [ ] (@Supabase_Ops) Trigger `trg_freeze_contract_fields`:
  - **BEFORE UPDATE** on `tasks` or `bookings` active rows.
  - **FROZEN:** `title`/`reqs`, `price`, `deadline`.
  - **ALLOWED:** `delivered_at`, `revisions_used`, `status` (via RPC).
- [ ] (@Supabase_Ops) RLS:
  - Select: Participants only.
  - Insert: Requester only.
  - **Update:** `DENY ALL` (RPC Only).

### 1.3 RPC Logic (SECURITY DEFINER)

- [ ] (@Supabase_Ops) `rpc_accept_change_request(id)`:
  - `SECURITY DEFINER`. Validate `auth.uid()` is recipient.
  - Atomic update: Request status -> Accepted, Contract -> New Version, Wallet -> Update.
- [ ] (@Supabase_Ops) `rpc_submit_delivery(entity_type, id, note)`:
  - `SECURITY DEFINER`. Validate `auth.uid()` is provider/freelancer.
  - Sets `delivered_at = NOW()`, `review_expires_at = NOW() + 3 days`.
  - Updates status to `delivered`.
- [ ] (@Supabase_Ops) `rpc_request_revision(entity_type, id, note)`:
  - `SECURITY DEFINER`. Validate `auth.uid()` is client.
  - Check `revisions_used < revisions_total`. Increment used.
  - Reset `delivered_at` = NULL. Status -> `active`.
- [ ] (@Supabase_Ops) `rpc_finalize_auto_approval(entity_type, id)`:
  - **Lazy Guard:** If `status='delivered'` AND `now() > review_expires_at`.
  - Actions: Move to `completed`, Release Payout.
  - Returns: New status.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Services

- [ ] (@Architect) Models: `WorkContractModel`, `ChangeRequestModel`, `ExtensionRequestModel`.
- [ ] (@Architect) Service `WorkManagementService`:
  - Wraps all RPCs. calls `rpc_finalize_auto_approval` on `loadWorkItem()`.

### 2.2 Unified ViewModel

- [ ] (@Architect) `WorkItemDetailsViewModel`:
  - Uses `vw_unified_work_items` for status logic.
  - `activeContract`: frozen snapshot.
  - `deliveryStatus`: Computed from `delivered_at` / `review_expires_at`.
  - `revisionsLeft`: `revisions_total - revisions_used`.
  - Actions: `deliverWork()`.

### 2.3 Dashboard Refinement

- [ ] (@Architect) Priorities:
  1. **Action Required:** `paid_request_pending`, `dispute_open`.
  2. **Workflow:** `change_pending`, `extension_pending`, `revision_requested` (Freelancer action).
  3. **In Review:** Items where `unified_status='delivered'`.

---

## Phase 3: UI (Freelancer View)

> Primary: @Pixel

### 3.1 Work Item Details Screen

- [ ] (@Pixel) "Requirements": Read Frozen Snapshot.
- [ ] (@Pixel) "Management":
  - If Active: Show "Deliver Work".
  - If Delivered: Show "In Review" + Timer.
  - If Revision Requested: Show Note + "Resubmit".
  - Change/Extension lists.

### 3.2 Dashboard

- [ ] (@Pixel) New Badges: "In Review", "Revision Requested".

---

## Phase 4: QA + Verification

> Primary: @Sentinel

### 4.1 Functional Tests

- [ ] (@Sentinel) **Escrow Guard:** Try to activate unpaid task -> Exception.
- [ ] (@Sentinel) **Delivery:** RPC `mark_delivered` -> Check `review_expires_at` is set.
- [ ] (@Sentinel) **Auto-Approve:** Manipulate DB time -> Call `rpc_finalize` -> Check status `completed`.
- [ ] (@Sentinel) **Revision Limit:** Request revision > limit -> Fail.

### 4.2 Security Tests

- [ ] (@Sentinel) **Non-Participant:** Try to call `rpc_submit_delivery` on random task -> Fail.
- [ ] (@Sentinel) **Direct Update:** Try to UPDATE `tasks` directly -> Fail.

---

## 5) Acceptance Criteria

- [ ] **Unified Status:** All logic relies on `vw_unified_work_items`.
- [ ] **Security:** All mutations via SECURITY DEFINER RPCs.
- [ ] **Contract Frozen:** Requirements stable.
- [ ] **Delivery Lifecycle:** Delivered -> Timer -> (Lazy Auto-approve/Revision).
- [ ] **Revisions:** Tracked and limited.

## 6) References

- Spec: `.TODO/Fixing_Dashbowrd.md`
- DB: `SUPABASE_SETUP.md`
