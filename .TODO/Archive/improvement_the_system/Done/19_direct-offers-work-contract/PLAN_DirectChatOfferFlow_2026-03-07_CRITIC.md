# Plan Critic — Direct Chat Offer Flow (Execution-Ready Rewrite)

**Source plan:** `.TODO/PLAN_DirectChatOfferFlow_2026-03-07.md`  
**Workflow:** `.agents/workflows/plan_critic.md`  
**Date:** 2026-03-07

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (inferred)

- Stack: Flutter + Supabase; MVVM; Provider; existing direct_offers feature and edge functions.
- Review window for auto-release is 3 days (align with bookings/tasks where documented).
- Fee lock column name: migrations use `fee_rate_applied_bps` in patch pseudocode; plan said `fee_rate_bps_snapshot`. Assumed: use one name consistently (see Decision below).
- Cron: SUPABASE_SETUP does not list `fn_check_expired_reviews`; assumed equivalent scheduled job or pg_cron exists for tasks/bookings and will be extended, or must be created.
- QiCard edge functions own creation of payment session and write of payment_request_id/correlation_id/expires_at to DB (server authority).
- Disputes: additive `direct_offer_id`; constraint "exactly one of task_id or direct_offer_id" (or equivalent) to be decided.

### Decision Needed (Blocking)

| # | What decision is missing | Options | Recommended | What changes in plan |
|---|---------------------------|---------|-------------|------------------------|
| 1 | Fee lock column name on `direct_offers` | (A) `fee_rate_bps_snapshot` (B) `fee_rate_applied_bps` | (B) `fee_rate_applied_bps` — matches existing migration pseudocode `20260307_08_patch_rpc_fee_locking.sql` and avoids two names in codebase. | All DDL, model, and doc references use `fee_rate_applied_bps`. Plan already references ledger reading "from row". |
| 2 | Who writes payment_request_id / correlation_id / expires_at | (A) Edge only (B) App calls RPC then edge (C) Edge writes on create session | (C) Edge writes when creating payment session (server authority). | Phase 2: ensure edge `qicard_payment_create_direct_offer` updates direct_offers row before returning form_url; app only reads. |
| 3 | Disputes: direct_offer linkage | (A) Add `direct_offer_id` uuid nullable; CHECK (task_id IS NOT NULL OR direct_offer_id IS NOT NULL) (B) Polymorphic related_entity_type + related_entity_id | (A) Simpler, matches existing task_id pattern; admin views already filter by task. | Phase 1 schema and RLS use direct_offer_id; Phase 2 dispute creation passes direct_offer_id. |

---

