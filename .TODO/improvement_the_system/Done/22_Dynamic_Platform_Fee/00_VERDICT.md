# VERDICT: Dynamic Platform Fee System

## OLD vs NEW Comparison

### OLD System (Current Implementation)

| Aspect         | Detail                                             | Evidence                                             |
| -------------- | -------------------------------------------------- | ---------------------------------------------------- |
| Fee Source     | Hardcoded 1000 bps (10%), overridable via `p_meta` | `20260303` RPC line 350                              |
| Fee Locking    | ❌ None                                            | `escrow_hold` handler has no fee logic               |
| Client Control | 🔴 Client can set fee to 0 via `p_meta`            | `COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000)` |
| Config Table   | `system_config` exists but no fee row              | Live DB query: 4 keys, none fee-related              |
| Fee Columns    | ❌ Only `price` on bookings                        | `information_schema.columns` query                   |
| Ledger Math    | ✅ Balanced (DEBIT = CREDIT sum)                   | Lines 384-390                                        |
| Refund         | ✅ Correct gross reversal (no fee recalc)          | Lines 534-538                                        |
| Rounding       | ✅ Consistent `FLOOR` policy                       | Line 351 + meta tag                                  |
| Idempotency    | ✅ Journal-level replay protection                 | Lines 75-90                                          |
| Audit Trail    | ✅ `audit_logs` written for all events             | Lines 258-261, 401-404                               |

**OLD Score: 4/10**

- Ledger mechanics are sound ✅
- Fee source is catastrophically insecure 🔴
- No locking, no config, no immutability 🔴

---

### NEW System (Diagram 22 — Aspirational Design)

| Aspect                | Detail                                         | Evidence                                 |
| --------------------- | ---------------------------------------------- | ---------------------------------------- |
| Fee Source            | `platform_settings.fee_rate_default`           | Diagram line 20                          |
| Fee Locking           | Lock at escrow time                            | Diagram lines 30-42                      |
| Client Control        | Client cannot influence fee                    | Diagram design intent                    |
| Config Table          | `platform_settings` table                      | Diagram line 15                          |
| Fee Columns           | `fee_rate_applied`, `fee_amount`, `net_amount` | Diagram lines 55-60                      |
| Implementation Status | ❌ **ZERO implementation**                     | No migration, no RPC changes, no columns |

**NEW (as-designed) Score: 9/10** — If implemented.
**NEW (as-implemented) Score: 0/10** — Nothing exists.

---

## Is NEW Truly Safer?

### **YES, but ONLY AFTER the Minimal Patch Plan is applied.**

The NEW design is architecturally superior because:

1. **Eliminates client fee spoofing** by reading from a locked entity column, not `p_meta`.
2. **Isolates rate changes** so admin adjustments only affect future escrows.
3. **Creates an audit trail** linking each booking to its specific fee policy.
4. **Uses immutability triggers** to prevent post-lock tampering.

Without the patch, the NEW system is pure documentation — the OLD system's risks remain fully active.

---

## Production Blockers

| #   | Blocker                                            | Severity | Fix in Patch      |
| --- | -------------------------------------------------- | -------- | ----------------- |
| 1   | **No fee config row** in `system_config`           | CRITICAL | Step 1            |
| 2   | **No `fee_rate_applied_bps` column** on entities   | CRITICAL | Step 2            |
| 3   | **`release_with_fee` reads `p_meta`** for fee rate | CRITICAL | Step 3b           |
| 4   | **`escrow_hold` does not lock fee**                | CRITICAL | Step 3a           |
| 5   | **No immutability guard** on locked fee            | HIGH     | Step 2 (trigger)  |
| 6   | **Legacy data** has no fee record                  | MEDIUM   | Step 2 (backfill) |

**All 4 CRITICAL blockers must be resolved before first production release.**

---

## Final Scorecard

| Metric               | OLD      | NEW (after patch) |
| -------------------- | -------- | ----------------- |
| Fee Source Security  | 1/10     | 10/10             |
| Lock Enforcement     | 0/10     | 10/10             |
| Ledger Balance       | 10/10    | 10/10             |
| Refund Correctness   | 10/10    | 10/10             |
| Rounding Consistency | 10/10    | 10/10             |
| Idempotency          | 10/10    | 10/10             |
| Audit Trail          | 8/10     | 10/10             |
| Config Flexibility   | 0/10     | 9/10              |
| **Overall**          | **4/10** | **10/10**         |

---

## Deliverables Summary

| File                       | Contents                                             |
| -------------------------- | ---------------------------------------------------- |
| `01_SCHEMA_PROOF.md`       | Evidence that fee columns and config row are missing |
| `02_RPC_SECURITY_AUDIT.md` | Proof of client-spoofable fee rate + minimal fix     |
| `03_LEDGER_SPLIT_PROOF.md` | Balanced journal proof + refund reversal proof       |
| `04_MINIMAL_PATCH_PLAN.md` | 3-step migration with backfill, triggers, RPC patch  |
