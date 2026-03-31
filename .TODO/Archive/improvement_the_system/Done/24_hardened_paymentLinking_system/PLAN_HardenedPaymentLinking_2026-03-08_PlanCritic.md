# Plan Critic: Hardened Payment Linking System (24)

**Source plan:** `.TODO/PLAN_HardenedPaymentLinking_2026-03-08.md`  
**Workflow:** `.agents/workflows/plan_critic.md`  
**Date:** 2026-03-08

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (inferred)

- Stack: Flutter app, Supabase (Postgres, Edge Functions), QiCard gateway; Admin dashboard is Next.js (referenced in improvement folder).
- Single team or cross-functional execution; agents @Supabase_Ops, @Architect, @Sentinel, @Pixel, @SlineDocs own steps.
- PAYMENT_HMAC_SECRET (or equivalent) will be provisioned in Supabase secrets / Vault before edge deployment; no implementation without it.
- Tender payment flow remains separate (tender-specific edge/RPC); hardening applies to booking and direct_offer first, with optional later extension to tender.
- Realtime is already enabled for `payment_intents` in Supabase project.
- Admin dashboard repo/location exists or will be created; “Next.js dashboard” is in scope for Orphan Queue and Payment Trace.

### Decision Needed (Blocking)

| # | What is missing | Options | Recommended | Why | Plan impact |
|---|-----------------|---------|-------------|-----|-------------|
| D1 | **Canonical create path** | (1) Migrate booking/direct_offer to `create_payment_intent` only and deprecate `qicard_payment_create` / `qicard_payment_create_direct_offer`; (2) Add intent creation + HMAC inside existing `qicard_payment_create` / `qicard_payment_create_direct_offer` and keep two edge names; (3) New single edge (e.g. `payment_intent_create`) used by both booking and direct_offer, deprecate both old create functions. | Option 1 | Single code path, one webhook (`finalize_payment_webhook` or merged into `qicard_webhook_handler`), less branching. | Plan must commit to one create entry point and one webhook entry point; Flutter must call that edge and receive intent_id + checkout_url. |
| D2 | **Canonical webhook** | (1) Harden `finalize_payment_webhook` only and route QiCard to it when using intents; (2) Harden `qicard_webhook_handler` to support intent path (lookup by intent_id/gateway_intent_id, payment_events, HMAC, ledger with intent_id) and keep single webhook URL. | Option 2 | One webhook URL for QiCard; no routing/duplication; existing handler already has QiCard RSA verification. | Plan must specify which handler gets the new logic and that the other is deprecated or removed for booking/direct_offer. |
| D3 | **payment_events intent_id when intent unknown** | Webhook receives payload with gateway_intent_id but no intent_id (e.g. legacy or stripped metadata). (1) Insert payment_events with intent_id NULL and gateway_event_id only; (2) Do not insert payment_events if intent lookup fails, only orphan_payments. | Option 2 | Append-only audit should link to intent when we have one; otherwise we only record orphan. Schema: intent_id nullable or separate “anonymous” event table. | Plan and schema must state whether payment_events.intent_id is NOT NULL (then no row when intent missing) or nullable. |

---

