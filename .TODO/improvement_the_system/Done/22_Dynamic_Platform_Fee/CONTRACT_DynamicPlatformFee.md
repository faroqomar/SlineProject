# Contract: Dynamic Platform Fee System

**Version**: 1.0  
**Date**: 2026-03-06  
**Status**: Active (Phase 0.2)

This contract defines the behavior changes, data structures, and interfaces for the Dynamic Platform Fee implementation.

---

## 1. RPC Behavior Contract

### 1.1 process_payment_event_ledger - escrow_hold

**Current Behavior**:
- Does NOT write fee rate to entity
- Does NOT read from platform_settings

**New Behavior**:
```yaml
preconditions:
  - Feature flag 'fee_locking_enabled' must be 'true'
  - Entity (booking/direct_offer/task_request) must exist
  - Entity payment_status must be 'unpaid'

execution:
  1. Read fee_rate_default_bps from platform_settings
  2. Validate against max_fee_rate_bps
  3. Write fee_rate_applied_bps to entity
  4. Continue with existing escrow logic

postconditions:
  - entity.fee_rate_applied_bps = global fee rate at call time
  - entity.payment_status = 'held'
  - journal_entry records fee_rate_applied_bps in meta

error_codes:
  - ERR_FEE_RATE_NOT_AVAILABLE: platform_settings missing fee_rate_default_bps
  - ERR_FEE_RATE_EXCEEDS_MAX: calculated fee exceeds max_fee_rate_bps
```

### 1.2 process_payment_event_ledger - release_with_fee

**Current Behavior**:
- Reads fee_rate_bps from p_meta parameter (client injectable)
- Falls back to hardcoded 1000 bps

**New Behavior**:
```yaml
preconditions:
  - Feature flag 'fee_locking_enabled' must be 'true'
  - Entity fee_rate_applied_bps must NOT be NULL
  - Entity payment_status must be 'held'

execution:
  1. Read fee_rate_applied_bps from entity (ignore p_meta for clients)
  2. If actor is admin AND p_meta contains 'fee_rate_bps', allow override
  3. Calculate: fee_amount = FLOOR(price * fee_rate_applied_bps / 10000)
  4. Calculate: net_amount = price - fee_amount
  5. Write fee_amount and net_amount to entity
  6. Execute ledger lines: platform_escrow -> freelancer_available + platform_revenue

postconditions:
  - entity.fee_amount = calculated fee
  - entity.net_amount = calculated net
  - entity.payment_status = 'released'
  - entity.fee_rate_applied_bps unchanged (immutability enforced by trigger)

error_codes:
  - ERR_FEE_RATE_NOT_LOCKED: entity.fee_rate_applied_bps is NULL
  - ERR_FEE_CALCULATION_MISMATCH: fee + net != gross (invariant violation)
  - ERR_IMMUTABILITY_VIOLATION: trigger prevented fee_rate change (should never happen)
```

### 1.3 Security Rules for p_meta

```yaml
client_actor:
  p_meta.fee_rate_bps: IGNORED (always use locked rate)
  p_meta.actor_role: IGNORED

admin_actor:
  p_meta.fee_rate_bps: HONORED (override locked rate)
  p_meta.actor_role: must be 'admin'

service_role_actor:
  p_meta.fee_rate_bps: HONORED (for edge cases/support)
```

---

## 2. Data Model Contract

### 2.1 platform_settings Table

```sql
CREATE TABLE public.platform_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,        -- { "value": <integer> }
    updated_at TIMESTAMPTZ DEFAULT now(),
    updated_by UUID REFERENCES auth.users(id)
);

-- Required rows
INSERT INTO platform_settings (key, value) VALUES
('fee_rate_default_bps', '{"value": 1000}'),   -- 10% default
('max_fee_rate_bps', '{"value": 3000}'),         -- 30% max
('fee_locking_enabled', '{"value": false}');     -- Feature flag (start false)
```

**Access Control**:
- SELECT: authenticated (read-only)
- INSERT/UPDATE/DELETE: admin only (via admin_users table)

