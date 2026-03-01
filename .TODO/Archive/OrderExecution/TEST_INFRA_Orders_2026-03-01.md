> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# Orders Test Infrastructure — 2026-03-01

## Shared Baseline
- Widget tests use `test/test_support/pump_app.dart`.
- Integration preflight pattern reuses `integration_test/support/preflight.dart` and `integration_test/support/t61_t70_env.dart`.

## Orders Test Requirements
- Stable selectors/keys required for:
  - orders nav item target verification
  - orders tab controls
  - orders refresh action
  - orders empty/error states
  - offer action buttons
- Unit coverage required for:
  - task status codec
  - offer status codec
  - orders dashboard state
  - offer-sheet viewmodel state
- Widget coverage required for:
  - navigation to orders slot
  - orders state rendering
- Staging verification inputs required for manual/RLS validation:
  - one owner account
  - one freelancer account
  - one open owner task with one pending request
  - one non-owner task for negative checks

## Run Commands
- `flutter analyze`
- `flutter test test/unit/models/task_model_test.dart`
- `flutter test test/unit/models/task_request_model_test.dart`
- `flutter test test/unit/features/orders/orders_view_model_test.dart`
- `flutter test test/unit/features/orders/order_offers_view_model_test.dart`
- `flutter test test/widget/app/main_navigation_screen_test.dart`

## Failure Artifacts
- Capture failing command output in execution log.
- Use targeted `rg` checks for raw exception leakage and restored orders wiring.
