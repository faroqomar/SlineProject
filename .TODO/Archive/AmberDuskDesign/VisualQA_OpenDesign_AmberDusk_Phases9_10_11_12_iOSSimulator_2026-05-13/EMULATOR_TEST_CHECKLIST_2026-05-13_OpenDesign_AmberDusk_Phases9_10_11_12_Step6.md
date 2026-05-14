# EMULATOR TEST CHECKLIST: OpenDesign Amber Dusk Phases 9-12 Step 6

Date: 2026-05-13
Status: OPEN MANUAL RUNTIME GATE
Source report: `.TODO/MASTER_REPORT_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12.md`

## Purpose

Run this checklist before claiming final Phase 9-12 visual parity. Automated tests and analyzer are green, but they do not prove runtime phone layout, text overflow, scroll behavior, small-width fit, or screenshot parity.

## Device Matrix

Run each visual flow on these logical widths:

- 360
- 390
- 402
- 430

For each width:

- Light mode.
- Dark mode.
- Text scale 1.0.
- Text scale 1.3 on all primary flows.
- Text scale 2.0 on profile, public profile, settings, notification modal, and search tabs.
- Authenticated client account.
- Authenticated freelancer account.
- Slow network or forced loading state where the ViewModel/test harness supports it.
- Empty, error, loading, and populated states where data fixtures can trigger them.

## Open Design And Screenshot Gate

- [ ] Re-check Open Design MCP before writing final visual notes.
- [ ] Compare exact-evidence surfaces against Open Design: profile hero, metrics, availability card, service rows, portfolio strip, settings groups, edit rows, sheet root, and scrim treatment.
- [ ] Keep categories, search, favorites, saved tasks, notification modal/list details, helper overlays, and CTA/status outputs labeled adaptation-only unless exact screenshots are provided.
- [ ] Append visual notes to `.TODO/PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md` only after user screenshots are supplied.

## Primary Runtime Flows

### Profile And Settings

- [ ] `ProfileScreen`: loading, error, empty profile fallback, populated profile.
- [ ] `ProfileScreen`: identity hero, metrics grid, availability card, skill/service rows, portfolio proof strip, grouped actions, and bottom safe area do not overflow at every width.
- [ ] `ProfileScreen`: settings route opens, role switch still uses the existing ViewModel/service flow, and no visual change alters role authority.
- [ ] `SettingsScreen`: dark-mode switch changes state without layout shift.
- [ ] `SettingsScreen`: Manage Portfolio row opens the correct screen.
- [ ] `SettingsScreen`: logout cancel keeps the session and closes the dialog.
- [ ] `SettingsScreen`: logout confirm signs out through the existing auth ViewModel path.
- [ ] `SettingsScreen`: every row remains tappable with at least the expected touch target and readable contrast.

### Edit Profile And Avatar

- [ ] `EditProfileScreen`: fields load with current data and preserve labels, validation, helper text, and keyboard-safe scrolling.
- [ ] `EditProfileScreen`: skills chips wrap cleanly at all widths and text scales.
- [ ] `EditProfileScreen`: save success returns or shows the expected feedback through the existing ViewModel path.
- [ ] `EditProfileScreen`: save failure logs via `AppLogger` and shows user-safe text.
- [ ] `ProfileAvatarWidget`: avatar success, cancel, upload failure, and loading overlay states keep signed/public URL behavior unchanged.
- [ ] `ProfilePreviewModal`: preview opens, scrolls, closes, and avoids image/text overlap.

### Public Profile

