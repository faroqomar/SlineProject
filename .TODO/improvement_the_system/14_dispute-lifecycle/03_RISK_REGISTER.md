# Risk Register: Dispute Lifecycle

## J1) Current System Risks (Legacy)

| Risk ID  | Description                                                                                             | Severity | Likelihood | Impact         | Evidence                                                                                   |
| -------- | ------------------------------------------------------------------------------------------------------- | -------- | ---------- | -------------- | ------------------------------------------------------------------------------------------ |
| **R1.1** | **Escrow Bypass**: User completes task via RPC while dispute is pending.                                | High     | Medium     | Financial Loss | `rpc_approve_delivery` lacks dispute check.                                                |
| **R1.2** | **Status Injection**: Malicious user sets `status='resolved'` via `supabase.from('disputes').update()`. | Critical | Low        | Fraud          | `disputes` status is plain text, RLS for update might be too broad.                        |
| **R1.3** | **Evidence Leak**: Defendant sees private complainant notes not meant for them.                         | Medium   | Medium     | Privacy Breach | `dispute_messages.is_internal` exists for support, but evidence table lacks privacy flags. |

## J2) Improvement Risks (New Design)

| Risk ID  | Description                                                                                       | Mitigation                                                                       |
| -------- | ------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **R2.1** | **Migration Friction**: Moving from plain text to Enum might break existing (if any) rows.        | Use a phased migration: add enum, sync data, then switch column type.            |
| **R2.2** | **Admin Overload**: Forced manual assignment might delay resolution.                              | Allow "Claim" model where admins pick from a queue instead of forced assignment. |
| **R2.3** | **Circular Dependency**: Dispute depends on Task, but Task completion depends on Dispute closure. | Implement a clear "Locked" state for tasks with active disputes.                 |
