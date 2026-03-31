# FULL REPORT: 20 Withdrawals Lifecycle

## 0) Skill Selection

- **Skills selected**: State Machine & Lifecycle, Idempotency & Concurrency, DB-First Financial Modeling, Threat Modeling (Security), Diagram Crafting (Mermaid).
- **Why these fit**: Withdrawals handle money leaving the SLine platform. Mistakes here mean permanent capital loss. Modeling the terminal states (`completed`, `failed`, `canceled`) and the double-entry locking mechanisms are the absolute highest priorities.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/20_withdrawals-lifecycle`
- **What system/feature it describes**: How a Freelancer moves their `available` balance to their real-world bank account, and how the platform guarantees that money isn't double-spent while the transfer clears.
- **Entities involved**: `withdrawal_requests` (table), `process_payment_event_ledger`, `WalletService.dart`.

## 2) Human Explanation

A Freelancer requests to withdraw $100. The system creates a `withdrawal_request` (`status=requested`) and immediately fires a Ledger event. The Ledger moves $100 from `user_available` to `user_pending`. This ensures the freelancer can't spend that $100 on a booking while the admin processes the payout. An Admin approves the transfer (`status=processing`). When the bank clears it, the Admin marks it `completed`; the Ledger debits `user_pending` and credits the system's external bank account. If the user cancels _before_ processing, the Ledger pushes the money back to `user_available`.

## 3) Symbol Legend

- **Rectangles**: Actor execution steps (Freelancer vs Gateway).
- **Solid Arrows**: State transitions and Ledger lock operations.
- **Dashed Arrows (Alts)**: Terminal failure/cancellation rollbacks.

## 4) Extracted Contracts & Invariants

1. **Total Balance Invariant**: `Total_User_Balance = Available + PendingWithdrawal`.
2. **Never Delete**: Withdrawal requests cannot be deleted; they must be transitioned to `canceled` or `failed`.
3. **Cancellation Lock**: Users cannot cancel a withdrawal once the status shifts to `processing`.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Status enums varied wildly in the docs vs the app.
- **Resolution**: Enforce constraints in DB: `requested`, `processing`, `completed`, `failed`, `canceled`.

### 5.2 Logic Drift

- **Conflict**: Legacy cancellation flow just changed the status, leaving funds trapped in the `user_pending` ledger account.
- **Resolution**: Implement a symmetric `withdrawal_cancel` Ledger event to accurately reverse the initial lock.

### 5.3 Data Model Drift

- None detected within the base `withdrawal_requests` fields.

## 6) Security & Failure Modes (Adversarial)

- **Cancel-after-Dispatch**: Admin wires money; User immediately taps 'Cancel' in app to get their UI balance back (Double Spend).
  - _Mitigation_: App UI AND Postgres `UPDATE` rules block cancellation if `status == 'processing'`. Admin must act as the authority for `failed` reversals.
- **Micro-Withdrawal Spam**: User submits 10,000 withdrawal requests for 1 penny.
  - _Mitigation_: Application-layer minimum withdrawal limits ($50).

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Wallet View, Withdrawal Prompt.
- **States**: Lists split by Available vs Pending. Button logic disabling "Cancel" if `processing`.
- **Guardrails**: Prevent withdrawal if `Amount > Available_Balance`.

### 7.2 Admin Dashboard UI

- **Pages**: Payout Pipeline.
- **Metrics**: Total pending platform float.
- **Drilldowns**: Ability to bulk-export `requested` lines to standard bank CSV formats.

### 7.3 Implementation Hooks

- `WalletService.cancelWithdrawal()`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9.5/10 (Post-fixes)
- **Best Diagram Type**: Sequence Diagram explicitly detailing the exact Ledger operations at every phase of the transfer.

## 9) Upgrade Plan

- **Phase 0: Observability**: Ensure `admin_logs` trace any manual status overrides.
- **Phase 1: Contracts**: Harmonize the enum constraints (`requested`, `processing`, `completed`, `failed`, `canceled`).
- **Phase 2: Hardening**: Deploy the `withdrawal_cancel` event type into `process_payment_event_ledger`.
- **Phase 3: Scale**: Add RPC `rpc_create_withdrawal_request` to wrap the `INSERT` and the Ledger lock perfectly atomically.

## 10) Risks

### 10.1 Risks if current version kept

- **Orphaned Funds**: The missing cancellation ledger logic actively destroyed platform balance integrity.

### 10.2 Risks introduced by fixes

- **Admin Bottleneck**: Everything relies on Admins manually marking payouts as `completed`. _Mitigation_: Future integration with QiCard payout API Webhooks.

## 11) Test Plan (High-value)

- **Unit (DB)**: Execute `withdrawal_cancel` event -> Ensure exactly matching reverse entry moves funds back to `available`.
- **Integration**: While a request is `processing`, attempt to update it to `canceled` -> Assert RLS/Trigger rejection.

## 12) Production Checklist

- [ ] Ledger `withdrawal_cancel` type added.
- [ ] Cancellation UI locked correctly based on status.
- [ ] Admin Dashboard workflow requires explicit `processing` state toggle.
