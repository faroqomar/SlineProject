# 📌 Plan: Hardened Payment Linking System (24)

## 1) Goal

- **Goal:** Implement the full Hardened Payment Linking System so every gateway payment is pre-registered in `payment_intents`, bound by a server-side HMAC signature, audit-logged in `payment_events`, and linked to the ledger via `payment_intent_id`. Orphaned or tampered events go to `orphan_payments` for admin review.
- **Why:** Prevents orphan payments, amount/entity tampering, and webhook replay; ensures crash recovery and full auditability with the existing double-entry ledger.
- **Result:** Single, secure path: BFF creates intent (with signature) → Gateway → Webhook validates signature/amount, appends event, updates intent, calls ledger with `payment_intent_id`; UI resolves via Realtime. Admin can triage orphans.

## 2) Scope

### In-Scope

- Schema alignment: `payment_intents` (signature, currency, paid_at if missing), `payment_events` append-only and service_role-only writes, `orphan_payments` (investigated flag if desired).
- Ledger RPC: `process_payment_event_ledger` accepts and stores `payment_intent_id` in `journal_entries.meta` for escrow/gateway flows.
- Edge: HMAC-SHA256 signature on intent creation; webhook verifies internal signature, appends to `payment_events`, looks up by `gateway_intent_id`, amount match, idempotency.
- Unifying booking and direct-offer creation flows to use the intent-based path (create intent then gateway) or ensuring `qicard_webhook_handler` uses intents and ledger link when intent_id is present.
- Flutter: Realtime subscription on `payment_intents` for checkout resolution; no client-side finalization.
- Admin: Orphan queue (list, raw payload viewer, resolve/refund actions) and payment trace (intent → event → journal).
- Docs: SUPABASE_SETUP.md and DEVELOPER_GUIDE sections for payment_intents, payment_events, orphan_payments, and hardened flow.
- Threat model and test plan from the improvement folder (signature tampering, replay, RLS).

### Out-of-Scope

- Changing double-entry ledger semantics (only adding optional `payment_intent_id` linkage).
- New payment gateways beyond QiCard.
- Withdraw or payout flows (unchanged).
- Observability/alerting implementation details beyond “document required events.”

## 3) Evidence & Findings (From Scan)

### Existing

- **DB:** Migration `20260307000000_hardened_payment_gateway.sql`: `payment_intents` (id, entity_type, entity_id, payer_id, receiver_id, gross_amount, fee_rate_locked, gateway_intent_id, idempotency_key, status: created|gateway_processing|succeeded|failed), `payment_events` (id, gateway_event_id, intent_id, event_type, payload), `orphan_payments` (id, gateway_event_id, error_reason, payload). RLS: SELECT on payment_intents for payer; no INSERT/UPDATE for anon/authenticated on payment_events/orphan_payments (service_role only in practice). Indexes on payer_id, gateway_intent_id, intent_id.
- **Edge:** `create_payment_intent` inserts intent, calls QiCard with additionalInfo.intent_id, updates intent with gateway_intent_id; no HMAC. `finalize_payment_webhook` looks up intent by additionalInfo.intent_id, idempotency on status=succeeded, then submitGatewayEscrowHold/submitDirectOfferGatewayEscrow/submitTenderGatewayEscrow; does not insert into payment_events first; does not verify internal signature; does not pass payment_intent_id to ledger. `qicard_payment_create` / `qicard_payment_create_direct_offer`: create booking/offer server-side, call QiCard with booking_id/offer_id (no payment_intents). `qicard_webhook_handler`: QiCard RSA verification, submitGatewayEscrowHold/submitDirectOfferGatewayEscrow for booking/direct_offer/tender; does not use payment_intents.
- **Flutter:** `lib/core/services/qicard_payment_service.dart`: `streamPaymentIntentStatus(intentId)` on `payment_intents`; `createPaymentForBooking` invokes `qicard_payment_create`; `createPaymentForDirectOffer` invokes `qicard_payment_create_direct_offer`. Booking checkout uses create result and subscribes when `intentId != null`. Tender flow uses tender-specific edge and coordinator.
- **Docs:** STRUCTURE.md references v2.20 hardened tables and admin views. SUPABASE_SETUP.md has no section for payment_intents/payment_events/orphan_payments. Improvement folder: `24_hardened_paymentLinking_system` with HOLISTIC_REPORT, GAPS_AND_FIXES, INVARIANTS, RISK_REGISTER, TEST_PLAN, diagram.

