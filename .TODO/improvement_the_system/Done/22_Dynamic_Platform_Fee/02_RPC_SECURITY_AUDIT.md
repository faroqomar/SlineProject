# RPC Security Audit: Dynamic Platform Fee

## Finding 1: Client-Controllable Fee Rate (CRITICAL)

### Evidence

**File**: `supabase/migrations/Archive/20260303_direct_offer_ledger_rpc.sql`
**Line 350**:

```sql
v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000);
```

### Analysis

- The `release_with_fee` handler reads `fee_rate_bps` from `p_meta`.
- `p_meta` is a JSONB parameter passed by the caller.
- The caller for `release_with_fee` is the **client** (line 339):
  ```sql
  IF v_actor_user_id IS NULL OR v_actor_user_id != v_client_id THEN
      -- reject
  ```
- This means: **any authenticated client can set their own fee to 0 bps** by calling:
  ```sql
  SELECT process_payment_event_ledger(
    'release_with_fee', 'booking', '<booking_id>', '<idem_key>',
    NULL, 'IQD', '{"fee_rate_bps": 0}'::jsonb
  );
  ```
- Result: Platform receives **zero revenue**. Provider gets full gross.

### Severity: **CRITICAL** 🔴

### Proof of Exploitability

1. Client creates a booking (price = 100,000 IQD).
2. Client escrows funds (`escrow_hold`) — no fee involved at this stage.
3. Provider delivers work, status moves to `delivered`.
4. Client calls `release_with_fee` with `p_meta = '{"fee_rate_bps": 0}'`.
5. RPC sets `v_fee_rate_bps = 0`, `v_fee_amount = 0`, `v_net_amount = 100,000`.
6. Platform gets 0 revenue. Provider gets 100% of gross.

### Why 1000 bps Hardcode is Also Bad

Even without spoofing, the 10% default is hardcoded. If the admin dashboard changes the fee to 15%, the RPC will still use 10% for any call that doesn't pass `fee_rate_bps` in meta. This means the diagram's "Lock at Escrow" concept is completely unimplemented.

---

## Finding 2: No Lock Mechanism Exists

### Evidence — `escrow_hold` handler (lines 107-274)

The full `escrow_hold` handler:

1. Validates entity type, status, payment_status ✅
2. Validates actor is client ✅
3. Checks sufficient funds ✅
4. Creates journal entry ✅
5. Creates ledger lines (DEBIT client, CREDIT escrow) ✅
6. **Updates entity `payment_status = 'held'`** ✅
7. ❌ **Does NOT read any fee rate from anywhere**
8. ❌ **Does NOT write `fee_rate_applied` to the entity**

There is **zero fee-related logic** in the escrow path. The diagram's "Lock at Escrow" is **entirely aspirational**.

---

## Finding 3: `get_public_system_config` Does Not Expose Fee Rate

### Evidence

**File**: `20260310101000_dashboard_public_config_reports_disputes_bridge.sql` (lines 90-100)

```sql
CREATE OR REPLACE FUNCTION public.get_public_system_config()
RETURNS TABLE(key text, value jsonb)
...
  WHERE sc.key IN ('maintenance_mode', 'app_banner', 'disable_signups', 'min_app_version')
```

The allowed-key whitelist does not include any fee-related keys. Even if a `fee_rate_bps` row were added to `system_config`, it would not be exposed through this function.

---

## Finding 4: `admin_update_system_config` Has No Fee Validation

### Evidence (lines 38-73)

```sql
CREATE OR REPLACE FUNCTION public.admin_update_system_config(
  p_key text,
  p_value jsonb,
  p_actor_user_id uuid
) RETURNS text
```

This function accepts **any** key/value pair. There is no domain validation for fee-specific constraints (e.g., non-negative, max cap, bps range 0–10000). An admin could set `fee_rate_bps` to `-500` or `99999`.

**Positive**: The function is `REVOKE`d from PUBLIC and only granted to `service_role`. It also writes to `audit_logs`. These are good security practices.

---

## Minimal Fix Required

### Fix 1: Remove `p_meta` fee override in `release_with_fee`

```sql
-- BEFORE (line 350):
v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000);

-- AFTER:
v_fee_rate_bps := v_entity.fee_rate_applied_bps;  -- Read from locked entity

IF v_fee_rate_bps IS NULL THEN
    RETURN jsonb_build_object(
        'ok', false,
        'error', jsonb_build_object(
            'code', 'ERR_FEE_NOT_LOCKED',
            'message', 'Fee rate was not locked at escrow. Cannot release.'
        )
    );
END IF;
```

### Fix 2: Lock fee in `escrow_hold` handler

After line 256 (entity status update), add:

```sql
-- Read current fee rate from system_config
SELECT (value->>'fee_rate_bps')::INTEGER INTO v_fee_rate_bps
FROM public.system_config WHERE key = 'platform_fee';

IF v_fee_rate_bps IS NULL THEN
    v_fee_rate_bps := 1000;  -- Safe default only as last resort
END IF;

-- Lock the fee rate to the entity
IF p_related_entity_type = 'booking' THEN
    UPDATE public.bookings SET fee_rate_applied_bps = v_fee_rate_bps WHERE id = p_related_entity_id;
ELSIF p_related_entity_type = 'direct_offer' THEN
    UPDATE public.direct_offers SET fee_rate_applied_bps = v_fee_rate_bps WHERE id = p_related_entity_id;
ELSIF p_related_entity_type = 'task_request' THEN
    UPDATE public.task_requests SET fee_rate_applied_bps = v_fee_rate_bps WHERE id = p_related_entity_id;
END IF;
```
