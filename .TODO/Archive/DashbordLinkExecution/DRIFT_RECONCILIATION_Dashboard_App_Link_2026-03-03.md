# Drift Reconciliation - Dashboard App Link (2026-03-03)

Reference baseline: `.TODO/Link the Dashbord/For_SlineApp.md`

## Reconciled in `supabase/migrations/`

- `20260310100000_dashboard_admin_approvals_and_pii_logs.sql`
  - adds/aligns `admin_users`, `admin_approvals`, `admin_pii_access_logs`
  - adds approval RPCs (`admin_request_approval`, `admin_approve_or_reject_approval`, `admin_adjust_wallet`)
- `20260310101000_dashboard_public_config_reports_disputes_bridge.sql`
  - adds/aligns `admin_update_system_config`
  - adds `get_public_system_config` (public-safe read bridge)
  - adds reports/disputes app RLS bridges
- `20260310102000_dashboard_core_user_controls_and_reports.sql`
  - adds/aligns profile moderation + force logout fields and RPCs
  - adds/aligns reports queue schema and triage/close RPCs

## App Integration Delivered

- Guard enforcement: `lib/core/services/account_guard_service.dart` + `lib/main.dart`
- Public system config runtime wiring:
  - `lib/core/services/system_config_service.dart`
  - `lib/core/providers/system_config_view_model.dart`
  - auth/app-shell consumption in `lib/features/auth/view/*` and `lib/app/main_navigation_screen.dart`
- Safety/report/dispute paths:
  - `lib/features/safety/*`
  - task/chat/profile/booking UI entry points

## Validation Notes

- `flutter analyze` (targeted changed files): pass
- Widget tests:
  - `test/widget/auth/login_screen_test.dart`: pass
  - `test/widget/chat/chat_screen_test.dart`: pass
  - `test/widget/app/main_navigation_screen_test.dart`: pass
