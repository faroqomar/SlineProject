# Ledger Split & Refund Proof

## A) Release Split Balance Proof

### Evidence

**File**: `20260303_direct_offer_ledger_rpc.sql`, lines 384-390 (post-patch via `20260308`)

```sql
-- Post-patch version (20260308):
INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
SELECT v_journal_entry_id, line.account_id, line.direction, line.amount, p_currency
FROM (
    VALUES
        (v_platform_escrow_id, 'DEBIT'::public.ledger_direction_enum, v_entity_amount_gross),
        (v_user_available_id,  'CREDIT'::public.ledger_direction_enum, v_net_amount),
        (v_platform_revenue_id,'CREDIT'::public.ledger_direction_enum, v_fee_amount)
) AS line(account_id, direction, amount)
WHERE line.amount > 0;
```

### Mathematical Proof

Given:

- `v_entity_amount_gross = G` (e.g., 100,000 IQD)
- `v_fee_rate_bps = R` (e.g., 1000 bps = 10%)
- `v_fee_amount = FLOOR(G * R / 10000)` → Line 351
- `v_net_amount = G - v_fee_amount` → Line 352

Then:

```
DEBIT  platform_escrow   = G
CREDIT provider_available = G - FLOOR(G*R/10000)
CREDIT platform_revenue   = FLOOR(G*R/10000)
```

**Balance check**: `DEBIT - CREDIT = G - (G - FLOOR(G*R/10000)) - FLOOR(G*R/10000) = 0` ✅

### Invariant: `Client_Paid = Freelancer_Earned + Platform_Fee`

- Client paid (at escrow): `G`
- Freelancer earned (at release): `v_net_amount = G - FLOOR(G*R/10000)`
- Platform fee (at release): `v_fee_amount = FLOOR(G*R/10000)`
- Sum: `(G - FLOOR(G*R/10000)) + FLOOR(G*R/10000) = G` ✅

### Edge Case: Zero Fee (fee_rate_bps = 0)

When `v_fee_rate_bps = 0`:

- `v_fee_amount = FLOOR(G * 0 / 10000) = 0`
- `v_net_amount = G - 0 = G`

The post-patch code (`20260308`) correctly handles this:

```sql
WHERE line.amount > 0;  -- Skips the platform_revenue line when fee = 0
```

Result: Only 2 ledger lines instead of 3, avoiding the `ck_ledger_lines_amount_positive` constraint. ✅

---

## B) Refund Reversal Proof

### Evidence

**File**: `20260303_direct_offer_ledger_rpc.sql`, lines 534-538

```sql
-- Create ledger lines (DEBIT platform_escrow, CREDIT user_available)
INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
VALUES
    (v_journal_entry_id, v_platform_escrow_id, 'DEBIT', v_entity_amount_gross, p_currency),
    (v_journal_entry_id, v_user_available_id,  'CREDIT', v_entity_amount_gross, p_currency);
```

### Analysis

**Refund is a gross-amount reversal of escrow. ✅**

| Event         | DEBIT Account             | CREDIT Account            | Amount |
| ------------- | ------------------------- | ------------------------- | ------ |
| `escrow_hold` | `user_available` (client) | `platform_escrow`         | `G`    |
| `refund`      | `platform_escrow`         | `user_available` (client) | `G`    |

The refund:

1. Returns the **full gross amount** to the client. ✅
2. Does **not** recalculate or deduct fees. ✅ (No fee variables are used in the refund handler.)
3. Uses the same `v_entity_amount_gross` as the original escrow. ✅

### Balance Proof

```
Escrow:  DEBIT client(-G) + CREDIT escrow(+G) = 0
Refund:  DEBIT escrow(-G) + CREDIT client(+G) = 0
Net:     client(0) + escrow(0) = 0  ✅
```

### Gate Validation

- Refund only allowed when `payment_status = 'held'` (line 471). ✅
- Status must be `declined`, `canceled`, `expired_unanswered`, or `dispute_refund` (line 482). ✅
- Actor can be client, provider, or system (line 495). ✅

### Refund Does NOT Touch Released Funds

If `payment_status = 'released'` (already paid out), the refund gate rejects the call. This prevents double-spending. ✅

---

## C) Rounding Policy

### Evidence

**Line 351**: `v_fee_amount := FLOOR((v_entity_amount_gross * v_fee_rate_bps) / 10000);`

**Rounding rule: `FLOOR`** — always rounds down.

This means:

- The fee will never exceed the mathematical percentage.
- Any fractional amount goes to the provider (net), not the platform.
- This is the **provider-favorable** rounding policy.

### Consistency Check

| Location                          | Rounding Used                          | Consistent?         |
| --------------------------------- | -------------------------------------- | ------------------- |
| RPC `release_with_fee` (line 351) | `FLOOR`                                | ✅ Source           |
| Journal `meta` (line 373)         | `'rounding_policy': 'floor'`           | ✅ Documented       |
| UI (Flutter)                      | N/A (reads stored values)              | ✅ No recalculation |
| Ledger lines                      | Uses `v_fee_amount` and `v_net_amount` | ✅ Same values      |

**The rounding policy is consistent.** ✅

### Edge Case: Very Small Amounts

For `price = 1 IQD` and `fee_rate_bps = 1000`:

- `fee = FLOOR(1 * 1000 / 10000) = FLOOR(0.1) = 0`
- `net = 1 - 0 = 1`

Platform gets 0 on micro-transactions. The zero-fee patch handles this correctly (line skipped). ✅

---

## D) Summary

| Check                                            | Status    | Evidence                                 |
| ------------------------------------------------ | --------- | ---------------------------------------- |
| Release split balances (DEBIT = CREDIT)          | ✅ PROVEN | Lines 384-390                            |
| `Client_Paid = Freelancer_Earned + Platform_Fee` | ✅ PROVEN | Mathematical proof above                 |
| Refund reverses gross only                       | ✅ PROVEN | Lines 534-538                            |
| Refund ignores fees                              | ✅ PROVEN | No fee variables in refund handler       |
| Zero-fee edge case handled                       | ✅ PROVEN | `WHERE line.amount > 0` (20260308 patch) |
| Rounding policy consistent                       | ✅ PROVEN | `FLOOR` everywhere                       |
| Double-spend prevented                           | ✅ PROVEN | Gate: `payment_status = 'held'`          |
