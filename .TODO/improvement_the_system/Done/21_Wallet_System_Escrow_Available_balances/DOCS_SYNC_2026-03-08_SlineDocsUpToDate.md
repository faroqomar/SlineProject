# Docs Sync: SlineDocs Up To Date (Reference Integrity)

**Date:** 2026-03-08  
**Trigger:** User request — "make sure everything up to date using @.agents/workflows/slinedocs.md"

---

## 1) Doc Files Updated

| Document | Change |
|----------|--------|
| `Sline_everything/Sline_Log.md` | Fixed `.TODO` paths: 16 escrow CONTRACT/RUNBOOK → `Done/16_escrow-invariants-idempotency/`; 21 Contract reference expanded to full path. Added new entry "Docs Sync — Reference Integrity & Diagram Standard (2026-03-08)" with workflow ref and summary. |
| `Sline_everything/MVP_ROADMAP.md` | Wallet/ledger row: all references now full paths — PLAN (ImplementReady/21), EXECUTION_LOG (ImplementReady/21), DEVELOPER_GUIDE, CONTRACT (Done/09). |
| `Sline_everything/SUPABASE_SETUP.md` | Changelog §17 Version 2.20.1: added bullet "Wallet activity — include spent" for migration `20260307160000_wallet_activity_include_spent.sql`. §6.6 already documented the view. |

**Already correct (no change):**

- `Sline_everything/DEVELOPER_GUIDE.md` — 09 path already `Done/09_ledger-event-flow/`.
- `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` — 09 path already `Done/09_ledger-event-flow/`.
- `Sline_everything/AppDigram/All_Diagrams/09_ledger-event-flow.md` — already points to Done/09.
- `Sline_everything/AppDigram/All_Diagrams/16_escrow-invariants-idempotency.md` — already points to Done/16; full checklist applied in prior session.
- `Sline_everything/SUPABASE_SETUP.md` §6.6 — already described vw_wallet_activity_user with 20260307160000 and "spent".

---

## 2) Summary of Changes

- **Reference integrity:** Canonical locations: 09 and 16 under `.TODO/improvement_the_system/Done/`; 21 under `.TODO/improvement_the_system/ImplementReady/`. All cross-references in Sline_Log and DEVELOPER_GUIDE/MVP_ROADMAP aligned to these paths.
- **MVP_ROADMAP:** Replaced shorthand paths with full paths so every link is resolvable without guessing.
- **SUPABASE_SETUP:** Changelog now records the wallet_activity "include spent" migration for 2.20.1.

---

## 3) References Validated

| Reference | Status |
|-----------|--------|
| `.TODO/improvement_the_system/Done/09_ledger-event-flow/CONTRACT_ledger_event_flow.md` | Exists |
| `.TODO/improvement_the_system/Done/09_ledger-event-flow/SMOKE_CHECKLIST_AND_RUNBOOK.md` | Exists |
| `.TODO/improvement_the_system/Done/16_escrow-invariants-idempotency/RUNBOOK_EscrowIdempotency_T1_T2.md` | Exists |
| `.TODO/improvement_the_system/Done/16_escrow-invariants-idempotency/PLAN_EscrowInvariantsIdempotency_2026-03-07_CRITIC.md` | In Done (plan files in same folder) |
| `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/CONTRACT_rpc_approve_delivery.md` | Exists |
| `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md` | Exists |
| `supabase/migrations/20260307160000_wallet_activity_include_spent.sql` | Exists |
| `Sline_everything/AppDigram/All_Diagrams/16_escrow-invariants-idempotency.md` | Exists |
| `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` | Exists |

No dead paths. DB objects (rpc_approve_delivery, vw_wallet_activity_user, journal_entries, etc.) documented in SUPABASE_SETUP.

---

## 4) Why Each Update Was Needed

- **Sline_Log:** Escrow Idempotency and Ledger Event Flow entries must point to the actual folder locations (Done). Contract for 21 must be fully qualified for search and traceability.
- **MVP_ROADMAP:** Full paths prevent broken links when .TODO structure is reorganized and match SlineDocs "no dead paths" rule.
- **SUPABASE_SETUP:** Every DB migration must appear in the changelog; wallet_activity_include_spent was missing.

---

## 5) Versioning

- No version bump. Documentation sync only; code and schema unchanged.

---

**Produced by:** SlineDocs workflow (`.agents/workflows/slinedocs.md`). Documentation is up to date; reference integrity validated.
