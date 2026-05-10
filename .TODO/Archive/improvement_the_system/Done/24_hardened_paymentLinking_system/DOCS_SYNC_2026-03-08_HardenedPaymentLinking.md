# Docs Sync: Hardened Payment Linking (2026-03-08)

**Workflow:** `.agents/workflows/slinedocs.md`  
**Scope:** Ensure all Sline_everything docs and .TODO references are up to date after Hardened Payment Linking implementation.

---

## 1. Doc files updated

| File | Changes |
|------|---------|
| **Sline_everything/Sline_Log.md** | Added top-level entry "Hardened Payment Linking (2026-03-08)" with Implemented (DB, Edge, App), Impact, Verification (plan, execution log, master report, orchestrator reports, checklist), Technical Notes. |
| **Sline_everything/MVP_ROADMAP.md** | QiCard integration row: status set to ✅ Completed; notes updated to describe Hardened Payment Linking (intent path, payment_events, ledger meta, Realtime, migrations). Current Focus: item 1 updated to optional HMAC + Admin Orphan Queue/Trace. |
| **Sline_everything/STRUCTURE.md** | Added migration bullet "Hardened Payment Linking (2026-03-08)" (20260308200000, 20260308200100, webhook intent path, bookin_payment paymentIntentId, plan/execution refs). Last Updated line updated. |
| **Sline_everything/ARCHITECTURE_ANALYSIS.md** | Extended Hardened Payment Gateway (v2.20) bullet with Hardened Payment Linking (2026-03-08): webhook intent path, payment_events audit, journal_entries.meta payment_intent_id, Realtime subscription, plan ref. |
| **Sline_everything/SUPABASE_SETUP.md** | *(Already updated in prior fix pass)* §5.23–5.25 payment_intents/payment_events/orphan_payments, Quick Reference, Key Business Rules, journal_entries meta note. |
| **Sline_everything/DEVELOPER_GUIDE.md** | *(Already updated in prior fix pass)* Hardened Payment Gateway section rewritten (§1–5): overview, DB mapping ref to SUPABASE_SETUP, webhook intent path, Flutter flow, security; CONTRACT/LOGGING refs. |

---

## 2. Summary of changes

- **Sline_Log:** New versioned entry so Hardened Payment Linking is in the master timeline with plan, execution log, master report, and checklist refs.
- **MVP_ROADMAP:** QiCard integration marked completed with Hardened Payment Linking details; roadmap status matches implementation.
- **STRUCTURE:** Migration history and plan/execution refs added so structure doc reflects latest payment hardening.
- **ARCHITECTURE_ANALYSIS:** One-line traceability from architecture to Hardened Payment Linking plan and behavior.

No new code or DB changes in this sync; only documentation and cross-references.

---

## 3. References validated

| Reference | Exists |
|-----------|--------|
| `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md` | ✅ |
| `.TODO/PLAN_HardenedPaymentLinking_2026-03-08.md` | ✅ |
| `.TODO/EXECUTION_LOG_HardenedPaymentLinking_2026-03-08.md` | ✅ |
| `.TODO/MASTER_REPORT_2026-03-08_HardenedPaymentLinking.md` | ✅ |
| `.TODO/ARCHITECT_REPORT_2026-03-08_HardenedPaymentLinking.md` | ✅ |
| `.TODO/OBSERVABILITY_REPORT_2026-03-08_HardenedPaymentLinking.md` | ✅ |
| `.TODO/DOCS_REPORT_2026-03-08_HardenedPaymentLinking.md` | ✅ |
| `.TODO/CODEGUARD_REVIEW_2026-03-08_HardenedPaymentLinking.md` | ✅ |
| `.TODO/improvement_the_system/ImplementReady/24_hardened_paymentLinking_system/CHECKLIST_AND_SUMMARY.md` | ✅ |
| `.TODO/improvement_the_system/ImplementReady/24_hardened_paymentLinking_system/CONTRACT_HardenedPaymentLinking.md` | ✅ |
| `.TODO/improvement_the_system/ImplementReady/24_hardened_paymentLinking_system/LOGGING_AND_SECRETS.md` | ✅ |
| `supabase/migrations/20260308200000_hardened_payment_linking_schema.sql` | ✅ |
| `supabase/migrations/20260308200100_hardened_payment_ledger_meta_payment_intent_id.sql` | ✅ |
| `supabase/functions/qicard_webhook_handler/` | ✅ |
| `supabase/functions/_shared/bookin_payment.ts` | ✅ |
| `lib/core/services/qicard_payment_service.dart` | ✅ |
| `lib/core/services/payment_service.dart` | ✅ |
| `lib/features/booking/view/payment_webview_screen.dart` | ✅ |
| `lib/features/direct_offers/view/direct_offer_details_screen.dart` | ✅ |
| `lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart` | ✅ |

---

## 4. Why each update was needed

- **Sline_Log:** DocsKeeper workflow requires every meaningful change to be in the master log with plan/execution/verification refs.
- **MVP_ROADMAP:** QiCard hardening is complete for the intent path and Realtime; status must be ✅ and notes must match reality.
- **STRUCTURE:** Migration list must include 20260308200000 and 20260308200100 and link to plan/execution for discoverability.
- **ARCHITECTURE_ANALYSIS:** High-level architecture doc should reference the latest payment hardening and plan for traceability.
- **SUPABASE_SETUP / DEVELOPER_GUIDE:** Already updated in the earlier “fix everything in the report” pass; no further change in this sync.

---

## 5. Output

- This file: `.TODO/DOCS_SYNC_2026-03-08_HardenedPaymentLinking.md`
- All referenced paths checked; no broken references found.
