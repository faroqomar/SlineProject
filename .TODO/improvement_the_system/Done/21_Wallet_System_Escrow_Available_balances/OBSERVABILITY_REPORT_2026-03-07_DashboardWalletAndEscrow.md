# Observability Report: Dashboard Wallet Tab + Wallet Escrow

**Scope:** Dashboard Wallet Tab + Wallet Escrow Available Balances  
**Date:** 2026-03-07  
**Pipeline:** Observability (2/4)

---

## 1) Files Scanned (Evidence)

- `lib/features/dashboard/view/tabs/wallet_tab.dart`
- `lib/features/wallet/utils/transaction_label_helper.dart`
- `lib/features/wallet/viewmodels/wallet_view_model.dart`
- `lib/features/direct_offers/services/direct_offers_service.dart`
- `lib/features/wallet/services/wallet_service.dart`

---

## 2) Telemetry Gaps

### WalletTab

| Gap | Severity | Recommendation |
|-----|----------|----------------|
| No log when tab loads wallet | LOW | Optional: `AppLogger.d('WalletTab: loading wallet', tag: 'Wallet')` in addPostFrameCallback. Not critical — WalletViewModel.loadWallet already logs on error. |
| No log on refresh | LOW | RefreshIndicator calls vm.loadWallet(); WalletViewModel logs on error. Acceptable. |

### transaction_label_helper

| Gap | Severity | Recommendation |
|-----|----------|----------------|
| Pure function; no logging | N/A | No logging needed for pure label mapping. |

### DirectOffersService (existing)

| Status | Evidence |
|--------|----------|
| OK | AppLogger at start, on validation failure, on RPC error, on success. Tag: DirectOffers. |

### WalletService (existing)

| Status | Evidence |
|--------|----------|
| OK | AppLogger.w on getWalletBalance failure. Tag: Wallet. |

### WalletViewModel (existing)

| Status | Evidence |
|--------|----------|
| OK | AppLogger.e on loadWallet failure. |

---

## 3) What to Log / What NOT to Log

**Log:**
- Wallet load start (optional, debug)
- Wallet load error (already in WalletViewModel)
- Direct offer complete start/success/error (already in DirectOffersService)
- Balance fetch error (already in WalletService)

**Do NOT log:**
- Raw balance amounts (privacy)
- User IDs in logs (use tags/correlation only)
- Full transaction payloads

---

## 4) Correlation Strategy

- Tag `Wallet` for wallet-related flows.
- Tag `DirectOffers` for direct offer flows.
- No request_id in WalletTab (no RPC from tab; ViewModel handles it). Optional: add request_id to ledger p_meta in future (separate plan).

---

## 5) Summary

- **Observability:** Adequate. Critical paths (complete offer, balance fetch, load error) are logged.
- **Gaps:** None blocking. Optional: debug log on WalletTab init.
- **Recommendation:** Proceed to SlineDocs. No mandatory changes.
