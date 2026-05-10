# 📌 Plan: Booking Lifecycle Hardening (05_booking-lifecycle)

## 1) Goal

- **Goal:** Implement the hardened booking state machine from `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle`: add `disputed` and `no_show` states, block client-initiated `delivered` → `canceled`, enforce dispute gate for post-delivery complaints, align cron auto-approval and ledger, and document ledger transition mapping.
- **Why:** Current diagram and `fn_booking_guard` allow `delivered` → `canceled` by client (griefing risk). `no_show` and `disputed` are missing from DB enum; auto-approval and ledger consistency for bookings need verification.
- **Result:** Production-safe booking lifecycle with clear transition rules, audit trail, and no unilateral post-delivery refund by client.

## 2) Scope

### In-Scope

- Add `disputed` and `no_show` to `booking_status_enum` (additive).
- Update `fn_booking_guard`: forbid `delivered` → `canceled` when actor is client; allow `delivered` → `disputed` (client) and `disputed` → `completed` / `refunded` (admin or RPC).
- Define and enforce `no_show` transition (who, when, guardrails per System Critic).
- Ensure booking auto-approval path (`rpc_finalize_auto_approval` or cron) releases escrow via `process_payment_event_ledger` when moving to `completed`.
- Ledger mapping: document and verify `booking_status_enum` terminal transitions → `payment_event_type` (e.g. `release_with_fee`, `refund`).
- Observability: emit `admin_logs` / `work_logs` (or equivalent) on booking status transitions for audit.
- Flutter: align `BookingStatus` and `UnifiedWorkStatus` with new enum values; update StatusPresenter, booking details, dashboard, unified work view for `disputed` and `no_show`.
- Diagram and docs: update `05_booking-lifecycle.md` and DEVELOPER_GUIDE/SUPABASE_SETUP to reflect final state machine and invariants.
- QA: DB tests for guard (reject `delivered` → `canceled` by client), slot overlap, cron, and ledger triggers.

### Out-of-Scope

- Time-based cancellation penalty rules (e.g. 24h cutoff for full refund) — can be a follow-up.
- `partial_refund` as a terminal state or ledger event — only document if already supported; otherwise out-of-scope.
- Changing direct_offer or task lifecycles.
- New storage buckets or Realtime schema changes.

## 3) Evidence & Findings (From Scan)

### Existing

- **Docs:** `Sline_everything/DEVELOPER_GUIDE.md` (booking feature, work management); `SUPABASE_SETUP.md` §4.2 `booking_status_enum`, §8.2 bookings triggers, §9.4 `rpc_finalize_auto_approval`, §9.5 `rpc_approve_delivery`; `STRUCTURE.md`, `MVP_ROADMAP.md`, `ARCHITECTURE_ANALYSIS.md`, `CODE_REVIEW.md`.
- **DB (from docs):** `booking_status_enum`: pending, confirmed, in_progress, canceled, completed, paid_request_pending, active, delivered, refunded, expired_unanswered (no `disputed`, no `no_show`). `fn_booking_guard`: allows pending→paid_request_pending, paid_request_pending→active/refunded, active→delivered, delivered→completed (client only), and **any** transition to `canceled` (no actor check). `bookings.review_expires_at` exists. `fn_reject_overlapping_slots` on slots. `disputes` has `task_id` and `direct_offer_id` (booking disputes via task_id). `rpc_approve_delivery` has booking branch with dispute guard and `process_payment_event_ledger('release_with_fee', 'booking', ...)`. `rpc_finalize_auto_approval` has dispute guard (migration 20260308140000); doc says it "sets status='completed'" for booking — ledger call for booking auto-approval not explicitly stated in doc.
- **Code:** `lib/core/app_enums.dart` — `BookingStatus` has `noShow`, `declined`, `inProgress`, `confirmed` (legacy/UI). `lib/features/booking/models/booking_model.dart` — `_mapDbStatusToEnum` maps `no_show` → noShow; DB enum currently has no `no_show`. `lib/features/booking/` (service, repository, viewmodel, view), `lib/features/work/services/work_management_service.dart`, `lib/features/dashboard/` (bookings tab, permission service), `StatusPresenter.bookingStatusColor` / `bookingStatusLabel`, `status_badge.dart`, `vw_unified_work_items` (disputed via task dispute).
- **ImplementReady folder:** `00_HOLISTIC_REPORT.md`, `01_NOTES.md`, `02_GAPS_AND_FIXES.md`, `03_RISK_REGISTER.md`, `04_DIAGRAM_FINAL.md`, `07_SYSTEM_CRITIC_VERDICT.md` — define target diagram, invariants, no_show/disputed, and critic’s minimal improvements (no_show adjudication, ledger mapping table).

