# Observability Report: home

## Scope
- Scope: `home` discovery/feed after the hardening, pagination, and filter completion work.
- Evidence reviewed:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:63-257`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart:85-211`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart:13-52`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/discovery_task_sliver.dart:89-156`

## Observability Status
- PASS.
- The release-blocking gaps identified in the previous report are closed.

## Implemented Telemetry
1. Feed lifecycle events are now structured.
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:82-88`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:112-121`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:123-134`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:169-207`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:209-220`
- Events present:
  - `home_feed_load_started`
  - `home_feed_load_succeeded`
  - `home_feed_load_failed`

2. Load-more skip behavior is now visible.
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:148-159`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/discovery_task_sliver.dart:131-147`
- Outcome: repeated sentinel-trigger confusion can now be separated from cursor exhaustion or concurrent load suppression.

3. Filter actions are now logged with safe aggregate fields only.
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart:85-116`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart:196-211`
- Events present:
  - `home_filters_applied`
  - `home_filters_reset`
- Safe fields only:
  - `search_present`
  - `category_present`
  - `budget_min_present`
  - `budget_max_present`
  - `delivery_bucket_count`
  - `seller_level_count`
  - `sort_by`
  - `result_count`

4. Query/RPC correlation is now present.
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:72-76`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:162-165`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:422-462`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart:13-16`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart:41-49`
- Outcome: one `feed_request_id` now ties together feed load intent, task query, and profile-summary RPC failure logging.

## Privacy / Logging Guardrails
- PASS: raw search text is not emitted by filter telemetry.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart:200-209`
- PASS: raw profile id arrays are not logged on RPC failure.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart:41-49`
- PASS: logs use counts / booleans / error type instead of raw profile or task content.

## Remaining Non-Blockers
1. LOW: no dedicated metric sink assertions exist in automated tests.
- Evidence:
  - current tests validate behavior, not emitted log payloads:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/home/home_view_model_test.dart:41-168`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`
- Why it is not blocking: runtime instrumentation is present, and current release coverage is focused on functional correctness.

## Decision
- PASS.
- Observability is sufficient for the Home release path now that feed, filter, and RPC correlation events are in place.