### 2.2 bookings Table (New Columns)

```sql
ALTER TABLE public.bookings
ADD COLUMN fee_rate_applied_bps INTEGER,  -- Locked fee rate (basis points)
ADD COLUMN fee_amount BIGINT,              -- Calculated platform fee (IQD)
ADD COLUMN net_amount BIGINT;              -- Net to freelancer (IQD)

-- Constraints
CHECK (fee_rate_applied_bps >= 0 AND fee_rate_applied_bps <= 3000)
CHECK (fee_amount + net_amount = price)  -- When both are not NULL
```

### 2.3 direct_offers Table (New Columns)

```sql
ALTER TABLE public.direct_offers
ADD COLUMN fee_rate_applied_bps INTEGER,
ADD COLUMN fee_amount BIGINT,
ADD COLUMN net_amount BIGINT;

-- Same constraints as bookings
```

### 2.4 task_requests Table (New Columns)

```sql
ALTER TABLE public.task_requests
ADD COLUMN fee_rate_applied_bps INTEGER,
ADD COLUMN fee_amount BIGINT,
ADD COLUMN net_amount BIGINT;

-- Same constraints as bookings
```

---

## 3. Calculation Contract

### 3.1 Fee Calculation Formula

```
fee_amount = FLOOR(price * fee_rate_applied_bps / 10000)
net_amount = price - fee_amount
```

**Precision Rules**:
- Use integer division (FLOOR), not rounding
- Basis points (100 = 1%, 1000 = 10%)
- All amounts in smallest currency unit (IQD)

**Edge Cases**:
| Price | Fee Rate | Fee | Net | Notes |
|-------|----------|-----|-----|-------|
| 100 | 12% | 12 | 88 | Standard |
| 99 | 12% | 11 | 88 | Rounds down |
| 10 | 12% | 1 | 9 | Small amount |
| 1 | 12% | 0 | 1 | Zero fee OK |
| 100000 | 12% | 12000 | 88000 | Large amount |

### 3.2 Invariants

1. **Fee Lock Immutability**:
   - Once `fee_rate_applied_bps` is set, it can never change
   - Enforced by trigger `trg_protect_fee_rate_applied`

2. **Gross Balance**:
   - `fee_amount + net_amount = price` (when both columns are populated)

3. **Ledger Balance**:
   - Sum of all ledger_lines for a journal_entry = 0

4. **Global Rate Read**:
   - Only `escrow_hold` reads from `platform_settings`
   - `release_with_fee` reads from entity only

---

## 4. Trigger Contract

### 4.1 Immutability Trigger

```sql
CREATE OR REPLACE FUNCTION fn_protect_fee_rate_applied()
RETURNS TRIGGER AS $$
BEGIN
    -- Allow NULL -> value (initial lock)
    -- Block value -> different value (attempted modification)
    IF OLD.fee_rate_applied_bps IS NOT NULL 
       AND NEW.fee_rate_applied_bps IS DISTINCT FROM OLD.fee_rate_applied_bps THEN
        RAISE EXCEPTION 'ERR_IMMUTABILITY_VIOLATION: fee_rate_applied_bps is immutable once set';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all three tables
CREATE TRIGGER trg_protect_fee_rate_applied
BEFORE UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION fn_protect_fee_rate_applied();
```

### 4.2 Audit Trigger

```sql
CREATE OR REPLACE FUNCTION fn_log_platform_settings_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO admin_logs (action, table_name, record_id, old_data, new_data, performed_by)
    VALUES (
        'UPDATE', 
        'platform_settings', 
        NEW.key, 
        jsonb_build_object('value', OLD.value), 
        jsonb_build_object('value', NEW.value), 
        NEW.updated_by
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_platform_settings_change
AFTER UPDATE ON public.platform_settings
FOR EACH ROW EXECUTE FUNCTION fn_log_platform_settings_change();
```

---

## 5. RLS Contract

### 5.1 platform_settings Policies

