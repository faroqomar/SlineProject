# Master Report: 14a Dispute Extension — Multi-Agent Review

**Date:** 2026-03-08  
**Scope:** 14a Dispute Extension (PLAN_14a_DisputeExtension_2026-03-08 — Phases 6–9)  
**Pipeline:** Architect → Observability → SlineDocs → CodeGuard (sequential)  
**Spec:** `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md`

---

## A) Executive Summary

| Item | Result |
|------|--------|
| **What was reviewed** | Migration (Frozen guards, partial unique indexes, rpc_submit_dispute); DisputeService, SafetyViewModel; work_item_details_screen, direct_offer_details_screen, booking_details_screen (Report Issue + banners); ErrorMapper; SUPABASE_SETUP, DEVELOPER_GUIDE; tests. |
| **Overall risk level** | **MEDIUM** (CodeGuard). No BLOCKER from any agent. |
| **Final decision** | **Ready ✅** — Not blocked. Optional fixes and doc updates recommended below. |

**Agent reports produced:**
- `.TODO/ARCHITECT_REPORT_2026-03-08_14aDisputeExtension.md`
- `.TODO/OBSERVABILITY_REPORT_2026-03-08_14aDisputeExtension.md`
- `.TODO/DOCS_REPORT_2026-03-08_14aDisputeExtension.md`
- `.TODO/CODEGUARD_REVIEW_2026-03-08_14aDisputeExtension.md`

---

## B) Consolidated Findings (Deduplicated)

### Security
| Severity | Finding | Owner | Path / object | Fix |
|----------|---------|--------|----------------|-----|
| — | No vulnerability identified. RLS unchanged; SECURITY DEFINER + auth.uid(); no injection; reason/defendant not logged. | CodeGuard | Migration, DisputeService | None. |

### Data integrity
| Severity | Finding | Owner | Path / object | Fix |
|----------|---------|--------|----------------|-----|
| — | Partial unique indexes and rpc_submit_dispute enforce one open/active per entity; eligibility enforced in RPC. | Architect, CodeGuard | disputes, rpc_submit_dispute | None. |

### Architecture / MVVM
| Severity | Finding | Owner | Path / object | Fix |
|----------|---------|--------|----------------|-----|
| — | MVVM compliant: no direct Supabase in views; dispute state via Service → VM → UI. | Architect | All three detail screens | None. |
| MED | Work item details: _ReportIssueGuard does not handle sourceType == 'direct_offer' (only task/booking). Direct_offer Report Issue only on direct_offer_details_screen. | CodeGuard | work_item_details_screen.dart | Optional: add direct_offer branch to _ReportIssueGuard with hasOpenDisputeForDirectOffer(entityId) when work item is direct_offer. |
| LOW | Booking: optionally show Report Issue when status is active (14a §5); currently only delivered. | Architect | booking_details_screen.dart | Optional. |

### Performance
| Severity | Finding | Owner | Path / object | Fix |
|----------|---------|--------|----------------|-----|
| LOW | Multiple dispute-status / hasOpen calls per screen (banner + guards) for same entity — duplicate work, not N+1 over lists. | CodeGuard, Observability | Detail screens | Optional: cache dispute status/hasOpen per entity in VM or widget. |

### Observability
| Severity | Finding | Owner | Path / object | Fix |
|----------|---------|--------|----------------|-----|
| LOW | No correlation_id in dispute flow; Frozen block not distinguished in client logs (submit_delivery/request_revision). | Observability | SafetyViewModel, WorkManagementService | Optional: add outcome/code for "dispute in progress"; optional correlation_id. |
| LOW | getDisputeStatus*: only error path logged; no success event. | Observability | dispute_service.dart | Optional: safety_dispute_status_fetched or equivalent. |

### Docs / reference integrity
| Severity | Finding | Owner | Path / object | Fix |
|----------|---------|--------|----------------|-----|
| LOW | SUPABASE_SETUP has multiple "§9" blocks; changelog "See §9.1, §9.2, §9.2a" could point to wrong section. | SlineDocs | SUPABASE_SETUP.md | Optional: add short note or heading to disambiguate which §9 refers to RPCs. |
| LOW | MVP_ROADMAP does not mention Plan 14a, migration 20260308160000, Frozen guards, or task/direct_offer Report Issue. | SlineDocs | MVP_ROADMAP.md | Add 14a / Frozen / Report Issue (task, direct_offer) to roadmap. |
| LOW | STRUCTURE "Recent migration themes" lists 20260308140000, 20260308150000 but not 20260308160000. | SlineDocs | STRUCTURE.md | Add 20260308160000 (14a dispute extension). |
| LOW | Sline_Log: no release entry for 14a. | SlineDocs | Sline_Log.md | Add release entry. |

