# Gaps and Fixes: Direct Offers Work Contract

## 1. Lifecycle Inconsistency

- **Gap**: The original diagram assumed `rpc_approve_delivery` was used for completion. In reality, `rpc_approve_delivery` lacks branch logic for `direct_offer`.
- **Fix**: The system uses a direct Ledger event call (`release_with_fee`) from the Flutter service. The improved diagram must reflect this decentralized approach (where the Client logic in the App triggers the Ledger directly).

## 2. Missing "Approve" Step in RPC

- **Gap**: Unlike `task` and `booking`, which have a formal `rpc_approve_delivery` that updates the entity status and _then_ calls the ledger, `direct_offer` depends on the `process_payment_event_ledger` call to update its status via a side effect (the ledger function updates the entity status).
- **Fix**: Ensure the `process_payment_event_ledger` function body (as seen in Section 15 of `SUPABASE_SETUP.md`) correctly performs the update: `direct_offers.payment_status = 'released'`.
- **Observation**: The `fn_direct_offer_guard` requires `payment_status = 'released'` to allow `status = 'completed'`. This means the Ledger _must_ be the one to update the payment status.

## 3. Race Conditions in Multiple Accepts

- **Gap**: If a user double-clicks "Accept", the trigger handles state transitions, but idempotency in the Flutter service for `acceptOfferWithoutPayment` is not explicit beyond Supabase's standard behavior.
- **Fix**: Add idempotency checks or ensure the UI disables the button after the first click. (This is a UI/UX fix, but the DB guard prevents the status from moving backward).

## 4. Unclear "Pay Now" Flow

- **Gap**: The diagram shows a linear flow, but the product allows "Accept without payment" followed by a later "Pay Now" from the dashboard.
- **Fix**: The improved diagram will show the branching path: Immediate Payment vs. Deferred Payment.

## 5. Dispute Phase Missing

- **Gap**: What if the work is delivered but the client refuses to pay?
- **Fix**: The system needs a clear "Dispute" status in the `direct_offer_status` enum (if it exists) or a way to trigger a refund.
- **Evidence**: `process_payment_event_ledger` supports `refund` for `direct_offer`. This implies a dispute flow exists or is planned.
