# Plan Critic: Booking Lifecycle Hardening (05_booking-lifecycle)

**Source plan:** `.TODO/PLAN_BookingLifecycle_2026-03-08.md`  
**Critic workflow:** `.agents/workflows/plan_critic.md`  
**Date:** 2026-03-08

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (inferred)

- Stack: Flutter + Supabase (Postgres, RLS, triggers, RPC). No other backend.
- Team can run Supabase MCP or SQL against live/linked project to confirm enum and trigger body.
- Dispute resolution for bookings reuses existing `disputes` table (task_id = booking’s task_id); no new `booking_id` on disputes.
- Admin “resolve disputed booking” is either existing admin flow (update dispute + then update booking via RPC) or a new RPC; plan assumes one of these exists or will be added.
- `rpc_finalize_auto_approval` is invoked by pg_cron or equivalent for bookings; plan does not add a new cron job, only fixes the function body if needed.
- Test baseline: existing RLS tests under `test/rls/`; no dedicated booking guard tests yet. New tests will be added in same repo (unit/DB/integration as appropriate).
- Single branch / main-focused workflow unless stated otherwise; doc updates in same PR as code.

### Decision Needed (Blocking)

| # | What decision is missing | Options | Recommended | What changes in plan |
|---|--------------------------|---------|------------|----------------------|
| 1 | Who can set `active` → `no_show` and how? | (A) Only provider or system (B) Client sets no_show → auto-create dispute (C) Only admin after evidence | **B**: Client “no show” creates dispute; admin or RPC later can set status to `no_show` after resolution. | Guard: allow `active`→`no_show` only when `auth.uid() = provider_id` OR from SECURITY DEFINER RPC; client path goes to dispute. Plan adds explicit step for no_show RPC/guard and UI “Report no-show” → dispute. |
| 2 | How does admin resolve a disputed booking (set `disputed` → `completed` or `refunded`)? | (A) Direct UPDATE on `bookings` with admin RLS bypass (B) New RPC `admin_resolve_booking_dispute(booking_id, resolution)` (C) Existing dispute resolution flow only updates dispute; booking status updated by trigger or separate step | **B**: New or existing RPC that checks admin, then updates booking status and calls ledger. | Plan must add Backend step: define RPC (or document existing one) for disputed→completed/refunded and ledger; Guard must allow these transitions only from that RPC (or admin role in guard). |
| 3 | Where does booking status transition audit go? | (A) `admin_logs` (B) `work_logs` (C) New table `booking_audit_log` | **A or B**: Use existing `admin_logs` or `work_logs` if schema supports entity_type + event; otherwise extend. | Plan adds Observability step: one migration or trigger to write transition events; artifact = DDL or trigger + doc. |

---

