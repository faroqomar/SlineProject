# Threat Model: Dynamic Platform Fee System

**Version**: 1.0  
**Date**: 2026-03-06  
**Auditor**: @ThreatModeler  
**Scope**: Fee locking mechanism, platform_settings access, RPC security

---

## 1. Asset Inventory

| Asset | Value | Exposure |
|-------|-------|----------|
| Platform fee revenue | Financial | RPC parameter injection |
| platform_settings.fee_rate_default_bps | Financial | Unauthorized modification |
| bookings.fee_rate_applied_bps | Audit/Contract | Unauthorized modification |
| Ledger integrity | Financial/Compliance | Fee calculation errors |

---

## 2. Threat Actors

| Actor | Motivation | Capability |
|-------|------------|------------|
| Malicious Client | Pay 0% fees | Can craft RPC calls with p_meta |
| Compromised Admin | Set 100% fees | Has admin credentials |
| Insider Developer | Bypass controls | Has database access |
| External Attacker | Revenue theft | Limited (RLS/Auth barriers) |

---

## 3. Attack Scenarios

### 3.1 Client Fee Rate Spoofing (CRITICAL)

**Attack**: Client sets `p_meta.fee_rate_bps = 0` to avoid platform fees

**Current System** (Vulnerable):
```sql
v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000);
-- Client controls p_meta, can set any fee rate!
```

**Mitigation** (New System):
```sql
-- For client actors: Ignore p_meta, use locked rate
IF v_actor_user_id NOT IN (SELECT user_id FROM admin_users) THEN
    v_fee_rate_bps := v_entity.fee_rate_applied_bps;
ELSE
    -- Admin can override
    v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, v_entity.fee_rate_applied_bps);
END IF;
```

**Test**:
```dart
test('client cannot spoof fee rate', () {
  final params = createSpoofAttemptParams(
    spoofedFeeRateBps: 0,
    // ...
  );
  // Expect: RPC uses global rate, ignores spoofed 0%
});
```

**Impact**: HIGH (Revenue loss)  
**Likelihood**: MED (Requires client knowledge of p_meta)  
**Risk**: CRITICAL

---

### 3.2 Fee Lock Bypass (CRITICAL)

**Attack**: Client directly updates `bookings.fee_rate_applied_bps` after escrow

**Mitigation**:
```sql
-- Immutability trigger
IF OLD.fee_rate_applied_bps IS NOT NULL 
   AND NEW.fee_rate_applied_bps IS DISTINCT FROM OLD.fee_rate_applied_bps THEN
    RAISE EXCEPTION 'fee_rate_applied_bps is immutable';
END IF;
```

**Test**:
```sql
-- Attempt to change locked fee (should fail)
UPDATE bookings 
SET fee_rate_applied_bps = 0 
WHERE id = 'locked-booking-id';
-- Expected: ERROR: fee_rate_applied_bps is immutable
```

**Impact**: HIGH (Revenue loss, audit failure)  
**Likelihood**: LOW (Requires UPDATE permissions)  
**Risk**: HIGH

---

### 3.3 platform_settings Modification (HIGH)

**Attack**: Unauthorized user changes `fee_rate_default_bps` to 100%

**Mitigation**:
```sql
-- RLS Policy: Admin only
CREATE POLICY "platform_settings_write_admin"
ON platform_settings FOR ALL
TO authenticated 
USING (auth.uid() IN (SELECT user_id FROM admin_users));
```

**Defense in Depth**:
- RLS prevents anon/authenticated access
- Max fee rate cap (30%)
- Audit logging

**Test**:
```sql
-- As regular user (should fail)
UPDATE platform_settings 
SET value = '{"value": 10000}' 
WHERE key = 'fee_rate_default_bps';
-- Expected: 0 rows affected (RLS)
```

**Impact**: HIGH (All future bookings affected)  
**Likelihood**: LOW (Requires admin access bypass)  
**Risk**: HIGH

---

### 3.4 Fee Calculation Manipulation (MEDIUM)

**Attack**: Exploit rounding to reduce fees by 1 unit per transaction

**Scenario**:
- Price: 99 IQD
- Fee: 12%
- Expected: floor(99 * 0.12) = 11 IQD
- Attacker tries to manipulate to 10 IQD

**Mitigation**:
- Integer math only (no floating point)
- Consistent FLOOR formula
- Constraint: `CHECK (fee_amount = (price * fee_rate_applied_bps) / 10000)`

**Test**:
```dart
test('rounding is deterministic', () {
  expect(calculateFee(99, 1200), equals(11)); // Not 12
  expect(calculateFee(100, 1200), equals(12));
});
```

