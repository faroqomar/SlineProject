# Dashboard Finance Boundary Contract

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Rule

- Standard dashboard runtime **must not** have direct client access to platform-wide financial metrics (vw_financial_metrics_realtime, vw_financial_metrics_period).
- Options: (1) Remove authenticated SELECT on these views and remove/quarantine repository methods, or (2) Expose metrics only via an admin-only RPC/service boundary.

## Server

- Grant: `authenticated` must not have SELECT on vw_financial_metrics_realtime, vw_financial_metrics_period unless through an admin-scoped RPC.
- If admin RPC is used: RPC must check admin role or service_role only.

## Client

- Dashboard repository must not expose fetchFinancialMetrics / fetchPeriodFinancialMetrics to the standard dashboard flow.
- Either delete these methods or move them to an admin-only module that is not used by the main dashboard provider.

## Verification

- Query information_schema.role_table_grants for these views; authenticated must not appear for SELECT.
- rg for fetchFinancialMetrics in lib/features/dashboard must show no call from dashboard ViewModel or tabs.
