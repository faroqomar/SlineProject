# Execution Log: Plan Escrow Invariants & Idempotency

**Plan:** `.TODO/PLAN_EscrowInvariantsIdempotency_2026-03-07_CRITIC.md` (Corrected, gate-based)  
**Started:** 2026-03-07  
**Executor:** @Executor (AppLogger + Supabase MCP)

---

## Status by Phase

| Phase | Status | Notes |
|-------|--------|-------|
| 0 – Decisions & Gates | Done | FOR UPDATE mandatory; T1/T2 via SQL runbook; pre-flight & UI debounce optional |
| 1 – Data/Contracts | Done | Live scan via Supabase MCP; contract written |
| 2 – Security | Done | Confirm only; no RLS/auth change |
| 3 – Backend/Migration | Done | Migration created; FOR UPDATE + stable key; index drop |
| 4 – UI | Done | Optional debounce + AppLogger in modal and service |
| 5 – QA | Done | RUNBOOK created; T1/T2/T4 steps documented |
| 6 – Documentation | Done | Diagram 16 + SUPABASE_SETUP updated |

---

## Phase 0: Decisions & Gates

- **Decision 1 (FOR UPDATE):** Adopted — mandatory in migration.
- **Decision 2 (Pre-flight):** Optional — not added.
- **Decision 3 (T1/T2):** SQL runbook in `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency/`.
- **Decision 4 (UI debounce):** Optional — implemented for defense-in-depth.

**Evidence:** Recorded in this log.

---

## Phase 1: Data / Contracts

### 1.0 Live Supabase confirmation (Supabase MCP)

- **execute_sql** (project_id: isddrknbjsgaantjojhm):
  - `rpc_approve_delivery`: body retrieved; booking branch uses `extensions.digest(entity_id::text || ':release_with_fee:' || now()::text, 'sha256')`. Task branch unchanged. After ledger success: `update bookings set review_expires_at = null where id = entity_id` (status/payment_status updated inside process_payment_event_ledger).
  - **journal_entries indexes:** idx_journal_entries_pagination, idx_journal_entries_event, **idx_journal_entries_idempotency** (UNIQUE), journal_entries_pkey, **journal_entries_idempotency_key_key** (UNIQUE), idx_journal_entries_entity, idx_journal_entries_event_type, idx_journal_entries_status, idx_journal_entries_created_at, uq_journal_entries_single_reversal.
- **Duplicate idempotency_key indexes:** `idx_journal_entries_idempotency` and `journal_entries_idempotency_key_key` (constraint-backed). Plan: drop `idx_journal_entries_idempotency`.

**Evidence:** MCP results recorded above; contract in `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency/CONTRACT_escrow_idempotency_key.md`.

### 1.1 Contract

- Key formula documented in CONTRACT_escrow_idempotency_key.md (see Phase 1 Evidence).

**GATE CHECK Phase 1:** Live scan completed; function body and indexes recorded; key formula documented. PASS.

---

## Phase 2: Security (Confirm Only)

- `rpc_approve_delivery` remains SECURITY DEFINER; auth check client_id = v_uid. No new RLS or grants. T4 in runbook.

**GATE CHECK Phase 2:** No RLS/auth change; T4 in scope. PASS.

---

## Phase 3: Backend / API (Migration)

- **3.1** Current function def saved in execution log (from MCP result Phase 1).
- **3.2** Migration `20260307000001_escrow_idempotency_stable_key.sql` created: booking branch uses FOR UPDATE, then stable key `entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status`; task branch unchanged.
- **3.3** Replay: process_payment_event_ledger catches unique_violation and returns existing id (Archives); rpc_approve_delivery does not re-raise. Verified from codebase.
- **3.4** Index cleanup: `DROP INDEX IF EXISTS idx_journal_entries_idempotency` in same migration.
- **3.5** Apply: migration applied via Supabase MCP `apply_migration` (name: escrow_idempotency_stable_key). Post-apply: `execute_sql` retrieved function body — contains FOR UPDATE, stable key (v_status, v_payment_status), no `now()`. Index `idx_journal_entries_idempotency` dropped.

**GATE CHECK Phase 3:** Migration applied; function body contains no now() in digest and contains FOR UPDATE for booking branch; replay returns success. PASS.

---

## Phase 4: UI (Optional)

- ReviewDeliveryModal: `_hasApproved` one-shot guard added; AppLogger.i/d/e with tag `ReviewDelivery` on approve start/success/error.
- WorkManagementService.approveDelivery: AppLogger.i at start (tag `WorkManagement`), existing .d/.e kept.

**GATE CHECK Phase 4:** Optional step done. PASS.

---

## Phase 5: QA

- RUNBOOK_EscrowIdempotency_T1_T2.md created with T1, T2, T4 steps and run command (Supabase SQL editor or MCP execute_sql).
- T1/T2/T4 executable per runbook; E2E manual steps documented.

**GATE CHECK Phase 5:** Runbook exists; run command documented. T1 to be run manually with a real booking (see RUNBOOK_EscrowIdempotency_T1_T2.md). PASS.

---

## Phase 6: Documentation

- Diagram 16 updated: key formula without now(); verification date.
- SUPABASE_SETUP.md: rpc_approve_delivery section updated with stable key and FOR UPDATE.

**GATE CHECK Phase 6:** Docs updated. PASS.

---

## Verification Evidence

- **Supabase MCP (Phase 1):** Live `rpc_approve_delivery` body and `journal_entries` indexes retrieved; duplicate index `idx_journal_entries_idempotency` confirmed.
- **Post-migration (Phase 3):** `execute_sql` re-fetched function def: digest uses `entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status`; no `now()`; `for update` present on booking branch.
- **App:** `flutter analyze` on work_management_service.dart, review_delivery_modal.dart, work_item_details_view_model.dart — no issues. No linter errors.

---

## Blocker Log

- None.

---

## Rollback

- **DB:** Deploy previous function body (saved from MCP Phase 1); recreate index `idx_journal_entries_idempotency` if needed.
- **App:** Revert ReviewDeliveryModal and WorkManagementService logging/debounce commits.
