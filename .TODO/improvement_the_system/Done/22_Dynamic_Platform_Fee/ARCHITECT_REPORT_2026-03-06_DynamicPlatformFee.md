# Architecture Review Report: Dynamic Platform Fee Implementation

**Agent**: @Architect  
**Date**: 2026-03-06  
**Scope**: Dynamic Platform Fee System (`22_Dynamic_Platform_Fee`)  
**Status**: REVIEW COMPLETE - Issues Identified

---

## 1. Executive Summary

This report reviews the architecture and logic of the Dynamic Platform Fee implementation. The implementation follows the MVVM pattern correctly in test infrastructure, but **several critical issues** have been identified in migration logic, calculation consistency, and RPC contract alignment.

**Overall Assessment**: ⚠️ **NEEDS FIXES BEFORE PRODUCTION**

| Category | Status | Notes |
|----------|--------|-------|
| Test Infrastructure (MVVM) | ✅ PASS | Proper layering, no boundary violations |
| Migration Schema | ✅ PASS | Correct column types, proper RLS |
| Migration Logic | ❌ FAIL | Calculation inconsistency: FLOOR vs integer division |
| RPC Contract Alignment | ⚠️ PARTIAL | Placeholder migration (08) not implemented |
| Data Flow | ⚠️ PARTIAL | Missing error code mapping in LedgerService |

---

## 2. Files Scanned

### Documentation Files (5)
1. `.TODO/PLAN_DynamicPlatformFee_CRITIC_2026-03-06.md` - Corrected plan from @PlanCritic
2. `.TODO/CONTRACT_DynamicPlatformFee.md` - Behavior contracts (v1.0)
3. `.TODO/THREAT_MODEL_DynamicPlatformFee.md` - Security threat model
4. `.TODO/MIGRATION_PLAN_DynamicPlatformFee.md` - Migration strategy
5. `Sline_everything/SUPABASE_SETUP.md` - Referenced for schema context

### Test Infrastructure Files (4)
6. `test/fixtures/booking_fixtures.dart` - Test fixtures for bookings/offers/requests
7. `test/helpers/ledger_rpc_invoker.dart` - RPC invocation helpers
8. `test/integration/fee_locking_test.dart` - Integration tests
9. `test/helpers/mock_supabase.dart` - Mock Supabase client

### Migration Files (9)
10. `supabase/migrations/20260307_01_create_platform_settings.sql`
11. `supabase/migrations/20260307_02_add_fee_columns.sql`
12. `supabase/migrations/20260307_03_create_immutability_trigger.sql`
13. `supabase/migrations/20260307_04_backfill_bookings.sql`
14. `supabase/migrations/20260307_05_backfill_direct_offers.sql`
15. `supabase/migrations/20260307_06_backfill_task_requests.sql`
16. `supabase/migrations/20260307_07_verify_backfill.sql`
17. `supabase/migrations/20260307_08_patch_rpc_fee_locking.sql` - ⚠️ PLACEHOLDER
18. `supabase/migrations/20260307_09_enable_fee_locking.sql`

### Production Code Files (1)
19. `lib/features/wallet/services/ledger_service.dart` - RPC client service

**Total Files Scanned**: 19

---

## 3. MVVM Compliance Review

### 3.1 Test Infrastructure Architecture

**Assessment**: ✅ **COMPLIANT**

The test infrastructure correctly follows MVVM boundaries:

```
test/
├── fixtures/          # Data models (Model layer) ✅
│   ├── booking_fixtures.dart
│   └── fixtures.dart (barrel)
├── helpers/           # Service helpers (Service layer) ✅
│   ├── ledger_rpc_invoker.dart
│   ├── mock_supabase.dart
│   └── helpers.dart (barrel)
└── integration/       # Integration tests (test orchestration) ✅
    └── fee_locking_test.dart
```

**Boundary Analysis**:

| Layer | File | Responsibility | MVVM Status |
|-------|------|----------------|-------------|
| Model | `booking_fixtures.dart` | Pure data generation, immutable maps | ✅ Correct |
| Service | `ledger_rpc_invoker.dart` | RPC param builders, response parsers | ✅ Correct |
| Test | `fee_locking_test.dart` | Test orchestration, assertions | ✅ Correct |

**No MVVM Violations Found**: Test fixtures don't call Supabase directly; helpers don't contain business logic; tests don't bypass service layer.

### 3.2 Production Code Architecture

