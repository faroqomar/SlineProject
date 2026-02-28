# Rollout — Bookin — 2026-02-28

## Staging Order

1. Apply `20260228_bookin_server_authority.sql`
2. Deploy:
   - `qicard_payment_create`
   - `qicard_payment_recovery`
   - `booking_decline_refund`
   - updated `qicard_webhook_handler`
3. Verify MCP/live schema matches the deployed migration
4. Release the Flutter build that uses the new booking payment functions

## Compatibility Notes

- Additive booking columns allow old rows to remain readable.
- Booking flow should switch first; broader notification-policy tightening can wait until non-booking callers are migrated.

## Stop Conditions

- Webhook rejects valid signed traffic
- Recovery fails for owned bookings after successful QiCard completion
- Refund path returns provider/client-visible contradictory state
