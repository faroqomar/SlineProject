# SLine Execution Checklist (v2.1)

> **Status**: Execution Ready (Final v3)
> **Architecture**: Strict MVVM + Supabase
> **Protocol**: Payment Simulation (Wallet = Source of Truth)

This checklist enforces a strict execution order: **Phase 1 → Phase 3 → Phase 2 → Phase 4 → Phase 5**.

---

## Phase 1: Booking Core, Wallet Foundation & Payment Simulation
**Goal**: Establish the "Pay First, Book Later" flow, secure status logic, and the financial source of truth.

### 1) Database (DDL/Migrations)
- [ ] **Enum**: `payment_status_enum` ('unpaid', 'held', 'released', 'refunded').
- [ ] **Enum**: Update `booking_status_enum` (+ 'paid_request_pending', 'active', 'delivered', 'completed', 'cancelled', 'refunded', 'expired_unanswered').
- [ ] **Table (Bookings)**: Drop `slot_id` NOT NULL. Add `payment_status` ('unpaid'), `requirements` ('{}'), `package_id` (text).
- [ ] **Table (Wallet - Early)**: Create `wallet_transactions` (id, user_id, amount, type, status, related_entity_id, related_entity_type, related_txn_id, created_at). Index on `user_id`.
- [ ] **Security**: `REVOKE UPDATE(payment_status, client_id, provider_id, package_id, requirements, price) ON public.bookings FROM authenticated;` (Strict Column Locking).
- [ ] **Action**: Enable RLS on `bookings` and `wallet_transactions`.

### 2) RLS Policies
- [ ] `bookings_select_parties`: `FOR SELECT USING (auth.uid() = client_id OR auth.uid() = provider_id)`.
- [ ] `bookings_insert_client`: `FOR INSERT WITH CHECK (auth.uid() = client_id)`.
- [ ] `bookings_update_status_only`: `FOR UPDATE USING (...)` (Relies on REVOKE for column safety, allows status changes per role).
- [ ] `bookings_deny_delete`: `FOR DELETE USING (false)`.
- [ ] `wallet_select_own`: `FOR SELECT USING (auth.uid() = user_id)`.
- [ ] `wallet_deny_mod`: `FOR INSERT/UPDATE/DELETE USING (false)` (Strictly System-only).

### 3) RPC / Edge Functions (Critical for Phase 1)
- [ ] **Function**: Create `process_payment_event(p_entity_id, p_type, p_event)` `SECURITY DEFINER`.
    - [ ] **Transaction/Validation**: Use `BEGIN...EXCEPTION`. Check existing status before action (e.g., Release req `delivered`). Check Idempotency (don't double release).
    - [ ] **Wallet Ownership Rules**:
        - **Escrow**: `user_id = provider_id` (Held for freelancer).
        - **Release**: `user_id = provider_id` (Paid to freelancer).
        - **Refund**: `user_id = client_id` (Returned to client).
    - [ ] **Logic (Escrow)**: Insert `wallet` (Escrow/Pending/Provider). Update Entity `payment_status='held'`.
    - [ ] **Logic (Release)**: Update Entity `status='completed', payment_status='released'`. Update wallet Escrow->Completed. Insert `wallet` (Release/Completed/Provider).
    - [ ] **Logic (Refund)**: Update Entity `status='refunded', payment_status='refunded'` (UNLESS status='expired_unanswered', then keep status). Update wallet Escrow->Refunded. Insert `wallet` (Refund/Completed/Client).
- [ ] **Function**: Create `process_expired_requests()` (Admin-only).
    - [ ] Find > 24h `paid_request_pending`.
    - [ ] Update status `expired_unanswered` first.
    - [ ] Call `process_payment_event(..., 'refund')`.

### 4) Backend Services (MVVM)
- [ ] **Service**: Update `BookingService`:
    - [ ] `createBooking`: Insert `paid_request_pending` -> Call RPC 'escrow'.
    - [ ] `approveAndRelease`: Call RPC 'release'.
    - [ ] `declineBooking`: Update status 'cancelled' -> Call RPC 'refund'.
    - [ ] `markDelivered`: Update status 'delivered'.
- [ ] **Service**: Update `TaskService`:
    - [ ] `createOrder`(assign): Call RPC 'escrow' (if paid).
    - [ ] `completeOrder`: Call RPC 'release'.
    - [ ] `cancelOrder`: Call RPC 'refund'.
- [ ] **ViewModel**: Refactor `BookingViewModel` (Pay -> Create + RPC).

### 5) UI Screens/Widgets
- [ ] **BookingScreen**: Remove Slot. Add Requirements. Pay -> Simulation.
- [ ] **CreateTaskScreen**: Clean UI. No upload.
- [ ] **Skeleton**: Match dimensions exactly.

### 6) QA
- [ ] **Manual**: Pay Booking -> Wallet (Provider) shows Pending Escrow.
- [ ] **Manual**: Decline -> Wallet (Client) shows Refund.
- [ ] **Manual**: Release -> Wallet (Provider) shows Release.
- [ ] **Manual**: Double-click release -> Idempotency prevents double pay.
- [ ] **Manual**: Manual DB Update of `requirements` -> Rejected (REVOKE check).

---

## Phase 3: Dashboard Restructuring
**Goal**: Clean navigation.

### 1) Backend Services
- [ ] `BookingService.getPendingRequests()`.
- [ ] `TaskService.getPendingPaymentTenders()`.

### 2) UI
- [ ] Remove "Manage" Tab. Merge to Bookings.
- [ ] **FreelancerDashboard**: Pending Requests | Active Bookings.
- [ ] **FreelancerWork**: Active (Bookings+Orders) | Completed | Cancelled.
- [ ] **Overview**: Toggle for "Recent Activity".
- [ ] **Notification**: Mark Read logic + Red/Gray Badge.

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