### Missing

- `disputed` and `no_show` in live `booking_status_enum`.
- In `fn_booking_guard`: actor check to forbid client-driven `delivered` → `canceled`; explicit allowed transitions for `delivered` → `disputed` and `disputed` → `completed` / `refunded`.
- Formal no_show transition rules (who can set, timing/proof; critic recommends client-initiated no_show → disputed or admin-only).
- Confirmation whether `rpc_finalize_auto_approval` booking branch calls `process_payment_event_ledger` when setting completed (docs suggest status-only; if so, escrow would not release on auto-approval).
- Centralized ledger mapping table (booking status transition → event_type) in `.TODO/` or SUPABASE_SETUP.
- Observability: no explicit requirement yet for logging booking status transitions to admin_logs/work_logs.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- **Docs vs DB enum:** SUPABASE_SETUP §4.2 lists `confirmed`, `in_progress`; quick reference table lists `confirmed` but DDL block shows same. Dart has `BookingStatus.confirmed`, `inProgress`, `noShow`, `declined` — mapping already handles some DB values; adding `disputed` and `no_show` to DB requires migration and Dart mapping.
- **Guard risk:** Current guard allows any `NEW.status = 'canceled'`; changing to deny client `delivered`→`canceled` is a breaking behavior change and must be deployed with UI that routes unhappy clients to "Report Issue" (dispute) instead of Cancel.
- **rpc_finalize_auto_approval:** If booking branch does not call ledger, auto-approved bookings would have status=completed but funds still in escrow — financial bug. Plan must verify and fix.
- **Migration order:** Add enum values first (additive), then change trigger logic; avoid dropping or renaming existing enum values.

## 4) System Impact Map

- **UI:** Booking details, booking list/dashboard cards, StatusPresenter, status badges, unified work view — must show `disputed` and `no_show` correctly; "Cancel" after delivery replaced by "Report Issue" (dispute) for client.
- **MVVM/App Logic:** BookingViewModel, BookingService, DashboardViewModel, WorkManagementService — status update paths; SafetyViewModel already has dispute checks; ensure booking status transitions use RPC/guard-compliant paths.
- **Database:** `booking_status_enum` (add 2 values); `fn_booking_guard` (rewrite transition matrix); optionally `rpc_finalize_auto_approval` (ensure booking branch calls ledger); cron that calls finalize for bookings unchanged in intent but must match new status set.
- **RLS/Security:** No new tables; RLS on `bookings` unchanged in principle; guard enforces who can do which transition (client vs provider vs admin).
- **Realtime/Notifications:** Notifications may be created by existing triggers or app when status changes; ensure disputed/no_show trigger appropriate messaging.
- **Storage:** None.
- **Observability:** Add audit logging for booking status transitions (admin_logs or work_logs per holistic report).
- **Compatibility & Migration:** Additive enum + updated trigger; existing rows keep current status; app must handle new enum values (Dart already has noShow; add disputed).
- **Contracts:** `.TODO/` contract file for booking status → ledger event_type mapping; API contract for any new RPC (e.g. admin resolve disputed booking) if not using existing dispute resolution path.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance + non-regression list (measurable): guard rejects client `delivered`→`canceled`; disputed/no_show visible in UI; auto-approval releases escrow for booking; ledger mapping doc exists.
- [ ] (@Architect) Confirm modules/entry points: `lib/features/booking/`, work_management_service, dashboard bookings tab, vw_unified_work_items, fn_booking_guard, rpc_finalize_auto_approval.
- **Verify (@Sentinel):** done-conditions + rollback triggers documented in §8 below.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Threat model + security requirements + negative checks for booking lifecycle (delivery-cancel griefing, no_show abuse) in `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/` or `.TODO/`.
- **Verify (@Sentinel):** testable and included in Phase 4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Contract file in `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/`: booking_status_enum transitions → ledger event_type (e.g. completed→release_with_fee, refunded/expired_unanswered→refund, canceled pre-delivery→refund, no_show→refund after dispute, disputed→completed/refund via admin).
- **Verify (@Sentinel):** contract matches schema + process_payment_event_ledger shapes.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Additive enum migration (ADD VALUE for `disputed`, `no_show`); no backfill of existing rows; trigger update in same or follow-up migration; compatibility window: deploy backend before app that sends new statuses.
- **Verify (@Sentinel):** measurable compatibility window and rollback (revert trigger; enum values can remain).

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Optional: feature flag to hide "Cancel" after delivery and show "Report Issue" only after guard is live.
- **Verify (@Sentinel):** rollback path documented.

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via Supabase MCP (e.g. list_tables, execute_sql) for `bookings`, `booking_status_enum`, `fn_booking_guard`, `rpc_finalize_auto_approval` — confirm current enum values and trigger body.
- [ ] (@Supabase_Ops) Confirm no conflicts with existing (avoid drops/renames unless planned).
- **Verify (@Sentinel):** drift + safe approach recorded in plan or Evidence.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Migration: `ALTER TYPE booking_status_enum ADD VALUE IF NOT EXISTS 'disputed';` and `ADD VALUE IF NOT EXISTS 'no_show';` (order if required by Postgres version).
- [ ] (@Supabase_Ops) No new tables; indexes only if new queries (e.g. disputed bookings) need them.
- **Verify (@Sentinel):** no leaks/breaks, naming consistent, minimal risk.

