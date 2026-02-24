# CodeGuard Review Report: Tender Payment Flow

**Date**: 2026-02-24  
**Scope**: Two-step Award → Payment flow for task tenders  
**Change Type**: HIGH (payments, wallet, booking states)  
**Areas**: DB/RPC, MVVM, UI, Ledger, WebView

---

## Scope

- **Change Type**: HIGH
- **Areas**: UI / MVVM / DB / RLS / Ledger / Storage / WebView
- **Files Reviewed**: 15+ (migrations, services, viewmodels, views)

---

## Evidence Collected

- **Commands run**: `flutter analyze` — 5 issues (deprecations, BuildContext async gap)
- **Docs scanned**: CODE_REVIEW.md, SUPABASE_SETUP.md, TENDER_PAYMENT_VERIFICATION_CHECKLIST.md
- **Web freshness**: Not performed (focused on security/logic)

---

## Critical Issues (BLOCKERS)

### 1. Ledger/DB Flow Mismatch — Payment Will Fail

**Location**: `lib/features/tasks/services/task_service.dart` lines 548–576  
**Risk**: `payAwardedOffer` calls `pay_awarded_offer` RPC first (sets `payment_status='held'`), then `LedgerService.submitPaymentEvent(escrow_hold)`. The ledger `escrow_hold` gate requires `status='pending'` AND `payment_status='unpaid'` (see `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql` lines 155–164). After the RPC, `payment_status` is already `'held'`, so the ledger call will fail with `ERR_GATE_NOT_ALLOWED`.

**Additional**: Tender flow uses QiCard (external gateway), not wallet balance. The correct event is `gateway_escrow`, not `escrow_hold`. `gateway_escrow` also expects `status='pending'` (line 1043), but awarded offers have `status='accepted'`.

**Fix**: Either:
- Add a new ledger event (e.g. `gateway_escrow_awarded`) that accepts `status='accepted'` and `payment_status='unpaid'` for `task_request`, or
- Reorder: call ledger (`gateway_escrow`) first, then `pay_awarded_offer` RPC, and extend `gateway_escrow` to allow `status='accepted'` for `task_request`.

**Owner**: @Supabase_Ops + @Architect

---

### 2. Inbox "Pay Now" Calls Wrong Handler

**Location**: `lib/features/dashboard/view/tabs/inbox_tab.dart` lines 102–104  
**Risk**: When `showPay` is true (status=accepted, payment_status=unpaid), `onAccept` is `() => vm.acceptOffer(offer)`. `acceptOffer` calls `escrowHoldOffer`, which expects `status='pending'`. The "Pay Now" action should navigate to `TenderPaymentScreen`, not call `acceptOffer`.

```dart
onAccept: offer.status == OfferStatus.pending && isClient && !_isAwarding
    ? () => _handleAwardOffer(context, vm, offer)
    : () => vm.acceptOffer(offer),  // Wrong for "Pay Now"
```

**Fix**: Add a separate `onPay` callback for awarded-unpaid offers that navigates to `TenderPaymentScreen`. Pass `onPay` when `showPay` is true.

**Owner**: @Architect

---

### 3. "Pay Later" Flow Has No UI Entry Point

**Location**: `lib/features/dashboard/viewmodels/dashboard_view_model.dart`, `lib/features/dashboard/data/dashboard_repository.dart`  
**Risk**: `fetchClientAwardedUnpaidOffers()` exists but is never called from `_loadData()`. Inbox uses `getOffersReceived`, which only fetches `status='pending'`. After award, the offer disappears from inbox. If the client taps "Pay Later", there is no UI to complete payment later.

**Fix**: Call `fetchClientAwardedUnpaidOffers()` in dashboard load and surface awarded-unpaid offers in a "Pending Payment" section (e.g. next actions or inbox).

**Owner**: @Architect

---

### 4. `task_requests` Schema vs Ledger Expectation

**Location**: `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql`, `supabase/migrations/20260225_create_wallet_views.sql`  
**Risk**: Ledger RPC and `vw_unified_payable_items` expect `task_requests` to have `client_id`, `provider_id`, `amount_gross`. SUPABASE_SETUP.md documents `task_requests` with `task_id`, `freelancer_id`, `price` only. If these columns are missing, ledger and views will fail.

