# 03 DEPENDENCY ORDER

The SLine platform's financial stability and predictability demand that any remaining implementation execute in a strict blocker-first sequence. Do not proceed to the Flutter UI layer until the backend DB invariants are secured.

## Phase 1: Database Invariants (Immediate Blockers)

1. **Idempotency Hash Fix**
   - **Target**: `rpc_approve_delivery` / `journal_entries`
   - **Action**: Remove the non-deterministic `now()` value from the SHA256 digest in `rpc_approve_delivery`.
   - **Reason**: Retries currently calculate unique hashes per millisecond, failing completely to prevent double processing in `process_payment_event_ledger`.
   - **Blocking**: Entire Escrow Release reliability.

2. **Schema Terminology Unification**
   - **Target**: `accounts`, `journal_entries`, `ledger_lines` vs UI/App naming (`wallet_transactions`).
   - **Action**: Delete any legacy `wallet_transactions` tables and replace exclusively with aggregating PostgreSQL views spanning `journal_entries`. Update backend RPC references.
   - **Reason**: Double-entry ledger is non-negotiable for auditability.
   - **Blocking**: Wallet System implementation and Admin Dashboard queries.

3. **RPC Extensibility Update**
   - **Target**: `rpc_approve_delivery`
   - **Action**: Add `direct_offer` to the `entity_type` validation list. Ensure `direct_offers.client_id` acts as the `user_id` guard.
   - **Reason**: Without this, Direct Offers are "unapprovable" by clients, trapping Escrow funds indefinitely.
   - **Blocking**: Direct Offer Lifecycle closure.

## Phase 2: Missing FSM State Machines

1. **Dispute DB Controls**
   - **Target**: `disputes` table, `payment_event_type_enum`
   - **Action**: Introduce `dispute_status_enum` restricting `status` from plain text to `open | active | resolved`. Implement trigger guards banning unauthorized status transitions.
   - **Reason**: Protect mediation resolution triggers.
   - **Blocking**: Dispute/Admin Panel completion.

2. **Notification Automation completeness**
   - **Target**: `bookings` and `disputes` tables -> `notifications`
   - **Action**: Add AFTER UPDATE triggers watching state changes (`pending -> paid_request_pending`) and triggering `private_upsert_notification`.
   - **Reason**: Ensure users receive reliable updates without client-side polling.
   - **Blocking**: Unified Notification Timeline functionality.

## Phase 3: Flutter / Client Architecture

1. **Implement Missing Availability Hook**
   - **Target**: Flutter `AvailabilityService`
   - **Action**: Wire standard Flutter insert pattern to target `availability_slots`.
   - **Reason**: DB table overlap guard successfully protects schedules, but Flutter has no UI to use it.
   - **Blocking**: Freelancer capabilities parity.

2. **Align Payment Intents Checkout**
   - **Target**: Flutter Payment Screens
   - **Action**: Hook UI to server-side only `create_payment_intent` and strip any client-side Gateway SDK direct logic.
   - **Reason**: Ensure hard binding verification.
   - **Blocking**: Secure Payment Processing.