## B) Gate Status (Pass/Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|--------------------------|
| **0) Test Infrastructure** | ❌ FAIL | No test harness or fixture contract for direct_offers; no RLS test steps; no automated smoke for payment path. | Add Gate 0: create `test/features/direct_offers/`; define fixture contract (minimal direct_offers row + auth); add RLS test matrix runnable step; document run command. |
| **1) Data/Contracts** | ❌ FAIL | Live DB not scanned; contract files not yet written; fee source for release_with_fee (row vs meta) not confirmed in live RPC. | Run live Supabase scan; add contract artifact (`.TODO/` direct_offer payment + release); confirm process_payment_event_ledger reads fee from direct_offers row when present. |
| **2) Security** | ⚠️ PASS (conditional) | RLS and guard are in plan; trigger to block price/currency/fee updates after accept is specified. | Make explicit: RLS UPDATE policy does not expose fee_rate_applied_bps/price/currency to client updates; guard or trigger enforces. Add RLS check matrix with 2+ negative tests. |
| **3) Backend/API** | ❌ FAIL | Cron for direct_offers auto-release may not exist; ledger RPC may not yet use row fee for direct_offer. | Confirm or create cron branch for direct_offers; implement or verify process_payment_event_ledger uses direct_offers.fee_rate_applied_bps on release_with_fee. |
| **4) UI/Integration** | ⚠️ PASS (conditional) | Phase 3 wires composite state; no UI before backend. | Ensure no UI change deploys before Phase 1–2 backend and contract verification. |
| **5) Release/QA** | ❌ FAIL | Manual E2E only; no automated regression; no flake/retry policy. | Add at least one automated critical-path test (e.g. service role/state guards); document manual E2E script and edge-case checklist; add retry budget for payment simulator if used. |

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix (exact step(s)) | Owner | Acceptance check |
|-----|-------------------|---------------------|--------|-------------------|
| Live DB never scanned before schema change | Drift (e.g. column already present) causes migration failure or duplicate object errors. | Insert step **before** any DDL: "Run Supabase MCP list_tables (verbose) for public.direct_offers, disputes; execute_sql to list fn_direct_offer_guard and any pg_cron/scheduled job touching review_expires_at. Record result in execution log." | Backend / @Supabase_Ops | Log artifact listing current columns and trigger/cron names. |
| Cron for auto-release not confirmed to exist | Delivered offers never auto-release; permanent escrow lock remains. | Add step: "Locate or create scheduled function that runs release for entities where review_expires_at < now(). Add branch for direct_offers (status=delivered, payment_status=held, review_expires_at not null). Use same idempotency pattern as rpc_approve_delivery." | Backend / @Supabase_Ops | Cron run (or manual run) releases one test delivered direct_offer after expiry. |
| Fee for direct_offer release not read from row | Ledger uses global or client-supplied fee; platform revenue or provider amount wrong after fee change. | Add step: "In process_payment_event_ledger, for direct_offer release_with_fee: read fee_rate_applied_bps (or fee_rate_bps_snapshot) and amount from direct_offers row; ignore p_meta for fee. If column null, fallback to platform_settings or safe default." | Backend / @Supabase_Ops | Unit or integration test: change global fee, release direct_offer created before change; assert fee used is row value. |
| markDelivered does not set delivered_at / review_expires_at | Cron has nothing to act on; auto-release never triggers. | Add step: "DirectOffersService.markDelivered (or RPC called by it) must set status='delivered', delivered_at=now(), review_expires_at=now()+3 days in one UPDATE." | Backend / @Architect | After markDelivered, SELECT shows non-null delivered_at and review_expires_at. |
| No test harness or RLS tests | Regressions (e.g. client completing before deliver) ship; RLS leaks go undetected. | Add Gate 0: "Create test/features/direct_offers/; add direct_offers_service_test.dart with tests: (1) client cannot call cancelOffer, (2) freelancer cannot call payNow, (3) markDelivered only when isActive. Add RLS check: allowed (client updates own accepted row to canceled), forbidden (other user updates same row). Document run: flutter test test/features/direct_offers/." | Frontend + Backend / @Sentinel + @Architect | `flutter test test/features/direct_offers/` passes; RLS matrix file exists and is run. |
| Dispute creation for direct_offer not a concrete step | Active offers stay stuck; support keeps manual DB edits. | Add step: "Implement createDisputeForDirectOffer(offerId): validate current user is client or freelancer, status active or delivered; insert into disputes (direct_offer_id, complainant_id, defendant_id, reason, status='open'). Wire 'Report issue' in DirectOfferDetailsScreen to ViewModel → service." | Backend + Frontend / @Architect + @Pixel | User can open dispute from offer detail; row exists in disputes with direct_offer_id. |
| Payment intent not persisted before redirect | Crash or back-button loses payment; recovery has no DB anchor. | Add step: "Edge qicard_payment_create_direct_offer: after creating QiCard session, UPDATE direct_offers SET payment_request_id=..., payment_correlation_id=..., payment_expires_at=... WHERE id=offer_id AND status='accepted' AND payment_status='unpaid'. Return same ids to app." | Backend / @Supabase_Ops (edge) | After create session, row has non-null payment_request_id and payment_expires_at. |
| Double webhook / double recovery idempotency | Two ledger escrow_hold for same offer; double debit or constraint violation. | Plan already references idempotency; add explicit: "Recovery and webhook path use same idempotency key pattern (entity_id + payment_request_id or gateway_id); process_payment_event_ledger rejects duplicate key." | Backend / @Supabase_Ops | Second call with same key returns success without second ledger write (verify in test). |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|----------------|
| Direct offer status + payment_status transitions are valid and monotonic. | fn_direct_offer_guard trigger; app service checks before UPDATE. | Trigger test: invalid transition raises; service test: wrong role/state throws. |
| No double escrow_hold or double release for same offer. | Idempotency key in process_payment_event_ledger; journal_entries unique constraint. | Test: same idempotency key twice → one journal entry. |
| Client cannot update price/currency/fee after acceptance. | Trigger or RLS: block UPDATE of price, currency, fee_rate_applied_bps when status != 'sent' or payment_status != 'unpaid'. | RLS/trigger test: client role UPDATE with changed price on accepted row fails. |
| Delivered offers have a path to release (manual or auto). | review_expires_at set on markDelivered; cron runs release for expired rows. | E2E: deliver → advance time / run cron → payment_status=released. |
| Single source of truth for payment intent: DB. | payment_request_id, payment_correlation_id, payment_expires_at stored before redirect; recovery reads from row. | Recovery test: row without payment_request_id not recoverable by id; with it, recovery succeeds once. |
| RLS: only client or freelancer of the offer can read/update their offer. | RLS policies on direct_offers SELECT/UPDATE by client_id/freelancer_id. | RLS matrix: other user SELECT/UPDATE fails. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Live DB drift (column/trigger already exists) | Phase 1 DDL | Med | Med | Local | Migration apply error | Run live scan first; conditional DDL or skip. | Document drift; no drop. |
| Cron does not run or misses direct_offers | Phase 1 cron | Med | High | Feature | Delivered offers never auto-release | Add direct_offers branch; test with one row. | Manual run script; support run. |
| Fee from row not used on release | Ledger RPC | Med | High | Data integrity | Wrong fee in ledger_lines | Implement read from direct_offers in RPC. | Patch RPC; backfill if needed. |
| Timeout abuse (freelancer delivers, waits 3d) | UX / cron | Med | Med | Feature | Client complaints | Notify client on deliver; dispute before expiry. | Dispute path; admin release to client. |
| Double webhook / double recovery | Edge + app | Low | High | Data-loss / duplicate hold | Duplicate journal_entries or constraint error | Idempotency key; unique constraint. | Idempotency test; alert on duplicate key. |
| Old app leaves review_expires_at null | Backfill / cron | Low | Med | Feature | Null review_expires_at on delivered | Cron: only rows where review_expires_at IS NOT NULL. | No auto-release for old rows until app updated. |
| Disputes RLS allows cross-user insert | Phase 1 RLS | Low | High | Security-breach | RLS test fails | Policy: complainant is client or freelancer of direct_offer. | RLS matrix; fix policy. |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** the migration runs against a DB that already has `delivered_at` from a prior experiment → duplicate column error; **gap: live scan**.
- **This fails when** the team assumes a cron exists and it doesn’t → delivered offers never auto-release; **gap: cron confirmation**.
- **This fails when** release_with_fee still uses global fee for direct_offer → after a fee change, old offers release with wrong amount; **gap: fee from row**.
- **This fails when** markDelivered only updates status → review_expires_at stays null and cron skips the row; **gap: set delivered_at + review_expires_at**.
- **This fails when** a user crashes after redirect and recovery looks up by offer_id only → two sessions could be created; **mitigation: persist payment_request_id before redirect**.
- **This fails when** two webhooks arrive for the same payment → double escrow_hold without idempotency; **mitigation: idempotency key**.
- **This fails when** no one runs RLS tests → a policy allows another user to update an offer; **gap: RLS test matrix**.
- **This fails when** "Report issue" is not implemented → active offers have no dispute path; **gap: createDisputeForDirectOffer**.
- **This fails when** client taps Complete before deliver and UI allows it → guard blocks but UX is confusing; **mitigation: composite state gating in UI**.
- **This fails when** tests are only manual → regression ships (e.g. payNow allowed for freelancer); **gap: service + RLS tests**.

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|------------------|-----------------|
| Confirm live schema and cron | Avoid duplicate DDL and wrong assumptions. | Run MCP list_tables verbose for direct_offers, disputes; SQL to list trigger and cron names. | Execution log snippet: columns, trigger, cron. | Log exists; no DDL until reviewed. |
| Single fee column name | Avoid two names (snapshot vs applied_bps). | Use fee_rate_applied_bps everywhere (DDL, model, docs). | Migration, DirectOffer model, SUPABASE_SETUP.md. | Grep shows one name. |
| Cron branch for direct_offers | Auto-release delivered offers. | Add branch in existing cron (or create): WHERE direct_offers.status='delivered' AND payment_status='held' AND review_expires_at IS NOT NULL AND now() > review_expires_at; call same release path as rpc_approve_delivery with idempotency. | Migration or cron job definition. | One test row auto-releases after expiry. |
| Ledger reads fee from row for direct_offer | Correct fee on release after global change. | In process_payment_event_ledger release_with_fee for direct_offer: SELECT fee_rate_applied_bps, price FROM direct_offers WHERE id=p_related_entity_id; use that fee; if null use safe default. | Migration patching RPC. | Test: change global fee, release old offer; fee = row value. |
| markDelivered sets timestamps | Cron can run. | UPDATE direct_offers SET status='delivered', delivered_at=now(), review_expires_at=now()+interval '3 days' WHERE id=... (in service or via RPC). | DirectOffersService + optional RPC. | SELECT after markDelivered has non-null delivered_at, review_expires_at. |
| Payment intent persisted before redirect | Recovery and idempotency possible. | Edge qicard_payment_create_direct_offer: after session create, UPDATE direct_offers SET payment_request_id, payment_correlation_id, payment_expires_at WHERE id AND status='accepted' AND payment_status='unpaid'. | Edge function code. | After create session, row has values. |
| RLS + service tests | Regressions and RLS leaks caught. | Add test/features/direct_offers/direct_offers_service_test.dart (role/state guards); add .TODO RLS check matrix and 2 tests (allowed + forbidden). | Test file; matrix doc; run command. | flutter test passes; matrix run documented. |
| Dispute creation for direct_offer | Active offers can be escalated. | createDisputeForDirectOffer(offerId): validate user is party, insert disputes (direct_offer_id, complainant_id, defendant_id, reason, status='open'). UI: "Report issue" → ViewModel → service. | Service method; UI button; disputes row. | E2E: create dispute from offer detail; row exists. |
| Contract artifact | Shared contract for payment and release. | Write .TODO/06_direct_offer_contract.md: payment (edge writes payment_* before redirect; recovery idempotency); release (fee from row). | Contract file. | File exists; Phase 1–2 steps reference it. |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Goal / Why / Result (overall)

