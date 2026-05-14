# 8.10 Orders / Work Management Flow

# 8.13 Wallet Flow

## Purpose

Unified tracking and administration of Work (Tasks, Bookings, Direct Offers) and the Ledger (Wallet Balances, Escrow logic).

## Sequences

### Unified Dashboard Flow

```mermaid
flowchart TD
    Nav[Bottom Nav] --> Dash[Dashboard Screen]
    Dash --> Overview[Overview Tab]
    Dash --> Work[Work Tab]
    Dash --> Wallet[Wallet Tab]

    Work --> DB_View[(vw_unified_work_items)]
    DB_View --> ListView[Lazy List Render]

    ListView -->|Tap Item| WorkDetails[Work Item Details Screen]

    WorkDetails -->|Freelancer Action| SubmitWork[Submit Delivery]
    WorkDetails -->|Client Action| ReviewWork[Review & Approve Delivery]
    WorkDetails -->|Client Action| Dispute[Report Issue / Dispute]
```

### Approving Delivery & Wallet Ledger Updates

```mermaid
sequenceDiagram
    participant Client
    participant DashboardVM
    participant LedgerRPC
    participant LedgerDB
    participant WalletVM

    Client->>DashboardVM: Approve Delivery
    DashboardVM->>LedgerRPC: rpc_approve_delivery(entity_type, id)

    Note over LedgerRPC: Uses FOR UPDATE stable idempotency lock
    LedgerRPC->>LedgerDB: Shift funds Escrow -> Release_with_fee
    LedgerDB-->>LedgerRPC: Success

    LedgerRPC-->>DashboardVM: UI Resolves
    DashboardVM->>WalletVM: Refresh Wallet Balances
    WalletVM-->>Client: Wallet Tab updates Escrow & Available
```

## UI State Contracts

- `vw_unified_work_items` guarantees 4 branches of tasks always map back cleanly into the `WorkItemDetails` UI safely. Fallbacks do not exist. If the DB doesn't return the row, the UI shows "Work item not found".
- Escrow actions implement strict Loading Overlays securely resolving against the ledger.
- Wallet "Withdraw" functions are marked "Coming Soon".
