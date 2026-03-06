# Concurrency Proof: Escrow Release

## Question B1: Is there row-level locking?

### ✅ PROVEN — Inside `process_payment_event_ledger`

**Source**: Live SQL of `process_payment_event_ledger`, section 5.2 (`release_with_fee`)

```sql
SELECT id, client_id, provider_id, status, payment_status, price AS amount_gross
INTO v_entity
FROM public.bookings
WHERE id = p_related_entity_id
FOR UPDATE;
```

This `FOR UPDATE` lock is applied inside the ledger function for **bookings**, **task_requests**, and **direct_offers**.

### 🟡 PARTIAL — Missing in `rpc_approve_delivery` (outer RPC)

**Source**: Live SQL of `rpc_approve_delivery`

```sql
select status, payment_status, client_id, provider_id, price
into v_status, v_payment_status, v_client_id, v_provider_id, v_price
from bookings where id = entity_id;
-- NO FOR UPDATE here
```

The outer RPC reads without a lock. This means:

- Two concurrent calls can BOTH read `status = 'delivered'` and `payment_status = 'held'`
- Both proceed to generate idempotency keys (different keys due to `now()`)
- Both call `process_payment_event_ledger`
- **Inside** the ledger function, the `FOR UPDATE` serializes them
- The second call sees `payment_status = 'released'` after the first commits → gate blocks it

**This works because the INNER function re-reads with `FOR UPDATE`.** The outer read is a "fast-path optimization" (or oversight), but it's safe because the inner function does the authoritative check.

---

## Question B2: Can two concurrent approvals double-release?

### ✅ PROVEN SAFE — Cannot double-release

**Proof by tracing two concurrent calls (Call A and Call B) line-by-line**:

| Step | Call A                                                                            | Call B                                                                            |
| ---- | --------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| 1    | `rpc_approve_delivery` reads booking: `status='delivered', payment_status='held'` | `rpc_approve_delivery` reads booking: `status='delivered', payment_status='held'` |
| 2    | Generates key `K_A` (with `now()=T_A`)                                            | Generates key `K_B` (with `now()=T_B`)                                            |
| 3    | Calls `process_payment_event_ledger(K_A)`                                         | Calls `process_payment_event_ledger(K_B)`                                         |
| 4    | Idempotency check: no existing journal with `K_A` → proceed                       | Idempotency check: no existing journal with `K_B` → proceed                       |
| 5    | `SELECT ... FROM bookings WHERE id = X FOR UPDATE` — **acquires row lock**        | `SELECT ... FROM bookings WHERE id = X FOR UPDATE` — **BLOCKS (waiting for A)**   |
| 6    | Reads `payment_status = 'held'` → passes gate                                     | _(blocked)_                                                                       |
| 7    | Inserts journal entry with `K_A`                                                  | _(blocked)_                                                                       |
| 8    | Inserts ledger lines (DEBIT escrow, CREDIT provider, CREDIT revenue)              | _(blocked)_                                                                       |
| 9    | `UPDATE bookings SET payment_status = 'released', status = 'completed'`           | _(blocked)_                                                                       |
| 10   | **COMMIT** — releases lock                                                        | **UNBLOCKED** — `FOR UPDATE` returns now                                          |
| 11   | Returns `{ok: true, journal_entry_id: J_A}`                                       | Reads `payment_status = 'released'` → **`ERR_GATE_NOT_ALLOWED`**                  |
| 12   | —                                                                                 | Returns `{ok: false, error: 'ERR_GATE_NOT_ALLOWED'}`                              |

✅ **Only one release ever occurs.** The second call is blocked by `FOR UPDATE` and then rejected by the status gate.

---

## Edge Case: What if both calls arrive within the SAME transaction?

This is impossible in PostgreSQL. Each `SELECT ... FOR UPDATE` operates within its own transaction. The second call's transaction will wait for the first to commit or rollback.

---

## Summary Table

| Check                                  | Status                  | Evidence                                                |
| -------------------------------------- | ----------------------- | ------------------------------------------------------- |
| `FOR UPDATE` on entity row             | ✅ Yes (inner function) | `process_payment_event_ledger` L5.2                     |
| `FOR UPDATE` in outer RPC              | 🟡 Missing              | `rpc_approve_delivery` reads plain SELECT               |
| Two concurrent calls → double-release? | ✅ No                   | `FOR UPDATE` serializes, status gate blocks second call |
| **Overall concurrency safety**         | ✅ Safe                 | Two-layer defense: `FOR UPDATE` + status gate           |