## B) Gate Status (Pass/Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|--------------------------|
| **0) Test Infrastructure Gate** | ❌ FAIL | No shared test harness or fixture contract for payment flows; no bounded timeouts/retries for webhook/e2e; test plan references T-SEC/T-ROB/T-RLS but not infra. | Add step: define test harness (e.g. Supabase local or test project), fixture manifest (minimal booking + intent rows), env/secrets injection for HMAC, timeout/retry budget for integration tests; document run commands. |
| **1) Data/Contracts Gate** | ❌ FAIL | Contract file not written; `journal_entries.meta` shape for payment_intent_id not fixed; payment_events intent_id nullability not decided; live DB not yet scanned. | Add: APIContract artifact (request/response + webhook payload + RPC meta); DDL for new columns and RLS matrix; run Supabase MCP scan and record drift. |
| **2) Security Gate** | ❌ FAIL | RLS for payment_events/orphan_payments not explicit (rely on default deny); no explicit “no UPDATE/DELETE” for payment_events; HMAC secret provisioning not a concrete step. | Add: explicit RLS policies (INSERT service_role only; no UPDATE/DELETE on payment_events); secret provisioning step and verification; RLS test steps (allowed + forbidden). |
| **3) Backend/API Gate** | ❌ FAIL | Create path and webhook path not decided (D1, D2); ledger RPC change not implemented; webhook does not append payment_events or verify HMAC. | Add: implement chosen create + webhook path; add p_payment_intent_id to RPC and meta; implement payment_events INSERT and HMAC verify in webhook. |
| **4) UI/Integration Gate** | ❌ FAIL | Flutter still calls qicard_payment_create for booking; no guarantee intent_id returned on all create paths; Admin Orphan Queue and Trace not implemented. | Add: switch Flutter to call canonical create edge and handle intent_id + Realtime; implement Admin Orphan Queue and Payment Trace; fallback when intent_id null (recovery flow). |
| **5) Release/QA Gate** | ❌ FAIL | No feature flag or staged rollout; no flake/retry policy for tests; no DoD per PR. | Add: feature flag or cutover plan; test retry budget and artifact capture; PR DoD (contract + RLS + one E2E path). |

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix (exact steps) | Owner | Acceptance check |
|-----|-------------------|-------------------|-------|------------------|
| **G1** Canonical create and webhook not chosen | Two code paths will remain; Flutter and QiCard routing ambiguous; duplicate or missing logic. | Add blocking decision step: document “Canonical create = X, Canonical webhook = Y” and “Deprecate/remove Z.” Update plan phases to reference only X and Y. | Product/Architect | One create edge and one webhook handler for booking + direct_offer in scope. |
| **G2** payment_events insert before processing not implemented | Audit trail missing; replay and forensics impossible. | In webhook handler: immediately after signature validation, INSERT into payment_events (gateway_event_id, intent_id if present, payload); use gateway_event_id as idempotency for duplicate event insert (UNIQUE). If intent unknown, still insert with intent_id NULL or skip per D3. | Backend | Every webhook hit produces one payment_events row (or orphan only when intent missing). |
| **G3** Webhook does not verify amount or internal HMAC | Amount tampering and signature bypass; ledger can be credited wrong amount. | In webhook: after intent lookup, (1) compare intent.gross_amount with webhook amount (and currency); (2) recompute HMAC from intent row (entity_id, gross_amount, currency, payer_id) and compare with metadata.signature. On mismatch → orphan_payments, return 200, do not call ledger. | Backend | T-SEC-1, T-SEC-3 pass; orphan_payments has reason (amount_mismatch | signature_mismatch). |
| **G4** Ledger RPC does not accept or store payment_intent_id | Audit link intent → journal missing; forensics and compliance gap. | Add optional p_payment_intent_id UUID to process_payment_event_ledger; in escrow_hold and gateway_escrow branches, set journal_entries.meta = meta || jsonb_build_object('payment_intent_id', p_payment_intent_id). Deploy migration. | Backend | Query journal_entries where meta->>'payment_intent_id' = intent_id returns rows for new payments. |
| **G5** RLS for payment_events not explicit | Default deny may be misconfigured; UPDATE could be allowed by mistake. | Add policies: payment_events INSERT for service_role only; no UPDATE policy; no DELETE policy. Optionally add trigger to reject UPDATE/DELETE. Document in RLS matrix. | Backend | T-RLS-2: authenticated UPDATE payment_events fails. |
| **G6** Flutter create path may not receive intent_id | UI cannot subscribe to Realtime; crash recovery and success resolution fail. | Ensure canonical create edge returns { intent_id, checkout_url } (or form_url). Flutter: if intent_id present, subscribe to payment_intents(id). If absent, keep existing recovery/polling fallback. | Frontend | Booking and direct_offer checkout show success via Realtime when intent_id returned. |
| **G7** No test infra or deterministic setup for payment tests | Tests will be flaky or depend on production; no repeatable runs. | Add Test Infrastructure Gate: define test Supabase project or local, seed minimal data (one booking, one intent), document PAYMENT_HMAC_SECRET injection; set timeout (e.g. 30s) and max retries (1) for webhook integration tests. | Infra/QA | Integration test run completes without env-specific secrets in code; one command documented. |
| **G8** Admin Orphan Queue and Trace not scoped with deliverables | Scope creep or empty “admin” bullet. | Define: Orphan Queue = list page (orphan_payments), filters, raw payload modal, “Resolve”/“Refund” actions (call existing refund RPC or mark investigated). Trace = search by intent_id or gateway_intent_id, show intent row + payment_events rows + journal_entries with meta.payment_intent_id. | Product/Frontend | Admin can open Orphan Queue and Payment Trace and perform at least read + one action. |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|---------------|
| Every escrow/gateway payment is bound to a payment_intent created before the gateway call. | Edge create path inserts payment_intent with signature before calling QiCard; webhook looks up intent by gateway_intent_id or intent_id; ledger called only after intent found and validated. | Query: no journal_entries with event_type in ('escrow_hold','gateway_escrow') and created_at > cutover_date where meta->>'payment_intent_id' is null (after cutover). |
| intent.gross_amount equals webhook amount for successful ledger call. | Webhook compares before calling ledger; mismatch → orphan_payments. | T-SEC-3: send webhook with wrong amount → orphan, no ledger row. |
| payment_events is append-only. | RLS: no UPDATE/DELETE policies; optional trigger RAISE on UPDATE/DELETE. | T-RLS-2: attempt UPDATE payment_events → fail. |
| Same gateway_intent_id (or idempotency_key) never causes two ledger entries. | Webhook checks intent.status = 'succeeded' and returns 200 without calling ledger; ledger idempotency_key includes payment_intent_id or gateway_intent_id. | T-ROB-1: send 5 identical webhooks → 1 ledger entry, 5 payment_events rows. |
| Only service_role can INSERT/UPDATE payment_intents and INSERT payment_events. | RLS policies: anon/authenticated no INSERT/UPDATE on payment_intents; anon/authenticated no INSERT on payment_events. | RLS tests: authenticated INSERT payment_events → fail; authenticated UPDATE payment_intents → fail. |
| Status transitions for payment_intents are monotonic (created → gateway_processing → succeeded | failed). | Application logic in edge; optional DB trigger to enforce allowed transitions. | Test: update intent from succeeded to created fails (app or trigger). |

