# Threat Model — Bookin — 2026-02-28

## High-Risk Threats

### Client-side merchant credential exposure

- Prior state:
  - Flutter contained QiCard Basic Auth operations
- Control:
  - booking flow moved to edge functions
  - client QiCard service now calls server endpoints for booking create/recovery/refund

### Forged webhook acceptance

- Prior state:
  - unsigned webhook acceptance was possible when key config was absent
- Control:
  - fail closed unless `QICARD_ALLOW_UNSIGNED_LOCAL_DEV=true`
  - invalid signature returns `401`

### Replay / double-hold

- Threat:
  - webhook and recovery both try to record the same hold
- Control:
  - ledger idempotency key `qicard:<payment_id>:gateway_escrow:SUCCESS`
  - replay treated as safe no-op

### Cross-user notification spoofing

- Prior state:
  - booking client code inserted notifications for other users
- Control:
  - booking flow no longer inserts notifications from Flutter
  - booking notifications are emitted from DB trigger

### Tampered booking amount / provider / slot

- Threat:
  - client submits forged provider or price
- Control:
  - `rpc_create_booking_draft_validated` derives provider from slot/task relation
  - price derived from task package or task budget
  - blocked slot and occupied slot checks are server-side

### Unauthorized recovery

- Threat:
  - non-owner recovers another client’s booking
- Control:
  - `qicard_payment_recovery` requires authenticated caller to equal `bookings.client_id`

### Unauthorized refund

- Threat:
  - non-party or wrong party triggers refund
- Control:
  - `booking_decline_refund` requires caller to be booking party
  - held-fund refund path restricted to provider

## Residual Risks

- Live `notifications_insert_any` policy is still permissive for authenticated users outside the booking flow.
- Live `process_payment_event_ledger` execute ACL remains broad and should be tightened further if other callers are retired.
- Tender QiCard flow is outside this remediation slice and still needs the same server-authoritative migration if the project wants full global QiCard closure.