```sql
-- Enable RLS
ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;

-- Read policy (authenticated)
CREATE POLICY "platform_settings_read"
ON platform_settings FOR SELECT
TO authenticated USING (true);

-- Write policy (admin only)
CREATE POLICY "platform_settings_write_admin"
ON platform_settings FOR ALL
TO authenticated
USING (auth.uid() IN (SELECT user_id FROM admin_users))
WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

-- No anon access
CREATE POLICY "platform_settings_no_anon"
ON platform_settings FOR ALL
TO anon USING (false);
```

### 5.2 Entity Table Policies

Existing RLS on `bookings`, `direct_offers`, `task_requests` remains unchanged.
New columns inherit existing row-level policies.

---

## 6. Migration Contract

### 6.1 Phase 1: Introduce (Non-Breaking)

1. Create `platform_settings` table
2. Add nullable columns to `bookings`, `direct_offers`, `task_requests`
3. Add RLS policies
4. Add triggers (disabled initially)
5. Seed `platform_settings` with `fee_locking_enabled = false`

**Rollback**:
```sql
DROP TABLE IF EXISTS platform_settings;
ALTER TABLE bookings DROP COLUMN IF EXISTS fee_rate_applied_bps;
ALTER TABLE bookings DROP COLUMN IF EXISTS fee_amount;
ALTER TABLE bookings DROP COLUMN IF EXISTS net_amount;
-- Repeat for direct_offers, task_requests
```

### 6.2 Phase 2: Backfill

1. Update all held/released entities with `fee_rate_applied_bps = 1000`
2. Calculate and populate `fee_amount` and `net_amount` for completed entities

**Verification**:
```sql
SELECT COUNT(*) FROM bookings 
WHERE payment_status IN ('held', 'released') 
AND fee_rate_applied_bps IS NULL;
-- Must return 0
```

### 6.3 Phase 3: Enable

1. Update `platform_settings.fee_locking_enabled = true`
2. Enable immutability triggers
3. Deploy patched RPC

---

## 7. Testing Contract

### 7.1 Unit Tests

- Fee calculation edge cases (6 scenarios)
- Trigger immutability enforcement
- RLS policy enforcement

### 7.2 Integration Tests

1. **Escrow Lock Test**:
   - Set global fee to 12%
   - Call escrow_hold
   - Verify entity.fee_rate_applied_bps = 1200

2. **Fee Change Test**:
   - Complete escrow with fee at 12%
   - Change global fee to 15%
   - Verify entity.fee_rate_applied_bps still 1200

3. **Release Test**:
   - Release booking with locked rate 12%
   - Verify fee_amount calculated at 12%
   - Verify net_amount = price - fee_amount

4. **Spoof Test**:
   - Call escrow_hold with p_meta.fee_rate_bps = 0
   - Verify locked rate uses global setting (not 0)

5. **Admin Override Test**:
   - Call release_with_fee as admin with p_meta.fee_rate_bps = 500
   - Verify fee calculated at 5% (admin override works)

---

## 8. Error Code Reference

| Code | Description | When Raised |
|------|-------------|-------------|
| ERR_FEE_RATE_NOT_LOCKED | Fee rate not locked for entity | release_with_fee called on entity without fee_rate_applied_bps |
| ERR_FEE_RATE_NOT_AVAILABLE | Global fee rate not configured | platform_settings missing fee_rate_default_bps |
| ERR_FEE_RATE_EXCEEDS_MAX | Fee rate exceeds maximum | Calculated fee > max_fee_rate_bps |
| ERR_FEE_CALCULATION_MISMATCH | Fee calculation error | fee + net != gross (invariant violation) |
| ERR_IMMUTABILITY_VIOLATION | Fee rate cannot change | Trigger prevented fee_rate_applied_bps update |

---

## 9. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-06 | Initial contract for Dynamic Platform Fee implementation |

---

**Approved By**: @APIContract  
**Reviewed By**: @Architect, @Supabase_Ops, @Sentinel
