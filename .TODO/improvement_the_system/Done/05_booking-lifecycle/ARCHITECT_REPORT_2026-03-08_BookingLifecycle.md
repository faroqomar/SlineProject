# Architect Report: Booking Lifecycle (05_booking-lifecycle)

**Plan:** `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md` (section H – Corrected Plan)  
**Execution log:** `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md`  
**Contract:** `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/CONTRACT_booking_ledger_mapping.md`  
**Date:** 2026-03-08  
**Scope:** DB migrations, app (enum, model, service, status presenter, booking details, booking card), unit test, contract.

---

## 1. Architecture / Logic Findings (MVVM & Data Flow)

### 1.1 MVVM boundary check

| Layer | File(s) | Finding |
|-------|---------|--------|
| **View** | `booking_details_screen.dart`, `booking_card.dart` | No direct Supabase usage. Uses `context.read<BookingViewModel>()`, `context.read<SafetyViewModel>()`, `UnifiedCtaResolver`. Status updates go via `vm.updateBookingStatus()` (line 434–436, 602–604 in booking_details_screen). **PASS.** |
| **ViewModel** | `booking_view_model.dart` | `updateBookingStatus` delegates to `_repo.updateBookingStatus` (739–741). No Supabase calls. **PASS.** |
| **Repository** | `booking_repository.dart` | Delegates to `_service.updateBookingStatus` (37–42). **PASS.** |
| **Service** | `booking_service.dart` | Only layer that touches Supabase: `_client.from(_bookingsTable).update(...)` (170–175). Guard logic (client cannot cancel delivered) lives here (156–168). **PASS.** |

**Verdict:** Data flow for booking status updates is strictly **View → ViewModel → Repository → Service → Supabase**. No MVVM violations in scope.

### 1.2 Client “Report Issue” (delivered → disputed)

- **UI:** `booking_details_screen.dart` shows “Report Issue” for client when `booking.status` is `active` or `delivered` and no open dispute (366–372, `_ReportIssueGuardBooking`). On tap → `_showDisputeDialog` → `SafetyViewModel.submitDispute(taskId, reason, defendantId)` (471).
- **Backend:** Guard allows `delivered` → `disputed` when `v_is_client` (20260308210100, line 49). App does **not** call `updateBookingStatus(bookingId, BookingStatus.disputed)` after `submitDispute`. So the dispute row is created, but **booking.status remains `delivered`** unless set elsewhere (e.g. trigger or future change).
- **Plan invariant (PlanCritic §D):** “Single source of truth for ‘is this booking disputed?’ = vw_unified_work_items or app uses booking.status = 'disputed'.”  
- **Finding:** Optional app follow-up: after successful `submitDispute` for a booking’s task, call `BookingViewModel.updateBookingStatus(bookingId, BookingStatus.disputed)` so the booking row reflects disputed and aligns with the invariant. Not a blocker: unified work view can derive “disputed” from dispute row on `task_id`.

### 1.3 Client cancel blocked (delivered → canceled)

- **Service:** `booking_service.dart` 156–168: if `newStatus == canceled`, current user is client, and current booking status is delivered → `AppLogger.w` + `throw StateError('You cannot cancel after delivery. Use Report Issue to open a dispute.')`. No Supabase update is attempted.
- **Guard:** 20260308210100 lines 51–53: `NEW.status = 'canceled' AND v_is_client` → `RAISE EXCEPTION`.
- **Flow:** View calls `vm.updateBookingStatus(booking.id, status)` (e.g. 254–256 for “Cancel Booking” when pending only; delivered client has no Cancel button). Any stray call (e.g. from another screen) is blocked in service and would be rejected by guard if it reached DB. **PASS.**

### 1.4 Admin resolve disputed (RPC)

- **RPC:** `admin_resolve_booking_dispute(p_booking_id, p_resolution, p_idempotency_key)` in 20260308210300. Checks `is_admin(auth.uid())`; for `completed` calls `process_payment_event_ledger('release_with_fee', ...)` with stable idempotency key then `UPDATE bookings SET review_expires_at = NULL`; for `refunded` calls ledger `refund` then `UPDATE bookings SET status = 'refunded'`. Booking `status`/`payment_status` for `completed` are updated inside `process_payment_event_ledger` (per SUPABASE_SETUP). Not invoked from in-scope app code; admin path is backend/dashboard. **PASS.**

