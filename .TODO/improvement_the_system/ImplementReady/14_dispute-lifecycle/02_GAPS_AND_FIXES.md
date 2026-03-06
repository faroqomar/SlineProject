# Gaps and Fixes: Dispute Lifecycle

## 1. State Machine Gaps

| Gap                     | Risk                                                                             | Proposed Fix                                                    |
| ----------------------- | -------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| **Loose Status**        | `status` is a plain `text` column in `disputes` (§5.24). Allows invalid strings. | Implement `dispute_status_enum`.                                |
| **Missing Transitions** | No DB trigger enforces `open -> active -> resolved`.                             | Add `trg_dispute_guard` with `fn_dispute_guard()`.              |
| **Silent Resolution**   | `resolved_at` is nullable but not auto-set by a trigger.                         | Auto-set `resolved_at = now()` when status moves to 'resolved'. |

## 2. Security & RLS Gaps

| Gap                     | Risk                                                                            | Proposed Fix                                                         |
| ----------------------- | ------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Evidence Access**     | `dispute_evidence` RLS not fully detailed for participants.                     | Ensure ONLY complainant, defendant, and admin can `SELECT` evidence. |
| **Status Manipulation** | If RLS allows UPDATE on `disputes`, a party might try to resolve it themselves. | Restrict `status` updates to Admin role or `SECURITY DEFINER` RPCs.  |
| **Ghost Disputes**      | No check if a dispute already exists for a task.                                | Add a unique constraint or check in `submitDispute` to prevent spam. |

## 3. Financial Integration Gaps

| Gap                   | Risk                                                                                            | Proposed Fix                                                                                         |
| --------------------- | ----------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Escrow Disconnect** | The lifecycle doesn't explicitly lock the task/booking from completion while in dispute.        | Add a check in `rpc_approve_delivery` to block if an 'open' or 'active' dispute exists for the task. |
| **Partial Refunds**   | Original diagram only mentions `refund` or `release`. Production often needs split resolutions. | Ensure `process_payment_event_ledger` supports split payouts.                                        |

## 4. Admin Audit Gaps

| Gap                     | Risk                           | Proposed Fix                                                           |
| ----------------------- | ------------------------------ | ---------------------------------------------------------------------- |
| **Assignment Tracking** | "Admin assigns" is unverified. | Add `assigned_admin_id` to `disputes` and log changes in `admin_logs`. |
