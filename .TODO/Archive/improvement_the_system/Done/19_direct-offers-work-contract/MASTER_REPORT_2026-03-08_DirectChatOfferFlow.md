# Master Report: Direct Chat Offer Flow (Orchestrator)

**Date:** 2026-03-08  
**Scope:** DirectChatOfferFlow (06_direct-chat-offer-flow)  
**Plan reference:** `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md`  
**Pipeline:** @Architect → @Observability → @SlineDocs → @CodeGuard (sequential)

---

## A) Executive Summary

| Item | Result |
|------|--------|
| **What was reviewed** | Direct Chat Offer Flow implementation: SQL migrations (direct_offer_flow_harden, direct_offer_guard_rls_ledger, direct_offer_auto_release_cron), Flutter direct_offers feature (model, service, viewmodel, view, tests), and related .TODO artifacts (contract, threat model, migration plan, RLS matrix, execution log). |
| **Overall risk level** | **HIGH** (escrow/RLS/cron) — appropriate for payments; no BLOCKERs. |
| **Final decision** | **Ready** — CodeGuard APPROVED; no pipeline halt. Follow-up items are non-blocking (docs, format, optional trigger extension, observability improvements). |

---

## B) Consolidated Findings (Deduplicated)

Grouped by category with severity, owner agent, paths, and fix recommendation.

### Security

| # | Finding | Severity | Owner | Paths / objects | Fix |
|---|---------|----------|--------|------------------|-----|
| 1 | RLS disputes INSERT: complainant must be party to direct_offer (or task). | — | CodeGuard | `disputes_insert_own`, migration 20260319110000 | **Implemented.** No action. |
| 2 | Trigger blocks price/currency when not sent/unpaid; fee protected by existing immutability trigger. | — | CodeGuard / Architect | `fn_direct_offer_protect_price_currency`, `trg_protect_fee_rate_applied_direct_offers` | **Implemented.** Optional: extend price/currency trigger to also block `fee_rate_applied_bps` for full plan compliance (Architect). |

### Data Integrity

| # | Finding | Severity | Owner | Paths / objects | Fix |
|---|---------|----------|--------|------------------|-----|
| 3 | Release uses fee from row only; idempotency key stable. | — | Architect / CodeGuard | `rpc_approve_delivery`, `run_auto_release_expired_direct_offers` | **Implemented.** No action. |
| 4 | markDelivered sets delivered_at and review_expires_at in one UPDATE. | — | Architect | `direct_offers_service.dart` | **Implemented.** No action. |

### Architecture / MVVM

| # | Finding | Severity | Owner | Paths / objects | Fix |
|---|---------|----------|--------|------------------|-----|
| 5 | No direct Supabase in views; ViewModel → Service only. | — | Architect | `direct_offer_details_screen.dart`, viewmodel, service | **Compliant.** No action. |
| 6 | Single source for default fee/currency (1000 bps, IQD) in app and RPC. | LOW | Architect | `direct_offers_service.dart`, `rpc_approve_delivery` | Optional: shared constant (e.g. core/config) so DB and app stay in sync. |

### Performance

| # | Finding | Severity | Owner | Paths / objects | Fix |
|---|---------|----------|--------|------------------|-----|
| 7 | No N+1; getOffersByIds batched; cron uses FOR UPDATE SKIP LOCKED. | — | CodeGuard | `direct_offers_service.dart`, 20260319120000 | **Implemented.** No action. |
| 8 | Cron query has no dedicated partial index. | LOW | CodeGuard | `run_auto_release_expired_direct_offers` | Optional: add partial index on (status, payment_status, review_expires_at) if direct_offers volume grows. |

### Observability

| # | Finding | Severity | Owner | Paths / objects | Fix |
|---|---------|----------|--------|------------------|-----|
| 9 | No stable event_name in logs; recover success omits payment_request_id. | MED | Observability | `direct_offers_service.dart` | Add payment_request_id to recover success log; consider event_name when adding structured logging. |
| 10 | Pay path: request_id only in LedgerService, not in DirectOffersService. | LOW | Observability | `direct_offers_service.dart`, `ledger_service.dart` | Optionally pass and log request_id in DirectOffersService for pay path correlation. |
| 11 | Cron auto-release: no DB-side logging (no audit_logs/RAISE NOTICE). | LOW | Observability | 20260319120000_direct_offer_auto_release_cron.sql | Consider INSERT INTO audit_logs or RAISE NOTICE for ops visibility. |
| 12 | rejectOffer/cancelOffer: no "offer not found" warning when offer is null. | LOW | Observability | `direct_offers_service.dart` | Add AppLogger.w when offer null for consistency with other flows. |

### Docs / Reference Integrity

| # | Finding | Severity | Owner | Paths / objects | Fix |
|---|---------|----------|--------|------------------|-----|
| 13 | SUPABASE_SETUP §5.14: missing trigger, index, cron; §5.24: missing direct_offer_id, chk_dispute_entity, RLS. | HIGH | SlineDocs | SUPABASE_SETUP.md | Apply doc updates per DOCS_REPORT §3.1 (trigger, index, cron, disputes schema/RLS, changelog). |
| 14 | Direct_Offers_Feature.md: table 2.1 missing new columns; lifecycle §4.5 missing delivered_at, review_expires_at, auto-release. | HIGH | SlineDocs | DEVELOPER_GUIDE/Direct_Offers_Feature.md | Add full column ref or link to §5.14; document delivered_at, review_expires_at, cron; add contract ref; Last Updated. |
| 15 | STRUCTURE.md: no bullet for 20260319* migrations. | HIGH | SlineDocs | STRUCTURE.md | Add Direct Chat Offer Flow hardening bullet (three migrations). |
| 16 | Sline_Log.md: no entry for Direct Chat Offer Flow implementation. | HIGH | SlineDocs | Sline_Log.md | Add entry with plan/execution log links and implemented items. |
| 17 | AppDigram 06_direct-chat-offer-flow: "pending" vs "sent"; direct_offer_status_enum (DB uses text); missing trigger/cron. | MED | SlineDocs | AppDigram/All_Diagrams/06_direct-chat-offer-flow.md | Use "sent"; fix enum ref; add trigger and auto-release; last_verified 2026-03-08. |
| 18 | SUPABASE_SETUP §9.5 rpc_approve_delivery: migration 20260319110000 not listed (fee from row). | MED | SlineDocs | SUPABASE_SETUP.md §9.5 | Add migration ref for direct_offer fee-from-row. |

