# 📌 Plan: Escrow Invariants & Idempotency (16_escrow-invariants-idempotency)

## 1) Goal

- **Goal:** Implement the improvements defined in the folder `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency` and the diagram `Sline_everything/AppDigram/All_Diagrams/16_escrow-invariants-idempotency.md` so that escrow release is correctly idempotent under retries and concurrency.
- **Why:** The current `rpc_approve_delivery` idempotency key uses `now()`, so each retry gets a different key and the UNIQUE constraint never prevents double release. System is currently safe only due to status gates and locking; the key should be a proper defense layer.
- **Result:** Stable idempotency key, optional FOR UPDATE/pre-flight hardening, index cleanup, optional UI debounce, docs and diagram updated; verification and tests in place.

## 2) Scope

### In-Scope

- `rpc_approve_delivery`: change idempotency key from `entity_id || ':release_with_fee:' || now()` to a stable digest (e.g. `entity_id || ':release_with_fee:' || v_status || ':' || v_payment_status`).
- Optional hardening: pre-flight check for existing `release_with_fee` journal entry; `SELECT ... FOR UPDATE` on entity row before ledger call (per 02_GAPS_AND_FIXES / 00_HOLISTIC_REPORT).
- Drop duplicate index on `journal_entries.idempotency_key` if present (keep only constraint-backed index).
- Optional: one-shot debounce in Approve Delivery UI (ReviewDeliveryModal or equivalent).
- Fee rate: document or fix `fee_rate_bps = 0` only after explicit business decision (see folder 07_MINIMAL_PATCH_PLAN).
- Verification: idempotent replay test, concurrency test; diagram and SUPABASE_SETUP.md aligned with implementation.
- All changes additive or function replacement; no table drops or breaking contract changes.

### Out-of-Scope

- `gateway_escrow` / QiCard path (different flow; doc 16 notes it explicitly).
- Changing `process_payment_event_ledger` signature or idempotency semantics (already correct).
- Backfilling or changing existing `journal_entries` rows (old keys remain valid).
- Client-supplied idempotency key (Option B from GAPS); we use server-side stable key only.

## 3) Evidence & Findings (From Scan)

### Existing

- **App:** `lib/features/work/services/work_management_service.dart` — `approveDelivery(entityId, entityType)` calls `_supabase.rpc('rpc_approve_delivery', params: {'entity_type': entityType, 'entity_id': entityId})`. No client idempotency key.
- **DB (from migrations):** `rpc_approve_delivery(entity_type, entity_id)` in `supabase/migrations/Archive/20260224_fix_rpc_approve_delivery_digest_schema.sql` — booking branch uses `extensions.digest(entity_id::text || ':release_with_fee:' || now()::text, 'sha256')` and `process_payment_event_ledger(..., p_meta := '{"fee_rate_bps": 0}'::jsonb)`. Task branch only updates status (no ledger).
- **DB:** `journal_entries.idempotency_key` has `uq_journal_entries_idempotency_key` (UNIQUE). `process_payment_event_ledger` checks `SELECT id FROM journal_entries WHERE idempotency_key = p_idempotency_key AND status = 'posted'` and returns existing on hit.
- **Docs:** `Sline_everything/AppDigram/All_Diagrams/16_escrow-invariants-idempotency.md` — status Implemented/Verified; diagram shows digest and idempotency check; evidence table and verification 2026-03-05.
- **Folder:** `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency/` — 00_HOLISTIC_REPORT, 02_GAPS_AND_FIXES, 04_TEST_PLAN, escrow_idempotency_proof/07_MINIMAL_PATCH_PLAN.md define patches and tests.

### Missing

- Live confirmation of current `rpc_approve_delivery` body and of `journal_entries` indexes (non-Archive migrations may have evolved). Plan assumes @Supabase_Ops will confirm via Supabase MCP or SQL.
- RLS test or integration test that asserts idempotent replay for `rpc_approve_delivery` (04_TEST_PLAN exists but may not be automated).

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- **Drift:** Diagram says "Implemented" but folder 00_HOLISTIC_REPORT scores current key 4/10 and recommends stable key. Treat diagram as intent; implementation plan fulfils that intent.
- **Risk:** Changing key formula is backward compatible (new keys differ from old; no migration of old rows needed). Retries after patch will see same key per entity/status and hit idempotency.
- **Risk:** If `v_status`/`v_payment_status` are read before `FOR UPDATE`, a race could in theory use stale values; minimal patch uses values already read in the same RPC (booking branch). FOR UPDATE in Phase 1 optional step serializes concurrent calls.
- **fee_rate_bps:** 07_MINIMAL_PATCH_PLAN marks as business decision; do not change in this plan until product confirms.

