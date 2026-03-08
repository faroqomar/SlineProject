# Diagram Final: Production-Grade Hardened Flow

**Skills applied**: Diagram Crafting (Mermaid), Threat Modeling (Security), Idempotency & Concurrency, DB-First Financial Modeling.

This diagram represents the "End State" with all hardening guards in place.

```mermaid
sequenceDiagram
    participant UI as Client App UI
    participant BFF as Backend (BFF)
    participant DB as Postgres (Supabase)
    participant GW as Payment Gateway
    participant WH as Webhook Handler
    participant Ledger as Ledger RPC

    %% 1. Pre-Authentication & Binding
    UI->>BFF: Pay(entity_type, entity_id, amount)
    BFF->>DB: Validate Entity Status & Payer
    Note over DB: Check if booking is 'pending_payment'<br/>or direct_offer is 'accepted'
    BFF->>DB: INSERT payment_intents (id, entity, payer, amount, signature, fee_rate)
    Note over BFF,DB: signature = HMAC(SECRET, id + entity + amount + payer)

    %% 2. Gateway Handshake
    BFF->>GW: Create Intent (metadata={payment_intent_id, signature, ...})
    GW-->>BFF: gateway_intent_id, checkout_url
    BFF->>DB: UPDATE payment_intents SET gateway_intent_id, status='gateway_created'
    BFF-->>UI: checkout_url

    %% 3. Secure Finalization (Webhook)
    UI->>GW: User Completes Payment
    GW-->>WH: Webhook: success(gateway_intent_id, metadata, amount)

    WH->>DB: INSERT payment_events (raw_payload) [Audit Trail]
    WH->>DB: SELECT * FROM payment_intents WHERE gateway_intent_id = ...

    alt VALID Intent + Valid Signatures + Amount Matches
        WH->>BFF: Verify metadata using internal HMAC(SECRET, ...)
        BFF-->>WH: Valid
        WH->>DB: BEGIN TRANSACTION
        WH->>DB: UPDATE payment_intents SET status='succeeded', paid_at=now()
        WH->>Ledger: process_payment_event_ledger(escrow_hold, ..., intent_id)
        WH->>DB: UPDATE entity SET payment_status='held', status='active'
        WH->>DB: COMMIT
    else INVALID / Tampered / Missing
        WH->>DB: INSERT orphan_payments (payload, reason='sign_mismatch')
        WH->>DB: Alert Admin
    end

    %% 4. User Notification
    DB-->>UI: Realtime: payment_intent_id updated to 'succeeded'
    UI->>UI: Show Success Screen
```

### Key Improvements

1.  **HMAC Metadata Binding**: Prevents an attacker from modifying the amount or target entity in the gateway URL (if the gateway allows modification) and ensures we only process webhooks we "signed" for.
2.  **Atomic State Machine**: Status transitions for both the intent and the entity are wrapped in a single database transaction.
3.  **Audit-First Webhook**: Every raw payload is saved to `payment_events` BEFORE processing logic.
4.  **Realtime Feedback**: Eliminated the need for manual polling.
5.  **Quarantine Path**: Formalized the `orphan_payments` table for unmatched gateway events.
