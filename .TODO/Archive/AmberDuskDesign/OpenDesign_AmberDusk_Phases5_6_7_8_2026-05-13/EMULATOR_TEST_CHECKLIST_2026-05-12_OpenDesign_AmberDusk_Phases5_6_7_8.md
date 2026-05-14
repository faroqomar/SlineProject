# Emulator Test Checklist - Open Design Amber Dusk Phases 5-8

**Date:** 2026-05-12  
**Scope:** every uncommitted file touched in the Phase 5-8 session, including docs, screenshots, tests, and source files.  
**Reference evidence:** `.TODO/OpenDesign_AmberDusk_Phases5_6_7_8_OpenDesignScreenshots_2026-05-12/` plus the phase plan and critique.

## Global Setup

- Run on phone widths where feasible: 360, 390, 402, and 430 logical pixels.
- Use the active app theme. Do not switch Amber Dusk into the global app theme unless a later plan explicitly asks for it.
- For every screen: check no text overlap, no clipped buttons, no raw blue/Material fallback, no glass/blur treatment, no route crash, and no visible private IDs, callback URLs, or storage paths.
- Compare against exported Open Design screenshots only where screenshots exist; otherwise use the plan's evidence notes and mark "no exact artboard".

## Artifact And Evidence Files

| File(s) | Emulator action | Pass criteria |
| --- | --- | --- |
| `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md` | No emulator route. Use as checklist source while testing. | Every covered route maps back to the planned phase/screen group. |
| `.TODO/PLAN_CRITIQUE_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments.md` | No emulator route. Review before testing. | Critique constraints remain honored: no backend drift, no global theme activation, no design-system improvisation. |
| `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md` | No emulator route. Use as execution history. | Step 6 corrections are present: 44 production Dart files, 6 test Dart files, visual-only Messages toggle, coverage gate recorded. |
| `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_Step6.md` | No emulator route. Use as review gate. | All BLOCKER/HIGH/MED findings remain closed after emulator testing. |
| `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md` | No emulator route. Use this file. | Mark each route/state as pass, fail, or blocked with device width and screenshot. |
| `.TODO/OpenDesign_AmberDusk_Phases5_6_7_8_OpenDesignScreenshots_2026-05-12/README.md` | No emulator route. Use as screenshot manifest. | Manifest notes match actual exported PNG files and note the Messages copy conflict correctly. |
| `.TODO/OpenDesign_AmberDusk_Phases5_6_7_8_OpenDesignScreenshots_2026-05-12/*.png` | Compare emulator screenshots to each matching route/state. | Use exact comparison where a phone screenshot exists; use supplemental web screenshots only for density/tokens, not exact phone parity. |

## Auth And System Gates

| File(s) | Emulator route/state | Pass criteria | Automated coverage |
| --- | --- | --- | --- |
| `lib/features/auth/view/login_screen.dart` | Logged-out login screen; empty submit; invalid credentials; keyboard open. | Amber Dusk surface/token treatment, readable form fields, no overflow at all widths, password visibility works, errors are user-safe. | Full test suite and analyzer; visual QA manual. |
| `lib/features/auth/view/signup_screen.dart` | Signup form; validation errors; disabled submit state; keyboard open. | 8-character password requirement matches visible copy, role controls fit, no token drift or clipped controls. | Full test suite and analyzer; visual QA manual. |
| `lib/features/auth/view/forgot_password_screen.dart` | Forgot password entry and success/error states. | Tokenized field/button treatment, safe errors, no layout jump when keyboard appears. | Full test suite and analyzer; visual QA manual. |
| `lib/features/auth/view/reset_password_update_screen.dart` | Reset password update state. | Consistent Amber Dusk form styling and no clipped validation text. | Full test suite and analyzer; visual QA manual. |
| `lib/features/auth/view/account_restricted_screen.dart` | Restricted account gate. | Critical status copy is readable, actions fit, no unsupported decorative treatment. | Full test suite and analyzer; visual QA manual. |
| `lib/features/auth/view/maintenance_screen.dart` | Maintenance gate. | Hero/status panel stays inside safe area, copy wraps cleanly at 360 px. | Full test suite and analyzer; visual QA manual. |
| `lib/features/auth/view/update_required_screen.dart` | Update-required gate. | Primary action remains accessible and no text overlaps app chrome. | Full test suite and analyzer; visual QA manual. |

