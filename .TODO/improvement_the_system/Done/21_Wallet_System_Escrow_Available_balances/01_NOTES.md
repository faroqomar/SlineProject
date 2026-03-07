# Audit Notes: Wallet System Escrow & Available Balances

**Skills Selected:**

1. **Evidence-First Reading**: Used to compare diagrams with `SUPABASE_SETUP.md`.
2. **DB-First Financial Modeling**: Essential for auditing the double-entry account chart.
3. **Threat Modeling (Security)**: Checking for release/refund bypasses.
4. **Idempotency & Concurrency**: Verifying double-charge protection.
5. **Invariants & Contracts**: Mapping ledger states to booking statuses.
6. **Diagram Crafting (Mermaid)**: For the upgraded technical flow.

---

## 1. Initial Findings (Legacy vs. Truth)

### The Diagram (`21_Wallet_System...md`)

- **Entities**: Uses `wallet_transactions` table.
- **RPC**: Uses `process_payment_event`.
- **States**: Simplistic "Held" vs "Released" on a single table.
- **Evidence of Obsolescence**: `SUPABASE_SETUP.md:1459` explicitly labels `process_payment_event` as **🚨 DEPRECATED**.

### The Truth (`SUPABASE_SETUP.md`)

- **Architecture**: **Double-Entry Ledger (v2.16)**.
- **Tables**: `accounts`, `journal_entries`, `ledger_lines`.
- **Primary RPC**: `process_payment_event_ledger`.
- **Invariant**: Every event creates a Journal Entry where Sum(DR) + Sum(CR) = 0.
- **View**: `wallet_balances` (v2.16) computes sums from `ledger_lines` joined with `accounts` (Lines 964-978).

---

## 2. Core Transitions (Ledger-First)

### A. Escrow Hold (`escrow_hold`)

- **Trigger**: Client pays (via QiCard edge function).
- **Ledger Lines**:
  - `DEBIT`: `user_available:<client_id>`
  - `CREDIT`: `platform_escrow`
- **Entity Update**: `bookings.status = 'paid_request_pending'` (or `direct_offers.status = 'active'`).

### B. Release Funds (`release_with_fee`)

- **Trigger**: Client approves delivery (or auto-approval).
- **Ledger Lines**:
  - `DEBIT`: `platform_escrow`
  - `CREDIT`: `user_available:<freelancer_id>` (Net)
  - `CREDIT`: `platform_revenue` (Fee)
- **Zero-Fee Safety**: `SUPABASE_SETUP.md:1438` - Revenue line is omitted if bps is 0.

### C. Refund (`refund`)

- **Trigger**: Cancel/Decline/Dispute.
- **Ledger Lines**:
  - `DEBIT`: `platform_escrow`
  - `CREDIT`: `user_available:<client_id>`

---

## 3. Evidence Trace

- **Double-Entry Requirement**: `SUPABASE_SETUP.md:93`
- **Frozen Table Policy**: `SUPABASE_SETUP.md:556` (RLS on `wallet_transactions` prevents writes).
- **Idempotency Mechanism**: `SUPABASE_SETUP.md:1847` uses `extensions.digest` based on `entity_id` and action type.
- **direct_offer Support**: `19_direct-offers-work-contract.md:15` confirms the same ledger RPC is used.

---

## 4. Immediate Critical Gaps

1. **Diagram Sync**: The current diagram is 100% legacy and would mislead an engineer trying to implement it today.
2. **Platform Fee Source**: Where is the BPS (Basis Points) stored? Diagram doesn't show it; `SUPABASE_SETUP.md:1438` mentions it but doesn't list the config table.
3. **Admin Controls**: No visibility in the diagram for how admin corrects a failed transaction. `admin_logs` exist but aren't in the flow.
