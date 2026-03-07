# Master Report: Wallet Escrow Available Balances (Orchestrator)

**Scope:** Wallet Escrow Available Balances  
**Plan:** `.TODO/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md`  
**Date:** 2026-03-07  
**Pipeline:** Architect → Observability → SlineDocs → CodeGuard

---

## A) Executive Summary

- **What was reviewed:** All code and artifacts from the Wallet Escrow Available Balances execution: DirectOffersService.completeOffer (switch to rpc_approve_delivery), WalletService.getWalletBalance (error logging), migration 20260307120000 (direct_offer branch in rpc_approve_delivery), test comment update, diagram 21, and .TODO contract/LIVE_SCAN/RLS matrix.
- **Overall risk level:** **LOW.** No security or performance blockers; MVVM and single exit point preserved; CodeGuard APPROVED.
- **Final decision:** **Ready.** Optional doc updates only (non-blocking).

---

## B) Consolidated Findings (Deduplicated)

### Security
| Finding | Severity | Owner | Path / Object | Fix |
|---------|----------|--------|----------------|-----|
| None | — | — | — | — |

### Data Integrity
| Finding | Severity | Owner | Path / Object | Fix |
|---------|----------|--------|----------------|-----|
| None | — | — | — | Idempotency and FOR UPDATE in RPC verified. |

### Architecture / MVVM
| Finding | Severity | Owner | Path / Object | Fix |
|---------|----------|--------|----------------|-----|
| None | — | — | — | Architect: boundaries and single source of truth OK. |

### Performance
| Finding | Severity | Owner | Path / Object | Fix |
|---------|----------|--------|----------------|-----|
| None | — | — | — | CodeGuard: no N+1, single RPC. |

### Observability
| Finding | Severity | Owner | Path / Object | Fix |
|---------|----------|--------|----------------|-----|
| None | — | — | — | AppLogger used; no PII. Optional: request_id in p_meta later. |

### Docs / Reference Integrity
| Finding | Severity | Owner | Path / Object | Fix |
|---------|----------|--------|----------------|-----|
| DEVELOPER_GUIDE/Wallet_Feature: direct offer completion path not stated | LOW | @SlineDocs | DEVELOPER_GUIDE or Wallet_Feature.md | State that direct offer “Approve & release” uses rpc_approve_delivery(entity_type: 'direct_offer'). |
| SUPABASE_SETUP: rpc_approve_delivery entity_type list | LOW | @SlineDocs | SUPABASE_SETUP.md | Ensure entity_type lists task, booking, direct_offer. |
| Sline_Log: execution not logged | LOW | @SlineDocs | Sline_Log.md | Optional: add entry for Wallet Escrow plan + direct_offer RPC. |

---

## C) Fix Plan (Ordered, Step-by-Step)

| Step | Owner | Action | Verification |
|------|--------|--------|--------------|
| 1 | @SlineDocs | Update DEVELOPER_GUIDE or Wallet_Feature: direct offer completion calls rpc_approve_delivery(entity_type: 'direct_offer', entity_id). | Grep for rpc_approve_delivery and direct_offer in docs; sentence present. |
| 2 | @SlineDocs | In SUPABASE_SETUP, in rpc_approve_delivery section, list entity_type as task, booking, direct_offer. | Read section; three types listed. |
| 3 | @SlineDocs (optional) | In Sline_Log, add line: Wallet Escrow plan executed; rpc_approve_delivery direct_offer; DirectOffersService uses RPC. | Optional. |
| 4 | @CodeGuard | No re-run required unless code or DB changes again. | — |

---

## D) Regression Checklist

- **Critical flows:**  
  - Booking: Pay → Deliver → Approve (rpc_approve_delivery booking) — unchanged.  
  - Direct offer: Pay → Mark delivered → Approve & release (rpc_approve_delivery direct_offer) — now via RPC; E2E: complete offer and check ledger + offer status.  
  - Wallet: Open wallet screen, balance from vw_wallet_balances_user — unchanged; error path now logged.
- **Quick test:**  
  `flutter test test/rls/ledger_rls_test.dart test/unit/wallet/ test/rls/view_security_test.dart`  
  Plus manual: direct offer delivered → Approve & release → success and balance update.

---

## E) Rollback Notes

- **App:** Revert DirectOffersService.completeOffer to use LedgerService.submitPaymentEvent for release_with_fee + direct_offer (previous implementation). Revert WalletService getWalletBalance error log if desired.
- **DB:** Revert migration 20260307120000 (replace rpc_approve_delivery with version that has only task + booking branches). No data backfill.
- **Docs:** Revert diagram 21 and any DEVELOPER_GUIDE/SUPABASE_SETUP changes from this plan.

---

## F) Next Actions

1. **Optional:** Apply doc updates (Steps 1–3 above).  
2. **No code or migration changes required** for approval; pipeline is **Ready**.  
3. If deploying to production: run regression checklist once; then deploy.
