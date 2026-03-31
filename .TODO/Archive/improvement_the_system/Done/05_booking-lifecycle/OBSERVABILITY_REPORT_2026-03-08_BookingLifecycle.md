# Observability Report: Booking Lifecycle (05_booking-lifecycle)

**Scope:** Booking Lifecycle hardening (05_booking-lifecycle)  
**Plan reference:** `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md`, `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md`  
**Date:** 2026-03-08  
**Agent:** Observability (SLineObservability)

---

## 1. Telemetry Gaps

### 1.1 What IS logged today (app layer)

| Location | Line(s) | Level | Message / Trigger |
|----------|---------|--------|-------------------|
| **BookingService** (`lib/features/booking/services/booking_service.dart`) | 161–163 | `AppLogger.w` | "Blocked client from canceling delivered booking" — when client attempts cancel on delivered booking (guard block). Tag: `Booking`. |
| | 177–180 | `AppLogger.i` | "Updated booking $bookingId status to $newStatus" — on successful status update. Tag: `Booking`. |
| | 184–190 | `AppLogger.e` | "Failed to update booking status for $bookingId" — on non-StateError failures (Supabase/network). Tag: `Booking`. StateError is rethrown and not logged here (183). |
| | 46–51, 79–85, 106–111, 138–143, 204–209, 224–230, 255–259, 283–288, 306–311, 354–359 | `AppLogger.e` | Various: list client/provider bookings, get pending, create draft, getBookingById, escrow hold, approveAndRelease, decline, markDelivered, acceptBooking failures. Tag: `Booking`. |
| | 124–126, 222–225, 248–251, 280–284, 302–305, 352–353 | `AppLogger.i` | create draft call, escrow hold, approveAndRelease, decline, markDelivered, acceptBooking success. Tag: `Booking`. |
| | 327–330, 341–346 | `AppLogger.w` | "Promoting pending held booking before accept"; "Blocked accept booking due to invalid state" (with json). Tag: `Booking`. |
| **BookingViewModel** (`lib/features/booking/viewmodels/booking_view_model.dart`) | 751–757 | `AppLogger.e` | "Failed to update booking $bookingId status to $newStatus" — called for **all** caught errors in `updateBookingStatus`, including **StateError** (guard block). Tag: `Booking`. **Side effect:** `AppLogger.e` triggers `CrashReportingService.instance.recordError` (logger_service.dart:177–181), so guard blocks are reported as crashes. |
| | 164, 235–240, 296–301, 314–319, 342–347, 360–365, 392, 517–522, 617–622, etc. | `AppLogger.e` / `AppLogger.w` / `AppLogger.i` | getBookingById, escrowHold, releaseBookingWithFee, acceptBooking, declineBooking, markDelivered, cancelBookingDraftIfUnpaid, _refreshBookingInLists, contactProvider, and other flows. Tag: `Booking`. |

**Evidence (exact log lines):**

- Guard block: `booking_service.dart:159–166` — `AppLogger.w('Blocked client from canceling delivered booking', tag: 'Booking');` then `throw StateError(...)`.
- Success: `booking_service.dart:176–179` — `AppLogger.i('Updated booking $bookingId status to $newStatus', tag: 'Booking');`
- Service error path: `booking_service.dart:182–190` — `if (e is StateError) rethrow; AppLogger.e('Failed to update booking status for $bookingId', ...)`.
- ViewModel catch-all: `booking_view_model.dart:749–758` — `bookingsError = _mapError(e); AppLogger.e('Failed to update booking $bookingId status to $newStatus', error: e, stackTrace: st, tag: 'Booking'); return false;`

### 1.2 What is NOT logged (gaps)

| Flow | Where it happens | Logged from app? | Note |
|------|-------------------|------------------|------|
| **DB trigger: fn_booking_guard** | `supabase/migrations/20260308210100_booking_lifecycle_guard.sql` | No | Backend only. Trigger raises exception (e.g. "client cannot cancel a delivered booking; use Report Issue"); no server-side log to app. App only sees PostgrestException if client somehow sent delivered→canceled. |
| **Admin resolve disputed booking** | RPC `admin_resolve_booking_dispute` — `supabase/migrations/20260308210300_admin_resolve_booking_dispute.sql` | No | Not invoked from in-scope app code; admin path is backend/dashboard. No app logging for admin resolve. |
| **Auto-approval (cron)** | `rpc_finalize_auto_approval` — `supabase/migrations/20260308210200_rpc_finalize_auto_approval_booking_ledger.sql` | No | Invoked by pg_cron (or equivalent); no app involvement. No app logging. |
| **process_payment_event_ledger** | DB function (ledger) | No | Backend only; no app logging. |
| **Client opens dispute (Report Issue)** | `SafetyViewModel.submitDispute` from `booking_details_screen.dart` | Not in booking scope | Dispute submission is in safety feature; booking lifecycle report does not require booking-specific log for "dispute submitted for booking" (optional enhancement). |
| **User-facing status change in UI** | `booking_details_screen.dart` _updateStatus → VM.updateBookingStatus | No log in View | Correct: no logging in UI layer. SnackBar shows "Status updated" / "Failed to update status". |

