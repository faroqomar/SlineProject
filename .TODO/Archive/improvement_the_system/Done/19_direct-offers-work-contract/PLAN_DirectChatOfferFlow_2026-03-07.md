# 📌 Plan: Direct Chat Offer Flow (Production Hardening)

## 1) Goal

- **Goal:** Implement the improvements defined in `.TODO/improvement_the_system/ImplementReady/06_direct-chat-offer-flow` so that the Direct Chat Offer flow is production-safe: correct nomenclature, escrow timeout to prevent permanent lock, composite state accuracy, active-offer cancellation/dispute path, and full payment traceability (gateway + fee lock + currency).
- **Why:** Current system has critical risks: (1) no `review_expires_at` on direct_offers → freelancer funds can be permanently locked if client never approves; (2) no way to cancel/refund an active (paid) offer; (3) no gateway traceability on direct_offers → crash mid-checkout or duplicate webhook can cause lost/duplicate money; (4) no fee/currency lock at acceptance → ledger can desync if platform fee or currency changes during escrow.
- **Result:** Direct offers align with bookings for timeout safety, dispute linkage, and payment traceability; UI and diagrams use composite states and correct status names; cron auto-releases delivered offers after review window; disputes table supports direct_offer_id.

---

## 2) Scope

### In-Scope

- Nomenclature: all UI and diagrams use `sent` (not `pending`) for initial offer state.
- Schema: add to `direct_offers` — `delivered_at`, `review_expires_at`, `currency` (default IQD), `fee_rate_bps_snapshot`, `payment_request_id`, `payment_gateway_id`, `payment_correlation_id`, `payment_expires_at`, `payment_recovered_at`; additive only.
- Escrow timeout: `markDelivered` sets `delivered_at` and `review_expires_at` (e.g. now + 3 days); cron `fn_check_expired_reviews` (or equivalent) includes `direct_offers` so delivered offers auto-release after timeout.
- Composite states: UI and ViewModels gate all actions on `[status, payment_status]`; no actions allowed based on `status` alone.
- Active-offer resolution: protocol for cancel/refund of active (held) offers — either mutual cancellation and/or dispute path; extend `disputes` to support `direct_offer_id` (or equivalent) so admin can resolve and trigger refund/release.
- Gateway traceability: before redirect to QiCard, persist `payment_request_id`, `payment_correlation_id`, `payment_expires_at` on `direct_offers`; on recovery/webhook set `payment_gateway_id`, `payment_recovered_at`; recovery and ledger use DB as source of truth.
- Fee and currency lock: at offer acceptance (or at create), stamp `fee_rate_bps_snapshot` and `currency` on the row; ledger `release_with_fee` uses snapshot for direct_offers.
- Guard/trigger: `fn_direct_offer_guard` (and any RPC) updated so that once status is past `sent`/unpaid, `price`, `currency`, `fee_rate_bps_snapshot` cannot be updated by client; idempotency for escrow_hold/release enforced.
- Observability: minimal event list for direct-offer payment and dispute flows (as per project standards).
- Documentation: DEVELOPER_GUIDE (Direct_Offers_Feature.md), SUPABASE_SETUP.md, and any diagrams updated to match implementation; state diagram (e.g. V3 from 07_SYSTEM_CRITIC_VERDICT) reflected in docs.

### Out-of-Scope

- Changing the public tender/task flow or booking flow logic beyond any shared RPC/cron changes.
- New payment gateways or currencies beyond existing (IQD + existing QiCard).
- Full dispute UI/admin dashboard redesign; only the data model and minimal app hooks needed to create/link disputes for direct offers and for admin to resolve (existing dispute resolution path extended).

---

## 3) Evidence & Findings (From Scan)

### Existing

