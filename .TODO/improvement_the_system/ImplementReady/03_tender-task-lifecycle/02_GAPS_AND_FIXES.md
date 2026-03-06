# Gaps in Current System

1. **State Missing Escrow (`assigned` -> `in_progress`)**
   - **Gap**: The current flow treats the move from `assigned` to `in_progress` as implicit ("Work begins").
   - **Fix**: The transition MUST explicitly require a `gateway_escrow` payment event processed by `process_payment_event_ledger`.
   - **Evidence**: `SUPABASE_SETUP.md` refers to migration `20260314000000_tender_gateway_escrow_accept_assigned.sql`.

2. **State Missing Delivery & Review Phase**
   - **Gap**: The diagram shows `in_progress` -> `closed`. It misses the critical delivery handoff.
   - **Fix**: Add a `delivered` state (represented functionally by setting `delivered_at` and `review_expires_at` via `rpc_submit_delivery` or similar). The client then explicitly approves (or auto-approves via cron) to reach `closed`, triggering `release_with_fee`.

3. **Oversimplified Cancellation**
   - **Gap**: Diagram shows `[*] -> canceled` from any early state.
   - **Fix**: Differentiate post-escrow cancellation from pre-escrow. Pre-escrow (status `open` or `assigned`), the client can easily cancel. Post-escrow (status `in_progress`), mutual cancellation or dispute is required to process the `refund` ledger event.

4. **Task Status Enum Inaccuracy**
   - **Gap**: The diagram's metadata claims the DB uses `task_status_enum`.
   - **Fix**: Update the terminology. `tasks.status` is a `text` column protected by a `CHECK (status IN ('open', 'assigned', 'closed', 'in_progress', 'canceled'))`.

# Proposed Guardrails

1. **Payment Timeout Guard**
   - Implement a cron or edge function that automatically expires tasks in the `assigned` status if `payment_status` remains `unpaid` beyond 24-48 hours. This frees the freelancer and resets the task.
2. **Offer Concurrency Guard**
   - Modify `accept_task_request` to take an expected price or `updated_at` timestamp from the `task_request` to prevent a freelancer from silently bumping the price microseconds before the client clicks accept.
3. **Escrow Refund Lock**
   - Enforce an RLS policy or trigger that prevents setting `status = 'canceled'` directly by the client when `status = 'in_progress'` without a corresponding `dispute` or mutual `change_request` resolution.
