# Contract: Proposals RPC and Models 2026-03-04

**Purpose**: Typed, testable proposal contract set.

## Proposal model (app)

- **ProposalModel** (or equivalent): id, taskId, bidderId, bidderName?, avatarPath?, price, days, note?, status (pending | rejected | accepted), createdAt, updatedAt; optional paymentDeadline, taskTitle for resume.
- Nullability and capability fields (canReplace, canReject, canAward, etc.) per STATE_MATRIX.

## Proposal payment summary (resume payload)

- **ProposalPaymentSummary**: requestId, taskId, taskTitle, freelancerName, amount, paymentDeadline (DateTime? from server); used by all launchers (Requests, Inbox, Work, Next Actions, Work Details).

## Awarded-unpaid resume payload

- Same shape as ProposalPaymentSummary; source: get_client_awarded_unpaid_offers / get_freelancer_awarded_unpaid_offers or view returning server-derived deadline and title.

## Profile summary fields (proposal surfaces only)

- Minimum: id, display_name (or full_name), avatar_url or storage path. No bio, active_role, skills, seller_level unless product requires.

## Error taxonomy

- **RoleMismatch**: User in wrong role (e.g. client submitting without freelancer mode).
- **Validation**: Invalid price/days/note.
- **NotFound**: Task or request not found.
- **Unauthorized**: RLS or RPC auth rejection.
- **Conflict**: Replace conflict or already awarded/cancelled.
- **FinalizeFailed**: Ledger or DB failure in finalize.

## Actor matrix (by operation)

| Operation | Owner | Freelancer | Unrelated |
|-----------|-------|------------|-----------|
| Submit/replace | No | Yes (own) | No |
| Reject | Yes | No | No |
| Award | Yes | No | No |
| Pay/finalize | Yes (client) | No | No |
| Cancel awarded | Yes | No | No |
| Read own list | Yes (received) | Yes (sent) | No |
| Read awarded-unpaid | Yes (client) | Yes (freelancer) | No |

## SQL verification

- RLS and RPC verification steps live in **RLS_MATRIX_Proposals_2026-03-04.md** (created Phase 1).
- **Canonical test destination**: `test/integration_test/proposals/` for proposal runtime scenarios.
