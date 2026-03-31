# Docs Report: 14a Dispute Extension — Documentation & Reference Integrity

**Date:** 2026-03-08  
**Plan:** `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`  
**Spec:** `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md`  
**Execution Log:** `.TODO/EXECUTION_LOG_14a_DisputeExtension_2026-03-08.md`  
**Scope:** Migration `20260308160000_14a_dispute_extension_frozen_guards.sql`; DisputeService, SafetyViewModel, work_item_details_screen, direct_offer_details_screen, booking_details_screen; SUPABASE_SETUP and DEVELOPER_GUIDE (Phase 9).  
**Author:** @SlineDocs (review only; no fixes applied).

---

## 1. Documentation delta (what was updated)

### 1.1 SUPABASE_SETUP.md

| Section | Location (line / heading) | Content documented |
|--------|----------------------------|---------------------|
| **§9.1 `rpc_submit_delivery`** | Lines 2254–2262 (`### 9.1 rpc_submit_delivery`) | Purpose; **Frozen guard**: open/active dispute check (task + booking), exception `Cannot submit delivery: dispute in progress`; logic (tasks/bookings); migrations: Archive 20260224 + **20260308160000_14a_dispute_extension_frozen_guards.sql**. |
| **§9.2 `rpc_request_revision`** | Lines 2264–2275 (`### 9.2 rpc_request_revision`) | Purpose; **Frozen guard**: open/active dispute (task/booking), exception `Cannot request revision: dispute in progress`; exception list for ErrorMapper; migrations: 20260308120000 + **20260308160000**. |
| **§9.2a `rpc_submit_dispute`** | Lines 2277–2288 (`### 9.2a rpc_submit_dispute (Plan 14a)`) | Purpose; parameters (p_task_id, p_direct_offer_id, p_reason, p_defendant_id); eligibility (task in_progress|delivered, direct_offer active|delivered); single open/active rule and exception messages; partial unique indexes listed; migration 20260308160000. |
| **§17 Changelog** | Lines 2482–2495 (`## 17. Changelog` → Version 2.20.1) | Entry: "Plan 14a — Frozen guards, unique indexes, rpc_submit_dispute (2026-03-08):" migration 20260308160000; rpc_submit_delivery restored + Frozen guard; rpc_request_revision Frozen guard; indexes; rpc_submit_dispute; cross-ref "See §9.1, §9.2, §9.2a." |

**Summary:** §9.1, §9.2, §9.2a and §17 are updated and consistent with the migration and plan. No delta missing for these sections.

---

### 1.2 DEVELOPER_GUIDE.md

| Area | Location (line / heading) | Content documented |
|------|----------------------------|---------------------|
| **Dispute entry points (Plan 14a)** | Lines 2565–2569 (`#### Dispute entry points (Plan 14a)`) | Booking: "Report Issue" when delivered, no open/active dispute, submit via `SafetyViewModel.submitDispute(taskId: booking.taskId, ...)`. Task: work item details, task source, in progress or delivered, submit via `submitDispute(taskId: entityId, ...)`. Direct offer: direct offer details, active or delivered, submit via `submitDispute(directOfferId: offerId, ...)`; DisputeService uses `rpc_submit_dispute`. |
| **Frozen behaviour (Plan 14a)** | Lines 2571–2578 (`#### Frozen behaviour (Plan 14a)`) | Open or active dispute → Frozen; **rpc_submit_delivery** and **rpc_request_revision** raise and do not change state; **rpc_approve_delivery** and **rpc_finalize_auto_approval** block release; ErrorMapper + WorkManagementService / SafetyViewModel. |
| **Banners and UI widgets** | Lines 2582–2587 (Dispute lifecycle §3–4) | UI: `_ApproveWithDisputeGuard`, `_BookingDisputeBanner`; work item: `_ReviewWithDisputeGuard`, `_ReportIssueGuard` (task), `_DisputeBannerContent`; direct offer: `_ApproveWithDisputeGuard`, `_DirectOfferDisputeBanner`, `_ReportIssueGuardDirectOffer`. Plan refs: PLAN_DisputeLifecycle, **PLAN_14a_DisputeExtension**. Banner copy: **open** → "Dispute under review. Approve and release disabled."; **active** → "Work frozen — in dispute." (from getDisputeStatusForTask/ForBooking/ForDirectOffer). |

