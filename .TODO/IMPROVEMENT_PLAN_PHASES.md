# SLine Execution Checklist (v2.1)

> **Status**: Execution Ready (Final v3)
> **Architecture**: Strict MVVM + Supabase
> **Protocol**: Payment Simulation (Wallet = Source of Truth)

This checklist enforces a strict execution order: **Phase 1 → Phase 3 → Phase 2 → Phase 4 → Phase 5**.

---

## Phase 1: Booking Core, Wallet Foundation & Payment Simulation
**Goal**: Establish the "Pay First, Book Later" flow, secure status logic, and the financial source of truth.

### 1) Database (DDL/Migrations)
- [x] **Enum**: `payment_status_enum` ('unpaid', 'held', 'released', 'refunded').
- [x] **Enum**: Update `booking_status_enum` (+ 'paid_request_pending', 'active', 'delivered', 'completed', 'cancelled', 'refunded', 'expired_unanswered').
- [x] **Table (Bookings)**: Drop `slot_id` NOT NULL. Add `payment_status` ('unpaid'), `requirements` ('{}'), `package_id` (text).
- [x] **Table (Wallet - Early)**: Create `wallet_transactions` (id, user_id, amount, type, status, related_entity_id, related_entity_type, related_txn_id, created_at). Index on `user_id`.
- [x] **Security**: `REVOKE UPDATE(payment_status, client_id, provider_id, package_id, requirements, price) ON public.bookings FROM authenticated;` (Strict Column Locking).
- [x] **Action**: Enable RLS on `bookings` and `wallet_transactions`.

### 2) RLS Policies
- [x] `bookings_select_parties`: `FOR SELECT USING (auth.uid() = client_id OR auth.uid() = provider_id)`.
- [x] `bookings_insert_client`: `FOR INSERT WITH CHECK (auth.uid() = client_id)`.
- [x] `bookings_update_status_only`: `FOR UPDATE USING (...)` (Relies on REVOKE for column safety, allows status changes per role).
- [x] `bookings_deny_delete`: `FOR DELETE USING (false)`.
- [x] `wallet_select_own`: `FOR SELECT USING (auth.uid() = user_id)`.
- [x] `wallet_deny_mod`: `FOR INSERT/UPDATE/DELETE USING (false)` (Strictly System-only).

### 3) RPC / Edge Functions (Critical for Phase 1)
- [x] **Function**: Create `process_payment_event(p_entity_id, p_type, p_event)` `SECURITY DEFINER`.
    - [x] **Transaction/Validation**: Use `BEGIN...EXCEPTION`. Check existing status before action (e.g., Release req `delivered`). Check Idempotency (don't double release).
    - [x] **Wallet Ownership Rules**:
        - **Escrow**: `user_id = provider_id` (Held for freelancer).
        - **Release**: `user_id = provider_id` (Paid to freelancer).
        - **Refund**: `user_id = client_id` (Returned to client).
    - [x] **Logic (Escrow)**: Insert `wallet` (Escrow/Pending/Provider). Update Entity `payment_status='held'`.
    - [x] **Logic (Release)**: Update Entity `status='completed', payment_status='released'`. Update wallet Escrow->Completed. Insert `wallet` (Release/Completed/Provider).
    - [x] **Logic (Refund)**: Update Entity `status='refunded', payment_status='refunded'` (UNLESS status='expired_unanswered', then keep status). Update wallet Escrow->Refunded. Insert `wallet` (Refund/Completed/Client).
- [x] **Function**: Create `process_expired_requests()` (Admin-only).
    - [x] Find > 24h `paid_request_pending`.
    - [x] Update status `expired_unanswered` first.
    - [x] Call `process_payment_event(..., 'refund')`.

### 4) Backend Services (MVVM)
- [x] **Service**: Update `BookingService`:
    - [x] `createBooking`: Insert `paid_request_pending` -> Call RPC 'escrow'.
    - [x] `approveAndRelease`: Call RPC 'release'.
    - [x] `declineBooking`: Update status 'cancelled' -> Call RPC 'refund'.
    - [x] `markDelivered`: Update status 'delivered'.
- [x] **Service**: Update `TaskService`:
    - [x] `createOrder`(assign): Call RPC 'escrow' (if paid).
    - [x] `completeOrder`: Call RPC 'release'.
    - [x] `cancelOrder`: Call RPC 'refund'.
- [x] **ViewModel**: Refactor `BookingViewModel` (Pay -> Create + RPC).

### 5) UI Screens/Widgets
- [x] **BookingScreen**: Remove Slot. Add Requirements. Pay -> Simulation.
- [x] **CreateTaskScreen**: Clean UI. No upload.
- [x] **Skeleton**: Match dimensions exactly.

### 6) QA
- [x] **Manual**: Pay Booking -> Wallet (Provider) shows Pending Escrow.
- [x] **Manual**: Decline -> Wallet (Client) shows Refund.
- [x] **Manual**: Release -> Wallet (Provider) shows Release.
- [x] **Manual**: Double-click release -> Idempotency prevents double pay.
- [x] **Manual**: Manual DB Update of `requirements` -> Rejected (REVOKE check).

---

## Phase 3: Dashboard Restructuring
**Goal**: Clean navigation.

### 1) Backend Services
- [x] `BookingService.getPendingRequests()`.
- [x] `TaskService.getPendingPaymentTenders()`.

### 2) UI
- [x] Remove "Manage" Tab. Merge to Bookings.
- [x] **FreelancerDashboard**: Pending Requests | Active Bookings.
- [x] **FreelancerWork**: Active (Bookings+Orders) | Completed | Cancelled.
- [x] **Overview**: Toggle for "Recent Activity".
- [x] **Notification**: Mark Read logic + Red/Gray Badge.

---

## Phase 2: Unified Management & Notes System
**Goal**: Centralized panel.

### 1) Database
- [ ] **Table**: `work_logs` (id, author_id, related_entity_id, related_entity_type, content, is_private, metadata `jsonb`, created_at).
- [ ] **Functions**: `is_work_log_participant`, `is_provider_of_entity`.
- [ ] **Events**: Define metadata for: `extension_request`, `price_change_proposal`, `cancel_request` (+ accept/reject).

### 2) Feature UI
- [ ] **OrderManagementPanel**:
    - [ ] Embed in Booking/Task Detials.
    - [ ] Actions: Request Extension (Log event), Propose Price Change (Log event).
    - [ ] Chat/Notes.

---

## Phase 4: Freelancer Wallet MVP
**Goal**: Visual Truth.

### 1) UI
- [ ] **WalletScreen**:
    - [ ] Show Provider Balance (Released).
    - [ ] Show Pending Escrow (Held).
    - [ ] Transaction History (Merged view of owned transactions).

---

## Phase 5: Monitoring & Polish
**Goal**: Final cleanup.

### 1) Database
- [ ] **Trigger**: `conversations_before_insert_guard` (Remove favorites check).
- [ ] **Table**: `audit_logs`.

### 2) UI
- [ ] **AppBar**: Bell Icon (Red/Gray).