**Assessment**: ⚠️ **PARTIAL GAP**

```lib/features/wallet/services/ledger_service.dart``` (lines 91-110):

```dart
// Current error code mapping (lines 91-110)
String? _mapLedgerCode(String? code) {
  switch (code) {
    case 'ERR_GATE_NOT_ALLOWED': ...
    case 'ERR_ENTITY_NOT_FOUND': ...
    // ❌ MISSING: New fee locking error codes
    // case 'ERR_FEE_RATE_NOT_LOCKED': ...
    // case 'ERR_FEE_CALCULATION_MISMATCH': ...
    // case 'ERR_IMMUTABILITY_VIOLATION': ...
  }
}
```

**Gap**: `LedgerService` doesn't map the new error codes defined in `CONTRACT_DynamicPlatformFee.md` (lines 351-359).

---

## 4. Data Flow Analysis

### 4.1 Data Flow Diagram (Text Description)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DYNAMIC FEE LOCKING FLOW                       │
└─────────────────────────────────────────────────────────────────────────┘

PHASE 1: ESCROW (Fee Lock)
──────────────────────────
  Client App
       │
       ▼
  ┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
  │  LedgerService  │────▶│  RPC:escrow_hold │────▶│  platform_settings  │
  │  (submitPayment │     │                  │     │  (read global rate) │
  │   Event)        │     │                  │     │                     │
  └─────────────────┘     └──────────────────┘     └─────────────────────┘
                              │
                              ▼
                        ┌─────────────┐
                        │   bookings  │◀──── fee_rate_applied_bps (LOCKED)
                        │  (UPDATE)   │      (immutable after set)
                        └─────────────┘

PHASE 2: RELEASE (Fee Calculation)
─────────────────────────────────
  Client App
       │
       ▼
  ┌─────────────────┐     ┌──────────────────────┐
  │  LedgerService  │────▶│ RPC:release_with_fee │
  │                 │     │                      │
  └─────────────────┘     └──────────────────────┘
                                  │
                    ┌──────────────┼──────────────┐
                    ▼              ▼              ▼
              ┌─────────┐    ┌───────────┐   ┌───────────┐
              │ bookings│    │fee_amount │   │net_amount │
              │(SELECT) │    │(UPDATE)   │   │(UPDATE)   │
              │(locked  │    │           │   │           │
              │  rate)   │    │           │   │           │
              └─────────┘    └───────────┘   └───────────┘

SECURITY BOUNDARIES
───────────────────
  • Client cannot spoof fee rate (p_meta ignored for non-admin)
  • Immutability trigger blocks rate changes
  • RLS protects platform_settings
  • Admin override logged in admin_logs
```

### 4.2 Fixture Data Flow

```dart
// test/fixtures/booking_fixtures.dart (lines 53-90)
Map<String, dynamic> createBookingFixture({
  ...
  int? feeRateAppliedBps,
  int? feeAmount,
  int? netAmount,
}) {
  // Calculate fee amounts if fee rate is provided
  final calculatedFeeAmount = feeAmount ??
      (feeRateAppliedBps != null ? (price * feeRateAppliedBps ~/ 10000) : null);
  // ...
}
```

**Assessment**: ✅ **CORRECT** - Uses integer division (`~/`) matching the contract's FLOOR formula.

---

## 5. Logic Issues Found

### Issue 1: CRITICAL - Calculation Inconsistency in Backfill Migrations

**Location**: 
- `20260307_04_backfill_bookings.sql` (lines 14-15)
- `20260307_05_backfill_direct_offers.sql` (lines 14-15)
- `20260307_06_backfill_task_requests.sql` (lines 14-15)

**Current Code** (integer division):
```sql
UPDATE public.bookings 
SET 
    fee_rate_applied_bps = 1000,
    fee_amount = (price * 1000) / 10000,  -- ❌ WRONG: uses / not FLOOR
    net_amount = price - ((price * 1000) / 10000)
