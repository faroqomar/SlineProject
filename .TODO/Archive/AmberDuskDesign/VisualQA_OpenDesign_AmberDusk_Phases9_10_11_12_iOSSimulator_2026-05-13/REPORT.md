# Visual QA Report - Amber Dusk Phases 9-12 - iOS Simulator

Date: 2026-05-13  
Device: iPhone 17 Simulator, iOS 26.5  
App target: SLine Flutter app  
Scope: login, signup, posting, discovery, proposals, dashboard, messages, booking, payment, logout, cross-account replay  
Implementation status: report-only pass; no app code was edited.

## Evidence Sources

- Open Design MCP project: `Sline V2 Amber Dusk.html`
- Open Design project id: `1674a1db-7a74-4c80-8e2c-196a0385a8f7`
- Screenshot folder: `screenshots/`
- Test accounts:
  - `1test@test.com` / provided shared test password
  - `2test@test.com` / provided shared test password
- Payment test card was used only in the gateway. Report text redacts the PAN and CVV; the local screenshot evidence includes test-card entry and should be redacted before external sharing.

## Open Design Baseline

The Open Design MCP evidence sets the Amber Dusk target as a warm, low-light product system:

- Core colors: page near-black `#0E0B08`, app backgrounds `#1A1612` and `#241F1A`, cream `#F2E8D5`, muted copy `#8F8478`, primary `#D4906A`, amber `#E6B87A`, rust `#C9695C`, forest `#7FA872`.
- Typography: Fraunces is reserved for page titles, freelancer names, and major wallet values. DM Sans is used for controls, body text, and operational copy.
- Primary mobile destinations: Home, Dashboard, Messages, Profile. Design evidence does not support extra primary destinations outside this contract.
- Dashboard tabs: Overview, Bookings, Work, Wallet, Inbox.
- Messages modes: Received and Sent.
- Create-post flow: choose Tender or Booking, fill details, review a live card preview, then post into the matching Home feed category.
- Booking-card target: deep rust gradient, 24px radius, borderless top sheen, lower bevel, and a single layered hero shadow.
- Visual restriction: avoid blue, purple, and teal accents in Amber Dusk app surfaces unless they are unavoidable external vendor UI.

## Flow Covered

1. Started from the login welcome screen.
2. Tried account 1 login before signup and confirmed invalid credentials behavior.
3. Signed up account 1.
4. Observed unexpected post-signup landing on an existing Job Details screen.
5. Navigated account 1 Home and created a Tender post through Type, Details, and Review.
6. Confirmed account 1 Home did not immediately show the newly created tender.
7. Logged out account 1.
8. Signed up account 2.
9. Confirmed account 2 Home did show account 1's new tender.
10. Opened the tender as account 2 and attempted proposal submission.
11. Audited Dashboard Overview, Bookings, Work, Wallet, and Inbox.
12. Audited Messages Received, Sent, and search.
13. Opened a Booking listing, started chat, and sent a booking-context message.
14. Started booking payment and completed the QiCard web payment with the provided test MasterCard ending `8582`.
15. Returned from gateway and checked Booking Details plus Dashboard Bookings.
16. Opened account 1's tender from account 2, sent a direct task-context message.
17. Logged back into account 1 and confirmed the received thread from account 2.

## Severity Summary

| Severity | Count | Areas |
| --- | ---: | --- |
| Blocker | 2 | Proposal submission, paid booking recovery |
| High | 5 | Payment metadata exposure, legacy screens, signup routing, feed refresh, money display |
| Medium | 8 | Dashboard empty states, inbox mode inconsistency, create-post ergonomics, chat transition, copy/category consistency |
| Low | 5 | Microcopy, spacing, disabled-state clarity, vendor handoff polish, screenshot handling |

## Blockers

### 1. Proposal submission is blocked by invalid prefilled amount

Evidence: `18_offers_empty_legacy_teal.png`, `19_submit_proposal_sheet_empty.png`, `20_submit_proposal_filled.png`, `21_submit_proposal_prefilled_amount_invalid.png`

Account 2 opened account 1's tender and reached the proposal sheet. The amount field was prefilled as `75000.0`. Submitting produced an amount validation error. The field could not be reliably cleared or edited through the simulator accessibility/keyboard path, so the proposal could not be submitted.

