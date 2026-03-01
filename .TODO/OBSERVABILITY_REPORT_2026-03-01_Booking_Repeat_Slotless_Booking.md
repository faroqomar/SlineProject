# Observability Report — Booking Repeat Slotless Booking

## Scope
- Feature path: slotless direct booking payment creation and server-side draft creation.
- Plan reference: MISSING. Risk elevated.
- Reviewed paths:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/qicard_payment_create/index.ts`

## Evidence
- Booking create request logs only `task_id`, `package_id`, `has_note`, and `requirements_keys`.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:441`
- QiCard service logs sanitized summaries for server rejection payloads.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart:157`
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart:388`
- Correlation IDs are logged after successful draft creation.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:468`
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/qicard_payment_create/index.ts:54`
- Logger masks token fields in structured JSON output.
  - File: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart:40`

## What To Log
- Booking create request started
  - Required fields: `task_id`, `package_id`, `has_note`, `requirements_keys_count`, `platform`
- Booking create request rejected
  - Required fields: `task_id`, sanitized `error_code`, `error_stage`, `provider=QiCard`
- Booking draft created
  - Required fields: `booking_id`, `correlation_id`, `payment_request_id`, `task_id`
- Payment create edge failure
  - Required fields: `task_id`, `booking_id` when present, `correlation_id` when present, `stage`

## What NOT To Log
- Raw booking note text
- Raw payment payloads from gateway
- Token material
- Full user email or other PII
- Full `requirements` payload values unless individually classified as safe

## Findings
### O1 — Privacy handling for this path is acceptable
- Severity: LOW
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:444`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart:388`
- Notes:
  - The flow logs note presence, not note content.
  - The QiCard service summarizes server payloads instead of dumping full raw objects.

### O2 — Rejected create attempts have no stable correlation ID before booking creation
- Severity: MED
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:441`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/qicard_payment_create/index.ts:54`
- Impact:
  - When booking creation fails before a booking row exists, support cannot correlate repeated attempts across client, edge function, and DB layers with one request-scoped ID.
- Recommendation:
  - Add a pre-create `request_correlation_id` generated at the client or edge entrypoint and include it in all create-attempt logs, success or failure.

### O3 — Event taxonomy is still message-based, not event-name-based
- Severity: LOW
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart:442`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart:158`
- Impact:
  - Console traces are readable, but harder to aggregate mechanically compared with stable event names like `booking_payment_create_rejected`.
- Recommendation:
  - Introduce stable event names in logger metadata for payment-create flows.

## Correlation Strategy
- Current:
  - Success path has booking-derived `correlation_id` once the draft exists.
- Needed improvement:
  - Add a request-scoped correlation ID before RPC invocation so failures before booking creation are traceable.

## Observability Decision
- APPROVED with follow-up.
- No privacy blocker detected for this scope.
- Recommended next telemetry improvement: request-scoped correlation for create failures.
