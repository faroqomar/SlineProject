# Orders Feature Reference (Decommissioned)

## Status

This standalone feature was decommissioned on 2026-03-01.

## Current Contract

- The live dashboard tab is `lib/features/dashboard/view/dashboard_screen.dart`.
- `lib/app/main_navigation_screen.dart` still uses the legacy enum slot `NavView.orders` for compatibility, but it does not load any Dart code from `lib/features/orders/`.
- `lib/features/orders/README.md` is the only remaining file in the old feature folder. It exists to document the removal and stop accidental reintroduction.

## Migration Guidance

- Do not add new runtime code under `lib/features/orders/`.
- If client-side published-task management is reintroduced, implement it under the live `dashboard`, `work`, and `tasks` architecture.
- Keep authorization and offer-decision rules documented under the live task/work contracts, not under this retired feature note.

## Verification

- `rg -n "features/orders/|OrdersDashboardScreen|OrdersViewModel|OrdersService" lib test integration_test`
- `flutter analyze`
