# Master Report: Hardened Payment Linking (Orchestrator)

**Scope:** Hardened Payment Linking System (24)  
**Plan:** `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md`  
**Pipeline:** Architect → Observability → SlineDocs → CodeGuard  
**Date:** 2026-03-08

---

## A) Executive Summary

- **What was reviewed:** All code and migrations for the Hardened Payment Linking implementation: webhook intent path (`qicard_webhook_handler`, `bookin_payment`), Flutter payment services and UI (booking checkout, direct offer details, payment webview), schema and RPC migrations, and improvement-folder contracts/logging docs.
- **Overall risk level:** **LOW.** No BLOCKER from any agent.
- **Final decision:** **Ready ✅** — Safe to merge. Follow-up work is docs and optional observability enhancement.

---

## B) Consolidated Findings (Deduplicated)

### Security
| Severity | Owner | Location | Finding | Fix |
|----------|--------|----------|---------|-----|
| — | CodeGuard | — | No security blockers. RLS, input validation, no PII in logs. | None. |

### Data integrity
| Severity | Owner | Location | Finding | Fix |
|----------|--------|----------|---------|-----|
| — | Architect | Webhook | Idempotency and amount check correct; payment_events before ledger. | None. |

### Architecture / MVVM
| Severity | Owner | Location | Finding | Fix |
|----------|--------|----------|---------|-----|
| — | Architect | Flutter views | No direct Supabase in view layer; ViewModel/service used. | None. |

### Performance
| Severity | Owner | Location | Finding | Fix |
|----------|--------|----------|---------|-----|
| — | CodeGuard | Webhook, Flutter | Single queries, stream cancelled on dispose. | None. |

### Observability
| Severity | Owner | Location | Finding | Fix |
|----------|--------|----------|---------|-----|
| LOW | Observability | `qicard_webhook_handler/index.ts` | No structured "outcome" log for intent path success. | Optional: add one log line per outcome (e.g. `intent_path_processed` with intent_id, gateway_event_id, entity_type) for metrics. |

### Docs / reference integrity
| Severity | Owner | Location | Finding | Fix |
|----------|--------|----------|---------|-----|
| MED | SlineDocs | SUPABASE_SETUP.md, DEVELOPER_GUIDE.md | New columns, RLS, trigger, and ledger meta not yet documented. | Update SUPABASE_SETUP (tables, migrations 20260308200000, 20260308200100); DEVELOPER_GUIDE (intent path, Realtime, CONTRACT/LOGGING refs). |

---

## C) Fix Plan (Ordered)

| Step | Owner | Action | Status |
|------|--------|--------|--------|
| 1 | @SlineDocs | Update SUPABASE_SETUP.md: payment_intents (signature, currency, paid_at), payment_events (RLS, append-only trigger), orphan_payments (investigated); migrations; journal_entries.meta.payment_intent_id. | **Done** — §5.23–5.25, Quick Reference, Key Business Rules, journal_entries note. |
| 2 | @SlineDocs | Update DEVELOPER_GUIDE.md: Hardened flow intent path in webhook, payment_events audit, ledger meta; Realtime when intent_id present; reference CONTRACT and LOGGING_AND_SECRETS. | **Done** — §1–5 rewritten; CONTRACT/LOGGING refs added. |
| 3 | @Observability | Add structured outcome log in webhook (intent_path_processed, intent_path_orphan). | **Done** — qicard_webhook_handler logs event + intent_id/gateway_event_id/entity_type or reason. |
| 4 | @CodeGuard | Re-run gate after docs/observability changes (optional). | Pending (no BLOCKER expected). |

---

## D) Regression Checklist

- **Critical flows:** (1) Booking checkout: create payment → open webview → return or Realtime success. (2) Direct offer: create payment → open webview → return or Realtime success. (3) Webhook: QiCard POST with SUCCESS and additionalInfo.intent_id → intent lookup → payment_events insert → amount check → ledger + intent update.
- **Quick test:** Run `flutter analyze` on changed Dart files; run `flutter test`; in staging send a test webhook with intent_id and confirm one payment_events row and journal_entry with meta.payment_intent_id.

---

## E) Rollback Notes

- **Flutter:** Revert payment_webview_screen (optional params), direct_offer_details_screen (intentId/stream), direct_offer_details_view_model (streamPaymentIntentStatus). Booking and direct offer still work via callback URL without Realtime.
- **Edge:** Revert handleIntentBasedPayment and intent-path branch in webhook; legacy path unchanged. Revert bookin_payment.ts paymentIntentId in submit* (meta then omits payment_intent_id).
- **DB:** Migrations are additive. To roll back schema: drop new columns/policies/trigger and revert RPCs to previous version (separate migration). Prefer code revert over DB rollback where possible.

---

## F) Next Actions

1. **Merge:** No blockers; pipeline approves. Proceed with merge when ready.
2. **Docs:** Schedule SUPABASE_SETUP and DEVELOPER_GUIDE updates (Steps 1–2 above).
3. **Optional:** Add structured outcome log in webhook (Step 3); re-run CodeGuard if desired.
4. **Deferred:** HMAC in create edge and webhook signature verification (PAYMENT_HMAC_SECRET) per plan Phase 3 follow-up.
