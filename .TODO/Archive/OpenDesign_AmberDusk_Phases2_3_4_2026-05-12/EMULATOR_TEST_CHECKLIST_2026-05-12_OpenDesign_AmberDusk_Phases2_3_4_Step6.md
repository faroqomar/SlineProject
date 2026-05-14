# Emulator Test Checklist - Open Design Amber Dusk Phases 2, 3, and 4 Step 6

Date: 2026-05-12
Target: iOS Simulator, phone viewport.
Reference evidence:

- Open Design screenshots: `.TODO/OpenDesign_AmberDusk_Phases2_3_4_OpenDesignScreenshots_2026-05-11/`
- Runtime screenshots from this session: `.TODO/VisualQA_OpenDesign_AmberDusk_Phases2_3_4_iOSSimulator_2026-05-12/`
- Color comparison captures: `.TODO/Archive/VisualQA_ColorCompare_2026-05-12/`
- Plan and critique: `.TODO/PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`, `.TODO/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard.md`
- Session log: `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`

## Setup

- [ ] Launch the current app build on the open iOS Simulator.
- [ ] Use a seeded/login state that exposes Home, Create, Dashboard, Messages, Profile, Wallet, Saved, Search, Favorites, and Categories.
- [ ] Confirm the app is using the Amber Dusk design state.
- [ ] Compare at default text scale first, then repeat core navigation and card checks at larger text scale.
- [ ] Capture new screenshots only after each screen is stable and async loading has settled.

## Shell And Navigation

Files covered:

- `lib/app/main_navigation_screen.dart`
- `lib/core/widgets/custom_bottom_nav_bar.dart`
- `lib/core/utils/transitions/custom_route_transitions.dart`
- `test/widget/app/main_navigation_screen_test.dart`
- `test/core/widgets/custom_bottom_nav_bar_test.dart`

Checks:

- [ ] Home shell shows the intended Amber Dusk background gradient/surface without an opaque container hiding it.
- [ ] Bottom nav active/inactive colors, label typography, spacing, and rounded dock shape match `phase2-home-shell-fab-nav.png`.
- [ ] Message badge shows a dot when no numeric count exists and a numeric badge when a positive count exists.
- [ ] FAB appears only on Home and opens Create Task.
- [ ] Dashboard, Messages, and Profile nav states match their Open Design references.
- [ ] Route transitions feel opaque and do not reveal stale screens underneath.

## Create Task Flow

Files covered:

- `lib/features/tasks/view/create_task_screen.dart`
- `lib/features/tasks/view/widgets/task_concept_section.dart`
- `lib/features/tasks/view/widgets/booking_logistics_section.dart`
- `lib/features/tasks/models/task_model.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `test/widget/tasks/create_task_screen_test.dart`

Checks:

- [ ] Type selection screen matches `phase2-create-type-tender-selected.png` and `phase2-create-type-booking-selected.png`.
- [ ] Tender and booking cards expose clear selected state visually and to VoiceOver.
- [ ] Close button is reachable, labelled, and dismisses the sheet.
- [ ] Title, description, budget, role, seniority, and package fields remain editable after navigation between steps.
- [ ] Deadline chips select by date correctly after waiting on the screen; no drift from `DateTime.now()` is visible.
- [ ] Tender details and review match `phase2-create-tender-details.png` and `phase2-create-tender-review.png`.
- [ ] Booking details and review match `phase2-create-booking-details.png` and `phase2-create-booking-review.png`.
- [ ] Validation errors use localized copy where new keys were added.

## Home, Discovery, Filters, And Cards

Files covered:

- `lib/features/home/view/home_screen.dart`
- `lib/features/home/view/widgets/filters_modal.dart`
- `lib/features/tasks/view/widgets/discovery_task_sliver.dart`
- `lib/features/tasks/view/widgets/task_card.dart`
- `lib/features/tasks/view/widgets/tender_task_card.dart`
- `lib/features/tasks/view/widgets/booking_task_card.dart`
- `lib/features/booking/view/widgets/booking_card.dart`
- `lib/core/utils/format_price.dart`
- `test/widget/home/home_screen_test.dart`
- `test/widget/home/filters_modal_test.dart`
- `test/widget/cards/task_card_test.dart`
- `test/widget/cards/booking_task_card_test.dart`
- `test/widget/booking/bookings_discovery_screen_test.dart`

Checks:

- [ ] Home All feed matches `phase3-home-all-feed.png`.
- [ ] Booking filter view matches `phase3-home-bookings-filter.png`.
- [ ] Tasks filter view matches `phase3-home-tasks-filter.png`.
- [ ] Task, tender, booking, and discovery cards match Open Design colors, typography, radius, shadows, chip styling, and price formatting.
- [ ] HOT badge uses Amber Dusk star color for both background and icon/text.
- [ ] Booking avatar online indicator only appears when real presence data says online.
- [ ] Filter modal surface, border, chips, sort controls, and Apply button respond correctly in dark/light mode.
- [ ] Filter changes are not committed until Apply.
- [ ] Empty-state copy uses "tasks" language, not old "posts/tenders" language where changed.

## Dashboard

Files covered:

- `lib/features/dashboard/view/dashboard_screen.dart`
- `lib/features/dashboard/view/tabs/overview_tab.dart`
- `lib/features/dashboard/view/tabs/bookings_tab.dart`
- `lib/features/dashboard/view/tabs/inbox_tab.dart`
- `lib/features/dashboard/view/tabs/work_tab.dart`
- `lib/features/dashboard/view/tabs/wallet_tab.dart`
- `lib/features/dashboard/view/widgets/activity_feed_preview.dart`
- `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart`
- `lib/features/dashboard/view/widgets/next_actions_list.dart`
- `lib/features/dashboard/view/widgets/work_item_card.dart`
- `lib/features/booking/view/widgets/dashboard_booking_card.dart`
- `lib/features/tasks/view/widgets/dashboard_offer_card.dart`
- `test/widget/dashboard/dashboard_screen_test.dart`
- `test/widget/dashboard/work_tab_test.dart`
- `test/widget/dashboard/booking_card_test.dart`
- `test/widget/dashboard/inbox_tab_test.dart`
- `test/widget/dashboard/dashboard_offer_card_test.dart`

Checks:

- [ ] Overview tab matches `phase4-dashboard-overview.png`.
- [ ] Counters animate without layout shift and use the correct completed-work tab route.
- [ ] Bookings tab skeleton padding and loaded list padding align; compare `phase4-dashboard-bookings.png`.
- [ ] Booking card primary/secondary actions enable only when real actions exist.
- [ ] Inbox Received and Sent mode buttons announce selected state and do not fetch unexpectedly on mode switch.
- [ ] Award, reject, pay-now, and withdraw actions show correct snackbar colors and callbacks.
- [ ] DashboardOfferCard has only its explicit buttons announced as controls.
- [ ] Work Active, Done, and Cancelled sub-tabs match their three phase 4 screenshots.
- [ ] Work item progress bars are scoped to the right item and use formatted zero-price fallback.
- [ ] Dashboard tab labels and bottom padding remain stable across safe-area sizes.

## Messages

Files covered:

- `lib/features/chat/view/messages_screen.dart`
- `test/widget/chat/messages_screen_test.dart`

Checks:

- [ ] Messages nav state matches `phase2-messages-nav-active.png`.
- [ ] Search opens, filters by participant name and message text, and can be cleared.
- [ ] Responses/Requests segmented control announces selected state.
- [ ] Switching modes does not hide valid conversations until a real model contract supports direction filtering.
- [ ] Online row label accurately reflects the shown data; each visible participant has an individual semantic label.
- [ ] Delete confirmation dialog uses Amber Dusk surface, text, danger, and button styling.

## Profile

Files covered:

- `lib/features/profile/view/profile_screen.dart`
- `lib/features/profile/viewmodels/profile_view_model.dart`
- `test/unit/profile/profile_view_model_test.dart`

Checks:

- [ ] Profile nav state matches `phase2-profile-nav-active.png`.
- [ ] Hero badges come from ViewModel data and fall back safely when unavailable.
- [ ] Rating comes from ViewModel data and does not display stale hardcoded values.
- [ ] Settings, public profile, and logout rows are reachable across the whole row, announce as buttons, and show feedback when navigation cannot happen.

## Wallet

Files covered:

- `lib/features/wallet/view/wallet_screen.dart`
- `lib/features/wallet/view/wallet_dashboard_screen.dart`
- `lib/features/wallet/view/widgets/wallet_hero_card.dart`
- `lib/features/wallet/view/widgets/wallet_shared_body.dart`
- `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`
- `lib/features/wallet/view/widgets/wallet_timeline_card.dart`
- `test/widget/wallet/wallet_shared_body_test.dart`

Checks:

- [ ] Wallet title, available balance, withdraw, and top-up labels come from localization.
- [ ] Back and refresh buttons have accessible labels.
- [ ] Hero card, snapshot card, timeline, and dashboard wallet tab use Amber Dusk tokens consistently.
- [ ] Disabled snapshot actions explain where withdraw/top-up can be performed.
- [ ] Hairline divider and spacing match the design without clipped text.

## Search, Saved, Favorites, And Categories

Files covered:

- `lib/features/search/view/search_screen.dart`
- `lib/features/search/view/widgets/search_result_profile_card.dart`
- `lib/features/saved/view/saved_tasks_screen.dart`
- `lib/features/saved/view/widgets/saved_task_tile.dart`
- `lib/features/favorites/view/favorites_screen.dart`
- `lib/features/favorites/view/widgets/favorite_card.dart`
- `lib/features/categories/view/categories_screen.dart`
- `test/features/favorites/view/widgets/favorite_card_test.dart`

Checks:

- [ ] Search tab colors, selected text, muted text, cards, and profile CTA use the same Amber Dusk scheme in light/dark mode.
- [ ] Profile result card has a single accessible outer button; inner visual CTA is not announced as a nested button.
- [ ] Saved tasks screen header, refresh, empty state, and outline buttons use the same Amber Dusk token source.
- [ ] Saved task tile semantics mention delete availability.
- [ ] Favorite card exposes Start Chat and Remove as separate actions without an outer conflicting button node.
- [ ] Categories screen uses shared Amber Dusk color resolution and matches the app shell palette.

## Core Theme, Tokens, And Utilities

Files covered:

- `lib/core/theme/app_dimens.dart`
- `lib/core/theme/app_layout.dart`
- `lib/core/theme/designs/amber_dusk/amber_dusk_colors.dart`
- `lib/core/theme/designs/amber_dusk/amber_dusk_spacing.dart`
- `lib/core/theme/designs/amber_dusk/amber_dusk_tokens.dart`
- `lib/core/theme/designs/amber_dusk/amber_dusk_widget_theme.dart`

Checks:

- [ ] New radius, spacing, divider, and bottom-padding tokens do not alter unrelated screens.
- [ ] Amber Dusk text inverse, scrim, transparent, hero, and semantic colors render correctly in every touched screen above.
- [ ] Motion and elevation feel consistent across cards, sheets, and navigation.

## Documentation And Screenshot Artifacts

Files covered:

- `.TODO/OpenDesign_AmberDusk_Phases2_3_4_OpenDesignScreenshots_2026-05-11/README.md`
- `.TODO/OpenDesign_AmberDusk_Phases2_3_4_OpenDesignScreenshots_2026-05-11/*.png`
- `.TODO/VisualQA_OpenDesign_AmberDusk_Phases2_3_4_iOSSimulator_2026-05-12/REPORT.md`
- `.TODO/VisualQA_OpenDesign_AmberDusk_Phases2_3_4_iOSSimulator_2026-05-12/*.png`
- `.TODO/Archive/VisualQA_ColorCompare_2026-05-12/*.png`
- `.TODO/PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`
- `.TODO/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md`

Checks:

- [ ] Every runtime screenshot has a matching Open Design reference or an explicit note explaining why it is coverage-only.
- [ ] Visual QA report records pass/fail per screen, not only global notes.
- [ ] Any remaining mismatch is entered as a follow-up item before release.
- [ ] Master Report, plan, critique, and session log agree on scope and unresolved gates.

## Final Gate

- [ ] All checklist items above pass on the target simulator.
- [ ] New final runtime screenshots are saved beside the existing VisualQA captures.
- [ ] `.TODO/VisualQA_OpenDesign_AmberDusk_Phases2_3_4_iOSSimulator_2026-05-12/REPORT.md` is updated with final evidence.
- [ ] No code is marked release-ready until the manual visual parity gate is complete.
