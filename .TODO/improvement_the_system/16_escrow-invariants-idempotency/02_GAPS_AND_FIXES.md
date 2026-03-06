# Gaps and Fixes: 16_escrow-invariants-idempotency.md

## Skills applied:

- Idempotency & Concurrency
- Threat Modeling (Security)
- DB-First Financial Modeling

---

## GAP 1: "Ephemeral" Idempotency Key (CRITICAL)

### The Issue

The current implementation of `rpc_approve_delivery` generates the `idempotency_key` server-side using `now()::text`.

```sql
entity_id::text || ':release_with_fee:' || now()::text
```

Because `now()` changes on every request, a network retry from the mobile app will result in a **different** key being generated on the server. This completely bypasses the `UNIQUE` constraint on `journal_entries.idempotency_key`.

### The Risk

If the client calls `approveDelivery`, the server processes it (debits escrow, credits freelancer), but the network cuts out before the "Success" response reaches the app. The app retries the call. The server generates a **second** key, sees no collision, and **releases funds a second time**.

### The Fix

The idempotency key must be derived from **immutable business facts** or provided by the **client**.

- **Option A (Stable Key)**: Use `entity_id::text || ':release_with_fee:' || source_status`. Since the status transitions to `completed` after the first success, a second attempt would either collide on the key OR fail a status-check precondition.
- **Option B (Client Key)**: Require the client to pass a GUID created at the moment of the user's "Confirm" tap.

---

## GAP 2: Missing Pre-flight Status Check

### The Issue

The logic relies on the `idempotency_key` as the primary guard. If the key generation is flawed (Gap 1), there is no secondary check to see if the escrow has already been released for this entity.

### The Fix

Add an explicit check at the start of `rpc_approve_delivery`:

```sql
IF EXISTS (
  SELECT 1 FROM journal_entries
  WHERE related_entity_id = p_entity_id
  AND event_type = 'release_with_fee'
  AND status = 'posted'
) THEN
  RETURN; -- Already released
END IF;
```

---

## GAP 3: Atomic Status vs. Ledger Lag

### The Issue

The current diagram shows:

1. `PROC`: Execute ledger lines.
2. `COMPLETE`: Update entity status.
   If the ledger insert succeeds but the entity update fails (unlikely in a transaction, but possible if there are complex triggers), the system might be in an inconsistent state.

### The Fix

Ensure the entity update is the **first** thing that happens (or use `FOR UPDATE` lock) to serialize requests for the same entity at the database level.

1. `SELECT ... FROM tasks WHERE id = p_entity_id FOR UPDATE;`
2. Check if status is correct for release.
3. Call ledger function.
4. Update status.

---

## GAP 4: Fee Rate Precision & Edge Cases

### The Issue

`release_with_fee` assumes a fee is always present. If the fee is 0, it might try to insert a 0-amount ledger line, which violates `ck_ledger_lines_amount_positive`.

### The Fix

The ledger function must skip credit lines where `amount <= 0`. (Evidence suggests this was patched in v2.17, but should be strictly enforced in the contract).