## Chat, Messages, Attachments, And Notifications

| File(s) | Emulator route/state | Pass criteria | Automated coverage |
| --- | --- | --- | --- |
| `lib/features/chat/view/messages_screen.dart`, `test/widget/chat/messages_screen_test.dart` | Messages list with no conversations, multiple conversations, search open, toggle Received/Sent. | Toggle copy is `Received`/`Sent`; toggling does not hide valid conversations; search still filters by participant/message only. | `messages_screen_test.dart`; full suite. |
| `lib/features/chat/view/chat_screen.dart`, `lib/features/chat/view/widgets/message_bubble.dart`, `lib/features/chat/view/widgets/offer_message_bubble.dart`, `lib/features/chat/view/widgets/chat_context_widget.dart`, `lib/features/chat/view/widgets/create_offer_sheet.dart` | Open a conversation, send/reply state, offer bubble, context panel, create-offer sheet. | Bubbles use tokenized radii/colors, actions fit, no raw IDs in logs/UI, reply swipe does not leak listeners after navigation. | Full suite; visual QA manual. |
| `lib/features/chat/view/widgets/conversation_list_tile.dart` | Conversation rows with long names, unread state, missing avatar. | Row density matches Amber Dusk, unread indicator is visible, long names/messages ellipsize. | Full suite; visual QA manual. |
| `lib/features/chat/attachments/widgets/attachment_message_tile.dart`, `lib/features/chat/attachments/services/upload_service.dart`, `lib/features/chat/services/attachment_service.dart`, `lib/features/chat/viewmodels/chat_view_model.dart`, `test/widget/chat/phase6_attachment_message_tile_test.dart` | Attachment loading, success, resolver failure, retry, fullscreen image. | No private storage path appears in UI/logs; resolver stays behind ViewModel/service; error state is readable and retryable. | `phase6_attachment_message_tile_test.dart`; full suite. |
| `lib/features/notifications/view/notifications_modal.dart`, `lib/features/notifications/view/widgets/notification_badge_button.dart`, `lib/features/notifications/view/widgets/notification_tile.dart` | Notification badge, modal empty/list states, long notification text. | Badge does not overlap, modal height and list rows fit, notification text wraps without clipping. | Full suite; visual QA manual. |

## Dashboard Inbox, Tasks, Tenders, And Award Flows

| File(s) | Emulator route/state | Pass criteria | Automated coverage |
| --- | --- | --- | --- |
| `lib/features/dashboard/view/tabs/inbox_tab.dart`, `test/widget/dashboard/inbox_tab_test.dart` | Dashboard Inbox with received offers, disabled Sent tab, award/pay/withdraw actions where available. | `Sent` is visibly disabled until data contract exists; received list remains actionable; no invisible tap traps. | `inbox_tab_test.dart`; full suite. |
| `lib/features/tasks/view/tenders_screen.dart`, `lib/features/tasks/view/tender_payment_screen.dart`, `test/widget/tasks/tender_payment_screen_test.dart` | Tenders list, empty/loading/load-more, tender payment summary. | Dense Amber Dusk rows, payment CTA fits, no raw payment IDs or URLs. | `tender_payment_screen_test.dart`; full suite. |
| `lib/features/tasks/view/task_details_screen.dart` | Task details as client owner, freelancer, closed task, tender task. | Action panel matches state, unavailable actions disabled, no layout collision with bottom action area. | Full suite; visual QA manual. |
| `lib/features/tasks/view/widgets/requests/request_award_dialog.dart`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | Request tile normal/expired/payment error; award dialog under/over budget; cancel award dialog. | Solid primary/danger CTAs use accessible inverse text; countdown/status text wraps; dialog actions fit at 360 px. | Request tile/award dialog tests in full suite. |
| `lib/features/work/view/work_item_details_screen.dart`, `lib/features/work/view/widgets/work_item_bottom_actions.dart`, `lib/features/work/view/widgets/review_delivery_modal.dart` | Work item active, review delivery, complete/cancel action states. | Bottom actions stay reachable, modal content fits, no raw IDs in UI/logs. | Full suite; visual QA manual. |
| `lib/features/management/view/order_management_panel.dart`, `lib/features/management/view/widgets/work_log_tile.dart` | Management panel and work log list with empty/error/log states. | Logs remain readable, timestamps/status chips fit, error states do not expose raw backend details. | Full suite; visual QA manual. |

