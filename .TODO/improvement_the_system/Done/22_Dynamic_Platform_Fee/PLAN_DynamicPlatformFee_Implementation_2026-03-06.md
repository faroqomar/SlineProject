# 📌 Plan: Dynamic Platform Fee System Implementation

**Date**: 2026-03-06
**Target**: Folder `22_Dynamic_Platform_Fee` - Production-grade fee locking system
**Status**: Plan Only (Pending Review)

---

## 1) Goal

- **Goal**: Implement a dynamic platform fee system that locks the fee rate at escrow time, preventing fee changes from affecting in-flight bookings while allowing admins to adjust future rates.
- **Why**: Current system hardcodes 10% fee and allows potential client spoofing via `p_meta`. This creates financial drift risk and audit failures.
- **Result**: A secure, auditable fee system where:
  1. Admin sets global fee rate in `platform_settings`
  2. Fee rate is locked to booking at escrow time (`fee_rate_applied_bps`)
  3. Release uses the locked rate, not the current global rate
  4. All fee calculations are immutable and traceable

---

## 2) Scope

### In-Scope

1. **Database Schema**:
   - Create `platform_settings` table (global fee configuration)
   - Add `fee_rate_applied_bps`, `fee_amount`, `net_amount` columns to `bookings`
   - Add same columns to `direct_offers` and `task_requests` (for consistency)

2. **RLS & Security**:
   - `platform_settings` admin-only access
   - Immutability trigger to prevent `fee_rate_applied_bps` changes after lock

3. **RPC Modifications**:
   - Patch `process_payment_event_ledger` to:
     - Read global fee from `platform_settings` during `escrow_hold`
     - Write locked fee to entity columns
     - Read locked fee from entity during `release_with_fee` (ignore `p_meta` for clients)
     - Calculate `fee_amount` and `net_amount` using `FLOOR()` for precision

4. **Data Migration**:
   - Backfill existing bookings with 10% (1000 bps) default rate
   - Seed `platform_settings` with initial 10% fee rate

5. **Flutter App (Minimal)**:
   - Display fee breakdown in booking/offer details (if UI exists)
   - No new screens - backend-focused feature

6. **Documentation Sync**:
   - Update `SUPABASE_SETUP.md` with new table/columns
   - Update diagrams in `22_Dynamic_Platform_Fee.md`

### Out-of-Scope

1. **Admin Dashboard UI**: Out of scope - assumes admin updates `platform_settings` via SQL or future admin dashboard
2. **Fee Change Notifications**: No client/freelancer notifications when global rate changes
3. **Historical Analytics**: No reporting on fee rate history over time
4. **Multi-Currency Fees**: Only IQD support (existing constraint)
5. **Complex Fee Structures**: No tiered/volume-based fees (flat percentage only)

---

## 3) Evidence & Findings (From Scan)

### Existing

| Component | Evidence | Status |
|-----------|----------|--------|
| `process_payment_event_ledger` RPC | `supabase/migrations/Archive/20260225_create_process_payment_event_ledger_rpc.sql` | ✅ Exists |
| `bookings` table | `SUPABASE_SETUP.md` Section 5.9 | ✅ Exists |
| `direct_offers` table | `SUPABASE_SETUP.md` Section 5.11 | ✅ Exists |
| `task_requests` table | `SUPABASE_SETUP.md` Section 5.4 | ✅ Exists |
| `accounts`, `journal_entries`, `ledger_lines` | `SUPABASE_SETUP.md` Section 5.22 | ✅ Exists |
| Double-entry ledger system | `SUPABASE_SETUP.md` Section 9 | ✅ Active |
| `payment_event_type_enum` | `SUPABASE_SETUP.md` | ✅ Exists (includes `escrow_hold`, `release_with_fee`) |

### Missing

