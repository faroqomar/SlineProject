# SlineDocs Report: Hardened Payment Linking

**Scope:** Hardened Payment Linking System (24)  
**Plan:** `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Agent:** @SlineDocs (per orchestrator pipeline)

---

## 1. Documentation delta list

| Doc | Required update | Status |
|-----|-----------------|--------|
| **SUPABASE_SETUP.md** | Document payment_intents (signature, currency, paid_at), payment_events (RLS, append-only trigger), orphan_payments (investigated); process_payment_event_ledger / process_gateway_escrow_direct_offer storing payment_intent_id in journal_entries.meta. | **Pending** — noted in execution log Phase 5; not yet updated. |
| **DEVELOPER_GUIDE.md** | Hardened flow: intent path in webhook, payment_events audit, ledger meta.payment_intent_id, Realtime subscription when intent_id present; reference CONTRACT and LOGGING_AND_SECRETS. | **Pending** — execution log recommends update in next docs pass. |
| **STRUCTURE.md** | No structural change to lib/; optional note that payment flow uses payment_intents + payment_events. | **Optional** |
| **MVP_ROADMAP.md** | If Hardened Payment Linking is a tracked item, mark Phase 1–4 done and Phase 5 (HMAC) deferred. | **Optional** |

---

## 2. Reference integrity scan

| Reference | Location | Valid |
|-----------|----------|--------|
| CONTRACT_HardenedPaymentLinking.md | 24_hardened_paymentLinking_system/ | Yes; contract matches implementation (p_meta for ledger, no new RPC param). |
| LOGGING_AND_SECRETS.md | 24_hardened_paymentLinking_system/ | Yes; Flutter/Edge rules followed. |
| DECISION_CanonicalCreateAndWebhook.md | 24_hardened_paymentLinking_system/ | Yes; D1/D2/D3 recorded. |
| PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md | .TODO/ | Yes; phases and gates referenced in execution log. |
| DEVELOPER_GUIDE.md (Hardened Payment Gateway) | Sline_everything/DEVELOPER_GUIDE.md | Existing section 2.20; does not yet describe intent path in webhook or meta.payment_intent_id. **Update recommended.** |
| SUPABASE_SETUP.md (tables) | Sline_everything/SUPABASE_SETUP.md | payment_intents, payment_events, orphan_payments likely mentioned; new columns and RLS/trigger not yet documented. **Update recommended.** |

---

## 3. Outdated statements (to fix)

- **DEVELOPER_GUIDE.md:** If it states that "only finalize_payment_webhook" or "create_payment_intent only" is used, align with decision: canonical webhook = qicard_webhook_handler with intent path; create remains qicard_payment_create / qicard_payment_create_direct_offer until HMAC migration.
- **SUPABASE_SETUP.md:** Add migration refs 20260308200000 and 20260308200100 and list new columns/policies/trigger and ledger meta behavior.

---

## 4. Required doc updates (ordered)

1. **SUPABASE_SETUP.md:** Add subsection for Hardened Payment Linking: tables payment_intents (signature, currency, paid_at), payment_events (RLS service_role INSERT only, trigger append-only), orphan_payments (investigated); RPCs persist payment_intent_id in journal_entries.meta when provided in p_meta; migrations 20260308200000, 20260308200100.
2. **DEVELOPER_GUIDE.md:** In Hardened Payment Gateway (or payment) section: add intent path (webhook looks up intent, inserts payment_events, validates amount, calls ledger with payment_intent_id in meta); Realtime subscription when intent_id present; reference CONTRACT and LOGGING_AND_SECRETS in improvement folder.
3. **Execution log:** Already notes "Update SUPABASE_SETUP.md and DEVELOPER_GUIDE when doing next docs pass." No further change required in execution log.

---

## 5. Conclusion

- **Documentation delta:** Two main docs need updates (SUPABASE_SETUP, DEVELOPER_GUIDE); improvement folder and plan refs are intact.
- **Blockers:** None. Doc updates are follow-up work; do not block merge.
