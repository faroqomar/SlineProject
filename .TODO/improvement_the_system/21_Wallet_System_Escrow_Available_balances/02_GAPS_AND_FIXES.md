# Gaps and Fixes: Wallet System Audit

## 1. Architectural Gaps

### GAP-01: Outdated Transaction Model

- **Diagram**: Points to `wallet_transactions` table.
- **Reality**: `wallet_transactions` is frozen (RLS trigger `trg_wallet_transactions_freeze`).
- **Fix**: Update all components to reference the multi-table ledger: `accounts`, `journal_entries`, and `ledger_lines`.

### GAP-02: Non-Atomic State Transitions

- **Diagram**: Shows `TAP "Pay"` calling an RPC immediately.
- **Reality**: Payment (escrow hold) is often asynchronous (QiCard redirects, webhooks).
- **Fix**: The diagram must include the "payment session" state (`paid_request_pending`) and the transition from unpaid to held through the recovery or webhook logic.

### GAP-03: Missing Platform Revenue Entity

- **Diagram**: Briefly mentions "Revenue event" but doesn't show where money goes.
- **Reality**: `process_payment_event_ledger` explicitly credits `platform_revenue` account.
- **Fix**: Add a platform revenue account as a first-class participant in the release flow.

---

## 2. Security & Safety Gaps

### GAP-04: Lack of Double-Spend Protection (Idempotency)

- **Diagram**: No mention of idempotency.
- **Reality**: `SUPABASE_SETUP.md:1847` shows digest-based idempotency keys used in `process_payment_event_ledger`.
- **Fix**: Explicitly show `idempotency_key` generation and check in the RPC sequence.

### GAP-05: Missing Auth Context check

- **Diagram**: Implies anyone can call "Approve delivery".
- **Reality**: RPCs must check `auth.uid() == client_id`.
- **Fix**: Add guard clauses to the sequence diagram showing participant verification.

---

## 3. Operational Gaps

### GAP-06: No Auditability of Financial Events

- **Diagram**: No mention of logs.
- **Reality**: `journal_entries` has a `meta` field for debug info, and `admin_logs` track high-level actions.
- **Fix**: Include the journal entry header as an audit link between the booking and the ledger lines.
