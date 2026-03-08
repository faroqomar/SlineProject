# Contract: Booking Status → Ledger Event Mapping

**Plan:** `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md`  
**Purpose:** Single source of truth for which `process_payment_event_ledger` event_type is used for each terminal or financial booking transition. Prevents double-release and wrong event_type.

**Verified against:** `Sline_everything/SUPABASE_SETUP.md` §4.7 `payment_event_type_enum`, §4.8 `related_entity_type_enum`, §9.5 `rpc_approve_delivery`, `process_payment_event_ledger`.

---

## Allowed event_types for `related_entity_type = 'booking'`

From SUPABASE_SETUP, `payment_event_type_enum` includes:  
`escrow_hold`, `release_with_fee`, `refund`, `withdrawal_request`, `deposit`, `withdrawal_complete`, `withdrawal_failed`, `admin_credit`, `admin_adjustment`, `reversal`, `gateway_escrow`.

For **booking** entity, the ledger flow uses:

- **escrow_hold** — when payment is captured (e.g. gateway webhook or pay flow); not a status transition in this contract.
- **release_with_fee** — release from escrow to provider (booking completed).
- **refund** — return funds to client (canceled, refunded, expired_unanswered, no_show after resolution, disputed→refunded).

---

## Mapping Table

| Old status | New status | Who triggers | event_type | Idempotency key pattern | Notes |
|------------|------------|--------------|------------|--------------------------|-------|
| pending | paid_request_pending | Client / Gateway | (payment path; not status-only) | — | Escrow held at payment; status update separate. |
| delivered | completed | Client (rpc_approve_delivery) or Cron (rpc_finalize_auto_approval) | release_with_fee | entity_id \|\| ':release_with_fee:' \|\| status \|\| payment_status (stable, no now()) | FOR UPDATE on booking; then ledger; then clear review_expires_at. |
| paid_request_pending | refunded | Provider decline | refund | — | Ledger refund; status set. |
| paid_request_pending | expired_unanswered | Cron | refund | — | Ledger refund; status set. |
| active | canceled | Client or Provider (pre-delivery) | refund | — | Refund to client. |
| disputed | completed | Admin RPC (admin_resolve_booking_dispute) | release_with_fee | Same as delivered→completed | Admin resolves for provider. |
| disputed | refunded | Admin RPC | refund | — | Admin resolves for client. |
| active | no_show | Provider or SECURITY DEFINER RPC | refund | — | After resolution or provider confirm; refund to client. |

---

## Invariants

1. Every terminal financial state (completed, refunded, canceled pre-delivery, expired_unanswered, no_show after resolution) must have exactly one ledger event (release_with_fee or refund).
2. Idempotency key for release_with_fee must be stable (no `now()`) so retries do not double-release.
3. All booking ledger calls use `related_entity_type = 'booking'` and `related_entity_id = booking.id`.
