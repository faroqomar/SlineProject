# SLine Execution Checklist (v2.1)

> **Generated from**: Improvement Plan v6 + Review (Final)
> **Architecture**: Strict MVVM + Supabase

---

## Phase 1: Booking Core Overhaul (Logic, Schema & Critical UI)

### 1) Database (DDL/Migrations)
- [ ] Create `payment_status_enum` (unpaid, held, released, refunded) using `DO` block with `pg_enum` check.
- [ ] Update `booking_status_enum` adding `paid_request_pending`, `active`, `delivered`, `completed`, `cancelled`, `refunded`, `expired_unanswered` using `DO` block.
- [ ] Alter table `bookings`: Drop `slot_id` NOT NULL constraint.
- [ ] Alter table `bookings`: Add `payment_status` column (default 'unpaid').
- [ ] Alter table `bookings`: Add `requirements` column (jsonb).
- [ ] Alter table `bookings`: Add `package_id` column (text).
- [ ] **Security**: `REVOKE UPDATE(payment_status) ON public.bookings FROM authenticated;` (Prevent manual changes).
- [ ] **Action**: Enable RLS on `bookings` explicitly.

### 2) RLS Policies
- [ ] Create `bookings_select_parties`: `FOR SELECT USING (auth.uid() = client_id OR auth.uid() = provider_id)`.
- [ ] Create `bookings_insert_client`: `FOR INSERT WITH CHECK (auth.uid() = client_id)`.
- [ ] Create `bookings_update_provider`: `FOR UPDATE USING (auth.uid() = provider_id) WITH CHECK (auth.uid() = provider_id AND status IN ('active', 'delivered', 'cancelled'))` (Cannot set refunded/completed).
- [ ] Create `bookings_update_client`: `FOR UPDATE USING (auth.uid() = client_id) WITH CHECK (auth.uid() = client_id AND status = 'cancelled')`.
- [ ] Create `bookings_deny_delete`: `FOR DELETE USING (false)`.
- [ ] **Verify**: Status updates tightly controlled.

### 3) RPC / Edge Functions
- [ ] Add `is_admin_check` function (SECURITY DEFINER, SET search_path=public) to verify role.
- [ ] Create `process_expired_requests` (Admin-only):
    - [ ] Secure with `IF NOT is_admin_check() THEN RAISE EXCEPTION`.
    - [ ] Logic: Call `process_payment_event(id, 'booking', 'refund')`.
    - [ ] Logic: Update status `expired_unanswered`.

### 4) Backend Services
- [ ] Update `BookingService`: `createBooking(package)` -> Insert + Call RPC 'escrow'.
- [ ] Update `BookingService`: `approveAndRelease(id)` -> Call RPC 'release'.
- [ ] Update `BookingService`: `declineBooking(id)` -> Update status to 'cancelled' (RLS allows) -> Call RPC 'refund'. (**Decision 1**: Provider sets cancelled, RPC sets refunded payment AND status 'refunded').
- [ ] Update `BookingService`: `markDelivered(id)` -> Update status 'delivered'.

### 5) ViewModels
- [ ] Refactor `BookingViewModel`: Remove slot logic, handle Option B.

### 6) UI Screens/Widgets
- [ ] Update `BookingScreen`: Remove "Select Slot".
- [ ] Update `CreateTaskScreen`: Remove "Upload Image".
- [ ] Fix `BookingCardSkeleton`.

### 7) QA
- [ ] Manual: Decline Booking -> Verify final DB row status='refunded' (NOT cancelled) and payment='refunded'.

### 8) Docs
- [ ] Update `SUPABASE_SETUP.md`.

---

## Phase 2: Unified Management & Notes System

### 1) Database
- [ ] Create table `work_logs`.
- [ ] Index on `(related_entity_id, related_entity_type)`.
- [ ] Function `is_work_log_participant(type, entity_id, uid) -> bool` mapping rules.
- [ ] Function `is_provider_of_entity(type, entity_id, uid) -> bool` mapping rules (for private checks).
- [ ] Enable RLS on `work_logs`.