---

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|--------------|------------|----------|
| HMAC secret missing or wrong | Edge env | Med | High | Feature (payments fail or orphan spike) | Orphan count rises; webhook logs “signature mismatch” | Secret in Vault; deploy checklist; smoke test with known payload | Manual match in Admin Orphan Queue; fix secret and redeploy |
| Webhook replay causes double escrow | Webhook handler | Low | High | Data (double credit) | Duplicate journal_entries for same intent | Idempotency: status=succeeded skip; ledger idempotency_key includes intent/gateway id | Idempotency in RPC; retries return 200 |
| payment_events insert fails and webhook continues | Webhook order of ops | Med | Med | App-wide (no audit) | Missing rows in payment_events for known gateway_event_id | INSERT payment_events first in same request; if INSERT fails, return 5xx and do not process | QiCard retries webhook; fix DB and replay |
| Legacy bookings without intent_id | Mixed flows | High | Low | Local (old rows) | journal_entries with null meta.payment_intent_id | No backfill; new flows only use intent_id | Accept legacy rows; forensics use gateway metadata |
| Gateway strips metadata (intent_id/signature) | QiCard integration | Med | High | Feature (orphan explosion) | Spike in orphan_payments with reason “intent_not_found” or “missing metadata” | Use gateway_intent_id as primary lookup; store gateway_intent_id on intent; fallback lookup by gateway_intent_id | Admin manual link; contact gateway provider |
| Flutter calls wrong edge after cutover | App deploy order | Med | High | Feature (no intent_id, no Realtime) | Users stuck on “Processing” | Deploy edge first; app backward compatible (handle missing intent_id) | Recovery flow; re-deploy app |
| RLS misconfiguration allows write to payment_events | Migration | Low | High | Security-breach | RLS test fails or audit | Explicit policies; RLS matrix and tests | Patch RLS and redeploy |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** the team implements HMAC in the create edge but the webhook still uses the legacy path (qicard_webhook_handler) that never looks up intents → payments complete but no payment_events, no intent_id in ledger, and no audit trail. *(G1, G2)*
- **This fails when** the webhook writes to payment_events only after a successful intent lookup → if lookup fails we never log the raw payload and lose forensics. *(G2, D3)*
- **This fails when** amount or signature verification is skipped “temporarily” and a tampered webhook is processed → wrong amount in ledger or wrong entity credited. *(G3)*
- **This fails when** process_payment_event_ledger is not updated and journal_entries never store payment_intent_id → audit trail broken. *(G4)*
- **This fails when** RLS is left as “default deny” and a later migration adds a permissive policy by mistake → payment_events or payment_intents become writable by anon. *(G5)*
- **This fails when** Flutter continues to call qicard_payment_create which does not return intent_id → Realtime subscription never starts and users never see success. *(G6)*
- **This fails when** integration tests hit production or use hardcoded secrets and fail in CI or leak keys. *(G7)*
- **This fails when** the same success webhook is delivered twice and idempotency is not enforced → two ledger entries and double escrow. *(Invariant, T-ROB-1)*

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|-----------------|----------------|
| Lock canonical create and webhook | Avoid dual paths and ambiguity | Decision: create = create_payment_intent (or migrate qicard_payment_create to create intents); webhook = qicard_webhook_handler with intent lookup + payment_events + HMAC + amount + ledger with intent_id. Deprecate finalize_payment_webhook for new flows or merge its logic into qicard_webhook_handler. | One-page decision doc in .TODO/ or improvement folder | Single create endpoint and single webhook URL documented and used by Flutter / QiCard |
| Test infrastructure for payment tests | Tests must be runnable and deterministic | Create test Supabase config or use existing; document PAYMENT_HMAC_SECRET (or test secret); define seed: one booking, one payment_intent; timeout 30s, retries 1 for webhook tests; run command in README or .TODO/. | Fixture manifest, env template, run command doc | `make payment-test` or equivalent succeeds in CI/local |
| Explicit RLS for payment_events | Prevent accidental UPDATE/DELETE | Migration: CREATE POLICY for INSERT service_role only; do not create UPDATE/DELETE policies; optional trigger to RAISE on UPDATE/DELETE. | DDL in migration; RLS matrix row | T-RLS-2 passes |
| Webhook: insert payment_events first | Audit every webhook hit | In webhook handler, after QiCard signature verification: INSERT INTO payment_events (gateway_event_id, intent_id, event_type, payload). Use gateway_event_id from payload; intent_id from lookup or NULL. Handle UNIQUE on gateway_event_id (ignore duplicate insert). | Edge function code | Every test webhook hit inserts one payment_events row |
| Webhook: verify amount and HMAC | Tampering → orphan only | After intent lookup: if intent.gross_amount != webhook amount (or currency mismatch) → orphan_payments, return 200. Recompute HMAC(secret, entity_id\|gross_amount\|currency\|payer_id), compare to metadata.signature; mismatch → orphan_payments, return 200. | Edge function code | T-SEC-1, T-SEC-3 pass |
| Ledger RPC: payment_intent_id in meta | Audit link | Add p_payment_intent_id UUID DEFAULT NULL to process_payment_event_ledger; in escrow_hold and gateway_escrow branches set meta = COALESCE(meta,'{}'::jsonb) || jsonb_build_object('payment_intent_id', p_payment_intent_id). | Migration + RPC body | Query journal_entries for new payments shows payment_intent_id in meta |
| Contract document | Shared shape for edge and app | Write CONTRACT_*.md: create request (entity_type, entity_id, …), response (intent_id, checkout_url); webhook payload (paymentId, amount, additionalInfo.intent_id, additionalInfo.signature); RPC meta.payment_intent_id. | CONTRACT_*.md in .TODO/ or improvement folder | All parties reference same doc |
| Flutter: use canonical create and Realtime | Success resolution and crash recovery | Change booking/direct_offer to call create_payment_intent (or migrated create) and read intent_id from response; subscribe to payment_intents(id) when intent_id present; on status=succeeded show success; if intent_id null use existing recovery flow. | Flutter service + ViewModel + UI | E2E: pay → success screen without refresh |
| Admin Orphan Queue | Triage orphans | List orphan_payments (table), filter by date/reason; modal with raw payload; actions: Mark investigated, or call refund RPC when applicable. | Admin dashboard page(s) | Admin can open list and resolve one orphan |
| Admin Payment Trace | Forensics | Search by intent_id or gateway_intent_id; show payment_intents row, payment_events rows, journal_entries where meta->>'payment_intent_id' = intent_id. | Admin dashboard page or section | Admin can open trace for one intent and see timeline |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Decisions and Contracts (Blocking)

