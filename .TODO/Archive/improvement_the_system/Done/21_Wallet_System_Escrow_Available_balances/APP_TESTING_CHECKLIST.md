# App Testing Checklist (from Git Changes)

Based on `git status` and `git diff --name-only`, this checklist covers all app changes that need verification.

---

## 1. Dashboard Wallet Tab

**Changed files:** `lib/core/app_enums.dart`, `lib/features/dashboard/view/dashboard_screen.dart`, `lib/features/dashboard/view/tabs/wallet_tab.dart` (new), `lib/features/wallet/utils/transaction_label_helper.dart` (new), `test/widget/dashboard/dashboard_screen_test.dart`

| # | Action | Expected |
|---|--------|----------|
| 1.1 | Open app, go to Dashboard | Dashboard loads |
| 1.2 | Confirm tab bar shows 5 tabs: Overview, Bookings, Work, **Wallet**, Inbox | Wallet tab visible between Work and Inbox |
| 1.3 | Tap **Wallet** tab | Tab switches; no crash |
| 1.4 | On Wallet tab: see Total balance, Available to withdraw, Withdraw section | Values shown (or 0); Withdraw shows "Coming Soon" and is disabled |
| 1.5 | Confirm balances never negative | Even with no activity, shows 0, not negative |
| 1.6 | Pull to refresh on Wallet tab | Data reloads (or stays 0) |
| 1.7 | If you have transactions: see "Money received" and "Money spent" with source/destination labels | Labels like "Payment from booking", "Booking payment" |
| 1.8 | If no transactions: see "No transactions yet" | Empty state shown |

---

## 2. Overview Tab (Wallet Snapshot)

**Changed files:** Overview uses `WalletViewModel`; no direct change to overview_tab, but wallet snapshot depends on same ViewModel.

| # | Action | Expected |
|---|--------|----------|
| 2.1 | Open Dashboard, stay on Overview | Wallet snapshot card shows Available + Held (or 0) |
| 2.2 | Confirm snapshot loads without crash | No error |

---

## 3. Direct Offer: Approve and Release

**Changed files:** `lib/features/direct_offers/services/direct_offers_service.dart` (completeOffer now calls `rpc_approve_delivery`)

| # | Action | Expected |
|---|--------|----------|
| 3.1 | As **client**, have a direct offer that is **Delivered** and payment **held** | Offer in correct state |
| 3.2 | Open offer details, tap **Approve & release** (or similar) | Button shows loading; request runs |
| 3.3 | Request succeeds | Offer moves to Completed; freelancer balance increases |
| 3.4 | Tap Approve twice quickly (double-tap) | Only one ledger release; no double credit |
| 3.5 | In logs, search for tag **DirectOffers** | See start, success, or error logs (no print) |

---

## 4. Booking: Approve Delivery

**Changed files:** `lib/features/work/services/work_management_service.dart`, `lib/features/work/view/widgets/review_delivery_modal.dart`, `lib/features/work/viewmodels/work_item_details_view_model.dart` (AppLogger, correlationId)

| # | Action | Expected |
|---|--------|----------|
| 4.1 | As **client**, have a booking that is **Delivered** and payment **held** | Booking in correct state |
| 4.2 | Open work item, tap **Review delivery** → **Approve** | Request succeeds; booking moves to Completed |
| 4.3 | Freelancer balance increases | Check Wallet tab or Wallet screen |
| 4.4 | Double-tap Approve | Only one release; idempotent |
| 4.5 | In logs, search for tag **WorkManagement** or **ReviewDelivery** | See approval logs |

---

## 5. Wallet Screen (Standalone)

**Changed files:** `lib/features/wallet/services/wallet_service.dart` (error logging)

| # | Action | Expected |
|---|--------|----------|
| 5.1 | Open Wallet (from profile or dashboard link) | Screen loads |
| 5.2 | See Available, Escrow/Held (and Pending Withdrawal if any) | Values from server; no NaN |
| 5.3 | Pull to refresh | Balances update |
| 5.4 | Simulate network failure (e.g. airplane mode) and open Wallet | App does not crash; may show 0 or error state |
| 5.5 | In logs on error: search for tag **Wallet** | See warning/error log |

---

## 6. Ledger and Views

**Changed files:** `lib/features/wallet/services/ledger_service.dart`, `lib/core/utils/ledger_forensics.dart` (new), migrations applied

| # | Action | Expected |
|---|--------|----------|
| 6.1 | Wallet balance and activity come from `vw_wallet_balances_user`, `vw_wallet_activity_user` | No use of legacy `wallet_transactions` |
| 6.2 | Run RLS tests | `flutter test test/rls/ledger_rls_test.dart test/rls/view_security_test.dart` passes |

---

## 7. Booking Payment Flow (if applicable)

**Changed files:** `lib/features/booking/*`, `lib/core/services/*` (payment, qicard, demo)

| # | Action | Expected |
|---|--------|----------|
| 7.1 | Create booking, pay via QiCard or Demo | Payment completes; escrow held |
| 7.2 | Provider accepts, delivers | Client can approve |
| 7.3 | Client approves | Escrow released; freelancer balance increases |

---

## 8. Automated Tests (No Device)

| # | Command | Expected | Verified |
|---|---------|----------|----------|
| 8.1 | `flutter test test/widget/dashboard/dashboard_screen_test.dart` | All tests pass (5 tabs) | Yes |
| 8.2 | `flutter test test/unit/wallet/` | Wallet unit tests pass | Yes |
| 8.3 | `flutter test test/rls/ledger_rls_test.dart test/rls/view_security_test.dart` | RLS tests pass | Yes |
| 8.4 | `flutter analyze lib/` | No issues | Yes |

---

## 9. Quick Regression (Critical Paths)

1. **Dashboard:** Open → switch to Wallet tab → see balance/activity.
2. **Direct offer:** Delivered + held → Approve & release → Completed.
3. **Booking:** Delivered + held → Approve → Completed.
4. **Wallet:** Open Wallet screen → see balance; pull to refresh.
5. **Idempotency:** Double-tap Approve on booking or direct offer → no double release.

---

## 10. Log Verification (Optional)

Search console output for:

- `[Wallet]` — WalletTab load, balance fetch errors
- `[DirectOffers]` — completeOffer start, validation, error, success
- `[WorkManagement]` — approveDelivery
- `[ReviewDelivery]` — modal approval

No raw `print()` in these flows.
