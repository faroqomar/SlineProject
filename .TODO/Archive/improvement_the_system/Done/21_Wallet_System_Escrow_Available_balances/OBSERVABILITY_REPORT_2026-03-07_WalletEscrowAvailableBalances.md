# Observability Report: Wallet Escrow Available Balances

**Scope:** Wallet Escrow Available Balances (PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC)  
**Date:** 2026-03-07  
**Plan:** `.TODO/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md`

---

## 1) Files Scanned (Evidence)

- `lib/features/direct_offers/services/direct_offers_service.dart` (completeOffer logging)
- `lib/features/wallet/services/wallet_service.dart` (getWalletBalance error log)
- `lib/features/work/services/work_management_service.dart` (existing approveDelivery logging — reference)
- `lib/core/services/logger_service.dart` (AppLogger API — reference)

---

## 2) Telemetry Gaps

- **Direct offer complete flow:** Now instrumented with AppLogger at start (info), validation failures (warning with offerId/state), RPC failure (error + stackTrace), and success (info). No PII in logs (offerId is entity id, not user id). **Gap closed.**
- **Wallet getWalletBalance:** Error path now logs with AppLogger.w (tag: Wallet, error: e). Success path does not log (acceptable for high-frequency read). **Gap closed.**
- **Correlation:** No correlation ID or request_id added to these logs. For wallet/escrow flows, tag + offerId/entity_id is sufficient for support. Optional future: add request_id to LedgerService/RPC calls per CONTRACT_ledger_event_flow (p_meta.request_id).

---

## 3) Event Taxonomy (What to Log)

| Event / Location | Level | What to log | What NOT to log |
|------------------|--------|-------------|------------------|
| completeOffer start | info | tag, offerId | client_id, freelancer_id, price |
| completeOffer not client | warning | tag, offerId | user id |
| completeOffer invalid state | warning | tag, offerId, delivered, paymentStatus | user id |
| completeOffer RPC error | error | tag, offerId, error, stackTrace | full response body |
| completeOffer success | info | tag, offerId | |
| getWalletBalance error | warning | tag, error | user id, balance values |

Current implementation matches the above. No secrets, tokens, or raw PII are logged.

---

## 4) Privacy-Safe Logging Plan

- **Implemented:** No user IDs in log messages for completeOffer; only offerId (entity id). Error messages from RPC may contain server text (e.g. "Not authorized"); acceptable.
- **Recommendation:** Keep avoiding logging of client_id/freelancer_id in app logs; RPC and journal_entries.meta already carry them server-side for audit.

---

## 5) Correlation Strategy

- **Current:** Tag-based (DirectOffers, Wallet). For a single complete-offer flow, one can grep by offerId across logs.
- **Optional (future):** Add a request_id (UUID) in DirectOffersService.completeOffer and pass to p_meta when/if app ever calls process_payment_event_ledger directly for this flow again (not required for current RPC path).

---

## 6) Summary

- **Observability:** AppLogger used consistently; no print(); critical paths (complete offer, balance fetch error) covered.
- **Privacy:** No PII in logs.
- **Blockers:** None.
- **Recommendation:** Proceed to DocsKeeper and CodeGuard.