- **Goal:** Remove ambiguity so implementation has a single path.
- **Why:** Without D1/D2/D3, two implementations will diverge and tests will be undefined.
- **How:** Document canonical create edge and webhook; decide payment_events intent_id when intent missing; write CONTRACT_*.md (create request/response, webhook payload, RPC meta).
- **Result:** One create endpoint, one webhook handler, contract file, and RLS matrix started.

**Steps:**

1. (@Architect) Decide and document: “Canonical create = … ; Canonical webhook = … ; Deprecate/remove ….”
2. (@APIContract) Write CONTRACT_HardenedPaymentLinking.md (request/response, webhook payload, journal_entries.meta.payment_intent_id).
3. (@Supabase_Ops) Decide payment_events.intent_id (NOT NULL vs nullable) per D3; document in contract.

**GATE CHECK (Phase 0):** Contract exists; canonical create and webhook named; no implementation starts until this passes.

---

### Phase 1: Data and Schema

- **Goal:** Schema and RLS ready for intents, events, orphans, and ledger link.
- **Why:** Edge and webhook depend on columns and policies.
- **How:** Run Supabase MCP scan; add columns; add RLS policies; add RPC parameter and meta.
- **Result:** payment_intents (signature, currency, paid_at), payment_events append-only RLS, orphan_payments (investigated optional), process_payment_event_ledger(p_payment_intent_id) and meta.

