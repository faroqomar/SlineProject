# Dashboard Task/Booking Transition Contract

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Principle

- Task and booking workflow transitions are **server-authoritative**. Client must call RPCs that validate actor, current status, and allowed next status.
- Raw client row updates (tasks.update(), bookings.update()) must not be the workflow authority for dashboard-driven transitions.

## Server

- Provide RPCs such as rpc_dashboard_update_task_status, rpc_dashboard_update_booking_status (or reuse existing transition RPCs) that:
  - Take actor (user id), entity id, current status, next status (or action).
  - Validate that the transition is allowed and that the actor has the right role.
  - Return success or typed error (invalid_transition, unauthorized, not_found).
- RLS remains on tables; RPCs enforce workflow rules.

## Client

- Dashboard ViewModel and BookingService/TaskService must call these RPCs for accept/decline/cancel/status changes triggered from dashboard.
- No direct .update() for status-only workflow changes from dashboard path.

## Allowed Transitions (Reference)

- Booking: paid_request_pending → accepted/declined; confirmed → canceled (via cancel/refund RPC).
- Task/offer: pending → awarded; awarded+unpaid → pay path (ledger then pay_awarded_offer).
- Document full matrix in STATE_MACHINE_Dashboard_2026-03-01.md.

## Verification

- rg updateTaskStatus|updateBookingStatus in dashboard/tasks/booking for workflow transitions; must go through RPC.
- Negative test: invalid transition returns error and does not change row.