### 2) RLS Policies
- [ ] Create `logs_select_private`: `FOR SELECT USING (auth.uid() = author_id AND is_private = true)`.
- [ ] Create `logs_select_public`: `FOR SELECT USING (is_private = false AND (auth.uid() = author_id OR is_work_log_participant(...)))`.
- [ ] Create `logs_insert_participants`: `FOR INSERT WITH CHECK (is_work_log_participant(...) AND (is_private = false OR (is_private = true AND is_provider_of_entity(...))))`. (**Decision 2**: Private logs restricted to Provider).
- [ ] Create `logs_deny_update`: `FOR UPDATE USING (false)`.
- [ ] Create `logs_deny_delete`: `FOR DELETE USING (false)`.

### 3) RPC
- [ ] (None).

### 4) Services
- [ ] Create `WorkLogService`.
- [ ] Map `task_requests` queries in `TaskService`.

### 5) ViewModels
- [ ] Create `WorkLogViewModel`.

### 6) UI
- [ ] Create `OrderManagementPanel`.
- [ ] Update `BookingDetailsScreen`: Embed Panel.
- [ ] Update `TaskDetailsScreen`: Embed Panel (for `task_requests`).

### 7) QA
- [ ] Manual: Client attempt private log -> Error.
- [ ] Manual: Freelancer private log -> Success (Client can't see).

---

## Phase 3: Dashboard Restructuring

### 6) UI
- [ ] `FreelancerDashboard`: Work tab (Active = active + delivered).
- [ ] `ClientDashboard`: Tasks tab (Awarded = assigned/pending_payment).

---

## Phase 4: Freelancer Wallet MVP

### 1) Database
- [ ] Create `wallet_transactions` (id, user_id, amount, type, status, related_entity*, related_txn_id, created_at).
- [ ] Enable RLS.

### 2) RLS Policies
- [ ] `wallet_select_own`: `FOR SELECT USING (auth.uid() = user_id)`.
- [ ] `wallet_deny_insert`: `FOR INSERT WITH CHECK (false)`.
- [ ] `wallet_deny_updates`: `FOR UPDATE USING (false)`.
- [ ] `wallet_deny_delete`: `FOR DELETE USING (false)`.

### 3) RPC
- [ ] Create `process_payment_event(p_entity_id, p_type, p_event)`: `SECURITY DEFINER`.
    - [ ] `SET search_path = public` (Security best practice).
    - [ ] `REVOKE ALL` from PUBLIC; `GRANT EXECUTE` to authenticated.
    - [ ] Logic (Escrow): Insert `type='escrow', status='pending'`. Entity `payment_status='held'`.
    - [ ] Logic (Release): Look up pending escrow (idempotency). Update it `status='completed'`. Insert `type='release', status='completed', related_txn_id=escrow_id`. Entity `status='completed', payment_status='released'`.
    - [ ] Logic (Refund): Look up pending escrow. Update it `status='refunded'`. Insert `type='refund', status='completed', related_txn_id=escrow_id`. Entity `status='refunded', payment_status='refunded'`.

### 4) Services
- [ ] `WalletService`: Read-only.

### 5) ViewModels
- [ ] `WalletViewModel`: Calculate via `released` (completed sum) and `escrow` (pending sum).

---

## Phase 5: Monitoring & Polish

### 1) Database
- [ ] Create `audit_logs` (including receiver_id, is_read, etc fields if reusing? No, separate).
- [ ] **Action**: Enable RLS on `audit_logs`.

### 2) RLS Policies
- [ ] `audit_insert_auth`: `FOR INSERT WITH CHECK (auth.uid() IS NOT NULL)`.
- [ ] `audit_select_admin`: `FOR SELECT USING (is_admin_check())`.
- [ ] `audit_deny_update`: `FOR UPDATE USING (false)`.
- [ ] `audit_deny_delete`: `FOR DELETE USING (false)`.

### 5) ViewModels
- [ ] Update `NotificationViewModel`: Query `messages` table for count.
    - [ ] **Schema Check**: `messages` must have `receiver_id`, `is_read` (bool), and index `(receiver_id, is_read)`.

### 6) UI
- [ ] Notification Top Bar (Red/Gray icon).

---

## Release Gate

- [ ] **Escrow Lifecycle**: Pay -> Pending Escrow. Release -> Escrow Completed + Release txn created. Refund -> Escrow Cancelled + Refund txn created.
- [ ] **Data Integrity**: `bookings.payment_status` perfectly mirrors wallet state.
- [ ] **Security**: No client inserts to wallet. No manual `payment_status` updates allowed (revoked).
- [ ] **Decisions Implemented**: Provider private logs strictly enforced via function. Decline sets 'cancelled' (RPC completes refund loop).
