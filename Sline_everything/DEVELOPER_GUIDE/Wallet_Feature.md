# Wallet Feature Reference

## 1. Human Explanation

The Wallet feature provides a financial dashboard for Freelancers (and Clients). It implements the "Pay-First" flow visualization where funds can be in three states:
1.  **Held (Escrow)**: Funds linked to an active booking/task that are not yet released.
2.  **Pending Withdrawal**: Funds locked for withdrawal processing (moved from Available).
3.  **Available**: Funds released to the user that are ready for withdrawal.

The feature relies on a **double-entry ledger system** using `journal_entries` and `ledger_lines` tables, replacing the legacy `wallet_transactions` table.

**Event flow and runbook:** See `.TODO/improvement_the_system/Done/09_ledger-event-flow/` — diagram (`06_DIAGRAM_FINAL.md`), risk register (`03_RISK_REGISTER.md`), contract (`CONTRACT_ledger_event_flow.md`), smoke checklist and withdrawal orphan runbook (`SMOKE_CHECKLIST_AND_RUNBOOK.md`). Unit tests: `flutter test test/unit/wallet/`. RLS tests: `flutter test test/rls/ledger_rls_test.dart`. Forensics (`session_id`, `request_id` in `p_meta`) are built by `lib/core/utils/ledger_forensics.dart` and merged by `LedgerService` on every ledger call.

## 2. Database & Supabase Mapping

### 2.1 Ledger Core Tables

#### `public.accounts` - Chart of Accounts

| Column | Type | Purpose / Usage |
| --- | --- | --- |
| `id` | `uuid` (PK) | Account ID |
| `account_code` | `text` (UNIQUE) | Account identifier (e.g., 'user_available:{user_id}', 'platform_escrow') |
| `account_type` | `enum` | 'asset', 'liability', 'revenue', 'expense', 'equity' |
| `owner_id` | `uuid` (FK, nullable) | User owner (NULL for platform accounts) |
| `currency` | `text` | Always 'IQD' for MVP |

**Platform Accounts (owner_id = NULL):**
- `platform_cash` - Cash position
- `platform_escrow` - Escrow liability
- `platform_revenue` - Revenue account
- `platform_test_float` - Testing float for admin credits

**User Accounts (owner_id = auth.users.id):**
- `user_available:{user_id}` - User's available balance (asset)
- `user_pending_withdrawal:{user_id}` - Pending withdrawal (liability)

#### `public.journal_entries` - Transaction Headers

| Column | Type | Purpose / Usage |
| --- | --- | --- |
| `id` | `uuid` (PK) | Journal entry ID |
| `event_type` | `enum` | 'escrow_hold', 'release_with_fee', 'refund', 'deposit', 'withdrawal_request', 'withdrawal_complete', 'withdrawal_failed', 'gateway_escrow' |
| `related_entity_type` | `enum` | 'booking', 'task_request', 'withdrawal_request' |
| `related_entity_id` | `uuid` | ID of related entity |
| `idempotency_key` | `text` (UNIQUE) | UUIDv5 deterministic key for idempotency |
| `status` | `enum` | 'posted' (active) or 'voided' (excluded) |
| `created_by` | `uuid` (FK) | Actor user ID (NULL for system events) |
| `currency` | `text` | Always 'IQD' |
| `meta` | `jsonb` | Additional data (fee info, PSP metadata, etc.) |

#### `public.ledger_lines` - Double-Entry Lines

| Column | Type | Purpose / Usage |
| --- | --- | --- |
| `id` | `uuid` (PK) | Line ID |
| `journal_entry_id` | `uuid` (FK) | Parent journal entry |
| `account_id` | `uuid` (FK) | Account being debited/credited |
| `direction` | `enum` | 'DEBIT' or 'CREDIT' |
| `amount` | `numeric` | Always positive |
| `currency` | `text` | Always 'IQD' |

**Key Rule:** Every journal entry must have balanced lines (SUM(DEBITS) == SUM(CREDITS)).

#### `public.withdrawal_requests` - Withdrawal Tracking

| Column | Type | Purpose / Usage |
| --- | --- | --- |
| `id` | `uuid` (PK) | Request ID |
| `user_id` | `uuid` (FK) | Requester |
| `status` | `enum` | 'requested', 'processing', 'completed', 'failed', 'canceled' |
| `amount` | `numeric` | Request amount |
| `gateway_provider` | `text` | Payment gateway used |
| `gateway_payment_id` | `text` | Gateway payment reference |

### 2.2 Wallet Views

#### `vw_wallet_balances_user` - User Balance Aggregation

Security: `security_invoker = on` (user only sees their own data)

