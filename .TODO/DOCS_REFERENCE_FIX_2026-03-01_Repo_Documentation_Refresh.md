# Docs Reference Fix - Repo Documentation Refresh

**Date:** 2026-03-01

## Broken or Stale References Fixed

### Structure / Architecture
- Removed live documentation of `presentation/` and `controllers/` as the active feature layout.
- Replaced it with the current `view/`, `viewmodels/`, `services/`, `models/`, `data/` structure.

### Auth
- Removed live references to deleted file:
  - `lib/features/auth/services/auth_service.dart`
- Replaced auth data-layer documentation with:
  - `lib/features/auth/data/auth_repository.dart`
  - `lib/features/auth/viewmodels/auth_view_model.dart`

### Booking
- Removed live references to deleted booking UI files:
  - `lib/features/booking/view/availability_screen.dart`
  - `lib/features/booking/view/add_slot_sheet.dart`
  - `lib/features/booking/view/booking_sheet.dart`
- Replaced booking flow references with the current screens:
  - `lib/features/booking/view/payment_checkout_screen.dart`
  - `lib/features/booking/view/payment_return_screen.dart`
  - `lib/features/booking/view/payment_webview_screen.dart`
  - `lib/features/booking/view/bookings_list_screen.dart`
  - `lib/features/booking/view/booking_details_screen.dart`

### Core
- Replaced stale dialog-loading references with the current overlay-handle pattern:
  - `lib/core/utils/loading_utils.dart`
- Added missing core runtime docs for:
  - `lib/core/config/payment_runtime_config.dart`
  - `lib/core/services/payment_pending_store.dart`
  - `lib/core/utils/flutter_error_filters.dart`

### Historical Docs Clarified
- Added historical-context notices to:
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/COMPREHENSIVE_ANALYSIS_SUMMARY.md`

## Validation Method

Reference validation was run against the refreshed live-doc set by extracting path-like references and confirming they exist in the repository.

Result:
- no missing file paths remained in the refreshed live-doc set after fixes
