# SLine App Test Map and Execution Guide

Date: 2026-05-13  
Source report: `REPORT.md`  
Screenshot evidence: `screenshots/`  
Open Design source: `Sline V2 Amber Dusk.html` via Open Design MCP  
Purpose: make future simulator and automation runs faster, more targeted, and more predictable.

## How To Use This File

This file is the operational map for retesting the app. It is not a bug report by itself. Use it to decide:

- Which flow to test.
- Which account starts the flow.
- Which screen must appear before the test can begin.
- Which screenshots must be captured.
- Which known failures are expected from the 2026-05-13 run.
- Which Open Design rules each flow must respect.
- Which tests can be skipped when a fix is scoped to one area.

For findings and severity, read `REPORT.md`. For raw visual evidence, open the matching numbered screenshot in `screenshots/`.

## Evidence Available From The Previous Run

The previous simulator pass produced 45 screenshots and covered:

- Login and invalid login.
- Signup for account 1 and account 2.
- Unexpected post-signup route.
- Home feed.
- Create Tender flow: Type, Details, Review, post-return Home.
- Account switching and logout.
- Cross-account discovery of a newly created tender.
- Tender details and proposal attempt.
- Dashboard Overview, Bookings, Work, Wallet, Inbox.
- Messages Received, Sent, and search.
- Booking feed and Booking Details.
- Booking-context chat.
- QiCard payment checkout and external gateway.
- Post-payment return and Dashboard Bookings check.
- Task-context chat from account 2 to account 1.
- Account 1 received-message verification.

The previous run ended after account 1 opened the received chat thread from account 2. Do not assume simulator state persists across restarts. Always confirm the current auth state before starting a targeted test.

## Test Secrets Policy

Do not store raw payment card numbers, CVV values, or shared passwords in this file.

Use these references instead:

- Account 1 email: `1test@test.com`
- Account 2 email: `2test@test.com`
- Password: use the operator-provided shared test password.
- Test card: use the operator-provided MasterCard test card ending `8582`.
- Expiry and CVV: use the operator-provided test values.

Screenshot `38_qicard_checkout_filled_pre_pay.png` contains sensitive test-card entry. Redact it before sharing outside the local test environment.

## Open Design Rules That Every Visual Test Must Check

Every app-owned screen in these phases must be checked against these design rules:

- App-owned surfaces use Amber Dusk colors, not legacy teal, blue, purple, or bright cyan.
- Core palette:
  - Page near-black: `#0E0B08`
  - Background: `#1A1612`
  - Raised background: `#241F1A`
  - Cream text: `#F2E8D5`
  - Muted text: `#8F8478`
  - Primary rust/amber: `#D4906A`
  - Amber highlight: `#E6B87A`
  - Rust danger/accent: `#C9695C`
  - Forest success: `#7FA872`
- Fraunces is reserved for page titles, freelancer names, and major wallet values.
- DM Sans is used for controls, body copy, form labels, and operational UI.
- Primary mobile destinations are Home, Dashboard, Messages, and Profile.
- Dashboard tabs must be Overview, Bookings, Work, Wallet, Inbox.
- Messages must support Received and Sent modes.
- Create Post must follow Type -> Details -> Review -> Home/category confirmation.
- Booking cards should follow the Amber Dusk booking-card target: deep rust gradient, 24px radius, borderless top sheen, lower bevel, and one layered hero shadow.
- External vendor UI can keep its own brand colors, but SLine-owned container and return states must still feel intentional.

## Global Test Setup

Before any full or targeted run:

1. Confirm the simulator device.
   - Previous device: iPhone 17 Simulator, iOS 26.5.
   - Previous device id: `598B6947-2F57-4F22-865A-3E576CB94679`.
2. Launch the app against the intended test backend.
3. Confirm whether the app starts authenticated or unauthenticated.
4. If authenticated, note which account is active.
5. Confirm Open Design MCP is reachable before visual comparison work.
6. Create a fresh screenshot directory for the run.
7. Use stable screenshot names: two-digit order, account, screen, result.
   - Example: `04_account1_signup_filled_pre_submit.png`.
8. Keep notes while testing. Do not wait until the end; payment and routing failures are easy to lose.

## Global Pass-Fail Language

Use these result labels consistently:

- PASS: observed behavior matches expected behavior and Open Design target.
- PASS_WITH_NOTE: behavior works, but minor design, copy, timing, or polish issue exists.
- FAIL_KNOWN: failure matches a previously documented issue.
- FAIL_NEW: new regression or new mismatch not present in the previous run.
- BLOCKED: cannot complete because earlier required state did not happen.
- NEEDS_MANUAL_RECHECK: simulator or computer-use friction may be affecting the result.