## B) Gate Status (Pass/Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|--------------------------|
| **0) Test Infrastructure** | ❌ FAIL | No explicit test harness for booking guard; no fixture/manifest for booking states; no run command or artifact path for DB tests. | Add step: define test directory (e.g. `test/db/` or `test/unit/booking_guard_test.dart`), fixture (e.g. seed booking rows with status), run command (`flutter test test/...` or SQL test script), and failure artifact path. |
| **1) Data/Contracts** | ❌ FAIL | Ledger mapping contract is “create file” but exact shape (which event_type per transition) not specified; `process_payment_event_ledger` signature and allowed event_types for booking not verified in plan. | Add: Contract artifact with table (old_status, new_status, actor, event_type, idempotency rule). Verify against SUPABASE_SETUP process_payment_event_ledger; add step to confirm allowed event_types for `related_entity_type = 'booking'`. |
| **2) Security** | ⚠️ CONDITIONAL | Guard and RLS are specified but “admin or RPC” for disputed→completed is vague; no explicit RLS check for who can UPDATE bookings to disputed/no_show. | Add: Explicit permission matrix (client / provider / admin / RPC) per transition; ensure guard rejects client delivered→canceled; add RLS test (allowed + forbidden) for booking updates. |
| **3) Backend/API** | ❌ FAIL | `rpc_finalize_auto_approval` booking branch may not call ledger — not confirmed; no explicit step to read current function body and add ledger call. | Add: Step 1.3.1 “Inspect rpc_finalize_auto_approval booking branch; if no process_payment_event_ledger call, add it with same pattern as rpc_approve_delivery and stable idempotency key.” Output: migration file. Stop condition: booking auto-approval releases escrow (test or manual). |
| **4) UI/Integration** | ✅ PASS | UI steps are clear: hide Cancel after delivery, show Report Issue, add disputed/no_show to StatusPresenter and screens. | Ensure loading/error when status update fails (e.g. guard rejection) shows user-friendly message (ErrorMapper). |
| **5) Release/QA** | ⚠️ CONDITIONAL | Manual E2E and “DB test” mentioned but no automated test list; no flake/retry or artifact capture. | Add: At least one automated test that asserts guard rejects client delivered→canceled (DB or integration); document manual E2E script path; optional retry budget for integration tests. |

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix (exact step(s)) | Owner | Acceptance check |
|-----|--------------------|----------------------|-------|-------------------|
| **rpc_finalize_auto_approval booking branch may not release escrow** | Auto-approved bookings would stay status=completed but funds stuck in escrow; finance bug. | Add Phase 1 step: Inspect `rpc_finalize_auto_approval` for entity_type=booking; if it only sets status, add call to `process_payment_event_ledger('release_with_fee', 'booking', id, idempotency_key, ...)` with FOR UPDATE and stable key, then set status/payment_status. | Backend | Query: after cron run, booking completed and ledger has release_with_fee for that booking_id. |
| **No_show actor and path undefined** | Either anyone could set no_show (abuse) or no one can (feature dead). | Add: (1) Guard allows `active`→`no_show` only when `auth.uid() = provider_id` OR from SECURITY DEFINER RPC. (2) Client “Report no-show” creates dispute (existing flow), not direct status update. (3) Optional RPC `provider_confirm_no_show(booking_id)` or admin sets no_show after dispute. | Backend + Product | Guard test: client UPDATE to no_show fails; provider or RPC succeeds. |
| **Admin resolve disputed booking path missing** | Disputed bookings never move to completed/refunded. | Add: Define RPC (e.g. `admin_resolve_booking_dispute(booking_id, new_status)` where new_status in (completed, refunded)). RPC checks admin, then updates booking and calls ledger. Guard allows disputed→completed/refunded only when called from this RPC (e.g. SECURITY DEFINER). | Backend | Admin can resolve a disputed booking and funds move correctly. |
| **Ledger contract not concrete** | Implementers may guess event_type or idempotency; mismatch causes double-release or errors. | Add Phase 0 step: Create `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/CONTRACT_booking_ledger_mapping.md` with table: Transition (e.g. delivered→completed), event_type, idempotency key pattern, who triggers. Verify against `process_payment_event_ledger` allowed event_types. | Backend / APIContract | Contract file exists and is referenced in Phase 1.3. |
| **Guard “delivered → disputed” actor** | If only client can set disputed, guard must explicitly allow `NEW.status = 'disputed'` when `OLD.status = 'delivered'` and `auth.uid() = client_id`. | In fn_booking_guard, add branch: OLD.status = 'delivered' AND NEW.status = 'disputed' AND v_is_client → RETURN NEW. | Backend | DB test: client can set delivered→disputed; client cannot set delivered→canceled. |
| **Test baseline for guard not established** | No way to run “guard rejects client cancel after delivery” in CI. | Add: One test (e.g. Dart integration or SQL in test/rls/) that as client updates booking from delivered to canceled and expects failure. Document run command. | QA / Backend | `flutter test test/...` or `psql ... -f test_booking_guard.sql` passes/fails as specified. |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|----------------|
| Client cannot move a delivered booking to canceled. | `fn_booking_guard`: reject OLD.status='delivered' AND NEW.status='canceled' when auth.uid() = client_id. | DB test: UPDATE by client_id → exception. |
| Every terminal financial state (completed, refunded, canceled pre-delivery, expired_unanswered, no_show after resolution) has exactly one ledger event. | process_payment_event_ledger called from RPC/trigger for each terminal transition; idempotency key per (entity_id, event_type, key). | Contract table + spot check: completed → release_with_fee; refunded/expired/canceled → refund. |
| Booking status transitions are monotonic and guard-validated. | All updates go through trigger; no direct UPDATE that bypasses trigger. | Trigger covers all allowed (old, new, actor) combinations; any other raises. |
| Auto-approval (review_expires_at) releases escrow for booking. | rpc_finalize_auto_approval booking branch calls process_payment_event_ledger('release_with_fee', ...) when setting completed. | After cron run, journal_entries has release_with_fee for booking. |
| No_show is not set by client unilaterally. | Guard: active→no_show only when auth.uid() = provider_id or SECURITY DEFINER RPC. | Test: client UPDATE to no_show → exception. |
| Single source of truth for “is this booking disputed?” | vw_unified_work_items or app uses booking.status = 'disputed' (and/or existing dispute row by task_id). | UI and RPC use same condition; doc states it. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Auto-approval does not release escrow | rpc_finalize_auto_approval | Med | High | Feature (bookings) | Escrow balance never drops after auto-complete | Add ledger call in same migration as guard | Patch migration to call ledger; backfill stuck bookings |
| Client can still cancel after delivery (guard not deployed) | fn_booking_guard | Med | High | Financial | Client gets refund after delivery | Deploy trigger before/with UI that hides Cancel | Revert trigger; restore old guard |
| No_show abuse (client sets no_show for refund) | fn_booking_guard | Med | High | Financial | Unusual spike in no_show | Guard allows no_show only from provider or RPC | Restrict no_show to admin-only until RPC exists |
| Enum migration order (trigger before values) | Migrations | Low | Med | App-wide | Migration fails or trigger references missing value | Add enum values in migration 1; trigger in migration 2 | Rollback trigger; keep enum |
| Old app sends canceled after delivery | App + backend | Med | Low | Local (that user) | PostgrestException on update | Deploy app that hides Cancel; feature flag optional | User sees error; support explains “use Report Issue” |
| Double-release on retry (auto-approval) | rpc_finalize_auto_approval | Low | High | Data integrity | Duplicate journal_entries | Stable idempotency key (no now()); FOR UPDATE | Idempotency in process_payment_event_ledger |
| Disputed booking never resolved | Admin flow | Med | Med | Feature | Disputed count grows | Document and implement admin RPC | Manual SQL update by admin (one-off) |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** we deploy the new guard but the app still shows “Cancel” for delivered bookings: users tap Cancel, get a generic error, and think the app is broken.
- **This fails when** rpc_finalize_auto_approval never calls the ledger for bookings: after review_expires_at, bookings show completed but escrow never releases and providers never get paid.
- **This fails when** we add disputed/no_show to the enum but the guard does not allow delivered→disputed for client: “Report Issue” creates a dispute row but booking status stays delivered and UI/backend logic is inconsistent.
- **This fails when** a client finds a way to set status to no_show (e.g. old API or bug): they get a refund without provider consent and we have no audit trail.
- **This fails when** we don’t define how admin resolves disputed bookings: disputed bookings pile up and support has no safe procedure.
- **This fails when** the ledger contract is wrong (e.g. wrong event_type): process_payment_event_ledger throws or double-counts, and payouts are wrong.
- **This fails when** we run migrations in wrong order (trigger that references disputed before enum has it): migration fails in production.
- **This fails when** there is no automated test for the guard: a later refactor re-allows client delivered→canceled and we ship a regression.

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|-----------------|-----------------|
| Contract: booking status → ledger event_type | Prevent wrong or duplicate ledger calls | Write CONTRACT_booking_ledger_mapping.md with table (old_status, new_status, event_type, who). Cross-check with process_payment_event_ledger. | CONTRACT_booking_ledger_mapping.md | Contract reviewed and referenced in Phase 1. |
| Confirm and fix rpc_finalize_auto_approval for booking | Avoid escrow never released on auto-approval | Run Supabase MCP or SQL to get function body. If booking branch lacks process_payment_event_ledger, add call (FOR UPDATE, stable idempotency key), then set status. | Migration SQL | Manual or test: auto-approve booking → ledger has release_with_fee. |
| Define no_show and disputed in guard with actor | Prevent abuse and dead paths | In fn_booking_guard: (1) delivered→canceled only if NOT client. (2) delivered→disputed only if client. (3) disputed→completed/refunded only from admin RPC. (4) active→no_show only if provider or SECURITY DEFINER. | Migration SQL (trigger) | DB tests: client delivered→canceled fails; client delivered→disputed ok; client active→no_show fails. |
| Admin RPC to resolve disputed booking | So disputed bookings can be closed | Add RPC admin_resolve_booking_dispute(booking_id, resolution). Check admin; update booking status; call ledger if completed/refunded. Guard allows disputed→completed/refunded from this RPC. | Migration or doc of existing RPC | Admin can resolve and ledger updates. |
| Test: guard rejects client delivered→canceled | Regression safety | Add test (Dart or SQL): as client, UPDATE bookings SET status='canceled' WHERE id=... AND status='delivered'; expect exception. | test/... (e.g. test/db/booking_guard_test.dart or .sql) | CI run passes; test fails if guard is reverted. |
| Booking status transition audit | Observability | Trigger on bookings (AFTER UPDATE) or in RPC: insert into admin_logs or work_logs (entity_type=booking, entity_id, old_status, new_status, actor). Or document existing. | Migration (trigger) or doc | Each transition has a log row (or doc states where it is). |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Data/Contracts & Prerequisites

