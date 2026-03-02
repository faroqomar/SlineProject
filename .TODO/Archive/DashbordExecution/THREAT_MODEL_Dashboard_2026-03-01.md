# Dashboard Remediation – Threat Model

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Abuse Cases and Mitigations

| Threat | Mitigation | Verification |
|--------|------------|---------------|
| Finance data exposure | Revoke direct authenticated SELECT on finance views; or admin-only RPC | Grant query; negative test |
| Unauthorized task/booking transitions | Server RPCs validate actor, current state, next state | RLS + RPC negative checks |
| Replay / idempotency | Ledger and payment RPCs use idempotency keys | Documented in CONTRACT; test replay rejected |
| Insufficient funds | Ledger returns ok:false; client does not call pay_awarded_offer | Unit test LedgerService; integration or manual |
| Expired payment window | Server rejects; client shows error and does not advance state | Manual / contract test |
| Partial payment drift | Reconciliation artifact with verify queries and forward-fix rules | RECONCILIATION doc; run queries |
| Stale cache / wallet state | Cache invalidation and wallet load on dashboard entry | Wallet snapshot test; cache wiring |
| PII in logs | Redaction rules; no tokens/full PII in AppLogger | Observability doc; grep review |

## Negative Checks (Testable)

- Non-admin cannot SELECT from vw_financial_metrics_*.
- Invalid transition (wrong actor or invalid next state) fails in RPC.
- Ledger ok:false prevents pay_awarded_offer from being called.
- Replayed idempotency key returns idempotency error.
- Expired offer/booking payment path returns error and no state change.
