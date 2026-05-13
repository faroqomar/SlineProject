# SLine UI Surface Inventory

Last updated: 2026-05-13

This file is the durable source of truth for SLine's user interface surfaces. It exists so redesign, QA, accessibility, navigation, and feature-change work can track every screen, popup, sheet, tab, route, navigation entry, and major reusable UI component without missing hidden or secondary surfaces.

## Maintenance Contract

- Planner, PlanCritic, Executor, Pixel, Orchestrator, Sentinel, and DocsKeeper must read this file for any UI, navigation, redesign, accessibility, feature-shell, modal, popup, tab, route, or reusable-widget work.
- Any new screen, route, sheet, dialog, popup menu, tab, major reusable widget, or deep-link UI surface must be added here in the same change that creates it.
- If an agent discovers a UI surface that is missing from this file, the agent must update this file or route the update to DocsKeeper before the work is considered complete.
- If a screen is renamed, moved, archived, or replaced, update the entry instead of leaving duplicate names.
- Use this file with `Sline_everything/DOC_SOURCE_MAP.md` and `Sline_everything/AppDigram/README.md` when planning or reviewing UI work.

## How To Use This File

For a redesign or UI change:

1. Identify the feature area in this inventory.
2. Read the listed route, screen, and popup entries before planning changes.
3. Cross-check live code with `rg` for the screen class, route name, and popup/sheet helpers.
4. Update this file when code adds, removes, moves, or materially changes a UI surface.
5. Record any related docs/diagram update in `Sline_everything/DOC_SOURCE_MAP.md` when the change affects planning routes.

## Surface Types

| Type | Meaning |
| --- | --- |
| Route screen | A full-screen page reachable through named routes, pushed routes, deep links, or app shell navigation |
| Shell surface | Persistent app frame, tab host, bottom nav, FAB, or app-level guard UI |
| Subscreen | A tab, tab view, nested state view, or route-level section that behaves like a screen |
| Sheet | `showModalBottomSheet` or persistent bottom-sheet UI |
| Dialog | `showDialog`, alert, confirmation, loading, or reason-entry modal |
| Menu | Popup menu, overflow action menu, or contextual action menu |
| Transient feedback | SnackBar, banner, inline state, toast-like error/success surface |
| Shared widget | Reusable UI component used across multiple feature screens |

## App Shell And Navigation

| Surface | File | Entry point / notes |
| --- | --- | --- |
| App root and auth listener | `lib/main.dart` | `SLineApp`, `_AppWithAuthListener`, route table, provider graph, account guard routing |
| Splash screen | `lib/main.dart` | Initial startup surface before auth/app shell resolution |
| Main app shell | `lib/app/main_navigation_screen.dart` | Hosts the four visible bottom-nav tabs and central create-task action |
| Bottom navigation model | `lib/core/navigation/main_nav_destinations.dart` | Home index 0, Dashboard index 1, Messages index 2, Profile index 3 |
| Bottom navigation widget | `lib/core/widgets/custom_bottom_nav_bar.dart` | Persistent app navigation control |
| Create task floating action | `lib/app/main_navigation_screen.dart`, `lib/core/utils/transitions/custom_route_transitions.dart`, and `lib/features/tasks/view/create_task_screen.dart` | App-shell action opens `CreateTaskScreen` through `SlinePageRoute.modalSheet` |
| Notification entry point | `lib/features/notifications/view/widgets/notification_badge_button.dart` | Opens notifications modal and routes selected notification payloads |
| Runtime config banner | `lib/app/main_navigation_screen.dart` | Dismissible shell banner from `SystemConfigViewModel.config.banner*`; supports warning/error/default coloring and vertical-drag dismiss |
| Route transition helpers | `lib/core/utils/transitions/custom_route_transitions.dart`, `lib/core/utils/app_animations.dart` | Shared page transitions and FAB press/rotation animation helpers used by shell/auth navigation |

## Named Route Map

| Route | Screen | File |
| --- | --- | --- |
| `/login` | `LoginScreen` | `lib/features/auth/view/login_screen.dart` |
| `/signup` | `SignupScreen` | `lib/features/auth/view/signup_screen.dart` |
| `/reset-password` | `ResetPasswordUpdateScreen` | `lib/features/auth/view/reset_password_update_screen.dart` |
| `/main` | `MainNavigationScreen` | `lib/app/main_navigation_screen.dart` |
| `/home` | `HomeScreen` | `lib/features/home/view/home_screen.dart` |
| `/dashboard` | `DashboardScreen` | `lib/features/dashboard/view/dashboard_screen.dart` |
| `/categories` | `CategoriesScreen` | `lib/features/categories/view/categories_screen.dart` |
| `/favorites` | `FavoritesScreen` | `lib/features/favorites/routes/favorites_routes.dart`, `lib/features/favorites/view/favorites_screen.dart` |
| `/saved` | `SavedTasksScreen` | `lib/features/saved/routes/saved_routes.dart`, `lib/features/saved/view/saved_tasks_screen.dart`; helper exists, but it is not currently registered in `lib/main.dart` route resolution |

## Deep-Link UI Routes

Deep-link handlers are not normal screens, but they create visible loading, error, or detail-route transitions and must be included in redesign and QA planning.

| Entity | Handler file | UI surfaces affected |
| --- | --- | --- |
| Booking | `lib/features/booking/services/booking_deep_link_handler.dart` | Loading dialog and booking details route; current handler rethrows failures without local not-found feedback |
| Task / offer | `lib/features/tasks/services/task_deep_link_handler.dart` | Registers `task` and `offer`; loading dialog, task details route, task-not-found SnackBar |
| Chat | `lib/features/chat/services/chat_deep_link_handler.dart` | Loading dialog, chat route, failed/unsupported feedback via `DeepLinkService` |
| Work item | `lib/features/work/services/work_deep_link_handler.dart` | Directly pushes `WorkItemDetailsScreen` or `DirectOfferDetailsScreen`; destination screen owns loading/error UI |
| Direct offer | `lib/features/direct_offers/services/direct_offer_deep_link_handler.dart` | Directly pushes `DirectOfferDetailsScreen`; destination screen owns loading/error UI |
| Profile | `lib/features/profile/services/profile_deep_link_handler.dart` | Public profile route; destination screen owns the `User not found` state |
| Generic deep-link fallback | `lib/core/services/deep_link_service.dart` | Notification/activity routing fallback SnackBars for missing task-request metadata, unsupported entity types, and failed entity opening |

## Core Shared UI Components

| Surface | File(s) | Used for |
| --- | --- | --- |
| Buttons | `lib/core/widgets/app_button.dart`, `lib/core/widgets/app_styled_button.dart`, `lib/core/widgets/circle_icon_button.dart`, `lib/core/widgets/scale_button.dart` | Primary actions, icon actions, pressed-state affordances |
| Inputs | `lib/core/widgets/app_text_field.dart` | Shared text input styling and validation |
| Cards and surfaces | `lib/core/widgets/app_card.dart`, `lib/core/widgets/app_card_container.dart` | Reusable card layout and feature containers |
| Status indicators | `lib/core/widgets/status_badge.dart`, `lib/core/widgets/skeleton_loader.dart`, `lib/core/widgets/skeleton_card.dart`, `lib/core/widgets/skeleton_card_extended.dart` | Status pills, loading skeletons, empty/loading states |
| Media | `lib/core/widgets/signed_avatar.dart`, `lib/core/widgets/signed_image.dart`, `lib/core/widgets/fullscreen_image_viewer.dart` | Private/public image rendering and full-screen image preview |
| Navigation helpers | `lib/core/widgets/sliver_tab_bar_delegate.dart`, `lib/core/widgets/custom_bottom_nav_bar.dart` | Sliver tab pinning and bottom navigation |
| Blocking loader helper | `lib/core/utils/loading_utils.dart` | Shared modal barrier and spinner used while opening chat, booking status updates, task context, and profile conversations |
| Route and motion helpers | `lib/core/utils/transitions/custom_route_transitions.dart`, `lib/core/utils/app_animations.dart` | Shared route transitions plus production FAB press/rotation animation widgets |

## Feature Surface Inventory