- **Docs:** `Sline_everything/SUPABASE_SETUP.md` §5.14 documents `direct_offers` with columns: id, conversation_id, client_id, freelancer_id, task_id, title, description, price, days, status, payment_status, created_at, updated_at. No `delivered_at`, `review_expires_at`, or payment gateway columns. §5.24 `disputes` has `task_id` (nullable), no `direct_offer_id`. Bookings (§5.8) has `payment_request_id`, `payment_gateway_id`, `payment_correlation_id`, `payment_expires_at`, `payment_recovered_at`, `delivered_at`, `review_expires_at`.
- **Code:** `lib/features/direct_offers/services/direct_offers_service.dart` — createOffer (status `sent`, payment_status `unpaid`); acceptOfferWithoutPayment; payNow (ledger escrow_hold); recoverPaymentAfterCallback (invokes edge `qicard_payment_recovery_direct_offer`); cancelOffer (freelancer, only when isSent); cancelAcceptedOffer (client, only accepted+unpaid); markDelivered (sets status `delivered` only, no delivered_at/review_expires_at); completeOffer (rpc_approve_delivery). No cancelActiveOffer or dispute initiation.
- **RPC/Ledger:** `rpc_approve_delivery` supports entity_type `direct_offer`; `process_payment_event_ledger` supports escrow_hold, release_with_fee, refund for direct_offer. Docs mention `fn_direct_offer_guard` for status/payment transitions.
- **Edge functions:** `qicard_payment_create_direct_offer`, `qicard_payment_recovery_direct_offer` under `supabase/functions/`.
- **Feature folder:** `lib/features/direct_offers/` — models, services, viewmodels, view; integration in chat (ChatViewModel, offer_message_bubble), dashboard (dashboard_repository, dashboard_view_model, dashboard_screen), payment_webview_screen, deep_link_service.
- **Improvement folder:** `.TODO/improvement_the_system/ImplementReady/06_direct-chat-offer-flow/` — 00_HOLISTIC_REPORT, 01_NOTES, 02_GAPS_AND_FIXES, 03_RISK_REGISTER, 07_SYSTEM_CRITIC_VERDICT define gaps, state machine (composite states), DB patch (currency, fee_rate_bps_snapshot, gateway columns, delivered_at, review_expires_at), and verification checklist.

### Missing

- On `direct_offers`: columns `currency`, `fee_rate_bps_snapshot`, `payment_request_id`, `payment_gateway_id`, `payment_correlation_id`, `payment_expires_at`, `payment_recovered_at`, `delivered_at`, `review_expires_at`.
- Cron (or scheduled function) that auto-releases delivered direct_offers when `now() > review_expires_at` (equivalent to tasks/bookings behavior).
- RPC or service method to set `delivered_at` and `review_expires_at` when marking delivered (currently service does plain UPDATE status only).
- Disputes table support for direct_offer (e.g. `direct_offer_id` or polymorphic resource); app flow to create dispute for a direct_offer and admin path to resolve (refund/release).
- Stamping `fee_rate_bps_snapshot` and `currency` at accept/create; ledger/release using snapshot for direct_offers.
- Edge function and app flow: persist payment intent on `direct_offers` before redirect; recovery matching on `payment_request_id`/idempotency.
- UI/diagram updates: all references to `pending` → `sent`; composite state logic in offer bubble and detail screen.
- Tests: direct_offers_service_test.dart (role/state guards); RLS check matrix for direct_offers UPDATE.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- **Live DB not scanned in this session.** Plan is based on docs + code + improvement folder. **Before execution, a live Supabase scan (list_tables, execute_sql for direct_offers, disputes, fn_direct_offer_guard, cron) is MANDATORY** to confirm current columns, triggers, and cron; any drift (e.g. columns already present) must be reconciled without destructive drops/renames.
- **Risk:** Adding `fee_rate_bps_snapshot` and using it in `release_with_fee` requires contract with ledger RPC (parameter or read from row); existing ledger may not accept fee from row — must verify and possibly extend `process_payment_event_ledger` for direct_offer to use snapshot.
- **Risk:** Disputes table extension (direct_offer_id) may require RLS and admin visibility changes; avoid breaking existing task-based disputes.
- **Risk:** Auto-release cron: ensure it uses same idempotency and locking pattern as manual approve (no double release).
- **Risk:** Timeout abuse (freelancer marks delivered and waits 3 days); mitigate with client notifications and dispute path before timeout (noted in 00_HOLISTIC_REPORT).

---

## 4) System Impact Map