## App Map By Area

### Auth And Account State

Screens and states:

- Login welcome.
- Invalid credentials.
- Signup empty form.
- Signup filled form.
- Post-signup landing.
- Logout confirmation.
- Re-login.

Previous evidence:

- `01_login_welcome.png`
- `02_login_invalid_credentials_account1.png`
- `03_signup_form_empty.png`
- `04_signup_form_account1_filled_pre_submit.png`
- `05_account1_post_signup_job_details_unexpected_landing.png`
- `13_logout_confirmation_dialog.png`
- `14_signup_form_account2_filled_pre_submit.png`

Known issues:

- Signup for account 1 routed to an unrelated existing Job Details screen.
- Signup validation and submit state were visually unclear.
- Login text-entry had simulator text-selection friction; treat this as NEEDS_MANUAL_RECHECK unless reproduced manually.

### Main Shell And Home

Screens and states:

- Home feed.
- Feed category filters.
- All/Tenders/Bookings behavior.
- Newly posted tender visibility.
- New listing count.
- Bottom navigation.

Previous evidence:

- `06_account1_home_feed.png`
- `10_after_post_home_feed_no_new_tender_visible.png`
- `16_account2_home_sees_account1_tender.png`
- `31_home_bookings_feed_account2.png`

Known issues:

- Account 1 did not immediately see its own newly posted tender after posting.
- Account 2 saw the tender later, proving backend creation and cross-account visibility.
- Feed count and label copy can read task-only even when mixed content is visible.

### Create Post

Screens and states:

- Type chooser.
- Tender details.
- Booking details if tested later.
- Review preview.
- Submit/loading/success.
- Post-return Home.

Previous evidence:

- `07_create_post_type_sheet.png`
- `08_create_tender_details_filled.png`
- `09_create_tender_review_preview.png`
- `10_after_post_home_feed_no_new_tender_visible.png`

Known issues:

- Type -> Details -> Review flow exists and matches the design model.
- Details sheet is cramped near lower fields.
- Tags were not completed in the prior run because lower-sheet interaction became difficult.
- Post-return Home did not refresh for the poster.

### Tender Detail, Offers, And Proposal

Screens and states:

- Tender details.
- Apply/proposal entry.
- Offers empty state.
- Proposal bottom sheet empty.
- Proposal filled.
- Proposal validation.
- Proposal success.
- Client-side proposal reception.

Previous evidence:

- `17_account2_job_details_apply.png`
- `18_offers_empty_legacy_teal.png`
- `19_submit_proposal_sheet_empty.png`
- `20_submit_proposal_filled.png`
- `21_submit_proposal_prefilled_amount_invalid.png`

Known issues:

- Proposal submission is currently blocked.
- Amount field was prefilled as `75000.0`.
- Submitting produced amount validation failure.
- Field edit/clear behavior was unreliable in the simulator.
- Offers and proposal surfaces are legacy teal and not Amber Dusk.

### Dashboard

Screens and states:

- Overview.
- Bookings.
- Work.
- Wallet.
- Wallet lower actions.
- Inbox.
- Inbox Received/Sent state.

Previous evidence:

- `22_dashboard_overview_account2.png`
- `23_dashboard_bookings_empty_account2.png`
- `24_dashboard_work_empty_account2.png`
- `25_dashboard_wallet_account2.png`
- `26_dashboard_wallet_lower_account2.png`
- `27_dashboard_inbox_empty_account2.png`
- `41_dashboard_bookings_after_payment_empty_account2.png`

Known issues:

- Dashboard tabs exist and match Open Design names.
- Empty states are too passive and do not route users to the next useful action.
- Dashboard Inbox Sent mode looked disabled or unavailable while standalone Messages supports Sent.
- Bookings remained empty after the payment gateway reached a processed state.
- Wallet lower section exposes unfinished coming-soon behavior.

### Messages And Chat

Screens and states:

- Messages Received.
- Messages Sent.
- Messages search.
- Booking-context chat.
- Task-context chat.
- Empty chat.
- Sent chat.
- Received chat.

Previous evidence:

- `28_messages_received_empty_account2.png`
- `29_messages_sent_empty_account2.png`
- `30_messages_search_open_account2.png`
- `33_chat_empty_booking_context_legacy_teal.png`
- `34_chat_message_sent_account2.png`
- `42_chat_test_one_empty_context_visual_offset.png`
- `43_chat_test_one_message_sent_account2.png`
- `44_account1_messages_received_from_account2.png`
- `45_account1_chat_thread_from_account2.png`

Known issues:

- Cross-account task-context message delivery worked.
- Booking-context message sending worked.
- Chat screen remains legacy teal/blue.
- Task-context chat showed a left-edge transition/render offset.
- Search opens, but the scope of search is not clear.

### Booking And Payment

Screens and states:

- Bookings feed.
- Booking Details.
- Package selection.
- Book Basic CTA.
- In-app payment checkout.
- Payment processing.
- QiCard webview empty.
- QiCard test-card entry.
- Gateway processed result.
- Return to app.
- Dashboard Bookings after return.

Previous evidence:

- `31_home_bookings_feed_account2.png`
- `32_booking_details_legacy_teal_account2.png`
- `35_payment_checkout_qicard_pre_pay_account2.png`
- `36_payment_checkout_processing_account2.png`
- `37_qicard_checkout_empty.png`
- `38_qicard_checkout_filled_pre_pay.png`
- `39_qicard_processed_raw_metadata.png`
- `40_after_payment_return_booking_details_still_book_basic.png`
- `41_dashboard_bookings_after_payment_empty_account2.png`

Known issues:

- Booking Details is legacy teal/blue.
- Booking Details displayed dollar semantics while checkout used IQD.
- In-app checkout is closer to Amber Dusk than Booking Details.
- Gateway processed the payment, but the app returned to an unchanged booking detail state.
- Dashboard Bookings stayed empty after processed payment.
- Gateway result exposed raw technical metadata.

### Profile And Settings

Screens and states:

- Profile top.
- Account control.
- Settings.
- Logout confirmation.

Previous evidence:

- `11_profile_account1_top.png`
- `12_settings_account_control_logout.png`
- `13_logout_confirmation_dialog.png`
- `15_profile_account2_top.png`

Known issues:

- Profile top is broadly aligned with Amber Dusk.
- Logout confirmation works.
- Settings/account control path was usable.

## Full Run Script

Use this when you need a complete cross-account pass.

### Phase A: Boot And Login Baseline

1. Start simulator.
2. Launch app.
3. Capture starting screen.
4. If app is authenticated, log out through Profile -> Settings -> Logout.
5. Capture login welcome.
6. Try logging in with account 1 before signup or with a purposely invalid state if the account is absent.
7. Capture invalid credentials or expected auth error.

Expected:

- Login welcome is readable and on-token.
- Invalid login produces a clear, non-technical error.
- Error does not trap the user.

Previous known result:

- Invalid login state was captured successfully.

### Phase B: Account 1 Signup And Home

1. Open signup.
2. Capture empty signup form.
3. Fill account 1 email.
4. Fill account 1 full name.
5. Fill operator-provided shared test password.
6. Capture filled form before submit.
7. Submit signup.
8. Wait for route transition.
9. Capture first authenticated landing.
10. Navigate to Home if not already there.
11. Capture Home feed.

Expected:

- Signup requirements and enabled state match actual submit behavior.
- First authenticated landing is deterministic.
- Preferred landing: Home or Profile completion.

Previous known result:

- App landed unexpectedly on an existing Job Details screen.

### Phase C: Account 1 Creates A Tender

1. From Home, open Create Post.
2. Capture type chooser.
3. Select Tender.
4. Fill title.
5. Fill description.
6. Fill budget as an integer IQD amount.
7. Fill location.
8. Fill work type.
9. Fill deadline.
10. Fill category.
11. Fill tags if the lower sheet is reachable.
12. Capture details filled.
13. Continue to Review.
14. Capture live preview.
15. Submit post.
16. Wait for return route.
17. Capture Home after submit.
18. Verify whether new tender appears for the posting user.

Expected:

- Type -> Details -> Review is smooth.
- Keyboard does not hide final controls.
- Review card accurately reflects details.
- Submit returns to the matching feed/category.
- New tender appears immediately or a durable success state explains where it went.

Previous known result:

- Flow submitted, but account 1 Home did not show the new tender immediately.

### Phase D: Logout Account 1

1. Navigate to Profile.
2. Capture Profile top if not already captured in this run.
3. Open settings/account control.
4. Capture logout area.
5. Tap logout.
6. Capture confirmation dialog.
7. Confirm logout.
8. Verify login screen appears.

Expected:

- Logout path is discoverable.
- Confirmation copy is clear.
- Logout returns to unauthenticated state.

Previous known result:

- Logout worked.

### Phase E: Account 2 Signup And Discovery

1. Open signup.
2. Fill account 2 email.
3. Fill account 2 full name.
4. Fill operator-provided shared test password.
5. Capture filled form.
6. Submit signup.
7. Navigate to Home.
8. Verify account 1's newly created tender appears.
9. Capture the tender in account 2 Home.