### Tooling / analyzer
| Severity | Finding | Owner | Path / object | Fix |
|----------|---------|--------|----------------|-----|
| LOW | flutter analyze: 1 info — test imports `postgrest` (not direct dependency). | CodeGuard | test/unit/safety/dispute_service_test.dart | Add postgrest to dev_dependencies or remove direct import. |

---

## C) Fix Plan (Ordered, Step-by-Step)

| Step | Owner | Action | Verification |
|------|--------|--------|--------------|
| 1 | @SlineDocs | Update MVP_ROADMAP: add 14a Dispute Extension (Frozen guards, rpc_submit_dispute, task/direct_offer Report Issue, banners). | MVP_ROADMAP mentions 14a and migration. |
| 2 | @SlineDocs | Update STRUCTURE: add migration 20260308160000 to recent migration themes. | STRUCTURE lists 14a migration. |
| 3 | @SlineDocs | Update Sline_Log: add release entry for 14a (Frozen guards, dispute UI, banners). | Sline_Log has entry. |
| 4 | @SlineDocs | Optional: in SUPABASE_SETUP, add one-line note near changelog that "§9.1, §9.2, §9.2a" refer to "Functions (RPCs)" section. | No broken refs. |
| 5 | @Architect or dev | Optional: work_item_details_screen — in _ReportIssueGuard, when sourceType == 'direct_offer', use hasOpenDisputeForDirectOffer(entityId) and show Report Issue when eligible. | Manual: unified work item as direct_offer shows Report Issue when active/delivered and no dispute. |
| 6 | Dev | Optional: resolve analyzer info — add postgrest to dev_dependencies or change test to avoid direct postgrest import. | flutter analyze with 0 info. |
| 7 | @CodeGuard | Re-run review after steps 1–4 (and optionally 5–6) if fixes applied. | CODEGUARD_REVIEW updated or re-run. |

---

## D) Regression Checklist

| Flow | How to test quickly |
|------|----------------------|
| Submit dispute (booking) | Booking details → delivered → Report Issue → submit reason → success; Approve disabled. |
| Submit dispute (task) | Work item details (task, in_progress or delivered) → Report Issue → submit → success. |
| Submit dispute (direct_offer) | Direct offer details → active or delivered → Report Issue → submit → success. |
| Frozen: submit delivery | With open/active dispute on task/booking, submit delivery → expect error message (dispute in progress). |
| Frozen: request revision | With open/active dispute, request revision → expect error message. |
| Single active dispute | Submit second dispute for same task (or direct_offer) while first is open → expect "open or active dispute already exists" or unique violation. |
| Banners | With dispute open → "Dispute under review"; with dispute active → "Work frozen — in dispute." |
| Approve / Review disabled | With open/active dispute, Approve & Release and Review delivery disabled on booking, work item, direct offer. |

---

## E) Rollback Notes

| Area | Rollback |
|------|----------|
| **DB** | Revert migration: drop rpc_submit_dispute; drop indexes uq_disputes_one_open_active_per_task, uq_disputes_one_open_active_per_direct_offer; restore previous rpc_submit_delivery and rpc_request_revision bodies (without Frozen guard). |
| **App** | Revert DisputeService to submit via direct INSERT with taskId only; remove getDisputeStatus*; SafetyViewModel revert to previous submit API. |
| **UI** | Remove Report Issue from work item and direct offer details; remove open/active banners or revert to single generic banner. |
| **Docs** | Revert SUPABASE_SETUP §9.1, §9.2, §9.2a, §17; DEVELOPER_GUIDE dispute/Frozen/banner sections. |

---

## F) Next Actions

1. **Recommended (non-blocking):** Complete fix plan steps 1–4 (MVP_ROADMAP, STRUCTURE, Sline_Log, SUPABASE_SETUP note).
2. **Optional:** Steps 5–6 (direct_offer in work item Report Issue guard; analyzer info).
3. **Optional:** Observability improvements (correlation_id, Frozen outcome in client logs, getDisputeStatus success event).
4. **No blocker:** Pipeline did not halt; CodeGuard APPROVED. Release from review perspective is **Ready**.
