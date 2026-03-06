# Diagram V1: Current Conceptual Flow (High Risk)

**Skills applied**: Diagram Crafting (Mermaid), Threat Modeling (Security).

This diagram represents the "Current State" based on the documentation, highlighting the high-risk "Random Webhook" vulnerability where payments lack a server-side binding (Intent).

```mermaid
sequenceDiagram
    participant UI as Client App UI
    participant API as Backend (BFF)
    participant DB as Postgres (Supabase)
    participant GW as Payment Gateway
    participant WH as Webhook Handler

    UI->>API: Initiate Payment (entity_id)
    API->>GW: Create Session
    Note right of API: RISK: No 'Payment Intent' row created.<br/>Amount/Fees only exist in transient session.
    GW-->>API: checkout_url
    API-->>UI: Redirect to Gateway

    UI->>GW: User Pays
    GW-->>WH: Webhook: success(amount, entity_id)

    WH->>DB: Process Webhook
    Note right of WH: RISK: Webhook depends on ephemeral Gateway ID.<cr/>No internal signature to verify binding integrity.

    WH->>DB: RPC process_payment_event_ledger(...)
    DB-->>WH: OK
    Note right of DB: Payment finalized without intent audit trail.
```

### Risk Critical Path

1.  **Missing Intent**: No way to verify if the amount paid is what the server _expected_.
2.  **No Ledger Link**: The `ledger_lines` don't point back to a specific payment request, only to the entity (booking/task).
3.  **Traceability Gap**: If a payment fails to update the DB, there is no "Intent" row to reconcile against.