Columns:
- `user_id` - Current user ID
- `currency` - 'IQD'
- `available_balance` - Sum of user_available account
- `pending_withdrawal_balance` - Sum of user_pending_withdrawal account
- `held_balance` - Calculated from entity-linked escrow events

#### `vw_wallet_activity_user` - Transaction History

Security: `security_invoker = on`

**As of migration `20260307160000_wallet_activity_include_spent`**, the view includes both credits to the user and **debits (spent)**: `user_available` DEBIT and `user_pending_withdrawal` DEBIT (e.g. `gateway_escrow`), so clients see a full money story. See diagram 21 and SUPABASE_SETUP §6.6.

Columns:
- `journal_entry_id` - Transaction ID
- `created_at` - Timestamp
- `event_type` - Type of transaction
- `amount_gross` - Total transaction amount
- `amount_net` - Net amount affecting user
- `fee_amount` - Fee deducted (if any)
- `counterparty_user_id` - Other party in transaction

#### `vw_financial_metrics_realtime` - Platform Metrics

Columns:
- `gmv_iqd` - Total Gross Merchandise Value
- `revenue_iqd` - Total platform revenue (fees)
- `escrow_held_iqd` - Total escrow held
- `platform_cash_iqd` - Platform cash position
- `lifetime_refunds_iqd` - Total refunds issued

## 3. File Inventory

| File | Layer | Description |
| --- | --- | --- |
| `lib/core/services/payment_service.dart` | Interface | Abstract payment service interface |
| `lib/core/services/qicard_payment_service.dart` | Service | QiCard payment gateway implementation |
| `lib/features/wallet/services/wallet_service.dart` | Service | Fetches balances and manages withdrawals |
| `lib/features/wallet/services/ledger_service.dart` | Service | RPC wrapper for ledger operations |
| `lib/features/wallet/models/wallet_balance_model.dart` | Model | Holds `availableBalance`, `heldBalance`, `pendingWithdrawalBalance` |
| `lib/features/wallet/models/wallet_activity_model.dart` | Model | Activity/transaction details |
| `lib/features/wallet/viewmodels/wallet_view_model.dart` | ViewModel | Manages wallet state |
| `lib/features/wallet/view/wallet_screen.dart` | UI | Wallet dashboard and history |
| `lib/features/dashboard/view/tabs/wallet_tab.dart` | UI | Dashboard Wallet tab: total balance, available, Coming Soon withdraw, transaction history (received/spent). Uses WalletViewModel. |
| `lib/features/wallet/utils/transaction_label_helper.dart` | Helper | Human-readable transaction source/destination labels from event type and related entity |
| `lib/features/dashboard/data/dashboard_repository.dart` | Data | Includes ledger-based financial metrics |
| `lib/features/dashboard/models/financial_metrics_model.dart` | Model | Platform financial metrics |

## 4. Approve delivery (single exit point for escrow release)

For **bookings** and **direct offers**, the app releases escrow via a single RPC: `rpc_approve_delivery(entity_type, entity_id)`. The client calls it with `entity_type` = `'booking'` or `'direct_offer'`; the RPC validates ownership, then calls `process_payment_event_ledger('release_with_fee', ...)` with a deterministic idempotency key. Booking flow: `WorkManagementService.approveDelivery()`. Direct offer flow: `DirectOffersService.completeOffer()` → `rpc_approve_delivery(entity_type: 'direct_offer', entity_id)`.

Contract: `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/CONTRACT_rpc_approve_delivery.md`.

## 5. RPC: process_payment_event_ledger

Main RPC for all payment operations. **Never write directly to ledger tables.**

### Parameters
- `p_event_type` - Event type (see event catalog)
- `p_related_entity_type` - Entity type ('booking', 'task_request', 'withdrawal_request', 'direct_offer')
- `p_related_entity_id` - Entity UUID
- `p_idempotency_key` - UUIDv5 deterministic key
- `p_amount_gross` - Amount (optional, read from entity when possible)
- `p_currency` - 'IQD' (default)
- `p_meta` - Additional JSON metadata

### Event Types

| Event | Actor | Effect |
| --- | --- | --- |
| `escrow_hold` | Client | DEBIT user_available, CREDIT platform_escrow |
| `release_with_fee` | Client | DEBIT platform_escrow, CREDIT user_available (provider net), CREDIT platform_revenue (fee). Only lines with amount > 0 are inserted (zero fee → revenue line omitted). Entity status uses explicit enum casts (migrations 20260307–20260308). |
| `refund` | Provider/System | DEBIT platform_escrow, CREDIT user_available (client) |
| `withdrawal_request` | User | DEBIT user_available, CREDIT user_pending_withdrawal |
| `withdrawal_complete` | System | DEBIT user_pending_withdrawal, CREDIT platform_cash |
| `withdrawal_failed` | System | DEBIT user_pending_withdrawal, CREDIT user_available |
| `deposit` | System | DEBIT platform_cash, CREDIT user_available |
| `gateway_escrow` | System | DEBIT user_pending_withdrawal, CREDIT platform_escrow |
| `admin_credit` | System (testing) | DEBIT platform_test_float, CREDIT user_available |