**Goal:** Lock contracts and migration order so backend work is unambiguous.  
**Why:** Prevents wrong ledger calls and migration failures.  
**How:** Create ledger contract; confirm enum and RPC behavior; define test approach.

**Steps:**

0.1 **Contract (Backend/APIContract)**  
- Create `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/CONTRACT_booking_ledger_mapping.md`.  
- Table: booking status transition → event_type (e.g. delivered→completed → release_with_fee; paid_request_pending→refunded/expired_unanswered → refund; active→canceled → refund; disputed→completed → release_with_fee; disputed→refunded → refund; no_show after resolution → refund).  
- Verify against SUPABASE_SETUP process_payment_event_ledger (allowed event_types for booking).  
- **Artifact:** CONTRACT_booking_ledger_mapping.md.  
- **GATE CHECK:** Contract exists and matches DB function.

0.2 **Live DB confirmation (Supabase_Ops)**  
- Use Supabase MCP or SQL: list current `booking_status_enum` values; get `fn_booking_guard` body; get `rpc_finalize_auto_approval` body (booking branch).  
- Record in plan or Evidence: current enum, whether booking branch calls ledger.  
- **GATE CHECK:** No surprise drops/renames; approach for adding enum + trigger documented.

0.3 **Test baseline (Sentinel)**  
- Decide: DB test in repo (e.g. `test/db/` or SQL script) vs RLS-style test.  
- Document: run command, fixture (e.g. one booking row delivered, client_id set), expected result (client update to canceled → error).  
- **Artifact:** Test file or script path + one-line run instruction.  
- **GATE CHECK:** At least one guard test is defined and runnable.