### Missing

- `payment_intents`: no `signature` (text), no `currency` (text), no `paid_at` (timestamptz). Status enum uses `gateway_processing` vs spec `gateway_created` (cosmetic).
- `process_payment_event_ledger`: no parameter or meta field for `payment_intent_id`; journal_entries not explicitly storing intent link for audit.
- Edge create path: no HMAC computed or stored; metadata passed to gateway does not include platform signature for webhook re-check.
- Webhook: no INSERT into `payment_events` before processing; no internal HMAC verification; no amount match (intent.gross_amount vs webhook amount); ledger calls do not pass payment_intent_id.
- Unified flow: booking/direct-offer creation currently use qicard_payment_create / qicard_payment_create_direct_offer (no intents). Either migrate them to create_payment_intent + finalize_payment_webhook, or add intent creation + HMAC to existing edge and make webhook intent-aware for those flows.
- Admin UI: no Orphan Queue or Payment Trace Explorer (Next.js dashboard).
- SUPABASE_SETUP.md: no DDL/policy description for payment_intents, payment_events, orphan_payments.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- **Dual paths:** create_payment_intent + finalize_payment_webhook use intents but lack signature/audit/ledger link; qicard_payment_create + qicard_webhook_handler do not use intents. Plan must pick one canonical path and migrate the other (or merge).
- **RLS:** payment_events and orphan_payments have RLS enabled but no explicit policies in migration (default deny); ensure only service_role can INSERT (and payment_events has no UPDATE/DELETE).
- **Live DB:** Planner mandates re-scan via Supabase MCP (`list_tables`, `execute_sql` for touched objects). If migrations were not applied, tables may be missing; if applied, column set may differ from improvement spec. Record drift in Phase 0.
- **Migration risk:** Existing bookings/direct offers paid via legacy flow have no payment_intent rows; ledger entries exist without intent_id. Backfill not required for old rows; new flows only must use intent_id.

## 4) System Impact Map