Expected:

- Account 2 can see public/cross-account tender.
- New tender appears near the top if it is recently created.
- Feed count and category copy are accurate.

Previous known result:

- Account 2 saw account 1's tender.

### Phase F: Account 2 Proposal Attempt

1. Open account 1's tender from account 2 Home.
2. Capture tender details.
3. Tap Apply or equivalent CTA.
4. Capture Offers or proposal entry state.
5. Open proposal sheet.
6. Capture empty proposal sheet.
7. Enter cover letter.
8. Enter delivery time.
9. Confirm amount field is editable.
10. Normalize amount to integer IQD.
11. Capture filled proposal sheet.
12. Submit proposal.
13. Capture success or validation failure.
14. If success, log out account 2 and verify account 1 receives the proposal in Dashboard Inbox or relevant task detail.

Expected:

- Proposal amount accepts integer IQD.
- Decimal-formatted prefill is not used.
- User can edit every required field.
- Successful proposal appears for the client.

Previous known result:

- Blocked by invalid `75000.0` amount handling.

### Phase G: Account 2 Dashboard Audit

1. Navigate to Dashboard.
2. Capture Overview.
3. Tap Bookings.
4. Capture Bookings.
5. Tap Work.
6. Capture Work.
7. Tap Wallet.
8. Capture top wallet.
9. Scroll if needed and capture lower wallet.
10. Tap Inbox.
11. Capture Inbox.
12. Try Received/Sent behavior if present.

Expected:

- Tabs match Open Design: Overview, Bookings, Work, Wallet, Inbox.
- Empty states explain what is empty and where to go next.
- Wallet uses Amber Dusk typography and money formatting.
- Inbox behavior is consistent with standalone Messages.

Previous known result:

- Tabs existed.
- Empty states were passive.
- Dashboard Inbox Sent looked unavailable.

### Phase H: Account 2 Messages Audit

1. Navigate to Messages.
2. Capture Received.
3. Tap Sent.
4. Capture Sent.
5. Open search.
6. Capture search.
7. Search for known account name if data exists.
8. Clear search.

Expected:

- Received and Sent are both available.
- Search scope is clear.
- Empty states are helpful and on-token.

Previous known result:

- Received, Sent, and search opened successfully.

### Phase I: Account 2 Booking Chat

1. Navigate to Home.
2. Open Bookings category/feed.
3. Capture bookings feed.
4. Open a booking card.
5. Capture Booking Details.
6. Start chat with booking provider.
7. Capture empty booking-context chat.
8. Send a short test message.
9. Capture sent message.

Expected:

- Booking card follows Amber Dusk card design.
- Booking Details uses Amber Dusk tokens and IQD formatting.
- Chat context card clearly identifies the booking.
- Message sends and appears in the thread.

Previous known result:

- Message sent.
- Booking Details and Chat were legacy teal/blue.

### Phase J: Account 2 Booking Payment

1. From Booking Details, select Basic package unless testing another package.
2. Tap Book Basic.
3. Capture in-app payment checkout before payment.
4. Confirm amount, service title, package, delivery time, and due date.
5. Tap Pay.
6. Capture processing state.
7. Wait for QiCard webview.
8. Capture empty gateway form.
9. Enter operator-provided test-card data.
10. Capture pre-pay card form only if local evidence is needed.
11. Submit gateway payment.
12. Capture gateway processed result.
13. Return to app.
14. Capture returned Booking Details.
15. Navigate to Dashboard -> Bookings.
16. Capture Bookings after payment.

Expected:

- Checkout uses IQD consistently.
- App frames external gateway handoff clearly.
- Gateway success does not expose raw technical metadata to users.
- App returns to booking confirmation, receipt, or active booking detail.
- Dashboard Bookings shows the new booking.
- Original Booking Details does not still invite the user to book the same package.

Previous known result:

- Gateway processed payment.
- Raw metadata was exposed.
- App returned to unchanged Booking Details with `Book Basic`.
- Dashboard Bookings remained empty.

### Phase K: Account 2 Sends Task-Context Message To Account 1

1. Return to account 1's tender or task detail.
2. Tap chat/message CTA.
3. Capture empty task-context chat.
4. Watch for route transition artifacts.
5. Send a clear test message to account 1.
6. Capture sent message.

Expected:

- Chat route fully covers previous screen.
- Context card clearly identifies the task/tender.
- Message appears in thread.

Previous known result:

- Message sent.
- A left-edge visual offset appeared on chat open.

### Phase L: Account 1 Verifies Received Message

