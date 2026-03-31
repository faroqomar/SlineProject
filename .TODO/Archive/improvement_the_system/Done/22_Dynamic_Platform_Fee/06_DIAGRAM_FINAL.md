# Final Improved Diagram (Production Grade)

The improved version includes:

1. **Idempotency checks** (standard in SLine ledger).
2. **Actor validation** (Client vs System).
3. **Explicit audit logging**.
4. **Resiliency** (handling missing rates).

```mermaid
sequenceDiagram
    participant Admin as Admin Dashboard
    participant DB as Postgres (platform_settings)
    participant C as Client
    participant RPC as Ledger RPC (Security Definer)
    participant Ledger as ledger_lines (Append-Only)

    Note over Admin, DB: Phase 0: Policy Setup
    Admin->>DB: UPDATE platform_settings SET fee_rate_bps=1200
    Note right of DB: Logged in admin_logs

    Note over C, RPC: Phase 1: Escrow (Locking)
    C->>RPC: process_payment_event_ledger(escrow_hold, booking_id, idem_key)
    RPC->>RPC: Check Idempotency
    RPC->>DB: SELECT fee_rate_bps FROM platform_settings
    DB-->>RPC: 1200 bps
    RPC->>DB: UPDATE bookings SET fee_rate_applied=1200, status='paid_request_pending'
    RPC->>Ledger: INSERT DEBIT client_available, CREDIT platform_escrow
    RPC-->>C: OK (Fee locked at 12%)

    Note over Admin, DB: Global Rate Change
    Admin->>DB: UPDATE platform_settings SET fee_rate_bps=1500
    Note right of DB: Future bookings get 15%

    Note over C, RPC: Phase 2: Release (Enforcement)
    C->>RPC: process_payment_event_ledger(release_with_fee, booking_id, idem_key2)
    RPC->>RPC: Check Idempotency
    RPC->>DB: SELECT gross_amount, fee_rate_applied FROM bookings
    DB-->>RPC: gross=100k, fee_rate_applied=1200 (NOT 1500)

    RPC->>RPC: fee = floor(100k * 1200 / 10000) = 12k
    RPC->>RPC: net = 100k - 12k = 88k

    RPC->>DB: UPDATE bookings SET fee_amount=12k, net_amount=88k, status='completed'
    RPC->>Ledger: INSERT DEBIT platform_escrow(100k)
    RPC->>Ledger: INSERT CREDIT freelancer_available(88k)
    RPC->>Ledger: INSERT CREDIT platform_revenue(12k)

    RPC-->>C: Success
```
