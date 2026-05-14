# Transactional QA Recovery Simulator Smoke Report

Date: 2026-05-13
Device: iPhone 17 simulator, iOS 26.5
Runtime: `flutter run -d 598B6947-2F57-4F22-865A-3E576CB94679 --dart-define=USE_QICARD_PAYMENT=true`
Account observed: `Test One`

## Screenshots Captured

- `screenshots/phase00_baseline_payment_booking_dashboard_chat.png`
- `screenshots/phase03_iqd_proposal_booking_money.png`
- `screenshots/phase04_booking_details_amber.png`
- `screenshots/phase04_chat_thread_amber.png`
- `screenshots/phase04_create_offer_sheet_iqd_teal_remaining.png`
- `screenshots/phase05_create_details_keyboard.png`
- `screenshots/phase06_dashboard_empty_ctas.png`
- `screenshots/phase06_dashboard_inbox_fixed.png`
- `screenshots/phase06_dashboard_work_empty_cta_teal.png`
- `screenshots/phase06_messages_search_guidance.png`
- `screenshots/phase06_wallet_withdraw_disabled.png`
- `screenshots/phase15_payment_vendor_handoff_pre_pay.png`

## Confirmed Fixed Or Improved

- Home discovery labels now read `All posts`, `Booking posts`, and `Tender posts`.
- Home feed count reads `9 items`; Booking mode reads `6 items`.
- Home tender and booking cards show IQD amounts instead of dollar semantics.
- Booking Details package price displays `50K IQD`.
- Payment checkout summary displays `50K IQD`.
- Payment checkout includes QiCard handoff expectation copy before the Pay action.
- Dashboard Bookings empty state now has an action: `Browse booking posts`.
- Dashboard Work empty state now has an action: `Find tender posts`.
- Dashboard Inbox no longer exposes a disabled Received/Sent segmented control. It now frames the tab as `Proposals requiring action` and points full Received/Sent threads to Messages.
- Messages search placeholder now says `Search current mode by name or message...`.
- Wallet withdraw unavailable state is explicit: withdrawals are paused until payout verification is enabled, and the button reads `Withdrawal unavailable`.
- Create Post Details sheet keeps the lower work-type field and bottom actions reachable. Hardware keyboard was active, so no software keyboard rendered in this simulator run.

## Runtime Gaps Found

- Booking Details still contains teal/cyan accents in `Order Timeline & Notes`, especially the note input border, lock icon, divider, send icon, and empty-state text.
- Chat still contains teal/cyan accents in the header offer button, task-context chip, message bubble border, composer border, attachment icon, and send button.
- Create Offer sheet now uses `Amount (IQD)` and `50000`, but still contains teal/cyan accents in the drag handle, labels, active field border, and dimmed chat header offer button.
- Dashboard Bookings, Work, and Inbox CTAs are functional but still teal/cyan rather than Amber Dusk primary.
- Payment checkout has a visible left-edge sliver from the previous route during/after transition.
- Payment checkout still contains teal/cyan accents in the booking note field and secure-payment line.

## Not Completed In This Pass

- The actual `Pay 50K IQD` action was not tapped. Under the Computer Use confirmation policy, the next action creates a booking payment intent and proceeds into the QiCard payment flow, so action-time confirmation is required before proceeding.
- QiCard processed success, return recovery, Dashboard Bookings after payment, and raw metadata suppression were not validated at runtime yet.
- Signup submit and post publish were not performed in this pass because those are externally visible account/post actions in Computer Use. Create Post details ergonomics were checked without publishing.

## Recommended Next Fix Pass

1. Replace remaining teal/cyan accents in Booking Details timeline/note widgets, Chat shell/context/composer/bubble widgets, Create Offer sheet active states, Dashboard empty-state CTA buttons, and Payment checkout note/secure-payment widgets.
2. Fix the payment checkout route transition/background so the previous route is fully covered.
3. After action-time confirmation, run the QiCard payment flow and capture:
   - `phase01_payment_processed_to_app_success.png`
   - `phase02_dashboard_bookings_after_payment.png`
   - `phase08_04_payment_success.png`
   - `phase08_05_dashboard_bookings.png`