Impact:
- Freelancer cannot bid on a tender that was just posted.
- This blocks the tender marketplace loop.
- The decimal formatting suggests a model or controller formatting mismatch for an integer money field.

Design comparison:
- Open Design expects the posted Tender to support a clear applicant/proposal path from Home into Dashboard/Inbox. This flow breaks before a proposal can exist.

### 2. Payment gateway processed, but app did not confirm or recover the booking

Evidence: `35_payment_checkout_qicard_pre_pay_account2.png`, `36_payment_checkout_processing_account2.png`, `37_qicard_checkout_empty.png`, `38_qicard_checkout_filled_pre_pay.png`, `39_qicard_processed_raw_metadata.png`, `40_after_payment_return_booking_details_still_book_basic.png`, `41_dashboard_bookings_after_payment_empty_account2.png`

Account 2 started a booking payment for `50K IQD`, completed the QiCard gateway with the provided test card ending `8582`, and reached a gateway `Processed` result. After returning to the app, Booking Details still showed `Book Basic`, and Dashboard Bookings remained empty.

Impact:
- User pays but sees no success state, receipt, booking record, or recovery route.
- The same package still appears bookable after the processed gateway result.
- Dashboard Bookings cannot be trusted as a source of truth after payment.

Design comparison:
- Amber Dusk dashboard expects Bookings to represent active booking state. Payment completion needs to land in a booking confirmation or active booking detail state, not return to an unchanged purchase CTA.

## High Findings

### 3. Gateway success page exposes raw technical metadata

Evidence: `39_qicard_processed_raw_metadata.png`

The processed payment page displayed raw ids and metadata such as booking id, entity type, payer id, entity id, correlation id, and intent id.

Impact:
- This is not appropriate customer-facing output.
- It increases privacy and support risk.
- It makes the payment flow feel unfinished and untrusted.

Expected:
- Show a concise processed state, amount, merchant/app name, and a return action. Technical ids belong in logs and support tools, not primary UI.

### 4. Several key transactional screens still use legacy teal/blue styling

Evidence: `18_offers_empty_legacy_teal.png`, `32_booking_details_legacy_teal_account2.png`, `33_chat_empty_booking_context_legacy_teal.png`, `34_chat_message_sent_account2.png`, `42_chat_test_one_empty_context_visual_offset.png`, `45_account1_chat_thread_from_account2.png`

Offers, Booking Details, and Chat retain a teal/blue legacy visual language. These are central marketplace surfaces, so the mismatch is highly visible.

Impact:
- Breaks the Amber Dusk system contract.
- Makes the app feel like multiple products stitched together.
- Payment and chat confidence suffer because the most sensitive screens are the least aligned.

Expected:
- Replace teal/blue surfaces with Amber Dusk tokens. External QiCard vendor UI can remain branded, but SLine-owned screens should not.

### 5. Signup routes to an unexpected existing Job Details screen

Evidence: `05_account1_post_signup_job_details_unexpected_landing.png`

After signing up account 1, the app landed on an existing Job Details page instead of Home, onboarding, profile completion, or a clean Dashboard state.

Impact:
- New users begin inside unrelated marketplace content.
- It is unclear whether this is stale navigation state, deep-link persistence, or auth redirect behavior.

Expected:
- First authenticated landing should be deterministic. For this design phase, Home or Profile completion would be the most coherent destinations.

### 6. New post does not refresh immediately for the posting user

Evidence: `09_create_tender_review_preview.png`, `10_after_post_home_feed_no_new_tender_visible.png`, `16_account2_home_sees_account1_tender.png`

Account 1 created a tender. Account 1 returned to Home and still saw the old feed count and no new tender. Account 2 later saw the new tender at the top of Home.

Impact:
- Poster receives no strong confirmation that posting worked.
- Realtime/database creation works, but local feed refresh or filter invalidation does not.

Expected:
- After posting, route to the matching feed category with the new item pinned or highlighted, or show a durable success confirmation and refresh.

### 7. Money display mixes IQD and dollar semantics

Evidence: `31_home_bookings_feed_account2.png`, `32_booking_details_legacy_teal_account2.png`, `35_payment_checkout_qicard_pre_pay_account2.png`

