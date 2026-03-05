# Dashboard Remediation – Observability

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Required Events (AppLogger)

- **DashboardViewModel**: refreshDashboard (start/success/failure), setTab, booking accept/decline/cancel, task award/pay entry points, cache hit/miss (when wired).
- **DashboardRepository**: fetch work items, activity, profile summaries (result count or error); do not log finance payloads.
- **TaskService**: awardTaskOffer, payAwardedOffer (start, ledger result, pay RPC result, failure).
- **LedgerService**: processPaymentEventLedger (request redacted); response ok true/false; business-rule failure with taxonomy (e.g. insufficient_funds, status_mismatch, expired).
- **BookingService**: transition/cancel/refund entry and outcome.
- **TenderPaymentViewModel/Coordinator**: payment flow start, submit, success, failure.
- **WalletViewModel**: load start/success/failure for snapshot.
- **DashboardCacheService**: get/set/invalidate by key (no sensitive values); only when wired.

## Correlation

- Use trace IDs for multi-step flows (e.g. award → ledger → pay); same ID in ViewModel and services where feasible.
- Log level: info (normal), warning (recoverable), error (blocking failure).

## Redaction Rules

- Never log: tokens, full PII, raw payment card data, full ledger payloads.
- Allowed: correlation ID, flow name, entity type, entity ID (UUID), result (success/failure), error code/message (sanitized).

## Failure Taxonomy (Payment)

- insufficient_funds
- status_mismatch
- expired
- entity_not_found
- idempotency_replay
- amount_mismatch
- other (with sanitized message)

## Evidence

- List event names and sample sanitized payloads in execution log and in this doc when implementing.
