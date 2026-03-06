# Risk Register

## J1) Risks if we keep the current system (diagram perspective)

| Risk                       | Severity | Likelihood | Impact                                                                                                                     | Evidence                                             |
| -------------------------- | -------- | ---------- | -------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| **Architecture Drift**     | High     | High       | Teams will design features thinking a bid is isolated, missing the parent `tasks` mutation.                                | `accept_task_request` in `SUPABASE_SETUP.md`.        |
| **Payment State Desync**   | High     | Medium     | UI might show "In Progress" before payment gateway reconciliation, leading to work without escrow.                         | `SUPABASE_SETUP.md:1913` (Tender QiCard transition). |
| **Missing Replace Intent** | Low      | High       | PMs/frontend won't realize freelancers can replace bids, leading to "delete then create" UX instead of atomic replacement. | `TaskRequestsService.dart`.                          |
| **Race Conditions**        | Medium   | Low        | Simultaneous acceptance of different bids if the RPC transactionality is not respected visually.                           | `SUPABASE_SETUP.md:1411` (Auto-rejection logic).     |

## J2) Risks introduced by improvements

| Risk                   | Mitigation                                                                                                                    |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Diagram Complexity** | Grouping Task and Bid states into blocks to maintain visual clarity.                                                          |
| **Migration Risk**     | The "Accepted-Unpaid" state is new. Migration `20260314000000` already handles this; the diagram must reflect the live truth. |