1. Logout account 2.
2. Login account 1.
3. Navigate to Messages.
4. Capture Received.
5. Confirm account 2 appears in the list.
6. Open the thread.
7. Capture thread.
8. Optionally reply to account 2 and capture reply.
9. If reply is sent, log back into account 2 and verify receipt.

Expected:

- Account 1 receives account 2's task-context message.
- Thread opens.
- Message preview and task context are correct.
- Reply delivery works if tested.

Previous known result:

- Account 1 received and opened the account 2 message.
- Reply was not completed in the previous run.

## Targeted Test Suites

Use these when you do not need the full run.

### Suite 1: Auth And Routing, 5-8 Minutes

Run when touching auth, navigation, deep links, onboarding, or route restoration.

Tests:

- T01 invalid login.
- T02 signup form state.
- T03 post-signup landing.
- T04 logout confirmation.
- T05 re-login.

Evidence to capture:

- Login welcome.
- Invalid credentials.
- Filled signup.
- First authenticated landing.
- Logout confirmation.

Known failure to watch:

- Post-signup landing on unrelated Job Details.

### Suite 2: Create Tender And Feed Refresh, 8-12 Minutes

Run when touching Home, Create Post, tasks/tenders, feed ViewModels, realtime refresh, or repository caching.

Tests:

- T10 create post type chooser.
- T11 tender details.
- T12 review preview.
- T13 submit tender.
- T14 poster Home refresh.
- T15 second-account visibility.

Evidence to capture:

- Type sheet.
- Details filled.
- Review card.
- Poster Home after post.
- Account 2 Home with new tender.

Known failure to watch:

- Poster feed stale while second account sees new tender.

### Suite 3: Proposal Submission, 6-10 Minutes

Run first after any proposal, offers, money-input, or tender-detail fix.

Tests:

- T20 open tender as account 2.
- T21 open proposal sheet.
- T22 edit amount.
- T23 submit proposal.
- T24 verify client receives proposal.

Evidence to capture:

- Proposal sheet empty.
- Proposal sheet filled.
- Success or validation.
- Client inbox/task offer state.

Known failure to watch:

- Amount prefilled as decimal string and rejected.

### Suite 4: Dashboard States, 6-10 Minutes

Run after dashboard, wallet, booking state, work state, or inbox changes.

Tests:

- T30 overview.
- T31 bookings empty or populated.
- T32 work empty or populated.
- T33 wallet top.
- T34 wallet lower.
- T35 inbox.

Evidence to capture:

- One screenshot per tab.

Known failures to watch:

- Empty states too passive.
- Dashboard Inbox Sent unavailable.
- Bookings empty after payment.

### Suite 5: Messages And Chat, 8-12 Minutes

Run after message list, realtime chat, chat UI, or route transition changes.

Tests:

- T40 Received.
- T41 Sent.
- T42 Search.
- T43 booking-context chat send.
- T44 task-context chat send.
- T45 cross-account receive.

Evidence to capture:

- Received list.
- Sent list.
- Search open.
- Empty chat.
- Sent chat.
- Receiving account list.
- Receiving account thread.

Known failures to watch:

- Legacy teal/blue chat UI.
- Left-edge route offset.

### Suite 6: Booking Payment, 12-18 Minutes

Run after payment, booking, webview, wallet, checkout, Edge Function, or dashboard booking changes.

Tests:

- T50 bookings feed.
- T51 Booking Details.
- T52 in-app checkout.
- T53 gateway load.
- T54 gateway submit.
- T55 post-return app state.
- T56 Dashboard Bookings after return.

Evidence to capture:

- Booking feed.
- Booking Details.
- Checkout before pay.
- Processing.
- Gateway empty.
- Gateway processed.
- Return state.
- Dashboard Bookings.

Known failures to watch:

- Raw metadata on gateway result.
- App returns to unchanged `Book Basic` state.
- Dashboard Bookings stays empty.
- Currency mismatch between `$` and IQD.

### Suite 7: Amber Dusk Visual Sweep, 10-15 Minutes

Run after token/theme/widget work.

Screens:

- Home.
- Create Post Type/Details/Review.
- Tender Details.
- Offers.
- Proposal sheet.
- Dashboard tabs.
- Messages list.
- Chat.
- Booking Details.
- Payment Checkout.
- Profile.
- Settings/logout.

Check:

- No app-owned teal/blue/purple accents.
- Correct background, text, surface, and button tokens.
- Correct typography roles.
- Bottom nav matches primary destination contract.
- Empty states use Amber Dusk tone and actions.
- Money formatting is consistent.

Known failures to watch:

- Offers, Booking Details, and Chat are legacy.

## Detailed Test Case Matrix

