# CodeGuard Review Report: home

## Scope
- Change type: HIGH.
- Areas reviewed: UI, MVVM, filters, pagination, RPC boundary, RLS, docs, targeted tests.
- Files reviewed:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/viewmodels/profile_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_add_profiles_seller_level.sql`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_create_rpc_get_profile_summaries.sql`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_fix_search_profiles_safe_summary.sql`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_add_tasks_status_created_id_index.sql`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_harden_home_related_read_policies.sql`

## Verification Evidence
### Static and automated checks
- `flutter analyze`
  - Result: PASS
- `flutter test test/unit/home/home_view_model_test.dart`
  - Result: PASS
- `flutter test test/unit/tasks/task_filter_view_model_test.dart`
  - Result: PASS
- `flutter test test/unit/profile/profile_view_model_test.dart`
  - Result: PASS
- `flutter test test/widget/home/home_screen_test.dart`
  - Result: PASS
- `flutter test test/widget/home/filters_modal_test.dart`
  - Result: PASS
- `flutter test test/widget/tasks/tenders_screen_test.dart`
  - Result: PASS
- `flutter test test/widget/booking/bookings_discovery_screen_test.dart`
  - Result: PASS
- `rg -n "ChangeNotifierProvider\\(create: .*SavedTasksViewModel" lib`
  - Result: no matches
- `rg -n "from\\('profiles'\\)|from\\(\"profiles\"\\)" lib`
  - Result: remaining direct `profiles` reads are limited to self-scoped or unrelated feature-local flows, not Home cross-user enrichment.

### Live Supabase verification on 2026-03-01
- Applied migrations present in live project:
  - `home_add_profiles_seller_level`
  - `home_create_rpc_get_profile_summaries`
  - `home_fix_search_profiles_safe_summary_v2`
  - `home_add_tasks_status_created_id_index_retry`
  - `home_harden_home_related_read_policies`
  - `home_fix_profile_summary_function_grants`
- Verified live contract state:
  - `public.profiles.seller_level` exists and is non-null with default from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_add_profiles_seller_level.sql:21-69`
  - `public.rpc_get_profile_summaries(uuid[])` exists with auth guard and safe columns only from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`
  - `public.search_profiles(text, text, integer, integer)` exists with safe summary return type from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:3-61`
  - `idx_tasks_status_created_id` exists from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_add_tasks_status_created_id_index.sql:1-5`
  - `public.tasks` `SELECT` policy is only `tasks_select_authenticated_open_or_involved` from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_harden_home_related_read_policies.sql:10-21`
  - `public.profiles` `SELECT` policy is only `profiles_select_self` from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`
  - `public.saved_tasks` remains owner-only with `saved_tasks_select_own`, `saved_tasks_insert_own`, `saved_tasks_delete_own`
  - function execute privileges verified:
    - `anon_rpc = false`
    - `auth_rpc = true`
    - `anon_search = false`
    - `auth_search = true`

## Findings
### Resolved blockers
1. RESOLVED: app/DB contract mismatch.
- Fixed by deploying:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_add_profiles_seller_level.sql:21-69`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:3-61`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_add_tasks_status_created_id_index.sql:1-5`
- App-side consumption is live in:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart:21-33`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:422-462`

2. RESOLVED: permissive Home-related live RLS.
- Fixed by deploying `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_harden_home_related_read_policies.sql:3-31`.
- Outcome: Home feed is authenticated-only at the DB layer, and base `profiles` direct reads are self-only.

3. RESOLVED: no-op advanced filters and unstable pagination.
- Fixed in:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart:155-299`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:422-462`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:66-207`
- Covered by:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/home/home_view_model_test.dart:41-168`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`

4. RESOLVED: duplicate Home-scoped saved state and duplicated list behavior.
- Fixed in:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart:68-79`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/discovery_task_sliver.dart:9-156`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/tenders_screen.dart:42-101`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/view/bookings_discovery_screen.dart:44-104`
- Covered by:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart:79-152`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/tasks/tenders_screen_test.dart:45-96`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/booking/bookings_discovery_screen_test.dart:45-96`

### Residual warnings
1. LOW: dependency lag remains in the wider repo.
- Evidence source: prior `flutter pub outdated` run in this workspace.
- Why it is not a Home blocker: no dependency upgrade was required to complete the Home feed hardening safely; upgrading Supabase/auth/deep-link packages should stay a separate change set.

2. LOW: the worktree still contains unrelated formatting drift from a previous repo-wide `dart format` invocation.
- Why it is not a Home correctness blocker: the Home feature checks and tests passed; unrelated touched files were not reverted to avoid destructive changes against user work.

## Passed Checks
- ✅ MVVM boundary is clean for Home/Tenders/Bookings.
- ✅ Live DB contract now matches the app contract.
- ✅ Home feed is authenticated-only at the DB layer.
- ✅ Cross-user profile summaries are limited to safe RPC payloads.
- ✅ Saved tasks stayed owner-only.
- ✅ Composite cursor pagination is implemented and indexed.
- ✅ Advanced filters are implemented and tested.
- ✅ Shared discovery sliver and global bookmark state are in place.
- ✅ Documentation is synced to the current Home implementation.

## Final Decision
- PASS.
- CodeGuard gate is clear for the `home` feature.