| Component | Required For | Status |
|-----------|------------|--------|
| `platform_settings` table | Global fee storage | ❌ Missing |
| `bookings.fee_rate_applied_bps` | Fee lock storage | ❌ Missing |
| `bookings.fee_amount` | Calculated fee storage | ❌ Missing |
| `bookings.net_amount` | Net payout storage | ❌ Missing |
| Same columns on `direct_offers` | Consistency | ❌ Missing |
| Same columns on `task_requests` | Consistency | ❌ Missing |
| Fee immutability trigger | Security | ❌ Missing |

### Conflicts / Risks

| Risk | Evidence | Severity |
|------|----------|----------|
| **Client Spoofing via `p_meta`** | RPC reads `fee_rate_bps` from `p_meta` parameter (line 339 in migration) - malicious clients could pass low fee | 🔴 **CRITICAL** |
| **Hardcoded 10% Fallback** | `v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000);` - ignores global settings | 🔴 **CRITICAL** |
| **No Fee Locking** | `escrow_hold` event does NOT write fee rate to booking record | 🔴 **CRITICAL** |
| **Naming Drift** | Some docs use `system_config` vs `platform_settings` - must standardize on `platform_settings` | 🟡 Medium |
| **Schema Inconsistency** | RPC uses `amount_gross` while booking table uses `price` - need to verify column mapping | 🟡 Medium |
| **Backfill Complexity** | Existing bookings need `fee_rate_applied_bps = 1000` to maintain invariant | 🟡 Medium |

---

## 4) System Impact Map

| Layer | Impact |
|-------|--------|
| **UI** | Minimal - display `fee_amount` and `net_amount` in booking/offer details if UI exists |
| **MVVM/App Logic** | None - no new ViewModels needed |
| **Database** | High - new table, 3 new columns on 3 tables, triggers, RPC patch |
| **RLS/Security** | High - new policies for `platform_settings`, immutability enforcement |
| **Realtime/Notifications** | None - no realtime changes needed |
| **Storage** | None - no storage changes |
| **Observability** | Low - consider logging fee rate changes in `admin_logs` |
| **Compatibility & Migration** | High - must backfill existing bookings with 10% rate |
| **Contracts** | High - RPC behavior changes for `escrow_hold` and `release_with_fee` |

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> **Primary**: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Confirm acceptance criteria from test plan in `22_Dynamic_Platform_Fee/04_TEST_PLAN.md`:
  - Set fee to 12% → Escrow → Verify `fee_rate_applied_bps=1200`
  - Change fee to 15% → Verify locked booking STILL has `fee_rate_applied_bps=1200`
  - Release → Verify split uses 12% (not 15%)
- [ ] (@Architect) Confirm affected modules:
  - `supabase/migrations/` - new migration file
  - `lib/features/booking/` - potential UI updates
  - `lib/features/direct_offers/` - potential UI updates
  - `Sline_everything/SUPABASE_SETUP.md` - documentation
- **Verify (@Sentinel)**: All test scenarios documented and measurable

