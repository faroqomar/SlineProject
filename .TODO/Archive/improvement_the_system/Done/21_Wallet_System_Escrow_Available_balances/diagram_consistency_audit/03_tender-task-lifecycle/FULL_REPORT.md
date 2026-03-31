# FULL REPORT: 03 Tender Task Lifecycle

## 0) Skill Selection

- **Skills selected**: State Machine & Lifecycle, Invariants & Contracts, DB-First Financial Modeling, Idempotency & Concurrency, Diagram Crafting.
- **Why these fit**: Captures complex task state gates (`open`, `assigned`, `in_progress`), linked to payment events (double-entry ledger rules). Optimistic concurrency safeguards the acceptance mechanism.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/03_tender-task-lifecycle`
- **What system/feature it describes**: Complete state machine for a client-posted task (`tender`), bidding, assignment, payment escrow, delivery, and resolution.
- **Entities involved**: `tasks`, `task_requests` (bids), `accept_task_request` (RPC), `process_payment_event_ledger`, `gateway_escrow`.

## 2) Human Explanation

A Client posts a task (`open`). Freelancers submit bids (`task_requests`). When the Client accepts a bid, `accept_task_request` locks the price via an optimistic concurrency check and marks the task `assigned`. The Client must pay the agreed amount. When the `gateway_escrow` payment payload clears via `process_payment_event_ledger`, the ledger creates double-entry records and updates the task to `in_progress`. The Freelancer delivers the work. The Client approves, triggering `release_with_fee`, moving the task to `closed`. If the Client doesn't pay in `assigned` mode, a cron job removes the freelancer lock and returns the task to `open`. Any post-escrow cancellation must flow through dispute/change requests for a ledger `refund`.

## 3) Symbol Legend

- **Circles/Rounded Rectangles**: Task status ENUMs or CHECK constraints.
- **Solid Arrows**: State transitions triggered by users.
- **Dashed Arrows**: Automated Cron or Webhook transitions.
- **Diamonds**: Payment validation blocks.

## 4) Extracted Contracts & Invariants

1. **Status Constraint Rule**: `tasks.status` strictly follows `('open', 'assigned', 'closed', 'in_progress', 'canceled')`.
2. **Escrow Gateway Constraint**: Transition from `assigned` to `in_progress` MUST only happen via successful ledger escrow.
3. **Acceptance Lock**: `accept_task_request` RPC transitions both `task_requests` to `accepted` and `tasks` to `assigned`.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: "Accepted" vs "Assigned". `tasks.status` is `assigned`, while `task_requests.status` is `accepted` and `payment_status` is `held` to become `in_progress`.
- **Resolution**: Use `assigned` strictly for pre-payment locks. `in_progress` implies escrow successfully held.

### 5.2 Logic Drift

- **Conflict**: Client could cancel an `in_progress` task freely in historical versions.
- **Resolution**: Direct DB updates for cancellation check if `payment_status` is unheld. If held, cancellation requires dispute pathways.

### 5.3 Data Model Drift

- **Conflict**: Payment logic used deprecated `process_payment_event`.
- **Resolution**: Updated to `process_payment_event_ledger` handling `gateway_escrow`.

## 6) Security & Failure Modes (Adversarial)

- **Concurrent Offer Tampering**: Freelancer updates bid price just before Client clicks Accept. _Mitigation_: `accept_task_request` enforces an `expected_price` check (optimistic lock).
- **Abandoned Tasks**: Client accepts bid but never pays. _Mitigation_: Cron job wipes unpaid `assigned` tasks.
- **Duplicate Payout**: Double-clicking "approve delivery". _Mitigation_: Ledger idempotency keys reject duplicate `release_with_fee`.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Task Feed, Task Detail, Payment WebView.
- **States**: View Bids, Pending Payment, Work Started, Delivered, Complete.
- **Guardrails**: Freelancer UI locks while in `assigned`. Hide "Submit Delivery" button unless `in_progress`.

### 7.2 Admin Dashboard UI

- **Pages**: Active Tasks, Payment Reconciliation.
- **Metrics**: Count of `assigned` but unpaid tasks waiting for the cron job.
- **Drilldowns**: Deep link from Task ID -> Ledger Entries.

### 7.3 Implementation Hooks

- `TaskService.acceptOffer()` -> `rpc('accept_task_request')`.
- Payment Service -> `edge/qicard_webhooks` -> `process_payment_event_ledger`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10
- **Best Diagram Type**: State Diagram (StateDiagram-v2 in Mermaid) clearly defines the strictly gated status loops and failure dead-ends.

## 9) Upgrade Plan

- **Phase 0: Observability**: Log all status shifts caused by API vs Webhook.
- **Phase 1: Contracts**: Enforce the expected price logic in the RPC. Block `in_progress` cancellations.
- **Phase 2: Hardening**: Deploy the unpaid `assigned` expiry Cron.
- **Phase 3: Database**: Ensure idempotency on all Webhook deliveries.

## 10) Risks

### 10.1 Risks if current version kept

- **Assigned Freeze**: Freelancers get starved waiting endlessly for unpaid clients.

### 10.2 Risks introduced by fixes

- **Optimistic Concurrency Fails**: Clients might occasionally see "Price changed" errors. _Mitigation_: Good UI error tracking.

## 11) Test Plan (High-value)

- **Integration**: Send bid, accept bid, wait for Cron, assert task becomes `open`.
- **Unit (RPC)**: Attempt to accept an offer with mismatched price param, expect Exception.

## 12) Production Checklist

- [ ] Optimistic lock logic in `accept_task_request`.
- [ ] Cron job for unpaid `assigned` tasks runs hourly.
- [ ] Dispute refund triggers properly redirect to Ledger API.