- **UI:** Booking and direct-offer checkout already use intent_id + Realtime when returned; ensure edge returns intent_id for all create paths. Orphan/trace UX = Admin dashboard (new).
- **MVVM/App Logic:** ViewModels continue to call payment service; service continues to call edge and subscribe to payment_intents; no direct Supabase from View.
- **Database:** Additive: optional columns on payment_intents (signature, currency, paid_at); optional meta in journal_entries for payment_intent_id; ensure payment_events has no UPDATE/DELETE policies; orphan_payments optional investigated column.
- **RLS/Security:** payment_intents: INSERT/UPDATE only via service_role (edge); payment_events: INSERT only service_role, no UPDATE/DELETE; orphan_payments: admin read, service_role insert (and optional update for investigated).
- **Realtime/Notifications:** Existing Realtime subscription on payment_intents by id; no change to notification tables.
- **Storage:** None.
- **Observability:** Document required events (intent created, gateway_created, succeeded, orphan recorded); optional logging in edge/webhook (no PII in logs).
- **Compatibility & Migration:** Additive schema; legacy ledger rows remain valid; new escrow/gateway flows must pass payment_intent_id once RPC supports it.
- **Contracts:** Edge request/response (intent_id, checkout_url); webhook payload (gateway + metadata with intent_id and signature); Flutter ↔ edge contract unchanged except guarantee of intent_id on create.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance + non-regression list (measurable): intent created for every new booking/direct-offer payment; webhook appends payment_events; amount/signature mismatch → orphan_payments; idempotency on replay; ledger journal_entries.meta includes payment_intent_id for new escrow entries.
- [ ] (@Architect) Confirm modules/entry points: booking (qicard_payment_create or create_payment_intent), direct_offer (qicard_payment_create_direct_offer or create_payment_intent), tender (existing tender flow); webhook (qicard_webhook_handler vs finalize_payment_webhook); Flutter qicard_payment_service + payment_checkout_screen / direct_offer_details.
- **Verify (@Sentinel):** done-conditions and rollback triggers documented in Phase 8.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Threat model + security requirements + negative checks in `.TODO/improvement_the_system/ImplementReady/24_hardened_paymentLinking_system/` (reuse 04_TEST_PLAN.md T-SEC-*, T-ROB-*, T-RLS-*).
- **Verify (@Sentinel):** Testable and included in Phase 4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Contract file in `.TODO/` or in improvement folder: Edge create request/response (entity_type, entity_id → intent_id, checkout_url, optional form_url); Webhook payload (gateway fields + additionalInfo.intent_id, optional signature); Ledger RPC new optional p_payment_intent_id and journal_entries.meta.payment_intent_id.
- **Verify (@Sentinel):** Contract matches schema + shapes.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Additive only: add columns to payment_intents (signature, currency, paid_at); add meta key for payment_intent_id in ledger RPC; no backfill of old journal_entries. Rollback: drop new columns / ignore new param. Compatibility window: N/A (additive).
- **Verify (@Sentinel):** Measurable compatibility window (e.g. one release with optional param).

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Optional: feature flag to route booking/direct-offer to intent-based edge vs legacy; or single cutover after webhook hardened.
- **Verify (@Sentinel):** Rollback path documented (revert edge + RPC patch).

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via Supabase MCP (`list_tables` for public, verbose) for payment_intents, payment_events, orphan_payments, journal_entries columns and RLS policies.
- [ ] (@Supabase_Ops) Confirm no conflicts with existing (avoid drops/renames); record drift vs migration file and improvement spec.
- **Verify (@Sentinel):** Drift + safe approach recorded in plan or risk register.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) DDL: add to payment_intents (signature TEXT, currency TEXT DEFAULT 'IQD', paid_at TIMESTAMPTZ); add to orphan_payments (investigated BOOLEAN DEFAULT false) if desired; ensure payment_events has no UPDATE/DELETE policies (explicit deny or omit).
- [ ] (@Supabase_Ops) Indexes: already idx_payment_intents_gateway_id; add index for status+entity if needed for admin views.
- **Verify (@Sentinel):** No leaks/breaks, naming consistent, minimal risk.

### 1.2 RLS

- [ ] (@Supabase_Ops) Policies: payment_intents INSERT/UPDATE only service_role (or edge via service_role); payment_events INSERT only service_role, no UPDATE/DELETE policies; orphan_payments INSERT service_role, SELECT for admin role if applicable.
- [ ] (@Supabase_Ops) RLS check matrix file in `.TODO/` or improvement folder (anon/authenticated/service_role × SELECT/INSERT/UPDATE/DELETE per table).
- **Verify (@Sentinel):** Negative fails, positive passes (T-RLS-*).

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) process_payment_event_ledger: add optional parameter p_payment_intent_id UUID; when provided, store in journal_entries.meta (e.g. meta->'payment_intent_id' or meta->>'payment_intent_id'). Apply to escrow_hold and gateway_escrow branches.
- [ ] (@Supabase_Ops) Idempotency: ensure idempotency_key used in ledger includes payment_intent_id or gateway_intent_id where applicable so replay does not double-escrow.
- **Verify (@Sentinel):** State rules enforced; idempotency test passes.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Run additive migration(s) per plan; no backfill.
- **Verify (@Sentinel):** Verify queries and RPC calls pass.

---

## Phase 2: App Layer (Edge + Flutter)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Flutter: ensure payment intent model or response DTO includes id, status, gateway_intent_id if needed; align to contract (intent_id, checkout_url).
- [ ] (@Architect) Edge: types for intent row (signature, currency, paid_at) and webhook payload.
- **Verify (@Sentinel):** Types/nullability match contract.

