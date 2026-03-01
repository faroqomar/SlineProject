# Architect Report — Booking Repeat Slotless Booking

## Scope
- Feature: slotless direct booking creation for repeated client purchases of the same service task.
- Plan reference: MISSING. Risk elevated per orchestrator rule.
- Reviewed paths:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/data/booking_repository.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/qicard_payment_create/index.ts`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_remove_booking_slot_dependency.sql`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql`

## Evidence
- ViewModel delegates booking payment creation to the payment service, not directly to Supabase.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:435`
- QiCard payment service calls the server edge function `qicard_payment_create`.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart:126`
- The edge function calls `rpc_create_booking_draft_validated`.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/qicard_payment_create/index.ts:43`
- The older migration enforced one active slotless booking per `(task_id, client_id)` using a unique partial index and duplicate-check branch.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_remove_booking_slot_dependency.sql:42`
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_remove_booking_slot_dependency.sql:145`
- The current migration removes that unique index and inserts without the duplicate client-task guard.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql:1`
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql:16`
- Live DB verification confirms the unique index is gone and the replacement non-unique index exists.
  - DB object: `public.idx_bookings_task_client_active`
  - DB object absent: `public.uq_bookings_active_task_client`
- Live DB verification confirms the current `public.rpc_create_booking_draft_validated(uuid,text,text,jsonb)` function no longer raises `BOOKING_ALREADY_EXISTS_FOR_CLIENT`.

## MVVM Boundary Check
- PASS: ViewModel owns the user-facing error state and delegates network/server work to `PaymentService`.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:459`
- PASS: Payment service encapsulates the edge-function call.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart:144`
- PASS: No direct Supabase calls were found in the reviewed view layer for this scope.

## Data Flow Map
1. Booking UI invokes `BookingViewModel.createPaymentForBooking(...)`.
2. `BookingViewModel` calls `PaymentService.createPaymentForBooking(...)`.
3. QiCard service invokes edge function `qicard_payment_create`.
4. Edge function calls `public.rpc_create_booking_draft_validated(...)`.
5. RPC inserts a new booking row and returns the canonical booking.
6. Edge function attaches payment metadata and returns the payment form URL.

## Findings
### F1 — Old business rule lived in the database, not the client
- Severity: MED
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_remove_booking_slot_dependency.sql:42`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_remove_booking_slot_dependency.sql:145`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/qicard_payment_create/index.ts:43`
- Why it mattered:
  - Client retries could never succeed because the RPC rejected the request before payment creation.
- Status:
  - Fixed live and in repo by `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql`.

### F2 — One stale UI error message still encoded the removed rule
- Severity: LOW
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:89`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:120`
- Why it mattered:
  - If an old environment still emitted `BOOKING_ALREADY_EXISTS_FOR_CLIENT`, the app would tell the user the rule still existed.
- Status:
  - Updated to neutral retry guidance.

## Proposed Refactors / Contract Notes
- No architectural refactor required for this scope.
- Keep slotless repeat-booking enforcement server-side. Do not add client-side prechecks for duplicate client-task pairs.
- Preserve slot-based exclusivity separately from slotless direct bookings.

## Path Validation Notes
- Confirmed existing code paths:
  - `BookingViewModel.createPaymentForBooking(...)`
  - `QiCardPaymentService.createPaymentForBooking(...)`
  - edge function `qicard_payment_create`
  - RPC `public.rpc_create_booking_draft_validated(...)`
- Confirmed current migration file exists:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql`

## Architect Decision
- APPROVED for this scope.
- No MVVM violation detected.
- Remaining risk is operational: every environment must apply the new migration before expecting repeat slotless bookings to work.
