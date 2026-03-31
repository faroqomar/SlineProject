# 📌 Plan: 14a Dispute Extension (Frozen Guards, Unique Index, Insert Guard, Task/Direct-Offer Dispute UI, Banners)

**Extends:** `.TODO/PLAN_DisputeLifecycle_2026-03-08.md` (Phases 0–5 Done).  
**Spec:** `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md` (all 16 sections).  
**Gap source:** `.TODO/EXECUTION_LOG_DisputeLifecycle_2026-03-08.md` — "Audit vs 14a".  
**Date:** 2026-03-08.

---

## 1) Goal

- **Goal:** Implement the remaining 14a items so that (1) Frozen behaviour is enforced at RPC level for submit_delivery and request_revision, (2) at most one open/active dispute per entity is enforced in DB and at insert, (3) dispute creation is guarded by eligibility and single-active rule, and (4) task and direct_offer have dispute entry points and all entity screens show explicit open/active dispute banners.
- **Why:** Escrow and lifecycle integrity require blocking delivery/revision when disputed; duplicate disputes and ineligible inserts must be rejected; users need clear entry points and status (open vs active) on booking, task, direct_offer, and unified work details.
- **Result:** DB/RPC enforce Frozen + single-active + eligibility; app exposes dispute for task and direct_offer; banners show "Dispute under review" (open) and "Work frozen — in dispute" (active).

---

## 2) Scope

### In-Scope

1. **Frozen guards:** Add dispute check to `rpc_submit_delivery` and `rpc_request_revision` so that when the entity has an open or active dispute, the RPC blocks (14a §7, §14.2, §14.3).
2. **Partial unique index:** One open/active dispute per entity — partial unique index on `disputes` for `(task_id)` WHERE `status IN ('open','active')`; similar for `(direct_offer_id)`. Booking uses `task_id`, so covered by task_id index (14a §12, §14.1).
3. **Dispute insert guard:** Reject INSERT into disputes if (a) entity is not in eligible state (booking: active|delivered, task: in_progress|delivered, direct_offer: active|delivered) OR (b) an open/active dispute already exists. Implement via RPC (e.g. `rpc_submit_dispute`) or trigger (14a §5, §14.2).
4. **Task dispute UI:** Expose "Report Issue" / Dispute on task/work item details when task is in_progress or delivered and no open/active dispute; reuse `DisputeService.submitDispute(taskId, reason, defendantId)` (14a §10.2).
5. **Direct_offer dispute UI:** Extend DisputeService to accept `direct_offer_id` and insert `disputes.direct_offer_id`; add Dispute button on direct offer details when offer is active or delivered and no open/active dispute (14a §4.3, §10.3).
6. **Banners:** On booking details, task/work item details, direct_offer details, and unified work item details: show explicit banner when dispute status is "open" (e.g. "Dispute under review") and when "active" (e.g. "Work frozen — in dispute") (14a §10.1–10.3).

### Out-of-Scope (Do Not Add Steps)

- Admin dashboard (queue, detail, Accept/Resolve/Cancel UI and RPCs).
- Admin audit logging for dispute actions.
- Split/partial payout.
- Evidence/messages UI beyond existing placeholder.

---

## 3) Evidence & Findings (From Scan)

### Existing

- **Docs:** DEVELOPER_GUIDE, SUPABASE_SETUP §5.24 (disputes: task_id, direct_offer_id, chk_dispute_entity), §9.1 rpc_submit_delivery, §9.2 rpc_request_revision, §9.4/9.5 dispute guard in rpc_finalize_auto_approval and rpc_approve_delivery. MVP_ROADMAP lists dispute lifecycle Done (Phases 0–5).
- **DB:** `disputes` has task_id, direct_offer_id (no booking_id; booking uses task_id). dispute_status_enum, trg_dispute_guard, trg_dispute_set_resolved_at. Escrow guard in rpc_approve_delivery and rpc_finalize_auto_approval. No partial unique index on disputes. No dispute check in rpc_submit_delivery or rpc_request_revision.
- **Migrations:** `rpc_request_revision` in `supabase/migrations/20260308120000_harden_rpc_request_revision.sql`. `rpc_submit_delivery` only in `supabase/migrations/Archive/20260224_fix_rpc_submit_delivery_booking_transition.sql` — live DB may have it; must locate or restore.
- **App:** `lib/features/work/services/work_management_service.dart` calls `rpc_submit_delivery` and `rpc_request_revision`. `lib/features/safety/services/dispute_service.dart`: submitDispute only accepts taskId (inserts task_id); has hasOpenDisputeForTask, hasOpenDisputeForBooking, hasOpenDisputeForDirectOffer.
- **UI:** Booking details: "Report Issue" when status == delivered; _ApproveWithDisputeGuard; no open/active banner. Work item details: _buildDisputedBanner when status == disputed (single generic message); _ReviewWithDisputeGuard; no "Report Issue" for task. Direct offer details: _ApproveWithDisputeGuard only; no Dispute button; no banner.

