# Architect Report: home

## Scope
- Scope: `home` discovery/feed hardening, completion, and non-regression.
- Repo scope reviewed:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart:21-260`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:30-238`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart:6-27`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart:5-299`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:46-69`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:400-480`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart:6-82`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/viewmodels/profile_view_model.dart:63-125`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/discovery_task_sliver.dart:9-156`
- Live contract reviewed through Supabase after migration deployment on 2026-03-01.

## Architecture Status
- PASS.
- No MVVM boundary blocker remains in the reviewed Home discovery flow.

## Evidence Collected
- Global feed and saved-task providers remain app-level and singular in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:135-152`.
- Home/Tenders/Bookings now depend on a shared feed contract instead of screen-local data owners:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart:6-27`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart:42-49`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/tenders_screen.dart:23-31`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/view/bookings_discovery_screen.dart:25-33`
- Shared discovery rendering is consolidated in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/discovery_task_sliver.dart:9-156`.
- Cross-user profile enrichment is isolated behind a service boundary in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart:13-52` and consumed by `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:46-68`.
- Home header uses a summary-only path in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/viewmodels/profile_view_model.dart:66-93`.

## Boundary Checks
- PASS: reviewed views do not call Supabase directly.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart:42-49`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/tenders_screen.dart:23-31`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/view/bookings_discovery_screen.dart:25-33`
- PASS: profile summary reads are routed through an RPC-backed service, not direct cross-user `profiles` queries.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart:21-33`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:457-462`
- PASS: Home no longer creates a duplicate `SavedTasksViewModel`; refresh reads the global provider from context.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart:68-79`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:145-148`
- PASS: list/pagination behavior is shared rather than duplicated.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart:238-260`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/tenders_screen.dart:78-101`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/view/bookings_discovery_screen.dart:80-104`

## Design Notes
- `HomeViewModel` still owns the discovery feed state, but it now publishes a neutral contract consumed by Home/Tenders/Bookings in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:30-31` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart:6-27`.
- This is acceptable for the current release because the feature dependency direction is now through `tasks/viewmodels/discovery_feed_view_model_contract.dart`, not through direct `home/*` implementation details.

## Remaining Non-Blockers
1. LOW: discovery feed ownership is still implemented by `HomeViewModel` rather than a neutral `DiscoveryFeedViewModel` concrete class.
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:30-31`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart:6-27`
- Why it is not blocking: the contract boundary is already in place and consumers are decoupled from `HomeScreen` internals.
- Follow-up only if discovery scope expands further.

2. LOW: advanced filters remain loaded-window filters, not full-corpus query filters.
- Evidence:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart:119-299`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart:177-207`
- Why it is not blocking: this matches the locked contract in the Home plan and docs.

## Path Validation
- Present:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/discovery_task_sliver.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart`
- Absent by design:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/widgets/service_card.dart`

## Decision
- PASS.
- Architecture gate is clear for `home` in the current repo state and live DB state.
