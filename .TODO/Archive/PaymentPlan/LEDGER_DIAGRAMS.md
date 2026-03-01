# PAYMENT LEDGER SYSTEM - DIAGRAM PACK

## 1. Master Poster (Component, Read/Write, Cutover)

Provides an eagle-eye view of app inputs descending down past validation layers to the ledger.

```mermaid
flowchart TB
  subgraph APP["Flutter App"]
    UI["UI Screens"]
    WS["WalletService\n(Read Views)"]
    BS["Booking/Task Service\n(RPC Calls)"]
    DS["DashboardRepository\n(Operational + Financial)"]
    UI --> WS
    UI --> BS
    UI --> DS
  end

  subgraph SB["Supabase (DB + RPC + RLS)"]
    RPC["RPC Engine\nprocess_payment_event_ledger"]
    LOCK["Row Lock\nSELECT ... FOR UPDATE"]
    GATE["Gate Validation\n(status + payment_status + actor)"]
    FUNDS["Funds Check\n(prevent negative balances)"]
    IDEMP["Idempotency\nUNIQUE(idempotency_key)"]
    BAL["Balance Check\nSUM(DEBIT)==SUM(CREDIT)"]
    AUD["Write audit_logs"]
    STAT["Update Entity Status/Payment Status"]

    VWB["vw_wallet_balances_user"]
    VWA["vw_wallet_activity_user"]
    VFR["vw_financial_metrics_realtime"]
    VFP["vw_financial_metrics_period(...)"]
  end

  subgraph DATA["Core Tables"]
    ACC[(accounts)]
    JE[(journal_entries)]
    LL[(ledger_lines)]
    ENT[(bookings / task_requests / withdrawal_requests)]
    ALOG[(audit_logs)]
    LEG[(legacy wallet_transactions)]
  end

  BS -->|"RPC (event + idempotency_key)"| RPC
  RPC --> LOCK --> GATE --> FUNDS --> IDEMP --> BAL
  BAL --> JE
  BAL --> LL
  BAL --> AUD --> ALOG
  BAL --> STAT --> ENT

  WS -.-> VWB --> JE
  WS -.-> VWA --> LL
  DS -.-> VFR --> ACC
  DS -.-> VFP --> ACC

  LEG -. "Phase E Backfill" .-> JE
  LEG -. "Freeze Writes" .-> LEG
```

---

## 2. Entity Relationship Diagram (ERD)

Illustrates how the ledger is isolated securely from UI models. Notice the distinct coverage (no generic tasks).

```mermaid
erDiagram
  ACCOUNTS ||--o{ LEDGER_LINES : "account_id"
  JOURNAL_ENTRIES ||--o{ LEDGER_LINES : "journal_entry_id"

  BOOKINGS ||--o{ JOURNAL_ENTRIES : "related_entity"
  TASK_REQUESTS ||--o{ JOURNAL_ENTRIES : "related_entity"
  WITHDRAWAL_REQUESTS ||--o{ JOURNAL_ENTRIES : "related_entity"
  JOURNAL_ENTRIES ||--o{ AUDIT_LOGS : "journal_entry_id"

  ACCOUNTS {
    uuid id PK
    text account_code "e.g. user_available:{user_id}"
    text account_type "asset | liability | revenue | expense | equity"
    uuid owner_id "nullable; auth.users ID"
    text currency
  }

  JOURNAL_ENTRIES {
    uuid id PK
    text idempotency_key "UNIQUE"
    text event_type
    text related_entity_type "booking | task_request | withdrawal_request | admin_adjustment"
    uuid related_entity_id
    text currency
  }

  LEDGER_LINES {
    uuid id PK
    uuid journal_entry_id FK
    uuid account_id FK
    text direction "DEBIT | CREDIT"
    numeric amount
  }

  WITHDRAWAL_REQUESTS {
    uuid id PK
    uuid user_id
    text status "requested | processing | completed | failed | canceled"
    numeric amount
    text currency
  }

  AUDIT_LOGS {
    uuid id PK
    uuid actor_user_id
    text action
    text related_entity_type
    uuid journal_entry_id
  }
```

---

## 3. General Sequences (Deposit, Escrow, Release, Refund)

### Event: Deposit (Top-up) & Escrow Hold

```mermaid
sequenceDiagram
  participant UI as App Client
  participant Webhook as Stripe Webhook
  participant RPC as RPC Engine
  participant ENT as Bookings / Tasks
  participant Ledger

  Note over UI, Ledger: Event: Flat Deposit (Webhook is Source of Truth)
  Webhook->>RPC: process_payment_event_ledger(deposit)
  RPC->>Ledger: Debit platform_cash / Credit user_available
  RPC-->>Webhook: Return 200

  Note over UI, Ledger: Event: Escrow Hold (Booking)
  UI->>RPC: process_payment_event_ledger(escrow_hold)
  activate RPC
  RPC->>ENT: Lock Entity Row for Update
  RPC->>RPC: Validate Gates (status, payment_status, actor)
  RPC->>RPC: Check Funds (user_available >= amnt)
  RPC->>Ledger: Enforce Idempotency
  RPC->>Ledger: Insert Balanced Lines (Debit user_available, Credit platform_escrow)
  RPC->>ENT: Update payment_status = 'held'
  RPC-->>UI: End Tx (Return state)
  deactivate RPC
```