### Missing

- Frozen guard inside rpc_submit_delivery and rpc_request_revision.
- Partial unique indexes on disputes (task_id, direct_offer_id) WHERE status IN ('open','active').
- Backend dispute insert guard (eligibility + single open/active per entity).
- DisputeService overload or params for direct_offer_id.
- Task/work item details: "Report Issue" button when task in_progress|delivered and no open/active dispute.
- Direct offer details: "Report Issue" button and submit path with direct_offer_id.
- Banners that distinguish "open" (under review) vs "active" (frozen).

### Conflicts / Risks

- **rpc_submit_delivery:** Not in non-Archive migrations; planner must require "locate in live DB or restore from Archive" before adding dispute guard. Risk: wrong function signature or missing branch if restored from old migration.
- **Open vs active block:** 14a §16 item 5 recommends blocking submit_delivery/request_revision only when **active** (Frozen). This plan follows the user requirement to block when **open or active**; product can narrow to active-only later.
- **Booking eligibility:** 14a §5 says booking eligible = active | delivered. Current UI shows "Report Issue" only when delivered; plan can include "optionally show when active" as minor UX alignment.

---

## 4) System Impact Map

- **UI:** Booking details, work_item_details_screen, direct_offer_details_screen — banners (open/active) and task + direct_offer dispute buttons.
- **MVVM/App Logic:** DisputeService (extend submit for direct_offer_id; optional eligibility check before submit). SafetyViewModel may expose dispute status (open/active) for banners if not already derivable from existing hasOpenDispute* + new fetch.
- **Database:** disputes (partial unique indexes); new or updated RPC: rpc_submit_delivery (guard), rpc_request_revision (guard), rpc_submit_dispute or trigger (insert guard).
- **RLS/Security:** No new RLS; insert guard enforces eligibility and single-active at RPC/trigger layer.
- **Realtime/Notifications:** None.
- **Storage:** None.
- **Observability:** Existing AppLogger in DisputeService; optional log when RPC blocks due to dispute.
- **Compatibility & Migration:** Additive (indexes, RPC guards, new RPC). Old app that inserts disputes directly may get rejection from insert guard until it switches to rpc_submit_dispute (if we use RPC).
- **Contracts:** Error messages from new RPC/guard must be mapped in ErrorMapper if shown in UI.

---

## 5) Risk Classification

- **HIGH:** DB/guards — Frozen guards and insert guard; wrong predicate or missing branch can allow release or duplicate dispute.
- **MEDIUM:** UI — Task/direct_offer dispute button and banners; incorrect visibility or copy only.

---

# ✅ Execution Phases (Extension — Phases 6, 7, 8)

## Phase 6: Database & RPC (Frozen Guards, Partial Unique Index, Insert Guard)

> Primary: @Supabase_Ops

**Goal:** Enforce Frozen behaviour in rpc_submit_delivery and rpc_request_revision; enforce one open/active dispute per entity; reject ineligible or duplicate dispute inserts.  
**Why:** 14a §7, §12, §14.1–14.3.  
**How:** One or more additive migrations; locate rpc_submit_delivery; add dispute check at start of both RPCs; create partial unique indexes; add rpc_submit_dispute (or trigger) that checks entity status and existing open/active dispute before insert.

### 6.0 Live Supabase Confirmation (MANDATORY)

- [ ] **6.0.1** (@Supabase_Ops) Confirm `rpc_submit_delivery` exists in live DB (name, params: entity_type, entity_id, note). If missing, restore from `supabase/migrations/Archive/20260224_fix_rpc_submit_delivery_booking_transition.sql` into a new migration and document.  
- [ ] **6.0.2** (@Supabase_Ops) Confirm `rpc_request_revision` current body (task + booking branches; entity_type, entity_id, p_note).  
- **GATE (@Sentinel):** Location and signature of rpc_submit_delivery documented; no conflicting object names.

### 6.1 Frozen Guard — rpc_submit_delivery

