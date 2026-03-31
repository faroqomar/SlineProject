# CodeGuard Review Report: Booking Lifecycle (05_booking-lifecycle)

**Date:** 2026-03-08  
**Scope:** Booking Lifecycle hardening (enum, guard, rpc_finalize_auto_approval, admin_resolve_booking_dispute, ledger patch, app layer, UI, test, contract)  
**Plan reference:** `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md`, `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md`

---

## Scope

| Item | Value |
|------|--------|
| **Change Type** | HIGH (payments, booking state machine, RLS/guard, SECURITY DEFINER RPCs) |
| **Areas** | DB (migrations), MVVM (models, service, view, widgets), Test, Contract |
| **Files Reviewed** | 5 migrations, 6 app files, 1 test file, 1 contract doc |

### Files Scanned

- **DB:** `supabase/migrations/20260308210000_booking_lifecycle_enum.sql`, `20260308210100_booking_lifecycle_guard.sql`, `20260308210200_rpc_finalize_auto_approval_booking_ledger.sql`, `20260308210300_admin_resolve_booking_dispute.sql`, `20260308210400_ledger_allow_disputed_booking_admin.sql`
- **App:** `lib/core/app_enums.dart`, `lib/features/booking/models/booking_model.dart`, `lib/features/booking/services/booking_service.dart`, `lib/core/utils/status_presenter.dart`, `lib/features/booking/view/booking_details_screen.dart`, `lib/features/booking/view/widgets/booking_card.dart`
- **Test:** `test/unit/booking/booking_guard_contract_test.dart`
- **Contract:** `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/CONTRACT_booking_ledger_mapping.md`
- **Docs:** `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/CODE_REVIEW.md` (relevant sections)

---

## Evidence Collected

| Check | Result |
|-------|--------|
| `flutter analyze` (lib paths above) | No issues found |
| `flutter test test/unit/booking/` | 11 tests passed (includes `booking_guard_contract_test.dart`) |
| `dart format --set-exit-if-changed` (booking + status_presenter) | 3 files were reformatted (booking_details_screen, payment_webview_screen, dashboard_booking_card) — recommend running `dart format .` and committing |
| Docs scanned | DEVELOPER_GUIDE, SUPABASE_SETUP (§4.2, §5.9, §7.7, §9.4, §9.5, fn_booking_guard, process_payment_event_ledger), CODE_REVIEW |
| Web freshness | Not required for this scope (no new external deps; Supabase/Flutter usage unchanged) |

---

## Risk Rating (per area)

| Area | Rating | Notes |
|------|--------|--------|
| **Security** | Low | RLS on bookings unchanged; guard + admin RPC + ledger gates enforced; no secrets/PII in logs |
| **Data integrity** | Low | Idempotency keys stable; guard blocks client delivered→canceled; double-release mitigated |
| **Performance** | Low | No N+1 in touched code; trigger is per-row; RPCs use FOR UPDATE and single-row ops |
| **Compatibility** | Low | Additive enum; app maps new statuses; guard backward-compatible |

---

## 1. Security

### 1.1 RLS for bookings

- **Evidence:** SUPABASE_SETUP §7.7 — `bookings_select_parties` (SELECT), `bookings_insert_client` (INSERT), `bookings_update_status_only` (UPDATE), `bookings_deny_delete` (DELETE). No policy changes in this feature; guard runs in trigger context (same session, so RLS still applies to the underlying UPDATE).
- **Verdict:** No new RLS policies; existing policies remain least-privilege (client/provider only). Guard does not bypass RLS; it only restricts which status transitions are allowed.

### 1.2 admin_resolve_booking_dispute: SECURITY DEFINER and is_admin check

- **Evidence:** `20260308210300_admin_resolve_booking_dispute.sql`:
  - `SECURITY DEFINER` + `SET search_path TO public`.
  - First check: `IF v_admin_id IS NULL OR NOT public.is_admin(v_admin_id) THEN RAISE EXCEPTION 'Only admin can resolve a disputed booking';`
- **Verdict:** Admin-only enforced at RPC entry; non-admin callers get a clear exception. No service_role or anon usage in client code.

### 1.3 process_payment_event_ledger gates (disputed + admin)

