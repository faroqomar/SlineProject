# Evidence File: Availability & Overlap Guard

## A) DB Overlap Guard

- **Check 1:** `trg_no_overlap_slots` + `fn_reject_overlapping_slots` logic.
- **Evidence:** MISSING in DB migrations. `grep_search` across `supabase/migrations/` yields no hits globally for `tstzrange` nor `fn_reject_overlapping_slots`.
- **Finding:** The overlap check is a hallucination of the documentation. There is no DB mechanism preventing providers from creating overlapping slots.

## B) Booking-slot atomicity

- **Check 1:** Prove booking creation atomically flips `availability_slots.is_blocked=true`.
- **Evidence:** `rpc_create_booking_draft_validated` (`supabase/migrations/Archive/20260228_bookin_server_authority.sql`, Line 80).
  ```sql
  IF v_slot.is_blocked THEN
    RAISE EXCEPTION 'BOOKING_SLOT_BLOCKED';
  END IF;
  ```
  The RPC inserts the booking and returns it. **It never issues an `UPDATE availability_slots SET is_blocked = true`**.
- **Check 2:** Prove two concurrent bookings produce 1 success + 1 fail (DB-side).
- **Evidence:** While the block-state is never flipped, a secondary check natively exists:
  ```sql
  IF EXISTS (SELECT 1 FROM public.bookings b WHERE b.slot_id = p_slot_id AND b.status::TEXT NOT IN ('canceled', 'refunded', 'expired_unanswered') LIMIT 1) THEN
    RAISE EXCEPTION 'BOOKING_SLOT_UNAVAILABLE';
  ```
  This query prevents the _exact same slot_ from being double-booked. However, because slots can overlap (due to missing constraint #A), the system is still vulnerable to parallel overlapping bookings across distinct slot rows.

## C) Deletion/history safety

- **Check 1:** Confirm FK `booking.slot_id -> availability_slots.id` uses `RESTRICT` (no CASCADE wipe).
- **Evidence:** Extracted from `SUPABASE_SETUP.md`: `FK to availability_slots`. Postgres defaults to `NO ACTION` (which acts as RESTRICT during transaction validation) when explicit actions like `CASCADE` are missing.
- **Finding:** Safe, provided `CASCADE` has not been added directly to the live schema silently.

## D) Flutter implementation

- **Check 1:** Prove `AvailabilityService` + ViewModel + UI exist for INSERT.
- **Evidence:** `grep_search` for `availability_slots` in `lib/` only surfaces JSON parsing in `lib/features/booking/models/booking_model.dart`.
- **Finding:** MISSING.

## E) Timezone contract

- **Check 1:** Prove UI sends UTC ISO strings to timestamptz.
- **Evidence:** MISSING. UI does not exist yet.
