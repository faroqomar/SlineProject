# 📋 CRITIQUE & CORRECTED PLAN: Dynamic Platform Fee Implementation

**Auditor**: @PlanCritic  
**Original Plan**: `PLAN_DynamicPlatformFee_Implementation_2026-03-06.md`  
**Date**: 2026-03-06  
**Status**: CRITIQUE + CORRECTED EXECUTION PLAN

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions Made
1. **Migration timing**: Zero-downtime acceptable (Postgres `ADD COLUMN` is non-blocking)
2. **Backfill volume**: < 100k bookings (backfill completes in seconds)
3. **QiCard integration**: Webhook handlers won't conflict with fee changes
4. **Admin identity**: Admin users identified by `auth.users` role claim or specific user IDs
5. **Currency**: IQD only (no multi-currency complexity)

### Decision Needed (BLOCKING)

| Decision | Options | Recommended | Impact on Plan |
|----------|---------|-------------|----------------|
| **Fee rate storage format** | A) Basis points INTEGER (1000 = 10%)<br>B) Decimal NUMERIC (0.10 = 10%) | **A) Basis points** | Affects column type, calculations, rounding logic |
| **Max fee cap** | A) Hard DB constraint (e.g., 30% max)<br>B) App-level validation only<br>C) No cap | **A) DB constraint** | Adds safety but requires constraint migration |
| **Admin detection in RPC** | A) Check `auth.users.raw_user_meta->>'role' = 'admin'`<br>B) Check against `admin_users` table<br>C) Service role only | **B) `admin_users` table** | More secure, explicit admin list |
| **Zero-fee handling** | A) Allow 0% fee (disabled platform)<br>B) Minimum 1% fee enforced | **A) Allow 0%** | For promotions/testing; requires test coverage |

**⚠️ BLOCKING**: Cannot proceed past Phase 0.3 without decision on Admin detection method.

---

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
**Status**: ❌ **FAIL**
- **Reason 1**: No test harness for RPC/ledger testing (requires Supabase test container)
- **Reason 2**: No fixture system for deterministic booking states
- **Reason 3**: No existing tests for `process_payment_event_ledger` to use as regression baseline
- **Fix Required**:
  - Create `test/integration/ledger_rpc_test.dart` harness
  - Create `test/fixtures/booking_fixtures.dart` with standardized states
  - Add `test/helpers/ledger_test_helper.dart` for RPC invocation

### Gate 1: Data/Contracts Gate
**Status**: ❌ **FAIL**
- **Reason 1**: No contract file exists defining RPC behavior changes
- **Reason 2**: Column naming inconsistent in plan (`fee_rate_applied` vs `fee_rate_applied_bps`)
- **Reason 3**: Missing type precision specification (NUMERIC vs BIGINT for amounts)
- **Fix Required**:
  - Create `.TODO/CONTRACT_DynamicPlatformFee.md` with exact field types
  - Standardize on `fee_rate_applied_bps INTEGER` (basis points)
  - Standardize on `fee_amount BIGINT` (smallest currency unit)
  - Standardize on `net_amount BIGINT` (smallest currency unit)

