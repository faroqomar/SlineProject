# Migration — Bookin — 2026-02-28

## Strategy

- Additive-first
- No destructive enum or table renames in the remediation release
- Preserve live `bookings.price` as the canonical booking amount field

## Introduce

Migration file:

- `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260228_bookin_server_authority.sql`

Adds:

- `booking_payment_audits`
- `bookings.payment_request_id`
- `bookings.payment_gateway_id`
- `bookings.payment_correlation_id`
- `bookings.payment_expires_at`
- `bookings.payment_recovered_at`
- `rpc_create_booking_draft_validated`
- `rpc_finalize_booking_refund`
- `fn_booking_server_notifications`
- `trg_booking_server_notifications`

## Backfill

- None required for old rows to remain readable.
- New payment context columns stay nullable for pre-remediation bookings.

## Enforce

- Booking app flow should stop inserting booking drafts directly from Flutter and use `qicard_payment_create`.
- Booking app flow should stop client-triggered webhook POST recovery and use `qicard_payment_recovery`.
- Booking decline/refund should use `booking_decline_refund`.

## Compatibility Window

- Old bookings remain valid because the migration is additive.
- Old app clients can still read historical rows.
- Rollout should monitor for clients still depending on direct booking insert/payment flows before any later DB policy tightening.

## Rollback

- Forward-fix preferred once payment context starts being written.
- Safe rollback surface:
  - stop routing app traffic to new edge functions
  - keep additive booking columns in place
  - keep audit table in place
  - do not attempt destructive column removal during incident response
