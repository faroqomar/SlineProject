# Execution Log: Booking Lifecycle Hardening (Plan Critic)

**Plan:** `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md` (section H – Corrected Plan)  
**Started:** 2026-03-08  
**Executor:** @Executor | AppLogger + Supabase MCP required

---

## Status by Phase

| Phase | Status | Notes |
|-------|--------|-------|
| 0 – Data/Contracts & Prerequisites | Done | Contract + Live DB (MCP) + test baseline |
| 1 – Database & Security | Done | Enum + guard + rpc_finalize + admin RPC + ledger patch applied via MCP |
| 2 – App Layer (MVVM) | Done | BookingStatus.disputed; guard in BookingService; AppLogger |
| 3 – UI | Done | StatusPresenter + booking_details_screen disputed/no_show |
| 4 – QA & Release | In Progress | Guard contract test passes; booking unit tests pass |
| 5 – Release & Rollback | Documented | Rollback in plan |

---

## Evidence & Findings (Pre-Execution Scan)

### Evidence (what exists)
- `Sline_everything/DEVELOPER_GUIDE.md`, `SUPABASE_SETUP.md`, `MVP_ROADMAP.md`, `STRUCTURE.md`, `ARCHITECTURE_ANALYSIS.md`, `CODE_REVIEW.md` — paths confirmed.
- `lib/features/booking/`: booking_service.dart (uses AppLogger), booking_model.dart, viewmodels, view.
- `lib/core/app_enums.dart`: BookingStatus has noShow, no disputed yet.
- `lib/core/services/logger_service.dart`: AppLogger.d/i/w/e with tag.
- `booking_status_enum` in docs: pending, confirmed, in_progress, canceled, completed, paid_request_pending, active, delivered, refunded, expired_unanswered (no disputed, no no_show in DB).
- `process_payment_event_ledger`: supports booking; event_types include release_with_fee, refund, escrow_hold, gateway_escrow.
- Supabase project_id: `isddrknbjsgaantjojhm` (SUPABASE_SETUP.md).

### Gaps (what must be created)
- CONTRACT_booking_ledger_mapping.md.
- Enum values: disputed, no_show.
- fn_booking_guard rewrite (delivered→canceled block for client; delivered→disputed; disputed→completed/refunded; active→no_show).
- rpc_finalize_auto_approval booking branch: confirm/add ledger call.
- admin_resolve_booking_dispute RPC (or equivalent).
- BookingStatus.disputed in Dart; _mapDbStatusToEnum for 'disputed'.
- Guard test (client delivered→canceled fails).
- AppLogger in all new/critical booking paths.

### Risks
- Live DB may differ from docs; MCP execute_sql requires linked project.
- Migration order: enum first, then trigger.

### Observability notes
- AppLogger in BookingService, WorkManagementService, BookingViewModel for status updates and errors.
- Plan requires booking status transition audit (admin_logs/work_logs or doc).

---

## Phase 0: Data/Contracts & Prerequisites

### Step 0.1 – Contract (Backend/APIContract)
- **Agent:** APIContract / Executor  
- **Action:** Create CONTRACT_booking_ledger_mapping.md.

### Step 0.2 – Live DB confirmation (Supabase_Ops)
- **Agent:** Supabase MCP / Executor  
- **Action:** Query enum values, fn_booking_guard, rpc_finalize_auto_approval.

### Step 0.3 – Test baseline (Sentinel)
- **Agent:** Sentinel / Executor  
- **Action:** Define guard test (path, run command, expected result).

### Step 0.4 – Decisions recorded
- No_show: provider or RPC only; client → dispute.
- Admin resolve: new RPC admin_resolve_booking_dispute.

---

## Completed Steps (Detail)

### Phase 0
- **0.1 Contract:** Created `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/CONTRACT_booking_ledger_mapping.md` with transition → event_type table. Verified against SUPABASE_SETUP.
- **0.2 Live DB (Supabase MCP):** Queried `booking_status_enum` (no disputed/no_show); retrieved `fn_booking_guard` and `rpc_finalize_auto_approval` bodies. Confirmed booking branch of rpc_finalize_auto_approval did not call ledger → fixed in Phase 1.
- **0.3 Test baseline:** Added `test/unit/booking/booking_guard_contract_test.dart`. Run: `flutter test test/unit/booking/booking_guard_contract_test.dart`. Expects StateError when client cancels delivered booking.

### Phase 1
- **1.1 Enum:** Applied via MCP `apply_migration` (name: booking_lifecycle_enum): ADD VALUE 'disputed', 'no_show'.
- **1.2 fn_booking_guard:** Applied via MCP (name: booking_lifecycle_guard). Blocks client delivered→canceled; allows delivered→disputed (client), disputed→completed/refunded (admin), active→no_show (provider/admin).
- **1.3 rpc_finalize_auto_approval:** Applied via MCP (name: rpc_finalize_auto_approval_booking_ledger). Booking branch now calls process_payment_event_ledger('release_with_fee', ...) when payment_status=held, then clears review_expires_at.
- **1.4 admin_resolve_booking_dispute:** Applied via MCP `apply_migration` (name: admin_resolve_booking_dispute). Admin-only RPC to resolve disputed booking to completed (release_with_fee) or refunded.
- **1.5 Ledger patch (disputed admin):** Applied via MCP `apply_migration` (name: ledger_allow_disputed_booking_admin). `process_payment_event_ledger`: release_with_fee allows status `disputed` when `p_related_entity_type = 'booking'` and `public.is_admin(v_actor_user_id)`, and actor may be admin; refund allows status `disputed` when admin and actor may be admin. Repo migration: `supabase/migrations/20260308210400_ledger_allow_disputed_booking_admin.sql`.

### Phase 2
- **2.1 Models:** Added `BookingStatus.disputed` in `lib/core/app_enums.dart`. `BookingModel._mapDbStatusToEnum` maps 'disputed' → disputed; `_mapStatusToDb` maps disputed → 'disputed'.
- **2.2 Services:** `BookingService.updateBookingStatus` — guard: if newStatus==canceled and current user is client and current booking status is delivered, AppLogger.w + throw StateError (user message: use Report Issue). AppLogger.i on success, AppLogger.e on failure (existing).
- **2.3 ViewModels:** No change; guard in service prevents client cancel-after-delivery.

### Phase 3
- **3.1 UI:** `StatusPresenter.bookingStatusColor` / `bookingStatusLabel`: added disputed, no_show. `booking_details_screen.dart` _buildStatusBanner: added case BookingStatus.disputed. Report Issue already shown for client when delivered (no Cancel after delivery).

### Phase 4
- **Guard test:** `flutter test test/unit/booking/booking_guard_contract_test.dart` — **PASS**. AppLogger.w "Blocked client from canceling delivered booking" observed.
- **Booking unit tests:** `flutter test test/unit/booking/` — **11 tests passed.**

---

## Blockers

*(None yet.)*

---

## Rollback Triggers

- Phase 1: Revert trigger migration; keep enum. Revert rpc_finalize_auto_approval if changed.
- App: Revert app; backend can stay.
