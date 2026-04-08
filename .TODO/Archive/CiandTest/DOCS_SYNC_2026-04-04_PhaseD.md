# Docs Sync: Phase D Harden (2026-04-04)

## @SlineDocs Full Sync (2026-04-04)

This is the complete documentation sync for Phase D. All 7 core documents updated.

## Documents Updated

### `CLAUDE.md`
- Added: Sentry `--dart-define=SENTRY_DSN` and `SENTRY_ENV` to Build & Run
- Added: 28% coverage floor note to CI/CD section
- Added: Architecture guard Check 3 tightening note
- Added: `MIGRATION_REVIEW_CHECKLIST.md` reference to Supabase Backend section
- Added: `supabase/tests/` SQL tests reference

### `Sline_everything/STRUCTURE.md`
- Updated: Last Updated date to 2026-04-04 (Phase D)
- Added: `sentry_crash_reporting_service.dart` to core/services listing
- Added: `MIGRATION_REVIEW_CHECKLIST.md` to top-level listing
- Added: `supabase/tests/` directory with 3 SQL test files
- Added: 3 dashboard delegate test files
- Added: 2 ViewModel test files (submit_request, requests_filter)
- Added: Sentry service test file

### `.TODO/AUDIT_Quality_Architecture_2026-04-01.md`
- Marked: Phase D as DONE (all D1-D11 items with dates and details)
- Updated: Results summary with test count 706→774

### `docs/LOG/SESSION_PLAN_PhaseD_Harden_2026-04-03.md`
- Full session timeline through Phase 9
- All evidence, problems encountered, and agent improvement notes

## New Files Created in Phase D

### Source Code
- `lib/core/services/sentry_crash_reporting_service.dart` (72 lines)
- `lib/features/dashboard/viewmodels/dashboard_work_delegate.dart` (362 lines)
- `lib/features/dashboard/viewmodels/dashboard_inbox_delegate.dart` (297 lines)
- `lib/features/dashboard/viewmodels/dashboard_booking_delegate.dart` (172 lines)
- `lib/features/tasks/viewmodels/submit_request_view_model.dart` (261 lines)
- `lib/features/tasks/viewmodels/requests_filter_view_model.dart` (87 lines)
- `lib/features/tasks/models/expired_bid_filter.dart` (28 lines)
- `lib/features/tasks/view/widgets/requests/request_award_dialog.dart` (416 lines)

### Tests
- `test/unit/core/sentry_crash_reporting_service_test.dart` (10 tests)
- `test/unit/dashboard/dashboard_work_delegate_test.dart` (10 tests)
- `test/unit/dashboard/dashboard_inbox_delegate_test.dart` (8 tests)
- `test/unit/dashboard/dashboard_booking_delegate_test.dart` (11 tests)
- `test/unit/viewmodels/submit_request_view_model_test.dart` (15 tests)
- `test/unit/viewmodels/requests_filter_view_model_test.dart` (15 tests)

### SQL Tests
- `supabase/tests/accept_task_request_test.sql` (4 test cases)
- `supabase/tests/escrow_idempotency_test.sql` (5 test cases)
- `supabase/tests/role_switch_rate_limit_test.sql` (6 test cases)

### Documentation
- `MIGRATION_REVIEW_CHECKLIST.md`
- `.TODO/DOCS_SYNC_2026-04-04_PhaseD.md` (this file)

## Files Modified in Phase D

- `pubspec.yaml` — added `sentry_flutter: ^8.0.0`
- `lib/main.dart` — Sentry init wrapper + crash reporting in all error boundaries
- `lib/features/auth/viewmodels/auth_session_view_model.dart` — user identity on login/logout
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart` — rewritten with 3 delegates
- `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` — rewritten with scoped VM
- `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` — filter/award extracted
- `lib/features/notifications/viewmodels/notification_view_model.dart` — A6 fix (lazy client DI)
- `lib/features/saved/viewmodels/saved_tasks_view_model.dart` — A6 fix (client DI)
- `.github/workflows/ci.yml` — guard tightened + coverage floor
- `supabase/functions/_shared/bookin_payment.ts` — CORS tightened
- `supabase/functions/qicard_webhook_handler/index.ts` — paymentId validation

## @SlineDocs Full Sync Updates (2026-04-04)

### `Sline_everything/Sline_Log.md`
- Added: Complete Phase D version entry with all D1–D11 items, bug fixes, metrics, and references
- Updated: Last Updated date to 2026-04-04

### `Sline_everything/DEVELOPER_GUIDE.md`
- Added: §11 Observability section rewritten — Sentry integration, error boundary chain, PII sanitizer
- Added: §11.1 Delegate Decomposition Pattern — when to use, DI strategy, dispose safety, example
- Added: §11.2 Lazy Supabase Client Pattern — correct vs incorrect patterns with code examples
- Added: §11.3 Coverage & CI Gates — 28% floor, architecture guard, migration checklist

### `Sline_everything/CODE_REVIEW.md`
- Added: Lazy Supabase Client Resolution guardrail (Phase D)
- Added: Delegate Dispose Safety guardrail (Phase D)
- Added: God-File Decomposition Checklist (Phase D)
- Added: Defensive Collection Patterns guardrail (Phase D)
- Updated: Section header date to 2026-04-04

### `Sline_everything/SUPABASE_SETUP.md`
- Added: paymentId/intentId regex validation in webhook handler
- Added: Edge Function CORS Configuration section (ALLOWED_ORIGIN, finish URL trust, local dev)
- Added: SQL Assertion Tests section (3 test files, execution instructions)

### `Sline_everything/MVP_ROADMAP.md`
- Moved: Phase D from "Current Focus" to "Completed Phases" with ✅ status and full summary
- Added: §10 Current Focus with Phase E definition
- Updated: Section numbering (9 → Completed Phases, 10 → Current Focus)

### `Sline_everything/STRUCTURE.md`
- Added: `expired_bid_filter.dart` in tasks/models listing
- Added: `submit_request_view_model.dart` in tasks/viewmodels listing
- Added: `requests_filter_view_model.dart` in tasks/viewmodels listing
- Added: `request_award_dialog.dart` in tasks/view/widgets/requests listing

### Agent Files Updated (System Evolution v3)
- `.cursor/Agents/Architect.md` — Added §4.7 Lazy Supabase Client Resolution
- `.cursor/Agents/Executor.md` — Added §3.4 Native Dependency Build Gate, §3.5 Per-Sub-Phase Test Gate, §3.6 CI Guard Exclusion Review
- `.cursor/Agents/Sline_Planner.md` — Added §1.2 Decomposition Line-Count Feasibility
- `.cursor/Agents/orchestrator.md` — Added §2.1 Parallel Review Mode

## References Validated
- All Flutter file paths verified against `lib/` directory
- All Supabase function paths verified against `supabase/functions/` directory
- All test file paths verified against `test/` directory
- All .TODO plan/session log paths verified
- MIGRATION_REVIEW_CHECKLIST.md exists at project root
- supabase/tests/ directory exists with 3 SQL test files
- `test/helpers/mock_services.dart` — added MockTaskRequestsService
