# Skills Selected

- State Machine & Lifecycle
- Invariants & Contracts
- DB-First Financial Modeling
- Idempotency & Concurrency
- Diagram Crafting (Mermaid)

Why these skills: The tender task lifecycle involves strict state transitions, escrow payment dependencies, and concurrent actions (multiple freelancer bids). Financial modeling is required for the escrow to in-progress gateway constraint. Diagram crafting is critical to output the final accurate Mermaid flow.

Skills not used: Repo Mapping, Observability, Production Migration Planning, etc. The scope focuses on the exact logic flows rather than migration strategy or repo setup.

# Invariants & Contracts

1. **Status Constraint**: `tasks.status` is a `text` field with a `CHECK` constraint: `status IN ('open', 'assigned', 'closed', 'in_progress', 'canceled')`. It is NOT a Postgres `ENUM` type (unlike `booking_status_enum`). Evidence: `tasks` table schema.
2. **Acceptance Lock**: An offer (`task_requests`) goes from `pending` -> `accepted` when `accept_task_request` is called. This moves the task from `open` -> `assigned`, locking it from other proposals.
3. **Escrow Gateway**: The task moves from `assigned` -> `in_progress` ONLY when the QiCard escrow payment succeeds (`gateway_escrow` event processed by `process_payment_event_ledger`). Evidence: `20260314000000_tender_gateway_escrow_accept_assigned.sql` migration.
4. **Ownership**: Client ID matches `owner_id`. Freight of operations belongs to `client_id` (paying) and `freelancer_id` (working).

# Failure Modes & Attack Scenarios

1. **Failure Mode**: Client accepts a proposal but never pays escrow.
   - **Current**: Task gets stuck in `assigned`. Freelancer is tied up but cannot start work safely.
   - **Should happen**: Auto-expire the assigned state if payment is not completed within a threshold, reverting to `open`, or marking `canceled`.
2. **Race Condition**: Multiple freelancers submitting `task_requests` concurrently or modifying prices right before client clicks "Accept".
   - **Current**: Could lead to mismatch in expected vs actual price at acceptance time.
   - **Should happen**: `accept_task_request` must optionally accept a price check to ensure the client accepted the exact offer version intended.
3. **Failure Mode**: Client cancels task while work is `in_progress`.
   - **Current**: Simple diagrams show `Any early state -> canceled`.
   - **Should happen**: A task `in_progress` has locked funds. Cancellation must trigger the dispute resolution/refund ledger flow (`refund` payment event), it cannot be a simple state toggle.
4. **Delivery State Ignored**: The current diagram skips the delivery phase.
   - **Current**: Client just "approves final delivery" from `in_progress`.
   - **Should happen**: Freelancer submits work (`message_type = 'delivery_submitted'`, sets `delivered_at`, sets `review_expires_at`). This triggers a countdown for auto-closing if the client is unresponsive.