**Summary:** Dispute entry points, Frozen behaviour, and banner copy are documented and match the implementation. DEVELOPER_GUIDE Phase 9 updates are present.

---

## 2. Reference integrity

### 2.1 Broken or ambiguous references

| Issue | Location | Severity | Detail |
|-------|----------|----------|--------|
| **Duplicate section "9" in SUPABASE_SETUP** | SUPABASE_SETUP.md | **LOW (ambiguity)** | Document has multiple "9" headings: **## 9. RPC Functions** at ~1406 (9.1 Search, 9.2 Role Switching); **## 9. Functions & RPC** at ~1514 (9.1 Helper, 9.2 RPC); **### 9. Functions (RPCs)** at ~2250 (9.1 rpc_submit_delivery, 9.2 rpc_request_revision, 9.2a rpc_submit_dispute). Changelog "See §9.1, §9.2, §9.2a" intends the **third** block (lines 2250+). A reader following "first §9.1" lands on Search, not rpc_submit_delivery. Not a dead path; section number reuse only. |
| **None** | All code paths below | — | No broken file paths or missing files found for 14a scope. |

### 2.2 Validated paths and objects

- **Migration:** `supabase/migrations/20260308160000_14a_dispute_extension_frozen_guards.sql` — exists; content matches plan (Frozen guards, partial unique indexes, rpc_submit_dispute).
- **DisputeService:** `lib/features/safety/services/dispute_service.dart` — exists; submitDispute(taskId|directOfferId), hasOpenDispute*, getDisputeStatusForTask/ForDirectOffer/ForBooking; calls `rpc_submit_dispute`.
- **SafetyViewModel:** `lib/features/safety/viewmodels/safety_view_model.dart` — exists; delegates to DisputeService; submitDispute, hasOpenDispute*, getDisputeStatus*; ErrorMapper via _mapError.
- **work_item_details_screen:** `lib/features/work/view/work_item_details_screen.dart` — exists; `_buildDisputedBanner`, `_DisputeBannerContent`, `_ReportIssueGuard`, `_ReviewWithDisputeGuard`; "Report Issue" and open/active banner copy.
- **direct_offer_details_screen:** `lib/features/direct_offers/view/direct_offer_details_screen.dart` — exists; `_DirectOfferDisputeBanner`, `_ReportIssueGuardDirectOffer`, Approve guard; banner open/active copy.
- **booking_details_screen:** `lib/features/booking/view/booking_details_screen.dart` — exists; `_BookingDisputeBanner`, Report Issue, dispute dialog.
- **ErrorMapper:** `lib/core/utils/error_mapper.dart` — exists; maps "Cannot submit delivery: dispute in progress", "Cannot request revision: dispute in progress", "Entity not eligible for dispute", "open or active dispute already exists", "Reason is required", "Exactly one of task_id or direct_offer_id".
- **Plans:** `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`, `.TODO/PLAN_DisputeLifecycle_2026-03-08.md` — exist.
- **Spec:** `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md` — exists; 16 sections; no doc-internal broken refs.
- **DEVELOPER_GUIDE** task reporting path: `lib/features/tasks/view/task_details_screen.dart` — exists (task reporting; dispute entry for task is on work item details, not task details — doc correctly says "Report Issue on work item details" for task).

### 2.3 Outdated section numbers

- No **wrong** section numbers found. The only issue is **ambiguity** of which "§9" is meant (see 2.1). Section **17** is unique and correct (Changelog at 2482).

### 2.4 Missing cross-references

- **SUPABASE_SETUP §17** links to §9.1, §9.2, §9.2a and to the migration; no missing cross-ref for 14a there.
- **DEVELOPER_GUIDE** links to PLAN_14a_DisputeExtension and PLAN_DisputeLifecycle at line 2585; correct.
- **Execution log** references plan, spec, and doc updates; no missing cross-ref.

**BLOCKER:** None. Ambiguous §9 does not invalidate plan assumptions; it only makes navigation to the correct RPC section less obvious.

---

## 3. Required doc updates still missing

