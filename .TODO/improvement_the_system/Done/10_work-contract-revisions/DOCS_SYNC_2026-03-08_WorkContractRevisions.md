# Docs Sync Note: Work Contract Revisions (RPC hardening)

**Workflow:** `.agents/workflows/slinedocs.md`  
**Date:** 2026-03-08  
**Scope:** Work Contract Revisions — `rpc_request_revision` state/cap guards, ErrorMapper, UI

---

## 1) Doc files updated

| Doc | Section / location | Change |
|-----|--------------------|--------|
| `Sline_everything/SUPABASE_SETUP.md` | §1 Key Business Rules | Bullet: revision requests enforce status and limit (`rpc_request_revision`: status='delivered', revisions_used < revisions_total). |
| `Sline_everything/SUPABASE_SETUP.md` | §9.2 `rpc_request_revision` | Logic: state guard (status='delivered') and cap guard (revisions_used < revisions_total); exception messages; migration `20260308120000_harden_rpc_request_revision.sql`; reference to Frozen guard in 20260308160000. |
| `Sline_everything/DEVELOPER_GUIDE.md` | Work table (RPC row) | `rpc_request_revision` row: limit check (status=delivered, revisions_used < revisions_total); revision errors mapped via ErrorMapper and shown in Review Delivery modal. |
| `Sline_everything/DEVELOPER_GUIDE.md` | Dispute / Frozen | Note that rpc_submit_delivery and rpc_request_revision raise dispute-in-progress errors when Frozen. |
| `Sline_everything/Sline_Log.md` | Work Contract Revisions entry | Full entry: plan, execution, master report; migration path; app (ErrorMapper, ViewModel, modal, service); doc refs. **Docs sync note:** added link to this file. |
| `Sline_everything/STRUCTURE.md` | Recent migrations | Bullet: Work contract revisions hardening (2025-03-08): `20260308120000_harden_rpc_request_revision.sql`; plan link. **Last Updated** line: added "Work contract revisions hardening ref". |
| `Sline_everything/MVP_ROADMAP.md` | Delivery submission and approval row | Note: Work contract revisions (2025-03-08): `rpc_request_revision` enforces status=delivered and revisions_used < revisions_total; ErrorMapper + UI disable when no revisions left; plan link. |
| `Sline_everything/AppDigram/All_Diagrams/10_work-contract-revisions.md` | Implementation path | Path set to `lib/features/work/services/work_management_service.dart` for RPC calls. |
| `Sline_everything/AppDigram/All_Diagrams/12_unified-work-view.md` | Service path | Corrected `lib/features/work/work_management_service.dart` → `lib/features/work/services/work_management_service.dart` (reference integrity). |

---

## 2) Summary of changes

- **DB/docs:** RPC contract and migration are documented in SUPABASE_SETUP (§1, §9.2); changelog and §9.2 cite migration `20260308120000_harden_rpc_request_revision.sql`.
- **App/docs:** DEVELOPER_GUIDE work table and dispute section describe revision limits, ErrorMapper, and Frozen behavior; diagram 10 and 12 point to the correct service path.
- **Traceability:** Sline_Log, STRUCTURE, and MVP_ROADMAP link to the plan and execution log; Sline_Log links to this DOCS_SYNC note.

---

## 3) References validated

| Reference | Status |
|-----------|--------|
| `supabase/migrations/20260308120000_harden_rpc_request_revision.sql` | Exists |
| `lib/features/work/services/work_management_service.dart` | Exists |
| `lib/features/work/viewmodels/work_item_details_view_model.dart` | Exists |
| `lib/features/work/view/widgets/review_delivery_modal.dart` | Exists |
| `lib/core/utils/error_mapper.dart` | Exists |
| `.TODO/PLAN_WorkContractRevisions_2025-03-08_PlanCritic.md` | Exists |
| `.TODO/EXECUTION_LOG_WorkContractRevisions_2025-03-08.md` | Exists |
| `.TODO/MASTER_REPORT_2025-03-08_WorkContractRevisions.md` | Exists |
| RPC name `rpc_request_revision` in SUPABASE_SETUP §9.2 | Matches migration and app |
| Diagram 10, 12 service paths | Corrected / verified |

---

## 4) Why each update was needed

- **SUPABASE_SETUP:** Single source of truth for RPC behavior and migrations; §1 and §9.2 needed to reflect state/cap guards and migration name so DB and docs stay aligned.
- **DEVELOPER_GUIDE:** Developers need to know revision limits, where errors are mapped (ErrorMapper), and that Frozen (dispute) blocks revision; work table and dispute section updated accordingly.
- **Sline_Log:** Every executed plan must have a traceable entry with plan/execution/review links and a docs sync note for major work (slinedocs §8.1).
- **STRUCTURE.md:** New migration and its purpose must appear in the migration list; Last Updated reflects the work contract revisions ref.
- **MVP_ROADMAP:** Delivery/revision row should reflect that revision request is fully implemented with RPC guards and UI (disable when no revisions, ErrorMapper messages).
- **Diagrams 10 and 12:** Correct service path (`lib/features/work/services/work_management_service.dart`) so diagrams match the codebase and reference checks pass.