### 0.2 Threat Model (CRITICAL - Money Flow)

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_DynamicPlatformFee.md`:
  - Attack: Client passes `fee_rate_bps=0` in `p_meta` → Mitigation: RPC ignores `p_meta` fee for clients
  - Attack: Admin sets fee to 100% → Mitigation: Validate max fee rate (e.g., 30%)
  - Attack: Modify locked fee after escrow → Mitigation: Immutability trigger
  - Attack: Query `platform_settings` as anon → Mitigation: RLS policy
- **Verify (@Sentinel)**: All threats have testable mitigations

### 0.3 Contracts (RPC Behavior Changes)

- [ ] (@APIContract) Create `.TODO/CONTRACT_DynamicPlatformFee.md`:
  - `process_payment_event_ledger('escrow_hold', ...)` now writes `fee_rate_applied_bps` to entity
  - `process_payment_event_ledger('release_with_fee', ...)` now reads `fee_rate_applied_bps` from entity
  - `p_meta->>'fee_rate_bps'` is IGNORED for client actors (only respected for admin/service role)
- **Verify (@Sentinel)**: Contract matches expected Flutter ↔ DB behavior

### 0.4 Migration Plan

- [ ] (@DataMigration) Create `.TODO/MIGRATION_PLAN_DynamicPlatformFee.md`:
  - **Introduce**: `platform_settings` table + columns (non-breaking)
  - **Backfill**: Existing bookings get `fee_rate_applied_bps = 1000`
  - **Enforce**: Immutability trigger prevents changes to locked fees
  - **Compatibility Window**: Old app versions continue working (they ignore new columns)
- **Verify (@Sentinel)**: Zero-downtime migration path confirmed

---

## Phase 1: Database & Security

> **Primary**: @Supabase_Ops

### 1.0 Live Supabase Confirmation

- [ ] (@Supabase_Ops) Re-scan live database:
  - Confirm `bookings` columns: `id`, `client_id`, `provider_id`, `price`, `status`, `payment_status`
  - Confirm `direct_offers` columns match expected
  - Confirm `task_requests` columns match expected
  - Confirm `process_payment_event_ledger` signature
- **Verify (@Sentinel)**: Live schema matches expected migration targets

### 1.1 Schema (Additive-First)

- [ ] (@Supabase_Ops) Create migration `20260307_create_platform_settings.sql`:
  - Create `platform_settings` table with key/value JSONB structure
  - Seed with `fee_rate_default_bps = 1000` (10%)
  - Add `max_fee_rate_bps` constraint (e.g., 3000 = 30% max)
- [ ] (@Supabase_Ops) Create migration `20260307_add_fee_columns_to_entities.sql`:
  - Add `fee_rate_applied_bps INTEGER` to `bookings`, `direct_offers`, `task_requests`
  - Add `fee_amount NUMERIC` to same tables
  - Add `net_amount NUMERIC` to same tables
- **Verify (@Sentinel)**: All columns added, no breaking changes

### 1.2 RLS

- [ ] (@Supabase_Ops) Add RLS policies for `platform_settings`:
  - `SELECT`: Only authenticated users (for read-only display if needed)
  - `INSERT/UPDATE/DELETE`: Only service role or admin users
- [ ] (@Supabase_Ops) Add immutability trigger:
  - Trigger: `trg_protect_fee_rate_applied`
  - Rule: If `OLD.fee_rate_applied_bps IS NOT NULL` and new value differs → RAISE EXCEPTION
- **Verify (@Sentinel)**: RLS audit passes - no unauthorized access paths

### 1.3 Triggers/RPC

- [ ] (@Supabase_Ops) Patch `process_payment_event_ledger` - `escrow_hold` block:
  - Read `fee_rate_default_bps` from `platform_settings`
  - Write to `entity.fee_rate_applied_bps`
  - Log rate lock in `journal_entries.meta`
- [ ] (@Supabase_Ops) Patch `process_payment_event_ledger` - `release_with_fee` block:
  - Read `fee_rate_applied_bps` from entity (NOT from `p_meta`)
  - Calculate: `fee_amount = FLOOR(gross * fee_rate_applied_bps / 10000)`
  - Calculate: `net_amount = gross - fee_amount`
  - Write `fee_amount` and `net_amount` to entity
- [ ] (@Supabase_Ops) Add admin override logic (optional):
  - If actor is admin/service role → allow `p_meta->>'fee_rate_bps'` override
  - If actor is client → ignore `p_meta` fee rate
- **Verify (@Sentinel)**: RPC logic matches contract, no `p_meta` spoofing possible

### 1.4 Migration Execution

- [ ] (@DataMigration) Run backfill:
  - Update all existing bookings with `payment_status = 'held'` or `payment_status = 'released'` → set `fee_rate_applied_bps = 1000`
  - Backfill `fee_amount` and `net_amount` for completed bookings using historical data
- **Verify (@Sentinel)**: Backfill query runs without errors, all records updated

---

## Phase 2: App Layer (Minimal)

> **Primary**: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Update `Booking` model (if exists):
  - Add `feeRateAppliedBps`, `feeAmount`, `netAmount` fields
- [ ] (@Architect) Update `DirectOffer` model (if exists):
  - Add same fee-related fields
- **Verify (@Sentinel)**: Model fields match database columns

### 2.2 Services/Repositories

- [ ] (@Architect) Update `BookingRepository`:
  - Ensure queries select new fee columns
- [ ] (@Architect) Update `DirectOffersRepository`:
  - Ensure queries select new fee columns
- **Verify (@Sentinel)**: No N+1 queries, RLS-safe access

### 2.3 ViewModels (Minimal)

- [ ] (@Architect) Update `BookingDetailsViewModel` (if exists):
  - Expose fee breakdown for display
- **Verify (@Sentinel)**: Fee display is accurate

---

## Phase 3: UI (If Applicable)

> **Primary**: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Add fee breakdown display in booking/offer detail screens:
  - Show gross amount, fee amount, net amount
  - Show fee percentage (e.g., "Platform fee (12%)")
- **Verify (@Sentinel)**: UI displays correctly with loading/error states

### 3.2 Polish

- [ ] (@Pixel) Format currency amounts using existing formatters
- **Verify (@Sentinel)**: Consistent with app theme

---

## Phase 4: QA + Security (MANDATORY)

> **Primary**: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Run migration verify queries:
  - `SELECT * FROM platform_settings` → returns 1 row with `fee_rate_default_bps = 1000`
  - `SELECT fee_rate_applied_bps FROM bookings WHERE payment_status = 'held'` → all non-null
- [ ] (@Sentinel) Verify model field mapping:
  - Booking model includes all 3 new fee fields
- **Verify (@Sentinel)**: No mismatches

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute threat model negative checks:
  - Attempt to update `bookings.fee_rate_applied_bps` directly → expect trigger rejection
  - Call RPC as client with `p_meta = '{"fee_rate_bps": 0}'` → expect locked rate used
  - Query `platform_settings` as anon → expect RLS rejection
- [ ] (@Sentinel) RLS leak audit:
  - Verify `platform_settings` not readable by anon
  - Verify `platform_settings` not writable by non-admin
- **Verify (@Sentinel)**: Unauthorized access impossible

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E script:
  1. Set global fee to 12% (1200 bps)
  2. Create booking and escrow payment
  3. Verify `bookings.fee_rate_applied_bps = 1200`
  4. Change global fee to 15% (1500 bps)
  5. Verify booking still has `fee_rate_applied_bps = 1200`
  6. Complete booking (release)
  7. Verify ledger lines use 12% fee (not 15%)
  8. Verify `bookings.fee_amount` and `bookings.net_amount` populated
- [ ] (@Sentinel) Edge cases:
  - Zero fee rate (0 bps) - system should handle gracefully
  - Small amounts where fee rounds to 0
  - Concurrent escrows with rate change mid-flight
- **Verify (@Sentinel)**: All tests pass

---

## Phase 5: Documentation Sync (MANDATORY)

> **Primary**: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/SUPABASE_SETUP.md`:
  - Add `platform_settings` table documentation (Section 5.x)
  - Update `bookings`, `direct_offers`, `task_requests` with new fee columns
  - Update `process_payment_event_ledger` RPC documentation with fee locking behavior
