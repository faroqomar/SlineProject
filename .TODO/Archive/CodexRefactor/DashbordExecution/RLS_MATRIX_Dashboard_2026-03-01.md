# Dashboard RLS / Grant Matrix

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Views

| Object | client | freelancer | provider | admin | anonymous |
|--------|--------|------------|----------|-------|-----------|
| vw_wallet_balances_user | SELECT (own row) | SELECT (own row) | SELECT (own row) | - | - |
| vw_wallet_activity_user | SELECT (own) | SELECT (own) | SELECT (own) | - | - |
| vw_financial_metrics_realtime | no | no | no | service_role only | no |
| vw_financial_metrics_period | no | no | no | service_role only | no |
| vw_unified_work_items | SELECT (involved) | SELECT (involved) | SELECT (involved) | - | no |

(Exact RLS/security_invoker behavior from live scan when available.)

## Tables (Dashboard-Touched)

- **profiles**: read own; update active_role (and allowed fields) for self.
- **tasks**: read involved; update via RPC or allowed policies only for workflow.
- **task_requests**: read involved; update via award_task_offer / pay_awarded_offer / ledger only.
- **bookings**: read involved; accept/decline/cancel via server RPC or allowed policies.
- **activity_log**: read (scoped by RLS).
- **services**: read own / as needed for dashboard.

## RPCs

- **process_payment_event_ledger**: execute for authenticated; RPC validates entity and state.
- **award_task_offer**: client task owner only; RPC validates.
- **pay_awarded_offer**: client task owner only; after ledger hold.
- **rpc_get_profile_summaries**: authenticated; returns minimal fields.

## Verification Queries

- Grants: `SELECT table_name, grantee, privilege_type FROM information_schema.role_table_grants WHERE table_schema = 'public' AND table_name IN ('vw_financial_metrics_realtime', 'vw_financial_metrics_period');` → authenticated must not appear.
- Negative: run as authenticated non-admin; SELECT from vw_financial_metrics_* must fail.
