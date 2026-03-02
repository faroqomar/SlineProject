# Dashboard Tender Payment Contract

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Sequencing

1. **Award**: award_task_offer(task_id, request_id) → task_request status set to accepted/unpaid (or agreed state).
2. **Ledger hold**: process_payment_event_ledger(...) with event type for escrow hold. Must succeed (ok: true) before next step.
3. **Pay**: pay_awarded_offer(task_id, request_id) → task_request and task state updated.

## Invariants

- If ledger returns **ok: false** (insufficient funds, status mismatch, expired, etc.), client must **not** call pay_awarded_offer. State must not advance.
- LedgerService must throw on ok:false (already implemented); TaskService.payAwardedOffer must not call pay RPC after ledger failure.
- One orchestration path: TenderPaymentCoordinator used by both dashboard InboxTab and task-request flow.

## Idempotency

- Ledger RPC uses idempotency key; replay returns same result or idempotency error.
- Pay RPC must be idempotent or guarded so duplicate submit does not double-apply.

## Client

- TenderPaymentScreen bound to TenderPaymentViewModel; ViewModel uses TenderPaymentCoordinator (and TaskService/LedgerService via DI). No service instantiation in widget.
- Coordinator: calls award (if not already awarded), then ledger, then pay; short-circuits on first failure and reports error.

## Verification

- Unit test: ledger returns ok:false → coordinator does not call pay RPC.
- Unit test: LedgerService throws on ok:false (existing).
- Manual or integration: insufficient funds → user sees error; task_request status unchanged.
