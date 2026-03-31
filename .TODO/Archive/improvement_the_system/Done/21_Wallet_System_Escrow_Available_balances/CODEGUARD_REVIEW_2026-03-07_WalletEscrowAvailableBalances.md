# CodeGuard Review: Wallet Escrow Available Balances

**Scope:** Wallet Escrow Available Balances (PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC)  
**Date:** 2026-03-07  
**Plan:** `.TODO/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md`  
**Risk level:** MEDIUM (wallet/escrow flow, RPC change)

---

## 1) Files Reviewed (Evidence)

- `lib/features/direct_offers/services/direct_offers_service.dart` (completeOffer)
- `lib/features/wallet/services/wallet_service.dart` (getWalletBalance)
- `supabase/migrations/20260307120000_rpc_approve_delivery_direct_offer.sql`
- `test/rls/view_security_test.dart` (comment)
- Contract and execution log referenced.

---

## 2) Security

- **RLS / AuthZ:** rpc_approve_delivery is SECURITY DEFINER; direct_offer branch enforces `v_client_id != v_uid` (auth.uid() = direct_offers.client_id). No client-supplied user id; actor from session only. **OK.**
- **Secrets / PII:** No secrets or PII in app logs (offerId only). **OK.**
- **Ledger writes:** Only via process_payment_event_ledger from RPC; no direct INSERT from app. **OK.**
- **Verdict:** No security blockers.

---

## 3) Performance

- **N+1:** completeOffer does getOffer() then one RPC; no loop. **OK.**
- **Wallet:** getWalletBalance is single view query; no change. **OK.**
- **Migration:** Adds one function replacement; no new indexes or heavy queries. **OK.**
- **Verdict:** No performance blockers.

---

## 4) Compatibility

- **Flutter/Dart:** No new dependencies. AppLogger and Supabase client usage unchanged. **OK.**
- **Supabase:** RPC signature unchanged (entity_type, entity_id); additive branch. Older app versions that do not send direct_offer are unaffected. **OK.**
- **Verdict:** No compatibility blockers.

---

## 5) Best Practices / SLine Compliance

- **MVVM:** Service layer only calls RPC; no view → Supabase. **OK.**
- **Single source of truth:** Escrow release for direct offer goes through single RPC. **OK.**
- **Tests:** Ledger RLS tests and wallet unit tests exist and pass. **OK.**

---

## 6) Verification Commands

```bash
flutter analyze lib/features/direct_offers/services/direct_offers_service.dart lib/features/wallet/services/wallet_service.dart
flutter test test/rls/ledger_rls_test.dart test/unit/wallet/ test/rls/view_security_test.dart
```

(Already run during execution; both clean.)

---

## 7) Risk Rating

| Area       | Rating | Notes                                      |
|------------|--------|--------------------------------------------|
| Security   | LOW    | RPC enforces client_id; no PII in logs     |
| Performance| LOW    | Single RPC, single view read                |
| Compatibility | LOW | Additive RPC branch                        |
| Data integrity | LOW | Idempotency in RPC; FOR UPDATE in branch  |

---

## 8) Blockers

- **None.**

---

## 9) Decision

**APPROVED ✅**

No BLOCKER; no Critical or High issues. Safe to merge pending doc updates (see DOCS_REPORT). CodeGuard does not block pipeline.
