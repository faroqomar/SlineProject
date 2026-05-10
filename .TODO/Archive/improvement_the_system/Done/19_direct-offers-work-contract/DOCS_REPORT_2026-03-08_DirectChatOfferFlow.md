# Docs Report: Direct Chat Offer Flow (06_direct-chat-offer-flow)

**Plan reference:** `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md`  
**Execution log:** `.TODO/EXECUTION_LOG_DirectChatOfferFlow_2026-03-07_CRITIC.md`  
**Scope:** DirectChatOfferFlow implementation — documentation delta and reference integrity  
**Date:** 2026-03-08  
**Author:** @DocsKeeper

---

## 1) Documentation delta (required doc updates)

The following updates are required so that `Sline_everything/` and related docs remain the single source of truth for the implemented Direct Chat Offer Flow hardening.

| # | Doc / area | Update required | Priority |
|---|------------|-----------------|----------|
| 1 | **Sline_everything/SUPABASE_SETUP.md** | **§5.14 direct_offers:** Add trigger `trg_direct_offer_protect_price_currency` (function `fn_direct_offer_protect_price_currency`) — blocks UPDATE of price/currency when status != 'sent' or payment_status != 'unpaid'. Add index `idx_direct_offers_processing` (partial: status='accepted' AND payment_status='unpaid' AND payment_request_id IS NOT NULL). Document cron: function `run_auto_release_expired_direct_offers()` and pg_cron job `auto-release-expired-direct-offers` (hourly). Add migration refs: `20260319110000_direct_offer_guard_rls_ledger.sql`, `20260319120000_direct_offer_auto_release_cron.sql`. | High |
| 2 | **Sline_everything/SUPABASE_SETUP.md** | **§5.24 disputes:** Add column `direct_offer_id` (uuid, nullable, FK to direct_offers(id)). Document constraint `chk_dispute_entity`: exactly one of task_id or direct_offer_id must be set. Document RLS policy `disputes_insert_own`: INSERT allowed when complainant_id = auth.uid() and (task_id IS NOT NULL OR (direct_offer_id IS NOT NULL and user is client/freelancer of that offer)). Add migration refs: `20260319000000_direct_offer_flow_harden.sql`, `20260319110000_direct_offer_guard_rls_ledger.sql`. | High |
| 3 | **Sline_everything/SUPABASE_SETUP.md** | **§9.5 rpc_approve_delivery:** In the Migrations line, add `20260319110000_direct_offer_guard_rls_ledger.sql` (direct_offer branch now reads `fee_rate_applied_bps` from direct_offers row and passes it in p_meta to process_payment_event_ledger). | Medium |
| 4 | **Sline_everything/SUPABASE_SETUP.md** | **§17 Changelog:** Add entry (e.g. Version 2.17.3 or under March 2026): Direct Chat Offer Flow hardening — migrations `20260319000000_direct_offer_flow_harden.sql` (currency, payment_*, delivered_at, review_expires_at on direct_offers; direct_offer_id and chk_dispute_entity on disputes), `20260319110000_direct_offer_guard_rls_ledger.sql` (trigger protect price/currency, disputes_insert_own RLS, rpc_approve_delivery fee from row for direct_offer), `20260319120000_direct_offer_auto_release_cron.sql` (run_auto_release_expired_direct_offers + pg_cron). | High |
| 5 | **Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md** | **Table 2.1:** Already omits several columns present in DB and §5.14. Either add missing columns (currency, fee_rate_applied_bps, payment_request_id, payment_gateway_id, payment_correlation_id, payment_expires_at, payment_recovered_at, delivered_at, review_expires_at) or add a single line: "Full column list: see Sline_everything/SUPABASE_SETUP.md §5.14." | High |
| 6 | **Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md** | **Lifecycle / §4.5:** State that Mark Delivered sets `delivered_at` and `review_expires_at` (e.g. now + 3 days). Document auto-release: cron runs `run_auto_release_expired_direct_offers()` so delivered offers with review_expires_at &lt; now() are released automatically (no permanent escrow lock). | High |
| 7 | **Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md** | **Contract reference:** Add reference to `.TODO/06_direct_offer_contract.md` (payment intent, release fee-from-row, disputes.direct_offer_id). | Medium |
| 8 | **Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md** | **Last Updated:** Set to 2026-03-08 (or implementation date). Version v2.17 can stay; note hardening in a short sentence if desired. | Low |
| 9 | **Sline_everything/STRUCTURE.md** | **Recent migration themes:** Add bullet for Direct Chat Offer Flow hardening (Plan DirectChatOfferFlow CRITIC): migrations `20260319000000_direct_offer_flow_harden.sql`, `20260319110000_direct_offer_guard_rls_ledger.sql`, `20260319120000_direct_offer_auto_release_cron.sql` (currency, payment_*, delivered_at, review_expires_at; disputes.direct_offer_id; trigger protect price/currency; RLS disputes_insert_own; rpc_approve_delivery fee from row; cron auto-release). | High |
| 10 | **Sline_everything/Sline_Log.md** | Add master log entry for Direct Chat Offer Flow (Plan Critic) implementation: migrations applied; DirectOffer model and DirectOffersService updated (accept stamps fee/currency, markDelivered sets delivered_at/review_expires_at); tests in test/features/direct_offers/; contract, threat model, migration plan, RLS matrix in .TODO/. Link plan and execution log. | High |
| 11 | **Sline_everything/MVP_ROADMAP.md** | Optional: Under "Direct Chat Offers", add note that hardening (delivered_at, review_expires_at, auto-release cron, disputes.direct_offer_id, fee from row, trigger protect price/currency) was completed per PLAN_DirectChatOfferFlow_2026-03-07_CRITIC. | Low |
| 12 | **Sline_everything/AppDigram/All_Diagrams/06_direct-chat-offer-flow.md** | Align with implementation: (a) Use "sent" for initial state (DB uses `status='sent'`; diagram currently uses "pending"). (b) Add note that delivered → completed can occur via client Approve or via cron when review_expires_at &lt; now(). (c) Add trigger `trg_direct_offer_protect_price_currency`. (d) Remove or correct "direct_offer_status_enum" — DB uses text for status, not an enum. (e) Update last_verified to 2026-03-08. | Medium |

