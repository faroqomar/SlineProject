# Architect Report: Wallet Escrow Available Balances

**Scope:** Wallet Escrow Available Balances (PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC)  
**Date:** 2026-03-07  
**Plan:** `.TODO/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md`

---

## 1) Files Scanned (Evidence)

- `lib/features/direct_offers/services/direct_offers_service.dart` (completeOffer)
- `lib/features/wallet/services/wallet_service.dart` (getWalletBalance)
- `supabase/migrations/20260307120000_rpc_approve_delivery_direct_offer.sql`
- `test/rls/view_security_test.dart` (comment only)
- `Sline_everything/AppDigram/All_Diagrams/21_Wallet_System_Escrow_Available_balances.md`
- Contract: `.TODO/.../21_Wallet_System_Escrow_Available_balances/CONTRACT_rpc_approve_delivery.md`

---

## 2) Architecture / Logic Findings

### MVVM boundary check

- **View layer:** No changes. Wallet and direct offer screens use ViewModels only; no new direct Supabase calls from view.
- **ViewModel layer:** DirectOfferDetailsViewModel already had `completeInProgress` and calls `_directOffersService.completeOffer()`; no change. Work approval uses WorkManagementService.approveDelivery (unchanged).
- **Service layer:** DirectOffersService.completeOffer now calls `_client.rpc('rpc_approve_delivery', ...)` instead of LedgerService.submitPaymentEvent. Single exit point for escrow release is preserved; contract aligns with CONTRACT_rpc_approve_delivery.
- **Verdict:** MVVM boundaries respected. No view → Supabase; service is single source for RPC.

### Data flow map

- **Direct offer complete:** UI → DirectOfferDetailsViewModel.completeOffer() → DirectOffersService.completeOffer() → Supabase RPC `rpc_approve_delivery(entity_type: 'direct_offer', entity_id)`. RPC (SECURITY DEFINER) validates client_id = auth.uid(), then process_payment_event_ledger('release_with_fee', 'direct_offer', ...). No duplicate ledger path.
- **Wallet balance:** Unchanged: ViewModel → WalletRepository → WalletService → `vw_wallet_balances_user`. getWalletBalance now logs on error (warning level); still returns zero on failure (no throw).
- **Verdict:** Single source of truth per concept; no duplicate query paths introduced.

### Contract checks

- RPC params: `entity_type`, `entity_id` (snake_case) match contract and Supabase convention. Flutter sends `entity_type: 'direct_offer'`, `entity_id: offerId` (string UUID). Contract specifies `entity_type` one of task, booking, direct_offer — **match**.
- Canonical views: WalletService uses `vw_wallet_balances_user` and `vw_wallet_activity_user` only; no `wallet_transactions`. **Match** contract and LIVE_SCAN.

### Path / name validation

- All referenced paths exist: DirectOffersService, WalletService, rpc_approve_delivery, direct_offers table, vw_wallet_balances_user, vw_wallet_activity_user.
- Migration references public.direct_offers, process_payment_event_ledger — exist in schema.

---

## 3) Proposed Refactors (None Required)

- No refactors required for this change set. Optional: consider extracting a small shared “approve delivery” RPC caller if booking and direct_offer call sites grow (currently WorkManagementService and DirectOffersService each call RPC; acceptable).

---

## 4) Risks / Notes

- **LOW:** DirectOffersService no longer uses LedgerService for completeOffer; idempotency is enforced entirely in RPC. Consistent with plan (single exit via rpc_approve_delivery).
- **LOW:** getWalletBalance swallows errors and returns zero after logging. Existing behavior; no change to throwing semantics.

---

## 5) Summary

- **Architecture:** Compliant. MVVM preserved; single exit for escrow release; contract and paths validated.
- **Blockers:** None.
- **Recommendation:** Proceed to Observability and Docs review.