---

## 2. Event taxonomy

### 2.1 Tags

- **Booking** — used for all booking service and view model log calls in scope.

### 2.2 Event types / log messages (booking lifecycle–relevant)

| Event / message | Level | Tag | When |
|-----------------|--------|-----|------|
| Blocked client from canceling delivered booking | W | Booking | Client attempted cancel on delivered booking (service guard). |
| Updated booking &lt;id&gt; status to &lt;status&gt; | I | Booking | Status update succeeded. |
| Failed to update booking status for &lt;id&gt; | E | Booking | Status update failed (Supabase/network or StateError rethrown to VM). |
| Failed to update booking &lt;id&gt; status to &lt;status&gt; | E | Booking | Same, from ViewModel. |
| Marked booking &lt;id&gt; as delivered | I | Booking | markDelivered success. |
| Failed to mark booking &lt;id&gt; as delivered | E | Booking | markDelivered failure. |
| Accepted booking &lt;id&gt; | I | Booking | acceptBooking success. |
| Failed to accept booking &lt;id&gt; | E | Booking | acceptBooking failure. |
| Blocked accept booking due to invalid state | W | Booking | Accept attempted in invalid state (with json: booking_id, status, payment_status). |
| Promoting pending held booking before accept | W | Booking | Accept path promoted pending→paid_request_pending→active. |
| Escrow hold submitted for booking &lt;id&gt; | I | Booking | escrowHold success. |
| Approve and release submitted for booking &lt;id&gt; | I | Booking | approveAndRelease success. |
| Decline and refund submitted for booking &lt;id&gt; | I | Booking | declineBooking success. |
| Failed to release funds for booking &lt;id&gt; | E | Booking | releaseBookingWithFee failure. |
| Canceled orphan unpaid booking draft: &lt;id&gt; | I | Booking | cancelBookingDraftIfUnpaid success. |
| Failed to cancel unpaid draft booking=&lt;id&gt; | W | Booking | cancelBookingDraftIfUnpaid failure. |
| Failed to refresh booking &lt;id&gt; | W | Booking | _refreshBookingInLists failure. |

No separate event names (e.g. `booking_status_update_success`) are used; messages are free-form with tag `Booking`.

---

## 3. Privacy-safe logging plan

### 3.1 Safe to log

- **booking_id (UUID)** — entity identifier; not PII by itself; needed for correlation and support. **Verdict:** OK to log.
- **status / newStatus** — enum-like values (e.g. `delivered`, `canceled`). **Verdict:** OK.
- **feature/screen** — e.g. `feature: booking`, `screen: booking_details`. **Verdict:** OK (not in use today; optional).
- **Error codes** (e.g. Postgrest 23505), sanitized DB messages. **Verdict:** OK.
- **Stack traces** — only for real errors; avoid for expected guard block (see §5). **Verdict:** OK when no secrets.

### 3.2 Do NOT log

- **client_id / provider_id** — user identifiers; avoid in logs unless redacted (e.g. last 2–4 chars only) per policy. **Current code:** booking_id is logged; client_id/provider_id are not logged in booking lifecycle messages. **Verdict:** Keep as-is.
- **Secrets, tokens, payment details, chat content.** **Verdict:** Not logged in booking flows.
- **Full task content, requirements, note.** **Verdict:** Not logged.

### 3.3 Recommendation

- Keep logging **booking_id** and **status** for status updates and guard block.
- Do **not** add client_id/provider_id to log messages; if needed for debugging, use last 2–4 chars and document in privacy policy.

---

## 4. Correlation strategy

### 4.1 Current state

- **No correlation_id** is generated or propagated for "user tapped Cancel on delivered booking → guard block → log".
- Flow is traceable only by **timestamp + tag "Booking" + message + booking_id** (and optionally user session in crash tool if error is reported).

### 4.2 Recommendation

- For **single-step** flows (e.g. one status update), **booking_id + timestamp** is enough to correlate service log and ViewModel log.
- For **multi-step** flows (e.g. book → pay → accept → deliver → approve), consider:
  - Generating a **correlation_id** (e.g. UUID) at the start of a user-initiated flow (e.g. in ViewModel when entering booking details or starting status update).
  - Passing it through service calls (e.g. optional parameter or thread-local) and including it in every AppLogger call for that flow.
- **Short term:** No change required for current scope; correlation by booking_id + time is sufficient for guard block and status update.
- **Long term:** Add correlation_id to critical booking flows (e.g. payment hold → accept → deliver → release) for incident tracing.

---

## 5. Recommendations

### 5.1 BLOCKER: Guard block reported as crash

