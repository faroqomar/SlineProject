# Docs Sync: Phase E Polish (2026-04-04)

## Documents Updated

### `CLAUDE.md`
- Added: `flutter gen-l10n` command to Build & Run section
- Updated: Architecture Guard from 6 to 7 checks, added Check 7 description (core cannot import features)
- Updated: Coverage floor from 28% to 33%, test count to 982 across 27 VM test files
- Added: Sealed ViewState pattern to Key architectural rules (ViewState<T> + AppFailure)
- Added: DeepLinkRegistry pattern to Key architectural rules (zero feature imports)
- Added: `very_good_analysis` linting rule to Conventions > Strict rules
- Updated: Error handling convention to recommend sealed ViewState<T> for new VMs

### `.TODO/AUDIT_Quality_Architecture_2026-04-01.md`
- Replaced: Phase E task list with detailed E1-E10 completion table (all DONE)
- Added: Phase E results summary (780 to 982 tests, 34.9% coverage, 33% floor, APK fixed)
- Updated: Section 4.2 very_good_analysis migration note marked DONE

## Phase E Metrics

| Metric | Before | After |
|--------|--------|-------|
| Tests | 780 | 982 (+202) |
| Coverage | 30.6% | 34.9% |
| Coverage floor | 28% | 33% |
| Lint ruleset | flutter_lints | very_good_analysis (~70+ rules) |
| Architecture guard checks | 6 | 7 |
| VMs tested | 16/27 | 27/27 |
| God files decomposed | 9 | 9 (5 logic + 4 views) |

## New Files Created in Phase E

### Infrastructure (lib/core/models/)
- `lib/core/models/app_failure.dart` -- AppFailure sealed class
- `lib/core/models/view_state.dart` -- ViewState<T> sealed class (loading | loaded | error)

### Extracted Delegates and Widgets
- `lib/core/services/payment_response_helpers.dart`
- `lib/features/booking/view/widgets/payment_order_summary_card.dart`
- `lib/features/booking/viewmodels/booking_payment_delegate.dart`
- `lib/features/tasks/services/task_offer_service.dart`
- `lib/features/tasks/services/task_request_error_mapper.dart`
- `lib/features/tasks/view/widgets/booking_logistics_section.dart`
- `lib/features/tasks/view/widgets/task_concept_section.dart`
- `lib/features/tasks/viewmodels/task_requests_award_delegate.dart`
- `lib/features/wallet/view/widgets/wallet_hero_card.dart`
- `lib/features/wallet/view/widgets/wallet_timeline_card.dart`
- `lib/features/work/view/widgets/work_item_booking_details.dart`
- `lib/features/work/view/widgets/work_item_bottom_actions.dart`
- `lib/features/work/view/widgets/work_item_guard_widgets.dart`

### Tests
- `test/unit/core/models/` -- ViewState and AppFailure unit tests
- 11 new VM test files (27/27 VMs now covered)
- 12 new shared mocks in `test/helpers/mock_services.dart`

### Documentation
- `.TODO/LINT_DEBT_PhaseE.md` -- 27 disabled lint rules with justification tracking
- `.TODO/PLAN_PhaseE_Polish_2026-04-04.md` -- Phase E execution plan
- `.TODO/DOCS_SYNC_2026-04-04_PhaseE.md` (this file)

## Key Phase E Changes

1. **Lint upgrade**: flutter_lints replaced with very_good_analysis. 862 dart fix auto-fixes + 12 manual fixes. 27 rules disabled with tracking.
2. **Sealed classes**: ViewState<T> and AppFailure sealed class infrastructure. 3 VMs migrated as proof of concept.
3. **DI improvements**: 5 VMs refactored with lazy getter pattern for Supabase.instance.
4. **God file decomposition**: 9 files decomposed into 13 new delegate/widget files.
5. **DeepLinkService**: Refactored to 0 feature imports using DeepLinkRegistry pattern.
6. **Localization**: l10n.yaml + app_en.arb (22 stubs) wired into MaterialApp.
7. **CI hardening**: Check 7 (core cannot import features), coverage floor raised to 33%.
8. **APK build**: Fixed (was broken in Phase D).