- [ ] (@SlineDocs) Update `Sline_everything/AppDigram/All_Diagrams/22_Dynamic_Platform_Fee.md`:
  - Mark implemented features as complete
  - Update diagram to reflect actual implementation
- [ ] (@SlineDocs) Add changelog entry in `Sline_everything/Sline_Log.md`
- **Verify (@Sentinel)**: Docs match code + live DB reality

---

## 7) Acceptance Criteria (MANDATORY)

### Correctness
- [ ] `platform_settings` table exists with `fee_rate_default_bps = 1000`
- [ ] All existing bookings have `fee_rate_applied_bps` backfilled to 1000
- [ ] New escrows lock current global fee rate to `fee_rate_applied_bps`
- [ ] Release uses locked rate, not current global rate
- [ ] `fee_amount` and `net_amount` calculated and stored correctly

### Security
- [ ] `platform_settings` RLS prevents anon access
- [ ] Immutability trigger prevents `fee_rate_applied_bps` changes
- [ ] Client cannot spoof fee rate via `p_meta`
- [ ] Admin can override fee rate if needed (optional)

### UX Stability
- [ ] Existing bookings continue working (no disruption)
- [ ] Old app versions work (backward compatible)
- [ ] Fee breakdown displays correctly in UI

### Performance
- [ ] No N+1 queries introduced
- [ ] RPC performance unchanged (single row lookups)
- [ ] Migration completes in < 5 seconds for existing data