### Auth And Account Access

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Login | `lib/features/auth/view/login_screen.dart` | Email/password form, forgot-password link, sign-up action, auth error feedback |
| Signup | `lib/features/auth/view/signup_screen.dart` | Full name/email/password/confirm form, password strength and requirements, disabled-signup notice, validation and auth feedback |
| Forgot password | `lib/features/auth/view/forgot_password_screen.dart` | Reset request form, success state, email feedback |
| Reset password update | `lib/features/auth/view/reset_password_update_screen.dart` | New-password form and token failure states |
| Auth inline validation surfaces | `lib/features/auth/view/login_screen.dart`, `lib/features/auth/view/signup_screen.dart`, `lib/features/auth/view/reset_password_update_screen.dart` | Inline validation, shake feedback, password requirements/strength, disabled-signup notice, reset success countdown |
| Account restricted | `lib/features/auth/view/account_restricted_screen.dart` | Reason panel, contact-support action, email-launch fallback SnackBar |
| Maintenance | `lib/features/auth/view/maintenance_screen.dart` | App-blocking maintenance state |
| Update required | `lib/features/auth/view/update_required_screen.dart` | Force-update state, app-store launch, clipboard fallback SnackBar |

### Home, Discovery, Categories, Search, Favorites, And Saved

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Home feed | `lib/features/home/view/home_screen.dart` | Feed states, filter entry, task cards, signed media, refresh/empty/error states |
| Home discovery mode tabs | `lib/features/home/view/home_screen.dart` | `_HomeDiscoveryMode` chips for All Work, Bookings, and Tenders; changes feed filtering and empty-state copy |
| Home task details entry | `lib/features/home/view/home_screen.dart` | `TaskCard.onTap` pushes `TaskDetailsScreen` with `MaterialPageRoute` |
| Home filters sheet | `lib/features/home/view/widgets/filters_modal.dart` | Draggable sheet with sort, budget range, delivery time, seller level, reset, and apply controls |
| Categories | `lib/features/categories/view/categories_screen.dart` | Searchable category grid, skeleton loading, empty/error states; category taps currently log only |
| Search | `lib/features/search/view/search_screen.dart` | Search input, Find Work/Find Talent tabs, task result cards, profile result cards, loading/error/empty/no-result states |
| Search mode tabs | `lib/features/search/view/search_screen.dart` | Find Work / Find Talent segmented tabs, task/profile loading states, error, initial empty, and no-result states |
| Search result profile card | `lib/features/search/view/widgets/search_result_profile_card.dart` | Profile preview row used inside search |
| Favorites | `lib/features/favorites/view/favorites_screen.dart` | Favorite freelancers, empty/error states, sign-in/start-chat/remove SnackBars |
| Favorites chat entry and feedback | `lib/features/favorites/view/favorites_screen.dart`, `lib/features/favorites/view/widgets/favorite_card.dart` | Favorite card/card button starts chat, pushes `ChatScreen`, and shows sign-in/start-chat/remove SnackBars |
| Favorite card | `lib/features/favorites/view/widgets/favorite_card.dart` | Favorite freelancer row/card action surface |
| Saved tasks | `lib/features/saved/view/saved_tasks_screen.dart` | Saved task list, empty/error states, task detail push, and empty CTA reset to `/main` |
| Saved task details entry | `lib/features/saved/view/saved_tasks_screen.dart` | Saved task list opens `TaskDetailsScreen`; empty CTA resets to `/main` |
| Saved task tile | `lib/features/saved/view/widgets/saved_task_tile.dart` | Saved task row action surface |

