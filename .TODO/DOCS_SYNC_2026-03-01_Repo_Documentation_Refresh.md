# Docs Sync - Repo Documentation Refresh

**Date:** 2026-03-01

## Updated Documents

- `Sline_everything/STRUCTURE.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/DEVELOPER_GUIDE/Core Module.md`
- `Sline_everything/DEVELOPER_GUIDE/Auth Feature.md`
- `Sline_everything/DEVELOPER_GUIDE/Booking Feature.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/CODE_REVIEW.md`
- `Sline_everything/COMPREHENSIVE_ANALYSIS_SUMMARY.md`

## Why These Updates Were Needed

- `STRUCTURE.md` still documented the old `presentation/` and `controllers/` folder pattern.
- `DEVELOPER_GUIDE.md` and the embedded core/auth/booking sections still referenced deleted files and removed booking slot screens.
- `Core Module.md` did not document `payment_runtime_config.dart`, `payment_pending_store.dart`, `flutter_error_filters.dart`, or the `LoadingHandle` overlay pattern.
- `Auth Feature.md` still described a deleted `auth_service.dart` layer.
- `Booking Feature.md` still documented slot creation and `booking_sheet.dart` instead of the live server-backed checkout and recovery flow.
- `MVP_ROADMAP.md` had multiple duplicated historical versions in one file and no clear current-state module matrix.
- analysis/review docs needed explicit historical banners so older findings stop being mistaken for the live structure.

## Code / DB Reality Used For Sync

- Flutter structure under `lib/`
- edge functions and migrations under `supabase/`
- active planning and execution artifacts under `.TODO/`
- current booking/payment runtime:
  - `lib/features/booking/view/payment_checkout_screen.dart`
  - `lib/features/booking/view/payment_return_screen.dart`
  - `lib/features/booking/view/payment_webview_screen.dart`
  - `lib/core/config/payment_runtime_config.dart`
  - `lib/core/services/payment_pending_store.dart`
  - `lib/core/utils/loading_utils.dart`
  - `lib/features/auth/data/auth_repository.dart`
  - `supabase/functions/qicard_payment_create/index.ts`
  - `supabase/functions/qicard_payment_recovery/index.ts`

## Reference Validation

Validated against refreshed docs:
- `lib/...` paths
- `supabase/...` paths
- `.TODO/...` references introduced by this sync
- `Sline_everything/...` internal document references

Validation result:
- no missing file paths found in the refreshed doc set

## Notes

- `Sline_everything/Sline_Log.md`, `Sline_everything/CODE_REVIEW.md`, and `Sline_everything/COMPREHENSIVE_ANALYSIS_SUMMARY.md` retain historical content intentionally; only live-reference confusion was corrected.
- historical change logs that mention removed files remain as history, not live structure guidance.