- [ ] **6.1.1** (@Supabase_Ops) In a new migration: at start of `rpc_submit_delivery`, add dispute check: for entity_type `task` — EXISTS (SELECT 1 FROM disputes WHERE task_id = entity_id AND status IN ('open','active')); for `booking` — get task_id from bookings WHERE id = entity_id, then same EXISTS on task_id; for `direct_offer` (if branch exists) — EXISTS on direct_offer_id. If true, RAISE EXCEPTION e.g. 'Cannot submit delivery: dispute in progress'.  
- [ ] **6.1.2** (@Supabase_Ops) Apply migration; document in SUPABASE_SETUP §9.1.  
- **GATE (@Sentinel):** Call rpc_submit_delivery with entity that has open dispute → expect exception; no state change.

### 6.2 Frozen Guard — rpc_request_revision

- [ ] **6.2.1** (@Supabase_Ops) In same or new migration: at start of `rpc_request_revision`, add dispute check: for `task` — EXISTS (disputes WHERE task_id = entity_id AND status IN ('open','active')); for `booking` — task_id from bookings, then same. If true, RAISE EXCEPTION e.g. 'Cannot request revision: dispute in progress'.  
- [ ] **6.2.2** (@Supabase_Ops) Apply; document in SUPABASE_SETUP §9.2.  
- **GATE (@Sentinel):** Call rpc_request_revision with entity that has open dispute → expect exception.

### 6.3 Partial Unique Index — One Open/Active per Entity

- [ ] **6.3.1** (@Supabase_Ops) Create partial unique index on disputes: UNIQUE (task_id) WHERE task_id IS NOT NULL AND status IN ('open','active'). Name e.g. uq_disputes_one_open_active_per_task.  
- [ ] **6.3.2** (@Supabase_Ops) Create partial unique index: UNIQUE (direct_offer_id) WHERE direct_offer_id IS NOT NULL AND status IN ('open','active'). Name e.g. uq_disputes_one_open_active_per_direct_offer.  
- **GATE (@Sentinel):** Second INSERT for same task_id (or direct_offer_id) with status open/active fails with unique violation.

### 6.4 Dispute Insert Guard (Eligibility + Single-Active)

- [ ] **6.4.1** (@Supabase_Ops) Implement insert guard via RPC `rpc_submit_dispute` (recommended) or BEFORE INSERT trigger. Logic: (1) Exactly one of p_task_id or p_direct_offer_id provided. (2) If task_id: check task status IN ('in_progress','delivered'); check no existing dispute for that task_id with status IN ('open','active'). (3) If direct_offer_id: check direct_offer status IN ('active','delivered'); check no existing dispute for that direct_offer_id with status IN ('open','active'). (4) If any check fails, RAISE. (5) Else INSERT into disputes (complainant_id = auth.uid(), task_id or direct_offer_id, reason, status = 'open', defendant_id if provided). Booking disputes: caller passes task_id from booking.task_id.  
- [ ] **6.4.2** (@Supabase_Ops) RLS: keep disputes_insert_own for direct INSERT if still allowed; recommend app and docs use rpc_submit_dispute only so eligibility is enforced. If using RPC only, optional: restrict direct INSERT via RLS or remove public INSERT.  
- **GATE (@Sentinel):** Insert for entity in wrong status → exception; second insert for same entity open/active → exception (or unique index).  
- **Rollback note:** Drop RPC or trigger; remove partial unique indexes if needed (allow duplicates again).

---

## Phase 7: App Layer (DisputeService direct_offer_id, Optional Eligibility)

> Primary: @Architect

**Goal:** App can submit disputes for direct_offer; optionally check eligibility before calling RPC; ErrorMapper handles new RPC errors.  
**Why:** 14a §4.3, §10.3.  
**How:** Extend DisputeService with submitDispute overload or named params for direct_offer_id; call rpc_submit_dispute when implemented (or keep direct insert for task, add insert with direct_offer_id for direct offer). If backend has rpc_submit_dispute, switch to it for both task and direct_offer and pass entity type + id.

### 7.1 DisputeService — Direct Offer and RPC (if applicable)

- [ ] **7.1.1** (@Architect) Add submitDispute path for direct_offer: e.g. submitDispute({ String? taskId, String? directOfferId, required String reason, String? defendantId }). If rpc_submit_dispute exists: call RPC with p_task_id or p_direct_offer_id. Else: insert into disputes with direct_offer_id set (task_id NULL), complainant_id, reason, status 'open'; validate exactly one of taskId/directOfferId.  
- [ ] **7.1.2** (@Architect) Ensure defendantId resolved for direct_offer (e.g. from direct_offer row: other party).  
- **GATE (@Sentinel):** Unit test: submit with direct_offer_id inserts row with direct_offer_id set; hasOpenDisputeForDirectOffer true after submit.