**Fix**: Confirm schema; add migration to add `client_id`, `provider_id`, `amount_gross` (or equivalent) to `task_requests` if missing.

**Owner**: @Supabase_Ops

---

### 5. QiCard Webhook Does Not Support Task Requests

**Location**: `supabase/functions/qicard_webhook_handler/index.ts` lines 234–241  
**Risk**: Webhook hardcodes `p_related_entity_type: "booking"`. Tender flow passes `requestId` (task_request id) as `booking_id`. Webhook would look up a booking with that ID and fail or process the wrong entity.

**Fix**: Detect entity type from `additionalInfo` (e.g. `entity_type` or `booking_id` vs `request_id`) and call ledger with `p_related_entity_type: "task_request"` when appropriate.

**Owner**: @Supabase_Ops

---

## Warnings (Should Fix)

### 6. BuildContext Used Across Async Gap

**Location**: `lib/features/tasks/view/tender_payment_screen.dart` line 81  
**Risk**: `Navigator.of(context).push` is called after `await` without checking `mounted`. Widget may be disposed.

**Fix**: Add `if (!mounted) return;` before navigation, or use a `mounted` check before `Navigator.push`.

---

### 7. Error Message May Leak Internal Details

**Location**: `lib/features/tasks/view/tender_payment_screen.dart` line 120  
**Risk**: `_errorMessage = 'Payment failed: ${e.toString()}'` can expose stack traces or internal errors to users.

**Fix**: Use `ErrorMapper.map(e)` or a safe user-facing message instead of raw `e.toString()`.

---

### 8. `cleanup_expired_awards` Callable by Any Authenticated User

**Location**: `supabase/migrations/20260226_tender_award_payment_flow.sql` lines 373–416  
**Risk**: Function has `SECURITY DEFINER` but no restriction to cron/service role. Any user could trigger cleanup.

**Fix**: Add `IF auth.role() != 'service_role' AND auth.role() != 'postgres' THEN RAISE EXCEPTION` or restrict via RLS/GRANT so only cron can execute.

---

### 9. No Transaction Wrapping in `pay_awarded_offer`

**Location**: `supabase/migrations/20260226_tender_award_payment_flow.sql` lines 169–278  
**Risk**: Multiple UPDATEs and INSERTs are not wrapped in an explicit transaction. A failure mid-flow could leave inconsistent state (e.g. task updated but request not).

**Fix**: Wrap the body in `BEGIN ... COMMIT` with `EXCEPTION` handler for rollback. (Pl/pgSQL functions run in an implicit transaction, but explicit handling improves clarity and error handling.)

---

### 10. Deprecated API Usage

**Locations**:
- `lib/features/dashboard/view/tabs/inbox_tab.dart:104` — `acceptOffer` deprecated
- `lib/features/tasks/view/tender_payment_screen.dart:226` — `withOpacity` deprecated (use `withValues`)
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart:613` — missing deprecation message
- `lib/features/tasks/viewmodels/task_requests_view_model.dart:149` — missing deprecation message

**Fix**: Replace deprecated APIs; add deprecation messages where required.

---

## Passed Checks

- RPC functions use `SECURITY DEFINER` and validate `auth.uid()` / task ownership
- No SQL injection (parameters are bound)
- `pay_awarded_offer` checks payment deadline and auto-cancels expired awards
- `award_task_offer` prevents double-accept (checks for existing accepted offer)
- PaymentWebViewScreen has `mounted` and `_isDisposed` guards
- `PopScope` and back handling in WebView are correct
- QiCard credentials use `String.fromEnvironment` (not hardcoded in production)
- Error handling uses `AppLogger` and `ErrorMapper` in services
- MVVM separation is respected (View → ViewModel → Service)

---

## Risk Notes

- **Threat model**: Payment state machine can be bypassed if ledger and DB get out of sync. Double-payment risk if client retries after partial success.
- **Regression**: Changing ledger event order or adding new event types may affect bookings flow.

---

## Dependency Status

- Not audited for this review.

---

## Final Decision

**BLOCKED**

**Next actions**:
1. Fix ledger/DB flow (Critical #1) before enabling tender payments.
2. Fix inbox "Pay Now" handler (Critical #2).
3. Add "Pay Later" UI entry point (Critical #3).
4. Verify `task_requests` schema and QiCard webhook support (Critical #4, #5).
5. Address warnings (#6–#10) for robustness and maintainability.