### 1.5 Auto-approval (rpc_finalize_auto_approval + ledger)

- **Migration:** 20260308210200. Booking branch: `SELECT ... FOR UPDATE`; if `status = 'delivered'` and `review_expires_at` passed and `payment_status = 'held'`, builds stable idempotency key `entity_id || ':release_with_fee:' || _status || ':' || v_payment_status` (no `now()`), calls `process_payment_event_ledger('release_with_fee', 'booking', ...)`, on success clears `review_expires_at` (status/payment_status set in ledger). **PASS.** Aligns with CONTRACT “stable idempotency key” and “FOR UPDATE”.

---

## 2. Data Flow Map (Summary)

| Flow | Entry | View | ViewModel | Service / RPC | DB / Ledger |
|------|--------|------|-----------|----------------|-------------|
| **Client “Report Issue”** | Report Issue button | `_showDisputeDialog` → `SafetyViewModel.submitDispute` | SafetyViewModel | DisputeService (insert dispute) | dispute row created; booking status **not** set to disputed in app (see 1.2) |
| **Client cancel blocked** | Any attempt to set canceled when delivered as client | `vm.updateBookingStatus(id, canceled)` | BookingViewModel → repo | BookingService: guard → StateError before Supabase | No update sent; if sent, fn_booking_guard raises |
| **Admin resolve disputed** | Admin tool (out of app scope) | — | — | RPC `admin_resolve_booking_dispute` | is_admin check → ledger (release_with_fee or refund) → booking updated by ledger/RPC |
| **Auto-approval** | Cron | — | — | `rpc_finalize_auto_approval('booking', id)` | FOR UPDATE → ledger release_with_fee (stable key) → review_expires_at cleared |

---

## 3. Path and Name Validation

### 3.1 Files scanned (in scope)

| Path | Exists | Notes |
|------|--------|-------|
| `supabase/migrations/20260308210000_booking_lifecycle_enum.sql` | Yes | Adds `disputed`, `no_show` to enum |
| `supabase/migrations/20260308210100_booking_lifecycle_guard.sql` | Yes | Replaces `fn_booking_guard` |
| `supabase/migrations/20260308210200_rpc_finalize_auto_approval_booking_ledger.sql` | Yes | Booking branch + ledger |
| `supabase/migrations/20260308210300_admin_resolve_booking_dispute.sql` | Yes | SECURITY DEFINER RPC |
| `supabase/migrations/20260308210400_ledger_allow_disputed_booking_admin.sql` | Yes | Patches `process_payment_event_ledger` |
| `lib/core/app_enums.dart` | Yes | `BookingStatus.disputed` (line 38) |
| `lib/features/booking/models/booking_model.dart` | Yes | `_mapDbStatusToEnum` 'disputed'→disputed, 'no_show'→noShow; `_mapStatusToDb` disputed→'disputed', noShow→'no_show' |
| `lib/features/booking/services/booking_service.dart` | Yes | Guard in `updateBookingStatus`; `_mapStatusToDb` includes disputed, no_show |
| `lib/core/utils/status_presenter.dart` | Yes | `bookingStatusColor`/`bookingStatusLabel` for disputed, noShow |
| `lib/features/booking/view/booking_details_screen.dart` | Yes | Status banner disputed/no_show; Report Issue; no Cancel for client when delivered |
| `lib/features/booking/view/widgets/booking_card.dart` | Yes | Badge for disputed, noShow |
| `test/unit/booking/booking_guard_contract_test.dart` | Yes | Expects StateError on client cancel delivered |
| `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/CONTRACT_booking_ledger_mapping.md` | Yes | Transition → event_type table |

### 3.2 DB objects (referenced in plan/code)

| Object | Migration / doc | Status |
|--------|------------------|--------|
| `bookings` | Table; RLS in SUPABASE_SETUP §7.7 | Exists (doc) |
| `booking_status_enum` | 20260308210000 adds disputed, no_show | Values added |
| `fn_booking_guard` | 20260308210100 CREATE OR REPLACE | Replaced; trigger `trg_booking_guard` remains (SUPABASE_SETUP §4.2, 1414) |
| `process_payment_event_ledger` | 20260308210400 patches body; SUPABASE_SETUP §9.5 | Patched for disputed+admin |
| `admin_resolve_booking_dispute` | 20260308210300 | Created |
| `rpc_finalize_auto_approval` | 20260308210200 | Booking branch + ledger call |