**Steps:**

1. (@Supabase_Ops) Live scan: list_tables (public) verbose for payment_intents, payment_events, orphan_payments, journal_entries; execute_sql for policies. Record drift in plan or risk register.
2. (@Supabase_Ops) DDL migration: add payment_intents.signature TEXT, payment_intents.currency TEXT DEFAULT 'IQD', payment_intents.paid_at TIMESTAMPTZ; add orphan_payments.investigated BOOLEAN DEFAULT false if desired; ensure payment_events.intent_id matches D3 (nullable or not).
3. (@Supabase_Ops) RLS: payment_intents INSERT/UPDATE service_role only (SELECT payer already exists); payment_events INSERT service_role only, no UPDATE/DELETE policies; orphan_payments INSERT service_role, SELECT for admin. Optional: trigger on payment_events to reject UPDATE/DELETE.
4. (@Supabase_Ops) process_payment_event_ledger: add p_payment_intent_id UUID DEFAULT NULL; in escrow_hold and gateway_escrow set meta = COALESCE(meta,'{}'::jsonb) || jsonb_build_object('payment_intent_id', p_payment_intent_id).
5. (@DataMigration) Apply migration(s). (@Sentinel) Verify: SELECT new columns; RLS tests (authenticated INSERT payment_events fails).

**GATE CHECK (Phase 1):** New columns exist; RLS matrix filled; RPC accepts p_payment_intent_id and writes meta; no RLS leak.

---

### Phase 2: Security and Secrets

- **Goal:** HMAC secret available; RLS tests in place; no sensitive data in logs.
- **Why:** Signature verification and least privilege must be enforced and testable.
- **How:** Provision PAYMENT_HMAC_SECRET (Vault/Edge env); add RLS tests; document logging rules.
- **Result:** Secret set and verified; T-RLS-1, T-RLS-2 in test plan; logging contract (no PII).

**Steps:**

1. (@Supabase_Ops / Infra) Ensure PAYMENT_HMAC_SECRET is set for Edge (Vault or Supabase secrets); document how to rotate.
2. (@Sentinel) Add to test plan: T-RLS-1 (authenticated cannot create intent for other payer), T-RLS-2 (authenticated cannot UPDATE payment_events). Implement or document how to run.
3. (@Observability) Document: log intent_id/gateway_intent_id only (no amount/PII in plaintext); orphan reason logged.

**GATE CHECK (Phase 2):** Secret present; RLS tests defined and runnable; logging rules documented.

---

### Phase 3: Backend (Edge Create + Webhook)

- **Goal:** Create path writes intent with HMAC; webhook appends event, verifies amount and signature, updates intent, calls ledger with payment_intent_id.
- **Why:** Single secure path from create to ledger.
- **How:** Implement in canonical create edge and canonical webhook per Phase 0.
- **Result:** Create returns intent_id + checkout_url with signature in metadata; webhook inserts payment_events, validates, then updates intent and calls ledger with p_payment_intent_id.

**Steps:**