## Booking, Payment, Wallet

| File(s) | Emulator route/state | Pass criteria | Automated coverage |
| --- | --- | --- | --- |
| `lib/features/booking/view/bookings_list_screen.dart`, `lib/features/booking/view/bookings_discovery_screen.dart`, `lib/features/booking/view/widgets/booking_card.dart` | Bookings list loading/empty/error/filter; discovery list; booking card with image/status/long title. | Cards use Amber Dusk tokens, images resolve through signed image surface, status chips fit, load-more works. | Booking list/discovery/card coverage in full suite; visual QA manual. |
| `lib/features/booking/view/booking_details_screen.dart` | Booking detail pending/confirmed/delivered/dispute states. | Price/status sections are legible, action buttons reflect role/state, no bottom overflow. | `booking_details_screen_test.dart`; full suite. |
| `lib/features/booking/view/payment_method_screen.dart`, `lib/features/booking/view/widgets/payment_order_summary_card.dart` | Payment method selection and order summary. | Summary numbers align, method cards are selectable and readable, no clipped amount/currency. | Full suite; visual QA manual. |
| `lib/features/booking/view/payment_checkout_screen.dart` | Checkout initial, processing, gateway confirmation, error, success. | Primary CTA contrast passes visually, spinner visible on solid fill, no raw exception/booking IDs in UI/logs. | `payment_checkout_screen_test.dart`; full suite. |
| `lib/features/booking/view/payment_webview_screen.dart` | WebView opening, page start/finish, back navigation, callback mismatch/failure/success where feasible. | Logs classify URL facts only; no host/path/query values; loading/error UI remains tokenized. | Payment checkout/return tests; full suite; emulator WebView manual. |
| `lib/features/booking/view/payment_return_screen.dart` | Success callback, failed recovery, retry state. | Recovery messages are user-safe, retry action visible, no raw callback URI. | `payment_return_screen_test.dart`; full suite. |
| `lib/features/wallet/view/widgets/wallet_hero_card.dart`, `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`, `test/widget/wallet/wallet_shared_body_test.dart` | Wallet dashboard, hero card, snapshot card, loading/error/empty/activity states. | Wallet remains summary-only; Withdraw/Top up look disabled/coming-soon; balances and composition bar fit. | `wallet_shared_body_test.dart`; full suite. |
| `lib/features/profile/view/settings_screen.dart` | Profile settings and wallet/withdrawal preview route. | Settings rows match Amber Dusk density; coming-soon withdrawal copy is not presented as active flow. | Full suite; visual QA manual. |

## Proposal Payment Wrapper

| File(s) | Emulator route/state | Pass criteria | Automated coverage |
| --- | --- | --- | --- |
| `test/widget/proposals/proposal_payment_screen_test.dart` | No direct emulator route for test file; verify proposal payment entry in app if reachable. | Proposal payment screen uses the shared payment surface and inherits Amber Dusk tokens. | `proposal_payment_screen_test.dart`; full suite. |

## Final Runtime Sign-Off Template

For each emulator pass, record:

- Device/width:
- Route/state:
- Reference screenshot:
- Result: pass / fail / blocked
- Screenshot path:
- Notes:
