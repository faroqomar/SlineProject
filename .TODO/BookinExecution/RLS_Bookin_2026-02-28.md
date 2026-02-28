# RLS — Bookin — 2026-02-28

## Live Matrix Summary

### `availability_slots`

- Read:
  - authenticated: allowed
- Write:
  - authenticated owner only (`provider_id = auth.uid()`)

### `bookings`

- Read:
  - party-owned only by policy intent
- Insert:
  - current live policies still allow client-owned direct insert
- Update:
  - provider and client have overlapping live update policies
- Delete:
  - denied

### `notifications`

- Read:
  - own notifications only
- Update:
  - own notifications only
- Insert:
  - live policy currently allows any authenticated user

## Remediation Decision

- Booking flow itself no longer depends on client-side notification insert.
- Booking draft creation is moved to server-owned RPC + edge function.
- Recovery and refund are moved to server-owned edge functions.

## Remaining RLS Follow-Up

- Tighten or retire `notifications_insert_any` after non-booking features are migrated off direct notification inserts.
- Revisit direct `bookings` insert policy after compatibility window ends and all supported clients use the validated server path.
