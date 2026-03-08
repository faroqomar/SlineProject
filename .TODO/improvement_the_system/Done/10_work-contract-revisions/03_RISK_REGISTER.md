# Risk Register: Work Contract Revisions

## Skills Selected

- **Threat Modeling (Security)**: To detect malicious or abusive behavior.
- **DB-First Financial Modeling**: To ensure escrowed money is not trapped forever by infinite revision loops.

## J1) Risks if we keep the current system

1. **Infinite Revisions (Escrow Trapping)**
   - **Severity**: High
   - **Likelihood**: Medium
   - **Impact**: Freelancers never get paid because the client keeps hitting 'request revision'. The RPC `rpc_request_revision` does not actually enforce the `revisions_total` limit.
   - **Evidence**: `supabase/migrations/20260305180100_work_revision_and_change_rpcs.sql`, lines 30-37. No `revisions_total` condition.
2. **State Machine Corruption (Revision spam on active tasks)**
   - **Severity**: High
   - **Likelihood**: Low (requires API manipulation)
   - **Impact**: Client can reset the task to `active` even if it is `completed` or `cancelled`, breaking workflow invariants.
   - **Evidence**: `rpc_request_revision` executes unconditional `UPDATE ... SET status = 'active'` without checking `WHERE status = 'delivered'`.

## J2) Risks introduced by improvements

1. **Hard caps blocking legitimate minor tweaks**
   - **Severity**: Low
   - **Likelihood**: High
   - **Mitigation**: If revisions cap is hit, freelancers can still voluntarily accept change requests via `change_requests` or the client can open a dispute.