### 7.2 ErrorMapper (If New RPC Messages)

- [ ] **7.2.1** (@Architect) If rpc_submit_dispute or Frozen guard raises new messages (e.g. "Cannot submit delivery: dispute in progress", "Entity not eligible for dispute"), add ErrorMapper entries and use in WorkManagementService / SafetyViewModel where applicable.  
- **GATE (@Sentinel):** User sees friendly message when RPC blocks.

### 7.3 Optional: Eligibility Check in App

- [ ] **7.3.1** (@Architect) Optional: Before showing Dispute button or calling submit, app checks entity status (in_progress|delivered for task; active|delivered for direct_offer; active|delivered for booking). Not a substitute for backend guard.  
- **GATE (@Sentinel):** Button hidden when status not eligible; submit still guarded by backend.

---

## Phase 8: UI (Task Dispute Button, Direct-Offer Dispute Button, Banners)

> Primary: @Pixel

**Goal:** Task/work item details and direct_offer details show "Report Issue" when eligible and no open/active dispute; all four screens show explicit banner for "open" vs "active" dispute.  
**Why:** 14a §10.1–10.3.  
**How:** Add Dispute button to work_item_details_screen for task branch (in_progress|delivered, !hasOpenDisputeForTask); add Dispute button to direct_offer_details_screen (active|delivered, !hasOpenDisputeForDirectOffer). Add or extend banner on booking details, work item details, direct_offer details to show "Dispute under review" when open and "Work frozen — in dispute" when active (requires dispute status in VM or second query; if only hasOpenDispute* is available, single banner "Dispute in progress" is acceptable until status is exposed).

### 8.1 Task / Work Item Details — Dispute Button

- [ ] **8.1.1** (@Pixel) On work_item_details_screen, for task (and booking when shown as work item): when entity status is in_progress or delivered and SafetyViewModel.hasOpenDisputeForTask(entityId) is false, show "Report Issue" (or "Dispute") button. On tap: show reason dialog and call DisputeService.submitDispute(taskId: entityId, reason, defendantId from task/client). Reuse pattern from booking_details_screen _showDisputeDialog.  
- [ ] **8.1.2** (@Pixel) Hide button when hasOpenDisputeForTask is true or status not in_progress/delivered.  
- **GATE (@Sentinel):** Manual: task in_progress, no dispute → button visible; submit → dispute created; button hidden. No direct Supabase in view.

### 8.2 Direct Offer Details — Dispute Button

- [ ] **8.2.1** (@Pixel) On direct_offer_details_screen: when offer status is active or delivered and hasOpenDisputeForDirectOffer(offerId) is false, show "Report Issue" button. On tap: reason dialog and DisputeService.submitDispute(directOfferId: offerId, reason, defendantId from offer).  
- [ ] **8.2.2** (@Pixel) Hide when dispute exists or status not active/delivered.  
- **GATE (@Sentinel):** Manual: direct_offer active, no dispute → button visible; submit → row with direct_offer_id; button hidden.

### 8.3 Banners — Open vs Active

- [ ] **8.3.1** (@Pixel) **Booking details:** When dispute exists for booking (hasOpenDisputeForBooking true), show banner. If dispute status available: "Dispute under review" for open, "Work frozen — in dispute" for active. If only hasOpenDispute* available, show single banner e.g. "Dispute in progress — approve and release disabled."  
- [ ] **8.3.2** (@Pixel) **Work item details:** Extend _buildDisputedBanner to show "Dispute under review" when open and "Work frozen — in dispute" when active (requires dispute status in WorkItemDetailsViewModel or SafetyViewModel; if view already has unified_status = disputed, optional: fetch dispute status for banner copy).  
- [ ] **8.3.3** (@Pixel) **Direct offer details:** When hasOpenDisputeForDirectOffer true, show same banner pattern (open vs active if status available).  
- [ ] **8.3.4** (@Pixel) **Unified work item details:** Same banner in work_item_details_screen covers unified entry.  
- **GATE (@Sentinel):** Banners visible when dispute exists; copy distinguishes open vs active where implemented; no regression on Approve/Review disabled state.

### 8.4 Dispute Status for Banners (If Not Already Available)

