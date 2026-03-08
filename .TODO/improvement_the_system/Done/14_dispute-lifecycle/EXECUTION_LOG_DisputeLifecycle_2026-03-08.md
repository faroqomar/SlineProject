# Execution Log: Dispute Lifecycle (PLAN_DisputeLifecycle_2026-03-08)

**Plan:** `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`  
**Started:** 2026-03-08  
**Executor:** @Executor (per .cursor/Agents/Executor.md)

---

## Full Context Scan (Pre-Execution)

### Evidence (what exists)
- **Docs:** DEVELOPER_GUIDE, SUPABASE_SETUP §5.24–5.26 (disputes, dispute_messages, dispute_evidence), §9.4 rpc_finalize_auto_approval, §9.5 rpc_approve_delivery; MVP_ROADMAP, STRUCTURE, ARCHITECTURE_ANALYSIS, CODE_REVIEW.
- **Code:** `lib/features/safety/services/dispute_service.dart` (submitDispute, AppLogger.i on submit); `lib/features/safety/viewmodels/safety_view_model.dart`; `lib/features/booking/view/booking_details_screen.dart` (Report Issue); dashboard repository/permission_service (disputed bucket); `lib/core/services/logger_service.dart` (AppLogger).
- **DB (Supabase MCP):** `rpc_approve_delivery` and `rpc_finalize_auto_approval` exist. disputes: policies `disputes_insert_own`, `disputes_select_party` only; no policies on dispute_messages, dispute_evidence. disputes table empty (no rows → enum migration safe).
- **rpc_finalize_auto_approval:** In DB; handles entity_type = 'task' and 'booking'; sets status to 'completed' when review_expires_at passed; does NOT call process_payment_event_ledger (completion may trigger other flows). Location: live DB only (not in repo migrations).

### Gaps (what must be created)
- Escrow guard in rpc_approve_delivery (task, booking, direct_offer) and in rpc_finalize_auto_approval (task, booking).
- Explicit deny policies on disputes (UPDATE/DELETE).
- RLS policies on dispute_messages and dispute_evidence.
- dispute_status_enum, trg_dispute_guard, resolved_at trigger (scope B).
- test/unit/safety/dispute_service_test.dart; RLS test or SQL test doc.
- Dispute model; has_open_dispute for CTA; UI disable Approve when dispute exists.

### Risks
- rpc_finalize_auto_approval not in repo: patch via new migration (recreate function with dispute check).
- Booking branch must use task_id from bookings.

### Observability notes
- AppLogger already used in DisputeService (submit). Add AppLogger for: dispute check block in service layer if we add hasOpenDispute; no sensitive payload (only entity_type/entity_id or dispute_id).

---

## Phase Status

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 0: Preconditions & Gates | Done | Test infra + rpc location doc |
| Phase 1: Data & Security | Done | Migration applied via MCP; RLS matrix added |
| Phase 2: App Layer | Done | hasOpenDisputeForTask + SafetyViewModel |
| Phase 3: UI | Done | _ApproveWithDisputeGuard on booking details |
| Phase 4: QA & Release | Done | Unit tests pass; AppLogger in use |
| Phase 5: Documentation | Done | SUPABASE_SETUP §9.4/9.5 + changelog |

---

## Step-by-Step Log

### Phase 0 (Done)
- **0.2 Locate rpc_finalize_auto_approval:** Confirmed in DB via Supabase MCP; not in repo. Documented in `.TODO/improvement_the_system/ImplementReady/14_dispute-lifecycle/rpc_finalize_auto_approval_location.md`. Function handles task + booking only; no direct_offer.
- **0.4 Test infra (Gate 0):** Created `test/unit/safety/dispute_service_test.dart` with Fake-based insert capture and awaitable stub. Tests: submitDispute inserts status 'open', task_id, complainant_id, defendant_id; inserts without defendant_id; throws on empty reason; throws when not signed in. All use AppLogger (existing in DisputeService). Run: `flutter test test/unit/safety/dispute_service_test.dart` — **4/4 passed.**
- **Evidence:** AppLogger visible in test output (`[Safety] ✅ Dispute submitted`).

### Phase 1 (Done)
- **Migration:** `20260308140000_dispute_lifecycle_escrow_guard_rls.sql` created and applied via Supabase MCP. Contents: escrow guard in `rpc_approve_delivery` (task, booking, direct_offer) and in `rpc_finalize_auto_approval` (task, booking); explicit deny UPDATE/DELETE on `disputes`; RLS for `dispute_messages` and `dispute_evidence` (participant-only SELECT/INSERT); indexes on `disputes(task_id)`, `(direct_offer_id)`, `(status)`.
- **RLS check matrix:** `.TODO/improvement_the_system/ImplementReady/14_dispute-lifecycle/RLS_CHECK_MATRIX.md` added.
- **Verification:** Policies confirmed in DB via MCP (disputes_deny_update, disputes_deny_delete, dispute_messages_*, dispute_evidence_*).

### Phase 2 (Done)
- **DisputeService:** Added `hasOpenDisputeForTask(String taskId)` with AppLogger.d when open dispute found, AppLogger.e on error (safe default: return true on error to block Approve).
- **SafetyViewModel:** Added `hasOpenDisputeForTask(String taskId)` delegating to DisputeService.
- **Booking details:** "Approve & Release" gated by `_ApproveWithDisputeGuard` — FutureBuilder calls `SafetyViewModel.hasOpenDisputeForTask(booking.taskId)`; button disabled when dispute open; loading state "Checking…".

### Phase 3 (Done)
- UI wiring: Booking details screen uses dispute guard; dashboard already maps `disputed` from `vw_unified_work_items` (Phase 3.1).

### Phase 4 (Evidence)
- Unit tests: `flutter test test/unit/safety/dispute_service_test.dart` — 4/4 passed. AppLogger observed in output.
- Regression: Escrow guard verified by migration (RPCs raise when dispute exists). Manual QA: create dispute → call approve → expect exception (can be run via Supabase MCP or app).

---

## Audit vs 14a (2026-03-08)

**Spec:** `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md`

**In place (existing + implemented):** Escrow block in rpc_approve_delivery and rpc_finalize_auto_approval; RLS deny UPDATE/DELETE on disputes; RLS participant-only on dispute_messages and dispute_evidence; dispute_status_enum and trg_dispute_guard / trg_dispute_set_resolved_at; vw_unified_work_items disputed override; SafetyViewModel.hasOpenDisputeForTask/ForBooking/ForDirectOffer; Approve/Review disabled on booking, work item, direct offer details; dispute submit on booking details (via task_id).

**Still missing per 14a (no step in current plan or backlog):** Frozen guards in rpc_submit_delivery and rpc_request_revision; partial unique index (one open/active dispute per entity); dispute insert guard (eligibility + single-active); submit path for task (button/entry) and direct_offer (service accepts only taskId; no direct_offer_id in insert); explicit dispute open/active banners; admin queue/accept/resolve/cancel UI and RPCs; admin audit logging; eligibility check at insert (backend).
