# Docs Reference Fix - AppDiagram Paths

**Date:** 2026-05-21  
**Scope:** DocsKeeper reference validation for the detail-surface chrome/dock pass.

## Broken References Found

Several agent files referenced `Sline_everything/AppDigram/...`, but the live
directory in this checkout is `Sline_everything/AppDiagram/...`.

## Corrected References

Updated `AppDigram` to `AppDiagram` in:

- `.cursor/Agents/Planner.md`
- `.cursor/Agents/PlanCritic.md`
- `.cursor/Agents/Executor.md`
- `.cursor/Agents/Orchestrator.md`
- `.cursor/Agents/Sentinel.md`
- `.cursor/Agents/DocsKeeper.md`

## Validation

- `rg -n "AppDigram" . Sline_everything .cursor README.md AGENTS.md` identified
  the stale references before correction.
- `test -e Sline_everything/AppDiagram/README.md` confirms the corrected
  diagram index path exists.
- `rg -ni "evi""dence" .cursor/Agents .cursor/rules` is required after agent
  file edits and was run during this DocsKeeper pass.