- **Goal:** Harden Direct Chat Offer flow: nomenclature, escrow timeout, composite states, dispute path, payment traceability, fee/currency lock.
- **Why:** Permanent escrow lock, no active-offer cancellation, no gateway traceability, and fee drift are critical risks.
- **Result:** Direct offers have delivered_at/review_expires_at, cron auto-release, disputes.direct_offer_id, payment_* columns, fee_rate_applied_bps used on release; UI uses composite state and "sent"; tests and RLS matrix in place.

---

### Phase 0: Test Infrastructure & Preconditions Gate

**Goal:** Test harness and contracts exist so later phases are verifiable.  
**Why:** Without them, fake progress (e.g. "QA done" with no automated checks) is likely.  
**How:** Create test dir; contract doc; live DB scan; threat model and migration plan.

**Steps:**

1. **(@Sentinel)** Create `test/features/direct_offers/`; add `direct_offers_service_test.dart` with: (1) client cannot call cancelOffer (wrong role), (2) freelancer cannot call payNow (wrong role), (3) markDelivered throws when !isActive. Use mocks for SupabaseClient/LedgerService. **Output:** Test file. **Stop:** `flutter test test/features/direct_offers/` passes (or skipped with @Skip if deps not ready; document reason).
2. **(@APIContract)** Write `.TODO/06_direct_offer_contract.md`: payment intent (edge writes payment_request_id, payment_correlation_id, payment_expires_at before redirect; recovery idempotency key shape); release (release_with_fee for direct_offer uses row.fee_rate_applied_bps). **Output:** Contract file. **Stop:** File in repo; referenced in Phase 1–2.
3. **(@Supabase_Ops)** Live Supabase scan: list_tables verbose public.direct_offers, public.disputes; execute_sql to list trigger on direct_offers and any pg_cron/scheduled job name containing review_expires or expired. **Output:** Execution log (columns, trigger name, cron name or "none"). **Stop:** Log exists; no Phase 1 DDL until drift is resolved.
4. **(@ThreatModeler)** Threat model for direct offer flow (permanent lock, timeout abuse, double webhook, fee tampering, unauthorized cancel). **Output:** `.TODO/06_direct_offer_threat_model.md` with testable negative cases. **Stop:** Doc exists; Phase 4 references it.
5. **(@DataMigration)** Migration plan: additive columns only; backfill currency/default fee for existing rows if needed; rollback = disable cron branch only. **Output:** `.TODO/06_direct_offer_migration_plan.md`. **Stop:** Doc exists.

