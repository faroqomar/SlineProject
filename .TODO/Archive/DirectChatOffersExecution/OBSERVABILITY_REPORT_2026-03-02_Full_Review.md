# Observability Full Review Report

**Date:** 2026-03-02  
**Scope:** Full_Review (entire codebase: lib/, including direct_offers, dashboard, wallet, booking, and all features)  
**Plan reference:** Plan Missing — Risk Elevated  
**Constraints:** Analysis only; no code changes, no breaking changes, strict MVVM.

---

## 1. Telemetry Gaps

Critical flows that are under-instrumented or not instrumented in a consistent, correlation-friendly way.

### 1.1 Auth

| Flow | Current state | Gap |
|------|----------------|-----|
| Login success | `AppLogger.i("User profile loaded: ${profile['full_name']}")` in `auth_view_model.dart` | **PII risk**: full_name logged. No stable event name; no correlation_id. |
| Login failure | `AppLogger.e('Login failed: $e')` | Raw exception in message; no event_name, no error_code. |
| Register success | No log | No `auth_register_success` or equivalent. |
| Register failure | `AppLogger.e('Registration failed: $e')` | Same as login. |
| Password reset | Success/failure logged generically; no event taxonomy. | No `auth_password_reset_requested` / success. |
| Logout | `AppLogger.e` on failure only; sign-out success not explicitly logged. | No `auth_logout_success`. |
| Session expiry | `AppLogger.w('Session expired - redirecting to login')` in main.dart | Good; could add correlation/session_id for multi-tab. |

**Summary:** Auth has ad-hoc logs but no event taxonomy, no correlation_id, and one PII leak (full_name).

### 1.2 Wallet

| Flow | Current state | Gap |
|------|----------------|-----|
| Balance fetch | No log on success; silent failure returns zero in `wallet_service.dart`. | No `wallet_balance_fetched`; failures not logged. |
| Activity list | No instrumentation. | No event for wallet_activity_list (count, cursor). |
| Withdrawal request | `AppLogger.i` for create + lock (with withdrawalId). | Good; missing correlation_id for multi-step. |
| Withdrawal cancel | `AppLogger.i('Withdrawal request cancelled: $withdrawalId')`. | No correlation_id. |
| Ledger submit | `AppLogger.i('Submitting Ledger Event: ...')` and `AppLogger.e` on failure. | No correlation_id; success path does not log result id (e.g. journal_entry_id). |

**Summary:** Wallet has key operations logged but no standard event names, no correlation_id propagation, and balance/activity fetches are blind.

### 1.3 Booking

| Flow | Current state | Gap |
|------|----------------|-----|
| List (client/provider) | Only catch-block logs; success not logged. | No booking_list_fetched (count, role). |
| Payment draft create | Edge function; client logs in `booking_service.dart` and `payment_checkout_screen.dart` with booking_id/correlation_id. | Correlation present; no stable event_name (e.g. booking_payment_draft_created). |
| Mark delivered / accept / decline | `AppLogger.i` with bookingId in booking_service and work_management_service. | Good; missing correlation_id on some paths. |
| Payment return (web/native) | main.dart and payment_webview_screen log callback params and recovery. | Good; event names ad-hoc. |
| Recovery (direct offer / booking) | Dashboard and direct_offer_details_screen log; qicard_payment_service logs. | Correlation present; no single event taxonomy. |

**Summary:** Booking has correlation_id in payment flows but no standard event list; list and some state transitions lack instrumentation.

### 1.4 Direct Offers

| Flow | Current state | Gap |
|------|----------------|-----|
| Create offer | `AppLogger.i('[DirectOffers] created offer=... conversation=...')`. | No correlation_id; no event_name. |
| Accept without payment | `AppLogger.i('[DirectOffers] acceptOfferWithoutPayment completed offer=...')`. | No correlation_id. |
| Pay now / recover | Service and payment service log with offer_id/correlation_id. | Correlation present; event names not standardized. |
| Reject / cancel / delivered / completed | Each has single-line `AppLogger.i` with offer_id. | No correlation_id; no standard event_name. |

**Summary:** Direct offers are logged per step but without a shared correlation_id across create → accept → pay → deliver → complete, and no stable event taxonomy.

### 1.5 Dashboard

| Flow | Current state | Gap |
|------|----------------|-----|
| Role fetch/update | Logged with tag; role value in message. | No event_name; no user_id in structured form. |
| Work items fetch | `AppLogger.i('Fetched N unified work items')` and error log. | No event_name; no correlation_id; no timing. |
| Activity feed | Error logged; success not. | No activity_feed_fetched. |
| Financial metrics | Debug/info logs in dashboard_repository. | No event_name; no correlation. |
| Web payment return (offer) | Dashboard_screen logs success/failure with offer_id. | Good; could standardize event name. |

