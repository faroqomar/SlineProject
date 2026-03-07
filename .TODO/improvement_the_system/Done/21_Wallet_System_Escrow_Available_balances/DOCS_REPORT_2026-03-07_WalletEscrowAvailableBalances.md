# Docs Report: Wallet Escrow Available Balances

**Scope:** Wallet Escrow Available Balances (PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC)  
**Date:** 2026-03-07  
**Plan:** `.TODO/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md`

---

## 1) Documentation Delta List

| Doc / Area | Change in Code/DB | Doc Update Status | Action |
|------------|-------------------|-------------------|--------|
| Diagram 21 (Wallet System Escrow) | Withdraw = Upcoming; entry point = process_payment_event_ledger / rpc_approve_delivery | **Done** | None |
| CONTRACT_rpc_approve_delivery | New contract for rpc_approve_delivery (params, entity_type, idempotency, direct_offer) | **Done** (in .TODO/.../21_...) | None |
| LIVE_SCAN, RLS_CHECK_MATRIX | New artifacts in .TODO/.../21_... | **Done** | None |
| DEVELOPER_GUIDE / Wallet_Feature | Direct offer completion now via rpc_approve_delivery (not LedgerService for release) | **Pending** | Add one line: direct offer completion uses rpc_approve_delivery |
| SUPABASE_SETUP | rpc_approve_delivery supports direct_offer | **Pending** | Confirm rpc_approve_delivery section lists entity_type including direct_offer |
| Sline_Log | Execution completed; migrations applied | **Optional** | Log entry for Wallet Escrow plan execution and direct_offer RPC |

---

## 2) Reference Integrity Scan

- **Contract references:** CONTRACT_rpc_approve_delivery references SUPABASE_SETUP, 09 ledger contract, work_management_service, direct_offers_service — all paths exist.
- **Diagram 21:** References wallet_balances view (legacy name); diagram text updated to process_payment_event_ledger / rpc_approve_delivery. No broken file refs in diagram.
- **Execution log:** References LIVE_SCAN, CONTRACT, RLS matrix, migration file — all exist.

---

## 3) Required Doc Updates (Ordered)

1. **DEVELOPER_GUIDE.md or Wallet_Feature.md:** State that direct offer “Approve & release” flow calls `rpc_approve_delivery(entity_type: 'direct_offer', entity_id)` (single exit point for escrow release). File: `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` or main DEVELOPER_GUIDE wallet section.
2. **SUPABASE_SETUP.md:** In the section documenting `rpc_approve_delivery`, ensure entity_type is listed as task, booking, **direct_offer**. If missing, add.
3. **Sline_Log.md (optional):** Add entry: Wallet Escrow Available Balances plan executed; rpc_approve_delivery extended with direct_offer; DirectOffersService.completeOffer uses RPC.

---

## 4) Broken Refs / Outdated Statements

- **None** that block the pipeline. Diagram 21 previously said “process_payment_event” as entry point; updated to process_payment_event_ledger / rpc_approve_delivery. No other broken refs found in changed scope.

---

## 5) Summary

- **Doc delta:** Diagram 21 and .TODO artifacts updated. DEVELOPER_GUIDE and SUPABASE_SETUP need small, non-blocking updates for direct_offer and rpc_approve_delivery.
- **Blockers:** None.
- **Recommendation:** Proceed to CodeGuard; apply doc updates in fix plan.