0.4 **Decisions (Product/Architect)**  
- Confirm: no_show only from provider or RPC; client “no show” → dispute.  
- Confirm: admin resolve via RPC (new or existing).  
- **GATE CHECK:** Decisions 1–2 from §A recorded.

---

### Phase 1: Database & Security (Backend)

**Goal:** Add enum values, enforce transition matrix and actor checks, ensure auto-approval releases escrow, optional audit log.  
**Why:** Correctness and security of booking lifecycle and money.  
**How:** Additive enum migration; trigger rewrite; fix rpc_finalize_auto_approval if needed; optional audit trigger; admin RPC.

**Steps:**

1.1 **Schema (Supabase_Ops)**  
- Migration 1: `ALTER TYPE booking_status_enum ADD VALUE IF NOT EXISTS 'disputed';` and `ADD VALUE IF NOT EXISTS 'no_show';` (order per Postgres if needed).  
- **Artifact:** `supabase/migrations/YYYYMMDD_booking_lifecycle_enum.sql`.  
- **GATE CHECK:** Enum has disputed and no_show; no existing data broken.

1.2 **Trigger fn_booking_guard (Supabase_Ops)**  
- Migration 2: Replace fn_booking_guard.  
- Rules: Keep all current allowed transitions. Add: (1) OLD.delivered AND NEW.canceled AND auth.uid() = client_id → RAISE. (2) OLD.delivered AND NEW.disputed AND auth.uid() = client_id → RETURN NEW. (3) OLD.disputed AND NEW IN (completed, refunded) → allow only from SECURITY DEFINER or admin (e.g. check via is_admin(auth.uid()) or RPC). (4) OLD.active AND NEW.no_show → allow only when auth.uid() = provider_id or from SECURITY DEFINER RPC. Remove blanket “IF NEW.status = 'canceled' RETURN NEW”.  
- **Artifact:** Same or second migration file.  
- **GATE CHECK:** Trigger deployed; manual or test: client delivered→canceled fails.

