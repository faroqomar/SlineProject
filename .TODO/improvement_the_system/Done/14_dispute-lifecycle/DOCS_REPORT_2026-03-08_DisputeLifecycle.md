# Docs Report: Dispute Lifecycle (2026-03-08)

**Scope:** Dispute Lifecycle — escrow guard, RLS, dispute enum, UI dispute guards, vw_unified_work_items disputed check.  
**Plan:** `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`  
**Execution:** `.TODO/EXECUTION_LOG_DisputeLifecycle_2026-03-08.md`  
**Author:** @SlineDocs (Orchestrator pipeline)

---

## 1. Documentation delta list

What changed in this scope and which docs must reflect it:

| Doc / area | What changed (Dispute Lifecycle) |
|------------|----------------------------------|
| **SUPABASE_SETUP** | Escrow guard in `rpc_approve_delivery` (task, booking, direct_offer) and `rpc_finalize_auto_approval` (task, booking); explicit deny UPDATE/DELETE on `disputes`; RLS on `dispute_messages` and `dispute_evidence` (participant-only); indexes on `disputes(task_id)`, `(direct_offer_id)`, `(status)`; **second migration** `20260308150000`: `dispute_status_enum` ('open','active','resolved','canceled'), trigger `trg_dispute_guard` (transition guard), trigger `trg_dispute_set_resolved_at` (set `resolved_at` when status → resolved); view `vw_unified_work_items` recreated with enum-safe disputed check (`d.status IN ('open','active')`). |
| **DEVELOPER_GUIDE** | Dispute lifecycle: escrow never released while dispute open/active; single source for “has dispute” — (1) dashboard/CTA from `vw_unified_work_items.unified_status = 'disputed'`, (2) Approve button guard from `SafetyViewModel.hasOpenDisputeForTask(booking.taskId)` / `hasOpenDisputeForBooking`; booking details `_ApproveWithDisputeGuard`; work item details dispute guard and disputed banner. |
| **STRUCTURE** | New test file `test/unit/safety/dispute_service_test.dart`; migrations `20260308140000_dispute_lifecycle_escrow_guard_rls.sql`, `20260308150000_dispute_enum_guard_resolved_at.sql`. |
| **MVP_ROADMAP** | Dispute lifecycle completion: escrow guard, RLS, enum/trigger/resolved_at, UI Approve disabled when disputed; optional dedicated row or expansion of “Booking dispute submission”. |
| **Sline_Log** | New versioned entry for Dispute Lifecycle (plan, execution log, migrations, app changes, verification refs). |
| **AppDigram/14_dispute-lifecycle.md** | Diagram and evidence are **outdated**: “NO enum”, “NO trigger”, “status is plain text” — now we have `dispute_status_enum`, `trg_dispute_guard`, `trg_dispute_set_resolved_at`, RLS deny and participant policies. |
| **.cursor/** | No dispute-specific references found that are broken; general refs to Sline_everything remain valid. |

---

## 2. Reference integrity scan

### 2.1 Broken or outdated references

| Location | Issue | Severity |
|----------|--------|----------|
| `Sline_everything/AppDigram/All_Diagrams/14_dispute-lifecycle.md` | States “NO enum found for dispute status”, “NO trigger found on disputes table”, “status is plain text”, “Is dispute_status_enum defined anywhere? Not found”. All false after migration `20260308150000`. | **High** |
| `Sline_everything/SUPABASE_SETUP.md` §5.24 | `disputes.status` described as `text`; actual type is `dispute_status_enum` after 20260308150000. RLS section does not list `disputes_deny_update`, `disputes_deny_delete`. | **High** |
| `Sline_everything/SUPABASE_SETUP.md` §5.25, §5.26 | No RLS policy names or behavior for `dispute_messages` and `dispute_evidence` (participant-only SELECT/INSERT). | **Medium** |
| `Sline_everything/SUPABASE_SETUP.md` §6.4 | View definition references only `20260308110000_upgrade_unified_work_view.sql` and rollback `20260308100000`. Current view is recreated in `20260308150000_dispute_enum_guard_resolved_at.sql` with enum-safe disputed check. Rollback path differs (enum migration). | **Medium** |
| `Sline_everything/SUPABASE_SETUP.md` §1 Enums table | `dispute_status_enum` not listed. | **Medium** |
| `Sline_everything/SUPABASE_SETUP.md` §17 Changelog | Entry for dispute lifecycle documents only `20260308140000`; missing `20260308150000` (enum, triggers, resolved_at, view recreate). | **Medium** |

### 2.2 Renamed / moved files

- None identified for this scope. `lib/features/safety/services/dispute_service.dart`, `safety_view_model.dart`, booking/work screens unchanged in path.

### 2.3 Outdated statements in Sline_everything/ and .cursor/

- **14_dispute-lifecycle.md**: Full evidence and “Open questions” section are outdated (enum, trigger, RLS, resolved_at).
- **SUPABASE_SETUP.md**: As in 2.1 (disputes type, RLS for dispute_messages/dispute_evidence, view migration ref, enums table, changelog).
- **DEVELOPER_GUIDE.md**: Dispute lifecycle and “single source for dispute state” are not explicitly described (escrow guard, dashboard vs detail-screen sources, Approve guard).
- **.cursor/**: No outdated dispute-specific statements found.

---

## 3. Required doc updates (bullet list)

- **Sline_everything/SUPABASE_SETUP.md**
  - §1 Quick Reference Enums: Add row for `dispute_status_enum` with values `'open', 'active', 'resolved', 'canceled'`.
  - §5.24 `disputes`: Change `status` type from `text` to `dispute_status_enum`; add RLS policies `disputes_deny_update`, `disputes_deny_delete` (FOR UPDATE/DELETE TO authenticated USING (false)); add note that status transitions are enforced by trigger `trg_dispute_guard` and `resolved_at` is set by `trg_dispute_set_resolved_at`; reference `.TODO/improvement_the_system/ImplementReady/14_dispute-lifecycle/RLS_CHECK_MATRIX.md`.
  - §5.25 `dispute_messages`: Document RLS enabled; policies `dispute_messages_select_participant`, `dispute_messages_insert_participant` (participant-only); migration `20260308140000_dispute_lifecycle_escrow_guard_rls.sql`.
  - §5.26 `dispute_evidence`: Document RLS enabled; policies `dispute_evidence_select_participant`, `dispute_evidence_insert_participant` (participant-only, INSERT also requires uploader_id = auth.uid()); migration same as above.
  - §6.4 `vw_unified_work_items`: Add that view is recreated in `20260308150000_dispute_enum_guard_resolved_at.sql` with enum-safe disputed check (`d.status IN ('open','active')`); mention dependency on `dispute_status_enum`; keep 20260308110000 as 4-branch + dispute override; note rollback for 20260308150000 is non-trivial (enum revert).
  - §17 Changelog: Add bullet for `20260308150000_dispute_enum_guard_resolved_at.sql`: dispute_status_enum; triggers trg_dispute_guard, trg_dispute_set_resolved_at; vw_unified_work_items recreated with enum-safe disputed check.

- **Sline_everything/DEVELOPER_GUIDE.md**
  - Dispute lifecycle / safety: Add subsection or bullets for (1) escrow guard — RPCs `rpc_approve_delivery` and `rpc_finalize_auto_approval` block when dispute open/active; (2) single source for “has dispute”: dashboard/CTA from `vw_unified_work_items.unified_status = 'disputed'`; Approve/Review button from `SafetyViewModel.hasOpenDisputeForTask` / `hasOpenDisputeForBooking`; (3) UI: booking details `_ApproveWithDisputeGuard`, work item details dispute guard and disputed banner from view status.
  - Reports and Disputes UX (§5.3): Mention `SafetyViewModel.hasOpenDisputeForTask` / `hasOpenDisputeForBooking` and dispute guard on Approve.

- **Sline_everything/STRUCTURE.md**
  - Test: Add `test/unit/safety/dispute_service_test.dart` under test layout.
  - Migrations (recent themes): Add dispute lifecycle: `20260308140000_dispute_lifecycle_escrow_guard_rls.sql`, `20260308150000_dispute_enum_guard_resolved_at.sql` (escrow guard, RLS, dispute_status_enum, triggers, view recreate).

- **Sline_everything/MVP_ROADMAP.md**
  - Either add row “Dispute lifecycle (escrow guard, RLS, UI)” with status ✅ and note (migrations 20260308140000, 20260308150000; SafetyViewModel hasOpenDispute; Approve disabled when disputed; vw_unified_work_items disputed), or expand “Booking dispute submission” row to include escrow guard, RLS, enum/trigger, UI guard.

- **Sline_everything/Sline_Log.md**
  - Add new entry (e.g. “Dispute Lifecycle — escrow guard, RLS, enum, UI (2026-03-08)”) with: plan, execution log, migrations, app changes (DisputeService.hasOpenDisputeForTask, SafetyViewModel, _ApproveWithDisputeGuard, test/unit/safety), verification refs (unit tests, RLS matrix), link to this DOCS_REPORT and PLAN/EXECUTION_LOG.

- **Sline_everything/AppDigram/All_Diagrams/14_dispute-lifecycle.md**
  - Update `sources.database` and body: status is `dispute_status_enum`; triggers `trg_dispute_guard` (transition guard), `trg_dispute_set_resolved_at` (resolved_at); RLS deny UPDATE/DELETE on disputes; RLS participant-only on dispute_messages and dispute_evidence.
  - Update evidence table: enum exists; triggers exist; open→active, active→resolved still admin-only but transitions enforced by trigger.
  - Update open questions: dispute_status_enum is defined; triggers enforce valid transitions and set resolved_at.
  - Bump `last_verified` to 2026-03-08.

---

## 4. Evidence: docs scanned and broken references

### 4.1 Docs scanned

- `Sline_everything/SUPABASE_SETUP.md` (§1, §5.24–5.26, §6.4, §9.4, §9.5, §17)
- `Sline_everything/DEVELOPER_GUIDE.md` (Work/Booking sections, Safety/Reports §5.3, RPC list, data flow)
- `Sline_everything/STRUCTURE.md` (top-level, lib/, test/, supabase/migrations)
- `Sline_everything/MVP_ROADMAP.md` (full)
- `Sline_everything/Sline_Log.md` (top entries)
- `Sline_everything/AppDigram/All_Diagrams/14_dispute-lifecycle.md` (full)
- `Sline_everything/AppDigram/All_Diagrams/12_unified-work-view.md`, `16_escrow-invariants-idempotency.md`, `09_ledger-event-flow.md`
- `Sline_everything/DEVELOPER_GUIDE/Booking Feature.md`, `Direct_Offers_Feature.md`, `Order_Management_Feature.md`
- `.TODO/PLAN_DisputeLifecycle_2026-03-08.md` (full)
- `.TODO/EXECUTION_LOG_DisputeLifecycle_2026-03-08.md` (full)
- `.TODO/improvement_the_system/ImplementReady/14_dispute-lifecycle/RLS_CHECK_MATRIX.md` (full)
- `supabase/migrations/20260308140000_dispute_lifecycle_escrow_guard_rls.sql` (full)
- `supabase/migrations/20260308150000_dispute_enum_guard_resolved_at.sql` (full)
- `.cursor/` — file list only (no deep dispute refs)

### 4.2 Broken references found (path and description)

| Path | Description |
|------|-------------|
| `Sline_everything/AppDigram/All_Diagrams/14_dispute-lifecycle.md` lines 13–14, 70–71, 76–78 | “NO enum”, “NO trigger”, “status is plain text”, “Is dispute_status_enum defined anywhere? Not found” — all invalid after 20260308150000. |
| `Sline_everything/SUPABASE_SETUP.md` §5.24 line 868 | `status` type `text` — should be `dispute_status_enum`. |
| `Sline_everything/SUPABASE_SETUP.md` §5.24 | RLS list missing `disputes_deny_update`, `disputes_deny_delete`. |
| `Sline_everything/SUPABASE_SETUP.md` §5.25, §5.26 | No RLS policy documentation. |
| `Sline_everything/SUPABASE_SETUP.md` §6.4 lines 1087–1088 | View definition and rollback reference only 20260308110000 / 20260308100000; current view from 20260308150000. |
| `Sline_everything/SUPABASE_SETUP.md` §1 Enums table | Missing `dispute_status_enum`. |
| `Sline_everything/SUPABASE_SETUP.md` §17 (2463) | Changelog has only 20260308140000; missing 20260308150000. |

---

## 5. Summary

- **Documentation deltas:** Six doc areas need updates (SUPABASE_SETUP, DEVELOPER_GUIDE, STRUCTURE, MVP_ROADMAP, Sline_Log, diagram 14). Changes cover dispute lifecycle behavior, dispute_status_enum, new RPC guards, RLS, and vw_unified_work_items disputed check.
- **Reference integrity:** One diagram (14) and several SUPABASE_SETUP sections contain broken or outdated references; DEVELOPER_GUIDE lacks an explicit dispute-lifecycle and single-source description.
- **Required updates:** Listed in §3 with file path and section/topic per item.
- **Evidence:** §4 lists all scanned docs and each broken reference with path and short description.

Implementing the bullets in §3 will bring docs in line with the Dispute Lifecycle implementation and preserve reference integrity.