### 1.2 RLS

- [ ] (@Supabase_Ops) No new RLS policies on `bookings` for this phase; transition rules enforced in `fn_booking_guard`. Ensure only admin or designated RPC can set `disputed`→`completed`/`refunded` if done via direct update (otherwise via RPC only).
- [ ] (@Supabase_Ops) RLS check matrix update in `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/` if any policy depends on status.
- **Verify (@Sentinel):** negative fails, positive passes.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Rewrite `fn_booking_guard`: (1) Remove blanket allow for `NEW.status = 'canceled'`. (2) Allow `delivered` → `canceled` only when actor is NOT client (e.g. provider or system). (3) Allow `delivered` → `disputed` when actor is client (or via RPC). (4) Allow `disputed` → `completed` or `refunded` (admin or RPC). (5) Define `active` → `no_show` (who: provider or system or client-with-guard; per critic, client no_show should go to disputed or require admin). (6) Keep all existing allowed transitions.
- [ ] (@Supabase_Ops) If `rpc_finalize_auto_approval` booking branch does not call `process_payment_event_ledger`: add ledger release (same pattern as rpc_approve_delivery booking branch) and then set status/payment_status; idempotency key stable.
- [ ] (@Supabase_Ops) Optional: dedicated RPC for "client reports no_show" that creates dispute or sets status under guard (per critic).
- **Verify (@Sentinel):** state rules enforced; unit test for client `delivered`→`canceled` raises exception.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Run migration(s) per plan (enum + trigger + optional rpc_finalize_auto_approval fix).
- **Verify (@Sentinel):** verify queries and trigger tests pass.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Add `BookingStatus.disputed` in `lib/core/app_enums.dart` (and keep `noShow`). Ensure `BookingModel._mapDbStatusToEnum` maps `'disputed'` → `BookingStatus.disputed` and `'no_show'` → `BookingStatus.noShow`; handle any legacy DB values.
- [ ] (@Architect) Align `UnifiedWorkStatus` and unified work view with `disputed` (already may exist via dispute table; confirm booking status `disputed` is reflected in vw_unified_work_items or fallback).
- **Verify (@Sentinel):** types/nullability match contract and DB.

### 2.2 Services/Repositories

- [ ] (@Architect) BookingService/BookingRepository: `_mapStatusToDb` and any status update calls must send only guard-allowed statuses; client post-delivery must call dispute flow (e.g. Report Issue), not update status to canceled.
- [ ] (@Architect) WorkManagementService: ensure booking cancel path is not used for delivered bookings by client; route to dispute where applicable.
- **Verify (@Sentinel):** RLS-safe, no UI→Supabase direct calls.

### 2.3 ViewModels

- [ ] (@Architect) BookingViewModel: no direct status update to `canceled` when status is `delivered`; expose or use dispute submission for client. DashboardViewModel/BookingViewModel: support new statuses for filters and actions.
- **Verify (@Sentinel):** recoverable state + correct transitions.

### 2.4 Observability (If needed)

