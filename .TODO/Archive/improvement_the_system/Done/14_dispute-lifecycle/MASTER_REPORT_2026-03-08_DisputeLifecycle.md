# Master Report: Dispute Lifecycle

**Scope:** Dispute Lifecycle (escrow guard, RLS, dispute_status_enum, UI dispute guards, Submit Evidence wiring)  
**Plan:** `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`  
**Execution:** `.TODO/EXECUTION_LOG_DisputeLifecycle_2026-03-08.md`  
**Date:** 2026-03-08  
**Orchestrator:** Pipeline run per `.agents/workflows/Orchestrator.md`

---

## A) Executive Summary

| Item | Result |
|------|--------|
| **What was reviewed** | Dispute lifecycle implementation: migrations (20260308140000, 20260308150000), DisputeService, SafetyViewModel, booking/work/direct_offer UI guards, dispute test, and related docs. |
| **Overall risk level** | **Medium–High** (escrow/RLS touched; server-side guards and fail-closed UI in place). |
| **Final decision** | **Ready** ✅ (CodeGuard: APPROVED; no BLOCKERs). |

**Agent reports produced:**
- `.TODO/ARCHITECT_REPORT_2026-03-08_DisputeLifecycle.md`
- `.TODO/OBSERVABILITY_REPORT_2026-03-08_DisputeLifecycle.md`
- `.TODO/DOCS_REPORT_2026-03-08_DisputeLifecycle.md`
- `.TODO/CODEGUARD_REVIEW_2026-03-08_DisputeLifecycle.md`

**Fixes already applied during pipeline:**
- **Architect:** `_ReviewWithDisputeGuard` now handles `sourceType == 'direct_offer'` with `hasOpenDisputeForDirectOffer(entityId)`.
- **CodeGuard:** Lint fix in `test/unit/safety/dispute_service_test.dart` (unnecessary cast removed).

---

## B) Consolidated Findings (Deduplicated)

### Security

| # | Severity | Owner | Path / object | Finding | Fix recommendation |
|---|----------|--------|----------------|--------|---------------------|
| B1 | MED | CodeGuard | RPC / RLS | Escrow and RLS touched; server-side guards in place. | None; verified. RPC dispute check at start of each branch; RLS deny UPDATE/DELETE on disputes; participant-only on dispute_messages/dispute_evidence. |
| B2 | LOW | CodeGuard | booking_details_screen | When `booking.taskId` is null/empty, Approve button is enabled; RPC still blocks. | Prefer `hasOpenDisputeForBooking(booking.id)` so null task_id is handled inside service. Optional. |

### Data integrity

| # | Severity | Owner | Path / object | Finding | Fix recommendation |
|---|----------|--------|----------------|--------|---------------------|
| B3 | MED | DocsKeeper | SUPABASE_SETUP §5.24, §1, §17 | `disputes.status` documented as text; enum and 20260308150000 not in enums table or changelog. | Update §5.24 (status = dispute_status_enum), §1 (add dispute_status_enum), §17 (add 20260308150000). |
| B4 | MED | DocsKeeper | SUPABASE_SETUP §5.25, §5.26, §6.4 | RLS for dispute_messages/dispute_evidence and view recreate (20260308150000) not documented. | Add RLS policy names/behavior; §6.4 note view recreated in 20260308150000. |

### Architecture / MVVM

| # | Severity | Owner | Path / object | Finding | Fix recommendation |
|---|----------|--------|----------------|--------|---------------------|
| B5 | — | Architect | All dispute UI | Views do not call Supabase; SafetyViewModel → DisputeService single source for Approve/Review gating. | None. |
| B6 | LOW | Architect | (Optional) | Same FutureBuilder + dispute check pattern in three screens. | Optional: shared widget e.g. DisputeAwareActionButton. |

### Performance

| # | Severity | Owner | Path / object | Finding | Fix recommendation |
|---|----------|--------|----------------|--------|---------------------|
| B7 | LOW | CodeGuard | FutureBuilder in guards | Rebuild can re-invoke future; one CTA per screen. | Optional: cache result per (entityType, entityId) in SafetyViewModel with short TTL. |

### Observability

| # | Severity | Owner | Path / object | Finding | Fix recommendation |
|---|----------|--------|----------------|--------|---------------------|
| B8 | MED | Observability | dispute_service.dart | Error logs in hasOpenDispute* lack entity id (task_id, direct_offer_id, booking_id). | Add corresponding entity id to AppLogger.e json in all three hasOpen* catch blocks. |
| B9 | LOW | Observability | safety_view_model.dart | submitDispute catch logs without task_id or event_name. | Add json: { event_name: 'safety_dispute_submit_failed', task_id: taskId } to VM error log. |
| B10 | LOW | Observability | dispute_service.dart | Optional: event_name in submit success. | Add event_name: 'safety_dispute_submitted' to success json. |

### Docs / reference integrity