### Tasks, Tenders, Requests, And Proposals

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Create task | `lib/features/tasks/view/create_task_screen.dart` | Tender/booking setup, images, category, validation, submit feedback |
| Task details | `lib/features/tasks/view/task_details_screen.dart` | Task header, media, bids/booking context, owner actions, report reason dialog |
| Tenders | `lib/features/tasks/view/tenders_screen.dart` | Search field, filter state, tender cards, reset search behavior, empty copy `No active tenders` |
| Tender payment | `lib/features/tasks/view/tender_payment_screen.dart` | Payment summary, payment action, success SnackBar, inline error/unavailable/deadline states |
| Requests list | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | Offer list, non-tender guard `Offers are only available for tender-type tasks.`, expired-bid popup filter menu, owner share sheet, submit-offer FAB, loading/empty/error/filter states |
| Requests share sheet | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | `_showShareOptions`; owner empty-state Share Task bottom sheet, copy-link SnackBar |
| Submit request sheet | `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | Bottom sheet for freelancer bid/request submission |
| Request award dialog | `lib/features/tasks/view/widgets/requests/request_award_dialog.dart` | Award confirmation, price comparison, deadline, risk acknowledgment, price mismatch dialog |
| Request tile | `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | Bid/request card actions, confirm/favorite/feedback surfaces |
| Proposal list | `lib/features/proposals/view/proposals_list_screen.dart` -> `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | Proposals compatibility re-export; implementation is `RequestsListScreen` |
| Proposal payment | `lib/features/proposals/view/proposal_payment_screen.dart` -> `lib/features/tasks/view/tender_payment_screen.dart` | Proposals compatibility re-export; opened through `openProposalPayment` route helper |
| Proposal payment route helper | `lib/features/proposals/routes/proposal_payment_route.dart` | Pushes tender payment flow with proposal payment summary wiring |
| Proposal details modal | `lib/features/proposals/view/proposal_details_modal.dart` | Deprecated/orphaned modal; no current lib/test call sites found during 2026-05-13 inventory scan |
| Submit proposal sheet | `lib/features/proposals/view/widgets/submit_proposal_sheet.dart` -> `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | Proposals compatibility re-export; implementation is `showSubmitRequestSheet` |
| Proposal tile | `lib/features/proposals/view/widgets/proposal_tile.dart` -> `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | Proposals compatibility re-export; implementation is `RequestTile` |
| Task cards | `lib/features/tasks/view/widgets/task_card.dart`, `lib/features/tasks/view/widgets/tender_task_card.dart`, `lib/features/tasks/view/widgets/booking_task_card.dart`, `lib/features/tasks/view/widgets/discovery_task_sliver.dart` | Reusable discovery/list task surfaces |
| Dashboard offer card | `lib/features/tasks/view/widgets/dashboard_offer_card.dart` | Offer/payment action card used in dashboard/inbox contexts; accept/reject/withdraw/release/refund callbacks |
| Offer expiration countdown | `lib/features/tasks/view/widgets/expiration_countdown.dart` | Bid/payment deadline countdown, urgency color states, `ExpirationBadge` |
| Payment status and logistics | `lib/features/tasks/view/widgets/payment_status_badge.dart`, `lib/features/tasks/view/widgets/booking_logistics_section.dart`, `lib/features/tasks/view/widgets/task_concept_section.dart` | Shared task-detail sections |

### Booking And Payment

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Bookings discovery | `lib/features/booking/view/bookings_discovery_screen.dart` | Search field, booking/service discovery list, empty/error states |
| Bookings list | `lib/features/booking/view/bookings_list_screen.dart` | TabBar/TabBarView, status filter bar, inline refresh error banner, booking state cards |
| Booking details | `lib/features/booking/view/booking_details_screen.dart` | Status header, requester/provider sections, timeline, legacy slot warning, provider awaiting-payment state, approve/release disabled/checking states, actions, report issue reason dialog |
| Payment checkout | `lib/features/booking/view/payment_checkout_screen.dart` | Draft cleanup state, payment launch, success/error states |
| Payment method | `lib/features/booking/view/payment_method_screen.dart` | Legacy demo payment form; no current lib/test call sites found during 2026-05-13 inventory scan |
| Payment return | `lib/features/booking/view/payment_return_screen.dart` | Success/failure return status and next actions |
| Web payment callback startup surface | `lib/main.dart`, `lib/features/booking/view/payment_return_screen.dart` | Startup home builder can render `PaymentReturnScreen` for explicit or pending web payment callbacks |
| Payment webview | `lib/features/booking/view/payment_webview_screen.dart` | WebView loading/error/retry, success/failure path handling, back-navigation prompt |
| Booking card | `lib/features/booking/view/widgets/booking_card.dart` | Booking list card, date/payment/status chips |
| Dashboard booking card | `lib/features/booking/view/widgets/dashboard_booking_card.dart` | Booking summary inside dashboard contexts |
| Payment order summary | `lib/features/booking/view/widgets/payment_order_summary_card.dart` | Reusable payment summary card |

### Chat, Messages, Offers, And Attachments

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Messages | `lib/features/chat/view/messages_screen.dart` | Conversation search, online row, conversation list, delete confirmation dialog |
| Messages controls and states | `lib/features/chat/view/messages_screen.dart` | Search toggle/bar, Received/Sent segmented control, online-now row, empty/no-results/loading states, chat-return unread-badge refresh |
| Chat | `lib/features/chat/view/chat_screen.dart` | Message list, composer, attachment actions, popup menu, reason dialogs, offer actions |
| Chat message interactions | `lib/features/chat/view/chat_screen.dart` | Long-press Copy/Reply bottom sheet, swipe-to-reply, reply preview bar, copied/error SnackBars |
| Chat report menu and dialogs | `lib/features/chat/view/chat_screen.dart` | Overflow menu, report conversation/user reason dialogs, report result SnackBars |
| Chat composer and transient controls | `lib/features/chat/view/chat_screen.dart` | Attachment action, send loading state, typing indicator, scroll-to-latest FAB, send/attachment failure SnackBars |
| Conversation tile | `lib/features/chat/view/widgets/conversation_list_tile.dart` | Conversation row, unread state, participant/avatar state |
| Message bubble | `lib/features/chat/view/widgets/message_bubble.dart` | Text, emoji-only rendering, reply quote, sent/delivered/read status icons, link tap handling, file/link semantics, feedback on launch failure |
| Offer message bubble | `lib/features/chat/view/widgets/offer_message_bubble.dart` | Accept/decline/cancel/deliver/complete action surface plus lifecycle chips: `Pending Payment`, `Paid`, `Completed • Paid`, accepted/canceled/declined, and `Pending Response` |
| Create offer sheet | `lib/features/chat/view/widgets/create_offer_sheet.dart` | Bottom sheet for direct offer creation |
| Chat context widget | `lib/features/chat/view/widgets/chat_context_widget.dart` | Task/profile context header and navigation feedback |
| Attachment tile | `lib/features/chat/attachments/widgets/attachment_message_tile.dart` | Signed URL loading, retry/error state, media preview, hero transition |
| Fullscreen attachment preview | `lib/core/widgets/fullscreen_image_viewer.dart` | Image zoom/preview route used by attachment/media surfaces |

### Dashboard

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Dashboard shell | `lib/features/dashboard/view/dashboard_screen.dart` | TabBar/TabBarView, role/settings bottom sheet, dashboard app bar |
| Overview tab | `lib/features/dashboard/view/tabs/overview_tab.dart` | Summary cards, next actions, activity preview |
| Bookings tab | `lib/features/dashboard/view/tabs/bookings_tab.dart` | Booking dashboard lists and state cards |
| Work tab | `lib/features/dashboard/view/tabs/work_tab.dart` | Nested TabBar/TabBarView for work states |
| Inbox tab | `lib/features/dashboard/view/tabs/inbox_tab.dart` | Inbox/action queues, awarding/payment/withdrawal entry points |
| Inbox mode toggle | `lib/features/dashboard/view/tabs/inbox_tab.dart` | Received/Sent segmented mode; Sent mode disabled placeholder for missing dashboard contract; award/pay SnackBars |
| Wallet tab | `lib/features/dashboard/view/tabs/wallet_tab.dart` | Embedded wallet snapshot and recent wallet state |
| Dashboard widgets | `lib/features/dashboard/view/widgets/` | Counters grid, next actions, work item card, activity feed preview, insufficient funds dialogs |
| Dashboard payment/action feedback | `lib/features/dashboard/view/tabs/inbox_tab.dart`, `lib/features/dashboard/view/tabs/work_tab.dart`, `lib/features/dashboard/view/widgets/next_actions_list.dart` | Proposal payment launcher, post-payment return refresh, insufficient-balance dialogs, cancel-award success/error SnackBars, ErrorMapper SnackBars |
| Dashboard activity deep-link preview | `lib/features/dashboard/view/widgets/activity_feed_preview.dart` | Activity timeline rows route through `DeepLinkService.handleActivity`; grouped Today/Yesterday/Earlier states, skeleton and empty states |

### Profile, Portfolio, Services, And Settings

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Profile | `lib/features/profile/view/profile_screen.dart` | Own profile overview, portfolio/services/settings entry points |
| Public profile | `lib/features/profile/view/public_profile_screen.dart` | `User not found` state, TabBar/TabBarView, report user reason dialog, public portfolio/services/reviews |
| Public profile action bar | `lib/features/profile/view/public_profile_screen.dart` | Sticky Message/Hire bar, create/open conversation route, login/self/error SnackBars |
| Public profile sections | `lib/features/profile/view/widgets/public_profile/public_profile_header.dart`, `lib/features/profile/view/widgets/public_profile/public_profile_stats.dart`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart`, `lib/features/profile/view/widgets/public_profile/public_profile_reviews.dart` | Header, stats, portfolio tab content, and reviews tab content |
| Edit profile | `lib/features/profile/view/edit_profile_screen.dart` | Profile form, skill add dialog, avatar flow |
| Settings | `lib/features/profile/view/settings_screen.dart` | Settings groups, logout confirmation dialog, account/app feedback SnackBars |
| Profile avatar widget | `lib/features/profile/view/widgets/profile_avatar_widget.dart` | Signed avatar image surface with upload/update feedback |
| Profile preview modal | `lib/features/profile/view/widgets/profile_preview_modal.dart` | Draggable bottom sheet embedding `PublicProfileScreen` |
| Portfolio screen | `lib/features/portfolio/view/portfolio_screen.dart` | Portfolio grid/list, pull-to-refresh, infinite-scroll loading tiles, add/details/edit sheets, long-press delete confirmation, success/failure SnackBars |
| Portfolio tile and placeholder | `lib/features/portfolio/view/widgets/portfolio_tile.dart`, `lib/features/portfolio/view/widgets/image_placeholder.dart` | Grid item, details-sheet entry, long-press delete entry, image fallback initials |
| Manage portfolio | `lib/features/profile/view/manage_portfolio_screen.dart` | Portfolio list, Add Item FAB, add/edit AlertDialog, image upload picker state, swipe delete and confirmation dialog |
| Add portfolio sheet | `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart` | Portfolio creation bottom sheet |
| Edit portfolio sheet | `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart` | Portfolio editing bottom sheet |
| Portfolio details sheet | `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart` | Portfolio item detail bottom sheet |
| My services | `lib/features/profile/view/my_services_screen.dart` | Freelancer service management list |
| Service card | `lib/features/services/view/widgets/service_card.dart` | Reusable service card used in profile/service contexts |

### Notifications

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Notification badge button | `lib/features/notifications/view/widgets/notification_badge_button.dart` | App-shell icon, unread badge, selected-notification routing |
| Notifications modal | `lib/features/notifications/view/notifications_modal.dart` | Bottom sheet, notification list, mark-all-read feedback |
| Notifications modal states | `lib/features/notifications/view/notifications_modal.dart` | Skeleton loading list, empty state, error/retry state, close action |
| Notification tile | `lib/features/notifications/view/widgets/notification_tile.dart` | Notification row/card action surface |

### Wallet

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Wallet screen | `lib/features/wallet/view/wallet_screen.dart` | Standalone wallet surface |
| Wallet dashboard | `lib/features/wallet/view/wallet_dashboard_screen.dart` | Standalone widget/screen file exists, but current route/reference scan found no app route registration |
| Wallet shared body | `lib/features/wallet/view/widgets/wallet_shared_body.dart` | Shared wallet layout body |
| Wallet shared states | `lib/features/wallet/view/widgets/wallet_shared_body.dart` | Loading card, unavailable/error retry card, insights tiles, withdrawals coming-soon action card |
| Wallet hero card | `lib/features/wallet/view/widgets/wallet_hero_card.dart` | Balance hero summary |
| Wallet snapshot card | `lib/features/wallet/view/widgets/wallet_snapshot_card.dart` | Action pills, disabled action states, snapshot metrics |
| Wallet timeline card | `lib/features/wallet/view/widgets/wallet_timeline_card.dart` | Wallet activity/timeline surface |

### Work, Management, And Order Operations

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Work item details | `lib/features/work/view/work_item_details_screen.dart` | TabBar/TabBarView, status sections, loading/error/no-details states, pending-payment actions, chat route, payment route, dispute reason dialog and SnackBars |
| Work item detail states and routes | `lib/features/work/view/work_item_details_screen.dart` | Loading/error/no-details states, pending-payment actions, chat route, payment route with return refresh, dispute SnackBars |
| Submit delivery modal | `lib/features/work/view/widgets/submit_delivery_modal.dart` | Bottom sheet/modal for delivery submission |
| Review delivery modal | `lib/features/work/view/widgets/review_delivery_modal.dart` | Delivery approval/revision review modal |
| Request extension modal | `lib/features/work/view/widgets/request_extension_modal.dart` | Deadline extension request modal |
| Work item booking details | `lib/features/work/view/widgets/work_item_booking_details.dart` | Booking/work contract detail section |
| Work item bottom actions | `lib/features/work/view/widgets/work_item_bottom_actions.dart` | Contextual action bar for work states |
| Work item guards | `lib/features/work/view/widgets/work_item_guard_widgets.dart` | Guard banners and state feedback |
| Order management panel | `lib/features/management/view/order_management_panel.dart` | Management shell/panel for work operations |
| Order management note composer | `lib/features/management/view/order_management_panel.dart` | Timeline loading/error/empty states, retry, public/private note toggle, send spinner, action error text |
| Order management section | `lib/features/management/view/widgets/order_management_section.dart` | Management subsection surface |
| Work log tile | `lib/features/management/view/widgets/work_log_tile.dart` | Work log entry row/card, private-note marker |