---

## 2) Reference integrity scan

### 2.1 Paths and files verified (exist and correct)

- `lib/features/direct_offers/models/direct_offer_model.dart` — exists; contains currency, feeRateAppliedBps, paymentRequestId, paymentGatewayId, paymentCorrelationId, paymentExpiresAt, paymentRecoveredAt, deliveredAt, reviewExpiresAt.
- `lib/features/direct_offers/services/direct_offers_service.dart` — exists; implementation of accept/markDelivered with new fields per execution log.
- `lib/features/chat/view/widgets/offer_message_bubble.dart` — exists (referenced in Direct_Offers_Feature.md).
- `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md` — exists.
- `.TODO/EXECUTION_LOG_DirectChatOfferFlow_2026-03-07_CRITIC.md` — exists.
- `.TODO/06_direct_offer_contract.md` — exists.
- `.TODO/06_direct_offer_threat_model.md` — present (user-provided list).
- `.TODO/06_direct_offer_migration_plan.md` — present (user-provided list).
- `.TODO/06_direct_offers_rls_matrix.md` — exists.
- `supabase/migrations/20260319000000_direct_offer_flow_harden.sql` — exists.
- `supabase/migrations/20260319110000_direct_offer_guard_rls_ledger.sql` — exists.
- `supabase/migrations/20260319120000_direct_offer_auto_release_cron.sql` — exists.
- `test/features/direct_offers/direct_offers_service_test.dart` — exists (execution log).
- `Sline_everything/SUPABASE_SETUP.md` §5.14 — column list already includes currency, payment_*, delivered_at, review_expires_at (no dead refs).
- `.cursor/` — no direct_offer–specific references found; no broken refs.

### 2.2 Outdated or incorrect statements

