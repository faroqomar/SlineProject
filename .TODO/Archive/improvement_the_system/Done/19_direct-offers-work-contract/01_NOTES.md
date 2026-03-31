# Audit Notes: Direct Offers Work Contract

## Skills Selected

- **Evidence-First Reading**: Extracted trigger and service logic from `SUPABASE_SETUP.md` and `direct_offers_service.dart`.
- **State Machine & Lifecycle**: Analyzed the transition logic in `fn_direct_offer_guard`.
- **DB-First Financial Modeling**: Verified the ledger integration for escrow hold and release.
- **Threat Modeling (Security)**: Evaluated the guard trigger for unauthorized state transitions.
- **Diagram Crafting (Mermaid)**: Redesigning the sequence to be production-accurate.

## Why these skills fit

The system is heavily reliant on a specific DB lifecycle guard and financial ledger events. Understanding the exact state transitions and the distinction between "booking/task" and "direct_offer" processing is critical.

## Skills intentionally not used

- **Repo Mapping**: The project structure is already well-understood from previous audits.
- **Production Migration Planning**: This is an audit of an existing system, not a new deployment.

## Key Evidence

1. **DB Trigger**: `fn_direct_offer_guard` in `SUPABASE_SETUP.md` (and migration files) enforces the lifecycle:
   - `sent -> accepted` (unpaid)
   - `accepted -> active` (requires `payment_status = 'held'`)
   - `active -> delivered` (freelancer only)
   - `delivered -> completed` (requires `payment_status = 'released'`)
2. **Flutter Service**: `lib/features/direct_offers/services/direct_offers_service.dart` confirms:
   - Delivery is marked by updating `status` to `delivered`.
   - Completion is triggered by calling `submitPaymentEvent('release_with_fee', 'direct_offer', ...)`.
3. **Hallucination Fixed**: The original diagram suggested `rpc_approve_delivery` was used. Evidence Shows `rpc_approve_delivery` EXPLICITLY fails for `direct_offer`. The actual path is a direct Ledger event call.

## Observations

- The `direct_offers` table essentially acts as a work contract, which is efficient but requires its own duplicated logic in the ledger if not careful (though `process_payment_event_ledger` seems to handle it).
- There is a "legacy" `acceptWithPayment` method in the service which might bypass the "dashboard pay" flow but is still secure because it uses the ledger.