| Document | Missing / recommended update | Priority |
|----------|-----------------------------|----------|
| **MVP_ROADMAP.md** | "Booking dispute submission" row (lines 72–73) describes Dispute lifecycle (20260308140000, 20260308150000) and Plan_DisputeLifecycle only. It does **not** mention Plan 14a, migration 20260308160000, Frozen guards, task/direct_offer Report Issue, or open/active banners. **Recommendation:** Add one line or bullet: e.g. "**14a (2026-03-08):** Frozen guards in rpc_submit_delivery and rpc_request_revision; rpc_submit_dispute; task and direct_offer Report Issue; open/active dispute banners. Migration 20260308160000. Plan: `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`." | **Recommended** |
| **STRUCTURE.md** | "Recent migration themes" (around lines 79–90) lists Dispute lifecycle 20260308140000 and 20260308150000; **does not** list 20260308160000 (14a). **Recommendation:** Add bullet: e.g. "**Plan 14a — Dispute extension (2026-03-08):** `20260308160000_14a_dispute_extension_frozen_guards.sql`: rpc_submit_delivery restored with Frozen guard; rpc_request_revision Frozen guard; partial unique indexes on disputes; rpc_submit_dispute. Plan: `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`." | **Recommended** |
| **Sline_Log.md** | No version entry for 14a or "Dispute Extension" or "Frozen guard" or migration 20260308160000. **Recommendation:** Add a release entry per SlineDocs template (Version X.Y.Z — 14a Dispute Extension; Implemented: migration, DisputeService, SafetyViewModel, screens, banners; Impact; Verification: plan, execution log; Technical notes: migrations, rollback). | **Recommended** |
| **14a spec (14a_dispute-entity-freeze-integration.md)** | Spec is requirement-only; no "Implementation status" section. **Optional:** Add a short note at top or end, e.g. "**Implementation (2026-03-08):** Plan `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`; migration `20260308160000_14a_dispute_extension_frozen_guards.sql`; app: DisputeService rpc_submit_dispute, task/direct_offer Report Issue, open/active banners." Not required for reference integrity. | **Optional** |

---

## 4. Files/objects referenced by docs vs code/DB

| Referenced item | In docs | In code/DB | Match |
|-----------------|--------|------------|-------|
| Migration `20260308160000_14a_dispute_extension_frozen_guards.sql` | SUPABASE_SETUP §9.1, §9.2, §9.2a, §17; Execution log; Plan | File present in `supabase/migrations/` | ✅ |
| `rpc_submit_delivery` (Frozen guard) | SUPABASE_SETUP §9.1; Plan | Migration defines it with dispute check | ✅ |
| `rpc_request_revision` (Frozen guard) | SUPABASE_SETUP §9.2; Plan | Migration defines it with dispute check | ✅ |
| `rpc_submit_dispute` | SUPABASE_SETUP §9.2a; Plan; DEVELOPER_GUIDE | Migration defines it; DisputeService calls it | ✅ |
| `uq_disputes_one_open_active_per_task` | SUPABASE_SETUP §9.2a; Plan | In migration | ✅ |
| `uq_disputes_one_open_active_per_direct_offer` | SUPABASE_SETUP §9.2a; Plan | In migration | ✅ |
| DisputeService.submitDispute(taskId|directOfferId) | DEVELOPER_GUIDE; Plan | dispute_service.dart | ✅ |
| SafetyViewModel hasOpenDispute*, getDisputeStatus*, submitDispute | DEVELOPER_GUIDE; Plan | safety_view_model.dart | ✅ |
| work_item_details_screen: _DisputeBannerContent, _ReportIssueGuard | DEVELOPER_GUIDE | work_item_details_screen.dart | ✅ |
| direct_offer_details_screen: _DirectOfferDisputeBanner, _ReportIssueGuardDirectOffer | DEVELOPER_GUIDE | direct_offer_details_screen.dart | ✅ |
| booking_details_screen: _BookingDisputeBanner | DEVELOPER_GUIDE | booking_details_screen.dart | ✅ |
| ErrorMapper (dispute/revision/delivery messages) | DEVELOPER_GUIDE Frozen behaviour | error_mapper.dart | ✅ |
| Exception text "Cannot submit delivery: dispute in progress" | SUPABASE_SETUP §9.1; ErrorMapper | Migration; error_mapper.dart | ✅ |
| Exception text "Cannot request revision: dispute in progress" | SUPABASE_SETUP §9.2; ErrorMapper | Migration; error_mapper.dart | ✅ |
| Banner "Dispute under review" / "Work frozen — in dispute" | DEVELOPER_GUIDE; Plan; Spec 14a §10 | work_item_details_screen, direct_offer_details_screen, booking_details_screen | ✅ |
| PLAN_14a_DisputeExtension_2026-03-08.md | Execution log; DEVELOPER_GUIDE; SUPABASE_SETUP §17 | .TODO/ | ✅ |
| 14a_dispute-entity-freeze-integration.md | Plan; Execution log | Sline_everything/AppDigram/All_Diagrams/ | ✅ |

