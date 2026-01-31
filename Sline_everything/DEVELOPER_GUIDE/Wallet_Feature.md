# Wallet Feature Reference

## 1. Human Explanation

The Wallet feature provides a financial dashboard for Freelancers (and Clients). It implements the "Pay-First" flow visualization where funds can be in two states:
1.  **Held (Escrow)**: Funds linked to an active booking/task that are not yet released.
2.  **Available**: Funds released to the user that are ready for withdrawal.

The feature relies on a single ledger table `wallet_transactions` and provides clarity via a secure database view `wallet_balances`.

## 2. Database & Supabase Mapping

### 2.1 `public.wallet_transactions`

| Column | Type | Purpose / Usage |
| --- | --- | --- |
| `id` | `uuid` (PK) | Transaction ID |
| `user_id` | `uuid` (FK) | Owner of the funds |
| `amount` | `numeric` | Amount (always positive) |
| `type` | `text` | 'escrow', 'release', 'refund', 'deposit', 'withdrawal' |
| `status` | `text` | 'held', 'released', 'completed', 'refunded' |

### 2.2 `public.wallet_balances` (VIEW)

A secure view (`security_invoker=on`) that aggregates balances.

```sql
select 
  user_id,
  coalesce(sum(amount) filter (where status = 'held'), 0) as held_balance,
  coalesce(sum(amount) filter (where status = 'released'), 0) as available_balance
from public.wallet_transactions
group by user_id;
```

## 3. File Inventory

| File | Layer | Description |
| --- | --- | --- |
| `lib/features/wallet/data/wallet_repository.dart` | Data | Exposes `getWalletBalance()` and `getTransactions()`. |
| `lib/features/wallet/data/wallet_service.dart` | Service | Fetches from View and Table. |
| `lib/features/wallet/models/wallet_balance_model.dart` | Model | Holds `availableBalance` and `heldBalance`. |
| `lib/features/wallet/models/wallet_transaction_model.dart` | Model | Transaction details. |
| `lib/features/wallet/viewmodels/wallet_view_model.dart` | ViewModel | Manages state. |
| `lib/features/wallet/view/wallet_screen.dart` | UI | Split balance display + History list. |

## 4. Usage Snippets

### 4.1 Checking Balance

```dart
final balance = await repository.getWalletBalance();
print('Available: ${balance.availableBalance}');
print('Escrow: ${balance.heldBalance}');
```

## 5. Testing Checklist

- [ ] **Escrow**: Create booking (Paid Request) -> Verify "Pending Escrow" increases.
- [ ] **Release**: Complete booking -> Verify "Pending Escrow" decreases, "Available" increases.
- [ ] **Data Integrity**: Ensure View sums match local transaction logic.