- **UI:** Chat offer bubble and DirectOfferDetailsScreen — use composite states for button visibility; rename any "pending" to "sent"; optional "Report issue" / dispute entry for active/delivered offers. Dashboard work items already use status; ensure labels and actions respect payment_status.
- **MVVM/App Logic:** DirectOffersService — markDelivered to set delivered_at + review_expires_at (via RPC or UPDATE); optional requestCancelActiveOffer / createDisputeForDirectOffer; createPaymentForCard flow to persist payment_request_id/correlation_id/expires_at before redirect; recovery to validate and set payment_recovered_at/gateway_id. ViewModels and dashboard performPrimaryAction unchanged in spirit; fee/currency read from offer model. DirectOffer model extended with new fields.
- **Database:** direct_offers — additive columns (currency, fee_rate_bps_snapshot, payment_* , delivered_at, review_expires_at). disputes — additive direct_offer_id (or related_entity_type + related_entity_id if preferred). Optional: partial index on direct_offers for processing checkouts (accepted + unpaid + payment_request_id not null).
- **RLS/Security:** RLS on direct_offers remains participant-based; ensure UPDATE policy does not allow client/freelancer to change fee_rate_bps_snapshot, price, currency after creation/acceptance (or enforce in trigger). Disputes RLS: allow insert when complainant is client or freelancer of the direct_offer; admin resolution path unchanged.
- **Realtime/Notifications:** Notify client when offer is marked delivered (if not already) to reduce timeout abuse; optional notification before review_expires_at.
- **Storage:** No new buckets; dispute_evidence already exists for dispute attachments.
- **Observability:** Log offer state transitions and payment recovery; optional analytics events for deliver/complete/dispute (no PII in logs).
- **Compatibility & Migration:** Additive schema only; existing rows get defaults (currency 'IQD', fee_rate_bps_snapshot from current platform config or default). No drop/rename. Old app versions may not set new columns — recovery and cron must handle nulls (e.g. skip auto-release if review_expires_at is null).
- **Contracts:** API contract for direct_offer payment (edge ↔ DB ↔ app): payment_request_id, payment_correlation_id, payment_expires_at written before redirect; recovery idempotency key from entity_id + gateway intent. Fee snapshot contract: release_with_fee for direct_offer uses row.fee_rate_bps_snapshot when present.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance + non-regression list (measurable): direct offer create → accept → pay → deliver → complete still works; unpaid cancel and sent cancel work; delivered offer auto-releases after 3 days when cron runs; active offer can enter dispute; client cannot complete before deliver; freelancer cannot pay.
- [ ] (@Architect) Confirm modules/entry points: direct_offers (service, viewmodel, view), chat (offer bubble), dashboard (work list, payment return), edge functions qicard_payment_create_direct_offer, qicard_payment_recovery_direct_offer.
- **Verify (@Sentinel):** done-conditions + rollback triggers documented in §8.

### 0.2 Threat Model (sensitive: money + escrow)

- [ ] (@ThreatModeler) Threat model + security requirements + negative checks in `.TODO/` (e.g. permanent escrow lock, timeout abuse, double webhook, fee tampering, unauthorized cancel).
- **Verify (@Sentinel):** testable items included in Phase 4.

### 0.3 Contracts (payloads and DB shapes change)

- [ ] (@APIContract) Contract file(s) in `.TODO/`: direct_offer payment (edge ↔ DB: payment_request_id, correlation_id, expires_at; recovery idempotency); direct_offer release (fee_rate_bps_snapshot source); disputes direct_offer linkage.
- **Verify (@Sentinel):** contract matches schema + shapes after Phase 1.

### 0.4 Migration Plan (schema + data)

- [ ] (@DataMigration) Plan: introduce new columns (additive), backfill currency/fee_rate_bps_snapshot for existing rows where needed, no enforce drop; rollback = remove cron branch for direct_offers only, keep columns; compatibility window for old app (null review_expires_at = no auto-release).
- **Verify (@Sentinel):** compatibility window and rollback steps documented.

### 0.5 Feature Flag/Rollout (optional)

- [ ] (@Architect) Toggle strategy if desired (e.g. auto-release behind flag).
- **Verify (@Sentinel):** rollback path documented.

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via Supabase MCP (list_tables verbose for public.direct_offers, disputes; execute_sql or migrations list) for touched objects.
- [ ] (@Supabase_Ops) Confirm no conflicts with existing (no drops/renames unless in plan).
- **Verify (@Sentinel):** drift and safe approach recorded in execution log.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) DDL migration: ALTER TABLE direct_offers ADD COLUMN currency text NOT NULL DEFAULT 'IQD', ADD COLUMN fee_rate_bps_snapshot integer NOT NULL DEFAULT 1000, ADD COLUMN payment_request_id text, ADD COLUMN payment_gateway_id text, ADD COLUMN payment_correlation_id text, ADD COLUMN payment_expires_at timestamptz, ADD COLUMN payment_recovered_at timestamptz, ADD COLUMN delivered_at timestamptz, ADD COLUMN review_expires_at timestamptz.
- [ ] (@Supabase_Ops) Optional: CREATE INDEX idx_direct_offers_processing ON direct_offers(...) WHERE status = 'accepted' AND payment_status = 'unpaid' AND payment_request_id IS NOT NULL (per 07_SYSTEM_CRITIC_VERDICT).
- [ ] (@Supabase_Ops) Extend disputes: ADD COLUMN direct_offer_id uuid REFERENCES direct_offers(id) (or equivalent polymorphic design); RLS/constraints so one of task_id or direct_offer_id set.
- **Verify (@Sentinel):** no leaks/breaks, naming consistent, minimal risk.

