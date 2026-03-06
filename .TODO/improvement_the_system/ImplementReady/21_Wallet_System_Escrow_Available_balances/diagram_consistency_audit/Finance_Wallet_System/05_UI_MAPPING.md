# 05 UI MAPPING

This document maps the heavily-guarded backend operations established by the architecture to the Flutter Client UI entry points. UI engineering must strictly match these contracts.

## 1. Client Screens

### Task / Booking / Offer Payment Checkout

- **Triggers**: User taps "Checkout" or "Accept & Pay".
- **Backend Contract**: Calls secure wrapper instructing `create_payment_intent`. App presents standard Gateway form using token returned by server wrapper.
- **Verification**: Do NOT call Supabase ledger or update booking status from the client. The Webhook callback to Supabase acts as the sole driver for status transitions (`status='active'`).
- **Displayed State**: Stream the entity from Supabase. Show a loading state until the real-time websocket updates the row reflecting the completion broadcasted by the webhook.

### Work Delivery Review

- **Triggers**: User taps "Approve" on a submitted delivery screen.
- **Backend Contract**: Submits payload to `rpc_approve_delivery(entity_id, entity_type, signature_idempotency)`.
- **Important**: Ensure `entity_type` can support `direct_offer` as expected. This performs the Escrow depletion, transferring the net amount to Freelancer Available.
- **Displayed State**: Status -> `completed` on success. Automatically drops the Escrow liability from the view.

## 2. Freelancer Screens

### Balance Wallet

- **Triggers**: Screen initialization or pull-to-refresh.
- **Backend Contract**: Selects aggregate sum from `vw_wallet_balances`.
- **Displayed State**: Must correctly separate "Withdrawable / Available Balance" (cleared funds via completed deliveries) vs "Held In Escrow" (locked incoming amounts on active requests).

### Submit Withdrawal

- **Triggers**: User taps "Request Payout" inputting a balance constraint.
- **Backend Contract**: Calls `WalletService.requestWithdrawal()` matching validation constraints.
- **Verification**: Initiates `process_payment_event_ledger(withdrawal_request)`. Mints a pending balance line item to temporarily "lock" liquidity available to the user before Admin clearance.

### Availability Calendar

- **Triggers**: Provider adds schedule slot arrays.
- **Backend Contract**: Invokes `AvailabilityService` injecting `availability_slots` with precise inputs.
- **Verification**: Handled silently by backend `trg_no_overlap_slots`. The app will catch `EXCEPTION` if a booking attempt overlap happens and must map the exception string back to a clean user error UI ('Time slot taken').

## 3. Admin Dashboard

### Finance Overview

- **Triggers**: Admin navigating to `/operations/finance`.
- **Backend Contract**: Selects from `vw_admin_finance_metrics`, querying GMV, Escrows held, Fees processed, and orphan payloads identified.
- **Security restriction**: Access strictly restricted by policy referencing `admin_users` definition. Requires `Security Invoker = false` specifically elevated to a trusted role.

### Escrow Liability Drilldown

- **Backend Contract**: Reads from `payment_events`, `journal_entries` joined against bookings allowing traceability on stuck delivery loops and providing a pathway to trigger forced ledger-release functions (`rpc_admin_force_resolve`).
