# DOCS_SYNC — Diagram 21 & Wallet docs (2026-03-08)

**Workflow:** `.agents/workflows/slinedocs.md`  
**Scope:** Reference integrity, diagram checklist, wallet activity include spent alignment.

---

## 1. Doc files updated

| File | Change |
|------|--------|
| `Sline_everything/AppDigram/All_Diagrams/21_Wallet_System_Escrow_Available_balances.md` | Fixed **Execution log** reference to full path: `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/EXECUTION_LOG_PLAN_WalletEscrowAvailableBalances_2026-03-07.md` (was `.TODO/EXECUTION_LOG_PLAN_WalletEscrowAvailableBalances_2026-03-07.md`). |
| `Sline_everything/Sline_Log.md` | **Wallet Escrow entry:** Plan and Execution Log paths corrected to full paths under `.../21_Wallet_System_Escrow_Available_balances/`. Master Report path corrected to same folder. **New entry:** "Diagram 21 + Wallet activity include spent (2026-03-08)" — diagram full checklist, OLD/NEW diagrams, gateway_escrow, vw_wallet_activity_user include spent; reference fixes; link to this DOCS_SYNC and workflow. |
| `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` | Under `vw_wallet_activity_user`: added sentence that as of migration `20260307160000_wallet_activity_include_spent` the view includes debits (spent) — user_available DEBIT, user_pending_withdrawal DEBIT (e.g. gateway_escrow); reference to diagram 21 and SUPABASE_SETUP §6.6. |

---

## 2. Summary of changes

- **Reference integrity:** All cross-references from diagram 21 and Sline_Log to `.TODO/` now use **full paths** so every referenced file exists (no dead paths).
- **Diagram 21:** Already contained full checklist and NEW/Implemented diagram with gateway_escrow and activity include spent; only the execution log link was wrong and was fixed.
- **Wallet activity:** Migration `20260307160000_wallet_activity_include_spent.sql` and view behaviour are already documented in SUPABASE_SETUP §6.6 and changelog; DEVELOPER_GUIDE Wallet_Feature now explicitly states “include spent” and points to diagram 21 and §6.6.
- **Sline_Log:** New entry records the diagram + docs sync and reference fixes; existing Wallet Escrow entry references are valid.

---

## 3. References validated

| Reference | Location | Status |
|-----------|----------|--------|
| CONTRACT_rpc_approve_delivery.md | Diagram 21, Sline_Log | Path valid under `.../21_Wallet_System_Escrow_Available_balances/` |
| EXECUTION_LOG_PLAN_WalletEscrowAvailableBalances_2026-03-07.md | Diagram 21, Sline_Log | Path fixed to full path in 21 folder |
| PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md | Sline_Log | Path fixed to full path in 21 folder |
| MASTER_REPORT_2026-03-07_WalletEscrowAvailableBalances.md | Sline_Log | Path fixed to full path in 21 folder |
| CHECKLIST_AND_SUMMARY_2026-03-07.md | Diagram 21 | Path valid |
| 20260307160000_wallet_activity_include_spent.sql | Diagram 21, SUPABASE_SETUP, DEVELOPER_GUIDE | File exists under `supabase/migrations/` |
| lib/features/wallet/services/wallet_service.dart | Diagram 21 | Exists |
| lib/features/wallet/viewmodels/wallet_view_model.dart | Diagram 21 | Exists |
| lib/features/work/services/work_management_service.dart | Diagram 21 | Exists |
| lib/features/direct_offers/services/direct_offers_service.dart | Diagram 21 | Exists |

---

## 4. Why each update was needed

- **Diagram 21 execution log path:** The execution log lives in the 21 folder, not at `.TODO` root. Wrong path would break “no dead paths” rule (DocsKeeper §7.1).
- **Sline_Log Plan / Execution Log / Master Report paths:** Same reason; Sline_Log is the master timeline and must reference existing files.
- **Sline_Log new entry:** Any meaningful doc change (diagram checklist, reference fixes, wallet activity behaviour) must be captured with specifics (DocsKeeper §1, §4).
- **DEVELOPER_GUIDE Wallet_Feature:** Diagram 21 and SUPABASE_SETUP already described “include spent”; Wallet_Feature is the developer-facing wallet doc and must state the same behaviour and point to diagram 21 and §6.6 for a single source of truth.

---

## 5. Not changed (already correct)

- **SUPABASE_SETUP.md:** §6.6 and changelog (2.20.1) already document `vw_wallet_activity_user` and migration `20260307160000_wallet_activity_include_spent`. No edit applied.
- **MVP_ROADMAP.md:** No feature completion in this sync; no status change.
- **STRUCTURE.md:** No file/folder renames or moves.
