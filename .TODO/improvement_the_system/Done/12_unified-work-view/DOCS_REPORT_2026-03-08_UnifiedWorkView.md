# Docs Report: Unified Work View

**Scope:** Unified Work View (12_unified-work-view)  
**Plan:** `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`  
**Date:** 2026-03-08  
**Agent:** @SlineDocs

---

## 1. Documentation Delta List

### 1.1 Updated (Evidence)

| Doc | Section | Change |
|-----|---------|--------|
| `Sline_everything/SUPABASE_SETUP.md` | §6.4 vw_unified_work_items | Updated to 4 branches, disputes, security_invoker, conversation_id, rollback migration ref. ✅ |
| `Sline_everything/DEVELOPER_GUIDE.md` | Work Management | Fallback Mapper replaced with "Single source of truth"; table row for vw_unified_work_items updated. ✅ |

### 1.2 Created

| Doc | Purpose |
|-----|---------|
| `.TODO/contract_vw_unified_work_items.md` | View column and dispute JOIN contract. ✅ |
| `.TODO/RLS_check_unified_work_view.md` | RLS check matrix and optional SQL. ✅ |

---

## 2. Reference Integrity Scan

### 2.1 Broken or Outdated Refs

| Ref | Location | Issue | Severity |
|-----|----------|--------|----------|
| `unified_work_item_fallback_mapper.dart` | DEVELOPER_GUIDE, Sline_Log, various .TODO/ and spec files | File deleted; some docs still mention it. | MED (docs only; code is correct) |

**Evidence:**  
- `Sline_everything/DEVELOPER_GUIDE.md` — Updated to "Single source of truth", no fallback mapper. ✅  
- `Sline_everything/Sline_Log.md` — May still reference UnifiedWorkItemFallbackMapper (not scanned in full).  
- `.TODO/improvement_the_system/ImplementReady/12_unified-work-view/` — Spec/audit docs; historical. No change required for implementation.  

### 2.2 Required Doc Updates

| Action | Owner | File |
|--------|--------|------|
| **Optional:** Remove or soften reference to `UnifiedWorkItemFallbackMapper` in Sline_Log.md if it exists (changelog / history). | @SlineDocs | `Sline_everything/Sline_Log.md` |

No broken code references; only historical/changelog mentions may remain.

---

## 3. Naming / Path Consistency

- Migration files: `20260308100000_rollback_unified_work_view.sql`, `20260308110000_upgrade_unified_work_view.sql`. Referenced in SUPABASE_SETUP §6.4. ✅  
- Contract and RLS docs in `.TODO/` match plan and execution. ✅  

---

## 4. Summary

- **Docs:** SUPABASE_SETUP and DEVELOPER_GUIDE updated; contract and RLS artifacts in .TODO.  
- **Refs:** No code refs to deleted mapper. Optional: Sline_Log.md cleanup. No BLOCKER.
