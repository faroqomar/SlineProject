# Observability — Bookin — 2026-02-28

## Correlation IDs

- Create: `booking:<booking_id>:create`
- Recover: `booking:<booking_id>:recover`
- Refund: `booking:<booking_id>:refund`

## Audit Sink

- Table: `public.booking_payment_audits`
- Key fields:
  - `booking_id`
  - `event_type`
  - `correlation_id`
  - `actor_user_id`
  - `outcome`
  - `payload`
  - `created_at`

## Required Events

- `payment_create`
- `payment_recovery`
- `booking_decline_refund`
- `booking_cancel_unpaid`
- `refund_finalize`
- `webhook_accept`
- `webhook_reject`

## App Logging

- Booking checkout errors: `AppLogger` in `PaymentCheckoutScreen`
- Service invocation failures: `AppLogger` in `QiCardPaymentService`
- ViewModel booking action failures: `AppLogger` in `BookingViewModel`
