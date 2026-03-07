# RLS Check Matrix: Wallet & Ledger

**Plan:** PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC  
**Date:** 2026-03-07

---

## Tables

| Object | Role | SELECT | INSERT | UPDATE | DELETE | Notes |
|--------|------|--------|--------|--------|--------|-------|
| journal_entries | authenticated | No (or via view only) | No | No | No | Only RPC/service_role writes |
| ledger_lines | authenticated | No (or via view only) | No | No | No | Only RPC/service_role writes |
| accounts | authenticated | No (or via view only) | No | No | No | Only RPC/service_role writes |
| journal_entries | service_role | Yes | Yes | Yes | Yes | RPC runs as definer |
| ledger_lines | service_role | Yes | Yes | Yes | Yes | |
| accounts | service_role | Yes | Yes | Yes | Yes | |

## Views (user-scoped)

| Object | Role | SELECT | Notes |
|--------|------|--------|-------|
| vw_wallet_balances_user | authenticated | Own row only (auth.uid()) | security_invoker or equivalent |
| vw_wallet_activity_user | authenticated | Own rows only | security_invoker or equivalent |

## Verification

- **Test 1:** Authenticated user SELECT from vw_wallet_balances_user returns only own row. (See test/rls.)
- **Test 2:** Authenticated user INSERT into ledger_lines fails. (See test/rls/ledger_rls_test.dart.)
