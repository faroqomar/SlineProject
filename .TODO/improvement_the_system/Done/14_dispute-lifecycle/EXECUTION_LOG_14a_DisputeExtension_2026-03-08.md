# Execution Log: PLAN_14a_DisputeExtension_2026-03-08

**Plan:** `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`  
**Spec:** `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md`  
**Started:** 2026-03-08

## Phase status

| Phase | Status | Notes |
|-------|--------|--------|
| Phase 6 (Database & RPC) | Done | Migration 20260308160000: rpc_submit_delivery restored+Frozen, rpc_request_revision Frozen, indexes, rpc_submit_dispute |
| Phase 7 (App layer) | Done | DisputeService: submitDispute(taskId|directOfferId), rpc_submit_dispute; getDisputeStatus*; ErrorMapper + VM ErrorMapper; submitDelivery error mapping in VM |
| Phase 8 (UI) | Done | Task Report Issue (work item details); direct offer Report Issue + banner; booking/work/direct_offer dispute banners (open vs active) |
| Phase 9 (QA & docs) | Done | SUPABASE_SETUP §9.1/9.2/9.2a, DEVELOPER_GUIDE dispute entry points + Frozen + banners; unit test updated |

## Step log

### Phase 6
- **6.0:** rpc_submit_delivery was only in Archive; restored in 20260308160000 with Frozen guard. rpc_request_revision confirmed in 20260308120000.
- **6.1:** Frozen guard added at start of rpc_submit_delivery (task: EXISTS disputes task_id; booking: task_id from bookings then EXISTS).
- **6.2:** Frozen guard added at start of rpc_request_revision (task, booking same pattern).
- **6.3:** uq_disputes_one_open_active_per_task, uq_disputes_one_open_active_per_direct_offer created.
- **6.4:** rpc_submit_dispute(p_task_id, p_direct_offer_id, p_reason, p_defendant_id) — eligibility + single open/active; INSERT; GRANT EXECUTE.
- **Verification:** Apply migration locally or via Supabase dashboard; GATE: call RPC with open dispute → expect exception; second insert same entity → unique violation.

### Phase 7
- **7.1:** submitDispute now accepts taskId or directOfferId; calls rpc_submit_dispute. SafetyViewModel updated; booking_details_screen unchanged (passes taskId).
- **7.2:** ErrorMapper: dispute in progress (submit_delivery, request_revision), entity not eligible, open dispute already exists, reason required.
- **7.3:** getDisputeStatusForTask/ForDirectOffer/ForBooking added for Phase 8 banners. WorkItemDetailsViewModel uses ErrorMapper for submitDelivery errors.

### Phase 8
- **8.1:** Work item details: "Report Issue" for task when status in (active, delivered), guarded by _ReportIssueGuard (hasOpenDisputeForTask); _showDisputeDialog with reason + submitDispute(taskId, defendantId).
- **8.2:** Direct offer details: "Report Issue" when active or delivered, _ReportIssueGuardDirectOffer; submitDispute(directOfferId, reason, defendantId).
- **8.3:** Banners: _BookingDisputeBanner (booking details); _DisputeBannerContent (work item details); _DirectOfferDisputeBanner (direct offer details). Copy: open → "Dispute under review..."; active → "Work frozen — in dispute."
- **8.4:** getDisputeStatus* used in banner content (Phase 7).

### Phase 9
- **9.1:** Regression: unit test dispute_service_test.dart updated for rpc_submit_dispute; all 4 tests pass. Manual GATE: apply migration; call rpc_submit_delivery/rpc_request_revision with open dispute → expect exception; second dispute insert same entity → unique violation; dispute buttons and banners visible per eligibility.
- **9.2:** SUPABASE_SETUP: §9.1 Frozen guard + migration ref; §9.2 Frozen guard + exception; new §9.2a rpc_submit_dispute and partial unique indexes; §17 changelog entry. DEVELOPER_GUIDE: dispute entry points (booking, task, direct_offer); Frozen behaviour (submit_delivery, request_revision); banner copy (open vs active); UI widget refs.

---

## Final summary

- **Migration:** Applied via **Supabase MCP** `apply_migration` (project_id: isddrknbjsgaantjojhm, name: 14a_dispute_extension_frozen_guards) — **success**. All SQL changes are now live in the database. Local file: `supabase/migrations/20260308160000_14a_dispute_extension_frozen_guards.sql`.
- **Rollback:** Reverse order: drop `rpc_submit_dispute`; drop indexes `uq_disputes_one_open_active_per_task`, `uq_disputes_one_open_active_per_direct_offer`; re-apply previous bodies of `rpc_submit_delivery` and `rpc_request_revision` without Frozen guard.
- **Observability:** AppLogger used in DisputeService (submit, hasOpen*, getDisputeStatus*); SafetyViewModel and WorkItemDetailsViewModel log errors; no `print()`.

---

## Evidence / Gaps / Risks (Context scan)

- **Evidence:** Plan and spec loaded. DEVELOPER_GUIDE, SUPABASE_SETUP §5.24, §9.1, §9.2, §9.4, §9.5 confirmed. disputes: task_id, direct_offer_id, status (enum), chk_dispute_entity. rpc_request_revision in 20260308120000 (task, booking). rpc_submit_delivery only in Archive (20260224): task + booking, params (entity_type, entity_id, note). WorkManagementService calls both RPCs. DisputeService: submitDispute(taskId only); hasOpenDisputeForTask/ForDirectOffer/ForBooking. SafetyViewModel delegates; no getDisputeStatus. Booking: Report Issue when delivered; work item: no Report Issue; direct offer: no Report Issue; banners generic or missing.
- **Gaps:** rpc_submit_delivery not in live migrations (restore + Frozen guard). Frozen guard in rpc_request_revision. Partial unique indexes. rpc_submit_dispute (insert guard). DisputeService direct_offer path. Task/direct_offer dispute buttons and open/active banners. ErrorMapper for new messages. Docs update.
- **Risks:** Restore from Archive is single source; direct_offer branch not in Archive — guard only for task/booking in submit_delivery.
