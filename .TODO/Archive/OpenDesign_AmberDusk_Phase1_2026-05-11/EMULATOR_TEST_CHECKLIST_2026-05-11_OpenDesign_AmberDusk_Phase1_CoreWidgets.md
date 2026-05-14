# Emulator Test Checklist - Open Design Amber Dusk Phase 1 Core Widgets

Date: 2026-05-11
Scope: every file touched or left uncommitted during the Phase 1 shared phone-widget session
Status: READY FOR MANUAL EMULATOR EXECUTION

## 0. Evidence Preconditions

- [ ] Confirm latest code is the current uncommitted worktree.
- [ ] Confirm `coverage/lcov.info` is not tracked in the index after coverage regeneration.
- [ ] Keep Open Design MCP artifact available: project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, artifact `Sline V2 Amber Dusk.html`.
- [ ] Treat `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/` as reference only; README marks the pack provisional.

## 1. Command Preflight

- [ ] `flutter gen-l10n`
- [ ] `dart format --set-exit-if-changed lib/core/widgets lib/core/theme test/core/widgets test/core/theme`
- [ ] `flutter analyze --no-fatal-infos`
- [ ] `flutter test test/core/theme/ test/core/widgets/`
- [ ] `flutter test test/widget/app/main_navigation_screen_test.dart test/widget/cards/task_card_test.dart test/widget/cards/booking_task_card_test.dart test/widget/tasks/task_details_screen_test.dart test/widget/booking/booking_details_screen_test.dart`
- [ ] `flutter test --coverage`
- [ ] Verify total coverage remains above 40%.
- [ ] `git diff --check && git diff --cached --check`

## 2. Emulator Matrix

Run each route group at these logical widths:

- [ ] 360 x representative phone height
- [ ] 390 x representative phone height
- [ ] 402 x representative phone height
- [ ] 430 x representative phone height

For each width:

- [ ] Text scale 1.0.
- [ ] Text scale 1.3.
- [ ] Android bottom system navigation inset visible.
- [ ] Light theme if app exposes it.
- [ ] Dark theme if app exposes it.
- [ ] Capture screenshot or write manual notes for every route group below.

## 3. Route Smoke Checklist

### Home / Discovery

- [ ] App launches to Home without exception.
- [ ] Bottom nav is solid, centered, above Android system nav, and has no blur/glass.
- [ ] Active nav capsule uses Amber primary tint; inactive icons use muted tone.
- [ ] Home cards use Amber card/container surfaces and do not show teal borders.
- [ ] `AppButton` and `AppStyledButton` labels fit at width 360 and text scale 1.3.
- [ ] Long button labels ellipsize instead of overflowing.
- [ ] `CircleIconButton` remains visually 42px while touch target remains at least 48px.
- [ ] Signed avatars/images show Amber placeholders while loading or failing.
- [ ] Empty/error/loading states show shimmer skeletons, not spinners, where Phase 1 widgets apply.

### Dashboard / Work Shell

- [ ] Global TabBar active label and underline are Amber, not teal.
- [ ] Sliver tab bar pinned state keeps the same surface and themed border behavior as tests.
- [ ] App cards and panel containers remain borderless or use documented token border width.
- [ ] Wallet/work skeletons use Amber neutral shimmer colors.
- [ ] Status badges for active/won use forest foreground and active overlay.
- [ ] Completed/refunded statuses use cream foreground and completed overlay.
- [ ] Pending/review statuses pulse briefly and remain readable.

### Messages

- [ ] Messages nav item shows compact rust dot when count is zero.
- [ ] Messages nav item shows numeric badge when a positive count is injected.
- [ ] Messages nav marker can be suppressed when no notification exists.
- [ ] Conversation tile skeletons use Amber neutral shimmer, not teal/white shimmer.
- [ ] Message bubble skeletons use Amber neutral shimmer.
- [ ] Signed avatars do not log raw storage paths during fallback scenarios.
- [ ] No `CircularProgressIndicator` appears in message skeleton loading states.

### Profile / Media