### 2.2 Services/Repositories

- [ ] (@Architect) Edge create flow: compute HMAC-SHA256(PAYMENT_HMAC_SECRET, entity_id + gross_amount + currency + payer_id), store in payment_intents.signature; pass signature in gateway metadata (e.g. additionalInfo.signature) for webhook verification.
- [ ] (@Architect) Edge webhook: (1) INSERT into payment_events (gateway_event_id, intent_id from payload, raw payload) first (audit); (2) look up payment_intents by gateway_intent_id or intent_id; (3) verify internal signature (recompute HMAC from intent row, compare to metadata); (4) verify amount (intent.gross_amount == webhook amount); (5) if already succeeded return 200; (6) in transaction: UPDATE payment_intents SET status='succeeded', paid_at=now(); call process_payment_event_ledger with p_payment_intent_id; UPDATE entity (booking/direct_offer/task_request) status/payment_status; (7) on validation failure INSERT orphan_payments.
- [ ] (@Architect) Unify flows: either (A) migrate qicard_payment_create and qicard_payment_create_direct_offer to create payment_intent (with HMAC) then call QiCard and return intent_id + form_url, and route webhook to same finalize path; or (B) keep two webhooks but make qicard_webhook_handler intent-aware when additionalInfo.intent_id is present (create intent in webhook for legacy is not acceptable per spec — intents must be created before gateway call). Prefer (A) for single path.
- [ ] (@Architect) Storage rule: DB stores paths only; no change for payment tables.
- **Verify (@Sentinel):** RLS-safe, no UI→Supabase for payment_events/orphan_payments; no N+1.

### 2.3 ViewModels

- [ ] (@Architect) Booking/DirectOffer: ensure create payment returns intent_id and UI subscribes to payment_intents Realtime for that id; loading/error states and crash recovery (re-fetch intent by entity on resume).
- [ ] (@Architect) Single source of truth: one create endpoint per flow that returns intent_id.
- **Verify (@Sentinel):** Recoverable state, correct transitions.

### 2.4 Observability (If needed)

- [ ] (@Observability) Event list + correlation (intent_id, gateway_intent_id) in `.TODO/` or improvement folder.
- [ ] (@Architect) Instrument edge/webhook (no PII in logs).
- **Verify (@Sentinel):** No sensitive logs, consistent correlation.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Checkout screens use ViewModels only; display loading/empty/error; Realtime drives success/failure state (no polling for finalization).
- [ ] (@Pixel) Admin dashboard (Next.js): Orphan Queue (list orphan_payments, raw payload modal, Force Resolve / Refund); Payment Trace Explorer (search by intent_id or gateway_intent_id, timeline: intent → event → journal).
- **Verify (@Sentinel):** Stable UX on slow/empty data.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Micro-interactions for success/failure (low-risk only).
- **Verify (@Sentinel):** No perf regression.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Shapes/types match contract; migration verify queries (e.g. select from payment_intents with new columns).
- **Verify (@Sentinel):** No mismatch.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute T-SEC-1 (metadata signature tampering → orphan, no ledger); T-SEC-2 (unknown gateway_intent_id → orphan); T-SEC-3 (amount mismatch → orphan); T-ROB-1 (replay → single ledger); T-ROB-2 (app crash recovery); T-ROB-3 (entity state lock); T-RLS-1 (payer impersonation); T-RLS-2 (payment_events append-only).
- **Verify (@Sentinel):** Unauthorized access impossible; idempotency and amount binding hold.

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E: booking checkout → pay → success screen via Realtime; direct offer checkout → pay → success; orphan path (tampered payload → orphan record).
- [ ] (@Sentinel) Edge cases: network failure after intent created; stale client; null intent_id handling.
- **Verify (@Sentinel):** No crashes, consistent behavior.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Required logs/events exist; privacy redaction enforced.
- **Verify (@Sentinel):** Actionable telemetry without leaks.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update SUPABASE_SETUP.md: tables payment_intents, payment_events, orphan_payments (columns, RLS, indexes); process_payment_event_ledger new parameter and meta; hardened flow (create intent → gateway → webhook → ledger link).
- [ ] (@DocsKeeper) Update DEVELOPER_GUIDE.md / Hardened Payment Gateway section: intent lifecycle, signature, webhook validation, Realtime resolution, admin orphan queue.
- [ ] (@DocsKeeper) STRUCTURE.md / MVP_ROADMAP.md: reflect intent-based flow and admin views.
- **Verify (@Sentinel):** Docs match code + live DB reality.