Booking details show `$50000`, while payment checkout uses `50K IQD`. The app marketplace context and payment provider point to IQD.

Impact:
- Users may misunderstand payment amount or currency.
- Payment trust is reduced before the most sensitive step.

Expected:
- Use one money formatter across booking cards, booking details, checkout, dashboard, wallet, and receipts.

## Medium Findings

### 8. Dashboard empty states are too passive

Evidence: `23_dashboard_bookings_empty_account2.png`, `24_dashboard_work_empty_account2.png`, `27_dashboard_inbox_empty_account2.png`

Bookings, Work, and Inbox empty states show basic empty messaging but do not provide clear routes back to discovery, posting, or messages.

Expected:
- Empty Bookings: CTA to browse bookings.
- Empty Work: CTA to find tenders or manage offers.
- Empty Inbox: CTA to check Home or Messages, depending on role.

### 9. Dashboard Inbox Sent mode is disabled while Messages supports Sent

Evidence: `27_dashboard_inbox_empty_account2.png`, `28_messages_received_empty_account2.png`, `29_messages_sent_empty_account2.png`

Open Design expects Received and Sent modes for messaging. Standalone Messages exposes both. Dashboard Inbox shows Sent as disabled or visually unavailable.

Expected:
- Either Dashboard Inbox should mirror Received/Sent behavior or use a different label that does not imply unavailable sent-message support.

### 10. Create-post detail sheet is functional but cramped near lower fields

Evidence: `08_create_tender_details_filled.png`, `09_create_tender_review_preview.png`

The Type, Details, Review structure matches Open Design, but the Details sheet is dense and lower controls are awkward to reach. Tags were not completed during this run because the sheet interaction became difficult after the lower inputs.

Expected:
- Keep the three-step flow.
- Improve bottom spacing, keyboard avoidance, and field affordances.
- Ensure the primary action never hides the final editable controls.

### 11. Feed filter copy is inconsistent with mixed content

Evidence: `06_account1_home_feed.png`, `16_account2_home_sees_account1_tender.png`, `31_home_bookings_feed_account2.png`

Home uses counts and labels that read like task-only counts even when Home includes bookings and tenders.

Expected:
- Use category-specific counts: tasks, bookings, tenders, or listings depending on active tab.

### 12. Chat transition showed a left-edge visual offset

Evidence: `42_chat_test_one_empty_context_visual_offset.png`

Opening the task-context chat showed a visible left-edge sliver from the previous view or a transitional layout offset.

Expected:
- Chat route transitions should fully cover the previous route and respect safe area/background fill.

### 13. Chat works cross-account, but remains off-system visually

Evidence: `43_chat_test_one_message_sent_account2.png`, `44_account1_messages_received_from_account2.png`, `45_account1_chat_thread_from_account2.png`

Functional cross-account message delivery succeeded. Account 2 sent a task-context message to account 1, and account 1 received it in Messages. The issue is visual and structural: chat uses teal accents, old app-bar styling, and different density from Amber Dusk.

Expected:
- Preserve the working realtime/message behavior.
- Reskin the chat shell, composer, context card, bubbles, empty state, and route background with Amber Dusk tokens.

### 14. Signup validation and button state are not clear

Evidence: `03_signup_form_empty.png`, `04_signup_form_account1_filled_pre_submit.png`, `14_signup_form_account2_filled_pre_submit.png`

Signup shows password requirements, but the form still allowed successful account creation with the provided password. The visual disabled/enabled state was hard to read in the simulator.

Expected:
- Validation requirements, enabled state, and actual submit behavior should match exactly.

### 15. Payment vendor handoff needs stronger SLine framing

Evidence: `35_payment_checkout_qicard_pre_pay_account2.png`, `36_payment_checkout_processing_account2.png`, `37_qicard_checkout_empty.png`

The in-app checkout summary is close to Amber Dusk, but the jump into the external QiCard webview is visually abrupt. Vendor colors are acceptable, but the app should set expectations before handoff and recover gracefully after return.

Expected:
- Before webview: clear "You are entering QiCard secure checkout" copy.
- During webview: app-level title/back/retry affordances.
- After webview: success, pending, failed, or recovery state.

