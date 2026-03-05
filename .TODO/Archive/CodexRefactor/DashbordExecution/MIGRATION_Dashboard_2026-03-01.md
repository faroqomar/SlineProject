# Dashboard Remediation – Migration Plan

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Order (Additive-First)

1. **Introduce**: New RPCs (transition RPCs, admin finance RPC if needed); new profile summary RPC if versioned.
2. **Backfill**: Not applicable for dashboard (no bulk data backfill required for transition contract).
3. **Enforce**: Revoke direct authenticated SELECT on finance views; point client to RPCs; remove deprecated paths after compatibility window.

## Finance Boundary

- Migration: REVOKE SELECT on vw_financial_metrics_realtime, vw_financial_metrics_period from authenticated (or create admin-only RPC and grant execute to admin only).
- App: Remove or quarantine DashboardRepository.fetchFinancialMetrics / fetchPeriodFinancialMetrics before or with same release.

## Transition RPCs

- Add migrations that create rpc_dashboard_update_task_status, rpc_dashboard_update_booking_status (or document reuse of existing RPCs).
- App: Switch dashboard path to call these RPCs; remove direct status updates for workflow.

## Tender Payment State Machine

- Align award output status with ledger gate and pay RPC (may require migration to fix status checks in process_payment_event_ledger or pay_awarded_offer).
- See RECONCILIATION for partial drift handling.

## Profile Summary

- If versioned: add rpc_get_profile_summaries_v2 with minimal columns; migrate dashboard/profile; deprecate old RPC.
- Compatibility window: until all callers use v2, keep old RPC; then remove.

## Rollback

- Each migration has a rollback script (restore grants, drop new RPCs) in same folder or documented.
- Do not hand-edit production grants; use migrations only.