- **Issue:** When the client taps Cancel on a delivered booking, `BookingService` correctly logs `AppLogger.w` and throws `StateError`. `BookingViewModel.updateBookingStatus` catches the exception and calls `AppLogger.e(..., error: e, stackTrace: st)`. `AppLogger.e` invokes `CrashReportingService.instance.recordError` (logger_service.dart:177–181), so **every guard block is reported as a crash**.
- **Fix:** In `BookingViewModel.updateBookingStatus`, when the caught exception is `StateError` (e.g. guard message contains "cannot cancel after delivery"), do **not** call `AppLogger.e` (or call `AppLogger.w` without reporting to crash). Optionally log once at warning: e.g. `AppLogger.w('Booking status update rejected (guard)', tag: 'Booking', error: e)` so it is observable but not reported as a crash.
- **Evidence:** `booking_view_model.dart:749–758`; `logger_service.dart:176–181`.

### 5.2 Optional: _mapError for StateError

- **Current:** `_mapError` does not special-case `StateError`; it returns `e.toString()`, so the user sees "You cannot cancel after delivery. Use Report Issue to open a dispute." **Verdict:** UX is correct; no change required for user message.
- **Optional:** Add an explicit branch for `StateError` in `_mapError` to return a stable user message and document that this path is an expected business rule, not a bug.

### 5.3 Admin resolve

- **Current:** `admin_resolve_booking_dispute` is backend-only (RPC); not called from app. No app logging.
- **Recommendation:** If an admin UI is added later, log there: e.g. `AppLogger.i('Admin resolved disputed booking', tag: 'Booking', json: { 'booking_id': id, 'resolution': completed|refunded })` (no admin user PII). DB-side audit (e.g. admin_logs or trigger) is out of app scope but recommended in plan (Phase 1.5).

### 5.4 Auto-approval and dispute flow

- **Auto-approval:** Invoked by cron; no app log. Rely on DB/ledger audit and optional DB trigger for transition audit (plan Phase 1.5).
- **Dispute flow:** Client "Report Issue" goes through `SafetyViewModel.submitDispute`; no booking-specific event today. Optional: add a booking-scoped log when dispute is submitted for a booking (e.g. in VM or service when task_id is linked to booking) for funnel analytics.

### 5.5 Test and log assertion

- **Current:** `test/unit/booking/booking_guard_contract_test.dart` expects `StateError` with message containing "cannot cancel after delivery"; it does **not** assert on AppLogger output.
- **Evidence:** Execution log: "AppLogger.w 'Blocked client from canceling delivered booking' observed" (manual). Test file: lines 90–99 — `throwsA(isA<StateError>().having(...))`.
- **Recommendation:** Keep test as-is (behavior contract). If desired, add a test that verifies no crash report is sent for guard block (e.g. mock CrashReportingService and assert it is not called for StateError from updateBookingStatus).

---

## 6. Evidence summary (files scanned)

| File | Purpose |
|------|--------|
| `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md` | Plan and Phase 2.4 observability gate. |
| `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md` | Execution evidence (AppLogger in service, guard test). |
| `lib/features/booking/services/booking_service.dart` | All AppLogger.w/i/e for guard, status update, list, get, escrow, approve, decline, markDelivered, acceptBooking. |
| `lib/features/booking/viewmodels/booking_view_model.dart` | updateBookingStatus catch logs AppLogger.e for all errors; _mapError; other booking flows. |
| `lib/features/booking/view/booking_details_screen.dart` | No AppLogger; UI only (SnackBar, Report Issue, status banner). |
| `lib/features/booking/view/widgets/booking_card.dart` | No AppLogger; status badge and display only. |
| `lib/core/services/logger_service.dart` | AppLogger.e calls CrashReportingService.recordError. |
| `supabase/migrations/20260308210100_booking_lifecycle_guard.sql` | fn_booking_guard; no app logging. |
| `supabase/migrations/20260308210300_admin_resolve_booking_dispute.sql` | Admin RPC; not called from app. |
| `supabase/migrations/20260308210200_rpc_finalize_auto_approval_booking_ledger.sql` | Cron-triggered; no app logging. |
| `test/unit/booking/booking_guard_contract_test.dart` | Expects StateError; no log assertion. |

---

## 7. Summary

| Verdict | Description |
|--------|-------------|
| **BLOCKER** | Guard block (client cancel after delivery) is logged with `AppLogger.e` in ViewModel and thus reported to CrashReportingService as a crash. This produces false positives. **Fix:** In `BookingViewModel.updateBookingStatus`, treat `StateError` (guard) as expected; use `AppLogger.w` or skip error log and do not report to crash. |
| **Gaps** | (1) No correlation_id for multi-step booking flows. (2) Admin resolve and auto-approval have no app-side logs (acceptable; backend-only). (3) Optional: DB trigger or admin_logs for status transition audit (plan Phase 1.5). (4) Optional: booking-scoped event when dispute is submitted for a booking. |
| **Observability OK** | Guard block is correctly logged at **service** level with `AppLogger.w`. Status update success/failure (non-guard) is logged in service (i/e) and ViewModel (e). Tag "Booking" is consistent. booking_id in logs is privacy-acceptable. No PII in current booking lifecycle log messages. |

**Required follow-up:** Resolve BLOCKER (stop reporting guard block as crash from ViewModel).
