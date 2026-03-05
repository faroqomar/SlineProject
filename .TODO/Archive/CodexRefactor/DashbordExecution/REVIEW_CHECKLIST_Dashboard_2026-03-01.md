# Dashboard Remediation – Review Checklist

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

Use per slice before merge.

## Security / RLS

- [ ] Finance views: no direct `authenticated` SELECT; non-admin path removed or gated.
- [ ] Task/booking transitions: server RPCs only; no raw client row updates for workflow.
- [ ] Tender payment: ledger `{ok:false}` is terminal; no state advance after failure.
- [ ] Profile summary: minimal fields only; no over-exposure.
- [ ] RLS matrix and negative checks documented and run.

## MVVM Boundary

- [ ] No Supabase/client calls from dashboard views or tender payment view.
- [ ] TenderPaymentScreen uses ViewModel/coordinator only (no in-widget TaskService/QiCardPaymentService).
- [ ] All data access via repository/service; ViewModels own orchestration.

## Dead Code / Duplicate Flow

- [ ] Single tender payment orchestration path (coordinator); dashboard and task-request use it.
- [ ] Dead Manage tab/files removed or explicitly deprecated; no new owner for Manage.
- [ ] Unused repository methods (finance, awarded-unpaid if duplicated) removed or quarantined.

## Test Evidence

- [ ] Unit tests: coordinator, LedgerService ok:false, transition guards, wallet init.
- [ ] Widget tests: overview wallet, work CTA, inbox/tender payment states, booking actions.
- [ ] Integration: role switch; award/pay or manual contract with postconditions.
- [ ] Failure artifacts captured when tests fail; rerun policy followed.

## Docs Sync

- [ ] DEVELOPER_GUIDE, SUPABASE_SETUP, MVP_ROADMAP, STRUCTURE updated for dashboard changes.
- [ ] CODE_REVIEW / ARCHITECTURE_ANALYSIS updated only where current-live contract changed.