**GATE CHECK:** Test dir and contract exist; live scan logged; threat model and migration plan documented. If Gate 0 fails, do not start Phase 1.

---

### Phase 1: Data & Contracts Gate (Schema, RLS, Triggers, Cron)

**Goal:** DB and RPC support timeout, traceability, fee lock, and disputes.  
**Why:** UI and app logic depend on columns and RPC behavior.  
**How:** Additive DDL; RLS; guard/trigger; cron branch; ledger fee-from-row.

**Steps:**

1. **(@Supabase_Ops)** DDL migration (only if live scan shows columns missing): ALTER TABLE direct_offers ADD COLUMN currency text NOT NULL DEFAULT 'IQD', ADD COLUMN fee_rate_applied_bps int NOT NULL DEFAULT 1000, ADD COLUMN payment_request_id text, ADD COLUMN payment_gateway_id text, ADD COLUMN payment_correlation_id text, ADD COLUMN payment_expires_at timestamptz, ADD COLUMN payment_recovered_at timestamptz, ADD COLUMN delivered_at timestamptz, ADD COLUMN review_expires_at timestamptz. Optional: partial index idx_direct_offers_processing WHERE status='accepted' AND payment_status='unpaid' AND payment_request_id IS NOT NULL. **Output:** Migration file. **Stop:** Apply succeeds; list_tables shows columns.
2. **(@Supabase_Ops)** disputes: ADD COLUMN direct_offer_id uuid REFERENCES direct_offers(id); ADD CONSTRAINT chk_dispute_entity CHECK (task_id IS NOT NULL OR direct_offer_id IS NOT NULL). **Output:** Migration. **Stop:** Apply succeeds.
3. **(@Supabase_Ops)** RLS: direct_offers UPDATE remains participant; ensure no policy allows client/freelancer to set fee_rate_applied_bps/price/currency (or rely on trigger). disputes: INSERT for complainant where direct_offer_id in (SELECT id FROM direct_offers WHERE client_id = auth.uid() OR freelancer_id = auth.uid()). **Output:** Migration. **Stop:** RLS matrix run (allowed/forbidden) passes.
4. **(@Supabase_Ops)** fn_direct_offer_guard (or new trigger): forbid UPDATE of price, currency, fee_rate_applied_bps when status != 'sent' or payment_status != 'unpaid'. **Output:** Migration. **Stop:** Invalid UPDATE raises.
5. **(@Supabase_Ops)** Cron: add branch for direct_offers (status='delivered', payment_status='held', review_expires_at IS NOT NULL, now() > review_expires_at) → call same release logic as rpc_approve_delivery with stable idempotency key. If no cron exists, create scheduled function and schedule it. **Output:** Migration or cron definition. **Stop:** One test row auto-releases after setting review_expires_at in past and running job.
6. **(@Supabase_Ops)** process_payment_event_ledger: for direct_offer release_with_fee, read fee_rate_applied_bps and price from direct_offers row; use for fee calculation; ignore client p_meta for fee. **Output:** Migration (patch RPC). **Stop:** Test or manual run: release uses row fee.
7. **(@DataMigration)** Apply migrations; backfill fee_rate_applied_bps/currency for existing direct_offers if required. **Output:** Applied migrations log. **Stop:** Queries and RPCs succeed.