All referenced files and DB objects in scope exist and match the described behaviour. No BLOCKER from mismatches.

---

## 5. Evidence (exact doc paths and line/section references)

- **SUPABASE_SETUP.md**  
  - §9.1: lines 2254–2262 (`### 9.1 rpc_submit_delivery`).  
  - §9.2: lines 2264–2275 (`### 9.2 rpc_request_revision`).  
  - §9.2a: lines 2277–2288 (`### 9.2a rpc_submit_dispute (Plan 14a)`).  
  - §17: lines 2482–2495 (`## 17. Changelog`, Version 2.20.1, Plan 14a bullet).  
  - Duplicate "9" headings: 1406 (`## 9. RPC Functions`), 1514 (`## 9. Functions & RPC`), 2250 (`### 9. Functions (RPCs)`).

- **DEVELOPER_GUIDE.md**  
  - Dispute entry points: lines 2565–2569 (`#### Dispute entry points (Plan 14a)`).  
  - Frozen behaviour: lines 2571–2578 (`#### Frozen behaviour (Plan 14a)`).  
  - UI widgets and banner copy: lines 2582–2587 (Dispute lifecycle §3–4).  
  - Plan 14a ref: line 2585 (`.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`).

- **MVP_ROADMAP.md**  
  - Dispute row: lines 72–73; no 14a or 20260308160000.

- **STRUCTURE.md**  
  - Dispute lifecycle migrations: line 90 (20260308140000, 20260308150000 only); 20260308160000 not listed.  
  - dispute_service_test: line 234.

- **Sline_Log.md**  
  - Grep for "14a", "Dispute Extension", "Frozen guard": no matches.

- **Migration**  
  - `supabase/migrations/20260308160000_14a_dispute_extension_frozen_guards.sql`: full read; RPCs and indexes match plan and SUPABASE_SETUP.

- **Code**  
  - `lib/features/safety/services/dispute_service.dart`: submitDispute, hasOpen*, getDisputeStatus* (full read).  
  - `lib/features/safety/viewmodels/safety_view_model.dart`: delegates + ErrorMapper (full read).  
  - `lib/features/work/view/work_item_details_screen.dart`: _buildDisputedBanner, _DisputeBannerContent, _ReportIssueGuard (grep + context).  
  - `lib/features/direct_offers/view/direct_offer_details_screen.dart`: _DirectOfferDisputeBanner, _ReportIssueGuardDirectOffer (grep + context).  
  - `lib/features/booking/view/booking_details_screen.dart`: _BookingDisputeBanner (grep + context).  
  - `lib/core/utils/error_mapper.dart`: dispute/revision/delivery/eligibility/reason/exactly-one mappings (grep + read).

---

## 6. Summary

- **Documentation delta:** SUPABASE_SETUP §9.1, §9.2, §9.2a and §17 are updated and accurate. DEVELOPER_GUIDE dispute entry points, Frozen behaviour, and banners are updated and match the app.
- **Reference integrity:** One **ambiguity** (duplicate section "9" in SUPABASE_SETUP); no broken paths or wrong section numbers. No BLOCKER.
- **Missing updates:** MVP_ROADMAP (14a bullet), STRUCTURE (14a migration bullet), Sline_Log (14a release entry); 14a spec implementation note optional.
- **Files/objects:** All referenced files and DB objects exist and match docs.

**Conclusion:** Phase 9 doc updates for 14a are in place and consistent with code and DB. Recommended follow-ups: add 14a to MVP_ROADMAP and STRUCTURE, and add a Sline_Log release entry; optionally disambiguate or rename SUPABASE_SETUP §9 (RPCs) to avoid confusion with the other "9" sections.