### Event: Release with Fee & Refund

```mermaid
sequenceDiagram
  participant UI as App Client
  participant RPC as RPC Engine
  participant ENT as Bookings / Tasks
  participant Ledger

  Note over UI, Ledger: Event: Release With Fee
  UI->>RPC: process_payment_event_ledger(release_with_fee)
  activate RPC
  RPC->>ENT: Lock Entity Row
  RPC->>RPC: Validate Gate (status=delivered, payment_status=held, actor)
  RPC->>Ledger: Insert Balanced Lines (Debit escrow, Credit user_available, Credit platform_revenue)
  RPC->>ENT: Update payment_status = 'released', status = 'completed'
  RPC-->>UI: End Tx
  deactivate RPC

  Note over UI, Ledger: Event: Refund / Decline
  UI->>RPC: process_payment_event_ledger(refund)
  activate RPC
  RPC->>ENT: Lock Entity Row
  RPC->>RPC: Validate Gate (payment_status=held, actor)
  RPC->>Ledger: Reverse lines (Debit escrow, Credit user_available)
  RPC->>ENT: Update status according to business rule (e.g. canceled, expired_unanswered), payment_status = 'refunded'
  RPC-->>UI: End Tx
  deactivate RPC
```

### Event: Withdrawal Flow (Request & Webhook Resolutions)

```mermaid
sequenceDiagram
  participant UI as App Client
  participant WREQ as withdrawal_requests
  participant RPC as RPC Engine
  participant Webhook as Stripe Webhook
  participant Ledger

  Note over UI, Ledger: Part 1: Withdrawal Request
  UI->>RPC: request_withdrawal()
  RPC->>WREQ: INSERT status = 'requested' (Locks funds)
  RPC->>Ledger: process_payment_event_ledger(withdrawal_request): Debit user_available, Credit user_pending_withdrawal

  Note over UI, Ledger: Part 2: Webhooks Dictate Outcome
  Webhook->>RPC: Event: payout.paid (psp_idempotency_key)
  RPC->>Ledger: process_payment_event_ledger(withdrawal_complete)
  Ledger->>Ledger: Debit user_pending_withdrawal, Credit platform_cash
  RPC->>WREQ: UPDATE status = 'completed'

  Note over UI, Ledger: Alternative: payout.failed
  Webhook->>RPC: Event: payout.failed (psp_idempotency_key)
  RPC->>Ledger: process_payment_event_ledger(withdrawal_failed)
  Ledger->>Ledger: Debit user_pending_withdrawal, Credit user_available
  RPC->>WREQ: UPDATE status = 'failed'
```

---

## 4. Entity Payment State Machine

Highlights the allowed execution events gated by `payment_status` and operational `status`.

```mermaid
stateDiagram-v2
  [*] --> Unpaid : Entity Created

  Unpaid --> Held : Event: escrow_hold
  Note right of Held: Gates ensure funds & actor

  Held --> Delivered : Operational Status Update
  Note right of Delivered: Work submitted, pending approval

  Delivered --> Released : Event: release_with_fee
  Note right of Released: Requires status = 'delivered' & payment_status = 'held'

  Held --> Refunded : Event: refund
  Note right of Refunded: Requires validation of cancelation rules

  Released --> [*]
  Refunded --> [*]
```

---

## 5. Idempotency Flow

Depicts the absolute isolation mechanism inside the core engine protecting against duplicity.

```mermaid
graph TD
  START[Incoming process_payment_event_ledger] --> HAS_KEY{Has idempotency_key?}
  HAS_KEY -- No --> ERR1(Throw Missing Key Error)

  HAS_KEY -- Yes --> LOCK[BEGIN TX\nSELECT FOR UPDATE on Target Entity]
  LOCK --> GATE{Gate Validation\nstatus + payment_status + actor}
  GATE -- No --> ERR2(State Error\nROLLBACK)

  GATE -- Yes --> FUNDS{Funds Check\nSufficient balance?}
  FUNDS -- No --> ERR3(Insufficient Funds\nROLLBACK)

  FUNDS -- Yes --> IDEMP{Key exists in\njournal_entries?}
  IDEMP -- Yes --> SUCCESS_NOOP(Return Success\nNo DB Write)

  IDEMP -- No --> WRITE[Insert journal + ledger_lines]
  WRITE --> BAL{Balance Check\nSUM DEBIT == SUM CREDIT?}
  BAL -- No --> ERR4(Unbalanced Journal\nROLLBACK)

  BAL -- Yes --> AUD[Insert audit_logs]
  AUD --> UPDATE[Update entity status/payment_status]
  UPDATE --> COMMIT[COMMIT TX]
  COMMIT --> OK[Return Success]
```
