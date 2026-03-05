# Execution Log: Work Full Remediation

- **Plan**: `.TODO/Archive/WorkExectuion/PLAN_Work_Full_Remediation_2026-03-04.md`
- **Start**: 2026-03-05
- **Executor**: Agent (Executor-led)

## Phase status

| Phase | Status | Notes |
|-------|--------|-------|
| Pre-execution (context scan) | Done | Docs/code scanned; Supabase MCP used; project_id isddrknbjsgaantjojhm |
| Phase 0: Gates & contracts | Done | TEST_INFRA, SELECTORS, FIXTURES, FAILURE_ARTIFACTS, THREAT_MODEL, DECISION_work_chat_contract, CONTRACT_work_actions, IDEMPOTENCY_work, DB_PROVENANCE_work, STATE_MATRIX_work, PR_PLAN_work, RELEASE_CHECKLIST_work, SPEC_LOCK_work created |
| Phase 1: Data/contracts | Done | Shared UnifiedWorkItemFallbackMapper; work + dashboard use it; completed→completed; PII logging reduced; booking chat uses DM path |
| Phase 2: Security/RLS | Done | LIVE_ACCESS + RLS_MATRIX_work created; MCP list_tables confirmed work tables exist |
| Phase 3: Backend/API | Done | Booking chat fix (DM path for booking); chat/cancel/refresh moved into ViewModel; service split deferred |
| Phase 4: UI/integration | Done | Orchestration moved to ViewModel (openConversation, cancelAward, refreshDashboard); full screen split deferred |
| Phase 5: QA + release | Done | flutter analyze pass; unit + widget tests pass; grep checks documented |

## Pre-execution evidence

### Documentation scan
- Read: DEVELOPER_GUIDE (work section 1953–2024), SUPABASE_SETUP, STRUCTURE, CODE_REVIEW, MVP_ROADMAP references.
- Work feature is route-local; docs declare work_contracts, change_requests, extension_requests, RPCs.

### Codebase scan
- `lib/features/work/`: work_item_details_screen, work_item_details_view_model, work_management_service, unified_work_item_model, change_request_model, extension_request_model, work_contract_model, submit_delivery_modal, request_extension_modal, review_delivery_modal.
- Dependencies: dashboard (repository, viewmodel, work_tab, bookings_tab, work_item_card), booking_service, message_service, chat_view_model, profile_summary_service, task_service, tender_payment_coordinator, deep_link_service, payment_service, main.dart.

### Supabase object reality (MCP)
- **list_projects**: Success; project_id `isddrknbjsgaantjojhm`.
- **list_tables** (public, verbose): Live DB has `work_contracts` (RLS on, 32 rows), `change_requests` (RLS on, 0 rows), `extension_requests` (RLS on, 2 rows), `bookings`, `task_requests`.
- **Repo migrations**: `rg` for work_contracts|change_requests|extension_requests|rpc_request_revision|rpc_accept_change_request in supabase/migrations → **no matches**. So live has tables; repo has no migration source-of-truth for them.

### Evidence / Gaps / Risks / Observability
- **Evidence**: Work feature exists; test harnesses (pump_app, integration_test support) exist; AppLogger in use in work viewmodel and service; live DB has work tables.
- **Gaps**: Missing migrations for work_contracts, change_requests, extension_requests, rpc_request_revision, rpc_accept_change_request; no work-detail unit/widget tests; booking chat passes booking id to task RPC; direct booking cancel; widget-layer orchestration.
- **Risks**: DB/release blocked until provenance reconciled; PII at info level in viewmodel; duplicate fallback mapper; tender pay hold-before-DB inconsistency.
- **Observability**: Add/verify AppLogger on load path, mutations, chat path; remove info-level participant IDs (W-SEC-02).

## Blockers
- None currently.

## Per-step log

- **Phase 0**: Created TEST_INFRA, SELECTORS, FIXTURES, FAILURE_ARTIFACTS, THREAT_MODEL, DECISION_work_chat_contract, CONTRACT_work_actions, IDEMPOTENCY_work, DB_PROVENANCE_work, STATE_MATRIX_work, PR_PLAN_work, RELEASE_CHECKLIST_work, SPEC_LOCK_work, LIVE_ACCESS_work, RLS_MATRIX_work.
- **Phase 1**: Added `UnifiedWorkItemFallbackMapper`; WorkManagementService and dashboard use it; viewmodel uses mapper for booking fallback; completed→completed; PII logging reduced to debug; unit tests for mapper.
- **Phase 2**: LIVE_ACCESS and RLS_MATRIX created; MCP list_tables confirmed work_contracts, change_requests, extension_requests exist.
- **Phase 3**: Booking chat uses `taskId: item.isTask ? item.id : null`; MessageService logs task vs DM path; ViewModel has openConversation(), cancelAward(), refreshDashboard() with injected ChatViewModel/DashboardViewModel.
- **Phase 4**: Screen creates VM with ctx.read<ChatViewModel> and ctx.read<DashboardViewModel>; _handleMessage uses vm.openConversation(); pay/cancel use vm.refreshDashboard() and vm.cancelAward().
- **Phase 5**: `flutter analyze` pass; `flutter test test/unit/work/ test/unit/models/unified_work_item_model_test.dart test/widget/dashboard/work_tab_test.dart` pass. Grep: no booking id as taskId in work (taskId: item.isTask ? item.id : null only).
- **SQL (full plan)**: Added repo source-of-truth and applied via Supabase MCP: `20260305180000_work_contracts_change_extension_requests.sql` (work_contracts, change_requests, extension_requests + RLS), `20260305180100_work_revision_and_change_rpcs.sql` (rpc_request_revision, rpc_accept_change_request). DB_PROVENANCE_work updated.