- [ ] SignedAvatar initials fallback uses Amber media fallback and foreground.
- [ ] SignedAvatar icon fallback uses Amber media fallback and foreground.
- [ ] SignedImage failure fallback shows localized `Tap to retry`.
- [ ] SignedImage retry tap re-enters loading and resolves/fails cleanly.
- [ ] SignedImage generic media token override remains visually isolated when tested.
- [ ] Online indicator uses forest and stays visible on dark surfaces.
- [ ] No raw signed URL or storage path appears in debug output.

### Task / Booking Details

- [ ] Task detail header, cards, and bottom actions still render after shared widget changes.
- [ ] Booking detail status banners use the new StatusBadge semantic groups.
- [ ] AppTextField error border uses rust and focused error border is visibly stronger.
- [ ] AppTextField labels uppercase where provided and keep counter/focus/disabled behavior.
- [ ] Apply/Manage/Book actions preserve tap behavior.
- [ ] Long text in fields and buttons does not overlap adjacent content.

## 4. Shared Widget Target Checks

- [ ] `AppButton`: default, pressed, disabled, loading, success flash, error flash, icon, custom override, and long-label states.
- [ ] `AppStyledButton`: primary and ghost variants, icon size, disabled/loading, text color handling.
- [ ] `ScaleButton`: press animation, disabled opacity, immediate callback path.
- [ ] `AppTextField`: hint, label, focus, disabled, clear, password toggle, counter, validation error, long text.
- [ ] `CircleIconButton`: visual size, touch target, border width, tooltip, semantics, custom foreground/background.
- [ ] `CustomBottomNavBar`: active state, safe area, compact dot, count badge, suppression, tap navigation.
- [ ] `StatusBadge`: setup/timeout, review/pending, active/won, completed/refunded, canceled/failed, custom color, small variant, pulse timing.
- [ ] `SkeletonLoader`: rectangular shimmer, circular avatar shimmer, animation advances over frames.
- [ ] `SkeletonTaskCard`: task surface, Amber divider, Amber shimmer, no spinner.
- [ ] `SkeletonBookingCard`: header gradient, Amber shimmer, no spinner.
- [ ] `SkeletonOfferCard`: Amber panel surface and shimmer.
- [ ] `SkeletonMessageBubble`: left/right alignment and Amber shimmer.
- [ ] `SkeletonConversationTile`: avatar/text/timestamp placeholders and Amber shimmer.
- [ ] `SkeletonSearchResultCard`: avatar/tag placeholders and Amber shimmer.
- [ ] `SkeletonCategoryTile`: grid tile placeholder and Amber shimmer.
- [ ] `SkeletonFavoriteCard`: avatar/action placeholders and Amber shimmer.
- [ ] `SkeletonDetailsScreen`: scrollable details placeholder and Amber shimmer.
- [ ] `SkeletonCardExtended` variants T-CW120 through T-CW128: render without spinner and use Amber panel/shimmer roles.
- [ ] `SignedAvatar`: null path, public URL, injected generator, generator failure, online dot, semantics.
- [ ] `SignedImage`: null/empty path, public URL, injected generator, generator failure, retry, localization, semantics.
- [ ] `SliverTabBarDelegate`: themed surface, themed border, self-documenting shrink/overlap behavior.

## 5. File Coverage Map

### CI / Generated / Build Artifacts

- [ ] `.github/workflows/ci.yml`: coverage is uploaded as an artifact.
- [ ] `coverage/lcov.info`: removed from tracked index; regenerated file remains ignored locally.

### Phase Plans, Reports, Logs, Handoffs, Screenshots

- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets.md`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/DOCS_SYNC_2026-05-11_OpenDesign_AmberDusk_Phase1_CoreWidgets.md`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/MASTER_REPORT_2026-05-11_OpenDesign_AmberDusk_Phase1_CoreWidgets.md`
- [ ] `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-11_OpenDesign_AmberDusk_Phase1_CoreWidgets.md`
- [ ] `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phase1_CoreWidgets_ToWeb_2026-05-11.md`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/README.md`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-360-home.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-360-dashboard.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-360-messages.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-360-profile.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-390-home.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-390-dashboard.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-390-messages.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-390-profile.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-402-home.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-402-dashboard.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-402-messages.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-402-profile.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-430-home.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-430-dashboard.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-430-messages.png`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-430-profile.png`
- [ ] `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`