**GATE CHECK:** All migrations applied; RLS matrix passed; cron branch runs; ledger uses row fee. If Gate 1 fails, do not start Phase 2.

---

### Phase 2: Security Gate (RLS Matrix, Guard Verification)

**Goal:** No cross-user or post-accept tampering.  
**Why:** Money and status must be protected.  
**How:** RLS check matrix file; run negative tests.

**Steps:**

1. **(@Supabase_Ops)** Create `.TODO/06_direct_offers_rls_matrix.md`: table of (actor, action, expected). E.g. client UPDATE own offer status to canceled when accepted+unpaid: allow; other user UPDATE: deny. **Output:** Matrix file. **Stop:** File exists.
2. **(@Sentinel)** Run RLS checks (e.g. as second user): SELECT/UPDATE direct_offers row belonging to another user must fail. **Output:** Test steps or script. **Stop:** Negative cases fail as expected.

**GATE CHECK:** RLS matrix documented and negative tests pass. Then proceed to Phase 3.

---

### Phase 3: Backend/API Gate (Services, Edge, Model)

**Goal:** App and edge use new columns and contracts.  
**Why:** UI and recovery depend on service and edge behavior.  
**How:** Model fields; markDelivered sets timestamps; edge persists payment_*; accept stamps fee/currency; optional dispute creation.