- [ ] `PublicProfileScreen`: loading spinner, retryable error, and populated states render.
- [ ] `PublicProfileScreen`: unified hero, actions, tabs, metrics, and sticky bottom actions stay within screen bounds.
- [ ] `PublicProfileScreen`: About tab bio and skills wrap at all text scales.
- [ ] `PublicProfileScreen`: Portfolio tab shows compact proof tiles, empty state, and preview interaction.
- [ ] `PublicProfileScreen`: History tab handles empty and populated rows.
- [ ] `PublicProfileScreen`: Reviews tab handles empty and populated reviews.
- [ ] `PublicProfileScreen`: Message when unauthenticated shows safe prompt and no crash.
- [ ] `PublicProfileScreen`: Message self-profile path is blocked or safely handled.
- [ ] `PublicProfileScreen`: Message service failure shows generic safe copy and logs.
- [ ] `PublicProfileScreen`: Hire Now uses the existing placeholder/fallback path and logs the interaction.
- [ ] `PublicProfileScreen`: favorite toggle reflects success/failure without desyncing public profile state.
- [ ] `ReportUserDialog`: Submit is disabled for empty reason.
- [ ] `ReportUserDialog`: report success closes safely.
- [ ] `ReportUserDialog`: report failure keeps safe copy and no raw exception text.

### Portfolio And Services

- [ ] `PortfolioScreen`: loading, empty, error, populated grid, pagination/loading-more, and retry states render.
- [ ] `PortfolioScreen`: rapid Add taps do not stack sheets.
- [ ] `AddPortfolioSheet`: add success, validation, image cancel, image upload failure, and close behavior work.
- [ ] `EditPortfolioSheet`: edit success, validation, image replacement, and close behavior work.
- [ ] `PortfolioDetailsSheet`: details open, delete confirmation opens, cancel keeps item, confirm deletes through ViewModel.
- [ ] `PortfolioTile`: image, fallback, title, and subtitle are readable and tappable.
- [ ] `ImagePlaceholder`: placeholder uses Amber Dusk solid treatment and no glass/blur.
- [ ] `ManagePortfolioScreen`: loading, empty, populated, add/edit, image upload failure, delete confirmation, and edit tooltip states render.
- [ ] `MyServicesScreen`: loading, empty, error, populated, back tooltip, create/edit placeholder, and status badges render.
- [ ] `ServiceCard`: active/inactive/pending or available status variants are readable and do not overflow.

### Secondary Screens

- [ ] `CategoriesScreen`: loading, error, empty, populated grid, category color chips, and navigation tap behavior render.
- [ ] `SearchScreen`: tabs expose button semantics, selected state is visible, and results update without overflow.
- [ ] `SearchResultProfileCard`: avatar, title, rating/skill metadata, and CTA states fit at all widths.
- [ ] `FavoritesScreen`: loading, empty, error, populated list, retry, and pull-to-refresh render.
- [ ] `FavoriteCard`: chat, remove, date, avatar, and fallback states render; removing reflects in list.
- [ ] Existing hardcoded skipped integration coverage: manually verify a favorite added from public profile appears in Favorites and can be removed.
- [ ] `SavedTasksScreen`: loading, empty, error, populated, remove, and detail navigation states render.
- [ ] `SavedTaskTile`: long title, budget, category, date, remove, and tap states fit.

### Notifications And Shared Helpers

- [ ] `NotificationBadgeButton`: count `1`, `9+`, and zero/unread hidden states render in light and dark mode.
- [ ] `NotificationBadgeButton`: rapid taps do not stack modals.
- [ ] `NotificationsModal`: loading, empty, error, populated list, retry, and close tooltip states render.
- [ ] `NotificationsModal`: Mark all success clears unread visual state.
- [ ] `NotificationsModal`: Mark all failure shows safe SnackBar and does not clear unread state.
- [ ] `NotificationTile`: each notification type icon/color is readable; unread/read rows differ without excessive contrast.
- [ ] `NotificationTile`: tapping a deeplink notification follows the existing navigation/deeplink path.
- [ ] `LoadingUtils`: blocking overlay shows one scrim, spinner, optional message, and closes idempotently.
- [ ] `StatusPresenter`: warning, danger, success, neutral, and muted presenter outputs are readable in at least one live status surface or test harness.
- [ ] `UnifiedCtaResolver`: award, payment, delivered review, refund, and no-action metadata still map to expected CTA labels/status tones.

## File Coverage Map

### Source Files