---

## 4) System Impact Map

- **UI:** Optional one-shot debounce on Approve button (prevents double-tap; backend remains authority).
- **MVVM/App Logic:** No change to WorkManagementService contract (still entity_id + entity_type); no new parameters.
- **Database:** One migration: `CREATE OR REPLACE FUNCTION rpc_approve_delivery` with stable key; optional `DROP INDEX idx_journal_entries_idempotency` if present.
- **RLS/Security:** No change to RLS; `rpc_approve_delivery` remains SECURITY DEFINER; authorization (client_id = auth.uid()) unchanged.
- **Realtime/Notifications:** None.
- **Storage:** None.
- **Observability:** Optional: admin_logs or logging for idempotent replay (per holistic report Phase 2); can be deferred.
- **Compatibility & Migration:** No app version constraint; no data backfill.
- **Contracts:** API contract unchanged (same RPC name and params); diagram and SUPABASE_SETUP.md updated to reflect new key formula.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance: (1) Second call to `rpc_approve_delivery` for same entity in releasable state returns without duplicate ledger lines; (2) Diagram and SUPABASE_SETUP reflect stable key formula. Non-regression: existing delivery approval E2E still passes.
- [ ] (@Architect) Confirm entry points: `WorkManagementService.approveDelivery` only; no other callers of `rpc_approve_delivery`.
- **Verify (@Sentinel):** Done-conditions and rollback (revert migration) documented.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Confirm: double-release and replay scenarios covered in 02_GAPS_AND_FIXES; negative checks in 04_TEST_PLAN (T4) and Phase 4.
- **Verify (@Sentinel):** Testable and included in Phase 4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) No payload change; RPC name and params unchanged. Optional: note in `.TODO/` or DEVELOPER_GUIDE that idempotency is server-side only.
- **Verify (@Sentinel):** N/A or contract note matches behavior.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) No schema reshape; function replacement only. Rollback: redeploy previous `rpc_approve_delivery` body from Archive if needed.
- **Verify (@Sentinel):** Rollback step recorded in Section 8.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) No feature flag required; change is correctness fix with backward-compatible key space.
- **Verify (@Sentinel):** Rollback path = revert migration.

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via `@mcp:supabase-mcp-server:` (or equivalent) for `rpc_approve_delivery` body, `journal_entries` (columns + indexes including `idempotency_key`), and `process_payment_event_ledger` idempotency branch.
- [ ] (@Supabase_Ops) Confirm no conflicting migration or duplicate index names; note exact current key expression (expect `now()` in digest).
- **Verify (@Sentinel):** Drift and safe approach recorded in execution log.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) No new tables/columns. Migration only: `CREATE OR REPLACE FUNCTION public.rpc_approve_delivery` with stable idempotency key: `entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status` (or equivalent immutable context; booking branch only; task branch unchanged).
- **Verify (@Sentinel):** No leaks/breaks; digest input has no `now()`.

### 1.2 RLS

- [ ] (@Supabase_Ops) No RLS change; `rpc_approve_delivery` remains SECURITY DEFINER with same auth checks.
- **Verify (@Sentinel):** N/A.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Optional: add `SELECT ... FROM tasks/bookings WHERE id = entity_id FOR UPDATE` at start of releasable branch to serialize concurrent calls (per 02_GAPS_AND_FIXES GAP 3). Optional: pre-flight check for existing `release_with_fee` journal entry for entity (GAP 2).
- [ ] (@Supabase_Ops) Ensure `process_payment_event_ledger` is still called with same semantics; unique_violation handler continues to return existing journal id.
- **Verify (@Sentinel):** State rules and idempotency behavior unchanged from caller perspective.

### 1.4 Index Cleanup

- [ ] (@Supabase_Ops) If live DB has both `uq_journal_entries_idempotency_key` (constraint) and `idx_journal_entries_idempotency` (or similar), add `DROP INDEX IF EXISTS idx_journal_entries_idempotency;` in same or follow-up migration.
- **Verify (@Sentinel):** Unique constraint on `idempotency_key` still present after drop.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) No model changes; RPC params unchanged.
- **Verify (@Sentinel):** Types unchanged.

### 2.2 Services/Repositories

- [ ] (@Architect) No change to `WorkManagementService.approveDelivery` signature or implementation unless adding optional error mapping for 409/unique_violation (if surfaced by Supabase client).
- **Verify (@Sentinel):** No direct Supabase in UI; service only.

### 2.3 ViewModels

- [ ] (@Architect) No ViewModel change required for idempotency; optional: ensure retry logic does not double-call on success (e.g. disable button on success).
- **Verify (@Sentinel):** Recoverable state on network error (retry safe).

