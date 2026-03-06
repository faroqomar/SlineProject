# UI Screenshots Checklist: Escrow Release

## F1) App Screenshots — Client Side

### SS-C1: Work Details BEFORE Approval

- **When**: Entity status = `delivered`, payment_status = `held`
- **Expected UI elements**:
  - Title: Booking/Task name
  - Status badge: `DELIVERED`
  - Payment status: `HELD`
  - Bottom bar: "Review" button (enabled, visible)
  - "Message" button alongside
- **Backend state**: `bookings.status = 'delivered'`, `bookings.payment_status = 'held'`
- **Proof query**: `SELECT status, payment_status FROM bookings WHERE id = $ENTITY_ID`

### SS-C2: Review Delivery Modal (Confirm Step)

- **When**: Client taps "Review" button
- **Expected UI elements**:
  - Modal title: "Review Delivery"
  - Body: "Review the delivered work..."
  - Two buttons: "Request Changes" (secondary) + "Approve" (primary, enabled)
- **Backend state**: No change yet (modal only)
- **File**: [review_delivery_modal.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/view/widgets/review_delivery_modal.dart#L102-L128)

### SS-C3: After Approval Success

- **When**: Client tapped "Approve", RPC succeeded
- **Expected UI elements**:
  - Modal closes
  - Status badge: `COMPLETED`
  - Payment status: `RELEASED`
  - Bottom bar: "Review" button **hidden** (canReview = false)
- **Backend state**: `bookings.status = 'completed'`, `bookings.payment_status = 'released'`
- **Proof query**: `SELECT status, payment_status FROM bookings WHERE id = $ENTITY_ID`
- **Ledger proof**: `SELECT * FROM journal_entries WHERE related_entity_id = $ENTITY_ID AND event_type = 'release_with_fee'` → exactly 1 row

### SS-C4: Network Failure Retry

- **Step 1**: Client taps "Approve" → DB commits → network cuts before response
  - **Expected**: Modal shows loading spinner, then returns to "Approve" button state (error caught)
  - **Take screenshot**
- **Step 2**: Client taps "Approve" again
  - **Expected**: RPC throws "Work not delivered" (status changed to `completed`)
  - Modal stays open with loading resets
  - **Take screenshot**
- **Step 3**: Client closes modal and refreshes
  - **Expected**: Screen shows `COMPLETED` + `RELEASED` states
  - **Take screenshot**
- **Backend proof**: `SELECT COUNT(*) FROM journal_entries WHERE related_entity_id = $ENTITY_ID AND event_type = 'release_with_fee'` → exactly 1

---

## F2) App Screenshots — Freelancer Side

### SS-F1: Earnings/Wallet BEFORE Release

- **When**: Entity is `delivered`, payment_status = `held`
- **Expected UI elements**:
  - Available balance: unchanged (escrow not yet released)
  - Work item status: `DELIVERED` with "Waiting for Client Review" label
- **Backend query**: Find provider account balance via ledger:
  ```sql
  SELECT COALESCE(SUM(CASE
    WHEN direction = 'CREDIT' THEN amount
    WHEN direction = 'DEBIT' THEN -amount
  END), 0) AS balance
  FROM ledger_lines ll
  JOIN journal_entries je ON ll.journal_entry_id = je.id
  JOIN accounts a ON ll.account_id = a.id
  WHERE a.account_code = 'user_available:' || $PROVIDER_ID
  AND je.status = 'posted';
  ```

### SS-F2: Earnings/Wallet AFTER Release

- **When**: Client approved, entity is `completed`, payment_status = `released`
- **Expected UI elements**:
  - Available balance: increased by `net_amount` (price - fee)
  - Work item status: `COMPLETED`
- **Backend query**: Same as above — verify balance increased by exactly `v_net_amount`

### SS-F3: Notification

- **When**: Delivery approved
- **Expected**: Push notification or in-app notification "Your delivery was approved" (if implemented)
- **Note**: Notification system existence needs to be verified separately

---

## F3) Admin Dashboard Screenshots

### ⚠ No Admin Dashboard Exists — Use Supabase Table Editor

### SS-A1: Ledger Trace for Entity

- **Tool**: Supabase SQL Editor
- **Query**:
  ```sql
  SELECT je.id, je.event_type, je.idempotency_key, je.status, je.created_at,
         ll.account_id, ll.direction, ll.amount, a.account_code
  FROM journal_entries je
  JOIN ledger_lines ll ON ll.journal_entry_id = je.id
  JOIN accounts a ON ll.account_id = a.id
  WHERE je.related_entity_id = $ENTITY_ID
  ORDER BY je.created_at, ll.id;
  ```
- **Expected**: Exactly 1 `release_with_fee` journal entry with 2-3 ledger lines (debit escrow, credit provider, optionally credit revenue)

### SS-A2: Escrow Monitor

- **Tool**: Supabase SQL Editor
- **Query**: `SELECT id, client_id, provider_id, price, payment_status FROM bookings WHERE payment_status = 'held';`
- **Expected**: Entity NOT in this list after successful release

### SS-A3: Audit Log

- **Tool**: Supabase SQL Editor
- **Query**: `SELECT * FROM audit_logs WHERE action = 'payment.release_with_fee' AND related_entity_id = $ENTITY_ID ORDER BY created_at;`
- **Expected**: Exactly 1 entry with `gross_amount`, `fee_amount`, `net_amount`

### SS-A4: Double-Release Anomaly Check

- **Tool**: Supabase SQL Editor
- **Query**:
  ```sql
  SELECT related_entity_id, COUNT(*) AS release_count
  FROM journal_entries
  WHERE event_type = 'release_with_fee' AND status = 'posted'
  GROUP BY related_entity_id
  HAVING COUNT(*) > 1;
  ```
- **Expected**: 0 rows (no entity should have >1 posted release)