**Summary:** Dashboard has operational logs but no event taxonomy, no correlation_id, and no performance (e.g. duration_ms) on heavy fetches.

### 1.6 Chat

| Flow | Current state | Gap |
|------|----------------|-----|
| Start conversation (task/DM) | message_service logs with conversation id. | No correlation_id for “start conversation” flow. |
| Send message | `AppLogger.i('Sent message=... conversation=...')`. | No event_name; no correlation_id. |
| Realtime subscription | Errors logged; no success event. | No chat_realtime_subscribed. |
| Create direct offer (from chat) | chat_view_model logs error; direct_offers_service logs create. | No single correlation_id from chat → offer → payment. |

**Summary:** Chat is well logged for debugging but lacks event taxonomy and correlation_id for multi-step flows (e.g. offer from chat → payment).

### 1.7 Other Features

- **Portfolio:** Good tag usage and json payloads; no event taxonomy or correlation_id.
- **Tasks / Home feed:** Home has structured _logFeedEvent with surface/requestId/duration; task filter has _logFilterEvent. Not aligned with a global event list.
- **Notifications:** Only error logs; no fetch success or mark-read events.
- **Favorites / Saved / Categories:** Minimal or no instrumentation.
- **Profile:** Logs include userId and sometimes paths; no event taxonomy.

### 1.8 Crash & Global Error

- **runZonedGuarded** and **FlutterError.onError** / **PlatformDispatcher.onError** feed AppLogger.e and CrashReportingService (via AppLogger.e). No correlation_id or feature/screen context attached to crash context.
- **CrashReportingService**: Abstract; NoOp implementation. No setUserIdentifier/setCustomKey called from app (no user id or correlation_id on breadcrumbs).

---

## 2. Event Taxonomy

### 2.1 What to Log (Stable Event Names & Structured Fields)

Use **snake_case** event names and consistent fields.

| Domain | Suggested event names | Recommended structured fields (minimal) |
|--------|------------------------|------------------------------------------|
| Auth | `auth_login_success`, `auth_login_failed`, `auth_register_success`, `auth_register_failed`, `auth_logout_success`, `auth_password_reset_requested`, `auth_session_expired` | `event_name`, `timestamp`, `feature=auth`, `severity`, `error_code` (if failed). **No** email, full_name, password. |
| Wallet | `wallet_balance_fetched`, `wallet_activity_list_fetched`, `wallet_withdrawal_request_created`, `wallet_withdrawal_cancelled`, `ledger_event_submitted`, `ledger_event_failed` | `event_name`, `timestamp`, `feature=wallet`, `entity_id` (withdrawal_id/booking_id/offer_id), `correlation_id` when in multi-step flow. |
| Booking | `booking_list_fetched`, `booking_payment_draft_created`, `booking_payment_return_received`, `booking_recovery_completed`, `booking_accepted`, `booking_declined`, `booking_delivered`, `booking_completed` | `event_name`, `timestamp`, `feature=booking`, `booking_id`, `correlation_id`, `screen` (optional). |
| Direct offers | `direct_offer_created`, `direct_offer_accepted`, `direct_offer_pay_started`, `direct_offer_payment_recovered`, `direct_offer_rejected`, `direct_offer_cancelled`, `direct_offer_delivered`, `direct_offer_completed` | `event_name`, `timestamp`, `feature=direct_offers`, `offer_id`, `correlation_id`, `conversation_id` (optional). |
| Dashboard | `dashboard_work_items_fetched`, `dashboard_activity_feed_fetched`, `dashboard_financial_metrics_fetched`, `dashboard_role_updated`, `dashboard_payment_return_handled` | `event_name`, `timestamp`, `feature=dashboard`, `entity_id`/`offer_id`/`booking_id` as relevant, `correlation_id`, `duration_ms` (for fetches). |
| Chat | `chat_conversation_started`, `chat_message_sent`, `chat_realtime_subscribed`, `chat_offer_created` | `event_name`, `timestamp`, `feature=chat`, `conversation_id`, `message_id`/`offer_id` when relevant, `correlation_id` for offer flow. |

All events should include:

- `event_name` (string)
- `timestamp` (ISO or ms)
- `feature` (auth | wallet | booking | direct_offers | dashboard | chat | profile | ...)
- `severity` (info | warn | error)

When part of a multi-step flow (payment, offer lifecycle): `correlation_id` and relevant `entity_id` (booking_id, offer_id, payment_id).

### 2.2 What NOT to Log