**Steps:**

1. **(@Architect)** DirectOffer model: add currency, feeRateAppliedBps, paymentRequestId, paymentGatewayId, paymentCorrelationId, paymentExpiresAt, paymentRecoveredAt, deliveredAt, reviewExpiresAt (fromJson/toJson, nullability per DB). **Output:** direct_offer_model.dart. **Stop:** Types match contract.
2. **(@Architect)** DirectOffersService.markDelivered: single UPDATE setting status='delivered', delivered_at=now(), review_expires_at=now()+3 days (or call RPC that does same). **Output:** Service code. **Stop:** After markDelivered, SELECT shows non-null delivered_at, review_expires_at.
3. **(@Supabase_Ops / Edge)** Edge qicard_payment_create_direct_offer: after creating QiCard session, UPDATE direct_offers SET payment_request_id=..., payment_correlation_id=..., payment_expires_at=... WHERE id=offer_id AND status='accepted' AND payment_status='unpaid'. **Output:** Edge code. **Stop:** After create session, row has values.
4. **(@Architect)** At accept (acceptOfferWithoutPayment): read current platform fee_rate_bps (e.g. platform_settings or default 1000) and currency 'IQD'; UPDATE direct_offers SET fee_rate_applied_bps=..., currency=... WHERE id=offerId. **Output:** Service code. **Stop:** After accept, row has fee_rate_applied_bps set.
5. **(@Architect)** Recovery path (app + edge): validate payment_request_id matches row; set payment_gateway_id, payment_recovered_at on success; idempotency key from entity_id + payment_request_id (or per contract). **Output:** Edge + service. **Stop:** Second recovery with same key does not double-apply.
6. **(@Architect)** Optional: createDisputeForDirectOffer(offerId) — validate user is client or freelancer, offer status active or delivered; INSERT disputes (direct_offer_id, complainant_id, defendant_id, reason, status='open'). **Output:** Service method. **Stop:** Insert succeeds; RLS allows.
7. **(@Architect)** ViewModels: all actions gated on composite state (canMarkDelivered = isActive; canComplete = isDelivered && paymentHeld; canCancelByClient = accepted && unpaid). **Output:** ViewModel logic. **Stop:** No action available when state forbids it.
8. **(@Observability)** Event list for direct offer (create, accept, pay, deliver, complete, dispute) in `.TODO/`; instrument service (no PII). **Output:** Event list; log calls. **Stop:** Doc and logs in place.

