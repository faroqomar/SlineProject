# MASTER REPORT — Booking Repeat Slotless Booking

## A) Executive Summary
- What was reviewed:
  - The slotless direct booking flow that previously rejected repeat bookings from the same client for the same booking task.
  - App path reviewed from `BookingViewModel` to `QiCardPaymentService` to `qicard_payment_create` to `public.rpc_create_booking_draft_validated(...)`.
- Overall risk level:
  - MEDIUM after review.
  - Reason: this is a payment-adjacent booking lifecycle change, but the removed guard was a business uniqueness rule rather than an authorization control.
- Final decision:
  - Ready.
  - Note: plan reference was missing, so process risk remains elevated even though technical blockers were not found.

## B) Consolidated Findings (Deduplicated)

### Security
- Severity: LOW
- Owner agent: `@CodeGuard`
- Exact files or DB objects:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart:157`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart:388`
  - `public.rpc_create_booking_draft_validated(uuid,text,text,jsonb)`
- Fix recommendation:
  - No security blocker in this scope. Keep booking creation server-authoritative and keep sanitized logging.

### Data Integrity
- Severity: MED
- Owner agent: `@Architect`
- Exact files or DB objects:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_remove_booking_slot_dependency.sql:42`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_remove_booking_slot_dependency.sql:145`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql:1`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql:16`
- Fix recommendation:
  - Use the new migration in every environment so repeat slotless bookings insert successfully.
  - Keep slot exclusivity separate from slotless direct bookings.

### Architecture / MVVM
- Severity: LOW
- Owner agent: `@Architect`
- Exact files:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:435`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart:126`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/qicard_payment_create/index.ts:43`
- Fix recommendation:
  - No refactor required.
  - Preserve the current server-authoritative path and do not add client-side duplicate-booking prechecks.

### Performance
- Severity: LOW
- Owner agent: `@CodeGuard`
- Exact files or DB objects:
  - `public.idx_bookings_task_client_active`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql:3`
- Fix recommendation:
  - Keep the non-unique partial index in place to preserve active-booking lookup performance.

### Observability
- Severity: MED
- Owner agent: `@Observability`
- Exact files:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:441`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/qicard_payment_create/index.ts:54`
- Fix recommendation:
  - Add a request-scoped correlation ID before booking creation so rejected attempts are traceable even when no booking row exists yet.

### Docs / Reference Integrity
- Severity: MED
- Owner agent: `@SlineDocs`
- Exact files:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md:1428`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md:1964`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Booking Feature.md:12`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/Sline_Log.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/MVP_ROADMAP.md`
- Fix recommendation:
  - Rule description docs are current.
  - Add changelog and execution-log linkage for this migration scope.

## C) Fix Plan (Ordered, Step-by-Step)

### Step 1 — Roll out the DB rule everywhere
- Owner: `@Supabase_Ops`
- What to do:
  - Apply `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql` to every remaining environment.
- Verification checklist:
  - Confirm `public.uq_bookings_active_task_client` is absent.
  - Confirm `public.idx_bookings_task_client_active` exists.
  - Confirm `public.rpc_create_booking_draft_validated(uuid,text,text,jsonb)` no longer raises `BOOKING_ALREADY_EXISTS_FOR_CLIENT`.

### Step 2 — Keep the client copy aligned with the server contract
- Owner: `@Architect`
- What to do:
  - Retain the neutral fallback message in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:89` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:120`.
- Verification checklist:
  - `flutter analyze lib/features/booking/viewmodels/booking_view_model.dart test/unit/booking/booking_view_model_test.dart`
  - `flutter test test/unit/booking/booking_view_model_test.dart`

### Step 3 — QA downstream repeated-booking behavior
- Owner: `@Sentinel`
- What to do:
  - Verify provider dashboards, booking lists, details screens, and notifications behave correctly when one client creates multiple active slotless bookings on the same task.
- Verification checklist:
  - Create two slotless bookings for the same `task_id` as the same client.
  - Confirm both appear and can be distinguished by `booking.id`.
  - Confirm provider-side views do not collapse them into one row.

### Step 4 — Improve create-attempt correlation
- Owner: `@Observability`
- What to do:
  - Add request-scoped correlation before the RPC call so failures before draft creation are traceable.
- Verification checklist:
  - Failed create attempt logs include the same request correlation in client and edge-function traces.

### Step 5 — Record the change in project history
- Owner: `@SlineDocs`
- What to do:
  - Add a `Sline_Log.md` entry and link the relevant `.TODO` review artifacts.
  - Optionally add a brief roadmap note.
- Verification checklist:
  - Paths in the changelog entry resolve.
  - The migration path and affected DB objects are named explicitly.

### Step 6 — Gate rerun after follow-up work
- Owner: `@CodeGuard`
- What to do:
  - Re-run focused review if Step 4 or Step 5 introduces code/doc changes.
- Verification checklist:
  - No new blockers.
  - Analyzer/tests still pass.

## D) Regression Checklist
- Critical flows list:
  - Repeat slotless booking create on iPhone.
  - Repeat slotless booking create on Chrome.
  - Provider receives and views multiple active bookings from the same client on the same task.
  - Payment draft creation still returns a distinct `booking_id` for each attempt.
- How to test quickly:
  1. Use one booking task that supports slotless direct bookings.
  2. Create a first booking as the client.
  3. Without canceling the first booking, create a second booking for the same task as the same client.
  4. Verify both bookings exist in DB and UI.
  5. Verify no `BOOKING_ALREADY_EXISTS_FOR_CLIENT` error appears.

## E) Rollback Notes
- DB rollback:
  - Recreate the old unique partial index `uq_bookings_active_task_client` and restore the duplicate-check branch inside `public.rpc_create_booking_draft_validated(...)`.
  - Risk:
    - Any newly created duplicate slotless bookings would need manual handling before reapplying the old uniqueness rule.
- App rollback:
  - Revert the neutral fallback copy in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart` only if the DB rule is also restored.
- Operational rollback trigger:
  - Provider dashboards or downstream workflows prove they cannot handle multiple active bookings for the same task-client pair.

## Next Actions
1. Retry the same direct booking flow on iPhone and Chrome in the now-updated environment.
2. Run the provider/client multi-booking QA listed above.
3. Decide whether to schedule the observability correlation improvement as a small follow-up patch.
