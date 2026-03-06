# FULL REPORT: 22 Dynamic Platform Fee

## 0) Skill Selection

- **Skills selected**: DB-First Financial Modeling, Invariants & Contracts, Threat Modeling (Security), Evidence-First Reading, Diagram Crafting.
- **Why these fit**: Platform fees must be legally predictable for freelancers. Changing a fee dynamically demands a "Lock at Escrow" architecture. Validating this snapshot process within the DB Ledger prevents severe revenue leaks and prevents clients spoofing 0% fees.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/Done/22_Dynamic_Platform_Fee`
- **What system/feature it describes**: How SLine establishes its commission rate (e.g., 10% vs 15%), and how that rate is locked-in dynamically whenever a new booking is funded, ensuring future rate changes don't affect past agreements.
- **Entities involved**: `platform_settings` (New Table), `bookings` (Cols: `fee_rate_applied`), `process_payment_event_ledger`.

## 2) Human Explanation

If the platform fee is 10% on Monday, and a Freelancer accepts a job on Monday, they expect to pay 10%. If SLine raises the fee to 15% on Tuesday, the Monday job must still clear at 10% when it finishes on Wednesday. To do this, the Ledger RPC checks `platform_settings.fee_rate_bps` the exact moment Escrow is funded. It saves that rate directly onto the `booking` row (`fee_rate_applied = 1000`). When the work is 'Released', the RPC uses the locked rate directly to calculate the final Platform Revenue account credit.

## 3) Symbol Legend

- **Rectangles**: Configuration Tables vs Ledger RPC Engine.
- **Solid Arrows**: "Lock" phase vs "Execution" phase.
- **Dashed Arrows**: Admin updating global constraints.

## 4) Extracted Contracts & Invariants

1. **The Lock Rule**: Once `payment_status` is `held`, the entity's `fee_rate_applied` can NEVER change.
2. **Gross Balance Rule**: `Client_Paid = Freelancer_Earned + Platform_Revenue`.
3. **Double-Entry Balance**: Fee events result in 3 lines: DR Escrow(Gross), CR Freelancer(Net), CR Platform(Fee). `Sum = 0`.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: The codebase lacked a `platform_settings` table to centralize this.
- **Resolution**: Provide explicit schema additions for `fee_rate_default` mapped in Basis Points (bps).

### 5.2 Logic Drift

- **Conflict**: Initial implementations relied on passing `fee` calculations via client-side `meta` dicts.
- **Resolution**: The RPC MUST ignore the client entirely and read the rate from the trusted DB configuration.

### 5.3 Data Model Drift

- **Conflict**: `bookings` was missing `fee_rate_applied`.
- **Resolution**: Add `fee_rate_applied`, `fee_amount`, `net_amount` to entities.

## 6) Security & Failure Modes (Adversarial)

- **Client Rate Spoofing**: A malicious client passes `fee_rate_bps = 0` via the frontend API payload to save the freelancer money in exchange for a kickback.
  - _Mitigation_: The `SECURITY DEFINER` Ledger RPC natively ignores the payload for fee math, fetching it exclusively from the DB trusted environment.
- **Penny Drift**: 10% of 99 cents results in fractions.
  - _Mitigation_: Implementation mandates `FLOOR()` or `ROUND()` strictly executed in SQL, avoiding JS integer drift.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: "Earnings Breakdown" (Freelancer), "Task Receipt" (Client).
- **States**: UI mathematically calculates local approximations to show the user visually.
- **Guardrails**: UI never controls the final truth; it just displays what it expects.

### 7.2 Admin Dashboard UI

- **Pages**: Finance Configurations.
- **Metrics**: Current Platform Average BPS taking effect.
- **Drilldowns**: Admin logs showing exactly when `UPDATE platform_settings` occurred.

### 7.3 Implementation Hooks

- `process_payment_event_ledger`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 10/10 (Post-fixes)
- **Best Diagram Type**: Sequence Diagram heavily splitting "Phase 1: Locking" vs "Phase 2: Execution".

## 9) Upgrade Plan

- **Phase 0: Observability**: Ensure `p_meta` in Journal Entries tracks the exact BPS rate utilized during Release.
- **Phase 1: Contracts**: Deploy `platform_settings` and `fee_rate_applied` columns.
- **Phase 2: Hardening**: Rewrite the Release phase inside the Ledger RPC to fetch the locked rate, compute Math securely, and distribute chunks.
- **Phase 3: Scale**: Maintain.

## 10) Risks

### 10.1 Risks if current version kept

- **Financial Drift**: Without locked rates, retroactive fee changes trigger mass user anger and disputes.

### 10.2 Risks introduced by fixes

- **Legacy Migration**: Older bookings lack `fee_rate_applied`. _Mitigation_: SQL migration script backfills all existing bookings with the legacy `1000 bps` rate.

## 11) Test Plan (High-value)

- **Integration**: Create booking, fund escrow (locks 10%). Admin changes global rate to 15%. Client releases booking. Assert the final fee taken was exactly 10%.
- **Unit**: Verify Float/Floor rounding math precisely balances fractions (e.g. 100 / 3).

## 12) Production Checklist

- [ ] Schema extensions applied (`fee_rate_applied`).
- [ ] RPC strips client manipulation parameters securely.
- [ ] Backfill migration completed for existing entity states.
