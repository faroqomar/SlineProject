# RLS Matrix: Proposals 2026-03-04

**Purpose**: Testable RLS and RPC contract for proposal access.

## Allowed / denied by actor

| Actor | task_requests (owner read) | task_requests (freelancer read) | award / pay / cancel | get_client_awarded_unpaid | get_freelancer_awarded_unpaid |
|-------|----------------------------|---------------------------------|----------------------|---------------------------|-------------------------------|
| Owner (client) | Allowed (own task) | Denied | Allowed (own task) | Allowed (own rows) | Denied |
| Freelancer (bidder) | Denied | Allowed (own rows) | Denied | Denied | Allowed (own rows) |
| Unrelated authenticated | Denied | Denied | Denied | Denied | Denied |
| Unauthenticated | Denied | Denied | Denied | Denied | Denied |

## Profile summary (proposal context)

- Allowed only via chosen contract (minimum-field RPC or narrow rpc_get_profile_summaries for proposal callers).
- Direct `profiles` join in owner proposal list: not allowed after contract (use RPC).

## SQL verification steps

1. **Spoofed client_id**: As user A (freelancer), call `get_client_awarded_unpaid_offers(user_B_uuid)`; expect empty or error (must not return user B's data).
2. **Spoofed freelancer_id**: As user A (client), call `get_freelancer_awarded_unpaid_offers(user_B_uuid)`; expect empty or error.
3. **Owner award**: As task owner, call `award_task_offer(request_id)`; expect success.
4. **Non-owner award**: As non-owner, call `award_task_offer(request_id)`; expect error "Only task owner can award".
5. **Cancel**: As owner, call `cancel_awarded_offer(request_id)`; expect success. As non-owner, expect error.

Run against staging after applying 20260304060000_secure_proposal_rpc_contract.sql.