1.3 **rpc_finalize_auto_approval booking branch (Supabase_Ops)**  
- If booking branch does not call process_payment_event_ledger: add same pattern as rpc_approve_delivery (FOR UPDATE, stable idempotency key, call process_payment_event_ledger('release_with_fee', 'booking', ...), then set status/payment_status).  
- **Artifact:** Migration.  
- **GATE CHECK:** Auto-approval test or manual: completed booking has ledger release_with_fee.

1.4 **Admin resolve disputed booking (Supabase_Ops)**  
- Add or document RPC (e.g. admin_resolve_booking_dispute(booking_id, new_status)). Check is_admin(auth.uid()); update booking; call ledger when new_status in (completed, refunded).  
- **Artifact:** Migration or doc.  
- **GATE CHECK:** Admin can resolve; guard allows disputed→completed/refunded from this RPC.

1.5 **Observability (optional)**  
- Trigger on bookings AFTER UPDATE: insert into admin_logs or work_logs (entity_type=booking, entity_id, old_status, new_status). Or document existing.  
- **Artifact:** Migration or doc.  
- **GATE CHECK:** Transitions auditable.

1.6 **RLS**  
- No new policies on bookings unless needed. Ensure no policy allows client to bypass guard (guard runs as SECURITY DEFINER). Update RLS matrix in .TODO if needed.  
- **GATE CHECK:** Negative test: client cannot set delivered→canceled.

---

### Phase 2: App Layer (MVVM)

**Goal:** Models and services match new enum and guard; no client path to cancel after delivery.  
**Why:** App must only perform allowed transitions and show correct states.  
**How:** Add BookingStatus.disputed; mapping; service layer never sends canceled for delivered by client; use dispute flow.

**Steps:**

2.1 **Models (Architect)**  
- Add `BookingStatus.disputed` in lib/core/app_enums.dart. Keep noShow.  
- BookingModel._mapDbStatusToEnum: map 'disputed' → disputed, 'no_show' → noShow.  
- _mapStatusToDb: add disputed, no_show.  
- **Artifact:** app_enums.dart, booking_model.dart.  
- **GATE CHECK:** No null/unknown for new values; contract alignment.

2.2 **Services (Architect)**  
- BookingService/Repository: do not call updateBookingStatus(..., canceled) when current status is delivered and current user is client.  
- WorkManagementService: same; route client post-delivery to dispute (Report Issue), not cancel.  
- **Artifact:** booking_service.dart, work_management_service.dart.  
- **GATE CHECK:** No UI path that sends delivered→canceled as client.

2.3 **ViewModels (Architect)**  
- BookingViewModel: expose/call dispute submission for client when delivered; filters support disputed/no_show.  
- **Artifact:** booking_view_model.dart, dashboard_view_model if needed.  
- **GATE CHECK:** Recoverable state; correct transitions only.

2.4 **Observability (Observability)**  
- Event list for booking status transitions in .TODO or DEVELOPER_GUIDE; instrument in service (not UI); no PII in logs.  
- **GATE CHECK:** Correlation and events documented.

---

### Phase 3: UI (After logic)

**Goal:** Client sees Approve / Report Issue (not Cancel) when delivered; disputed and no_show visible everywhere.  
**Why:** UX and safety.  
**How:** Booking details, StatusPresenter, badges, dashboard, unified work.

**Steps:**

3.1 **Wiring (Pixel)**  
- Booking details: if status == delivered and role == client, show Approve + Report Issue; hide/remove Cancel that sets status to canceled.  
- StatusPresenter.bookingStatusColor / bookingStatusLabel: add disputed; ensure no_show.  
- Status badges and booking cards: disputed, no_show.  
- Dashboard and unified work list: show and filter disputed/no_show.  
- Loading/error: when status update fails (e.g. guard), show ErrorMapper message.  
- **Artifact:** booking_details_screen.dart, status_presenter.dart, dashboard cards, etc.  
- **GATE CHECK:** Client cannot cancel delivered booking; new statuses render correctly.