---

## 7) Acceptance Criteria (MANDATORY)

- Every new booking and direct-offer payment creates a payment_intent row (with signature) before calling the gateway; webhook appends one payment_event row per webhook hit; amount and internal signature are validated before ledger call.
- Ledger: every new escrow_hold/gateway_escrow journal entry stores payment_intent_id in meta when provided.
- Replay: sending the same success webhook multiple times results in exactly one ledger update and 200 OK for duplicates.
- Tampering: changing amount or signature in webhook payload results in orphan_payments insert and no ledger update.
- RLS: anon/authenticated cannot INSERT or UPDATE payment_events; only service_role (edge) can; payment_intents INSERT/UPDATE only via service_role.
- UX: Checkout resolves to success/failure via Realtime subscription on payment_intents; no client-side finalization.
- Admin: Orphan queue and payment trace (intent → event → journal) available and documented.

---

## 8) Rollback Plan

- **DB:** Additive columns can be left in place; if RPC change causes issues, deploy RPC version that ignores p_payment_intent_id and does not write meta (previous behavior).
- **Edge:** Revert to previous edge version (legacy qicard_payment_create + qicard_webhook_handler without intent path) and re-deploy; ensure Flutter still works with legacy response (form_url without intent_id) with fallback to recovery flow.
- **App:** If intent_id not returned, existing recovery/polling fallback can remain until edge is fixed; no destructive app change required if backward compatible.
- **Emergency:** Disable webhook processing via feature flag or redirect to read-only handler that only logs and returns 200 (no DB writes); triage orphans manually.

---

## 9) References (From Scan)

- `.TODO/improvement_the_system/ImplementReady/24_hardened_paymentLinking_system/`: 00_INDEX.md, 00_HOLISTIC_REPORT.md, 02_GAPS_AND_FIXES.md, 03_RISK_REGISTER.md, 04_INVARIANTS.md, 04_TEST_PLAN.md, 06_DIAGRAM_FINAL.md, 99_EVERYTHING_FULL_REPORT.md, 24_hardened_paymentLinking_system.IMPROVEMENT.md
- `Sline_everything/DEVELOPER_GUIDE.md` (Hardened Payment Gateway v2.20, Finance & Payment Ledger)
- `Sline_everything/SUPABASE_SETUP.md` (§ process_payment_event_ledger, ledger, booking webhook)
- `Sline_everything/STRUCTURE.md` (migrations, edge functions, lib/features/booking, direct_offers, core/services)
- `Sline_everything/MVP_ROADMAP.md` (Booking and Payment Flows, QiCard hardening)
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` (Hardened Payment Gateway v2.20)
- `Sline_everything/CODE_REVIEW.md` (guardrails)
- `supabase/migrations/20260307000000_hardened_payment_gateway.sql`
- `supabase/functions/create_payment_intent/index.ts`, `finalize_payment_webhook/index.ts`, `qicard_payment_create/index.ts`, `qicard_webhook_handler/index.ts`, `_shared/bookin_payment.ts`
- `lib/core/services/qicard_payment_service.dart`, `lib/features/booking/viewmodels/booking_view_model.dart`, `lib/features/booking/view/payment_checkout_screen.dart`, `lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart`
- Live Supabase scan: to be performed via Supabase MCP (`list_tables` with verbose, `execute_sql` for policies) and results recorded in Phase 0/1.
