# Docs Sync — 2026-03-01 — Orders Dashboard Decommission

## Updated Docs

- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
- `Sline_everything/STRUCTURE.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/Sline_Log.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/CODE_REVIEW.md`
- `.TODO/CodexRefactor/01_FEATURES_INDEX.md`
- `.TODO/CONTRACT_Orders_Runtime_2026-03-01.md`
- `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`

## Summary

- Removed the old standalone `orders` runtime from `lib/features/orders/*.dart`.
- Documented that the live bottom-nav dashboard entry is `lib/features/dashboard/view/dashboard_screen.dart`.
- Preserved `lib/features/orders/README.md` as a tombstone note so the retired folder has an explicit owner/replacement trail.
- Clarified that `NavView.orders` is a legacy enum name, not a live standalone feature contract.
- Stamped stale `.TODO` orders audit/plan/review/pipeline artifacts as `Historical Status: Superseded` so they cannot be mistaken for the current contract.

## Why Each Update Was Needed

- `Sline_everything/DEVELOPER_GUIDE.md`: the consolidated guide still described `OrdersDashboardScreen` and `OrdersViewModel` as live runtime code.
- `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`: the dedicated feature doc was fully stale after the runtime deletion.
- `Sline_everything/STRUCTURE.md`: the feature list still claimed `orders` was a live feature folder.
- `Sline_everything/MVP_ROADMAP.md`: the workspace note still counted `orders` as an implemented live surface.
- `Sline_everything/Sline_Log.md`: changelog needed an explicit decommission entry tied to exact file paths.
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`: the architecture history needed the live consolidation decision recorded explicitly.
- `Sline_everything/CODE_REVIEW.md`: this decommission exposed a reusable cleanup rule for orphaned feature/provider/doc surfaces after navigation consolidation.
- `.TODO/CodexRefactor/01_FEATURES_INDEX.md`: active feature inventory still listed `orders` as auditable runtime code.
- `.TODO/CONTRACT_Orders_Runtime_2026-03-01.md`: current contract note was incorrect and would mislead future fixes.
- `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`: created to log the missing artifact cross-links and current architecture/reference corrections required by `DocsKeeper.md`.

## Reference Validation

- Verified current live dashboard references:
  - `lib/app/main_navigation_screen.dart`
  - `lib/core/widgets/custom_bottom_nav_bar.dart`
  - `lib/features/dashboard/view/dashboard_screen.dart`
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
- Verified removed runtime references no longer exist under `lib/` or `test/`:
  - `OrdersDashboardScreen`
  - `OrdersViewModel`
  - `OrdersService`
  - `OrderOffersViewModel`

## Notes

- Historical `.TODO/` reports that discussed the retired module were intentionally left unchanged as dated snapshots.
- Those historical files now carry an explicit superseded banner at the top.
- The authoritative current contract is now the dashboard/work documentation plus the decommission note at `lib/features/orders/README.md`.