3.2 **Polish (Pixel, optional)**  
- Micro-interactions for disputed/no_show; no perf regression.  
- **GATE CHECK:** No regression.

---

### Phase 4: QA & Release

**Goal:** Automated guard test, security checks, E2E and docs.  
**Why:** Regression and release confidence.  
**How:** Run guard test; RLS/abuse checks; manual E2E script; docs.

**Steps:**

4.1 **Contract and migration (Sentinel)**  
- Verify contract vs schema; migration verify queries (enum, trigger exist).  
- **GATE CHECK:** No mismatch.

4.2 **Security (Sentinel)**  
- Run guard test: client delivered→canceled fails.  
- No_show: client cannot set no_show (test or manual).  
- RLS: allowed/forbidden matrix.  
- **GATE CHECK:** Unauthorized access impossible.

4.3 **Functional (Sentinel)**  
- Manual E2E: book → pay → accept → deliver → client sees Approve / Report Issue only; Report Issue creates dispute; auto-approval (if cron runs) completes and releases escrow.  
- Edge: network error, stale status, new enum in cache.  
- **Artifact:** E2E script or checklist in .TODO.  
- **GATE CHECK:** No crashes; behavior correct.

4.4 **Observability (Sentinel)**  
- Confirm transition logs exist and are safe.  
- **GATE CHECK:** Auditable; no leaks.

4.5 **Documentation (DocsKeeper)**  
- Update 05_booking-lifecycle.md (Mermaid + ledger labels).  
- SUPABASE_SETUP: §4.2 enum, transition matrix, fn_booking_guard, rpc_finalize_auto_approval.  
- DEVELOPER_GUIDE: booking lifecycle, dispute gate, no_show, link to contract.  
- MVP_ROADMAP, Sline_Log: booking lifecycle hardening.  
- **GATE CHECK:** Docs match code and DB.

---

### Phase 5: Release & Rollback

**Goal:** Safe deploy and rollback path.  
**Why:** Avoid prolonged outage or wrong payouts.  
**How:** Deploy order (backend first recommended); rollback steps documented.

**Steps:**

5.1 **Deploy order**  
- Prefer: (1) Enum + trigger + rpc_finalize_auto_approval + admin RPC, (2) then app.  
- If app first: old app may send canceled after delivery and get error (acceptable if rare).  
- **GATE CHECK:** Order documented.

5.2 **Rollback**  
- DB: Revert trigger migration (restore old fn_booking_guard); optionally revert rpc_finalize_auto_approval; enum can stay.  
- App: Revert app; backend can stay.  
- Emergency: Revert trigger only to re-allow client cancel while fixing.  
- **GATE CHECK:** Rollback steps in plan or runbook.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- rpc_finalize_auto_approval booking branch ledger call not confirmed; risk of escrow never released.
- No_show and disputed actor rules not defined (who can set what).
- Admin path for resolving disputed bookings not specified.
- Ledger contract was “create file” without exact shape.
- Test baseline for guard (client delivered→canceled reject) not established.
- Order of steps was fine but several steps were under-specified (guard branches, RPC behavior, test run command).

### 2) Added steps

- Phase 0: Contract file CONTRACT_booking_ledger_mapping.md with table; live DB confirmation of rpc_finalize_auto_approval; test baseline (directory, fixture, run command).
- Phase 1: Explicit step to inspect and fix rpc_finalize_auto_approval booking branch; admin RPC for resolving disputed booking; optional audit trigger for transitions; explicit guard branches for delivered→disputed (client), delivered→canceled (not client), disputed→completed/refunded (admin/RPC), active→no_show (provider/RPC).
- Phase 4: Automated guard test; E2E script artifact; observability check.
- Phase 5: Deploy order and rollback as explicit phase.

### 3) Removed steps

- None; only expanded and reordered.

### 4) Reordered steps

- Contract and live DB confirmation moved to Phase 0 (before any migration).
- Test baseline moved to Phase 0 so Phase 4 has a test to run.
- Admin RPC and rpc_finalize_auto_approval fix placed in Phase 1 before app work.