- [ ] `lib/core/theme/app_dimens.dart`
- [ ] `lib/core/utils/loading_utils.dart`
- [ ] `lib/core/utils/status_presenter.dart`
- [ ] `lib/core/utils/unified_cta_resolver.dart`
- [ ] `lib/features/categories/view/categories_screen.dart`
- [ ] `lib/features/favorites/view/favorites_screen.dart`
- [ ] `lib/features/favorites/view/widgets/favorite_card.dart`
- [ ] `lib/features/notifications/view/notifications_modal.dart`
- [ ] `lib/features/notifications/view/widgets/notification_badge_button.dart`
- [ ] `lib/features/notifications/view/widgets/notification_tile.dart`
- [ ] `lib/features/notifications/viewmodels/notification_view_model.dart`
- [ ] `lib/features/portfolio/view/portfolio_screen.dart`
- [ ] `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart`
- [ ] `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart`
- [ ] `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart`
- [ ] `lib/features/portfolio/view/widgets/image_placeholder.dart`
- [ ] `lib/features/portfolio/view/widgets/portfolio_tile.dart`
- [ ] `lib/features/profile/view/edit_profile_screen.dart`
- [ ] `lib/features/profile/view/manage_portfolio_screen.dart`
- [ ] `lib/features/profile/view/my_services_screen.dart`
- [ ] `lib/features/profile/view/profile_screen.dart`
- [ ] `lib/features/profile/view/public_profile_screen.dart`
- [ ] `lib/features/profile/view/settings_screen.dart`
- [ ] `lib/features/profile/view/widgets/profile_avatar_widget.dart`
- [ ] `lib/features/profile/view/widgets/profile_preview_modal.dart`
- [ ] `lib/features/profile/view/widgets/public_profile/public_profile_header.dart`
- [ ] `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart`
- [ ] `lib/features/profile/view/widgets/public_profile/public_profile_reviews.dart`
- [ ] `lib/features/profile/view/widgets/public_profile/public_profile_stats.dart`
- [ ] `lib/features/saved/view/saved_tasks_screen.dart`
- [ ] `lib/features/saved/view/widgets/saved_task_tile.dart`
- [ ] `lib/features/search/view/search_screen.dart`
- [ ] `lib/features/search/view/widgets/search_result_profile_card.dart`
- [ ] `lib/features/services/view/widgets/service_card.dart`

### Test Files

- [ ] `test/unit/core/loading_utils_test.dart`
- [ ] `test/unit/core/status_presenter_test.dart`
- [ ] `test/unit/core/unified_cta_resolver_test.dart`
- [ ] `test/unit/notifications/notification_view_model_test.dart`
- [ ] `test/widget/notifications/notification_badge_button_test.dart`
- [ ] `test/widget/notifications/notifications_modal_test.dart`
- [ ] `test/widget/profile/phase9_dialogs_test.dart`
- [ ] `test/widget/search/search_screen_test.dart`

### Docs And Planning Artifacts

- [ ] `README.md`
- [ ] `Sline_everything/MVP_ROADMAP.md`
- [ ] `Sline_everything/Sline_Log.md`
- [ ] `Sline_everything/UI_SURFACE_INVENTORY.md`
- [ ] `.TODO/DOCS_SYNC_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12.md`
- [ ] `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12_Step6.md`
- [ ] `.TODO/MASTER_REPORT_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12.md`
- [ ] `.TODO/PLAN_CRITIQUE_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness.md`
- [ ] `.TODO/PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`
- [ ] `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phases9_10_11_12_ToWeb_2026-05-13.md`
- [ ] `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`

## Acceptance

- [ ] Every checked source route has screenshots or notes for the required width/mode matrix.
- [ ] Every exact-evidence surface has Open Design comparison notes.
- [ ] Every adaptation-only surface is labeled adaptation-only in notes.
- [ ] No runtime overflow, clipped text, unreadable contrast, stacked modal, or hidden tap target remains.
- [ ] The phase plan receives appended visual notes only after user screenshots are provided and Open Design MCP is rechecked.