### 2.4 Observability (If needed)

- [ ] (@Observability) Optional: log idempotent replay in backend or app (per holistic report); can be Phase 5 or later.
- **Verify (@Sentinel):** No PII in logs.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Optional: one-shot debounce in Approve Delivery flow (e.g. `_hasApproved` guard in modal or screen that calls `onApprove`). Allow retry on error (reset guard on catch).
- [ ] (@Pixel) Loading/disabled state already present; ensure no double submit from double-tap.
- **Verify (@Sentinel):** Stable UX on slow network; no duplicate RPC from single user intent.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Skip unless UX debt item.
- **Verify (@Sentinel):** N/A.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) RPC signature and behavior match SUPABASE_SETUP.md and diagram; migration applies cleanly on dev/staging.
- **Verify (@Sentinel):** No mismatch.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Run 04_TEST_PLAN T4 (bypass attempt: already completed entity); confirm RPC rejects or no-ops.
- [ ] (@Sentinel) Confirm RLS: only client can call; no cross-tenant release.
- **Verify (@Sentinel):** Unauthorized access impossible.

### 4.3 Functional QA

- [ ] (@Sentinel) Idempotent replay: call `rpc_approve_delivery` twice for same entity (e.g. booking in `delivered`/`held`); second call must not create extra journal_entries/ledger_lines (T1).
- [ ] (@Sentinel) Optional: concurrent call test (T2) or E2E retry (T3) per 04_TEST_PLAN.
- [ ] (@Sentinel) Manual E2E: approve delivery from app once; verify completed and balance correct; retry from UI and verify no double credit.
- **Verify (@Sentinel):** No crashes; idempotency verified.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) If replay logging added, verify no sensitive data.
- **Verify (@Sentinel):** Optional.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/AppDigram/All_Diagrams/16_escrow-invariants-idempotency.md`: key formula in diagram and evidence table (digest input without `now()`); verification date and result.
- [ ] (@SlineDocs) Update `Sline_everything/SUPABASE_SETUP.md` section for `rpc_approve_delivery`: document stable key formula and optional FOR UPDATE/pre-flight if implemented.
- [ ] (@SlineDocs) Optional: short note in DEVELOPER_GUIDE (Finance & Payment Ledger or Work Management) that escrow release is idempotent under retry.
- **Verify (@Sentinel):** Docs match code and live DB.

---

## 7) Acceptance Criteria (MANDATORY)

- Second `rpc_approve_delivery` call for the same entity (in releasable state) does not create additional `journal_entries` or `ledger_lines`; same idempotency_key used.
- Diagram 16 and SUPABASE_SETUP reflect the stable key generation (no `now()` in digest input).
- Existing E2E flow: client can approve delivery once and see status completed and correct wallet balance; retry after success does not change outcome.
- No new RLS or security regressions; only client can approve delivery for their entity.
- Optional: Approve button does not trigger duplicate RPC on double-tap (UI guard or backend idempotency sufficient).

---

## 8) Rollback Plan

- **DB:** Revert migration: deploy previous `rpc_approve_delivery` body (e.g. from `supabase/migrations/Archive/20260224_fix_rpc_approve_delivery_digest_schema.sql` or current live version saved before change). No data migration to undo.
- **App:** No app change required for idempotency key; if UI debounce was added, revert that commit.
- **Emergency:** If double-release observed (should not occur after patch), disable delivery approval via feature flag or revert RPC; investigate and re-deploy fixed function.

---

## 9) References (From Scan)

- `Sline_everything/DEVELOPER_GUIDE.md` — Work Management, Finance & Payment Ledger
- `Sline_everything/SUPABASE_SETUP.md` — RPC list, ledger, journal_entries
- `Sline_everything/AppDigram/All_Diagrams/16_escrow-invariants-idempotency.md` — diagram and evidence
- `Sline_everything/MVP_ROADMAP.md`, `STRUCTURE.md`, `ARCHITECTURE_ANALYSIS.md`, `CODE_REVIEW.md`
- `lib/features/work/services/work_management_service.dart` — approveDelivery
- `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency/00_HOLISTIC_REPORT.md`
- `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency/02_GAPS_AND_FIXES.md`
- `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency/04_TEST_PLAN.md`
- `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency/escrow_idempotency_proof/07_MINIMAL_PATCH_PLAN.md`
- `supabase/migrations/Archive/20260224_fix_rpc_approve_delivery_digest_schema.sql`
- Live Supabase scan (via @mcp:supabase-mcp-server or SQL) to be performed in Phase 1.0.
