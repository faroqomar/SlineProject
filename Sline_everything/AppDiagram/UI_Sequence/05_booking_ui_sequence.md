# 8.9 Booking Flow

## Purpose

Clients browsing a freelancer's availability and checking out a booking slot. The flow uses the server-backed QiCard booking draft, sanitized return URLs, app-held pending context, payment-intent realtime where available, and dashboard/list refresh after recovery.

## Sequences

### Booking & Checkout Flow

```mermaid
sequenceDiagram
    participant Client
    participant BookingDetails
    participant BookingVM
    participant PaymentSvc
    participant WebView
    participant Return
    participant Dashboard
    participant DB
    participant QiCard

    Client->>BookingDetails: Tap "Book Basic"
    BookingDetails->>BookingVM: createPaymentForBooking(task/package/note)
    BookingVM->>PaymentSvc: qicard_payment_create(...)
    PaymentSvc->>DB: create validated draft + payment_intent
    DB-->>PaymentSvc: booking_id + intent_id
    PaymentSvc->>QiCard: create session with additionalInfo IDs
    QiCard-->>PaymentSvc: form_url
    PaymentSvc-->>BookingVM: booking_id + form_url + intent_id

    BookingVM-->>WebView: Open PaymentWebViewScreen + intent stream
    Client->>QiCard: Process Payment in WebView

    alt Payment Success
        QiCard->>PaymentSvc: Webhook with additionalInfo IDs
        PaymentSvc->>DB: verify intent, post gateway escrow, mark held
        DB-->>WebView: Realtime intent status succeeded
        WebView-->>BookingVM: Sanitized PaymentReturnArgs(SUCCEEDED)
        BookingVM->>DB: recoverBookingPaymentWithRetries(...)
        BookingVM->>Dashboard: Refresh Bookings/Work lists
        BookingVM-->>Client: Success/pending/retry state
    else Sanitized callback before realtime
        QiCard-->>Return: payment_return=1 + status only
        Return->>BookingVM: Resolve trusted pending context
        BookingVM->>DB: recoverBookingPaymentWithRetries(...)
        BookingVM-->>Dashboard: Refresh dashboard/list buckets
    else Payment Cancelled
        WebView-->>BookingVM: CANCELED / recoverable state
        BookingVM-->>Dashboard: Terminal draft shown outside active/upcoming buckets
    end
```

## State Rules

- Overlapping bookings logically blocked via `fn_reject_overlapping_slots` GiST indexes in DB.
- Payment intents explicitly tracked in `payment_intents` and `orphan_payments` for hardened ledger sync.
- Booking Status Transitions: `pending` -> `paid_request_pending` -> `active` -> `delivered` -> `completed` / `disputed`. Enforced by DB Trigger `fn_booking_guard`.
- Customer-facing payment return URLs must not expose booking, payer, entity, intent, or correlation metadata. Technical identifiers stay in Edge `additionalInfo`, logs, and support tooling.
- Success, pending, failed, canceled, retry, and recovery paths must refresh the source route plus Dashboard Bookings/Work buckets. Terminal drafts must not appear as active/upcoming bookings unless the lifecycle contract explicitly allows it.

## Screen Details

- **PaymentWebViewScreen**: Acts as a secure wrapper for QiCard, trusted callback validation, realtime intent completion, retry/back behavior, and sanitized return arguments.
- **PaymentReturnScreen**: Resolves sanitized web callbacks by using `PaymentPendingStore` or trusted app-held state, then triggers recovery.
- **Dashboard Bookings / Work**: Must be refreshed after held recovery and checked during QA for success, pending, failed, canceled, retry, and recovery states.
