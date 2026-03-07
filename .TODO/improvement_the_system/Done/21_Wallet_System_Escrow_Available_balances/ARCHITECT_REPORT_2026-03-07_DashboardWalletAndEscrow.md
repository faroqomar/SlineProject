# Architect Report: Dashboard Wallet Tab + Wallet Escrow

**Scope:** Dashboard Wallet Tab + Wallet Escrow Available Balances  
**Plans:** Dashboard Wallet Tab plan; PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC  
**Date:** 2026-03-07  
**Pipeline:** Architect (1/4)

---

## 1) Files Scanned (Evidence)

**Dashboard Wallet Tab (new):**
- `lib/features/dashboard/view/tabs/wallet_tab.dart`
- `lib/features/wallet/utils/transaction_label_helper.dart`
- `lib/core/app_enums.dart` (DashboardTab.wallet)
- `lib/features/dashboard/view/dashboard_screen.dart`
- `test/widget/dashboard/dashboard_screen_test.dart`

**Wallet Escrow (existing):**
- `lib/features/direct_offers/services/direct_offers_service.dart` (completeOffer)
- `lib/features/wallet/services/wallet_service.dart` (getWalletBalance)
- `lib/features/wallet/viewmodels/wallet_view_model.dart`
- `lib/features/wallet/data/wallet_repository.dart`

---

## 2) Architecture / Logic Findings

### MVVM boundary check

- **WalletTab (View):** Uses `Consumer<WalletViewModel>` and `context.read<WalletViewModel>()`. No direct Supabase calls. Loads wallet via ViewModel.loadWallet(). **Compliant.**
- **transaction_label_helper:** Pure function; no side effects. **Compliant.**
- **DirectOffersService.completeOffer:** Calls RPC only; no direct ledger writes. **Compliant.**
- **WalletViewModel:** Uses WalletRepository → WalletService; no direct Supabase in ViewModel. **Compliant.**
- **Verdict:** MVVM boundaries respected. No view → Supabase; single source of truth via WalletViewModel.

### Data flow map

- **WalletTab:** Tab init → `WalletViewModel.loadWallet()` → WalletRepository → WalletService → `vw_wallet_balances_user`, `vw_wallet_activity_user`. Same path as OverviewTab wallet snapshot and WalletScreen. **Single source of truth.**
- **Transaction labels:** `getTransactionSourceOrDestination` and `isReceivedTransaction` are pure; no DB. **OK.**
- **Direct offer complete:** Unchanged from prior report; RPC single exit. **OK.**

### Contract checks

- **DashboardTab enum:** `overview, bookings, activeWork, wallet, inbox` — wallet at index 3. TabBar and TabBarView length = 5. **Match.**
- **WalletViewModel:** Already provided at app level (main.dart); WalletTab consumes it. **OK.**
- **Balance clamp:** `_clamp(value)` uses `value.clamp(0.0, double.infinity)`. Non-negative display enforced. **Match plan.**

### Path / name validation

- All paths exist: wallet_tab.dart, transaction_label_helper.dart, WalletViewModel, WalletRepository, WalletService, vw_wallet_balances_user, vw_wallet_activity_user.
- DashboardScreen imports wallet_tab; TabBarView includes WalletTab(). **OK.**

---

## 3) Proposed Refactors (None Required)

- No refactors required. WalletTab correctly reuses WalletViewModel; no duplicate data layer.

---

## 4) Risks / Notes

- **LOW:** WalletTab and OverviewTab both trigger loadWallet() on init. Both use same WalletViewModel; second load overwrites first. Acceptable (Overview loads on dashboard entry; Wallet loads when tab switched). No duplicate network if user stays on Overview.
- **LOW:** transaction_label_helper default case uses `e.substring(1)` — safe when `e.isEmpty` returns ''; `e[0]` would throw on empty. The `e.isEmpty ? '' : ...` guard prevents that. **OK.**

---

## 5) Summary

- **Architecture:** Compliant. MVVM preserved; single source of truth; no new Supabase calls from views.
- **Blockers:** None.
- **Recommendation:** Proceed to Observability and Docs review.