1. (@Architect) Create edge: after inserting payment_intent, compute signature = HMAC-SHA256(PAYMENT_HMAC_SECRET, entity_id|gross_amount|currency|payer_id); update intent with signature; pass signature in gateway additionalInfo; return intent_id and checkout_url.
2. (@Architect) Webhook: (1) Verify QiCard RSA signature. (2) INSERT payment_events (gateway_event_id, intent_id if available, payload). (3) Look up intent by gateway_intent_id or additionalInfo.intent_id. (4) If not found → orphan_payments, return 200. (5) If intent.status = 'succeeded' → return 200 (idempotency). (6) Verify amount (intent.gross_amount == webhook amount) and currency; mismatch → orphan. (7) Verify internal HMAC (recompute from intent, compare to metadata.signature); mismatch → orphan. (8) In transaction: UPDATE payment_intents SET status='succeeded', paid_at=now(); call process_payment_event_ledger(..., p_payment_intent_id => intent.id); update entity (booking/direct_offer/task_request). (9) On any validation failure insert orphan_payments with reason.
3. (@Architect) Migrate booking/direct_offer: if canonical create is create_payment_intent, add booking/direct_offer logic (draft creation, price resolution) into it and have Flutter call it; or refactor qicard_payment_create to create intent + HMAC and return intent_id + form_url. Ensure one code path.
4. (@Sentinel) Run T-SEC-1, T-SEC-2, T-SEC-3, T-ROB-1, T-ROB-2, T-ROB-3.

**GATE CHECK (Phase 3):** Create returns intent_id; webhook inserts payment_events; amount/signature mismatch → orphan; replay → single ledger; ledger meta has payment_intent_id.

---

### Phase 4: Flutter and UI

- **Goal:** Checkout uses canonical create, subscribes to payment_intents by intent_id, shows success/failure via Realtime; Admin Orphan Queue and Trace available.
- **Why:** User sees correct state; support can triage orphans and trace payments.
- **How:** Wire Flutter to canonical create; subscribe when intent_id present; implement Admin pages.
- **Result:** Booking and direct_offer checkout resolve via Realtime when intent_id present; Admin can list orphans and view trace.

**Steps:**

1. (@Architect) Flutter: ensure createPaymentForBooking and createPaymentForDirectOffer call canonical create edge; parse intent_id and checkout_url; subscribe to payment_intents(id) when intent_id != null; on status succeeded/failed update UI; fallback to recovery when intent_id null.
2. (@Pixel) Checkout screens: loading/empty/error states; Realtime drives success/failure; no double submit (disable button while processing).
3. (@Pixel) Admin: Orphan Queue — list orphan_payments, raw payload modal, Mark investigated / Refund (if RPC exists). Payment Trace — search by intent_id or gateway_intent_id, show intent + events + journal_entries.
4. (@Sentinel) E2E: full booking checkout → pay → success; direct_offer checkout → pay → success; one tampered webhook → orphan visible in Admin.

**GATE CHECK (Phase 4):** Flutter uses one create path and Realtime; Admin can open Orphan Queue and Trace and perform at least one action.

---

### Phase 5: QA, Release, and Docs

- **Goal:** All tests pass; rollout safe; docs match implementation.
- **Why:** Regression prevention and safe deployment.
- **How:** Run full test plan; define rollout (flag or cutover); update docs.
- **Result:** Tests green; rollout plan and rollback documented; SUPABASE_SETUP.md and DEVELOPER_GUIDE updated.

**Steps:**

1. (@Sentinel) Run full test plan (T-SEC, T-ROB, T-RLS, E2E); document flake/retry (e.g. 1 retry, 30s timeout); artifact capture for failures.
2. (@Architect) Rollout: deploy edge first (backward compatible response); then app; or feature flag “use_intent_create” and switch when ready. Document rollback: revert edge, app keeps recovery path.
3. (@SlineDocs) Update SUPABASE_SETUP.md: payment_intents, payment_events, orphan_payments (columns, RLS); process_payment_event_ledger p_payment_intent_id and meta; hardened flow. Update DEVELOPER_GUIDE.md: intent lifecycle, HMAC, webhook validation, Realtime, Admin. Update STRUCTURE.md / MVP_ROADMAP.md.
4. (@Sentinel) Definition of done per PR: contract respected, RLS tests pass, one E2E path (booking or direct_offer) verified.