All referenced paths and DB object names are present and consistent.

---

## 4. Contract vs Migrations and Ledger

### 4.1 CONTRACT_booking_ledger_mapping vs implementation

| Contract row | Migration / behavior | Match |
|--------------|----------------------|--------|
| delivered → completed (client or cron) | rpc_finalize_auto_approval: stable key `entity_id::text || ':release_with_fee:' || _status || ':' || v_payment_status`, FOR UPDATE, then ledger | Yes |
| disputed → completed (admin) | admin_resolve_booking_dispute: stable key for release_with_fee; ledger then clears review_expires_at | Yes |
| disputed → refunded (admin) | admin_resolve_booking_dispute: refund + idempotency key; UPDATE status = 'refunded' | Yes |
| active → no_show (provider/admin) | fn_booking_guard allows when v_is_provider OR is_admin | Yes |
| Client cannot delivered → canceled | Guard RAISE + BookingService StateError | Yes |

### 4.2 Ledger patch (20260308210400)

- Patch uses `replace(def, ...)` on `pg_get_functiondef(oid)` for `process_payment_event_ledger`. Replaces exact substrings for (1) release_with_fee gate (allow disputed when booking + admin), (2) release_with_fee actor (allow admin), (3) refund gate (allow disputed when admin), (4) refund actor (allow admin).
- **Risk:** If the live function body differs (whitespace, comments, schema), `replace` may not match and migration can no-op or fail. Recommend verifying against current function body before apply or having a fallback “recreate function” migration.

---

## 5. Proposed Refactors and Risks

### 5.1 Optional refactors

1. **Set booking to disputed after Report Issue:** After `SafetyViewModel.submitDispute` succeeds for a booking’s task, call `BookingViewModel.updateBookingStatus(bookingId, BookingStatus.disputed)` so `booking.status` matches the “disputed” invariant and lists/filters can use it without joining disputes. Low risk; improves consistency.
2. **Diagram sync:** `Sline_everything/AppDigram/All_Diagrams/05_booking-lifecycle.md` still shows “delivered --> canceled: Client Cancels”. Update to remove client path to canceled and add delivered → disputed (Report Issue) and auto-approval → completed.

### 5.2 Risks

| Risk | Mitigation |
|------|------------|
| Ledger patch replace fails on divergent DB | Test migration on copy of production or confirm function body matches replace strings; else provide full CREATE OR REPLACE for process_payment_event_ledger. |
| Admin RPC not exposed in app | By design; admin uses dashboard or SQL. Document in DEVELOPER_GUIDE / runbook. |
| Old app sends canceled after delivery | User gets StateError or guard exception; plan accepts this; UI hides Cancel for delivered client. |

---

## 6. Evidence Summary

- **Files scanned:** All 13 paths listed in §3.1; SUPABASE_SETUP.md (enum, guard, ledger, rpc_finalize_auto_approval); DEVELOPER_GUIDE.md (MVVM); CONTRACT and Plan Critic section H.
- **Key code refs:**  
  - Guard: `booking_service.dart` 156–168 (client cancel block), 170–175 (update).  
  - Guard trigger: `20260308210100` lines 45–54 (delivered), 57–60 (disputed).  
  - Status mapping: `booking_model.dart` 148–176 (`_mapDbStatusToEnum`), 359–378 (`_mapStatusToDb`).  
  - UI status: `status_presenter.dart` 24–26, 43–44 (disputed, noShow); `booking_details_screen.dart` 354–406 (`_buildStatusBanner`), 364–372 (Report Issue).  
- **Test:** `booking_guard_contract_test.dart` expects StateError containing “cannot cancel after delivery” when client updates to canceled for a delivered booking.

---

## 7. Verdict

**APPROVED** for the Booking Lifecycle hardening scope (05_booking-lifecycle, Plan Critic section H).

- MVVM boundaries are respected; data flow is View → ViewModel → Service → Supabase for status updates.
- Client cannot cancel a delivered booking (service guard + DB trigger); client can open dispute (Report Issue); admin RPC and auto-approval ledger behavior match the contract.
- Paths, class names, and DB objects referenced in plan and code exist and are consistent.
- Contract and migrations align; only recommendation is optional app update to set `booking.status = disputed` after Report Issue and to update the booking-lifecycle diagram. Ledger patch dependency on exact function body is a known deployment risk to validate per environment.

---

*End of Architect Report.*