### Gate 2: Security Gate
**Status**: ❌ **FAIL**
- **Reason 1**: No explicit `admin_users` table reference for admin detection
- **Reason 2**: Immutability trigger spec insufficient (doesn't cover NULL→value transition)
- **Reason 3**: Missing audit logging for fee rate changes
- **Fix Required**:
  - Verify `admin_users` table exists or create it
  - Update trigger spec: allow NULL→value, block value→different_value
  - Add `admin_logs` entries for `platform_settings` changes

### Gate 3: Backend/API Gate
**Status**: ❌ **FAIL**
- **Reason 1**: RPC patch plan underspecified (exact line changes not documented)
- **Reason 2**: No idempotency key format specified for fee lock operation
- **Reason 3**: No error response contract for "fee rate not locked" scenario
- **Fix Required**:
  - Document exact RPC changes with before/after SQL
  - Define idempotency key: `escrow_hold:{booking_id}:{timestamp}`
  - Define error code: `ERR_FEE_RATE_NOT_LOCKED`

### Gate 4: UI/Integration Gate
**Status**: ✅ **PASS** (Minimal impact)
- **Reason**: UI changes are display-only, no new flows

### Gate 5: Release/QA Gate
**Status**: ❌ **FAIL**
- **Reason 1**: No feature flag mechanism for gradual rollout
- **Reason 2**: No staging environment test plan
- **Reason 3**: No rollback verification steps
- **Fix Required**:
  - Add feature flag to RPC: check `platform_settings->>'fee_locking_enabled'`
  - Document staging test sequence
  - Add rollback verification queries

---

## C) Critical Gaps (Must-Fix)

### Gap 1: No Deterministic Test Setup
- **Why it will break**: Tests will fail intermittently due to timing, missing data, or environment differences
- **Fix**: 
  1. Create `test/fixtures/ledger_test_scenario.dart` with:
     - `createTestBooking({required String paymentStatus, int? lockedFeeBps})`
     - `createTestPlatformSettings({required int feeRateBps})`
  2. Create `test/helpers/ledger_rpc_invoker.dart` with typed wrappers
- **Owner**: Backend + QA
- **Acceptance**: `dart test test/integration/fee_locking_test.dart` passes deterministically

### Gap 2: No Fee Calculation Precision Specification
- **Why it will break**: IQD rounding disputes; FLOOR vs ROUND vs CEILING affects revenue
- **Fix**:
  1. Document: `fee_amount = FLOOR(gross_amount * fee_rate_applied_bps / 10000)`
  2. Add test cases: 99 IQD @ 12% → 11 IQD (not 12)
  3. Add constraint: `CHECK (fee_amount <= gross_amount * fee_rate_applied_bps / 10000)`
- **Owner**: Backend
- **Acceptance**: Unit tests verify rounding for edge cases

### Gap 3: No Concurrent Escrow Race Condition Handling
- **Why it will break**: Admin changes fee during active escrow; multiple escrows lock different rates
- **Fix**:
  1. Document behavior: "Each escrow locks rate at moment of RPC call"
  2. Add test: Two simultaneous escrows with fee change between them
  3. Ensure no transaction isolation issues
- **Owner**: Backend
- **Acceptance**: Concurrent test passes with different locked rates

### Gap 4: Missing Direct Offer and Task Request Consistency
- **Why it will break**: System works for bookings but fails for direct_offers or task_requests
- **Fix**:
  1. Verify `direct_offers` has same columns as `bookings`
  2. Verify `task_requests` has same columns
  3. Update RPC to handle all three entity types uniformly
- **Owner**: Backend
- **Acceptance**: Test all three entity types through full escrow→release cycle

### Gap 5: No Backfill Verification Query
- **Why it will break**: Some bookings miss backfill, causing NULL fee errors on release
- **Fix**:
  1. Add verification: `SELECT COUNT(*) FROM bookings WHERE fee_rate_applied_bps IS NULL AND payment_status IN ('held', 'released')`
  2. Result must be 0 before proceeding to Phase 2
- **Owner**: Backend
- **Acceptance**: Verification query returns 0

### Gap 6: No Rollback Testing Steps
- **Why it will break**: Rollback plan exists but never tested; fails in emergency
- **Fix**:
  1. Add task: "Test rollback on staging database"
  2. Document exact verification steps post-rollback
- **Owner**: Backend + QA
- **Acceptance**: Rollback tested on copy of production data

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | Enforcement | Verification |
|-----------|-------------|--------------|
| **Fee lock immutability** | Trigger `trg_protect_fee_rate_applied` | `UPDATE bookings SET fee_rate_applied_bps = 2000 WHERE fee_rate_applied_bps = 1000` → expect exception |
| **Fee rate source of truth** | RPC reads from `platform_settings` | `SELECT current_setting('fee_rate_default_bps')` in RPC → returns platform_settings value |
| **Client cannot spoof fee** | RPC ignores `p_meta->>'fee_rate_bps'` for non-admin | Test: client call with `p_meta = '{"fee_rate_bps": 0}'` → uses locked rate |
| **Gross = Fee + Net** | Constraint: `CHECK (fee_amount + net_amount = gross_amount)` | All bookings satisfy equation |
| **Ledger balance** | Double-entry: sum of lines = 0 | `SELECT SUM(amount) FROM ledger_lines WHERE journal_entry_id = X` → always 0 |
| **Audit trail** | `admin_logs` entry per settings change | `SELECT COUNT(*) FROM admin_logs WHERE table_name = 'platform_settings'` > 0 after change |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast Radius | Early Signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Backfill misses rows | Migration | Med | High | Data corruption | NULL fee_rate on release attempt | Verification query + count match | Emergency patch: allow fallback to global rate with logging |
| RPC performance regression | RPC patch | Low | Med | Slow payments | P95 latency increase in logs | Keep queries single-row | Add index if needed |
| Admin detection fails | Security | Low | High | Security breach | Unexpected fee rates in journal | Strict role check + audit log | Emergency: disable fee locking via flag |
| Client app doesn't show new fields | UI | Med | Low | Confused users | Support tickets about "missing fee info" | Feature detection in app | Server-side still works; add UI in patch release |
| Concurrent escrow with rate change | RPC | Med | Med | Different rates for similar bookings | Inconsistent fee amounts | Document behavior clearly | Accept as designed; rates lock at call time |
| Old app version breaks | Compatibility | Low | High | App crashes | Crashlytics errors | Backward compatible schema | App version gate if needed |
| QiCard webhook conflicts | Integration | Low | High | Payment failures | Webhook errors in edge function | Test with QiCard sandbox | Fallback to manual reconciliation |
| Trigger prevents legitimate updates | DB | Low | High | Cannot modify bookings | Update failures | Test trigger with all scenarios | Drop trigger emergency fix |

---

## F) Pre-Mortem (How This Fails in Real Life)

1. **This fails when** the backfill query misses bookings with non-standard `payment_status` values, causing NULL fee errors when clients try to release.
   - *Maps to*: Gap 5

2. **This fails when** a malicious client discovers the admin override path in the RPC and spoofs admin role to set 0% fees.
   - *Maps to*: Gate 2 failure

3. **This fails when** the `direct_offers` table schema differs from `bookings`, causing the RPC to fail on direct offer payments.
   - *Maps to*: Gap 4

4. **This fails when** an admin sets fee to 50% and the app UI doesn't show the fee breakdown, causing user confusion and support tickets.
   - *Maps to*: Risk "Client app doesn't show new fields"

5. **This fails when** the migration runs during a QiCard webhook processing, creating a race condition that double-charges or loses a payment.
   - *Maps to*: Risk "QiCard webhook conflicts"

6. **This fails when** the immutability trigger is too aggressive and prevents legitimate booking updates (like status changes).
   - *Maps to*: Risk "Trigger prevents legitimate updates"

7. **This fails when** the rollback is needed but the rollback SQL wasn't tested and drops the wrong columns.
   - *Maps to*: Gap 6

8. **This fails when** fee calculation rounding causes `fee + net != gross` by 1 IQD, violating ledger invariants.
   - *Maps to*: Gap 2

9. **This fails when** two clients escrow simultaneously with a fee change between them, and the business team complains about "unfair" different rates.
   - *Maps to*: Risk "Concurrent escrow with rate change"

10. **This fails when** the test environment doesn't have `pg_cron` enabled, causing the migration to fail on trigger creation.
    - *Maps to*: Gap 1

---

## G) Plan Fixes (Concrete Additions / Expansions)

### Fix 1: Test Infrastructure (Must Complete Before Phase 1)
**Goal**: Deterministic test harness for ledger RPC  
**Why**: Without this, we cannot verify correctness or catch regressions  
**How**:
```dart
// test/fixtures/booking_fixtures.dart
class BookingFixtures {
  static Future<Booking> createTestBooking({
    required String paymentStatus,
    int? feeRateAppliedBps,
    int price = 100000,
  }) async { ... }
}

// test/helpers/ledger_rpc_invoker.dart
class LedgerRpcInvoker {
  static Future<LedgerResult> escrowHold({
    required String bookingId,
    required int amount,
    String? feeRateBpsInMeta, // For spoofing tests
  }) async { ... }
}
```
**Output**: `test/fixtures/booking_fixtures.dart`, `test/helpers/ledger_rpc_invoker.dart`  
**Stop condition**: `dart test test/integration/fee_locking_test.dart` passes 5 consecutive runs

### Fix 2: Contract File (Must Complete Before Phase 1)
**Goal**: Explicit contract for RPC behavior changes  
**Why**: Prevents ambiguity in implementation  
**How**: Create `.TODO/CONTRACT_DynamicPlatformFee.md`:
```yaml
rpc: process_payment_event_ledger
event_types_affected:
  - escrow_hold
  - release_with_fee
changes:
  escrow_hold:
    before: Does NOT write fee rate to entity
    after: READS platform_settings.fee_rate_default_bps, WRITES to entity.fee_rate_applied_bps
  release_with_fee:
    before: Reads fee from p_meta or uses 1000 bps default
    after: READS entity.fee_rate_applied_bps (ignores p_meta for clients)
error_codes_added:
  - ERR_FEE_RATE_NOT_LOCKED
  - ERR_FEE_CALCULATION_MISMATCH
```
**Output**: `.TODO/CONTRACT_DynamicPlatformFee.md`  
**Stop condition**: Contract reviewed and signed off by @Architect

### Fix 3: Precision Specification (Must Complete Before Phase 1.3)
**Goal**: Exact fee calculation formula  
**Why**: Prevents rounding disputes and invariant violations  
**How**:
```sql
-- Formula documentation
-- fee_amount = FLOOR(gross_amount * fee_rate_applied_bps / 10000)
-- net_amount = gross_amount - fee_amount
-- Constraint: fee_amount + net_amount = gross_amount

-- Test cases
SELECT 
  FLOOR(100 * 1200 / 10000) = 12,    -- 100 IQD @ 12% = 12 IQD
  FLOOR(99 * 1200 / 10000) = 11,    -- 99 IQD @ 12% = 11 IQD (not 12)
  FLOOR(1000 * 1000 / 10000) = 100; -- 1000 @ 10% = 100
```
**Output**: Formula in `SUPABASE_SETUP.md`, test cases in `test/unit/fee_calculation_test.dart`  
**Stop condition**: All edge case tests pass

### Fix 4: Admin Detection Decision (BLOCKING)
**Goal**: Secure admin identification method  
**Why**: Prevents privilege escalation  
**How**: Verify or create `admin_users` table:
```sql
-- Verify exists
SELECT EXISTS (
  SELECT 1 FROM information_schema.tables 
  WHERE table_name = 'admin_users'
);

-- If not exists, create
CREATE TABLE public.admin_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  role TEXT NOT NULL CHECK (role IN ('super', 'finance', 'support')),
  created_at TIMESTAMPTZ DEFAULT now()
);
```
**Output**: Admin detection method documented  
**Stop condition**: Query `SELECT * FROM admin_users WHERE user_id = auth.uid()` works

### Fix 5: Feature Flag (Must Add to Phase 1.3)
**Goal**: Gradual rollout capability  
**Why**: Allows emergency disable without rollback  
**How**:
```sql
-- Add to platform_settings
INSERT INTO platform_settings (key, value) 
VALUES ('fee_locking_enabled', '{"value": true}');

-- RPC checks before using new logic
IF (SELECT value->>'value' FROM platform_settings WHERE key = 'fee_locking_enabled') = 'true' THEN
  -- New logic
ELSE
  -- Legacy logic (hardcoded 10%)
END IF;
```
**Output**: Feature flag in `platform_settings`  
**Stop condition**: Can toggle fee locking on/off via SQL

### Fix 6: Backfill Verification (Must Add to Phase 1.4)
**Goal**: Confirm all affected rows updated  
**Why**: Prevents NULL fee errors  
**How**:
```sql
-- Verification queries
SELECT 'bookings' as table_name, COUNT(*) as null_count
FROM bookings 
WHERE fee_rate_applied_bps IS NULL 
  AND payment_status IN ('held', 'released')
UNION ALL
SELECT 'direct_offers', COUNT(*)
FROM direct_offers
WHERE fee_rate_applied_bps IS NULL 
  AND payment_status IN ('held', 'released')
UNION ALL
SELECT 'task_requests', COUNT(*)
FROM task_requests  
WHERE fee_rate_applied_bps IS NULL 
  AND payment_status IN ('held', 'released');
-- Result must be 0 for all tables
```
**Output**: Verification query, run result  
**Stop condition**: All counts = 0

### Fix 7: Rollback Testing (Must Add to Phase 4)
**Goal**: Verified rollback capability  
**Why**: Emergency confidence  
**How**:
1. Apply migration to staging copy
2. Run smoke tests
3. Apply rollback SQL
4. Verify app still works with old code
5. Document any data loss (should be none)
**Output**: Rollback test report  
**Stop condition**: Rollback completes in < 5 minutes, no data loss

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Preconditions & Gates (COMPLETE BEFORE ANY CODE)

#### 0.1 Test Infrastructure Setup
**Goal**: Deterministic testing capability  
**Why**: Without tests, we cannot verify correctness  
**How**:
1. Create `test/fixtures/booking_fixtures.dart`
2. Create `test/helpers/ledger_rpc_invoker.dart`
3. Create `test/integration/fee_locking_test.dart` with 3 test cases:
   - Escrow locks fee rate
   - Release uses locked rate (not global)
   - Client spoof attempt fails
**Result**: Test harness ready, all 3 tests initially fail (expected)

#### 0.2 Contract & Decision Finalization
**Goal**: Unambiguous implementation spec  
**Why**: Prevents misinterpretation during coding  
**How**:
1. Create `.TODO/CONTRACT_DynamicPlatformFee.md`
2. **DECISION REQUIRED**: Admin detection method
3. Document exact column types: `fee_rate_applied_bps INTEGER`, `fee_amount BIGINT`, `net_amount BIGINT`
4. Document exact formula: `FLOOR(gross * bps / 10000)`
**Result**: Contract file approved

#### 0.3 Threat Model
**Goal**: Security requirements defined  
**Why**: Money flows are high-risk  
**How**: @ThreatModeler creates `.TODO/THREAT_MODEL_DynamicPlatformFee.md`:
- Spoofing scenarios
- Privilege escalation paths
- Audit requirements
**Result**: Threat model with mitigations for each attack

#### 0.4 Migration Plan
**Goal**: Zero-downtime deployment path  
**Why**: Production safety  
**How**: @DataMigration creates `.TODO/MIGRATION_PLAN_DynamicPlatformFee.md`:
- Introduce → Backfill → Enforce sequence
- Exact SQL for each step
- Verification queries
**Result**: Migration plan with timing estimates

**GATE CHECK (Phase 0)**:
- [ ] Test harness creates/runs without errors
- [ ] Contract file exists and reviewed
- [ ] Admin detection method decided
- [ ] Threat model complete
- [ ] Migration plan has verification queries

---

### Phase 1: Database Schema & Security (ADDITIVE-ONLY)

#### 1.0 Live Database Confirmation
**Goal**: Verify current state matches assumptions  
**Why**: Prevents surprises during migration  
**How**:
```sql
-- Run verification queries
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'bookings';
-- Document any deviations from expected
```
**Result**: Baseline schema documented

#### 1.1 Create platform_settings Table
**Goal**: Global fee configuration storage  
**Why**: Single source of truth for default fee  
**How**:
```sql
CREATE TABLE public.platform_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    updated_by UUID REFERENCES auth.users(id)
);

-- Seed initial values
INSERT INTO public.platform_settings (key, value) VALUES
('fee_rate_default_bps', '{"value": 1000}'),
('max_fee_rate_bps', '{"value": 3000}'),
('fee_locking_enabled', '{"value": false}'); -- Start disabled
```
**Result**: Table exists with seed data, feature flag OFF

#### 1.2 Add Fee Columns to Entities
**Goal**: Store locked fee per booking/offer/request  **Why**: Fee locking requires per-entity storage  **How**:
```sql
-- Bookings
ALTER TABLE public.bookings 
ADD COLUMN fee_rate_applied_bps INTEGER,
ADD COLUMN fee_amount BIGINT,
ADD COLUMN net_amount BIGINT;

-- Direct offers
ALTER TABLE public.direct_offers 
ADD COLUMN fee_rate_applied_bps INTEGER,
ADD COLUMN fee_amount BIGINT,
ADD COLUMN net_amount BIGINT;

-- Task requests
ALTER TABLE public.task_requests 
ADD COLUMN fee_rate_applied_bps INTEGER,
ADD COLUMN fee_amount BIGINT,
ADD COLUMN net_amount BIGINT;
```
**Result**: All columns added (nullable, no constraint violations)

#### 1.3 Add RLS Policies
**Goal**: Secure access to platform_settings  **Why**: Prevent unauthorized fee manipulation  **How**:
```sql
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Allow read to authenticated
CREATE POLICY "platform_settings_read_authenticated"
ON public.platform_settings FOR SELECT
TO authenticated USING (true);

-- Allow write to admin only
CREATE POLICY "platform_settings_write_admin"
ON public.platform_settings FOR ALL
TO authenticated 
USING (auth.uid() IN (SELECT user_id FROM admin_users))
WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

-- No anon access
CREATE POLICY "platform_settings_no_anon"
ON public.platform_settings FOR ALL
TO anon USING (false);
```
**Result**: Policies active, tested with anon/authenticated/admin roles

#### 1.4 Add Fee Immutability Trigger
**Goal**: Prevent fee rate changes after lock  **Why**: Core business rule  **How**:
```sql
CREATE OR REPLACE FUNCTION fn_protect_fee_rate_applied()
RETURNS TRIGGER AS $$
BEGIN
    -- Allow NULL -> value (initial lock)
    -- Block value -> different value (attempted modification)
    IF OLD.fee_rate_applied_bps IS NOT NULL 
       AND NEW.fee_rate_applied_bps IS DISTINCT FROM OLD.fee_rate_applied_bps THEN
        RAISE EXCEPTION 'fee_rate_applied_bps is immutable once set (booking_id: %, current: %, attempted: %)',
            NEW.id, OLD.fee_rate_applied_bps, NEW.fee_rate_applied_bps;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all three tables
CREATE TRIGGER trg_protect_fee_rate_applied
BEFORE UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION fn_protect_fee_rate_applied();

CREATE TRIGGER trg_protect_fee_rate_applied_direct_offers
BEFORE UPDATE ON public.direct_offers
FOR EACH ROW EXECUTE FUNCTION fn_protect_fee_rate_applied();

CREATE TRIGGER trg_protect_fee_rate_applied_task_requests
BEFORE UPDATE ON public.task_requests
FOR EACH ROW EXECUTE FUNCTION fn_protect_fee_rate_applied();
```
**Result**: Trigger active, tested with update attempts

#### 1.5 Add Audit Logging for Settings Changes
**Goal**: Track who changed fee rates  **Why**: Audit requirement  **How**:
```sql
CREATE OR REPLACE FUNCTION fn_log_platform_settings_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO admin_logs (action, table_name, record_id, old_data, new_data, performed_by)
    VALUES ('UPDATE', 'platform_settings', NEW.key, jsonb_build_object('value', OLD.value), jsonb_build_object('value', NEW.value), NEW.updated_by);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_platform_settings_change
AFTER UPDATE ON public.platform_settings
FOR EACH ROW EXECUTE FUNCTION fn_log_platform_settings_change();
```
**Result**: Changes logged to admin_logs

**GATE CHECK (Phase 1)**:
- [ ] platform_settings table exists with 3 seed rows
- [ ] All 3 entity tables have 3 new columns (nullable)
- [ ] RLS policies block anon, allow authenticated read, restrict write to admin
- [ ] Immutability trigger allows NULL→value, blocks value→new_value
- [ ] Audit trigger creates admin_logs entries

---

### Phase 2: Data Migration (BACKFILL)

#### 2.1 Backfill Existing Bookings
**Goal**: Populate fee_rate_applied_bps for existing records  **Why**: Prevent NULL errors on release  **How**:
```sql
-- Backfill all held/released bookings with default 10%
UPDATE public.bookings 
SET fee_rate_applied_bps = 1000,
    fee_amount = FLOOR(price * 1000 / 10000),
    net_amount = price - FLOOR(price * 1000 / 10000)
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;

-- Same for direct_offers and task_requests
UPDATE public.direct_offers 
SET fee_rate_applied_bps = 1000,
    fee_amount = FLOOR(price * 1000 / 10000),
    net_amount = price - FLOOR(price * 1000 / 10000)
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;

UPDATE public.task_requests 
SET fee_rate_applied_bps = 1000,
    fee_amount = FLOOR(price * 1000 / 10000),
    net_amount = price - FLOOR(price * 1000 / 10000)
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;
```
**Result**: All existing held/released records have fee data

#### 2.2 Verify Backfill Completeness
**Goal**: Confirm no NULL values remain  **Why**: Zero NULL tolerance  **How**:
```sql
SELECT 'bookings' as table_name, COUNT(*) as null_count
FROM bookings 
WHERE fee_rate_applied_bps IS NULL 
  AND payment_status IN ('held', 'released')
UNION ALL
SELECT 'direct_offers', COUNT(*)
FROM direct_offers
WHERE fee_rate_applied_bps IS NULL 
  AND payment_status IN ('held', 'released')
UNION ALL
SELECT 'task_requests', COUNT(*)
FROM task_requests  
WHERE fee_rate_applied_bps IS NULL 
  AND payment_status IN ('held', 'released');
```
**Result**: All counts = 0

**GATE CHECK (Phase 2)**:
- [ ] Backfill query ran without errors
- [ ] Verification query shows 0 NULL values for held/released

---

### Phase 3: RPC Patching (CORE LOGIC)

#### 3.1 Patch escrow_hold Handler
**Goal**: Lock fee rate at escrow time  **Why**: Core feature requirement  **How**:
```sql
-- In process_payment_event_ledger, escrow_hold block:
IF (SELECT value->>'value' FROM platform_settings WHERE key = 'fee_locking_enabled') = 'true' THEN
    -- Read global fee rate
    SELECT (value->>'value')::INTEGER INTO v_fee_rate_bps
    FROM platform_settings 
    WHERE key = 'fee_rate_default_bps';
    
    -- Validate against max
    SELECT LEAST(v_fee_rate_bps, (value->>'value')::INTEGER)
    INTO v_fee_rate_bps
    FROM platform_settings 
    WHERE key = 'max_fee_rate_bps';
    
    -- Write locked rate to entity
    IF p_related_entity_type = 'booking' THEN
        UPDATE public.bookings 
        SET fee_rate_applied_bps = v_fee_rate_bps
        WHERE id = p_related_entity_id;
    ELSIF p_related_entity_type = 'direct_offer' THEN
        UPDATE public.direct_offers 
        SET fee_rate_applied_bps = v_fee_rate_bps
        WHERE id = p_related_entity_id;
    ELSIF p_related_entity_type = 'task_request' THEN
        UPDATE public.task_requests 
        SET fee_rate_applied_bps = v_fee_rate_bps
        WHERE id = p_related_entity_id;
    END IF;
    
    -- Log in journal meta
    v_new_meta := jsonb_set(COALESCE(p_meta, '{}'), '{fee_rate_applied_bps}', to_jsonb(v_fee_rate_bps));
ELSE
    -- Legacy mode: use hardcoded 1000 bps
    v_fee_rate_bps := 1000;
    v_new_meta := p_meta;
END IF;
```
**Result**: Escrow locks fee rate when feature enabled

#### 3.2 Patch release_with_fee Handler
**Goal**: Use locked rate for release calculation  **Why**: Core feature requirement  **How**:
```sql
-- In process_payment_event_ledger, release_with_fee block:
IF (SELECT value->>'value' FROM platform_settings WHERE key = 'fee_locking_enabled') = 'true' THEN
    -- Read locked rate from entity (ignore p_meta for clients)
    IF p_related_entity_type = 'booking' THEN
        SELECT fee_rate_applied_bps, price 
        INTO v_fee_rate_bps, v_entity_amount_gross
        FROM public.bookings 
        WHERE id = p_related_entity_id;
    ELSIF p_related_entity_type = 'direct_offer' THEN
        SELECT fee_rate_applied_bps, price 
        INTO v_fee_rate_bps, v_entity_amount_gross
        FROM public.direct_offers 
        WHERE id = p_related_entity_id;
    ELSIF p_related_entity_type = 'task_request' THEN
        SELECT fee_rate_applied_bps, price 
        INTO v_fee_rate_bps, v_entity_amount_gross
        FROM public.task_requests 
        WHERE id = p_related_entity_id;
    END IF;
    
    -- Validate fee is locked
    IF v_fee_rate_bps IS NULL THEN
        RAISE EXCEPTION 'ERR_FEE_RATE_NOT_LOCKED: Fee rate not locked for entity %', p_related_entity_id;
    END IF;
    
    -- Admin override: only if actor is admin
    IF v_actor_user_id IN (SELECT user_id FROM admin_users) 
       AND p_meta ? 'fee_rate_bps' THEN
        v_fee_rate_bps := (p_meta->>'fee_rate_bps')::INTEGER;
    END IF;
    
    -- Calculate fee and net
    v_fee_amount := FLOOR(v_entity_amount_gross * v_fee_rate_bps / 10000);
    v_net_amount := v_entity_amount_gross - v_fee_amount;
    
    -- Store calculations
    IF p_related_entity_type = 'booking' THEN
        UPDATE public.bookings 
        SET fee_amount = v_fee_amount, net_amount = v_net_amount
        WHERE id = p_related_entity_id;
    ELSIF p_related_entity_type = 'direct_offer' THEN
        UPDATE public.direct_offers 
        SET fee_amount = v_fee_amount, net_amount = v_net_amount
        WHERE id = p_related_entity_id;
    ELSIF p_related_entity_type = 'task_request' THEN
        UPDATE public.task_requests 
        SET fee_amount = v_fee_amount, net_amount = v_net_amount
        WHERE id = p_related_entity_id;
    END IF;
ELSE
    -- Legacy mode: use hardcoded 1000 bps
    v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::INTEGER, 1000);
    v_fee_amount := FLOOR(v_entity_amount_gross * v_fee_rate_bps / 10000);
    v_net_amount := v_entity_amount_gross - v_fee_amount;
END IF;
```
**Result**: Release uses locked rate, admin can override

#### 3.3 Enable Feature Flag
**Goal**: Activate new behavior  **Why**: Gradual rollout  **How**:
```sql
UPDATE platform_settings 
SET value = '{"value": true}', updated_at = now(), updated_by = auth.uid()
WHERE key = 'fee_locking_enabled';
```
**Result**: New logic active

**GATE CHECK (Phase 3)**:
- [ ] RPC patch applied without errors
- [ ] Feature flag starts as false
- [ ] Test: escrow_hold with flag false uses legacy path
- [ ] Test: escrow_hold with flag true locks fee rate
- [ ] Test: release_with_fee with flag true uses locked rate
- [ ] Test: client spoof attempt (p_meta with fee_rate_bps) ignored
- [ ] Test: admin override (p_meta with fee_rate_bps) works when actor is admin

---

### Phase 4: QA & Security Verification

#### 4.1 Unit Tests (RPC Logic)
**Goal**: Verify calculation correctness  **How**: Run `test/unit/fee_calculation_test.dart`  
**Tests**:
- `FLOOR(100 * 1200 / 10000) = 12`
- `FLOOR(99 * 1200 / 10000) = 11`
- `FLOOR(1000 * 1000 / 10000) = 100`
**Result**: All tests pass

#### 4.2 Integration Tests (End-to-End)
**Goal**: Verify full escrow→release cycle  **How**: Run `test/integration/fee_locking_test.dart`  
**Tests**:
1. Set global fee to 12% → escrow → verify locked at 12%
2. Change global fee to 15% → verify locked booking still 12%
3. Release → verify split uses 12% (not 15%)
4. Client spoof attempt → verify locked rate used
5. Concurrent escrows with rate change → verify each locks its own rate
**Result**: All tests pass

#### 4.3 Security Tests (RLS & Abuse)
**Goal**: Verify security boundaries  **How**: Manual SQL tests  
**Tests**:
- Anon SELECT platform_settings → expect 0 rows
- Anon UPDATE platform_settings → expect policy violation
- Client UPDATE bookings.fee_rate_applied_bps → expect trigger rejection
- Client RPC with p_meta fee override → expect ignored
- Admin RPC with p_meta fee override → expect accepted
**Result**: All security boundaries hold

#### 4.4 Migration Verification
**Goal**: Confirm production-ready state  **How**: Run verification queries on production copy  
**Checks**:
- All held/released bookings have non-null fee_rate_applied_bps
- All held/released bookings have fee_amount + net_amount = price
- Immutability trigger prevents fee changes
- Audit log captures settings changes
**Result**: All checks pass

#### 4.5 Rollback Testing
**Goal**: Verified rollback capability  **How**: Test rollback on staging  
**Steps**:
1. Apply full migration
2. Run smoke tests
3. Apply rollback SQL
4. Verify app still works
5. Confirm no data loss
**Result**: Rollback successful

**GATE CHECK (Phase 4)**:
- [ ] Unit tests pass (calculation precision)
- [ ] Integration tests pass (end-to-end flow)
- [ ] Security tests pass (RLS, spoofing, privilege escalation)
- [ ] Migration verification passes
- [ ] Rollback test passes

---

### Phase 5: Documentation & Release

#### 5.1 Documentation Update
**Goal**: Accurate documentation  **How**: @SlineDocs updates:
- `SUPABASE_SETUP.md`: Add platform_settings table, update entity columns, update RPC docs
- `22_Dynamic_Platform_Fee.md`: Mark implemented features as complete
- `Sline_Log.md`: Add changelog entry
**Result**: Docs match implementation

#### 5.2 Release Checklist
**Goal**: Production deployment ready  **How**: Final verification:
- [ ] All gates passed
- [ ] Feature flag enabled in production
- [ ] Monitoring dashboard updated (if applicable)
- [ ] Support team notified of fee display changes
- [ ] Rollback runbook accessible
**Result**: Ready for production

**GATE CHECK (Phase 5)**:
- [ ] Documentation updated
- [ ] Release checklist complete
- [ ] Rollback runbook tested

---

## I) Change Report (Diff-Style)

### Original Issues Summary
1. No test infrastructure specified
2. Contract file missing
3. Admin detection method undecided
4. Fee calculation precision unspecified
5. No feature flag for gradual rollout
6. Backfill verification missing
7. Rollback testing not included
8. Gate structure not explicit

### Added Steps
- Phase 0.1: Test infrastructure setup (fixtures, helpers, harness)
- Phase 0.2: Contract finalization with explicit decisions
- Phase 1.5: Audit logging for settings changes
- Phase 2.2: Backfill verification query
- Phase 3.x: Feature flag implementation
- Phase 4.4: Migration verification
- Phase 4.5: Rollback testing

### Removed Steps
- None (original steps preserved but expanded)

### Reordered Steps
- Test infrastructure moved to Phase 0 (was implied but not explicit)
- Feature flag added throughout (was missing)
- Rollback testing moved to Phase 4 (was only in plan, not executed)

### Expanded Steps
- Phase 1.4: Immutability trigger expanded with NULL→value vs value→new_value logic
- Phase 3.2: Admin override logic added
- Phase 4: Split into 5 sub-steps with specific tests

### Why
- Test infrastructure is prerequisite for all other verification
- Contract and decisions prevent ambiguity during implementation
- Feature flag enables safe gradual rollout
- Verification steps ensure production safety
- Rollback testing provides emergency confidence

### Residual Risks (What Still Remains Risky)
1. **QiCard integration**: Webhook handlers not tested with new fee logic
2. **Old app versions**: May display confusing fee info if server returns new fields unexpectedly
3. **Concurrent escrow edge case**: Business may question different rates for simultaneous bookings
4. **Trigger performance**: Immutability trigger on every booking update (monitor for slowdown)
5. **Admin user management**: Assumes admin_users table exists and is maintained

---

**END OF CRITIQUE & CORRECTED PLAN**

*This plan is now execution-ready with explicit gates, blocking decisions, and verified rollback capability.*