### Direct Offers

| Surface | File | Subsurfaces / related UI |
| --- | --- | --- |
| Direct offer details | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Offer lifecycle, confirm action dialog, report reason dialog, dispute guard banners |
| Direct offer payment route | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | QiCard web browser launch, in-app `PaymentWebViewScreen`, payment completion/error SnackBars |

### Modules Without Dedicated User Screens

| Module | Current UI status |
| --- | --- |
| `lib/features/safety/` | Service/viewmodel support only; visible report/dispute UI currently lives in task, booking, profile, work, and direct-offer surfaces |
| `lib/features/orders/` | No dedicated `view/` screen in the current tree; order/work management UI is under `management` and `work` |
| `lib/features/services/` | Reusable `ServiceCard` widget only; service management surface currently lives under profile |

## SnackBar And Transient Feedback Inventory

This section is intentionally separate from the screen inventory. SnackBars, inline banners, loading cards, empty states, disabled states, dialogs, and sheets are visual UI surfaces and must be included in redesign, QA, and accessibility passes.

Last deep scan: 2026-05-13 with `rg "ScaffoldMessenger\.of\(|showSnackBar\(|SnackBar\(" lib/main.dart lib/app lib/core/widgets lib/features` plus dialog/sheet/menu/state scans.

### SnackBars

| Area | File | Trigger / surface | User-facing copy or source |
| --- | --- | --- | --- |
| Auth | `lib/features/auth/view/account_restricted_screen.dart` | Support email launch fallback | `Could not open email. Please contact $_supportEmail.` |
| Auth | `lib/features/auth/view/update_required_screen.dart` | Store launch and clipboard fallback | `Could not open the store. Update link copied to clipboard. Please paste it in your browser.` or `Could not open the store. Please visit $fallback to update.` |
| Core deep links | `lib/core/services/deep_link_service.dart` | Generic notification/activity routing failures | `Cannot open this notification.`, `This item type is not supported.`, or `Failed to open item. Please try again.` |
| Booking | `lib/features/booking/view/booking_details_screen.dart` | Missing task data blocks dispute | `l10n.bookingCannotDisputeMissingTask` |
| Booking | `lib/features/booking/view/booking_details_screen.dart` | Dispute submission result | `l10n.disputeSubmitted`, `vm.error`, or `l10n.disputeFailed` |
| Booking | `lib/features/booking/view/booking_details_screen.dart` | Status update result | `l10n.statusUpdated` or `l10n.statusUpdateFailed` |
| Payment | `lib/features/booking/view/payment_webview_screen.dart` | External payment URL launch failure | `Could not open payment link` |
| Chat | `lib/features/chat/view/chat_screen.dart` | Image attachment send failure | `Failed to send image` |
| Chat | `lib/features/chat/view/chat_screen.dart` | Create-offer validation | `Please enter a valid price` |
| Chat | `lib/features/chat/view/chat_screen.dart` | Create-offer failure | `Could not create offer. Please try again.` |
| Chat | `lib/features/chat/view/chat_screen.dart` | Message send failure | `Message could not be sent. Please try again.` |
| Chat | `lib/features/chat/view/chat_screen.dart` | Message context action | `Message copied` |
| Chat | `lib/features/chat/view/chat_screen.dart` | Offer accepted from chat | `Offer accepted. Complete payment from your Dashboard.` |
| Chat | `lib/features/chat/view/chat_screen.dart` | Offer accept failure | `Could not accept offer. Please try again.` |
| Chat | `lib/features/chat/view/chat_screen.dart` | Conversation/user report result | `Report submitted.`, `vm.error`, or `Report failed.` |
| Chat | `lib/features/chat/view/messages_screen.dart` | Delete/archive conversation failure | `Could not archive this conversation. Please try again.` |
| Chat | `lib/features/chat/view/widgets/chat_context_widget.dart` | Task context loading failure | `Could not load task details.` |
| Chat | `lib/features/chat/view/widgets/chat_context_widget.dart` | Task context route failure | `Could not open task details. Please try again.` |
| Chat | `lib/features/chat/view/widgets/create_offer_sheet.dart` | Create-offer empty form | `Please fill in title and price` |
| Chat | `lib/features/chat/view/widgets/create_offer_sheet.dart` | Create-offer invalid price | `Price must be a valid positive number` |
| Chat | `lib/features/chat/view/widgets/create_offer_sheet.dart` | Create-offer invalid delivery days | `Delivery days must be a valid positive number` |
| Chat | `lib/features/chat/view/widgets/message_bubble.dart` | Link launch failure | `Could not open link.` |
| Dashboard | `lib/features/dashboard/view/tabs/inbox_tab.dart` | Award failure | `result?['error']` or `Failed to award offer` |
| Dashboard | `lib/features/dashboard/view/tabs/inbox_tab.dart` | Award exception fallback | `Error: $e` |
| Dashboard | `lib/features/dashboard/view/tabs/work_tab.dart` | Pay/start action failures | `ErrorMapper.map(e)` |
| Dashboard | `lib/features/dashboard/view/tabs/work_tab.dart` | Cancel award success/failure | `Award cancelled. Task is open again.` or `ErrorMapper.map(e)` |
| Dashboard | `lib/features/dashboard/view/widgets/next_actions_list.dart` | Primary/secondary action failures | `ErrorMapper.map(e)` |
| Dashboard | `lib/features/dashboard/view/widgets/next_actions_list.dart` | Cancel award success/failure | `Award cancelled. Task is open again.` or `ErrorMapper.map(e)` |
| Direct offers | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Payment start failure | `result.error` or `Could not start payment` |
| Direct offers | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Browser payment handoff | `Complete payment in the browser. Return here and refresh the offer.` |
| Direct offers | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Payment page launch failure | `Could not open payment page.` |
| Direct offers | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Payment return success | `Payment completed.` |
| Direct offers | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Cancel offer failure | `Something went wrong. Please try again.` |
| Direct offers | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Delivery marked | `Work marked as delivered.` |
| Direct offers | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Delivery/release failures | `ErrorMapper.map(e)` |
| Direct offers | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Payment release success | `Payment released.` |
| Direct offers | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Dispute result | `Dispute submitted.`, `safetyVm.error`, or `Dispute failed.` |
| Favorites | `lib/features/favorites/view/favorites_screen.dart` | Chat blocked while signed out | `Please sign in to start chat` |
| Favorites | `lib/features/favorites/view/favorites_screen.dart` | Chat start failure | `Could not start chat. Please try again.` |
| Favorites | `lib/features/favorites/view/favorites_screen.dart` | Remove favorite success/failure | `Removed from favorites`, `vm.error`, or `Could not remove. Please try again.` |
| Notifications | `lib/features/notifications/view/notifications_modal.dart` | Mark all read success/failure | `All marked as read` or `Could not mark notifications as read. Please try again.` |
| Portfolio | `lib/features/portfolio/view/portfolio_screen.dart` | Add portfolio result | `Portfolio item added` |
| Portfolio | `lib/features/portfolio/view/portfolio_screen.dart` | Delete portfolio result | `Deleted successfully` or `Delete failed. Please try again.` |
| Portfolio | `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart` | Image picker failure | `Failed to pick image. Please try again.` |
| Portfolio | `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart` | Create portfolio failure | `widget.controller.error` or `Failed to create item. Please try again.` |
| Portfolio | `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart` | Edit portfolio result | `Updated successfully`, `widget.controller.error`, `Update failed. Please try again.`, or `An error occurred. Please try again.` |
| Portfolio | `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart` | Detail-sheet delete result | `Deleted successfully` or `Delete failed. Please try again.` |
| Profile | `lib/features/profile/view/widgets/profile_avatar_widget.dart` | Avatar upload failure | `controller.avatarUploadError` |
| Profile | `lib/features/profile/view/edit_profile_screen.dart` | Save profile failure | `Failed to save profile. Please try again.` |
| Profile | `lib/features/profile/view/manage_portfolio_screen.dart` | Manage portfolio upload failure | `vm.portfolioUploadError` |
| Profile | `lib/features/profile/view/my_services_screen.dart` | Placeholder service actions | `Edit service coming soon` and `Create service coming soon` |
| Profile | `lib/features/profile/view/profile_screen.dart` | Public profile blocked while signed out | `Sign in to view your public profile.` |
| Profile | `lib/features/profile/view/public_profile_screen.dart` | Share placeholder | `Share coming soon` |
| Profile | `lib/features/profile/view/public_profile_screen.dart` | Message action blocked/failure | `You must be logged in to message.`, `You cannot message yourself.`, or `Error starting chat: $e` |
| Profile | `lib/features/profile/view/public_profile_screen.dart` | Report user result | `Report submitted.`, `vm.error`, or `Report failed.` |
| Profile | `lib/features/profile/view/settings_screen.dart` | Settings placeholders | `Notification settings coming soon`, `Language settings coming soon`, and `Request withdrawal — coming soon` |
| Tasks | `lib/features/tasks/services/task_deep_link_handler.dart` | Missing deep-linked task | `Task not found` |
| Tasks | `lib/features/tasks/view/create_task_screen.dart` | Create-task validation/failure | `Please fill in title and description` or `Error: $e` |
| Tasks | `lib/features/tasks/view/task_details_screen.dart` | Report task result | `Report submitted.`, `vm.error`, or `Report failed.` |
| Tasks | `lib/features/tasks/view/task_details_screen.dart` | Account/chat guards | `Your account is restricted. Please contact support.`, `You must be logged in to chat.`, or `Error starting chat: $e` |
| Payment | `lib/features/tasks/view/tender_payment_screen.dart` | Tender payment success | `Payment successful! Work is now active.` |
| Requests | `lib/features/tasks/view/widgets/requests/request_award_dialog.dart` | Award failure/already awarded | `Failed to award offer. Please refresh and try again.`, `This offer has already been awarded.`, or `Award failed. Please refresh and try again.` |
| Requests | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | Share sheet copy action | `Link copied to clipboard` |
| Requests | `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | Pre-sheet guard failure | `vm.guardError` or `Unable to load task.` |
| Requests | `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | Submit/replace result | `Bid replaced successfully`, `Bid submitted successfully`, `vm.submitError`, or `Failed to submit bid` |
| Requests | `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | Cancel award result | `Award cancelled successfully` |
| Requests | `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | Favorite result | `Added to favorites`, `Already in favorites`, `vm.error`, or `Could not add. Please try again.` |
| Work | `lib/features/work/view/widgets/review_delivery_modal.dart` | Revision blocked/failure | `widget.getRevisionError?.call()` |
| Work | `lib/features/work/view/work_item_details_screen.dart` | Cancel award success/failure | `Award cancelled. Task is open again.` or `ErrorMapper.map(e)` |
| Work | `lib/features/work/view/work_item_details_screen.dart` | Booking dispute blocked | `This booking cannot be disputed because task data is missing.` |
| Work | `lib/features/work/view/work_item_details_screen.dart` | Dispute result | `Dispute submitted.`, `safetyVm.error`, or `Dispute failed.` |
| Work | `lib/features/work/view/work_item_details_screen.dart` | Chat route failure | `Could not open conversation` or `Failed to open chat. Please try again.` |

