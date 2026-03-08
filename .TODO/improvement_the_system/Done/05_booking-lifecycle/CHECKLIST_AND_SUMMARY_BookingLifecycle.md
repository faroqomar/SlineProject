# Booking Lifecycle — Checklist & Summary

**Plan:** `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md` (section H)  
**Scope:** 05_booking-lifecycle hardening (disputed, no_show, guard, admin resolve, ledger)

---

## Part 1: App verification checklist

Use this list to confirm behavior **in the actual app** (device/emulator).

### As **client**

| # | What to do | Expected result | Why |
|---|------------|-----------------|-----|
| 1 | Open a booking that is **delivered** (work submitted, waiting for your approval). | You see **Approve** and **Report Issue**. You do **not** see a **Cancel** button. | Client cannot cancel after delivery; only Report Issue (→ disputed) or Approve (→ completed). |
| 2 | If you had an old build that showed Cancel on delivered: tap Cancel (or trigger status update to canceled). | App shows an error message like *"You cannot cancel after delivery. Use Report Issue to open a dispute."* — and the booking stays **delivered**. No crash. | Service blocks client delivered→canceled; ViewModel shows user message and does not report to crash. |
| 3 | On the same delivered booking, tap **Report Issue** and submit a dispute. | Dispute is created. (Booking may still show as delivered in UI until we optionally add “set status to disputed” after dispute; backend allows delivered→disputed.) | Guard allows client to set delivered→disputed. |
| 4 | Open a booking in status **disputed** (e.g. after Report Issue, or if admin set it). | You see a **disputed** banner/state (orange/amber style) and no Approve/Cancel for delivery. | New status `disputed` is shown in details and cards. |
| 5 | Browse booking list (client or provider). | Any booking with status **disputed** or **no_show** shows the correct label/badge (not “unknown”). | StatusPresenter and booking card handle disputed and no_show. |

### As **provider**

| # | What to do | Expected result | Why |
|---|------------|-----------------|-----|
| 6 | Open a booking that is **active**. | You can mark delivered; depending on product, you may have a way to mark **no-show** (or only admin can). | Guard allows active→no_show for provider or admin. |
| 7 | Open a booking in **disputed** or **no_show**. | Disputed shows disputed banner; no_show shows no_show badge/label. | Same UI as client for new statuses. |

### General

| # | What to do | Expected result | Why |
|---|------------|-----------------|-----|
| 8 | Approve a delivered booking (client). | Booking moves to **completed** and funds release (if payment was held). | Unchanged; rpc_approve_delivery or auto-approval calls ledger. |
| 9 | Wait for auto-approval (or use cron) on a delivered booking past review window. | Booking moves to **completed** and escrow releases. | rpc_finalize_auto_approval booking branch now calls ledger. |

**Admin:** Resolving disputed bookings is done via backend (RPC `admin_resolve_booking_dispute`), not in the app UI. No in-app checklist for admin resolve.

---

## Part 2: What was done (short summary)

### Added

| Where | What | Why |
|-------|------|-----|
| **DB (Supabase)** | Enum values **disputed**, **no_show** on `booking_status_enum`. | So bookings can be in “disputed” or “no-show” state. |
| **DB** | New trigger logic in **fn_booking_guard**: client **cannot** go delivered→canceled; client **can** go delivered→disputed; only **admin** can go disputed→completed or disputed→refunded; provider/admin can set active→no_show. | Prevents griefing (client cancel after delivery); supports Report Issue and admin resolve. |
| **DB** | **rpc_finalize_auto_approval** booking branch now calls **process_payment_event_ledger** when payment is held. | So auto-approved bookings actually release escrow (before: funds could stay stuck). |
| **DB** | New RPC **admin_resolve_booking_dispute**(booking_id, resolution). | So admin can resolve a disputed booking to “completed” (release to provider) or “refunded” (refund to client). |
| **DB** | **process_payment_event_ledger** updated so that for **booking**, when status is **disputed**, an **admin** can call release_with_fee or refund. | So admin_resolve_booking_dispute can move money correctly. |
| **App** | **BookingStatus.disputed** in `app_enums.dart`. | So the app knows the “disputed” state. |
| **App** | **BookingModel** maps DB `disputed` / `no_show` ↔ enum `disputed` / `noShow`. | So we read and write these statuses correctly. |
| **App** | **BookingService** guard: if client tries to set status to **canceled** while booking is **delivered**, we log a warning and **throw StateError** (no Supabase call). | So the app blocks “cancel after delivery” even before the DB trigger. |
| **App** | **BookingViewModel**: when **updateBookingStatus** fails with **StateError** (guard), we log with **AppLogger.w** and **do not** report to crash. | So “cannot cancel after delivery” is not counted as a crash. |
| **App** | **StatusPresenter** and UI: **disputed** and **no_show** get a color and label. | So users see “Disputed” / “No show” instead of unknown. |
| **App** | **Booking details** screen: banner for **disputed**; **booking card**: badge for **disputed**. | So disputed bookings are clearly visible. |
| **App** | **BookingModel.statusToDbString()** and **toJson()** use it for `status`. | So any API write sends DB-safe values (e.g. `no_show` not `noShow`). |
| **Tests** | **booking_guard_contract_test**: expects **StateError** when client tries to cancel a delivered booking. | So we don’t regress the guard. |
| **Docs** | **05_booking-lifecycle.md** updated: diagram (disputed, no_show, no client delivered→canceled), sources, verification. | So the diagram matches real behavior. |
| **Docs** | **SUPABASE_SETUP**: enum, transitions, fn_booking_guard summary, rpc_finalize_auto_approval, **admin_resolve_booking_dispute**, changelog. | So schema and RPCs are documented. |
| **Docs** | **DEVELOPER_GUIDE** & **Booking Feature**: disputed in status list; note that client cannot cancel after delivery; guard, auto-approval, admin RPC. | So devs know the rules. |
| **Docs** | **MVP_ROADMAP**, **Sline_Log**, **STRUCTURE**: Booking Lifecycle 2026-03-08 and migrations. | So roadmap and structure reflect the work. |