WHERE ...
```

**Contract Requirement** (lines 155-158):
```sql
fee_amount = FLOOR(price * fee_rate_applied_bps / 10000)
```

**Problem**: 
- SQL `/` with integers performs truncation toward zero (same as FLOOR for positives)
- But this is **implicit behavior** - not explicit FLOOR
- Inconsistent with contract and test fixtures

**Risk**: If `price * 1000` exceeds integer bounds or if database settings change, behavior may differ.

**Fix Required**:
```sql
-- Should be explicit FLOOR
fee_amount = FLOOR(price * 1000 / 10000)
```

### Issue 2: HIGH - RPC Patch Migration is Placeholder

**Location**: `20260307_08_patch_rpc_fee_locking.sql` (lines 130-154)

**Current State**:
```sql
-- NOTE: This migration is a PLACEHOLDER
-- The actual implementation requires:
-- 1. Full function recreation (the function is 1000+ lines)
-- ...
```

**Problem**: The core RPC logic change is not implemented. Only pseudocode provided.

**Impact**: BLOCKS Phase 3 enablement.

### Issue 3: MEDIUM - Missing Error Code Mapping

**Location**: `lib/features/wallet/services/ledger_service.dart` (lines 91-110)

**Missing Mappings**:
| Error Code | Contract Line | User-Facing Message |
|------------|---------------|---------------------|
| `ERR_FEE_RATE_NOT_LOCKED` | 355 | "Fee rate not set. Please contact support." |
| `ERR_FEE_CALCULATION_MISMATCH` | 356 | "Payment calculation error. Please try again." |
| `ERR_IMMUTABILITY_VIOLATION` | 357 | "Fee rate cannot be changed." |

### Issue 4: LOW - Trigger Comment Mismatch

**Location**: `20260307_03_create_immutability_trigger.sql` (lines 46-49)

**Comment says**:
```sql
-- Disable initially (will be enabled in Phase 3)
```

**But triggers are disabled via DISABLE TRIGGER**, which is correct, but the comment could be clearer about the specific migration file that enables them (09).

---

## 6. RPC Contract Alignment

### 6.1 Contract vs Implementation Matrix

| Contract Requirement | Source File | Status | Notes |
|---------------------|-------------|--------|-------|
| `escrow_hold` locks fee rate | `08_patch_rpc_fee_locking.sql` | ⚠️ PARTIAL | Pseudocode only |
| `release_with_fee` uses locked rate | `08_patch_rpc_fee_locking.sql` | ⚠️ PARTIAL | Pseudocode only |
| Admin override works | `08_patch_rpc_fee_locking.sql` | ⚠️ PARTIAL | Specified but not implemented |
| Feature flag check | `08_patch_rpc_fee_locking.sql` | ✅ SPECIFIED | `fee_locking_enabled` check in pseudocode |
| Error code `ERR_FEE_RATE_NOT_LOCKED` | `CONTRACT.md:355` | ✅ DEFINED | Not in LedgerService |
| Error code `ERR_FEE_CALCULATION_MISMATCH` | `CONTRACT.md:356` | ✅ DEFINED | Not in LedgerService |
| Error code `ERR_IMMUTABILITY_VIOLATION` | `CONTRACT.md:357` | ✅ DEFINED | Trigger uses this code |

### 6.2 Test Helper Alignment

**Location**: `test/helpers/ledger_rpc_invoker.dart` (lines 326-334)

```dart
class FeeLockingErrorCodes {
  static const String feeRateNotLocked = 'ERR_FEE_RATE_NOT_LOCKED';
  static const String feeCalculationMismatch = 'ERR_FEE_CALCULATION_MISMATCH';
  static const String immutabilityViolation = 'ERR_IMMUTABILITY_VIOLATION';
  // ...
}
```

**Assessment**: ✅ **ALIGNED** - Test helpers match contract error codes.

---

## 7. Migration File Logic Review

### 7.1 Migration Sequence Analysis

```
Phase 1: Schema (01-03)
├── 01_create_platform_settings.sql     ✅ Table + RLS + audit trigger
├── 02_add_fee_columns.sql              ✅ Columns added (nullable)
└── 03_create_immutability_trigger.sql   ✅ Triggers created (disabled)

Phase 2: Backfill (04-07)
├── 04_backfill_bookings.sql            ⚠️ Uses / not FLOOR
├── 05_backfill_direct_offers.sql       ⚠️ Uses / not FLOOR
├── 06_backfill_task_requests.sql       ⚠️ Uses / not FLOOR (also uses proposed_price)
└── 07_verify_backfill.sql              ✅ Correct verification query