**Impact**: LOW (1 unit per transaction)  
**Likelihood**: LOW (No exploit path)  
**Risk**: LOW

---

### 3.5 Admin Privilege Abuse (HIGH)

**Attack**: Admin sets fee to 100% on specific booking via override

**Mitigation**:
- Admin override logged in admin_logs
- Admin override only works on release (not escrow lock)
- Max fee cap still applies to admin override

**Test**:
```sql
-- Verify admin action is logged
SELECT * FROM admin_logs 
WHERE table_name = 'bookings' 
AND action = 'ADMIN_FEE_OVERRIDE';
```

**Impact**: HIGH (Specific booking affected)  
**Likelihood**: LOW (Requires admin access)  
**Risk**: MEDIUM (Auditable)

---

### 3.6 Race Condition: Fee Change During Escrow (MEDIUM)

**Attack**: Admin changes fee rate while multiple escrows in progress

**Scenario**:
1. Client A starts escrow (global rate 10%)
2. Admin changes rate to 15%
3. Client B starts escrow
4. Client A's booking should lock at 10%
5. Client B's booking should lock at 15%

**Mitigation**: Design is correct - each escrow locks rate at call time

**Test**:
```dart
test('concurrent escrows lock different rates', () async {
  // Start two escrows with rate change between them
  // Verify each locked its respective rate
});
```

**Impact**: LOW (By design)  
**Likelihood**: N/A  
**Risk**: LOW

---

### 3.7 Feature Flag Bypass (MEDIUM)

**Attack**: Attacker attempts to use new fee logic before official enablement

**Mitigation**:
- RPC checks `fee_locking_enabled` flag
- Flag default is `false`
- Backfill required before enablement

**Test**:
```sql
-- Verify feature flag blocks new logic
SELECT value->>'value' FROM platform_settings WHERE key = 'fee_locking_enabled';
-- Expected: 'false' initially
```

**Impact**: MED (Unpredictable behavior)  
**Likelihood**: LOW  
**Risk**: LOW

---

## 4. Security Test Plan

### 4.1 Automated Security Tests

```dart
// test/security/fee_locking_security_test.dart
group('Security: Fee Rate Spoofing', () {
  test('client with p_meta.fee_rate_bps=0 is ignored', () async {
    // Attempt spoof
    // Verify locked rate is global rate, not 0
  });

  test('non-admin cannot change platform_settings', () async {
    // As regular user, attempt UPDATE
    // Verify RLS blocks (0 rows affected)
  });

  test('immutability trigger blocks fee_rate change', () async {
    // Attempt direct UPDATE of locked fee_rate_applied_bps
    // Verify exception raised
  });

  test('admin override is logged', () async {
    // Admin overrides fee on release
    // Verify admin_logs entry created
  });
});
```

### 4.2 Manual Security Audit

| Check | Method | Expected Result |
|-------|--------|-----------------|
| RLS policy effectiveness | SQL SELECT as anon | 0 rows returned |
| Trigger enforcement | SQL UPDATE locked fee | Exception raised |
| Max fee cap | Set fee_rate > 30% | Constraint violation |
| Audit trail | Change platform_settings | Entry in admin_logs |
| RPC parameter handling | Call with spoofed p_meta | Rate ignored |

---

## 5. Mitigation Summary

| Threat | Mitigation | Status |
|--------|------------|--------|
| Client spoofing | Ignore p_meta for non-admin | Implemented in contract |
| Lock bypass | Immutability trigger | Specified in contract |
| Settings tampering | RLS + admin_users | Specified in contract |
| Calculation error | Integer math + FLOOR | Specified in contract |
| Admin abuse | Audit logging | Specified in contract |
| Race conditions | Design (per-escrow lock) | By design |
| Feature bypass | Feature flag check | Specified in contract |

---

## 6. Residual Risks (After Mitigations)

1. **Compromised admin account**: Can set high fees, but logged
2. **Database superuser**: Can bypass RLS/triggers, but requires infrastructure access
3. **Application bug**: Fee calculation edge cases, mitigated by tests
4. **Feature flag mismanagement**: Premature enablement, mitigated by process

---

## 7. Security Checklist

- [x] Threat scenarios documented
- [x] Mitigations specified
- [x] Security tests defined
- [x] Audit logging required
- [x] Access controls specified
- [x] Input validation rules defined
- [ ] Security tests implemented (Phase 4)
- [ ] Security audit completed (Phase 4)

---

**Approved By**: @ThreatModeler  
**Reviewed By**: @CodeGuard, @Sentinel, @Supabase_Ops