### 1.2 RLS

- [ ] (@Supabase_Ops) Policies: direct_offers UPDATE remains participant-scoped; ensure no policy allows updating fee_rate_bps_snapshot/price/currency by app role after status != sent (or rely on trigger).
- [ ] (@Supabase_Ops) disputes: allow INSERT for complainant when dispute is for a direct_offer they are party to; SELECT for parties + admin.
- [ ] (@Supabase_Ops) RLS check matrix file in `.TODO/` for direct_offers + disputes.
- **Verify (@Sentinel):** negative fails, positive passes.

### 1.3 Triggers / RPC / Cron

- [ ] (@Supabase_Ops) fn_direct_offer_guard: disallow UPDATE of price, currency, fee_rate_bps_snapshot when status not in (sent) or when payment_status != 'unpaid' (per business rule).
- [ ] (@Supabase_Ops) New RPC or extend existing: e.g. rpc_mark_delivered_direct_offer(entity_id) that sets status='delivered', delivered_at=now(), review_expires_at=now()+interval '3 days' (or keep in app UPDATE with both columns).
- [ ] (@Supabase_Ops) Cron fn_check_expired_reviews (or equivalent): add branch for direct_offers where status='delivered' AND payment_status='held' AND review_expires_at IS NOT NULL AND now() > review_expires_at → call release_with_fee path with idempotency (same pattern as rpc_approve_delivery).
- [ ] (@Supabase_Ops) process_payment_event_ledger: for direct_offer release_with_fee, use fee_rate_bps_snapshot from row when present (extend RPC or function signature if needed).
- **Verify (@Sentinel):** state rules enforced; no double release.

### 1.4 Migration Execution

- [ ] (@DataMigration) Apply migration(s) per plan; backfill fee_rate_bps_snapshot/currency for existing direct_offers if required.
- **Verify (@Sentinel):** verify queries and RPCs pass against live DB.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) DirectOffer model: add currency, feeRateBpsSnapshot, paymentRequestId, paymentGatewayId, paymentCorrelationId, paymentExpiresAt, paymentRecoveredAt, deliveredAt, reviewExpiresAt; fromJson/toJson; nullable where appropriate.
- [ ] (@Architect) Mapping + domain error mapping for new guard/trigger errors.
- **Verify (@Sentinel):** types/nullability match contract and DB.

### 2.2 Services / Repositories

- [ ] (@Architect) DirectOffersService.markDelivered: after UPDATE status, set delivered_at and review_expires_at (via second UPDATE or single UPDATE with all three; or call new RPC if implemented).
- [ ] (@Architect) Create payment flow: before redirect to QiCard, edge function (or app) must UPDATE direct_offers SET payment_request_id, payment_correlation_id, payment_expires_at where id=offerId (edge should do this when creating session); recovery must match payment_request_id and set payment_gateway_id, payment_recovered_at.
- [ ] (@Architect) At accept (or at create): read current platform fee_rate_bps and stamp fee_rate_bps_snapshot (and currency) on row — either in acceptOfferWithoutPayment or in edge when creating payment session; ensure ledger release uses it.
- [ ] (@Architect) Optional: requestCancelActiveOffer (mutual) or createDisputeForDirectOffer — call disputes insert with direct_offer_id; admin resolution path (existing) extended to handle direct_offer refund/release.
- [ ] (@Architect) No N+1; storage rule: paths only, signed URLs at render.
- **Verify (@Sentinel):** RLS-safe, no UI→Supabase; idempotency in recovery.

### 2.3 ViewModels

- [ ] (@Architect) DirectOfferDetailsViewModel (and chat/dashboard where offer state is used): all actions gated on composite state (e.g. canMarkDelivered = isActive; canComplete = isDelivered && paymentHeld; canCancelByClient = accepted && unpaid).
- [ ] (@Architect) Single source of truth; loading/error handling for new fields.
- **Verify (@Sentinel):** recoverable state, correct transitions.

### 2.4 Observability

