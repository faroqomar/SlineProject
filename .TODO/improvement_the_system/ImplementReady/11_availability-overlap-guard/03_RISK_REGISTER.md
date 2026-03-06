# Risk Register: 11_availability-overlap-guard

## J1) Risks if we keep the current system

1. **Dependency Missing (Flutter):**
   - **Severity:** High
   - **Likelihood:** 100%
   - **Impact:** Feature is inaccessible. Providers cannot add schedule slots.
   - **Evidence:** `lib/` search yields no `AvailabilityService` or UI components for insertion.
2. **Postgres Exception Unhandled DB Error:**
   - **Severity:** Medium
   - **Likelihood:** High (once UI is built)
   - **Impact:** Confusing "PostgrestException" dialogs for users attempting overlaps.
   - **Evidence:** Custom string in `raise exception 'Overlapping availability slot for provider %'` must be mapped in dart.

## J2) Risks introduced by improvements

1. **Timezone Complexities:**
   - **Risk:** Flutter `DateTime` -> Postgres `timestamptz` conversion limits or shifts may cause daylight savings overlaps or buggy range behavior.
   - **Mitigation:** Ensure UI passes explicit UTC ISO strings to Supabase (`toUtc().toIso8601String()`).
2. **Slot Deletions vs Booking History:**
   - **Risk:** Unrestricted delete on `availability_slots` could orphan or wipe out bookings if `booking.slot_id` uses CASCADE.
   - **Mitigation:** Database foreign key must use `RESTRICT` on delete.