### Archived Phase 0 / Existing Documentation Still Dirty In Worktree

- [ ] `.TODO/Archive/EMULATOR_TEST_CHECKLIST_2026-05-11_OpenDesign_AmberDusk_Phase0.md`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/DOCS_SYNC_2026-05-11_DocsKeeper_AgentSystemAmberDusk.md`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/MASTER_REPORT_2026-05-11_OpenDesign_AmberDusk_Phase0.md`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase0_PhoneFoundation.md`
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
- [ ] `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
- [ ] `Sline_everything/CODE_REVIEW.md`
- [ ] `Sline_everything/DEVELOPER_GUIDE.md`
- [ ] `Sline_everything/STRUCTURE.md`
- [ ] `Sline_everything/Sline_Log.md`

### Theme / Tokens / Localization

- [ ] `lib/core/theme/app_dimens.dart`
- [ ] `lib/core/theme/app_theme.dart`
- [ ] `lib/core/theme/designs/amber_dusk/amber_dusk_tokens.dart`
- [ ] `lib/core/theme/designs/amber_dusk/amber_dusk_widget_theme.dart`
- [ ] `lib/l10n/app_en.arb`
- [ ] `lib/l10n/app_localizations.dart`
- [ ] `lib/l10n/app_localizations_en.dart`

### Shared Widgets

- [ ] `lib/core/widgets/app_button.dart`
- [ ] `lib/core/widgets/app_card.dart`
- [ ] `lib/core/widgets/app_card_container.dart`
- [ ] `lib/core/widgets/app_styled_button.dart`
- [ ] `lib/core/widgets/app_text_field.dart`
- [ ] `lib/core/widgets/circle_icon_button.dart`
- [ ] `lib/core/widgets/custom_bottom_nav_bar.dart`
- [ ] `lib/core/widgets/scale_button.dart`
- [ ] `lib/core/widgets/signed_avatar.dart`
- [ ] `lib/core/widgets/signed_image.dart`
- [ ] `lib/core/widgets/skeleton_card.dart`
- [ ] `lib/core/widgets/skeleton_card_extended.dart`
- [ ] `lib/core/widgets/skeleton_loader.dart`
- [ ] `lib/core/widgets/sliver_tab_bar_delegate.dart`
- [ ] `lib/core/widgets/status_badge.dart`

### Core Theme / Widget Tests

- [ ] `test/core/theme/amber_dusk_widget_theme_test.dart`
- [ ] `test/core/widgets/app_button_test.dart`
- [ ] `test/core/widgets/app_card_container_test.dart`
- [ ] `test/core/widgets/app_card_test.dart`
- [ ] `test/core/widgets/app_styled_button_test.dart`
- [ ] `test/core/widgets/app_text_field_test.dart`
- [ ] `test/core/widgets/circle_icon_button_test.dart`
- [ ] `test/core/widgets/custom_bottom_nav_bar_test.dart`
- [ ] `test/core/widgets/scale_button_test.dart`
- [ ] `test/core/widgets/signed_avatar_test.dart`
- [ ] `test/core/widgets/signed_image_test.dart`
- [ ] `test/core/widgets/skeleton_card_extended_test.dart`
- [ ] `test/core/widgets/skeleton_card_test.dart`
- [ ] `test/core/widgets/skeleton_loader_test.dart`
- [ ] `test/core/widgets/sliver_tab_bar_delegate_test.dart`
- [ ] `test/core/widgets/status_badge_test.dart`
- [ ] `test/core/widgets/widget_test_helpers.dart`

## 6. Pass / Fail Recording

For each emulator width, record:

- [ ] Device/profile name.
- [ ] Exact logical size.
- [ ] Text scale.
- [ ] Route group.
- [ ] Screenshot path or written observation.
- [ ] Pass/fail.
- [ ] Any mismatch against Open Design MCP evidence.
- [ ] Any mismatch against generated widget tests.

Phase 1 visual closure requires all checked route groups to pass or a new TODO/fix issue for each failure.