**GATE CHECK:** Model and service match contract; edge persists payment_*; recovery idempotent; fee stamped on accept. Then proceed to Phase 4.

---

### Phase 4: UI/Integration Gate (Wiring, Nomenclature, Dispute Entry)

**Goal:** UI reflects composite state and "sent"; dispute entry available.  
**Why:** Correct UX and no Supabase in view.  
**How:** Wire ViewModel only; rename Pending → Sent; optional "Report issue" button.

**Steps:**

1. **(@Pixel)** Chat offer bubble and DirectOfferDetailsScreen: buttons and labels driven by ViewModel composite state only; rename any "Pending" (for offer status) to "Sent". **Output:** View code. **Stop:** No direct Supabase in view; correct labels.
2. **(@Pixel)** Loading/empty/error states for offer detail and (if implemented) dispute creation. **Output:** View code. **Stop:** No crash on empty or error.
3. **(@Pixel)** If createDisputeForDirectOffer exists: add "Report issue" (or equivalent) on DirectOfferDetailsScreen for active/delivered; wire to ViewModel → service. **Output:** Button + wiring. **Stop:** Tap creates dispute row.

**GATE CHECK:** UI uses ViewModel only; nomenclature "sent"; optional dispute flow works. Then proceed to Phase 5.

---

### Phase 5: Release/QA Gate (QA, Security, Docs)

**Goal:** Functional and security checks pass; docs and diagram updated.  
**Why:** Ship only after verification and doc sync.  
**How:** Contract + migration checks; threat model negative tests; E2E script; observability check; docs.

**Steps:**

1. **(@Sentinel)** Contract + migration: shapes match contract; migration verify queries (if any) pass. **Output:** Checklist result. **Stop:** No mismatch.
2. **(@Sentinel)** Run threat model negative cases (unauthorized cancel, double webhook, fee tampering, timeout abuse). **Output:** Test log. **Stop:** All negative cases fail as expected.
3. **(@Sentinel)** Manual E2E script: create → accept → pay (with recovery) → deliver → complete; deliver → simulate cron → auto-release; cancel sent; cancel accepted unpaid; (optional) create dispute. Edge: app crash after redirect → recovery by payment_request_id; duplicate webhook → idempotency. **Output:** E2E checklist or script. **Stop:** All scenarios pass.
4. **(@Sentinel)** Observability: required events logged; no PII. **Output:** Verification note. **Stop:** Logs usable; no leak.
5. **(@SlineDocs)** Update DEVELOPER_GUIDE/Direct_Offers_Feature.md (schema, lifecycle, composite states, dispute, timeout, gateway columns). Update SUPABASE_SETUP.md §5.14 direct_offers, §5.24 disputes, RPC/cron. Update AppDiagram/state diagram to V3 composite (sent_unpaid → ...). **Output:** Updated docs. **Stop:** Docs match code and DB.

**GATE CHECK:** All Phase 5 steps done; E2E and negative tests pass; docs updated. Then release.

---

### Acceptance Criteria (recap)

