# Final Improved Diagram: Ledger Event Flow

```mermaid
flowchart TD
    subgraph TriggerSources [Triggers & Actions]
        T1(App: Pay Booking)
        T2(App: Accept Delivery)
        T3(App: Refund/Cancel)
        T4(App: Withdraw Funds)
        T5(Webhook: QiCard Paid)
    end

    subgraph ClientLogic [Client-Side Logic]
        Idem[Generate Idempotency Key\nUUIDv5(entity + type)]
    end

    subgraph Engine [Ledger Engine (RPC)]
        direction TB
        RPC[process_payment_event_ledger]
        Gate{Gate Validation\nStatus? Balance?}
        Auth{Auth/RLS Check}
        Journal[Create Journal Entry]
        Balance[Double-Entry Check\nSum == 0]
    end

    subgraph Accounts [Ledger Accounts]
        UA[User: Available]
        PE[Platform: Escrow]
        PR[Platform: Revenue]
        PA[Provider: Available]
        PW[User: Pending Withdrawal]
    end

    %% Flow: Escrow Hold
    T1 & T5 --> Idem
    Idem --> Auth --> RPC
    RPC --> Gate --> Journal
    Journal -->|escrow_hold| UA -. DR .-> Balance
    Journal -->|escrow_hold| PE -. CR .-> Balance

    %% Flow: Release
    T2 --> Idem
    Journal -->|release_with_fee| PE -. DR .-> Balance
    Journal -->|release_with_fee| PA -. CR .-> Balance
    Journal -->|release_with_fee| PR -. CR (if fee > 0) .-> Balance

    %% Flow: Refund
    T3 --> Idem
    Journal -->|refund| PE -. DR .-> Balance
    Journal -->|refund| UA -. CR .-> Balance

    %% Flow: Withdrawal
    T4 --> Idem
    Journal -->|withdrawal_request| UA -. DR .-> Balance
    Journal -->|withdrawal_request| PW -. CR .-> Balance

    Balance -->|Success| Committed[Committed & Notified]
    Balance -->|Fail| Rollback[Transaction Rollback]
```
