# Test Plan: Dispute Lifecycle

## 1. Unit Tests (Flutter)

- **Path**: `test/features/safety/services/dispute_service_test.dart`
- **Test cases**:
  - `submitDispute` inserts row with `status='open'`.
  - `submitDispute` throws if `reason` is empty.
  - `submitDispute` correctly includes `task_id` and `defendant_id`.

## 2. RLS & Security Tests (Supabase)

- **Path**: `supabase/tests/disputes_rls.test.sql`
- **Test cases**:
  - `complainant` can insert into `disputes`.
  - `non-participant` CANNOT select from `disputes`.
  - `complainant` CANNOT update `status` column (Privilege boundary).
  - `admin` role can update all columns.

## 3. Integration Tests (Ledger & Transitions)

- **Path**: `supabase/tests/dispute_resolution.test.sql`
- **Test cases**:
  - Trigger `trg_dispute_guard` prevents `open -> resolved` without passing through `active`.
  - Calling `process_payment_event_ledger` with `refund` correctly debit/credits the ledger lines.
  - `disputes.resolved_at` is NOT null after status becomes 'resolved'.

## 4. Manual Verification

- **Steps**:
  1. Log in as Client A.
  2. Submit a dispute for Task T (Assigned to Freelancer B).
  3. Verify row in `disputes` is 'open'.
  4. Verify Task T is "Locked" (cannot be approved for payment).
  5. Log in as Admin.
  6. Change status to 'active'.
  7. Process resolution (Refund).
  8. Verify wallet balance for Client A increased.