- [ ] (@Observability) Event list + correlation for booking status transitions (in `.TODO/` or DEVELOPER_GUIDE); recommend admin_logs/work_logs on transition (Phase 0 holistic report).
- [ ] (@Architect) Instrument booking status changes in service layer (not UI); no sensitive data in logs.
- **Verify (@Sentinel):** no sensitive logs, consistent correlation.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Booking details: for client, when status is `delivered`, show "Report Issue" (dispute) instead of "Cancel"; remove or hide Cancel button that would set status to canceled. Show appropriate states for `disputed` and `no_show` (banners, labels).
- [ ] (@Pixel) StatusPresenter.bookingStatusColor / bookingStatusLabel: add cases for `disputed` and ensure `no_show` is correct. Status badges and booking cards: same.
- [ ] (@Pixel) Dashboard bookings tab and unified work list: disputed/no_show display and filters if needed.
- [ ] (@Pixel) Loading/empty/error states for booking flows unchanged; ensure new statuses do not break existing states.
- **Verify (@Sentinel):** stable UX on slow/empty data; no Cancel after delivery for client.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Micro-interactions for disputed/no_show (low-risk only).
- **Verify (@Sentinel):** no perf regression.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Shapes/types match contract (booking status enum, ledger event types).
- [ ] (@Sentinel) Run migration verify queries (enum values present; trigger exists).
- **Verify (@Sentinel):** no mismatch.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute ThreatModeler negative checks: client cannot set `delivered`→`canceled` (DB test); no_show abuse scenario (client cannot unilaterally set no_show to get refund if guard requires dispute).
- [ ] (@Sentinel) RLS/guard audit: only intended actors can perform each transition.
- **Verify (@Sentinel):** unauthorized access impossible.

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E: create booking → pay → accept → deliver → client sees Approve / Report Issue (not Cancel); report issue creates dispute; auto-approval after review_expires_at completes and releases escrow (if cron runs).
- [ ] (@Sentinel) Edge cases: network error on status update, stale status, null handling for new enum in old app cache.
- **Verify (@Sentinel):** no crashes, consistent behavior.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Booking status transition logs exist and are useful; privacy redaction enforced.
- **Verify (@Sentinel):** actionable telemetry without leaks.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update `Sline_everything/AppDigram/All_Diagrams/05_booking-lifecycle.md` with final Mermaid diagram (from 04_DIAGRAM_FINAL.md + critic’s ledger labels if desired).
- [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md`: §4.2 booking_status_enum (add disputed, no_show); status transition matrix; fn_booking_guard description; rpc_finalize_auto_approval booking/ledger behavior if changed.
- [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE.md` booking section: lifecycle, dispute gate, no_show, and link to contract/ledger mapping.
- [ ] (@DocsKeeper) Update `Sline_everything/MVP_ROADMAP.md` and `Sline_everything/Sline_Log.md` with booking lifecycle hardening entry.
- **Verify (@Sentinel):** docs match code + live DB reality.

---

## 7) Acceptance Criteria (MANDATORY)

- `fn_booking_guard` rejects client-initiated `delivered` → `canceled` (DB test or RPC test).
- `fn_reject_overlapping_slots` still prevents double-booking (existing test or smoke).
- Cron or `rpc_finalize_auto_approval` for booking: when review_expires_at passed and no dispute, booking moves to completed and escrow released via `process_payment_event_ledger('release_with_fee', 'booking', ...)` (verified by test or manual check).
- Ledger mapping document exists: terminal booking status transitions → event_type (release_with_fee, refund, etc.).
- UI: Client cannot cancel a delivered booking; can only approve or report issue (dispute). Disputed and no_show states visible and correct.
- Observability: booking status transitions auditable (admin_logs or work_logs).
- No regression: existing booking flows (pending → paid → active → delivered → completed, cancel before delivery, decline, expire) still work.

---

## 8) Rollback Plan

- **DB rollback:** Revert trigger migration (restore previous `fn_booking_guard` that allows canceled); enum values `disputed`/`no_show` can remain (additive). If rpc_finalize_auto_approval was changed, revert that migration.
- **App rollback:** Revert app to previous version; backend can stay on new guard (old app will get exception if client tries to set canceled after delivery — acceptable or feature-flag off).
- **Emergency disable:** If critical bug, revert trigger only so that client can again set canceled (restore previous behavior) while fixing.

---

## 9) References (From Scan)

- `Sline_everything/DEVELOPER_GUIDE.md` (booking, work management)
- `Sline_everything/SUPABASE_SETUP.md` (§4.2 booking_status_enum, §8.2 bookings triggers, §9.4 rpc_finalize_auto_approval, §9.5 rpc_approve_delivery, disputes §5.24)
- `Sline_everything/STRUCTURE.md`, `Sline_everything/MVP_ROADMAP.md`, `Sline_everything/ARCHITECTURE_ANALYSIS.md`, `Sline_everything/CODE_REVIEW.md`
- `lib/core/app_enums.dart`, `lib/features/booking/` (models, services, viewmodels, view), `lib/features/work/services/work_management_service.dart`, `lib/features/dashboard/`
- `Sline_everything/AppDigram/All_Diagrams/05_booking-lifecycle.md`
- `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle/00_HOLISTIC_REPORT.md`, `01_NOTES.md`, `02_GAPS_AND_FIXES.md`, `03_RISK_REGISTER.md`, `04_DIAGRAM_FINAL.md`, `07_SYSTEM_CRITIC_VERDICT.md`
- Supabase MCP: use for live scan of enum and trigger (list_tables / execute_sql as applicable).