- **Evidence:** `20260308210400_ledger_allow_disputed_booking_admin.sql`:
  - release_with_fee: gate allows `v_booking_status = 'disputed'` when `p_related_entity_type = 'booking'` and `public.is_admin(v_actor_user_id)`; actor check allows admin in addition to client.
  - refund: gate allows disputed when admin; actor check allows admin in addition to provider/client.
- **Verdict:** Ledger gates correctly allow disputed→completed/refunded only when actor is admin; no relaxation for non-admin.

### 1.4 No secrets or PII in logs

- **Evidence:** `BookingService` uses `AppLogger.i/w/e` with tag `'Booking'`; messages reference `bookingId`, `newStatus`, and generic text ("Blocked client from canceling delivered booking"). No `client_id`, `provider_id`, or payment details in log messages.
- **Verdict:** No secrets or PII in logs in the reviewed paths.

---

## 2. Data integrity

### 2.1 Idempotency in ledger and rpc_finalize_auto_approval

- **Evidence:**
  - `20260308210200_rpc_finalize_auto_approval_booking_ledger.sql`: idempotency key = `encode(extensions.digest(entity_id::text || ':release_with_fee:' || _status || ':' || v_payment_status, 'sha256'), 'hex')` — no `now()`, so retries reuse the same key.
  - `20260308210300_admin_resolve_booking_dispute.sql`: completed key = `p_booking_id::text || ':release_with_fee:disputed:' || v_booking.payment_status`; refund key = `...':refund:disputed:' || v_booking.payment_status` — both stable.
- **Verdict:** Idempotency keys are deterministic; double-release on retry is prevented.

### 2.2 Guard prevents client delivered→canceled

- **Evidence:** `20260308210100_booking_lifecycle_guard.sql` (lines 51–54): `IF NEW.status = 'canceled' AND v_is_client THEN RAISE EXCEPTION 'Invalid booking status transition: client cannot cancel a delivered booking; use Report Issue';`
- **App guard:** `BookingService.updateBookingStatus` (lines 155–167): if `newStatus == canceled` and current user is client and current status is delivered, logs and throws `StateError` with user-facing message before calling Supabase.
- **Verdict:** DB trigger and app-layer guard both enforce the rule; contract test asserts the app guard.

### 2.3 Double-release prevention

- **Evidence:** rpc_finalize_auto_approval uses `FOR UPDATE` on the booking row before computing the idempotency key and calling `process_payment_event_ledger`. admin_resolve_booking_dispute uses `FOR UPDATE` and stable keys. CONTRACT_booking_ledger_mapping.md states idempotency key pattern and “no now()”.
- **Verdict:** FOR UPDATE + stable keys + ledger idempotency prevent double-release.

---

## 3. Performance

- **N+1:** No new loops over collections that trigger per-item DB calls in the reviewed code. `listBookingsAsClient` / `listBookingsAsProvider` / `getBookingById` / `updateBookingStatus` are single-query or one fetch + one update.
- **Trigger cost:** `fn_booking_guard` runs per row on BEFORE UPDATE; logic is simple (status/actor checks). No heavy queries inside the trigger.
- **Heavy queries:** Not introduced. RPCs use single-row SELECT ... FOR UPDATE and single-row UPDATE; no full-table scans added.
- **Verdict:** No N+1 or significant performance regressions in scope.

---

## 4. Compatibility

- **Enum:** Additive only (`disputed`, `no_show`); existing rows and code paths unchanged.
- **App:** `BookingStatus.disputed` and existing `noShow` mapped in `_mapDbStatusToEnum` and `_mapStatusToDb`; StatusPresenter and UI handle both.
- **Verdict:** Backward compatible; old app may still attempt cancel-after-delivery and receive DB/app error (documented acceptable behavior).

---

## 5. Verification commands

| Command | Purpose |
|---------|---------|
| `flutter analyze lib/core/app_enums.dart lib/features/booking/ lib/core/utils/status_presenter.dart` | Static analysis on changed files |
| `flutter test test/unit/booking/` | Unit + guard contract tests |
| `dart format .` | Apply project formatting (3 files were not formatted before review) |

**Suggested SQL/RLS checks (manual or CI):**