- [ ] (@Observability) Event list + correlation strategy in `.TODO/` for direct offer payment and dispute.
- [ ] (@Architect) Instrument services/viewmodels (not UI); no sensitive data in logs.
- **Verify (@Sentinel):** consistent correlation, no PII.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Chat offer bubble and DirectOfferDetailsScreen: use ViewModel/service only; all labels and buttons driven by composite state; rename any "Pending" to "Sent" where it denotes offer status.
- [ ] (@Pixel) Loading/empty/error states for new flows (e.g. dispute created).
- **Verify (@Sentinel):** stable UX on slow/empty data; no Supabase in view.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Micro-interactions low-risk only.
- **Verify (@Sentinel):** no perf regression.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Shapes/types match contract; migration verify queries (if any) pass.
- **Verify (@Sentinel):** no mismatch.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute ThreatModeler negative checks (unauthorized cancel, double webhook, fee tampering, timeout abuse).
- [ ] (@Sentinel) RLS leak audit for direct_offers and disputes; storage audit if dispute evidence used.
- **Verify (@Sentinel):** unauthorized access impossible.

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E: create → accept → pay (with recovery path) → deliver → complete; deliver → wait/simulate cron → auto-release; cancel sent; cancel accepted unpaid; create dispute for active offer (if implemented).
- [ ] (@Sentinel) Edge cases: app crash after redirect (recovery by payment_request_id); duplicate webhook (idempotency); null review_expires_at (no auto-release).
- **Verify (@Sentinel):** no crashes, consistent behavior.

### 4.4 Observability Validation (if included)

- [ ] (@Sentinel) Required logs/events exist and are useful; privacy redaction enforced.
- **Verify (@Sentinel):** actionable telemetry without leaks.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md (schema, lifecycle, composite states, dispute, timeout, gateway columns).
- [ ] (@SlineDocs) Update Sline_everything/SUPABASE_SETUP.md §5.14 direct_offers, §5.24 disputes, RPC/cron sections.
- [ ] (@SlineDocs) Update any AppDiagram/state diagram to V3 composite state machine (sent_unpaid → ... → completed_released / canceled_*).
- **Verify (@Sentinel):** docs match code + live DB reality.

---

## 7) Acceptance Criteria (MANDATORY)

- All offer lifecycle transitions (create, accept, pay, deliver, complete, cancel sent, cancel accepted unpaid) work without regression.
- Delivered direct offers auto-release after review window when cron runs (review_expires_at set, cron includes direct_offers).
- No permanent escrow lock: every delivered offer has a path to release (manual approve or auto after 3 days).
- Active (paid) offers can enter dispute path; admin can resolve to refund or release; disputes table supports direct_offer_id.
- Payment traceability: payment_request_id/correlation_id/expires_at stored before redirect; recovery uses DB; idempotency prevents double escrow.
- Fee and currency: release_with_fee for direct_offer uses fee_rate_bps_snapshot and currency from row; no tampering after accept.
- UI and diagrams use "sent" not "pending"; composite states drive all actions.
- RLS and guard prevent unauthorized updates and fee/price/currency changes after acceptance.
- Observability: key events logged without PII.
- Documentation and diagrams reflect implementation and DB schema.

---

## 8) Rollback Plan

- **DB rollback:** New columns are additive; no automatic rollback of DDL. If needed: stop cron branch for direct_offers only; do not drop columns until no app version depends on them. For disputes.direct_offer_id: leave column nullable; no drop required for rollback of feature.
- **App rollback:** Revert app to previous version; ensure backend accepts old app (null delivered_at/review_expires_at → cron skips; null payment_* → recovery still works if edge remains backward compatible).
- **Emergency disable:** Feature flag or config to disable auto-release for direct_offers only; or temporarily point cron to no-op for direct_offers branch.

---

## 9) References (From Scan)

- `Sline_everything/DEVELOPER_GUIDE.md` (system map, Direct Chat Offers reference)
- `Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md`
- `Sline_everything/SUPABASE_SETUP.md` (§5.14 direct_offers, §5.8 bookings, §5.24 disputes, §9 rpc_approve_delivery, process_payment_event_ledger, fn_check_expired_reviews)
- `Sline_everything/MVP_ROADMAP.md`, `ARCHITECTURE_ANALYSIS.md`, `STRUCTURE.md`, `CODE_REVIEW.md`
- `lib/features/direct_offers/services/direct_offers_service.dart`, viewmodels, view, models
- `lib/features/chat/` (ChatViewModel, offer_message_bubble), `lib/features/dashboard/` (dashboard_repository, dashboard_view_model, dashboard_screen)
- `.TODO/improvement_the_system/ImplementReady/06_direct-chat-offer-flow/` (00_HOLISTIC_REPORT.md, 01_NOTES.md, 02_GAPS_AND_FIXES.md, 03_RISK_REGISTER.md, 07_SYSTEM_CRITIC_VERDICT.md)
- Live Supabase scan (MCP list_tables, execute_sql) to be performed at Phase 0/1 and referenced in execution log.