### Removed

| Where | What | Why |
|-------|------|-----|
| **UI** | **Cancel** button for the client when the booking is **delivered**. | Client must use Report Issue (→ disputed), not cancel (guard forbids delivered→canceled). |
| **Behavior** | Treating “client cancel after delivery” as an error that gets reported to **CrashReportingService**. | It’s an expected business rule (guard); we only log a warning so it’s not a false crash. |
| **Docs** | Wrong reference to **booking_screen.dart** in 05_booking-lifecycle.md. | File doesn’t exist; replaced with payment_checkout_screen, booking_details_screen, bookings_discovery_screen. |

### Modified

| Where | What changed | Why |
|-------|----------------|-----|
| **DB** | **fn_booking_guard** body replaced. | To enforce: no client delivered→canceled; client can delivered→disputed; only admin disputed→completed/refunded; provider/admin active→no_show. |
| **DB** | **rpc_finalize_auto_approval**: booking branch now builds a stable idempotency key, calls **process_payment_event_ledger('release_with_fee', ...)**, then clears review_expires_at. | So auto-approval actually releases escrow for bookings. |
| **DB** | **process_payment_event_ledger**: **release_with_fee** and **refund** for **booking** now allow status **disputed** when the actor is **admin**. | So admin_resolve_booking_dispute can complete or refund disputed bookings. |
| **App** | **BookingService.updateBookingStatus**: before calling Supabase, if (client + delivered + newStatus==canceled) → AppLogger.w + StateError. | Enforce “no cancel after delivery” in app and give a clear user message. |
| **App** | **BookingViewModel.updateBookingStatus** catch block: if exception is **StateError** → AppLogger.w only (no AppLogger.e, no crash report). | Avoid reporting guard block as a crash. |
| **App** | **BookingModel.toJson()**: `status` now uses **statusToDbString(status)** instead of **status.name**. | So JSON used for API writes has DB-safe status (e.g. no_show). |
| **Docs** | **05_booking-lifecycle.md**: diagram, sources, verification block. | Reflect disputed, no_show, guard, rpc_finalize_auto_approval, admin_resolve_booking_dispute. |
| **Docs** | **SUPABASE_SETUP**: enum table, §4.2 type and transitions, §9 fn_booking_guard, §9.4 rpc_finalize_auto_approval, new §9.4a admin_resolve_booking_dispute, §17 changelog. | Document new and changed DB behavior. |
| **Docs** | **DEVELOPER_GUIDE** and **Booking Feature**: status list, backend objects, short lifecycle note. | Document disputed and lifecycle rules. |
| **Repo** | **dart format** run on touched/format-inconsistent files. | Align with project style. |

---

## Part 3: One-line “why” for the feature

**Before:** Clients could cancel after delivery (griefing/refund abuse); auto-approval didn’t release escrow for bookings; there was no way for admin to resolve disputed bookings.

**After:** Clients cannot cancel after delivery (they use Report Issue → disputed); auto-approval releases escrow for bookings; admin can resolve disputed bookings to completed or refunded via RPC; disputed and no_show are first-class statuses in the app and DB.