### Dialogs, Sheets, Menus, And Blocking Loaders

| Type | File | Surface / contents |
| --- | --- | --- |
| Loading dialog | `lib/features/booking/services/booking_deep_link_handler.dart` | Booking deep-link route loading before booking details push |
| Loading dialog | `lib/features/chat/services/chat_deep_link_handler.dart` | Chat deep-link route loading before chat push |
| Loading dialog | `lib/features/tasks/services/task_deep_link_handler.dart` | Task/offer deep-link route loading before task details push |
| Loading helper | `lib/core/utils/loading_utils.dart` | Shared modal barrier and `CircularProgressIndicator`; current consumers are booking chat/status update, chat context task, public profile message, task chat, and work-item chat |
| Loading dialog | `lib/features/chat/view/widgets/chat_context_widget.dart` | `LoadingUtils` dialog while loading task context |
| Loading dialog | `lib/features/booking/view/booking_details_screen.dart` | `LoadingUtils` dialog while starting booking chat and updating booking status |
| Loading dialog | `lib/features/profile/view/public_profile_screen.dart` | `LoadingUtils` dialog while creating or opening a conversation from public profile |
| Loading dialog | `lib/features/tasks/view/task_details_screen.dart` | `task_chat` loader while starting a conversation |
| Loading dialog | `lib/features/work/view/work_item_details_screen.dart` | `work_item_chat` loader while opening a work conversation |
| Sheet-like route | `lib/app/main_navigation_screen.dart`, `lib/core/utils/transitions/custom_route_transitions.dart`, `lib/features/tasks/view/create_task_screen.dart` | Create-task FAB opens the bottom-sheet create/edit flow through `SlinePageRoute.modalSheet` |
| Sheet | `lib/features/home/view/home_screen.dart`, `lib/features/home/view/widgets/filters_modal.dart` | Home filters with sort, budget range, delivery time, seller level, reset, and apply controls |
| Sheet | `lib/features/notifications/view/notifications_modal.dart` | Notifications bottom sheet with mark-all-read, loading, empty, error, and list states |
| Sheet | `lib/features/dashboard/view/dashboard_screen.dart` | Dashboard settings sheet with `Dashboard Settings`, role control, `Freelancer`, and `Client` |
| Sheet | `lib/features/chat/view/chat_screen.dart` | Message context sheet with `Copy` and `Reply` actions |
| Sheet | `lib/features/chat/view/widgets/create_offer_sheet.dart` | Create direct offer form, validation feedback, and submit action |
| Sheet | `lib/features/profile/view/widgets/profile_preview_modal.dart` | Draggable public profile preview sheet |
| Sheet | `lib/features/portfolio/view/portfolio_screen.dart` | Add portfolio sheet entry |
| Sheet | `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart` | Portfolio edit sheet |
| Sheet | `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart` | Portfolio detail sheet with delete confirmation entry |
| Sheet | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | Owner share sheet with `Share Task`, `Copy Link`, and share-via action |
| Sheet | `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | Submit/replace request bottom sheet with existing-bid summary, warning banner, upload placeholder, and confirmation dialog |
| Sheet | `lib/features/work/view/work_item_details_screen.dart` | Submit delivery, request extension, and review delivery sheets |
| Dialog | `lib/features/booking/view/booking_details_screen.dart` | Report issue reason dialog |
| Dialog | `lib/features/chat/view/chat_screen.dart` | Report conversation/user reason dialogs |
| Dialog | `lib/features/chat/view/messages_screen.dart` | Delete conversation confirmation |
| Dialog | `lib/features/dashboard/view/tabs/work_tab.dart`, `lib/features/dashboard/view/widgets/next_actions_list.dart` | Insufficient-balance dialog with add-funds path |
| Dialog | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Cancel offer confirmation and report issue reason dialog |
| Dialog | `lib/features/portfolio/view/portfolio_screen.dart`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart` | Delete portfolio item confirmations |
| Dialog | `lib/features/profile/view/edit_profile_screen.dart` | Add skill dialog |
| Dialog | `lib/features/profile/view/manage_portfolio_screen.dart` | Add/edit portfolio item dialog and delete confirmation |
| Dialog | `lib/features/profile/view/public_profile_screen.dart` | Report user reason dialog |
| Dialog | `lib/features/profile/view/settings_screen.dart` | Support & Safety dialog and logout confirmation |
| Dialog | `lib/features/tasks/view/task_details_screen.dart` | Report task reason dialog |
| Dialog | `lib/features/tasks/view/widgets/requests/request_award_dialog.dart` | Award freelancer confirmation and offer-updated price mismatch dialog |
| Dialog | `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | Replace-bid confirmation with warning banner |
| Dialog | `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | Cancel award confirmation |
| Dialog | `lib/features/work/view/work_item_details_screen.dart` | Work dispute reason dialog |
| Menu | `lib/features/chat/view/chat_screen.dart` | Overflow popup menu: `Report Conversation`, `Report User` |
| Menu | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | Expired-bid popup filter menu |
| Banner | `lib/app/main_navigation_screen.dart` | App-wide runtime config banner; not a `MaterialBanner` |
| Banner | `lib/features/booking/view/bookings_list_screen.dart` | Inline refresh error banner when stale bookings remain visible |
| Banner | `lib/features/booking/view/booking_details_screen.dart` | Booking status CTA banner and dispute guard banner |
| Banner | `lib/features/tasks/view/tender_payment_screen.dart` | Tender unavailable/payment deadline warning banner |
| Banner | `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | Replace-bid warning banner |
| Banner | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Direct-offer dispute guard banner |
| Banner | `lib/features/work/view/work_item_details_screen.dart`, `lib/features/work/view/widgets/work_item_guard_widgets.dart` | Work dispute guard banner and review/report guard states |
| MaterialBanner | None found under `lib/main.dart`, `lib/app`, `lib/core/widgets`, or `lib/features` | Current banners are custom inline widgets or SnackBars |

### Inline Loading, Empty, Error, Disabled, And Micro-State Surfaces

| Area | File(s) | State coverage |
| --- | --- | --- |
| Startup and shell | `lib/main.dart`, `lib/app/main_navigation_screen.dart`, `lib/core/widgets/custom_bottom_nav_bar.dart` | Startup text `SLine is loading...`, tab transitions, scroll-aware FAB, runtime banner, active bottom-nav capsule, label opacity, Messages badge/dot with `99+` cap |
| Core navigation feedback | `lib/core/services/deep_link_service.dart`, `lib/core/utils/loading_utils.dart` | Generic deep-link SnackBars, shared blocking modal barrier, and spinner used by feature route-opening flows |
| Shared buttons | `lib/core/widgets/app_button.dart`, `lib/core/widgets/app_styled_button.dart`, `lib/core/widgets/scale_button.dart` | Loading spinner, disabled opacity, success check flash, error flash, haptic feedback, pointer blocking |
| Shared text fields | `lib/core/widgets/app_text_field.dart` | Password visibility, clear text, character counter, focused/error borders, validation state |
| Shared status/media | `lib/core/widgets/status_badge.dart`, `lib/core/widgets/signed_avatar.dart`, `lib/core/widgets/signed_image.dart`, `lib/core/widgets/fullscreen_image_viewer.dart` | Status tone/icon/pending pulse, avatar shimmer/initials/online dot, signed-image shimmer/error/retry, full-screen image loading/error/caption/drag-to-dismiss |
| Auth | `lib/features/auth/view/login_screen.dart`, `lib/features/auth/view/signup_screen.dart`, `lib/features/auth/view/forgot_password_screen.dart`, `lib/features/auth/view/reset_password_update_screen.dart`, `lib/features/auth/view/maintenance_screen.dart` | Login/signup inline validation, shake feedback, disabled-signup notice, password strength/requirements, forgot-password success, reset-password success/countdown, maintenance retry loading |
| Home/discovery | `lib/features/home/view/home_screen.dart`, `lib/features/home/view/widgets/filters_modal.dart`, `lib/features/tasks/view/widgets/discovery_task_sliver.dart`, `lib/features/tasks/view/tenders_screen.dart` | Discovery mode chips, filter sheet selection states, skeletons, empty states, load-more spinner, `No tasks found`, `No booking services`, `No active tasks`, and `No active tenders` copies |
| Search/categories/favorites/saved | `lib/features/search/view/search_screen.dart`, `lib/features/categories/view/categories_screen.dart`, `lib/features/favorites/view/favorites_screen.dart`, `lib/features/saved/view/saved_tasks_screen.dart` | Search initial/no-result/error states, category skeleton/empty/error, favorite empty/error, saved-task empty/error and empty CTA |
| Task creation/details | `lib/features/tasks/view/create_task_screen.dart`, `lib/features/tasks/view/task_details_screen.dart`, `lib/features/tasks/view/widgets/task_concept_section.dart` | Multi-step `Type`/`Details`/`Review` wizard, tender/booking selected cards, category loading, review preview, report/chat/account guard states |
| Requests/proposals | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart`, `lib/features/tasks/view/widgets/requests/request_award_dialog.dart`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | Request skeletons, non-tender guard, expired filter, empty/filter-empty/error states, replace-mode sheet, upload coming-soon row, award deadline/risk sections, price mismatch, request-tile payment recovery, inline retry/dismiss error |
| Booking/payment | `lib/features/booking/view/bookings_discovery_screen.dart`, `lib/features/booking/view/bookings_list_screen.dart`, `lib/features/booking/view/booking_details_screen.dart`, `lib/features/booking/view/payment_checkout_screen.dart`, `lib/features/booking/view/payment_return_screen.dart`, `lib/features/booking/view/payment_webview_screen.dart`, `lib/features/booking/view/payment_method_screen.dart` | Booking discovery search/semantics, client/provider tabs, filter chips, state cards, legacy slot warning, awaiting-payment provider state, approve/release checking/disabled state, status banners, dispute banners, QiCard/demo checkout variants, success/error/gateway waiting, return terminal states, WebView error/retry/back behavior, legacy form validators |
| Chat/messages | `lib/features/chat/view/messages_screen.dart`, `lib/features/chat/view/chat_screen.dart`, `lib/features/chat/view/widgets/create_offer_sheet.dart`, `lib/features/chat/view/widgets/message_bubble.dart`, `lib/features/chat/view/widgets/offer_message_bubble.dart`, `lib/features/chat/attachments/widgets/attachment_message_tile.dart` | Conversation skeletons, `Received`/`Sent` mode, online row, delete swipe background, empty/no-result states, chat-return unread refresh, chat initial spinner, `Start the conversation`, typing indicator, context banner, composer spinner, reply preview, emoji-only bubbles, reply quotes, read/delivered icons, offer lifecycle chips, attachment skeleton/error/retry/hero preview |
| Dashboard | `lib/features/dashboard/view/dashboard_screen.dart`, `lib/features/dashboard/view/tabs/inbox_tab.dart`, `lib/features/dashboard/view/tabs/work_tab.dart`, `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart`, `lib/features/dashboard/view/widgets/next_actions_list.dart`, `lib/features/dashboard/view/widgets/work_item_card.dart` | Web payment callback recovery, payment route return refresh, role/settings sheet, counter loading/count-up cards, status-colored metric routing, next-action state, work-card progress/status/review alerts and action buttons |
| Notifications | `lib/features/notifications/view/widgets/notification_badge_button.dart`, `lib/features/notifications/view/notifications_modal.dart`, `lib/features/notifications/view/widgets/notification_tile.dart` | Animated unread badge with `9+` cap, modal skeleton/empty/error/retry, unread tile tint/dot/type icon |
| Profile/portfolio/services | `lib/features/profile/view/profile_screen.dart`, `lib/features/profile/view/public_profile_screen.dart`, `lib/features/profile/view/edit_profile_screen.dart`, `lib/features/profile/view/settings_screen.dart`, `lib/features/profile/view/manage_portfolio_screen.dart`, `lib/features/portfolio/view/portfolio_screen.dart`, `lib/features/services/view/widgets/service_card.dart` | Profile loading/error retry, own/public portfolio empty states, settings badges/dark-mode row/logout, public profile tabs/action bar/reporting, edit-profile validation/skill dialog, portfolio pull-to-refresh/infinite loading/delete states, service status badges |
| Wallet | `lib/features/wallet/view/widgets/wallet_shared_body.dart`, `lib/features/wallet/view/widgets/wallet_hero_card.dart`, `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`, `lib/features/wallet/view/widgets/wallet_timeline_card.dart` | `Loading wallet`, `Wallet unavailable`, retry, disabled `Withdraw soon`/`Top up soon`, `Coming Soon`, disabled `Request withdrawal`, composition bar, insight tiles, `No wallet activity yet` |
| Work/management | `lib/features/work/view/work_item_details_screen.dart`, `lib/features/work/view/widgets/submit_delivery_modal.dart`, `lib/features/work/view/widgets/request_extension_modal.dart`, `lib/features/work/view/widgets/review_delivery_modal.dart`, `lib/features/work/view/widgets/work_item_guard_widgets.dart`, `lib/features/management/view/order_management_panel.dart`, `lib/features/management/view/widgets/work_log_tile.dart` | Work loading/error/no-details, tabs `Overview`/`Extensions`/`Contract`, empty request/contract states, delivery/extension/review sheets, `No revisions left.`, dispute guards, management timeline loading/error/empty, note privacy toggle, send spinner, private-note badge |
| Direct offers | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Loading/error/not-found state, `CUSTOM OFFER` header, status pill, `PENDING PAYMENT`, price zone, cancel/report dialogs, payment browser handoff, dispute banner, approve/release guard states |

