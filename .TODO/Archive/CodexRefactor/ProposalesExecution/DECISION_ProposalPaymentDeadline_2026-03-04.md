# Decision: Proposal Payment Deadline 2026-03-04

**Status**: Locked.

## Chosen strategy

**Server-derived deadline in awarded-unpaid contract.**

- Do **not** fabricate deadline client-side (e.g. `DateTime.now() + 24h`).
- Awarded-unpaid resume payload (from get_client_awarded_unpaid_offers / get_freelancer_awarded_unpaid_offers or view) must include a **server-derived** payment_deadline (and task_title) when available.
- If live DB has no such column yet: derive from existing server timestamps or add additive column/contract in Phase 1; backfill only if required.

## Implementation

- Phase 1: Implement chosen contract (view or RPC output); Phase 2 app consumes typed ProposalPaymentSummary with paymentDeadline and taskTitle from server.
