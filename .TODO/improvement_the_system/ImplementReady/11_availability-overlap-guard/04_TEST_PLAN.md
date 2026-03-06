# Test Plan: 11_availability-overlap-guard

## 1. RLS Authorization Tests

- **Test:** Authenticated provider attempts to insert slot for their own `provider_id`.
  - **Expected:** Success.
- **Test:** Authenticated user attempts to insert slot for another user's `provider_id`.
  - **Expected:** RLS failure.

## 2. Invariant (Overlap) Tests

- **Test:** Provider creates Slot A (Monday 9 AM - 11 AM).
  - **Expected:** Success.
- **Test:** Provider attempts to create Slot B (Monday 10 AM - 12 PM).
  - **Expected:** Failure (Overlap Exception thrown).
- **Test:** Provider creates Slot C (Monday 11 AM - 1 PM).
  - **Expected:** Success (Edge limits don't overlap since `[)` inclusive/exclusive bounds).

## 3. Booking Integration Tests

- **Test:** Client books Slot A. System updates Slot A `is_blocked = true`.
- **Test:** With Slot A `is_blocked = true`, provider attempts to create an overlapping slot on Monday 10-12 PM.
  - **Expected:** Should overlap fail or pass depending on `is_blocked` behavior in `fn_reject_overlapping_slots`. (Current DB implementation dictates overlap check ignores blocks or includes them? By evidence, it says `is_blocked=false only`- meaning blocked slots _might_ allow new slots under them, which is a logic flaw to be verified).
  - **Action:** Fix database logic if it allows newly created slots to overlap with already-blocked ones.