## Full Visual File Coverage Index

This index intentionally lists every current app-shell, core navigation/feedback helper, core widget, feature `view/`, feature visual `widgets/`, feature `routes/`, and feature deep-link handler file that can create or route visual UI. Keep it exact so broad redesign scans can diff this section against the filesystem.

### App And Core Widgets

| File | Visual responsibility |
| --- | --- |
| `lib/main.dart` | App root, startup shell, named route resolution, splash screen, auth listener, payment callback startup surface |
| `lib/app/main_navigation_screen.dart` | Authenticated app shell, tab host, FAB, runtime banner, bottom navigation placement |
| `lib/core/navigation/main_nav_destinations.dart` | Bottom-navigation destination model and tab metadata |
| `lib/core/services/deep_link_service.dart` | Generic notification/activity deep-link routing and fallback SnackBars |
| `lib/core/utils/app_animations.dart` | Legacy production FAB press/rotation animation widgets and deprecated motion constants |
| `lib/core/utils/loading_utils.dart` | Shared blocking overlay loader with modal barrier and spinner |
| `lib/core/utils/transitions/custom_route_transitions.dart` | Shared page route transitions including forward push, modal sheet, fade, and deprecated wrappers |
| `lib/core/widgets/app_button.dart` | Shared primary/secondary/loading button control |
| `lib/core/widgets/app_card.dart` | Shared card surface |
| `lib/core/widgets/app_card_container.dart` | Shared card/container shell |
| `lib/core/widgets/app_styled_button.dart` | Shared styled action button |
| `lib/core/widgets/app_text_field.dart` | Shared input control |
| `lib/core/widgets/circle_icon_button.dart` | Shared circular icon action |
| `lib/core/widgets/custom_bottom_nav_bar.dart` | Bottom navigation and nav item visual states |
| `lib/core/widgets/fullscreen_image_viewer.dart` | Full-screen signed/public image preview route and drag-to-dismiss wrapper |
| `lib/core/widgets/scale_button.dart` | Shared press-scale interaction wrapper |
| `lib/core/widgets/signed_avatar.dart` | Signed avatar image surface |
| `lib/core/widgets/signed_image.dart` | Signed image rendering surface |
| `lib/core/widgets/skeleton_card.dart` | Skeleton task, booking, offer, message, conversation, search, category, favorite, and details placeholders |
| `lib/core/widgets/skeleton_card_extended.dart` | Skeleton wallet, proposal, work item, notification, service, favorite, search, and profile placeholders |
| `lib/core/widgets/skeleton_loader.dart` | Base shimmer/skeleton loader, text, and avatar placeholders |
| `lib/core/widgets/sliver_tab_bar_delegate.dart` | Sliver-pinned tab bar helper |
| `lib/core/widgets/status_badge.dart` | Shared status badge |

