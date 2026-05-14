# Docs Reference Fix - Guidance Paths

**Date:** 2026-05-13  
**Agent:** @DocsKeeper  
**Scope:** stale project guidance references discovered during Phase 5-8 execution and Step 7 SystemEvolution.

## Broken References Found

| File | Broken reference | Why broken |
| --- | --- | --- |
| `.cursor/rules/project-rules.mdc` | `GEMINI.md` | `GEMINI.md` is not present in this checkout. The active repo guidance is supplied by `AGENTS.md` plus `.cursor/PROJECT_CONTEXT.md` and `.cursor/Agents/`. |
| `.cursor/PROJECT_CONTEXT.md` | `GEMINI.md` | Same stale guide-name reference. |
| `Sline_everything/SUPABASE_SETUP.md` | `GEMINI.md` | Additional Resources pointed to the missing guide file. |
| `Sline_everything/Sline_Log.md` | `GEMINI.md` | Historical files-touched entry referenced the missing guide file as documentation. |

## Corrections Applied

| File | Replacement |
| --- | --- |
| `.cursor/rules/project-rules.mdc` | `AGENTS.md` for project overview, conventions, build/run commands; `.cursor/Agents/` for agent definitions and triggers. |
| `.cursor/PROJECT_CONTEXT.md` | `AGENTS.md` for repo instructions; `.cursor/Agents/` for agent definitions and triggers. |
| `Sline_everything/SUPABASE_SETUP.md` | `AGENTS.md` and `.cursor/Agents/` in Additional Resources. |
| `Sline_everything/Sline_Log.md` | `AGENTS.md` in the historical documentation file list. |

## Validation

- `test -f AGENTS.md` succeeded.
- `test -f GEMINI.md` failed, confirming the old reference was dead.
- `rg -n "GEMINI" .cursor/rules .cursor/PROJECT_CONTEXT.md .cursor/Agents Sline_everything` returns only intentional evidence mentions in agent/report notes, not active guidance references.
