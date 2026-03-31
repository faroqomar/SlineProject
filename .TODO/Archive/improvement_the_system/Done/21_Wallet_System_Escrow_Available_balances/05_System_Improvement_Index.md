# System Improvement Audit Index

## Reviewed Files

| File Path                                      | Verdict     | Critical Blockers                                                                                                                                  |
| :--------------------------------------------- | :---------- | :------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/.TODO/PLAN_Wallet_Integration_2026-03-07.md` | **PARTIAL** | Missing backend constraint checks for negative `pending_withdrawal_balance` anomalies, idempotency keys for UI withdrawal triggers (future phase). |

## Implementation Order

1. Phase 1: ViewModel Mathematical Invariants & Safe Mapping
2. Phase 2: Complete UI Rendering of Missing Balances (Held & Pending)
3. Phase 3: Transaction Label Taxonomy Overhaul
4. Phase 4: Strict QA validation (UI state bounds testing)