### Migration Safety
- [ ] Zero-downtime deployment possible
- [ ] Rollback plan tested and documented
- [ ] Backfill query tested on copy of production data

---

## 8) Rollback Plan

### DB Rollback (If Needed Within 24 Hours)

```sql
-- 1. Remove immutability triggers
DROP TRIGGER IF EXISTS trg_protect_fee_rate_applied ON bookings;
DROP TRIGGER IF EXISTS trg_protect_fee_rate_applied ON direct_offers;
DROP TRIGGER IF EXISTS trg_protect_fee_rate_applied ON task_requests;

-- 2. Revert RPC to original (restore from backup in migrations/Archive/)
-- Apply: 20260225_create_process_payment_event_ledger_rpc.sql (original)

-- 3. Drop new columns (optional - can leave as nullable)
ALTER TABLE bookings DROP COLUMN IF EXISTS fee_rate_applied_bps;
ALTER TABLE bookings DROP COLUMN IF EXISTS fee_amount;
ALTER TABLE bookings DROP COLUMN IF EXISTS net_amount;
-- ... repeat for direct_offers, task_requests

-- 4. Drop platform_settings
DROP TABLE IF EXISTS platform_settings;
```

### Forward Fix (If Issues Found After 24 Hours)

- Fix forward via new migration rather than rollback
- Example: If fee calculation has bug, patch RPC in new migration

### Emergency Disable

- If critical bug found: temporarily disable new fee logic in RPC by checking feature flag
- Fallback to hardcoded 10% until fix deployed

---

## 9) References

### Documentation Scanned
- `Sline_everything/SUPABASE_SETUP.md` - Database schema reference
- `Sline_everything/DEVELOPER_GUIDE.md` - Feature architecture
- `Sline_everything/STRUCTURE.md` - File organization
- `Sline_everything/MVP_ROADMAP.md` - Current feature status
- `.TODO/improvement_the_system/22_Dynamic_Platform_Fee/00_HOLISTIC_REPORT.md` - Audit findings
- `.TODO/improvement_the_system/22_Dynamic_Platform_Fee/01_NOTES.md` - Ground truth vs diagram
- `.TODO/improvement_the_system/22_Dynamic_Platform_Fee/02_GAPS_AND_FIXES.md` - Identified gaps
- `.TODO/improvement_the_system/22_Dynamic_Platform_Fee/03_RISK_REGISTER.md` - Risk analysis
- `.TODO/improvement_the_system/22_Dynamic_Platform_Fee/04_TEST_PLAN.md` - Test scenarios
- `.TODO/improvement_the_system/22_Dynamic_Platform_Fee/06_DIAGRAM_FINAL.md` - Final diagram

### Code Scanned
- `supabase/migrations/Archive/20260225_create_process_payment_event_ledger_rpc.sql` - RPC to patch
- `lib/core/services/payment_service.dart` - Payment interface
- `lib/features/booking/` - Booking feature
- `lib/features/direct_offers/` - Direct offers feature

### Live DB Status (From Evidence Files)
- `platform_settings` table: ❌ Does not exist (evidence: `01_SCHEMA_PROOF.md` line 10)
- `bookings.fee_rate_applied`: ❌ Column missing (evidence: `01_SCHEMA_PROOF.md` line 67)
- `process_payment_event_ledger` RPC: ✅ Exists (evidence: migration file found)
- Current fee logic: Hardcoded 1000 bps fallback (evidence: `01_NOTES.md` line 22)

### Agent Workflow Used
- `.agents/workflows/planner.md` - Strategic Planner workflow

---

**END OF PLAN**

*This plan is ready for review. Once approved, execution can begin with @Executor agent using the phases above.*
