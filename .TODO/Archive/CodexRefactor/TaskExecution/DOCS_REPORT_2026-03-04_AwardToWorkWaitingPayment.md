# SlineDocs Report: Award to Work Waiting Payment

**Date:** 2026-03-04  
**Scope:** Award to Work Waiting Payment  
**Plan:** Award → Work Section + Waiting Payment + Cancel

---

## 1. Documentation Delta List

| Doc | Section | Status | Action |
|-----|---------|--------|--------|
| Sline_everything/SUPABASE_SETUP.md | §6.4 vw_unified_work_items | Updated | Already describes three branches, columns, and migration ref. **OK.** |
| Sline_everything/DEVELOPER_GUIDE.md | Dashboard / work items table | Outdated | Table still says "UNION ALL of tasks + bookings with normalized status". Should add "includes awarded pending-payment branch". |
| Sline_everything/DEVELOPER_GUIDE.md | Tender payment / Award flow | Partial | No explicit sentence that "Award moves task to Work tab (Waiting payment); Pay/Cancel from Work". Add one line. |
| Sline_everything/Sline_Log.md | Changelog | Not updated | Add entry for Award → Work + cancel_awarded_offer + vw_unified_work_items third branch. |
| .cursor/PROJECT_CONTEXT.md | — | Optional | No change required; dashboard link notes already reference work/offers. |

---

## 2. Reference Integrity Scan

- **Broken refs:** None found. Plan references SUPABASE_SETUP.md §6.4, DEVELOPER_GUIDE, dashboard_repository, etc.; all exist.
- **Renamed files:** None.
- **Outdated statements:**
  - DEVELOPER_GUIDE.md table row for `vw_unified_work_items`: "UNION ALL of tasks + bookings with normalized status" is incomplete; view now has three branches (tasks in progress, bookings, awarded pending payment).

---

## 3. Required Doc Updates (Ordered)

1. **DEVELOPER_GUIDE.md:** In the table where `vw_unified_work_items` is described, change to: "UNION ALL of tasks (in progress + awarded pending payment) and bookings with normalized status; see SUPABASE_SETUP.md §6.4."
2. **DEVELOPER_GUIDE.md:** In Dashboard / Tender payment paragraph, add: "Awarding an offer moves the task to the Work tab as 'Waiting payment'; the client can Pay or Cancel from there. Cancel reverts the award so the task reappears in Inbox."
3. **Sline_Log.md:** Add a short version entry for 2026-03-04: Award → Work flow, cancel_awarded_offer RPC, vw_unified_work_items third branch (awarded_request_id, payment_deadline).

---

**Conclusion:** Doc deltas are small. No broken refs. Updates are MED priority. No BLOCKER.
