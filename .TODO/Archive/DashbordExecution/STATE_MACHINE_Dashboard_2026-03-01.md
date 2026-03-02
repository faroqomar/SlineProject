# Dashboard State Machines

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Task / Offer (Tender)

- **Pending** → Award → **accepted/unpaid** (or equivalent).
- **accepted/unpaid** → Ledger hold success → **held** (or equivalent) → Pay RPC → task/request active/completed.
- Invalid: call pay without successful ledger hold; award twice; pay with ok:false from ledger.
- Failure states: ledger ok:false (insufficient_funds, status_mismatch, expired) → no transition; user sees error.

## Booking

- **paid_request_pending** → Accept → **accepted** (or confirmed); Decline → **declined**.
- **confirmed** → Cancel → must go through cancel/refund RPC → **canceled** (with ledger reversal if applicable).
- Invalid: client raw update to cancel without refund path; wrong actor for accept/decline.

## Ledger

- process_payment_event_ledger returns ok: true → client may proceed to pay_awarded_offer.
- ok: false → client must not proceed; throw and show user message (taxonomy in OBSERVABILITY).

## Kill-Switch / Disabled

- If live payment contract is unverified or disabled: award/pay entry points in UI show disabled or read-only; user sees message (e.g. "Payment temporarily unavailable").
