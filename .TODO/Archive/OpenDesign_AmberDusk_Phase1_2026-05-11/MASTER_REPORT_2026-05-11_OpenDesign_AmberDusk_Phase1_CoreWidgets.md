# Master Report - Open Design Amber Dusk Phase 1 Core Widgets

Date: 2026-05-11
Scope: Phase 1 shared phone-widget runtime activation
Plan: `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
Session log: `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
Status: CODE GATES PASS; MANUAL EMULATOR VISUAL QA CHECKLIST CREATED

## Review Inputs

- Orchestrator instructions read from `.cursor/Agents/Orchestrator.md`.
- Phase 1 source-of-truth plan and session log read before reporting.
- Open Design MCP rechecked against project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`; active artifact: `Sline V2 Amber Dusk.html`.
- Review agents completed:
  - Agent A UI/design review: `019e180e-ec81-7623-8e40-44c4dcd7caab`.
  - Agent B architecture/MVVM review: `019e180e-ef74-7152-b398-781a4de41330`.
  - Agent C test/QA review: `019e180e-f733-7fe1-8fa6-5ed47973700b`.

## Master Findings And Fix Verification

### BLOCKER-1 - Runtime phone visual QA was not recorded

Finding: The Phase 1 plan requires phone-width manual QA at 360, 390, 402, and 430 widths, while the session log and screenshot README marked visual evidence as provisional.

Disposition: Process gate remains for manual emulator execution. Code cannot honestly close this without runtime screenshots or manual notes. The required artifact was created as `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-11_OpenDesign_AmberDusk_Phase1_CoreWidgets.md`, covering every file touched this session and every widget family changed.

Status: RELEASE GATE OPEN UNTIL CHECKLIST IS EXECUTED.

### HIGH-1 - TabBar still used teal-era active colors

Finding: `AppTheme.tabBarTheme` routed active label and indicator colors through `AppColorScheme.primary`, which remains teal.

Fix:
- `lib/core/theme/app_theme.dart` now builds `TabBarThemeData` from the Amber Dusk tab adapter passed into `_buildTheme`.
- `test/core/theme/amber_dusk_widget_theme_test.dart` now asserts Amber Dusk active label and indicator colors for light and dark themes.

Status: FIXED AND VERIFIED.

### HIGH-2 - Skeleton shimmer defaulted to legacy card/hover colors

Finding: `SkeletonLoader` was theme-aware, but `AppTheme` seeded `SkeletonColors` from legacy card background and teal hover colors.

Fix:
- `lib/core/theme/app_theme.dart` now seeds `SkeletonColors` from `AmberDuskTokens.widgetTheme.skeleton`.
- `test/core/widgets/skeleton_loader_test.dart`, `test/core/widgets/skeleton_card_test.dart`, and `test/core/widgets/skeleton_card_extended_test.dart` verify Amber skeleton gradients and spinner absence.

Status: FIXED AND VERIFIED.

### HIGH-3 - Required downstream smoke tests were not evidenced after latest fixes

Finding: Step 5 verification did not prove the final uncommitted shared-widget changes against the downstream app shell and card/details tests.

Fix:
- Re-ran the required downstream smoke suite:
  - `test/widget/app/main_navigation_screen_test.dart`
  - `test/widget/cards/task_card_test.dart`
  - `test/widget/cards/booking_task_card_test.dart`
  - `test/widget/tasks/task_details_screen_test.dart`
  - `test/widget/booking/booking_details_screen_test.dart`

Status: FIXED AND VERIFIED.

### HIGH-4 - Base skeleton coverage missed several variants

Finding: The plan required coverage for task, booking, offer, message bubble, conversation tile, search result, category tile, favorite card, and details screen skeleton variants.

Fix:
- `test/core/widgets/skeleton_card_test.dart` now covers the remaining base variants and verifies Amber shimmer colors plus no spinner.

Status: FIXED AND VERIFIED.

### MED-1 - Status semantic groups reused the same amber overlay

Finding: Active/won and completed/refunded statuses had distinct foregrounds but shared the primary amber pill background.

Fix:
- `lib/core/theme/designs/amber_dusk/amber_dusk_widget_theme.dart` now exposes muted, active, completed, primary, and urgent status recipes.
- `lib/core/widgets/status_badge.dart` maps setup/timeout, pending/review, active/won, completed/refunded, and failure/canceled states through those recipes.
- `test/core/widgets/status_badge_test.dart` verifies foreground and background roles plus pulse timing.

Status: FIXED AND VERIFIED.

### MED-2 - Messages nav badge contract lacked count/absence coverage

Finding: The notification marker behavior was not testable for absence and numeric counts.

Fix:
- `lib/core/widgets/custom_bottom_nav_bar.dart` now exposes optional `showMessagesNotification` and `messagesNotificationCount` constructor inputs while preserving existing defaults.
- `test/core/widgets/custom_bottom_nav_bar_test.dart` covers compact dot, numeric count, and suppression.

Status: FIXED AND VERIFIED.

### MED-3 - Required widget state cases were missing from focused tests

Finding: AppButton, AppTextField, CircleIconButton, and StatusBadge had missing state coverage from the plan.

Fix:
- `test/core/widgets/app_button_test.dart` adds custom override and long-label coverage.
- `test/core/widgets/app_text_field_test.dart` adds focus, disabled, counter, and long text coverage.
- `test/core/widgets/circle_icon_button_test.dart` adds min touch target, tooltip, and semantics coverage.
- `test/core/widgets/status_badge_test.dart` adds pulse timing coverage.
- `lib/core/widgets/app_button.dart` now ellipsizes long labels inside fixed-width buttons.

Status: FIXED AND VERIFIED.

### MED-4 - Signed media logging could still leak raw exception text

Finding: Signed media warning logs redacted the JSON file field but still passed raw exception objects to `AppLogger`.

Fix:
- `lib/core/widgets/signed_image.dart` and `lib/core/widgets/signed_avatar.dart` now pass sanitized exception type labels to `AppLogger`.
- `SignedAvatar` received the same filename redaction hardening as `SignedImage`.

Status: FIXED AND VERIFIED.

### MED-5 - `SignedImage` exposed Amber Dusk tokens in its public API

Finding: `SignedImage.mediaTokens` used the Amber Dusk media token type directly.

Fix:
- `lib/core/widgets/signed_image.dart` now exposes generic `SignedImageMediaTokens`.
- Amber Dusk remains the default internal adapter, while callers can override with a non-design-system-specific object.
- `test/core/widgets/signed_image_test.dart` verifies generic media override behavior.

Status: FIXED AND VERIFIED.

### MED-6 - Localization test helper did not install generated delegates

Finding: The new `tapToRetry` string was generated, but core widget tests did not install localization delegates.

Fix:
- `test/core/widgets/widget_test_helpers.dart` now installs `AppLocalizations.localizationsDelegates` and `supportedLocales`.
- `test/core/widgets/signed_image_test.dart` verifies the retry text through the generated localization context.
- `flutter gen-l10n` was rerun.

Status: FIXED AND VERIFIED.

### MED-7 - `LinearGradient(` raw-value scan needed classification

Finding: The plan allows remaining raw-value hits only when classified.

Classification:
- `lib/core/widgets/skeleton_loader.dart:98`: intentional animated shimmer gradient. Colors are resolved from `SkeletonColors` and verified by `skeleton_loader_test.dart`.
- `lib/core/widgets/skeleton_card.dart:201`: intentional booking skeleton header gradient. Colors are resolved from Amber skeleton tokens and verified by `skeleton_card_test.dart`.

Status: CLASSIFIED AND VERIFIED.

## Validation Evidence

- `flutter gen-l10n`: PASS.
- `dart format --set-exit-if-changed lib/core/widgets lib/core/theme test/core/widgets test/core/theme`: PASS, 54 files checked, 0 changed.
- `flutter analyze --no-fatal-infos`: PASS, no issues.
- `flutter test test/core/theme/ test/core/widgets/`: PASS, 210 tests.
- Downstream smoke tests: PASS, 73 tests.
- `flutter test --coverage`: PASS, 1502 passed, 30 skipped.
- Coverage: 46.80% (`LH=11308`, `LF=24162`), above CI 40% floor.
- `git diff --check && git diff --cached --check`: PASS.

## Residual Release Gate

The only remaining gate is manual/runtime visual evidence. Execute `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-11_OpenDesign_AmberDusk_Phase1_CoreWidgets.md` on Android emulator widths 360, 390, 402, and 430 before declaring Phase 1 visually complete.
