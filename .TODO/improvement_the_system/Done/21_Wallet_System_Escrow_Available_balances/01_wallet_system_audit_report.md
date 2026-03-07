# Wallet System & Financial Overview Audit Report
Date: 2026-03-07

## 1. Executive Summary
An exhaustive audit of SLine's Wallet System, Wallet Feature, Dashboard Overviews, and related backend/frontend mechanisms reveals a highly sophisticated and secure **Double-Entry Ledger Architecture**. The platform operates on a strict "Pay-First" escrow system, ensuring all financial movements are ledger-recorded, atomic, and idempotent.

While the foundation is remarkably robust, some user-facing elements—notably the Withdrawal UI and Admin Financial Dashboards—remain in a "planned" or "partially implemented" state, despite their backend data structures being entirely established.

## 2. System Coverage Scanned
- **Frontend (Flutter)**: `WalletTab`, `OverviewTab`, `WalletService`, `LedgerService`, `WalletViewModel`, models (activity/balance), and dashboard repositories.
- **Backend (Supabase)**: `SUPABASE_SETUP.md`, ledger RPCs (`process_payment_event_ledger`), aggregation views (`vw_wallet_balances_user`, `vw_wallet_activity_user`), and tables.
- **Documentation & Diagrams**: `Wallet_Feature.md`, Diagrams 21 (Escrow), 09 (Ledger Flow), 20 (Withdrawals), and 23 (Admin Dashboard Wallet Finance).

## 3. Current Wallet-Related Implementation
- **What is fully implemented?**
  - **The Double-Entry Ledger Backend**: The legacy `wallet_transactions` table is successfully frozen. The new system securely tracks state via `journal_entries` and `ledger_lines`.
  - **Pay-First Escrow & Release**: Payments transition through `platform_escrow` safely using a single exit point: `rpc_approve_delivery()`.
  - **Wallet Data Models & Views**: Users can view their balances and history reliably via `vw_wallet_balances_user` and `vw_wallet_activity_user`.
- **What is partially implemented?**
  - **Withdrawals**: The backend `WalletService.requestWithdrawal()` locks funds into a `user_pending_withdrawal` account properly. However, the UI (`wallet_tab.dart`) displays "Coming Soon" and a disabled button. The cancellation method (`cancelWithdrawalRequest()`) exists in the backend service but has no UI bindings.
- **What is planned but not implemented?**
  - **Admin Dashboard Financial Engine**: Diagram 23 defines an Admin Wallet view (`vw_admin_finance_metrics`, `vw_admin_booking_finance`), but an inspection of `SUPABASE_SETUP.md` reveals these views do not yet exist in the database.

## 4. Dashboard Overview Analysis
- **Current Financial Overview**: The Dashboard (`overview_tab.dart`) displays a simplified financial summary via the `<WalletSnapshotCard()>` widget.
- **How it works**: When the dashboard loads, it dispatches `WalletViewModel().loadWallet()`. The overview piggybacks directly onto the same view-model data that powers the dedicated Wallet Tab.
- **Data Source**: It shows real (not mocked) data aggregated by Supabase views. It relies purely on the double-entry accounting numbers.

## 5. Wallet Tab Analysis
- **State**: A dedicated tab exists (`lib/features/dashboard/view/tabs/wallet_tab.dart`).
- **Functionality**:
  - Displays "Total Balance" (Available + Held).
  - Displays "Available to withdraw" (True cleared funds).
  - Displays "Withdraw" (Hardcoded to visually look locked / "Coming Soon").
  - Displays "Transaction history" categorized by "Money received" and "Money spent" (with icon decorations indicating arrows).
- **Data Safety**: All UI components fetch data from `WalletViewModel`, which reads real calculated data directly from the system ledger. There is zero client-side math performed off raw transactions; it is strictly a read-only mirror of the Supabase aggregation views.

## 6. Workflow Analysis
* **Escrow (Booking to Money Flow)**:
  - **Implemented**: *Fully Real*. QiCard/Edge calls `escrow_hold` or `gateway_escrow`, hitting `process_payment_event_ledger()`. Money moves from `user_available` (or gateway) to `platform_escrow`.
* **Escrow Release (Approval Flow)**:
  - **Implemented**: *Fully Real*. Single exit point (`rpc_approve_delivery`). Resolves ownership, secures the row via `FOR UPDATE`, and deducts the platform fee (`release_with_fee`).
