# Test Plan: Ledger Integrity

## 1. Unit Tests (Dart)

- **`LedgerService.generateIdempotencyKey`**: Verify that identical `entityId` and `eventType` always produce the same UUIDv5.
- **`WalletService.getWalletBalance`**: Mock `vw_wallet_balances_user` response and verify model parsing.
- **`LedgerService.submitPaymentEvent`**: Verify RPC call parameters (correct enum strings, types).

## 2. Database Integration Tests (SQL/RPC)

- **Double-Entry Balance Check**:
  ```sql
  -- After any process_payment_event_ledger call
  SELECT journal_id, sum(amount * (CASE WHEN direction = 'CREDIT' THEN 1 ELSE -1 END))
  FROM ledger_lines
  GROUP BY journal_id
  HAVING sum(amount * (CASE WHEN direction = 'CREDIT' THEN 1 ELSE -1 END)) != 0;
  -- Should return 0 rows.
  ```
- **Idempotency Replay**: Call the RPC twice with the same key; verify the second call returns the same result (or a specific error that the service maps to "already processed").
- **Insufficient Funds**: Attempt `escrow_hold` with amount > available; verify `ERR_INSUFFICIENT_FUNDS`.

## 3. RLS Verification

- Verify that a user cannot insert into `ledger_lines` or `journal_entries` directly (only via RPC).
- Verify that `vw_wallet_balances_user` correctly filters by `auth.uid()`.

## 4. Manual Verification

- Perform a "Pay Booking" action in the app.
- Check Supabase Dashboard -> `ledger_lines` for the generated rows.
- Verify `Provider Available` only increases after "Approve Delivery".