| ID | Name | Start State | Steps | Expected | Previous Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| T00 | Launch app | Simulator running | Start app, observe first route | Auth state is clear | Worked | `01_login_welcome.png` |
| T01 | Invalid login | Logged out | Enter account 1 before signup or invalid credentials | Clear error | Worked | `02_login_invalid_credentials_account1.png` |
| T02 | Signup empty form | Logged out | Open signup | Requirements visible | Worked | `03_signup_form_empty.png` |
| T03 | Account 1 signup | Signup form | Fill account 1 and submit | Deterministic landing | Failed routing expectation | `04`, `05` |
| T04 | Account 1 Home | Authenticated as account 1 | Navigate Home | Home feed visible | Worked | `06` |
| T10 | Create post type | Account 1 Home | Tap create | Type chooser visible | Worked | `07` |
| T11 | Tender details | Type chooser | Select Tender, fill fields | Fields editable, no overlap | Partially worked | `08` |
| T12 | Tender review | Details complete | Continue | Preview matches inputs | Worked | `09` |
| T13 | Submit tender | Review | Submit | New tender visible or confirmed | Poster feed stale | `10` |
| T14 | Logout | Account 1 | Profile -> settings -> logout | Login state returns | Worked | `11`, `12`, `13` |
| T20 | Account 2 signup | Logged out | Fill account 2 and submit | Account 2 authenticated | Worked | `14`, `15` |
| T21 | Cross-account tender visibility | Account 2 Home | Find account 1 tender | New tender visible | Worked | `16` |
| T22 | Tender apply | Account 2 tender detail | Tap apply/offers | Proposal path available | Partially worked | `17`, `18` |
| T23 | Proposal fill | Proposal sheet | Fill cover, delivery, amount | All fields valid/editable | Failed amount validation | `19`, `20`, `21` |
| T30 | Dashboard Overview | Account 2 | Open Dashboard | Overview on-token | Worked | `22` |
| T31 | Dashboard Bookings | Account 2 Dashboard | Tap Bookings | Booking state visible | Empty | `23`, `41` |
| T32 | Dashboard Work | Account 2 Dashboard | Tap Work | Work state visible | Empty | `24` |
| T33 | Dashboard Wallet | Account 2 Dashboard | Tap Wallet | Wallet visible | Worked with notes | `25`, `26` |
| T34 | Dashboard Inbox | Account 2 Dashboard | Tap Inbox | Received/Sent behavior clear | Sent looked unavailable | `27` |
| T40 | Messages Received | Account 2 | Open Messages | Received visible | Worked | `28` |
| T41 | Messages Sent | Account 2 Messages | Tap Sent | Sent visible | Worked | `29` |
| T42 | Messages Search | Account 2 Messages | Open search | Search visible | Worked with note | `30` |
| T50 | Booking feed | Account 2 Home | Tap Bookings | Booking cards visible | Worked | `31` |
| T51 | Booking Details | Booking feed | Open booking | Detail uses Amber Dusk/IQD | Legacy and currency mismatch | `32` |
| T52 | Booking chat | Booking Details | Open chat, send message | Message sends | Worked, legacy UI | `33`, `34` |
| T60 | Checkout | Booking Details | Tap Book Basic | Checkout summary visible | Worked | `35` |
| T61 | Payment processing | Checkout | Tap Pay | Processing visible | Worked | `36` |
| T62 | Gateway entry | Payment | Wait webview, fill card | Gateway usable | Worked | `37`, `38` |
| T63 | Gateway result | Gateway | Submit payment | User-safe success | Raw metadata exposed | `39` |
| T64 | Payment return | Gateway processed | Return app | Booking success/recovery | Failed | `40`, `41` |
| T70 | Task-context chat | Account 2 tender detail | Open chat | Route clean | Visual offset | `42` |
| T71 | Send task message | Account 2 chat | Send message | Message sends | Worked | `43` |
| T72 | Account 1 receives | Account 1 Messages | Open Received | Account 2 visible | Worked | `44` |
| T73 | Account 1 opens thread | Account 1 Messages | Open thread | Message visible | Worked | `45` |

## Known Blockers And Retest Conditions

### Proposal Blocker

Retest only after one of these changes:

- Proposal amount field formatter changed.
- Proposal validation changed.
- Tender budget model or money formatter changed.
- Proposal bottom sheet rewritten.
- Offers/tender detail flow changed.

Minimum retest:

1. Account 2 opens account 1 tender.
2. Account 2 opens proposal sheet.
3. Amount is integer IQD and editable.
4. Proposal submits.
5. Account 1 receives proposal.

### Payment Recovery Blocker

Retest only after one of these changes:

- Payment return handler changed.
- QiCard callback handling changed.
- Booking creation after payment changed.
- Dashboard Bookings ViewModel/service changed.
- Payment Edge Function changed.

Minimum retest:

1. Account 2 opens booking.
2. Account 2 pays through QiCard.
3. Gateway processed result does not expose raw metadata.
4. App returns to success/pending/booking detail.
5. Dashboard Bookings shows the booking.

### Legacy Visual System Blocker

Retest after any Amber Dusk visual pass touching:

- Offers.
- Proposal sheet.
- Booking Details.
- Chat.
- Task details.
- Payment checkout.

Minimum retest:

1. Capture each screen.
2. Compare against Open Design palette.
3. Confirm no app-owned teal/blue/purple accents remain.
4. Confirm typography and spacing match the design system.

## Screenshots To Capture In The Next Full Run

Use this list as the full screenshot contract.

1. Login welcome.
2. Invalid login error.
3. Signup empty.
4. Account 1 signup filled before submit.
5. Account 1 first authenticated landing.
6. Account 1 Home.
7. Create Post type chooser.
8. Tender details filled.
9. Tender review preview.
10. Account 1 Home after submit.
11. Account 1 Profile.
12. Settings/account control logout area.
13. Logout confirmation.
14. Account 2 signup filled before submit.
15. Account 2 Profile or first authenticated landing.
16. Account 2 Home with account 1 tender.
17. Account 2 tender detail.
18. Offers/proposal entry.
19. Proposal sheet empty.
20. Proposal sheet filled.
21. Proposal submit result.
22. Account 1 proposal received state, only after proposal blocker is fixed.
23. Dashboard Overview.
24. Dashboard Bookings before payment.
25. Dashboard Work.
26. Dashboard Wallet top.
27. Dashboard Wallet lower.
28. Dashboard Inbox.
29. Messages Received.
30. Messages Sent.
31. Messages search.
32. Booking feed.
33. Booking Details.
34. Booking-context chat empty.
35. Booking-context chat sent.
36. Payment checkout before pay.
37. Payment processing.
38. QiCard gateway empty.
39. QiCard gateway filled before pay, local/redacted evidence only.
40. Gateway processed result.
41. App return after payment.
42. Dashboard Bookings after payment.
43. Task-context chat empty.
44. Task-context chat sent from account 2.
45. Account 1 Messages Received with account 2 thread.
46. Account 1 opened thread.
47. Account 1 reply sent, if reply path is tested.
48. Account 2 received account 1 reply, if reply path is tested.

## What To Skip When Testing Specific Fixes

Skip payment when testing:

- Signup validation.
- Create Post sheet spacing.
- Messages Received/Sent copy.
- Dashboard Wallet visuals.

Skip signup when testing:

- Payment return.
- Booking Details styling.
- Chat route transition.
- Dashboard Bookings after payment.

Skip cross-account logout/login when testing:

- Pure visual style of one screen.
- Create Post sheet layout.
- Wallet lower coming-soon state.

Do not skip cross-account verification when testing:

- Proposal submission.
- Message delivery.
- Feed visibility.
- Booking state after payment.

## Fast Reproduction Recipes

### Reproduce Proposal Blocker

1. Login as account 2.
2. Go to Home.
3. Open account 1's tender.
4. Tap Apply or proposal entry.
5. Open proposal sheet.
6. Enter cover letter.
7. Enter delivery days.
8. Leave or observe amount field.
9. Submit.

Expected current failure:

- Amount appears as decimal-formatted money and is rejected.

### Reproduce Payment Return Blocker

1. Login as account 2.
2. Go to Home -> Bookings.
3. Open booking listing.
4. Tap Book Basic.
5. Confirm in-app checkout.
6. Pay through QiCard with operator-provided test card.
7. Return to app.
8. Go to Dashboard -> Bookings.

Expected current failure:

- App returns to unchanged Booking Details.
- Dashboard Bookings is empty.

### Reproduce Legacy Chat UI

1. Login as account 2.
2. Open a booking or tender.
3. Tap chat.
4. Capture empty chat and sent chat.

Expected current failure:

- Chat uses teal/blue legacy styling.

### Reproduce Feed Refresh Issue

1. Login as account 1.
2. Create a tender.
3. Submit.
4. Observe account 1 Home immediately.
5. Logout and login as account 2.
6. Observe account 2 Home.

Expected current failure:

- Account 1 does not see the tender immediately.
- Account 2 can see it later.

## Automation Notes

Future automation should prefer user-visible behavior over internal implementation checks.

Recommended automation structure:

- One setup helper for launching simulator and app.
- One auth helper for login/logout/signup.
- One screenshot helper that names files deterministically.
- One flow helper per major domain:
  - AuthFlow
  - CreatePostFlow
  - HomeDiscoveryFlow
  - ProposalFlow
  - DashboardFlow
  - MessagesFlow
  - BookingPaymentFlow
  - ProfileSettingsFlow
- One report helper that maps every screenshot to:
  - test id
  - route/screen
  - account
  - expected state
  - observed state
  - Open Design notes
  - known issue id

Avoid brittle automation that depends on exact widget tree structure. Prefer visible text and accessibility labels. If the app later adds stable test ids or semantic labels, update the automation to use them.

## Manual Notes For The Next Agent

- Do not treat the previous report as proof that the current app still behaves the same way. Re-run targeted tests after code changes.
- Re-check Open Design MCP before doing visual judgement work.
- If payment is tested, record every state before and after the external gateway.
- If proposal is tested, do not stop at the validation error; document whether the amount field can be edited and what keyboard appears.
- If chat is tested, capture the first frame after opening the route if a visual offset appears again.
- If signup routing is tested, capture the exact first screen after submit before navigating away.
- If Dashboard Bookings is empty after payment, capture both the returned Booking Details and Dashboard Bookings.
- If a test is blocked, write the blocker in the notes and do not infer downstream behavior.

## Current Known Issue Register

| Issue ID | Severity | Area | Summary | Primary Screenshots | Retest Suite |
| --- | --- | --- | --- | --- | --- |
| QA-001 | Blocker | Proposal | Amount prefilled as decimal and rejected | `19`, `20`, `21` | Suite 3 |
| QA-002 | Blocker | Payment | Processed payment not reflected in app booking state | `35`-`41` | Suite 6 |
| QA-003 | High | Payment | Gateway processed page exposes raw metadata | `39` | Suite 6 |
| QA-004 | High | Visual system | Offers, Booking Details, and Chat remain legacy teal/blue | `18`, `32`, `33`, `34`, `42`, `45` | Suite 7 |
| QA-005 | High | Auth routing | Signup lands on unrelated Job Details | `05` | Suite 1 |
| QA-006 | High | Home feed | Poster Home does not immediately show new tender | `09`, `10`, `16` | Suite 2 |
| QA-007 | High | Money formatting | Booking details uses dollar semantics while checkout uses IQD | `31`, `32`, `35` | Suite 6 |
| QA-008 | Medium | Dashboard | Empty states lack clear next action | `23`, `24`, `27` | Suite 4 |
| QA-009 | Medium | Dashboard Inbox | Sent mode unavailable in Dashboard Inbox | `27`, `28`, `29` | Suite 4 |
| QA-010 | Medium | Create Post | Details sheet cramped near lower fields | `08`, `09` | Suite 2 |
| QA-011 | Medium | Home copy | Feed labels/counts do not clearly match mixed content | `06`, `16`, `31` | Suite 2 |
| QA-012 | Medium | Chat routing | Left-edge route/render offset on chat open | `42` | Suite 5 |
| QA-013 | Medium | Chat visual | Cross-account chat works but is off-system visually | `43`, `44`, `45` | Suite 5 |
| QA-014 | Medium | Signup validation | Requirements and submit state unclear | `03`, `04`, `14` | Suite 1 |
| QA-015 | Medium | Payment handoff | Vendor handoff lacks strong SLine framing | `35`, `36`, `37` | Suite 6 |
| QA-016 | Low | Messages search | Search scope is not clear | `30` | Suite 5 |
| QA-017 | Low | Wallet | Lower wallet actions expose coming-soon behavior | `25`, `26` | Suite 4 |
| QA-018 | Low | Offers | Empty offers screen has unclear action hierarchy | `18` | Suite 3 |
| QA-019 | Low | Evidence hygiene | Payment screenshot contains test card entry | `38` | Evidence handling |
| QA-020 | Low | Simulator input | Login text-entry friction may be tooling-specific | Not isolated | Suite 1 |

## Definition Of Done For A Future Full QA Pass

A future full QA pass is complete only when:

1. Every test in the full run script has a PASS, PASS_WITH_NOTE, FAIL_KNOWN, FAIL_NEW, BLOCKED, or NEEDS_MANUAL_RECHECK result.
2. Every screenshot in the screenshot contract is either captured or marked not applicable with a reason.
3. Every FAIL_NEW has a concise reproduction path.
4. Every FAIL_KNOWN references an issue id from this file or a newer report.
5. Open Design MCP has been checked during the same session for visual tests.
6. Payment evidence has raw card details redacted before any external sharing.
7. The final report states exactly which account ended logged in and on which screen.
8. No app code is edited during report-only QA runs.