* **Withdrawals Request Flow**:
  - **Implemented**: *Backend Real, UI Mocked*. Translates to a `withdrawal_request` event shifting funds to `user_pending_withdrawal`. Gateway completion steps (`withdrawal_complete`, `withdrawal_failed`) exist as enums, though external webhooks manage them.

## 7. Diagram Analysis
- **21_Wallet_System_Escrow_Available_balances.md**: Highly accurate. Matches 1:1 with the implemented single exit point `rpc_approve_delivery` and standard wallet views.
- **09_ledger-event-flow.md**: Accurate reference to the core engine.
- **20_withdrawals-lifecycle.md**: Accurate on the backend DB/service contract. Properly identifies `cancelWithdrawalRequest()` and gateway updates.
- **23_Admin_Dashboard_Wallet_Finance.md**: **Outdated / Missing**. Details `vw_admin_finance_metrics`, which is missing from `SUPABASE_SETUP.md`. The diagram reflects a planned feature that has not been executed yet.

## 8. Business Rules and Financial Safety Analysis
- **Balance Calculation**: Secure. Balances are derived dynamically off immutable double-entry ledger lines. 
- **Negative Balances Risiko**: Extremely low. The ledger enforces constraints stopping withdrawals if funds are insufficient (`ERR_INSUFFICIENT_FUNDS`).
- **Separation of Money States**: Very strict. `held_balance`, `available_balance`, and `pending_withdrawal_balance` are distinctly separated at the database level using explicit account designations (e.g., `user_pending_withdrawal:{uid}`).
- **Spending**: Strictly treated as ledger entries (Debits/Credits), eliminating the risky paradigm of manually decrementing a plain `balance` integer.

## 9. Missing Pieces / Gaps
- **Frontend Gap**: No interface mapped for users to input a withdrawal amount, execute `WalletService.requestWithdrawal()`, or `cancelWithdrawalRequest()`.
- **Database Gap**: Missing `vw_admin_finance_metrics`, `vw_admin_booking_finance`, and `vw_admin_escrow_open` to fulfill Diagram 23 (Admin Wallet Finance).
- **Edge/Webhook Gap**: The documentation states QiCard webhooks finalizing `withdrawal_complete` run in an edge function, which must be rigorously audited or built to avoid stuck pending withdrawals.

## 10. Classification Table of All Wallet-Related Parts

| Feature | Classification | Evidence / Note |
| :- | :- | :- |
| **Double-Entry Ledger Framework** | Fully Implemented | `SUPABASE_SETUP.md`, `process_payment_event_ledger` RPC |
| **Escrow Hold & Release (Booking/Tasks)** | Fully Implemented | `rpc_approve_delivery`, `DirectOffersService.completeOffer` |
| **Wallet Tab UI (Balances & History)** | Fully Implemented | `wallet_tab.dart`, `vw_wallet_balances_user` |
| **Wallet Snapshot (Dashboard)** | Fully Implemented | `wallet_snapshot_card.dart`, `overview_tab.dart` |
| **Withdrawal Request Logic (Backend)** | Backend Only | `WalletService.requestWithdrawal()` |
| **Withdrawal Action (UI)** | UI Only (Mock) | `WalletTab` displays "Coming Soon" |
| **Withdrawal Cancellation** | Backend Only | `WalletService.cancelWithdrawalRequest()` exists, no UI bindings |
| **Admin Wallet / Escrow Dashboards** | Documented Only | Mentioned in Diagram 23, missing from `SUPABASE_SETUP.md` |

## 11. Risks / Inconsistencies / Ambiguities
- **Risk (Withdrawals Pipeline)**: If the withdrawal feature backend is live but the UI mock blocks it, manual withdrawal triggers bypassing the UI (e.g. API hacking/testing) will lock user funds into `pending_withdrawal` permanently if the final gateway execution webhook isn't fully operational.
- **Ambiguity (Fee Calculation)**: `Wallet_Feature.md` mentions that setting the fee equal to exactly zero omits the revenue ledger line, but details on where `system_config.platform_fee_bps` lives UI-wise remain undocumented or non-existent for Admins.

## 12. Final Conclusion
SLine today possesses a production-grade, highly secure financial backend representing funds via a strict **Ledger**. The **Client/Freelancer Dashboard Interfaces** for viewing money are fully wired and functional, relying on real aggregated data. 

However, the flow of **money *leaving* the app (Withdrawals)** and **Admin Financial Oversight (Admin Dashboards)** are the two massive remaining pieces that classify as partially implemented or documented-only. The system is safe to handle internal task escrows, but it is **not yet fully feature-complete for end-to-end monetization extraction**.