Phase 3: Enable (08-09)
├── 08_patch_rpc_fee_locking.sql        ❌ PLACEHOLDER - not implemented
└── 09_enable_fee_locking.sql           ✅ Correct enablement logic
```

### 7.2 Migration 06 Special Case

**Location**: `20260307_06_backfill_task_requests.sql` (line 14)

```sql
fee_amount = (proposed_price * 1000) / 10000,  -- ❌ Uses proposed_price, not price
```

**Issue**: `task_requests` uses `proposed_price` column while others use `price`. This is correct for schema alignment but must be verified against actual `task_requests` table schema.

---

## 8. Architecture Gaps

### Gap 1: No Production Service Layer Update

**Missing**: A service/repository to expose `platform_settings` to the Flutter app.

**Expected**: 
```
lib/features/wallet/services/platform_settings_service.dart
```

**Use Case**: Admin dashboard needs to read current fee rate.

### Gap 2: No ViewModel for Fee Display

**Missing**: ViewModel to handle fee calculation display in UI.

**Expected**:
```
lib/features/wallet/viewmodels/fee_calculation_viewmodel.dart
```

**Use Case**: Show fee breakdown before escrow (client) and before release (freelancer).

### Gap 3: Test Fixtures Missing `admin_users` Setup

**Missing**: Fixture to create admin users for testing admin override.

**Location**: `test/fixtures/booking_fixtures.dart`

**Needed**:
```dart
Map<String, dynamic> createAdminUserFixture({...})
```

---

## 9. Recommendations

### Immediate Actions (Before Phase 3)

1. **Fix backfill calculations** (Priority: CRITICAL)
   - Change `/` to `FLOOR()` in migrations 04, 05, 06
   - Verify with edge cases: 99 IQD @ 12% should = 11 IQD

2. **Implement RPC patch** (Priority: CRITICAL)
   - Replace placeholder in `08_patch_rpc_fee_locking.sql`
   - Must include feature flag checks, admin override, error handling

3. **Add error code mapping** (Priority: HIGH)
   - Update `LedgerService._mapLedgerCode()` with new error codes

### Before Production

4. **Add service layer for platform_settings** (Priority: MEDIUM)
   - Create `PlatformSettingsService` for admin dashboard integration

5. **Add integration test for admin override** (Priority: MEDIUM)
   - Test that admin can override fee rate via `p_meta`
   - Test that non-admin override is ignored

6. **Verify task_requests schema** (Priority: MEDIUM)
   - Confirm `proposed_price` column exists (not `price`)

---

## 10. Evidence Summary

### Logic Errors (with line references)

| Issue | File | Line | Evidence |
|-------|------|------|----------|
| Calculation uses `/` not `FLOOR` | `04_backfill_bookings.sql` | 14 | `(price * 1000) / 10000` |
| Calculation uses `/` not `FLOOR` | `05_backfill_direct_offers.sql` | 14 | `(price * 1000) / 10000` |
| Calculation uses `/` not `FLOOR` | `06_backfill_task_requests.sql` | 14 | `(proposed_price * 1000) / 10000` |
| RPC patch is placeholder | `08_patch_rpc_fee_locking.sql` | 130 | `-- This migration is a PLACEHOLDER` |
| Missing error code | `ledger_service.dart` | 91-110 | No `ERR_FEE_RATE_NOT_LOCKED` mapping |

### Correct Implementation (with line references)

| Aspect | File | Line | Evidence |
|--------|------|------|----------|
| Test uses FLOOR | `booking_fixtures.dart` | 69 | `price * feeRateAppliedBps ~/ 10000` |
| Trigger uses correct error code | `03_create_immutability_trigger.sql` | 18 | `ERR_IMMUTABILITY_VIOLATION` |
| Contract defines FLOOR | `CONTRACT.md` | 157 | `FLOOR(price * fee_rate_applied_bps / 10000)` |
| Error codes in tests | `ledger_rpc_invoker.dart` | 327-329 | `ERR_FEE_RATE_NOT_LOCKED`, etc. |

---

## 11. Sign-off

| Reviewer | Status | Notes |
|----------|--------|-------|
| @Architect | ⚠️ CONDITIONAL PASS | Fixes required before Phase 3 |
| @Supabase_Ops | PENDING | Must verify RPC implementation |
| @Sentinel | PENDING | Must verify test coverage |

**Next Steps**:
1. @Supabase_Ops to implement actual RPC patch (replace placeholder)
2. @Architect to fix backfill calculations
3. @Sentinel to add missing error code tests
4. Re-review after fixes

---

*Report generated by @Architect agent following full codebase scan of 19 files.*