### Error Codes

- `ERR_MISSING_IDEMPOTENCY_KEY` - Idempotency key required
- `ERR_IDEMPOTENCY_REPLAY` - Transaction already processed
- `ERR_GATE_NOT_ALLOWED` - Event not allowed for current status
- `ERR_INSUFFICIENT_FUNDS` - Not enough balance
- `ERR_UNBALANCED_JOURNAL` - Ledger integrity error
- `ERR_ENTITY_NOT_FOUND` - Related entity doesn't exist
- `ERR_CURRENCY_MISMATCH` - Only IQD supported
- `ERR_AMOUNT_MISMATCH` - Client amount differs from entity
- `ERR_WITHDRAWAL_AMOUNT_INVALID` - Invalid withdrawal amount

## 6. Usage Snippets

### 6.1 Checking Balance

```dart
final balance = await walletService.getWalletBalance();
print('Available: ${balance.availableBalance}');
print('Pending Withdrawal: ${balance.pendingWithdrawalBalance}');
print('Held in Escrow: ${balance.heldBalance}');
```

### 6.2 Creating a Withdrawal Request

```dart
final withdrawalId = await walletService.requestWithdrawal(
  amount: 50000, // IQD
);
```

### 5.3 Submitting Ledger Event

```dart
final result = await ledgerService.submitPaymentEvent(
  eventType: 'escrow_hold',
  relatedEntityType: 'booking',
  relatedEntityId: bookingId,
  amountGross: price,
  meta: {'client_id': clientId, 'provider_id': providerId},
);
```

### 5.4 Generating Idempotency Key

```dart
final idempotencyKey = ledgerService.generateIdempotencyKey(
  bookingId,
  'escrow_hold',
);
// Format: UUIDv5(NAMESPACE, 'sline:ledger:{namespace}:{entityId}_{eventType}')
```

## 7. Migration Notes

### Legacy System (Frozen)

The `wallet_transactions` table is **frozen** via trigger:
```sql
-- Any INSERT/UPDATE/DELETE will raise exception
-- "wallet_transactions is frozen. Use process_payment_event_ledger instead."
```

### Ledger Benefits

1. **Double-Entry Accounting** - Every transaction has balanced debits/credits
2. **Audit Trail** - Immutable records with `audit_logs` table
3. **Idempotency** - Safe retry with deterministic keys
4. **Multi-Currency Ready** - Currency column prepared for future expansion
5. **Platform Metrics** - Real-time GMV, Revenue, Escrow calculations

## 8. Testing Checklist

- [ ] **Escrow**: Create booking -> Escrow funds -> Verify `held_balance` increases
- [ ] **Release**: Mark delivered -> Release funds -> Verify `available_balance` increases for provider
- [ ] **Withdrawal**: Request withdrawal -> Verify `available` decreases, `pending_withdrawal` increases
- [ ] **Withdrawal Complete**: Gateway webhook -> Verify `pending_withdrawal` decreases
- [ ] **Withdrawal Failed**: Gateway failure webhook -> Verify funds return to `available`
- [ ] **Idempotency**: Submit same event twice -> Verify only one journal entry created
- [ ] **Insufficient Funds**: Try escrow with low balance -> Verify `ERR_INSUFFICIENT_FUNDS`
- [ ] **Ledger Balance**: Verify SUM(all debits) == SUM(all credits) across all accounts
- [ ] **Audit Trail**: Check `audit_logs` has entry for every payment event

## 9. Security

- **RLS**: Users can only see their own accounts and ledger lines
- **Append-Only**: `journal_entries` and `ledger_lines` cannot be updated or deleted
- **RPC Gate**: All payment events go through `process_payment_event_ledger` with actor validation
- **Idempotency**: Prevents double-spend via unique constraint on `idempotency_key`

## 10. Webhook Integration

Edge Function: `qicard_webhook_handler`

- Verifies RSA signature from QiCard
- Maps QiCard events to ledger events
- Uses deterministic idempotency keys: `qicard:{paymentId}:{eventType}:{status}`
- Required env vars: `QICARD_RSA_PUBLIC_KEY_PEM`, `QICARD_PROVIDER_NAME`

## 11. References

- Plan: `.TODO/PaymentPlan/PLAN_PaymentLedger_2026-02-23.md`
- System Spec: `.TODO/PaymentPlan/PAYMENT_LEDGER_SYSTEM_SPEC.md`
- RPC Migration: `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql`
