# PLAN_OpenDesign_AmberDusk_TransactionalQARecovery_2026-05-13

## Summary

Fix the VisualQA transactional recovery gaps from the Phase 9-12 iOS simulator report: QiCard payment completion must recover into booking state, payment metadata must stay out of customer UI, money must display as IQD, and transactional surfaces must align with Amber Dusk.

## Evidence

- Source report: `.TODO/VisualQA_OpenDesign_AmberDusk_Phases9_10_11_12_iOSSimulator_2026-05-13/REPORT.md`
- Test map: `.TODO/VisualQA_OpenDesign_AmberDusk_Phases9_10_11_12_iOSSimulator_2026-05-13/APP_TEST_MAP_AND_EXECUTION_GUIDE.md`
- Open Design project: `1674a1db-7a74-4c80-8e2c-196a0385a8f7`
- Open Design anchors: private payment details, create post into matching feed, Dashboard tabs, Messages Received/Sent, no blue/purple accents, IQD labels.
- Sensitive evidence: screenshot `38_qicard_checkout_filled_pre_pay.png` contains test card entry and must stay local or be redacted before sharing.

## Phases

1. Payment completion contract: wire payment intent realtime into `PaymentWebViewScreen`, sanitize callback URLs, recover booking state, and avoid raw metadata UI.
2. Booking/dashboard truth: refresh booking lists and dashboard after held recovery and show success/pending states instead of unchanged purchase CTA.
3. IQD money consistency: remove proposal cents conversions that conflict with live `task_requests.price numeric` IQD and replace dollar labels.
4. Transactional Amber Dusk UI: reskin booking details, offers/proposal sheet, chat shell/context/composer/bubbles.
5. Signup/create-post/home flow: deterministic signup landing, `CreateTaskResult`, post-success Home refresh, and feed copy fixes.
6. Dashboard/messages/wallet fixes: active empty-state actions, no disabled Sent affordance, scoped Messages search guidance, intentional wallet withdraw disabled state.
7. Tests and static checks: focused widget/unit tests, analyzer, and `flutter test`.
8. Simulator QA: screenshot each fixed phase in the new VisualQA folder.
9. Docs and handoff: update only docs that reflect changed behavior and log screenshot/test evidence.

## Acceptance Criteria

- QiCard processed payments land in success, pending, or recoverable retry state.
- Dashboard Bookings shows recovered booking after held payment.
- Customer UI does not expose booking, payer, entity, correlation, or intent metadata.
- SLine-owned transactional UI avoids teal/blue/dollar-era styling.
- Signup lands on Main/Home and post creation visibly refreshes for the poster.
- Money displays are IQD throughout touched transactional surfaces.
- Tests and analyzer pass, or failures are documented with exact blockers.

## Execution Status

- Code/static/test implementation completed on 2026-05-13.
- `flutter analyze --no-fatal-infos`, `git diff --check`, focused affected tests, and full `flutter test` passed.
- Simulator screenshot confirmation remains pending; use `.TODO/VisualQA_OpenDesign_AmberDusk_TransactionalQARecovery_iOSSimulator_2026-05-13/README.md` for required screenshot names.
- Edge Function source was updated locally but not deployed from this session.
