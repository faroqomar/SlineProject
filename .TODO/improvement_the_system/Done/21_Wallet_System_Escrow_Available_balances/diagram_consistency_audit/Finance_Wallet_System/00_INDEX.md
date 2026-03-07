# 00 INDEX: Diagram Consistency Audit

## Scope

Scanned 24 diagram files in `Sline_everything/AppDigram/All_Diagrams`.

## Scanned Folders / Files & Status

| ID  | File Name                                     | Status                                    |
| --- | --------------------------------------------- | ----------------------------------------- |
| 01  | 01_auth-profile-provisioning.md               | PASS                                      |
| 02  | 02_role-switching-flow.md                     | PASS                                      |
| 03  | 03_tender-task-lifecycle.md                   | PASS                                      |
| 04  | 04_task-request-bid-flow.md                   | PASS                                      |
| 05  | 05_booking-lifecycle.md                       | PASS                                      |
| 06  | 06_direct-chat-offer-flow.md                  | PARTIAL (Conflicts with 19)               |
| 07  | 07_chat-creation-matrix.md                    | PASS                                      |
| 08  | 08_chat-realtime-sync.md                      | PASS                                      |
| 09  | 09_ledger-event-flow.md                       | PASS                                      |
| 10  | 10_work-contract-revisions.md                 | PASS                                      |
| 11  | 11_availability-overlap-guard.md              | PARTIAL (Missing Flutter call)            |
| 12  | 12_unified-work-view.md                       | PASS                                      |
| 13  | 13_notification-routing.md                    | PARTIAL (Missing Booking/Dispute sources) |
| 14  | 14_dispute-lifecycle.md                       | PARTIAL (Missing DB state triggers)       |
| 15  | 15_rls-authorization-map.md                   | PASS                                      |
| 16  | 16_escrow-invariants-idempotency.md           | FAIL (Critical `now()` ID bug)            |
| 17  | 17_storage-signed-urls-flow.md                | PARTIAL (TTL unverified)                  |
| 18  | 18_realtime-subscription-topology.md          | PASS                                      |
| 19  | 19_direct-offers-work-contract.md             | FAIL (Missing Approval RPC)               |
| 20  | 20_withdrawals-lifecycle.md                   | PASS                                      |
| 21  | 21_Wallet_System_Escrow_Available_balances.md | FAIL (Naming Drift with 09)               |
| 22  | 22_Dynamic_Platform_Fee.md                    | PASS                                      |
| 23  | 23_Admin_Dashboard_Wallet_Finance.md          | PARTIAL (Template state)                  |
| 24  | 24_hardened_paymentLinking_system.md          | PARTIAL (Depends on implementation)       |

## Top Contradictions Found

1. **Idempotency Destruction**: Diagram 16 explicitly cites using `now()` in the SHA256 idempotency key hash for `rpc_approve_delivery`. This guarantees a new hash on every retry, completely breaking idempotency.
2. **Unapprovable Direct Offers**: Diagram 19 notes `rpc_approve_delivery` restricts operation to `entity_type IN ('task', 'booking')`. The `direct_offer` entity type is unhandled, making it physically impossible for clients to approve delivery and release escrow for direct offers.
3. **Ledger vs Wallet Terminology Drift**: Diagram 09 uses strict double-entry ledger terminology (`accounts`, `journal_entries`, `ledger_lines`), while Diagram 21 references a flatter `wallet_transactions` table.
4. **Disputes Lack DB Enforcement**: Diagram 14 admits disputes use a simple untyped text `status` with no DB layer state machine enforcement, relying safely on assumed Admin panel behavior.
5. **Notification Blackholes**: Diagram 13 proves DB trigger handles chat/offer notifications, but booking/dispute payment events have no observed notification trigger or edge function mapping.

## Implementation Order

1. **Fix Idempotency & DB Schemas**: Resolve the `now()` issue, unify ledger table schemas.
2. **Unify Contracts**: Ensure `direct_offers` can utilize `rpc_approve_delivery`.
3. **Enforce DB FSM**: Add DB level triggers and enums for disputes and booking edge cases.
4. **Implement UI flows**: Map precise RPC endpoints to the unified frontend.
