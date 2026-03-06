# FULL REPORT: 04 Task Request Bid Flow

## 0) Skill Selection

- **Skills selected**: State Machine & Lifecycle, Idempotency & Concurrency, Threat Modeling (Security), Diagram Crafting.
- **Why these fit**: Task requests (bids) have a highly volatile state. Concurrency skills help evaluate multiple freelancers bidding simultaneously. Threat modeling maps out malicious edits to a bid just before acceptance.
- **Skills not used**: DB-First Financial Modeling (handled in tender-task-lifecycle).

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow`
- **What system/feature it describes**: Freelancers discovering open tasks, submitting bids (`task_requests`), updating prices, and clients accepting or rejecting them.
- **Entities involved**: `tasks`, `task_requests` (table), `accept_task_request` (RPC).

## 2) Human Explanation

A Client's task stays open. Multiple Freelancers submit `task_requests`. Each request starts as `pending`. Freelancers can edit the price or days. A Client views the bids and clicks "Accept" on one. The backend RPC atomically marks the winning bid as `accepted`, sets the task to `assigned`, and marks all other competing bids as `rejected`. If the client clicks "Reject" manually on a bid, only that bid becomes `rejected`.

## 3) Symbol Legend

- **Circles**: Bid States (pending, accepted, rejected, withdrawn).
- **Solid Arrows**: Explicit user actions (Submit, Accept, Reject, Withdraw).
- **Diamonds**: Business rule validations (Is Task still open? Is price matching?).

## 4) Extracted Contracts & Invariants

1. **Single Winner Rule**: A task can only have ONE `accepted` task request. The RP `accept_task_request` enforces this by bulk-rejecting the rest.
2. **Open Dependency**: A `task_request` can only be inserted or updated if the parent task is still `open`.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: UI labels "Cancel", while DB schema uses "Withdrawn" vs "Rejected".
- **Resolution**: "Withdrawn" = acted upon by Freelancer. "Rejected" = acted upon by Client or System.

### 5.2 Logic Drift

- **Conflict**: Bids could theoretically be submitted when a task is `assigned` if RLS was weak.
- **Resolution**: RLS and RPCs strictly limit INSERT/UPDATE on `task_requests` where `tasks.status = 'open'`.

### 5.3 Data Model Drift

- None detected within the bid flow loop itself.

## 6) Security & Failure Modes (Adversarial)

- **Bait and Switch**: Freelancer edits the bid price lower to rank higher, then edits it higher the millisecond before the client clicks Accept.
  - _Mitigation_: The `accept_task_request` RPC takes an `expected_price` argument. If the actual current price differs, it throws an error and aborts.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Task Feed (Freelancer), Bid Submission Modal, Task Details (Client viewing bids).
- **States**: Loading, Submitted, Price Changed.
- **Guardrails**: Hide the Edit Bid button if the task is no longer open.

### 7.2 Admin Dashboard UI

- **Pages**: Task drilldown page displaying the history of all bids.
- **Metrics**: Average bids per task, bid-to-acceptance ratio.
- **Drilldowns**: View the price history of a single `task_request`.

### 7.3 Implementation Hooks

- `TaskRequestService.submitBid()` -> `from('task_requests').insert()`.
- `TaskRequestService.acceptBid()` -> `rpc('accept_task_request', { expected_price })`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10
- **Best Diagram Type**: State Diagram for the Bid Entity Lifecycle (`pending` -> `accepted` | `rejected` | `withdrawn`).

## 9) Upgrade Plan

- **Phase 0: Observability**: Track bid edits to monitor bait-and-switch attempts.
- **Phase 1: Contracts**: Enforce `expected_price` in the frontend API calls to `accept_task_request`.
- **Phase 2: Hardening**: Ensure auto-reject triggers correctly when the task times out or is canceled.

## 10) Risks

### 10.1 Risks if current version kept

- **Bait and switch fraud**: Without optimistic locking, clients can be scammed.

### 10.2 Risks introduced by fixes

- None, standard ACID compliance.

## 11) Test Plan (High-value)

- **Unit (RPC)**: Pass multiple bids, accept one, assert others are rejected.
- **Security (RLS)**: Attempt to insert a bid on an `assigned` task. Verify failure.

## 12) Production Checklist

- [ ] Optimistic price lock included in client UI parameters.
- [ ] DB trigger to reject remaining bids integrated into the Acceptance RPC.
