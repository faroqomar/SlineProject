# Ledger Event Flow: Smoke Checklist & Withdrawal Runbook

**Plan:** PLAN_LedgerEventFlow_2026-03-07  
**Last updated:** 2026-03-07

---

## Pre-release smoke checklist

Run before release (manual or automated). All must pass.

| # | Step | Expected |
|---|------|----------|
| 1 | **Pay Booking** — Complete a booking payment (e.g. QiCard or demo flow). | New rows in `ledger_lines` for the booking; journal entry with event_type `escrow_hold` (or `gateway_escrow`). |
| 2 | **Approve Delivery** — Client approves delivery for a held booking. | Provider’s available balance increases; journal entry with event_type `release_with_fee`; `ledger_lines` balanced (sum DR = sum CR per journal). |
| 3 | **Withdraw** — User requests withdrawal from wallet. | Row in `withdrawal_requests` with status `requested`; corresponding journal entry and `ledger_lines` for `withdrawal_request` (user_available DR, user_pending_withdrawal CR). |

**Verification queries (optional):**

- Unbalanced journals (should return 0 rows):
  ```sql
  SELECT journal_entry_id, sum(amount * (CASE WHEN direction = 'CREDIT' THEN 1 ELSE -1 END)) AS balance
  FROM ledger_lines
  GROUP BY journal_entry_id
  HAVING sum(amount * (CASE WHEN direction = 'CREDIT' THEN 1 ELSE -1 END)) != 0;
  ```
- Forensics in meta (sample one recent journal):
  ```sql
  SELECT id, event_type, meta->>'session_id' AS session_id FROM journal_entries ORDER BY created_at DESC LIMIT 5;
  ```

---

## Withdrawal two-phase runbook (orphan handling)

**Decision:** Withdrawal uses two-phase (insert `withdrawal_requests` then call ledger). If the ledger call fails, the app marks the request as `failed`. Orphaned rows (status = `requested` with no ledger entry) can occur if cleanup fails.

### Orphan detection query

```sql
-- Withdrawal requests stuck in 'requested' with no matching journal (run as service_role or admin)
SELECT wr.id, wr.user_id, wr.amount, wr.created_at
FROM withdrawal_requests wr
LEFT JOIN journal_entries je ON je.related_entity_type = 'withdrawal_request' AND je.related_entity_id = wr.id
WHERE wr.status = 'requested' AND je.id IS NULL
ORDER BY wr.created_at DESC;
```

### Actions

1. **Review** the list; confirm with support whether the user retried or reported failure.
2. **Mark failed** to unblock reporting and prevent double-processing:
   ```sql
   UPDATE withdrawal_requests SET status = 'failed', updated_at = now() WHERE id = ANY($1);
   ```
   (Use the IDs from the orphan query.)
3. **Log** in admin or support tooling; no automatic retry of ledger without product approval.

---

## Test run commands

- Unit (wallet): `flutter test test/unit/wallet/`
- RLS (ledger): `flutter test test/rls/ledger_rls_test.dart`
- Integration/RLS with real Supabase: use `RlsTestHelper(Supabase.instance.client)` and run `assertCannotInsert` for `ledger_lines` / `journal_entries` (see `test/rls/ledger_rls_test.dart`).

Timeout/retry: integration tests 30s timeout, 1 retry; failure logs in test output.
