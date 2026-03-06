# Gaps and Fixes: Work Contract Revisions

## Skills Selected

- **State Machine & Lifecycle**: Because pushing state backward (`delivered` -> `active`) has side effects on SLAs and constraints.
- **Threat Modeling (Security)**: Because an unlimited revision loop can hold funds in escrow indefinitely (griefing).

## Identified Gaps

1. **Missing Hard Cap Enforcement in RPC:** The diagram says "DB checks limits" comparing `revisions_used < revisions_total`, but the code for `rpc_request_revision` (Lines 14-55 in `20260305180100_work_revision_and_change_rpcs.sql`) _never checks_ `revisions_total`. It simply increments `revisions_used`. A client could request infinite revisions.
2. **Missing State Guard in RPC:** `rpc_request_revision` does not explicitly check if `status = 'delivered'`. It blindly resets the state to `active`. A client could call this while the task is already `active` or `completed` to break state.
3. **Immutability of Work Contracts:** `work_contracts` relies on `version` and `contract_hash`, but triggers to automatically populate/freeze this on delivery are absent from the immediate RPC, relying on an invisible `trg_freeze_contract_fields`.

## Proposed Fixes

1. **State Guard:** Add `IF t.status <> 'delivered' THEN RAISE EXCEPTION 'Can only request revision on delivered work'; END IF;` to `rpc_request_revision`.
2. **Hard Cap Guard:** In `rpc_request_revision`, check: `IF t.revisions_used >= t.revisions_total THEN RAISE EXCEPTION 'No revisions remaining'; END IF;`.
3. **Grace Period Escapes:** Ensure that if a freelancer refuses to revise indefinitely, there is a dispute path.
