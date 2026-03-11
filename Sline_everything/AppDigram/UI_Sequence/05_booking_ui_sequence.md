# 8.9 Booking Flow

## Purpose

Clients browsing a freelancer's availability and checking out a booking slot. Handled securely matching QiCard payment workflows.

## Sequences

### Booking & Checkout Flow

```mermaid
sequenceDiagram
    participant Client
    participant FreelancerProfile
    participant BookingVM
    participant PaymentSvc
    participant DB
    participant QiCard

    Client->>FreelancerProfile: Tap "Book Now"
    FreelancerProfile->>BookingVM: Load Availability Slots
    BookingVM-->>Client: Show Slots Sheet

    Client->>BookingVM: Select Slot & Confirm
    BookingVM->>DB: create draft booking (status='pending')
    DB-->>BookingVM: booking_id

    BookingVM->>PaymentSvc: initiateCheckout(booking_id)
    PaymentSvc->>QiCard: create Payment Session
    QiCard-->>PaymentSvc: Payment URL

    PaymentSvc->>Client: Open PaymentWebViewScreen
    Client->>QiCard: Process Payment

    alt Payment Success
        QiCard->>PaymentSvc: Redirect to Sline specific URL scheme
        PaymentSvc->>DB: verify payment webhook & update status
        DB-->>Client: Dashboard (Work Item)
    else Payment Cancelled
        QiCard->>PaymentSvc: Redirect failure
        PaymentSvc->>Client: Show Checkout Error
    end
```

## State Rules

- Overlapping bookings logically blocked via `fn_reject_overlapping_slots` GiST indexes in DB.
- Payment intents explicitly tracked in `payment_intents` and `orphan_payments` for hardened ledger sync.
- Booking Status Transitions: `pending` -> `paid_request_pending` -> `active` -> `delivered` -> `completed` / `disputed`. Enforced by DB Trigger `fn_booking_guard`.

## Screen Details

- **PaymentWebViewScreen**: Acts as a secure wrapper handling the redirection events securely to return seamlessly back to the app routing state.