- Lifecycle create → accept → pay → deliver → complete and cancel (sent / accepted unpaid) work.
- Delivered offers get delivered_at and review_expires_at; cron auto-releases after 3 days.
- No permanent escrow lock.
- Active/delivered offers can enter dispute (direct_offer_id); admin can resolve.
- Payment traceability: payment_* stored before redirect; recovery idempotent.
- release_with_fee for direct_offer uses row.fee_rate_applied_bps; no tampering after accept.
- UI uses "sent" and composite state; RLS and guard prevent unauthorized and post-accept updates.
- Tests: service role/state guards and RLS matrix run; docs and diagram updated.

---

### Rollback Plan (unchanged)

- DB: additive only; rollback = disable cron branch for direct_offers; do not drop columns.
- App: revert app; backend tolerates null delivered_at/review_expires_at and null payment_*.
- Emergency: disable auto-release (config or cron no-op for direct_offers).

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- No test infrastructure or RLS test steps; no Gate 0.
- Live DB scan was in Phase 1 instead of a precondition; risk of drift.
- Fee column name inconsistency (fee_rate_bps_snapshot vs fee_rate_applied_bps).
- Cron for direct_offers auto-release assumed to exist; not confirmed.
- Ledger reading fee from row for direct_offer not a concrete step.
- markDelivered did not explicitly set delivered_at/review_expires_at in one place.
- Payment intent persistence before redirect was "edge should"; not assigned as edge step.
- Dispute creation was "optional" without a concrete task; RLS for disputes.direct_offer_id not detailed.
- No explicit RLS check matrix or negative tests.
- Phases were not gate-based; no "GATE CHECK" to block progress.
- Test Infrastructure Gate and Security Gate were not separate; Release/QA had no automated test requirement.

### 2) Added steps

- Gate 0: Test dir + direct_offers_service_test.dart (role/state guards); contract file; live scan before DDL; threat model; migration plan.
- RLS matrix file and run step; negative RLS tests.
- Explicit step: cron branch for direct_offers (or create cron).
- Explicit step: process_payment_event_ledger reads fee from direct_offers row for release_with_fee.
- Explicit step: markDelivered single UPDATE with delivered_at and review_expires_at.
- Explicit step: edge updates direct_offers with payment_* when creating session.
- Explicit step: acceptOfferWithoutPayment stamps fee_rate_applied_bps and currency.
- Explicit step: createDisputeForDirectOffer + "Report issue" UI (optional but concrete).
- Phase 2 as Security Gate (RLS matrix + verification).
- GATE CHECK at end of each phase.

### 3) Removed steps

- None; optional items made concrete or explicitly optional with owner.

### 4) Reordered steps

- Live Supabase scan: from Phase 1.0 → Phase 0 (before any DDL).
- Contract file: from Phase 0.3 → Phase 0 (artifact before schema).
- Test harness and service tests: from "Evidence Missing" / Phase 4 → Phase 0 and Phase 5.

### 5) Expanded steps

- Phase 1: Split into schema (1), RLS (2), guard (3), cron (4), ledger fee-from-row (5), apply (6); each with output and stop condition.
- Phase 2: New Security Gate with RLS matrix and negative tests.
- Phase 3: Edge persistence of payment_* and accept stamping fee/currency spelled out; recovery idempotency.
- Phase 5: E2E script and threat model execution; observability check.

### 6) Why (short, practical)

- Gate 0 prevents shipping without tests or contracts; live scan prevents migration failures.
- Single fee column name avoids bugs and doc drift.
- Cron and fee-from-row are critical for correctness; they are now unmissable steps.
- RLS matrix and negative tests catch permission bugs before production.
- Gate-based flow blocks fake progress: each phase has a clear pass/fail before the next.

### 7) Residual risks

- Cron scheduling (pg_cron vs Supabase scheduled function) depends on project setup; operator must confirm.
- Admin resolution path for disputes (refund vs release) may require separate admin tooling not in this plan.
- Old app versions that never set review_expires_at: cron correctly skips them but those rows never auto-release until app is updated.
- Flaky E2E (e.g. payment simulator) if used; recommend bounded retries and clear failure artifact path.
