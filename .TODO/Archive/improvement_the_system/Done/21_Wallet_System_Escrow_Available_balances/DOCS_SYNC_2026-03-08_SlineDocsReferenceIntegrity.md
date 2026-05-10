# DOCS_SYNC — DocsKeeper Reference Integrity & Diagram Standard

**Date:** 2026-03-08  
**Workflow:** `.agents/workflows/slinedocs.md`  
**Trigger:** “Make sure everything up to date using slinedocs”

---

## 1. Doc files updated

| File | Change |
|------|--------|
| `Sline_everything/Sline_Log.md` | Fixed 4 references: `ImplementReady/09_ledger-event-flow` → `Done/09_ledger-event-flow`; `ImplementReady/16_escrow-invariants-idempotency` → `Done/16_escrow-invariants-idempotency`. Added new entry “Docs Sync — Reference Integrity & Diagram Standard (2026-03-08)”. |
| `Sline_everything/DEVELOPER_GUIDE.md` | Ledger event flow (09) path: `ImplementReady/09_ledger-event-flow/` → `Done/09_ledger-event-flow/`. |
| `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` | Event flow and runbook path: `ImplementReady/09_ledger-event-flow/` → `Done/09_ledger-event-flow/`. |
| `Sline_everything/SUPABASE_SETUP.md` | §6.6 `vw_wallet_activity_user`: updated to match migration `20260307160000_wallet_activity_include_spent.sql` (include spent/gateway_escrow, security_invoker, new columns). §17 Changelog: added bullet for this view. Header “Last Updated” extended with wallet activity view and docs reference integrity. |
| `Sline_everything/MVP_ROADMAP.md` | No change required; Wallet row already referenced `Done/09_ledger-event-flow/CONTRACT_ledger_event_flow.md`. |

---

## 2. Summary of changes

- **Reference integrity:** Plans 09 and 16 were moved from `ImplementReady` to `Done`. All references in `Sline_everything/` now point to the correct folders so links resolve.
- **Diagram 09:** Already updated in a prior step to full diagram-doc standard (checklist, OLD + Implemented diagram, refs to Done/09). Confirmed as single source for ledger event flow.
- **SUPABASE_SETUP:** View `vw_wallet_activity_user` was changed by migration `20260307160000_wallet_activity_include_spent.sql`; doc now describes and shows current DDL and changelog entry.

---

## 3. References validated

| Reference | Status |
|-----------|--------|
| `.TODO/improvement_the_system/Done/09_ledger-event-flow/` | ✅ Exists |
| `.TODO/improvement_the_system/Done/09_ledger-event-flow/CONTRACT_ledger_event_flow.md` | ✅ Exists |
| `.TODO/improvement_the_system/Done/09_ledger-event-flow/SMOKE_CHECKLIST_AND_RUNBOOK.md` | ✅ Exists |
| `.TODO/improvement_the_system/Done/16_escrow-invariants-idempotency/` | ✅ Exists |
| `.TODO/improvement_the_system/Done/16_escrow-invariants-idempotency/RUNBOOK_EscrowIdempotency_T1_T2.md` | ✅ Exists |
| `Sline_everything/AppDigram/All_Diagrams/09_ledger-event-flow.md` | ✅ Exists, refs Done/09 |
| `supabase/migrations/20260307160000_wallet_activity_include_spent.sql` | ✅ Exists |

---

## 4. Why each update was needed

- **Sline_Log / DEVELOPER_GUIDE / Wallet_Feature:** Links to 09 and 16 pointed to `ImplementReady`, which no longer contains those plans; updating to `Done` removes dead paths and satisfies DocsKeeper “No Dead Paths” rule.
- **SUPABASE_SETUP §6.6:** The view definition and behavior changed in a migration; doc must match deployed schema and describe “include spent” for Wallet UI and diagram 21.
- **Sline_Log new entry:** Documents this docs sync and reference fix for traceability.

---

## 5. Next / optional

- Leave `.TODO/` internal docs (e.g. Done/09 execution logs) that still mention “ImplementReady” as-is for historical accuracy; only `Sline_everything/` was corrected as the single source of truth for developers.
- Run “reference validation” again after any future moves of plan folders (ImplementReady ↔ Done).
