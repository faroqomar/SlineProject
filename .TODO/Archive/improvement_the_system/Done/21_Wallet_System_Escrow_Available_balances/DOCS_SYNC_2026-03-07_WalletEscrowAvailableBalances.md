# DOCS_SYNC — Wallet Escrow Available Balances (direct_offer in rpc_approve_delivery)

**Date:** 2026-03-07  
**Scope:** Post-execution documentation sync for Plan 21 (Wallet System Escrow / Available Balances).  
**Workflow:** `.agents/workflows/slinedocs.md`

---

## 1. Doc files updated (this session)

| File | Change | Why |
|------|--------|-----|
| `Sline_everything/DEVELOPER_GUIDE.md` | RPC table row for `rpc_approve_delivery`: added entity_type (task, booking, direct_offer), stable idempotency wording, link to Wallet_Feature §4 and SUPABASE_SETUP §9.5. | Single source of truth for approve-delivery; direct_offer is now in scope. |
| `Sline_everything/DEVELOPER_GUIDE.md` | §2.3 Balance View: renamed to **`vw_wallet_balances_user`** (canonical user-scoped view); noted app uses this only; added `vw_wallet_activity_user` and link to Wallet_Feature. | App and RLS use user-scoped views; avoids confusion with non-user views. |
| `Sline_everything/MVP_ROADMAP.md` | Wallet and ledger row: added 2026-03-07 bullet (direct_offer in rpc_approve_delivery, DirectOffersService.completeOffer → RPC); linked PLAN_CRITIC, EXECUTION_LOG, Wallet_Feature §4, 09 contract; noted Withdraw = Upcoming. | Roadmap reflects current wallet/escrow completion state and traceability. |

**Already updated in prior steps (no further edit):**

- `Sline_everything/Sline_Log.md` — entry "Wallet Escrow Available Balances — direct_offer in rpc_approve_delivery (2026-03-07)".
- `Sline_everything/SUPABASE_SETUP.md` — §9.5 parameters and direct_offer branch, migration `20260307120000_rpc_approve_delivery_direct_offer.sql`.
- `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` — §4 Approve delivery (single exit), §5 process_payment_event_ledger, direct_offer in p_related_entity_type, renumbered §6–§11.
- `Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md` — completeOffer uses `rpc_approve_delivery(entity_type: 'direct_offer')`, file inventory.
- `Sline_everything/AppDigram/All_Diagrams/21_Wallet_System_Escrow_Available_balances.md` — Withdraw = Upcoming, entry point wording.

---

## 2. References validated

- `.TODO/PLAN_WalletEscrowAvailableBalances_2026-03-07.md` ✅  
- `.TODO/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md` ✅  
- `.TODO/EXECUTION_LOG_PLAN_WalletEscrowAvailableBalances_2026-03-07.md` ✅  
- `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/CONTRACT_rpc_approve_delivery.md` ✅  
- `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/LIVE_SCAN_2026-03-07.md` ✅  
- `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/RLS_CHECK_MATRIX_wallet_ledger.md` ✅  
- `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/CHECKLIST_AND_SUMMARY_2026-03-07.md` ✅  
- `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow/` (CONTRACT_ledger_event_flow.md, etc.) ✅  
- `DEVELOPER_GUIDE/Wallet_Feature.md`, `DEVELOPER_GUIDE/Direct_Offers_Feature.md` ✅  
- `lib/features/wallet/`, `lib/features/direct_offers/services/direct_offers_service.dart` ✅  

No broken paths found; no DOCS_REFERENCE_FIX required.

---

## 3. Summary of changes (full doc delta for Plan 21)

- **RPC contract:** `rpc_approve_delivery` supports `entity_type`: task, booking, direct_offer; idempotency via stable key + FOR UPDATE; single exit for escrow release.
- **App:** `DirectOffersService.completeOffer()` calls `rpc_approve_delivery(entity_type: 'direct_offer', entity_id)` (no direct LedgerService.submitPaymentEvent for approval).
- **Views:** Canonical user-facing balance/activity views are `vw_wallet_balances_user` and `vw_wallet_activity_user` (documented in DEVELOPER_GUIDE and Wallet_Feature).
- **Withdraw:** Documented as upcoming feature only; not in scope for this release.

---

## 4. Cross-links (for SlineDocs)

- Plan: `.TODO/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md`  
- Execution log: `.TODO/EXECUTION_LOG_PLAN_WalletEscrowAvailableBalances_2026-03-07.md`  
- Contract: `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/CONTRACT_rpc_approve_delivery.md`  
- Checklist: `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/CHECKLIST_AND_SUMMARY_2026-03-07.md`  
- Master report: `.TODO/MASTER_REPORT_2026-03-07_WalletEscrowAvailableBalances.md`  
- Sline_Log: `Sline_everything/Sline_Log.md` (entry 2026-03-07 Wallet Escrow Available Balances)
