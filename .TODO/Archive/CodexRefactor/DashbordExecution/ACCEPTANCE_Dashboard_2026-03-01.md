# Dashboard Remediation – Acceptance Criteria

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

Measurable release blockers and non-regression rules.

## Must Pass (Release Blockers)

1. **Finance**: Standard dashboard runtime has zero non-admin direct access to platform finance aggregates.
2. **Transitions**: Dashboard task and booking workflow transitions are server-authoritative; raw client row updates are not the workflow authority.
3. **Tender payment**: Award/pay cannot advance task/request state after ledger rejection, `{ok:false}`, or status mismatch.
4. **Single payment path**: Dashboard and task-request flows use one tender-payment coordinator path.
5. **MVVM**: TenderPaymentScreen does not instantiate backend services directly (ViewModel/DI only).
6. **Ownership**: Dashboard live ownership is split only across shell/role/overview/bookings/work/inbox; dead Manage ownership does not survive.
7. **MyServices**: MyServicesScreen no longer depends on dashboard-owned state.
8. **Wallet snapshot**: Wallet snapshot shows correct balances on first dashboard entry without visiting wallet screen first.
9. **Lazy load**: Hidden tabs do not fetch data on first paint.
10. **Dead code**: Dead Manage files and unsupported TODO/no-op paths are removed or replaced with explicit disabled states.
11. **Tests**: Test infrastructure artifacts, fixtures, selector map, and failure artifact conventions exist and are used.
12. **Docs**: Docs and live DB evidence are synced; any remaining unresolved live drift keeps release blocked.

## Non-Regression Rules

- Existing dashboard shell (four tabs) remains usable; role switch works.
- Booking accept/decline/cancel and task offer award/pay/reject paths remain testable and observable (AppLogger).
- No new direct Supabase calls from views; no new print() in touched code.
