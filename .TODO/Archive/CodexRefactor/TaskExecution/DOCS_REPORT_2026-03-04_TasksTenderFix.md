# Docs Report: Tasks Tender Fix

**Scope:** Tasks Tender Fix (code and migration changes)  
**Plan reference:** `.TODO/PLAN_Tasks_Fix_All_2026-03-01.md`  
**Date:** 2026-03-04  
**Agent:** @DocsKeeper

---

## 1. Documentation Scan Performed

- `Sline_everything/DEVELOPER_GUIDE.md` — Task feature and tender flow references
- `Sline_everything/SUPABASE_SETUP.md` — replace_task_request, task_requests, RLS
- `Sline_everything/MVP_ROADMAP.md` — Task/tender status
- `.TODO/EXECUTION_LOG_PLAN_Tasks_Fix_All_2026-03-01.md` — Execution evidence
- `.TODO/PLAN_Tasks_Fix_All_2026-03-01.md` — Plan checklist

---

## 2. Reference Integrity

| Reference | Location | Status |
|-----------|----------|--------|
| `replace_task_request(...)` | SUPABASE_SETUP.md §15 / RPC list | Documented; migration now exists in repo ✅ |
| Task tender flow (award → pay) | DEVELOPER_GUIDE.md | Described; fail-closed behavior not yet documented |
| Task requests (submit/replace) | DEVELOPER_GUIDE, SUPABASE_SETUP | Replace RPC params match migration ✅ |
| `profiles.active_role` / is_freelancer | SUPABASE_SETUP RLS | Client no longer mutates active_role; docs still describe RLS/is_freelancer ✅ |

No broken file paths or class names in reviewed docs for this scope.

---

## 3. Required Doc Updates (Delta List)

| Doc | Change | Priority |
|-----|--------|----------|
| `Sline_everything/SUPABASE_SETUP.md` | Changelog: add migration `20260311000000_replace_task_request.sql` and note that `replace_task_request` is now defined in repo. | MED |
| `Sline_everything/DEVELOPER_GUIDE.md` (or Task Feature section) | Add short note: tender payment is fail-closed when using Demo or QiCard processPayment (server-backed tender flow required for real payment). | MED |
| `Sline_everything/DEVELOPER_GUIDE.md` | Note: offer submission no longer mutates `profiles.active_role`; RLS (is_freelancer) applies; UX message if insert denied. | LOW |
| `Sline_everything/MVP_ROADMAP.md` | Optional: mention tender payment hardening (fail-closed, replace_task_request in migrations). | LOW |
| `Sline_everything/Sline_Log.md` | Log: Tasks Tender Fix (date): fail-closed coordinator, replace_task_request migration, active_role removal, coordinator tests. | LOW |

---

## 4. Execution / Plan Cross-Links

- `.TODO/EXECUTION_LOG_PLAN_Tasks_Fix_All_2026-03-01.md` already references plan and tasks.TODO.md. ✅
- Recommend cross-reference from DEVELOPER_GUIDE (Task/tender section) to execution log or plan for “what was hardened.” Optional.

---

## 5. Summary

- **Reference integrity:** No broken refs; RPC and flow references valid.
- **Outdated statements:** Only “replace_task_request was documented but not in migrations” is now resolved; add changelog.
- **Required updates:** Changelog + short tender fail-closed and active_role notes in DEVELOPER_GUIDE; optional Sline_Log and MVP_ROADMAP.
- **Blockers:** None.