### 5) Expanded steps

- fn_booking_guard: from “rewrite” to explicit branches (delivered→canceled reject for client; delivered→disputed allow client; disputed→completed/refunded admin/RPC only; active→no_show provider/RPC only).
- Ledger: from “document” to “create contract file with table and verify against process_payment_event_ledger”.
- QA: from “DB test” to “define test file, fixture, run command, and at least one guard test”.
- Rollback: from bullets to Phase 5 with deploy order and emergency revert.

### 6) Why

- To make execution unambiguous: one contract file, one test run command, explicit guard matrix and RPC behavior.
- To close financial and abuse risks: auto-approval must release escrow; no_show and disputed must have defined actors and admin resolution path.
- To make the plan gate-based: each phase has a GATE CHECK so we don’t proceed with wrong assumptions.

### 7) Residual risks

- Cron schedule for rpc_finalize_auto_approval is outside this plan (assumed existing); if it doesn’t run for bookings, auto-approval won’t happen.
- Time-based cancellation penalties still out of scope; may need a follow-up.
- Partial refund / split resolution for disputes is not in scope; admin RPC may only do full completed or full refunded.

---

## Mandatory Critique Checklist (Failures Found)

### 3.1 Scope & Requirements
- **Goal measurable:** ✅ Yes (guard reject, escrow release, UI no Cancel after delivery).
- **Non-goals stated:** ✅ Yes (time-based penalties, partial_refund, other lifecycles).
- **Edge/abuse:** ⚠️ No_show and “who resolves disputed” were underspecified → **fixed in Decisions and Guard**.

### 3.2 Dependencies & Ordering
- **UI before data:** ❌ Original plan had UI in Phase 3 after backend; correct. No fix.
- **DB/RLS before API/UI:** ❌ Contract and rpc_finalize_auto_approval confirmation were not strict prerequisites → **fixed: Phase 0 contract + live DB before Phase 1**.

### 3.3 Data Model & Contracts
- **Tables/enums:** ✅ Enum additive.
- **DTO boundaries:** ✅ Models and mapping in Phase 2.
- **Transitions defined:** ❌ Ledger mapping was vague → **fixed: CONTRACT_booking_ledger_mapping.md with table**.

### 3.4 Security (RLS + AuthZ)
- **Read/write per role:** ⚠️ “Admin or RPC” for disputed→completed was vague → **fixed: explicit admin RPC and guard branch**.
- **No_show setter:** ❌ Not defined → **fixed: provider or RPC only; client → dispute**.

### 3.5 Performance & Scalability
- **Pagination/indexes:** ✅ No new tables; indexes only if needed for disputed list.
- **N+1:** Not introduced by this plan.

### 3.6 Error Handling & Observability
- **Error taxonomy:** ⚠️ Guard rejection should map to user message → **fixed: ErrorMapper in UI step**.
- **Logging:** ⚠️ “Emit admin_logs” was generic → **fixed: optional trigger or doc in Plan Fixes**.

### 3.7 UX & State Machine
- **Loading/empty/error:** ✅ Mentioned; added explicit ErrorMapper for guard failure.
- **Double submit / race:** Idempotency in ledger; guard is single row.

### 3.8 Testing & QA
- **Smoke/regression:** ✅ Guard test and E2E.
- **RLS tests:** ⚠️ “RLS/guard audit” was not a concrete test → **fixed: at least one guard test (client delivered→canceled fails)**.
- **Test infra:** ❌ No harness/fixture/run command → **fixed: Phase 0 test baseline step**.
- **Deterministic setup:** ⚠️ Fixture (e.g. one booking row) added in Phase 0.

### 3.9 Release & Migration
- **Feature flag:** Optional in original; kept.
- **Backward compatibility:** ✅ Additive enum; old app may error on cancel after delivery.
- **Rollback:** ✅ Expanded to Phase 5.

### 3.10 Developer Workflow
- **Branch/review:** Inferred single main; no change.
- **Doc update:** ✅ Phase 4.5 documentation step.
- **Definition of done:** ✅ GATE CHECKs per phase.

---

**End of Plan Critic output. Use section H (Corrected Plan) as the execution-ready plan.**
