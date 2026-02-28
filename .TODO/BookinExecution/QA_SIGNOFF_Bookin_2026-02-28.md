# QA Sign-Off — Bookin — 2026-02-28

## Manual Staging Script

1. Create a booking task with package data and provider availability.
2. As the client, open `AvailabilityScreen`, select a slot, and continue to `PaymentCheckoutScreen`.
3. Confirm the checkout opens a server-returned `form_url`.
4. Complete the QiCard flow and return through the trusted callback host.
5. Verify either webhook or recovery moves the booking to `paid_request_pending` with `payment_status='held'`.
6. Verify the provider sees the booking and can accept it.
7. Verify provider decline on a held booking routes through `booking_decline_refund` and ends at `status='refunded'`, `payment_status='refunded'`.
8. Verify the booking details and booking list screens show the same canonical schedule/payment state after refresh.

## Automated Evidence Present

- `flutter analyze`
- `flutter test test/unit/booking test/unit/models/booking_model_test.dart`

## Remaining Automated Gaps

- Widget tests for checkout/WebView/list/detail
- Edge-function tests for create/recovery/refund/webhook
- SQL contract tests for booking and notification RLS
