# Idempotency Proof: Escrow Release

## Question A1: Does the key include a time seed?

### ✅ YES — PROVEN (PRODUCTION BLOCKER)

**Source**: Live SQL of `rpc_approve_delivery` (verified 2026-03-06)

```sql
v_idempotency_key := encode(
  extensions.digest(
    entity_id::text || ':release_with_fee:' || now()::text,
    'sha256'
  ), 'hex'
);
```

The `now()::text` component changes on every transaction. Two calls 1 second apart produce completely different SHA256 hashes.

**Example**:

- Call 1 at `2026-03-06 20:00:01`: `digest('abc-123:release_with_fee:2026-03-06 20:00:01' ...)` → `0xA1B2...`
- Call 2 at `2026-03-06 20:00:02`: `digest('abc-123:release_with_fee:2026-03-06 20:00:02' ...)` → `0xC3D4...`

These are **different keys**. The UNIQUE constraint WILL NOT fire. The second call WILL create a second journal entry and release funds again.

---

## Question A2: Does a network retry produce the same key?

### 🔴 NO — PROVEN FAILURE

**Proof**: Because `now()` returns the transaction timestamp, and a retry is a new transaction, the key will always be different.

**Attack scenario**:

1. Client taps "Approve" → RPC generates key `K1` with `now() = T1`
2. DB commits: `journal_entries` row with `K1`, `ledger_lines` debit/credit posted, `bookings.payment_status = 'released'`
3. Network cuts before HTTP response reaches app
4. App shows error → client taps "Approve" again
5. **BUT**: `rpc_approve_delivery` re-reads the booking and since `payment_status = 'released'` and `status = 'completed'`, it should fail at the status check...

**Wait — deeper analysis**:

Looking at the actual flow in `rpc_approve_delivery`:

```sql
-- Step 1: Read entity (no FOR UPDATE)
select status, payment_status, client_id, provider_id, price
into v_status, v_payment_status, v_client_id, v_provider_id, v_price
from bookings where id = entity_id;

-- Step 2: Check status
if v_status != 'delivered' then raise exception 'Work not delivered'; end if;

-- Step 3: Branch on payment_status
if v_payment_status = 'held' then
  -- Generate key with now(), call ledger
  ...
else
  -- Just update status to completed
  update bookings set status = 'completed' ...
end if;
```

**Scenario**: After first success, `status = 'completed'` and `payment_status = 'released'`.

- Step 2: `status != 'delivered'` → `RAISE EXCEPTION 'Work not delivered'` ✅

**So the OUTER RPC's status check acts as a secondary guard.**

### Revised Assessment:

The `now()`-seeded key is still wrong in principle, but the **status check in `rpc_approve_delivery`** (`status != 'delivered'`) catches retries AFTER the first success because the status transitions to `'completed'`.

**HOWEVER**, the race window between two simultaneous calls (before the status update commits) is the real danger:

1. Call A reads `status = 'delivered'`, `payment_status = 'held'` (snapshot)
2. Call B reads `status = 'delivered'`, `payment_status = 'held'` (snapshot, same moment)
3. Call A generates `K1`, enters `process_payment_event_ledger`
4. Call B generates `K2`, enters `process_payment_event_ledger`
5. Inside `process_payment_event_ledger`, both hit `FOR UPDATE` — **Call B blocks until Call A commits**
6. Call A commits: `payment_status = 'released'`
7. Call B resumes: `FOR UPDATE` returns `payment_status = 'released'` → **gate check fails** ✅

**The `FOR UPDATE` inside `process_payment_event_ledger` IS the real guard.** Not the idempotency key.

### Final Verdict on A2:

- **Network retry after success**: ✅ Safe (outer RPC status check blocks it)
- **Simultaneous concurrent calls**: ✅ Safe (inner `FOR UPDATE` + status gate blocks it)
- **Idempotency key correctness**: 🔴 **Broken by design** but **masked by status guards**

> The system is safe **despite** the broken idempotency key, not **because** of it.

---

## Question A3: UNIQUE constraint on `journal_entries.idempotency_key`

### ✅ PROVEN

**Source**: Live `pg_constraint` query (verified 2026-03-06)

```
journal_entries_idempotency_key_key | UNIQUE (idempotency_key)
```

**EXCEPTION handler** in `process_payment_event_ledger`:

```sql
EXCEPTION WHEN unique_violation THEN
  IF SQLERRM LIKE '%journal_entries_idempotency_key%' THEN
    SELECT id INTO v_existing_journal_id FROM journal_entries WHERE idempotency_key = p_idempotency_key;
    RETURN jsonb_build_object('ok', true, 'journal_entry_id', v_existing_journal_id, ...);
  END IF;
```

✅ The UNIQUE constraint exists. ✅ The EXCEPTION handler returns a safe no-op. **But the broken key means this path is never actually triggered for retries.**

---

## Summary Table

| Check                                  | Status         | Evidence                                                               |
| -------------------------------------- | -------------- | ---------------------------------------------------------------------- |
| Key includes time seed (`now()`)       | 🔴 YES (bad)   | `rpc_approve_delivery` live SQL                                        |
| Retry produces same key                | 🔴 NO (broken) | `now()` changes per-transaction                                        |
| UNIQUE constraint on `idempotency_key` | ✅ Yes         | `pg_constraint` query                                                  |
| UNIQUE violation → safe no-op          | ✅ Yes         | EXCEPTION handler in `process_payment_event_ledger`                    |
| **Overall idempotency correctness**    | 🟡 PARTIAL     | Key is broken, but status guards + `FOR UPDATE` prevent double-release |