### Auth And System Gates

| File | Visual responsibility |
| --- | --- |
| `lib/features/auth/view/login_screen.dart` | Login form, inline error, shake feedback, sign-up and forgot-password navigation |
| `lib/features/auth/view/signup_screen.dart` | Signup form, disabled-signup notice, password strength/requirements, validation feedback |
| `lib/features/auth/view/forgot_password_screen.dart` | Forgot-password form and success/check-email view |
| `lib/features/auth/view/reset_password_update_screen.dart` | Password reset update form, requirement rows, success countdown |
| `lib/features/auth/view/account_restricted_screen.dart` | Restricted account gate, reason panel, support email action |
| `lib/features/auth/view/maintenance_screen.dart` | Maintenance-mode blocking surface |
| `lib/features/auth/view/update_required_screen.dart` | Force-update blocking surface, app-store action, clipboard fallback |

### Home, Discovery, Search, Categories, Favorites, And Saved

| File | Visual responsibility |
| --- | --- |
| `lib/features/home/view/home_screen.dart` | Home feed, discovery mode chips, filter entry, task-card route pushes |
| `lib/features/home/view/widgets/filters_modal.dart` | Home filter bottom sheet |
| `lib/features/categories/view/categories_screen.dart` | Category grid, category cards, skeleton/empty/error states |
| `lib/features/search/view/search_screen.dart` | Search screen, Find Work/Find Talent tabs, task/profile result states |
| `lib/features/search/view/widgets/search_result_profile_card.dart` | Search profile result card |
| `lib/features/favorites/routes/favorites_routes.dart` | Favorites route helper |
| `lib/features/favorites/view/favorites_screen.dart` | Favorites list, empty/error states, chat route entry and feedback |
| `lib/features/favorites/view/widgets/favorite_card.dart` | Favorite freelancer card |
| `lib/features/saved/routes/saved_routes.dart` | Saved-task route helper |
| `lib/features/saved/view/saved_tasks_screen.dart` | Saved-task list, task-detail route entry, empty/error states |
| `lib/features/saved/view/widgets/saved_task_tile.dart` | Saved task row/tile |

### Tasks, Tenders, Requests, Proposals, And Payment Entry

