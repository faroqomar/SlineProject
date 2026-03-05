# Live Supabase Scan – Dashboard

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Status: BLOCKED

Live scan is blocked until one of:

- MCP Supabase auth is restored and `execute_sql` / list operations succeed, or
- A verified SQL export for touched objects is attached (definitions/grants for views, RPCs, RLS).

Do not start Phase 1.1 (finance boundary implementation) or other DB-sensitive work against production until this artifact is populated with actual live definitions.

## Touched Objects (From Repo)

- **Views**: vw_unified_work_items, vw_financial_metrics_realtime, vw_financial_metrics_period, vw_wallet_balances_user
- **RPCs**: rpc_get_profile_summaries, award_task_offer, pay_awarded_offer, process_payment_event_ledger, get_client_awarded_unpaid_offers, get_freelancer_awarded_unpaid_offers
- **Tables**: profiles, activity_log, tasks, task_requests, bookings, services

## When Unblocked

- Export live definitions and grants for the above.
- Record doc-vs-live drift here; do not delete or rename DB objects to match docs without migration.
