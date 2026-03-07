# Test Plan: Direct Offers Work Contract

## 1. Unit Tests (State Transitions)

- **Goal**: Verify `fn_direct_offer_guard` logic.
- **Tools**: SQL test scripts (e.g., `pgTAP` or manual INSERT/UPDATE tests).
- **Cases**:
  - [ ] Try `sent -> delivered` (Expected: FAIL).
  - [ ] Try `sent -> accepted` (unpaid) (Expected: PASS).
  - [ ] Try `accepted -> active` (unpaid) (Expected: FAIL).
  - [ ] Try `accepted -> active` (held) (Expected: PASS).
  - [ ] Try `active -> delivered` by Client (Expected: FAIL).

## 2. Integration Tests (Full Flow)

- **Goal**: Verify Flutter `DirectOffersService` E2E.
- **Tools**: Flutter Widget/Integration Tests.
- **Steps**:
  - [ ] Freelancer creates offer -> Message appears in chat.
  - [ ] Client accepts without payment -> Status becomes `accepted`.
  - [ ] Client pays -> Status becomes `active`, `payment_status` becomes `held`.
  - [ ] Freelancer marks delivered -> Status becomes `delivered`.
  - [ ] Client completes -> Status becomes `completed`, `payment_status` becomes `released`.

## 3. Security & RLS Tests

- **Goal**: Ensure user isolation.
- **Cases**:
  - [ ] User A tries to accept User B's offer (Expected: RLS FAIL).
  - [ ] Freelancer tries to accept their own offer (Expected: Service/Logic FAIL).
  - [ ] Anonymous user tries to view direct offers (Expected: RLS FAIL).

## 4. Ledger Verification

- **Goal**: Verify financial accuracy.
- **Steps**:
  - [ ] Inspect `ledger_lines` after `escrow_hold`.
  - [ ] Inspect `ledger_lines` after `release_with_fee`.
  - [ ] Check `platform_revenue` for fee calculation (bps).
