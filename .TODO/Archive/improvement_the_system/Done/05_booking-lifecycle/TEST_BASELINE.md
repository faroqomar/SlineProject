# Booking Lifecycle — Test Baseline

**Plan:** `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md`

## Guard contract test

- **File:** `test/unit/booking/booking_guard_contract_test.dart`
- **Run:** `flutter test test/unit/booking/booking_guard_contract_test.dart`
- **Expects:** When current user is client and booking status is delivered, `updateBookingStatus(bookingId, BookingStatus.canceled)` throws `StateError` with message containing "cannot cancel after delivery".
- **Fixture:** Mock Supabase client returns a delivered booking with `client_id` matching auth user; no DB seed required.

## All booking unit tests

- **Run:** `flutter test test/unit/booking/`
- **Evidence:** 11 tests passed (including guard contract test). AppLogger used; no print().

## DB verification (manual / Supabase MCP)

- **Enum:** `SELECT enumlabel FROM pg_enum WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'booking_status_enum');` — must include `disputed`, `no_show`.
- **Guard:** As client, `UPDATE bookings SET status = 'canceled' WHERE id = <delivered_booking_id> AND client_id = auth.uid();` — must raise exception.
