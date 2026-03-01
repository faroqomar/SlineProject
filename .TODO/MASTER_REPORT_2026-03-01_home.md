# Master Report: home

## Outcome
- Home report findings are fixed for the current repo state and live Supabase state.
- Gate status:
  - Architecture: PASS
  - Observability: PASS
  - Docs: PASS
  - CodeGuard: PASS

## What Was Fixed
1. Security and data boundary
- Added seller-level schema and backfill in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_add_profiles_seller_level.sql:21-69`.
- Added authenticated-only safe summary RPC in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`.
- Replaced unsafe `search_profiles` return shape with safe summary columns in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:3-61`.
- Hardened Home-related RLS in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_harden_home_related_read_policies.sql:3-31`.

2. Feed correctness
- Stabilized pagination with `created_at DESC, id DESC` composite cursor in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:422-462` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:66-207`.
- Added matching feed index in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_add_tasks_status_created_id_index.sql:1-5`.

3. UI and shared state
- Removed Home-local saved-task state by using the app-level provider already defined in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:145-152` and consumed in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart:68-79`.
- Added shared discovery list behavior in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/discovery_task_sliver.dart:9-156`.
- Shared feed access now flows through `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart:6-27`.

4. Filters and header load
- Implemented delivery-time and seller-level filtering in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart:155-299`.
- Added summary-only Home header loading in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/viewmodels/profile_view_model.dart:66-93`.

5. Observability and docs
- Added feed/filter/RPC telemetry in:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:82-220`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart:196-211`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart:34-49`
- Synced docs in:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md:53-67`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Home Feature.md:3-118`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/STRUCTURE.md:3-6`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/Sline_Log.md:24-65`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/MVP_ROADMAP.md:29-37`

## Verification Summary
### Local checks
- `flutter analyze`: PASS
- Targeted tests: PASS
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/home/home_view_model_test.dart:41-168`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/profile/profile_view_model_test.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart:104-153`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/filters_modal_test.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/tasks/tenders_screen_test.dart:45-96`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/booking/bookings_discovery_screen_test.dart:45-96`
- Duplicate Home saved-provider scan: PASS

### Live DB checks on 2026-03-01
- `public.profiles` direct reads are self-only.
- `public.tasks` Home reads are authenticated-only or involved-user-only.
- `public.saved_tasks` remains owner-only.
- `public.rpc_get_profile_summaries(uuid[])` is authenticated-only.
- `public.search_profiles(...)` is authenticated-only and returns safe summary columns only.
- `idx_tasks_status_created_id` exists.

## Reports
- `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/ARCHITECT_REPORT_2026-03-01_home.md`
- `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/OBSERVABILITY_REPORT_2026-03-01_home.md`
- `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/DOCS_REPORT_2026-03-01_home.md`
- `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/CODEGUARD_REVIEW_2026-03-01_home.md`

## Residual Non-Home Risks
1. Wider-repo dependency lag still exists and should be handled as a separate upgrade project.
2. The working tree still contains unrelated formatting drift from an earlier repo-wide formatting run; those changes were not reverted in this pass.
3. Supabase advisor warnings still exist for unrelated features and tables outside the Home scope.

## Final Status
- Home report remediation is complete.
- No Home-specific blocker remains in the current repo state or live Home DB contract.