- [ ] **8.4.1** (@Architect) If SafetyViewModel or DisputeService does not expose dispute status (open vs active), add e.g. Future<DisputeStatus?> getDisputeStatusForTask(taskId) / forDirectOffer(offerId) / forBooking(bookingId) returning 'open' | 'active' | null. Use in banner logic.  
- **GATE (@Sentinel):** Banner text matches dispute status when available.

---

## Phase 9: QA & Documentation (Extension)

> Primary: @Sentinel, @SlineDocs

### 9.1 QA

- [ ] **9.1.1** (@Sentinel) Regression: rpc_submit_delivery without dispute succeeds; with open dispute fails. Same for rpc_request_revision.  
- [ ] **9.1.2** (@Sentinel) Second dispute insert for same entity (open/active) fails (DB or RPC).  
- [ ] **9.1.3** (@Sentinel) Insert dispute for entity in wrong status fails.  
- [ ] **9.1.4** (@Sentinel) Task and direct_offer dispute buttons visible only when eligible and no dispute; submit creates correct row; banners show on all four screens when disputed.  
- **GATE (@Sentinel):** All above pass.

### 9.2 Documentation

- [ ] **9.2.1** (@SlineDocs) Update SUPABASE_SETUP: §9.1 rpc_submit_delivery (Frozen guard), §9.2 rpc_request_revision (Frozen guard), new § for rpc_submit_dispute (if added); partial unique indexes on disputes; eligibility and single-active rule.  
- [ ] **9.2.2** (@SlineDocs) Update DEVELOPER_GUIDE: dispute entry points (booking, task, direct_offer); Frozen behaviour (submit_delivery, request_revision blocked); banner copy (open vs active).  
- **GATE (@Sentinel):** Docs match code and DB.

---

## 6) Acceptance Criteria (14a Extension)

- rpc_submit_delivery and rpc_request_revision raise when entity has open or active dispute; no state change.
- At most one row in disputes per (task_id or direct_offer_id) with status in ('open','active'); partial unique indexes enforce.
- Dispute insert (direct or via RPC) rejected when entity not in eligible state or when open/active dispute already exists for that entity.
- "Report Issue" on task/work item details when task in_progress|delivered and no open/active dispute; submit uses existing DisputeService (taskId).
- "Report Issue" on direct_offer details when active|delivered and no open/active dispute; submit sets disputes.direct_offer_id (DisputeService extended).
- Booking, task/work, direct_offer, and unified work details show explicit banner when dispute open ("Dispute under review") and when active ("Work frozen — in dispute") (or single banner if status not yet exposed).

---

## 7) Rollback Plan

- **DB:** Revert migrations in reverse order: drop rpc_submit_dispute (or trigger); drop partial unique indexes; remove dispute check from rpc_submit_delivery and rpc_request_revision (re-apply previous function bodies). No table drops.
- **App:** Revert DisputeService and UI changes; remove ErrorMapper entries for new messages.
- **Emergency:** If Frozen guard causes operational issue, re-apply RPC bodies without dispute check; document and fix forward.

---

## 8) References (From Scan)

- `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md` — §§1–16 (spec).
- `Sline_everything/DEVELOPER_GUIDE.md` — MVVM, feature map, work management.
- `Sline_everything/SUPABASE_SETUP.md` — §5.24 disputes, §9.1 rpc_submit_delivery, §9.2 rpc_request_revision, §9.4–9.5 escrow guard.
- `.TODO/PLAN_DisputeLifecycle_2026-03-08.md` — existing plan (Phases 0–5 Done).
- `.TODO/EXECUTION_LOG_DisputeLifecycle_2026-03-08.md` — Audit vs 14a gap list.
- `lib/features/safety/services/dispute_service.dart` — submitDispute(taskId), hasOpenDispute*.
- `lib/features/work/services/work_management_service.dart` — rpc_submit_delivery, rpc_request_revision.
- `lib/features/booking/view/booking_details_screen.dart` — Report Issue, _ApproveWithDisputeGuard.
- `lib/features/work/view/work_item_details_screen.dart` — _buildDisputedBanner, _ReviewWithDisputeGuard.
- `lib/features/direct_offers/view/direct_offer_details_screen.dart` — _ApproveWithDisputeGuard.
- `supabase/migrations/20260308120000_harden_rpc_request_revision.sql` — rpc_request_revision.
- `supabase/migrations/Archive/20260224_fix_rpc_submit_delivery_booking_transition.sql` — rpc_submit_delivery (restore if missing in live).
- Live Supabase: confirm via MCP or SQL before Phase 6 (rpc_submit_delivery, rpc_request_revision, disputes schema).
