# 06 IMPLEMENTATION PLAN

Follow this phased plan to implement the unified backend and frontend system safely without introducing regressions. Execute sequentially.

## Phase 1: PostgreSQL Hardening (Backend)

1. **Remove `now()` from Idempotency Hash**
   - **Target**: `rpc_approve_delivery` (PostgreSQL function).
   - **Change**: Replace the `extensions.digest(entity_id || ':release_with_fee:' || now(), 'sha256')` logic.
   - **Solution**: Demand the UUID from the client as a parameter `p_idempotency_key`, generated at the frontend moment of interaction. Fallback: Hash purely deterministic data like `entity_id || ':release_with_fee:' || entity.status`.

2. **Broaden Approval RPC Support**
   - **Target**: `rpc_approve_delivery`
   - **Change**: Allow `entity_type` parameter to enthusiastically accept `direct_offer`. Link validation directly to `direct_offers.client_id = auth.uid()`.

3. **Dispute Lifecycle Database Guard**
   - **Target**: `disputes` table, Database schema
   - **Change**: Alter the table to bind `status` to an enumerated type `dispute_status_enum (open, active, resolved)`. Draft an AFTER UPDATE trigger on `disputes` blocking invalid state reversals and enforcing backend log tracking on mediation outcomes.

4. **Add Booking Notifications Trigger**
   - **Target**: `bookings` table trigger.
   - **Change**: On UPDATE setting `payment_status` to `paid_request_pending` or booking `status` to `active`, insert localized templates corresponding directly into the `notifications` table for Real-Time delivery to the participants.

5. **Cleanup Wallet Tables Nomenclature**
   - **Target**: Database schema
   - **Change**: Drop any redundant `wallet_transactions` tables that do not align seamlessly with the new double-entry `journal_entries` design. Abstract complex math exclusively behind `vw_wallet_balances`.

## Phase 2: Server Architecture (Payment Unification)

1. **Server-Side Intents Core**
   - **Target**: Edge functions or Next.js Web backend.
   - **Change**: Centralize all token minting and signature metadata binding `(fee_rate, gross, target, payer)` strictly server side.
   - **Result**: Client is inherently prevented from crafting valid webhooks holding false values or executing bypassing payloads.

2. **Webhook Integrity Check & Orphan Action**
   - **Target**: Webhook fulfillment route.
   - **Change**: Hard-code rejection if Gateway signature mismatches expected HMAC.
   - **Action**: Any payload surviving basic sanity tests but failing data matching gets automatically dumped into `orphan_payments` instead of crashing.

## Phase 3: Flutter / UI Layer

1. **Payment Intent UI Flow**
   - **Target**: Checkout Modals across Work screens.
   - **Change**: Modify the entry-point to block rendering external gateways until the backend responds supplying a `payment_intent_id`.

2. **Direct Offer UI Completion**
   - **Target**: Direct Offer chat UI.
   - **Change**: Inject a prominent "Approve Delivery" button for the client when Direct Offer moves to `delivered`. Bind this action strictly calling `rpc_approve_delivery(direct_offer)`.

3. **Schedule Input Integration**
   - **Target**: Availability Manager
   - **Change**: Connect the user-facing calendar directly bridging into the `availability_slots` table to complete the implementation validated strictly by the database collision prevention triggers.

## Verification

Do not deploy to production until executing Phase 1 logic across full-path E2E tests, verifying that simulating multiple overlapping requests does not increment ledger lines inappropriately (Idempotency assurance).
