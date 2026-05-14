# SESSION_PLAN_OpenDesign_AmberDusk_TransactionalQARecovery_2026-05-13

## Planner Notes

- Implementation started from the Phase 9-12 VisualQA report and the Open Design Amber Dusk project.
- The current worktree already contains unrelated Phase 9-12 profile/secondary readiness edits; implementation must preserve those changes.
- Supabase table reality was previously confirmed for `payment_intents`, `payment_events`, `orphan_payments`, `bookings`, and `task_requests`.
- Supabase Edge Function listing was unavailable through the connector during execution; local `supabase/functions/` files are the implementation source until live function access is restored.

## Session Evidence To Append

- Screenshot folder: `.TODO/VisualQA_OpenDesign_AmberDusk_TransactionalQARecovery_iOSSimulator_2026-05-13/screenshots/`
- Test commands:
  - `dart format <changed dart files>` — passed, 31 files checked, 0 changed after final patch.
  - `flutter analyze --no-fatal-infos` — passed, no issues found.
  - `git diff --check` — passed.
  - `flutter test test/widget/booking/payment_checkout_screen_test.dart test/widget/booking/payment_return_screen_test.dart test/unit/core/payment_runtime_config_test.dart test/unit/viewmodels/submit_request_view_model_test.dart` — passed.
  - `flutter test test/widget/home/home_screen_test.dart test/widget/dashboard/inbox_tab_test.dart test/widget/wallet/wallet_shared_body_test.dart test/widget/chat/messages_screen_test.dart test/widget/auth/signup_screen_test.dart` — passed.
  - `flutter test test/widget/tasks/submit_request_sheet_test.dart` — passed after updating the IQD amount-field expectations.
  - `flutter test test/widget/tasks/task_details_screen_test.dart test/widget/chat/offer_message_bubble_test.dart` — passed after updating IQD and Amber Dusk structural expectations.
  - `flutter test` — passed; machine reporter summary: `success=true`, `1578` visible tests done, `30` skipped.
- Simulator evidence:
  - Partial pass captured with Computer Use on iPhone 17 simulator, iOS 26.5.
  - Report: `.TODO/VisualQA_OpenDesign_AmberDusk_TransactionalQARecovery_iOSSimulator_2026-05-13/SIMULATOR_SMOKE_REPORT.md`
  - Payment submit/recovery screenshots remain pending because `Pay 50K IQD` requires action-time confirmation under the Computer Use policy.

## Implementation Summary

- Payment return handling now trusts the app-held payment intent state instead of exposing customer-facing raw gateway metadata. `PaymentWebViewScreen` receives the intent stream, can pop itself on realtime success, and sanitized callbacks recover through trusted widget state or `PaymentPendingStore`.
- Booking recovery now refreshes booking lists after held payment recovery and keeps unknown gateway states recoverable instead of treating them as hard failure.
- Customer-facing payment finish URLs in `qicard_payment_create` and `create_payment_intent` were sanitized; technical IDs remain in metadata for webhook/log handling.
- Proposal/request, booking package, direct-offer, dashboard, wallet, and touched chat surfaces now use IQD display semantics in the changed paths.
- Signup success resets to `/main` with Home selected, and create-post completion returns a `CreateTaskResult` so Main navigation can refresh Home and show durable success feedback.
- Dashboard empty states now expose route-back CTAs; Dashboard Inbox no longer renders a disabled Sent mode; Messages search clarifies current-mode scope; Wallet withdraw is intentionally disabled with availability copy.

## Remaining Gate

- Full payment simulator VisualQA remains open. Required screenshots are listed in `.TODO/VisualQA_OpenDesign_AmberDusk_TransactionalQARecovery_iOSSimulator_2026-05-13/README.md`.
- Edge Functions were edited locally but not deployed from this session; live function listing/deploy still needs authenticated Supabase access.

### [2026-05-14 01:20:01 +03] SYSTEMEVOLUTION INPUT — POST-FIX SIMULATOR CHECK

- Current-app screenshots captured in `.TODO/VisualQA_OpenDesign_AmberDusk_TransactionalQARecovery_iOSSimulator_2026-05-14/screenshots/`.
- The focused chat composer and create-offer amount field were rechecked because the prior smoke report found teal/cyan inherited field styling. Captures `07_chat_empty_composer_amber_fixed.png`, `08_create_offer_sheet_amber_fixed.png`, and `09_chat_empty_composer_amber_final.png` show the interactive controls after the fix.
- Dashboard booking buckets were rechecked because a canceled QiCard draft had appeared in an active-style position during recovery testing. Capture `11_dashboard_bookings_closed_not_upcoming.png` shows the terminal booking under Closed rather than Upcoming.
- Current verification from the fixing pass: targeted teal/cyan scans passed, `git diff --check` passed, `flutter analyze --no-fatal-infos` passed, and `flutter test` passed.
- Residual payment gate: the final QiCard gateway Pay submission was still not replayed end-to-end in this pass, so processed-payment success callback verification remains a separate runtime branch until the external gateway action is executed again.
