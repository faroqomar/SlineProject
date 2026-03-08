# Execution Log: Work Contract Revisions (RPC Hardening)

**Plan:** `.TODO/PLAN_WorkContractRevisions_2025-03-08_PlanCritic.md`  
**Started:** 2025-03-08  
**Executor:** @Executor (AppLogger + Supabase MCP)

## Status by Phase

| Phase | Status | Notes |
|-------|--------|-------|
| 0 Preconditions | Done | Decisions locked; contract in plan + SUPABASE_SETUP |
| 1 Data/Backend | Done | 1.0 scan (columns present), 1.1 migration written, 1.2 applied via MCP |
| 2 Security | Done | No change; RPC same SECURITY DEFINER + client check |
| 3 App (MVVM + UI) | Done | ErrorMapper, ViewModel, service logging, modal + screen |
| 4 QA + Release | Done | error_mapper_test 7/7 passed; RPC body verified in live DB |
| 5 Documentation | Done | SUPABASE_SETUP §9.2 and §1 updated |

## Phase 0 — Preconditions & Decisions

- Acceptance criteria: RPC raises on non-delivered and on cap; UI shows mapped messages; client-only unchanged.
- Decision 1: Column existence confirmed in Phase 1.0 (Supabase MCP list_tables: tasks and bookings have revisions_used, revisions_total, status).
- Decision 2: Flutter test added in test/unit/core/error_mapper_test.dart (revision mapping group).
- Contract: Three exception messages documented in plan and in SUPABASE_SETUP §9.2.

**Evidence:** Plan §Contract + SUPABASE_SETUP §9.2 list: "Can only request revision on delivered work", "No revisions remaining", "Only client can request revision".

## Phase 1 — Data/Contracts & Backend

### 1.0 Live Supabase Confirmation

- [x] list_tables (verbose) for tasks, bookings — columns revisions_used, revisions_total, status present on both.
- [x] No prerequisite migration needed.
- [x] rpc_request_revision exists; after apply, prosrc verified via execute_sql (state + cap guards present).

**Evidence:** MCP list_tables result; execute_sql returned new function body with IF _status <> 'delivered' and IF _revisions_used >= _revisions_total.

### 1.1 Migration

- [x] Created `supabase/migrations/20260308120000_harden_rpc_request_revision.sql`. SELECT → client check → status check → cap check → UPDATE for task and booking.

### 1.2 Apply Migration

- [x] Applied via Supabase MCP apply_migration (name: harden_rpc_request_revision). success: true.

## Phase 3 — App Layer (MVVM + UI)

- [x] ErrorMapper: added three branches (Can only request revision…, No revisions remaining, Only client can request revision). `lib/core/utils/error_mapper.dart`.
- [x] ViewModel: `_error = ErrorMapper.map(e)` in requestRevision catch; `_error = null` at start; AppLogger.e with tag 'WorkItemDetails'. `lib/features/work/viewmodels/work_item_details_view_model.dart`.
- [x] Service: AppLogger.d on success (tag WorkManagement); AppLogger.e on catch with outcome (limit_reached / state_invalid / error). `lib/features/work/services/work_management_service.dart`.
- [x] ReviewDeliveryModal: canRequestRevision, getRevisionError; disable "Request Changes" when !canRequestRevision; show "No revisions left"; on reject failure show SnackBar(getRevisionError()). `lib/features/work/view/widgets/review_delivery_modal.dart`.
- [x] work_item_details_screen: pass canRequestRevision (revisionsUsed < revisionsTotal), getRevisionError: () => vm.error. `lib/features/work/view/work_item_details_screen.dart`.

## Phase 4 — QA + Release

- [x] ErrorMapper unit tests: added group "ErrorMapper work revision" with 3 tests (No revisions remaining, Can only request…, Only client…). `flutter test test/unit/core/error_mapper_test.dart` — 7/7 passed.
- [x] RPC body verified in live DB via execute_sql (prosrc contains state and cap guards).
- Manual E2E / RLS tests: to be run with logged-in client (documented in plan).

## Phase 5 — Documentation

- [x] SUPABASE_SETUP.md §9.2: Logic updated (state + cap guards); exception messages and migration path added.
- [x] SUPABASE_SETUP.md §1 Key Business Rules: "Revision requests enforce status and limit…" updated.

## Blockers

None.

## Observability

- AppLogger: WorkManagementService.requestRevision (success: tag WorkManagement, entityType/entityId/note_length; error: tag WorkManagement, outcome limit_reached|state_invalid|error). WorkItemDetailsViewModel.requestRevision (error: tag WorkItemDetails). ReviewDeliveryModal (existing approve/reject logs).

## Rollback

- DB: Re-apply function body from `supabase/migrations/20260305180100_work_revision_and_change_rpcs.sql` for `rpc_request_revision` (no guards).
- App: Revert ErrorMapper revision branches; ViewModel _error = ErrorMapper.map(e) → _error = 'Failed to request revision'; ReviewDeliveryModal canRequestRevision/getRevisionError and disable logic; work_item_details_screen modal args.

## Completion Summary

- Migration applied; RPC enforces status='delivered' and revisions_used < revisions_total.
- App shows mapped messages and disables "Request Changes" when no revisions left.
- Tests: 7/7 in error_mapper_test (including 3 revision mapping tests).
- Docs: SUPABASE_SETUP §9.2 and §1 updated.
