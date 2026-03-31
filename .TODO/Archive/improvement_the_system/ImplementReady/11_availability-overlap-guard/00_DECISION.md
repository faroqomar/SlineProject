# Verdict: OLD vs NEW Availability Overlap Guard

**Role:** SLine Availability & Overlap Guard Critic
**Date:** 2026-03-05
**Focus:** Concurrency, Atomicity, and System Reality

## 1. Verdict

### OLD Diagram / System Score: **1 / 10**

- **Why:** The OLD diagram (`11_availability-overlap-guard.md`) hallucinated a database-level `trg_no_overlap_slots` constraint using `tstzrange`. **Evidence:** `grep_search` across `supabase/migrations/` yields **zero** results for `tstzrange` or `fn_reject_overlapping_slots`. It falsely claims the DB prevents overlapping slots. It also omits the booking insertion entirely.

### NEW Diagram / System Score: **2 / 10**

- **Why:** The NEW diagram explicitly connects booking to slot blocking via `UPDATE availability_slots SET is_blocked=true`. However, this is also **fiction** in the current codebase.
- **Evidence:** `rpc_create_booking_draft_validated` (the sole booking insert path in v2.16) checks `IF v_slot.is_blocked THEN RAISE EXCEPTION`, but it **never** executes an `UPDATE` to flip `is_blocked = true` upon successful insertion.
- **Concurrency Failure:** Because `is_blocked` remains `false`, any other client can concurrently pass the `IF v_slot.is_blocked` check on the same slot milliseconds later, failing only on the secondary `IF EXISTS` check. Furthermore, because `fn_reject_overlapping_slots` does not exist, the provider can create infinite perfectly overlapping slots for clients to book.

## 2. Blockers to Production (MUST-FIX)

1. **Missing DB Constraint:** The `fn_reject_overlapping_slots` trigger MUST be implemented using `tstzrange` to prevent providers from double-booking themselves by creating overlapping slots.
2. **Missing Atomicity:** `rpc_create_booking_draft_validated` MUST execute `UPDATE availability_slots SET is_blocked = true WHERE id = p_slot_id` to atomically remove the slot from the public pool and safely reject concurrent reads.
3. **Missing Flutter Write Path:** Providers have no `AvailabilityService`, `AvailabilityViewModel`, or UI to create/manage slots. The UI needs to enforce explicit UTC passing to avoid timezone boundary overlaps.

## 3. Verification Checklist (Post-Patch)

- [ ] **RLS Test:** Provider A cannot insert/update a slot belonging to Provider B's `provider_id`. (Evidence: `slots_write_owner` RLS rule must be verified).
- [ ] **Overlap Test:** Provider inserting `[10:00, 11:00)` completely fails when attempting to insert `[10:30, 11:30)` (Exception: `Overlapping availability slot`).
- [ ] **Concurrency Test:** Two clients hitting `rpc_create_booking_draft_validated` for the exact same `slot_id` at the exact same millisecond: 1 succeeds (slot explicitly block-updated), 1 fails (`BOOKING_SLOT_BLOCKED` or row lock timeout).
- [ ] **DST Test:** Provider creates a slot spanning a Daylight Savings Time boundary, UI securely transmits as `Z` (UTC ISO-8601), and Postgres stores it without timezone shifting errors.