**GATE CHECK (Phase 5):** All gates 0–5 pass; docs updated; rollout and rollback documented.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- Canonical create and webhook not chosen (two paths left open).
- payment_events insert and HMAC/amount verification not explicit as first webhook steps.
- Ledger RPC payment_intent_id and meta not a concrete migration step.
- RLS for payment_events not explicit (no UPDATE/DELETE).
- Test infrastructure and fixture contract missing.
- Admin Orphan Queue and Trace not scoped with clear deliverables.
- Decision on payment_events.intent_id when intent unknown was missing.
- Gate-based ordering and stop conditions were not strict.

### 2) Added steps (bullet list)

- Phase 0: Decision doc (canonical create + webhook); CONTRACT_*.md; payment_events intent_id nullability.
- Test Infrastructure Gate and fixture manifest + run command.
- Explicit RLS policies (INSERT service_role only; no UPDATE/DELETE payment_events).
- Secret provisioning and verification step.
- Webhook: INSERT payment_events first; then intent lookup; then amount + HMAC verify; then transaction (intent update + ledger + entity update).
- Migration: process_payment_event_ledger p_payment_intent_id and meta in journal_entries.
- Admin Orphan Queue and Trace defined (list, payload modal, resolve; search, intent + events + journal).
- Flutter: “use canonical create; subscribe when intent_id present; fallback when null.”
- Rollout and rollback (edge first, app backward compatible); PR DoD.

### 3) Removed steps

- None removed; optional “feature flag” kept as rollout option.

### 4) Reordered steps

- Contracts and decisions moved before any schema or backend (Phase 0).
- Security and secrets (Phase 2) after schema (Phase 1), before backend logic (Phase 3).
- Flutter and Admin UI (Phase 4) after backend (Phase 3); QA and docs (Phase 5) last.

### 5) Expanded steps

- “Unify flows” → concrete: choose one create edge and one webhook; migrate booking/direct_offer to that create; webhook steps as ordered list (insert event → lookup → idempotency → amount → HMAC → transaction).
- “RLS” → explicit policies and optional trigger; RLS matrix and T-RLS-1, T-RLS-2.
- “Acceptance” → invariants table and verification queries/tests.
- “Rollback” → edge revert, app backward compatible, recovery path.

### 6) Why (short, practical)

- Decisions first avoid rework and duplicate code paths.
- payment_events first in webhook guarantees audit even when intent is missing or validation fails.
- Explicit RLS prevents accidental write access.
- Test infra and gates prevent “works on my machine” and flaky releases.
- Gate checks force a passing condition before the next phase.

### 7) Residual risks

- Gateway metadata stripping (intent_id/signature) can still cause orphan spike; mitigation is gateway_intent_id lookup and Admin manual triage.
- Tender flow not in scope; if later extended, same pattern (intent before gateway, webhook with payment_events + HMAC + ledger link) must apply.
- Admin “Refund” action depends on existing refund RPC and permissions; may be out of scope for first release (Mark investigated only).

---

## Mandatory Critique Checklist (Summary)

| Section | Status | Failures found |
|---------|--------|----------------|
| 3.1 Scope & Requirements | ✅ Goal measurable; non-goals stated; edge/abuse in test plan | None |
| 3.2 Dependencies & Ordering | ❌ | Contracts and decisions must come before schema/backend; ordering fixed in Corrected Plan |
| 3.3 Data Model & Contracts | ❌ | Contract file and meta shape not fixed; intent_id nullability undecided; fixed in Phase 0 and G |
| 3.4 Security (RLS + AuthZ) | ❌ | RLS not explicit for payment_events; fixed in G5 and Phase 1/2 |
| 3.5 Performance & Scalability | ✅ | Indexes present; Realtime by id (single row); no N+1 in plan |
| 3.6 Error Handling & Observability | ⚠️ | Correlation (intent_id, gateway_intent_id) and logging rules added in G and Phase 2 |
| 3.7 UX & State Machine | ✅ | Loading/empty/error and Realtime; idempotency in webhook; fallback when no intent_id |
| 3.8 Testing & QA | ❌ | Test infra gate and fixture contract missing; T-SEC/T-ROB/T-RLS referenced but infra not; fixed in Gate 0 and G7 |
| 3.9 Release & Migration | ⚠️ | Rollback present; feature flag optional; rollout order (edge first) added |
| 3.10 Developer Workflow | ❌ | Branch strategy and PR DoD not in original plan; DoD added in Phase 5 |

---

**End of Plan Critic.**

Use this document as the execution-ready plan. Original plan remains in `.TODO/PLAN_HardenedPaymentLinking_2026-03-08.md` for reference.
