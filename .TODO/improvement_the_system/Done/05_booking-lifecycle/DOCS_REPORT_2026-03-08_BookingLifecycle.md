# Documentation & Reference-Integrity Report: Booking Lifecycle (05_booking-lifecycle)

**Scope:** 05_booking-lifecycle only.  
**Date:** 2026-03-08  
**Owner:** @SlineDocs  
**Plan reference:** `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md`  
**Execution log:** `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md`

---

## 1. Documentation delta list

What in `Sline_everything/` and `.TODO/` must be updated to reflect: **disputed**, **no_show**, **guard** (client cannot cancel after delivery), **admin RPC** (`admin_resolve_booking_dispute`), **ledger patch** (process_payment_event_ledger allows disputed when admin), **auto-approval ledger** (rpc_finalize_auto_approval booking branch calls process_payment_event_ledger).

| Doc / area | Current state | Required update |
|------------|---------------|-----------------|
| **Sline_everything/AppDigram/All_Diagrams/05_booking-lifecycle.md** | Diagram has no `disputed`, `no_show`; shows `delivered → canceled` by client; code source cites non-existent `booking_screen.dart`. | Add states: disputed, no_show. Change delivered→canceled to delivered→disputed (client); add disputed→completed/refunded (admin), active→no_show. Fix code sources to `payment_checkout_screen.dart` (and optionally bookings_discovery_screen, booking_details_screen). Update verification block: enum includes disputed/no_show; guard blocks client delivered→canceled; rpc_finalize_auto_approval calls ledger; admin_resolve_booking_dispute. |
| **Sline_everything/SUPABASE_SETUP.md** | Enum table (§0) and §4.2 CREATE TYPE omit `disputed`, `no_show`. §4.2 transition diagram allows delivered→canceled by client. fn_booking_guard() body (§9) is old (allows any canceled). No mention of 2026030821* migrations or `admin_resolve_booking_dispute`. | Add `disputed`, `no_show` to booking_status_enum table and CREATE TYPE. Replace transition diagram with guard-aligned one (delivered→disputed for client; no client delivered→canceled). Replace or summarize fn_booking_guard with behavior from `20260308210100_booking_lifecycle_guard.sql`. Add changelog entry and RPC list entry for `admin_resolve_booking_dispute`. Document migrations: 20260308210000, 20260308210100, 20260308210200, 20260308210300, 20260308210400. |
| **Sline_everything/DEVELOPER_GUIDE.md** | Booking table note lists statuses including no_show but not disputed; flow does not mention guard, auto-approval ledger, or admin resolve. | Add `disputed` to app-mapped status list. In Booking Feature Reference, add: client cannot cancel after delivery (use Report Issue); rpc_finalize_auto_approval releases escrow for booking; admin_resolve_booking_dispute for disputed→completed/refunded. |
| **Sline_everything/DEVELOPER_GUIDE/Booking Feature.md** | Status list has no_show but not disputed. Backend objects list does not include fn_booking_guard, rpc_finalize_auto_approval, admin_resolve_booking_dispute. | Add `disputed` to status app-maps. Add to backend: fn_booking_guard (transition rules), rpc_finalize_auto_approval (booking branch + ledger), admin_resolve_booking_dispute. |
| **Sline_everything/MVP_ROADMAP.md** | Section 5 (Booking and Payment Flows) has no mention of lifecycle hardening. | Add note: Booking Lifecycle (2026-03-08): disputed/no_show enum, guard blocks client cancel-after-delivery, rpc_finalize_auto_approval booking ledger, admin_resolve_booking_dispute. Optional: link plan/execution log. |
| **Sline_everything/Sline_Log.md** | No dedicated entry for Booking Lifecycle 2026-03-08. | Add version entry: Booking Lifecycle hardening (enum disputed/no_show, fn_booking_guard, rpc_finalize_auto_approval booking ledger, admin_resolve_booking_dispute, ledger patch). Link plan + execution log. |
| **Sline_everything/STRUCTURE.md** | Recent migration themes do not list Booking Lifecycle. | Add bullet: **Booking Lifecycle (2026-03-08):** 20260308210000 (enum), 20260308210100 (guard), 20260308210200 (rpc_finalize_auto_approval booking ledger), 20260308210300 (admin_resolve_booking_dispute), 20260308210400 (ledger_allow_disputed_booking_admin). Plan: `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md`. |
| **Sline_everything/ARCHITECTURE_ANALYSIS.md** | No booking-lifecycle-specific section. | Optional: one sentence under “Current Live Architecture Notes” that booking lifecycle guard and disputed/no_show are enforced (no change if scope is minimal). |
| **Sline_everything/CODE_REVIEW.md** | No booking-specific pattern. | Optional: add pattern “Guard in service layer for cancel-after-delivery (BookingService + fn_booking_guard)” if desired for reuse. |
| **.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/** | 00_HOLISTIC_REPORT, 01_NOTES, CONTRACT_booking_ledger_mapping.md exist and are consistent. | No change required; CONTRACT and plan refs are valid. |

---

## 2. Reference integrity scan

Every referenced file path, class name, and DB object checked: **exist** or **to be created**.

### 2.1 File paths (code)

| Reference | Location | Status |
|-----------|----------|--------|
| `lib/features/booking/booking_screen.dart` | 05_booking-lifecycle.md (sources, verification) | **BROKEN** — file does not exist. Use `lib/features/booking/view/payment_checkout_screen.dart` (and/or `bookings_discovery_screen.dart`, `booking_details_screen.dart`). |
| `lib/features/work/services/work_management_service.dart` | 05_booking-lifecycle.md | **EXISTS** |
| `lib/core/app_enums.dart` | 05_booking-lifecycle.md, DEVELOPER_GUIDE | **EXISTS**; `BookingStatus.disputed` and `BookingStatus.noShow` present. |
| `lib/features/booking/models/booking_model.dart` | DEVELOPER_GUIDE, ImplementReady | **EXISTS**; _mapDbStatusToEnum includes disputed, no_show. |
| `lib/features/booking/services/booking_service.dart` | DEVELOPER_GUIDE, execution log | **EXISTS**; guard in updateBookingStatus (client + delivered → canceled blocked). |
| `lib/core/utils/status_presenter.dart` | execution log | **EXISTS**; disputed, no_show cases added. |
| `lib/features/booking/view/booking_details_screen.dart` | DEVELOPER_GUIDE | **EXISTS**; disputed/no_show banner cases. |
| `test/unit/booking/booking_guard_contract_test.dart` | execution log, plan | **EXISTS** |

### 2.2 DB objects

| Object | Type | Status |
|--------|------|--------|
| `booking_status_enum` | enum | **EXISTS**; values `disputed`, `no_show` added in `20260308210000_booking_lifecycle_enum.sql`. |
| `fn_booking_guard` | function | **EXISTS**; replaced in `20260308210100_booking_lifecycle_guard.sql` (client delivered→canceled blocked; delivered→disputed; disputed→completed/refunded admin; active→no_show provider/admin). |
| `trg_booking_guard` | trigger | **EXISTS**; documented in SUPABASE_SETUP; fires fn_booking_guard. |
| `process_payment_event_ledger` | RPC | **EXISTS**; patched in 20260308210400 for admin release/refund when booking status = disputed. |
| `admin_resolve_booking_dispute` | RPC | **EXISTS**; `20260308210300_admin_resolve_booking_dispute.sql`. |
| `rpc_finalize_auto_approval` | RPC | **EXISTS**; booking branch calls process_payment_event_ledger in `20260308210200_rpc_finalize_auto_approval_booking_ledger.sql`. |

### 2.3 Plan / execution refs

| Reference | Status |
|-----------|--------|
| `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md` | **EXISTS** |
| `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md` | **EXISTS** |
| `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/CONTRACT_booking_ledger_mapping.md` | **EXISTS** |
| `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/00_HOLISTIC_REPORT.md` | **EXISTS** |
| `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/01_NOTES.md` | **EXISTS** |

---

## 3. Broken refs (exact)

| Broken ref | Exact path / name | Doc / location | Fix |
|------------|-------------------|----------------|-----|
| Non-existent code file | `lib/features/booking/booking_screen.dart` | `Sline_everything/AppDigram/All_Diagrams/05_booking-lifecycle.md` (sources.code, verification block) | Replace with `lib/features/booking/view/payment_checkout_screen.dart` (primary “create booking” UI). Optionally add `bookings_discovery_screen.dart`, `booking_details_screen.dart`. |

No other broken file paths or DB object names found in scope. Plan and execution log paths are valid.

---

## 4. Required doc updates (ordered, owner @SlineDocs)

1. **Sline_everything/AppDigram/All_Diagrams/05_booking-lifecycle.md**  
   - Fix code source: remove `lib/features/booking/booking_screen.dart`; add `lib/features/booking/view/payment_checkout_screen.dart` (and optionally discovery/details).  
   - Update diagram and step-by-step: add states disputed, no_show; delivered→disputed (client), disputed→completed/refunded (admin), active→no_show; remove client delivered→canceled.  
   - Update verification block: enum includes disputed, no_show; fn_booking_guard blocks client delivered→canceled; rpc_finalize_auto_approval booking branch calls ledger; admin_resolve_booking_dispute.

2. **Sline_everything/SUPABASE_SETUP.md**  
   - §0 enums table + §4.2: add `disputed`, `no_show` to `booking_status_enum`.  
   - §4.2: replace status transition diagram with guard-aligned transitions (no client delivered→canceled; delivered→disputed; disputed→completed/refunded; active→no_show).  
   - §9 fn_booking_guard: replace body with summary or updated logic from 20260308210100 (client delivered→canceled raise; delivered→disputed client; disputed→completed/refunded admin; active→no_show provider/admin).  
   - Add RPC `admin_resolve_booking_dispute` to RPC list; add changelog entry for Booking Lifecycle (migrations 20260308210000–20260308210400).

3. **Sline_everything/DEVELOPER_GUIDE.md**  
   - Booking Feature Reference: add `disputed` to app-mapped booking status list.  
   - Add short note: client cannot cancel after delivery (use Report Issue); rpc_finalize_auto_approval releases escrow for booking; admin_resolve_booking_dispute for disputed resolution.

4. **Sline_everything/DEVELOPER_GUIDE/Booking Feature.md**  
   - Status row: add `disputed` to app-maps.  
   - Backend objects: add fn_booking_guard, rpc_finalize_auto_approval (booking branch), admin_resolve_booking_dispute.

5. **Sline_everything/MVP_ROADMAP.md**  
   - Section 5 (Booking and Payment Flows): add note for Booking Lifecycle 2026-03-08 (disputed/no_show, guard, auto-approval ledger, admin RPC). Optional: link plan/execution log.

6. **Sline_everything/Sline_Log.md**  
   - Add version entry for Booking Lifecycle hardening (enum, guard, rpc_finalize_auto_approval booking ledger, admin_resolve_booking_dispute, ledger patch). Link `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md` and `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md`.

7. **Sline_everything/STRUCTURE.md**  
   - Under recent migration themes (supabase/migrations): add Booking Lifecycle (2026-03-08) bullet with migrations 20260308210000–20260308210400 and plan link.

---

## 5. Evidence summary

**Files scanned:**

- `Sline_everything/DEVELOPER_GUIDE.md` (grep + offset read)  
- `Sline_everything/SUPABASE_SETUP.md` (read §0, §4.2, §9 fn_booking_guard, grep for RPCs/migrations)  
- `Sline_everything/STRUCTURE.md` (full read)  
- `Sline_everything/MVP_ROADMAP.md` (full read)  
- `Sline_everything/Sline_Log.md` (grep)  
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` (full read)  
- `Sline_everything/CODE_REVIEW.md` (full read)  
- `Sline_everything/AppDigram/All_Diagrams/05_booking-lifecycle.md` (full read)  
- `Sline_everything/DEVELOPER_GUIDE/Booking Feature.md` (read + grep)  
- `Sline_everything/COMPREHENSIVE_ANALYSIS_SUMMARY.md` (grep)  
- `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md` (read)  
- `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md` (read)  
- `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/00_HOLISTIC_REPORT.md` (read)  
- `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/01_NOTES.md` (read)  
- `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/CONTRACT_booking_ledger_mapping.md` (read)  
- `lib/core/app_enums.dart` (read)  
- `supabase/migrations/20260308210000_booking_lifecycle_enum.sql`, `20260308210100_booking_lifecycle_guard.sql`, `20260308210200_rpc_finalize_auto_approval_booking_ledger.sql`, `20260308210300_admin_resolve_booking_dispute.sql`, `20260308210400_ledger_allow_disputed_booking_admin.sql` (existence + guard body read)  
- `lib/features/booking/view/` (glob: no `booking_screen.dart`; list: bookings_list_screen, booking_details_screen, bookings_discovery_screen, payment_*)

**Exact broken ref:**

- **Path:** `lib/features/booking/booking_screen.dart`  
- **Referenced in:** `Sline_everything/AppDigram/All_Diagrams/05_booking-lifecycle.md` (sources.code and verification block).  
- **Evidence:** Glob and listing of `lib/features/booking/view/` show no file named `booking_screen.dart`. Checkout entry is `payment_checkout_screen.dart`.

---

## 6. Verdict

**Doc OK:** No.  
**Deltas:** Yes — see §1 and §4.  
**BLOCKER:** No. The only invalid reference is the non-existent `booking_screen.dart`; fixing it to `payment_checkout_screen.dart` and applying the listed doc updates is sufficient. DB objects and plan/execution refs exist and are valid; the plan is not invalidated by refs.

**Summary:** One broken code path (05_booking-lifecycle.md → booking_screen.dart). Multiple doc deltas: SUPABASE_SETUP (enum, guard, RPC, migrations), 05_booking-lifecycle (diagram + sources), DEVELOPER_GUIDE + Booking Feature (disputed, guard, RPCs), MVP_ROADMAP, Sline_Log, STRUCTURE. Execute the ordered list in §4 to bring docs in line with Booking Lifecycle (05_booking-lifecycle) implementation.
