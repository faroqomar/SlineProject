# Legacy Orders Module

The standalone orders dashboard was removed on 2026-03-01.

- The bottom navigation dashboard slot now renders `lib/features/dashboard/view/dashboard_screen.dart`.
- The legacy navigation enum name `NavView.orders` is still in use for compatibility.
- Do not recreate new runtime code under `lib/features/orders/`.
- If client-specific task management returns, build it on the live `dashboard`, `work`, and `tasks` surfaces.