- **Secrets / tokens:** access_token, refresh_token, API keys, service role key. (AppLogger already masks access_token/refresh_token in JSON.)
- **PII:** full name, email, phone, address in clear. Redact or omit.
- **Passwords / OTP:** never.
- **Chat content / attachment content / raw file URLs:** never.
- **Raw payment details:** card numbers, CVV; only payment_id, booking_id, offer_id, correlation_id, status, amount (if policy allows) in sanitized form.
- **User id:** use only when required for audit; prefer last 2–4 chars if needed for debugging, or omit in production logs.

**Current PII finding:** `lib/features/auth/viewmodels/auth_view_model.dart` logs `profile['full_name']` on login success. This should be removed or redacted.

---

## 3. Correlation Strategy

### 3.1 Current State

- **Booking payment:** `correlation_id`, `booking_id`, `request_correlation_id` are generated in the client (payment_checkout_screen, booking_view_model), passed to edge functions and payment WebView, and returned in callback URLs. They are logged in payment_webview_screen, payment_return_screen, main.dart, and booking_service. **Good for booking payment flow.**
- **Direct offer payment:** `offer_id`, `correlation_id`, `request_correlation_id` are used in qicard_payment_service and direct_offers_service; recovery passes correlation through. **Partially consistent;** create → accept → pay should share one correlation_id for the full lifecycle.
- **Ledger / wallet:** No correlation_id today; only entity ids (withdrawal_id, booking_id, offer_id). Multi-step flows (e.g. withdrawal request → ledger) would benefit from a single correlation_id.
- **Chat → offer → payment:** No single correlation_id linking “create offer from chat” to “pay now” and “recover”; only offer_id and per-step correlation in payment.

### 3.2 Recommended Strategy

| Flow | Correlation ID source | Propagate to |
|------|------------------------|--------------|
| Booking payment | Generated at “create draft” (client); already in place. | Client logs, WebView callback, payment_return_screen, edge function (body/query), webhook handler. |
| Direct offer lifecycle | Generate at **offer create** (client); store with offer or in memory for session. | Accept, payNow, recoverPaymentAfterCallback, acceptWithPayment, and all client/service logs; edge function and webhook. |
| Wallet withdrawal | Generate at withdrawal request start. | Wallet_service, LedgerService.submitPaymentEvent, and any follow-up (cancel, admin). |
| Chat-originated offer | Same as direct offer: use one correlation_id from offer create through payment and recovery. | ChatViewModel, DirectOffersService, QiCardPaymentService, payment_webview_screen, dashboard recovery. |

**Backend (Supabase):** Edge functions and webhook already receive booking_id/offer_id/correlation_id. Ensure all server-side logs and any audit_logs include correlation_id when present; do not log raw tokens or PII.

---

## 4. Privacy-Safe Logging Plan (AppLogger)

### 4.1 Rules

1. **No print().** Use AppLogger only. (Scan: no print() in lib/.)
2. **Structured payloads:** Prefer `AppLogger.i(message, tag: 'Feature', json: { ... })` with fixed keys (event_name, feature, entity_id, correlation_id, duration_ms, error_code). Avoid free-form messages that might contain PII.
3. **Errors:** Use `AppLogger.e(message, tag: 'Feature', error: e, stackTrace: st)`. Do not interpolate raw exception into message in production; use error_code or sanitized message.
4. **No PII in logs:** Remove or redact full_name, email, phone. Auth success should log only that “login succeeded” with no user identifiers unless redacted (e.g. user_id last 4 chars if required).
5. **Token masking:** AppLogger already masks access_token and refresh_token in JSON; keep this and extend to any other token/key fields if added.
6. **Log level:** Keep `AppLogger.currentLevel = LogLevel.info` in production; use debug only for development. Ensure no sensitive data in info/warn/error.
7. **Crash context:** When integrating a real CrashReportingService implementation, set user identifier (e.g. hashed or last 4 chars) and setCustomKey for correlation_id, feature, screen; never attach tokens or PII.

### 4.2 Placement (MVVM)

- **Log in Services / Repositories:** All Supabase calls, RPCs, and edge function invocations; success/failure and correlation_id/entity_id.
- **Log in ViewModels:** High-level flow outcomes (e.g. “payment recovery started”, “offer accepted”) and user-facing errors; do not log from View layer except in rare cases (e.g. screen open/close with no ViewModel).
- **No Supabase in View:** Views must not call Supabase; logging in views should be minimal (e.g. screen lifecycle only) and never include raw API responses.

---

## 5. Evidence: Key Files Scanned

### 5.1 Documentation

