# Test Plan: Dynamic Platform Fee

## 1. Unit Tests (SQL/RPC)

- [ ] **Test Global Fee Update**: Verify `platform_settings` updates only by admins.
- [ ] **Test Escrow Lock**:
  1. Set fee to 12%.
  2. Start booking (escrow).
  3. Verify `bookings.fee_rate_applied` is 12%.
  4. Change fee to 15%.
  5. Verify `bookings.fee_rate_applied` is STILL 12%.
- [ ] **Test Release Logic**:
  1. Release booking with locked rate of 12%.
  2. Verify `ledger_lines` split matches 12% fee.
  3. Verify `bookings.fee_amount` and `net_amount` are populated correctly.

## 2. Security / Edge Cases

- [ ] **Spoof Attempt**: Call RPC as Client passing `p_meta -> 'fee_rate_bps': 0`. Verify it is ignored in favor of the locked rate.
- [ ] **Zero Amount**: Verify `ck_ledger_lines_amount_positive` is not violated if fee calculates to 0 (rounding/small amounts).
- [ ] **Rounding**: Test with amounts like 99.99 (if applicable) or fractional IQD to ensure `FLOOR` or `ROUND` works as expected.

## 3. Monitoring & Alerts

- [ ] **Alert on Zero Revenue**: Alert if a high-value booking results in 0 platform revenue.
- [ ] **Audit Trail**: Ensure `admin_logs` record every change to `platform_settings`.