## Low Findings

### 16. Search in Messages opens correctly but lacks useful empty guidance

Evidence: `30_messages_search_open_account2.png`

Search is available, but empty/search states should help users understand whether they are searching all messages, received only, sent only, or current mode only.

### 17. Wallet lower section exposes unfinished "Coming Soon" behavior

Evidence: `25_dashboard_wallet_account2.png`, `26_dashboard_wallet_lower_account2.png`

Wallet is visually closer to Amber Dusk than several other screens, but lower actions still show unfinished withdraw/coming-soon behavior.

Expected:
- If withdraw is not available, give a reason and keep the disabled affordance visually intentional.

### 18. Offers empty screen uses unclear action hierarchy

Evidence: `18_offers_empty_legacy_teal.png`

The screen shows empty state and action affordances, but the hierarchy around applying, reviewing offers, and returning to task details is not clear.

### 19. Screenshot 38 contains test payment data

Evidence: `38_qicard_checkout_filled_pre_pay.png`

This is valid local QA evidence but should be treated as sensitive test evidence because it shows test card entry. Redact before sharing outside local development.

### 20. Login form interaction had simulator text-selection friction

Evidence: observed during account switching; not isolated to a screenshot.

This may be a simulator/computer-use artifact rather than an app defect. Retest manually before filing as an app bug.

## Positive Findings

- Login, signup, logout, and re-login were functional for both test accounts.
- Account 2 could see account 1's newly created tender, proving backend creation and cross-account visibility.
- Main Dashboard tabs exist and match the Open Design names: Overview, Bookings, Work, Wallet, Inbox.
- Standalone Messages exposes Received and Sent modes.
- Cross-account direct messaging worked from account 2 to account 1.
- The in-app payment checkout summary is much closer to Amber Dusk than legacy Booking Details and Chat.
- Settings logout confirmation is clear and functional.
- Profile top surface for both accounts is broadly aligned with Amber Dusk color direction.

## Recommended Implementation Order

1. Fix proposal amount formatting/editability and add regression coverage for tender proposal submission.
2. Fix payment return handling so processed payments create or load the booking state and Dashboard Bookings reflects it.
3. Hide raw gateway metadata from customer-facing payment result screens.
4. Migrate Booking Details, Chat, Offers, and Proposal sheet away from teal/blue legacy styling.
5. Fix post-signup routing and stale Home feed after successful post creation.
6. Unify money formatting to IQD across listing cards, details, checkout, wallet, dashboard, and receipts.
7. Strengthen Dashboard empty states with role-aware actions.
8. Align Dashboard Inbox behavior with the Messages Received/Sent contract.
9. Improve Create Post lower-sheet ergonomics and keyboard avoidance.
10. Add visual regression screenshots for the full tested flow.

## Future Automation Notes

For a repeatable simulator agent, use this flow:

1. Reset or prepare simulator state.
2. Launch app with a known backend environment.
3. Login attempt for account 1 before signup; capture invalid state.
4. Signup account 1; verify deterministic landing route.
5. Create a Tender post and capture Type, Details, Review, and post-return Home.
6. Logout account 1.
7. Signup/login account 2.
8. Verify account 1's tender appears in account 2 Home.
9. Open tender and submit proposal with integer money value.
10. Audit account 2 Dashboard tabs.
11. Audit account 2 Messages Received, Sent, and search.
12. Open a Booking listing and send a booking-context chat message.
13. Start booking payment, enter test card, submit, and capture gateway result.
14. Verify booking success state and Dashboard Bookings.
15. Start task-context chat from account 2 to account 1.
16. Logout account 2 and login account 1.
17. Verify account 1 received the message and can open the thread.
18. Export screenshots with stable numbered filenames.
19. Generate report mapping each screenshot to Open Design expectations.

## Screenshot Index