- `Sline_everything/DEVELOPER_GUIDE.md` — Observability §11 (AppLogger, CrashReportingService, runZonedGuarded).
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` — MVVM, data flow.
- `Sline_everything/CODE_REVIEW.md` — Error handling, ErrorMapper.
- `Sline_everything/STRUCTURE.md` — lib/core, lib/features layout.
- `Sline_everything/SUPABASE_SETUP.md` — Tables, RLS, ledger, direct_offers, bookings.

### 5.2 Core

- `lib/core/services/logger_service.dart` — AppLogger API, levels, JSON masking (access_token, refresh_token), CrashReportingService on AppLogger.e, kDebugMode guard.
- `lib/core/services/crash_reporting_service.dart` — Abstract + NoOp; recordError, log, setUserIdentifier, setCustomKey (not used in app).
- `lib/core/services/qicard_payment_service.dart` — Booking/direct offer payment, correlation_id/booking_id/offer_id in params and logs.
- `lib/core/services/payment_service.dart` — PaymentResult/BookingPaymentResult/DirectOfferPaymentResult with correlationId.
- `lib/core/services/payment_pending_store.dart` — bookingId, correlationId stored.
- `lib/core/services/deep_link_service.dart` — AppLogger for navigation and errors.
- `lib/core/config/payment_runtime_config.dart` — payment_id, booking_id, correlation_id in query.
- `lib/core/models/payment_return_args.dart` — correlationId, bookingId, etc.
- `lib/main.dart` — runZonedGuarded, FlutterError.onError, PlatformDispatcher.onError, AppLogger; payment return and session expiry logging; no setUserIdentifier/setCustomKey.

### 5.3 Features

- **Auth:** `lib/features/auth/viewmodels/auth_view_model.dart` — login/register/reset/logout logs; PII (full_name) on login success.
- **Wallet:** `lib/features/wallet/services/wallet_service.dart`, `lib/features/wallet/services/ledger_service.dart` — withdrawal and ledger logs; no correlation_id; balance/activity fetch not logged.
- **Booking:** `lib/features/booking/services/booking_service.dart`, `lib/features/booking/view/payment_checkout_screen.dart`, `lib/features/booking/view/payment_webview_screen.dart`, `lib/features/booking/view/payment_return_screen.dart` — correlation_id and booking_id used and logged.
- **Direct offers:** `lib/features/direct_offers/services/direct_offers_service.dart`, `lib/features/direct_offers/view/direct_offer_details_screen.dart` — offer_id and correlation in payment path; no lifecycle correlation_id.
- **Dashboard:** `lib/features/dashboard/data/dashboard_repository.dart`, `lib/features/dashboard/view/dashboard_screen.dart` — work items, activity feed, financial metrics, role, web payment return; no event taxonomy or correlation.
- **Chat:** `lib/features/chat/services/message_service.dart`, `lib/features/chat/viewmodels/chat_view_model.dart`, `lib/features/chat/view/chat_screen.dart` — conversation/message and offer flows logged; no correlation_id for offer-from-chat.
- **Profile:** `lib/features/profile/viewmodels/profile_view_model.dart`, `lib/features/profile/viewmodels/user_profile_view_model.dart` — logs with userId/tag; no event taxonomy.
- **Portfolio:** `lib/features/portfolio/view/portfolio_screen.dart`, `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart` — AppLogger with tag and json; no event names.
- **Tasks/Home:** `lib/features/home/viewmodels/home_view_model.dart` — _logFeedEvent with surface, requestId, duration_ms. `lib/features/tasks/viewmodels/task_filter_view_model.dart` — _logFilterEvent. No global event list.
- **Work:** `lib/features/work/services/work_management_service.dart` — delivery/booking actions logged with entity id; no correlation_id.

### 5.4 Backend (Supabase)

- `supabase/functions/qicard_webhook_handler/index.ts` — console.log for non-success status; console.error for direct offer handler error; correlationId and offerId/bookingId in flow. No structured event taxonomy.

---

## Summary

| Area | Gaps | Priority |
|------|------|----------|
| Auth | PII in log; no event taxonomy; no correlation | High (privacy + consistency) |
| Wallet | No event taxonomy; no correlation; balance/activity not logged | Medium |
| Booking | Good correlation; missing event names and some list/transition logs | Medium |
| Direct offers | Correlation in payment only; no lifecycle correlation_id; no event names | Medium |
| Dashboard | No event taxonomy; no correlation; no timing on fetches | Medium |
| Chat | No event taxonomy; no correlation for offer-from-chat | Medium |
| Crash / global | No user/correlation context on crash reports | Medium |
| Event taxonomy | Ad-hoc messages; no stable event_name/feature/severity everywhere | High |
| Correlation | Booking/direct-offer payment good; offer lifecycle and wallet need propagation | High |

**Recommendation:** Introduce a single observability plan (event list, correlation strategy, privacy rules) and implement in Services/ViewModels only, without breaking MVVM or existing behavior. Address auth PII and crash context first; then standardize event names and correlation_id for payment and offer lifecycle flows.
