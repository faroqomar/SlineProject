# Minimal Patch Plan: Escrow Idempotency

> This patch is **NOT URGENT** — the system is currently safe. These are **correctness improvements** to align the code with its documented intent.

---

## Patch 1: Stable Idempotency Key (Recommended, Low Risk)

### What

Remove `now()` from the idempotency key hash in `rpc_approve_delivery`.

### Why

The current key is unique per call, which defeats the purpose of idempotency. Although the system is safe due to `FOR UPDATE` + status gates, the idempotency key should be a correct, working defense layer.

### SQL

```sql
-- BEFORE (current)
v_idempotency_key := encode(
  extensions.digest(
    entity_id::text || ':release_with_fee:' || now()::text,
    'sha256'
  ), 'hex'
);

-- AFTER (proposed)
v_idempotency_key := encode(
  extensions.digest(
    entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status,
    'sha256'
  ), 'hex'
);
```

### Impact

- **Zero-downtime**: `CREATE OR REPLACE FUNCTION` is atomic
- **No app changes needed**: App doesn't send idempotency key
- **Backward compatible**: Old keys remain in `journal_entries`, new keys are different format

### Verification

```sql
-- After patching, verify the function signature
SELECT prosrc FROM pg_proc WHERE proname = 'rpc_approve_delivery';
-- Should NOT contain 'now()'

-- Verify existing entries still work
SELECT COUNT(*) FROM journal_entries WHERE event_type = 'release_with_fee';
-- Should return same count as before
```

---

## Patch 2: Fix `fee_rate_bps = 0` (Business Decision Required)

### What

Change `'fee_rate_bps': 0` to `'fee_rate_bps': 1000` (or remove it entirely to use the default 10%).

### Why

Currently `rpc_approve_delivery` passes `fee_rate_bps = 0`, which means the platform collects **zero commission** on delivery approvals. The ledger function defaults to 1000 bps (10%) only when `fee_rate_bps` is NOT provided — but the explicit `0` overrides this.

### SQL

```sql
-- BEFORE
p_meta := '{"fee_rate_bps": 0}'::jsonb

-- AFTER (Option A: Use default 10%)
p_meta := '{}'::jsonb

-- AFTER (Option B: Explicit 10%)
p_meta := '{"fee_rate_bps": 1000}'::jsonb
```

### ⚠ This requires a business decision

- If `fee_rate_bps = 0` is **intentional** (fees collected at escrow hold time), no patch needed.
- If it's a **bug**, all past releases had 0 fee and need retroactive correction.

---

## Patch 3: Drop Duplicate Index (Cleanup)

### What

Drop the duplicate unique index on `journal_entries.idempotency_key`.

### SQL

```sql
-- Two indexes exist:
-- 1. journal_entries_idempotency_key_key (from UNIQUE constraint)
-- 2. idx_journal_entries_idempotency (manually created)
DROP INDEX IF EXISTS idx_journal_entries_idempotency;
```

### Impact

- Saves storage and reduces write amplification
- Zero-risk: the constraint-backed index remains

---

## Patch 4: UI Debounce on Approve Button (Optional, Defense-in-Depth)

### What

Add one-shot guard to prevent double-tap in `ReviewDeliveryModal`.

### Dart

```dart
// In _ReviewDeliveryModalState
bool _hasApproved = false;

Future<void> _handleApprove() async {
  if (_hasApproved) return; // one-shot guard
  _hasApproved = true;
  setState(() => _isLoading = true);
  try {
    await widget.onApprove();
    if (mounted) Navigator.pop(context, true);
  } catch (_) {
    _hasApproved = false; // allow retry on error
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### Impact

- Prevents the frame-budget race window between tap and `setState` render
- Backend already protects, but this is good UX

---

## Implementation Order

1. **Patch 1** (Stable key) — pure improvement, no risk
2. **Patch 3** (Drop index) — cleanup
3. **Patch 2** (Fee rate) — needs business decision first
4. **Patch 4** (UI debounce) — defense-in-depth, low priority