| # | File | Notes |
| ---: | --- | --- |
| 1 | `01_login_welcome.png` | Initial login welcome screen |
| 2 | `02_login_invalid_credentials_account1.png` | Account 1 invalid login before signup |
| 3 | `03_signup_form_empty.png` | Empty signup form |
| 4 | `04_signup_form_account1_filled_pre_submit.png` | Account 1 signup before submit |
| 5 | `05_account1_post_signup_job_details_unexpected_landing.png` | Unexpected post-signup Job Details route |
| 6 | `06_account1_home_feed.png` | Account 1 Home feed |
| 7 | `07_create_post_type_sheet.png` | Create post type selection |
| 8 | `08_create_tender_details_filled.png` | Tender details filled |
| 9 | `09_create_tender_review_preview.png` | Tender review preview |
| 10 | `10_after_post_home_feed_no_new_tender_visible.png` | Home after post, new tender not visible |
| 11 | `11_profile_account1_top.png` | Account 1 Profile |
| 12 | `12_settings_account_control_logout.png` | Settings account control |
| 13 | `13_logout_confirmation_dialog.png` | Logout confirmation |
| 14 | `14_signup_form_account2_filled_pre_submit.png` | Account 2 signup before submit |
| 15 | `15_profile_account2_top.png` | Account 2 Profile |
| 16 | `16_account2_home_sees_account1_tender.png` | Account 2 sees account 1 tender |
| 17 | `17_account2_job_details_apply.png` | Tender details apply entry |
| 18 | `18_offers_empty_legacy_teal.png` | Legacy Offers screen |
| 19 | `19_submit_proposal_sheet_empty.png` | Empty proposal sheet |
| 20 | `20_submit_proposal_filled.png` | Proposal fields filled |
| 21 | `21_submit_proposal_prefilled_amount_invalid.png` | Proposal amount validation failure |
| 22 | `22_dashboard_overview_account2.png` | Dashboard Overview |
| 23 | `23_dashboard_bookings_empty_account2.png` | Dashboard Bookings empty |
| 24 | `24_dashboard_work_empty_account2.png` | Dashboard Work empty |
| 25 | `25_dashboard_wallet_account2.png` | Dashboard Wallet top |
| 26 | `26_dashboard_wallet_lower_account2.png` | Dashboard Wallet lower area |
| 27 | `27_dashboard_inbox_empty_account2.png` | Dashboard Inbox empty |
| 28 | `28_messages_received_empty_account2.png` | Messages Received |
| 29 | `29_messages_sent_empty_account2.png` | Messages Sent |
| 30 | `30_messages_search_open_account2.png` | Messages search |
| 31 | `31_home_bookings_feed_account2.png` | Home Bookings feed |
| 32 | `32_booking_details_legacy_teal_account2.png` | Legacy Booking Details |
| 33 | `33_chat_empty_booking_context_legacy_teal.png` | Booking-context chat empty |
| 34 | `34_chat_message_sent_account2.png` | Booking-context chat message sent |
| 35 | `35_payment_checkout_qicard_pre_pay_account2.png` | In-app QiCard checkout before pay |
| 36 | `36_payment_checkout_processing_account2.png` | In-app payment processing |
| 37 | `37_qicard_checkout_empty.png` | QiCard webview empty |
| 38 | `38_qicard_checkout_filled_pre_pay.png` | QiCard test-card entry; redact before sharing |
| 39 | `39_qicard_processed_raw_metadata.png` | Gateway processed page with raw metadata |
| 40 | `40_after_payment_return_booking_details_still_book_basic.png` | Returned Booking Details still shows Book Basic |
| 41 | `41_dashboard_bookings_after_payment_empty_account2.png` | Dashboard Bookings still empty after payment |
| 42 | `42_chat_test_one_empty_context_visual_offset.png` | Task-context chat with visual offset |
| 43 | `43_chat_test_one_message_sent_account2.png` | Account 2 sent task-context message |
| 44 | `44_account1_messages_received_from_account2.png` | Account 1 received message |
| 45 | `45_account1_chat_thread_from_account2.png` | Account 1 opened received thread |

## Gaps Not Completed In This Pass

- Account 1 did not successfully receive a proposal because account 2 proposal submission was blocked.
- Booking success could not be verified inside Dashboard because the app did not surface a booking after gateway processed payment.
- No CodeRabbit review was run; no CodeRabbit connector/tool was available in this session. This document is a simulator/Open Design QA report, not an automated code-review report.
- Screenshots were captured in a test environment. The QiCard-related screenshots should be redacted before external publication.
