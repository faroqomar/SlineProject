# SLine Payment & Ledger System Architecture Report

## 1. Current State Analysis

**Schema & Tables**
- **Wallets:** We currently utilize a single-sided `wallet_transactions` table with a `type` enum (`deposit`, `escrow_hold`, `escrow_release`, `payment_in`, `refund`, `withdrawal`). 
- **Balances:** Handled via a Postgres view (`wallet_balances`) that aggregates transactions by user, separating `available_balance` and `held_balance`.
- **Primary Entities:** `bookings` and `task_requests` are the main sources of financial events. `bookings` has a `payment_status` (`unpaid`, `held`, `released`, `refunded`).
- **RPCs:** The `process_payment_event` RPC handles the heavy lifting, taking `p_type` (`escrow`, `release`, `refund`) and creating corresponding `wallet_transactions`.

**Payments & Booking Flow**
In the client code (`BookingService`), when a booking is created, the system calls `process_payment_event` with `escrow`. Upon provider approval, it calls `release`. Upon decline, it calls `refund`.
The `PaymentService` interface exists but currently uses a `DemoPaymentService` that merely delays and succeeds, without true external ledger (Stripe) syncing.

**Dashboard Counters**
Currently, `DashboardCounters` inside `DashboardRepository` derives values directly from counting the active status of `WorkItem` components (e.g., active, done, pending) and inbox offers. It does *not* derive Gross Merchandise Value (GMV), Revenue, or global Escrow amounts from the ledger.

---

## 2. Gaps vs. Global Standard Double-Entry Ledger

To achieve a production-grade, compliance-ready financial engine, the following gaps need to be addressed:

1. **Single-Sided Transactions:** `wallet_transactions` records amounts with a loose `isPositive` or type-based directional approach. A true double-entry system requires atomic multi-line `journal_entries` that balance to exactly zero (Debit = Credit) across established Accounts.
2. **Missing Chart of Accounts:** There are no formal System Accounts (e.g., "Main Escrow Bank", "SLine Revenue", "User Wallet").
3. **Idempotency:** The `process_payment_event` RPC lacks an idempotency key parameter. A network retry could technically double-charge or double-release funds if the status guard isn't wrapped in a strict serializable transaction block.
4. **Lack of Immutability / Audit Trail:** While the system prevents updates to `wallet_transactions` via RLS, a standard ledger requires a strict append-only guarantee at the database trigger level and a robust audit log tying every journal entry to a triggering action.
5. **Dashboard Financial Isolation:** Dashboard metrics (like GMV or Total Revenue) must be derived from the ledger (System Accounts), not by summing `tasks.price`. Summing entity prices leads to drift if refunds or partial payments happen.

---

## 3. Execution Plan (Phases to Refactor)

### Phase 1: Database Foundation
1. **Chart of Accounts:** Create an `accounts` table (id, type: liability, asset, revenue, owner_id) to represent User Wallets, System Escrow, and System Revenue.
2. **Ledger Tables:** Create `journal_entries` (id, description, entity_id, idempotency_key) and `ledger_lines` (journal_id, account_id, amount, direction: DEBIT/CREDIT).
3. **Idempotency:** Add unique constraints on `(entity_id, event_type, idempotency_key)`.

### Phase 2: RPC Migration
1. **Refactor `process_payment_event`:** Rewrite this function to insert into `journal_entries` and `ledger_lines` instead of `wallet_transactions`. The function MUST ensure `SUM(DEBIT) = SUM(CREDIT)`.
2. **Balance Materialization:** Update the `wallet_balances` view to compute balances using `ledger_lines` mapped to User Asset accounts vs Escrow Liability accounts. Keep the interface identical so the Flutter frontend doesn't break.

### Phase 3: Dashboard & Metrics Integration
1. **Financial Views:** Create new views (`vw_financial_metrics`) that aggregate System Revenue accounts for SLine earnings, and System Escrow accounts for total outstanding escrow.
2. **Update Admin/Dashboard Repositories:** Point GMV, Revenue, and Escrow dashboard numbers to query these new robust ledger views rather than iterating over tasks manually.

### Phase 4: Application Layer Hardening
1. **Pass Idempotency Keys:** Update `BookingService.dart` to securely generate and pass idempotency UUIDs for every payment RPC call.
2. **Payment Gateway Webhooks:** Implement the true Stripe/Payment handler that acts as the single entry point triggering the ledger `deposit` / `withdraw` events.

---

## 4. Payment Event Matrix (Double-Entry Design)

This matrix defines the standard movements across the Chart of Accounts.

| Trigger Event | Booking/Payment Status | Debit (Money leaving) | Credit (Money arriving) | Description |
| :--- | :--- | :--- | :--- | :--- |
| **External Deposit** | N/A | External Bank (Asset) | User Auth Wallet (Liability) | User tops up their wallet via Stripe. |
| **Escrow** | `unpaid` ➔ `held` | User Auth Wallet (Liability) | System Escrow (Liability) | Client books a task; funds move to escrow. |
| **Release** | `held` ➔ `released`| System Escrow (Liability) | Provider Wallet (Liability) + SLine Revenue (Equity) | Provider completes task. Platform takes commission, remainder goes to Provider. |
| **Refund** | `held` ➔ `refunded`| System Escrow (Liability) | User Auth Wallet (Liability) | Provider declines task or dispute won by client. Escrow returned to client. |
| **Withdrawal** | N/A | Provider Wallet (Liability) | External Bank (Asset) | Provider cashes out earnings. |

*Note: From the platform's perspective, User Wallets are liabilities (money owed to users).*

---

## 5. Dashboard Metrics Definitions

To ensure a single source of truth, all financial dashboard metrics must be strictly defined by Ledger Queries:

- **Gross Merchandise Value (GMV):** The total sum of all `Escrow` events initiated in the ledger over a given time frame.
- **Total Revenue (Earnings):** The total sum of Credits applied to the `SLine Revenue` account.
- **Escrow Outstanding:** The current real-time balance of the `System Escrow` account (Credits minus Debits).
- **Available Liquidity:** The current total balance of the `External Bank` asset account holding actual fiat.
- **Refund Rate:** The total sum of `Refund` events divided by the GMV over a given time frame.
- **Platform Take Rate:** Total Revenue divided by Gross Merchandise Value (GMV).

By adhering strictly to these double-entry queries, the frontend application avoids schema drift and guarantees that dashboard numbers legally match the payments ledger.
