# Threat Model: Proposals 2026-03-04

**Purpose**: Security and abuse cases for proposal flows.

## Threats

| Threat | Description | Mitigation |
|--------|-------------|------------|
| **Actor spoofing** | Caller supplies p_client_id/p_freelancer_id to RPCs and reads or mutates another user's proposal state. | Bind auth to `auth.uid()` inside SECURITY DEFINER RPCs; ignore or override caller-supplied actor params. |
| **Cross-user profile reads** | Owner proposal list uses direct profiles join; RLS profiles_select_self blocks or leaks. | Use minimum-field proposal profile contract (RPC) only; no direct profiles join for bidder identity. |
| **Partial finalize** | Non-QiCard: ledger event succeeds then pay_awarded_offer fails; state inconsistent. | Single server-owned atomic finalize RPC (ledger + task_request/task update). |
| **Role-side-effect abuse** | Client submits proposal; app mutates profiles.active_role to freelancer to satisfy RLS. | Remove client-side active_role mutation; fail fast with role-mode message. |
| **Self-favorite misuse** | Non-owner proposal tile shows "Add to favorites" for own bidder_id. | Hide or disable favorite action when viewer is the bidder (non-owner view). |
| **Replay / idempotency** | Finalize or award replayed; double-spend or double-award. | Idempotent finalize (by request_id/ledger id); award RPC checks current status. |

## Negative test actors

- **Anonymous**: No auth; all proposal RPCs and reads must fail.
- **Unrelated authenticated**: Different user; cannot read/mutate others' proposals.
- **Wrong role**: Client calling freelancer-only paths and vice versa; explicit error.
