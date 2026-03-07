# Final Improved Diagram: Direct Offers Work Contract

This diagram reflects the **production reality** of the SLine Direct Offer flow, specifically the decentralized completion path where the App triggers the Ledger directly for the `direct_offer` entity type.

```mermaid
sequenceDiagram
    autonumber
    participant F as Freelancer (App)
    participant C as Client (App)
    participant DO as direct_offers (DB)
    participant Ledger as Ledger RPC (DB)
    participant Guard as fn_direct_offer_guard (DB)

    Note over F, C: Phase 1: Creation & Acceptance
    F->>DO: createOffer(status='sent', payment='unpaid')
    DO-->>Guard: Validate initial state
    C->>DO: acceptOfferWithoutPayment(status='accepted')
    DO-->>Guard: Validate sent->accepted (unpaid)

    Note over C, DO: Phase 2: Escrow Payment
    C->>Ledger: submitPaymentEvent(escrow_hold, direct_offer, offer_id)
    Ledger->>DO: UPDATE payment_status='held', status='active'
    DO-->>Guard: Validate payment_status is held for active status

    Note over F, DO: Phase 3: Delivery
    F->>DO: markDelivered(status='delivered')
    DO-->>Guard: Validate auth.uid() is freelancer_id

    Note over C, Ledger: Phase 4: Release & Completion
    C->>Ledger: submitPaymentEvent(release_with_fee, direct_offer, offer_id)
    Ledger->>DO: UPDATE payment_status='released', status='completed'
    DO-->>Guard: Validate delivered->completed requires payment='released'

    Note right of Ledger: Platform fee deducted automatically<br/>based on bps in meta
```

### Key Improvements in this Diagram:

1.  **Removed Hallucination**: `rpc_approve_delivery` is no longer shown; instead, the direct call to `Ledger RPC` is illustrated.
2.  **Explicit Guards**: Shows the `fn_direct_offer_guard` checking transitions at every step.
3.  **Financial Reality**: Correctly shows that state transitions to `active` and `completed` are side-effects of the Ledger operations.
4.  **Role Enforcement**: Indicates where `auth.uid()` checks happen (Step 9).