| # | Severity | Owner | Path / object | Finding | Fix recommendation |
|---|----------|--------|----------------|--------|---------------------|
| B11 | HIGH | DocsKeeper | AppDigram/All_Diagrams/14_dispute-lifecycle.md | States "NO enum", "NO trigger", "status is plain text" — outdated after 20260308150000. | Update diagram and evidence: dispute_status_enum, trg_dispute_guard, trg_dispute_set_resolved_at, RLS; bump last_verified. |
| B12 | MED | DocsKeeper | DEVELOPER_GUIDE.md | Dispute lifecycle and single source for “has dispute” not described. | Add subsection: escrow guard, dashboard vs SafetyViewModel, UI guards. |
| B13 | MED | DocsKeeper | STRUCTURE.md, MVP_ROADMAP.md, Sline_Log.md | Test file, migrations, and completion status not reflected. | Add test path; migrations; roadmap/Sline_Log entry per DOCS_REPORT §3. |

---

## C) Fix Plan (Ordered, Step-by-Step)

| Step | Owner | Action | Verification |
|------|--------|--------|---------------|
| 1 | @DocsKeeper | Update SUPABASE_SETUP §1, §5.24–5.26, §6.4, §17 per DOCS_REPORT §3. | Grep for dispute_status_enum, disputes_deny_*, dispute_messages/evidence RLS; changelog has 20260308150000. |
| 2 | @DocsKeeper | Update DEVELOPER_GUIDE: dispute lifecycle, escrow guard, single source, UI guards. | Search for "dispute" and "SafetyViewModel.hasOpenDispute". |
| 3 | @DocsKeeper | Update STRUCTURE (test + migrations), MVP_ROADMAP, Sline_Log; update AppDigram/14_dispute-lifecycle.md. | Diagram no longer says "NO enum"/"NO trigger"; STRUCTURE lists dispute test and migrations. |
| 4 | Observability / Implementer | Add entity id to DisputeService hasOpen* error logs (task_id, direct_offer_id, booking_id). | AppLogger.e in each catch has json with correct id. |
| 5 | Observability / Implementer | Add task_id and event_name to SafetyViewModel.submitDispute catch log. | VM error log includes task_id and safety_dispute_submit_failed. |
| 6 | (Optional) Implementer | Booking details: use hasOpenDisputeForBooking(booking.id) in _ApproveWithDisputeGuard. | booking_details_screen passes booking.id; service handles null task_id. |
| 7 | @CodeGuard | Re-run gate after doc and logging changes (optional): `flutter analyze`, `flutter test test/unit/safety/`. | No new issues. |

---

## D) Regression Checklist

| Flow | How to test quickly |
|------|---------------------|
| Submit dispute (task) | From task/booking with delivery: open dispute; confirm Approve/Review disabled on details. |
| Approve blocked (task) | Work item details (task): open dispute → Review shows "Checking…" then disabled. |
| Approve blocked (booking) | Booking details: open dispute → Approve & Release disabled. |
| Approve blocked (direct offer) | Direct offer details: open dispute → Approve & release payment disabled. |
| Dashboard disputed | Ensure work item with dispute shows disputed bucket and Submit Evidence CTA → work item details with disputed banner. |
| RPC guard | (DB) Call rpc_approve_delivery / rpc_finalize_auto_approval with entity that has open dispute → expect exception. |
| Unit tests | `flutter test test/unit/safety/dispute_service_test.dart` — all 4 pass. |

---

## E) Rollback Notes

| Area | Rollback if needed |
|------|---------------------|
| **App (UI guards)** | Remove _ApproveWithDisputeGuard / _ReviewWithDisputeGuard; restore plain Approve/Review buttons. Revert SafetyViewModel/DisputeService hasOpen* methods if not used elsewhere. |
| **Migration 20260308150000** | Non-trivial: revert view to 20260308110000 definition (with text status comparison); drop triggers; alter status back to text; drop enum. Re-add disputes_status_check if it was dropped. |
| **Migration 20260308140000** | Revert RPC bodies to prior version; drop RLS on dispute_messages/dispute_evidence; drop deny policies on disputes; drop new indexes. Document in SUPABASE_SETUP. |
| **Docs** | Revert DocsKeeper changes from Fix Plan steps 1–3. |

---

## F) Next Actions

1. **Required (docs):** Execute Fix Plan steps 1–3 (@DocsKeeper) so SUPABASE_SETUP, DEVELOPER_GUIDE, STRUCTURE, MVP_ROADMAP, Sline_Log, and diagram 14 match the implementation.
2. **Recommended (observability):** Execute steps 4–5 (entity id in dispute error logs; VM submit failure log with task_id and event_name).
3. **Optional:** Step 6 (booking details guard via hasOpenDisputeForBooking(booking.id)); optional shared DisputeAwareActionButton; optional cache of dispute check in SafetyViewModel.
4. **Pipeline:** No BLOCKERs; merge of Dispute Lifecycle scope is approved. Optional CodeGuard re-run after doc/logging changes.