- Confirm enum values: `SELECT unnest(enum_range(NULL::booking_status_enum));` — should include `disputed`, `no_show`.
- As a client, attempt `UPDATE bookings SET status = 'canceled' WHERE id = <delivered_booking_id> AND client_id = auth.uid();` — expect trigger to raise.
- As admin, call `admin_resolve_booking_dispute(<disputed_booking_id>, 'completed', <idempotency_key>)` and verify booking moves to completed and ledger has one release_with_fee.

---

## 6. Blockers

**None.** No BLOCKERs identified; all Critical and HARD-GATE checks pass.

---

## Warnings (should fix / improve)

1. **BookingModel.toJson() status serialization**  
   - **Where:** `lib/features/booking/models/booking_model.dart` line 88: `'status': status.name`  
   - **Issue:** For `BookingStatus.noShow`, `status.name` is `'noShow'`; DB value is `'no_show'`. If this map is ever sent to the API for an update, the backend would receive the wrong value.  
   - **Suggestion:** Use a DB-safe serializer for status when sending to the backend (e.g. reuse `_mapStatusToDb` or a static helper). Keep `toJson()` aligned with DB for any field used in writes.  
   - **Owner:** Implementer / Architect  

2. **Ledger patch migration fragility**  
   - **Where:** `supabase/migrations/20260308210400_ledger_allow_disputed_booking_admin.sql`  
   - **Issue:** Uses `replace(def, ...)` on `pg_get_functiondef(oid)` for `process_payment_event_ledger`. If the live function body has different whitespace, comments, or casing, the replace may not match and the migration could leave the function partially or incorrectly patched.  
   - **Suggestion:** Prefer a full CREATE OR REPLACE of the ledger function in a migration (or a versioned patch that checks function body hash) so behavior is deterministic across environments.  
   - **Owner:** Supabase_Ops / Backend  

3. **Formatting**  
   - **Evidence:** `dart format --set-exit-if-changed` reformatted 3 files (e.g. `booking_details_screen.dart`).  
   - **Suggestion:** Run `dart format .` and commit so CI and future reviews don’t flag formatting.  
   - **Owner:** Implementer  

---

## Passed checks

- RLS on bookings unchanged and sufficient; guard does not weaken security.
- admin_resolve_booking_dispute: SECURITY DEFINER, is_admin check at entry, resolution restricted to completed/refunded.
- process_payment_event_ledger: disputed allowed only when admin for release_with_fee and refund; actor checks include admin.
- No secrets or PII in AppLogger usage in booking lifecycle paths.
- Idempotency: stable keys in rpc_finalize_auto_approval and admin_resolve_booking_dispute; FOR UPDATE used.
- Guard: client cannot set delivered→canceled (DB trigger + app guard); contract test enforces app guard.
- No N+1 or heavy new queries; trigger is lightweight.
- Enum additive; app and DB status mapping consistent for disputed/no_show.
- flutter analyze clean; flutter test test/unit/booking/ all passed.
- CONTRACT_booking_ledger_mapping.md aligns with plan and SUPABASE_SETUP (event_types, idempotency pattern).

---

## Risk notes

- **Threat model:** Client cannot cancel after delivery (griefing/refund abuse); no_show only from provider or admin; disputed resolution only via admin RPC. Guard and RPCs enforce this.
- **Regression:** If the guard trigger is reverted or relaxed, client delivered→canceled could reappear; the unit test in `booking_guard_contract_test.dart` protects the app-side guard only; DB-side should be covered by migration/rollback and optional SQL test.

---

## Dependency status

- No new dependencies in this feature. Existing Supabase/Flutter usage unchanged.  
- Outdated / deprecated / security advisories: not run for this scope (no dependency changes).

---

## Final decision

**APPROVED**

No blockers; security (RLS, admin RPC, ledger gates, no secrets in logs), data integrity (idempotency, guard, double-release prevention), performance, and compatibility are satisfied. Address the three warnings (toJson status, ledger patch robustness, formatting) in follow-up work.

---

## Next actions

1. Run `dart format .` and commit any formatting changes.
2. (Optional) Add SQL or integration test that client UPDATE delivered→canceled raises at DB (in addition to existing Dart guard test).
3. (Optional) Harden ledger patch migration (full function replace or versioned patch) and align BookingModel.toJson status with DB for any write path.