- **AppDigram 06_direct-chat-offer-flow.md:** States "direct_offer_status_enum — Implicit mapping". The `direct_offers.status` column is **text** in the schema and migrations, not an enum. This is misleading; either remove the enum reference or document that status is text with implicit transition rules.
- **Direct_Offers_Feature.md table 2.1:** Omits currency, fee_rate_applied_bps, and all payment_* and delivered_at/review_expires_at columns — doc lags implementation and SUPABASE_SETUP §5.14.
- **SUPABASE_SETUP §5.24 disputes:** Table does not list `direct_offer_id` or `chk_dispute_entity`; RLS for disputes INSERT with direct_offer_id is not documented. This invalidates any reader assuming disputes are task-only.
- **SUPABASE_SETUP §5.14 Triggers:** Only `fn_direct_offer_guard` and `fn_direct_offer_guard_insert` are listed. The new trigger `trg_direct_offer_protect_price_currency` is missing; plan assumptions (no post-accept price/currency change) are enforced by it — docs should reflect that.

### 2.3 Plan assumptions vs docs

- **Fee from row:** Plan and contract require release_with_fee for direct_offer to use `fee_rate_applied_bps` from the row. Migration 20260319110000 implements this in `rpc_approve_delivery`. SUPABASE_SETUP §9.5 describes the direct_offer branch but does not list this migration; the assumption is implemented in code but not clearly traceable in docs.
- **Dispute creation (createDisputeForDirectOffer / "Report issue"):** Plan Phase 3/4 marks this as optional/concrete; execution log shows Phase 3 partial and Phase 4/5 not started. Docs should **not** claim dispute creation for direct_offer is implemented until it is; no false refs found in core docs claiming it.
- **Cron auto-release:** Plan assumes a cron exists or is created; migration 20260319120000 creates it. SUPABASE_SETUP does not yet document this function or job — without that, "delivered offers auto-release after 3 days" is an unimplemented-looking assumption to a reader.

---

## 3) Required doc updates (exact paths and section suggestions)

### 3.1 Sline_everything/SUPABASE_SETUP.md

- **§5.14 (direct_offers):**
  - After the Triggers line, add: `trg_direct_offer_protect_price_currency` (BEFORE UPDATE) calls `fn_direct_offer_protect_price_currency` — rejects UPDATE of price/currency when status != 'sent' or payment_status != 'unpaid'. See `20260319110000_direct_offer_guard_rls_ledger.sql`.
  - In Indexes line, add: `idx_direct_offers_processing` (partial: status='accepted' AND payment_status='unpaid' AND payment_request_id IS NOT NULL). See `20260319000000_direct_offer_flow_harden.sql`.
  - Add a **Cron** line: Function `run_auto_release_expired_direct_offers()` (SECURITY DEFINER) selects delivered+held offers with review_expires_at &lt; now(), calls process_payment_event_ledger release_with_fee with fee from row, then updates status/payment_status. Scheduled via pg_cron as `auto-release-expired-direct-offers` (hourly). See `20260319120000_direct_offer_auto_release_cron.sql`.

- **§5.24 (disputes):**
  - Add row to table: `direct_offer_id` | uuid | ✅ | - | FK to direct_offers; exactly one of task_id or direct_offer_id.
  - After table, add: **Constraint:** `chk_dispute_entity` — (task_id IS NOT NULL AND direct_offer_id IS NULL) OR (task_id IS NULL AND direct_offer_id IS NOT NULL).
  - Add: **RLS:** INSERT policy `disputes_insert_own`: complainant_id = auth.uid() and (task_id IS NOT NULL OR (direct_offer_id IS NOT NULL and exists direct_offers row where client_id or freelancer_id = auth.uid())). See `20260319110000_direct_offer_guard_rls_ledger.sql`.

- **§9.5 rpc_approve_delivery — Migrations line:**  
  Append: `20260319110000_direct_offer_guard_rls_ledger.sql` (direct_offer branch reads fee_rate_applied_bps from direct_offers row).

- **§17 Changelog:**  
  Add new bullet (e.g. under Version 2.17.2 or new 2.17.3):  
  "**Direct Chat Offer Flow hardening (2026-03-07):** direct_offers: currency, payment_*, delivered_at, review_expires_at (migration 20260319000000); trigger trg_direct_offer_protect_price_currency (20260319110000); disputes: direct_offer_id, chk_dispute_entity, disputes_insert_own RLS (20260319000000, 20260319110000); rpc_approve_delivery direct_offer branch reads fee from row (20260319110000); cron run_auto_release_expired_direct_offers (20260319120000). Plan: .TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md."

### 3.2 Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md

