# Gaps & Fixes

### Identified Gaps

1. **Parent-Child Lifecycle Disconnect**:
   - _Current_: Focuses only on `task_requests`.
   - _Reality_: `accept_task_request` changes `tasks.status` to `assigned`.
2. **Missing Replacement Flow**:
   - `replace_task_request` is a core freelancer function to mitigate the "one active bid" constraint.
3. **Improper Mermaid Syntax**:
   - `TR --> TR` obscures the terminal states.
4. **Missing Payment Gateway States**:
   - Tenders now support QiCard. There is a "Payment Pending" / "Accepted-Unpaid" phase that the diagram ignores.
5. **Auto-Reject Observability**:
   - The diagram mentions auto-rejection but doesn't show it as a terminal state triggered by the `accept` RPC on a sibling bid.
6. **24h TTL**:
   - Bids expire if not acted upon.

### Proposed Fixes

- **Redesign State Machine**: Use specific nodes for `Pending`, `Accepted-Unpaid`, `Active (Paid)`, `Rejected`, `Expired`, and `Replaced`.
- **Sync Task States**: Explicitly show the `Task.Open` -> `Task.Assigned` -> `Task.InProgress` transitions triggered by bid events.
- **Annotate Guards**: Note the `conversations_before_insert_guard` bypass needed for the owner to reject and chat.
