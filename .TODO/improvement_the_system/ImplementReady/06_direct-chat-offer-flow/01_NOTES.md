# 01_NOTES

## Skills Selected

- **Evidence-First Reading**: To map the diagram claims against `SUPABASE_SETUP.md` and `DirectOffersService.dart`.
- **State Machine & Lifecycle**: To trace exact state transitions (e.g., `sent` -> `accepted` -> `active` vs `pending` -> `accepted`).
- **DB-First Financial Modeling**: Because the flow involves escrow locks, releases, and potential refunds using the ledger.
- **Diagram Crafting (Mermaid)**: To produce a valid, correctly modeled visual representation.
- **Invariants & Contracts**: To list out exactly what must hold true for each state.

## Discrepancies Found

1. **Initial State Name**: The diagram uses `pending`. The DB schema and `DirectOffersService` use `sent` as the initial status. `payment_status` starts as `unpaid`.
2. **Acceptance Split**: The diagram treats acceptance and payment as distinct, which matches `acceptOfferWithoutPayment` vs `payNow`.
   - Diagram: `pending --> accepted` (Accept) then `accepted --> active` (Pay).
3. **Cancelation of Active Offers**: The diagram shows `active --> canceled (triggers refund)`. However, `DirectOffersService` has `cancelAcceptedOffer` which ONLY allows canceling if `status == 'accepted'` and `payment_status == 'unpaid'`. There is NO `cancelActiveOffer` or refund trigger from the UI service. Either this requires admin intervention, or it's a massive gap in the UI implementation.
4. **Freelancer Cancelation**: Freelancers can only cancel when `isSent`, not when it's `active`.
5. **Ledger Integration**: The transition from `accepted` to `active` is triggered via `_ledgerService.submitPaymentEvent(eventType: 'escrow_hold')`. The transition to `completed` uses `release_with_fee`.

## Financial Modeling Notes

- `payment_status_enum`: `unpaid`, `held`, `released`, `refunded`.
- When client accepts without payment: `status = 'accepted'`, `payment_status = 'unpaid'`.
- When client pays: `status = 'active'`, `payment_status = 'held'`.
- Upon completion: `status = 'completed'`, `payment_status = 'released'`.

## Gaps

- Who can cancel an `active` offer? If the client or freelancer wants to abort, how is the refund (`refund` event) triggered? Currently missing in the flutter service layer. Dispute system (`disputes` table) might be required, but it's not modeled in the diagram.
- `fn_direct_offer_guard` handles DB-level state validation, but the visual flow doesn't detail the payment_status composite states.