- **§2.1 Table:** Add a sentence: "Full column list including currency, fee_rate_applied_bps, payment_*, delivered_at, review_expires_at: see Sline_everything/SUPABASE_SETUP.md §5.14."
- **§2.1 Lifecycle:** Extend with: "On Mark Delivered the service sets delivered_at and review_expires_at (e.g. now + 3 days). If the client does not Approve before review_expires_at, a cron job auto-releases the offer (no permanent escrow lock)."
- **§4.5 Deliver and complete:** Add: "Mark Delivered updates status to 'delivered' and sets delivered_at and review_expires_at. Completion can be manual (client Approve & release) or automatic when review_expires_at has passed (cron runs run_auto_release_expired_direct_offers)."
- **New subsection or note:** "Contract: payment intent, release fee-from-row, and disputes linkage: see .TODO/06_direct_offer_contract.md."
- **Last Updated:** 2026-03-08.

### 3.3 Sline_everything/STRUCTURE.md

- Under "Recent migration themes" / direct_offers bullet (around line 86–87), add a new bullet:  
  "**Direct Chat Offer Flow hardening (Plan DirectChatOfferFlow CRITIC, 2026-03-07):** `20260319000000_direct_offer_flow_harden.sql` (currency, payment_*, delivered_at, review_expires_at on direct_offers; direct_offer_id and chk_dispute_entity on disputes); `20260319110000_direct_offer_guard_rls_ledger.sql` (trigger protect price/currency, disputes_insert_own RLS, rpc_approve_delivery fee from direct_offers row); `20260319120000_direct_offer_auto_release_cron.sql` (run_auto_release_expired_direct_offers + pg_cron)."

### 3.4 Sline_everything/Sline_Log.md

- Add entry (e.g. after "Docs Sync — Reference Integrity" or under a "Direct Chat Offer Flow" heading):  
  Version / date 2026-03-08 (or 2026-03-07). Implemented: migrations 20260319000000, 20260319110000, 20260319120000; DirectOffer model new fields; DirectOffersService accept stamps fee/currency, markDelivered sets delivered_at and review_expires_at; test/features/direct_offers/direct_offers_service_test.dart; .TODO artifacts (06_direct_offer_contract.md, 06_direct_offer_threat_model.md, 06_direct_offer_migration_plan.md, 06_direct_offers_rls_matrix.md). Plan: .TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md. Execution: .TODO/EXECUTION_LOG_DirectChatOfferFlow_2026-03-07_CRITIC.md.

### 3.5 Sline_everything/AppDigram/All_Diagrams/06_direct-chat-offer-flow.md

- Replace or annotate "pending" with "sent" (DB initial status).
- In step-by-step or diagram, note: completed can be reached by client Approve or by cron when review_expires_at &lt; now().
- In Evidence/DB, add: `trg_direct_offer_protect_price_currency`; remove or correct "direct_offer_status_enum" (status is text).
- Set last_verified: 2026-03-08.

---

## 4) Broken refs that invalidate plan assumptions

- **None** of the broken or outdated items above **invalidate** the plan’s technical assumptions (fee from row, cron, trigger, disputes.direct_offer_id, markDelivered timestamps). Those are implemented in code and migrations. The gaps are **documentation-only**: the written docs do not yet describe the new trigger, cron, disputes schema/RLS, or migration list, so a reader relying only on docs could wrongly assume cron doesn’t exist or disputes are task-only. Fixing the delta list in §1 and §3 removes that risk.

---

## 5) Summary

| Category | Count |
|----------|--------|
| Doc files requiring updates | 5 (SUPABASE_SETUP, Direct_Offers_Feature, STRUCTURE, Sline_Log, 06_direct-chat-offer-flow) |
| High-priority updates | 7 |
| Medium-priority updates | 3 |
| Low-priority updates | 2 |
| Broken file paths | 0 |
| Outdated statements identified | 4 |
| Plan assumptions invalidated by broken refs | 0 |

**Next step:** Apply the edits in §3 in order (SUPABASE_SETUP first, then feature guide, STRUCTURE, Sline_Log, diagram). After edits, produce a short DOCS_SYNC note (e.g. `.TODO/DOCS_SYNC_2026-03-08_DirectChatOfferFlow.md`) listing the files updated and that reference integrity was re-checked.
