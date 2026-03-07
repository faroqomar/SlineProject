# Gaps and Fixes: Ledger Event Flow

## 1. Diagram Gaps (Visual & Structural)

### 1.1 Missing Lifecycle Events

- **Gap**: The original diagram only covers `escrow_hold`, `release_with_fee`, and `refund`. It misses the entry point for external payments (`gateway_escrow`) and exit points (`withdrawal_request`).
- **Fix**: Expand the Mermaid diagram to include a "Gateway" trigger and a "Withdrawal" trigger.

### 1.2 Idempotency Awareness

- **Gap**: The flow implies a synchronous call but doesn't show the `idempotency_key` as a mandatory contract.
- **Fix**: Add an explicit step showing the key generation via UUIDv5/Digest before calling the RPC.

### 1.3 State Guarding

- **Gap**: The diagram shows triggers blindly calling the RPC. In reality, the RPC has internal "GATES" (validation logic).
- **Fix**: Add a "Gate Verification" node within the RPC block to represent logic like `ERR_GATE_NOT_ALLOWED`.

---

## 2. System/Implementation Gaps

### 2.1 Admin Traceability

- **Problem**: While the ledger is immutable, manual adjustments by support staff (e.g., fee waiving after a release) are not explicitly typed in the diagram.
- **Fix**: Define an `admin_adjustment` event type in the `payment_event_type_enum` (if not already present) and document its flow.

### 2.2 Error Recovery in Code

- **Problem**: `WalletService.requestWithdrawal` has a manual cleanup block if the ledger fails. This is a "two-phase commit" problem.
- **Fix**: Recommend that the `withdrawal_request` insertion and the `ledger_event` call be wrapped in a single database transaction or a more robust state machine that handles the `failed` state automatically via a watcher.

### 2.3 Real-time Observability

- **Problem**: Users only see the "final" balance. There's no "pending" state shown in the ledger lines specifically for long-running gateways.
- **Fix**: Ensure `gateway_escrow` creates a line in a `transition` account before moving to `escrow` to handle asynchronous QiCard webhooks.