---

## C) Fix Plan (Ordered, Step-by-Step)

| Step | Owner | Action | Verification |
|------|--------|--------|---------------|
| 1 | Implementer | Run `dart format lib/features/direct_offers/ test/features/direct_offers/` and commit. | `dart format --set-exit-if-changed` exits 0; no diff. |
| 2 | @SlineDocs | Update SUPABASE_SETUP.md: §5.14 (trigger, index, cron), §5.24 (direct_offer_id, chk_dispute_entity, RLS), §9.5 (migration ref), §17 Changelog. | Grep confirms trg_direct_offer_protect_price_currency, run_auto_release_expired_direct_offers, direct_offer_id, 20260319* in doc. |
| 3 | @SlineDocs | Update Direct_Offers_Feature.md: table/column ref, lifecycle (delivered_at, review_expires_at, auto-release), contract ref, Last Updated. | Doc describes cron and new columns; link to 06_direct_offer_contract.md. |
| 4 | @SlineDocs | Update STRUCTURE.md and Sline_Log.md with migration themes and implementation entry. | STRUCTURE has 20260319* bullet; Sline_Log has Direct Chat Offer Flow entry with plan/execution links. |
| 5 | @SlineDocs | Update AppDigram 06_direct-chat-offer-flow.md: sent vs pending, enum ref, trigger, auto-release, last_verified. | Diagram matches implementation; no "direct_offer_status_enum" as type. |
| 6 | @Observability (optional) | Add payment_request_id to recover success log in DirectOffersService. | recoverPaymentAfterCallback success log includes payment_request_id (no PII). |
| 7 | @Architect (optional) | Extend fn_direct_offer_protect_price_currency to block fee_rate_applied_bps when not sent/unpaid (or document that existing immutability trigger covers it). | Plan Phase 1 step 4 fully met; no UPDATE of fee after accept. |
| 8 | Implementer (optional) | Fix or remove test/services/repro_test.dart (avoid_print) for clean flutter analyze. | `flutter analyze` has 0 issues in project (or repro_test excluded). |
| 9 | @CodeGuard (optional) | Re-run review after docs and format applied if release gate required. | CODEGUARD_REVIEW re-run shows no new issues. |

---

## D) Regression Checklist

| Flow | How to test quickly |
|------|----------------------|
| Accept (no payment) | Client accepts offer → row has fee_rate_applied_bps=1000, currency=IQD. |
| Mark delivered | Freelancer marks delivered → row has non-null delivered_at, review_expires_at (now + 3d). |
| Complete (client) | Client completes delivered+held offer → rpc_approve_delivery → payment_status=released, status=completed; ledger fee from row. |
| Auto-release (cron) | Set review_expires_at in past for a delivered+held offer; run SELECT run_auto_release_expired_direct_offers(); row and ledger updated. |
| Price/currency guard | Try UPDATE direct_offers SET price=0 WHERE status='accepted' → trigger raises. |
| Disputes INSERT | As client or freelancer of offer, INSERT into disputes (direct_offer_id, complainant_id, defendant_id, reason) → allowed; as other user → RLS deny. |
| Service tests | `flutter test test/features/direct_offers/direct_offers_service_test.dart` — 3 passed. |

---

## E) Rollback Notes

| Area | Rollback if needed |
|------|--------------------|
| **DB migrations** | Additive only; no column drops. To disable auto-release: remove or unschedule cron job `auto-release-expired-direct-offers`; leave function in place. To revert RLS: restore previous disputes_insert_own (complainant_id only) and re-apply. |
| **Trigger** | DROP TRIGGER trg_direct_offer_protect_price_currency ON direct_offers; function can remain. |
| **App (model/service)** | Revert commits; backend tolerates null new columns. Old app may not set review_expires_at (cron will not auto-release those rows). |
| **Docs** | Revert doc-only commits; no runtime impact. |

---

## Next Actions

1. **Mandatory (before merge if desired):** Step 1 (format and commit); Steps 2–5 (docs) per DOCS_REPORT.
2. **Recommended:** Step 6 (recover log payment_request_id); Step 8 (repro_test).
3. **Optional:** Step 7 (trigger fee_rate_applied_bps); Step 9 (CodeGuard re-run); Step 8 (repro_test).
4. **Edge (out of scope of this review):** Confirm edge `qicard_payment_create_direct_offer` writes payment_request_id, payment_correlation_id, payment_expires_at to direct_offers before redirect (per contract).

---

**Report produced by:** Orchestrator (orchestrator.md)  
**Agent reports:** ARCHITECT_REPORT_2026-03-08_DirectChatOfferFlow.md, OBSERVABILITY_REPORT_2026-03-08_DirectChatOfferFlow.md, DOCS_REPORT_2026-03-08_DirectChatOfferFlow.md, CODEGUARD_REVIEW_2026-03-08_DirectChatOfferFlow.md