| File | Visual responsibility |
| --- | --- |
| `lib/features/tasks/services/task_deep_link_handler.dart` | Task/offer deep-link loading dialog and task-details routing |
| `lib/features/tasks/view/create_task_screen.dart` | Bottom-sheet create/edit flow, tender/booking setup, media picker states, validation feedback |
| `lib/features/tasks/view/task_details_screen.dart` | Task details, media, owner actions, report reason dialog, chat/payment route entries |
| `lib/features/tasks/view/tenders_screen.dart` | Tenders list, search/filter input, tender cards, clear-search behavior, `No active tenders` empty state |
| `lib/features/tasks/view/tender_payment_screen.dart` | Tender/proposal payment summary, payment button, success SnackBar, inline error/unavailable/deadline feedback |
| `lib/features/tasks/view/widgets/task_card.dart` | Generic task card |
| `lib/features/tasks/view/widgets/tender_task_card.dart` | Tender discovery card and chips |
| `lib/features/tasks/view/widgets/booking_task_card.dart` | Booking discovery card, provider/action chips |
| `lib/features/tasks/view/widgets/discovery_task_sliver.dart` | Discovery sliver list/grid and load-more sentinel |
| `lib/features/tasks/view/widgets/dashboard_offer_card.dart` | Dashboard/inbox offer action card |
| `lib/features/tasks/view/widgets/expiration_countdown.dart` | Deadline countdown and expiration badge |
| `lib/features/tasks/view/widgets/payment_status_badge.dart` | Payment status badge |
| `lib/features/tasks/view/widgets/booking_logistics_section.dart` | Booking logistics detail section |
| `lib/features/tasks/view/widgets/task_concept_section.dart` | Task concept/detail section |
| `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | Request/proposal list, non-tender guard, expired filter menu, share sheet, submit FAB, list states |
| `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | Submit/replace request bottom sheet, comparison rows, confirmation dialog |
| `lib/features/tasks/view/widgets/requests/request_award_dialog.dart` | Award dialog, price mismatch dialog, deadline/risk sections |
| `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | Request/proposal tile, confirmation dialog, favorite and feedback states |
| `lib/features/proposals/routes/proposal_payment_route.dart` | Proposal payment route helper into tender payment |
| `lib/features/proposals/view/proposals_list_screen.dart` | Compatibility re-export to requests list |
| `lib/features/proposals/view/proposal_payment_screen.dart` | Compatibility re-export to tender payment |
| `lib/features/proposals/view/proposal_details_modal.dart` | Deprecated/orphaned proposal details modal |
| `lib/features/proposals/view/widgets/submit_proposal_sheet.dart` | Compatibility re-export to submit request sheet |
| `lib/features/proposals/view/widgets/proposal_tile.dart` | Compatibility re-export to request tile |

### Booking And Booking Payment

| File | Visual responsibility |
| --- | --- |
| `lib/features/booking/services/booking_deep_link_handler.dart` | Booking deep-link loading dialog and booking-details routing |
| `lib/features/booking/view/bookings_discovery_screen.dart` | Booking/service discovery list, search input, empty/error states |
| `lib/features/booking/view/bookings_list_screen.dart` | Booking list tabs, status filter bar, inline refresh error, state cards |
| `lib/features/booking/view/booking_details_screen.dart` | Booking details, status/timeline/actions, legacy slot warning, awaiting-payment state, approve/release guard, report issue dialog, dispute banners |
| `lib/features/booking/view/payment_checkout_screen.dart` | Payment checkout, draft cleanup state, payment launch, success/error states |
| `lib/features/booking/view/payment_method_screen.dart` | Legacy demo card form and validation state |
| `lib/features/booking/view/payment_return_screen.dart` | Payment return success/failure surface |
| `lib/features/booking/view/payment_webview_screen.dart` | Payment WebView, loading/error/retry/back-navigation UI |
| `lib/features/booking/view/widgets/booking_card.dart` | Booking card, image, chips, status/payment display |
| `lib/features/booking/view/widgets/dashboard_booking_card.dart` | Dashboard booking summary card and urgency bar |
| `lib/features/booking/view/widgets/payment_order_summary_card.dart` | Payment order summary card |

### Chat, Messages, Offers, And Attachments

| File | Visual responsibility |
| --- | --- |
| `lib/features/chat/services/chat_deep_link_handler.dart` | Chat deep-link loading dialog and chat routing |
| `lib/features/chat/view/messages_screen.dart` | Conversation inbox, mode toggle, search, online row, cards, delete confirmation, chat-return unread refresh |
| `lib/features/chat/view/chat_screen.dart` | Chat route, header, composer, message list, bottom sheets, report dialogs, reply UI |
| `lib/features/chat/view/widgets/conversation_list_tile.dart` | Conversation list tile |
| `lib/features/chat/view/widgets/chat_context_widget.dart` | Task/profile context header and route feedback |
| `lib/features/chat/view/widgets/create_offer_sheet.dart` | Create offer bottom sheet |
| `lib/features/chat/view/widgets/message_bubble.dart` | Message bubble, emoji-only rendering, reply quotes, status icons, links, launch feedback |
| `lib/features/chat/view/widgets/offer_message_bubble.dart` | Offer bubble with accept/decline/cancel/deliver/complete actions and lifecycle chips |
| `lib/features/chat/attachments/widgets/attachment_message_tile.dart` | Attachment message tile, signed URL state, retry/error/preview hero |

### Dashboard

| File | Visual responsibility |
| --- | --- |
| `lib/features/dashboard/view/dashboard_screen.dart` | Dashboard shell, role/settings sheet, TabBar/TabBarView |
| `lib/features/dashboard/view/tabs/overview_tab.dart` | Overview tab and section cards |
| `lib/features/dashboard/view/tabs/bookings_tab.dart` | Dashboard booking tab and state cards |
| `lib/features/dashboard/view/tabs/work_tab.dart` | Work tab, nested states, payment launchers, insufficient-funds dialog |
| `lib/features/dashboard/view/tabs/inbox_tab.dart` | Inbox tab, Received/Sent mode, disabled sent placeholder, action feedback |
| `lib/features/dashboard/view/tabs/wallet_tab.dart` | Embedded wallet tab |
| `lib/features/dashboard/view/widgets/activity_feed_preview.dart` | Activity preview, grouped timeline, deep-link rows, skeleton/empty states |
| `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart` | Dashboard counters grid and animated count cards |
| `lib/features/dashboard/view/widgets/next_actions_list.dart` | Next actions list, payment/cancel feedback, insufficient-funds dialog |
| `lib/features/dashboard/view/widgets/work_item_card.dart` | Work item dashboard card and status pill |

### Profile, Portfolio, And Services

| File | Visual responsibility |
| --- | --- |
| `lib/features/profile/services/profile_deep_link_handler.dart` | Profile deep-link public profile routing |
| `lib/features/profile/view/profile_screen.dart` | Own profile route, hero, sections, settings/service/portfolio entries |
| `lib/features/profile/view/public_profile_screen.dart` | Public profile route, tabs, sticky actions, report dialog |
| `lib/features/profile/view/edit_profile_screen.dart` | Edit profile form, skill dialog, avatar state |
| `lib/features/profile/view/settings_screen.dart` | Settings screen, logout dialog, coming-soon SnackBars |
| `lib/features/profile/view/manage_portfolio_screen.dart` | Manage portfolio list, FAB, add/edit dialogs, delete confirmation |
| `lib/features/profile/view/my_services_screen.dart` | Services management screen |
| `lib/features/profile/view/widgets/profile_avatar_widget.dart` | Profile avatar upload/display widget |
| `lib/features/profile/view/widgets/profile_preview_modal.dart` | Public profile preview bottom sheet |
| `lib/features/profile/view/widgets/public_profile/public_profile_header.dart` | Public profile header |
| `lib/features/profile/view/widgets/public_profile/public_profile_stats.dart` | Public profile stats |
| `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart` | Public profile portfolio tab content |
| `lib/features/profile/view/widgets/public_profile/public_profile_reviews.dart` | Public profile reviews tab content |
| `lib/features/portfolio/view/portfolio_screen.dart` | Portfolio list/grid, add/details/edit sheets, delete confirmation |
| `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart` | Add portfolio sheet |
| `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart` | Edit portfolio sheet |
| `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart` | Portfolio details sheet and delete confirmation |
| `lib/features/portfolio/view/widgets/portfolio_tile.dart` | Portfolio grid tile |
| `lib/features/portfolio/view/widgets/image_placeholder.dart` | Portfolio image fallback |
| `lib/features/services/view/widgets/service_card.dart` | Service card and service status badge |

### Notifications

| File | Visual responsibility |
| --- | --- |
| `lib/features/notifications/view/widgets/notification_badge_button.dart` | Notification badge button and unread badge |
| `lib/features/notifications/view/notifications_modal.dart` | Notifications bottom sheet, skeleton/empty/error/list states |
| `lib/features/notifications/view/widgets/notification_tile.dart` | Notification row/tile |

### Wallet

| File | Visual responsibility |
| --- | --- |
| `lib/features/wallet/view/wallet_screen.dart` | Standalone wallet route/surface |
| `lib/features/wallet/view/wallet_dashboard_screen.dart` | Wallet dashboard screen file; no current app route registration found |
| `lib/features/wallet/view/widgets/wallet_shared_body.dart` | Wallet shared body, loading/error/insight/action/timeline states |
| `lib/features/wallet/view/widgets/wallet_hero_card.dart` | Wallet balance hero, action pills, composition bar |
| `lib/features/wallet/view/widgets/wallet_snapshot_card.dart` | Snapshot metrics, action pills, disabled visual state |
| `lib/features/wallet/view/widgets/wallet_timeline_card.dart` | Wallet timeline and empty activity state |

### Work, Management, And Direct Offers

| File | Visual responsibility |
| --- | --- |
| `lib/features/work/services/work_deep_link_handler.dart` | Work/direct-offer deep-link route dispatch |
| `lib/features/work/view/work_item_details_screen.dart` | Work item details route, tabs, state cards, delivery/review/extension sheets, report dialog |
| `lib/features/work/view/widgets/submit_delivery_modal.dart` | Submit delivery modal/sheet |
| `lib/features/work/view/widgets/review_delivery_modal.dart` | Review delivery modal/sheet |
| `lib/features/work/view/widgets/request_extension_modal.dart` | Request extension modal/sheet |
| `lib/features/work/view/widgets/work_item_booking_details.dart` | Work item booking details section |
| `lib/features/work/view/widgets/work_item_bottom_actions.dart` | Work item bottom action bar |
| `lib/features/work/view/widgets/work_item_guard_widgets.dart` | Dispute, report, review, extension, and change-request guard widgets |
| `lib/features/management/view/order_management_panel.dart` | Order management timeline and note composer |
| `lib/features/management/view/widgets/order_management_section.dart` | Order management section wrapper |
| `lib/features/management/view/widgets/work_log_tile.dart` | Work log tile and private-note marker |
| `lib/features/direct_offers/services/direct_offer_deep_link_handler.dart` | Direct-offer deep-link routing |
| `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Direct offer details, payment routes, action dialogs, dispute/report guards |

## Redesign Coverage Checklist

For broad redesign work, the plan must explicitly account for:

- App shell: `MainNavigationScreen`, bottom nav, FAB, notification entry, route transitions.
- Auth/system states: login, signup, reset, maintenance, account restricted, update required.
- Primary tabs: Home, Dashboard, Messages, Profile.
- Secondary route screens: details pages, payment pages, wallet pages, public profile, settings, create task.
- Nested tabs: Dashboard tabs, Work tab states, Bookings list tabs, Work item detail tabs, Public profile tabs.
- Popups and sheets: filters, create offer, submit request/proposal, portfolio add/edit/detail, notifications, delivery/review/extension, role/settings bottom sheet.
- Dialogs and menus: report reason dialogs, delete/logout/award confirmations, price mismatch, insufficient funds, popup menus, deep-link loading dialogs.
- Transient feedback: SnackBars, banners, inline empty/loading/error states, disabled states.
- Shared widgets: buttons, cards, inputs, status badges, signed media, skeletons, bottom nav, wallet/task/booking/chat cards.

## Agent Update Rule

When any related agent runs:

- Planner must include this file in `Documentation And Diagram Sources` for UI work and list the affected inventory rows.
- PlanCritic must fail UI plans that do not use this file or do not list affected screens, popups, sheets, tabs, and routes.
- Executor must re-check this file before implementation and stop if the plan omits an affected UI surface.
- Pixel must compare the changed UI code against this inventory before and after implementation.
- Orchestrator must flag stale or missing inventory updates in the Master Report.
- Sentinel must block major UI work when a new or changed surface is absent from this file.
- DocsKeeper must keep this file, `README.md`, `Sline_everything/DOC_SOURCE_MAP.md`, and `Sline_everything/AppDigram/README.md` aligned.
