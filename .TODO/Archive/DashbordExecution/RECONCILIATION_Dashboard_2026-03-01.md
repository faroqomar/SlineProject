# Dashboard Payment Reconciliation

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Partial Payment Drift

- **Scenario**: Award succeeded but pay failed (ledger ok:false or exception); task_request may be accepted/unpaid with no ledger entry.
- **Detection**: Query task_requests where status indicates awarded/unpaid but no corresponding ledger hold (or pay_awarded_offer not completed).
- **Forward-fix**: Document safe update path (e.g. retry pay path with same idempotency, or manual reconciliation) and who may run it; do not ad hoc update in production.

## Verify Queries (Reference)

- List task_requests in accepted/unpaid (or equivalent) with no matching journal entry for hold.
- List bookings in confirmed with unexpected ledger state if cancel/refund was applied.

## Kill-Switch Triggers

- If live scan shows finance views still granted to authenticated: enable kill-switch for finance reads and revoke in migration.
- If payment state machine mismatch found in production: disable award/pay UI; run reconciliation queries; fix state machine in migration; then re-enable.

## Rollback

- Prefer forward-fix over partial rollback of money-related functions.
- Keep old contract paths only during compatibility window; then remove.
